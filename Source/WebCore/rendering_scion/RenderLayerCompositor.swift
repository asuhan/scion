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
  return oldStyle.overflowX() != newStyle.overflowX()
    || oldStyle.overflowY() != newStyle.overflowY()
    || oldStyle.hasClip() != newStyle.hasClip() || oldStyle.clip() != newStyle.clip()
}

private func styleAffectsLayerGeometry(style: RenderStyleWrapper) -> Bool {
  return style.hasClip() || style.clipPath() != nil || style.hasBorderRadius()
}

private func optEq<T: AnyObject>(_ a: T?, _ b: T?) -> Bool {
  if a != nil && b != nil {
    return ObjectIdentifier(a!) == ObjectIdentifier(b!)
  }
  if a == nil && b == nil {
    return true
  }
  return false
}

private func recompositeChangeRequiresGeometryUpdate(
  oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
) -> Bool {
  return oldStyle.transform() != newStyle.transform()
    || optEq(oldStyle.translate(), newStyle.translate())
    || optEq(oldStyle.scale(), newStyle.scale())
    || optEq(oldStyle.rotate(), newStyle.rotate())
    || oldStyle.transformBox() != newStyle.transformBox()
    || oldStyle.transformOriginX() != newStyle.transformOriginX()
    || oldStyle.transformOriginY() != newStyle.transformOriginY()
    || oldStyle.transformOriginZ() != newStyle.transformOriginZ()
    || oldStyle.usedTransformStyle3D() != newStyle.usedTransformStyle3D()
    || oldStyle.perspective() != newStyle.perspective()
    || oldStyle.perspectiveOriginX() != newStyle.perspectiveOriginX()
    || oldStyle.perspectiveOriginY() != newStyle.perspectiveOriginY()
    || oldStyle.backfaceVisibility() != newStyle.backfaceVisibility()
    || !arePointingToEqualData(oldStyle.offsetPath(), newStyle.offsetPath())
    || oldStyle.offsetAnchor() != newStyle.offsetAnchor()
    || oldStyle.offsetPosition() != newStyle.offsetPosition()
    || oldStyle.offsetDistance() != newStyle.offsetDistance()
    || oldStyle.offsetRotate() != newStyle.offsetRotate()
    || !arePointingToEqualData(oldStyle.clipPath(), newStyle.clipPath())
    || oldStyle.overscrollBehaviorX() != newStyle.overscrollBehaviorX()
    || oldStyle.overscrollBehaviorY() != newStyle.overscrollBehaviorY()
}

private func recompositeChangeRequiresChildrenGeometryUpdate(
  oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
) -> Bool {
  return oldStyle.hasPerspective() != newStyle.hasPerspective()
    || oldStyle.usedTransformStyle3D() != newStyle.usedTransformStyle3D()
}

// FIXME: remove and never ask questions about reflection layers.
private func rendererForCompositingTests(layer: RenderLayerWrapper) -> RenderLayerModelObjectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

