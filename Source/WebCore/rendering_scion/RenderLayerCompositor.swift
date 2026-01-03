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

enum CompositingUpdateType {
  case AfterStyleChange
  case AfterLayout
  case OnScroll
  case OnCompositedScroll
}

struct ScrollingTreeState {
  var parentNodeID: ScrollingNodeIDWrapper?
  let nextChildIndex: UInt64
  let needSynchronousScrollingReasonsUpdate = false
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

    let isPaintOrderAncestor = CPtrToInt(ancestorLayer!.p) == CPtrToInt(nextPaintOrderParent?.p)
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
    let clippingScopes: LayerOverlapMap.LayerAndBoundsVector = []

    var extentComputed = false
    var hasTransformAnimation = false
    var animationCausesExtentUncertainty = false
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
  }

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
    if enable != m_compositing {
      m_compositing = enable

      if m_compositing {
        ensureRootLayer()
        notifyIFramesOfCompositingChange()
      } else {
        destroyRootLayer()
      }

      m_renderView.layer()!.setNeedsPostLayoutCompositingUpdate()
    }
  }

  // True when some content element other than the root is composited.
  func hasContentCompositingLayers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Rebuild the tree of compositing layers
  func updateCompositingLayers(
    updateType: CompositingUpdateType, updateRoot: RenderLayerWrapper? = nil
  ) -> Bool {
    // TODO(asuhan): add logging and tree debugging
    let _ = TraceScope(.CompositingUpdateStart, .CompositingUpdateEnd)

    if updateType == .AfterStyleChange || updateType == .AfterLayout {
      cacheAcceleratedCompositingFlagsAfterLayout()  // Some flags (e.g. forceCompositingMode) depend on layout.
    }

    m_updateCompositingLayersTimer.stop()

    assert(
      m_renderView.document().backForwardCacheState() == .NotInBackForwardCache
        || m_renderView.document().backForwardCacheState() == .AboutToEnterBackForwardCache)

    // Compositing layers will be updated in Document::setVisualUpdatesAllowed(bool) if suppressed here.
    if !m_renderView.document().visualUpdatesAllowed() {
      return false
    }

    // Avoid updating the layers with old values. Compositing layers will be updated after the layout is finished.
    // This happens when m_updateCompositingLayersTimer fires before layout is updated.
    if m_renderView.needsLayout() {
      return false
    }

    if !m_compositing
      && (m_forceCompositingMode
        || (isRootFrameCompositor() && page().pageOverlayController().overlayCount() != 0))
    {
      enableCompositingMode(enable: true)
    }

    let isPageScroll =
      updateRoot == nil || CPtrToInt(updateRoot!.p) == CPtrToInt(rootRenderLayer().p)
    let updateRoot = rootRenderLayer()

    if updateType == .OnScroll || updateType == .OnCompositedScroll {
      // We only get here if we didn't scroll on the scrolling thread, so this update needs to re-position viewport-constrained layers.
      if m_renderView.settings().acceleratedCompositingForFixedPositionEnabled() && isPageScroll,
        let viewportConstrainedObjects = m_renderView.frameView().viewportConstrainedObjects()
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
        allowOverlappingProviders: m_renderView.settings().overlappingBackingStoreProvidersEnabled()
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
      var scrollingTreeState = ScrollingTreeState(
        parentNodeID: ScrollingNodeIDWrapper(), nextChildIndex: 0)

      if !m_renderView.frame().isMainFrame() {
        scrollingTreeState.parentNodeID = frameHostingNodeForFrame(m_renderView.frame())
      }

      let scrollingCoordinator = scrollingCoordinator()
      let hadSubscrollers =
        scrollingCoordinator != nil
        ? scrollingCoordinator!.hasSubscrollers(m_renderView.frame().rootFrame().frameID()) : false

      let traversalState = UpdateBackingTraversalState()
      let childList: [GraphicsLayer] = []
      updateBackingAndHierarchy(updateRoot, childList[...], traversalState, scrollingTreeState)

      if scrollingTreeState.needSynchronousScrollingReasonsUpdate {
        updateSynchronousScrollingNodes()
      }

      // Host the document layer in the RenderView's root layer.
      appendDocumentOverlayLayers(childList[...])
      // Even when childList is empty, don't drop out of compositing mode if there are
      // composited layers that we didn't hit in our traversal (e.g. because of visibility:hidden).
      if childList.isEmpty && !needsCompositingForContentOrOverlays() {
        destroyRootLayer()
      } else if m_rootContentsLayer != nil {
        m_rootContentsLayer!.setChildren(newChildren: childList)
      }

      if scrollingCoordinator != nil
        && scrollingCoordinator!.hasSubscrollers(m_renderView.frame().rootFrame().frameID())
          != hadSubscrollers
      {
        invalidateEventRegionForAllFrames()
      }

      resolveScrollingTreeRelationships()
    }

    // FIXME: Only do if dirty.
    updateRootLayerPosition()

    // TODO(asuhan): call into InspectorInstrumentation

    if m_renderView.needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() {
      m_renderView.repaintRootContents()
      m_renderView.setNeedsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(false)
    }

    return true
  }

  struct RequiresCompositingData {
    var layoutUpToDate: LayoutUpToDate = .Yes
    var nonCompositedForPositionReason: RenderLayerWrapper.ViewportConstrainedNotCompositedReason =
      .NoNotCompositedReason
    var reevaluateAfterLayout = false
    var intrinsic = false
  }

  // Whether layer's backing needs a graphics layer to clip z-order children of the given layer.
  // Return true if the given layer is a stacking context and has compositing child
  // layers that it needs to clip. In this case we insert a clipping GraphicsLayer
  // into the hierarchy between this layer and its children in the z-order hierarchy.
  private static func clipsCompositingDescendants(_ layer: RenderLayerWrapper) -> Bool {
    if !(layer.hasCompositingDescendant && layer.renderer().hasClipOrNonVisibleOverflow()) {
      return false
    }

    if layer.hasCompositedNonContainedDescendants {
      return false
    }

    return canUseDescendantClippingLayer(layer)
  }

  func fixedLayerIntersectsViewport(layer: RenderLayerWrapper) -> Bool {
    assert(layer.renderer().isFixedPositioned())

    // Fixed position elements that are invisible in the current view don't get their own layer.
    // FIXME: We shouldn't have to check useFixedLayout() here; one of the viewport rects needs to give the correct answer.
    var viewBounds = LayoutRectWrapper()
    if m_renderView.frameView().useFixedLayout() {
      viewBounds = LayoutRectWrapper(rect: m_renderView.unscaledDocumentRect())
    } else {
      viewBounds = m_renderView.frameView().rectForFixedPositionLayout()
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fixedRootBackgroundLayer() -> GraphicsLayer? {
    // Get the fixed root background from the RenderView layer's backing.
    let viewLayer = m_renderView.layer()
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
      let layer = m_renderView.layer()
    {
      layer.setNeedsCompositingGeometryUpdate()
    }
  }

  // Called after the view transparency, or the document or base background color change.
  private func rootBackgroundColorOrTransparencyChanged() {
    if !usesCompositing() {
      return
    }

    var backgroundColor: ColorWrapper? = ColorWrapper()
    let isTransparent = viewHasTransparentBackground(&backgroundColor)

    let extendedBackgroundColor =
      m_renderView.settings().backgroundShouldExtendBeyondPage() ? backgroundColor! : ColorWrapper()

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
    // If the renderer is not attached yet, no need to repaint.
    if CPtrToInt(layer.renderer().p) != CPtrToInt(m_renderView.p)
      && layer.renderer().parent() == nil
    {
      return
    }

    var repaintContainer = layer.renderer().containerForRepaint().renderer
    if repaintContainer == nil {
      repaintContainer = m_renderView
    }

    layer.repaintIncludingNonCompositingDescendants(repaintContainer: repaintContainer)
    if CPtrToInt(repaintContainer?.p) == CPtrToInt(m_renderView.p) {
      // The contents of this layer may be moving between the window
      // and a GraphicsLayer, so we need to make sure the window system
      // synchronizes those changes on the screen.
      m_renderView.frameView().setNeedsOneShotDrawingSynchronization()
    }
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

  func layerGainedCompositedScrollableOverflow(layer: RenderLayerWrapper) {
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

  private func rootRenderLayer() -> RenderLayerWrapper {
    return m_renderView.layer()!
  }

  func rootGraphicsLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerForClipping() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum RootLayerAttachment {
    case RootLayerUnattached
    case RootLayerAttachedViaChromeClient
    case RootLayerAttachedViaEnclosingFrame
  }

  func rootLayerAttachment() -> RootLayerAttachment { return m_rootLayerAttachment }

  func updateRootLayerAttachment() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateRootLayerPosition() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func invalidateEventRegionForAllFrames() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerBecameNonComposited(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isCompositedPlugin(renderer: RenderObjectWrapper) -> Bool {
    if let renderEmbeddedObject = renderer as? RenderEmbeddedObjectWrapper {
      return renderEmbeddedObject.requiresAcceleratedCompositing()
    }

    return false
  }

  func frameContentsCompositor(renderer: RenderWidgetWrapper) -> RenderLayerCompositorWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rootLayerConfigurationChanged() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerTiledBackingUsageChanged(graphicsLayer: GraphicsLayer?, usingTiledBacking: Bool) {
    if usingTiledBacking {
      m_layersWithTiledBackingCount += 1
      graphicsLayer!.tiledBacking()!.setIsInWindow(isInWindow: page().isInWindow())
    } else {
      assert(m_layersWithTiledBackingCount > 0)
      m_layersWithTiledBackingCount -= 1
    }
  }

  func useCoordinatedScrollingForLayer(layer: RenderLayerWrapper) -> Bool {
    if layer.isRenderViewLayer && hasCoordinatedScrolling() {
      return true
    }

    if let scrollingCoordinator = scrollingCoordinator() {
      return scrollingCoordinator.coordinatesScrollingForOverflowLayer(layer: layer)
    }

    return false
  }

  func removeFromScrollCoordinatedLayers(layer: RenderLayerWrapper) {
    detachScrollCoordinatedLayer(layer: layer, roles: allScrollCoordinationRoles)
  }

  func viewHasTransparentBackground() -> Bool {
    var dummy: ColorWrapper? = nil
    return viewHasTransparentBackgroundHelper(&dummy)
  }

  func viewHasTransparentBackground(_ backgroundColor: inout ColorWrapper?) -> Bool {
    return viewHasTransparentBackgroundHelper(&backgroundColor)
  }

  func viewHasTransparentBackgroundHelper(_ backgroundColor: inout ColorWrapper?) -> Bool {
    if m_renderView.frameView().isTransparent() {
      if backgroundColor != nil {
        backgroundColor = ColorWrapper()  // Return an invalid color.
      }
      return true
    }

    var documentBackgroundColor = m_renderView.frameView().documentBackgroundColor()
    if !documentBackgroundColor.isValid() {
      documentBackgroundColor = m_renderView.frameView().baseBackgroundColor()
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

  private class BackingSharingState {
    init(allowOverlappingProviders: Bool) {
      self.allowOverlappingProviders = allowOverlappingProviders
    }

    struct Provider {
      let providerLayer: RenderLayerWrapper? = nil
      let sharingLayers = ListSet<RenderLayerWrapper, ObjectIdentifier>()
      let absoluteBounds = LayoutRectWrapper()
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

        if CPtrToInt(layer.p) == CPtrToInt(providerLayer.p) {
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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isAdditionalProviderCandidate(
      _ candidateLayer: RenderLayerWrapper, _ candidateAbsoluteBounds: LayoutRectWrapper,
      stackingContextAncestor: RenderLayerWrapper?
    ) -> Bool {
      assert(!backingProviderCandidates.isEmpty)
      if stackingContextAncestor == nil
        || CPtrToInt(stackingContextAncestor!.p) != CPtrToInt(backingSharingStackingContext?.p)
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

    func endBackingSharingSequence(_ endLayer: RenderLayerWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func snapshot() -> BackingSharingSnapshot? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    let backingProviderCandidates: [Provider] = []
    let backingSharingStackingContext: RenderLayerWrapper? = nil
    private let allowOverlappingProviders: Bool
  }

  // Copy the accelerated compositing related flags from Settings
  private func cacheAcceleratedCompositingFlags() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cacheAcceleratedCompositingFlagsAfterLayout() {
    cacheAcceleratedCompositingFlags()

    if isRootFrameCompositor() {
      return
    }

    var queryData = RequiresCompositingData()
    let forceCompositingMode =
      m_hasAcceleratedCompositing && m_renderView.settings().forceCompositingMode()
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

  private func updateLayerCompositingState(
    layer: RenderLayerWrapper, compositingAncestor: RenderLayerWrapper?,
    _ queryData: inout RequiresCompositingData, _ backingSharingState: BackingSharingState
  ) -> Bool {
    var layerChanged = updateBacking(
      layer: layer, queryData: &queryData, backingSharingState: backingSharingState)

    // See if we need content or clipping layers. Methods called here should assume
    // that the compositing state of descendant layers has not been updated yet.
    if layer.backing != nil && layer.backing!.updateConfiguration(compositingAncestor!) {
      layerChanged = true
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

  private func computeExtent(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper, _ extent: inout OverlapExtent
  ) {
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
      && CPtrToInt(renderer.container()?.p) == CPtrToInt(m_renderView.p)
    {
      // Because fixed elements get moved around without re-computing overlap, we have to compute an overlap
      // rect that covers all the locations that the fixed element could move to.
      // FIXME: need to handle sticky too.
      extent.bounds = m_renderView.frameView().fixedScrollableAreaBoundsInflatedForScrolling(
        uninflatedBounds: extent.bounds)
    }

    extent.extentComputed = true
  }

  private func computeClippingScopes(_ layer: RenderLayerWrapper, _ extent: inout OverlapExtent) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func addToOverlapMap(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper, _ extent: inout OverlapExtent
  ) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func addDescendantsToOverlapMapRecursive(
    _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper,
    ancestorLayer: RenderLayerWrapper? = nil
  ) {
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
    computeExtent(overlapMap, layer, &extent)
    computeClippingScopes(layer, &extent)

    return overlapMap.overlapsLayers(
      layer, bounds: extent.bounds, enclosingClippingLayers: extent.clippingScopes[...])
  }

  private struct BackingSharingSnapshot {}

  private func updateBackingSharingBeforeDescendantTraversal(
    _ sharingState: BackingSharingState, _ overlapMap: LayerOverlapMap, _ layer: RenderLayerWrapper,
    _ layerExtent: inout OverlapExtent, _ willBeComposited: Bool,
    stackingContextAncestor: RenderLayerWrapper?
  ) -> BackingSharingSnapshot? {
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
    _ layerExtent: OverlapExtent, stackingContextAncestor: RenderLayerWrapper?,
    _ backingSharingSnapshot: BackingSharingSnapshot?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeCompositingRequirements(
    ancestorLayer: RenderLayerWrapper?, layer: RenderLayerWrapper,
    _ overlapMap: LayerOverlapMap,
    _ compositingState: inout CompositingState, _ backingSharingState: BackingSharingState,
    _ descendantHas3DTransform: inout Bool
  ) {
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
      backingSharingState, overlapMap, layer, layerExtent,
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
      backingSharingState, overlapMap, layer, layerExtent,
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
    _ layer: RenderLayerWrapper, _ childLayersOfEnclosingLayer: ArraySlice<GraphicsLayer>,
    _ traversalState: UpdateBackingTraversalState, _ scrollingTreeState: ScrollingTreeState,
    _ updateLevel: UpdateLevel = []
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isRunningTransformAnimation(_ renderer: RenderLayerModelObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func appendDocumentOverlayLayers(_ childList: ArraySlice<GraphicsLayer>) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    let expectedAttachment: RootLayerAttachment =
      isRootFrameCompositor()
      ? .RootLayerAttachedViaChromeClient : .RootLayerAttachedViaEnclosingFrame
    if expectedAttachment == m_rootLayerAttachment {
      return
    }

    if m_rootContentsLayer == nil {
      m_rootContentsLayer = GraphicsLayer.create(factory: graphicsLayerFactory(), client: self)
      let overflowRect = snappedIntRect(rect: m_renderView.layoutOverflowRect())
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
    if m_rootContentsLayer == nil {
      return
    }

    detachRootLayer()

    if m_layerForHorizontalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForHorizontalScrollbar)
      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView.frameView(), orientation: .Horizontal)
      }
      if let horizontalScrollbar = m_renderView.frameView().horizontalScrollbar() {
        m_renderView.frameView().invalidateScrollbar(
          scrollbar: horizontalScrollbar,
          rect: IntRect(
            location: IntPoint(x: 0, y: 0), size: horizontalScrollbar.frameRect().size))
      }
    }

    if m_layerForVerticalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForVerticalScrollbar)
      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView.frameView(), orientation: .Vertical)
      }
      if let verticalScrollbar = m_renderView.frameView().verticalScrollbar() {
        m_renderView.frameView().invalidateScrollbar(
          scrollbar: verticalScrollbar,
          rect: IntRect(
            location: IntPoint(x: 0, y: 0), size: verticalScrollbar.frameRect().size))
      }
    }

    if m_layerForScrollCorner != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForScrollCorner)
      m_renderView.frameView().invalidateScrollCorner(
        rect: m_renderView.frameView().scrollCornerRect())
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
    if m_rootContentsLayer == nil {
      return
    }

    print("RenderLayerCompositor \(self) attachRootLayer \(attachment)")

    switch attachment {
    case .RootLayerUnattached:
      fatalError("Not reached")
    case .RootLayerAttachedViaChromeClient:
      page().chrome().client().attachRootGraphicsLayer(
        frame: m_renderView.frameView().frame(), layer: rootGraphicsLayer())
    case .RootLayerAttachedViaEnclosingFrame:
      // The layer will get hooked up via RenderLayerBacking::updateConfiguration()
      // for the frame's renderer in the parent document.
      if let ownerElement = m_renderView.document().ownerElement() {
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
    if m_rootContentsLayer == nil || m_rootLayerAttachment == .RootLayerUnattached {
      return
    }

    if let scrollingCoordinator = scrollingCoordinator() {
      scrollingCoordinator.frameViewWillBeDetached(frameView: m_renderView.frameView())
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

      if let ownerElement = m_renderView.document().ownerElement() {
        ownerElement.scheduleInvalidateStyleAndLayerComposition()
      }

      let frameRootScrollingNodeID = m_renderView.frameView().scrollingNodeID()
      if frameRootScrollingNodeID.bool() {
        if let scrollingCoordinator = scrollingCoordinator() {
          scrollingCoordinator.frameViewWillBeDetached(frameView: m_renderView.frameView())
          scrollingCoordinator.unparentNode(nodeID: frameRootScrollingNodeID)
        }
      }
    case .RootLayerAttachedViaChromeClient:
      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.frameViewWillBeDetached(frameView: m_renderView.frameView())
      }
      page().chrome().client().attachRootGraphicsLayer(
        frame: m_renderView.frameView().frame(), layer: nil)
    case .RootLayerUnattached:
      break
    }

    m_rootLayerAttachment = .RootLayerUnattached
    rootLayerAttachmentChanged()
  }

  private func rootLayerAttachmentChanged() {
    // The document-relative page overlay layer (which is pinned to the main frame's layer tree)
    // is moved between different RenderLayerCompositors' layer trees, and needs to be
    // reattached whenever we swap in a new RenderLayerCompositor.
    if m_rootLayerAttachment == .RootLayerUnattached {
      return
    }

    // The attachment can affect whether the RenderView layer's paintsIntoWindow() behavior,
    // so call updateDrawsContent() to update that.
    if let backing = m_renderView.layer()?.backing {
      backing.updateDrawsContent()
    }

    if !m_renderView.frameView().frame().isMainFrame() {
      return
    }

    let overlayHost = page().pageOverlayController().layerWithDocumentOverlays()
    m_rootContentsLayer!.addChild(childLayer: overlayHost)
  }

  private func updateOverflowControlsLayers() {
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
            scrollableArea: m_renderView.frameView(), orientation: .Horizontal)
        }
      }
    } else if m_layerForHorizontalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForHorizontalScrollbar)

      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView.frameView(), orientation: .Horizontal)
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
            scrollableArea: m_renderView.frameView(), orientation: .Vertical)
        }
      }
    } else if m_layerForVerticalScrollbar != nil {
      GraphicsLayer.unparentAndClear(layer: m_layerForVerticalScrollbar)

      if let scrollingCoordinator = scrollingCoordinator() {
        scrollingCoordinator.scrollableAreaScrollbarLayerDidChange(
          scrollableArea: m_renderView.frameView(), orientation: .Vertical)
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

    m_renderView.frameView().positionScrollbarLayers()
  }

  private func updateScrollLayerPosition() {
    assert(!hasCoordinatedScrolling())
    assert(m_scrolledContentsLayer != nil)

    let frameView = m_renderView.frameView()
    let scrollPosition = frameView.scrollPosition()

    // We use scroll position here because the root content layer is offset to account for scrollOrigin (see LocalFrameView::positionForRootContentLayer).
    m_scrolledContentsLayer!.setPosition(
      p: FloatPoint(x: Float32(-scrollPosition.x), y: Float32(-scrollPosition.y)))

    if let fixedBackgroundLayer = fixedRootBackgroundLayer() {
      fixedBackgroundLayer.setPosition(p: frameView.scrollPositionForFixedPosition().FloatPoint())
    }
  }

  private func updateScrollLayerClipping() {
    let layerForClipping = layerForClipping()
    if layerForClipping == nil {
      return
    }

    let layerSize = m_renderView.frameView().sizeForVisibleContent()
    layerForClipping!.setSize(size: FloatSize(size: layerSize))
    layerForClipping!.setPosition(p: positionForClipLayer())
  }

  private func positionForClipLayer() -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func notifyIFramesOfCompositingChange() {
    // Compositing affects the answer to RenderIFrame::requiresAcceleratedCompositing(), so
    // we need to schedule a style recalc in our parent document.
    if let ownerElement = m_renderView.document().ownerElement() {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresCompositingForTransform(renderer: RenderLayerModelObjectWrapper) -> Bool {
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
    return renderer.effectiveCapturedInViewTransition() || renderer.isRenderViewTransitionCapture()
  }

  private func requiresCompositingForVideo(renderer: RenderLayerModelObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresCompositingForCanvas(renderer: RenderLayerModelObjectWrapper) -> Bool {
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
    if renderer.hasBackdropFilter() {
      return true
    }

    if !m_compositingTriggers.contains(.FilterTrigger) {
      return false
    }

    return renderer.hasFilter()
  }

  private func requiresCompositingForWillChange(renderer: RenderLayerModelObjectWrapper) -> Bool {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Layout-dependent
  private func requiresCompositingForPlugin(
    renderer: RenderLayerModelObjectWrapper, queryData: inout RequiresCompositingData
  ) -> Bool {
    if !m_compositingTriggers.contains(.PluginTrigger) {
      return false
    }

    if !isCompositedPlugin(renderer: renderer) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresCompositingForOverflowScrolling(
    layer: RenderLayerWrapper, queryData: inout RequiresCompositingData
  ) -> Bool {
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

  private func computeIndirectCompositingReason(
    _ layer: RenderLayerWrapper, hasCompositedDescendants: Bool, has3DTransformedDescendants: Bool,
    paintsIntoProvidedBacking: Bool
  ) -> IndirectCompositingReason {
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
          if CPtrToInt(ancestorLayer.p) == CPtrToInt(compositedAncestor.p) {
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

  private func detachScrollCoordinatedLayer(
    layer: RenderLayerWrapper, roles: ScrollCoordinationRole
  ) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateSynchronousScrollingNodes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func requiresScrollLayer(attachment: RootLayerAttachment) -> Bool {
    let frameView = m_renderView.frameView()

    // This applies when the application UI handles scrolling, in which case RenderLayerCompositor doesn't need to manage it.
    if frameView.delegatedScrollingMode() == .DelegatedToNativeScrollView && isMainFrameCompositor()
    {
      return false
    }

    // We need to handle our own scrolling if we're:
    return m_renderView.frameView().platformWidget() == nil  // viewless (i.e. non-Mac, or Mac in WebKit2)
      || attachment == .RootLayerAttachedViaEnclosingFrame  // a composited frame on Mac
  }

  private func requiresHorizontalScrollbarLayer() -> Bool {
    return shouldCompositeOverflowControls()
      && m_renderView.frameView().horizontalScrollbar() != nil
  }

  private func requiresVerticalScrollbarLayer() -> Bool {
    return shouldCompositeOverflowControls() && m_renderView.frameView().verticalScrollbar() != nil
  }

  private func requiresScrollCornerLayer() -> Bool {
    return shouldCompositeOverflowControls() && m_renderView.frameView().isScrollCornerVisible()
  }

  // True if the FrameView uses a ScrollingCoordinator.
  private func hasCoordinatedScrolling() -> Bool {
    if let scrollingCoordinator = scrollingCoordinator() {
      return scrollingCoordinator.coordinatesScrollingForFrameView(
        frameView: m_renderView.frameView())
    }
    return false
  }

  // FIXME: make the coordinated/async terminology consistent.
  private func isAsyncScrollableStickyLayer(layer: RenderLayerWrapper) -> Bool {
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
    let frameView = m_renderView.frameView()

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
    let layer = m_renderView.layer()
    if layer == nil {
      return false
    }

    if let backing = layer!.backing {
      return backing.isFrameLayerWithTiledBacking
    }

    return false
  }

  private func isRootFrameCompositor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isMainFrameCompositor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_renderView: RenderViewWrapper
  private let m_updateCompositingLayersTimer: Timer

  private let m_compositingTriggers: ChromeClient.CompositingTriggerFlags = .AllTriggers
  private let m_hasAcceleratedCompositing = true

  private let m_compositingPolicy: CompositingPolicy = .Normal

  private let m_showDebugBorders = false
  private let m_showRepaintCounter = false

  private var m_compositing = false
  private var m_shouldFlushOnReattach = false
  private var m_forceCompositingMode = false

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
}
