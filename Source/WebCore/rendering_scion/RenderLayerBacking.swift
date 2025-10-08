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
private struct PaintedContentsInfo {
  func paintsBoxDecorations() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintsContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let backing: RenderLayerBacking
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

// RenderLayerBacking controls the compositing behavior for a single RenderLayer.
// It holds the various GraphicsLayers, and makes decisions about intra-layer rendering
// optimizations.
//
// There is one RenderLayerBacking for each RenderLayer that is composited.

final class RenderLayerBacking: GraphicsLayerClientWrapper {
  init(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Do cleanup while layer->backing() is still valid.
  func willBeDestroyed() {
    assert(ObjectIdentifier(owningLayer.backing!) == ObjectIdentifier(self))
    compositor().removeFromScrollCoordinatedLayers(layer: owningLayer)

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
      sharingLayers: backingSharingLayers, providerLayer: owningLayer)
    backingSharingLayers.clear()
  }

  // This can only update things that don't require up-to-date layout.
  func updateConfigurationAfterStyleChange() {
    updateMaskingLayer(hasMask: renderer().hasMask(), hasClipPath: renderer().hasClipPath())

    if owningLayer.hasReflection() {
      if let backing = owningLayer.reflectionLayer()!.backing {
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
    var contentsInfo = PaintedContentsInfo(backing: self)
    updateDrawsContent(contentsInfo: &contentsInfo)
  }

  func graphicsLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func detachFromScrollingCoordinator(roles: ScrollCoordinationRole) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func updateDebugIndicators(showBorder: Bool, showRepaintCounter: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canCompositeFilters() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
        owningLayer.setNeedsCompositingGeometryUpdate()
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
    var willBeBackdropRoot = owningLayer.isBackdropRoot() && !paintsIntoWindow()

    // If the RenderView is opaque, then that will occlude any pixels behind it and we don't need
    // to isolate it as a backdrop root.
    if owningLayer.isRenderViewLayer && !compositor().viewHasTransparentBackground() {
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

  private func updateDrawsContent(contentsInfo: inout PaintedContentsInfo) {
    if scrollContainerLayer != nil {
      // We don't have to consider overflow controls, because we know that the scrollbars are drawn elsewhere.
      // m_graphicsLayer only needs backing store if the non-scrolling parts (background, outlines, borders, shadows etc) need to paint.
      // m_scrollContainerLayer never has backing store.
      // m_scrolledContentsLayer only needs backing store if the scrolled contents need to paint.
      let hasNonScrollingPaintedContent =
        owningLayer.hasVisibleContent && owningLayer.hasVisibleBoxDecorationsOrBackground()
      m_graphicsLayer!.setDrawsContent(b: hasNonScrollingPaintedContent)

      let hasScrollingPaintedContent =
        hasBackingSharingLayers()
        || (owningLayer.hasVisibleContent
          && (renderer().hasBackground() || contentsInfo.paintsContent()))
      scrolledContentsLayer!.setDrawsContent(b: hasScrollingPaintedContent)
      return
    }

    let hasPaintedContent = containsPaintedContent(contentsInfo: contentsInfo)

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

  // Returns true if this layer has content that needs to be rendered by painting into the backing store.
  private func containsPaintedContent(contentsInfo: PaintedContentsInfo) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let owningLayer: RenderLayerWrapper

  // A list other layers that paint into this backing store, later than m_owningLayer in paint order.
  private let backingSharingLayers = ListSet<RenderLayerWrapper, UInt>()

  private let ancestorClippingStack: LayerAncestorClippingStack? = nil  // Only used if we are clipped by an ancestor which is not a stacking context.

  private let m_graphicsLayer: GraphicsLayer? = nil
  private let foregroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the foreground separately.
  private let backgroundLayer: GraphicsLayer? = nil  // Only used in cases where we need to draw the background separately.
  private var maskLayer: GraphicsLayer? = nil  // Only used if we have a mask and/or clip-path.

  private let scrollContainerLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.
  private let scrolledContentsLayer: GraphicsLayer? = nil  // Only used if the layer is using composited scrolling.

  let isFrameLayerWithTiledBacking = false
  let backgroundLayerPaintsFixedRootBackground = false
}

enum CanvasCompositingStrategy {
  case CanvasPaintedToEnclosingLayer
  case CanvasPaintedToLayer
  case CanvasAsLayerContents
}

func canvasCompositingStrategy(renderer: RenderObjectWrapper) -> CanvasCompositingStrategy {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
