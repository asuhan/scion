/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2021 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

import wk_interop

private func adjustedStyleDifference(
  _ diff: StyleDifference, oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
) -> StyleDifference {
  if diff >= .Layout {
    return diff
  }
  // FIXME: Preferably we do this at RenderStyle::changeRequiresLayout but checking against pseudo(::marker) is not sufficient.
  let needsLayout =
    oldStyle.listStylePosition() != newStyle.listStylePosition()
    || oldStyle.listStyleType() != newStyle.listStyleType()
    || oldStyle.isDisplayInlineType() != newStyle.isDisplayInlineType()
  return needsLayout ? .Layout : diff
}

final class RenderListMarkerWrapper: RenderBoxWrapper {
  convenience init(listItem: RenderListItemWrapper, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInside() -> Bool { return wk_interop.RenderListMarker_isInside(p) }

  func listItem() -> RenderListItemWrapper? {
    if let unwrapped = wk_interop.RenderListMarker_listItem(p) {
      return RenderListItemWrapper(p: unwrapped)
    }
    return nil
  }

  override final func computePreferredLogicalWidths() {
    assert(preferredLogicalWidthsDirty())
    updateContent()

    if isImage() {
      let imageSize = LayoutSizeWrapper(size: image!.imageSize(self, style().usedZoom()))
      maxPreferredLogicalWidth =
        style().isHorizontalWritingMode() ? imageSize.width() : imageSize.height()
      minPreferredLogicalWidth = maxPreferredLogicalWidth
      setPreferredLogicalWidthsDirty(shouldBeDirty: false)
      updateMargins()
      return
    }

    let font = style().fontCascade()

    var logicalWidth = LayoutUnit()
    if widthUsesMetricsOfPrimaryFont() {
      logicalWidth = LayoutUnit(
        value: (font.metricsOfPrimaryFont().intAscent() * 2 / 3 + 1) / 2 + 2)
    } else if !m_textWithSuffix.isEmpty() {
      logicalWidth = LayoutUnit(value: font.width(run: textRun().textRun))
    }

    minPreferredLogicalWidth = logicalWidth
    maxPreferredLogicalWidth = logicalWidth

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)

    updateMargins()
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.phase != .Foreground && paintInfo.phase != .Accessibility {
      return
    }

    if style().usedVisibility() != .Visible {
      return
    }

    let boxOrigin = paintOffset + location()
    var overflowRect = visualOverflowRect()
    overflowRect.moveBy(offset: boxOrigin)
    if !paintInfo.rect.intersects(other: overflowRect) {
      return
    }

    let box = LayoutRectWrapper(location: boxOrigin, size: size())

    var markerRect = relativeMarkerRect()
    markerRect.moveBy(delta: boxOrigin.FloatPoint())

    if paintInfo.phase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(self, markerRect)
      return
    }

    if markerRect.isEmpty() {
      return
    }

    let context = paintInfo.context()

    if isImage() {
      if let markerImage = image!.image(renderer: self, size: markerRect.size()) {
        context.drawImage(markerImage, markerRect)
      }
      if selectionState() != .None {
        var selRect: LayoutRectWrapper = localSelectionRect()
        selRect.moveBy(offset: boxOrigin)
        context.fillRect(
          rect: FloatRectWrapper(r: snappedIntRect(rect: selRect)),
          color: m_listItem!.selectionBackgroundColor())
      }
      return
    }

    if selectionState() != .None {
      var selRect: LayoutRectWrapper = localSelectionRect()
      selRect.moveBy(offset: boxOrigin)
      context.fillRect(
        rect: FloatRectWrapper(r: snappedIntRect(rect: selRect)),
        color: m_listItem!.selectionBackgroundColor())
    }

    let color = style().visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyColor)
    context.setStrokeColor(color: color)
    context.setStrokeStyle(style: .SolidStroke)
    context.setStrokeThickness(thickness: 1)
    context.setFillColor(color: color)

    let listStyleType = style().listStyleType()
    if listStyleType.isDisc() {
      context.fillEllipse(markerRect)
      return
    }
    if listStyleType.isCircle() {
      context.strokeEllipse(markerRect)
      return
    }
    if listStyleType.isSquare() {
      context.fillRect(markerRect)
      return
    }
    if m_textWithSuffix.isEmpty() {
      return
    }

    let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
    if !style().isHorizontalWritingMode() {
      markerRect.moveBy(delta: (-boxOrigin).FloatPoint())
      markerRect = markerRect.transposedRect()
      markerRect.moveBy(
        delta: FloatPoint(x: box.x().float(), y: (box.y() - logicalHeight()).float()))
      stateSaver.save()
      context.translate(x: markerRect.x(), y: markerRect.maxY())
      context.rotate(Float32(deg2rad(90)))
      context.translate(x: -markerRect.x(), y: -markerRect.maxY())
    }

    var textOrigin = FloatPoint(
      x: markerRect.x(), y: markerRect.y() + Float32(style().metricsOfPrimaryFont().intAscent()))
    textOrigin = roundPointToDevicePixels(
      point: LayoutPointWrapper(size: textOrigin),
      pixelSnappingFactor: document().deviceScaleFactor(),
      directionalRoundingToRight: style().isLeftToRightDirection())
    context.drawText(font: style().fontCascade(), run: textRun().textRun, point: textOrigin)
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func canBeSelectionLeaf() -> Bool { return true }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    super.styleWillChange(
      diff: adjustedStyleDifference(diff, oldStyle: style(), newStyle: newStyle), newStyle: newStyle
    )
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    var diff = diff
    if oldStyle != nil {
      diff = adjustedStyleDifference(diff, oldStyle: oldStyle!, newStyle: style())
    }
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if !optEq(image, style().listStyleImage()) {
      image?.removeClient(self)
      image = style().listStyleImage()
      image?.addClient(self)
    }
  }

  private func updateMargins() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateContent() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func relativeMarkerRect() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func localSelectionRect() -> LayoutRectWrapper {
    return LayoutRectWrapper(location: LayoutPointWrapper(), size: size())
  }

  private struct TextRunWithUnderlyingString {
    let textRun: TextRunWrapper
    let underlyingString: StringWrapper
  }

  private func textRun() -> TextRunWithUnderlyingString {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func widthUsesMetricsOfPrimaryFont() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_textWithSuffix = StringWrapper()
  private var image: StyleImage? = nil
  private let m_listItem: RenderListItemWrapper? = nil
}
