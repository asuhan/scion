/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007, 2008, 2009 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009-2023 Google, Inc.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2020, 2021, 2022, 2023, 2024 Igalia S.L.
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
 */

final class RenderSVGRootWrapper: RenderReplacedWrapper {
  func svgSVGElement() -> SVGSVGElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmbeddedThroughFrameContainingSVGDocument() -> Bool {
    // If our frame has an owner renderer, we're embedded through eg. object/embed/iframe,
    // but we only negotiate if we're in an SVG document inside object/embed, not iframe.
    if !(frame().ownerRenderer()?.isRenderEmbeddedObject() ?? false) || !isDocumentElementRenderer()
    {
      return false
    }
    return frame().document()!.isSVGDocument()
  }

  override func computeIntrinsicRatioInformation() -> (FloatSize, FloatSize) {
    assert(!shouldApplySizeContainment())

    // https://www.w3.org/TR/SVG/coords.html#IntrinsicSizing
    let intrinsicSize = calculateIntrinsicSize()
    var intrinsicRatio = FloatSize()

    if style().aspectRatioType() == .Ratio {
      intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
      return (intrinsicSize, intrinsicRatio)
    }

    var intrinsicRatioValue: LayoutSizeWrapper? = nil
    if !intrinsicSize.isEmpty() {
      intrinsicRatioValue = LayoutSizeWrapper(
        width: intrinsicSize.width, height: intrinsicSize.height)
    } else {
      let viewBoxSize = svgSVGElement().viewBox().size()
      if !viewBoxSize.isEmpty() {
        // The viewBox can only yield an intrinsic ratio, not an intrinsic size.
        intrinsicRatioValue = LayoutSizeWrapper(
          width: viewBoxSize.width, height: viewBoxSize.height)
      }
    }

    if intrinsicRatioValue != nil {
      intrinsicRatio = intrinsicRatioValue!.FloatSize()
    } else if style().aspectRatioType() == .AutoAndRatio {
      intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
    }
    return (intrinsicSize, intrinsicRatio)
  }

  override final func hasIntrinsicAspectRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyViewportClip() -> Bool {
    // the outermost svg is clipped if auto, and svg document roots are always clipped
    // When the svg is stand-alone (isDocumentElement() == true) the viewport clipping should always
    // be applied, noting that the window scrollbars should be hidden if overflow=hidden.
    return isNonVisibleOverflow(effectiveOverflowX()) || style().overflowX() == .Auto
      || self.isDocumentElementRenderer()
  }

  override final func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visualOverflowRectEquivalent() -> LayoutRectWrapper {
    return SVGBoundingBoxComputation.computeVisualOverflowRect(self)
  }

  func viewportContainer() -> RenderSVGViewportContainerWrapper? {
    let child = firstChild()
    if !(child?.isAnonymous() ?? false) {
      return nil
    }
    return child as? RenderSVGViewportContainerWrapper
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateLayoutSizeIfNeeded() -> Bool {
    let previousSize = size()
    updateLogicalWidth()
    updateLogicalHeight()
    return selfNeedsLayout() || previousSize != size()
  }

  override final func computeReplacedLogicalWidth(
    shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  )
    -> LayoutUnit
  {
    // When we're embedded through SVGImage (border-image/background-image/<html:img>/...) we're forced to resize to a specific size.
    if !containerSize.isEmpty() {
      return LayoutUnit(value: containerSize.width)
    }

    if isEmbeddedThroughFrameContainingSVGDocument() {
      return containingBlock()!.availableLogicalWidth()
    }

    // Standalone SVG / SVG embedded via SVGImage (background-image/border-image/etc) / Inline SVG.
    var result = super.computeReplacedLogicalWidth(shouldComputePreferred: shouldComputePreferred)
    if svgSVGElement().hasIntrinsicWidth() {
      return result
    }

    // Percentage units are not scaled, Length(100, %) resolves to 100% of the unzoomed RenderView content size.
    // However for SVGs purposes we need to always include zoom in the RenderSVGRoot boundaries.
    result *= style().usedZoom()
    return result
  }

  override func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    // When we're embedded through SVGImage (border-image/background-image/<html:img>/...) we're forced to resize to a specific size.
    if !containerSize.isEmpty() {
      return LayoutUnit(value: containerSize.height)
    }

    if isEmbeddedThroughFrameContainingSVGDocument() {
      return containingBlock()!.availableLogicalHeight(heightType: .IncludeMarginBorderPadding)
    }

    // Standalone SVG / SVG embedded via SVGImage (background-image/border-image/etc) / Inline SVG.
    var result = super.computeReplacedLogicalHeight(estimatedUsedWidth: estimatedUsedWidth)
    if svgSVGElement().hasIntrinsicHeight() {
      return result
    }

    // Percentage units are not scaled, Length(100, %) resolves to 100% of the unzoomed RenderView content size.
    // However for SVGs purposes we need to always include zoom in the RenderSVGRoot boundaries.
    result *= style().usedZoom()
    return result
  }