// RenderLayerCompositor manages the hierarchy of
// composited RenderLayers. It determines which RenderLayers
// become compositing, and creates and maintains a hierarchy of
// GraphicsLayers based on the RenderLayer painting order.
//
// There is one RenderLayerCompositor per RenderView.
final class RenderLayerCompositorWrapper: GraphicsLayerClientWrapper {
  init(renderView: RenderViewWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return true if this RenderView is in "compositing mode" (i.e. has one or more
  // composited RenderLayers)
  func usesCompositing() -> Bool { return m_compositing }

  // This will make a compositing layer at the root automatically, and hook up to
  // the native view/window system.
  func enableCompositingMode(enable: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // True when some content element other than the root is composited.
  func hasContentCompositingLayers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct RequiresCompositingData {
    var layoutUpToDate: LayoutUpToDate = .Yes
    var nonCompositedForPositionReason: RenderLayerWrapper.ViewportConstrainedNotCompositedReason =
      .NoNotCompositedReason
    var reevaluateAfterLayout = false
    let intrinsic = false
  }

  func fixedLayerIntersectsViewport(layer: RenderLayerWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Repaint the appropriate layers when the given RenderLayer starts or stops being composited.
  func repaintOnCompositingChange(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This method assumes that layout is up-to-date, unlike repaintOnCompositingChange().
  func repaintInCompositedAncestor(layer: RenderLayerWrapper, rect: LayoutRectWrapper) {
    let compositedAncestor = layer.enclosingCompositingLayerForRepaint(includeSelf: .ExcludeSelf)
      .layer
    if compositedAncestor == nil {
      return
    }

    assert(compositedAncestor!.backing != nil)
    var repaintRect = rect
    repaintRect.move(size: layer.offsetFromAncestor(ancestorLayer: compositedAncestor))
    compositedAncestor!.setBackingNeedsRepaintInRect(r: repaintRect)

    // The contents of this layer may be moving from a GraphicsLayer to the window,
    // so we need to make sure the window system synchronizes those changes on the screen.
    if compositedAncestor!.isRenderViewLayer {
      m_renderView.frameView().setNeedsOneShotDrawingSynchronization()
    }
  }

  // Notify us that a layer has been removed
  func layerWillBeRemoved(parent: RenderLayerWrapper, child: RenderLayerWrapper) {
    if parent.renderer().renderTreeBeingDestroyed() {
      return
    }

    if child.isComposited() {
      repaintInCompositedAncestor(layer: child, rect: child.backing!.compositedBounds())  // FIXME: do via dirty bits?
    } else if child.paintsIntoProvidedBacking() {
      let backingProviderLayer = child.backingProviderLayer!
      // FIXME: Optimize this repaint.
      backingProviderLayer.setBackingNeedsRepaint()
      backingProviderLayer.backing!.removeBackingSharingLayer(layer: child)
    } else {
      return
    }

    child.setNeedsCompositingLayerConnection()
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

    let layerChanged = updateBacking(layer: layer, queryData: &queryData)
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
      if layer.isComposited() {
        let hitTestingStateChanged =
          oldStyle != nil && (oldStyle!.usedPointerEvents() != newStyle.usedPointerEvents())
        if layer.renderer() is RenderWidgetWrapper || hitTestingStateChanged {
          // For RenderWidgets this is necessary to get iframe layers hooked up in response to scheduleInvalidateStyleAndLayerComposition().
          layer.setNeedsCompositingConfigurationUpdate()
        }
        // If we're changing to/from 0 opacity, then we need to reconfigure the layer since we try to
        // skip backing store allocation for opacity:0.
        if oldStyle != nil && oldStyle!.opacity() != newStyle.opacity()
          && (oldStyle!.opacity() == 0 || newStyle.opacity() == 0)
        {
          layer.setNeedsCompositingConfigurationUpdate()
        }
      }
      if oldStyle != nil
        && recompositeChangeRequiresGeometryUpdate(oldStyle: oldStyle!, newStyle: newStyle)
      {
        // FIXME: transform changes really need to trigger layout. See RenderElement::adjustStyleDifference().
        layer.setNeedsPostLayoutCompositingUpdate()
        layer.setNeedsCompositingGeometryUpdate()
      }
      if oldStyle != nil
        && recompositeChangeRequiresChildrenGeometryUpdate(oldStyle: oldStyle!, newStyle: newStyle)
      {
        layer.setChildrenNeedCompositingGeometryUpdate()
      }
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

  func updateRootLayerAttachment() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerBecameNonComposited(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameContentsCompositor(renderer: RenderWidgetWrapper) -> RenderLayerCompositorWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func useCoordinatedScrollingForLayer(layer: RenderLayerWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateRootContentLayerClipping() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  class BackingSharingState {
    struct Provider {
      let providerLayer: RenderLayerWrapper? = nil
      let sharingLayers = ListSet<RenderLayerWrapper, ObjectIdentifier>()
      let absoluteBounds = LayoutRectWrapper()
    }

    func backingProviderForLayer(layer: RenderLayerWrapper) -> Provider? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    // Add a layer that would repaint into a layer in m_backingSharingLayers.
    // That repaint has to wait until we've set the provider's backing-sharing layers.
    func addLayerNeedingRepaint(layer: RenderLayerWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    let backingProviderCandidates: [Provider] = []
  }

  // Whether the given RL needs a compositing layer.
  func needsToBeComposited(layer: RenderLayerWrapper, queryData: RequiresCompositingData) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private enum BackingRequired {
    case No
    case Yes
    case Unknown
  }

  private func updateBacking(
    layer: RenderLayerWrapper, queryData: inout RequiresCompositingData,
    backingSharingState: BackingSharingState? = nil, backingRequired: BackingRequired = .Unknown
  ) -> Bool {
    var layerChanged = false
    var backingRequired = backingRequired
    if backingRequired == .Unknown {
      backingRequired = needsToBeComposited(layer: layer, queryData: queryData) ? .Yes : .No
    } else {
      // Need to fetch viewportConstrainedNotCompositedReason, but without doing all the work that needsToBeComposited does.
      requiresCompositingForPosition(
        renderer: rendererForCompositingTests(layer: layer), layer: layer, queryData: &queryData)
    }

    if backingRequired == .Yes {
      // If we need to repaint, do so before making backing and disconnecting from the backing provider layer.
      if layer.backing == nil {
        repaintLayer(layer: layer, backingSharingState: backingSharingState)
      }

      layer.disconnectFromBackingProviderLayer()

      enableCompositingMode()

      if layer.backing == nil {
        layer.ensureBacking()

        if layer.isRenderViewLayer && useCoordinatedScrollingForLayer(layer: layer) {
          let frameView = m_renderView.frameView()
          if let scrollingCoordinator = scrollingCoordinator() {
            scrollingCoordinator.frameViewRootLayerDidChange(frameView: frameView)
          }
          updateRootContentLayerClipping()

          if let tiledBacking = layer.backing!.tiledBacking() {
            tiledBacking.setTopContentInset(topContentInset: frameView.topContentInset())
          }
        }

        // This layer and all of its descendants have cached repaints rects that are relative to
        // the repaint container, so change when compositing changes; we need to update them here.
        if layer.parent() != nil {
          layer.computeRepaintRectsIncludingDescendants()
        }

        layer.setNeedsCompositingGeometryUpdate()
        layer.setNeedsCompositingConfigurationUpdate()
        layer.setNeedsCompositingPaintOrderChildrenUpdate()

        layerChanged = true
      }
    } else {
      if layer.backing != nil {
        // If we're removing backing on a reflection, clear the source GraphicsLayer's pointer to
        // its replica GraphicsLayer. In practice this should never happen because reflectee and reflection
        // are both either composited, or not composited.
        if layer.isReflection() {
          let sourceLayer = (layer.renderer().parent()! as! RenderLayerModelObjectWrapper).layer()
          if let backing = sourceLayer!.backing {
            assert(optEq(backing.graphicsLayer()!.replicaLayer(), layer.backing!.graphicsLayer()))
            backing.graphicsLayer()!.setReplicatedByLayer(layer: nil)
          }
        }

        layer.clearBacking()
        layerChanged = true

        // This layer and all of its descendants have cached repaints rects that are relative to
        // the repaint container, so change when compositing changes; we need to update them here,
        // as long as shared backing isn't going to change our repaint container.
        if !repaintTargetsSharedBacking(layer: layer, backingSharingState: backingSharingState) {
          layer.computeRepaintRectsIncludingDescendants()
        }

        // If we need to repaint, do so now that we've removed the backing.
        repaintLayer(layer: layer, backingSharingState: backingSharingState)
      }
    }

    if layerChanged {
      if let renderWidget = layer.renderer() as? RenderWidgetWrapper {
        if let innerCompositor = frameContentsCompositor(renderer: renderWidget),
          innerCompositor.usesCompositing()
        {
          innerCompositor.updateRootLayerAttachment()
        }
      }
    }

    if layerChanged {
      layer.clearClipRectsIncludingDescendants(typeToClear: .PaintingClipRects)
    }

    // If a fixed position layer gained/lost a backing or the reason not compositing it changed,
    // the scrolling coordinator needs to recalculate whether it can do fast scrolling.
    if layer.renderer().isFixedPositioned() {
      if layer.viewportConstrainedNotCompositedReason != queryData.nonCompositedForPositionReason {
        layer.setViewportConstrainedNotCompositedReason(
          reason: queryData.nonCompositedForPositionReason)
        layerChanged = true
      }
      if layerChanged, let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.frameViewFixedObjectsDidChange(frameView: m_renderView.frameView())
      }
    } else {
      layer.setViewportConstrainedNotCompositedReason(reason: .NoNotCompositedReason)
    }

    if let layerBacking = layer.backing {
      layerBacking.updateDebugIndicators(
        showBorder: m_showDebugBorders, showRepaintCounter: m_showRepaintCounter)
    }

    return layerChanged
  }

  private func repaintTargetsSharedBacking(
    layer: RenderLayerWrapper, backingSharingState: BackingSharingState?
  ) -> Bool {
    return backingSharingState != nil
      && layerRepaintTargetsBackingSharingLayer(layer: layer, sharingState: backingSharingState!)
  }

  private func repaintLayer(layer: RenderLayerWrapper, backingSharingState: BackingSharingState?) {
    if repaintTargetsSharedBacking(layer: layer, backingSharingState: backingSharingState) {
      print(
        "Layer \(layer)  needs to repaint into potential backing-sharing layer, postponing repaint")
      backingSharingState!.addLayerNeedingRepaint(layer: layer)
    } else {
      repaintOnCompositingChange(layer: layer)
    }
  }

  private func layerRepaintTargetsBackingSharingLayer(
    layer: RenderLayerWrapper, sharingState: BackingSharingState
  ) -> Bool {
    if sharingState.backingProviderCandidates.isEmpty {
      return false
    }

    var currLayer: RenderLayerWrapper? = layer
    while currLayer != nil {
      if compositedWithOwnBackingStore(layer: currLayer!) {
        return false
      }

      if currLayer!.paintsIntoProvidedBacking() {
        return false
      }

      if sharingState.backingProviderForLayer(layer: currLayer!) != nil {
        return true
      }

      currLayer = currLayer!.paintOrderParent()
    }

    return false
  }

  private func scrollingCoordinator() -> ScrollingCoordinatorWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  private func requiresCompositingForPosition(
    renderer: RenderLayerModelObjectWrapper, layer: RenderLayerWrapper,
    queryData: inout RequiresCompositingData
  ) -> Bool {
    // position:fixed elements that create their own stacking context (e.g. have an explicit z-index,
    // opacity, transform) can get their own composited layer. A stacking context is required otherwise
    // z-index and clipping will be broken.
    if !renderer.isPositioned() {
      return false
    }

    let position = renderer.style().position()
    let isFixed = renderer.isFixedPositioned()
    if isFixed && !layer.isStackingContext() {
      return false
    }

    let isSticky = renderer.isInFlowPositioned() && position == .Sticky
    if !isFixed && !isSticky {
      return false
    }

    // FIXME: acceleratedCompositingForFixedPositionEnabled should probably be renamed acceleratedCompositingForViewportConstrainedPositionEnabled().
    if !m_renderView.settings().acceleratedCompositingForFixedPositionEnabled() {
      return false
    }

    if isSticky {
      return isAsyncScrollableStickyLayer(layer: layer)
    }

    if queryData.layoutUpToDate == .No {
      queryData.reevaluateAfterLayout = true
      return layer.isComposited()
    }

    let container = renderer.container()
    assert(container != nil)

    // Don't promote fixed position elements that are descendants of a non-view container, e.g. transformed elements.
    // They will stay fixed wrt the container rather than the enclosing frame.
    if CPtrToInt(container!.p) != CPtrToInt(m_renderView.p) {
      queryData.nonCompositedForPositionReason = .NotCompositedForNonViewContainer
      return false
    }

    let paintsContent = layer.isVisuallyNonEmpty() || layer.hasVisibleDescendant
    if !paintsContent {
      queryData.nonCompositedForPositionReason = .NotCompositedForNoVisibleContent
      return false
    }

    let intersectsViewport = fixedLayerIntersectsViewport(layer: layer)
    if !intersectsViewport {
      queryData.nonCompositedForPositionReason = .NotCompositedForBoundsOutOfView
      print("Layer \(layer) is outside the viewport")
      return false
    }

    return true
  }

  private static func styleChangeMayAffectIndirectCompositingReasons(
    oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
  ) -> Bool {
    if RenderElementWrapper.createsGroupForStyle(style: newStyle)
      != RenderElementWrapper.createsGroupForStyle(style: oldStyle)
    {
      return true
    }
    if newStyle.isolation() != oldStyle.isolation() {
      return true
    }
    if newStyle.hasTransform() != oldStyle.hasTransform() {
      return true
    }
    if optEq(newStyle.boxReflect(), oldStyle.boxReflect()) {
      return true
    }
    if newStyle.usedTransformStyle3D() != oldStyle.usedTransformStyle3D() {
      return true
    }
    if newStyle.hasPerspective() != oldStyle.hasPerspective() {
      return true
    }

    return false
  }

  // FIXME: make the coordinated/async terminology consistent.
  func isAsyncScrollableStickyLayer(layer: RenderLayerWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_renderView: RenderViewWrapper

  private let m_showDebugBorders = false
  private let m_showRepaintCounter = false

  private let m_compositing = false
}
