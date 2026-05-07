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

import wk_interop

enum CompositingUpdateType {
  case AfterStyleChange
  case AfterLayout
  case OnScroll
  case OnCompositedScroll
}

struct ScrollingTreeState {
  init() { self.init(parentNodeID: nil, nextChildIndex: 0) }

  init(parentNodeID: ScrollingNodeIDWrapper?, nextChildIndex: UInt64) {
    self.parentNodeID = parentNodeID
    self.nextChildIndex = nextChildIndex
  }

  var parentNodeID: ScrollingNodeIDWrapper?
  var nextChildIndex: UInt64
  var needSynchronousScrollingReasonsUpdate = false
}

class ScrollingTreeStateRef {
  init(_ v: ScrollingTreeState) { self.v = v }

  var v: ScrollingTreeState
}

struct ScrollCoordinationRole: OptionSet {
  let rawValue: UInt8

  static let ViewportConstrained = ScrollCoordinationRole(rawValue: 1 << 0)
  static let Scrolling = ScrollCoordinationRole(rawValue: 1 << 1)
  static let ScrollingProxy = ScrollCoordinationRole(rawValue: 1 << 2)
  static let FrameHosting = ScrollCoordinationRole(rawValue: 1 << 3)
  static let PluginHosting = ScrollCoordinationRole(rawValue: 1 << 4)
  static let Positioning = ScrollCoordinationRole(rawValue: 1 << 5)
}

private let allScrollCoordinationRoles: ScrollCoordinationRole = [
  .Scrolling,
  .ScrollingProxy,
  .ViewportConstrained,
  .FrameHosting,
  .PluginHosting,
  .Positioning,
]

private struct BackingSharingSequenceIdentifierWrapper: Equatable {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func generate() -> BackingSharingSequenceIdentifierWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private func frameHostingNodeForFrame(_ frame: LocalFrameWrapper) -> ScrollingNodeIDWrapper? {
  if frame.document() == nil || frame.view() == nil {
    return nil
  }

  // Find the frame's enclosing layer in our render tree.
  let ownerElement = frame.document()!.ownerElement()
  if ownerElement == nil {
    return nil
  }

  let widgetRenderer = ownerElement!.renderer() as? RenderWidgetWrapper
  if widgetRenderer == nil {
    return nil
  }

  if !widgetRenderer!.hasLayer() || !widgetRenderer!.layer()!.isComposited() {
    // TODO(asuhan): add logging
    return nil
  }

  let frameHostingNodeID = widgetRenderer!.layer()!.backing!.scrollingNodeIDForRole(
    role: .FrameHosting)

  return frameHostingNodeID
}

private func clippingChanged(oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper) -> Bool {
  return oldStyle.overflowX() != newStyle.overflowX()
    || oldStyle.overflowY() != newStyle.overflowY()
    || oldStyle.hasClip() != newStyle.hasClip() || oldStyle.clip() != newStyle.clip()
}

private func styleAffectsLayerGeometry(style: RenderStyleWrapper) -> Bool {
  return style.hasClip() || style.clipPath() != nil || style.hasBorderRadius()
}

func optEq<T: AnyObject>(_ a: T?, _ b: T?) -> Bool {
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
  var renderer = layer.renderer()

  // The compositing state of a reflection should match that of its reflected layer.
  if layer.isReflection() {
    renderer = renderer.parent() as! RenderLayerModelObjectWrapper  // The RenderReplica's parent is the object being reflected.
  }

  return renderer
}

private enum AncestorTraversal {
  case Continue
  case Stop
}

// This is a simplified version of containing block walking that only handles absolute and fixed position.
@discardableResult
private func traverseAncestorLayers(
  _ layer: RenderLayerWrapper,
  _ function: (RenderLayerWrapper, Bool, Bool) -> AncestorTraversal
) -> AncestorTraversal {
  var positioningBehavior = layer.renderer().style().position()
  var nextPaintOrderParent = layer.paintOrderParent()

  var ancestorLayer = layer.parent()
  while ancestorLayer != nil {
    var inContainingBlockChain = true

    switch positioningBehavior {
    case .Static, .Relative, .Sticky:
      break
    case .Absolute:
      inContainingBlockChain = ancestorLayer!.renderer().canContainAbsolutelyPositionedObjects()
    case .Fixed:
      inContainingBlockChain = ancestorLayer!.renderer().canContainFixedPositionObjects()
    }

    let isPaintOrderAncestor =
      CPtrToInt(ancestorLayer!.layerId()) == CPtrToInt(nextPaintOrderParent?.layerId())
    if function(ancestorLayer!, inContainingBlockChain, isPaintOrderAncestor) == .Stop {
      return .Stop
    }

    if inContainingBlockChain {
      positioningBehavior = ancestorLayer!.renderer().style().position()
    }

    if isPaintOrderAncestor {
      nextPaintOrderParent = ancestorLayer!.paintOrderParent()
    }

    ancestorLayer = ancestorLayer!.parent()
  }

  return .Continue
}

private func frameContentsRenderView(_ renderer: RenderWidgetWrapper) -> RenderViewWrapper? {
  return renderer.frameOwnerElement().contentDocument()?.renderView()
}

private func canUseDescendantClippingLayer(_ layer: RenderLayerWrapper) -> Bool {
  if layer.isolatesCompositedBlending() {
    return false
  }

  // We can only use the "descendant clipping layer" strategy when the clip rect is entirely within
  // the border box, because of interactions with border-radius clipping and compositing.
  if let renderer = layer.renderBox(), renderer.hasClip() {
    let borderBoxRect = renderer.borderBoxRect()
    let clipRect = renderer.clipRect(location: LayoutPointWrapper(), fragment: nil)

    let clipRectInsideBorderRect = intersection(a: borderBoxRect, b: clipRect) == clipRect
    return clipRectInsideBorderRect
  }

  return true
}

private func styleHas3DTransformOperation(style: RenderStyleWrapper) -> Bool {
  return style.transform().has3DOperation()
    || (style.translate() != nil && style.translate()!.is3DOperation())
    || (style.scale() != nil && style.scale()!.is3DOperation())
    || (style.rotate() != nil && style.rotate()!.is3DOperation())
}

private func styleTransformOperationsAreRepresentableIn2D(style: RenderStyleWrapper) -> Bool {
  return style.transform().isRepresentableIn2D()
    && (style.translate() != nil || style.translate()!.isRepresentableIn2D())
    && (style.scale() != nil || style.scale()!.isRepresentableIn2D())
    && (style.rotate() != nil || style.rotate()!.isRepresentableIn2D())
}

private func collectStationaryLayerRelatedOverflowNodes(_ layer: RenderLayerWrapper)
  -> [ScrollingNodeIDWrapper]
{
  var scrollingNodes: [ScrollingNodeIDWrapper] = []

  let appendOverflowLayerNodeID = { (overflowLayer: RenderLayerWrapper) in
    assert(overflowLayer.isComposited())
    if overflowLayer.isComposited() {
      let scrollingNodeID = overflowLayer.backing!.scrollingNodeIDForRole(role: .Scrolling)
      if scrollingNodeID.bool() {
        scrollingNodes.append(scrollingNodeID)
        return
      }
    }
    // TODO(asuhan): add logging
  }

  // Collect all the composited scrollers which affect the position of this layer relative to its compositing ancestor (which might be inside the scroller or the scroller itself).
  var seenPaintOrderAncestor = false
  traverseAncestorLayers(
    layer,
    {
      (ancestorLayer: RenderLayerWrapper, isContainingBlockChain: Bool, isPaintOrderAncestor: Bool)
      in
      seenPaintOrderAncestor = seenPaintOrderAncestor || isPaintOrderAncestor
      if isContainingBlockChain && isPaintOrderAncestor {
        return .Stop
      }

      if seenPaintOrderAncestor && !isContainingBlockChain
        && ancestorLayer.hasCompositedScrollableOverflow()
      {
        appendOverflowLayerNodeID(ancestorLayer)
      }

      return .Continue
    })

  return scrollingNodes
}

private func collectRelatedCoordinatedScrollingNodes(
  _ layer: RenderLayerWrapper, _ positioningBehavior: ScrollPositioningBehavior
) -> [ScrollingNodeIDWrapper] {
  switch positioningBehavior {
  case .Stationary:
    if layer.ancestorCompositingLayer() != nil {
      return collectStationaryLayerRelatedOverflowNodes(layer)
    }
    return []
  case .Moves, .None:
    fatalError("Not reached")
  }
}

private func scrollCoordinationRoleForNodeType(_ nodeType: ScrollingNodeType)
  -> ScrollCoordinationRole
{
  switch nodeType {
  case .MainFrame, .Subframe, .Overflow, .PluginScrolling:
    return .Scrolling
  case .OverflowProxy:
    return .ScrollingProxy
  case .FrameHosting:
    return .FrameHosting
  case .PluginHosting:
    return .PluginHosting
  case .Fixed, .Sticky:
    return .ViewportConstrained
  case .Positioned:
    return .Positioning
  }
}

// RenderLayerCompositor manages the hierarchy of
// composited RenderLayers. It determines which RenderLayers
// become compositing, and creates and maintains a hierarchy of
// GraphicsLayers based on the RenderLayer painting order.
//
// There is one RenderLayerCompositor per RenderView.
final class RenderLayerCompositorWrapper: GraphicsLayerClientWrapper {
  private struct OverlapExtent {
    func knownToBeHaveExtentUncertainty() -> Bool {
      return extentComputed && animationCausesExtentUncertainty
    }

    var bounds = LayoutRectWrapper()
    var clippingScopes: LayerOverlapMap.LayerAndBoundsVector = []

    var extentComputed = false
    var hasTransformAnimation = false
    var animationCausesExtentUncertainty = false
    var clippingScopesComputed = false
  }

  private struct CompositingState {
    init(compAncestor: RenderLayerWrapper?, testOverlap: Bool = true) {
      compositingAncestor = compAncestor
      testingOverlap = testOverlap
    }

    func stateForPaintOrderChildren(_ layer: RenderLayerWrapper) -> CompositingState {
      var childState = CompositingState(compAncestor: compositingAncestor)
      if layer.isStackingContext() {
        childState.stackingContextAncestor = layer
      } else {
        childState.stackingContextAncestor = stackingContextAncestor
      }

      childState.backingSharingAncestor = backingSharingAncestor
      childState.subtreeIsCompositing = false
      childState.testingOverlap = testingOverlap
      childState.fullPaintOrderTraversalRequired = fullPaintOrderTraversalRequired
      childState.descendantsRequireCompositingUpdate = descendantsRequireCompositingUpdate
      childState.ancestorHasTransformAnimation = ancestorHasTransformAnimation
      childState.hasCompositedNonContainedDescendants = false
      childState.hasNotIsolatedCompositedBlendingDescendants = false  // FIXME: should this only be reset for stacking contexts?
      childState.hasBackdropFilterDescendantsWithoutRoot = false
      #if !LOG_DISABLED
        childState.depth = depth + 1
      #endif
      return childState
    }

    mutating func updateWithDescendantStateAndLayer(
      _ childState: CompositingState, layer: RenderLayerWrapper, ancestorLayer: RenderLayerWrapper?,
      _ layerExtent: OverlapExtent, _ isUnchangedSubtree: Bool = false
    ) {
      // Subsequent layers in the parent stacking context also need to composite.
      subtreeIsCompositing =
        subtreeIsCompositing || childState.subtreeIsCompositing || layer.isComposited()
      if !isUnchangedSubtree {
        fullPaintOrderTraversalRequired =
          fullPaintOrderTraversalRequired || childState.fullPaintOrderTraversalRequired
      }

      // Turn overlap testing off for later layers if it's already off, or if we have an animating transform.
      // Note that if the layer clips its descendants, there's no reason to propagate the child animation to the parent layers. That's because
      // we know for sure the animation is contained inside the clipping rectangle, which is already added to the overlap map.
      let canReenableOverlapTesting = { [layer] () in
        return layer.isComposited()
          && RenderLayerCompositorWrapper.clipsCompositingDescendants(layer)
      }
      if (!childState.testingOverlap && !canReenableOverlapTesting())
        || layerExtent.knownToBeHaveExtentUncertainty()
      {
        testingOverlap = false
      }

      let computeHasCompositedNonContainedDescendants = { [self] () in
        if hasCompositedNonContainedDescendants {
          return true
        }
        if ancestorLayer == nil {
          return false
        }
        if !layer.isComposited() {
          return false
        }
        if !layer.renderer().isOutOfFlowPositioned() {
          return false
        }
        if layer.ancestorLayerIsInContainingBlockChain(ancestor: ancestorLayer!) {
          return false
        }
        return true
      }

      hasCompositedNonContainedDescendants = computeHasCompositedNonContainedDescendants()

      if (layer.isComposited() && layer.hasBlendMode())
        || (layer.hasNotIsolatedCompositedBlendingDescendants
          && !layer.isolatesCompositedBlending())
      {
        hasNotIsolatedCompositedBlendingDescendants = true
      }

      if (layer.isComposited() && layer.hasBackdropFilter())
        || (layer.hasBackdropFilterDescendantsWithoutRoot && !layer.isBackdropRoot())
      {
        hasBackdropFilterDescendantsWithoutRoot = true
      }
    }

    func hasNonRootCompositedAncestor() -> Bool {
      return compositingAncestor != nil && !compositingAncestor!.isRenderViewLayer
    }

    var compositingAncestor: RenderLayerWrapper?
    var backingSharingAncestor: RenderLayerWrapper? = nil
    var stackingContextAncestor: RenderLayerWrapper? = nil
    var subtreeIsCompositing = false
    var testingOverlap = true
    var fullPaintOrderTraversalRequired = false
    var descendantsRequireCompositingUpdate = false
    var ancestorHasTransformAnimation = false
    var hasCompositedNonContainedDescendants = false
    var hasNotIsolatedCompositedBlendingDescendants = false
    var hasBackdropFilterDescendantsWithoutRoot = false
    #if !LOG_DISABLED
      var depth: UInt32 = 0
    #endif
  }

  private struct UpdateBackingTraversalState {
    init(
      compAncestor: RenderLayerWrapper? = nil, clippedLayers: ArraySlice<RenderLayerWrapper>? = nil,
      overflowScrollers: ArraySlice<RenderLayerWrapper>? = nil
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func stateForDescendants() -> UpdateBackingTraversalState {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    var compositingAncestor: RenderLayerWrapper?

    // List of layers in the current stacking context that are clipped by ancestor scrollers.
    var layersClippedByScrollers: ArraySlice<RenderLayerWrapper>
    // List of layers with composited overflow:scroll.
    var overflowScrollLayers: ArraySlice<RenderLayerWrapper>
  }

  init(_ renderView: RenderViewWrapper) {
    assert(renderView.isNativeImpl())
    pInterop = wk_interop.RenderLayerCompositor_create(renderView.getWk())
    self.m_renderView = nil
    self.m_updateCompositingLayersTimer = Timer()
    self.scrollingNodeToLayerMap = [:]
  }

  deinit { wk_interop.RenderLayerCompositor_destroy(interop()) }

  // Return true if this RenderView is in "compositing mode" (i.e. has one or more
  // composited RenderLayers)
  func usesCompositing() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderLayerCompositor_usesCompositing(interop())
    }
    return m_compositing
  }

  // This will make a compositing layer at the root automatically, and hook up to
  // the native view/window system.
  func enableCompositingMode(enable: Bool = true) {
    assert(isNativeImpl())
    if enable != m_compositing {
      m_compositing = enable

      if m_compositing {
        ensureRootLayer()
        notifyIFramesOfCompositingChange()
      } else {
        destroyRootLayer()
      }

      m_renderView!.layer()!.setNeedsPostLayoutCompositingUpdate()
    }
  }