  override func layout() {
    let _ = SetForScope(scopedVariable: &inLayout, newValue: true)
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    // Arbitrary affine transforms are incompatible with RenderLayoutState.
    let _ = LayoutStateDisabler(context: view().frameView().layoutContext())

    let repainter = LayoutRepainter(renderer: self)

    // Update layer transform before laying out children (SVG needs access to the transform matrices during layout for on-screen text font-size calculations).
    // Eventually re-update if the transform reference box, relevant for transform-origin, has changed during layout.
    //
    // FIXME: LBSE should not repeat the same mistake -- remove the on-screen text font-size hacks that predate the modern solutions to this.
    do {
      assert(!isLayoutSizeChanged)
      let _ = SetForScope(
        scopedVariable: &isLayoutSizeChanged, newValue: updateLayoutSizeIfNeeded())

      assert(!didTransformToRootUpdate)
      let transformUpdater = SVGLayerTransformUpdater(self)
      let _ = SetForScope(
        scopedVariable: &didTransformToRootUpdate,
        newValue: transformUpdater.layerTransformChanged())
      layoutChildren()
    }

    clearOverflow()
    if !shouldApplyViewportClip() {
      addVisualOverflow(rect: visualOverflowRectEquivalent())
    }
    addVisualEffectOverflow()

    invalidateBackgroundObscurationStatus()

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  private func layoutChildren() {
    var containerLayout = SVGContainerLayout(self)
    containerLayout.layoutChildren(selfNeedsLayout())

    let boundingBoxComputation = SVGBoundingBoxComputation(self)
    m_objectBoundingBox = boundingBoxComputation.computeDecoratedBoundingBox(
      SVGBoundingBoxComputation.objectBoundingBoxDecoration)
    strokeBoundingBox = nil

    let objectBoundingBoxDecorationWithoutTransformations = SVGBoundingBoxComputation
      .objectBoundingBoxDecoration.union(.IgnoreTransformations)
    objectBoundingBoxWithoutTransformations = boundingBoxComputation.computeDecoratedBoundingBox(
      objectBoundingBoxDecorationWithoutTransformations)

    containerLayout.positionChildrenRelativeToContainer()
  }

  // FIXME: Basically a copy of RenderBlock::paint() - ideally one would share this code.
  // However with LFC on the horizon that investment is useless, we should concentrate
  // on LFC/SVG integration once the LBSE is upstreamed.
  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // Don't paint, if the context explicitly disabled it.
    if paintInfo.context().paintingDisabled() && !paintInfo.context().detectingContentfulPaint() {
      return
    }

    // An empty viewport disables rendering.
    if borderBoxRect().isEmpty() {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    // Check if we need to do anything at all.
    // FIXME: Could eliminate the isDocumentElementRenderer() check if we fix background painting so that the RenderView
    // paints the root's background.
    if !isDocumentElementRenderer()
      && !paintInfo.paintBehavior.contains(.CompositedOverflowScrollContent)
    {
      var overflowBox = visualOverflowRect()
      flipForWritingMode(rect: &overflowBox)
      overflowBox.moveBy(offset: adjustedPaintOffset)
      if !overflowBox.intersects(other: paintInfo.rect) {
        return
      }
    }

    let pushedClip = pushContentsClip(paintInfo: &paintInfo, accumulatedOffset: adjustedPaintOffset)
    paintObject(paintInfo: &paintInfo, paintOffset: adjustedPaintOffset)
    if pushedClip {
      popContentsClip(
        paintInfo: &paintInfo, originalPhase: paintInfo.phase,
        accumulatedOffset: adjustedPaintOffset
      )
    }

    // Our scrollbar widgets paint exactly when we tell them to, so that they work properly with
    // z-index. We paint after we painted the background/border, so that the scrollbars will
    // sit above the background/border.
    if (paintInfo.phase == .BlockBackground || paintInfo.phase == .ChildBlockBackground)
      && hasNonVisibleOverflow() && layer() != nil && (layer()!.scrollableArea() != nil)
      && style().usedVisibility() == .Visible && paintInfo.shouldPaintWithinRoot(renderer: self)
      && !paintInfo.paintRootBackgroundOnly()
    {
      layer()!.scrollableArea()!.paintOverflowControls(
        context: paintInfo.context(), paintOffset: roundedIntPoint(point: adjustedPaintOffset),
        damageRect: snappedIntRect(rect: paintInfo.rect))
    }
  }

  override final func paintObject(
    paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if (paintInfo.phase == .BlockBackground || paintInfo.phase == .ChildBlockBackground)
      && style().usedVisibility() == .Visible
    {
      if hasVisibleBoxDecorations() {
        paintBoxDecorations(paintInfo: paintInfo, paintOffset: paintOffset)
      }
    }

    let adjustedPaintOffset = paintOffset + location()
    if paintInfo.phase == .Mask && style().usedVisibility() == .Visible {
      paintSVGMask(paintInfo, adjustedPaintOffset)
      return
    }

    if paintInfo.phase == .ClippingMask && style().usedVisibility() == .Visible {
      paintSVGClippingMask(paintInfo: paintInfo, objectBoundingBox: objectBoundingBox())
      return
    }

    if paintInfo.paintRootBackgroundOnly() {
      return
    }

    let context = paintInfo.context()
    if context.detectingContentfulPaint() {
      for current: RenderObjectWrapper in childrenOfType(parent: self) {
        if !current.isRenderSVGHiddenContainer() {
          context.setContentfulPaintDetected()
          return
        }
      }
      return
    }

    // Don't paint if we don't have kids, except if we have filters we should paint those.
    if firstChild() == nil {
      // FIXME: We should only call addRelevantUnpaintedObject() if there is no filter. Revisit this if we add filter support to LBSE.
      if paintInfo.phase == .Foreground {
        page().addRelevantUnpaintedObject(object: self, objectPaintRect: visualOverflowRect())
      }
      return
    }

    if paintInfo.phase == .BlockBackground {
      return
    }

    var scrolledOffset = paintOffset
    scrolledOffset.moveBy(offset: LayoutPointWrapper(point: -scrollPosition()))

    if paintInfo.phase != .SelfOutline {
      paintContents(paintInfo, scrolledOffset)
    }

    if (paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline) && hasOutline()
      && style().usedVisibility() == .Visible
    {
      paintOutline(
        paintInfo: paintInfo,
        paintRect: LayoutRectWrapper(location: adjustedPaintOffset, size: size()))
    }
  }

  private func paintContents(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper) {
    // We don't paint our own background, but we do let the kids paint their backgrounds.
    var paintInfoForChild = paintInfo.deepCopy()
    if paintInfo.phase == .ChildOutlines {
      paintInfoForChild.phase = .Outline
    } else if paintInfo.phase == .ChildBlockBackgrounds {
      paintInfoForChild.phase = .ChildBlockBackground
    }

    paintInfoForChild.updateSubtreePaintRootForChildren(renderer: self)
    for child: RenderElementWrapper in childrenOfType(parent: self) {
      if !child.hasSelfPaintingLayer() {
        child.paint(paintInfo: &paintInfoForChild, paintOffset: paintOffset)
      }
    }
  }

  override func updateLayerTransform() {
    super.updateLayerTransform()

    if !hasLayer() {
      return
    }

    // An empty viewBox disables the rendering -- dirty the visible descendant status!
    if svgSVGElement().hasViewBoxAttr() && svgSVGElement().hasEmptyViewBox() {  // TODO(asuhan): replace hasEmptyViewBox with general hasAttribute test
      layer()!.dirtyVisibleContentStatus()
    }
  }

  private func calculateIntrinsicSize() -> FloatSize {
    return FloatSize(
      width: floatValueForLength(
        length: svgSVGElement().intrinsicWidth(), maximumValue: LayoutUnit(value: 0)),
      height: floatValueForLength(
        length: svgSVGElement().intrinsicHeight(), maximumValue: LayoutUnit(value: 0)))
  }

  var inLayout = false
  var didTransformToRootUpdate = false
  var isLayoutSizeChanged = false

  let containerSize = IntSize()
  private var m_objectBoundingBox = FloatRectWrapper()
  private var objectBoundingBoxWithoutTransformations = FloatRectWrapper()
  private var strokeBoundingBox: FloatRectWrapper? = nil
}
