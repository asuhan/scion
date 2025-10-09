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

    let contentRequest = RenderLayerWrapper.PaintedContentRequest()
    content = backing.paintsContent(request: contentRequest) ? .True : .False

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

  let backing: RenderLayerBacking
  var boxDecorations: RequestState = .Unknown
  var content: RequestState = .Unknown

  private var contentsType: ContentsTypeDetermination = .Unknown
}

private func clearBackingSharingLayerProviders(
  sharingLayers: ListSet<RenderLayerWrapper, UInt>, providerLayer: RenderLayerWrapper
) {
  for layer in sharingLayers {
    if CPtrToInt(layer.backingProviderLayer?.p) == CPtrToInt(providerLayer.p) {
      layer.setBackingProviderLayer(backingProvider: nil)
    }
  }
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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

  // Update contents and clipping structure.
  func updateDrawsContent() {
    var contentsInfo = PaintedContentsInfo(inBacking: self)
    updateDrawsContent(contentsInfo: &contentsInfo)
  }

  func graphicsLayer() -> GraphicsLayer? {
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

  func hasMaskLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // RenderLayers with backing normally short-circuit paintLayer() because
  // their content is rendered via callbacks from GraphicsLayer. However, the document
  // layer is special, because it has a GraphicsLayer to act as a container for the GraphicsLayers
  // for descendants, but its contents usually render into the window (in which case this returns true).
  // This returns false for other layers, and when the document layer actually needs to paint into its backing store
  // for some reason.
  func paintsIntoWindow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true for a composited layer that has no backing store of its own, so
  // paints into some ancestor layer.
  func paintsIntoCompositedAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func compositedBounds() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func tiledBacking() -> TiledBackingWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustTiledBackingCoverage() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func createGraphicsLayer(name: String, layerType: GraphicsLayer.`Type` = .Normal)
    -> GraphicsLayer
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func renderer() -> RenderLayerModelObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func compositor() -> RenderLayerCompositorWrapper {
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

  private func updateOpacity(style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateTransform(style: RenderStyleWrapper) {
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

  func paintsBoxDecorations() -> Bool {
    if !owningLayer!.hasVisibleBoxDecorations() {
      return false
    }

    return !supportsDirectlyCompositedBoxDecorations(renderer: renderer())
  }

  func paintsContent(request: RenderLayerWrapper.PaintedContentRequest) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

    if let styleable = StyleableWrapper.fromRenderer(renderer: renderer()) {
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
  func isDirectlyCompositedImage() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isUnscaledBitmapOnly() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var owningLayer: RenderLayerWrapper? = nil

  // A list other layers that paint into this backing store, later than owningLayer in paint order.
  private let backingSharingLayers = ListSet<RenderLayerWrapper, UInt>()

  let ancestorClippingStack: LayerAncestorClippingStack? = nil  // Only used if we are clipped by an ancestor which is not a stacking context.

  private let contentsContainmentLayer: GraphicsLayer? = nil  // Only used if we have a background layer; takes the transform.
  private var m_graphicsLayer: GraphicsLayer? = nil
  private let foregroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the foreground separately.
  let backgroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the background separately.
  private var childContainmentLayer: GraphicsLayer? = nil  // Only used if we have clipping on a stacking context with compositing children, or if the layer has a tile cache.
  private var maskLayer: GraphicsLayer? = nil  // Only used if we have a mask and/or clip-path.

  private let layerForHorizontalScrollbar: GraphicsLayer? = nil
  private let layerForVerticalScrollbar: GraphicsLayer? = nil
  private let layerForScrollCorner: GraphicsLayer? = nil
  private let overflowControlsContainer: GraphicsLayer? = nil

  private let scrollContainerLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.
  private let scrolledContentsLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.

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