  // True when some content element other than the root is composited.
  func hasContentCompositingLayers() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderLayerCompositor_hasContentCompositingLayers(interop())
    }
    return contentLayersCount != 0
  }

  // Rebuild the tree of compositing layers
  func updateCompositingLayers(
    updateType: CompositingUpdateType, updateRoot: RenderLayerWrapper? = nil
  ) -> Bool {
    assert(isNativeImpl())
    // TODO(asuhan): add logging and tree debugging
    let unused = TraceScope(.CompositingUpdateStart, .CompositingUpdateEnd)
    use(unused)

    if updateType == .AfterStyleChange || updateType == .AfterLayout {
      cacheAcceleratedCompositingFlagsAfterLayout()  // Some flags (e.g. forceCompositingMode) depend on layout.
    }

    m_updateCompositingLayersTimer.stop()

    assert(
      m_renderView!.document().backForwardCacheState() == .NotInBackForwardCache
        || m_renderView!.document().backForwardCacheState() == .AboutToEnterBackForwardCache)

    // Compositing layers will be updated in Document::setVisualUpdatesAllowed(bool) if suppressed here.
    if !m_renderView!.document().visualUpdatesAllowed() {
      return false
    }

    // Avoid updating the layers with old values. Compositing layers will be updated after the layout is finished.
    // This happens when m_updateCompositingLayersTimer fires before layout is updated.
    if m_renderView!.needsLayout() {
      return false
    }

    if !m_compositing
      && (m_forceCompositingMode
        || (isRootFrameCompositor() && page().pageOverlayController().overlayCount() != 0))
    {
      enableCompositingMode(enable: true)
    }

    let isPageScroll =
      updateRoot == nil
      || CPtrToInt(updateRoot!.layerId()) == CPtrToInt(rootRenderLayer().layerId())
    let updateRoot = rootRenderLayer()

    if updateType == .OnScroll || updateType == .OnCompositedScroll {
      // We only get here if we didn't scroll on the scrolling thread, so this update needs to re-position viewport-constrained layers.
      if m_renderView!.settings().acceleratedCompositingForFixedPositionEnabled() && isPageScroll,
        let viewportConstrainedObjects = m_renderView!.frameView().viewportConstrainedObjects()
      {
        for renderer in viewportConstrainedObjects {
          if let layer = renderer.layer() {
            layer.setNeedsCompositingGeometryUpdate()
          }
        }
      }

      // Scrolling can affect overlap. FIXME: avoid for page scrolling.
      updateRoot.setDescendantsNeedCompositingRequirementsTraversal()
    }

    if updateType == .AfterLayout {
      // Ensure that post-layout updates push new scroll position and viewport rects onto the root node.
      rootRenderLayer().setNeedsScrollingTreeUpdate()
    }

    if !updateRoot.hasDescendantNeedingCompositingRequirementsTraversal() && !m_compositing {
      return true
    }

    if !updateRoot.needsAnyCompositingTraversal() {
      return true
    }

    m_compositingUpdateCount += 1

    // FIXME: optimize root-only update.
    if updateRoot.hasDescendantNeedingCompositingRequirementsTraversal()
      || updateRoot.needsCompositingRequirementsTraversal()
    {
      let rootLayer = rootRenderLayer()
      var compositingState = CompositingState(compAncestor: updateRoot)
      let backingSharingState = BackingSharingState(
        allowOverlappingProviders: m_renderView!.settings()
          .overlappingBackingStoreProvidersEnabled()
      )
      let overlapMap = LayerOverlapMap(rootLayer: rootLayer)

      var descendantHas3DTransform = false
      computeCompositingRequirements(
        ancestorLayer: nil, layer: rootLayer, overlapMap, &compositingState, backingSharingState,
        &descendantHas3DTransform
      )
    }

    if updateRoot.hasDescendantNeedingUpdateBackingOrHierarchyTraversal()
      || updateRoot.needsUpdateBackingOrHierarchyTraversal()
    {
      // TODO(asuhan): assert layersWithUnresolvedRelations is empty (ignoring nulls)
      let scrollingTreeState = ScrollingTreeStateRef(
        ScrollingTreeState(
          parentNodeID: ScrollingNodeIDWrapper(), nextChildIndex: 0))

      if !m_renderView!.frame().isMainFrame() {
        scrollingTreeState.v.parentNodeID = frameHostingNodeForFrame(m_renderView!.frame())
      }

      let scrollingCoordinator = scrollingCoordinator()
      let hadSubscrollers =
        scrollingCoordinator != nil
        ? scrollingCoordinator!.hasSubscrollers(m_renderView!.frame().rootFrame().frameID()) : false

      var traversalState = UpdateBackingTraversalState()
      var childList: [GraphicsLayer] = []
      updateBackingAndHierarchy(updateRoot, &childList[...], &traversalState, scrollingTreeState)

      if scrollingTreeState.v.needSynchronousScrollingReasonsUpdate {
        updateSynchronousScrollingNodes()
      }

      // Host the document layer in the RenderView's root layer.
      appendDocumentOverlayLayers(&childList[...])
      // Even when childList is empty, don't drop out of compositing mode if there are
      // composited layers that we didn't hit in our traversal (e.g. because of visibility:hidden).
      if childList.isEmpty && !needsCompositingForContentOrOverlays() {
        destroyRootLayer()
      } else if m_rootContentsLayer != nil {
        m_rootContentsLayer!.setChildren(newChildren: childList)
      }

      if scrollingCoordinator != nil
        && scrollingCoordinator!.hasSubscrollers(m_renderView!.frame().rootFrame().frameID())
          != hadSubscrollers
      {
        invalidateEventRegionForAllFrames()
      }

      resolveScrollingTreeRelationships()
    }

    // FIXME: Only do if dirty.
    updateRootLayerPosition()

    // TODO(asuhan): call into InspectorInstrumentation

    if m_renderView!.needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() {
      m_renderView!.repaintRootContents()
      m_renderView!.setNeedsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(false)
    }

    return true
  }

  // This is only used when state changes and we do not exepect a style update or layout to happen soon (e.g. when
  // we discover that an iframe is overlapped during painting).
  func scheduleCompositingLayerUpdate() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct RequiresCompositingData {
    var layoutUpToDate: LayoutUpToDate = .Yes
    var nonCompositedForPositionReason: RenderLayerWrapper.ViewportConstrainedNotCompositedReason =
      .NoNotCompositedReason
    var reevaluateAfterLayout = false
    var intrinsic = false
  }

  // Whether layer's backing needs a graphics layer to do clipping by an ancestor (non-stacking-context parent with overflow).
  // Return true if the given layer has some ancestor in the RenderLayer hierarchy that clips,
  // up to the enclosing compositing ancestor. This is required because compositing layers are parented
  // according to the z-order hierarchy, yet clipping goes down the renderer hierarchy.
  // Thus, a RenderLayer can be clipped by a RenderLayer that is an ancestor in the renderer hierarchy,
  // but a sibling in the z-order hierarchy.
  // FIXME: can we do this without a tree walk?
  func clippedByAncestor(_ layer: RenderLayerWrapper, _ compositingAncestor: RenderLayerWrapper?)
    -> Bool
  {
    assert(isNativeImpl())
    assert(layer.isComposited())
    if compositingAncestor == nil {
      return false
    }

    if layer.renderer().capturedInViewTransition() {
      return false
    }

    // If the compositingAncestor clips, that will be taken care of by clipsCompositingDescendants(),
    // so we only care about clipping between its first child that is our ancestor (the computeClipRoot),
    // and layer. The exception is when the compositingAncestor isolates composited blending children,
    // in this case it is not allowed to clipsCompositingDescendants() and each of its children
    // will be clippedByAncestor()s, including the compositingAncestor.
    var computeClipRoot = compositingAncestor
    if canUseDescendantClippingLayer(compositingAncestor!) {
      computeClipRoot = nil
      var parent: RenderLayerWrapper? = layer
      while parent != nil {
        let next = parent!.parent()
        if CPtrToInt(next?.layerId()) == CPtrToInt(compositingAncestor?.layerId()) {
          computeClipRoot = parent
          break
        }
        parent = next
      }

      if computeClipRoot == nil
        || CPtrToInt(computeClipRoot!.layerId()) == CPtrToInt(layer.layerId())
      {
        return false
      }
    }

    let backgroundClipRect = layer.backgroundClipRect(
      clipRectsContext: RenderLayerWrapper.ClipRectsContext(
        inRootLayer: computeClipRoot, inClipRectsType: .TemporaryClipRects))
    return !backgroundClipRect.isInfinite()  // FIXME: Incorrect for CSS regions.
  }

  func updateAncestorClippingStack(
    _ layer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the ScrollingNodeID for the containing async-scrollable layer that scrolls this renderer's border box.
  // May return 0 for position-fixed content.
  // Note that this returns the ScrollingNodeID of the scroller this layer is embedded in, not the layer's own ScrollingNodeID if it has one.
  private static func asyncScrollableContainerNodeID(_ renderer: RenderObjectWrapper)
    -> ScrollingNodeIDWrapper
  {
    guard let enclosingLayer = renderer.enclosingLayer() else {
      return ScrollingNodeIDWrapper()
    }

    let layerScrollingNodeID = { (layer: RenderLayerWrapper) -> ScrollingNodeIDWrapper in
      if layer.isComposited() {
        return layer.backing!.scrollingNodeIDForRole(role: .Scrolling)
      }
      return ScrollingNodeIDWrapper()
    }

    // If the renderer is inside the layer, we care about the layer's scrollability. Otherwise, we let traverseAncestorLayers look at ancestors.
    if !renderer.hasLayer() {
      let scrollingNodeID = layerScrollingNodeID(enclosingLayer)
      if scrollingNodeID.bool() {
        return scrollingNodeID
      }
    }

    var containerScrollingNodeID = ScrollingNodeIDWrapper()
    traverseAncestorLayers(
      enclosingLayer,
      {
        (
          ancestorLayer: RenderLayerWrapper, isContainingBlockChain: Bool,
          isPaintOrderAncestor: Bool
        )
        in
        if isContainingBlockChain && ancestorLayer.hasCompositedScrollableOverflow() {
          containerScrollingNodeID = layerScrollingNodeID(ancestorLayer)
          return .Stop
        }
        return .Continue
      })

    return containerScrollingNodeID
  }

  // Whether layer's backing needs a graphics layer to clip z-order children of the given layer.
  // Return true if the given layer is a stacking context and has compositing child
  // layers that it needs to clip. In this case we insert a clipping GraphicsLayer
  // into the hierarchy between this layer and its children in the z-order hierarchy.
  static func clipsCompositingDescendants(_ layer: RenderLayerWrapper) -> Bool {
    if !(layer.hasCompositingDescendant && layer.renderer().hasClipOrNonVisibleOverflow()) {
      return false
    }

    if layer.hasCompositedNonContainedDescendants {
      return false
    }

    return canUseDescendantClippingLayer(layer)
  }

  // Whether the given layer needs an extra 'contents' layer.
  // If an element has composited negative z-index children, those children render in front of the
  // layer background, so we need an extra 'contents' layer for the foreground of the layer object.
  func needsContentsCompositingLayer(_ layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    for layer in layer.negativeZOrderLayers() {
      if layer.isComposited() || layer.hasCompositingDescendant {
        return true
      }
    }

    return false
  }

  func fixedLayerIntersectsViewport(layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    assert(layer.renderer().isFixedPositioned())

    // Fixed position elements that are invisible in the current view don't get their own layer.
    // FIXME: We shouldn't have to check useFixedLayout() here; one of the viewport rects needs to give the correct answer.
    var viewBounds = LayoutRectWrapper()
    if m_renderView!.frameView().useFixedLayout() {
      viewBounds = LayoutRectWrapper(rect: m_renderView!.unscaledDocumentRect())
    } else {
      viewBounds = m_renderView!.frameView().rectForFixedPositionLayout()
    }

    let layerBounds = layer.calculateLayerBounds(
      ancestorLayer: layer, offsetFromRoot: LayoutSizeWrapper(),
      flags: [
        .UseLocalClipRectIfPossible, .IncludeFilterOutsets, .UseFragmentBoxesExcludingCompositing,
        .ExcludeHiddenDescendants, .DontConstrainForMask, .IncludeCompositedDescendants,
      ])
    // Map to m_renderView to ignore page scale.
    let absoluteBounds = layer.renderer().localToContainerQuad(
      localQuad: FloatQuad(inRect: layerBounds.FloatRect()), container: m_renderView
    )
    .boundingBox()
    return viewBounds.intersects(
      other: LayoutRectWrapper(rect: enclosingIntRect(rect: absoluteBounds)))
  }

  func supportsFixedRootBackgroundCompositing() -> Bool {
    assert(isNativeImpl())
    if let renderViewBacking = m_renderView!.layer()!.backing {
      return renderViewBacking.isFrameLayerWithTiledBacking
    }
    return false
  }

  func needsFixedRootBackgroundLayer(_ layer: RenderLayerWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fixedRootBackgroundLayer() -> GraphicsLayer? {
    assert(isNativeImpl())
    // Get the fixed root background from the RenderView layer's backing.
    let viewLayer = m_renderView!.layer()
    if viewLayer == nil {
      return nil
    }

    if viewLayer!.isComposited() && viewLayer!.backing!.backgroundLayerPaintsFixedRootBackground {
      return viewLayer!.backing!.backgroundLayer
    }

    return nil
  }

  // We can't rely on getting layerStyleChanged() for a style change that affects the root background, because the style change may
  // be on the body which has no RenderLayer.
  func rootOrBodyStyleChanged(renderer: RenderElementWrapper, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    if !usesCompositing() {
      return
    }

    var oldBackgroundColor = ColorWrapper()
    if oldStyle != nil {
      oldBackgroundColor = oldStyle!.visitedDependentColorWithColorFilter(
        colorProperty: .CSSPropertyBackgroundColor)
    }

    if oldBackgroundColor
      != renderer.style().visitedDependentColorWithColorFilter(
        colorProperty: .CSSPropertyBackgroundColor)
    {
      rootBackgroundColorOrTransparencyChanged()
    }

    let hadFixedBackground = oldStyle != nil && oldStyle!.hasEntirelyFixedBackground()
    if hadFixedBackground != renderer.style().hasEntirelyFixedBackground() {
      rootLayerConfigurationChanged()
    }

    if oldStyle != nil
      && (oldStyle!.overscrollBehaviorX() != renderer.style().overscrollBehaviorX()
        || oldStyle!.overscrollBehaviorY() != renderer.style().overscrollBehaviorY()),
      let layer = m_renderView!.layer()
    {
      layer.setNeedsCompositingGeometryUpdate()
    }
  }

  // Called after the view transparency, or the document or base background color change.
  func rootBackgroundColorOrTransparencyChanged() {
    if !isNativeImpl() {
      wk_interop.RenderLayerCompositor_rootBackgroundColorOrTransparencyChanged(interop())
      return
    }
    if !usesCompositing() {
      return
    }

    var backgroundColor: ColorWrapper? = ColorWrapper()
    let isTransparent = viewHasTransparentBackground(&backgroundColor)

    let extendedBackgroundColor =
      m_renderView!.settings().backgroundShouldExtendBeyondPage()
      ? backgroundColor! : ColorWrapper()

    let transparencyChanged = m_viewBackgroundIsTransparent != isTransparent
    let backgroundColorChanged = m_viewBackgroundColor != backgroundColor!
    let extendedBackgroundColorChanged = m_rootExtendedBackgroundColor != extendedBackgroundColor

    if !transparencyChanged && !backgroundColorChanged && !extendedBackgroundColorChanged {
      return
    }

    m_viewBackgroundIsTransparent = isTransparent
    m_viewBackgroundColor = backgroundColor!
    m_rootExtendedBackgroundColor = extendedBackgroundColor

    if extendedBackgroundColorChanged {
      page().chrome().client().pageExtendedBackgroundColorDidChange()
    }

    rootLayerConfigurationChanged()
  }

  // Repaint the appropriate layers when the given RenderLayer starts or stops being composited.
  func repaintOnCompositingChange(layer: RenderLayerWrapper) {
    assert(isNativeImpl())
    // If the renderer is not attached yet, no need to repaint.
    if CPtrToInt(layer.renderer().id()) != CPtrToInt(m_renderView!.id())
      && layer.renderer().parent() == nil
    {
      return
    }

    var repaintContainer = layer.renderer().containerForRepaint().renderer
    if repaintContainer == nil {
      repaintContainer = m_renderView
    }

    layer.repaintIncludingNonCompositingDescendants(repaintContainer: repaintContainer)
    if CPtrToInt(repaintContainer?.id()) == CPtrToInt(m_renderView!.id()) {
      // The contents of this layer may be moving between the window
      // and a GraphicsLayer, so we need to make sure the window system
      // synchronizes those changes on the screen.
      m_renderView!.frameView().setNeedsOneShotDrawingSynchronization()
    }
  }

  // This method assumes that layout is up-to-date, unlike repaintOnCompositingChange().
  func repaintInCompositedAncestor(layer: RenderLayerWrapper, rect: LayoutRectWrapper) {
    assert(isNativeImpl())
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
      m_renderView!.frameView().setNeedsOneShotDrawingSynchronization()
    }
  }

  // Notify us that a layer has been removed
  func layerWillBeRemoved(parent: RenderLayerWrapper, child: RenderLayerWrapper) {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func layerGainedCompositedScrollableOverflow(layer: RenderLayerWrapper) {
    assert(isNativeImpl())
    var queryData = RequiresCompositingData()
    queryData.layoutUpToDate = .No

    let layerChanged = updateBacking(
      layer: layer, queryData: &queryData, backingSharingState: nil, backingRequired: .Yes)
    if layerChanged {
      layer.setChildrenNeedCompositingGeometryUpdate()
      layer.setNeedsCompositingLayerConnection()
      layer.setSubsequentLayersNeedCompositingRequirementsTraversal()
      // Ancestor layers that composited for indirect reasons (things listed in styleChangeMayAffectIndirectCompositingReasons()) need to get updated.
      // This could be optimized by only setting this flag on layers with the relevant styles.
      layer.setNeedsPostLayoutCompositingUpdateOnAncestors()
    }

    if let backing = layer.backing {
      backing.updateConfigurationAfterStyleChange()
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

  // Repaint all composited layers.
  func repaintCompositedLayers() {
    if !isNativeImpl() {
      wk_interop.RenderLayerCompositor_repaintCompositedLayers(interop())
      return
    }
    recursiveRepaintLayer(rootRenderLayer())
  }

  // Returns true if the given layer needs it own backing store.
  func requiresOwnBackingStore(
    _ layer: RenderLayerWrapper, _ compositingAncestorLayer: RenderLayerWrapper?,
    _ layerCompositedBoundsInAncestor: LayoutRectWrapper,
    _ ancestorCompositedBounds: LayoutRectWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func rootRenderLayer() -> RenderLayerWrapper {
    assert(isNativeImpl())
    return m_renderView!.layer()!
  }

  func rootGraphicsLayer() -> GraphicsLayer? {
    assert(isNativeImpl())
    return m_overflowControlsHostLayer ?? m_rootContentsLayer
  }

  private func scrollContainerLayer() -> GraphicsLayer? {
    assert(isNativeImpl())
    return m_scrollContainerLayer
  }
  private func scrolledContentsLayer() -> GraphicsLayer? {
    assert(isNativeImpl())
    return m_scrolledContentsLayer
  }
  private func clipLayer() -> GraphicsLayer? {
    assert(isNativeImpl())
    return m_clipLayer
  }
  private func rootContentsLayer() -> GraphicsLayer? {
    assert(isNativeImpl())
    return m_rootContentsLayer
  }

  func layerForClipping() -> GraphicsLayer? {
    assert(isNativeImpl())
    return m_clipLayer ?? m_scrollContainerLayer
  }

  enum RootLayerAttachment {
    case RootLayerUnattached
    case RootLayerAttachedViaChromeClient
    case RootLayerAttachedViaEnclosingFrame
  }

  func rootLayerAttachment() -> RootLayerAttachment {
    assert(isNativeImpl())
    return m_rootLayerAttachment
  }

  func updateRootLayerAttachment() {
    assert(isNativeImpl())
    ensureRootLayer()
  }

  private func updateRootLayerPosition() {
    assert(isNativeImpl())
    if m_rootContentsLayer != nil {
      m_rootContentsLayer!.setSize(size: FloatSize(size: m_renderView!.frameView().contentsSize()))
      m_rootContentsLayer!.setPosition(p: m_renderView!.frameView().positionForRootContentLayer())
      m_rootContentsLayer!.setAnchorPoint(p: FloatPoint3D())
    }

    updateScrollLayerClipping()
  }

  func setIsInWindow(_ isInWindow: Bool) {
    assert(!isNativeImpl())
    wk_interop.RenderLayerCompositor_setIsInWindow(interop(), isInWindow)
  }

  private func invalidateEventRegionForAllFrames() {
    assert(isNativeImpl())
    var frame: FrameWrapper? = page().mainFrame()
    while frame != nil {
      guard let localFrame = frame as? LocalFrameWrapper else {
        frame = frame!.tree().traverseNext()
        continue
      }
      if let view = localFrame.contentRenderer() {
        view.compositor().invalidateEventRegionForAllLayers()
      }
      frame = frame!.tree().traverseNext()
    }
  }

  private func invalidateEventRegionForAllLayers() {
    assert(isNativeImpl())
    applyToCompositedLayerIncludingDescendants(
      m_renderView!.layer()!,
      { (layer: RenderLayerWrapper) in
        layer.invalidateEventRegion(reason: .SettingDidChange)
      })
  }

  func layerBecameComposited(_ layer: RenderLayerWrapper) {
    assert(isNativeImpl())
    if CPtrToInt(layer.layerId()) != CPtrToInt(m_renderView!.layer()?.layerId()) {
      contentLayersCount += 1
    }
  }

  func layerBecameNonComposited(layer: RenderLayerWrapper) {
    assert(isNativeImpl())
    // TODO(asuhan): Inform the inspector that the given RenderLayer was destroyed.

    if CPtrToInt(layer.layerId()) != CPtrToInt(m_renderView!.layer()?.layerId()) {
      assert(contentLayersCount > 0)
      contentLayersCount -= 1
    }
  }

  static func hasCompositedWidgetContents(_ renderer: RenderObjectWrapper) -> Bool {
    guard let renderWidget = renderer as? RenderWidgetWrapper else { return false }
    return renderWidget.requiresAcceleratedCompositing()
  }

  static func isCompositedPlugin(renderer: RenderObjectWrapper) -> Bool {
    if let renderEmbeddedObject = renderer as? RenderEmbeddedObjectWrapper {
      return renderEmbeddedObject.requiresAcceleratedCompositing()
    }

    return false
  }

  static func frameContentsCompositor(renderer: RenderWidgetWrapper)
    -> RenderLayerCompositorWrapper?
  {
    return frameContentsRenderView(renderer)?.compositor()
  }

  struct WidgetLayerAttachment {
    init(widgetLayersAttachedAsChildren: Bool, layerHierarchyChanged: Bool) {
      self.widgetLayersAttachedAsChildren = widgetLayersAttachedAsChildren
      self.layerHierarchyChanged = layerHierarchyChanged
    }

    init() {
      self.init(widgetLayersAttachedAsChildren: false, layerHierarchyChanged: false)
    }

    var widgetLayersAttachedAsChildren: Bool
    var layerHierarchyChanged: Bool
  }

  func attachWidgetContentLayersIfNecessary(_ renderer: RenderWidgetWrapper)
    -> WidgetLayerAttachment
  {
    assert(isNativeImpl())
    let layer = renderer.layer()!
    if !layer.isComposited() {
      return WidgetLayerAttachment(
        widgetLayersAttachedAsChildren: false, layerHierarchyChanged: false)
    }

    let backing = layer.backing!
    let hostingLayer = backing.parentForSublayers()

    let isVisible = renderer.style().usedVisibility() == .Visible

    let addContentsLayerChildIfNecessary = { (contentsLayer: GraphicsLayer, isVisible: Bool) in
      if isVisible && hostingLayer.children().count == 1
        && ObjectIdentifier(hostingLayer.children()[0]) == ObjectIdentifier(contentsLayer)
      {
        return false
      }

      if !isVisible && hostingLayer.children().isEmpty {
        return false
      }

      hostingLayer.removeAllChildren()
      if isVisible {
        hostingLayer.addChild(childLayer: contentsLayer)
      }
      return true
    }

    var result = WidgetLayerAttachment()
    if RenderLayerCompositorWrapper.isCompositedPlugin(renderer: renderer),
      let contentsLayer = backing.layerForContents()
    {
      result.widgetLayersAttachedAsChildren = isVisible
      result.layerHierarchyChanged = addContentsLayerChildIfNecessary(contentsLayer, isVisible)
      if !isLayerForPluginWithScrollCoordinatedContents(layer) {
        return result
      }

      let scrollingCoordinator = scrollingCoordinator()
      if scrollingCoordinator == nil {
        return result
      }

      let pluginHostingNodeID = backing.scrollingNodeIDForRole(role: .PluginHosting)
      if !pluginHostingNodeID.bool() {
        return result
      }

      let renderEmbeddedObject = renderer as! RenderEmbeddedObjectWrapper
      renderEmbeddedObject.willAttachScrollingNode()

      let pluginScrollingNodeID = renderEmbeddedObject.scrollingNodeID()
      if pluginScrollingNodeID.bool() {
        if isVisible {
          scrollingCoordinator!.insertNode(
            m_renderView!.frameView().frame().rootFrame().frameID(), .PluginScrolling,
            pluginScrollingNodeID, parentID: pluginHostingNodeID, childIndex: 0)
          renderEmbeddedObject.didAttachScrollingNode()
        } else {
          scrollingCoordinator!.unparentNode(nodeID: pluginScrollingNodeID)
        }
      }
      return result
    }

    let innerCompositor = Self.frameContentsCompositor(renderer: renderer)
    if innerCompositor == nil || !innerCompositor!.usesCompositing()
      || innerCompositor!.rootLayerAttachment() != .RootLayerAttachedViaEnclosingFrame
    {
      return result
    }

    result.widgetLayersAttachedAsChildren = isVisible
    if let iframeRootLayer = innerCompositor!.rootGraphicsLayer() {
      result.layerHierarchyChanged = addContentsLayerChildIfNecessary(iframeRootLayer, isVisible)
    }

    let frameHostingNodeID = backing.scrollingNodeIDForRole(role: .FrameHosting)
    if frameHostingNodeID.bool() {
      let scrollingCoordinator = scrollingCoordinator()
      if scrollingCoordinator == nil {
        return result
      }

      if let contentsRenderView = frameContentsRenderView(renderer) {
        let frameRootScrollingNodeID = contentsRenderView.frameView().scrollingNodeID()
        if frameRootScrollingNodeID.bool() {
          if isVisible {
            scrollingCoordinator!.insertNode(
              m_renderView!.frameView().frame().rootFrame().frameID(), .Subframe,
              frameRootScrollingNodeID, parentID: frameHostingNodeID, childIndex: 0)
          } else {
            scrollingCoordinator!.unparentNode(nodeID: frameRootScrollingNodeID)
          }
        }
      }
    }

    return result
  }

  private func collectViewTransitionNewContentLayers(
    _ layer: RenderLayerWrapper, _ childList: inout ArraySlice<GraphicsLayer>
  ) {
    assert(isNativeImpl())
    if layer.renderer().style().pseudoElementType() != .ViewTransitionNew
      || !layer.hasVisibleContent
    {
      return
    }

    if !(layer.renderer() as! RenderViewTransitionCaptureWrapper).canUseExistingLayers() {
      return
    }

    let activeViewTransition = layer.renderer().document().activeViewTransition()
    if activeViewTransition == nil {
      return
    }

    let capturedElement = activeViewTransition!.namedElements().find(
      key: layer.renderer().style().pseudoElementNameArgument())
    if capturedElement == nil {
      return
    }

    let newStyleable = capturedElement!.newElement.styleable()
    if newStyleable == nil {
      return
    }

    var capturedRenderer = newStyleable!.renderer()
    if capturedRenderer == nil || !capturedRenderer!.hasLayer() {
      return
    }

    if capturedRenderer!.isDocumentElementRenderer() {
      capturedRenderer = capturedRenderer!.view()
      assert(capturedRenderer!.hasLayer())
    }

    let modelObject = capturedRenderer! as! RenderLayerModelObjectWrapper
    if let backing = modelObject.layer()!.backing {
      childList.append(backing.childForSuperlayersExcludingViewTransitions())
    }
  }

  // Update the geometry of the layers used for clipping and scrolling in frames.
  func frameViewDidChangeLocation(_ contentsOffset: IntPoint) {
    assert(isNativeImpl())
    m_overflowControlsHostLayer?.setPosition(p: FloatPoint(p: contentsOffset))
  }

  func frameViewDidChangeSize() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rootLayerConfigurationChanged() {
    assert(isNativeImpl())
    if let renderViewBacking = m_renderView!.layer()!.backing,
      renderViewBacking.isFrameLayerWithTiledBacking
    {
      m_renderView!.layer()!.setNeedsCompositingConfigurationUpdate()
      scheduleCompositingLayerUpdate()
    }
  }

  override func pageScaleFactor() -> Float32 {
    assert(isNativeImpl())
    return page().pageScaleFactor()
  }

  func layerTiledBackingUsageChanged(graphicsLayer: GraphicsLayer?, usingTiledBacking: Bool) {
    assert(isNativeImpl())
    if usingTiledBacking {
      m_layersWithTiledBackingCount += 1
      graphicsLayer!.tiledBacking()!.setIsInWindow(isInWindow: page().isInWindow())
    } else {
      assert(m_layersWithTiledBackingCount > 0)
      m_layersWithTiledBackingCount -= 1
    }
  }

  // FIXME: make the coordinated/async terminology consistent.
  func isViewportConstrainedFixedOrStickyLayer(_ layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    if layer.renderer().isStickilyPositioned() {
      return isAsyncScrollableStickyLayer(layer: layer)
    }

    if !(layer.renderer().isFixedPositioned() && layer.behavesAsFixed) {
      return false
    }

    var ancestor = layer.parent()
    while ancestor != nil {
      if ancestor!.hasCompositedScrollableOverflow() {
        return true
      }
      if ancestor!.isStackingContext() && ancestor!.isComposited()
        && ancestor!.renderer().isFixedPositioned()
      {
        return false
      }
      ancestor = ancestor!.parent()
    }

    return true
  }

  private func useCoordinatedScrollingForLayer(_ layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    if layer.isRenderViewLayer && hasCoordinatedScrolling() {
      return true
    }

    if let scrollingCoordinator = scrollingCoordinator() {
      return scrollingCoordinator.coordinatesScrollingForOverflowLayer(layer: layer)
    }

    return false
  }

  private func computeCoordinatedPositioningForLayer(
    _ layer: RenderLayerWrapper, compositedAncestor: RenderLayerWrapper?
  ) -> ScrollPositioningBehavior {
    assert(isNativeImpl())
    if layer.isRenderViewLayer {
      return .None
    }

    if layer.renderer().isFixedPositioned() && layer.behavesAsFixed {
      return .None
    }

    if !layer.hasCompositedScrollingAncestor {
      return .None
    }

    if scrollingCoordinator() == nil {
      return .None
    }

    if compositedAncestor == nil {
      fatalError("Not reached")
    }

    return RenderLayerCompositorWrapper.layerScrollBehahaviorRelativeToCompositedAncestor(
      layer, compositedAncestor: compositedAncestor!)
  }

  private func isLayerForIFrameWithScrollCoordinatedContents(_ layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    guard let renderWidget = layer.renderer() as? RenderWidgetWrapper else {
      return false
    }

    if let frame = renderWidget.frameOwnerElement().contentFrame(), frame is RemoteFrameWrapper {
      return renderWidget.hasLayer() && renderWidget.layer()!.isComposited()
    }

    guard let contentDocument = renderWidget.frameOwnerElement().contentDocument() else {
      return false
    }

    guard let view = contentDocument.renderView() else {
      return false
    }

    if let scrollingCoordinator = scrollingCoordinator() {
      return scrollingCoordinator.coordinatesScrollingForFrameView(frameView: view.frameView())
    }

    return false
  }

  private func isLayerForPluginWithScrollCoordinatedContents(_ layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    return (layer.renderer() as? RenderEmbeddedObjectWrapper)?.usesAsyncScrolling() ?? false
  }

  func removeFromScrollCoordinatedLayers(layer: RenderLayerWrapper) {
    assert(isNativeImpl())
    detachScrollCoordinatedLayer(layer: layer, roles: allScrollCoordinationRoles)
  }

  func willRemoveScrollingLayerWithBacking(
    _ layer: RenderLayerWrapper, _ backing: RenderLayerBacking
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func didAddScrollingLayer(_ layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func viewHasTransparentBackground() -> Bool {
    assert(isNativeImpl())
    var dummy: ColorWrapper? = nil
    return viewHasTransparentBackgroundHelper(&dummy)
  }

  func viewHasTransparentBackground(_ backgroundColor: inout ColorWrapper?) -> Bool {
    assert(isNativeImpl())
    return viewHasTransparentBackgroundHelper(&backgroundColor)
  }

  func viewHasTransparentBackgroundHelper(_ backgroundColor: inout ColorWrapper?) -> Bool {
    assert(isNativeImpl())
    if m_renderView!.frameView().isTransparent() {
      if backgroundColor != nil {
        backgroundColor = ColorWrapper()  // Return an invalid color.
      }
      return true
    }

    var documentBackgroundColor = m_renderView!.frameView().documentBackgroundColor()
    if !documentBackgroundColor.isValid() {
      documentBackgroundColor = m_renderView!.frameView().baseBackgroundColor()
    }

    assert(documentBackgroundColor.isValid())

    if backgroundColor != nil {
      backgroundColor = documentBackgroundColor
    }

    return !documentBackgroundColor.isOpaque()
  }

  func updateRootContentLayerClipping() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true if the policy changed.
  private func updateCompositingPolicy() -> Bool {
    assert(isNativeImpl())
    if !usesCompositing() {
      return false
    }

    let currentPolicy = m_compositingPolicy
    if let compositingPolicyOverride = page().compositingPolicyOverride() {
      m_compositingPolicy = compositingPolicyOverride
      return m_compositingPolicy != currentPolicy
    }

    if !canUpdateCompositingPolicy() {
      return false
    }

    let nowUnderMemoryPressure =
      MemoryPressureHandler.singleton().isUnderMemoryPressure()
      || MemoryPressureHandler.singleton().isUnderMemoryWarning()
    RenderLayerCompositorWrapper.cachedIsUnderMemoryPressureOrWarning = nowUnderMemoryPressure

    if RenderLayerCompositorWrapper.cachedIsUnderMemoryPressureOrWarning != nowUnderMemoryPressure {
      RenderLayerCompositorWrapper.cachedMemoryPolicy = MemoryPressureHandler.singleton()
        .currentMemoryUsagePolicy()
      RenderLayerCompositorWrapper.cachedIsUnderMemoryPressureOrWarning = nowUnderMemoryPressure
    }

    m_compositingPolicy =
      RenderLayerCompositorWrapper.cachedMemoryPolicy == .Unrestricted ? .Normal : .Conservative

    let didChangePolicy = currentPolicy != m_compositingPolicy
    if didChangePolicy && m_compositingPolicy == .Conservative {
      m_compositingPolicyHysteresis.impulse()
    }

    return didChangePolicy
  }

  private func canUpdateCompositingPolicy() -> Bool {
    assert(isNativeImpl())
    return m_compositingPolicyHysteresis.state() == .Stopped
  }

  private static var cachedMemoryPolicy: MemoryUsagePolicy = .Unrestricted
  private static var cachedIsUnderMemoryPressureOrWarning = false

  private class BackingSharingState {
    init(allowOverlappingProviders: Bool) {
      self.allowOverlappingProviders = allowOverlappingProviders
    }

    struct Provider {
      let providerLayer: RenderLayerWrapper?
      let sharingLayers: WeakListSet<RenderLayerWrapper>
      let absoluteBounds: LayoutRectWrapper
    }

    func backingProviderCandidateForLayer(
      _ layer: RenderLayerWrapper, _ compositor: RenderLayerCompositorWrapper,
      _ overlapMap: LayerOverlapMap, _ overlap: inout OverlapExtent
    ) -> Provider? {
      // TODO(asuhan): add logging

      if layer.hasReflection() {
        return nil
      }

      if !allowOverlappingProviders {
        for candidate in backingProviderCandidates {
          if layer.ancestorLayerIsInContainingBlockChain(ancestor: candidate.providerLayer!) {
            return candidate
          }
        }

        return nil
      }

      if backingProviderCandidates.isEmpty {
        return nil
      }

      // First, find the frontmost provider that is an ancestor in the containing block chain.
      let candidateIndex = backingProviderCandidates.lastIndex(where: { provider in
        let providerLayer = provider.providerLayer!

        if CPtrToInt(layer.layerId()) == CPtrToInt(providerLayer.layerId()) {
          return false
        }

        return layer.ancestorLayerIsInContainingBlockChain(ancestor: providerLayer)
      })

      if candidateIndex == nil {
        return nil
      }

      let candidate = backingProviderCandidates[candidateIndex!]

      // Only allow adding to providers that clip their descendants, unless there's only a single provider.
      // Unclipped providers in-front are tracked for overlap testing only.
      // FIXME: We could accumulate the union of the overlap bounds for a provider and its sharing layers to avoid this restriction.
      if backingProviderCandidates.count > 1
        && !candidate.providerLayer!.canUseCompositedScrolling()
      {
        return nil
      }

      if candidateIndex! == backingProviderCandidates.count - 1 {
        // No other provider is in front of the candidate, so no need to check for overlap.
        return candidate
      }

      let providerLayer = candidate.providerLayer!
      var overlapBounds = candidate.absoluteBounds
      if providerLayer.canUseCompositedScrolling() && providerLayer.scrollableArea() != nil
        && providerLayer.scrollableArea()!.hasScrollableHorizontalOverflow()
          != providerLayer.scrollableArea()!.hasScrollableVerticalOverflow()
      {
        // If the provider uses composited scrolling but only supports scrolling
        // in one axis, we can use the clipped overlap bounds in the other axis,
        // when checking for overlap.
        let clippedOverlapBounds = compositor.computeClippedOverlapBounds(
          overlapMap, layer, &overlap)
        if providerLayer.scrollableArea()!.hasScrollableHorizontalOverflow() {
          overlapBounds.setY(y: clippedOverlapBounds.y())
          overlapBounds.setHeight(height: clippedOverlapBounds.height())
        } else {
          overlapBounds.setX(x: clippedOverlapBounds.x())
          overlapBounds.setWidth(width: clippedOverlapBounds.width())
        }
      }

      // Check if any of the other candidates that are in front of the selected provider will
      // overlap the bounds of the layer to be added.
      for provider in backingProviderCandidates[(candidateIndex! + 1)...] {
        if overlapBounds.intersects(other: provider.absoluteBounds) {
          return nil
        }
      }

      return candidate
    }

    func existingBackingProviderCandidateForLayer(_ layer: RenderLayerWrapper) -> Provider? {
      assert(layer.paintsIntoProvidedBacking())
      for candidate in backingProviderCandidates {
        if CPtrToInt(layer.backingProviderLayer?.layerId())
          == CPtrToInt(candidate.providerLayer?.layerId())
        {
          return candidate
        }
      }
      return nil
    }

    func backingProviderForLayer(layer: RenderLayerWrapper) -> Provider? {
      for candidate in backingProviderCandidates {
        if candidate.sharingLayers.contains(value: layer) {
          return candidate
        }
      }

      return nil
    }

    // Add a layer that would repaint into a layer in m_backingSharingLayers.
    // That repaint has to wait until we've set the provider's backing-sharing layers.
    func addLayerNeedingRepaint(layer: RenderLayerWrapper) {
      layersPendingRepaint.add(value: layer)
    }

    func addBackingSharingCandidate(
      candidateLayer: RenderLayerWrapper, candidateAbsoluteBounds: LayoutRectWrapper,
      candidateStackingContext: RenderLayerWrapper, backingSharingSnapshot: BackingSharingSnapshot?
    ) {
      assert(
        CPtrToInt(backingSharingStackingContext?.layerId())
          == CPtrToInt(candidateStackingContext.layerId()))
      assert(
        !backingProviderCandidates.contains(where: { candidate in
          CPtrToInt(candidate.providerLayer?.layerId()) == CPtrToInt(candidateLayer.layerId())
        }))

      // Inserts candidateLayer into the provider list in z-order, using the state snapshot that
      // was taken before any descendant layers were traversed.

      if backingSharingSnapshot == nil
        || sequenceIdentifier() != backingSharingSnapshot!.sequenceIdentifier
      {
        // If a new sharing sequence has been started since the snapshot was taken, then this candidate
        // will be before any of the current ones in z-order (which must have been added by descendants of this layer).
        backingProviderCandidates.insert(
          Provider(
            providerLayer: candidateLayer,
            sharingLayers: WeakListSet<RenderLayerWrapper>(),
            absoluteBounds: candidateAbsoluteBounds), at: 0)
      } else {
        // Otherwise insert it at the position captured in the snapshot
        backingProviderCandidates.insert(
          Provider(
            providerLayer: candidateLayer,
            sharingLayers: WeakListSet<RenderLayerWrapper>(),
            absoluteBounds: candidateAbsoluteBounds), at: backingSharingSnapshot!.providerCount)
      }
    }

    func isAdditionalProviderCandidate(
      _ candidateLayer: RenderLayerWrapper, _ candidateAbsoluteBounds: LayoutRectWrapper,
      stackingContextAncestor: RenderLayerWrapper?
    ) -> Bool {
      assert(!backingProviderCandidates.isEmpty)
      if stackingContextAncestor == nil
        || CPtrToInt(stackingContextAncestor!.layerId())
          != CPtrToInt(backingSharingStackingContext?.layerId())
      {
        return false
      }

      if !allowOverlappingProviders {
        // Only allow multiple providers for overflow scroll, which we know clips its descendants.
        if !(backingProviderCandidates[0].providerLayer!.canUseCompositedScrolling()
          && candidateLayer.canUseCompositedScrolling())
        {
          return false
        }

        // Disallow overlap between backing providers.
        for candidate in backingProviderCandidates {
          if candidateAbsoluteBounds.intersects(other: candidate.absoluteBounds) {
            return false
          }
        }
        return true
      }

      if !backingProviderCandidates[0].providerLayer!.canUseCompositedScrolling() {
        return false
      }

      return backingProviderCandidates.count < 10
    }

    func startBackingSharingSequence(
      candidateLayer: RenderLayerWrapper, candidateAbsoluteBounds: LayoutRectWrapper,
      candidateStackingContext: RenderLayerWrapper
    ) {
      assert(backingSharingStackingContext != nil)
      assert(backingProviderCandidates.isEmpty)
      backingProviderCandidates.append(
        Provider(
          providerLayer: candidateLayer,
          sharingLayers: WeakListSet<RenderLayerWrapper>(),
          absoluteBounds: candidateAbsoluteBounds))
      backingSharingStackingContext = candidateStackingContext
    }

    func endBackingSharingSequence(_ endLayer: RenderLayerWrapper) {
      assert(backingSharingStackingContext != nil)

      let candidates = backingProviderCandidates
      backingProviderCandidates = []

      for candidate in candidates {
        candidate.sharingLayers.remove(value: endLayer)
        candidate.providerLayer!.backing!.setBackingSharingLayers(candidate.sharingLayers)
      }
      backingSharingStackingContext = nil
      m_sequenceIdentifier = BackingSharingSequenceIdentifierWrapper.generate()

      issuePendingRepaints()
    }

    func snapshot() -> BackingSharingSnapshot? {
      if backingSharingStackingContext == nil {
        return nil
      }
      return BackingSharingSnapshot(
        sequenceIdentifier: m_sequenceIdentifier, providerCount: backingProviderCandidates.count)
    }

    func sequenceIdentifier() -> BackingSharingSequenceIdentifierWrapper {
      return m_sequenceIdentifier
    }

    private func issuePendingRepaints() {
      for layer in layersPendingRepaint {
        // TODO(asuhan): add logging
        layer.computeRepaintRectsIncludingDescendants()
        layer.compositor().repaintOnCompositingChange(layer: layer)
      }

      layersPendingRepaint.clear()
    }

    var backingProviderCandidates: [Provider] = []
    var backingSharingStackingContext: RenderLayerWrapper? = nil
    private var m_sequenceIdentifier = BackingSharingSequenceIdentifierWrapper.generate()
    private let layersPendingRepaint = WeakHashSet<RenderLayerWrapper>()
    private let allowOverlappingProviders: Bool
  }

  // Copy the accelerated compositing related flags from Settings
  private func cacheAcceleratedCompositingFlags() {
    assert(isNativeImpl())
    let settings = m_renderView!.settings()
    var hasAcceleratedCompositing = settings.acceleratedCompositingEnabled()

    // We allow the chrome to override the settings, in case the page is rendered
    // on a chrome that doesn't allow accelerated compositing.
    if hasAcceleratedCompositing {
      m_compositingTriggers = page().chrome().client().allowedCompositingTriggers()
      hasAcceleratedCompositing = !m_compositingTriggers.isEmpty
    }

    let showDebugBorders = settings.showDebugBorders()
    let showRepaintCounter = settings.showRepaintCounter()
    let acceleratedDrawingEnabled = settings.acceleratedDrawingEnabled()

    // forceCompositingMode for subframes can only be computed after layout.
    var forceCompositingMode = m_forceCompositingMode
    if isRootFrameCompositor() {
      forceCompositingMode =
        m_renderView!.settings().forceCompositingMode() && hasAcceleratedCompositing
    }

    if hasAcceleratedCompositing != m_hasAcceleratedCompositing
      || showDebugBorders != m_showDebugBorders || showRepaintCounter != m_showRepaintCounter
      || forceCompositingMode != m_forceCompositingMode, let rootLayer = m_renderView!.layer()
    {
      rootLayer.setNeedsCompositingConfigurationUpdate()
      rootLayer.setDescendantsNeedUpdateBackingAndHierarchyTraversal()
    }

    let debugBordersChanged = m_showDebugBorders != showDebugBorders
    m_hasAcceleratedCompositing = hasAcceleratedCompositing
    m_forceCompositingMode = forceCompositingMode
    m_showDebugBorders = showDebugBorders
    m_showRepaintCounter = showRepaintCounter
    m_acceleratedDrawingEnabled = acceleratedDrawingEnabled

    if debugBordersChanged {
      m_layerForHorizontalScrollbar?.setShowDebugBorder(show: m_showDebugBorders)
      m_layerForVerticalScrollbar?.setShowDebugBorder(show: m_showDebugBorders)
      m_layerForScrollCorner?.setShowDebugBorder(show: m_showDebugBorders)
    }

    if updateCompositingPolicy() {
      rootRenderLayer().setDescendantsNeedCompositingRequirementsTraversal()
    }
  }

  private func cacheAcceleratedCompositingFlagsAfterLayout() {
    assert(isNativeImpl())
    cacheAcceleratedCompositingFlags()

    if isRootFrameCompositor() {
      return
    }

    var queryData = RequiresCompositingData()
    let forceCompositingMode =
      m_hasAcceleratedCompositing && m_renderView!.settings().forceCompositingMode()
      && requiresCompositingForScrollableFrame(&queryData)
    if forceCompositingMode != m_forceCompositingMode {
      m_forceCompositingMode = forceCompositingMode
      rootRenderLayer().setDescendantsNeedCompositingRequirementsTraversal()
    }
  }

  // Whether the given RL needs a compositing layer.
  private func needsToBeComposited(
    layer: RenderLayerWrapper, queryData: inout RequiresCompositingData
  )
    -> Bool
  {
    assert(isNativeImpl())
    if !canBeComposited(layer) {
      return false
    }

    return requiresCompositingLayer(layer: layer, queryData: &queryData)
      || layer.mustCompositeForIndirectReasons()
      || (usesCompositing() && layer.isRenderViewLayer)
  }

  // Whether the layer has an intrinsic need for compositing layer.
  // Note: this specifies whether the RL needs a compositing layer for intrinsic reasons.
  // Use needsToBeComposited() to determine if a RL actually needs a compositing layer.
  // FIXME: is clipsCompositingDescendants() an intrinsic reason?
  private func requiresCompositingLayer(
    layer: RenderLayerWrapper, queryData: inout RequiresCompositingData
  )
    -> Bool
  {
    assert(isNativeImpl())
    let renderer = rendererForCompositingTests(layer: layer)

    if renderer.layer() == nil {
      fatalError("Not reached")
    }

    // The root layer always has a compositing layer, but it may not have backing.
    if requiresCompositingForTransform(renderer: renderer)
      || requiresCompositingForAnimation(renderer: renderer)
      || requiresCompositingForPosition(
        renderer: renderer, layer: renderer.layer()!, queryData: &queryData)
      || requiresCompositingForCanvas(renderer: renderer)
      || requiresCompositingForFilters(renderer: renderer)
      || requiresCompositingForWillChange(renderer: renderer)
      || requiresCompositingForBackfaceVisibility(renderer: renderer)
      || requiresCompositingForViewTransition(renderer: renderer)
      || requiresCompositingForVideo(renderer: renderer)
      || requiresCompositingForModel(renderer: renderer)
      || requiresCompositingForFrame(renderer: renderer, queryData: &queryData)
      || requiresCompositingForPlugin(renderer: renderer, queryData: &queryData)
      || requiresCompositingForOverflowScrolling(layer: renderer.layer()!, queryData: &queryData)
    {
      queryData.intrinsic = true
      return true
    }
    return false
  }

  // Whether the layer could ever be composited.
  private func canBeComposited(_ layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    if m_hasAcceleratedCompositing && layer.isSelfPaintingLayer {
      if layer.renderer().isSkippedContent() {
        return false
      }

      if !layer.isInsideFragmentedFlow() {
        return true
      }

      // CSS Regions flow threads do not need to be composited as we use composited RenderFragmentContainers
      // to render the background of the RenderFragmentedFlow.
      if layer.isRenderFragmentedFlow() {
        return false
      }

      return true
    }
    return false
  }

  // Make or destroy the backing for this layer; returns true if backing changed.
  private enum BackingRequired {
    case No
    case Yes
    case Unknown
  }

  private func updateBacking(
    layer: RenderLayerWrapper, queryData: inout RequiresCompositingData,
    backingSharingState: BackingSharingState? = nil, backingRequired: BackingRequired = .Unknown
  ) -> Bool {
    assert(isNativeImpl())
    var layerChanged = false
    var backingRequired = backingRequired
    if backingRequired == .Unknown {
      backingRequired = needsToBeComposited(layer: layer, queryData: &queryData) ? .Yes : .No
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

        if layer.isRenderViewLayer && useCoordinatedScrollingForLayer(layer) {
          let frameView = m_renderView!.frameView()
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
        if let innerCompositor = Self.frameContentsCompositor(renderer: renderWidget),
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
        scrollingCoordinator.frameViewFixedObjectsDidChange(frameView: m_renderView!.frameView())
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

  private func updateLayerCompositingState(
    layer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?,
    _ queryData: inout RequiresCompositingData, _ backingSharingState: BackingSharingState
  ) -> Bool {
    assert(isNativeImpl())
    var layerChanged = updateBacking(
      layer: layer, queryData: &queryData, backingSharingState: backingSharingState)

    // See if we need content or clipping layers. Methods called here should assume
    // that the compositing state of descendant layers has not been updated yet.
    if layer.backing != nil && layer.backing!.updateConfiguration(compositingAncestor!) {
      layerChanged = true
    }

    return layerChanged
  }

  private func applyToCompositedLayerIncludingDescendants(
    _ layer: RenderLayerWrapper, _ function: (RenderLayerWrapper) -> Void
  ) {
    assert(isNativeImpl())
    if layer.isComposited() {
      function(layer)
    }
    var childLayer = layer.firstChild()
    while childLayer != nil {
      applyToCompositedLayerIncludingDescendants(childLayer!, function)
      childLayer = childLayer!.nextSibling()
    }
  }

  private func repaintTargetsSharedBacking(
    layer: RenderLayerWrapper, backingSharingState: BackingSharingState?
  ) -> Bool {
    assert(isNativeImpl())
    return backingSharingState != nil
      && layerRepaintTargetsBackingSharingLayer(layer: layer, sharingState: backingSharingState!)
  }

  private func repaintLayer(layer: RenderLayerWrapper, backingSharingState: BackingSharingState?) {
    assert(isNativeImpl())
    if repaintTargetsSharedBacking(layer: layer, backingSharingState: backingSharingState) {
      print(
        "Layer \(layer)  needs to repaint into potential backing-sharing layer, postponing repaint")
      backingSharingState!.addLayerNeedingRepaint(layer: layer)
    } else {
      repaintOnCompositingChange(layer: layer)
    }
  }

  // Repaint this and its child layers.
  private func recursiveRepaintLayer(_ layer: RenderLayerWrapper) {
    assert(isNativeImpl())
    layer.updateLayerListsIfNeeded()

    // FIXME: This method does not work correctly with transforms.
    if layer.isComposited() && !layer.backing!.paintsIntoCompositedAncestor() {
      layer.setBackingNeedsRepaint()
    }

    // TODO(asuhan): mutation checker

    if layer.hasCompositingDescendant {
      for renderLayer in layer.negativeZOrderLayers() {
        recursiveRepaintLayer(renderLayer)
      }

      for renderLayer in layer.positiveZOrderLayers() {
        recursiveRepaintLayer(renderLayer)
      }
    }

    for renderLayer in layer.normalFlowLayers() {
      recursiveRepaintLayer(renderLayer)
    }
  }

  private func layerRepaintTargetsBackingSharingLayer(
    layer: RenderLayerWrapper, sharingState: BackingSharingState
  ) -> Bool {
    assert(isNativeImpl())
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

  private func computeExtent(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper, _ extent: inout OverlapExtent
  ) {
    assert(isNativeImpl())
    if extent.extentComputed {
      return
    }

    var layerBounds = LayoutRectWrapper()
    if extent.hasTransformAnimation {
      extent.animationCausesExtentUncertainty =
        !layer.getOverlapBoundsIncludingChildrenAccountingForTransformAnimations(&layerBounds)
    } else {
      layerBounds = layer.overlapBounds()
    }

    // In the animating transform case, we avoid double-accounting for the transform because
    // we told pushMappingsToAncestor() to ignore transforms earlier.
    extent.bounds = enclosingLayoutRect(
      rect: overlapMap.geometryMap.absoluteRect(layerBounds.FloatRect()))

    // Empty rects never intersect, but we need them to for the purposes of overlap testing.
    if extent.bounds.isEmpty() {
      extent.bounds.setSize(size: LayoutSizeWrapper(width: Int32(1), height: Int32(1)))
    }

    let renderer = layer.renderer()
    if renderer.isFixedPositioned()
      && CPtrToInt(renderer.container()?.id()) == CPtrToInt(m_renderView!.id())
    {
      // Because fixed elements get moved around without re-computing overlap, we have to compute an overlap
      // rect that covers all the locations that the fixed element could move to.
      // FIXME: need to handle sticky too.
      extent.bounds = m_renderView!.frameView().fixedScrollableAreaBoundsInflatedForScrolling(
        uninflatedBounds: extent.bounds)
    }

    extent.extentComputed = true
  }

  private func computeClippingScopes(_ layer: RenderLayerWrapper, _ extent: inout OverlapExtent) {
    assert(isNativeImpl())
    if extent.clippingScopesComputed {
      return
    }

    // FIXME: constrain the scopes (by composited stacking context ancestor I think).
    let rootLayer = rootRenderLayer()
    extent.clippingScopes.append(
      LayerOverlapMap.LayerAndBounds(layer: rootLayer, bounds: LayoutRectWrapper()))

    if !layer.hasCompositedScrollingAncestor {
      return
    }

    traverseAncestorLayers(
      layer,
      { (ancestorLayer: RenderLayerWrapper, inContainingBlockChain: Bool, _: Bool) in
        if inContainingBlockChain && ancestorLayer.hasCompositedScrollableOverflow() {
          var clipRect = LayoutRectWrapper()
          if let box = ancestorLayer.renderer() as? RenderBoxWrapper {
            // FIXME: This is expensive. Broken with transforms.
            let offsetFromRoot = ancestorLayer.convertToLayerCoords(
              ancestorLayer: rootLayer, location: LayoutPointWrapper())
            clipRect = box.overflowClipRect(location: offsetFromRoot)
          }

          let layerAndBounds = LayerOverlapMap.LayerAndBounds(
            layer: ancestorLayer, bounds: clipRect)
          extent.clippingScopes.insert(layerAndBounds, at: 1)  // Order is roots to leaves.
        }
        return .Continue
      })

    extent.clippingScopesComputed = true
  }

  private func addToOverlapMap(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper, _ extent: inout OverlapExtent
  ) {
    assert(isNativeImpl())
    if layer.isRenderViewLayer {
      return
    }

    let clippedBounds = computeClippedOverlapBounds(overlapMap, layer, &extent)

    computeClippingScopes(layer, &extent)
    overlapMap.add(layer, bounds: clippedBounds, enclosingClippingLayers: extent.clippingScopes)
  }

  private func computeClippedOverlapBounds(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper, _ extent: inout OverlapExtent
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    computeExtent(overlapMap, layer, &extent)
    computeClippingScopes(layer, &extent)

    var clipRect = LayoutRectWrapper()
    if layer.hasCompositedScrollingAncestor {
      // Compute a clip up to the composited scrolling ancestor, then convert it to absolute coordinates.
      let scopeLayer = extent.clippingScopes.last!.layer
      clipRect =
        layer.backgroundClipRect(
          clipRectsContext: RenderLayerWrapper.ClipRectsContext(
            inRootLayer: scopeLayer, inClipRectsType: .TemporaryClipRects, inOptions: [])
        ).rect
      if !clipRect.isInfinite() {
        clipRect.setLocation(
          location: scopeLayer.convertToLayerCoords(
            ancestorLayer: rootRenderLayer(), location: clipRect.location()))
      }
    } else {
      clipRect =
        layer.backgroundClipRect(
          clipRectsContext: RenderLayerWrapper.ClipRectsContext(
            inRootLayer: rootRenderLayer(), inClipRectsType: .AbsoluteClipRects)
        ).rect  // FIXME: Incorrect for CSS regions.
    }

    var clippedBounds = extent.bounds
    if !clipRect.isInfinite() {
      // With delegated page scaling, pageScaleFactor() is not applied by RenderView, so we should not scale here.
      if !page().delegatesScaling() {
        clipRect.scale(pageScaleFactor())
      }

      clippedBounds.intersect(other: clipRect)
    }

    return clippedBounds
  }

  private func addDescendantsToOverlapMapRecursive(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper,
    ancestorLayer: RenderLayerWrapper? = nil
  ) {
    assert(isNativeImpl())
    if !canBeComposited(layer) {
      return
    }

    // A null ancestorLayer is an indication that 'layer' has already been pushed.
    if ancestorLayer != nil {
      overlapMap.geometryMap.pushMappingsToAncestor(layer: layer, ancestorLayer: ancestorLayer!)

      var layerExtent = OverlapExtent()
      addToOverlapMap(overlapMap, layer, &layerExtent)
    }

    // TODO(asuhan): mutation checker

    for renderLayer in layer.negativeZOrderLayers() {
      addDescendantsToOverlapMapRecursive(overlapMap, renderLayer, ancestorLayer: layer)
    }

    for renderLayer in layer.normalFlowLayers() {
      addDescendantsToOverlapMapRecursive(overlapMap, renderLayer, ancestorLayer: layer)
    }

    for renderLayer in layer.positiveZOrderLayers() {
      addDescendantsToOverlapMapRecursive(overlapMap, renderLayer, ancestorLayer: layer)
    }

    if ancestorLayer != nil {
      overlapMap.geometryMap.popMappingsToAncestor(ancestorLayer: ancestorLayer!)
    }
  }

  private func updateOverlapMap(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper,
    _ layerExtent: inout OverlapExtent,
    didPushContainer: Bool, addLayerToOverlap: Bool, addDescendantsToOverlap: Bool = false
  ) {
    assert(isNativeImpl())
    // TODO(asuhan): add logging
    if addLayerToOverlap {
      addToOverlapMap(overlapMap, layer, &layerExtent)
    }

    if addDescendantsToOverlap {
      // If this is the first non-root layer to composite, we need to add all the descendants we already traversed to the overlap map.
      addDescendantsToOverlapMapRecursive(overlapMap, layer)
    }

    if didPushContainer {
      overlapMap.popCompositingContainer(layer)
    }
  }

  private func layerOverlaps(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper, _ extent: inout OverlapExtent
  ) -> Bool {
    assert(isNativeImpl())
    computeExtent(overlapMap, layer, &extent)
    computeClippingScopes(layer, &extent)

    return overlapMap.overlapsLayers(
      layer, bounds: extent.bounds, enclosingClippingLayers: extent.clippingScopes[...])
  }

  private struct BackingSharingSnapshot {
    let sequenceIdentifier: BackingSharingSequenceIdentifierWrapper
    let providerCount: Int
  }

  private func updateBackingSharingBeforeDescendantTraversal(
    _ sharingState: BackingSharingState, _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper,
    _ layerExtent: inout OverlapExtent, _ willBeComposited: Bool,
    stackingContextAncestor: RenderLayerWrapper?
  ) -> BackingSharingSnapshot? {
    assert(isNativeImpl())
    // TODO(asuhan): add logging

    layer.setBackingProviderLayer(backingProvider: nil)

    let shouldEndSharingSequence = { [self] () in
      if sharingState.backingSharingStackingContext == nil {
        return false
      }

      if !willBeComposited {
        return false
      }

      // If this layer is composited, we can only continue the sequence if it's a new provider candidate.
      computeExtent(overlapMap, layer, &layerExtent)
      return !sharingState.isAdditionalProviderCandidate(
        layer, layerExtent.bounds, stackingContextAncestor: stackingContextAncestor)
    }()

    // A layer that composites resets backing-sharing, since subsequent layers need to composite to overlap it.
    if shouldEndSharingSequence {
      sharingState.endBackingSharingSequence(layer)
    }

    return sharingState.snapshot()
  }

  private func updateBackingSharingAfterDescendantTraversal(
    _ sharingState: BackingSharingState, _ overlapMap: LayerOverlapMap,
    _ layer: RenderLayerWrapper,
    _ layerExtent: inout OverlapExtent, stackingContextAncestor: RenderLayerWrapper?,
    _ backingSharingSnapshot: BackingSharingSnapshot?
  ) {
    assert(isNativeImpl())
    // TODO(asuhan): add logging

    if layer.isComposited() {
      // If this layer is being composited, clean up sharing-related state.
      layer.disconnectFromBackingProviderLayer()
      for candidate in sharingState.backingProviderCandidates {
        candidate.sharingLayers.remove(value: layer)
      }
    }

    // Backing sharing is constrained to layers in the same stacking context.
    if CPtrToInt(layer.layerId())
      == CPtrToInt(sharingState.backingSharingStackingContext?.layerId())
    {
      assert(
        !sharingState.backingProviderCandidates.contains(where: { candidate in
          return CPtrToInt(candidate.providerLayer?.layerId()) == CPtrToInt(layer.layerId())
        }))
      sharingState.endBackingSharingSequence(layer)

      if layer.isComposited() {
        layer.backing!.clearBackingSharingLayers()
      }

      return
    }

    if !layer.isComposited() {
      return
    }

    if stackingContextAncestor == nil {
      return
    }

    let canBeBackingProvider = !layer.hasCompositingDescendant
    if canBeBackingProvider {
      if sharingState.backingSharingStackingContext == nil {
        computeExtent(overlapMap, layer, &layerExtent)
        sharingState.startBackingSharingSequence(
          candidateLayer: layer, candidateAbsoluteBounds: layerExtent.bounds,
          candidateStackingContext: stackingContextAncestor!)
        return
      }

      computeExtent(overlapMap, layer, &layerExtent)
      if sharingState.isAdditionalProviderCandidate(
        layer, layerExtent.bounds, stackingContextAncestor: stackingContextAncestor)
      {
        sharingState.addBackingSharingCandidate(
          candidateLayer: layer, candidateAbsoluteBounds: layerExtent.bounds,
          candidateStackingContext: stackingContextAncestor!,
          backingSharingSnapshot: backingSharingSnapshot)
        return
      }
    }

    layer.backing!.clearBackingSharingLayers()

    // A layer that composites resets backing-sharing, since subsequent layers need to composite to overlap it. If a descendant didn't already end the sharing sequence that was current when processing of this layer started, end it now.
    if backingSharingSnapshot != nil
      && backingSharingSnapshot!.sequenceIdentifier == sharingState.sequenceIdentifier()
    {
      sharingState.endBackingSharingSequence(layer)
    }
  }

  private func computeCompositingRequirements(
    ancestorLayer: RenderLayerWrapper?, layer: RenderLayerWrapper,
    _ overlapMap: LayerOverlapMap,
    _ compositingState: inout CompositingState, _ backingSharingState: BackingSharingState,
    _ descendantHas3DTransform: inout Bool
  ) {
    assert(isNativeImpl())
    // TODO(asuhan): add logging

    layer.updateDescendantDependentFlags()
    layer.updateLayerListsIfNeeded()

    if !layer.hasDescendantNeedingCompositingRequirementsTraversal()
      && !layer.needsCompositingRequirementsTraversal()
      && !compositingState.fullPaintOrderTraversalRequired
      && !compositingState.descendantsRequireCompositingUpdate
    {
      traverseUnchangedSubtree(
        ancestorLayer: ancestorLayer, layer: layer, overlapMap, &compositingState,
        backingSharingState,
        &descendantHas3DTransform)
      return
    }

    // FIXME: maybe we can avoid updating all remaining layers in paint order.
    compositingState.fullPaintOrderTraversalRequired =
      compositingState.fullPaintOrderTraversalRequired
      || layer.needsCompositingRequirementsTraversal()
    compositingState.descendantsRequireCompositingUpdate =
      compositingState.descendantsRequireCompositingUpdate
      || layer.descendantsNeedCompositingRequirementsTraversal()

    layer.setHasCompositingDescendant(false)

    // We updated compositing for direct reasons in layerStyleChanged(). Here, check for compositing that can only be evaluated after layout.
    var queryData = RequiresCompositingData()
    var willBeComposited = layer.isComposited()
    var becameCompositedAfterDescendantTraversal = false
    var compositingReason: IndirectCompositingReason =
      compositingState.subtreeIsCompositing ? .Stacking : .None

    if layer.needsPostLayoutCompositingUpdate() || compositingState.fullPaintOrderTraversalRequired
      || compositingState.descendantsRequireCompositingUpdate
    {
      layer.setIndirectCompositingReason(.None)
      willBeComposited = needsToBeComposited(layer: layer, queryData: &queryData)
    }

    compositingState.fullPaintOrderTraversalRequired =
      compositingState.fullPaintOrderTraversalRequired
      || layer.subsequentLayersNeedCompositingRequirementsTraversal()

    var layerExtent = OverlapExtent()

    // Use the fact that we're composited as a hint to check for an animating transform.
    // FIXME: Maybe needsToBeComposited() should return a bitmask of reasons, to avoid the need to recompute things.
    if willBeComposited && !layer.isRenderViewLayer {
      layerExtent.hasTransformAnimation = isRunningTransformAnimation(layer.renderer())
    }

    let respectTransforms = !layerExtent.hasTransformAnimation
    overlapMap.geometryMap.pushMappingsToAncestor(
      layer: layer, ancestorLayer: ancestorLayer, respectTransforms: respectTransforms)

    var layerPaintsIntoProvidedBacking = false
    if !willBeComposited && compositingState.subtreeIsCompositing && canBeComposited(layer),
      let provider = backingSharingState.backingProviderCandidateForLayer(
        layer, self, overlapMap, &layerExtent)
    {
      provider.sharingLayers.add(value: layer)
      compositingReason = .None
      layerPaintsIntoProvidedBacking = true
    }

    // If we know for sure the layer is going to be composited, don't bother looking it up in the overlap map
    if !willBeComposited && !layerPaintsIntoProvidedBacking && !overlapMap.isEmpty
      && compositingState.testingOverlap
    {
      // If we're testing for overlap, we only need to composite if we overlap something that is already composited.
      if layerOverlaps(overlapMap, layer, &layerExtent) {
        compositingReason = .Overlap
      } else {
        compositingReason = .None
      }
    }

    if compositingReason != .None {
      layer.setIndirectCompositingReason(compositingReason)
    }

    // Check if the computed indirect reason will force the layer to become composited.
    if !willBeComposited && layer.mustCompositeForIndirectReasons() && canBeComposited(layer) {
      willBeComposited = true
      layerPaintsIntoProvidedBacking = false
    }

    // The children of this layer don't need to composite, unless there is
    // a compositing layer among them, so start by inheriting the compositing
    // ancestor with subtreeIsCompositing set to false.
    var currentState = compositingState.stateForPaintOrderChildren(layer)
    var didPushOverlapContainer = false

    let layerWillComposite = { () in
      // This layer is going to be composited, so children can safely ignore the fact that there's an
      // animation running behind this layer, meaning they can rely on the overlap map testing again.
      currentState.testingOverlap = true
      // This layer now acts as the ancestor for kids.
      currentState.compositingAncestor = layer
      // Compositing turns off backing sharing.
      currentState.backingSharingAncestor = nil

      if layerPaintsIntoProvidedBacking {
        layerPaintsIntoProvidedBacking = false
        // layerPaintsIntoProvidedBacking was only true for layers that would otherwise composite because of overlap. If we can
        // no longer share, put this this indirect reason back on the layer so that requiresOwnBackingStore() sees it.
        layer.setIndirectCompositingReason(.Overlap)
      } else if !didPushOverlapContainer {
        overlapMap.pushCompositingContainer(layer)
        didPushOverlapContainer = true
      }

      willBeComposited = true
    }

    let layerWillCompositePostDescendants = { () in
      layerWillComposite()
      currentState.subtreeIsCompositing = true
      becameCompositedAfterDescendantTraversal = true
    }

    if willBeComposited {
      layerWillComposite()

      computeExtent(overlapMap, layer, &layerExtent)
      currentState.ancestorHasTransformAnimation =
        currentState.ancestorHasTransformAnimation || layerExtent.hasTransformAnimation
      // Too hard to compute animated bounds if both us and some ancestor is animating transform.
      layerExtent.animationCausesExtentUncertainty =
        layerExtent.animationCausesExtentUncertainty
        || layerExtent.hasTransformAnimation && compositingState.ancestorHasTransformAnimation
    } else if layerPaintsIntoProvidedBacking {
      currentState.backingSharingAncestor = layer
      overlapMap.pushCompositingContainer(layer)
      didPushOverlapContainer = true
    }

    let backingSharingSnapshot = updateBackingSharingBeforeDescendantTraversal(
      backingSharingState, overlapMap, layer, &layerExtent, willBeComposited,
      stackingContextAncestor: compositingState.stackingContextAncestor)

    var anyDescendantHas3DTransform = false
    let descendantsAddedToOverlap = currentState.hasNonRootCompositedAncestor()

    if layer.hasNegativeZOrderLayers() {
      // Speculatively push this layer onto the overlap map.
      var didSpeculativelyPushOverlapContainer = false
      if !didPushOverlapContainer {
        overlapMap.pushSpeculativeCompositingContainer(layer)
        didPushOverlapContainer = true
        didSpeculativelyPushOverlapContainer = true
      }

      for childLayer in layer.negativeZOrderLayers() {
        computeCompositingRequirements(
          ancestorLayer: layer, layer: childLayer, overlapMap, &currentState, backingSharingState,
          &anyDescendantHas3DTransform)

        // If we have to make a layer for this child, make one now so we can have a contents layer
        // (since we need to ensure that the -ve z-order child renders underneath our contents).
        if !willBeComposited && currentState.subtreeIsCompositing {
          layer.setIndirectCompositingReason(.BackgroundLayer)
          layerWillComposite()
          overlapMap.confirmSpeculativeCompositingContainer()
        }
      }

      if didSpeculativelyPushOverlapContainer {
        if overlapMap.maybePopSpeculativeCompositingContainer() {
          didPushOverlapContainer = false
        } else if !willBeComposited {
          layer.setIndirectCompositingReason(.BackgroundLayer)
          layerWillComposite()
        }
      }
    }

    for childLayer in layer.normalFlowLayers() {
      computeCompositingRequirements(
        ancestorLayer: layer, layer: childLayer, overlapMap, &currentState, backingSharingState,
        &anyDescendantHas3DTransform)
    }

    for childLayer in layer.positiveZOrderLayers() {
      computeCompositingRequirements(
        ancestorLayer: layer, layer: childLayer, overlapMap, &currentState, backingSharingState,
        &anyDescendantHas3DTransform)
    }

    // Set the flag to say that this layer has compositing children.
    layer.setHasCompositingDescendant(currentState.subtreeIsCompositing)
    layer.setHasCompositedNonContainedDescendants(currentState.hasCompositedNonContainedDescendants)

    // If we just entered compositing mode, the root will have become composited (as long as accelerated compositing is enabled).
    if layer.isRenderViewLayer {
      if usesCompositing() && m_hasAcceleratedCompositing {
        willBeComposited = true
      }
    }

    let isolatedCompositedBlending = layer.isolatesCompositedBlending()
    layer.hasNotIsolatedCompositedBlendingDescendants =
      currentState.hasNotIsolatedCompositedBlendingDescendants
    if layer.isolatesCompositedBlending() != isolatedCompositedBlending {
      // isolatedCompositedBlending affects the result of clippedByAncestor().
      layer.setChildrenNeedCompositingGeometryUpdate()
    }

    assert(
      !layer.hasNotIsolatedCompositedBlendingDescendants
        || layer.hasNotIsolatedBlendingDescendants)

    let isBackdropRoot = layer.isBackdropRoot()
    layer.hasBackdropFilterDescendantsWithoutRoot =
      currentState.hasBackdropFilterDescendantsWithoutRoot
    if layer.isBackdropRoot() != isBackdropRoot {
      layer.setNeedsCompositingConfigurationUpdate()
    }

    // Now check for reasons to become composited that depend on the state of descendant layers.
    if !willBeComposited && canBeComposited(layer) {
      let indirectReason = computeIndirectCompositingReason(
        layer, hasCompositedDescendants: currentState.subtreeIsCompositing,
        has3DTransformedDescendants: anyDescendantHas3DTransform,
        paintsIntoProvidedBacking: layerPaintsIntoProvidedBacking)
      if indirectReason != .None {
        layer.setIndirectCompositingReason(indirectReason)
        layerWillCompositePostDescendants()
      }
    }

    if let reflectionLayer = layer.reflectionLayer() {
      // FIXME: Shouldn't we call computeCompositingRequirements to handle a reflection overlapping with another renderer?
      reflectionLayer.setIndirectCompositingReason(willBeComposited ? .Stacking : .None)
    }

    // If we're back at the root, and no other layers need to be composited, and the root layer itself doesn't need
    // to be composited, then we can drop out of compositing mode altogether. However, don't drop out of compositing mode
    // if there are composited layers that we didn't hit in our traversal (e.g. because of visibility:hidden).
    var rootLayerQueryData = RequiresCompositingData()
    if layer.isRenderViewLayer && !currentState.subtreeIsCompositing
      && !requiresCompositingLayer(layer: layer, queryData: &rootLayerQueryData)
      && !m_forceCompositingMode
      && !needsCompositingForContentOrOverlays()
    {
      // Don't drop out of compositing on iOS, because we may flash. See <rdar://problem/8348337>.
      #if !WTF_PLATFORM_IOS_FAMILY
        enableCompositingMode(enable: false)
        willBeComposited = false
      #endif
    }

    assert(willBeComposited == needsToBeComposited(layer: layer, queryData: &queryData))

    // Create or destroy backing here. However, we can't update geometry because layers above us may become composited
    // during post-order traversal (e.g. for clipping).
    if updateBacking(
      layer: layer, queryData: &queryData, backingSharingState: backingSharingState,
      backingRequired: willBeComposited ? .Yes : .No)
    {
      layer.setNeedsCompositingLayerConnection()
      // Child layers need to get a geometry update to recompute their position.
      layer.setChildrenNeedCompositingGeometryUpdate()
      // The composited bounds of enclosing layers depends on which descendants are composited, so they need a geometry update.
      layer.setNeedsCompositingGeometryUpdateOnAncestors()
    }

    // Update layer state bits.
    if let reflectionLayer = layer.reflectionLayer(),
      updateLayerCompositingState(
        layer: reflectionLayer, compositingAncestor: layer, &queryData, backingSharingState)
    {
      layer.setNeedsCompositingLayerConnection()
    }

    // FIXME: clarify needsCompositingPaintOrderChildrenUpdate. If a composited layer gets a new ancestor, it needs geometry computations.
    if layer.needsCompositingPaintOrderChildrenUpdate() {
      layer.setChildrenNeedCompositingGeometryUpdate()
      layer.setNeedsCompositingLayerConnection()
    }

    layer.clearCompositingRequirementsTraversalState()

    // Compute state passed to the caller.
    descendantHas3DTransform =
      descendantHas3DTransform || anyDescendantHas3DTransform || layer.has3DTransform()
    compositingState.updateWithDescendantStateAndLayer(
      currentState, layer: layer, ancestorLayer: ancestorLayer, layerExtent)
    updateBackingSharingAfterDescendantTraversal(
      backingSharingState, overlapMap, layer, &layerExtent,
      stackingContextAncestor: compositingState.stackingContextAncestor, backingSharingSnapshot)

    let layerContributesToOverlap =
      (currentState.compositingAncestor != nil
        && !currentState.compositingAncestor!.isRenderViewLayer)
      || currentState.backingSharingAncestor != nil
    updateOverlapMap(
      overlapMap, layer, &layerExtent, didPushContainer: didPushOverlapContainer,
      addLayerToOverlap: layerContributesToOverlap,
      addDescendantsToOverlap: becameCompositedAfterDescendantTraversal
        && !descendantsAddedToOverlap)

    if layer.isComposited() {
      layer.backing!.updateAllowsBackingStoreDetaching(absoluteBounds: layerExtent.bounds)
    }

    overlapMap.geometryMap.popMappingsToAncestor(ancestorLayer: ancestorLayer)
  }

  // We have to traverse unchanged layers to fill in the overlap map.
  private func traverseUnchangedSubtree(
    ancestorLayer: RenderLayerWrapper?, layer: RenderLayerWrapper,
    _ overlapMap: LayerOverlapMap,
    _ compositingState: inout CompositingState, _ backingSharingState: BackingSharingState,
    _ descendantHas3DTransform: inout Bool
  ) {
    assert(isNativeImpl())
    layer.updateDescendantDependentFlags()
    layer.updateLayerListsIfNeeded()

    assert(!compositingState.fullPaintOrderTraversalRequired)
    assert(!layer.hasDescendantNeedingCompositingRequirementsTraversal())
    assert(!layer.needsCompositingRequirementsTraversal())

    let layerIsComposited = layer.isComposited()
    var layerPaintsIntoProvidedBacking = false
    var didPushOverlapContainer = false

    var layerExtent = OverlapExtent()
    if layerIsComposited && !layer.isRenderViewLayer {
      layerExtent.hasTransformAnimation = isRunningTransformAnimation(layer.renderer())
    }

    let respectTransforms = !layerExtent.hasTransformAnimation
    overlapMap.geometryMap.pushMappingsToAncestor(
      layer: layer, ancestorLayer: ancestorLayer, respectTransforms: respectTransforms)

    // If we know for sure the layer is going to be composited, don't bother looking it up in the overlap map
    if !layerIsComposited && !overlapMap.isEmpty && compositingState.testingOverlap {
      computeExtent(overlapMap, layer, &layerExtent)
    }

    if layer.paintsIntoProvidedBacking() {
      let provider = backingSharingState.existingBackingProviderCandidateForLayer(layer)!
      // TODO(asuhan): add security assertions
      provider.sharingLayers.add(value: layer)
      layerPaintsIntoProvidedBacking = true
    }

    var currentState = compositingState.stateForPaintOrderChildren(layer)

    if layerIsComposited {
      // This layer is going to be composited, so children can safely ignore the fact that there's an
      // animation running behind this layer, meaning they can rely on the overlap map testing again.
      currentState.testingOverlap = true
      // This layer now acts as the ancestor for kids.
      currentState.compositingAncestor = layer
      currentState.backingSharingAncestor = nil
      overlapMap.pushCompositingContainer(layer)
      didPushOverlapContainer = true

      computeExtent(overlapMap, layer, &layerExtent)
      currentState.ancestorHasTransformAnimation =
        currentState.ancestorHasTransformAnimation || layerExtent.hasTransformAnimation
      // Too hard to compute animated bounds if both us and some ancestor is animating transform.
      layerExtent.animationCausesExtentUncertainty =
        layerExtent.animationCausesExtentUncertainty
        || layerExtent.hasTransformAnimation && compositingState.ancestorHasTransformAnimation
    } else if layerPaintsIntoProvidedBacking {
      overlapMap.pushCompositingContainer(layer)
      currentState.backingSharingAncestor = layer
      didPushOverlapContainer = true
    }

    let backingSharingSnapshot = updateBackingSharingBeforeDescendantTraversal(
      backingSharingState, overlapMap, layer, &layerExtent, layerIsComposited,
      stackingContextAncestor: compositingState.stackingContextAncestor)

    var anyDescendantHas3DTransform = false

    for childLayer in layer.negativeZOrderLayers() {
      traverseUnchangedSubtree(
        ancestorLayer: layer, layer: childLayer, overlapMap, &currentState, backingSharingState,
        &anyDescendantHas3DTransform)
      assert(!currentState.subtreeIsCompositing || layerIsComposited)
    }

    for childLayer in layer.normalFlowLayers() {
      traverseUnchangedSubtree(
        ancestorLayer: layer, layer: childLayer, overlapMap, &currentState, backingSharingState,
        &anyDescendantHas3DTransform)
    }

    for childLayer in layer.positiveZOrderLayers() {
      traverseUnchangedSubtree(
        ancestorLayer: layer, layer: childLayer, overlapMap, &currentState, backingSharingState,
        &anyDescendantHas3DTransform)
    }

    // Set the flag to say that this layer has compositing children.
    assert(layer.hasCompositingDescendant == currentState.subtreeIsCompositing)
    assert(
      !canBeComposited(layer) || !RenderLayerCompositorWrapper.clipsCompositingDescendants(layer)
        || layerIsComposited)

    descendantHas3DTransform =
      descendantHas3DTransform || anyDescendantHas3DTransform || layer.has3DTransform()

    assert(!currentState.fullPaintOrderTraversalRequired)
    compositingState.updateWithDescendantStateAndLayer(
      currentState, layer: layer, ancestorLayer: ancestorLayer, layerExtent, true)
    updateBackingSharingAfterDescendantTraversal(
      backingSharingState, overlapMap, layer, &layerExtent,
      stackingContextAncestor: compositingState.stackingContextAncestor,
      backingSharingSnapshot)

    let layerContributesToOverlap =
      (currentState.compositingAncestor != nil
        && !currentState.compositingAncestor!.isRenderViewLayer)
      || currentState.backingSharingAncestor != nil
    updateOverlapMap(
      overlapMap, layer, &layerExtent, didPushContainer: didPushOverlapContainer,
      addLayerToOverlap: layerContributesToOverlap)

    overlapMap.geometryMap.popMappingsToAncestor(ancestorLayer: ancestorLayer)

    assert(!layer.needsCompositingRequirementsTraversal())
  }

  private struct UpdateLevel: OptionSet {
    let rawValue: UInt8
    static let AllDescendants = UpdateLevel(rawValue: 1 << 0)
    static let CompositedChildren = UpdateLevel(rawValue: 1 << 1)
  }

  // Recurses down the tree, parenting descendant compositing layers and collecting an array of child layers for the current compositing layer.
  private func updateBackingAndHierarchy(
    _ layer: RenderLayerWrapper, _ childLayersOfEnclosingLayer: inout ArraySlice<GraphicsLayer>,
    _ traversalState: inout UpdateBackingTraversalState,
    _ scrollingTreeState: ScrollingTreeStateRef,
    _ updateLevel: UpdateLevel = []
  ) {
    assert(isNativeImpl())
    layer.updateDescendantDependentFlags()
    layer.updateLayerListsIfNeeded()

    var layerNeedsUpdate = !updateLevel.isEmpty
    var updateLevel = updateLevel
    if layer.descendantsNeedUpdateBackingAndHierarchyTraversal() {
      updateLevel.update(with: .AllDescendants)
    }

    let scrollingStateForDescendants = ScrollingTreeStateRef(scrollingTreeState.v)
    var traversalStateForDescendants = traversalState.stateForDescendants()
    let layersClippedByScrollers: [RenderLayerWrapper] = []
    let compositedOverflowScrollLayers: [RenderLayerWrapper] = []

    if layer.needsScrollingTreeUpdate() {
      scrollingTreeState.v.needSynchronousScrollingReasonsUpdate = true
    }

    let layerBacking = layer.backing
    if layerBacking != nil {
      updateLevel.remove(.CompositedChildren)

      // We updated the composited bounds in RenderLayerBacking::updateAfterLayout(), but it may have changed
      // based on which descendants are now composited.
      if layerBacking!.updateCompositedBounds() {
        layer.setNeedsCompositingGeometryUpdate()
        // Our geometry can affect descendants.
        updateLevel.update(with: .CompositedChildren)
      }

      if layerNeedsUpdate || layer.needsCompositingConfigurationUpdate() {
        if layerBacking!.updateConfiguration(traversalState.compositingAncestor) {
          layerNeedsUpdate = true  // We also need to update geometry.
          layer.setNeedsCompositingLayerConnection()
        }

        layerBacking!.updateDebugIndicators(
          showBorder: m_showDebugBorders, showRepaintCounter: m_showRepaintCounter)
      }

      var scrollingNodeChanges: ScrollingNodeChangeFlags = .Layer
      if layerNeedsUpdate || layer.needsCompositingGeometryUpdate() {
        layerBacking!.updateGeometry(traversalState.compositingAncestor)
        scrollingNodeChanges.update(with: .LayerGeometry)
      } else if layer.needsScrollingTreeUpdate() {
        scrollingNodeChanges.update(with: .LayerGeometry)
      }

      if let reflection = layer.reflectionLayer(), let reflectionBacking = reflection.backing {
        reflectionBacking.updateCompositedBounds()
        reflectionBacking.updateGeometry(layer)
        reflectionBacking.updateAfterDescendants()
      }

      if layer.parent() == nil {
        updateRootLayerPosition()
      }

      // FIXME: do based on dirty flags. Need to do this for changes of geometry, configuration and hierarchy.
      // Need to be careful to do the right thing when a scroll-coordinated layer loses a scroll-coordinated ancestor.
      scrollingStateForDescendants.v.parentNodeID = updateScrollCoordinationForLayer(
        layer: layer, compositingAncestor: traversalState.compositingAncestor, scrollingTreeState,
        scrollingNodeChanges)
      scrollingStateForDescendants.v.nextChildIndex = 0

      traversalStateForDescendants.compositingAncestor = layer
      traversalStateForDescendants.layersClippedByScrollers = layersClippedByScrollers[...]
      traversalStateForDescendants.overflowScrollLayers = compositedOverflowScrollLayers[...]

      // TODO(asuhan): add logging
    }

    if layer.childrenNeedCompositingGeometryUpdate() {
      updateLevel.update(with: .CompositedChildren)
    }

    // If this layer has backing, then we are collecting its children, otherwise appending
    // to the compositing child list of an enclosing layer.
    var layerChildren: [GraphicsLayer] = []
    var childList = layerBacking != nil ? layerChildren[...] : childLayersOfEnclosingLayer

    let requireDescendantTraversal =
      layer.hasDescendantNeedingUpdateBackingOrHierarchyTraversal()
      || (layer.hasCompositingDescendant
        && (layerBacking == nil || layer.needsCompositingLayerConnection()
          || !updateLevel.isEmpty))

    let requiresChildRebuild =
      layerBacking != nil && layer.needsCompositingLayerConnection()
      && !layer.hasCompositingDescendant

    // TODO(asuhan): mutation checker

    let appendForegroundLayerIfNecessary = { () in
      // If a negative z-order child is compositing, we get a foreground layer which needs to get parented.
      if layer.negativeZOrderLayers().size() == 0 {
        return
      }
      if layerBacking != nil && layerBacking!.foregroundLayer != nil {
        childList.append(layerBacking!.foregroundLayer!)
      }
    }

    if requireDescendantTraversal {
      for renderLayer in layer.negativeZOrderLayers() {
        updateBackingAndHierarchy(
          renderLayer, &childList, &traversalStateForDescendants, scrollingStateForDescendants,
          updateLevel)
      }

      appendForegroundLayerIfNecessary()

      for renderLayer in layer.normalFlowLayers() {
        updateBackingAndHierarchy(
          renderLayer, &childList, &traversalStateForDescendants, scrollingStateForDescendants,
          updateLevel)
      }

      for renderLayer in layer.positiveZOrderLayers() {
        updateBackingAndHierarchy(
          renderLayer, &childList, &traversalStateForDescendants, scrollingStateForDescendants,
          updateLevel)
      }

      // Pass needSynchronousScrollingReasonsUpdate back up.
      scrollingTreeState.v.needSynchronousScrollingReasonsUpdate =
        scrollingTreeState.v.needSynchronousScrollingReasonsUpdate
        || scrollingStateForDescendants.v.needSynchronousScrollingReasonsUpdate
      if scrollingTreeState.v.parentNodeID == scrollingStateForDescendants.v.parentNodeID {
        scrollingTreeState.v.nextChildIndex = scrollingStateForDescendants.v.nextChildIndex
      }
    } else if requiresChildRebuild {
      appendForegroundLayerIfNecessary()
    }

    if layerBacking != nil {
      if requireDescendantTraversal || requiresChildRebuild {
        var widgetLayerAttachment = WidgetLayerAttachment()
        if let renderWidget = layer.renderer() as? RenderWidgetWrapper {
          widgetLayerAttachment = attachWidgetContentLayersIfNecessary(renderWidget)
        }

        collectViewTransitionNewContentLayers(layer, &childList)

        if !widgetLayerAttachment.widgetLayersAttachedAsChildren {
          // If the layer has a clipping layer the overflow controls layers will be siblings of the clipping layer.
          // Otherwise, the overflow control layers are normal children.
          if !layerBacking!.hasClippingLayer() && !layerBacking!.hasScrollingLayer(),
            let overflowControlLayer = layerBacking!.overflowControlsContainer
          {
            layerChildren.append(overflowControlLayer)
          }

          adjustOverflowScrollbarContainerLayers(
            stackingContextLayer: layer, overflowScrollLayers: compositedOverflowScrollLayers[...],
            layersClippedByScrollers: layersClippedByScrollers[...], layerChildren: &layerChildren)
          layerBacking!.parentForSublayers().setChildren(newChildren: layerChildren)
        }
      }

      // Layers that are captured in a view transition get manually parented to their pseudo in collectViewTransitionNewContentLayers.
      // The view transition root (when the document element is captured) gets parented in RenderLayerBacking::childForSuperlayers.
      var skipAddToEnclosing =
        layer.renderer().capturedInViewTransition() && !layer.renderer().isDocumentElementRenderer()
      if layer.renderer().isViewTransitionRoot()
        && layer.renderer().document().activeViewTransitionCapturedDocumentElement()
      {
        skipAddToEnclosing = true
      }

      if !skipAddToEnclosing {
        childLayersOfEnclosingLayer.append(layerBacking!.childForSuperlayers())
      }

      if layerBacking!.hasAncestorClippingLayers()
        && layerBacking!.ancestorClippingStack!.hasAnyScrollingLayers()
      {
        traversalState.layersClippedByScrollers.append(layer)
      }

      if layer.hasCompositedScrollableOverflow() {
        traversalState.overflowScrollLayers.append(layer)
      }

      layerBacking!.updateAfterDescendants()
    }

    layer.clearUpdateBackingOrHierarchyTraversalState()
  }

  // Finds the set of overflow:scroll layers whose overflow controls hosting layer needs to be reparented,
  // to ensure that the scrollbars show on top of positioned content inside the scroller.
  private func adjustOverflowScrollbarContainerLayers(
    stackingContextLayer: RenderLayerWrapper, overflowScrollLayers: ArraySlice<RenderLayerWrapper>,
    layersClippedByScrollers: ArraySlice<RenderLayerWrapper>, layerChildren: inout [GraphicsLayer]
  ) {
    assert(isNativeImpl())
    if layersClippedByScrollers.isEmpty {
      return
    }

    var overflowScrollToLastContainedLayerMap: [UInt: RenderLayerWrapper] = [:]

    for clippedLayer in layersClippedByScrollers {
      let clippingStack = clippedLayer.backing!.ancestorClippingStack!

      for stackEntry in clippingStack.stack {
        if !stackEntry.clipData.isOverflowScroll {
          continue
        }

        if let layer = stackEntry.clipData.clippingLayer {
          overflowScrollToLastContainedLayerMap[CPtrToInt(layer.layerId())] = clippedLayer
        }
      }
    }

    for overflowScrollingLayer in overflowScrollLayers {
      let lastContainedDescendant = overflowScrollToLastContainedLayerMap[
        CPtrToInt(overflowScrollingLayer.layerId())]
      if lastContainedDescendant == nil || !lastContainedDescendant!.isComposited() {
        continue
      }

      let lastContainedDescendantBacking = lastContainedDescendant!.backing
      let overflowBacking = overflowScrollingLayer.backing
      if overflowBacking == nil {
        continue
      }

      var overflowContainerLayer = overflowBacking!.overflowControlsContainer
      if overflowContainerLayer == nil {
        continue
      }

      overflowContainerLayer!.removeFromParent()

      if overflowBacking!.hasAncestorClippingLayers() {
        overflowBacking!.ensureOverflowControlsHostLayerAncestorClippingStack(
          compositedAncestor: stackingContextLayer)
      }

      if let overflowControlsAncestorClippingStack = overflowBacking!
        .overflowControlsHostLayerAncestorClippingStack
      {
        overflowControlsAncestorClippingStack.lastLayer()!.setChildren(newChildren: [
          overflowContainerLayer!
        ])
        overflowContainerLayer = overflowControlsAncestorClippingStack.firstLayer()
      }

      let lastDescendantGraphicsLayer = lastContainedDescendantBacking!.childForSuperlayers()
      let overflowScrollerGraphicsLayer = overflowBacking!.childForSuperlayers()

      var lastDescendantLayerIndex: Int? = nil
      var scrollerLayerIndex: Int? = nil
      for (i, graphicsLayer) in layerChildren.enumerated() {
        if graphicsLayer === lastDescendantGraphicsLayer {
          lastDescendantLayerIndex = i
        } else if graphicsLayer === overflowScrollerGraphicsLayer {
          scrollerLayerIndex = i
        }
      }

      if lastDescendantLayerIndex != nil && scrollerLayerIndex != nil {
        let insertionIndex = max(lastDescendantLayerIndex! + 1, scrollerLayerIndex! + 1)
        // TODO(asuhan): add logging
        layerChildren.insert(overflowContainerLayer!, at: insertionIndex)
      }

      overflowBacking!.adjustOverflowControlsPositionRelativeToAncestor(stackingContextLayer)
    }
  }

  private func isRunningTransformAnimation(_ renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    if !m_compositingTriggers.contains(.AnimationTrigger) {
      return false
    }

    if let styleable = StyleableWrapper.fromRenderer(renderer),
      let effectsStack = styleable.keyframeEffectStack()
    {
      return effectsStack.isCurrentlyAffectingProperty(.CSSPropertyTransform)
        || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyRotate)
        || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyScale)
        || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyTranslate)
    }

    return false
  }

  private func appendDocumentOverlayLayers(_ childList: inout ArraySlice<GraphicsLayer>) {
    assert(isNativeImpl())
    if !isRootFrameCompositor() || !m_compositing {
      return
    }

    if !page().pageOverlayController().hasDocumentOverlays() {
      return
    }

    let overlayHost = page().pageOverlayController().layerWithDocumentOverlays()
    childList.append(overlayHost)
  }

  private func needsCompositingForContentOrOverlays() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func scheduleRenderingUpdate() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func ensureRootLayer() {
    assert(isNativeImpl())
    let expectedAttachment: RootLayerAttachment =
      isRootFrameCompositor()
      ? .RootLayerAttachedViaChromeClient : .RootLayerAttachedViaEnclosingFrame
    if expectedAttachment == m_rootLayerAttachment {
      return
    }

    if m_rootContentsLayer == nil {
      m_rootContentsLayer = GraphicsLayer.create(factory: graphicsLayerFactory(), client: self)
      let overflowRect = snappedIntRect(rect: m_renderView!.layoutOverflowRect())
      m_rootContentsLayer!.setName(name: "content root")  // TODO(asuhan): use a static string
      m_rootContentsLayer!.setSize(
        size: FloatSize(width: Float32(overflowRect.maxX()), height: Float32(overflowRect.maxY())))
      m_rootContentsLayer!.setPosition(p: FloatPoint())

      // Need to clip to prevent transformed content showing outside this frame
      updateRootContentLayerClipping()
    }

    if requiresScrollLayer(attachment: expectedAttachment) {
      if m_overflowControlsHostLayer == nil {
        assert(m_scrolledContentsLayer == nil)
        assert(m_clipLayer == nil)

        // Create a layer to host the clipping layer and the overflow controls layers.
        m_overflowControlsHostLayer = GraphicsLayer.create(
          factory: graphicsLayerFactory(), client: self)
        m_overflowControlsHostLayer!.setName(name: "overflow controls host")  // TODO(asuhan): use a static string

        m_scrolledContentsLayer = GraphicsLayer.create(
          factory: graphicsLayerFactory(), client: self, layerType: .ScrolledContents)
        m_scrolledContentsLayer!.setName(name: "frame scrolled contents")  // TODO(asuhan): use a static string
        m_scrolledContentsLayer!.setAnchorPoint(p: FloatPoint3D())

        // FIXME: m_scrollContainerLayer and m_clipLayer have similar roles here, but m_clipLayer has some special positioning to
        // account for clipping and top content inset (see LocalFrameView::yPositionForInsetClipLayer()).
        if m_scrollContainerLayer == nil {
          m_clipLayer = GraphicsLayer.create(factory: graphicsLayerFactory(), client: self)
          m_clipLayer!.setName(name: "frame clipping")  // TODO(asuhan): use a static string
          m_clipLayer!.setMasksToBounds(b: true)
          m_clipLayer!.setAnchorPoint(p: FloatPoint3D())

          m_clipLayer!.addChild(childLayer: m_scrolledContentsLayer!)
          m_overflowControlsHostLayer!.addChild(childLayer: m_clipLayer!)
        }

        m_scrolledContentsLayer!.addChild(childLayer: m_rootContentsLayer!)

        updateScrollLayerClipping()
        updateOverflowControlsLayers()

        if hasCoordinatedScrolling() {
          scheduleRenderingUpdate()
        } else {
          updateScrollLayerPosition()
        }
      }
    } else {
      if m_overflowControlsHostLayer != nil {
        GraphicsLayer.unparentAndClear(layer: m_overflowControlsHostLayer)
        GraphicsLayer.unparentAndClear(layer: m_clipLayer)
        GraphicsLayer.unparentAndClear(layer: m_scrollContainerLayer)
        GraphicsLayer.unparentAndClear(layer: m_scrolledContentsLayer)
      }
    }

    // Check to see if we have to change the attachment
    if m_rootLayerAttachment != .RootLayerUnattached {
      detachRootLayer()
    }

    attachRootLayer(attachment: expectedAttachment)
  }

  private func destroyRootLayer() {
    assert(isNativeImpl())
    if m_rootContentsLayer == nil {
      return
    }

    detachRootLayer()

    if m_layerForHorizontalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForHorizontalScrollbar)
      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView!.frameView(), orientation: .Horizontal)
      }
      if let horizontalScrollbar = m_renderView!.frameView().horizontalScrollbar() {
        m_renderView!.frameView().invalidateScrollbar(
          scrollbar: horizontalScrollbar,
          rect: IntRect(
            location: IntPoint(x: 0, y: 0), size: horizontalScrollbar.frameRect().size))
      }
    }

    if m_layerForVerticalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForVerticalScrollbar)
      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView!.frameView(), orientation: .Vertical)
      }
      if let verticalScrollbar = m_renderView!.frameView().verticalScrollbar() {
        m_renderView!.frameView().invalidateScrollbar(
          scrollbar: verticalScrollbar,
          rect: IntRect(
            location: IntPoint(x: 0, y: 0), size: verticalScrollbar.frameRect().size))
      }
    }

    if m_layerForScrollCorner != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForScrollCorner)
      m_renderView!.frameView().invalidateScrollCorner(
        rect: m_renderView!.frameView().scrollCornerRect())
    }

    if m_overflowControlsHostLayer != nil {
      GraphicsLayer.unparentAndClear(layer: m_overflowControlsHostLayer)
      GraphicsLayer.unparentAndClear(layer: m_clipLayer)
      GraphicsLayer.unparentAndClear(layer: m_scrollContainerLayer)
      GraphicsLayer.unparentAndClear(layer: m_scrolledContentsLayer)
    }
    assert(m_scrolledContentsLayer == nil)
    GraphicsLayer.unparentAndClear(layer: m_rootContentsLayer)
  }

  private func attachRootLayer(attachment: RootLayerAttachment) {
    assert(isNativeImpl())
    if m_rootContentsLayer == nil {
      return
    }

    print("RenderLayerCompositor \(self) attachRootLayer \(attachment)")

    switch attachment {
    case .RootLayerUnattached:
      fatalError("Not reached")
    case .RootLayerAttachedViaChromeClient:
      page().chrome().client().attachRootGraphicsLayer(
        frame: m_renderView!.frameView().frame(), layer: rootGraphicsLayer())
    case .RootLayerAttachedViaEnclosingFrame:
      // The layer will get hooked up via RenderLayerBacking::updateConfiguration()
      // for the frame's renderer in the parent document.
      if let ownerElement = m_renderView!.document().ownerElement() {
        ownerElement.scheduleInvalidateStyleAndLayerComposition()
      }
    }

    m_rootLayerAttachment = attachment
    rootLayerAttachmentChanged()

    if m_shouldFlushOnReattach {
      scheduleRenderingUpdate()
      m_shouldFlushOnReattach = false
    }
  }

  private func detachRootLayer() {
    assert(isNativeImpl())
    if m_rootContentsLayer == nil || m_rootLayerAttachment == .RootLayerUnattached {
      return
    }

    if let scrollingCoordinator = scrollingCoordinator() {
      scrollingCoordinator.frameViewWillBeDetached(frameView: m_renderView!.frameView())
    }

    switch m_rootLayerAttachment {
    case .RootLayerAttachedViaEnclosingFrame:
      // The layer will get unhooked up via RenderLayerBacking::updateConfiguration()
      // for the frame's renderer in the parent document.
      if m_overflowControlsHostLayer != nil {
        m_overflowControlsHostLayer!.removeFromParent()
      } else {
        m_rootContentsLayer!.removeFromParent()
      }

      if let ownerElement = m_renderView!.document().ownerElement() {
        ownerElement.scheduleInvalidateStyleAndLayerComposition()
      }

      let frameRootScrollingNodeID = m_renderView!.frameView().scrollingNodeID()
      if frameRootScrollingNodeID.bool() {
        if let scrollingCoordinator = scrollingCoordinator() {
          scrollingCoordinator.frameViewWillBeDetached(frameView: m_renderView!.frameView())
          scrollingCoordinator.unparentNode(nodeID: frameRootScrollingNodeID)
        }
      }
    case .RootLayerAttachedViaChromeClient:
      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.frameViewWillBeDetached(frameView: m_renderView!.frameView())
      }
      page().chrome().client().attachRootGraphicsLayer(
        frame: m_renderView!.frameView().frame(), layer: nil)
    case .RootLayerUnattached:
      break
    }

    m_rootLayerAttachment = .RootLayerUnattached
    rootLayerAttachmentChanged()
  }

  private func rootLayerAttachmentChanged() {
    assert(isNativeImpl())
    // The document-relative page overlay layer (which is pinned to the main frame's layer tree)
    // is moved between different RenderLayerCompositors' layer trees, and needs to be
    // reattached whenever we swap in a new RenderLayerCompositor.
    if m_rootLayerAttachment == .RootLayerUnattached {
      return
    }

    // The attachment can affect whether the RenderView layer's paintsIntoWindow() behavior,
    // so call updateDrawsContent() to update that.
    if let backing = m_renderView!.layer()?.backing {
      backing.updateDrawsContent()
    }

    if !m_renderView!.frameView().frame().isMainFrame() {
      return
    }

    let overlayHost = page().pageOverlayController().layerWithDocumentOverlays()
    m_rootContentsLayer!.addChild(childLayer: overlayHost)
  }

  private func updateOverflowControlsLayers() {
    assert(isNativeImpl())
    if requiresHorizontalScrollbarLayer() {
      if m_layerForHorizontalScrollbar == nil {
        m_layerForHorizontalScrollbar = GraphicsLayer.create(
          factory: graphicsLayerFactory(), client: self)
        m_layerForHorizontalScrollbar!.setAllowsBackingStoreDetaching(allowDetaching: false)
        m_layerForHorizontalScrollbar!.setAllowsTiling(allowsTiling: false)
        m_layerForHorizontalScrollbar!.setShowDebugBorder(show: m_showDebugBorders)
        m_layerForHorizontalScrollbar!.setName(name: "horizontal scrollbar container")  // TODO(asuhan): use a static string
        m_overflowControlsHostLayer!.addChild(childLayer: m_layerForHorizontalScrollbar!)

        if let scrollingCoordinator = scrollingCoordinator() {
          scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
            scrollableArea: m_renderView!.frameView(), orientation: .Horizontal)
        }
      }
    } else if m_layerForHorizontalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForHorizontalScrollbar)

      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView!.frameView(), orientation: .Horizontal)
      }
    }

    if requiresVerticalScrollbarLayer() {
      if m_layerForVerticalScrollbar == nil {
        m_layerForVerticalScrollbar = GraphicsLayer.create(
          factory: graphicsLayerFactory(), client: self)
        m_layerForVerticalScrollbar!.setAllowsBackingStoreDetaching(allowDetaching: false)
        m_layerForVerticalScrollbar!.setAllowsTiling(allowsTiling: false)
        m_layerForVerticalScrollbar!.setShowDebugBorder(show: m_showDebugBorders)
        m_layerForVerticalScrollbar!.setName(name: "vertical scrollbar container")  // TODO(asuhan): use a static string
        m_overflowControlsHostLayer!.addChild(childLayer: m_layerForVerticalScrollbar!)

        if let scrollingCoordinator = scrollingCoordinator() {
          scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
            scrollableArea: m_renderView!.frameView(), orientation: .Vertical)
        }
      }
    } else if m_layerForVerticalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForVerticalScrollbar)

      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView!.frameView(), orientation: .Vertical)
      }
    }

    if requiresScrollCornerLayer() {
      if m_layerForScrollCorner == nil {
        m_layerForScrollCorner = GraphicsLayer.create(factory: graphicsLayerFactory(), client: self)
        m_layerForScrollCorner!.setAllowsBackingStoreDetaching(allowDetaching: false)
        m_layerForScrollCorner!.setShowDebugBorder(show: m_showDebugBorders)
        m_layerForScrollCorner!.setName(name: "scroll corner")  // TODO(asuhan): use a static string
        m_overflowControlsHostLayer!.addChild(childLayer: m_layerForScrollCorner!)
      }
    } else {
      GraphicsLayer.unparentAndClear(layer: m_layerForScrollCorner)
    }

    m_renderView!.frameView().positionScrollbarLayers()
  }

  private func updateScrollLayerPosition() {
    assert(isNativeImpl())
    assert(!hasCoordinatedScrolling())
    assert(m_scrolledContentsLayer != nil)

    let frameView = m_renderView!.frameView()
    let scrollPosition = frameView.scrollPosition()

    // We use scroll position here because the root content layer is offset to account for scrollOrigin (see LocalFrameView::positionForRootContentLayer).
    m_scrolledContentsLayer!.setPosition(
      p: FloatPoint(x: Float32(-scrollPosition.x), y: Float32(-scrollPosition.y)))

    if let fixedBackgroundLayer = fixedRootBackgroundLayer() {
      fixedBackgroundLayer.setPosition(p: frameView.scrollPositionForFixedPosition().FloatPoint())
    }
  }

  private func updateScrollLayerClipping() {
    assert(isNativeImpl())
    let layerForClipping = layerForClipping()
    if layerForClipping == nil {
      return
    }

    let layerSize = m_renderView!.frameView().sizeForVisibleContent()
    layerForClipping!.setSize(size: FloatSize(size: layerSize))
    layerForClipping!.setPosition(p: positionForClipLayer())
  }

  private func positionForClipLayer() -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func notifyIFramesOfCompositingChange() {
    assert(isNativeImpl())
    // Compositing affects the answer to RenderIFrame::requiresAcceleratedCompositing(), so
    // we need to schedule a style recalc in our parent document.
    if let ownerElement = m_renderView!.document().ownerElement() {
      ownerElement.scheduleInvalidateStyleAndLayerComposition()
    }
  }

  private func page() -> PageWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func graphicsLayerFactory() -> GraphicsLayerFactory? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func scrollingCoordinator() -> ScrollingCoordinatorWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Non layout-dependent
  private func requiresCompositingForAnimation(renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    if !m_compositingTriggers.contains(.AnimationTrigger) {
      return false
    }

    if let styleable = StyleableWrapper.fromRenderer(renderer) {
      if styleable.hasRunningAcceleratedAnimations() {
        return true
      }
      if let effectsStack = styleable.keyframeEffectStack() {
        return
          (effectsStack.isCurrentlyAffectingProperty(.CSSPropertyOpacity)
          && (usesCompositing() || m_compositingTriggers.contains(.AnimatedOpacityTrigger)))
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyFilter)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyBackdropFilter)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyWebkitBackdropFilter)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyTranslate)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyScale)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyRotate)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyTransform)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyOffsetAnchor)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyOffsetDistance)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyOffsetPath)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyOffsetPosition)
          || effectsStack.isCurrentlyAffectingProperty(.CSSPropertyOffsetRotate)
      }
    }

    return false
  }

  private func requiresCompositingForTransform(renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    if !m_compositingTriggers.contains(.ThreeDTransformTrigger) {
      return false
    }

    // Note that we ask the renderer if it has a transform, because the style may have transforms,
    // but the renderer may be an inline that doesn't suppport them.
    if !renderer.isTransformed() {
      return false
    }

    switch m_compositingPolicy {
    case .Normal:
      return styleHas3DTransformOperation(style: renderer.style())
    case .Conservative:
      // Continue to allow pages to avoid the very slow software filter path.
      if styleHas3DTransformOperation(style: renderer.style()) && renderer.hasFilter() {
        return true
      }
      return styleTransformOperationsAreRepresentableIn2D(style: renderer.style()) ? false : true
    }
  }

  private func requiresCompositingForBackfaceVisibility(renderer: RenderLayerModelObjectWrapper)
    -> Bool
  {
    assert(isNativeImpl())
    if !m_compositingTriggers.contains(.ThreeDTransformTrigger) {
      return false
    }

    if renderer.style().backfaceVisibility() != .Hidden {
      return false
    }

    if renderer.layer()!.has3DTransformedAncestor {
      return true
    }

    // FIXME: workaround for webkit.org/b/132801
    if let stackingContext = renderer.layer()!.stackingContext(),
      stackingContext.renderer().style().preserves3D()
    {
      return true
    }

    return false
  }

  private func requiresCompositingForViewTransition(renderer: RenderLayerModelObjectWrapper) -> Bool
  {
    assert(isNativeImpl())
    return renderer.effectiveCapturedInViewTransition() || renderer.isRenderViewTransitionCapture()
  }

  private func requiresCompositingForVideo(renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    if !m_compositingTriggers.contains(.VideoTrigger) {
      return false
    }

    if !(renderer is RenderVideoWrapper) { return false }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresCompositingForCanvas(renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    if !m_compositingTriggers.contains(.CanvasTrigger) {
      return false
    }

    if !renderer.isRenderHTMLCanvas() {
      return false
    }

    let compositingStrategy = canvasCompositingStrategy(renderer: renderer)
    if compositingStrategy == .CanvasAsLayerContents {
      return true
    }

    if m_compositingPolicy == .Normal {
      return compositingStrategy == .CanvasPaintedToLayer
    }

    return false
  }

  private func requiresCompositingForFilters(renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    if renderer.hasBackdropFilter() {
      return true
    }

    if !m_compositingTriggers.contains(.FilterTrigger) {
      return false
    }

    return renderer.hasFilter()
  }

  private func requiresCompositingForWillChange(renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    if renderer.style().willChange() == nil
      || !renderer.style().willChange()!.canTriggerCompositing()
    {
      return false
    }

    if m_compositingPolicy == .Conservative {
      return false
    }

    if renderer is RenderBoxWrapper {
      return true
    }

    return renderer.style().willChange()!.canTriggerCompositingOnInline()
  }

  private func requiresCompositingForModel(renderer: RenderLayerModelObjectWrapper) -> Bool {
    assert(isNativeImpl())
    // TODO(asuhan): support model element
    return false
  }

  // Layout-dependent
  private func requiresCompositingForPlugin(
    renderer: RenderLayerModelObjectWrapper, queryData: inout RequiresCompositingData
  ) -> Bool {
    assert(isNativeImpl())
    if !m_compositingTriggers.contains(.PluginTrigger) {
      return false
    }

    if !RenderLayerCompositorWrapper.isCompositedPlugin(renderer: renderer) {
      return false
    }

    let pluginRenderer = renderer as! RenderWidgetWrapper
    if pluginRenderer.style().usedVisibility() != .Visible {
      return false
    }

    // If we can't reliably know the size of the plugin yet, don't change compositing state.
    if queryData.layoutUpToDate == .No {
      queryData.reevaluateAfterLayout = true
      return pluginRenderer.isComposited()
    }

    // Don't go into compositing mode if height or width are zero, or size is 1x1.
    let contentBox = snappedIntRect(rect: pluginRenderer.contentBoxRect())
    return (contentBox.height() * contentBox.width() > 1)
  }

  private func requiresCompositingForFrame(
    renderer: RenderLayerModelObjectWrapper, queryData: inout RequiresCompositingData
  ) -> Bool {
    assert(isNativeImpl())
    let frameRenderer = renderer as? RenderWidgetWrapper
    if frameRenderer == nil {
      return false
    }

    if frameRenderer!.style().usedVisibility() != .Visible {
      return false
    }

    if !frameRenderer!.requiresAcceleratedCompositing() {
      return false
    }

    if queryData.layoutUpToDate == .No {
      queryData.reevaluateAfterLayout = true
      return frameRenderer!.isComposited()
    }

    // Don't go into compositing mode if height or width are zero.
    return !snappedIntRect(rect: frameRenderer!.contentBoxRect()).isEmpty()
  }

  private func requiresCompositingForScrollableFrame(_ queryData: inout RequiresCompositingData)
    -> Bool
  {
    assert(isNativeImpl())
    if isRootFrameCompositor() {
      return false
    }

    if !(m_compositingTriggers.contains(.ScrollableNonMainFrameTrigger)) {
      return false
    }

    if queryData.layoutUpToDate == .No {
      queryData.reevaluateAfterLayout = true
      return m_renderView!.isComposited()
    }

    return m_renderView!.frameView().isScrollable()
  }

  private func requiresCompositingForOverflowScrolling(
    layer: RenderLayerWrapper, queryData: inout RequiresCompositingData
  ) -> Bool {
    assert(isNativeImpl())
    if !layer.canUseCompositedScrolling() {
      return false
    }

    if queryData.layoutUpToDate == .No {
      queryData.reevaluateAfterLayout = true
      return layer.isComposited()
    }

    layer.computeHasCompositedScrollableOverflow(layoutUpToDate: .Yes)
    return layer.hasCompositedScrollableOverflow()
  }

  @discardableResult
  private func requiresCompositingForPosition(
    renderer: RenderLayerModelObjectWrapper, layer: RenderLayerWrapper,
    queryData: inout RequiresCompositingData
  ) -> Bool {
    assert(isNativeImpl())
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
    if !m_renderView!.settings().acceleratedCompositingForFixedPositionEnabled() {
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
    if CPtrToInt(container!.id()) != CPtrToInt(m_renderView!.id()) {
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

  private func computeIndirectCompositingReason(
    _ layer: RenderLayerWrapper, hasCompositedDescendants: Bool, has3DTransformedDescendants: Bool,
    paintsIntoProvidedBacking: Bool
  ) -> IndirectCompositingReason {
    assert(isNativeImpl())
    // When a layer has composited descendants, some effects, like 2d transforms, filters, masks etc must be implemented
    // via compositing so that they also apply to those composited descendants.
    let renderer = layer.renderer()
    if hasCompositedDescendants
      && (layer.isolatesCompositedBlending() || layer.isBackdropRoot() || layer.transform != nil
        || renderer.createsGroup() || renderer.hasReflection())
    {
      return .GraphicalEffect
    }

    // A layer with preserve-3d or perspective only needs to be composited if there are descendant layers that
    // will be affected by the preserve-3d or perspective.
    if has3DTransformedDescendants {
      if renderer.style().preserves3D() {
        return .Preserve3D
      }

      if renderer.style().hasPerspective() {
        return .Perspective
      }
    }

    // If this layer scrolls independently from the layer that it would paint into, it needs to get composited.
    if !paintsIntoProvidedBacking && layer.hasCompositedScrollingAncestor {
      if let paintDestination = layer.paintOrderParent(),
        RenderLayerCompositorWrapper.layerScrollBehahaviorRelativeToCompositedAncestor(
          layer, compositedAncestor: paintDestination) != .None
      {
        return .OverflowScrollPositioning
      }
    }

    // Check for clipping last; if compositing just for clipping, the layer doesn't need its own backing store.
    if hasCompositedDescendants && RenderLayerCompositorWrapper.clipsCompositingDescendants(layer) {
      return .Clipping
    }

    return .None
  }

  private static func layerScrollBehahaviorRelativeToCompositedAncestor(
    _ layer: RenderLayerWrapper, compositedAncestor: RenderLayerWrapper
  )
    -> ScrollPositioningBehavior
  {
    if !layer.hasCompositedScrollingAncestor {
      return .None
    }

    let needsMovesNode = { () in
      var result = false
      traverseAncestorLayers(
        layer,
        {
          (
            ancestorLayer: RenderLayerWrapper, isContainingBlockChain: Bool,
            _ /* isPaintOrderAncestor */: Bool
          ) in
          if CPtrToInt(ancestorLayer.layerId()) == CPtrToInt(compositedAncestor.layerId()) {
            return .Stop
          }

          if isContainingBlockChain && ancestorLayer.hasCompositedScrollableOverflow() {
            result = true
            return .Stop
          }

          return .Continue
        })

      return result
    }

    if needsMovesNode() {
      return .Moves
    }

    if layer.boxScrollingScope != compositedAncestor.contentsScrollingScope {
      return .Stationary
    }

    return .None
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

  private struct ScrollingNodeChangeFlags: OptionSet {
    let rawValue: UInt8
    static let Layer = ScrollingNodeChangeFlags(rawValue: 1 << 0)
    static let LayerGeometry = ScrollingNodeChangeFlags(rawValue: 1 << 1)
  }

  private func attachScrollingNode(
    _ layer: RenderLayerWrapper, _ nodeType: ScrollingNodeType, _ treeState: ScrollingTreeStateRef
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let scrollingCoordinator = scrollingCoordinator()
    if scrollingCoordinator == nil {
      return ScrollingNodeIDWrapper()
    }

    // Crash logs suggest that backing can be null here, but we don't know how: rdar://problem/18545452.
    let backing = layer.backing!

    assert(treeState.v.parentNodeID != nil || nodeType == .Subframe)
    assert(nodeType != .MainFrame || !treeState.v.parentNodeID!.bool())

    let role = scrollCoordinationRoleForNodeType(nodeType)
    var nodeID = backing.scrollingNodeIDForRole(role: role)

    nodeID = registerScrollingNodeID(scrollingCoordinator!, nodeID, nodeType, treeState)

    // TODO(asuhan): add logging

    if !nodeID.bool() {
      return ScrollingNodeIDWrapper()
    }

    backing.setScrollingNodeIDForRole(nodeID, role)

    scrollingNodeToLayerMap.updateValue(layer, forKey: nodeID)

    return nodeID
  }

  private func registerScrollingNodeID(
    _ scrollingCoordinator: ScrollingCoordinatorWrapper, _ nodeID: ScrollingNodeIDWrapper,
    _ nodeType: ScrollingNodeType, _ treeState: ScrollingTreeStateRef
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    var nodeID = nodeID
    if !nodeID.bool() {
      nodeID = scrollingCoordinator.uniqueScrollingNodeID()
    }

    if nodeType == .Subframe && treeState.v.parentNodeID == nil {
      nodeID = scrollingCoordinator.createNode(
        m_renderView!.frameView().frame().rootFrame().frameID(), nodeType, nodeID)
    } else {
      let newNodeID = scrollingCoordinator.insertNode(
        m_renderView!.frameView().frame().rootFrame().frameID(), nodeType, nodeID,
        parentID: treeState.v.parentNodeID ?? ScrollingNodeIDWrapper(),
        childIndex: treeState.v.nextChildIndex)
      if newNodeID != nodeID {
        // We'll get a new nodeID if the type changed (and not if the node is new).
        scrollingCoordinator.unparentChildrenAndDestroyNode(nodeID: nodeID)
        scrollingNodeToLayerMap.removeValue(forKey: nodeID)
      }
      nodeID = newNodeID
    }

    assert(nodeID.bool())

    treeState.v.nextChildIndex += 1
    return nodeID
  }

  private func coordinatedScrollingRolesForLayer(
    _ layer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?
  ) -> ScrollCoordinationRole {
    assert(isNativeImpl())
    var coordinationRoles: ScrollCoordinationRole = []
    if isViewportConstrainedFixedOrStickyLayer(layer) {
      coordinationRoles.update(with: .ViewportConstrained)
    }

    if useCoordinatedScrollingForLayer(layer) {
      coordinationRoles.update(with: .Scrolling)
    }

    let coordinatedPositioning = computeCoordinatedPositioningForLayer(
      layer, compositedAncestor: compositingAncestor)
    switch coordinatedPositioning {
    case .Moves:
      coordinationRoles.update(with: .ScrollingProxy)
    case .Stationary:
      coordinationRoles.update(with: .Positioning)
    case .None:
      break
    }

    if isLayerForIFrameWithScrollCoordinatedContents(layer) {
      coordinationRoles.update(with: .FrameHosting)
    }

    if isLayerForPluginWithScrollCoordinatedContents(layer) {
      coordinationRoles.update(with: .PluginHosting)
    }

    return coordinationRoles
  }

  // Returns the ScrollingNodeID which acts as the parent for children.
  private func updateScrollCoordinationForLayer(
    layer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?,
    _ treeState: ScrollingTreeStateRef, _ changes: ScrollingNodeChangeFlags
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let roles = coordinatedScrollingRolesForLayer(layer, compositingAncestor: compositingAncestor)

    if !hasCoordinatedScrolling() {
      // If this frame isn't coordinated, it cannot contain any scrolling tree nodes.
      return ScrollingNodeIDWrapper()
    }

    var newNodeID = treeState.v.parentNodeID ?? ScrollingNodeIDWrapper()

    let childTreeState = ScrollingTreeStateRef(ScrollingTreeState())
    var currentTreeState = treeState

    // If there's a positioning node, it's the parent scrolling node for fixed/sticky/scrolling/frame hosting.
    if roles.contains(.Positioning) {
      newNodeID = updateScrollingNodeForPositioningRole(
        layer: layer, compositingAncestor: compositingAncestor, currentTreeState, changes)
      childTreeState.v.parentNodeID = newNodeID
      currentTreeState = childTreeState
    } else {
      detachScrollCoordinatedLayer(layer: layer, roles: .Positioning)
    }

    // If there's a scrolling proxy node, it's the parent scrolling node for fixed/sticky/scrolling/frame hosting.
    if roles.contains(.ScrollingProxy) {
      newNodeID = updateScrollingNodeForScrollingProxyRole(layer, currentTreeState, changes)
      childTreeState.v.parentNodeID = newNodeID
      currentTreeState = childTreeState
    } else {
      detachScrollCoordinatedLayer(layer: layer, roles: .ScrollingProxy)
    }

    // If is fixed or sticky, it's the parent scrolling node for scrolling/frame hosting.
    if roles.contains(.ViewportConstrained) {
      newNodeID = updateScrollingNodeForViewportConstrainedRole(layer, currentTreeState, changes)
      // ViewportConstrained nodes are the parent of same-layer scrolling nodes, so adjust the ScrollingTreeState.
      childTreeState.v.parentNodeID = newNodeID
      currentTreeState = childTreeState
    } else {
      detachScrollCoordinatedLayer(layer: layer, roles: .ViewportConstrained)
    }

    if roles.contains(.Scrolling) {
      newNodeID = updateScrollingNodeForScrollingRole(layer, currentTreeState, changes)
    } else {
      detachScrollCoordinatedLayer(layer: layer, roles: .Scrolling)
    }

    if roles.contains(.FrameHosting) {
      newNodeID = updateScrollingNodeForFrameHostingRole(layer, currentTreeState, changes)
    } else {
      detachScrollCoordinatedLayer(layer: layer, roles: .FrameHosting)
    }

    if roles.contains(.PluginHosting) {
      newNodeID = updateScrollingNodeForPluginHostingRole(layer, currentTreeState, changes)
    } else {
      detachScrollCoordinatedLayer(layer: layer, roles: .PluginHosting)
    }

    return newNodeID
  }

  // These return the ScrollingNodeID which acts as the parent for children.
  private func updateScrollingNodeForViewportConstrainedRole(
    _ layer: RenderLayerWrapper, _ treeState: ScrollingTreeStateRef,
    _ changes: ScrollingNodeChangeFlags
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let scrollingCoordinator = scrollingCoordinator()

    var nodeType: ScrollingNodeType = .Fixed
    if layer.renderer().style().position() == .Sticky {
      nodeType = .Sticky
    } else {
      assert(layer.renderer().isFixedPositioned())
    }

    let newNodeID = attachScrollingNode(layer, nodeType, treeState)
    if !newNodeID.bool() {
      fatalError("Not reached")
    }

    // TODO(asuhan): add logging

    if changes.contains(.Layer) {
      assert(layer.backing!.viewportAnchorLayer != nil)
      scrollingCoordinator!.setNodeLayers(
        newNodeID,
        ScrollingCoordinatorWrapper.NodeLayers(layer: layer.backing!.viewportAnchorLayer))
    }

    if changes.contains(.LayerGeometry) {
      switch nodeType {
      case .Fixed:
        scrollingCoordinator!.setViewportConstraintedNodeConstraints(
          newNodeID, computeFixedViewportConstraints(layer))
      case .Sticky:
        scrollingCoordinator!.setViewportConstraintedNodeConstraints(
          newNodeID, computeStickyViewportConstraints(layer))
      default:
        break
      }
    }

    return newNodeID
  }

  private func updateScrollingNodeForScrollingRole(
    _ layer: RenderLayerWrapper, _ treeState: ScrollingTreeStateRef,
    _ changes: ScrollingNodeChangeFlags
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let scrollingCoordinator = scrollingCoordinator()

    var newNodeID = ScrollingNodeIDWrapper()

    if layer.isRenderViewLayer {
      let frameView = m_renderView!.frameView()
      assert(scrollingCoordinator!.coordinatesScrollingForFrameView(frameView: frameView))

      newNodeID = attachScrollingNode(
        m_renderView!.layer()!, m_renderView!.frame().isMainFrame() ? .MainFrame : .Subframe,
        treeState)

      if !newNodeID.bool() {
        fatalError("Not reached")
      }

      if changes.contains(.Layer) {
        updateScrollingNodeLayers(newNodeID, layer, scrollingCoordinator!)
      }

      if changes.contains(.LayerGeometry) {
        scrollingCoordinator!.setScrollingNodeScrollableAreaGeometry(newNodeID, frameView)
        scrollingCoordinator!.setFrameScrollingNodeState(newNodeID, frameView)
      }
      page().chrome().client().ensureScrollbarsController(page(), frameView, true)
    } else {
      newNodeID = attachScrollingNode(layer, .Overflow, treeState)
      if !newNodeID.bool() {
        fatalError("Not reached")
      }

      if changes.contains(.Layer) {
        updateScrollingNodeLayers(newNodeID, layer, scrollingCoordinator!)
      }

      if changes.contains(.LayerGeometry) && treeState.v.parentNodeID != nil,
        let scrollableArea = layer.scrollableArea()
      {
        scrollingCoordinator!.setScrollingNodeScrollableAreaGeometry(newNodeID, scrollableArea)
      }
      if let scrollableArea = layer.scrollableArea() {
        page().chrome().client().ensureScrollbarsController(page(), scrollableArea, true)
      }
    }

    return newNodeID
  }

  private func updateScrollingNodeForScrollingProxyRole(
    _ layer: RenderLayerWrapper, _ treeState: ScrollingTreeStateRef,
    _ changes: ScrollingNodeChangeFlags
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let scrollingCoordinator = scrollingCoordinator()
    let clippingStack = layer.backing!.ancestorClippingStack
    if clippingStack == nil {
      return treeState.v.parentNodeID ?? ScrollingNodeIDWrapper()
    }

    var nodeID = ScrollingNodeIDWrapper()
    for i in 0..<clippingStack!.stack.count {
      if !clippingStack!.stack[i].clipData.isOverflowScroll {
        continue
      }

      nodeID = registerScrollingNodeID(
        scrollingCoordinator!, clippingStack!.stack[i].overflowScrollProxyNodeID, .OverflowProxy,
        treeState)
      if !nodeID.bool() {
        fatalError("Not reached")
      }
      clippingStack!.stack[i].overflowScrollProxyNodeID = nodeID

      if changes.contains(.Layer) {
        scrollingCoordinator!.setNodeLayers(
          clippingStack!.stack[i].overflowScrollProxyNodeID,
          ScrollingCoordinatorWrapper.NodeLayers(layer: clippingStack!.stack[i].scrollingLayer))
      }

      if changes.contains(.LayerGeometry) {
        if !setupScrollProxyRelatedOverflowScrollingNode(
          scrollingCoordinator!, clippingStack!.stack[i].overflowScrollProxyNodeID,
          clippingStack!.stack[i].clipData.clippingLayer!)
        {
          layersWithUnresolvedRelations.add(value: layer)
        }
      }
    }

    // FIXME: also m_overflowControlsHostLayerAncestorClippingStack

    if !nodeID.bool() {
      return treeState.v.parentNodeID ?? ScrollingNodeIDWrapper()
    }

    return nodeID
  }

  private func updateScrollingNodeForFrameHostingRole(
    _ layer: RenderLayerWrapper, _ treeState: ScrollingTreeStateRef,
    _ changes: ScrollingNodeChangeFlags
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let scrollingCoordinator = scrollingCoordinator()

    let newNodeID = attachScrollingNode(layer, .FrameHosting, treeState)
    if !newNodeID.bool() {
      fatalError("Not reached")
    }

    if changes.contains(.Layer) {
      scrollingCoordinator!.setNodeLayers(
        newNodeID, ScrollingCoordinatorWrapper.NodeLayers(layer: layer.backing!.graphicsLayer()))
    }

    if let renderWidget = layer.renderer() as? RenderWidgetWrapper,
      let frame = renderWidget.frameOwnerElement().contentFrame(),
      let remoteFrame = frame as? RemoteFrameWrapper
    {
      scrollingCoordinator!.setLayerHostingContextIdentifierForFrameHostingNode(
        newNodeID, remoteFrame.layerHostingContextIdentifier())
    }
    return newNodeID
  }

  private func updateScrollingNodeForPluginHostingRole(
    _ layer: RenderLayerWrapper, _ treeState: ScrollingTreeStateRef,
    _ changes: ScrollingNodeChangeFlags
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let newNodeID = attachScrollingNode(layer, .PluginHosting, treeState)
    if !newNodeID.bool() {
      fatalError("Not reached")
    }

    return newNodeID
  }

  private func updateScrollingNodeForPositioningRole(
    layer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?,
    _ treeState: ScrollingTreeStateRef, _ changes: ScrollingNodeChangeFlags
  ) -> ScrollingNodeIDWrapper {
    assert(isNativeImpl())
    let scrollingCoordinator = scrollingCoordinator()

    let newNodeID = attachScrollingNode(layer, .Positioned, treeState)
    if !newNodeID.bool() {
      fatalError("Not reached")
    }

    if changes.contains(.Layer) {
      let backing = layer.backing!
      scrollingCoordinator!.setNodeLayers(
        newNodeID, ScrollingCoordinatorWrapper.NodeLayers(layer: backing.graphicsLayer()))
    }

    if changes.contains(.LayerGeometry) && treeState.v.parentNodeID != nil {
      // Would be nice to avoid calling computeCoordinatedPositioningForLayer() again.
      let positioningBehavior = computeCoordinatedPositioningForLayer(
        layer, compositedAncestor: compositingAncestor)
      let relatedNodeIDs = collectRelatedCoordinatedScrollingNodes(layer, positioningBehavior)
      scrollingCoordinator!.setRelatedOverflowScrollingNodes(newNodeID, relatedNodeIDs[...])

      let graphicsLayer = layer.backing!.graphicsLayer()!
      let constraints = AbsolutePositionConstraints(
        alignmentOffset: graphicsLayer.pixelAlignmentOffset(),
        layerPositionAtLastLayout: graphicsLayer.position())
      scrollingCoordinator!.setPositionedNodeConstraints(newNodeID, constraints)
    }

    return newNodeID
  }

  private func updateScrollingNodeLayers(
    _ nodeID: ScrollingNodeIDWrapper, _ layer: RenderLayerWrapper,
    _ scrollingCoordinator: ScrollingCoordinatorWrapper
  ) {
    assert(isNativeImpl())
    // Plugins handle their own scrolling node layers.
    if isLayerForPluginWithScrollCoordinatedContents(layer) {
      return
    }

    if layer.isRenderViewLayer {
      let frameView = m_renderView!.frameView()
      scrollingCoordinator.setNodeLayers(
        nodeID,
        ScrollingCoordinatorWrapper.NodeLayers(
          layer: nil, scrollContainerLayer: scrollContainerLayer(),
          scrolledContentsLayer: scrolledContentsLayer(),
          counterScrollingLayer: fixedRootBackgroundLayer(), insetClipLayer: clipLayer(),
          rootContentsLayer: rootContentsLayer(),
          horizontalScrollbarLayer: frameView.layerForHorizontalScrollbar(),
          verticalScrollbarLayer: frameView.layerForVerticalScrollbar()))
    } else {
      let scrollableArea = layer.scrollableArea()!

      let backing = layer.backing!
      scrollingCoordinator.setNodeLayers(
        nodeID,
        ScrollingCoordinatorWrapper.NodeLayers(
          layer: backing.graphicsLayer(),
          scrollContainerLayer: backing.scrollContainerLayer,
          scrolledContentsLayer: backing.scrolledContentsLayer,
          counterScrollingLayer: nil, insetClipLayer: nil, rootContentsLayer: nil,
          horizontalScrollbarLayer: scrollableArea.layerForHorizontalScrollbar(),
          verticalScrollbarLayer: scrollableArea.layerForVerticalScrollbar()))
    }
  }

  private func detachScrollCoordinatedLayer(
    layer: RenderLayerWrapper, roles: ScrollCoordinationRole
  ) {
    assert(isNativeImpl())
    let backing = layer.backing
    if backing == nil {
      return
    }

    let scrollingCoordinator = scrollingCoordinator()
    if scrollingCoordinator == nil {
      return
    }

    if roles.contains(.Scrolling) {
      detachScrollCoordinatedLayerWithRole(
        layer: layer, scrollingCoordinator: scrollingCoordinator!, role: .Scrolling)
    }

    if roles.contains(.ScrollingProxy) {
      detachScrollCoordinatedLayerWithRole(
        layer: layer, scrollingCoordinator: scrollingCoordinator!, role: .ScrollingProxy)
    }

    if roles.contains(.FrameHosting) {
      detachScrollCoordinatedLayerWithRole(
        layer: layer, scrollingCoordinator: scrollingCoordinator!, role: .FrameHosting)
    }

    if roles.contains(.PluginHosting) {
      detachScrollCoordinatedLayerWithRole(
        layer: layer, scrollingCoordinator: scrollingCoordinator!, role: .PluginHosting)
    }

    if roles.contains(.ViewportConstrained) {
      detachScrollCoordinatedLayerWithRole(
        layer: layer, scrollingCoordinator: scrollingCoordinator!, role: .ViewportConstrained)
    }

    if roles.contains(.Positioning) {
      detachScrollCoordinatedLayerWithRole(
        layer: layer, scrollingCoordinator: scrollingCoordinator!, role: .Positioning)
    }

    backing!.detachFromScrollingCoordinator(roles: roles)
  }

  private func detachScrollCoordinatedLayerWithRole(
    layer: RenderLayerWrapper, scrollingCoordinator: ScrollingCoordinatorWrapper,
    role: ScrollCoordinationRole
  ) {
    assert(isNativeImpl())
    if role == .ScrollingProxy {
      assert(layer.isComposited())
      let clippingStack = layer.backing!.ancestorClippingStack
      if clippingStack == nil {
        return
      }

      for entry in clippingStack!.stack {
        if entry.overflowScrollProxyNodeID.bool() {
          unregisterNode(
            nodeID: entry.overflowScrollProxyNodeID, scrollingCoordinator: scrollingCoordinator)
        }
      }
      return
    }

    let nodeID = layer.backing!.scrollingNodeIDForRole(role: role)
    if !nodeID.bool() {
      return
    }

    unregisterNode(nodeID: nodeID, scrollingCoordinator: scrollingCoordinator)
  }

  private func unregisterNode(
    nodeID: ScrollingNodeIDWrapper, scrollingCoordinator: ScrollingCoordinatorWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func resolveScrollingTreeRelationships() {
    assert(isNativeImpl())
    if layersWithUnresolvedRelations.isEmptyIgnoringNullReferences() {
      return
    }

    let scrollingCoordinator = scrollingCoordinator()

    for layer in layersWithUnresolvedRelations {
      // TODO(asuhan): add logging

      if !layer.isComposited() {
        continue
      }

      if let clippingStack = layer.backing!.ancestorClippingStack {
        for entry in clippingStack.stack {
          if !entry.clipData.isOverflowScroll {
            continue
          }

          let succeeded = setupScrollProxyRelatedOverflowScrollingNode(
            scrollingCoordinator!, entry.overflowScrollProxyNodeID, entry.clipData.clippingLayer!)
          assert(succeeded)
        }
      }
    }

    layersWithUnresolvedRelations.clear()
  }

  private func setupScrollProxyRelatedOverflowScrollingNode(
    _ scrollingCoordinator: ScrollingCoordinatorWrapper,
    _ scrollingProxyNodeID: ScrollingNodeIDWrapper, _ overflowScrollingLayer: RenderLayerWrapper
  ) -> Bool {
    assert(isNativeImpl())
    let backing = overflowScrollingLayer.backing
    if backing == nil {
      return false
    }

    let overflowScrollNodeID = backing!.scrollingNodeIDForRole(role: .Scrolling)
    if !overflowScrollNodeID.bool() {
      return false
    }

    scrollingCoordinator.setRelatedOverflowScrollingNodes(
      scrollingProxyNodeID, [overflowScrollNodeID][...])
    return true
  }

  private func updateSynchronousScrollingNodes() {
    assert(isNativeImpl())
    if !hasCoordinatedScrolling() {
      return
    }

    if m_renderView!.settings().fixedBackgroundsPaintRelativeToDocument() {
      return
    }

    let scrollingCoordinator = scrollingCoordinator()!

    let rootScrollingNodeID = m_renderView!.frameView().scrollingNodeID()
    var nodesToClear: Set<ScrollingNodeIDWrapper> = []
    nodesToClear.reserveCapacity(scrollingNodeToLayerMap.count)
    for key in scrollingNodeToLayerMap.keys {
      nodesToClear.update(with: key)
    }

    let clearSynchronousReasonsOnNonRootNodes = { () in
      for nodeID in nodesToClear {
        if nodeID == rootScrollingNodeID {
          continue
        }

        // Harmless to call setSynchronousScrollingReasons on a non-scrolling node.
        scrollingCoordinator.setSynchronousScrollingReasons(nodeID, [])
      }
    }

    let setHasSlowRepaintObjectsSynchronousScrollingReasonOnRootNode = {
      (hasSlowRepaintObjects: Bool) in
      // ScrollingCoordinator manages all bits other than HasSlowRepaintObjects, so maintain their current value.
      var reasons = scrollingCoordinator.synchronousScrollingReasons(rootScrollingNodeID)
      if hasSlowRepaintObjects {
        reasons.update(with: .HasSlowRepaintObjects)
      } else {
        reasons.remove(.HasSlowRepaintObjects)
      }
      scrollingCoordinator.setSynchronousScrollingReasons(rootScrollingNodeID, reasons)
    }

    let slowRepaintObjects = m_renderView!.frameView().slowRepaintObjects()
    if slowRepaintObjects == nil {
      setHasSlowRepaintObjectsSynchronousScrollingReasonOnRootNode(false)
      clearSynchronousReasonsOnNonRootNodes()
      return
    }

    let relevantScrollingScope = { (renderer: RenderObjectWrapper, layer: RenderLayerWrapper) in
      return CPtrToInt(layer.renderer().id()) == CPtrToInt(renderer.id())
        ? layer.boxScrollingScope : layer.contentsScrollingScope
    }

    var rootHasSlowRepaintObjects = false
    for renderer in slowRepaintObjects! {
      guard let layer = renderer.enclosingLayer() else {
        continue
      }

      if relevantScrollingScope(renderer, layer) == nil {
        continue
      }

      let enclosingScrollingNodeID = RenderLayerCompositorWrapper.asyncScrollableContainerNodeID(
        renderer)
      // TODO(asuhan): add logging
      if enclosingScrollingNodeID.bool() {
        scrollingCoordinator.setSynchronousScrollingReasons(
          enclosingScrollingNodeID, [.HasSlowRepaintObjects])
        nodesToClear.remove(enclosingScrollingNodeID)

        // Although the root scrolling layer does not have a slow repaint object in it directly,
        // we need to set some synchronous scrolling reason on it so that
        // ScrollingCoordinator::shouldUpdateScrollLayerPositionSynchronously returns an
        // appropriate value. (Scrolling itself would be correct without this, since the
        // scrolling tree propagates DescendantScrollersHaveSynchronousScrolling bits up the
        // tree, but shouldUpdateScrollLayerPositionSynchronously looks at the scrolling state
        // tree instead.)
        rootHasSlowRepaintObjects = true
      } else if !layer.behavesAsFixed {
        rootHasSlowRepaintObjects = true
      }
    }

    setHasSlowRepaintObjectsSynchronousScrollingReasonOnRootNode(rootHasSlowRepaintObjects)
    clearSynchronousReasonsOnNonRootNodes()
  }

  private func computeFixedViewportConstraints(_ layer: RenderLayerWrapper)
    -> FixedPositionViewportConstraints
  {
    assert(isNativeImpl())
    assert(layer.isComposited())

    guard let anchorLayer = layer.backing!.viewportAnchorLayer else {
      fatalError("Not reached")
    }

    let constraints = FixedPositionViewportConstraints()
    constraints.setLayerPositionAtLastLayout(anchorLayer.position())
    constraints.setViewportRectAtLastLayout(
      m_renderView!.frameView().rectForFixedPositionLayout().FloatRect())
    constraints.setAlignmentOffset(anchorLayer.pixelAlignmentOffset())

    let style = layer.renderer().style()
    if !style.left().isAuto() {
      constraints.addAnchorEdge(edgeFlag: .AnchorEdgeLeft)
    }

    if !style.right().isAuto() {
      constraints.addAnchorEdge(edgeFlag: .AnchorEdgeRight)
    }

    if !style.top().isAuto() {
      constraints.addAnchorEdge(edgeFlag: .AnchorEdgeTop)
    }

    if !style.bottom().isAuto() {
      constraints.addAnchorEdge(edgeFlag: .AnchorEdgeBottom)
    }

    // If left and right are auto, use left.
    if style.left().isAuto() && style.right().isAuto() {
      constraints.addAnchorEdge(edgeFlag: .AnchorEdgeLeft)
    }

    // If top and bottom are auto, use top.
    if style.top().isAuto() && style.bottom().isAuto() {
      constraints.addAnchorEdge(edgeFlag: .AnchorEdgeTop)
    }

    return constraints
  }

  private func computeStickyViewportConstraints(_ layer: RenderLayerWrapper)
    -> StickyPositionViewportConstraints
  {
    assert(isNativeImpl())
    assert(layer.isComposited())

    let renderer = layer.renderer() as! RenderBoxModelObjectWrapper

    guard let anchorLayer = layer.backing!.viewportAnchorLayer else {
      fatalError("Not reached")
    }

    let constraints = renderer.computeStickyPositionConstraints(
      constrainingRect: renderer.constrainingRectForStickyPosition())

    constraints.setLayerPositionAtLastLayout(anchorLayer.position())
    constraints.setStickyOffsetAtLastLayout(renderer.stickyPositionOffset().FloatSize())
    constraints.setAlignmentOffset(anchorLayer.pixelAlignmentOffset())

    return constraints
  }

  private func requiresScrollLayer(attachment: RootLayerAttachment) -> Bool {
    assert(isNativeImpl())
    let frameView = m_renderView!.frameView()

    // This applies when the application UI handles scrolling, in which case RenderLayerCompositor doesn't need to manage it.
    if frameView.delegatedScrollingMode() == .DelegatedToNativeScrollView && isMainFrameCompositor()
    {
      return false
    }

    // We need to handle our own scrolling if we're:
    return m_renderView!.frameView().platformWidget() == nil  // viewless (i.e. non-Mac, or Mac in WebKit2)
      || attachment == .RootLayerAttachedViaEnclosingFrame  // a composited frame on Mac
  }

  private func requiresHorizontalScrollbarLayer() -> Bool {
    assert(isNativeImpl())
    return shouldCompositeOverflowControls()
      && m_renderView!.frameView().horizontalScrollbar() != nil
  }

  private func requiresVerticalScrollbarLayer() -> Bool {
    assert(isNativeImpl())
    return shouldCompositeOverflowControls() && m_renderView!.frameView().verticalScrollbar() != nil
  }

  private func requiresScrollCornerLayer() -> Bool {
    assert(isNativeImpl())
    return shouldCompositeOverflowControls() && m_renderView!.frameView().isScrollCornerVisible()
  }

  // True if the FrameView uses a ScrollingCoordinator.
  private func hasCoordinatedScrolling() -> Bool {
    assert(isNativeImpl())
    if let scrollingCoordinator = scrollingCoordinator() {
      return scrollingCoordinator.coordinatesScrollingForFrameView(
        frameView: m_renderView!.frameView())
    }
    return false
  }

  // FIXME: make the coordinated/async terminology consistent.
  private func isAsyncScrollableStickyLayer(layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    assert(layer.renderer().isStickilyPositioned())

    let enclosingOverflowLayer = layer.enclosingOverflowClipLayer(includeSelf: .ExcludeSelf)

    if enclosingOverflowLayer != nil && enclosingOverflowLayer!.hasCompositedScrollableOverflow() {
      return true
    }

    // If the layer is inside normal overflow, it's not async-scrollable.
    if enclosingOverflowLayer != nil {
      return false
    }

    // No overflow ancestor, so see if the frame supports async scrolling.
    if hasCoordinatedScrolling() {
      return true
    }

    return false
  }

  private func shouldCompositeOverflowControls() -> Bool {
    assert(isNativeImpl())
    let frameView = m_renderView!.frameView()

    if !frameView.managesScrollbars() {
      return false
    }

    if documentUsesTiledBacking() {
      return true
    }

    if m_overflowControlsHostLayer != nil && isMainFrameCompositor() {
      return true
    }

    return true
  }

  private func documentUsesTiledBacking() -> Bool {
    assert(isNativeImpl())
    let layer = m_renderView!.layer()
    if layer == nil {
      return false
    }

    if let backing = layer!.backing {
      return backing.isFrameLayerWithTiledBacking
    }

    return false
  }

  private func isRootFrameCompositor() -> Bool {
    assert(isNativeImpl())
    return m_renderView!.frameView().frame().isRootFrame()
  }

  private func isMainFrameCompositor() -> Bool {
    assert(isNativeImpl())
    return m_renderView!.frameView().frame().isMainFrame()
  }

  func interop() -> UnsafeMutableRawPointer {
    assert(!isNativeImpl())
    return pInterop!
  }

  private func isNativeImpl() -> Bool { return pInterop == nil }

  private let m_renderView: RenderViewWrapper?  // TODO(asuhan): make it non-optional
  private let m_updateCompositingLayersTimer: Timer

  private var m_compositingTriggers: ChromeClient.CompositingTriggerFlags = .AllTriggers
  private var m_hasAcceleratedCompositing = true

  private var m_compositingPolicy: CompositingPolicy = .Normal
  private let m_compositingPolicyHysteresis = PAL.HysteresisActivity()

  private var m_showDebugBorders = false
  private var m_showRepaintCounter = false
  private var m_acceleratedDrawingEnabled = false

  private var m_compositing = false
  private var m_shouldFlushOnReattach = false
  private var m_forceCompositingMode = false

  private var contentLayersCount: UInt32 = 0
  private var m_layersWithTiledBackingCount: UInt32 = 0
  private var m_compositingUpdateCount: UInt32 = 0

  private var m_rootLayerAttachment: RootLayerAttachment = .RootLayerUnattached

  private var m_rootContentsLayer: GraphicsLayer? = nil

  // Enclosing clipping layer for iframe content
  private var m_clipLayer: GraphicsLayer? = nil
  private var m_scrollContainerLayer: GraphicsLayer? = nil
  private var m_scrolledContentsLayer: GraphicsLayer? = nil

  // Enclosing layer for overflow controls and the clipping layer
  private var m_overflowControlsHostLayer: GraphicsLayer? = nil

  // Layers for overflow controls
  private var m_layerForHorizontalScrollbar: GraphicsLayer? = nil
  private var m_layerForVerticalScrollbar: GraphicsLayer? = nil
  private var m_layerForScrollCorner: GraphicsLayer? = nil

  private var m_viewBackgroundIsTransparent = false

  private var m_viewBackgroundColor = ColorWrapper()
  private var m_rootExtendedBackgroundColor = ColorWrapper()

  private var scrollingNodeToLayerMap: [ScrollingNodeIDWrapper: RenderLayerWrapper?]
  private let layersWithUnresolvedRelations = WeakHashSet<RenderLayerWrapper>()

  private let pInterop: UnsafeMutableRawPointer?
}
