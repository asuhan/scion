/*
 * Copyright (C) 2009-2023 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// This acts as a cache of what we know about what is painting into this RenderLayerBacking.
struct PaintedContentsInfo {
  enum ContentsTypeDetermination {
    case Unknown
    case SimpleContainer
    case DirectlyCompositedImage
    case UnscaledBitmapOnly
    case Painted
  }

  init(inBacking: RenderLayerBacking) {
    backing = inBacking
  }

  mutating func paintsBoxDecorationsDetermination() -> RequestState {
    if boxDecorations != .Unknown {
      return boxDecorations
    }

    boxDecorations = backing.paintsBoxDecorations() ? .True : .False
    return boxDecorations
  }

  mutating func paintsBoxDecorations() -> Bool {
    let state = paintsBoxDecorationsDetermination()
    return state == .True || state == .Undetermined
  }

  mutating func paintsContentDetermination() -> RequestState {
    if content != .Unknown {
      return content
    }

    var contentRequest = RenderLayerWrapper.PaintedContentRequest()
    content = backing.paintsContent(request: &contentRequest) ? .True : .False

    return content
  }

  mutating func paintsContent() -> Bool {
    let state = paintsContentDetermination()
    return state == .True || state == .Undetermined
  }

  mutating func contentsTypeDetermination() -> ContentsTypeDetermination {
    if contentsType != .Unknown {
      return contentsType
    }

    if backing.isSimpleContainerCompositingLayer(contentsInfo: &self) {
      contentsType = .SimpleContainer
    } else if backing.isDirectlyCompositedImage() {
      contentsType = .DirectlyCompositedImage
    } else if backing.isUnscaledBitmapOnly() {
      contentsType = .UnscaledBitmapOnly
    } else {
      contentsType = .Painted
    }

    return contentsType
  }

  mutating func isSimpleContainer() -> Bool {
    return contentsTypeDetermination() == .SimpleContainer
  }

  mutating func isDirectlyCompositedImage() -> Bool {
    return contentsTypeDetermination() == .DirectlyCompositedImage
  }

  mutating func isUnscaledBitmapOnly() -> Bool {
    return contentsTypeDetermination() == .UnscaledBitmapOnly
  }

  let backing: RenderLayerBacking
  var boxDecorations: RequestState = .Unknown
  var content: RequestState = .Unknown

  private var contentsType: ContentsTypeDetermination = .Unknown
}

private func clearBackingSharingLayerProviders(
  sharingLayers: ListSet<RenderLayerWrapper, ObjectIdentifier>, providerLayer: RenderLayerWrapper
) {
  for layer in sharingLayers {
    if CPtrToInt(layer.backingProviderLayer?.p) == CPtrToInt(providerLayer.p) {
      layer.setBackingProviderLayer(backingProvider: nil)
    }
  }
}

private func computePageTiledBackingCoverage(layer: RenderLayerWrapper)
  -> TiledBackingWrapper.TileCoverage
{
  // If the page is non-visible, don't incur the cost of keeping extra tiles for scrolling.
  if !layer.page().isVisible() {
    return .CoverageForVisibleArea
  }

  let frameView = layer.renderer().view().frameView()

  var tileCoverage: TiledBackingWrapper.TileCoverage = .CoverageForVisibleArea
  let useMinimalTilesDuringLiveResize = frameView.inLiveResize()
  if frameView.speculativeTilingEnabled() && !useMinimalTilesDuringLiveResize {
    let clipsToExposedRect = (frameView.viewExposedRect() != nil)
    if frameView.horizontalScrollbarMode() != .AlwaysOff || clipsToExposedRect {
      tileCoverage |= .CoverageForHorizontalScrolling
    }

    if frameView.verticalScrollbarMode() != .AlwaysOff || clipsToExposedRect {
      tileCoverage |= .CoverageForVerticalScrolling
    }
  }
  return tileCoverage
}

private func computeOverflowTiledBackingCoverage(layer: RenderLayerWrapper)
  -> TiledBackingWrapper.TileCoverage
{
  // If the page is non-visible, don't incur the cost of keeping extra tiles for scrolling.
  if !layer.page().isVisible() {
    return .CoverageForVisibleArea
  }

  let frameView = layer.renderer().view().frameView()

  var tileCoverage: TiledBackingWrapper.TileCoverage = .CoverageForVisibleArea
  let useMinimalTilesDuringLiveResize = frameView.inLiveResize()
  if !useMinimalTilesDuringLiveResize {
    if let scrollableArea = layer.scrollableArea() {
      if scrollableArea.hasScrollableHorizontalOverflow() {
        tileCoverage |= .CoverageForHorizontalScrolling
      }

      if scrollableArea.hasScrollableVerticalOverflow() {
        tileCoverage |= .CoverageForVerticalScrolling
      }
    }
  }
  return tileCoverage
}

private func scrollContainerLayerBox(_ renderBox: RenderBoxWrapper) -> LayoutRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func clippingLayerBox(_ renderer: RenderLayerModelObjectWrapper) -> LayoutRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func overflowControlsHostLayerRect(_ renderBox: RenderBoxWrapper) -> LayoutRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func subpixelOffsetFromRendererChanged(
  _ oldSubpixelOffsetFromRenderer: LayoutSizeWrapper,
  _ newSubpixelOffsetFromRenderer: LayoutSizeWrapper, _ deviceScaleFactor: Float32
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func subpixelForLayerPainting(_ point: LayoutPointWrapper, _ pixelSnappingFactor: Float32)
  -> FloatSize
{
  var x = point.x
  var y = point.y
  x = LayoutUnit(
    value: x >= Int32(0)
      ? floorToDevicePixel(value: x, pixelSnappingFactor: pixelSnappingFactor)
      : ceilToDevicePixel(value: x, pixelSnappingFactor: pixelSnappingFactor))
  y = LayoutUnit(
    value: y >= Int32(0)
      ? floorToDevicePixel(value: y, pixelSnappingFactor: pixelSnappingFactor)
      : ceilToDevicePixel(value: y, pixelSnappingFactor: pixelSnappingFactor))
  return (point - LayoutPointWrapper(x: x, y: y)).FloatSize()
}

struct OffsetFromRenderer {
  // 1.2px - > { m_devicePixelOffset = 1px m_subpixelOffset = 0.2px }
  var devicePixelOffset = LayoutSizeWrapper()
  var subpixelOffset = LayoutSizeWrapper()
}

private func computeOffsetFromRenderer(_ offset: LayoutSizeWrapper, _ deviceScaleFactor: Float32)
  -> OffsetFromRenderer
{
  var offsetFromRenderer = OffsetFromRenderer()
  offsetFromRenderer.subpixelOffset = LayoutSizeWrapper(
    size: subpixelForLayerPainting(toLayoutPoint(size: offset), deviceScaleFactor))
  offsetFromRenderer.devicePixelOffset = offset - offsetFromRenderer.subpixelOffset
  return offsetFromRenderer
}

struct SnappedRectInfo {
  let snappedRect: LayoutRectWrapper
  let snapDelta: LayoutSizeWrapper
}

private func snappedGraphicsLayer(
  _ offset: LayoutSizeWrapper, _ size: LayoutSizeWrapper, _ renderer: RenderLayerModelObjectWrapper
) -> SnappedRectInfo {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

struct ComputedOffsets {
  init(
    renderLayer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?,
    localRect: LayoutRectWrapper, parentGraphicsLayerRect: LayoutRectWrapper,
    primaryGraphicsLayerRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fromParentGraphicsLayer() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fromPrimaryGraphicsLayer() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private func layerRendererStyleHas3DTransformOperation(_ layer: RenderLayerWrapper) -> Bool {
  var renderer = layer.renderer()
  if layer.isReflection() {
    renderer = renderer.parent() as! RenderLayerModelObjectWrapper
  }
  let style = renderer.style()
  return style.transform().has3DOperation()
    || (style.translate()?.is3DOperation() ?? false)
    || (style.scale()?.is3DOperation() ?? false)
    || (style.rotate()?.is3DOperation() ?? false)
}

// FIXME: Code is duplicated in RenderLayer. Also, we should probably not consider filters a box decoration here.
private func hasVisibleBoxDecorations(style: RenderStyleWrapper) -> Bool {
  return style.hasVisibleBorder() || style.hasBorderRadius() || style.hasOutline()
    || style.hasUsedAppearance() || style.boxShadow() != nil || style.hasFilter()
}

private func canDirectlyCompositeBackgroundBackgroundImage(renderer: RenderElementWrapper) -> Bool {
  let style = renderer.style()

  if !GraphicsLayer.supportsContentsTiling() {
    return false
  }

  let fillLayer = style.backgroundLayers()
  if fillLayer.next() != nil {
    return false
  }

  if !fillLayer.imagesAreLoaded(renderer: renderer) {
    return false
  }

  if fillLayer.attachment != .ScrollBackground {
    return false
  }

  // FIXME: Allow color+image compositing when it makes sense.
  // For now bailing out.
  if style.visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyBackgroundColor)
    .isVisible()
  {
    return false
  }

  // FIXME: support gradients with isGeneratedImage.
  let styleImage = fillLayer.image()!
  if !styleImage.hasCachedImage() {
    return false
  }

  let image = styleImage.cachedImage()!.image()!
  if !image.isBitmapImage() {
    return false
  }

  return true
}

private func hasPaintedBoxDecorationsOrBackgroundImage(renderer: RenderElementWrapper) -> Bool {
  let style = renderer.style()

  if hasVisibleBoxDecorations(style: style) {
    return true
  }

  if !style.hasBackgroundImage() {
    return false
  }

  return !canDirectlyCompositeBackgroundBackgroundImage(renderer: renderer)
}

private func hasPerspectiveOrPreserves3D(style: RenderStyleWrapper) -> Bool {
  return style.hasPerspective() || style.preserves3D()
}

private func supportsDirectlyCompositedBoxDecorations(renderer: RenderLayerModelObjectWrapper)
  -> Bool
{
  if renderer.hasClip() {
    return false
  }

  if hasPaintedBoxDecorationsOrBackgroundImage(renderer: renderer) {
    return false
  }

  let style = renderer.style()
  // FIXME: We can't create a directly composited background if this
  // layer will have children that intersect with the background layer.
  // A better solution might be to introduce a flattening layer if
  // we do direct box decoration composition.
  // https://bugs.webkit.org/show_bug.cgi?id=119461
  if hasPerspectiveOrPreserves3D(style: style) {
    return false
  }

  return true
}

private func isCompositedPlugin(renderer: RenderObjectWrapper) -> Bool {
  if let embeddedObject = renderer as? RenderEmbeddedObjectWrapper {
    return embeddedObject.requiresAcceleratedCompositing()
  }
  return false
}

// Returning true stops the traversal.
enum LayerTraversal {
  case Continue
  case Stop
}

@discardableResult
private func traverseVisibleNonCompositedDescendantLayers(
  parent: RenderLayerWrapper, layerFunc: (RenderLayerWrapper) -> LayerTraversal
) -> LayerTraversal {
  // FIXME: We shouldn't be called with a stale z-order lists. See bug 85512.
  parent.updateLayerListsIfNeeded()

  for childLayer in parent.normalFlowLayers() {
    if compositedWithOwnBackingStore(layer: childLayer) {
      continue
    }

    if layerFunc(childLayer) == .Stop {
      return .Stop
    }

    if traverseVisibleNonCompositedDescendantLayers(parent: childLayer, layerFunc: layerFunc)
      == .Stop
    {
      return .Stop
    }
  }

  if parent.isStackingContext() && !parent.hasVisibleDescendant {
    return .Continue
  }

  // Use the m_hasCompositingDescendant bit to optimize?
  for childLayer in parent.negativeZOrderLayers() {
    if compositedWithOwnBackingStore(layer: childLayer) {
      continue
    }

    if layerFunc(childLayer) == .Stop {
      return .Stop
    }

    if traverseVisibleNonCompositedDescendantLayers(parent: childLayer, layerFunc: layerFunc)
      == .Stop
    {
      return .Stop
    }
  }

  for childLayer in parent.positiveZOrderLayers() {
    if compositedWithOwnBackingStore(layer: childLayer) {
      continue
    }

    if layerFunc(childLayer) == .Stop {
      return .Stop
    }

    if traverseVisibleNonCompositedDescendantLayers(parent: childLayer, layerFunc: layerFunc)
      == .Stop
    {
      return .Stop
    }
  }

  return .Continue
}

private func intersectsWithAncestor(
  child: RenderLayerWrapper, ancestor: RenderLayerWrapper,
  ancestorCompositedBounds: LayoutRectWrapper
) -> Bool? {
  // If any layers between child and ancestor are transformed, then adjusting the offset is
  // insufficient to convert coordinates into ancestor's coordinate space.
  if !child.canUseOffsetFromAncestor(ancestor: ancestor) {
    return nil
  }

  let overlap = child.boundingBox(
    ancestorLayer: ancestor, offsetFromRoot: child.offsetFromAncestor(ancestorLayer: ancestor),
    flags: .UseFragmentBoxesExcludingCompositing)
  return overlap.intersects(other: ancestorCompositedBounds)
}

// RenderLayerBacking controls the compositing behavior for a single RenderLayer.
// It holds the various GraphicsLayers, and makes decisions about intra-layer rendering
// optimizations.
//
// There is one RenderLayerBacking for each RenderLayer that is composited.

final class RenderLayerBacking: GraphicsLayerClientWrapper {
  init(layer: RenderLayerWrapper) {
    super.init()
    owningLayer = layer

    if layer.isRenderViewLayer {
      isMainFrameRenderViewLayer = renderer().frame().isMainFrame()
      isRootFrameRenderViewLayer = renderer().frame().isRootFrame()
      isFrameLayerWithTiledBacking = renderer().page().chrome().client()
        .shouldUseTiledBackingForFrameView(frameView: renderer().view().frameView())
    }

    createPrimaryGraphicsLayer()

    if let tiledBacking = tiledBacking() {
      tiledBacking.setIsInWindow(isInWindow: renderer().page().isInWindow())

      if isFrameLayerWithTiledBacking {
        tiledBacking.setScrollingPerformanceTestingEnabled(
          flag: renderer().settings().scrollingPerformanceTestingEnabled())
        adjustTiledBackingCoverage()
      }
    }
  }

  // Do cleanup while layer->backing() is still valid.
  func willBeDestroyed() {
    assert(ObjectIdentifier(owningLayer!.backing!) == ObjectIdentifier(self))
    compositor().removeFromScrollCoordinatedLayers(layer: owningLayer!)

    clearBackingSharingLayers()
  }

  func setBackingSharingLayers(_ sharingLayers: ListSet<RenderLayerWrapper, ObjectIdentifier>) {
    var sharingLayersChanged = backingSharingLayers.computeSize() != sharingLayers.computeSize()
    // For layers that used to share and no longer do, and are not composited, recompute repaint rects.
    for oldSharingLayer in backingSharingLayers {
      // Layers that go from shared to composited have their repaint rects recomputed in RenderLayerCompositor::updateBacking().
      if !sharingLayers.contains(value: oldSharingLayer) {
        sharingLayersChanged = true
        if !oldSharingLayer.isComposited() {
          oldSharingLayer.computeRepaintRectsIncludingDescendants()
        }
      }
    }

    clearBackingSharingLayerProviders(
      sharingLayers: backingSharingLayers, providerLayer: owningLayer!)

    if sharingLayersChanged {
      if !sharingLayers.isEmptyIgnoringNullReferences() {
        setRequiresOwnBackingStore(true)
      }
      setContentsNeedDisplay()  // This could be optimized to only repaint rects for changed layers.
    }

    let oldSharingLayers = backingSharingLayers.deepCopy()
    backingSharingLayers = sharingLayers

    for layer in backingSharingLayers {
      layer.setBackingProviderLayer(backingProvider: owningLayer)
    }

    if sharingLayersChanged {
      // For layers that are newly sharing, recompute repaint rects.
      for currentSharingLayer in backingSharingLayers {
        if !oldSharingLayers.contains(value: currentSharingLayer) {
          currentSharingLayer.computeRepaintRectsIncludingDescendants()
        }
      }
    }
  }

  func hasBackingSharingLayers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeBackingSharingLayer(layer: RenderLayerWrapper) {
    layer.setBackingProviderLayer(backingProvider: nil)
    backingSharingLayers.remove(value: layer)
  }

  func clearBackingSharingLayers() {
    clearBackingSharingLayerProviders(
      sharingLayers: backingSharingLayers, providerLayer: owningLayer!)
    backingSharingLayers.clear()
  }

  // This can only update things that don't require up-to-date layout.
  func updateConfigurationAfterStyleChange() {
    updateMaskingLayer(hasMask: renderer().hasMask(), hasClipPath: renderer().hasClipPath())

    if owningLayer!.hasReflection() {
      if let backing = owningLayer!.reflectionLayer()!.backing {
        let reflectionLayer = backing.graphicsLayer()
        m_graphicsLayer!.setReplicatedByLayer(layer: reflectionLayer)
      }
    } else {
      m_graphicsLayer!.setReplicatedByLayer(layer: nil)
    }

    // FIXME: do we care if opacity is animating?
    let style = renderer().style()
    updateOpacity(style: style)
    updateFilters(style: style)

    updateBackdropFilters(style: style)
    updateBackdropRoot()
    updateBlendMode(style: style)
    updateContentsScalingFilters(style: style)
  }

  // Returns true if layer configuration changed.
  func updateConfiguration(_ compositingAncestor: RenderLayerWrapper?) -> Bool {
    assert(!owningLayer!.normalFlowListDirty)
    assert(!owningLayer!.zOrderListsDirty)
    assert(!renderer().view().needsLayout())

    var layerConfigChanged = false
    let compositor = compositor()

    if updateTransformFlatteningLayer(compositingAncestor) {
      layerConfigChanged = true
    }

    if updateViewportConstrainedAnchorLayer(
      compositor.isViewportConstrainedFixedOrStickyLayer(owningLayer!))
    {
      layerConfigChanged = true
    }

    setBackgroundLayerPaintsFixedRootBackground(
      compositor.needsFixedRootBackgroundLayer(owningLayer!))

    if updateBackgroundLayer(backgroundLayerPaintsFixedRootBackground || requiresBackgroundLayer) {
      layerConfigChanged = true
    }

    if updateForegroundLayer(compositor.needsContentsCompositingLayer(owningLayer!)) {
      layerConfigChanged = true
    }

    var needsDescendantsClippingLayer = false
    let usesCompositedScrolling = owningLayer!.hasCompositedScrollableOverflow()

    if usesCompositedScrolling {
      // If it's scrollable, it has to be a box.
      let renderBox = renderer() as! RenderBoxWrapper
      let borderShape = BorderShape.shapeForBorderRect(
        style: renderBox.style(), borderRect: renderBox.borderBoxRect())
      let contentsClippingRect = borderShape.deprecatedPixelSnappedInnerRoundedRect(
        deviceScaleFactor())
      needsDescendantsClippingLayer = contentsClippingRect.isRounded()
    } else {
      needsDescendantsClippingLayer = RenderLayerCompositorWrapper.clipsCompositingDescendants(
        owningLayer!)
    }

    if updateScrollingLayers(usesCompositedScrolling) {
      layerConfigChanged = true
    }

    if updateDescendantClippingLayer(needsDescendantsClippingLayer) {
      layerConfigChanged = true
    }

    assert(
      CPtrToInt(compositingAncestor?.p) == CPtrToInt(owningLayer!.ancestorCompositingLayer()?.p))
    if updateAncestorClipping(
      compositor.clippedByAncestor(owningLayer!, compositingAncestor), compositingAncestor)
    {
      layerConfigChanged = true
    }

    if updateOverflowControlsLayers(
      requiresHorizontalScrollbarLayer(), requiresVerticalScrollbarLayer(),
      requiresScrollCornerLayer())
    {
      layerConfigChanged = true
    }

    if layerConfigChanged {
      updateInternalHierarchy()
    }

    // RenderLayerCompositor::adjustOverflowScrollbarContainerLayers() may have reparented the overflowControlsContainer
    // in an earlier update, so always put it back here. We don't yet know if it will get reparented again.
    if overflowControlsContainer != nil
      && !optEq(overflowControlsContainer!.parent(), m_graphicsLayer)
    {
      m_graphicsLayer!.addChild(childLayer: overflowControlsContainer!)
      // Ensure that we fix up the position of m_overflowControlsContainer.
      owningLayer!.setNeedsCompositingGeometryUpdate()
    }

    // FIXME: Overlow controls need to be above the flattening layer?
    if let flatteningLayer = tileCacheFlatteningLayer(),
      layerConfigChanged || !optEq(flatteningLayer.parent(), m_graphicsLayer)
    {
      // FIXME: m_graphicsLayer children are clobbered in RenderLayerCompositor::updateBackingAndHierarchy(); this probably doesn't work.
      m_graphicsLayer!.addChild(childLayer: flatteningLayer)
    }

    if updateMaskingLayer(hasMask: renderer().hasMask(), hasClipPath: renderer().hasClipPath()) {
      layerConfigChanged = true
    }

    if owningLayer!.hasReflection() {
      if owningLayer!.reflectionLayer()!.backing != nil {
        let reflectionLayer = owningLayer!.reflectionLayer()!.backing!.graphicsLayer()
        m_graphicsLayer!.setReplicatedByLayer(layer: reflectionLayer)
      }
    } else {
      m_graphicsLayer!.setReplicatedByLayer(layer: nil)
    }

    var contentsInfo = PaintedContentsInfo(inBacking: self)

    // Requires layout.
    if !owningLayer!.isRenderViewLayer {
      updateDirectlyCompositedBoxDecorations(contentsInfo)
    } else {
      updateRootLayerConfiguration()
    }

    // Requires layout.
    if contentsInfo.isDirectlyCompositedImage() {
      updateImageContents(contentsInfo)
    }

    let unscaledBitmap = contentsInfo.isUnscaledBitmapOnly()
    if unscaledBitmap == m_graphicsLayer!.appliesDeviceScale() {
      m_graphicsLayer!.setAppliesDeviceScale(!unscaledBitmap)
      layerConfigChanged = true
    }

    let shouldPaintUsingCompositeCopy =
      unscaledBitmap && (renderer() is RenderHTMLCanvasWrapper) && owningLayer!.hasVisibleContent
    if shouldPaintUsingCompositeCopy != m_shouldPaintUsingCompositeCopy {
      m_shouldPaintUsingCompositeCopy = shouldPaintUsingCompositeCopy
      m_graphicsLayer!.setShouldPaintUsingCompositeCopy(shouldPaintUsingCompositeCopy)
      layerConfigChanged = true
    }

    let attachPluginLayer = { [self] (_ rendererEmbeddedObject: RenderEmbeddedObjectWrapper) in
      guard let pluginViewBase = rendererEmbeddedObject.widget() as? PluginViewBase else { return }

      switch pluginViewBase.layerHostingStrategy() {
      case .None:
        break
      case .PlatformLayer:
        m_graphicsLayer!.setContentsToPlatformLayer(pluginViewBase.platformLayer(), .Plugin)
      case .GraphicsLayer:
        // layer is parented in RenderLayerCompositor::updateBackingAndHierarchy().
        break
      }
    }

    if RenderLayerCompositorWrapper.isCompositedPlugin(renderer: renderer()) {
      attachPluginLayer(renderer() as! RenderEmbeddedObjectWrapper)
    } else if let remoteFrame = (renderer() as? RenderWidgetWrapper)?.remoteFrame(),
      let contextIdentifier = remoteFrame.layerHostingContextIdentifier()
    {
      m_graphicsLayer!.setContentsToPlatformLayerHost(contextIdentifier)
    } else if shouldSetContentsDisplayDelegate() {
      let canvas = renderer().element() as! HTMLCanvasElementWrapper
      if let context = canvas.renderingContext() {
        context.setContentsToLayer(m_graphicsLayer!)
      }

      layerConfigChanged = true
    }

    // FIXME: Why do we do this twice?
    if let widget = renderer() as? RenderWidgetWrapper,
      compositor.attachWidgetContentLayersIfNecessary(widget).layerHierarchyChanged
    {
      owningLayer!.setNeedsCompositingGeometryUpdate()
      layerConfigChanged = true
    }

    if RenderLayerCompositorWrapper.hasCompositedWidgetContents(renderer()) {
      m_graphicsLayer!.setContentsRectClipsDescendants(true)
      updateContentsRects()
    }

    if updateBackdropRoot() {
      layerConfigChanged = true
    }

    if layerConfigChanged {
      updatePaintingPhases()
    }

    return layerConfigChanged
  }

  // Update graphics layer position and bounds.
  func updateGeometry(_ compositedAncestor: RenderLayerWrapper?) {
    assert(!owningLayer!.normalFlowListDirty)
    assert(!owningLayer!.zOrderListsDirty)
    assert(!owningLayer!.descendantDependentFlagsAreDirty())
    assert(!renderer().view().needsLayout())

    let style = renderer().style()
    let deviceScaleFactor = deviceScaleFactor()

    var isRunningAcceleratedTransformAnimation = false
    if let styleable = StyleableWrapper.fromRenderer(renderer()) {
      isRunningAcceleratedTransformAnimation = styleable.isRunningAcceleratedTransformAnimation()
    }

    updateTransform(style: style)
    updateOpacity(style: style)
    updateFilters(style: style)
    updateBackdropFilters(style: style)
    updateBackdropRoot()
    updateBlendMode(style: style)
    updateContentsScalingFilters(style: style)

    assert(optEq(compositedAncestor, owningLayer!.ancestorCompositingLayer()))
    var parentGraphicsLayerRect = computeParentGraphicsLayerRect(compositedAncestor)

    // If our content is being used in a view-transition, then all positioning is handled using a synthesized 'transform' property on the wrapping
    // ::view-transition-new element. Set the parent graphics layer rect to that of the pseudo, adjusted into coordinates of the parent layer.
    if renderer().effectiveCapturedInViewTransition() && renderer().element() != nil,
      let activeViewTransition = renderer().document().activeViewTransition(),
      let viewTransitionCapture = activeViewTransition.viewTransitionNewPseudoForCapturedElement(
        renderer: renderer())
    {
      let computedOffsets = ComputedOffsets(
        renderLayer: owningLayer!, compositingAncestor: compositedAncestor,
        localRect: viewTransitionCapture.captureOverflowRect(),
        parentGraphicsLayerRect: LayoutRectWrapper(), primaryGraphicsLayerRect: LayoutRectWrapper())
      parentGraphicsLayerRect = LayoutRectWrapper(
        location: LayoutPointWrapper(
          x: computedOffsets.fromParentGraphicsLayer().width(),
          y: computedOffsets.fromParentGraphicsLayer().height()),
        size: viewTransitionCapture.captureOverflowRect().size())
    }

    if ancestorClippingStack != nil {
      updateClippingStackLayerGeometry(
        ancestorClippingStack!, compositedAncestor, &parentGraphicsLayerRect)
    }

    let primaryGraphicsLayerRect = computePrimaryGraphicsLayerRect(
      compositedAncestor, parentGraphicsLayerRect)

    let compositedBoundsOffset = ComputedOffsets(
      renderLayer: owningLayer!, compositingAncestor: compositedAncestor,
      localRect: compositedBounds(), parentGraphicsLayerRect: parentGraphicsLayerRect,
      primaryGraphicsLayerRect: primaryGraphicsLayerRect)
    let rendererOffset = ComputedOffsets(
      renderLayer: owningLayer!, compositingAncestor: compositedAncestor,
      localRect: LayoutRectWrapper(), parentGraphicsLayerRect: parentGraphicsLayerRect,
      primaryGraphicsLayerRect: primaryGraphicsLayerRect)

    compositedBoundsOffsetFromGraphicsLayer = compositedBoundsOffset.fromPrimaryGraphicsLayer()

    var primaryLayerPosition = primaryGraphicsLayerRect.location()

    // FIXME: reflections should force transform-style to be flat in the style: https://bugs.webkit.org/show_bug.cgi?id=106959
    let preserves3D = style.preserves3D() && !renderer().hasReflection()

    if viewportAnchorLayer != nil {
      viewportAnchorLayer!.setPosition(p: primaryLayerPosition.FloatPoint())
      primaryLayerPosition = LayoutPointWrapper()
    }

    if contentsContainmentLayer != nil {
      contentsContainmentLayer!.setPreserves3D(preserves3D)
      contentsContainmentLayer!.setPosition(p: primaryLayerPosition.FloatPoint())
      primaryLayerPosition = LayoutPointWrapper()
      // Use the same size as m_graphicsLayer so transforms behave correctly.
      contentsContainmentLayer!.setSize(size: primaryGraphicsLayerRect.size().FloatSize())
    }

    let computeAnimationExtent = { [self] () -> FloatRectWrapper? in
      var animatedBounds = LayoutRectWrapper()
      if isRunningAcceleratedTransformAnimation
        && owningLayer!.getOverlapBoundsIncludingChildrenAccountingForTransformAnimations(
          &animatedBounds, additionalFlags: .IncludeCompositedDescendants)
      {
        return animatedBounds.FloatRect()
      }
      return nil
    }
    m_graphicsLayer!.setAnimationExtent(computeAnimationExtent())
    m_graphicsLayer!.setPreserves3D(preserves3D)
    m_graphicsLayer!.setBackfaceVisibility(style.backfaceVisibility() == .Visible)

    m_graphicsLayer!.setPosition(p: primaryLayerPosition.FloatPoint())
    m_graphicsLayer!.setSize(size: primaryGraphicsLayerRect.size().FloatSize())

    // Compute renderer offset from primary graphics layer. Note that primaryGraphicsLayerRect is in parentGraphicsLayer's coordinate system which is not necessarily
    // the same as the ancestor graphics layer.
    var primaryGraphicsLayerOffsetFromRenderer = OffsetFromRenderer()
    let oldSubpixelOffsetFromRenderer = subpixelOffsetFromRenderer
    primaryGraphicsLayerOffsetFromRenderer = computeOffsetFromRenderer(
      -rendererOffset.fromPrimaryGraphicsLayer(), deviceScaleFactor)
    subpixelOffsetFromRenderer = primaryGraphicsLayerOffsetFromRenderer.subpixelOffset
    hasSubpixelRounding =
      !subpixelOffsetFromRenderer.isZero()
      || compositedBounds().size() != primaryGraphicsLayerRect.size()

    if primaryGraphicsLayerOffsetFromRenderer.devicePixelOffset.FloatSize()
      != m_graphicsLayer!.offsetFromRenderer()
    {
      m_graphicsLayer!.setOffsetFromRenderer(
        primaryGraphicsLayerOffsetFromRenderer.devicePixelOffset.FloatSize())
    }

    // If we have a layer that clips children, position it.
    var clippingBox = LayoutRectWrapper()
    if let clipLayer = clippingLayer() {
      // clipLayer is the m_childContainmentLayer.
      clippingBox = clippingLayerBox(renderer())
      // Clipping layer is parented in the primary graphics layer.
      let clipBoxOffsetFromGraphicsLayer =
        toLayoutSize(point: clippingBox.location()) + rendererOffset.fromPrimaryGraphicsLayer()
      let snappedClippingGraphicsLayer = snappedGraphicsLayer(
        clipBoxOffsetFromGraphicsLayer, clippingBox.size(), renderer())
      clipLayer.setPosition(p: snappedClippingGraphicsLayer.snappedRect.location().FloatPoint())
      clipLayer.setSize(size: snappedClippingGraphicsLayer.snappedRect.size().FloatSize())
      clipLayer.setOffsetFromRenderer(
        toLayoutSize(point: clippingBox.location() - snappedClippingGraphicsLayer.snapDelta)
          .FloatSize())

      let computeMasksToBoundsRect = { [self] () in
        if renderer().style().clipPath() != nil || renderer().style().hasBorderRadius() {
          let borderShape = BorderShape.shapeForBorderRect(
            style: renderer().style(), borderRect: owningLayer!.rendererBorderBoxRect())
          var contentsClippingRect = borderShape.deprecatedPixelSnappedInnerRoundedRect(
            deviceScaleFactor)
          contentsClippingRect.move(
            size: LayoutSizeWrapper(size: -clipLayer.offsetFromRenderer()).FloatSize())
          return contentsClippingRect
        }

        return FloatRoundedRect(
          rect: FloatRectWrapper(
            location: FloatPoint(),
            size: snappedClippingGraphicsLayer.snappedRect.size().FloatSize()))
      }

      clipLayer.setContentsClippingRect(computeMasksToBoundsRect())
    }

    if maskLayer != nil {
      updateMaskingLayerGeometry()
    }

    updateChildrenTransformAndAnchorPoint(
      primaryGraphicsLayerRect, rendererOffset.fromParentGraphicsLayer())

    if owningLayer!.reflectionLayer() != nil && owningLayer!.reflectionLayer()!.isComposited() {
      let reflectionBacking = owningLayer!.reflectionLayer()!.backing!
      reflectionBacking.updateGeometry(owningLayer)

      // The reflection layer has the bounds of m_owningLayer.reflectionLayer(),
      // but the reflected layer is the bounds of this layer, so we need to position it appropriately.
      let layerBounds = compositedBounds().FloatRect()
      let reflectionLayerBounds = reflectionBacking.compositedBounds().FloatRect()
      reflectionBacking.graphicsLayer()!.setReplicatedLayerPosition(
        FloatPoint(layerBounds.location() - reflectionLayerBounds.location()))
    }

    if scrollContainerLayer != nil {
      assert(scrolledContentsLayer != nil)
      let scrollContainerBox = scrollContainerLayerBox(renderer() as! RenderBoxWrapper)
      let parentLayerBounds = clippingLayer() != nil ? scrollContainerBox : compositedBounds()

      // FIXME: need to do some pixel snapping here.
      scrollContainerLayer!.setPosition(
        p: FloatPoint((scrollContainerBox.location() - parentLayerBounds.location()).FloatSize()))
      scrollContainerLayer!.setSize(
        size: FloatSize(
          size: roundedIntSize(
            s: LayoutSizeWrapper(
              width: scrollContainerBox.width(), height: scrollContainerBox.height()))))

      let scrollableArea = owningLayer!.scrollableArea()!

      let scrollOffset = scrollableArea.scrollOffset()
      updateScrollOffset(scrollOffset)

      let oldScrollingLayerOffset = scrollContainerLayer!.offsetFromRenderer()
      scrollContainerLayer!.setOffsetFromRenderer(
        toFloatSize(a: scrollContainerBox.location().FloatPoint()))

      let paddingBoxOffsetChanged =
        oldScrollingLayerOffset != scrollContainerLayer!.offsetFromRenderer()

      let scrollSize = IntSize(
        width: scrollableArea.scrollWidth(), height: scrollableArea.scrollHeight())
      if FloatSize(size: scrollSize) != scrolledContentsLayer!.size() || paddingBoxOffsetChanged {
        scrolledContentsLayer!.setNeedsDisplay()
      }

      scrolledContentsLayer!.setSize(size: FloatSize(size: scrollSize))
      scrolledContentsLayer!.setScrollOffset(scrollOffset, .DontSetNeedsDisplay)
      scrolledContentsLayer!.setOffsetFromRenderer(
        toLayoutSize(point: scrollContainerBox.location()).FloatSize(), .DontSetNeedsDisplay)

      adjustTiledBackingCoverage()
    }

    if overflowControlsContainer != nil {
      let overflowControlsBox = overflowControlsHostLayerRect(renderer() as! RenderBoxWrapper)
      let boxOffsetFromGraphicsLayer =
        toLayoutSize(point: overflowControlsBox.location())
        + rendererOffset.fromPrimaryGraphicsLayer()
      let snappedBoxInfo = snappedGraphicsLayer(
        boxOffsetFromGraphicsLayer, overflowControlsBox.size(), renderer())

      overflowControlsContainer!.setPosition(p: snappedBoxInfo.snappedRect.location().FloatPoint())
      overflowControlsContainer!.setSize(size: snappedBoxInfo.snappedRect.size().FloatSize())
      overflowControlsContainer!.setMasksToBounds(b: true)
    }

    if foregroundLayer != nil {
      var foregroundSize = FloatSize()
      var foregroundOffset = FloatSize()
      var needsDisplayOnOffsetChange: GraphicsLayer.ShouldSetNeedsDisplay = .SetNeedsDisplay
      if scrolledContentsLayer != nil {
        foregroundSize = scrolledContentsLayer!.size()
        foregroundOffset =
          scrolledContentsLayer!.offsetFromRenderer()
          - toLayoutSize(point: LayoutPointWrapper(point: scrolledContentsLayer!.scrollOffset()))
          .FloatSize()
        needsDisplayOnOffsetChange = .DontSetNeedsDisplay
      } else if hasClippingLayer() {
        // If we have a clipping layer (which clips descendants), then the foreground layer is a child of it,
        // so that it gets correctly sorted with children. In that case, position relative to the clipping layer.
        foregroundSize = clippingBox.size().FloatSize()
        foregroundOffset = toFloatSize(a: clippingBox.location().FloatPoint())
      } else {
        foregroundSize = primaryGraphicsLayerRect.size().FloatSize()
        foregroundOffset = m_graphicsLayer!.offsetFromRenderer()
      }

      foregroundLayer!.setPosition(p: FloatPoint())
      foregroundLayer!.setSize(size: foregroundSize)
      foregroundLayer!.setOffsetFromRenderer(foregroundOffset, needsDisplayOnOffsetChange)
    }

    if backgroundLayer != nil {
      var backgroundPosition = FloatPoint()
      var backgroundSize = primaryGraphicsLayerRect.size().FloatSize()
      if backgroundLayerPaintsFixedRootBackground {
        let frameView = renderer().view().frameView()
        backgroundPosition = frameView.scrollPositionForFixedPosition().FloatPoint()
        backgroundSize = FloatSize(size: frameView.layoutSize())
      } else {
        let boundingBox = renderer().objectBoundingBox()
        backgroundPosition = boundingBox.location()
        backgroundSize = boundingBox.size()
      }
      backgroundLayer!.setPosition(p: backgroundPosition)
      backgroundLayer!.setSize(size: backgroundSize)
      backgroundLayer!.setOffsetFromRenderer(m_graphicsLayer!.offsetFromRenderer())
    }

    // If this layer was created just for clipping or to apply perspective, it doesn't need its own backing store.
    let ancestorCompositedBounds =
      compositedAncestor?.backing!.compositedBounds() ?? LayoutRectWrapper()
    setRequiresOwnBackingStore(
      compositor().requiresOwnBackingStore(
        owningLayer!, compositedAncestor,
        LayoutRectWrapper(
          location: toLayoutPoint(size: compositedBoundsOffset.fromParentGraphicsLayer()),
          size: compositedBounds().size()
        ), ancestorCompositedBounds))
    updateBackdropFiltersGeometry()
    updateAfterWidgetResize()

    positionOverflowControlsLayers()

    if subpixelOffsetFromRendererChanged(
      oldSubpixelOffsetFromRenderer, subpixelOffsetFromRenderer, deviceScaleFactor)
      && canIssueSetNeedsDisplay()
    {
      setContentsNeedDisplay()
    }
  }

  // Update state the requires that descendant layers have been updated.
  func updateAfterDescendants() {
    // FIXME: this potentially duplicates work we did in updateConfiguration().
    var contentsInfo = PaintedContentsInfo(inBacking: self)

    if !owningLayer!.isRenderViewLayer {
      updateDirectlyCompositedBoxDecorations(contentsInfo)
      if m_graphicsLayer!.usesContentsLayer() {
        resetContentsRect()
      }
    }

    updateDrawsContent(contentsInfo: &contentsInfo)

    if !isMainFrameRenderViewLayer && !isFrameLayerWithTiledBacking && !requiresBackgroundLayer {
      // For non-root layers, background is always painted by the primary graphics layer.
      assert(backgroundLayer == nil)
      m_graphicsLayer!.setContentsOpaque(
        b: !hasSubpixelRounding
          && owningLayer!.backgroundIsKnownToBeOpaqueInRect(compositedBounds()))
    }

    if layerRendererStyleHas3DTransformOperation(owningLayer!)
      || owningLayer!.hasCompositedScrollableOverflow()
    {
      m_graphicsLayer!.markDamageRectsUnreliable()
    }

    m_graphicsLayer!.setContentsVisible(
      owningLayer!.hasVisibleContent || hasVisibleNonCompositedDescendants())
    if scrollContainerLayer != nil {
      scrollContainerLayer!.setContentsVisible(renderer().style().usedVisibility() == .Visible)

      let userInteractive = renderer().visibleToHitTesting()
      scrollContainerLayer!.setUserInteractionEnabled(userInteractive)
      layerForHorizontalScrollbar?.setUserInteractionEnabled(userInteractive)
      layerForVerticalScrollbar?.setUserInteractionEnabled(userInteractive)
      layerForScrollCorner?.setUserInteractionEnabled(userInteractive)
    }
  }

  // Update contents and clipping structure.
  func updateDrawsContent() {
    var contentsInfo = PaintedContentsInfo(inBacking: self)
    updateDrawsContent(contentsInfo: &contentsInfo)
  }

  func graphicsLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Layer to clip children
  func hasClippingLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clippingLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAncestorClippingLayers() -> Bool { return ancestorClippingStack != nil }

  func ensureOverflowControlsHostLayerAncestorClippingStack(compositedAncestor: RenderLayerWrapper)
  {
    let scrollingCoordinator = owningLayer!.page().scrollingCoordinator()
    let clippingData = ancestorClippingStack!.compositedClipData()

    if overflowControlsHostLayerAncestorClippingStack != nil {
      overflowControlsHostLayerAncestorClippingStack!.updateWithClipData(
        scrollingCoordinator, clippingData)
    } else {
      overflowControlsHostLayerAncestorClippingStack = LayerAncestorClippingStack(clippingData)
    }

    ensureClippingStackLayers(overflowControlsHostLayerAncestorClippingStack!)

    var parentGraphicsLayerRect = computeParentGraphicsLayerRect(compositedAncestor)
    updateClippingStackLayerGeometry(
      overflowControlsHostLayerAncestorClippingStack!, compositedAncestor, &parentGraphicsLayerRect)

    connectClippingStackLayers(overflowControlsHostLayerAncestorClippingStack!)
  }

  func hasScrollingLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func detachFromScrollingCoordinator(roles: ScrollCoordinationRole) {
    if !scrollingNodeID.bool() && ancestorClippingStack != nil && !frameHostingNodeID.bool()
      && !pluginHostingNodeID.bool() && !viewportConstrainedNodeID.bool()
      && !positioningNodeID.bool()
    {
      return
    }

    let scrollingCoordinator = owningLayer!.page().scrollingCoordinator()
    if scrollingCoordinator == nil {
      return
    }

    if roles.contains(.Scrolling) && scrollingNodeID.bool() {
      print("Compositing: Detaching Scrolling node \(scrollingNodeID)")
      scrollingCoordinator!.unparentChildrenAndDestroyNode(nodeID: scrollingNodeID)
      scrollingNodeID = ScrollingNodeIDWrapper()
    }

    if roles.contains(.ScrollingProxy) && ancestorClippingStack != nil {
      ancestorClippingStack!.detachFromScrollingCoordinator(
        scrollingCoordinator: scrollingCoordinator!)
      print("Compositing: Detaching nodes in ancestor clipping stack")
    }

    if roles.contains(.FrameHosting) && frameHostingNodeID.bool() {
      print("Compositing: Detaching FrameHosting node \(frameHostingNodeID)")
      scrollingCoordinator!.unparentChildrenAndDestroyNode(nodeID: frameHostingNodeID)
      frameHostingNodeID = ScrollingNodeIDWrapper()
    }

    if roles.contains(.PluginHosting) && pluginHostingNodeID.bool() {
      print("Compositing: Detaching PluginHosting node \(pluginHostingNodeID)")
      scrollingCoordinator!.unparentChildrenAndDestroyNode(nodeID: pluginHostingNodeID)
      pluginHostingNodeID = ScrollingNodeIDWrapper()
    }

    if roles.contains(.ViewportConstrained) && viewportConstrainedNodeID.bool() {
      print("Compositing: Detaching ViewportConstrained node \(viewportConstrainedNodeID)")
      scrollingCoordinator!.unparentChildrenAndDestroyNode(nodeID: viewportConstrainedNodeID)
      viewportConstrainedNodeID = ScrollingNodeIDWrapper()
    }

    if roles.contains(.Positioning) && positioningNodeID.bool() {
      print("Compositing: Detaching Positioned node \(positioningNodeID)")
      scrollingCoordinator!.unparentChildrenAndDestroyNode(nodeID: positioningNodeID)
      positioningNodeID = ScrollingNodeIDWrapper()
    }
  }

  func scrollingNodeIDForRole(role: ScrollCoordinationRole) -> ScrollingNodeIDWrapper {
    switch role {
    case .Scrolling:
      return scrollingNodeID
    case .ScrollingProxy:
      // These nodeIDs are stored in m_ancestorClippingStack.
      fatalError("Not reached")
    case .FrameHosting:
      return frameHostingNodeID
    case .PluginHosting:
      return pluginHostingNodeID
    case .ViewportConstrained:
      return viewportConstrainedNodeID
    case .Positioning:
      return positioningNodeID
    default:
      return ScrollingNodeIDWrapper()
    }
  }

  func setScrollingNodeIDForRole(_ nodeID: ScrollingNodeIDWrapper, _ role: ScrollCoordinationRole) {
    switch role {
    case .Scrolling:
      scrollingNodeID = nodeID
    case .ScrollingProxy:
      // These nodeIDs are stored in ancestorClippingStack.
      fatalError("Not reached")
    case .FrameHosting:
      frameHostingNodeID = nodeID
    case .PluginHosting:
      pluginHostingNodeID = nodeID
    case .ViewportConstrained:
      viewportConstrainedNodeID = nodeID
    case .Positioning:
      positioningNodeID = nodeID
    default:
      fatalError("Not reached")
    }
  }

  func hasMaskLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parentForSublayers() -> GraphicsLayer {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func childForSuperlayers() -> GraphicsLayer {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func childForSuperlayersExcludingViewTransitions() -> GraphicsLayer {
    if transformFlatteningLayer != nil {
      return transformFlatteningLayer!
    }

    if ancestorClippingStack != nil {
      return ancestorClippingStack!.firstLayer()!
    }

    if viewportAnchorLayer != nil {
      return viewportAnchorLayer!
    }

    if contentsContainmentLayer != nil {
      return contentsContainmentLayer!
    }

    return graphicsLayer()!
  }

  // RenderLayers with backing normally short-circuit paintLayer() because
  // their content is rendered via callbacks from GraphicsLayer. However, the document
  // layer is special, because it has a GraphicsLayer to act as a container for the GraphicsLayers
  // for descendants, but its contents usually render into the window (in which case this returns true).
  // This returns false for other layers, and when the document layer actually needs to paint into its backing store
  // for some reason.
  func paintsIntoWindow() -> Bool {
    if isFrameLayerWithTiledBacking {
      return false
    }

    if owningLayer!.isRenderViewLayer {
      return compositor().rootLayerAttachment() != .RootLayerAttachedViaEnclosingFrame
    }

    return false
  }

  // Returns true for a composited layer that has no backing store of its own, so
  // paints into some ancestor layer.
  func paintsIntoCompositedAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setRequiresOwnBackingStore(_ requiresOwnBacking: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentsNeedDisplay(_ shouldClip: GraphicsLayer.ShouldClipToLayer = .ClipToLayer) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // r is in the coordinate space of the layer's render object
  func setContentsNeedDisplayInRect(
    _ r: LayoutRectWrapper, _ shouldClip: GraphicsLayer.ShouldClipToLayer = .ClipToLayer
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func compositedBounds() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true if changed.
  @discardableResult
  func updateCompositedBounds() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateAllowsBackingStoreDetaching(absoluteBounds: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateAfterWidgetResize() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func positionOverflowControlsLayers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func tiledBacking() -> TiledBackingWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustTiledBackingCoverage() {
    if isFrameLayerWithTiledBacking {
      let tileCoverage = computePageTiledBackingCoverage(layer: owningLayer!)
      if let tiledBacking = tiledBacking() {
        tiledBacking.setTileCoverage(coverage: tileCoverage)
      }
    }

    if owningLayer!.hasCompositedScrollableOverflow() && scrolledContentsLayer != nil {
      let tileCoverage = computeOverflowTiledBackingCoverage(layer: owningLayer!)
      scrolledContentsLayer!.setTileCoverage(coverage: tileCoverage)
    }
  }

  func updateDebugIndicators(showBorder: Bool, showRepaintCounter: Bool) {
    m_graphicsLayer!.setShowDebugBorder(show: showBorder)
    m_graphicsLayer!.setShowRepaintCounter(show: showRepaintCounter)

    // m_viewportAnchorLayer can't show layer borders becuase it's a structural layer.

    if ancestorClippingStack != nil {
      for entry in ancestorClippingStack!.stack {
        entry.clippingLayer!.setShowDebugBorder(show: showBorder)
      }
    }

    if foregroundLayer != nil {
      foregroundLayer!.setShowDebugBorder(show: showBorder)
      foregroundLayer!.setShowRepaintCounter(show: showRepaintCounter)
    }

    if contentsContainmentLayer != nil {
      contentsContainmentLayer!.setShowDebugBorder(show: showBorder)
    }

    if childContainmentLayer != nil {
      childContainmentLayer!.setShowDebugBorder(show: showBorder)
    }

    if backgroundLayer != nil {
      backgroundLayer!.setShowDebugBorder(show: showBorder)
      backgroundLayer!.setShowRepaintCounter(show: showRepaintCounter)
    }

    if maskLayer != nil {
      maskLayer!.setShowDebugBorder(show: showBorder)
      maskLayer!.setShowRepaintCounter(show: showRepaintCounter)
    }

    if layerForHorizontalScrollbar != nil {
      layerForHorizontalScrollbar!.setShowDebugBorder(show: showBorder)
    }

    if layerForVerticalScrollbar != nil {
      layerForVerticalScrollbar!.setShowDebugBorder(show: showBorder)
    }

    if layerForScrollCorner != nil {
      layerForScrollCorner!.setShowDebugBorder(show: showBorder)
    }

    if scrollContainerLayer != nil {
      scrollContainerLayer!.setShowDebugBorder(show: showBorder)
    }

    if scrolledContentsLayer != nil {
      scrolledContentsLayer!.setShowDebugBorder(show: showBorder)
      scrolledContentsLayer!.setShowRepaintCounter(show: showRepaintCounter)
    }

    if overflowControlsContainer != nil {
      overflowControlsContainer!.setShowDebugBorder(show: showBorder)
    }
  }

  override func deviceScaleFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func pageScaleFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentsBox() -> LayoutRectWrapper {
    let renderBox = renderer() as? RenderBoxWrapper
    if renderBox == nil {
      return LayoutRectWrapper()
    }

    var contentsRect = LayoutRectWrapper()

    if let renderReplaced = renderBox as? RenderReplacedWrapper,
      !(renderReplaced is RenderWidgetWrapper)
    {
      contentsRect = renderReplaced.replacedContentRect()
    } else {
      contentsRect = renderBox!.contentBoxRect()
    }

    contentsRect.move(size: contentOffsetInCompositingLayer())
    return contentsRect
  }

  func layerForContents() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustOverflowControlsPositionRelativeToAncestor(
    _ ancestorLayer: RenderLayerWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canCompositeFilters() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func createPrimaryGraphicsLayer() {
    let layerName = owningLayer!.name()
    m_graphicsLayer = createGraphicsLayer(
      name: layerName, layerType: isFrameLayerWithTiledBacking ? .PageTiledBacking : .Normal)

    if isFrameLayerWithTiledBacking {
      childContainmentLayer = createGraphicsLayer(name: "Page TiledBacking containment")
      m_graphicsLayer!.addChild(childLayer: childContainmentLayer!)
    }

    if isMainFrameRenderViewLayer {
      m_graphicsLayer!.setContentsOpaque(b: !compositor().viewHasTransparentBackground())
    }
    // Page scale is applied above the RenderView on iOS.
    if isRootFrameRenderViewLayer {
      m_graphicsLayer!.setAppliesPageScale()
    }

    let style = renderer().style()
    updateOpacity(style: style)
    updateTransform(style: style)
    updateFilters(style: style)
    updateBackdropFilters(style: style)
    updateBackdropRoot()
    updateBlendMode(style: style)
    updateContentsScalingFilters(style: style)
  }

  private func willDestroyLayer(layer: GraphicsLayer?) {
    if layer != nil && layer!.type() == .Normal && layer!.tiledBacking() != nil {
      compositor().layerTiledBackingUsageChanged(graphicsLayer: layer, usingTiledBacking: false)
    }
  }

  private func createGraphicsLayer(name: String, layerType: GraphicsLayer.`Type` = .Normal)
    -> GraphicsLayer
  {
    let graphicsLayerFactory = renderer().page().chrome().client().graphicsLayerFactory()

    let graphicsLayer = GraphicsLayer.create(
      factory: graphicsLayerFactory, client: self, layerType: layerType)

    graphicsLayer.setName(name: name)

    if renderer().isSVGLayerAwareRenderer()
      && renderer().document().settings().layerBasedSVGEngineEnabled()
    {
      graphicsLayer.setShouldUpdateRootRelativeScaleFactor(value: true)
    }

    return graphicsLayer
  }

  private func renderer() -> RenderLayerModelObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func compositor() -> RenderLayerCompositorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateInternalHierarchy() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateViewportConstrainedAnchorLayer(_ needsAnchorLayer: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateAncestorClipping(
    _ needsAncestorClip: Bool, _ compositingAncestor: RenderLayerWrapper?
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateDescendantClippingLayer(_ needsDescendantClip: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateOverflowControlsLayers(
    _ needsHorizontalScrollbarLayer: Bool, _ needsVerticalScrollbarLayer: Bool,
    _ needsScrollCornerLayer: Bool
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateForegroundLayer(_ needsForegroundLayer: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateBackgroundLayer(_ needsBackgroundLayer: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Masking layer is used for masks or clip-path.
  @discardableResult
  private func updateMaskingLayer(hasMask: Bool, hasClipPath: Bool) -> Bool {
    var layerChanged = false
    if hasMask || hasClipPath {
      var maskPhases: GraphicsLayerPaintingPhase = []
      if hasMask {
        maskPhases = .Mask
      }

      if hasClipPath {
        // If we have a mask, we need to paint the combined clip-path and mask into the mask layer.
        if hasMask || renderer().style().clipPath()!.type == .Reference
          || !GraphicsLayer.supportsLayerType(type: .Shape)
        {
          maskPhases.update(with: .ClipPath)
        }
      }

      let paintsContent = !maskPhases.isEmpty
      let requiredLayerType: GraphicsLayer.`Type` = paintsContent ? .Normal : .Shape
      if maskLayer != nil && maskLayer!.type() != requiredLayerType {
        m_graphicsLayer!.setMaskLayer(layer: nil)
        willDestroyLayer(layer: maskLayer)
        GraphicsLayer.clear(layer: maskLayer)
      }

      if maskLayer == nil {
        maskLayer = createGraphicsLayer(name: "mask", layerType: requiredLayerType)
        layerChanged = true
        m_graphicsLayer!.setMaskLayer(layer: maskLayer)
        // We need a geometry update to size the new mask layer.
        owningLayer!.setNeedsCompositingGeometryUpdate()
      }
      maskLayer!.setDrawsContent(b: paintsContent)
      maskLayer!.setPaintingPhase(phase: maskPhases)
    } else if maskLayer != nil {
      m_graphicsLayer!.setMaskLayer(layer: nil)
      willDestroyLayer(layer: maskLayer)
      GraphicsLayer.clear(layer: maskLayer)
      layerChanged = true
    }

    return layerChanged
  }

  private func updateTransformFlatteningLayer(_ compositingAncestor: RenderLayerWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresHorizontalScrollbarLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresVerticalScrollbarLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresScrollCornerLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateScrollingLayers(_ needsScrollingLayers: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateScrollOffset(_ scrollOffset: ScrollOffset) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateMaskingLayerGeometry() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateRootLayerConfiguration() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updatePaintingPhases() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setBackgroundLayerPaintsFixedRootBackground(
    _ backgroundLayerPaintsFixedRootBackground: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func contentOffsetInCompositingLayer() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func ensureClippingStackLayers(_ clippingStack: LayerAncestorClippingStack) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateClippingStackLayerGeometry(
    _ clippingStack: LayerAncestorClippingStack, _ compositedAncestor: RenderLayerWrapper?,
    _ parentGraphicsLayerRect: inout LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func connectClippingStackLayers(_ clippingStack: LayerAncestorClippingStack) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateOpacity(style: RenderStyleWrapper) {
    m_graphicsLayer!.setOpacity(opacity: compositingOpacity(rendererOpacity: style.opacity()))
  }

  private func updateTransform(style: RenderStyleWrapper) {
    var t = TransformationMatrix()
    if renderer().effectiveCapturedInViewTransition() {
      if let activeViewTransition = renderer().document().activeViewTransition() {
        if let viewTransitionCapture =
          activeViewTransition.viewTransitionNewPseudoForCapturedElement(renderer: renderer())
        {
          t.scaleNonUniform(
            sx: Float64(viewTransitionCapture.scale.width),
            sy: Float64(viewTransitionCapture.scale.height))
          t.translate(
            tx: viewTransitionCapture.captureContentInset().x.double(),
            ty: viewTransitionCapture.captureContentInset().y.double())
        }
        if owningLayer!.isRenderViewLayer {
          let scrollPosition = renderer().view().frameView().scrollPosition()
          t.translate(tx: Float64(-scrollPosition.x), ty: Float64(-scrollPosition.y))
        }
      }
    } else if owningLayer!.isTransformed() {
      owningLayer!.updateTransformFromStyle(
        transform: &t, style: style, options: RenderStyleWrapper.individualTransformOperations)
    }

    if contentsContainmentLayer != nil {
      contentsContainmentLayer!.setTransform(matrix: t)
      m_graphicsLayer!.setTransform(matrix: TransformationMatrix())
    } else {
      m_graphicsLayer!.setTransform(matrix: t)
    }
  }

  private func updateChildrenTransformAndAnchorPoint(
    _ primaryGraphicsLayerRect: LayoutRectWrapper,
    _ offsetFromParentGraphicsLayer: LayoutSizeWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateFilters(style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateBackdropFilters(style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  private func updateBackdropRoot() -> Bool {
    // Don't try to make the RenderView's layer a backdrop root if it's going to
    // paint into the window since it won't work (WebKitLegacy only).
    var willBeBackdropRoot = owningLayer!.isBackdropRoot() && !paintsIntoWindow()

    // If the RenderView is opaque, then that will occlude any pixels behind it and we don't need
    // to isolate it as a backdrop root.
    if owningLayer!.isRenderViewLayer && !compositor().viewHasTransparentBackground() {
      willBeBackdropRoot = false
    }

    if m_graphicsLayer!.isBackdropRoot() == willBeBackdropRoot {
      return false
    }

    m_graphicsLayer!.setIsBackdropRoot(isBackdropRoot: willBeBackdropRoot)
    return true
  }

  private func updateBackdropFiltersGeometry() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateBlendMode(style: RenderStyleWrapper) {
    // FIXME: where is the blend mode updated when m_ancestorClippingStacks come and go?
    if ancestorClippingStack != nil {
      ancestorClippingStack!.stack.first!.clippingLayer!.setBlendMode(blendMode: style.blendMode())
      m_graphicsLayer!.setBlendMode(blendMode: .Normal)
    } else {
      m_graphicsLayer!.setBlendMode(blendMode: style.blendMode())
    }
  }

  private func updateContentsScalingFilters(style: RenderStyleWrapper) {
    if !renderer().isRenderHTMLCanvas()
      || canvasCompositingStrategy(renderer: renderer()) != .CanvasAsLayerContents
    {
      return
    }
    var minificationFilter: GraphicsLayer.ScalingFilter = .Linear
    var magnificationFilter: GraphicsLayer.ScalingFilter = .Linear
    switch style.imageRendering() {
    case .CrispEdges, .Pixelated:
      // FIXME: In order to match other code-paths, we treat these the same.
      minificationFilter = .Nearest
      magnificationFilter = .Nearest
    default:
      break
    }
    m_graphicsLayer!.setContentsMinificationFilter(filter: minificationFilter)
    m_graphicsLayer!.setContentsMagnificationFilter(filter: magnificationFilter)
  }

  // Return the opacity value that this layer should use for compositing.
  func compositingOpacity(rendererOpacity: Float32) -> Float32 {
    var finalOpacity = rendererOpacity

    var curr = owningLayer!.stackingContext()
    while curr != nil {
      // If we found a compositing layer, we want to compute opacity
      // relative to it. So we can break here.
      if curr!.isComposited() {
        break
      }

      finalOpacity *= curr!.renderer().opacity()
      curr = curr!.stackingContext()
    }

    return finalOpacity
  }

  func paintsBoxDecorations() -> Bool {
    if !owningLayer!.hasVisibleBoxDecorations() {
      return false
    }

    return !supportsDirectlyCompositedBoxDecorations(renderer: renderer())
  }

  func paintsContent(request: inout RenderLayerWrapper.PaintedContentRequest) -> Bool {
    owningLayer!.updateDescendantDependentFlags()

    var paintsContent = false

    if owningLayer!.hasVisibleContent && owningLayer!.hasNonEmptyChildRenderers(request: request) {
      paintsContent = true
    }

    if request.isSatisfied() {
      return paintsContent
    }

    if isPaintDestinationForDescendantLayers(request: &request) {
      paintsContent = true
    }

    if request.isSatisfied() {
      return paintsContent
    }

    if owningLayer!.renderer() is RenderSVGModelObjectWrapper {
      // FIXME: [LBSE] Eventually cache if we're part of a RenderSVGHiddenContainer subtree to avoid tree walks.
      // FIXME: [LBSE] Eventually refine the logic to end up with a narrower set of conditions (webkit.org/b/243417).
      paintsContent =
        owningLayer!.hasVisibleContent
        && RenderAncestorIteratorAdapter<RenderSVGHiddenContainerWrapper>.lineageOfType(
          first: owningLayer!.renderer()
        ).first() == nil
      request.setHasPaintedContent()
    }

    if request.isSatisfied() {
      return paintsContent
    }

    if request.hasPaintedContent == .Unknown {
      request.hasPaintedContent = .False
    }

    return paintsContent
  }

  private func updateDrawsContent(contentsInfo: inout PaintedContentsInfo) {
    if scrollContainerLayer != nil {
      // We don't have to consider overflow controls, because we know that the scrollbars are drawn elsewhere.
      // m_graphicsLayer only needs backing store if the non-scrolling parts (background, outlines, borders, shadows etc) need to paint.
      // m_scrollContainerLayer never has backing store.
      // m_scrolledContentsLayer only needs backing store if the scrolled contents need to paint.
      let hasNonScrollingPaintedContent =
        owningLayer!.hasVisibleContent && owningLayer!.hasVisibleBoxDecorationsOrBackground()
      m_graphicsLayer!.setDrawsContent(b: hasNonScrollingPaintedContent)

      let hasScrollingPaintedContent =
        hasBackingSharingLayers()
        || (owningLayer!.hasVisibleContent
          && (renderer().hasBackground() || contentsInfo.paintsContent()))
      scrolledContentsLayer!.setDrawsContent(b: hasScrollingPaintedContent)
      return
    }

    let hasPaintedContent = containsPaintedContent(contentsInfo: &contentsInfo)

    // FIXME: we could refine this to only allocate backing for one of these layers if possible.
    m_graphicsLayer!.setDrawsContent(b: hasPaintedContent)
    if foregroundLayer != nil {
      foregroundLayer!.setDrawsContent(b: hasPaintedContent)
    }

    if backgroundLayer != nil {
      backgroundLayer!.setDrawsContent(
        b: backgroundLayerPaintsFixedRootBackground
          ? hasPaintedContent : contentsInfo.paintsBoxDecorations())
    }
  }

  // Returns true if this compositing layer has no visible content.
  // A "simple container layer" is a RenderLayer which has no visible content to render.
  // It may have no children, or all its children may be themselves composited.
  // This is a useful optimization, because it allows us to avoid allocating backing store.
  func isSimpleContainerCompositingLayer(contentsInfo: inout PaintedContentsInfo) -> Bool {
    if owningLayer!.isRenderViewLayer {
      return false
    }

    if hasBackingSharingLayers() {
      return false
    }

    if renderer().isRenderReplaced() && !isCompositedPlugin(renderer: renderer()) {
      return false
    }

    if renderer().isRenderTextControl() {
      return false
    }

    if contentsInfo.paintsBoxDecorations() || contentsInfo.paintsContent() {
      return false
    }

    if renderer().style().backgroundClip() == .Text {
      return false
    }

    if renderer().isDocumentElementRenderer() && owningLayer!.isolatesCompositedBlending() {
      return false
    }

    return true
  }

  // Returns true if this layer has content that needs to be rendered by painting into the backing store.
  private func containsPaintedContent(contentsInfo: inout PaintedContentsInfo) -> Bool {
    if contentsInfo.isSimpleContainer() || paintsIntoWindow() || paintsIntoCompositedAncestor()
      || artificiallyInflatedBounds || owningLayer!.isReflection()
    {
      return false
    }

    if contentsInfo.isDirectlyCompositedImage() {
      return false
    }

    if let styleable = StyleableWrapper.fromRenderer(renderer()) {
      if !styleable.mayHaveNonZeroOpacity() {
        return false
      }
    }

    if renderer() is RenderHTMLCanvasWrapper
      && canvasCompositingStrategy(renderer: renderer()) == .CanvasAsLayerContents
    {
      return owningLayer!.hasVisibleBoxDecorationsOrBackground()
    }

    return true
  }

  // Returns true if the RenderLayer just contains an image that we can composite directly.
  // An image can be directly compositing if it's the sole content of the layer, and has no box decorations
  // that require painting. Direct compositing saves backing store.
  func isDirectlyCompositedImage() -> Bool {
    let imageRenderer = renderer() as? RenderImageWrapper
    if imageRenderer == nil || owningLayer!.hasVisibleBoxDecorationsOrBackground()
      || owningLayer!.paintsWithFilters() || renderer().hasClip()
    {
      return false
    }

    if let cachedImage = imageRenderer!.cachedImage() {
      if !cachedImage.hasImage() {
        return false
      }

      if let image = cachedImage.imageForRenderer(renderer: imageRenderer) as? BitmapImageWrapper {
        if image.currentFrameOrientation() != ImageOrientation(orientation: .None) {
          return false
        }

        return m_graphicsLayer!.shouldDirectlyCompositeImage(image: image)
      } else {
        return false
      }
    }

    return false
  }

  private func updateImageContents(_ contentsInfo: PaintedContentsInfo) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isUnscaledBitmapOnly() -> Bool {
    if !(renderer() is RenderImageWrapper) && !(renderer() is RenderHTMLCanvasWrapper) {
      return false
    }

    if owningLayer!.hasVisibleBoxDecorationsOrBackground() {
      return false
    }

    if pageScaleFactor() < 1 {
      return false
    }

    let contents = contentsBox()
    if contents.location() != LayoutPointWrapper(x: 0, y: 0) {
      return false
    }

    if let imageRenderer = renderer() as? RenderImageWrapper {
      if let cachedImage = imageRenderer.cachedImage() {
        if !cachedImage.hasImage() {
          return false
        }

        if let image = cachedImage.imageForRenderer(renderer: imageRenderer) as? BitmapImageWrapper
        {
          if image.currentFrameOrientation() != ImageOrientation(orientation: .None) {
            return false
          }

          return contents.size().FloatSize() == image.size()
        }

        return false
      }
      return false
    }

    if renderer().style().imageRendering() == .CrispEdges
      || renderer().style().imageRendering() == .Pixelated
    {
      return false
    }

    let canvasRenderer = renderer() as! RenderHTMLCanvasWrapper
    if snappedIntRect(rect: contents).size == canvasRenderer.canvasElement().size() {
      return true
    }
    return false
  }

  private func updateDirectlyCompositedBoxDecorations(_ contentsInfo: PaintedContentsInfo) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func resetContentsRect() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateContentsRects() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Conservative test for having no rendered children.
  func isPaintDestinationForDescendantLayers(
    request: inout RenderLayerWrapper.PaintedContentRequest
  )
    -> Bool
  {
    var hasPaintingDescendant = false
    traverseVisibleNonCompositedDescendantLayers(
      parent: owningLayer!,
      layerFunc: { layer in
        let localRequest = RenderLayerWrapper.PaintedContentRequest()
        if layer.isVisuallyNonEmpty(request: localRequest) {
          let mayIntersect =
            intersectsWithAncestor(
              child: layer, ancestor: owningLayer!, ancestorCompositedBounds: compositedBounds())
            ?? true
          if mayIntersect {
            hasPaintingDescendant = true
            request.setHasPaintedContent()
          }
        }
        return (hasPaintingDescendant && request.isSatisfied()) ? .Stop : .Continue
      })

    return hasPaintingDescendant
  }

  private func hasVisibleNonCompositedDescendants() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func tileCacheFlatteningLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldSetContentsDisplayDelegate() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func canIssueSetNeedsDisplay() -> Bool {
    return !paintsIntoWindow() && !paintsIntoCompositedAncestor()
  }

  // FIXME: See if we need this now that updateGeometry() is always called in post-order traversal.
  private func computeParentGraphicsLayerRect(_ compositedAncestor: RenderLayerWrapper?)
    -> LayoutRectWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computePrimaryGraphicsLayerRect(
    _ compositedAncestor: RenderLayerWrapper?, _ parentGraphicsLayerRect: LayoutRectWrapper
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var owningLayer: RenderLayerWrapper? = nil

  // A list other layers that paint into this backing store, later than owningLayer in paint order.
  private var backingSharingLayers = ListSet<RenderLayerWrapper, ObjectIdentifier>()

  let ancestorClippingStack: LayerAncestorClippingStack? = nil  // Only used if we are clipped by an ancestor which is not a stacking context.
  var overflowControlsHostLayerAncestorClippingStack: LayerAncestorClippingStack? = nil  // Used when we have an overflow controls host layer which was reparented, and needs clipping by ancestors.

  private let contentsContainmentLayer: GraphicsLayer? = nil  // Only used if we have a background layer; takes the transform.
  private var m_graphicsLayer: GraphicsLayer? = nil
  let foregroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the foreground separately.
  let backgroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the background separately.
  private var childContainmentLayer: GraphicsLayer? = nil  // Only used if we have clipping on a stacking context with compositing children, or if the layer has a tile cache.
  let viewportAnchorLayer: GraphicsLayer? = nil  // Only used if we have a mask and/or clip-path.
  private var maskLayer: GraphicsLayer? = nil  // Only used if we have a mask and/or clip-path.
  private let transformFlatteningLayer: GraphicsLayer? = nil

  private let layerForHorizontalScrollbar: GraphicsLayer? = nil
  private let layerForVerticalScrollbar: GraphicsLayer? = nil
  private let layerForScrollCorner: GraphicsLayer? = nil
  let overflowControlsContainer: GraphicsLayer? = nil

  let scrollContainerLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.
  let scrolledContentsLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.

  var subpixelOffsetFromRenderer = LayoutSizeWrapper()  // This is the subpixel distance between the primary graphics layer and the associated renderer's bounds.
  var compositedBoundsOffsetFromGraphicsLayer = LayoutSizeWrapper()  // This is the subpixel distance between the primary graphics layer and the render layer bounds.

  private var viewportConstrainedNodeID = ScrollingNodeIDWrapper()
  private var scrollingNodeID = ScrollingNodeIDWrapper()
  private var frameHostingNodeID = ScrollingNodeIDWrapper()
  private var pluginHostingNodeID = ScrollingNodeIDWrapper()
  private var positioningNodeID = ScrollingNodeIDWrapper()

  private let artificiallyInflatedBounds = false  // bounds had to be made non-zero to make transform-origin work
  private var isMainFrameRenderViewLayer = false
  private var isRootFrameRenderViewLayer = false
  var isFrameLayerWithTiledBacking = false
  let backgroundLayerPaintsFixedRootBackground = false
  private let requiresBackgroundLayer = false
  private var hasSubpixelRounding = false
  private var m_shouldPaintUsingCompositeCopy = false
}

enum CanvasCompositingStrategy {
  case CanvasPaintedToEnclosingLayer
  case CanvasPaintedToLayer
  case CanvasAsLayerContents
}

func canvasCompositingStrategy(renderer: RenderObjectWrapper) -> CanvasCompositingStrategy {
  assert(renderer.isRenderHTMLCanvas())
  let context = (renderer as! RenderHTMLCanvasWrapper).canvasElement().renderingContext()
  if context == nil {
    return .CanvasPaintedToEnclosingLayer
  }
  if context!.delegatesDisplay() {
    return .CanvasAsLayerContents
  }
  if let context2D = context as? CanvasRenderingContext2DBaseWrapper, context2D.isAccelerated() {
    return .CanvasPaintedToLayer
  }
  return .CanvasPaintedToEnclosingLayer
}
