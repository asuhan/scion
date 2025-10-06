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

private func clippingChanged(oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func styleAffectsLayerGeometry(style: RenderStyleWrapper) -> Bool {
  return style.hasClip() || style.clipPath() != nil || style.hasBorderRadius()
}

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

    let newStyle = layer.renderer().style()

    if hasContentCompositingLayers() {
      if diff.rawValue >= StyleDifference.LayoutPositionedMovementOnly.rawValue {
        layer.setNeedsPostLayoutCompositingUpdate()
        layer.setNeedsCompositingGeometryUpdate()
      }

      if diff.rawValue >= StyleDifference.Layout.rawValue {
        // FIXME: only set flags here if we know we have a composited descendant, but we might not know at this point.
        if oldStyle != nil && clippingChanged(oldStyle: oldStyle!, newStyle: newStyle) {
          if layer.isStackingContext() {
            layer.setNeedsPostLayoutCompositingUpdate()  // Layer needs to become composited if it has composited descendants.
            layer.setNeedsCompositingConfigurationUpdate()  // If already composited, layer needs to create/destroy clipping layer.
            layer.setChildrenNeedCompositingGeometryUpdate()  // Clipping layers on this layer affect descendant layer geometry.
          } else {
            // Descendant (in containing block order) compositing layers need to re-evaluate their clipping,
            // but they might be siblings in z-order so go up to our stacking context.
            if let stackingContext = layer.stackingContext() {
              stackingContext.setDescendantsNeedUpdateBackingAndHierarchyTraversal()
            }
          }
        }

        if RenderLayerCompositorWrapper.styleChangeAffectsAnchorLayer(
          oldStyle: oldStyle, newStyle: newStyle)
        {
          layer.setNeedsCompositingConfigurationUpdate()
        }

        // These properties trigger compositing if some descendant is composited.
        if oldStyle != nil
          && RenderLayerCompositorWrapper.styleChangeMayAffectIndirectCompositingReasons(
            oldStyle: oldStyle!, newStyle: newStyle)
        {
          layer.setNeedsPostLayoutCompositingUpdate()
        }

        layer.setNeedsCompositingGeometryUpdate()
      }
    }

    if diff.rawValue >= StyleDifference.Repaint.rawValue && oldStyle != nil {
      // This ensures that we update border-radius clips on layers that are descendants in containing-block order but not paint order. This is necessary even when
      // the current layer is not composited.
      let changeAffectsClippingOfNonPaintOrderDescendants =
        !layer.isStackingContext() && layer.renderer().hasNonVisibleOverflow()
        && oldStyle!.border() != newStyle.border()
      if changeAffectsClippingOfNonPaintOrderDescendants, let parent = layer.paintOrderParent() {
        parent.setChildrenNeedCompositingGeometryUpdate()
      }
    }

    if let backing = layer.backing {
      backing.updateConfigurationAfterStyleChange()
    } else {
      return
    }

    if diff.rawValue >= StyleDifference.Repaint.rawValue {
      // Visibility change may affect geometry of the enclosing composited layer.
      if oldStyle != nil && oldStyle!.usedVisibility() != newStyle.usedVisibility() {
        layer.setNeedsCompositingGeometryUpdate()
      }

      // We'll get a diff of Repaint when things like clip-path change; these might affect layer or inner-layer geometry.
      if layer.isComposited() && oldStyle != nil {
        if styleAffectsLayerGeometry(style: oldStyle!) || styleAffectsLayerGeometry(style: newStyle)
        {
          layer.setNeedsCompositingGeometryUpdate()
        }
      }

      // image rendering mode can determine whether we use device pixel ratio for the backing store.
      if oldStyle != nil && oldStyle!.imageRendering() != newStyle.imageRendering() {
        layer.setNeedsCompositingConfigurationUpdate()
      }
    }

    if diff.rawValue >= StyleDifference.RecompositeLayer.rawValue {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  // This ensures that the viewport anchor layer will be updated when updating compositing layers upon style change
  private static func styleChangeAffectsAnchorLayer(
    oldStyle: RenderStyleWrapper?, newStyle: RenderStyleWrapper
  ) -> Bool {
    if oldStyle == nil {
      return false
    }

    return oldStyle!.hasViewportConstrainedPosition() != newStyle.hasViewportConstrainedPosition()
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

  private static func styleChangeMayAffectIndirectCompositingReasons(
    oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
