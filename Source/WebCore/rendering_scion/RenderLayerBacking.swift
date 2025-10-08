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

  func removeBackingSharingLayer(layer: RenderLayerWrapper) {
    layer.setBackingProviderLayer(backingProvider: nil)
    backingSharingLayers.remove(value: layer)
  }

  func clearBackingSharingLayers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateConfigurationAfterStyleChange() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Update contents and clipping structure.
  func updateDrawsContent() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func compositor() -> RenderLayerCompositorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let owningLayer: RenderLayerWrapper

  // A list other layers that paint into this backing store, later than m_owningLayer in paint order.
  private let backingSharingLayers = ListSet<RenderLayerWrapper, ObjectIdentifier>()

  let isFrameLayerWithTiledBacking = false
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
