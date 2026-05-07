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
  sharingLayers: WeakListSet<RenderLayerWrapper>, providerLayer: RenderLayerWrapper
) {
  for layer in sharingLayers {
    if CPtrToInt(layer.backingProviderLayer?.layerId()) == CPtrToInt(providerLayer.layerId()) {
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
  var result = LayoutRectWrapper.infiniteRect()
  if renderer.hasNonVisibleOverflow() {
    if let box = renderer as? RenderBoxWrapper {
      result = box.overflowClipRect(location: LayoutPointWrapper(), fragment: nil)  // FIXME: Incorrect for CSS regions.
    } else if let modelObject = renderer as? RenderSVGModelObjectWrapper {
      result = modelObject.overflowClipRect(location: LayoutPointWrapper(), fragment: nil)  // FIXME: Incorrect for CSS regions.
    }
  }

  if renderer.hasClip(), let box = renderer as? RenderBoxWrapper {
    result.intersect(other: box.clipRect(location: LayoutPointWrapper(), fragment: nil))  // FIXME: Incorrect for CSS regions.
  }

  return result
}

private func overflowControlsHostLayerRect(_ renderBox: RenderBoxWrapper) -> LayoutRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func layerOrAncestorIsTransformedOrUsingCompositedScrolling(_ layer: RenderLayerWrapper)
  -> Bool
{
  var curr: RenderLayerWrapper? = layer
  while curr != nil {
    if curr!.isTransformed() || curr!.hasCompositedScrollableOverflow() {
      return true
    }
    curr = curr!.parent()
  }

  return false
}

private func hasNonZeroTransformOrigin(_ renderer: RenderObjectWrapper) -> Bool {
  let style = renderer.style()
  return (style.transformOriginX().isFixed() && style.transformOriginX().value() != 0)
    || (style.transformOriginY().isFixed() && style.transformOriginY().value() != 0)
}

private func subpixelOffsetFromRendererChanged(
  _ oldSubpixelOffsetFromRenderer: LayoutSizeWrapper,
  _ newSubpixelOffsetFromRenderer: LayoutSizeWrapper, _ deviceScaleFactor: Float32
) -> Bool {
  let previous = snapSizeToDevicePixel(
    size: oldSubpixelOffsetFromRenderer, location: LayoutPointWrapper(),
    pixelSnappingFactor: deviceScaleFactor)
  let current = snapSizeToDevicePixel(
    size: newSubpixelOffsetFromRenderer, location: LayoutPointWrapper(),
    pixelSnappingFactor: deviceScaleFactor)
  return previous != current
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
  let graphicsLayerRect = LayoutRectWrapper(location: toLayoutPoint(size: offset), size: size)
  let snappedRect = LayoutRectWrapper(
    r: snapRectToDevicePixelsIfNeeded(rect: graphicsLayerRect, renderer: renderer))
  let snapDelta = snappedRect.location() - toLayoutPoint(size: offset)
  return SnappedRectInfo(snappedRect: snappedRect, snapDelta: snapDelta)
}

private func computeOffsetFromAncestorGraphicsLayer(
  _ compositedAncestor: RenderLayerWrapper?, _ location: LayoutPointWrapper,
  _ deviceScaleFactor: Float32
) -> LayoutSizeWrapper {
  if compositedAncestor == nil {
    return toLayoutSize(point: location)
  }

  // FIXME: This is a workaround until after webkit.org/b/162634 gets fixed. ancestorSubpixelOffsetFromRenderer
  // could be stale when a dynamic composited state change triggers a pre-order updateGeometry() traversal.
  let ancestorSubpixelOffsetFromRenderer = compositedAncestor!.backing!.subpixelOffsetFromRenderer
  let ancestorCompositedBounds = compositedAncestor!.backing!.compositedBounds()
  let floored = toLayoutSize(
    point: LayoutPointWrapper(
      size: floorPointToDevicePixels(
        ancestorCompositedBounds.location() - ancestorSubpixelOffsetFromRenderer,
        deviceScaleFactor)
    ))
  let ancestorRendererOffsetFromAncestorGraphicsLayer =
    -(floored + ancestorSubpixelOffsetFromRenderer)
  return ancestorRendererOffsetFromAncestorGraphicsLayer + toLayoutSize(point: location)
}

struct ComputedOffsets {
  init(
    renderLayer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?,
    localRect: LayoutRectWrapper, parentGraphicsLayerRect: LayoutRectWrapper,
    primaryGraphicsLayerRect: LayoutRectWrapper
  ) {
    self.renderLayer = renderLayer
    self.compositingAncestor = compositingAncestor
    self.location = localRect.location()
    self.parentGraphicsLayerOffset = toLayoutSize(point: parentGraphicsLayerRect.location())
    self.primaryGraphicsLayerOffset = toLayoutSize(point: primaryGraphicsLayerRect.location())
    self.deviceScaleFactor = renderLayer.renderer().document().deviceScaleFactor()
  }

  mutating func fromParentGraphicsLayer() -> LayoutSizeWrapper {
    if m_fromParentGraphicsLayer == nil {
      m_fromParentGraphicsLayer = fromAncestorGraphicsLayer() - parentGraphicsLayerOffset
    }
    return m_fromParentGraphicsLayer!
  }

  mutating func fromPrimaryGraphicsLayer() -> LayoutSizeWrapper {
    if m_fromPrimaryGraphicsLayer == nil {
      m_fromPrimaryGraphicsLayer =
        fromAncestorGraphicsLayer() - parentGraphicsLayerOffset - primaryGraphicsLayerOffset
    }
    return m_fromPrimaryGraphicsLayer!
  }

  private mutating func fromAncestorGraphicsLayer() -> LayoutSizeWrapper {
    if m_fromAncestorGraphicsLayer == nil {
      let localPointInAncestorRenderLayerCoords = renderLayer.convertToLayerCoords(
        ancestorLayer: compositingAncestor, location: location, adjustForColumns: .AdjustForColumns)
      m_fromAncestorGraphicsLayer = computeOffsetFromAncestorGraphicsLayer(
        compositingAncestor, localPointInAncestorRenderLayerCoords, deviceScaleFactor)
    }
    return m_fromAncestorGraphicsLayer!
  }

  private var m_fromAncestorGraphicsLayer: LayoutSizeWrapper? = nil
  private var m_fromParentGraphicsLayer: LayoutSizeWrapper? = nil
  private var m_fromPrimaryGraphicsLayer: LayoutSizeWrapper? = nil

  private let renderLayer: RenderLayerWrapper
  private let compositingAncestor: RenderLayerWrapper?
  // Location is relative to the renderer.
  private let location: LayoutPointWrapper
  private let parentGraphicsLayerOffset: LayoutSizeWrapper
  private let primaryGraphicsLayerOffset: LayoutSizeWrapper
  private let deviceScaleFactor: Float32
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

private func ancestorLayerWillCombineTransform(_ compositingAncestor: RenderLayerWrapper?) -> Bool {
  if compositingAncestor == nil {
    return false
  }
  return compositingAncestor!.preserves3D() || compositingAncestor!.hasPerspective()
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

private func backgroundRectForBox(_ box: RenderBoxWrapper) -> LayoutRectWrapper {
  switch box.style().backgroundClip() {
  case .BorderBox:
    return box.borderBoxRect()
  case .PaddingBox:
    return box.paddingBoxRect()
  case .ContentBox:
    return box.contentBoxRect()
  default:
    fatalError("Not reached")
  }
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

  func setBackingSharingLayers(_ sharingLayers: WeakListSet<RenderLayerWrapper>) {
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
      CPtrToInt(compositingAncestor?.layerId())
        == CPtrToInt(owningLayer!.ancestorCompositingLayer()?.layerId()))
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
      updateDirectlyCompositedBoxDecorations(&contentsInfo)
    } else {
      updateRootLayerConfiguration()
    }

    // Requires layout.
    if contentsInfo.isDirectlyCompositedImage() {
      updateImageContents(&contentsInfo)
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
      var computedOffsets = ComputedOffsets(
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

    var compositedBoundsOffset = ComputedOffsets(
      renderLayer: owningLayer!, compositingAncestor: compositedAncestor,
      localRect: compositedBounds(), parentGraphicsLayerRect: parentGraphicsLayerRect,
      primaryGraphicsLayerRect: primaryGraphicsLayerRect)
    var rendererOffset = ComputedOffsets(
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
      updateDirectlyCompositedBoxDecorations(&contentsInfo)
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
    if scrolledContentsLayer != nil {
      return scrolledContentsLayer!
    }

    return childContainmentLayer ?? m_graphicsLayer!
  }

  func childForSuperlayers() -> GraphicsLayer {
    if owningLayer!.isRenderViewLayer {
      // If the document element is captured, then the RenderView's layer will get attached
      // into the view-transition tree, and we instead want to attach the root of the VT tree to our ancestor.
      if owningLayer!.renderer().protectedDocument().activeViewTransitionCapturedDocumentElement() {
        if let viewTransitionRoot = owningLayer!.lastChild(),
          viewTransitionRoot.renderer().isViewTransitionRoot() && viewTransitionRoot.backing != nil
        {
          return viewTransitionRoot.backing!.childForSuperlayers()
        }
      }
    }
    return childForSuperlayersExcludingViewTransitions()
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
    if requiresOwnBacking == requiresOwnBackingStore {
      return
    }

    requiresOwnBackingStore = requiresOwnBacking

    // This affects the answer to paintsIntoCompositedAncestor(), which in turn affects
    // cached clip rects, so when it changes we have to clear clip rects on descendants.
    owningLayer!.clearClipRectsIncludingDescendants(typeToClear: .PaintingClipRects)
    owningLayer!.computeRepaintRectsIncludingDescendants()

    compositor().repaintInCompositedAncestor(layer: owningLayer!, rect: compositedBounds())
  }

  func setContentsNeedDisplay(_ shouldClip: GraphicsLayer.ShouldClipToLayer = .ClipToLayer) {
    assert(!paintsIntoCompositedAncestor())

    // Use the repaint as a trigger to re-evaluate direct compositing (which is never used on the root layer).
    if !owningLayer!.isRenderViewLayer {
      owningLayer!.setNeedsCompositingConfigurationUpdate()
    }

    owningLayer!.invalidateEventRegion(reason: .Paint)

    let frameView = renderer().view().frameView()
    if isMainFrameRenderViewLayer && frameView.isTrackingRepaints() {
      frameView.addTrackedRepaintRect(owningLayer!.absoluteBoundingBoxForPainting())
    }

    if m_graphicsLayer?.drawsContent() ?? false {
      // By default, setNeedsDisplay will clip to the size of the GraphicsLayer, which does not include margin tiles.
      // So if the TiledBacking has a margin that needs to be invalidated, we need to send in a rect to setNeedsDisplayInRect
      // that is large enough to include the margin. TiledBacking::bounds() includes the margin.
      let tiledBacking = tiledBacking()
      let rectToRepaint =
        tiledBacking != nil
        ? FloatRectWrapper(r: tiledBacking!.bounds())
        : FloatRectWrapper(location: FloatPoint(x: 0, y: 0), size: m_graphicsLayer!.size())
      m_graphicsLayer!.setNeedsDisplayInRect(rectToRepaint, shouldClip)
    }

    if foregroundLayer?.drawsContent() ?? false {
      foregroundLayer!.setNeedsDisplay()
    }

    if backgroundLayer?.drawsContent() ?? false {
      backgroundLayer!.setNeedsDisplay()
    }

    if maskLayer?.drawsContent() ?? false {
      maskLayer!.setNeedsDisplay()
    }

    if scrolledContentsLayer?.drawsContent() ?? false {
      scrolledContentsLayer!.setNeedsDisplay()
    }
  }

  // r is in the coordinate space of the layer's render object
  func setContentsNeedDisplayInRect(
    _ r: LayoutRectWrapper, _ shouldClip: GraphicsLayer.ShouldClipToLayer = .ClipToLayer
  ) {
    assert(!paintsIntoCompositedAncestor())

    // Use the repaint as a trigger to re-evaluate direct compositing (which is never used on the root layer).
    if !owningLayer!.isRenderViewLayer {
      owningLayer!.setNeedsCompositingConfigurationUpdate()
    }

    owningLayer!.invalidateEventRegion(reason: .Paint)

    let pixelSnappedRectForPainting = snapRectToDevicePixelsIfNeeded(rect: r, renderer: renderer())
    let frameView = renderer().view().frameView()
    if isMainFrameRenderViewLayer && frameView.isTrackingRepaints() {
      frameView.addTrackedRepaintRect(pixelSnappedRectForPainting)
    }

    if m_graphicsLayer?.drawsContent() ?? false {
      var layerDirtyRect = pixelSnappedRectForPainting
      layerDirtyRect.move(
        delta: -m_graphicsLayer!.offsetFromRenderer() - subpixelOffsetFromRenderer.FloatSize())
      m_graphicsLayer!.setNeedsDisplayInRect(layerDirtyRect, shouldClip)
    }

    if foregroundLayer?.drawsContent() ?? false {
      var layerDirtyRect = pixelSnappedRectForPainting
      layerDirtyRect.move(
        delta: -foregroundLayer!.offsetFromRenderer() - subpixelOffsetFromRenderer.FloatSize())
      foregroundLayer!.setNeedsDisplayInRect(layerDirtyRect, shouldClip)
    }

    // FIXME: need to split out repaints for the background.
    if backgroundLayer?.drawsContent() ?? false {
      var layerDirtyRect = pixelSnappedRectForPainting
      layerDirtyRect.move(
        delta: -backgroundLayer!.offsetFromRenderer() - subpixelOffsetFromRenderer.FloatSize())
      backgroundLayer!.setNeedsDisplayInRect(layerDirtyRect, shouldClip)
    }

    if maskLayer?.drawsContent() ?? false {
      var layerDirtyRect = pixelSnappedRectForPainting
      layerDirtyRect.move(
        delta: -maskLayer!.offsetFromRenderer() - subpixelOffsetFromRenderer.FloatSize())
      maskLayer!.setNeedsDisplayInRect(layerDirtyRect, shouldClip)
    }

    if scrolledContentsLayer?.drawsContent() ?? false {
      var layerDirtyRect = pixelSnappedRectForPainting
      var scrollOffset = ScrollOffset()
      if let scrollableArea = owningLayer!.scrollableArea() {
        scrollOffset = scrollableArea.scrollOffset()
      }
      layerDirtyRect.move(
        delta: -scrolledContentsLayer!.offsetFromRenderer()
          + toLayoutSize(point: LayoutPointWrapper(point: scrollOffset)).FloatSize()
          - subpixelOffsetFromRenderer.FloatSize())
      scrolledContentsLayer!.setNeedsDisplayInRect(layerDirtyRect, shouldClip)
    }
  }

  // Notification from the renderer that its content changed.
  func contentChanged(_ changeType: ContentChangeType) {
    var contentsInfo = PaintedContentsInfo(inBacking: self)
    if changeType == .ImageChanged || changeType == .CanvasChanged {
      if contentsInfo.isDirectlyCompositedImage() {
        updateImageContents(&contentsInfo)
        return
      }
      if contentsInfo.isUnscaledBitmapOnly() != m_graphicsLayer!.appliesDeviceScale() {
        compositor().scheduleCompositingLayerUpdate()
        return
      }
    }

    if changeType == .VideoChanged {
      compositor().scheduleCompositingLayerUpdate()
      return
    }

    if (changeType == .BackgroundImageChanged)
      && canDirectlyCompositeBackgroundBackgroundImage(renderer: renderer())
    {
      owningLayer!.setNeedsCompositingConfigurationUpdate()
    }

    if (changeType == .MaskImageChanged) && maskLayer != nil {
      owningLayer!.setNeedsCompositingConfigurationUpdate()
    }

    if (changeType == .CanvasChanged || changeType == .CanvasPixelsChanged)
      && renderer().isRenderHTMLCanvas()
      && canvasCompositingStrategy(renderer: renderer()) == .CanvasAsLayerContents
    {
      if changeType == .CanvasChanged {
        compositor().scheduleCompositingLayerUpdate()
      }

      m_graphicsLayer!.setContentsNeedsDisplay()
      return
    }
  }

  func compositedBounds() -> LayoutRectWrapper {
    return m_compositedBounds
  }

  // Returns true if changed.
  func setCompositedBounds(_ bounds: LayoutRectWrapper) -> Bool {
    if bounds == m_compositedBounds {
      return false
    }

    m_compositedBounds = bounds
    return true
  }

  // Returns true if changed.
  @discardableResult
  func updateCompositedBounds() -> Bool {
    var layerBounds = owningLayer!.calculateLayerBounds(
      ancestorLayer: owningLayer, offsetFromRoot: LayoutSizeWrapper(),
      flags: RenderLayerWrapper.defaultCalculateLayerBoundsFlags.union([
        .ExcludeHiddenDescendants, .DontConstrainForMask,
      ]))
    // Clip to the size of the document or enclosing overflow-scroll layer.
    // If this or an ancestor is transformed, we can't currently compute the correct rect to intersect with.
    // We'd need RenderObject::convertContainerToLocalQuad(), which doesn't yet exist.
    if shouldClipCompositedBounds() {
      let view = renderer().view()
      let rootLayer = view.layer()

      var clippingBounds =
        (renderer().isFixedPositioned()
          && CPtrToInt(renderer().container()?.id()) == CPtrToInt(view.id()))
        ? view.frameView().rectForFixedPositionLayout()
        : LayoutRectWrapper(rect: view.unscaledDocumentRect())

      if CPtrToInt(owningLayer!.layerId()) != CPtrToInt(rootLayer?.layerId()) {
        clippingBounds.intersect(
          other: owningLayer!.backgroundClipRect(
            clipRectsContext: RenderLayerWrapper.ClipRectsContext(
              inRootLayer: rootLayer, inClipRectsType: .AbsoluteClipRects)
          ).rect)  // FIXME: Incorrect for CSS regions.
      }

      let delta = owningLayer!.convertToLayerCoords(
        ancestorLayer: rootLayer, location: LayoutPointWrapper(),
        adjustForColumns: .AdjustForColumns)
      clippingBounds.move(dx: -delta.x, dy: -delta.y)

      layerBounds.intersect(other: clippingBounds)
    }

    // If the backing provider has overflow:clip, we know all sharing layers are affected by the clip because they are containing-block descendants.
    if !renderer().hasNonVisibleOverflow() {
      for layer in backingSharingLayers {
        assert(layer.isDescendantOf(owningLayer!))
        let offset = layer.offsetFromAncestor(ancestorLayer: owningLayer)
        let bounds = layer.calculateLayerBounds(
          ancestorLayer: owningLayer, offsetFromRoot: offset,
          flags: RenderLayerWrapper.defaultCalculateLayerBoundsFlags.union([
            .ExcludeHiddenDescendants, .DontConstrainForMask,
          ]))
        layerBounds.unite(other: bounds)
      }
    }

    // If the element has a transform-origin that has fixed lengths, and the renderer has zero size,
    // then we need to ensure that the compositing layer has non-zero size so that we can apply
    // the transform-origin via the GraphicsLayer anchorPoint (which is expressed as a fractional value).
    if layerBounds.isEmpty()
      && (hasNonZeroTransformOrigin(renderer()) || renderer().style().hasPerspective())
    {
      layerBounds.setWidth(width: Int32(1))
      layerBounds.setHeight(height: Int32(1))
      artificiallyInflatedBounds = true
    } else {
      artificiallyInflatedBounds = false
    }

    return setCompositedBounds(layerBounds)
  }

  func updateAllowsBackingStoreDetaching(absoluteBounds: LayoutRectWrapper) {
    let setAllowsBackingStoreDetaching = { [self] (allowDetaching: Bool) in
      m_graphicsLayer?.setAllowsBackingStoreDetaching(allowDetaching: allowDetaching)
      foregroundLayer?.setAllowsBackingStoreDetaching(allowDetaching: allowDetaching)
      backgroundLayer?.setAllowsBackingStoreDetaching(allowDetaching: allowDetaching)
      scrolledContentsLayer?.setAllowsBackingStoreDetaching(allowDetaching: allowDetaching)
    }

    if !owningLayer!.behavesAsFixed {
      setAllowsBackingStoreDetaching(true)
      return
    }

    // We'll allow detaching if the layer is outside the layout viewport. Fixed layers inside
    // the layout viewport can be revealed by async scrolling, so we want to pin their backing store.
    let frameView = renderer().view().frameView()
    let fixedLayoutRect =
      frameView.useFixedLayout()
      ? LayoutRectWrapper(rect: renderer().view().unscaledDocumentRect())
      : frameView.rectForFixedPositionLayout()

    let allowDetaching = !fixedLayoutRect.intersects(other: absoluteBounds)
    // TODO(asuhan): add logging
    setAllowsBackingStoreDetaching(allowDetaching)
  }

  private func updateAfterWidgetResize() {
    guard let renderWidget = renderer() as? RenderWidgetWrapper else { return }

    if let innerCompositor = RenderLayerCompositorWrapper.frameContentsCompositor(
      renderer: renderWidget)
    {
      innerCompositor.frameViewDidChangeSize()
      innerCompositor.frameViewDidChangeLocation(flooredIntPoint(point: contentsBox().location()))
    }

    if let contentsLayer = layerForContents() {
      contentsLayer.setPosition(p: FloatPoint(p: flooredIntPoint(point: contentsBox().location())))
    }
  }

  private func positionOverflowControlsLayers() {
    guard let scrollableArea = owningLayer!.scrollableArea() else { return }
    if !scrollableArea.hasScrollbars() {
      return
    }
    // FIXME: Should do device-pixel snapping.
    let box = renderBox()!
    let borderBox = snappedIntRect(rect: box.borderBoxRect())

    // overflowControlsContainer is positioned using the paddingBoxRectIncludingScrollbar.
    let paddingBox = snappedIntRect(rect: box.paddingBoxRectIncludingScrollbar())
    let paddingBoxInset = paddingBox.location - borderBox.location

    let positionScrollbarLayer = {
      (layer: GraphicsLayer, scrollbarRect: IntRect, paddingBoxInset: IntSize) in
      layer.setPosition(p: FloatPoint(p: scrollbarRect.location - paddingBoxInset))
      layer.setSize(size: FloatSize(size: scrollbarRect.size))
      if layer.usesContentsLayer() {
        let barRect = FloatRectWrapper(r: IntRect(location: IntPoint(), size: scrollbarRect.size))
        layer.setContentsRect(barRect)
        layer.setContentsClippingRect(FloatRoundedRect(rect: barRect))
      }
    }

    // These rects are relative to the borderBoxRect.
    let rects = scrollableArea.overflowControlsRects()
    if let layer = layerForHorizontalScrollbar {
      positionScrollbarLayer(layer, rects.horizontalScrollbar, paddingBoxInset)
      layer.setDrawsContent(
        b: scrollableArea.horizontalScrollbar() != nil && !layer.usesContentsLayer())
    }

    if let layer = layerForVerticalScrollbar {
      positionScrollbarLayer(layer, rects.verticalScrollbar, paddingBoxInset)
      layer.setDrawsContent(
        b: scrollableArea.verticalScrollbar() != nil && !layer.usesContentsLayer())
    }

    if let layer = layerForScrollCorner {
      let cornerRect = rects.scrollCornerOrResizerRect()
      layer.setPosition(p: FloatPoint(p: cornerRect.location - paddingBoxInset))
      layer.setSize(size: FloatSize(size: cornerRect.size))
      layer.setDrawsContent(b: !cornerRect.isEmpty())
    }
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
    if !RenderLayerCompositorWrapper.isCompositedPlugin(renderer: renderer()) {
      return nil
    }

    guard
      let pluginViewBase = (renderer() as! RenderEmbeddedObjectWrapper).widget() as? PluginViewBase
    else { return nil }

    if pluginViewBase.layerHostingStrategy() != .GraphicsLayer {
      return nil
    }

    return pluginViewBase.graphicsLayer()
  }

  func adjustOverflowControlsPositionRelativeToAncestor(
    _ ancestorLayer: RenderLayerWrapper
  ) {
    assert(overflowControlsContainer != nil)
    assert(ancestorLayer.isComposited())
    if ancestorLayer.backing == nil {
      return
    }

    var parentGraphicsLayerRect = computeParentGraphicsLayerRect(ancestorLayer)
    let primaryGraphicsLayerRect = computePrimaryGraphicsLayerRect(
      ancestorLayer, parentGraphicsLayerRect)

    let overflowControlsRect = overflowControlsHostLayerRect(renderer() as! RenderBoxWrapper)

    if overflowControlsHostLayerAncestorClippingStack != nil {
      updateClippingStackLayerGeometry(
        overflowControlsHostLayerAncestorClippingStack!, ancestorLayer, &parentGraphicsLayerRect)
    }

    var rendererOffset = ComputedOffsets(
      renderLayer: owningLayer!, compositingAncestor: ancestorLayer, localRect: LayoutRectWrapper(),
      parentGraphicsLayerRect: parentGraphicsLayerRect,
      primaryGraphicsLayerRect: primaryGraphicsLayerRect)

    let boxOffsetFromGraphicsLayer =
      toLayoutSize(point: overflowControlsRect.location())
      + rendererOffset.fromParentGraphicsLayer()
    let snappedBoxInfo = snappedGraphicsLayer(
      boxOffsetFromGraphicsLayer, overflowControlsRect.size(), renderer())

    overflowControlsContainer!.setPosition(p: snappedBoxInfo.snappedRect.location().FloatPoint())
    overflowControlsContainer!.setSize(size: snappedBoxInfo.snappedRect.size().FloatSize())
  }

  func canCompositeFilters() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func backgroundBoxForSimpleContainerPainting() -> FloatRectWrapper {
    guard let box = renderer() as? RenderBoxWrapper else { return FloatRectWrapper() }

    var backgroundBox = backgroundRectForBox(box)
    backgroundBox.move(size: contentOffsetInCompositingLayer())
    return snapRectToDevicePixels(rect: backgroundBox, pixelSnappingFactor: deviceScaleFactor())
  }

  private func createPrimaryGraphicsLayer() {
    let layerName = owningLayer!.name()
    m_graphicsLayer = createGraphicsLayer(
      layerName, isFrameLayerWithTiledBacking ? .PageTiledBacking : .Normal)

    if isFrameLayerWithTiledBacking {
      childContainmentLayer = createGraphicsLayer("Page TiledBacking containment")
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

  private func createGraphicsLayer(_ name: String, _ layerType: GraphicsLayer.`Type` = .Normal)
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

  private func renderBox() -> RenderBoxWrapper? { return owningLayer!.renderBox() }

  private func compositor() -> RenderLayerCompositorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateInternalHierarchy() {
    // foregroundLayer has to be inserted in the correct order with child layers,
    // so it's not inserted here.
    var lastClippingLayer: GraphicsLayer? = nil
    if ancestorClippingStack != nil {
      connectClippingStackLayers(ancestorClippingStack!)
      lastClippingLayer = ancestorClippingStack!.lastLayer()
    }

    // TODO(asuhan): create with initial capacity
    var orderedLayers: [GraphicsLayer] = []

    if lastClippingLayer != nil {
      orderedLayers.append(lastClippingLayer!)
    }

    if viewportAnchorLayer != nil {
      orderedLayers.append(viewportAnchorLayer!)
    }

    if contentsContainmentLayer != nil {
      contentsContainmentLayer!.removeAllChildren()

      assert(backgroundLayer != nil)
      contentsContainmentLayer!.addChild(childLayer: backgroundLayer!)

      // The loop below will add a second child to the contentsContainmentLayer.
      orderedLayers.append(contentsContainmentLayer!)
    }

    orderedLayers.append(m_graphicsLayer!)

    // The transform flattening layer is outside the clipping stack, so we need
    // to make sure we add the first layer in the clipping stack as its child.
    if transformFlatteningLayer != nil {
      if lastClippingLayer != nil {
        transformFlatteningLayer!.addChild(childLayer: ancestorClippingStack!.firstLayer()!)
      } else {
        transformFlatteningLayer!.addChild(childLayer: orderedLayers[0])
      }
    }

    if childContainmentLayer != nil {
      orderedLayers.append(childContainmentLayer!)
    }

    if scrollContainerLayer != nil {
      orderedLayers.append(scrollContainerLayer!)
    }

    var previousLayer: GraphicsLayer? = nil
    for layer in orderedLayers {
      previousLayer?.addChild(childLayer: layer)
      previousLayer = layer
    }

    // The clip for child layers does not include space for overflow controls, so they exist as
    // siblings of the clipping layer if we have one. Normal children of this layer are set as
    // children of the clipping layer.
    if overflowControlsContainer != nil {
      if layerForHorizontalScrollbar != nil {
        overflowControlsContainer!.addChild(childLayer: layerForHorizontalScrollbar!)
      }

      if layerForVerticalScrollbar != nil {
        overflowControlsContainer!.addChild(childLayer: layerForVerticalScrollbar!)
      }

      if layerForScrollCorner != nil {
        overflowControlsContainer!.addChild(childLayer: layerForScrollCorner!)
      }

      // overflowControlsContainer may get reparented later.
      m_graphicsLayer!.addChild(childLayer: overflowControlsContainer!)
    }
  }

  private func updateViewportConstrainedAnchorLayer(_ needsAnchorLayer: Bool) -> Bool {
    var layerChanged = false
    if needsAnchorLayer {
      if viewportAnchorLayer == nil {
        viewportAnchorLayer = createGraphicsLayer("ViewportConstrainedAnchorLayer", .Structural)  // // TODO(asuhan): set name correctly
        layerChanged = true
      }
    } else if viewportAnchorLayer != nil {
      willDestroyLayer(layer: viewportAnchorLayer)
      GraphicsLayer.unparentAndClear(layer: viewportAnchorLayer)
      layerChanged = true
    }

    return layerChanged
  }

  // Return true if the layer changed.
  private func updateAncestorClipping(
    _ needsAncestorClip: Bool, _ compositingAncestor: RenderLayerWrapper?
  ) -> Bool {
    var layersChanged = false

    if needsAncestorClip {
      if compositor().updateAncestorClippingStack(
        owningLayer!, compositingAncestor: compositingAncestor)
      {
        if ancestorClippingStack != nil {
          ensureClippingStackLayers(ancestorClippingStack!)
        }

        layersChanged = true
      }
    } else if ancestorClippingStack != nil {
      let scrollingCoordinator = owningLayer!.page().scrollingCoordinator()

      ancestorClippingStack!.clear(scrollingCoordinator)
      ancestorClippingStack = nil

      if overflowControlsHostLayerAncestorClippingStack != nil {
        overflowControlsHostLayerAncestorClippingStack!.clear(scrollingCoordinator)
        overflowControlsHostLayerAncestorClippingStack = nil
      }

      layersChanged = true
    }

    return layersChanged
  }

  // Return true if the layer changed.
  private func updateDescendantClippingLayer(_ needsDescendantClip: Bool) -> Bool {
    var layersChanged = false

    if needsDescendantClip {
      if childContainmentLayer == nil && !isFrameLayerWithTiledBacking {
        childContainmentLayer = createGraphicsLayer("child clipping")
        childContainmentLayer!.setMasksToBounds(b: true)
        childContainmentLayer!.setContentsRectClipsDescendants(true)
        layersChanged = true
      }
    } else if hasClippingLayer() {
      willDestroyLayer(layer: childContainmentLayer)
      GraphicsLayer.unparentAndClear(layer: childContainmentLayer)
      layersChanged = true
    }

    return layersChanged
  }

  private func updateOverflowControlsLayers(
    _ needsHorizontalScrollbarLayer: Bool, _ needsVerticalScrollbarLayer: Bool,
    _ needsScrollCornerLayer: Bool
  ) -> Bool {
    let createOrDestroyLayer = {
      [self] (layer: inout GraphicsLayer?, needLayer: Bool, drawsContent: Bool, layerName: String)
      in
      if needLayer == (layer != nil) {
        return false
      }

      if needLayer {
        layer = createGraphicsLayer(layerName)
        if drawsContent {
          layer!.setAllowsBackingStoreDetaching(allowDetaching: false)
          layer!.setAllowsTiling(allowsTiling: false)
        } else {
          layer!.setPaintingPhase(phase: [])
          layer!.setDrawsContent(b: false)
        }
      } else {
        willDestroyLayer(layer: layer)
        GraphicsLayer.unparentAndClear(layer: layer)
      }
      return true
    }

    var layersChanged = createOrDestroyLayer(
      &overflowControlsContainer,
      needsHorizontalScrollbarLayer || needsVerticalScrollbarLayer || needsScrollCornerLayer, false,
      "overflow controls container")

    let horizontalScrollbarLayerChanged = createOrDestroyLayer(
      &layerForHorizontalScrollbar, needsHorizontalScrollbarLayer, true, "horizontal scrollbar")
    layersChanged = layersChanged || horizontalScrollbarLayerChanged

    let verticalScrollbarLayerChanged = createOrDestroyLayer(
      &layerForVerticalScrollbar, needsVerticalScrollbarLayer, true, "vertical scrollbar")
    layersChanged = layersChanged || verticalScrollbarLayerChanged

    layersChanged =
      layersChanged
      || createOrDestroyLayer(&layerForScrollCorner, needsScrollCornerLayer, true, "scroll corner")

    if let scrollingCoordinator = owningLayer!.page().scrollingCoordinator(),
      let scrollableArea = owningLayer!.scrollableArea()
    {
      if horizontalScrollbarLayerChanged {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: scrollableArea, orientation: .Horizontal)
      }
      if verticalScrollbarLayerChanged {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: scrollableArea, orientation: .Vertical)
      }
    }

    return layersChanged
  }

  private func updateForegroundLayer(_ needsForegroundLayer: Bool) -> Bool {
    var layerChanged = false
    if needsForegroundLayer {
      if foregroundLayer == nil {
        foregroundLayer = createGraphicsLayer("ForegroundLayer")  // TODO(asuhan): set name correctly
        foregroundLayer!.setDrawsContent(b: true)
        layerChanged = true
      }
    } else if foregroundLayer != nil {
      willDestroyLayer(layer: foregroundLayer)
      GraphicsLayer.unparentAndClear(layer: foregroundLayer)
      layerChanged = true
    }

    return layerChanged
  }

  private func updateBackgroundLayer(_ needsBackgroundLayer: Bool) -> Bool {
    var layerChanged = false
    if needsBackgroundLayer {
      if backgroundLayer == nil {
        backgroundLayer = createGraphicsLayer("BackgroundLayer")  // TODO(asuhan): set name correctly
        backgroundLayer!.setDrawsContent(b: true)
        backgroundLayer!.setAnchorPoint(p: FloatPoint3D())
        layerChanged = true
      }

      if contentsContainmentLayer == nil {
        contentsContainmentLayer = createGraphicsLayer("contents containment")
        contentsContainmentLayer!.setAppliesPageScale(appliesScale: true)
        m_graphicsLayer!.setAppliesPageScale(appliesScale: false)
        layerChanged = true
      }
    } else {
      if backgroundLayer != nil {
        willDestroyLayer(layer: backgroundLayer)
        GraphicsLayer.unparentAndClear(layer: backgroundLayer)
        layerChanged = true
      }
      if contentsContainmentLayer != nil {
        willDestroyLayer(layer: contentsContainmentLayer)
        GraphicsLayer.unparentAndClear(layer: contentsContainmentLayer)
        layerChanged = true
        m_graphicsLayer!.setAppliesPageScale(appliesScale: true)
      }
    }

    return layerChanged
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
        maskLayer = createGraphicsLayer("mask", requiredLayerType)
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
    var needsFlatteningLayer = false
    // If our parent layer has preserve-3d or perspective, and it's not our DOM parent, then we need a flattening layer to block that from being applied in 3d.
    if ancestorLayerWillCombineTransform(compositingAncestor)
      && !owningLayer!.ancestorLayerIsDOMParent(ancestor: compositingAncestor)
    {
      needsFlatteningLayer = true
    }

    var layerChanged = false
    if needsFlatteningLayer {
      if transformFlatteningLayer == nil {
        transformFlatteningLayer = createGraphicsLayer("3d flattening")  // TODO(asuhan): set name correctly
        layerChanged = true
      }
    } else if transformFlatteningLayer != nil {
      willDestroyLayer(layer: transformFlatteningLayer)
      GraphicsLayer.unparentAndClear(layer: transformFlatteningLayer)
      layerChanged = true
    }

    return layerChanged
  }

  private func requiresLayerForScrollbar(_ scrollbar: Scrollbar?) -> Bool {
    if scrollbar == nil {
      return false
    }
    var requiresLayer = scrollbar!.isOverlayScrollbar()
    #if !WTF_PLATFORM_IOS_FAMILY  // FIXME: This should be an #if ENABLE(): webkit.org/b/210460
      requiresLayer = requiresLayer || renderer().settings().asyncOverflowScrollingEnabled()
    #endif
    return requiresLayer
  }

  private func requiresHorizontalScrollbarLayer() -> Bool {
    if let scrollableArea = owningLayer!.scrollableArea() {
      return requiresLayerForScrollbar(scrollableArea.horizontalScrollbar())
    }
    return false
  }

  private func requiresVerticalScrollbarLayer() -> Bool {
    if let scrollableArea = owningLayer!.scrollableArea() {
      return requiresLayerForScrollbar(scrollableArea.verticalScrollbar())
    }
    return false
  }

  private func requiresScrollCornerLayer() -> Bool {
    if !(owningLayer!.renderer() is RenderBoxWrapper) {
      return false
    }

    guard let scrollableArea = owningLayer!.scrollableArea() else { return false }

    let cornerRect = scrollableArea.overflowControlsRects().scrollCornerOrResizerRect()
    if cornerRect.isEmpty() {
      return false
    }

    let scrollbar = scrollableArea.verticalScrollbar() ?? scrollableArea.horizontalScrollbar()
    return requiresLayerForScrollbar(scrollbar)
  }

  private func updateScrollingLayers(_ needsScrollingLayers: Bool) -> Bool {
    if needsScrollingLayers == (scrollContainerLayer != nil) {
      return false
    }

    if scrollContainerLayer == nil {
      // Outer layer which corresponds with the scroll view. This never paints content.
      scrollContainerLayer = createGraphicsLayer("scroll container", .ScrollContainer)
      scrollContainerLayer!.setPaintingPhase(phase: [])
      scrollContainerLayer!.setDrawsContent(b: false)
      scrollContainerLayer!.setMasksToBounds(b: true)

      // Inner layer which renders the content that scrolls.
      scrolledContentsLayer = createGraphicsLayer("scrolled contents", .ScrolledContents)
      scrolledContentsLayer!.setDrawsContent(b: true)
      scrolledContentsLayer!.setAnchorPoint(p: FloatPoint3D())
      scrollContainerLayer!.addChild(childLayer: scrolledContentsLayer!)
    } else {
      compositor().willRemoveScrollingLayerWithBacking(owningLayer!, self)

      willDestroyLayer(layer: scrollContainerLayer)
      willDestroyLayer(layer: scrolledContentsLayer)

      GraphicsLayer.unparentAndClear(layer: scrollContainerLayer)
      GraphicsLayer.unparentAndClear(layer: scrolledContentsLayer)
    }

    if scrollContainerLayer != nil {
      compositor().didAddScrollingLayer(owningLayer!)
    }

    return true
  }

  private func updateScrollOffset(_ scrollOffset: ScrollOffset) {
    let scrollableArea = owningLayer!.scrollableArea()!

    if scrollableArea.currentScrollType() == .User {
      // If scrolling is happening externally, we don't want to touch the layer bounds origin here because that will cause jitter.
      setLocationOfScrolledContents(scrollOffset, .Sync)
      scrollableArea.setRequiresScrollPositionReconciliation(true)
    } else {
      // Note that we implement the contents offset via the bounds origin on this layer, rather than a position on the sublayer.
      setLocationOfScrolledContents(scrollOffset, .Set)
      scrollableArea.setRequiresScrollPositionReconciliation(false)
    }

    assert(scrolledContentsLayer!.position().isZero())
  }

  private func setLocationOfScrolledContents(
    _ scrollOffset: ScrollOffset, _ setOrSync: ScrollingLayerPositionAction
  ) {
    if setOrSync == .Sync {
      scrollContainerLayer!.syncBoundsOrigin(FloatPoint(p: scrollOffset))
    } else {
      scrollContainerLayer!.setBoundsOrigin(FloatPoint(p: scrollOffset))
    }
  }

  // FIXME: Avoid repaints when clip path changes.
  private func updateMaskingLayerGeometry() {
    maskLayer!.setSize(size: m_graphicsLayer!.size())
    maskLayer!.setPosition(p: FloatPoint())
    maskLayer!.setOffsetFromRenderer(m_graphicsLayer!.offsetFromRenderer())

    if !maskLayer!.drawsContent() && renderer().hasClipPath() {
      assert(renderer().style().clipPath()!.type != .Reference)

      // FIXME: Use correct reference box for inlines: https://bugs.webkit.org/show_bug.cgi?id=129047, https://github.com/w3c/csswg-drafts/issues/6383
      let boundingBox = owningLayer!.boundingBox(ancestorLayer: owningLayer)
      let referenceBoxForClippedInline = LayoutRectWrapper(
        r: snapRectToDevicePixelsIfNeeded(rect: boundingBox, renderer: renderer()))
      let offset = LayoutSizeWrapper(
        size: snapSizeToDevicePixel(
          size: -subpixelOffsetFromRenderer, location: LayoutPointWrapper(),
          pixelSnappingFactor: deviceScaleFactor()))
      let (clipPath, windRule) = owningLayer!.computeClipPath(
        offsetFromRoot: offset, rootRelativeBoundsForNonBoxes: referenceBoxForClippedInline)

      let pathOffset = maskLayer!.offsetFromRenderer()
      if !pathOffset.isZero() {
        clipPath.translate(-pathOffset)
      }

      maskLayer!.setShapeLayerPath(clipPath)
      maskLayer!.setShapeLayerWindRule(windRule)
    }
  }

  private func updateRootLayerConfiguration() {
    if !isFrameLayerWithTiledBacking {
      return
    }

    var backgroundColor: ColorWrapper? = ColorWrapper()
    let viewIsTransparent = compositor().viewHasTransparentBackground(&backgroundColor)

    if backgroundLayerPaintsFixedRootBackground && backgroundLayer != nil {
      if isMainFrameRenderViewLayer {
        backgroundLayer!.setBackgroundColor(backgroundColor!)
        backgroundLayer!.setContentsOpaque(b: !viewIsTransparent)
      }

      m_graphicsLayer!.setBackgroundColor(ColorWrapper())
      m_graphicsLayer!.setContentsOpaque(b: false)
    } else if isMainFrameRenderViewLayer {
      m_graphicsLayer!.setBackgroundColor(backgroundColor!)
      m_graphicsLayer!.setContentsOpaque(b: !viewIsTransparent)
    }
  }

  private func updatePaintingPhases() {
    // Phases for m_maskLayer are set elsewhere.
    var primaryLayerPhases: GraphicsLayerPaintingPhase = [.Background, .Foreground]

    if foregroundLayer != nil {
      var foregroundLayerPhases: GraphicsLayerPaintingPhase = [.Foreground]

      if scrolledContentsLayer != nil {
        foregroundLayerPhases.update(with: .OverflowContents)
      }

      foregroundLayer!.setPaintingPhase(phase: foregroundLayerPhases)
      primaryLayerPhases.remove(.Foreground)
    }

    if backgroundLayer != nil {
      backgroundLayer!.setPaintingPhase(phase: .Background)
      primaryLayerPhases.remove(.Background)
    }

    if scrolledContentsLayer != nil {
      var scrolledContentLayerPhases: GraphicsLayerPaintingPhase = [
        .OverflowContents, .CompositedScroll,
      ]
      if foregroundLayer == nil {
        scrolledContentLayerPhases.update(with: .Foreground)
      }
      scrolledContentsLayer!.setPaintingPhase(phase: scrolledContentLayerPhases)

      primaryLayerPhases.remove(.Foreground)
      primaryLayerPhases.update(with: .CompositedScroll)
    }

    m_graphicsLayer!.setPaintingPhase(phase: primaryLayerPhases)
  }

  private func setBackgroundLayerPaintsFixedRootBackground(
    _ backgroundLayerPaintsFixedRootBackground: Bool
  ) {
    if backgroundLayerPaintsFixedRootBackground == self.backgroundLayerPaintsFixedRootBackground {
      return
    }

    self.backgroundLayerPaintsFixedRootBackground = backgroundLayerPaintsFixedRootBackground

    if self.backgroundLayerPaintsFixedRootBackground {
      assert(self.isFrameLayerWithTiledBacking)
      renderer().view().frameView().removeSlowRepaintObject(
        renderer().view().rendererForRootBackground()!)
    }
  }

  // Return the offset from the top-left of this compositing layer at which the renderer's contents are painted.
  private func contentOffsetInCompositingLayer() -> LayoutSizeWrapper {
    return LayoutSizeWrapper(
      width: -m_compositedBounds.x() + compositedBoundsOffsetFromGraphicsLayer.width(),
      height: -m_compositedBounds.y() + compositedBoundsOffsetFromGraphicsLayer.height())
  }

  private func ensureClippingStackLayers(_ clippingStack: LayerAncestorClippingStack) {
    for i in 0..<clippingStack.stack.count {
      if clippingStack.stack[i].clippingLayer == nil {
        clippingStack.stack[i].clippingLayer = createGraphicsLayer(
          clippingStack.stack[i].clipData.isOverflowScroll
            ? "clip for scroller" : "ancestor clipping")
        clippingStack.stack[i].clippingLayer!.setMasksToBounds(b: true)
        clippingStack.stack[i].clippingLayer!.setPaintingPhase(phase: [])
      }

      if clippingStack.stack[i].clipData.isOverflowScroll {
        if clippingStack.stack[i].scrollingLayer == nil {
          clippingStack.stack[i].scrollingLayer = createGraphicsLayer("scrolling proxy")
        }
      } else if clippingStack.stack[i].scrollingLayer != nil {
        GraphicsLayer.unparentAndClear(layer: clippingStack.stack[i].scrollingLayer)
      }
    }
  }

  private func updateClippingStackLayerGeometry(
    _ clippingStack: LayerAncestorClippingStack, _ compositedAncestor: RenderLayerWrapper?,
    _ parentGraphicsLayerRect: inout LayoutRectWrapper
  ) {
    // All clipRects in the stack are computed relative to owningLayer, so convert them back to compositedAncestor.
    let offsetFromCompositedAncestor = toLayoutSize(
      point: owningLayer!.convertToLayerCoords(
        ancestorLayer: compositedAncestor, location: LayoutPointWrapper(),
        adjustForColumns: .AdjustForColumns))
    var lastClipLayerRect = parentGraphicsLayerRect

    let deviceScaleFactor = deviceScaleFactor()
    for entry in clippingStack.stack {
      var roundedClipRect = entry.clipData.clipRect
      var clipRect = roundedClipRect.rect()
      let clippingOffset = computeOffsetFromAncestorGraphicsLayer(
        compositedAncestor, clipRect.location() + offsetFromCompositedAncestor, deviceScaleFactor)
      let snappedClippingLayerRect = snappedGraphicsLayer(
        clippingOffset, clipRect.size(), renderer()
      ).snappedRect

      let clippingLayerPosition = toLayoutPoint(
        size: snappedClippingLayerRect.location() - lastClipLayerRect.location())
      entry.clippingLayer!.setPosition(p: clippingLayerPosition.FloatPoint())
      entry.clippingLayer!.setSize(size: snappedClippingLayerRect.size().FloatSize())

      clipRect.setLocation(location: LayoutPointWrapper())
      roundedClipRect.setRect(clipRect)
      entry.clippingLayer!.setContentsClippingRect(FloatRoundedRect(rect: roundedClipRect))
      entry.clippingLayer!.setContentsRectClipsDescendants(true)

      lastClipLayerRect = snappedClippingLayerRect

      if entry.clipData.isOverflowScroll {
        var scrollOffset = ScrollOffset()
        if let scrollableArea = entry.clipData.clippingLayer?.scrollableArea() {
          scrollOffset = scrollableArea.scrollOffset()
        }

        // scrollingLayer size and position are always 0,0.
        entry.scrollingLayer!.setBoundsOrigin(FloatPoint(p: scrollOffset))
        lastClipLayerRect.moveBy(offset: LayoutPointWrapper(point: -scrollOffset))
      }
    }

    parentGraphicsLayerRect = lastClipLayerRect
  }

  private func connectClippingStackLayers(_ clippingStack: LayerAncestorClippingStack) {
    let connectEntryLayers = { (entry: LayerAncestorClippingStack.ClippingStackEntry) -> Void in
      entry.clippingLayer?.setChildren(newChildren: [entry.scrollingLayer!])
    }

    let clippingEntryStack = clippingStack.stack[...]
    for i in 0..<clippingEntryStack.count - 1 {
      connectEntryLayers(clippingEntryStack[i])

      let entryParentForSublayers = clippingEntryStack[i].parentForSublayers()
      let childLayer = clippingEntryStack[i + 1].childForSuperlayers()
      entryParentForSublayers!.setChildren(newChildren: [childLayer!])
    }

    connectEntryLayers(clippingEntryStack.last!)
    clippingEntryStack.last!.parentForSublayers()!.removeAllChildren()
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
    var defaultAnchorPoint = FloatPoint3D(x: 0.5, y: 0.5, z: 0)

    if owningLayer!.isRenderViewLayer || renderer().effectiveCapturedInViewTransition() {
      defaultAnchorPoint = FloatPoint3D()
    }

    if !renderer().hasTransformRelatedProperty() || renderer().effectiveCapturedInViewTransition() {
      m_graphicsLayer!.setAnchorPoint(p: defaultAnchorPoint)
      contentsContainmentLayer?.setAnchorPoint(p: defaultAnchorPoint)
      childContainmentLayer?.setAnchorPoint(p: defaultAnchorPoint)
      scrollContainerLayer?.setAnchorPoint(p: defaultAnchorPoint)
      scrolledContentsLayer?.setPreserves3D(false)
      return
    }

    let deviceScaleFactor = deviceScaleFactor()
    let transformOrigin = owningLayer!.transformOriginPixelSnappedIfNeeded()
    let layerOffset = roundPointToDevicePixels(
      point: toLayoutPoint(size: offsetFromParentGraphicsLayer),
      pixelSnappingFactor: deviceScaleFactor)
    let anchor = FloatPoint3D(
      x: primaryGraphicsLayerRect.width() != 0
        ? ((layerOffset.x - primaryGraphicsLayerRect.x()) + transformOrigin.x)
          / primaryGraphicsLayerRect.width() : 0.5,
      y: primaryGraphicsLayerRect.height() != 0
        ? ((layerOffset.y - primaryGraphicsLayerRect.y()) + transformOrigin.y)
          / primaryGraphicsLayerRect.height() : 0.5,
      z: transformOrigin.z
    )

    if contentsContainmentLayer != nil {
      contentsContainmentLayer!.setAnchorPoint(p: anchor)
    } else {
      m_graphicsLayer!.setAnchorPoint(p: anchor)
    }

    let removeChildrenTransformFromLayers = { [self] (layerToIgnore: GraphicsLayer?) in
      if let clippingLayer = clippingLayer(), !optEq(clippingLayer, layerToIgnore) {
        clippingLayer.setChildrenTransform(TransformationMatrix())
        clippingLayer.setAnchorPoint(p: defaultAnchorPoint)
      }

      if scrollContainerLayer != nil && !optEq(scrollContainerLayer, layerToIgnore) {
        scrollContainerLayer!.setChildrenTransform(TransformationMatrix())
        scrollContainerLayer!.setAnchorPoint(p: defaultAnchorPoint)
        scrolledContentsLayer!.setPreserves3D(false)
      }

      if !optEq(m_graphicsLayer, layerToIgnore) {
        m_graphicsLayer!.setChildrenTransform(TransformationMatrix())
      }
    }

    if !renderer().style().hasPerspective() {
      removeChildrenTransformFromLayers(nil)
      return
    }

    let layerForChildrenTransform = { [self] () in
      if scrollContainerLayer != nil {
        // Scroll container layers are only created for RenderBox derived renderers.
        return (
          scrollContainerLayer, scrollContainerLayerBox(renderer() as! RenderBoxWrapper).FloatRect()
        )
      }
      if let layer = clippingLayer() {
        return (layer, clippingLayerBox(renderer()).FloatRect())
      }

      return (m_graphicsLayer, renderer().transformReferenceBoxRect())
    }

    let (layerForPerspective, layerForPerspectiveRect) = layerForChildrenTransform()
    if !optEq(layerForPerspective, m_graphicsLayer) {
      // If we have scrolling layers, we need the children transform on m_scrollContainerLayer to
      // affect children of m_scrolledContentsLayer, so set setPreserves3D(true).
      if optEq(layerForPerspective, scrollContainerLayer) {
        scrolledContentsLayer!.setPreserves3D(true)
      }

      let perspectiveAnchorPoint = FloatPoint3D(
        x: layerForPerspectiveRect.width() != 0
          ? (transformOrigin.x - layerForPerspectiveRect.x()) / layerForPerspectiveRect.width()
          : 0.5,
        y: layerForPerspectiveRect.height() != 0
          ? (transformOrigin.y - layerForPerspectiveRect.y()) / layerForPerspectiveRect.height()
          : 0.5,
        z: transformOrigin.z)

      layerForPerspective!.setAnchorPoint(p: perspectiveAnchorPoint)
    }

    layerForPerspective!.setChildrenTransform(owningLayer!.perspectiveTransform())
    removeChildrenTransformFromLayers(layerForPerspective)
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
    if !canCompositeBackdropFilters {
      return
    }

    guard let renderBox = renderer() as? RenderBoxWrapper else { return }

    var backdropFiltersRect = FloatRoundedRect()
    if renderBox.style().hasBorderRadius() && !renderBox.hasClip() {
      let borderShape = BorderShape.shapeForBorderRect(
        style: renderBox.style(), borderRect: renderBox.borderBoxRect())
      var roundedBoxRect = borderShape.deprecatedRoundedRect()
      roundedBoxRect.move(size: contentOffsetInCompositingLayer())
      backdropFiltersRect = roundedBoxRect.pixelSnappedRoundedRectForPainting(
        deviceScaleFactor: deviceScaleFactor())
    } else {
      var boxRect = renderBox.borderBoxRect()
      if renderBox.hasClip() {
        boxRect.intersect(other: renderBox.clipRect(location: LayoutPointWrapper(), fragment: nil))
      }
      boxRect.move(size: contentOffsetInCompositingLayer())
      backdropFiltersRect = FloatRoundedRect(
        rect: snapRectToDevicePixels(rect: boxRect, pixelSnappingFactor: deviceScaleFactor()))
    }

    m_graphicsLayer!.setBackdropFiltersRect(backdropFiltersRect)
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

  private func rendererBackgroundColor() -> ColorWrapper {
    var backgroundRenderer =
      renderer().isDocumentElementRenderer() ? renderer().view().rendererForRootBackground() : nil

    if backgroundRenderer == nil {
      backgroundRenderer = renderer()
    }

    return backgroundRenderer!.style().visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyBackgroundColor)
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

    if owningLayer!.hasVisibleContent && owningLayer!.hasNonEmptyChildRenderers(&request) {
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

  private func updateImageContents(_ contentsInfo: inout PaintedContentsInfo) {
    let imageRenderer = renderer() as! RenderImageWrapper

    guard let cachedImage = imageRenderer.cachedImage() else { return }

    guard let image = cachedImage.imageForRenderer(renderer: imageRenderer) else { return }

    // We have to wait until the image is fully loaded before setting it on the layer.
    if !cachedImage.isLoaded() {
      return
    }

    updateContentsRects()
    m_graphicsLayer!.setContentsToImage(image)

    updateDrawsContent(contentsInfo: &contentsInfo)

    // Image animation is "lazy", in that it automatically stops unless someone is drawing
    // the image. So we have to kick the animation each time; this has the downside that the
    // image will keep animating, even if its layer is not visible.
    image.startAnimation()
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

  private func updateDirectlyCompositedBoxDecorations(_ contentsInfo: inout PaintedContentsInfo) {
    if !owningLayer!.hasVisibleContent {
      return
    }

    // The order of operations here matters, since the last valid type of contents needs
    // to also update the contentsRect.
    updateDirectlyCompositedBackgroundColor(&contentsInfo)
    updateDirectlyCompositedBackgroundImage(&contentsInfo)
  }

  private func updateDirectlyCompositedBackgroundColor(_ contentsInfo: inout PaintedContentsInfo) {
    if backgroundLayer != nil && !backgroundLayerPaintsFixedRootBackground
      && !contentsInfo.paintsBoxDecorations()
    {
      m_graphicsLayer!.setContentsToSolidColor(ColorWrapper())
      backgroundLayer!.setContentsToSolidColor(rendererBackgroundColor())

      var contentsRect = backgroundBoxForSimpleContainerPainting()
      // NOTE: This is currently only used by RenderFullScreen, which we want to be
      // big enough to hide overflow areas of the root.
      contentsRect.inflate(size: contentsRect.size())
      backgroundLayer!.setContentsRect(contentsRect)
      backgroundLayer!.setContentsClippingRect(FloatRoundedRect(rect: contentsRect))
      return
    }

    if !contentsInfo.isSimpleContainer()
      || ((renderer() is RenderBoxWrapper)
        && !BackgroundPainter.paintsOwnBackground(renderer: renderBox()!))
    {
      m_graphicsLayer!.setContentsToSolidColor(ColorWrapper())
      return
    }

    let backgroundColor = rendererBackgroundColor()

    // An unset (invalid) color will remove the solid color.
    m_graphicsLayer!.setContentsToSolidColor(backgroundColor)
    let contentsRect = backgroundBoxForSimpleContainerPainting()
    m_graphicsLayer!.setContentsRect(contentsRect)
    m_graphicsLayer!.setContentsClippingRect(FloatRoundedRect(rect: contentsRect))
  }

  private func updateDirectlyCompositedBackgroundImage(_ contentsInfo: inout PaintedContentsInfo) {
    if !GraphicsLayer.supportsContentsTiling() {
      return
    }

    if contentsInfo.isDirectlyCompositedImage() {
      return
    }

    let style = renderer().style()
    if !contentsInfo.isSimpleContainer() || !style.hasBackgroundImage() {
      m_graphicsLayer!.setContentsToImage(nil)
      return
    }

    let backgroundBox = LayoutRectWrapper(r: backgroundBoxForSimpleContainerPainting())
    // FIXME: Absolute paint location is required here.
    let geometry = BackgroundPainter.calculateBackgroundImageGeometry(
      renderer: renderBox()!, paintContainer: renderBox(), fillLayer: style.backgroundLayers(),
      paintOffset: LayoutPointWrapper(), borderBoxRect: backgroundBox)

    m_graphicsLayer!.setContentsTileSize(geometry.tileSize.FloatSize())
    m_graphicsLayer!.setContentsTilePhase(geometry.phase.FloatSize())
    m_graphicsLayer!.setContentsRect(geometry.destinationRect.FloatRect())
    m_graphicsLayer!.setContentsClippingRect(
      FloatRoundedRect(rect: geometry.destinationRect.FloatRect()))
    m_graphicsLayer!.setContentsToImage(style.backgroundLayers().image()!.cachedImage()!.image())
  }

  private func resetContentsRect() {
    updateContentsRects()
    m_graphicsLayer!.setContentsTileSize(FloatSize(size: IntSize()))
    m_graphicsLayer!.setContentsTilePhase(FloatSize(size: IntSize()))
  }

  private func updateContentsRects() {
    m_graphicsLayer!.setContentsRect(
      snapRectToDevicePixelsIfNeeded(rect: contentsBox(), renderer: renderer()))

    guard let renderReplaced = renderer() as? RenderReplacedWrapper else { return }

    let borderShape = renderReplaced.borderShapeForContentClipping(
      borderBoxRect: renderReplaced.borderBoxRect())
    var contentsClippingRect = borderShape.deprecatedPixelSnappedInnerRoundedRect(
      deviceScaleFactor())
    contentsClippingRect.move(size: contentOffsetInCompositingLayer().FloatSize())
    m_graphicsLayer!.setContentsClippingRect(contentsClippingRect)
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
        var localRequest: RenderLayerWrapper.PaintedContentRequest? =
          RenderLayerWrapper.PaintedContentRequest()
        if layer.isVisuallyNonEmpty(request: &localRequest) {
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
    var hasVisibleDescendant = false
    traverseVisibleNonCompositedDescendantLayers(
      parent: owningLayer!,
      layerFunc: { (_ layer: RenderLayerWrapper) in
        hasVisibleDescendant = hasVisibleDescendant || layer.hasVisibleContent
        return hasVisibleDescendant ? .Stop : .Continue
      })

    return hasVisibleDescendant
  }

  private func shouldClipCompositedBounds() -> Bool {
    #if !WTF_PLATFORM_IOS_FAMILY
      // Scrollbar layers use this layer for relative positioning, so don't clip.
      if layerForHorizontalScrollbar != nil || layerForVerticalScrollbar != nil {
        return false
      }
    #endif

    if renderer().effectiveCapturedInViewTransition() {
      return false
    }
    if renderer().style().pseudoElementType() == .ViewTransitionNew {
      return false
    }

    if isFrameLayerWithTiledBacking {
      return false
    }

    if layerOrAncestorIsTransformedOrUsingCompositedScrolling(owningLayer!) {
      return false
    }

    return true
  }

  private func tileCacheFlatteningLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldSetContentsDisplayDelegate() -> Bool {
    if !renderer().isRenderHTMLCanvas() {
      return false
    }

    return canvasCompositingStrategy(renderer: renderer()) == .CanvasAsLayerContents
  }

  private func canIssueSetNeedsDisplay() -> Bool {
    return !paintsIntoWindow() && !paintsIntoCompositedAncestor()
  }

  // FIXME: See if we need this now that updateGeometry() is always called in post-order traversal.
  private func computeParentGraphicsLayerRect(_ compositedAncestor: RenderLayerWrapper?)
    -> LayoutRectWrapper
  {
    if compositedAncestor?.backing == nil {
      return LayoutRectWrapper(rect: renderer().view().documentRect())
    }

    let ancestorBacking = compositedAncestor!.backing!
    var parentGraphicsLayerRect = LayoutRectWrapper()
    if owningLayer!.isInsideFragmentedFlow() {
      // FIXME: flows/columns need work.
      var ancestorCompositedBounds = ancestorBacking.compositedBounds()
      ancestorCompositedBounds.setLocation(location: LayoutPointWrapper())
      parentGraphicsLayerRect = ancestorCompositedBounds
    }

    guard let ancestorRenderBox = compositedAncestor!.renderer() as? RenderBoxWrapper else {
      return parentGraphicsLayerRect
    }

    if ancestorBacking.hasClippingLayer() {
      // If the compositing ancestor has a layer to clip children, we parent in that, and therefore position relative to it.
      let clippingBox = clippingLayerBox(ancestorRenderBox)
      let clippingBoxOffset = computeOffsetFromAncestorGraphicsLayer(
        compositedAncestor, clippingBox.location(), deviceScaleFactor())
      parentGraphicsLayerRect =
        snappedGraphicsLayer(clippingBoxOffset, clippingBox.size(), renderer()).snappedRect
    }

    if compositedAncestor!.hasCompositedScrollableOverflow() {
      let scrollableArea = compositedAncestor!.scrollableArea()!

      let ancestorCompositedBounds = ancestorBacking.compositedBounds()
      let scrollContainerBox = scrollContainerLayerBox(ancestorRenderBox)
      let scrollOffset = LayoutPointWrapper(point: scrollableArea.scrollOffset())
      parentGraphicsLayerRect = LayoutRectWrapper(
        location: (scrollContainerBox.location()
          - toLayoutSize(point: ancestorCompositedBounds.location())
          - toLayoutSize(point: scrollOffset)), size: scrollContainerBox.size())
    }

    return parentGraphicsLayerRect
  }

  private func computePrimaryGraphicsLayerRect(
    _ compositedAncestor: RenderLayerWrapper?, _ parentGraphicsLayerRect: LayoutRectWrapper
  ) -> LayoutRectWrapper {
    var compositedBoundsOffset = ComputedOffsets(
      renderLayer: owningLayer!, compositingAncestor: compositedAncestor,
      localRect: compositedBounds(), parentGraphicsLayerRect: parentGraphicsLayerRect,
      primaryGraphicsLayerRect: LayoutRectWrapper())
    return LayoutRectWrapper(
      r: encloseRectToDevicePixels(
        rect: LayoutRectWrapper(
          location: toLayoutPoint(size: compositedBoundsOffset.fromParentGraphicsLayer()),
          size: compositedBounds().size()
        ), pixelSnappingFactor: deviceScaleFactor()))
  }

  private var owningLayer: RenderLayerWrapper? = nil

  // A list other layers that paint into this backing store, later than owningLayer in paint order.
  private var backingSharingLayers = WeakListSet<RenderLayerWrapper>()

  var ancestorClippingStack: LayerAncestorClippingStack? = nil  // Only used if we are clipped by an ancestor which is not a stacking context.
  var overflowControlsHostLayerAncestorClippingStack: LayerAncestorClippingStack? = nil  // Used when we have an overflow controls host layer which was reparented, and needs clipping by ancestors.

  private var contentsContainmentLayer: GraphicsLayer? = nil  // Only used if we have a background layer; takes the transform.
  private var m_graphicsLayer: GraphicsLayer? = nil
  var foregroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the foreground separately.
  var backgroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the background separately.
  private var childContainmentLayer: GraphicsLayer? = nil  // Only used if we have clipping on a stacking context with compositing children, or if the layer has a tile cache.
  var viewportAnchorLayer: GraphicsLayer? = nil  // Only used if we have a mask and/or clip-path.
  private var maskLayer: GraphicsLayer? = nil  // Only used if we have a mask and/or clip-path.
  private var transformFlatteningLayer: GraphicsLayer? = nil

  private var layerForHorizontalScrollbar: GraphicsLayer? = nil
  private var layerForVerticalScrollbar: GraphicsLayer? = nil
  private var layerForScrollCorner: GraphicsLayer? = nil
  var overflowControlsContainer: GraphicsLayer? = nil

  var scrollContainerLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.
  var scrolledContentsLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.

  private var m_compositedBounds = LayoutRectWrapper()
  var subpixelOffsetFromRenderer = LayoutSizeWrapper()  // This is the subpixel distance between the primary graphics layer and the associated renderer's bounds.
  var compositedBoundsOffsetFromGraphicsLayer = LayoutSizeWrapper()  // This is the subpixel distance between the primary graphics layer and the render layer bounds.

  private var viewportConstrainedNodeID = ScrollingNodeIDWrapper()
  private var scrollingNodeID = ScrollingNodeIDWrapper()
  private var frameHostingNodeID = ScrollingNodeIDWrapper()
  private var pluginHostingNodeID = ScrollingNodeIDWrapper()
  private var positioningNodeID = ScrollingNodeIDWrapper()

  private var artificiallyInflatedBounds = false  // bounds had to be made non-zero to make transform-origin work
  private var isMainFrameRenderViewLayer = false
  private var isRootFrameRenderViewLayer = false
  var isFrameLayerWithTiledBacking = false
  var requiresOwnBackingStore = true
  var canCompositeBackdropFilters = false
  var backgroundLayerPaintsFixedRootBackground = false
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
