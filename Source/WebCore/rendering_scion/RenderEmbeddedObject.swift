/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Simon Hausmann <hausmann@kde.org>
 *           (C) 2000 Stefan Schimanski (1Stein@gmx.de)
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
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

import Foundation

private let replacementTextRoundedRectHeight: Float32 = 22
private let replacementTextRoundedRectLeftTextMargin: Float32 = 10
private let replacementTextRoundedRectRightTextMargin: Float32 = 10
private let replacementTextRoundedRectRightTextMarginWithArrow: Float32 = 5
private let replacementTextRoundedRectTopTextMargin: Float32 = -1
private let replacementTextRoundedRectRadius: Float32 = 11
private let replacementArrowLeftMargin: Float32 = -4
private let replacementArrowPadding: Float32 = 4
private let replacementArrowCirclePadding: Float32 = 3

private let replacementTextRoundedRectPressedColor = SRGBA<UInt8>(
  red: 105, green: 105, blue: 105, alpha: 242)
private let replacementTextRoundedRectColor = SRGBA<UInt8>(
  red: 125, green: 125, blue: 125, alpha: 242)
private let replacementTextColor = SRGBA<UInt8>(red: 240, green: 240, blue: 240)
private let unavailablePluginBorderColor = ColorWrapper.white.colorWithAlphaByte(216)

