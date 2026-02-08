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

private let cMarkerPadding: Int32 = 7

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

  private func updateMarginsAndContent() {
    // FIXME: It's messy to use the preferredLogicalWidths dirty bit for this optimization, also unclear if this is premature optimization.
    if preferredLogicalWidthsDirty() {
      updateContent()
    }
    updateMargins()
  }

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
      m_maxPreferredLogicalWidth =
        style().isHorizontalWritingMode() ? imageSize.width() : imageSize.height()
      m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
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

    m_minPreferredLogicalWidth = logicalWidth
    m_maxPreferredLogicalWidth = logicalWidth

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
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    var blockOffset = LayoutUnit()
    var ancestor = parentBox(self)
    while ancestor != nil && CPtrToInt(ancestor!.p) != CPtrToInt(m_listItem?.p) {
      blockOffset += ancestor!.logicalTop()
      ancestor = parentBox(ancestor!)
    }

    let zero = LayoutUnit(value: UInt64(0))
    lineLogicalOffsetForListItem = m_listItem!.logicalLeftOffsetForLine(
      position: blockOffset, logicalHeight: zero)
    lineOffsetForListItem =
      style().isLeftToRightDirection()
      ? lineLogicalOffsetForListItem
      : m_listItem!.logicalRightOffsetForLine(position: blockOffset, logicalHeight: zero)

    if isImage() {
      updateMarginsAndContent()
      setWidth(width: image!.imageSize(self, style().usedZoom()).width)
      setHeight(height: image!.imageSize(self, style().usedZoom()).height)
    } else {
      setLogicalWidth(size: minPreferredLogicalWidth())
      setLogicalHeight(size: LayoutUnit(value: style().metricsOfPrimaryFont().intHeight()))
    }

    setMarginStart(value: LayoutUnit(value: 0))
    setMarginEnd(value: LayoutUnit(value: 0))

    let startMargin = style().marginStart()
    let endMargin = style().marginEnd()
    if startMargin.isFixed() {
      setMarginStart(value: LayoutUnit(value: startMargin.value()))
    }
    if endMargin.isFixed() {
      setMarginEnd(value: LayoutUnit(value: endMargin.value()))
    }

    clearNeedsLayout()
  }

  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    if !isImage() {
      return m_listItem!.lineHeight(
        firstLine: firstLine, direction: direction, linePositionMode: .PositionOfInteriorLineBoxes)
    }
    return super.lineHeight(
      firstLine: firstLine, direction: direction, linePositionMode: linePositionMode)
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
    let fontMetrics = style().metricsOfPrimaryFont()

    var marginStart = LayoutUnit()
    var marginEnd = LayoutUnit()

    if isInside() {
      if isImage() {
        marginEnd = LayoutUnit(value: cMarkerPadding)
      } else if widthUsesMetricsOfPrimaryFont() {
        marginStart = LayoutUnit(value: -1)
        marginEnd = Int32(fontMetrics.intAscent()) - minPreferredLogicalWidth() + 1
      }
    } else if isImage() {
      marginStart = -minPreferredLogicalWidth() - cMarkerPadding
      marginEnd = LayoutUnit(value: cMarkerPadding)
    } else {
      let offset = Int32(fontMetrics.intAscent()) * 2 / 3
      if widthUsesMetricsOfPrimaryFont() {
        marginStart = LayoutUnit(value: -offset - cMarkerPadding - 1)
        marginEnd = offset + cMarkerPadding + 1 - minPreferredLogicalWidth()
      } else if style().listStyleType().type == .String {
        if !m_textWithSuffix.isEmpty() {
          marginStart = -minPreferredLogicalWidth()
        }
      } else {
        if !m_textWithSuffix.isEmpty() {
          marginStart = -minPreferredLogicalWidth() - offset / 2
          marginEnd = LayoutUnit(value: offset / 2)
        }
      }
    }

    mutableStyle().setMarginStart(LengthWrapper(value: marginStart, type: .Fixed))
    mutableStyle().setMarginEnd(LengthWrapper(value: marginEnd, type: .Fixed))
  }

  private func updateContent() {
    if isImage() {
      // FIXME: This is a somewhat arbitrary width.  Generated images for markers really won't become particularly useful
      // until we support the CSS3 marker pseudoclass to allow control over the width and height of the marker box.
      let bulletWidth = LayoutUnit(value: Int32(style().metricsOfPrimaryFont().intAscent()) / 2)
      let defaultBulletSize = LayoutSizeWrapper(width: bulletWidth, height: bulletWidth)
      let imageSize = calculateImageIntrinsicDimensions(
        image: image!, positioningAreaSize: defaultBulletSize, scaleByUsedZoom: .No)
      image!.setContainerContextForRenderer(
        renderer: self, containerSize: imageSize.FloatSize(), containerZoom: style().usedZoom())
      m_textWithSuffix = emptyString()
      textWithoutSuffixLength = 0
      textIsLeftToRightDirection = true
      return
    }

    let isLeftToRightDirectionContent = {
      (content: StringWrapper) in
      // FIXME: Depending on the string value, we may need the real bidi algorithm. (rdar://106139180)
      // Also we may need to start checking for the entire content for directionality (and whether we need to check for additional
      // directionality characters like U_RIGHT_TO_LEFT_EMBEDDING).
      let bidiCategory = u_charDirection(content[0])
      return bidiCategory != .U_RIGHT_TO_LEFT && bidiCategory != .U_RIGHT_TO_LEFT_ARABIC
    }

    let styleType = style().listStyleType()
    switch styleType.type {
    case .String:
      m_textWithSuffix = styleType.identifier.string()
      textWithoutSuffixLength = UInt8(m_textWithSuffix.length())
      textIsLeftToRightDirection = isLeftToRightDirectionContent(m_textWithSuffix)
    case .CounterStyle:
      let counter = counterStyle()!
      let text = makeString(
        counter.prefix().text,
        counter.text(
          m_listItem!.value(),
          makeTextFlow(writingMode: style().writingMode(), direction: style().direction())))
      m_textWithSuffix = makeString(text, counter.suffix().text)
      textWithoutSuffixLength = UInt8(text.length())
      textIsLeftToRightDirection = isLeftToRightDirectionContent(text)
    case .None:
      m_textWithSuffix = StringWrapper(ASCIILiteral(" "))
      textWithoutSuffixLength = 0
      textIsLeftToRightDirection = true
    }
  }

  private func parentBox(_ box: RenderBoxWrapper) -> RenderBoxWrapper? {
    guard
      let multiColumnFlow = m_listItem!.enclosingFragmentedFlow() as? RenderMultiColumnFlowWrapper
    else { return box.parentBox() }
    let placeholder = multiColumnFlow.findColumnSpannerPlaceholder(spanner: box)
    return placeholder?.parentBox() ?? box.parentBox()
  }

  private func relativeMarkerRect() -> FloatRectWrapper {
    if isImage() {
      return FloatRectWrapper(
        x: 0, y: 0, width: image!.imageSize(self, style().usedZoom()).width,
        height: image!.imageSize(self, style().usedZoom()).height)
    }

    var relativeRect = FloatRectWrapper()
    if widthUsesMetricsOfPrimaryFont() {
      // FIXME: Are these particular rounding rules necessary?
      let fontMetrics = style().metricsOfPrimaryFont()
      let ascent = Int32(fontMetrics.intAscent())
      let bulletWidth = Float32((ascent * 2 / 3 + 1) / 2)
      relativeRect = FloatRectWrapper(
        x: 1, y: Float32(3 * (ascent - ascent * 2 / 3) / 2), width: bulletWidth, height: bulletWidth
      )
    } else {
      if m_textWithSuffix.isEmpty() {
        return FloatRectWrapper()
      }
      let font = style().fontCascade()
      relativeRect = FloatRectWrapper(
        x: 0, y: 0, width: font.width(run: textRun().textRun),
        height: Float32(font.metricsOfPrimaryFont().intHeight()))
    }

    if !style().isHorizontalWritingMode() {
      relativeRect = relativeRect.transposedRect()
      relativeRect.setX(x: width() - relativeRect.x() - relativeRect.width())
    }

    return relativeRect
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

  private func counterStyle() -> CSSCounterStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func widthUsesMetricsOfPrimaryFont() -> Bool {
    let listType = style().listStyleType()
    return listType.isCircle() || listType.isDisc() || listType.isSquare()
  }

  private var m_textWithSuffix = StringWrapper()
  private var textWithoutSuffixLength: UInt8 = 0
  private var textIsLeftToRightDirection = true
  private var image: StyleImage? = nil
  private let m_listItem: RenderListItemWrapper? = nil
  private var lineOffsetForListItem = LayoutUnit()
  private var lineLogicalOffsetForListItem = LayoutUnit()
}
