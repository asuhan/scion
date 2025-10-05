/*
 * Copyright (C) 2009-2020 Apple Inc. All rights reserved.
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

// RenderLayerCompositor manages the hierarchy of
// composited RenderLayers. It determines which RenderLayers
// become compositing, and creates and maintains a hierarchy of
// GraphicsLayers based on the RenderLayer painting order.
//
// There is one RenderLayerCompositor per RenderView.
final class RenderLayerCompositorWrapper: GraphicsLayerClientWrapper {
  // True when some content element other than the root is composited.
  func hasContentCompositingLayers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct RequiresCompositingData {
    var layoutUpToDate: LayoutUpToDate = .Yes
    let nonCompositedForPositionReason: RenderLayerWrapper.ViewportConstrainedNotCompositedReason =
      .NoNotCompositedReason
    let reevaluateAfterLayout = false
    let intrinsic = false
  }

  // Notify us that a layer has been removed
  func layerWillBeRemoved(parent: RenderLayerWrapper, child: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerStyleChanged(
    diff: StyleDifference, layer: RenderLayerWrapper, oldStyle: RenderStyleWrapper?
  ) {
    if diff == .Equal {
      return
    }

    // Create or destroy backing here so that code that runs during layout can reliably use isComposited() (though this
    // is only true for layers composited for direct reasons).
    // Also, it allows us to avoid a tree walk in updateCompositingLayers() when no layer changed its compositing state.
    var queryData = RequiresCompositingData()
    queryData.layoutUpToDate = .No

    let layerChanged = updateBacking(layer: layer, queryData: queryData)
    if layerChanged {
      layer.setChildrenNeedCompositingGeometryUpdate()
      layer.setNeedsCompositingLayerConnection()
      layer.setSubsequentLayersNeedCompositingRequirementsTraversal()
      // Ancestor layers that composited for indirect reasons (things listed in styleChangeMayAffectIndirectCompositingReasons()) need to get updated.
      // This could be optimized by only setting this flag on layers with the relevant styles.
      layer.setNeedsPostLayoutCompositingUpdateOnAncestors()
    }
    layer.setIntrinsicallyComposited(composited: queryData.intrinsic)

    if queryData.reevaluateAfterLayout {
      layer.setNeedsPostLayoutCompositingUpdate()
    }

    if hasContentCompositingLayers() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    if diff.rawValue >= StyleDifference.Repaint.rawValue && oldStyle != nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    if let backing = layer.backing {
      backing.updateConfigurationAfterStyleChange()
    } else {
      return
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerBecameNonComposited(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  class BackingSharingState {}

  enum BackingRequired {
    case No
    case Yes
    case Unknown
  }

  private func updateBacking(
    layer: RenderLayerWrapper, queryData: RequiresCompositingData,
    backingSharingState: BackingSharingState? = nil, backingRequired: BackingRequired = .Unknown
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