private func shouldUnavailablePluginMessageBeButton(
  _ page: PageWrapper,
  _ pluginUnavailabilityReason: RenderEmbeddedObjectWrapper.PluginUnavailabilityReason
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func drawReplacementArrow(_ context: GraphicsContextWrapper, _ insideRect: FloatRectWrapper)
{
  let _ = GraphicsContextStateSaver(context: context)

  var rect = insideRect
  rect.inflate(d: -replacementArrowPadding)

  let center = rect.center()
  let arrowTip = FloatPoint(x: rect.maxX(), y: center.y)

  context.setStrokeThickness(thickness: 2)
  context.setLineCap(lineCap: .Round)
  context.setLineJoin(lineJoin: .Round)

  let path = PathWrapper()
  path.moveTo(point: FloatPoint(x: rect.x(), y: center.y))
  path.addLineTo(point: arrowTip)
  path.addLineTo(point: FloatPoint(x: center.x, y: rect.y()))
  path.moveTo(point: arrowTip)
  path.addLineTo(point: FloatPoint(x: center.x, y: rect.maxY()))
  context.strokePath(path: path)
}

// Renderer for embeds and objects, often, but not always, rendered via plug-ins.
// For example, <embed src="foo.html"> does not invoke a plug-in.
final class RenderEmbeddedObjectWrapper: RenderWidgetWrapper {
  enum PluginUnavailabilityReason {
    case PluginMissing
    case PluginCrashed
    case PluginBlockedByContentSecurityPolicy
    case InsecurePluginVersion
    case UnsupportedPlugin
    case PluginTooSmall
  }

  func usesAsyncScrolling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollingNodeID() -> ScrollingNodeIDWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willAttachScrollingNode() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func didAttachScrollingNode() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func paintReplaced(
    _ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    if !showsUnavailablePluginIndicator() {
      return
    }

    if paintInfo.phase == .Selection {
      return
    }

    let context = paintInfo.context()
    if context.paintingDisabled() {
      return
    }

    var r = getReplacementTextGeometry(paintOffset)

    let background = PathWrapper()
    background.addRoundedRect(
      r.indicatorRect,
      FloatSize(width: replacementTextRoundedRectRadius, height: replacementTextRoundedRectRadius))

    let _ = GraphicsContextStateSaver(context: context)
    context.clip(rect: r.contentRect)
    context.setFillColor(
      color: ColorWrapper(
        unavailablePluginIndicatorIsPressed
          ? replacementTextRoundedRectPressedColor : replacementTextRoundedRectColor))
    context.fillPath(path: background)

    let strokePath = PathWrapper()
    var strokeRect = r.indicatorRect
    strokeRect.inflate(d: 1)
    strokePath.addRoundedRect(
      strokeRect,
      FloatSize(
        width: replacementTextRoundedRectRadius + 1, height: replacementTextRoundedRectRadius + 1))

    context.setStrokeColor(color: unavailablePluginBorderColor)
    context.setStrokeThickness(thickness: 2)
    context.strokePath(path: strokePath)

    let fontMetrics = r.font.metricsOfPrimaryFont()
    let labelX = roundf(
      r.replacementTextRect.location().x + replacementTextRoundedRectLeftTextMargin)
    let labelY = roundf(
      r.replacementTextRect.location().y
        + (r.replacementTextRect.size().height - Float32(fontMetrics.intHeight())) / 2
        + Float32(fontMetrics.intAscent()) + replacementTextRoundedRectTopTextMargin)
    context.setFillColor(color: ColorWrapper(replacementTextColor))
    context.drawBidiText(font: r.font, run: r.run, point: FloatPoint(x: labelX, y: labelY))

    if shouldUnavailablePluginMessageBeButton(page(), pluginUnavailabilityReason) {
      r.arrowRect.inflate(d: -replacementArrowCirclePadding)

      context.beginTransparencyLayer(opacity: 1.0)
      context.setFillColor(color: ColorWrapper(replacementTextColor))
      context.fillEllipse(r.arrowRect)

      context.setCompositeOperation(operation: .Clear)
      drawReplacementArrow(context, r.arrowRect)
      context.endTransparencyLayer()
    }
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // The relevant repainted object heuristic is not tuned for plugin documents.
    let countsTowardsRelevantObjects =
      !document().isPluginDocument() && paintInfo.phase == .Foreground

    if isPluginUnavailable {
      if countsTowardsRelevantObjects {
        page().addRelevantUnpaintedObject(object: self, objectPaintRect: visualOverflowRect())
      }
      renderReplacedPaint(paintInfo: &paintInfo, paintOffset: paintOffset)
      return
    }

    if countsTowardsRelevantObjects {
      page().addRelevantRepaintedObject(object: self, objectPaintRect: visualOverflowRect())
    }

    super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
  }

  override final func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    updateLogicalWidth()
    updateLogicalHeight()

    super.layout()

    clearOverflow()
    addVisualEffectOverflow()

    updateLayerTransform()

    if widget() == nil {
      view().frameView().addEmbeddedObjectToUpdate(self)
    }

    clearNeedsLayout()
  }

  private func showsUnavailablePluginIndicator() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    if !super.nodeAtPoint(request, &result, locationInContainer, accumulatedOffset, hitTestAction) {
      return false
    }

    guard let view = widget() as? PluginViewBase else { return true }
    let roundedPoint = locationInContainer.roundedPoint()

    if let horizontalScrollbar = view.horizontalScrollbar(),
      horizontalScrollbar.shouldParticipateInHitTesting()
        && horizontalScrollbar.frameRect().contains(roundedPoint)
    {
      result.setScrollbar(horizontalScrollbar)
      return true
    }

    if let verticalScrollbar = view.verticalScrollbar(),
      verticalScrollbar.shouldParticipateInHitTesting()
        && verticalScrollbar.frameRect().contains(roundedPoint)
    {
      result.setScrollbar(verticalScrollbar)
      return true
    }

    return true
  }

  private struct ReplacementTextGeometry {
    let accumulatedOffset: LayoutPointWrapper
    let contentRect: FloatRectWrapper
    let indicatorRect: FloatRectWrapper
    let replacementTextRect: FloatRectWrapper
    var arrowRect: FloatRectWrapper
    let font: FontCascadeWrapper
    let run: TextRunWrapper
    let textWidth: Float32
  }

  private func getReplacementTextGeometry(_ accumulatedOffset: LayoutPointWrapper)
    -> ReplacementTextGeometry
  {
    let includesArrow = shouldUnavailablePluginMessageBeButton(page(), pluginUnavailabilityReason)

    var contentRect = contentBoxRect().FloatRect()
    contentRect.moveBy(delta: FloatPoint(p: roundedIntPoint(point: accumulatedOffset)))

    let fontDescription = FontCascadeDescriptionWrapper()
    fontDescription.setOneFamily(
      SystemFontDatabase.singleton().systemFontShorthandFamily(.WebkitSmallControl))
    fontDescription.setWeight(boldWeightValue())
    fontDescription.setComputedSize(s: 12)
    let font = FontCascadeWrapper(fontDescription)
    font.update(fontSelector: nil)

    let run = TextRunWrapper(text: unavailablePluginReplacementText)
    let textWidth = font.width(run: run)

    var replacementTextRect = FloatRectWrapper()
    replacementTextRect.setSize(
      FloatSize(
        width: textWidth + replacementTextRoundedRectLeftTextMargin
          + (includesArrow
            ? replacementTextRoundedRectRightTextMarginWithArrow
            : replacementTextRoundedRectRightTextMargin),
        height: replacementTextRoundedRectHeight))
    replacementTextRect.setLocation(
      location: contentRect.location() + (contentRect.size() / 2 - replacementTextRect.size() / 2))

    var indicatorRect = replacementTextRect

    var arrowRect = FloatRectWrapper()
    // Expand the background rect to include the arrow, if it will be used.
    if includesArrow {
      arrowRect = indicatorRect
      arrowRect.setX(x: ceilf(arrowRect.maxX() + replacementArrowLeftMargin))
      arrowRect.setWidth(width: arrowRect.height())
      indicatorRect.unite(other: arrowRect)
    }
    return ReplacementTextGeometry(
      accumulatedOffset: accumulatedOffset, contentRect: contentRect, indicatorRect: indicatorRect,
      replacementTextRect: replacementTextRect, arrowRect: arrowRect, font: font, run: run,
      textWidth: textWidth)
  }

  private let isPluginUnavailable = false
  private let pluginUnavailabilityReason: PluginUnavailabilityReason = .PluginMissing
  private let unavailablePluginReplacementText = StringWrapper()
  private let unavailablePluginIndicatorIsPressed = false
}
