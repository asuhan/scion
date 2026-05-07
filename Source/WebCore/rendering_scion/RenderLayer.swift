/*
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
 * Copyright (c) 2020 Igalia S.L.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

import wk_interop

private enum BorderRadiusClippingRule {
  case IncludeSelfForBorderRadius
  case DoNotIncludeSelfForBorderRadius
}

enum IncludeSelfOrNot {
  case IncludeSelf
  case ExcludeSelf
}

enum LayoutUpToDate {
  case No
  case Yes
}

enum RepaintStatus {
  case NeedsNormalRepaint
  case NeedsFullRepaint
  case NeedsFullRepaintForPositionedMovementLayout
}

enum ClipRectsType: UInt8 {
  case PaintingClipRects  // Relative to painting ancestor. Used for painting.
  case RootRelativeClipRects  // Relative to the ancestor treated as the root (e.g. transformed layer). Used for hit testing.
  case AbsoluteClipRects  // Relative to the RenderView's layer. Used for compositing overlap testing.
  case NumCachedClipRectsTypes
  case AllClipRectTypes
  case TemporaryClipRects
}

enum ShouldRespectOverflowClip {
  case IgnoreOverflowClip
  case RespectOverflowClip
}

enum ShouldApplyRootOffsetToFragments {
  case ApplyRootOffsetToFragments
  case IgnoreRootOffsetForFragments
}

enum RequestState {
  case Unknown
  case DontCare
  case False
  case True
  case Undetermined
}

enum IndirectCompositingReason {
  case None
  case Clipping
  case Stacking
  case OverflowScrollPositioning
  case Overlap
  case BackgroundLayer
  case GraphicalEffect  // opacity mask filter transform etc.
  case Perspective
  case Preserve3D
}

private func makeMatrixRenderable(matrix: TransformationMatrix, has3DRendering: Bool) {
  if !has3DRendering {
    matrix.makeAffine()
  }
}

private var currentScope: ScrollingScope = 0

private func nextScrollingScope() -> ScrollingScope {
  currentScope += 1
  return currentScope
}

private func canCreateStackingContext(layer: RenderLayerWrapper) -> Bool {
  let renderer = layer.renderer()
  return renderer.hasTransformRelatedProperty()
    || renderer.hasClipPath()
    || renderer.hasFilter()
    || renderer.hasMask()
    || renderer.hasBackdropFilter()
    || renderer.hasBlendMode()
    || renderer.isTransparent()
    || renderer.requiresRenderingConsolidationForViewTransition()
    || renderer.isRenderViewTransitionCapture()
    || renderer.isPositioned()  // Note that this only creates stacking context in conjunction with explicit z-index.
    || renderer.hasReflection()
    || renderer.style().hasIsolation()
    || renderer.shouldApplyPaintContainment()
    || !renderer.style().hasAutoUsedZIndex()
    || (renderer.style().willChange() != nil
      && renderer.style().willChange()!.canCreateStackingContext())
    || layer.establishesTopLayer()
}

func compositedWithOwnBackingStore(layer: RenderLayerWrapper) -> Bool {
  return layer.isComposited() && !layer.backing!.paintsIntoCompositedAncestor()
}

private func performOverlapTests(
  overlapTestRequests: inout OverlapTestRequestMap, rootLayer: RenderLayerWrapper?,
  layer: RenderLayerWrapper
) {
  if overlapTestRequests.isEmpty() {
    return
  }

  var overlappedRequestClients: [OverlapTestRequestClient] = []
  let boundingBox = layer.boundingBox(
    ancestorLayer: rootLayer, offsetFromRoot: layer.offsetFromAncestor(ancestorLayer: rootLayer))
  for (client, clientRect) in overlapTestRequests {
    if !boundingBox.intersects(other: LayoutRectWrapper(rect: clientRect)) {
      continue
    }

    client.setOverlapTestResult(true)
    overlappedRequestClients.append(client)
  }
  for client in overlappedRequestClients {
    overlapTestRequests.remove(client)
  }
}

private func shouldDoSoftwarePaint(layer: RenderLayerWrapper, paintingReflection: Bool) -> Bool {
  return paintingReflection && !layer.has3DTransform()
}

private func shouldSuppressPaintingLayer(layer: RenderLayerWrapper) -> Bool {
  // Avoid painting all layers if the document is in a state where visual updates aren't allowed.
  // A full repaint will occur in Document::setVisualUpdatesAllowed(bool) if painting is suppressed here.
  if !layer.renderer().document().visualUpdatesAllowed() {
    return true
  }
  return false
}

private enum TransparencyClipBoxBehavior {
  case PaintingTransparencyClipBox
  case HitTestingTransparencyClipBox
}

private enum TransparencyClipBoxMode {
  case DescendantsOfTransparencyClipBox
  case RootOfTransparencyClipBox
}

private func hasVisibleBoxDecorationsOrBackground(renderer: RenderElementWrapper) -> Bool {
  return renderer.hasVisibleBoxDecorations() || renderer.style().hasOutline()
}

// Constrain the depth and breadth of the search for performance.
private let maxRendererTraversalCount: UInt32 = 200

private func determineNonLayerDescendantsPaintedContent(
  _ renderer: RenderElementWrapper, _ renderersTraversed: inout UInt32,
  _ request: inout RenderLayerWrapper.PaintedContentRequest
) {
  for child: RenderObjectWrapper in childrenOfType(parent: renderer) {
    renderersTraversed += 1
    if renderersTraversed > maxRendererTraversalCount {
      request.makeStatesUndetermined()
      return
    }

    if let renderText = child as? RenderTextWrapper {
      if !renderText.hasRenderedText() {
        continue
      }

      if renderer.style().usedUserSelect() != .None {
        request.setHasPaintedContent()
      }

      if !renderText.text().containsOnly(isASCIIWhitespace) {
        request.setHasPaintedContent()
      }

      if request.isSatisfied() {
        return
      }
    }

    guard let childElement = child as? RenderElementWrapper else { continue }

    if let modelObject = childElement as? RenderLayerModelObjectWrapper,
      modelObject.hasSelfPaintingLayer()
    {
      continue
    }

    if hasVisibleBoxDecorationsOrBackground(renderer: childElement) {
      request.setHasPaintedContent()
      if request.isSatisfied() {
        return
      }
    }

    if childElement is RenderReplacedWrapper {
      request.setHasPaintedContent()

      if request.isSatisfied() {
        return
      }
    }

    determineNonLayerDescendantsPaintedContent(childElement, &renderersTraversed, &request)
    if request.isSatisfied() {
      return
    }
  }
}

class ClipRects: Equatable {
  static func create() -> ClipRects {
    return ClipRects()
  }

  func reset() {
    overflowClipRect.reset()
    fixedClipRect.reset()
    posClipRect.reset()
    fixed = false
  }

  func setOverflowClipRectAffectedByRadius() { overflowClipRect.affectedByRadius = true }

  static func == (this: ClipRects, other: ClipRects) -> Bool {
    return this.overflowClipRect == other.overflowClipRect
      && this.fixedClipRect == other.fixedClipRect
      && this.posClipRect == other.posClipRect
      && this.fixed == other.fixed
  }

  var fixed = false
  var overflowClipRect = ClipRect()
  var fixedClipRect = ClipRect()
  var posClipRect = ClipRect()
}

class ClipRectsCache {
  func getClipRects(clipRectsType: ClipRectsType, respectOverflowClip: Bool) -> ClipRects? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setClipRects(clipRectsType: ClipRectsType, respectOverflowClip: Bool, clipRects: ClipRects?)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private func flattenedParent(element: ElementWrapper?) -> ElementWrapper? {
  if element == nil {
    return nil
  }
  var parent = element!.parentElementInComposedTree()
  while parent != nil {
    if parent!.computedStyle()!.display() != .Contents {
      break
    }
    parent = parent!.parentElementInComposedTree()
  }
  return parent
}

private func backgroundClipRectForPosition(parentRects: ClipRects, position: PositionType)
  -> ClipRect
{
  if position == .Fixed {
    return parentRects.fixedClipRect
  }

  if position == .Absolute {
    return parentRects.posClipRect
  }

  return parentRects.overflowClipRect
}

typealias ScrollingScope = UInt64

class RenderLayerWrapper {
  init(_ renderer: RenderLayerModelObjectWrapper) {
    if renderer.isNativeImpl() {
      m_renderer = nil
      pInterop = wk_interop.RenderLayer_create((renderer as! RenderViewWrapper).getWk())
      owner = true
      return
    }
    isRenderViewLayer = renderer.isRenderView()
    forcedStackingContext = renderer.isRenderMedia()
    isNormalFlowOnly = false
    m_isCSSStackingContext = false
    canBeBackdropRoot = false
    hasBackdropFilterDescendantsWithoutRoot = false
    isOpportunisticStackingContext = false
    zOrderListsDirty = false
    normalFlowListDirty = true
    hadNegativeZOrderList = false
    m_inResizeMode = false
    hasSelfPaintingLayerDescendant = false
    hasSelfPaintingLayerDescendantDirty = false
    usedTransparency = false
    paintingInsideReflection = false
    visibleContentStatusDirty = true
    hasVisibleContent = false
    visibleDescendantStatusDirty = false
    hasVisibleDescendant = false
    m_isFixedIntersectingViewport = false
    behavesAsFixed = false
    m_3DTransformedDescendantStatusDirty = true
    m_has3DTransformedDescendant = false
    hasCompositingDescendant = false
    hasCompositedNonContainedDescendants = false
    hasCompositedScrollingAncestor = false
    m_hasFixedContainingBlockAncestor = false
    m_hasTransformedAncestor = false
    has3DTransformedAncestor = false
    m_insideSVGForeignObject = false
    indirectCompositingReason = .None
    viewportConstrainedNotCompositedReason = .NoNotCompositedReason
    blendMode = .Normal
    hasNotIsolatedCompositedBlendingDescendants = false
    hasNotIsolatedBlendingDescendants = false
    hasNotIsolatedBlendingDescendantsStatusDirty = false
    repaintRectsValid = false
    m_renderer = renderer
    pInterop = nil
    owner = false

    setIsNormalFlowOnly(isNormalFlowOnly: shouldBeNormalFlowOnly())
    setIsCSSStackingContext(isCSSStackingContext: shouldBeCSSStackingContext())
    setCanBeBackdropRoot(canBeBackdropRoot: computeCanBeBackdropRoot())

    isSelfPaintingLayer = shouldBeSelfPaintingLayer()

    if isRenderViewLayer {
      contentsScrollingScope = nextScrollingScope()
      boxScrollingScope = contentsScrollingScope
    }

    let needsVisibleContentStatusUpdate = { () in
      if renderer.firstChild() != nil {
        return false
      }

      // Leave m_visibleContentStatusDirty = true in any case. The associated renderer needs to be inserted into the
      // render tree, before we can determine the visible content status. The visible content status of a SVG renderer
      // depends on its ancestors (all children of RenderSVGHiddenContainer are recursively invisible, no matter what).
      if renderer.isSVGLayerAwareRenderer()
        && renderer.document().settings().layerBasedSVGEngineEnabled()
      {
        return false
      }

      //  We need the parent to know if we have skipped content or content-visibility root.
      if renderer.style().hasSkippedContent() && renderer.parent() == nil {
        return false
      }
      return true
    }()

    if needsVisibleContentStatusUpdate {
      visibleContentStatusDirty = false
      hasVisibleContent = renderer.style().usedVisibility() == .Visible
    }
  }

  init(p: UnsafeMutableRawPointer, owner: Bool = false) {
    self.pInterop = p
    self.owner = owner
    self.m_renderer = nil
  }

  deinit {
    if self.owner {
      wk_interop.RenderLayer_destroy(pInterop!)
    }
  }

  func scrollableArea() -> RenderLayerScrollableArea? {
    if !isNativeImpl() {
      if let raw = wk_interop.RenderLayer_scrollableArea(pInterop!) {
        return RenderLayerScrollableArea(raw)
      }
      return nil
    }
    return m_scrollableArea
  }

  @discardableResult
  func ensureLayerScrollableArea() -> RenderLayerScrollableArea? {
    assert(isNativeImpl())
    let hadScrollableArea = scrollableArea() != nil

    if m_scrollableArea == nil {
      m_scrollableArea = RenderLayerScrollableArea(layer: self)
    }

    if !hadScrollableArea {
      if renderer().settings().asyncOverflowScrollingEnabled() {
        setNeedsCompositingConfigurationUpdate()
      }

      m_scrollableArea!.restoreScrollPosition()
    }

    return m_scrollableArea
  }

  func name() -> String {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func page() -> PageWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func renderer() -> RenderLayerModelObjectWrapper {
    if !isNativeImpl() {
      return createRenderObjectWrapperOrNative(wk_interop.RenderLayer_renderer(pInterop!))
        as! RenderLayerModelObjectWrapper
    }
    return m_renderer!
  }

  func renderBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    return renderer() as? RenderBoxWrapper
  }

  func parent() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    return m_parent
  }

  func previousSibling() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    return m_previous
  }

  func nextSibling() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    return m_next
  }

  func firstChild() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    return m_first
  }

  func lastChild() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    return m_last
  }

  func isDescendantOf(_ layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    var ancestor: RenderLayerWrapper? = self
    while ancestor != nil {
      if CPtrToInt(layer.layerId()) == CPtrToInt(ancestor!.layerId()) {
        return true
      }
      ancestor = ancestor!.parent()
    }
    return false
  }

  // This does an ancestor tree walk. Avoid it!
  private func root() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    var curr: RenderLayerWrapper? = self
    while curr!.parent() != nil {
      curr = curr!.parent()
    }
    return curr
  }

  private func addChild(_ child: RenderLayerWrapper, beforeChild: RenderLayerWrapper? = nil) {
    assert(isNativeImpl())
    if let prevSibling = beforeChild?.previousSibling() ?? lastChild() {
      child.setPreviousSibling(prev: prevSibling)
      prevSibling.setNextSibling(next: child)
      assert(CPtrToInt(prevSibling.layerId()) != CPtrToInt(child.layerId()))
    } else {
      setFirstChild(child)
    }

    if beforeChild != nil {
      beforeChild!.setPreviousSibling(prev: child)
      child.setNextSibling(next: beforeChild)
      assert(CPtrToInt(beforeChild!.layerId()) != CPtrToInt(child.layerId()))
    } else {
      setLastChild(child)
    }

    child.m_parent = self

    dirtyPaintOrderListsOnChildChange(child: child)

    child.updateAncestorDependentState()
    dirtyAncestorChainVisibleDescendantStatus()
    child.updateDescendantDependentFlags()

    if child.isSelfPaintingLayer || child.hasSelfPaintingLayerDescendant {
      setAncestorChainHasSelfPaintingLayerDescendant()
    }

    if compositor().hasContentCompositingLayers() {
      setDescendantsNeedCompositingRequirementsTraversal()
    }

    if child.hasDescendantNeedingCompositingRequirementsTraversal()
      || child.needsCompositingRequirementsTraversal()
    {
      child.setAncestorsHaveCompositingDirtyFlag(flag: .HasDescendantNeedingRequirementsTraversal)
    }

    if child.hasDescendantNeedingUpdateBackingOrHierarchyTraversal()
      || child.needsUpdateBackingOrHierarchyTraversal()
    {
      child.setAncestorsHaveCompositingDirtyFlag(
        flag: .HasDescendantNeedingBackingOrHierarchyTraversal)
    }

    if child.hasBlendMode()
      || (child.hasNotIsolatedBlendingDescendants && !child.isolatesBlending())
    {
      updateAncestorChainHasBlendingDescendants()  // Why not just dirty?
    }
  }

  func removeChild(oldChild: RenderLayerWrapper) {
    assert(isNativeImpl())
    if !renderer().renderTreeBeingDestroyed() {
      compositor().layerWillBeRemoved(parent: self, child: oldChild)
    }

    // remove the child
    if let prevSibling = oldChild.previousSibling() {
      prevSibling.setNextSibling(next: oldChild.nextSibling())
    }
    if let nextSibling = oldChild.nextSibling() {
      nextSibling.setPreviousSibling(prev: oldChild.previousSibling())
    }

    if CPtrToInt(m_first?.layerId()) == CPtrToInt(oldChild.layerId()) {
      m_first = oldChild.nextSibling()
    }
    if CPtrToInt(m_last?.layerId()) == CPtrToInt(oldChild.layerId()) {
      m_last = oldChild.previousSibling()
    }

    dirtyPaintOrderListsOnChildChange(child: oldChild)

    oldChild.setPreviousSibling(prev: nil)
    oldChild.setNextSibling(next: nil)
    oldChild.m_parent = nil

    oldChild.updateDescendantDependentFlags()
    if oldChild.hasVisibleContent || oldChild.hasVisibleDescendant {
      dirtyAncestorChainVisibleDescendantStatus()
    }

    if oldChild.isSelfPaintingLayer || oldChild.hasSelfPaintingLayerDescendant {
      dirtyAncestorChainHasSelfPaintingLayerDescendantStatus()
    }

    if compositor().hasContentCompositingLayers() {
      setDescendantsNeedCompositingRequirementsTraversal()
    }

    if oldChild.hasBlendMode()
      || (oldChild.hasNotIsolatedBlendingDescendants && !oldChild.isolatesBlending())
    {
      dirtyAncestorChainHasBlendingDescendants()
    }
    if renderer().style().usedVisibility() != .Visible {
      dirtyVisibleContentStatus()
    }
  }

  enum LayerChangeTiming {
    case StyleChange
    case RenderTreeConstruction
  }

  func insertOnlyThisLayer(_ timing: LayerChangeTiming) {
    if !isNativeImpl() {
      wk_interop.RenderLayer_insertOnlyThisLayer(pInterop!, timing == .RenderTreeConstruction)
      return
    }
    assert(isNativeImpl())
    if m_parent == nil && renderer().parent() != nil {
      // We need to connect ourselves when our renderer() has a parent.
      // Find our enclosingLayer and add ourselves.
      guard let parentLayer = renderer().layerParent() else { return }

      let beforeChild =
        CPtrToInt(parentLayer.reflectionLayer()?.layerId()) != CPtrToInt(layerId())
        ? renderer().layerNextSibling(parentLayer) : nil
      parentLayer.addChild(self, beforeChild: beforeChild)
    }

    // Remove all descendant layers from the hierarchy and add them to the new position.
    for child: RenderElementWrapper in childrenOfType(parent: renderer()) {
      child.moveLayers(self)
    }

    if parent() != nil, timing == .StyleChange {
      renderer().view().layerChildrenChangedDuringStyleChange(parent()!)
    }

    // Clear out all the clip rects.
    clearClipRectsIncludingDescendants()
  }

  func removeOnlyThisLayer(timing: LayerChangeTiming) {
    assert(isNativeImpl())
    if m_parent == nil {
      return
    }

    if timing == .StyleChange {
      renderer().view().layerChildrenChangedDuringStyleChange(parent()!)
    }

    compositor().layerWillBeRemoved(parent: m_parent!, child: self)

    // Dirty the clip rects.
    clearClipRectsIncludingDescendants()

    let nextSib = nextSibling()

    // Remove the child reflection layer before moving other child layers.
    // The reflection layer should not be moved to the parent.
    if let reflectionLayer = reflectionLayer() {
      removeChild(oldChild: reflectionLayer)
    }

    // Now walk our kids and reattach them to our parent.
    var current = m_first
    while current != nil {
      let next = current!.nextSibling()
      removeChild(oldChild: current!)
      m_parent!.addChild(current!, beforeChild: nextSib)
      current!.repaintStatus = .NeedsFullRepaint
      current = next
    }

    // Remove us from the parent.
    m_parent!.removeChild(oldChild: self)
    renderer().destroyLayer()
  }

  // isStackingContext is true for layers that we've determined should be stacking contexts for painting.
  // Not all stacking contexts are CSS stacking contexts.
  func isStackingContext() -> Bool {
    assert(isNativeImpl())
    return isCSSStackingContext() || isOpportunisticStackingContext
  }

  // isCSSStackingContext is true for layers that are stacking contexts from a CSS perspective.
  // isCSSStackingContext() => isStackingContext().
  // FIXME: m_forcedStackingContext should affect isStackingContext(), not isCSSStackingContext(), but doing so breaks media control mix-blend-mode.
  func isCSSStackingContext() -> Bool {
    assert(isNativeImpl())
    return self.m_isCSSStackingContext || self.forcedStackingContext
  }

  // Gets the enclosing stacking context for this layer, excluding this layer itself.
  func stackingContext() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    var layer = parent()
    while layer != nil && !layer!.isStackingContext() {
      layer = layer!.parent()
    }

    assert(layer == nil || layer!.isStackingContext())
    if establishesTopLayer() {
      assert(
        layer == nil
          || CPtrToInt(layer!.layerId()) == CPtrToInt(renderer().view().layer()!.layerId()))
    }
    return layer
  }

  func paintOrderParent() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    return isNormalFlowOnly ? m_parent : stackingContext()
  }

  func cachedClippedOverflowRect() -> LayoutRectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dirtyNormalFlowList() {
    assert(isNativeImpl())
    if normalFlowList != nil {
      normalFlowList!.removeAll()
    }
    normalFlowListDirty = true

    if hasCompositingDescendant {
      setNeedsCompositingPaintOrderChildrenUpdate()
    }
  }

  func dirtyZOrderLists() {
    assert(isNativeImpl())
    assert(isStackingContext())

    if posZOrderList != nil {
      posZOrderList!.removeAll()
    }
    if negZOrderList != nil {
      negZOrderList!.removeAll()
    }
    zOrderListsDirty = true

    // FIXME: Ideally, we'd only dirty if the lists changed.
    if hasCompositingDescendant {
      setNeedsCompositingPaintOrderChildrenUpdate()
    }
  }

  func dirtyStackingContextZOrderLists() {
    assert(isNativeImpl())
    let sc = stackingContext()
    sc?.dirtyZOrderLists()
  }

  func dirtyHiddenStackingContextAncestorZOrderLists() {
    assert(isNativeImpl())
    var sc = stackingContext()
    while sc != nil {
      sc!.dirtyZOrderLists()
      if sc!.hasVisibleContent {
        break
      }
      sc = sc!.stackingContext()
    }
  }

  func willCompositeClipPath() -> Bool {
    assert(isNativeImpl())
    if !isComposited() {
      return false
    }

    guard let clipPath = renderer().style().clipPath() else { return false }

    if renderer().hasMask() {
      return false
    }

    return (clipPath.type != .Shape || clipPath.type == .Shape)
      && GraphicsLayer.supportsLayerType(type: .Shape)
  }

  func hasDescendantNeedingCompositingRequirementsTraversal() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.HasDescendantNeedingRequirementsTraversal)
  }

  func hasDescendantNeedingUpdateBackingOrHierarchyTraversal() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.HasDescendantNeedingBackingOrHierarchyTraversal)
  }

  func needsCompositingPaintOrderChildrenUpdate() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.NeedsPaintOrderChildrenUpdate)
  }

  func needsScrollingTreeUpdate() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.NeedsScrollingTreeUpdate)
  }

  func childrenNeedCompositingGeometryUpdate() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.ChildrenNeedGeometryUpdate)
  }

  func descendantsNeedUpdateBackingAndHierarchyTraversal() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.DescendantsNeedBackingAndHierarchyTraversal)
  }

  func setNeedsCompositingConfigurationUpdate() {
    assert(isNativeImpl())
    setBackingAndHierarchyTraversalDirtyBit(v: .NeedsConfigurationUpdate)
  }

  func setNeedsScrollingTreeUpdate() {
    assert(isNativeImpl())
    setBackingAndHierarchyTraversalDirtyBit(v: .NeedsScrollingTreeUpdate)
  }

  func clearCompositingRequirementsTraversalState() {
    assert(isNativeImpl())
    compositingDirtyBits.remove(.HasDescendantNeedingRequirementsTraversal)
    compositingDirtyBits.remove(RenderLayerWrapper.computeCompositingRequirementsFlags)
  }

  func needsAnyCompositingTraversal() -> Bool {
    assert(isNativeImpl())
    return !compositingDirtyBits.isEmpty
  }

  struct LayerList: Sequence, IteratorProtocol {
    func next() -> RenderLayerWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func size() -> UInt64 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private struct Compositing: OptionSet {
    let rawValue: UInt8

    static let HasDescendantNeedingRequirementsTraversal = Compositing(rawValue: 1 << 0)  // Need to do the overlap-testing tree walk because hierarchy or geometry changed.
    static let HasDescendantNeedingBackingOrHierarchyTraversal = Compositing(rawValue: 1 << 1)  // Need to update geometry, configuration and update the GraphicsLayer tree.

    // Things that trigger HasDescendantNeedingRequirementsTraversal
    static let NeedsPaintOrderChildrenUpdate = Compositing(rawValue: 1 << 2)  // The paint order children of this layer changed (gained/lost child, order change).
    static let NeedsPostLayoutUpdate = Compositing(rawValue: 1 << 3)  // Needs compositing to be re-evaluated after layout (it depends on geometry).
    static let DescendantsNeedRequirementsTraversal = Compositing(rawValue: 1 << 4)  // Something changed that forces computeCompositingRequirements to traverse all descendant layers.
    static let SubsequentLayersNeedRequirementsTraversal = Compositing(rawValue: 1 << 5)  // Something changed that forces computeCompositingRequirements to traverse all layers later in paint order.

    // Things that trigger HasDescendantNeedingBackingOrHierarchyTraversal
    static let NeedsGeometryUpdate = Compositing(rawValue: 1 << 6)  // This layer needs a geometry update.
    static let NeedsConfigurationUpdate = Compositing(rawValue: 1 << 7)  // This layer needs a configuration update (updating its internal compositing hierarchy).
    static let NeedsScrollingTreeUpdate = Compositing(rawValue: 1 << 8)  // Something changed that requires this layer's scrolling tree node to be updated.
    static let NeedsLayerConnection = Compositing(rawValue: 1 << 9)  // This layer needs hookup with its parents or children.
    static let ChildrenNeedGeometryUpdate = Compositing(rawValue: 1 << 10)  // This layer's composited children need a geometry update.
    static let DescendantsNeedBackingAndHierarchyTraversal = Compositing(rawValue: 1 << 11)  // Something changed that forces us to traverse all descendant layers in updateBackingAndHierarchy.

    func containsAll(other: Compositing) -> Bool {
      return self.intersection(other) == other
    }

    func containsAny(other: Compositing) -> Bool {
      return !self.intersection(other).isEmpty
    }
  }

  private static let computeCompositingRequirementsFlags: Compositing = [
    .NeedsPaintOrderChildrenUpdate,
    .NeedsPostLayoutUpdate,
    .DescendantsNeedRequirementsTraversal,
    .SubsequentLayersNeedRequirementsTraversal,
  ]

  private static let updateBackingOrHierarchyFlags: Compositing = [
    .NeedsLayerConnection,
    .NeedsGeometryUpdate,
    .NeedsConfigurationUpdate,
    .NeedsScrollingTreeUpdate,
    .ChildrenNeedGeometryUpdate,
    .DescendantsNeedBackingAndHierarchyTraversal,
  ]

  private func setAncestorsHaveCompositingDirtyFlag(flag: Compositing) {
    assert(isNativeImpl())
    var layer = paintOrderParent()
    while layer != nil {
      if layer!.compositingDirtyBits.contains(flag) {
        break
      }
      layer!.compositingDirtyBits.update(with: flag)
      layer = layer!.paintOrderParent()
    }
  }

  func needsPostLayoutCompositingUpdate() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.NeedsPostLayoutUpdate)
  }

  func descendantsNeedCompositingRequirementsTraversal() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.DescendantsNeedRequirementsTraversal)
  }

  func subsequentLayersNeedCompositingRequirementsTraversal() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.SubsequentLayersNeedRequirementsTraversal)
  }

  func needsCompositingLayerConnection() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.NeedsLayerConnection)
  }

  func needsCompositingGeometryUpdate() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.NeedsGeometryUpdate)
  }

  func needsCompositingConfigurationUpdate() -> Bool {
    assert(isNativeImpl())
    return compositingDirtyBits.contains(.NeedsConfigurationUpdate)
  }

  private func setRequirementsTraversalDirtyBit(v: Compositing) {
    compositingDirtyBits.update(with: v)
    setAncestorsHaveCompositingDirtyFlag(flag: .HasDescendantNeedingRequirementsTraversal)
  }

  func setNeedsCompositingPaintOrderChildrenUpdate() {
    assert(isNativeImpl())
    setRequirementsTraversalDirtyBit(v: .NeedsPaintOrderChildrenUpdate)
  }

  func setNeedsPostLayoutCompositingUpdate() {
    assert(isNativeImpl())
    setRequirementsTraversalDirtyBit(v: .NeedsPostLayoutUpdate)
  }

  func setDescendantsNeedCompositingRequirementsTraversal() {
    assert(isNativeImpl())
    setRequirementsTraversalDirtyBit(v: .DescendantsNeedRequirementsTraversal)
  }

  func setSubsequentLayersNeedCompositingRequirementsTraversal() {
    assert(isNativeImpl())
    setRequirementsTraversalDirtyBit(v: .SubsequentLayersNeedRequirementsTraversal)
  }

  func setNeedsPostLayoutCompositingUpdateOnAncestors() {
    assert(isNativeImpl())
    setAncestorsHaveCompositingDirtyFlag(flag: .NeedsPostLayoutUpdate)
  }

  private func setBackingAndHierarchyTraversalDirtyBit(v: Compositing) {
    assert(isNativeImpl())
    compositingDirtyBits.update(with: v)
    setAncestorsHaveCompositingDirtyFlag(flag: .HasDescendantNeedingBackingOrHierarchyTraversal)
  }

  func setNeedsCompositingLayerConnection() {
    assert(isNativeImpl())
    setBackingAndHierarchyTraversalDirtyBit(v: .NeedsLayerConnection)
  }

  func setNeedsCompositingGeometryUpdate() {
    assert(isNativeImpl())
    setBackingAndHierarchyTraversalDirtyBit(v: .NeedsGeometryUpdate)
  }

  func setChildrenNeedCompositingGeometryUpdate() {
    assert(isNativeImpl())
    setBackingAndHierarchyTraversalDirtyBit(v: .ChildrenNeedGeometryUpdate)
  }

  func setDescendantsNeedUpdateBackingAndHierarchyTraversal() {
    assert(isNativeImpl())
    setBackingAndHierarchyTraversalDirtyBit(v: .DescendantsNeedBackingAndHierarchyTraversal)
  }

  func setNeedsCompositingGeometryUpdateOnAncestors() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsCompositingRequirementsTraversal() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsUpdateBackingOrHierarchyTraversal() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearUpdateBackingOrHierarchyTraversalState() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func normalFlowLayers() -> LayerList {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func positiveZOrderLayers() -> LayerList {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasNegativeZOrderLayers() -> Bool {
    assert(isNativeImpl())
    return negZOrderList != nil && !negZOrderList!.isEmpty
  }

  func negativeZOrderLayers() -> LayerList {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Update our normal and z-index lists.
  func updateLayerListsIfNeeded() {
    assert(isNativeImpl())
    updateDescendantDependentFlags()
    updateZOrderLists()
    updateNormalFlowList()

    if let reflectionLayer = self.reflectionLayer() {
      reflectionLayer.updateZOrderLists()
      reflectionLayer.updateNormalFlowList()
    }
  }

  func updateDescendantDependentFlags() {
    assert(isNativeImpl())
    if visibleDescendantStatusDirty || hasSelfPaintingLayerDescendantDirty
      || hasNotIsolatedBlendingDescendantsStatusDirty
      || hasIntrinsicallyCompositedDescendantsStatusDirty
    {
      var hasVisibleDescendant = false
      var hasSelfPaintingLayerDescendant = false
      var hasNotIsolatedBlendingDescendants = false
      var hasIntrinsicallyCompositedDescendants = false

      if hasNotIsolatedBlendingDescendantsStatusDirty {
        hasNotIsolatedBlendingDescendantsStatusDirty = false
        updateSelfPaintingLayer()
      }

      var child = firstChild()
      while child != nil {
        child!.updateDescendantDependentFlags()

        hasVisibleDescendant =
          hasVisibleDescendant || child!.hasVisibleContent || child!.hasVisibleDescendant
        hasSelfPaintingLayerDescendant =
          hasSelfPaintingLayerDescendant || child!.isSelfPaintingLayer
          || child!.hasSelfPaintingLayerDescendant
        hasNotIsolatedBlendingDescendants =
          hasNotIsolatedBlendingDescendants || child!.hasBlendMode()
          || (child!.hasNotIsolatedBlendingDescendants && !child!.isolatesBlending())
        hasIntrinsicallyCompositedDescendants =
          hasIntrinsicallyCompositedDescendants || child!.isIntrinsicallyComposited()
          || child!.hasIntrinsicallyCompositedDescendants
        child = child!.nextSibling()
      }

      self.hasVisibleDescendant = hasVisibleDescendant
      self.visibleDescendantStatusDirty = false
      self.hasSelfPaintingLayerDescendant = hasSelfPaintingLayerDescendant
      self.hasSelfPaintingLayerDescendantDirty = false
      self.hasIntrinsicallyCompositedDescendants = hasIntrinsicallyCompositedDescendants
      self.hasIntrinsicallyCompositedDescendantsStatusDirty = false

      self.hasNotIsolatedBlendingDescendants = hasNotIsolatedBlendingDescendants
    }

    if visibleContentStatusDirty {
      //  We need the parent to know if we have skipped content or content-visibility root.
      if renderer().style().hasSkippedContent() && renderer().parent() == nil {
        return
      }
      let hasVisibleContent = computeHasVisibleContent()
      if hasVisibleContent != self.hasVisibleContent {
        self.hasVisibleContent = hasVisibleContent
        if !isNormalFlowOnly {
          // We don't collect invisible layers in z-order lists if they are not composited.
          // As we change visibility, we need to dirty our stacking containers ancestors to be properly
          // collected.
          dirtyHiddenStackingContextAncestorZOrderLists()
        }
      }
      visibleContentStatusDirty = false
    }

    assert(!descendantDependentFlagsAreDirty())
  }

  func descendantDependentFlagsAreDirty() -> Bool {
    assert(isNativeImpl())
    return visibleDescendantStatusDirty || visibleContentStatusDirty
      || hasSelfPaintingLayerDescendantDirty
      || hasNotIsolatedBlendingDescendantsStatusDirty
      || hasIntrinsicallyCompositedDescendantsStatusDirty
  }

  func repaintIncludingDescendants() {
    assert(isNativeImpl())
    renderer().repaint()
    var current = firstChild()
    while current != nil {
      current!.repaintIncludingDescendants()
      current = current!.nextSibling()
    }
  }

  // Indicate that the layer contents need to be repainted. Only has an effect
  // if layer compositing is being used.
  func setBackingNeedsRepaint(shouldClip: GraphicsLayer.ShouldClipToLayer = .ClipToLayer) {
    if !isNativeImpl() {
      wk_interop.RenderLayer_setBackingNeedsRepaint(layerId(), shouldClip == .ClipToLayer)
      return
    }
    assert(isComposited())
    if backing!.paintsIntoWindow() {
      // If we're trying to repaint the placeholder document layer, propagate the
      // repaint to the native view system.
      renderer().view().repaintViewRectangle(LayoutRectWrapper(rect: absoluteBoundingBox()))
    } else {
      backing!.setContentsNeedDisplay(shouldClip)
    }
  }

  // The rect is in the coordinate space of the layer's render object.
  func setBackingNeedsRepaintInRect(
    r: LayoutRectWrapper, shouldClip: GraphicsLayer.ShouldClipToLayer = .ClipToLayer
  ) {
    assert(isNativeImpl())
    // https://bugs.webkit.org/show_bug.cgi?id=61159 describes an unreproducible crash here,
    // so assert but check that the layer is composited.
    assert(isComposited())
    if !isComposited() || backing!.paintsIntoWindow() {
      // If we're trying to repaint the placeholder document layer, propagate the
      // repaint to the native view system.
      var absRect = r
      absRect.move(size: offsetFromAncestor(ancestorLayer: root()))

      renderer().view().repaintViewRectangle(absRect)
    } else {
      backing!.setContentsNeedDisplayInRect(r, shouldClip)
    }
  }

  // Since we're only painting non-composited layers, we know that they all share the same repaintContainer.
  func repaintIncludingNonCompositingDescendants(repaintContainer: RenderLayerModelObjectWrapper?) {
    assert(isNativeImpl())
    let clippedOverflowRect =
      repaintRectsValid
      ? m_repaintRects.clippedOverflowRect
      : renderer().clippedOverflowRectForRepaint(repaintContainer)
    renderer().repaintUsingContainer(repaintContainer, clippedOverflowRect)

    var curr = firstChild()
    while curr != nil {
      if !curr!.isComposited() {
        curr!.repaintIncludingNonCompositingDescendants(repaintContainer: repaintContainer)
      }
      curr = curr!.nextSibling()
    }
  }

  func styleChanged(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    if !isNativeImpl() {
      wk_interop.RenderLayer_styleChanged(pInterop!, diff.rawValue, oldStyle?.p)
      return
    }
    setIsNormalFlowOnly(isNormalFlowOnly: shouldBeNormalFlowOnly())
    setCanBeBackdropRoot(canBeBackdropRoot: computeCanBeBackdropRoot())

    if setIsCSSStackingContext(isCSSStackingContext: shouldBeCSSStackingContext()) {
      if let parent = parent() {
        if isCSSStackingContext() {
          if !hasNotIsolatedBlendingDescendantsStatusDirty && hasNotIsolatedBlendingDescendants {
            parent.dirtyAncestorChainHasBlendingDescendants()
          }
        } else {
          if hasNotIsolatedBlendingDescendantsStatusDirty {
            parent.dirtyAncestorChainHasBlendingDescendants()
          } else if hasNotIsolatedBlendingDescendants {
            parent.updateAncestorChainHasBlendingDescendants()
          }
        }
      }
    }

    updateLayerScrollableArea()

    // FIXME: RenderLayer already handles visibility changes through our visibility dirty bits. This logic could
    // likely be folded along with the rest.
    if let oldStyle = oldStyle {
      let visibilityChanged = oldStyle.usedVisibility() != renderer().style().usedVisibility()
      if oldStyle.usedZIndex() != renderer().style().usedZIndex()
        || oldStyle.usedContentVisibility() != renderer().style().usedContentVisibility()
        || visibilityChanged
      {
        dirtyStackingContextZOrderLists()
        if isStackingContext() {
          dirtyZOrderLists()
        }
      }

      // Visibility and scrollability are input to canUseCompositedScrolling().
      if let scrollableArea = m_scrollableArea {
        if oldStyle.direction() != renderer().style().direction() {
          scrollableArea.invalidateScrollCornerRect(rect: IntRect())
        }
        if visibilityChanged
          || oldStyle.isOverflowVisible() != renderer().style().isOverflowVisible()
        {
          scrollableArea.computeHasCompositedScrollableOverflow(
            layoutUpToDate: diff.rawValue <= StyleDifference.RepaintLayer.rawValue ? .Yes : .No)
        }
      }
    }

    if let scrollableArea = m_scrollableArea {
      scrollableArea.createOrDestroyMarquee()
      scrollableArea.updateScrollbarsAfterStyleChange(oldStyle: oldStyle)
    }
    // Overlay scrollbars can make this layer self-painting so we need
    // to recompute the bit once scrollbars have been updated.
    updateSelfPaintingLayer()

    if !hasReflection() && reflection != nil {
      removeReflection()
    } else if hasReflection() {
      if let reflection = reflection {
        reflection.setStyle(style: createReflectionStyle())
      } else {
        createReflection()
      }
    }

    // FIXME: Need to detect a swap from custom to native scrollbars (and vice versa).
    if let scrollableArea = m_scrollableArea {
      scrollableArea.updateAllScrollbarRelatedStyle()
    }

    updateDescendantDependentFlags()
    updateTransform()
    updateBlendMode()
    updateFiltersAfterStyleChange(diff: diff, oldStyle: oldStyle)

    compositor().layerStyleChanged(diff: diff, layer: self, oldStyle: oldStyle)

    updateFilterPaintingStrategy()
  }

  func cannotBlitToWindow() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderLayer_cannotBlitToWindow(pInterop!)
    }
    if isTransparent() || hasReflection() || isTransformed() {
      return true
    }
    return parent()?.cannotBlitToWindow() ?? false
  }

  // FIXME: This function is incorrectly named. It's isNotOpaque, sometimes called hasOpacity, not isEntirelyTransparent.
  func isTransparent() -> Bool {
    assert(isNativeImpl())
    return renderer().isTransparent() || renderer().hasMask()
  }

  func hasReflection() -> Bool {
    assert(isNativeImpl())
    return renderer().hasReflection()
  }

  func isReflection() -> Bool {
    assert(isNativeImpl())
    return renderer().isRenderReplica()
  }

  func reflectionLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isReflectionLayer(layer: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    if let reflection = reflection {
      return CPtrToInt(layer.layerId()) == CPtrToInt(reflection.layer()?.layerId())
    }
    return false
  }

  func location() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> IntSize {
    assert(isNativeImpl())
    assert(!renderer().view().frameView().layerAccessPrevented())
    return layerSize
  }

  func scrollWidth() -> Int32 {
    assert(isNativeImpl())
    if let scrollableArea = m_scrollableArea {
      return scrollableArea.scrollWidth()
    }

    let box = renderBox()!
    var overflowRect = box.layoutOverflowRect()
    box.flipForWritingMode(rect: &overflowRect)
    return Int32(roundToInt(value: overflowRect.maxX() - overflowRect.x()))
  }

  func scrollHeight() -> Int32 {
    assert(isNativeImpl())
    if let scrollableArea = m_scrollableArea {
      return scrollableArea.scrollHeight()
    }

    let box = renderBox()!
    var overflowRect = box.layoutOverflowRect()
    box.flipForWritingMode(rect: &overflowRect)
    return Int32(roundToInt(value: overflowRect.maxY() - overflowRect.y()))
  }

  // Returns true when the layer could do touch scrolling, but doesn't look at whether there is actually scrollable overflow.
  func canUseCompositedScrolling() -> Bool {
    assert(isNativeImpl())
    return m_scrollableArea?.canUseCompositedScrolling() ?? false
  }

  // Returns true when there is actually scrollable overflow (requires layout to be up-to-date).
  func hasCompositedScrollableOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeHasCompositedScrollableOverflow(layoutUpToDate: LayoutUpToDate) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOverlayScrollbars() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateScrollInfoAfterLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateScrollbarSteps() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canResize() -> Bool {
    assert(isNativeImpl())
    // We need a special case for <iframe> because they never have
    // hasNonVisibleOverflow(). However, they do "implicitly" clip their contents, so
    // we want to allow resizing them also.
    return (renderer().hasNonVisibleOverflow() || renderer().isRenderIFrame())
      && renderer().style().resize() != .None
  }

  func compositor() -> RenderLayerCompositorWrapper {
    assert(isNativeImpl())
    return renderer().view().compositor()
  }

  // Notification from the renderer that its content changed (e.g. current frame of image changed).
  // Allows updates of layer content without repainting.
  func contentChanged(_ changeType: ContentChangeType) {
    assert(isNativeImpl())
    if changeType == .CanvasChanged || changeType == .VideoChanged
      || changeType == .FullScreenChanged || changeType == .ModelChanged
      || (isComposited() && changeType == .ImageChanged)
    {
      setNeedsPostLayoutCompositingUpdate()
      setNeedsCompositingConfigurationUpdate()
    }

    backing?.contentChanged(changeType)
  }

  func canRender3DTransforms() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: This is terrible. Bring back a cached bit for this someday. This crawl is going to slow down all
  // painting of content inside paginated layers.
  func hasCompositedLayerInEnclosingPaginationChain() -> Bool {
    assert(isNativeImpl())
    // No enclosing layer means no compositing in the chain.
    if m_enclosingPaginationLayer == nil {
      return false
    }

    // If the enclosing layer is composited, we don't have to check anything in between us and that
    // layer.
    if m_enclosingPaginationLayer!.isComposited() {
      return true
    }

    // If we are the enclosing pagination layer, then we can't be composited or we'd have passed the
    // previous check.
    if CPtrToInt(m_enclosingPaginationLayer?.layerId()) == CPtrToInt(layerId()) {
      return false
    }

    // The enclosing paginated layer is our ancestor and is not composited, so we have to check
    // intermediate layers between us and the enclosing pagination layer. Start with our own layer.
    if isComposited() {
      return true
    }

    // For normal flow layers, we can recur up the layer tree.
    if isNormalFlowOnly {
      return parent()!.hasCompositedLayerInEnclosingPaginationChain()
    }

    // Otherwise we have to go up the containing block chain. Find the first enclosing
    // containing block layer ancestor, and check that.
    var containingBlock = renderer().containingBlock()
    while containingBlock != nil && containingBlock is RenderViewWrapper {
      if containingBlock!.hasLayer() {
        return containingBlock!.layer()!.hasCompositedLayerInEnclosingPaginationChain()
      }
      containingBlock = containingBlock!.containingBlock()
    }
    return false
  }

  enum PaginationInclusionMode {
    case ExcludeCompositedPaginatedLayers
    case IncludeCompositedPaginatedLayers
  }

  func enclosingPaginationLayer(mode: PaginationInclusionMode) -> RenderLayerWrapper? {
    assert(isNativeImpl())
    if mode == .ExcludeCompositedPaginatedLayers && hasCompositedLayerInEnclosingPaginationChain() {
      return nil
    }
    return m_enclosingPaginationLayer
  }

  func updateTransform() {
    if !isNativeImpl() {
      wk_interop.RenderLayer_updateTransform(pInterop!)
      return
    }
    let hasTransform = renderer().isTransformed()
    let had3DTransform = has3DTransform()

    let hadTransform = transform != nil
    if hasTransform != hadTransform {
      if hasTransform {
        transform = TransformationMatrix()
      } else {
        transform = nil
      }

      // Layers with transforms act as clip rects roots, so clear the cached clip rects here.
      clearClipRectsIncludingDescendants()
    }

    if hasTransform {
      transform!.makeIdentity()
      updateTransformFromStyle(
        transform: &transform!, style: renderer().style(),
        options: RenderStyleWrapper.allTransformOperations)
    }

    if had3DTransform != has3DTransform() {
      dirty3DTransformedDescendantStatus()
      // Having a 3D transform affects whether enclosing perspective and preserve-3d layers composite, so trigger an update.
      setNeedsPostLayoutCompositingUpdateOnAncestors()
    }
  }

  func updateBlendMode() {
    assert(isNativeImpl())
    let hadBlendMode = blendMode != .Normal
    if let parent = parent(), hadBlendMode != hasBlendMode() {
      if hasBlendMode() {
        parent.updateAncestorChainHasBlendingDescendants()
      } else {
        parent.dirtyAncestorChainHasBlendingDescendants()
      }
    }

    blendMode = renderer().style().blendMode()
  }

  func willRemoveChildWithBlendMode() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetForInFlowPosition() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    return offsetForPosition
  }

  func clearClipRectsIncludingDescendants(typeToClear: ClipRectsType = .AllClipRectTypes) {
    assert(isNativeImpl())
    // FIXME: it's not clear how this layer not having clip rects guarantees that no descendants have any.
    if clipRectsCache == nil {
      return
    }

    clearClipRects(typeToClear: typeToClear)

    var l = firstChild()
    while l != nil {
      l!.clearClipRectsIncludingDescendants(typeToClear: typeToClear)
      l = l!.nextSibling()
    }
  }

  func clearClipRects(typeToClear: ClipRectsType = .AllClipRectTypes) {
    assert(isNativeImpl())
    if typeToClear == .AllClipRectTypes {
      clipRectsCache = nil
    } else {
      assert(typeToClear.rawValue < ClipRectsType.NumCachedClipRectsTypes.rawValue)
      clipRectsCache!.setClipRects(
        clipRectsType: typeToClear, respectOverflowClip: true, clipRects: nil)
      clipRectsCache!.setClipRects(
        clipRectsType: typeToClear, respectOverflowClip: false, clipRects: nil)
    }
  }

  func setHasVisibleContent() {
    assert(isNativeImpl())
    if hasVisibleContent && !visibleContentStatusDirty {
      assert(
        parent() == nil || parent()!.visibleDescendantStatusDirty
          || parent()!.hasVisibleDescendant)
      return
    }

    visibleContentStatusDirty = false
    hasVisibleContent = true
    computeRepaintRects(renderer().containerForRepaint().renderer)
    if !isNormalFlowOnly {
      // We don't collect invisible layers in z-order lists if they are not composited.
      // As we became visible, we need to dirty our stacking containers ancestors to be properly
      // collected.
      dirtyHiddenStackingContextAncestorZOrderLists()
    }

    parent()?.dirtyAncestorChainVisibleDescendantStatus()
  }

  func dirtyVisibleContentStatus() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisibleBoxDecorationsOrBackground() -> Bool {
    assert(isNativeImpl())
    return layout_scion.hasVisibleBoxDecorationsOrBackground(renderer: renderer())
  }

  func hasVisibleBoxDecorations() -> Bool {
    assert(isNativeImpl())
    if !hasVisibleContent {
      return false
    }

    return hasVisibleBoxDecorationsOrBackground()
      || (m_scrollableArea?.hasOverflowControls() ?? false)
  }

  private static func isContainerForPositioned(
    layer: RenderLayerWrapper, position: PositionType, establishesTopLayer: Bool
  ) -> Bool {
    if establishesTopLayer {
      return layer.isRenderViewLayer
    }

    switch position {
    case .Fixed:
      return layer.renderer().canContainFixedPositionObjects()

    case .Absolute:
      return layer.renderer().canContainAbsolutelyPositionedObjects()

    default:
      fatalError("Not reached")
    }
  }

  struct PaintedContentRequest {
    mutating func makeStatesUndetermined() {
      if hasPaintedContent == .Unknown {
        hasPaintedContent = .Undetermined
      }
    }

    mutating func setHasPaintedContent() { hasPaintedContent = .True }

    func probablyHasPaintedContent() -> Bool {
      return hasPaintedContent == .True || hasPaintedContent == .Undetermined
    }

    func isSatisfied() -> Bool { return hasPaintedContent != .Unknown }

    var hasPaintedContent: RequestState = .Unknown
  }

  // Returns true if this layer has visible content (ignoring any child layers).
  func isVisuallyNonEmpty(request: inout PaintedContentRequest?) -> Bool {
    assert(isNativeImpl())
    assert(!visibleDescendantStatusDirty)

    if !hasVisibleContent || renderer().style().opacity() == 0 {
      return false
    }

    if renderer().isRenderReplaced() || (m_scrollableArea?.hasOverflowControls() ?? false) {
      if request == nil {
        return true
      }

      request!.setHasPaintedContent()
      if request!.isSatisfied() {
        return true
      }
    }

    if hasVisibleBoxDecorationsOrBackground() {
      if request == nil {
        return true
      }

      request!.setHasPaintedContent()
      if request!.isSatisfied() {
        return true
      }
    }

    if request != nil {
      return hasNonEmptyChildRenderers(&request!)
    }

    var localRequest = PaintedContentRequest()
    return hasNonEmptyChildRenderers(&localRequest)
  }

  func isVisuallyNonEmpty() -> Bool {
    assert(isNativeImpl())
    var dummy: PaintedContentRequest? = nil
    return isVisuallyNonEmpty(request: &dummy)
  }

  // True if this layer container renderers that paint.
  func hasNonEmptyChildRenderers(_ request: inout PaintedContentRequest) -> Bool {
    assert(isNativeImpl())
    var renderersTraversed: UInt32 = 0
    determineNonLayerDescendantsPaintedContent(renderer(), &renderersTraversed, &request)
    return request.probablyHasPaintedContent()
  }

  func ancestorLayerIsInContainingBlockChain(
    ancestor: RenderLayerWrapper, checkLimit: RenderLayerWrapper? = nil
  ) -> Bool {
    assert(isNativeImpl())
    if CPtrToInt(ancestor.layerId()) == CPtrToInt(layerId()) {
      return true
    }

    var currentBlock = renderer().containingBlock()
    while currentBlock != nil && !(currentBlock! is RenderViewWrapper) {
      let currLayer = currentBlock!.layer()
      if CPtrToInt(currLayer?.layerId()) == CPtrToInt(ancestor.layerId()) {
        return true
      }

      if currLayer != nil && CPtrToInt(currLayer?.layerId()) == CPtrToInt(checkLimit?.layerId()) {
        return false
      }

      currentBlock = currentBlock!.containingBlock()
    }

    return false
  }

  // Gets the nearest enclosing positioned ancestor layer (also includes
  // the <html> layer and the root layer).
  func enclosingAncestorForPosition(position: PositionType) -> RenderLayerWrapper? {
    assert(isNativeImpl())
    var curr = parent()
    while curr != nil
      && !RenderLayerWrapper.isContainerForPositioned(
        layer: curr!, position: position, establishesTopLayer: establishesTopLayer())
    {
      curr = curr!.parent()
    }

    if establishesTopLayer() {
      assert(
        curr == nil || CPtrToInt(curr!.layerId()) == CPtrToInt(renderer().view().layer()!.layerId())
      )
    }
    return curr
  }

  // The layer relative to which clipping rects for this layer are computed.
  func clippingRootForPainting() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    if isComposited() {
      return self
    }

    if paintsIntoProvidedBacking() {
      return backingProviderLayer
    }

    var current: RenderLayerWrapper? = self
    while current != nil {
      if current!.isRenderViewLayer {
        return current
      }

      current = current!.paintOrderParent()
      assert(current != nil)
      if current!.transform != nil || compositedWithOwnBackingStore(layer: current!) {
        return current
      }

      if renderer().settings().css3DTransformBackfaceVisibilityInteroperabilityEnabled()
        && current!.participatesInPreserve3D()
        && current!.renderer().style().backfaceVisibility() == .Hidden
      {
        return current
      }

      if current!.paintsIntoProvidedBacking() {
        return current!.backingProviderLayer
      }
    }

    fatalError("Not reached")
  }

  func enclosingOverflowClipLayer(includeSelf: IncludeSelfOrNot) -> RenderLayerWrapper? {
    assert(isNativeImpl())
    var layer = (includeSelf == .IncludeSelf) ? self : parent()
    while layer != nil {
      if layer!.renderer().hasPotentiallyScrollableOverflow() {
        return layer
      }

      layer = layer!.parent()
    }
    return nil
  }

  // Enclosing compositing layer; if includeSelf is true, may return this.
  func enclosingCompositingLayer(includeSelf: IncludeSelfOrNot = .IncludeSelf)
    -> RenderLayerWrapper?
  {
    assert(isNativeImpl())
    if includeSelf == .IncludeSelf && isComposited() {
      return self
    }

    var curr = paintOrderParent()
    while curr != nil {
      if curr!.isComposited() {
        return curr
      }
      curr = curr!.paintOrderParent()
    }

    return nil
  }

  struct EnclosingCompositingLayerStatus {
    init(fullRepaintAlreadyScheduled: Bool = false, layer: RenderLayerWrapper? = nil) {
      self.fullRepaintAlreadyScheduled = fullRepaintAlreadyScheduled
      self.layer = layer
    }

    let fullRepaintAlreadyScheduled: Bool
    let layer: RenderLayerWrapper?
  }

  func enclosingCompositingLayerForRepaint(includeSelf: IncludeSelfOrNot = .IncludeSelf)
    -> EnclosingCompositingLayerStatus
  {
    if !isNativeImpl() {
      let status = wk_interop.RenderLayer_enclosingCompositingLayerForRepaint(
        layerId(), includeSelf == .ExcludeSelf)
      return EnclosingCompositingLayerStatus(
        fullRepaintAlreadyScheduled: status.fullRepaintAlreadyScheduled,
        layer: status.layer != nil ? RenderLayerWrapper(p: status.layer!) : nil)
    }
    var fullRepaintAlreadyScheduled =
      RenderLayerWrapper.isEligibleForFullRepaintCheck(layer: self) && needsFullRepaint()
    if includeSelf == .IncludeSelf,
      let repaintTarget = RenderLayerWrapper.repaintTargetForLayer(layer: self)
    {
      return EnclosingCompositingLayerStatus(
        fullRepaintAlreadyScheduled: fullRepaintAlreadyScheduled, layer: repaintTarget)
    }

    var curr = paintOrderParent()
    while curr != nil {
      fullRepaintAlreadyScheduled =
        fullRepaintAlreadyScheduled
        || (RenderLayerWrapper.isEligibleForFullRepaintCheck(layer: curr!)
          && curr!.needsFullRepaint())
      if let repaintTarget = RenderLayerWrapper.repaintTargetForLayer(layer: curr!) {
        return EnclosingCompositingLayerStatus(
          fullRepaintAlreadyScheduled: fullRepaintAlreadyScheduled, layer: repaintTarget)
      }
      curr = curr!.paintOrderParent()
    }

    return EnclosingCompositingLayerStatus()
  }

  // Ancestor compositing layer, excluding this.
  func ancestorCompositingLayer() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    return enclosingCompositingLayer(includeSelf: .ExcludeSelf)
  }

  func enclosingFilterLayer(_ includeSelf: IncludeSelfOrNot = .IncludeSelf) -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingFilterRepaintLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: This needs a better name.
  func setFilterBackendNeedsRepaintingInRect(_ rect: LayoutRectWrapper) {
    assert(isNativeImpl())
    assert(requiresFullLayerImageForFilters())
    assert(filters != nil)

    if rect.isEmpty() {
      return
    }

    var rectForRepaint = rect
    rectForRepaint.expand(box: toLayoutBoxExtent(extent: filterOutsets()))

    filters!.expandDirtySourceRect(rectForRepaint)

    var parentLayer = enclosingFilterRepaintLayer()!
    let repaintQuad = FloatQuad(inRect: rectForRepaint.FloatRect())
    var parentLayerRect = LayoutRectWrapper(
      rect: renderer().localToContainerQuad(
        localQuad: repaintQuad, container: parentLayer.renderer()
      ).enclosingBoundingBox())

    if parentLayer.isComposited() {
      if !parentLayer.backing!.paintsIntoWindow() {
        parentLayer.setBackingNeedsRepaintInRect(r: parentLayerRect)
        return
      }
      // If the painting goes to window, redirect the painting to the parent RenderView.
      parentLayer = renderer().view().layer()!
      parentLayerRect = LayoutRectWrapper(
        rect: renderer().localToContainerQuad(
          localQuad: repaintQuad, container: parentLayer.renderer()
        )
        .enclosingBoundingBox())
    }

    if parentLayer.paintsWithFilters() {
      parentLayer.setFilterBackendNeedsRepaintingInRect(parentLayerRect)
      return
    }

    if parentLayer.isRenderViewLayer {
      (parentLayer.renderer() as! RenderViewWrapper).repaintViewRectangle(parentLayerRect)
      return
    }

    fatalError("Not reached")
  }

  private static func repaintTargetForLayer(layer: RenderLayerWrapper) -> RenderLayerWrapper? {
    if compositedWithOwnBackingStore(layer: layer) {
      return layer
    }

    if layer.paintsIntoProvidedBacking() {
      return layer.backingProviderLayer
    }

    return nil
  }

  private static func isEligibleForFullRepaintCheck(layer: RenderLayerWrapper) -> Bool {
    return layer.isSelfPaintingLayer && !layer.renderer().hasPotentiallyScrollableOverflow()
      && !(layer.renderer() is RenderViewWrapper)
  }

  func canUseOffsetFromAncestor() -> Bool {
    assert(isNativeImpl())
    // FIXME: This really needs to know if there are transforms on this layer and any of the layers between it and the ancestor in question.
    return !isTransformed() && !renderer().isRenderOrLegacyRenderSVGRoot()
  }

  func canUseOffsetFromAncestor(ancestor: RenderLayerWrapper) -> Bool {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil && CPtrToInt(layer?.layerId()) != CPtrToInt(ancestor.layerId()) {
      if !layer!.canUseOffsetFromAncestor() {
        return false
      }
      layer = layer!.parent()
    }
    return true
  }

  enum ColumnOffsetAdjustment {
    case DontAdjustForColumns
    case AdjustForColumns
  }

  // Returns the layer reached on the walk up towards the ancestor.
  private static func accumulateOffsetTowardsAncestor(
    layer: RenderLayerWrapper, ancestorLayer: RenderLayerWrapper?,
    location: inout LayoutPointWrapper,
    adjustForColumns: RenderLayerWrapper.ColumnOffsetAdjustment
  ) -> RenderLayerWrapper? {
    assert(CPtrToInt(ancestorLayer?.layerId()) != CPtrToInt(layer.layerId()))

    let renderer = layer.renderer()
    let position = renderer.style().position()

    // FIXME: Positioning of out-of-flow(fixed, absolute) elements collected in a RenderFragmentedFlow
    // may need to be revisited in a future patch.
    // If the fixed renderer is inside a RenderFragmentedFlow, we should not compute location using localToAbsolute,
    // since localToAbsolute maps the coordinates from named flow to regions coordinates and regions can be
    // positioned in a completely different place in the viewport (RenderView).
    if position == .Fixed
      && (ancestorLayer == nil
        || CPtrToInt(ancestorLayer?.layerId()) == CPtrToInt(renderer.view().layer()?.layerId()))
    {
      // If the fixed layer's container is the root, just add in the offset of the view. We can obtain this by calling
      // localToAbsolute() on the RenderView.
      location.moveBy(
        offset: LayoutPointWrapper(
          size: renderer.localToAbsolute(localPoint: FloatPoint(), mode: .IsFixed)))
      return ancestorLayer
    }

    // For the fixed positioned elements inside a render flow thread, we should also skip the code path below
    // Otherwise, for the case of ancestorLayer == rootLayer and fixed positioned element child of a transformed
    // element in render flow thread, we will hit the fixed positioned container before hitting the ancestor layer.
    if position == .Fixed {
      // For a fixed layers, we need to walk up to the root to see if there's a fixed position container
      // (e.g. a transformed layer). It's an error to call offsetFromAncestor() across a layer with a transform,
      // so we should always find the ancestor at or before we find the fixed position container, if
      // the container is transformed.
      var fixedPositionContainerLayer: RenderLayerWrapper? = nil
      var foundAncestor = false
      var currLayer: RenderLayerWrapper? = layer.parent()
      while currLayer != nil {
        if CPtrToInt(currLayer?.layerId()) == CPtrToInt(ancestorLayer?.layerId()) {
          foundAncestor = true
        }

        if RenderLayerWrapper.isContainerForPositioned(
          layer: currLayer!, position: .Fixed, establishesTopLayer: layer.establishesTopLayer())
        {
          fixedPositionContainerLayer = currLayer
          // A layer that has a transform-related property but not a
          // transform still acts as a fixed-position container.
          // Accumulating offsets across such layers is allowed.
          if currLayer!.transform != nil {
            assert(foundAncestor)
          }
          break
        }
        currLayer = currLayer!.parent()
      }

      assert(fixedPositionContainerLayer != nil)  // We should have hit the RenderView's layer at least.

      if CPtrToInt(fixedPositionContainerLayer!.layerId()) != CPtrToInt(ancestorLayer?.layerId()) {
        let fixedContainerCoords = layer.offsetFromAncestor(
          ancestorLayer: fixedPositionContainerLayer)
        let ancestorCoords =
          foundAncestor
          ? ancestorLayer!.offsetFromAncestor(ancestorLayer: fixedPositionContainerLayer)
          : LayoutSizeWrapper()
        location.move(s: fixedContainerCoords - ancestorCoords)
        return foundAncestor ? ancestorLayer : fixedPositionContainerLayer
      }

      assert(ancestorLayer != nil)
      if CPtrToInt(ancestorLayer!.layerId()) == CPtrToInt(renderer.view().layer()?.layerId()) {
        // Add location in flow thread coordinates.
        location.moveBy(offset: layer.location())

        // Add flow thread offset in view coordinates since the view may be scrolled.
        location.moveBy(
          offset: LayoutPointWrapper(
            size: renderer.view().localToAbsolute(localPoint: FloatPoint(), mode: .IsFixed)))
        return ancestorLayer
      }
    }

    var parentLayer: RenderLayerWrapper? = nil
    if position == .Absolute || position == .Fixed {
      // Do what enclosingAncestorForPosition() does, but check for ancestorLayer along the way.
      parentLayer = layer.parent()
      var foundAncestorFirst = false
      while parentLayer != nil {
        // RenderFragmentedFlow is a positioned container, child of RenderView, positioned at (0,0).
        // This implies that, for out-of-flow positioned elements inside a RenderFragmentedFlow,
        // we are bailing out before reaching root layer.
        if RenderLayerWrapper.isContainerForPositioned(
          layer: parentLayer!, position: position, establishesTopLayer: layer.establishesTopLayer())
        {
          break
        }

        if CPtrToInt(parentLayer?.layerId()) == CPtrToInt(ancestorLayer?.layerId()) {
          foundAncestorFirst = true
          break
        }

        parentLayer = parentLayer!.parent()
      }

      // We should not reach RenderView layer past the RenderFragmentedFlow layer for any
      // children of the RenderFragmentedFlow.
      if renderer.enclosingFragmentedFlow() != nil {
        assert(CPtrToInt(parentLayer?.layerId()) != CPtrToInt(renderer.view().layer()?.layerId()))
      }

      if foundAncestorFirst {
        // Found ancestorLayer before the abs. positioned container, so compute offset of both relative
        // to enclosingAncestorForPosition and subtract.
        let positionedAncestor = parentLayer!.enclosingAncestorForPosition(position: position)
        let thisCoords = layer.offsetFromAncestor(ancestorLayer: positionedAncestor)
        let ancestorCoords = ancestorLayer!.offsetFromAncestor(ancestorLayer: positionedAncestor)
        location.move(s: thisCoords - ancestorCoords)
        return ancestorLayer
      }
    } else {
      parentLayer = layer.parent()
    }

    if parentLayer == nil {
      return nil
    }

    location.moveBy(offset: layer.location())

    if adjustForColumns == .AdjustForColumns {
      if let parentLayer = layer.parent(),
        CPtrToInt(parentLayer.layerId()) != CPtrToInt(ancestorLayer?.layerId())
      {
        if let multiColumnFlow = parentLayer.renderer() as? RenderMultiColumnFlowWrapper {
          if let fragment = multiColumnFlow.physicalTranslationFromFlowToFragment(
            physicalPoint: location)
          {
            location.move(
              s: fragment.topLeftLocation() - parentLayer.renderBox()!.topLeftLocation())
          }
        }
      }
    }

    return parentLayer
  }

  func convertToLayerCoords(
    ancestorLayer: RenderLayerWrapper?, location: LayoutPointWrapper,
    adjustForColumns: ColumnOffsetAdjustment = .DontAdjustForColumns
  )
    -> LayoutPointWrapper
  {
    assert(isNativeImpl())
    if CPtrToInt(ancestorLayer?.layerId()) == CPtrToInt(layerId()) {
      return location
    }

    var currLayer: RenderLayerWrapper? = self
    var locationInLayerCoords = location
    while currLayer != nil && CPtrToInt(currLayer?.layerId()) != CPtrToInt(ancestorLayer?.layerId())
    {
      currLayer = RenderLayerWrapper.accumulateOffsetTowardsAncestor(
        layer: currLayer!, ancestorLayer: ancestorLayer, location: &locationInLayerCoords,
        adjustForColumns: adjustForColumns)
    }

    // Pixel snap the whole SVG subtree as one "block" -- not individual layers down the SVG render tree.
    if renderer().isRenderSVGRoot() {
      return LayoutPointWrapper(
        size: roundPointToDevicePixels(
          point: locationInLayerCoords,
          pixelSnappingFactor: renderer().document().deviceScaleFactor()))
    }

    return locationInLayerCoords
  }

  func offsetFromAncestor(
    ancestorLayer: RenderLayerWrapper?,
    adjustForColumns: ColumnOffsetAdjustment = .DontAdjustForColumns
  ) -> LayoutSizeWrapper {
    assert(isNativeImpl())
    return toLayoutSize(
      point: convertToLayerCoords(
        ancestorLayer: ancestorLayer, location: LayoutPointWrapper(),
        adjustForColumns: adjustForColumns))
  }

  func zIndex() -> Int32 {
    assert(isNativeImpl())
    return renderer().style().usedZIndex()
  }

  struct PaintLayerFlag: OptionSet {
    let rawValue: UInt32

    static let HaveTransparency = PaintLayerFlag(rawValue: 1)
    static let AppliedTransform = PaintLayerFlag(rawValue: 2)
    static let TemporaryClipRects = PaintLayerFlag(rawValue: 4)
    static let PaintingReflection = PaintLayerFlag(rawValue: 8)
    static let PaintingOverlayScrollbars = PaintLayerFlag(rawValue: 16)
    static let PaintingCompositingBackgroundPhase = PaintLayerFlag(rawValue: 32)
    static let PaintingCompositingForegroundPhase = PaintLayerFlag(rawValue: 64)
    static let PaintingCompositingMaskPhase = PaintLayerFlag(rawValue: 128)
    static let PaintingCompositingClipPathPhase = PaintLayerFlag(rawValue: 256)
    static let PaintingCompositingScrollingPhase = PaintLayerFlag(rawValue: 512)
    static let PaintingOverflowContents = PaintLayerFlag(rawValue: 1024)
    static let PaintingRootBackgroundOnly = PaintLayerFlag(rawValue: 2048)
    static let PaintingSkipRootBackground = PaintLayerFlag(rawValue: 4096)
    static let PaintingChildClippingMaskPhase = PaintLayerFlag(rawValue: 8192)
    static let PaintingSVGClippingMask = PaintLayerFlag(rawValue: 16384)
    static let CollectingEventRegion = PaintLayerFlag(rawValue: 32768)
    static let PaintingSkipDescendantViewTransition = PaintLayerFlag(rawValue: 65536)
  }

  static let paintLayerPaintingCompositingAllPhasesFlags: PaintLayerFlag = [
    .PaintingCompositingBackgroundPhase, .PaintingCompositingForegroundPhase,
  ]

  enum SecurityOriginPaintPolicy {
    case AnyOrigin
    case AccessibleOriginOnly
  }

  // The two main functions that use the layer system.  The paint method
  // paints the layers that intersect the damage rect from back to
  // front.  The hitTest method looks for mouse events by walking
  // layers that intersect the point from front to back.
  func paint(
    context: GraphicsContextWrapper, damageRect: LayoutRectWrapper,
    subpixelOffset: LayoutSizeWrapper = LayoutSizeWrapper(), paintBehavior: PaintBehavior = .Normal,
    subtreePaintRoot: RenderObjectWrapper? = nil, paintFlags: PaintLayerFlag = [],
    paintPolicy: SecurityOriginPaintPolicy = .AnyOrigin, regionContext: RegionContext? = nil
  ) {
    assert(isNativeImpl())
    let overlapTestRequests = OverlapTestRequestMap()

    var paintingInfo = LayerPaintingInfo(
      inRootLayer: self, inDirtyRect: LayoutRectWrapper(rect: enclosingIntRect(rect: damageRect)),
      inPaintBehavior: paintBehavior, inSubpixelOffset: subpixelOffset,
      inSubtreePaintRoot: subtreePaintRoot,
      inOverlapTestRequests: overlapTestRequests,
      inRequireSecurityOriginAccessForWidgets: paintPolicy == .AccessibleOriginOnly)
    var paintFlags = paintFlags
    if regionContext != nil {
      paintingInfo.regionContext = regionContext
      if regionContext! is EventRegionContext {
        paintFlags.update(with: .CollectingEventRegion)
      }
    }
    paintLayer(context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)

    for widget in overlapTestRequests.keys() {
      widget.setOverlapTestResult(false)
    }
  }

  func hitTest(_ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper) -> Bool {
    assert(isNativeImpl())
    return hitTest(request, result.hitTestLocation, &result)
  }

  private func hitTest(
    _ request: HitTestRequestWrapper, _ hitTestLocation: HitTestLocationWrapper,
    _ result: inout HitTestResultWrapper
  ) -> Bool {
    assert(isNativeImpl())
    assert(isSelfPaintingLayer || hasSelfPaintingLayerDescendant)
    assert(!renderer().view().needsLayout())

    assert(!isRenderFragmentedFlow())
    var hitTestArea = LayoutRectWrapper(rect: renderer().view().documentRect())
    if !request.ignoreClipping() {
      let settings = renderer().settings()
      if settings.visualViewportEnabled() && settings.clientCoordinatesRelativeToLayoutViewport() {
        let frameView = renderer().view().frameView()
        var absoluteLayoutViewportRect = frameView.layoutViewportRect()
        let scaleFactor = frameView.frame().frameScaleFactor()
        if scaleFactor > 1 {
          absoluteLayoutViewportRect.scale(scaleFactor)
        }
        hitTestArea.intersect(other: absoluteLayoutViewportRect)
      } else {
        hitTestArea.intersect(
          other: LayoutRectWrapper(rect: renderer().view().frameView().visibleContentRect()))
      }
    }

    var insideLayer = hitTestLayer(
      rootLayer: self, containerLayer: nil, request, result, hitTestArea, hitTestLocation, false)
    if insideLayer.layer == nil {
      // We didn't hit any layer. If we are the root layer and the mouse is -- or just was -- down,
      // return ourselves. We do this so mouse events continue getting delivered after a drag has
      // exited the WebView, and so hit testing over a scrollbar hits the content document.
      if !request.isChildFrameHitTest() && (request.active() || request.release())
        && isRenderViewLayer
      {
        renderer().updateHitTestResult(
          result: &result,
          point: (renderer() as! RenderViewWrapper).flipForWritingMode(
            position: hitTestLocation.point()))
        insideLayer = HitLayer(layer: self)
      }
    }

    // Now determine if the result is inside an anchor - if the urlElement isn't already set.
    if let node = result.innerNode(), result.URLElement() == nil {
      result.setURLElement(node.enclosingLinkEventParentOrSelf())
    }

    // Now return whether we were inside this layer (this will always be true for the root
    // layer).
    return insideLayer.layer != nil
  }

  struct ClipRectsOption: OptionSet {
    let rawValue: UInt8

    static let RespectOverflowClip = ClipRectsOption(rawValue: 1 << 0)
    static let IncludeOverlayScrollbarSize = ClipRectsOption(rawValue: 1 << 1)
  }

  static let clipRectOptionsForPaintingOverflowControls: ClipRectsOption = []
  static let clipRectDefaultOptions: ClipRectsOption = [.RespectOverflowClip]

  struct ClipRectsContext {
    init(
      inRootLayer: RenderLayerWrapper?, inClipRectsType: ClipRectsType,
      inOptions: ClipRectsOption = RenderLayerWrapper.clipRectDefaultOptions
    ) {
      rootLayer = inRootLayer
      clipRectsType = inClipRectsType
      options = inOptions
    }

    func respectOverflowClip() -> Bool { return options.contains(.RespectOverflowClip) }

    func overlayScrollbarSizeRelevancy() -> OverlayScrollbarSizeRelevancy {
      return options.contains(.IncludeOverlayScrollbarSize)
        ? .IncludeOverlayScrollbarSize : .IgnoreOverlayScrollbarSize
    }

    let rootLayer: RenderLayerWrapper?
    var clipRectsType: ClipRectsType
    let options: ClipRectsOption
  }

  // This method figures out our layerBounds in coordinates relative to
  // |rootLayer|. It also computes our background and foreground clip rects
  // for painting/event handling.
  // Pass offsetFromRoot if known.
  func calculateRects(
    clipRectsContext: ClipRectsContext, paintDirtyRect: LayoutRectWrapper,
    layerBounds: inout LayoutRectWrapper, backgroundRect: inout ClipRect,
    foregroundRect: inout ClipRect,
    offsetFromRoot: LayoutSizeWrapper
  ) {
    assert(isNativeImpl())
    if CPtrToInt(clipRectsContext.rootLayer?.layerId()) != CPtrToInt(layerId()) && parent() != nil {
      backgroundRect = backgroundClipRect(clipRectsContext: clipRectsContext)
      backgroundRect.intersect(other: paintDirtyRect)
    } else {
      backgroundRect = ClipRect(rect: paintDirtyRect)
    }

    let offsetFromRootLocal = offsetFromRoot

    layerBounds = LayoutRectWrapper(
      location: toLayoutPoint(size: offsetFromRootLocal), size: LayoutSizeWrapper(size: size()))

    foregroundRect = backgroundRect

    // Update the clip rects that will be passed to child layers.
    if renderer().hasClipOrNonVisibleOverflow() {
      // This layer establishes a clip of some kind.
      if renderer().hasNonVisibleOverflow() {
        if CPtrToInt(layerId()) != CPtrToInt(clipRectsContext.rootLayer?.layerId())
          || clipRectsContext.respectOverflowClip()
        {
          let overflowClipRect = rendererOverflowClipRect(
            location: toLayoutPoint(size: offsetFromRootLocal), fragment: nil,
            relevancy: clipRectsContext.overlayScrollbarSizeRelevancy())
          foregroundRect.intersect(other: overflowClipRect)
          foregroundRect.affectedByRadius = true
        } else if transform != nil && renderer().style().hasBorderRadius() {
          foregroundRect.affectedByRadius = true
        }
      }

      if renderer().hasClip(), let box = renderer() as? RenderBoxWrapper {
        // Clip applies to *us* as well, so update the damageRect.
        let newPosClip = box.clipRect(
          location: toLayoutPoint(size: offsetFromRootLocal), fragment: nil)
        backgroundRect.intersect(other: newPosClip)
        foregroundRect.intersect(other: newPosClip)
      }

      // If we establish a clip at all, then make sure our background rect is intersected with our layer's bounds including our visual overflow,
      // since any visual overflow like box-shadow or border-outset is not clipped by overflow:auto/hidden.
      if rendererHasVisualOverflow() {
        // FIXME: Does not do the right thing with CSS regions yet, since we don't yet factor in the
        // individual region boxes as overflow.
        var layerBoundsWithVisualOverflow = rendererVisualOverflowRect()
        if renderer().isRenderBox() {
          renderBox()!.flipForWritingMode(rect: &layerBoundsWithVisualOverflow)  // Layers are in physical coordinates, so the overflow has to be flipped.
        }
        layerBoundsWithVisualOverflow.move(size: offsetFromRootLocal)
        if CPtrToInt(layerId()) != CPtrToInt(clipRectsContext.rootLayer?.layerId())
          || clipRectsContext.respectOverflowClip()
        {
          backgroundRect.intersect(other: layerBoundsWithVisualOverflow)
        }
      } else {
        // Shift the bounds to be for our region only.
        var bounds = rendererBorderBoxRectInFragment(fragment: nil)

        bounds.move(size: offsetFromRootLocal)
        if CPtrToInt(layerId()) != CPtrToInt(clipRectsContext.rootLayer?.layerId())
          || clipRectsContext.respectOverflowClip()
        {
          backgroundRect.intersect(other: bounds)
        }
      }
    }
  }

  // Public just for RenderTreeAsText.
  func collectFragments(
    fragments: inout LayerFragments, rootLayer: RenderLayerWrapper?, dirtyRect: LayoutRectWrapper,
    inclusionMode: PaginationInclusionMode, clipRectsType: ClipRectsType,
    clipRectOptions: ClipRectsOption, offsetFromRoot: LayoutSizeWrapper,
    layerBoundingBox: LayoutRectWrapper? = nil,
    applyRootOffsetToFragments: ShouldApplyRootOffsetToFragments = .IgnoreRootOffsetForFragments
  ) {
    assert(isNativeImpl())
    let paginationLayer = enclosingPaginationLayerInSubtree(
      rootLayer: rootLayer, mode: inclusionMode)
    if paginationLayer == nil || isTransformed() {
      // For unpaginated layers, there is only one fragment.
      let fragment = LayerFragment()
      let clipRectsContext = ClipRectsContext(
        inRootLayer: rootLayer, inClipRectsType: clipRectsType, inOptions: clipRectOptions)
      calculateRects(
        clipRectsContext: clipRectsContext, paintDirtyRect: dirtyRect,
        layerBounds: &fragment.layerBounds, backgroundRect: &fragment.backgroundRect,
        foregroundRect: &fragment.foregroundRect, offsetFromRoot: offsetFromRoot)
      fragments.append(fragment)
      return
    }

    // Compute our offset within the enclosing pagination layer.
    let offsetWithinPaginatedLayer = offsetFromAncestor(ancestorLayer: paginationLayer)

    // Calculate clip rects relative to the enclosingPaginationLayer. The purpose of this call is to determine our bounds clipped to intermediate
    // layers between us and the pagination context. It's important to minimize the number of fragments we need to create and this helps with that.
    let paginationClipRectsContext = ClipRectsContext(
      inRootLayer: paginationLayer, inClipRectsType: clipRectsType, inOptions: clipRectOptions)
    var layerBoundsInFragmentedFlow = LayoutRectWrapper()
    var backgroundRectInFragmentedFlow = ClipRect()
    var foregroundRectInFragmentedFlow = ClipRect()
    calculateRects(
      clipRectsContext: paginationClipRectsContext,
      paintDirtyRect: LayoutRectWrapper.infiniteRect(), layerBounds: &layerBoundsInFragmentedFlow,
      backgroundRect: &backgroundRectInFragmentedFlow,
      foregroundRect: &foregroundRectInFragmentedFlow,
      offsetFromRoot: offsetWithinPaginatedLayer)

    // Take our bounding box within the flow thread and clip it.
    var layerBoundingBoxInFragmentedFlow =
      layerBoundingBox != nil
      ? layerBoundingBox!
      : boundingBox(ancestorLayer: paginationLayer, offsetFromRoot: offsetWithinPaginatedLayer)
    layerBoundingBoxInFragmentedFlow.intersect(other: backgroundRectInFragmentedFlow.rect)

    let enclosingFragmentedFlow = paginationLayer!.renderer() as! RenderFragmentedFlowWrapper
    let parentPaginationLayer = paginationLayer!.parent()!.enclosingPaginationLayerInSubtree(
      rootLayer: rootLayer, mode: inclusionMode)
    var ancestorFragments: LayerFragments = []
    if parentPaginationLayer != nil {
      // Compute a bounding box accounting for fragments.
      var layerFragmentBoundingBoxInParentPaginationLayer =
        enclosingFragmentedFlow.fragmentsBoundingBox(
          layerBoundingBox: layerBoundingBoxInFragmentedFlow)

      // Convert to be in the ancestor pagination context's coordinate space.
      let offsetWithinParentPaginatedLayer = paginationLayer!.offsetFromAncestor(
        ancestorLayer: parentPaginationLayer)
      layerFragmentBoundingBoxInParentPaginationLayer.move(size: offsetWithinParentPaginatedLayer)

      // Now collect ancestor fragments.
      parentPaginationLayer!.collectFragments(
        fragments: &ancestorFragments, rootLayer: rootLayer, dirtyRect: dirtyRect,
        inclusionMode: inclusionMode, clipRectsType: clipRectsType,
        clipRectOptions: clipRectOptions,
        offsetFromRoot: offsetFromAncestor(ancestorLayer: rootLayer),
        layerBoundingBox: layerFragmentBoundingBoxInParentPaginationLayer,
        applyRootOffsetToFragments: .ApplyRootOffsetToFragments)

      if ancestorFragments.isEmpty {
        return
      }

      for ancestorFragment in ancestorFragments {
        // Shift the dirty rect into flow thread coordinates.
        var dirtyRectInFragmentedFlow = dirtyRect
        dirtyRectInFragmentedFlow.move(
          size:
            -offsetWithinParentPaginatedLayer - ancestorFragment.paginationOffset)

        let oldSize = fragments.count

        // Tell the flow thread to collect the fragments. We pass enough information to create a minimal number of fragments based off the pages/columns
        // that intersect the actual dirtyRect as well as the pages/columns that intersect our layer's bounding box.
        enclosingFragmentedFlow.collectLayerFragments(
          &fragments, layerBoundingBox: layerBoundingBoxInFragmentedFlow,
          dirtyRect: dirtyRectInFragmentedFlow)

        let newSize = fragments.count

        if oldSize == newSize {
          continue
        }

        for fragment in fragments[oldSize..<newSize] {
          // Set our four rects with all clipping applied that was internal to the flow thread.
          fragment.setRects(
            bounds: layerBoundsInFragmentedFlow, background: backgroundRectInFragmentedFlow,
            foreground: foregroundRectInFragmentedFlow,
            bbox: layerBoundingBoxInFragmentedFlow)

          // Shift to the root-relative physical position used when painting the flow thread in this fragment.
          fragment.moveBy(
            offset:
              toLayoutPoint(
                size: ancestorFragment.paginationOffset + fragment.paginationOffset
                  + offsetWithinParentPaginatedLayer))

          // Intersect the fragment with our ancestor's background clip so that e.g., columns in an overflow:hidden block are
          // properly clipped by the overflow.
          fragment.intersect(rect: ancestorFragment.paginationClip)

          // Now intersect with our pagination clip. This will typically mean we're just intersecting the dirty rect with the column
          // clip, so the column clip ends up being all we apply.
          fragment.intersect(rect: fragment.paginationClip)

          if applyRootOffsetToFragments == .ApplyRootOffsetToFragments {
            fragment.paginationOffset = fragment.paginationOffset + offsetWithinParentPaginatedLayer
          }
        }
      }

      return
    }

    // Shift the dirty rect into flow thread coordinates.
    let offsetOfPaginationLayerFromRoot = enclosingPaginationLayer(mode: inclusionMode)!
      .offsetFromAncestor(ancestorLayer: rootLayer)
    var dirtyRectInFragmentedFlow = dirtyRect
    dirtyRectInFragmentedFlow.move(size: -offsetOfPaginationLayerFromRoot)

    // Tell the flow thread to collect the fragments. We pass enough information to create a minimal number of fragments based off the pages/columns
    // that intersect the actual dirtyRect as well as the pages/columns that intersect our layer's bounding box.
    enclosingFragmentedFlow.collectLayerFragments(
      &fragments, layerBoundingBox: layerBoundingBoxInFragmentedFlow,
      dirtyRect: dirtyRectInFragmentedFlow)

    if fragments.isEmpty {
      return
    }

    // Get the parent clip rects of the pagination layer, since we need to intersect with that when painting column contents.
    var ancestorClipRect = ClipRect(rect: dirtyRect)
    if paginationLayer!.parent() != nil {
      let clipRectsContext = ClipRectsContext(
        inRootLayer: rootLayer, inClipRectsType: clipRectsType, inOptions: clipRectOptions)
      ancestorClipRect = paginationLayer!.backgroundClipRect(clipRectsContext: clipRectsContext)
      ancestorClipRect.intersect(other: dirtyRect)
    }

    for fragment in fragments {
      // Set our four rects with all clipping applied that was internal to the flow thread.
      fragment.setRects(
        bounds: layerBoundsInFragmentedFlow, background: backgroundRectInFragmentedFlow,
        foreground: foregroundRectInFragmentedFlow,
        bbox: layerBoundingBoxInFragmentedFlow)

      // Shift to the root-relative physical position used when painting the flow thread in this fragment.
      fragment.moveBy(
        offset: toLayoutPoint(size: fragment.paginationOffset + offsetOfPaginationLayerFromRoot))

      // Intersect the fragment with our ancestor's background clip so that e.g., columns in an overflow:hidden block are
      // properly clipped by the overflow.
      fragment.intersect(clipRect: ancestorClipRect)

      // Now intersect with our pagination clip. This will typically mean we're just intersecting the dirty rect with the column
      // clip, so the column clip ends up being all we apply.
      fragment.intersect(rect: fragment.paginationClip)

      if applyRootOffsetToFragments == .ApplyRootOffsetToFragments {
        fragment.paginationOffset = fragment.paginationOffset + offsetOfPaginationLayerFromRoot
      }
    }
  }

  enum LocalClipRectMode {
    case IncludeCompositingState
    case ExcludeCompositingState
  }

  func localClipRect(
    clipExceedsBounds: inout Bool, mode: LocalClipRectMode = .IncludeCompositingState
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    clipExceedsBounds = false
    // FIXME: border-radius not accounted for.
    // FIXME: Regions not accounted for.
    let clippingRootLayer = mode == .ExcludeCompositingState ? self : clippingRootForPainting()
    let offsetFromRoot = offsetFromAncestor(ancestorLayer: clippingRootLayer)
    var clipRect = clipRectRelativeToAncestor(
      ancestor: clippingRootLayer, offsetFromAncestor: offsetFromRoot,
      constrainingRect: LayoutRectWrapper.infiniteRect())
    if clipRect.isInfinite() {
      return clipRect
    }

    if renderer().hasClip() {
      if let box = renderer() as? RenderBoxWrapper {
        // CSS clip may be larger than our border box.
        let cssClipRect = box.clipRect(location: LayoutPointWrapper(), fragment: nil)
        clipExceedsBounds =
          !cssClipRect.isEmpty()
          && (clipRect.width() < cssClipRect.width() || clipRect.height() < cssClipRect.height())
      }
    }

    clipRect.move(size: -offsetFromRoot)
    return clipRect
  }

  func clipCrossesPaintingBoundary() -> Bool {
    assert(isNativeImpl())
    return CPtrToInt(
      parent()!.enclosingPaginationLayer(mode: .IncludeCompositedPaginatedLayers)?.layerId())
      != CPtrToInt(enclosingPaginationLayer(mode: .IncludeCompositedPaginatedLayers)?.layerId())
      || CPtrToInt(parent()!.enclosingCompositingLayerForRepaint().layer?.layerId())
        != CPtrToInt(enclosingCompositingLayerForRepaint().layer?.layerId())
  }

  // Pass offsetFromRoot if known.
  func intersectsDamageRect(
    layerBounds: LayoutRectWrapper, damageRect: LayoutRectWrapper, rootLayer: RenderLayerWrapper?,
    offsetFromRoot: LayoutSizeWrapper, cachedBoundingBox: LayoutRectWrapper? = nil
  ) -> Bool {
    assert(isNativeImpl())
    // Always examine the canvas and the root.
    // FIXME: Could eliminate the isDocumentElementRenderer() check if we fix background painting so that the RenderView
    // paints the root's background.
    if isRenderViewLayer || renderer().isDocumentElementRenderer() {
      return true
    }

    if damageRect.isInfinite() {
      return true
    }

    if damageRect.isEmpty() {
      return false
    }

    // If we aren't an inline flow, and our layer bounds do intersect the damage rect, then we can return true.
    if !renderer().isRenderInline() && layerBounds.intersects(other: damageRect) {
      return true
    }

    // Otherwise we need to compute the bounding box of this single layer and see if it intersects
    // the damage rect. It's possible the fragment computed the bounding box already, in which case we
    // can use the cached value.
    if let cachedBoundingBox = cachedBoundingBox {
      return cachedBoundingBox.intersects(other: damageRect)
    }

    return boundingBox(ancestorLayer: rootLayer, offsetFromRoot: offsetFromRoot).intersects(
      other: damageRect)
  }

  struct CalculateLayerBoundsFlag: OptionSet {
    let rawValue: UInt16

    static let IncludeSelfTransform = CalculateLayerBoundsFlag(rawValue: 1)
    static let UseLocalClipRectIfPossible = CalculateLayerBoundsFlag(rawValue: 2)
    static let IncludeFilterOutsets = CalculateLayerBoundsFlag(rawValue: 4)
    static let IncludePaintedFilterOutsets = CalculateLayerBoundsFlag(rawValue: 8)
    static let ExcludeHiddenDescendants = CalculateLayerBoundsFlag(rawValue: 16)
    static let DontConstrainForMask = CalculateLayerBoundsFlag(rawValue: 32)
    static let IncludeCompositedDescendants = CalculateLayerBoundsFlag(rawValue: 64)
    static let UseFragmentBoxesExcludingCompositing = CalculateLayerBoundsFlag(rawValue: 128)
    static let UseFragmentBoxesIncludingCompositing = CalculateLayerBoundsFlag(rawValue: 256)
    static let IncludeRootBackgroundPaintingArea = CalculateLayerBoundsFlag(rawValue: 512)
    static let PreserveAncestorFlags = CalculateLayerBoundsFlag(rawValue: 1024)
    static let UseLocalClipRectExcludingCompositingIfPossible = CalculateLayerBoundsFlag(
      rawValue: 2048)
  }

  static let defaultCalculateLayerBoundsFlags: CalculateLayerBoundsFlag = [
    .IncludeSelfTransform, .UseLocalClipRectIfPossible, .IncludePaintedFilterOutsets,
    .UseFragmentBoxesExcludingCompositing,
  ]

  // Bounding box relative to some ancestor layer. Pass offsetFromRoot if known.
  func boundingBox(
    ancestorLayer: RenderLayerWrapper?, offsetFromRoot: LayoutSizeWrapper = LayoutSizeWrapper(),
    flags: CalculateLayerBoundsFlag = []
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    var result = localBoundingBox(flags: flags)
    if renderer().view().frameView().hasFlippedBlockRenderers() {
      if renderer().isRenderBox() {
        renderBox()!.flipForWritingMode(rect: &result)
      } else {
        renderer().containingBlock()!.flipForWritingMode(rect: &result)
      }
    }

    var inclusionMode: PaginationInclusionMode = .ExcludeCompositedPaginatedLayers
    if flags.contains(.UseFragmentBoxesIncludingCompositing) {
      inclusionMode = .IncludeCompositedPaginatedLayers
    }

    var paginationLayer: RenderLayerWrapper? = nil
    if flags.contains(.UseFragmentBoxesExcludingCompositing)
      || flags.contains(.UseFragmentBoxesIncludingCompositing)
    {
      paginationLayer = enclosingPaginationLayerInSubtree(
        rootLayer: ancestorLayer, mode: inclusionMode)
    }

    var childLayer: RenderLayerWrapper = self
    let isPaginated = paginationLayer != nil
    while paginationLayer != nil {
      // Split our box up into the actual fragment boxes that render in the columns/pages and unite those together to
      // get our true bounding box.
      result.move(size: childLayer.offsetFromAncestor(ancestorLayer: paginationLayer))

      let enclosingFragmentedFlow = paginationLayer!.renderer() as! RenderFragmentedFlowWrapper
      result = enclosingFragmentedFlow.fragmentsBoundingBox(layerBoundingBox: result)

      childLayer = paginationLayer!
      paginationLayer = paginationLayer!.parent()!.enclosingPaginationLayerInSubtree(
        rootLayer: ancestorLayer, mode: inclusionMode)
    }

    if isPaginated {
      result.move(size: childLayer.offsetFromAncestor(ancestorLayer: ancestorLayer))
      return result
    }

    result.move(size: offsetFromRoot)
    return result
  }

  // Bounding box in the coordinates of this layer.
  func localBoundingBox(flags: CalculateLayerBoundsFlag = []) -> LayoutRectWrapper {
    assert(isNativeImpl())
    // There are three special cases we need to consider.
    // (1) Inline Flows.  For inline flows we will create a bounding box that fully encompasses all of the lines occupied by the
    // inline.  In other words, if some <span> wraps to three lines, we'll create a bounding box that fully encloses the
    // line boxes of all three lines (including overflow on those lines).
    // (2) Left/Top Overflow.  The width/height of layers already includes right/bottom overflow.  However, in the case of left/top
    // overflow, we have to create a bounding box that will extend to include this overflow.
    // (3) Floats.  When a layer has overhanging floats that it paints, we need to make sure to include these overhanging floats
    // as part of our bounding box.  We do this because we are the responsible layer for both hit testing and painting those
    // floats.
    var result = LayoutRectWrapper()
    if let renderInline = renderer() as? RenderInlineWrapper, renderer().isInline() {
      result = renderInline.linesVisualOverflowBoundingBox()
    } else if let modelObject = renderer() as? RenderSVGModelObjectWrapper {
      result = modelObject.visualOverflowRectEquivalent()
    } else if let tableRow = renderer() as? RenderTableRowWrapper {
      // Our bounding box is just the union of all of our cells' border/overflow rects.
      var cell = tableRow.firstCell()
      while cell != nil {
        let bbox = cell!.borderBoxRect()
        result.unite(other: bbox)
        let overflowRect = tableRow.visualOverflowRect()
        if bbox != overflowRect {
          result.unite(other: overflowRect)
        }
        cell = cell!.nextCell()
      }
    } else {
      let box = renderBox()!
      if !flags.contains(.DontConstrainForMask) && box.hasMask() {
        result = box.maskClipRect(paintOffset: LayoutPointWrapper())
        box.flipForWritingMode(rect: &result)  // The mask clip rect is in physical coordinates, so we have to flip, since localBoundingBox is not.
      } else {
        result = box.visualOverflowRect()
      }

      if flags.contains(.IncludeRootBackgroundPaintingArea)
        && renderer().isDocumentElementRenderer()
      {
        // If the root layer becomes composited (e.g. because some descendant with negative z-index is composited),
        // then it has to be big enough to cover the viewport in order to display the background. This is akin
        // to the code in RenderBox::paintRootBoxFillLayers().
        let frameView = renderer().view().frameView()
        result.setWidth(width: max(result.width(), frameView.contentsWidth() - result.x()))
        result.setHeight(height: max(result.height(), frameView.contentsHeight() - result.y()))
      }
    }
    return result
  }

  // Deprecated: Pixel snapped bounding box relative to the root.
  private func absoluteBoundingBox() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Device pixel snapped bounding box relative to the root. absoluteBoundingBox() callers will be directed to this.
  func absoluteBoundingBoxForPainting() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the 'reference box' used for clip-path handling (different rules for inlines, wrt. to boxes).
  func referenceBoxRectForClipPath(
    boxType: CSSBoxType, offsetFromRoot: LayoutSizeWrapper, rootRelativeBounds: LayoutRectWrapper
  ) -> FloatRectWrapper {
    assert(isNativeImpl())
    var isReferenceBox = false

    if renderer().document().settings().layerBasedSVGEngineEnabled()
      && renderer().isSVGLayerAwareRenderer()
    {
      isReferenceBox = true
    } else {
      isReferenceBox = renderer().isRenderBox()
    }

    // FIXME: Support different reference boxes for inline content.
    // https://bugs.webkit.org/show_bug.cgi?id=129047
    if !isReferenceBox {
      return rootRelativeBounds.FloatRect()
    }

    var referenceBoxRect = renderer().referenceBoxRect(boxType: boxType)
    referenceBoxRect.move(delta: offsetFromRoot.FloatSize())
    return referenceBoxRect
  }

  // Bounds used for layer overlap testing in RenderLayerCompositor.
  func overlapBounds() -> LayoutRectWrapper {
    assert(isNativeImpl())
    if overlapBoundsIncludeChildren() {
      return calculateLayerBounds(
        ancestorLayer: self, offsetFromRoot: LayoutSizeWrapper(),
        flags: [
          .UseLocalClipRectExcludingCompositingIfPossible, .IncludeFilterOutsets,
          .UseFragmentBoxesExcludingCompositing,
        ])
    }

    return localBoundingBox()
  }

  // Takes transform animations into account, returning true if they could be cheaply computed.
  // Unlike overlapBounds, these bounds include descendant layers.
  func getOverlapBoundsIncludingChildrenAccountingForTransformAnimations(
    _ bounds: inout LayoutRectWrapper, additionalFlags: CalculateLayerBoundsFlag = []
  ) -> Bool {
    assert(isNativeImpl())
    // The animation will override the display transform, so don't include it.
    let boundsFlags = additionalFlags.union(
      RenderLayerWrapper.defaultCalculateLayerBoundsFlags.subtracting([.IncludeSelfTransform]))

    bounds = calculateLayerBounds(
      ancestorLayer: self, offsetFromRoot: LayoutSizeWrapper(), flags: boundsFlags)

    var animatedBounds = bounds
    if let styleable = StyleableWrapper.fromRenderer(renderer()),
      styleable.computeAnimationExtent(&animatedBounds)
    {
      bounds = animatedBounds
      return true
    }

    return false
  }

  // If true, this layer's children are included in its bounds for overlap testing.
  // We can't rely on the children's positions if this layer has a filter that could have moved the children's pixels around.
  private func overlapBoundsIncludeChildren() -> Bool {
    assert(isNativeImpl())
    return hasFilter() && renderer().style().filter().hasFilterThatMovesPixels()
  }

  // Can pass offsetFromRoot if known.
  func calculateLayerBounds(
    ancestorLayer: RenderLayerWrapper?, offsetFromRoot: LayoutSizeWrapper,
    flags: CalculateLayerBoundsFlag = RenderLayerWrapper.defaultCalculateLayerBoundsFlags
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    if !isSelfPaintingLayer {
      return LayoutRectWrapper()
    }

    // FIXME: This could be improved to do a check like hasVisibleNonCompositingDescendantLayers() (bug 92580).
    if flags.contains(.ExcludeHiddenDescendants)
      && CPtrToInt(layerId()) != CPtrToInt(ancestorLayer?.layerId())
      && !hasVisibleContent && !hasVisibleDescendant
    {
      return LayoutRectWrapper()
    }

    if isRenderViewLayer {
      // The root layer is always just the size of the document.
      return LayoutRectWrapper(rect: renderer().view().unscaledDocumentRect())
    }

    var boundingBoxRect = localBoundingBox(flags: flags.union([.IncludeRootBackgroundPaintingArea]))
    if renderer().view().frameView().hasFlippedBlockRenderers() {
      if let box = renderer() as? RenderBoxWrapper {
        box.flipForWritingMode(rect: &boundingBoxRect)
      } else {
        renderer().containingBlock()!.flipForWritingMode(rect: &boundingBoxRect)
      }
    }

    var unionBounds = boundingBoxRect

    if flags.contains(.UseLocalClipRectIfPossible)
      || flags.contains(.UseLocalClipRectExcludingCompositingIfPossible)
    {
      var clipExceedsBounds = false
      var localClipRect = self.localClipRect(
        clipExceedsBounds: &clipExceedsBounds,
        mode: flags.contains(.UseLocalClipRectExcludingCompositingIfPossible)
          ? .ExcludeCompositingState : .IncludeCompositingState)
      if !localClipRect.isInfinite() && !clipExceedsBounds {
        if flags.contains(.IncludeSelfTransform) && paintsWithTransform(paintBehavior: .Normal) {
          localClipRect = transform!.mapRect(localClipRect)
        }

        localClipRect.move(size: offsetFromAncestor(ancestorLayer: ancestorLayer))
        return localClipRect
      }
    }

    // FIXME: should probably just pass 'flags' down to descendants.
    let descendantFlags =
      flags.contains(.PreserveAncestorFlags)
      ? flags
      : RenderLayerWrapper.defaultCalculateLayerBoundsFlags.union(
        flags.intersection([.ExcludeHiddenDescendants, .IncludeCompositedDescendants]))

    updateLayerListsIfNeeded()

    if let reflection = reflectionLayer() {
      if !reflection.isComposited() {
        let childUnionBounds = reflection.calculateLayerBounds(
          ancestorLayer: self, offsetFromRoot: reflection.offsetFromAncestor(ancestorLayer: self),
          flags: descendantFlags)
        unionBounds.unite(other: childUnionBounds)
      }
    }

    assert(isStackingContext() || positiveZOrderLayers().size() == 0)

    for childLayer in negativeZOrderLayers() {
      computeLayersUnion(
        childLayer: childLayer, unionBounds: &unionBounds, flags: flags,
        descendantFlags: descendantFlags)
    }

    for childLayer in positiveZOrderLayers() {
      computeLayersUnion(
        childLayer: childLayer, unionBounds: &unionBounds, flags: flags,
        descendantFlags: descendantFlags)
    }

    for childLayer in normalFlowLayers() {
      computeLayersUnion(
        childLayer: childLayer, unionBounds: &unionBounds, flags: flags,
        descendantFlags: descendantFlags)
    }

    if flags.contains(.IncludeFilterOutsets)
      || (flags.contains(.IncludePaintedFilterOutsets) && paintsWithFilters())
    {
      unionBounds.expand(box: toLayoutBoxExtent(extent: filterOutsets()))
    }

    if flags.contains(.IncludeSelfTransform) && paintsWithTransform(paintBehavior: .Normal) {
      boundingBoxRect = transform!.mapRect(boundingBoxRect)
      unionBounds = transform!.mapRect(unionBounds)
    }
    unionBounds.move(size: offsetFromRoot)
    return unionBounds
  }

  private func computeLayersUnion(
    childLayer: RenderLayerWrapper, unionBounds: inout LayoutRectWrapper,
    flags: CalculateLayerBoundsFlag, descendantFlags: CalculateLayerBoundsFlag
  ) {
    assert(isNativeImpl())
    if !flags.contains(.IncludeCompositedDescendants)
      && (childLayer.isComposited() || childLayer.paintsIntoProvidedBacking())
    {
      return
    }
    let childBounds = childLayer.calculateLayerBounds(
      ancestorLayer: self, offsetFromRoot: childLayer.offsetFromAncestor(ancestorLayer: self),
      flags: descendantFlags)
    // Ignore child layer (and behave as if we had overflow: hidden) when it is positioned off the parent layer so much
    // that we hit the max LayoutUnit value.
    unionBounds.checkedUnite(other: childBounds)
  }

  func needsFullRepaint() -> Bool {
    assert(isNativeImpl())
    return repaintStatus == .NeedsFullRepaint
      || repaintStatus == .NeedsFullRepaintForPositionedMovementLayout
  }

  func setIsSimplifiedLayoutRoot() {
    assert(isNativeImpl())
    isSimplifiedLayoutRoot = true
  }

  func staticInlinePosition() -> LayoutUnit {
    assert(!isNativeImpl())
    return LayoutUnit.fromRawValue(value: wk_interop.RenderLayer_staticInlinePosition(layerId()))
  }

  func staticBlockPosition() -> LayoutUnit {
    assert(!isNativeImpl())
    return LayoutUnit.fromRawValue(value: wk_interop.RenderLayer_staticBlockPosition(layerId()))
  }

  func setStaticInlinePosition(position: LayoutUnit) {
    assert(!isNativeImpl())
    wk_interop.RenderLayer_setStaticInlinePosition(layerId(), position.rawValue())
  }

  func setStaticBlockPosition(position: LayoutUnit) {
    assert(!isNativeImpl())
    wk_interop.RenderLayer_setStaticBlockPosition(layerId(), position.rawValue())
  }

  func isTransformed() -> Bool {
    assert(isNativeImpl())
    return renderer().isTransformed()
  }

  // updateTransformFromStyle computes a transform according to the passed options (e.g. transform-origin baked in or excluded) and the given style.
  func updateTransformFromStyle(
    transform: inout TransformationMatrix, style: RenderStyleWrapper,
    options: RenderStyleWrapper.TransformOperationOption
  ) {
    assert(isNativeImpl())
    let referenceBoxRect = snapRectToDevicePixelsIfNeeded(
      rect: renderer().transformReferenceBoxRect(style: style), renderer: renderer())
    renderer().applyTransform(
      transform: &transform, style: style, boundingBox: referenceBoxRect, options: options)
    makeMatrixRenderable(matrix: transform, has3DRendering: canRender3DTransforms())
  }

  // currentTransform computes a transform which takes accelerated animations into account. The
  // resulting transform has transform-origin baked in, unless non-default options are given. If
  // the layer does not have a transform, the identity matrix is returned.
  func currentTransform(_ options: RenderStyleWrapper.TransformOperationOption)
    -> TransformationMatrix
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentTransform() -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func renderableTransform(paintBehavior: PaintBehavior) -> TransformationMatrix {
    assert(isNativeImpl())
    if let matrix = transform {
      if paintBehavior.contains(.FlattenCompositingLayers) {
        makeMatrixRenderable(matrix: matrix, has3DRendering: false)
        return matrix
      }

      return matrix
    }

    return TransformationMatrix()
  }

  // Get the children transform (to apply a perspective on children), which is applied to transformed sublayers, but not this layer.
  // Returns true if the layer has a perspective.
  // Note that this transform has the perspective-origin baked in.
  func perspectiveTransform() -> TransformationMatrix {
    assert(isNativeImpl())
    if !renderer().hasTransformRelatedProperty() {
      return TransformationMatrix()
    }

    let style = renderer().style()
    if !style.hasPerspective() {
      return TransformationMatrix()
    }

    let transformReferenceBoxRect = snapRectToDevicePixelsIfNeeded(
      rect: renderer().transformReferenceBoxRect(style: style), renderer: renderer())
    let perspectiveOrigin = style.computePerspectiveOrigin(boundingBox: transformReferenceBoxRect)

    // In the regular case of a non-clipped, non-scrolled GraphicsLayer, all transformations
    // (via CSS 'transform' / 'perspective') are applied with respect to a predefined anchor point,
    // which depends on the chosen CSS 'transform-box' / 'transform-origin' properties.
    //
    // A transformation given by the CSS 'transform' property is applied, by translating
    // to the 'transform origin', applying the transformation, and translating back.
    // When an element specifies a CSS 'perspective' property, the perspective transformation matrix
    // that's computed here is propagated to the GraphicsLayer by calling setChildrenTransform().
    //
    // However the GraphicsLayer platform implementations (e.g. CA on macOS) apply the children transform,
    // defined on the parent, with respect to the anchor point of the parent, when rendering child elements.
    // This is wrong, as the perspective transformation (applied to a child of the element defining the
    // 3d effect), must be independant of the chosen transform-origin (the parents transform origin
    // must not affect its children).
    //
    // To circumvent this, explicitely remove the transform-origin dependency in the perspective matrix.
    let transformOrigin = transformOriginPixelSnappedIfNeeded()

    let transform = TransformationMatrix()
    style.unapplyTransformOrigin(transform, transformOrigin)
    style.applyPerspective(transform, FloatPoint3D(perspectiveOrigin))
    style.applyTransformOrigin(transform, transformOrigin)
    return transform
  }

  func perspectiveOrigin() -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformOriginPixelSnappedIfNeeded() -> FloatPoint3D {
    assert(isNativeImpl())
    if !renderer().hasTransformRelatedProperty() {
      return FloatPoint3D()
    }

    let style = renderer().style()
    let referenceBoxRect = renderer().transformReferenceBoxRect(style: style)

    var origin = style.computeTransformOrigin(referenceBoxRect)
    if rendererNeedsPixelSnapping(renderer: renderer()) {
      origin.setXY(
        roundPointToDevicePixels(
          point: LayoutPointWrapper(size: origin.xy()),
          pixelSnappingFactor: renderer().document().deviceScaleFactor()))
    }
    return origin
  }

  func preserves3D() -> Bool {
    assert(isNativeImpl())
    return renderer().style().preserves3D()
  }

  func hasPerspective() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func has3DTransform() -> Bool {
    assert(isNativeImpl())
    if let transform = transform {
      return !transform.isAffine()
    }
    return false
  }

  func hasTransformedAncestor() -> Bool {
    assert(isNativeImpl())
    return m_hasTransformedAncestor
  }

  func participatesInPreserve3D() -> Bool {
    assert(isNativeImpl())
    return ancestorLayerIsDOMParent(ancestor: parent()) && parent()!.preserves3D()
      && (transform != nil || renderer().style().backfaceVisibility() == .Hidden || preserves3D())
  }

  func hasFilter() -> Bool {
    assert(isNativeImpl())
    return renderer().hasFilter()
  }

  func filterOutsets() -> IntOutsets {
    assert(isNativeImpl())
    if filters != nil {
      return RenderLayerFilters.calculateOutsets(
        renderer: renderer(), targetBoundingBox: localBoundingBox().FloatRect())
    }
    return renderer().style().filterOutsets()
  }

  func hasBackdropFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBackdropRoot() -> Bool {
    assert(!isNativeImpl())
    return wk_interop.RenderLayer_isBackdropRoot(layerId())
  }

  func hasBlendMode() -> Bool {
    assert(isNativeImpl())
    return renderer().hasBlendMode()  // FIXME: Why ask the renderer this given we have blendMode?
  }

  func isolatesCompositedBlending() -> Bool {
    assert(isNativeImpl())
    return hasNotIsolatedCompositedBlendingDescendants && isCSSStackingContext()
  }

  func isolatesBlending() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderLayer_isolatesBlending(layerId())
    }
    return hasNotIsolatedBlendingDescendants && isCSSStackingContext()
  }

  func isComposited() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderLayer_isComposited(layerId())
    }
    return backing != nil
  }

  func hasCompositedMask() -> Bool {
    assert(isNativeImpl())
    if let backing = backing {
      return backing.hasMaskLayer()
    }
    return false
  }

  func setBackingProviderLayer(backingProvider: RenderLayerWrapper?) {
    assert(isNativeImpl())
    if optEq(backingProvider, backingProviderLayer) {
      return
    }

    if !renderer().renderTreeBeingDestroyed() {
      clearClipRectsIncludingDescendants()
    }

    backingProviderLayer = backingProvider
  }

  func disconnectFromBackingProviderLayer() {
    assert(isNativeImpl())
    if backingProviderLayer == nil {
      return
    }

    assert(backingProviderLayer!.isComposited())
    if backingProviderLayer!.isComposited() {
      backingProviderLayer!.backing!.removeBackingSharingLayer(layer: self)
    }
  }

  func paintsIntoProvidedBacking() -> Bool {
    assert(isNativeImpl())
    return backingProviderLayer != nil
  }

  @discardableResult
  func ensureBacking() -> RenderLayerBacking? {
    assert(isNativeImpl())
    if backing == nil {
      backing = RenderLayerBacking(layer: self)
      compositor().layerBecameComposited(self)

      updateFilterPaintingStrategy()
    }
    return backing
  }

  func clearBacking(layerBeingDestroyed: Bool = false) {
    assert(isNativeImpl())
    if backing == nil {
      return
    }

    if !renderer().renderTreeBeingDestroyed() {
      compositor().layerBecameNonComposited(layer: self)
    }

    backing!.willBeDestroyed()
    backing = nil

    if !layerBeingDestroyed {
      updateFilterPaintingStrategy()
    }
  }

  func usesCompositedScrolling() -> Bool {
    assert(isNativeImpl())
    return m_scrollableArea?.usesCompositedScrolling() ?? false
  }

  func paintsWithTransparency(paintBehavior: PaintBehavior) -> Bool {
    assert(isNativeImpl())
    if !renderer().isTransparent() && !hasNonOpacityTransparency() {
      return false
    }
    return paintBehavior.contains(.FlattenCompositingLayers) || !isComposited()
  }

  // If we will only draw a single item, then we can just apply
  // opacity to the drawing context rather than pushing a transparency
  // layer. This currently only detects a single bitmap image, but could
  // be extended to handle other cases.
  func canPaintTransparencyWithSetOpacity() -> Bool {
    assert(isNativeImpl())
    return isBitmapOnly() && !hasNonOpacityTransparency()
  }

  func paintsWithTransform(paintBehavior: PaintBehavior) -> Bool {
    assert(isNativeImpl())
    let paintsToWindow = !isComposited() || backing!.paintsIntoWindow()
    return transform != nil
      && (paintBehavior.contains(.FlattenCompositingLayers) || paintsToWindow)
  }

  func shouldPaintMask(paintBehavior: PaintBehavior, paintFlags: PaintLayerFlag) -> Bool {
    assert(isNativeImpl())
    if !renderer().hasMask() {
      return false
    }

    let paintsToWindow = !isComposited() || backing!.paintsIntoWindow()
    if paintsToWindow || paintBehavior.contains(.FlattenCompositingLayers) {
      return true
    }

    return paintFlags.contains(.PaintingCompositingMaskPhase)
  }

  func shouldApplyClipPath(paintBehavior: PaintBehavior, paintFlags: PaintLayerFlag) -> Bool {
    assert(isNativeImpl())
    if !renderer().hasClipPath() {
      return false
    }

    let paintsToWindow = !isComposited() || backing!.paintsIntoWindow()
    if paintsToWindow || paintBehavior.contains(.FlattenCompositingLayers) {
      return true
    }

    return paintFlags.contains(.PaintingCompositingClipPathPhase)
      || paintFlags.contains(.CollectingEventRegion)
  }

  // Returns true if background phase is painted opaque in the given rect.
  // The query rect is given in local coordinates.
  func backgroundIsKnownToBeOpaqueInRect(_ localRect: LayoutRectWrapper) -> Bool {
    assert(isNativeImpl())
    if !isSelfPaintingLayer && !hasSelfPaintingLayerDescendant {
      return false
    }

    if paintsWithTransparency(paintBehavior: .Normal) {
      return false
    }

    if renderer().isDocumentElementRenderer() {
      // Normally the document element doens't have a layer.  If it does have a layer, its background propagates to the RenderView
      // so this layer doesn't draw it.
      return false
    }

    // We can't use hasVisibleContent(), because that will be true if our renderer is hidden, but some child
    // is visible and that child doesn't cover the entire rect.
    if renderer().style().usedVisibility() != .Visible {
      return false
    }

    if paintsWithFilters() && renderer().style().filter().hasFilterThatAffectsOpacity() {
      return false
    }

    // FIXME: Handle simple transforms.
    if paintsWithTransform(paintBehavior: .Normal) {
      return false
    }

    // FIXME: Remove this check.
    // This function should not be called when layer-lists are dirty.
    // It is somehow getting triggered during style update.
    if zOrderListsDirty || normalFlowListDirty {
      return false
    }

    // Table painting is special; a table paints its sections.
    if renderer().isTablePart() {
      return false
    }

    // A fieldset with a legend will have an irregular shape, so can't be treated as opaque.
    if renderer().isFieldset() {
      return false
    }

    // FIXME: We currently only check the immediate renderer,
    // which will miss many cases.
    if renderer().backgroundIsKnownToBeOpaqueInRect(localRect) {
      return true
    }

    // We can't consult child layers if we clip, since they might cover
    // parts of the rect that are clipped out.
    if renderer().hasNonVisibleOverflow() {
      return false
    }

    return listBackgroundIsKnownToBeOpaqueInRect(positiveZOrderLayers(), localRect)
      || listBackgroundIsKnownToBeOpaqueInRect(negativeZOrderLayers(), localRect)
      || listBackgroundIsKnownToBeOpaqueInRect(normalFlowLayers(), localRect)
  }

  func paintsWithFilters() -> Bool {
    assert(isNativeImpl())
    let filter = renderer().style().filter()
    if filter.isEmpty() {
      return false
    }

    if renderer().isRenderOrLegacyRenderSVGRoot() && filter.isReferenceFilter() {
      return false
    }

    if RenderLayerFilters.isIdentity(renderer: renderer()) {
      return false
    }

    if !isComposited() {
      return true
    }

    return !backing!.canCompositeFilters()
  }

  func requiresFullLayerImageForFilters() -> Bool {
    assert(isNativeImpl())
    if !paintsWithFilters() {
      return false
    }

    return filters?.hasFilterThatMovesPixels() ?? false
  }

  static func topLayerRenderLayers(renderView: RenderViewWrapper) -> [RenderLayerWrapper] {
    var layers: [RenderLayerWrapper] = []
    for element in renderView.document().topLayerElements() {
      let renderer = (*element).containerRenderer()
      if renderer == nil {
        continue
      }

      if let backdropRenderer = renderer!.backdropRenderer(),
        backdropRenderer.hasLayer() && backdropRenderer.layer()!.parent() != nil
      {
        layers.append(backdropRenderer.layer()!)
      }

      if renderer!.hasLayer() {
        let modelObject = renderer! as! RenderLayerModelObjectWrapper
        if modelObject.layer()!.parent() != nil {
          layers.append(modelObject.layer()!)
        }
      }
    }
    return layers
  }

  func establishesTopLayer() -> Bool {
    assert(isNativeImpl())
    return isInTopLayerOrBackdrop(style: renderer().style(), element: renderer().element())
  }

  func isBitmapOnly() -> Bool {
    assert(isNativeImpl())
    if hasVisibleBoxDecorationsOrBackground() {
      return false
    }

    if renderer() is RenderHTMLCanvasWrapper {
      return true
    }

    if let imageRenderer = renderer() as? RenderImageWrapper {
      if let cachedImage = imageRenderer.cachedImage() {
        if !cachedImage.hasImage() {
          return false
        }
        return cachedImage.imageForRenderer(renderer: imageRenderer) is BitmapImageWrapper
      }
      return false
    }

    return false
  }

  enum ViewportConstrainedNotCompositedReason {
    case NoNotCompositedReason
    case NotCompositedForBoundsOutOfView
    case NotCompositedForNonViewContainer
    case NotCompositedForNoVisibleContent
  }

  func setViewportConstrainedNotCompositedReason(reason: ViewportConstrainedNotCompositedReason) {
    assert(isNativeImpl())
    viewportConstrainedNotCompositedReason = reason
  }

  func isRenderFragmentedFlow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInsideFragmentedFlow() -> Bool {
    assert(isNativeImpl())
    return renderer().fragmentedFlowState() != .NotInsideFlow
  }

  enum EventRegionInvalidationReason {
    case Paint
    case SettingDidChange
    case Style
    case NonCompositedFrame
  }

  @discardableResult
  func invalidateEventRegion(reason: EventRegionInvalidationReason) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsHiddenByOverflowTruncation(isHidden: Bool) {
    assert(!isNativeImpl())
    wk_interop.RenderLayer_setIsHiddenByOverflowTruncation(layerId(), isHidden)
  }

  func paintSVGResourceLayer(
    _ context: GraphicsContextWrapper, _ layerContentTransform: AffineTransform
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ancestorLayerIsDOMParent(ancestor: RenderLayerWrapper?) -> Bool {
    assert(isNativeImpl())
    if ancestor == nil {
      return false
    }
    if let parent = flattenedParent(element: renderer().element()) {
      if CPtrToInt(ancestor!.renderer().element()?.p) == CPtrToInt(parent.p) {
        return true
      }
    }

    if let parentPseudoId = parentPseudoElement(pseudoId: renderer().style().pseudoElementType()) {
      return parentPseudoId == ancestor!.renderer().style().pseudoElementType()
    }
    return false
  }

  private func setNextSibling(next: RenderLayerWrapper?) {
    assert(isNativeImpl())
    m_next = next
  }
  private func setPreviousSibling(prev: RenderLayerWrapper?) {
    assert(isNativeImpl())
    m_previous = prev
  }
  private func setFirstChild(_ first: RenderLayerWrapper) {
    assert(isNativeImpl())
    m_first = first
  }
  private func setLastChild(_ last: RenderLayerWrapper) {
    assert(isNativeImpl())
    m_last = last
  }

  private func updateAncestorDependentState() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func dirtyPaintOrderListsOnChildChange(child: RenderLayerWrapper) {
    assert(isNativeImpl())
    if child.isNormalFlowOnly {
      dirtyNormalFlowList()
    }

    if !child.isNormalFlowOnly || child.firstChild() != nil {
      // Dirty the z-order list in which we are contained. The stackingContext() can be null in the
      // case where we're building up generated content layers. This is ok, since the lists will start
      // off dirty in that case anyway.
      child.dirtyStackingContextZOrderLists()
    }
  }

  private func shouldBeNormalFlowOnly() -> Bool {
    assert(isNativeImpl())
    if canCreateStackingContext(layer: self) {
      return false
    }

    return renderer().hasNonVisibleOverflow()
      || renderer().isRenderHTMLCanvas()
      || renderer().isRenderVideo()
      || renderer().isRenderEmbeddedObject()
      || renderer().isRenderIFrame()
      || (renderer().style().specifiesColumns() && !isRenderViewLayer)
      || renderer().isRenderFragmentedFlow()
  }

  private func shouldBeCSSStackingContext() -> Bool {
    assert(isNativeImpl())
    return !renderer().style().hasAutoUsedZIndex()
      || renderer().shouldApplyLayoutOrPaintContainment()
      || renderer().requiresRenderingConsolidationForViewTransition()
      || renderer().isRenderViewTransitionCapture() || isRenderViewLayer
  }

  private func computeCanBeBackdropRoot() -> Bool {
    assert(isNativeImpl())
    if !renderer().settings().cssUnprefixedBackdropFilterEnabled() {
      return false
    }

    // In order to match other impls and not the spec, the document element should
    // only be a backdrop root (and be isolated from the base background color) if
    // another group rendering effect is present.
    // https://github.com/w3c/fxtf-drafts/issues/557
    return isRenderViewLayer
      || renderer().isTransparent()
      || renderer().hasBackdropFilter()
      || renderer().hasClipPath()
      || renderer().hasFilter()
      || renderer().hasBlendMode()
      || renderer().hasMask()
      || (renderer().requiresRenderingConsolidationForViewTransition()
        && !renderer().isDocumentElementRenderer())
      || (renderer().style().willChange() != nil
        && renderer().style().willChange()!.canBeBackdropRoot())
  }

  // Return true if changed.
  @discardableResult
  private func setIsNormalFlowOnly(isNormalFlowOnly: Bool) -> Bool {
    assert(isNativeImpl())
    if isNormalFlowOnly == self.isNormalFlowOnly {
      return false
    }

    self.isNormalFlowOnly = isNormalFlowOnly

    if let p = parent() {
      p.dirtyNormalFlowList()
    }
    dirtyStackingContextZOrderLists()
    return true
  }

  @discardableResult
  private func setIsCSSStackingContext(isCSSStackingContext: Bool) -> Bool {
    assert(isNativeImpl())
    let wasStacking = isStackingContext()
    m_isCSSStackingContext = isCSSStackingContext
    if wasStacking == isStackingContext() {
      return false
    }

    isStackingContextChanged()
    return true
  }

  @discardableResult
  private func setCanBeBackdropRoot(canBeBackdropRoot: Bool) -> Bool {
    assert(isNativeImpl())
    if self.canBeBackdropRoot == canBeBackdropRoot {
      return false
    }
    self.canBeBackdropRoot = canBeBackdropRoot
    return true
  }

  private func isStackingContextChanged() {
    assert(isNativeImpl())
    dirtyStackingContextZOrderLists()
    if isStackingContext() {
      dirtyZOrderLists()
    } else {
      clearZOrderLists()
    }
  }

  private func isDirtyStackingContext() -> Bool {
    assert(isNativeImpl())
    return zOrderListsDirty && isStackingContext()
  }

  private func updateZOrderLists() {
    assert(isNativeImpl())
    if !zOrderListsDirty {
      return
    }

    if !isStackingContext() {
      clearZOrderLists()
      zOrderListsDirty = false
      return
    }

    rebuildZOrderLists()
  }

  private func rebuildZOrderLists(
    posZOrderList: inout [RenderLayerWrapper]?, negZOrderList: inout [RenderLayerWrapper]?,
    accumulatedDirtyFlags: inout Compositing
  ) {
    assert(isNativeImpl())
    var child = firstChild()
    while child != nil {
      if !isReflectionLayer(layer: child!) {
        child!.collectLayers(
          positiveZOrderList: &posZOrderList, negativeZOrderList: &negZOrderList,
          accumulatedDirtyFlags: &accumulatedDirtyFlags)
      }
      child = child!.nextSibling()
    }

    // Sort the two lists.
    // TODO(asuhan): use a guaranteed stable sort
    if posZOrderList != nil {
      posZOrderList!.sort { first, second in first.zIndex() < second.zIndex() }
      // TODO(asuhan): shrink capacity to size
    }

    if negZOrderList != nil {
      negZOrderList!.sort { first, second in first.zIndex() < second.zIndex() }
      // TODO(asuhan): shrink capacity to size
    }

    if isRenderViewLayer && renderer().document().hasTopLayerElement() {
      let topLayerLayers = RenderLayerWrapper.topLayerRenderLayers(renderView: renderer().view())
      if topLayerLayers.isEmpty {
        return
      }
      if posZOrderList == nil {
        posZOrderList = []
      }

      var viewTransitionLayer: RenderLayerWrapper? = nil
      if !posZOrderList!.isEmpty
        && posZOrderList!.last!.renderer().style().pseudoElementType() == .ViewTransition
      {
        viewTransitionLayer = posZOrderList!.removeLast()
      }

      posZOrderList!.append(contentsOf: topLayerLayers)
      if let viewTransitionLayer = viewTransitionLayer {
        posZOrderList!.append(viewTransitionLayer)
      }
    }
  }

  private func rebuildZOrderLists() {
    assert(isNativeImpl())
    // TODO(asuhan): check layerListMutationAllowed() as well
    assert(isDirtyStackingContext())

    var childDirtyFlags = Compositing()
    rebuildZOrderLists(
      posZOrderList: &posZOrderList, negZOrderList: &negZOrderList,
      accumulatedDirtyFlags: &childDirtyFlags)
    zOrderListsDirty = false

    let hasNegativeZOrderList = negZOrderList != nil && negZOrderList!.count != 0
    // Having negative z-order lists affect whether a compositing layer needs a foreground layer.
    // Ideally we'd only trigger this when having z-order children changes, but we blow away the old z-order
    // lists on dirtying so we don't know the old state.
    if hasNegativeZOrderList != hadNegativeZOrderList {
      hadNegativeZOrderList = hasNegativeZOrderList
      if isComposited() {
        setNeedsCompositingConfigurationUpdate()
      }
    }

    // Building lists may have added layers with dirty flags, so make sure we propagate dirty bits up the tree.
    if compositingDirtyBits.containsAll(other: [
      .DescendantsNeedRequirementsTraversal, .DescendantsNeedBackingAndHierarchyTraversal,
    ]) {
      return
    }

    if childDirtyFlags.containsAny(other: RenderLayerWrapper.computeCompositingRequirementsFlags) {
      setDescendantsNeedCompositingRequirementsTraversal()
    }

    if childDirtyFlags.containsAny(other: RenderLayerWrapper.updateBackingOrHierarchyFlags) {
      setDescendantsNeedUpdateBackingAndHierarchyTraversal()
    }
  }

  private func collectLayers(
    positiveZOrderList: inout [RenderLayerWrapper]?,
    negativeZOrderList: inout [RenderLayerWrapper]?, accumulatedDirtyFlags: inout Compositing
  ) {
    assert(isNativeImpl())
    assert(!descendantDependentFlagsAreDirty())
    if establishesTopLayer() {
      return
    }

    let isStacking = isStackingContext()
    // Overflow layers are just painted by their enclosing layers, so they don't get put in zorder lists.
    var layerOrDescendantsAreVisible =
      (hasVisibleContent || intrinsicallyComposited)
      || ((hasVisibleDescendant || hasIntrinsicallyCompositedDescendants) && isStacking)
    layerOrDescendantsAreVisible =
      layerOrDescendantsAreVisible || page().hasEverSetVisibilityAdjustment()
    if !isNormalFlowOnly {
      if layerOrDescendantsAreVisible {
        if zIndex() >= 0 {
          if positiveZOrderList == nil {
            positiveZOrderList = []
          }
          positiveZOrderList!.append(self)
        } else {
          if negativeZOrderList == nil {
            negativeZOrderList = []
          }
          negativeZOrderList!.append(self)
        }
        accumulatedDirtyFlags.update(with: compositingDirtyBits)
        setWasIncludedInZOrderTree()
      } else {
        setWasOmittedFromZOrderTree()
      }
    }

    // Recur into our children to collect more layers, but only if we don't establish
    // a stacking context/container.
    if !isStacking {
      var child = firstChild()
      while child != nil {
        // Ignore reflections.
        if !isReflectionLayer(layer: child!) {
          child!.collectLayers(
            positiveZOrderList: &positiveZOrderList, negativeZOrderList: &negativeZOrderList,
            accumulatedDirtyFlags: &accumulatedDirtyFlags)
        }
        child = child!.nextSibling()
      }
    }
  }

  private func clearZOrderLists() {
    assert(isNativeImpl())
    assert(!isStackingContext())

    posZOrderList = nil
    negZOrderList = nil
  }

  private func updateNormalFlowList() {
    assert(isNativeImpl())
    if !normalFlowListDirty {
      return
    }

    var child = firstChild()
    while child != nil {
      // Ignore non-overflow layers and reflections.
      if child!.isNormalFlowOnly && !isReflectionLayer(layer: child!) {
        if normalFlowList == nil {
          normalFlowList = []
        }
        normalFlowList!.append(child!)
        child!.setWasIncludedInZOrderTree()
      }
      child = child!.nextSibling()
    }

    // TODO(asuhan): shrink capacity to size

    normalFlowListDirty = false
  }

  struct LayerPaintingInfo {
    init(
      inRootLayer: RenderLayerWrapper?, inDirtyRect: LayoutRectWrapper,
      inPaintBehavior: PaintBehavior, inSubpixelOffset: LayoutSizeWrapper,
      inSubtreePaintRoot: RenderObjectWrapper? = nil,
      inOverlapTestRequests: OverlapTestRequestMap? = nil,
      inRequireSecurityOriginAccessForWidgets: Bool = false
    ) {
      self.rootLayer = inRootLayer
      self.subtreePaintRoot = inSubtreePaintRoot
      self.paintDirtyRect = inDirtyRect
      self.subpixelOffset = inSubpixelOffset
      self.overlapTestRequests = inOverlapTestRequests
      self.paintBehavior = inPaintBehavior
      self.requireSecurityOriginAccessForWidgets = inRequireSecurityOriginAccessForWidgets
    }

    var rootLayer: RenderLayerWrapper?
    let subtreePaintRoot: RenderObjectWrapper?  // Only paint descendants of this object.
    var paintDirtyRect: LayoutRectWrapper  // Relative to rootLayer;
    var subpixelOffset: LayoutSizeWrapper
    let overlapTestRequests: OverlapTestRequestMap?
    var paintBehavior: PaintBehavior
    var requireSecurityOriginAccessForWidgets: Bool
    var clipToDirtyRect: Bool = true
    var regionContext: RegionContext? = nil
  }

  private func paintOffsetForRenderer(
    fragment: LayerFragment, paintingInfo: LayerPaintingInfo
  ) -> LayoutPointWrapper {
    assert(isNativeImpl())
    return toLayoutPoint(
      size: fragment.layerBounds.location() - rendererLocation() + paintingInfo.subpixelOffset)
  }

  // Compute, cache and return clip rects computed with the given layer as the root.
  private func updateClipRects(clipRectsContext: ClipRectsContext) -> ClipRects {
    assert(isNativeImpl())
    let clipRectsType = clipRectsContext.clipRectsType
    if let clipRectsCache = clipRectsCache,
      let clipRects = clipRectsCache.getClipRects(
        clipRectsType: clipRectsType, respectOverflowClip: clipRectsContext.respectOverflowClip())
    {
      return clipRects
    }

    if clipRectsCache == nil {
      clipRectsCache = ClipRectsCache()
    }

    // For transformed layers, the root layer was shifted to be us, so there is no need to
    // examine the parent. We want to cache clip rects with us as the root.
    let parentClipRects =
      (CPtrToInt(clipRectsContext.rootLayer?.layerId()) != CPtrToInt(layerId()) && parent() != nil)
      ? self.parentClipRects(clipRectsContext: clipRectsContext) : nil

    var clipRects = ClipRects.create()
    calculateClipRects(clipRectsContext: clipRectsContext, clipRects: &clipRects)

    if parentClipRects != nil && parentClipRects! == clipRects {
      clipRectsCache!.setClipRects(
        clipRectsType: clipRectsType, respectOverflowClip: clipRectsContext.respectOverflowClip(),
        clipRects: parentClipRects!)
      return parentClipRects!
    }
    clipRectsCache!.setClipRects(
      clipRectsType: clipRectsType, respectOverflowClip: clipRectsContext.respectOverflowClip(),
      clipRects: clipRects)
    return clipRects
  }

  // Compute and return the clip rects. If useCached is true, will used previously computed clip rects on ancestors
  // (rather than computing them all from scratch up the parent chain).
  private func calculateClipRects(clipRectsContext: ClipRectsContext, clipRects: inout ClipRects) {
    assert(isNativeImpl())
    if parent() == nil {
      // The root layer's clip rect is always infinite.
      clipRects.reset()
      return
    }

    let clipRectsType = clipRectsContext.clipRectsType
    let useCached = clipRectsType != .TemporaryClipRects

    // For transformed layers, the root layer was shifted to be us, so there is no need to
    // examine the parent. We want to cache clip rects with us as the root.

    // Ensure that our parent's clip has been calculated so that we can examine the values.
    if let parentLayer = CPtrToInt(clipRectsContext.rootLayer?.layerId()) != CPtrToInt(layerId())
      ? parent() : nil
    {
      if useCached, let parentClipRects = parentLayer.clipRects(context: clipRectsContext) {
        clipRects = parentClipRects
      } else {
        var parentContext = clipRectsContext

        if (parentContext.clipRectsType != .TemporaryClipRects
          && parentContext.clipRectsType != .AbsoluteClipRects) && clipCrossesPaintingBoundary()
        {
          parentContext.clipRectsType = .TemporaryClipRects
        }

        parentLayer.calculateClipRects(clipRectsContext: parentContext, clipRects: &clipRects)
      }
    } else {
      clipRects.reset()
    }

    // A fixed object is essentially the root of its containing block hierarchy, so when
    // we encounter such an object, we reset our clip rects to the fixedClipRect.
    if renderer().isFixedPositioned() {
      clipRects.posClipRect = clipRects.fixedClipRect
      clipRects.overflowClipRect = clipRects.fixedClipRect
      clipRects.fixed = true
    } else if renderer().isInFlowPositioned() {
      clipRects.posClipRect = clipRects.overflowClipRect
    } else if renderer().shouldUsePositionedClipping() {
      clipRects.overflowClipRect = clipRects.posClipRect
    }

    if (renderer().hasNonVisibleOverflow()
      && (clipRectsContext.respectOverflowClip()
        || CPtrToInt(layerId()) != CPtrToInt(clipRectsContext.rootLayer?.layerId())))
      || renderer().hasClip()
    {
      // This layer establishes a clip of some kind.

      // FIXME: Transforming a clip doesn't make a whole lot of sense, since it we have to round out to the
      // bounding box of the transformed quad.
      // It would be better for callers to transform rects into the coordinate space of the nearest clipped layer, apply
      // the clip in local space, and then repeat until the required coordinate space is reached.
      let needsTransform =
        clipRectsType == .AbsoluteClipRects
        ? m_hasTransformedAncestor || !canUseOffsetFromAncestor()
        : !canUseOffsetFromAncestor(ancestor: clipRectsContext.rootLayer!)

      var offset = LayoutPointWrapper()
      if !needsTransform {
        offset = toLayoutPoint(
          size: offsetFromAncestor(
            ancestorLayer: clipRectsContext.rootLayer, adjustForColumns: .AdjustForColumns))
      }

      if clipRects.fixed
        && CPtrToInt(clipRectsContext.rootLayer!.renderer().id())
          == CPtrToInt(renderer().view().id())
      {
        offset -= toLayoutSize(
          point: renderer().view().frameView().scrollPositionForFixedPosition())
      }

      if renderer().hasNonVisibleOverflow() {
        var newOverflowClip = ClipRect(
          rect: rendererOverflowClipRectForChildLayers(
            location: LayoutPointWrapper(), fragment: nil,
            relevancy: clipRectsContext.overlayScrollbarSizeRelevancy()))
        if needsTransform {
          newOverflowClip = ClipRect(
            rect: LayoutRectWrapper(
              r: renderer().localToContainerQuad(
                localQuad: FloatQuad(inRect: newOverflowClip.rect.FloatRect()),
                container: clipRectsContext.rootLayer!.renderer()
              ).boundingBox()))
        }
        newOverflowClip.moveBy(point: offset)
        newOverflowClip.affectedByRadius = renderer().style().hasBorderRadius()
        clipRects.overflowClipRect = intersection(
          a: newOverflowClip, b: clipRects.overflowClipRect)
        if renderer().canContainAbsolutelyPositionedObjects() {
          clipRects.posClipRect = intersection(a: newOverflowClip, b: clipRects.posClipRect)
        }
        if renderer().canContainFixedPositionObjects() {
          clipRects.fixedClipRect = intersection(a: newOverflowClip, b: clipRects.fixedClipRect)
        }
      }
      if renderer().hasClip(), let box = renderer() as? RenderBoxWrapper {
        var newPosClip = box.clipRect(location: LayoutPointWrapper(), fragment: nil)
        if needsTransform {
          newPosClip = LayoutRectWrapper(
            r: renderer().localToContainerQuad(
              localQuad: FloatQuad(inRect: newPosClip.FloatRect()),
              container: clipRectsContext.rootLayer!.renderer()
            ).boundingBox())
        }
        newPosClip.moveBy(offset: offset)
        let newPosClipCR = ClipRect(rect: newPosClip)
        clipRects.posClipRect = intersection(a: newPosClipCR, b: clipRects.posClipRect)
        clipRects.overflowClipRect = intersection(a: newPosClipCR, b: clipRects.overflowClipRect)
        clipRects.fixedClipRect = intersection(a: newPosClipCR, b: clipRects.fixedClipRect)
      }
    } else if renderer().hasNonVisibleOverflow() && transform != nil
      && renderer().style().hasBorderRadius()
    {
      clipRects.setOverflowClipRectAffectedByRadius()
    }
  }

  private func clipRects(context: ClipRectsContext) -> ClipRects? {
    assert(isNativeImpl())
    if let clipRectsCache = clipRectsCache {
      return clipRectsCache.getClipRects(
        clipRectsType: context.clipRectsType, respectOverflowClip: context.respectOverflowClip())
    }
    return nil
  }

  private func setAncestorChainHasSelfPaintingLayerDescendant() {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if renderer().shouldApplyPaintContainment() {
        hasSelfPaintingLayerDescendant = true
        hasSelfPaintingLayerDescendantDirty = false
        break
      }
      if !layer!.hasSelfPaintingLayerDescendantDirty && layer!.hasSelfPaintingLayerDescendant {
        break
      }

      layer!.hasSelfPaintingLayerDescendantDirty = false
      layer!.hasSelfPaintingLayerDescendant = true
      layer = layer!.parent()
    }
  }

  private func dirtyAncestorChainHasSelfPaintingLayerDescendantStatus() {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if layer!.hasSelfPaintingLayerDescendantDirty {
        break
      }

      layer!.hasSelfPaintingLayerDescendantDirty = true
      layer = layer!.parent()
    }
  }

  func computeRepaintRects(_ repaintContainer: RenderLayerModelObjectWrapper?) {
    assert(isNativeImpl())
    assert(!visibleContentStatusDirty)

    if !isSelfPaintingLayer {
      clearRepaintRects()
    } else {
      setRepaintRects(renderer().rectsForRepaintingAfterLayout(repaintContainer, .Yes))
    }
  }

  func computeRepaintRectsIncludingDescendants() {
    assert(isNativeImpl())
    // FIXME: computeRepaintRects() has to walk up the parent chain for every layer to compute the rects.
    // We should make this more efficient.
    // FIXME: it's wrong to call this when layout is not up-to-date, which we do.
    computeRepaintRects(renderer().containerForRepaint().renderer)

    var layer = firstChild()
    while layer != nil {
      layer!.computeRepaintRectsIncludingDescendants()
      layer = layer!.nextSibling()
    }
  }

  private func setRepaintRects(_ rects: RenderObjectWrapper.RepaintRects) {
    assert(isNativeImpl())
    m_repaintRects = rects
    repaintRectsValid = true
  }

  private func clearRepaintRects() {
    assert(isNativeImpl())
    repaintRectsValid = false
  }

  private func clipRectRelativeToAncestor(
    ancestor: RenderLayerWrapper?, offsetFromAncestor: LayoutSizeWrapper,
    constrainingRect: LayoutRectWrapper, temporaryClipRects: Bool = false
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    var layerBounds = LayoutRectWrapper()
    var backgroundRect = ClipRect()
    var foregroundRect = ClipRect()
    let clipRectType: ClipRectsType =
      (m_enclosingPaginationLayer == nil
        || CPtrToInt(m_enclosingPaginationLayer!.layerId()) == CPtrToInt(ancestor?.layerId()))
        && !temporaryClipRects
      ? .PaintingClipRects : .TemporaryClipRects
    let clipRectsContext = ClipRectsContext(inRootLayer: ancestor, inClipRectsType: clipRectType)
    calculateRects(
      clipRectsContext: clipRectsContext, paintDirtyRect: constrainingRect,
      layerBounds: &layerBounds,
      backgroundRect: &backgroundRect, foregroundRect: &foregroundRect,
      offsetFromRoot: offsetFromAncestor)
    return backgroundRect.rect
  }

  private func clipToRect(
    context: GraphicsContextWrapper, stateSaver: GraphicsContextStateSaver,
    regionContextStateSaver: RegionContextStateSaver, paintingInfo: LayerPaintingInfo,
    paintBehavior: PaintBehavior, clipRect: ClipRect,
    rule: BorderRadiusClippingRule = .IncludeSelfForBorderRadius
  ) {
    assert(isNativeImpl())
    let deviceScaleFactor = renderer().document().deviceScaleFactor()
    let needsClipping = !clipRect.isInfinite() && clipRect.rect != paintingInfo.paintDirtyRect
    if needsClipping || clipRect.affectedByRadius {
      stateSaver.save()
    }

    if needsClipping {
      var adjustedClipRect = clipRect.rect
      adjustedClipRect.move(size: paintingInfo.subpixelOffset)
      let snappedClipRect = snapRectToDevicePixelsIfNeeded(
        rect: adjustedClipRect, renderer: renderer())
      context.clip(rect: snappedClipRect)
      regionContextStateSaver.pushClip(clipRect: enclosingIntRect(rect: snappedClipRect))
    }

    if clipRect.affectedByRadius {
      // If the clip rect has been tainted by a border radius, then we have to walk up our layer chain applying the clips from
      // any layers with overflow. The condition for being able to apply these clips is that the overflow object be in our
      // containing block chain so we check that also.
      var layer: RenderLayerWrapper? = rule == .IncludeSelfForBorderRadius ? self : parent()
      while layer != nil {
        if paintBehavior.contains(.CompositedOverflowScrollContent)
          && layer!.usesCompositedScrolling()
        {
          break
        }

        if layer!.renderer().hasNonVisibleOverflow() && layer!.renderer().style().hasBorderRadius()
          && ancestorLayerIsInContainingBlockChain(ancestor: layer!)
        {
          var adjustedClipRect = LayoutRectWrapper(
            location: toLayoutPoint(
              size: layer!.offsetFromAncestor(
                ancestorLayer: paintingInfo.rootLayer, adjustForColumns: .AdjustForColumns)),
            size: LayoutSizeWrapper(size: layer!.size()))
          adjustedClipRect.move(size: paintingInfo.subpixelOffset)
          let borderShape = BorderShape.shapeForBorderRect(
            style: layer!.renderer().style(), borderRect: adjustedClipRect)
          if borderShape.innerShapeContains(rect: paintingInfo.paintDirtyRect) {
            context.clip(
              rect: snapRectToDevicePixels(
                rect: intersection(a: paintingInfo.paintDirtyRect, b: adjustedClipRect),
                pixelSnappingFactor: deviceScaleFactor))
          } else {
            borderShape.clipToInnerShape(context: context, deviceScaleFactor: deviceScaleFactor)
          }
        }

        if CPtrToInt(layer!.layerId()) == CPtrToInt(paintingInfo.rootLayer?.layerId()) {
          break
        }

        layer = layer!.parent()
      }
    }
  }

  private func updateSelfPaintingLayer() {
    assert(isNativeImpl())
    let isSelfPaintingLayer = shouldBeSelfPaintingLayer()
    if self.isSelfPaintingLayer == isSelfPaintingLayer {
      return
    }

    self.isSelfPaintingLayer = isSelfPaintingLayer
    if parent() == nil {
      return
    }

    if isSelfPaintingLayer {
      parent()!.setAncestorChainHasSelfPaintingLayerDescendant()
    } else {
      parent()!.dirtyAncestorChainHasSelfPaintingLayerDescendantStatus()
      clearRepaintRects()
      if let renderBox = self.renderBox(), renderBox.isFloating() {
        renderBox.updateFloatPainterAfterSelfPaintingLayerChange()
      }
    }
  }

  private func enclosingPaginationLayerInSubtree(
    rootLayer: RenderLayerWrapper?, mode: PaginationInclusionMode
  ) -> RenderLayerWrapper? {
    assert(isNativeImpl())
    // If we don't have an enclosing layer, or if the root layer is the same as the enclosing layer,
    // then just return the enclosing pagination layer (it will be 0 in the former case and the rootLayer in the latter case).
    let paginationLayer = enclosingPaginationLayer(mode: mode)
    if paginationLayer == nil
      || CPtrToInt(rootLayer?.layerId()) == CPtrToInt(paginationLayer!.layerId())
    {
      return paginationLayer
    }

    // Walk up the layer tree and see which layer we hit first. If it's the root, then the enclosing pagination
    // layer isn't in our subtree and we return nullptr. If we hit the enclosing pagination layer first, then
    // we can return it.
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if CPtrToInt(layer!.layerId()) == CPtrToInt(rootLayer?.layerId()) {
        return nil
      }
      if CPtrToInt(layer!.layerId()) == CPtrToInt(paginationLayer?.layerId()) {
        return paginationLayer
      }
      layer = layer!.parent()
    }

    // This should never be reached, since an enclosing layer should always either be the rootLayer or be
    // our enclosing pagination layer.
    fatalError("Not reached")
  }

  private func rendererLocation() -> LayoutPointWrapper {
    assert(isNativeImpl())
    if let box = renderer() as? RenderBoxWrapper {
      return box.location()
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.currentSVGLayoutLocation()
    }
    return LayoutPointWrapper()
  }

  func rendererBorderBoxRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func rendererBorderBoxRectInFragment(
    fragment: RenderFragmentContainerWrapper?,
    flags: RenderBoxWrapper.RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    if let box = renderer() as? RenderBoxWrapper {
      return box.borderBoxRectInFragment(fragment: fragment, flags: flags)
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.borderBoxRectInFragmentEquivalent(fragment: fragment, flags: flags)
    }
    return LayoutRectWrapper()
  }

  private func rendererVisualOverflowRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    if let box = renderer() as? RenderBoxWrapper {
      return box.visualOverflowRect()
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.visualOverflowRectEquivalent()
    }
    return LayoutRectWrapper()
  }

  private func rendererOverflowClipRect(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?,
    relevancy: OverlayScrollbarSizeRelevancy
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    if let box = renderer() as? RenderBoxWrapper {
      return box.overflowClipRect(location: location, fragment: fragment, relevancy: relevancy)
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.overflowClipRect(
        location: location, fragment: fragment, relevancy: relevancy)
    }
    return LayoutRectWrapper()
  }

  private func rendererOverflowClipRectForChildLayers(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?,
    relevancy: OverlayScrollbarSizeRelevancy
  )
    -> LayoutRectWrapper
  {
    assert(isNativeImpl())
    if let box = renderer() as? RenderBoxWrapper {
      return box.overflowClipRectForChildLayers(
        location: location, fragment: fragment, relevancy: relevancy)
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.overflowClipRectForChildLayers(
        location: location, fragment: fragment, relevancy: relevancy)
    }
    return LayoutRectWrapper()
  }

  private func rendererHasVisualOverflow() -> Bool {
    assert(isNativeImpl())
    if let box = renderer() as? RenderBoxWrapper {
      return box.hasVisualOverflow()
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.hasVisualOverflow()
    }
    return false
  }

  private func setupFontSubpixelQuantization(context: GraphicsContextWrapper) -> (Bool, Bool) {
    assert(isNativeImpl())
    if context.paintingDisabled() {
      return (false, true)
    }

    // FIXME: We shouldn't have to disable subpixel quantization for overflow clips or subframes once we scroll those
    // things on the scrolling thread.
    let didQuantizeFonts = context.shouldSubpixelQuantizeFonts()
    context.setShouldSubpixelQuantizeFonts(shouldSubpixelQuantizeFonts: false)
    return (true, didQuantizeFonts)
  }

  func computeClipPath(
    offsetFromRoot: LayoutSizeWrapper, rootRelativeBoundsForNonBoxes: LayoutRectWrapper
  ) -> (PathWrapper, WindRule) {
    assert(isNativeImpl())
    let style = renderer().style()

    if let clipPath = style.clipPath()! as? ShapePathOperation {
      let referenceBoxRect = referenceBoxRectForClipPath(
        boxType: clipPath.referenceBox, offsetFromRoot: offsetFromRoot,
        rootRelativeBounds: rootRelativeBoundsForNonBoxes)
      let snappedReferenceBoxRect = snapRectToDevicePixelsIfNeeded(
        rect: referenceBoxRect, renderer: renderer())
      return (
        clipPath.pathForReferenceRect(boundingRect: snappedReferenceBoxRect), clipPath.windRule()
      )
    }

    if let clipPath = style.clipPath()! as? BoxPathOperation,
      let box = renderer() as? RenderBoxWrapper
    {
      var shapeRect = computeRoundedRectForBoxShape(box: clipPath.referenceBox, renderer: box)
        .pixelSnappedRoundedRectForPainting(
          deviceScaleFactor: renderer().document().deviceScaleFactor())
      shapeRect.move(size: offsetFromRoot.FloatSize())

      return (
        clipPath.pathForReferenceRect(boundingRect: shapeRect), .NonZero
      )
    }

    return (PathWrapper(), .NonZero)
  }

  private func setupClipPath(
    context: GraphicsContextWrapper, stateSaver: GraphicsContextStateSaver,
    regionContextStateSaver: RegionContextStateSaver, paintingInfo: LayerPaintingInfo,
    paintFlags: inout PaintLayerFlag, offsetFromRoot: LayoutSizeWrapper
  ) {
    assert(isNativeImpl())
    let isCollectingRegions =
      paintFlags.contains(.CollectingEventRegion)
      || (paintingInfo.regionContext is AccessibilityRegionContext)
    if !renderer().hasClipPath() || (context.paintingDisabled() && !isCollectingRegions)
      || paintingInfo.paintDirtyRect.isEmpty()
    {
      return
    }

    // Applying clip-path on <clipPath> enforces us to use mask based clipping, so return false here to disable path based clipping.
    // Furthermore if we're the child of a resource container (<clipPath> / <mask> / ...) disabled path based clipping.
    if enclosingSVGHiddenOrResourceContainer is RenderSVGResourceClipperWrapper {
      // If isPaintingSVGResourceLayer is true, this function was invoked via paintSVGResourceLayer() -- clipping on <clipPath> is already
      // handled in RenderSVGResourceClipper::applyMaskClipping(), so do not set paintSVGClippingMask to true here.
      if isPaintingSVGResourceLayer {
        paintFlags.remove(.PaintingSVGClippingMask)
      } else {
        paintFlags.update(with: .PaintingSVGClippingMask)
      }
      return
    }

    let clippedContentBounds = calculateLayerBounds(
      ancestorLayer: paintingInfo.rootLayer, offsetFromRoot: offsetFromRoot,
      flags: [.UseLocalClipRectIfPossible])

    let style = renderer().style()
    let paintingOffsetFromRoot = LayoutSizeWrapper(
      size: snapSizeToDevicePixel(
        size: offsetFromRoot + paintingInfo.subpixelOffset, location: LayoutPointWrapper(),
        pixelSnappingFactor: renderer().document().deviceScaleFactor()))
    let clipPath = style.clipPath()!
    if (clipPath is ShapePathOperation)
      || (clipPath is BoxPathOperation && renderer() is RenderBoxWrapper)
    {
      // clippedContentBounds is used as the reference box for inlines, which is also poorly specified: https://github.com/w3c/csswg-drafts/issues/6383.
      let (path, windRule) = computeClipPath(
        offsetFromRoot: paintingOffsetFromRoot, rootRelativeBoundsForNonBoxes: clippedContentBounds)

      if isCollectingRegions {
        regionContextStateSaver.pushClip(path: path)
        return
      }

      stateSaver.save()
      context.clipPath(path: path, clipRule: windRule)
      return
    }

    if let referenceClipPathOperation = style.clipPath() as? ReferencePathOperation {
      if let svgClipper = renderer().svgClipperResourceFromStyle() {
        if let graphicsElement = svgClipper.shouldApplyPathClipping() {
          stateSaver.save()
          var svgReferenceBox = FloatRectWrapper()
          var coordinateSystemOriginTranslation = FloatSize()
          if renderer().isSVGLayerAwareRenderer() {
            assert(paintingInfo.subpixelOffset.isZero())
            let boundingBoxTopLeftCorner = renderer().nominalSVGLayoutLocation()
            svgReferenceBox = renderer().objectBoundingBox()
            coordinateSystemOriginTranslation =
              (toLayoutPoint(size: offsetFromRoot) - boundingBoxTopLeftCorner).FloatSize()
          } else {
            let clipPathObjectBoundingBox = referenceBoxRectForClipPath(
              boxType: .BorderBox, offsetFromRoot: offsetFromRoot,
              rootRelativeBounds: clippedContentBounds)
            svgReferenceBox = snapRectToDevicePixels(
              rect: LayoutRectWrapper(r: clipPathObjectBoundingBox),
              pixelSnappingFactor: renderer().document().deviceScaleFactor())
          }

          if !coordinateSystemOriginTranslation.isZero() {
            context.translate(size: coordinateSystemOriginTranslation)
          }

          svgClipper.applyPathClipping(
            context: context, targetRenderer: renderer(), objectBoundingBox: svgReferenceBox,
            graphicsElement: graphicsElement)

          if !coordinateSystemOriginTranslation.isZero() {
            context.translate(size: -coordinateSystemOriginTranslation)
          }
          return
        } else {
          paintFlags.update(with: .PaintingSVGClippingMask)
          return
        }
      }

      if let clipperRenderer = ReferencedSVGResources.referencedClipperRenderer(
        treeScope: renderer().treeScopeForSVGReferences(), clipPath: referenceClipPathOperation)
      {
        // Use the border box as the reference box, even though this is not clearly specified: https://github.com/w3c/csswg-drafts/issues/5786.
        // clippedContentBounds is used as the reference box for inlines, which is also poorly specified: https://github.com/w3c/csswg-drafts/issues/6383.
        let referenceBox = referenceBoxRectForClipPath(
          boxType: .BorderBox, offsetFromRoot: offsetFromRoot,
          rootRelativeBounds: clippedContentBounds)
        let snappedReferenceBox = snapRectToDevicePixelsIfNeeded(
          rect: referenceBox, renderer: renderer())
        let offset = snappedReferenceBox.location()

        var snappedClippingBounds = snapRectToDevicePixelsIfNeeded(
          rect: clippedContentBounds, renderer: renderer())
        snappedClippingBounds.moveBy(delta: -offset)

        stateSaver.save()
        context.translate(p: offset)
        clipperRenderer.applyClippingToContext(
          context: context, renderer: renderer(),
          objectBoundingBox: FloatRectWrapper(location: FloatPoint(), size: referenceBox.size()),
          clippedContentBounds: snappedClippingBounds, usedZoom: renderer().style().usedZoom())
        context.translate(p: -offset)

        // FIXME: Support event regions.
      }
    }
  }

  private func ensureLayerFilters() {
    assert(isNativeImpl())
    if filters != nil {
      return
    }

    filters = RenderLayerFilters(layer: self)
  }

  private func clearLayerFilters() {
    assert(isNativeImpl())
    filters = nil
  }

  private func updateLayerScrollableArea() {
    assert(isNativeImpl())
    let hasScrollableArea = scrollableArea() != nil
    var needsScrollableArea = false
    if let box = renderer() as? RenderBoxWrapper {
      needsScrollableArea = box.requiresLayerWithScrollableArea()
    }

    if needsScrollableArea == hasScrollableArea {
      return
    }

    if needsScrollableArea {
      ensureLayerScrollableArea()
    } else {
      clearLayerScrollableArea()
      if renderer().settings().asyncOverflowScrollingEnabled() {
        setNeedsCompositingConfigurationUpdate()
      }
    }

    InspectorInstrumentationWrapper.didAddOrRemoveScrollbars(renderer: renderer())
  }

  private func clearLayerScrollableArea() {
    assert(isNativeImpl())
    if let scrollableArea = m_scrollableArea {
      scrollableArea.clear()
      m_scrollableArea = nil
    }
  }

  private func filtersForPainting(context: GraphicsContextWrapper, paintFlags: PaintLayerFlag)
    -> RenderLayerFilters?
  {
    assert(isNativeImpl())
    if context.paintingDisabled() {
      return nil
    }

    if paintFlags.contains(.PaintingOverlayScrollbars) {
      return nil
    }

    if !paintsWithFilters() {
      return nil
    }

    return filters
  }

  private func setupFilters(
    destinationContext: GraphicsContextWrapper, paintingInfo: inout LayerPaintingInfo,
    paintFlags: PaintLayerFlag, offsetFromRoot: LayoutSizeWrapper, backgroundRect: ClipRect
  ) -> GraphicsContextWrapper? {
    assert(isNativeImpl())
    if let paintingFilters = filtersForPainting(context: destinationContext, paintFlags: paintFlags)
    {
      var filterRepaintRect = paintingFilters.dirtySourceRect
      filterRepaintRect.move(size: offsetFromRoot)

      let rootRelativeBounds = calculateLayerBounds(
        ancestorLayer: paintingInfo.rootLayer, offsetFromRoot: offsetFromRoot, flags: [])

      if let filterContext =
        paintingFilters.beginFilterEffect(
          renderer: renderer(), context: destinationContext,
          filterBoxRect: LayoutRectWrapper(rect: enclosingIntRect(rect: rootRelativeBounds)),
          dirtyRect: LayoutRectWrapper(rect: enclosingIntRect(rect: paintingInfo.paintDirtyRect)),
          layerRepaintRect: LayoutRectWrapper(rect: enclosingIntRect(rect: filterRepaintRect)),
          clipRect: backgroundRect.rect)
      {
        paintingInfo.paintDirtyRect = paintingFilters.repaintRect

        // If the filter needs the full source image, we need to avoid using the clip rectangles.
        // Otherwise, if for example this layer has overflow:hidden, a drop shadow will not compute correctly.
        // Note that we will still apply the clipping on the final rendering of the filter.
        paintingInfo.clipToDirtyRect = !paintingFilters.hasFilterThatMovesPixels()

        paintingInfo.requireSecurityOriginAccessForWidgets =
          paintingFilters.hasFilterThatShouldBeRestrictedBySecurityOrigin()

        return filterContext
      }

      return nil
    }
    return nil
  }

  private func applyFilters(
    originalContext: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo,
    behavior: PaintBehavior, backgroundRect: ClipRect
  ) {
    assert(isNativeImpl())
    let stateSaver = GraphicsContextStateSaver(context: originalContext, saveAndRestore: false)
    let needsClipping = filters!.hasSourceImage()

    if needsClipping {
      let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)

      clipToRect(
        context: originalContext, stateSaver: stateSaver,
        regionContextStateSaver: regionContextStateSaver, paintingInfo: paintingInfo,
        paintBehavior: behavior, clipRect: backgroundRect
      )
    }

    filters!.applyFilterEffect(destinationContext: originalContext)
  }

  private static func paintForFixedRootBackground(
    layer: RenderLayerWrapper, paintFlags: PaintLayerFlag
  )
    -> Bool
  {
    return layer.renderer().isDocumentElementRenderer()
      && paintFlags.contains(.PaintingRootBackgroundOnly)
  }

  func paintLayer(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    assert(isNativeImpl())
    var paintFlags = paintFlags
    if paintsIntoDifferentCompositedDestination(paintFlags: paintFlags) {
      if !context.performingPaintInvalidation()
        && !paintingInfo.paintBehavior.contains(.FlattenCompositingLayers)
      {
        return
      }

      paintFlags.update(with: .TemporaryClipRects)
    }

    if viewportConstrainedNotCompositedReason == .NotCompositedForBoundsOutOfView
      && !paintingInfo.paintBehavior.contains(.Snapshotting)
    {
      // Don't paint out-of-view viewport constrained layers (when doing prepainting) because they will never be visible
      // unless their position or viewport size is changed.
      assert(renderer().isFixedPositioned())
      return
    }

    paintLayerWithEffects(context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
  }

  private func shouldContinuePaint(paintFlags: PaintLayerFlag) -> Bool {
    assert(isNativeImpl())
    return backing!.paintsIntoWindow()
      || backing!.paintsIntoCompositedAncestor()
      || shouldDoSoftwarePaint(
        layer: self, paintingReflection: paintFlags.contains(.PaintingReflection))
      || RenderLayerWrapper.paintForFixedRootBackground(layer: self, paintFlags: paintFlags)
  }

  private func paintsIntoDifferentCompositedDestination(paintFlags: PaintLayerFlag) -> Bool {
    assert(isNativeImpl())
    if paintsIntoProvidedBacking() {
      return true
    }

    if isComposited() && !shouldContinuePaint(paintFlags: paintFlags) {
      return true
    }

    return false
  }

  private func paintLayerWithEffects(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    assert(isNativeImpl())
    // Non self-painting leaf layers don't need to be painted as their renderer() should properly paint itself.
    if !isSelfPaintingLayer && !hasSelfPaintingLayerDescendant {
      return
    }

    if shouldSuppressPaintingLayer(layer: self) {
      return
    }

    // If this layer is totally invisible then there is nothing to paint.
    if renderer().opacity() == 0 {
      return
    }

    var paintFlags = paintFlags
    if paintsWithTransparency(paintBehavior: paintingInfo.paintBehavior) {
      paintFlags.update(with: .HaveTransparency)
    }

    // PaintLayerFlag::AppliedTransform is used in RenderReplica, to avoid applying the transform twice.
    if paintsWithTransform(paintBehavior: paintingInfo.paintBehavior)
      && !paintFlags.contains(.AppliedTransform)
    {
      let layerTransform = renderableTransform(paintBehavior: paintingInfo.paintBehavior)
      // If the transform can't be inverted, then don't paint anything.
      if !layerTransform.isInvertible() {
        return
      }

      // If we have a transparency layer enclosing us and we are the root of a transform, then we need to establish the transparency
      // layer from the parent now, assuming there is a parent
      if paintFlags.contains(.HaveTransparency) {
        if CPtrToInt(layerId()) != CPtrToInt(paintingInfo.rootLayer?.layerId()),
          let parent = parent()
        {
          parent.beginTransparencyLayers(
            context: context, paintingInfo: paintingInfo, dirtyRect: paintingInfo.paintDirtyRect)
        } else {
          beginTransparencyLayers(
            context: context, paintingInfo: paintingInfo, dirtyRect: paintingInfo.paintDirtyRect)
        }
      }

      if enclosingPaginationLayer(mode: .ExcludeCompositedPaginatedLayers) != nil {
        paintTransformedLayerIntoFragments(
          context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
        return
      }

      // Make sure the parent's clip rects have been calculated.
      var clipRect = ClipRect(rect: paintingInfo.paintDirtyRect)
      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)
      if let parent = parent() {
        let options =
          paintFlags.contains(.PaintingOverflowContents)
          ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
          : RenderLayerWrapper.clipRectDefaultOptions
        let clipRectsContext = ClipRectsContext(
          inRootLayer: paintingInfo.rootLayer,
          inClipRectsType: paintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects,
          inOptions: options)
        clipRect = backgroundClipRect(clipRectsContext: clipRectsContext)
        clipRect.intersect(other: paintingInfo.paintDirtyRect)

        var paintBehavior: PaintBehavior = [.Normal]
        if paintFlags.contains(.PaintingOverflowContents) {
          paintBehavior.update(with: .CompositedOverflowScrollContent)
        }

        // Always apply SVG viewport clipping in coordinate system before the SVG viewBox transformation is applied.
        if let svgRoot = renderer() as? RenderSVGRootWrapper {
          if svgRoot.shouldApplyViewportClip() {
            var newRect = svgRoot.borderBoxRect()

            let offsetFromParent = offsetFromAncestor(ancestorLayer: clipRectsContext.rootLayer)
            let offsetForThisLayer = offsetFromParent + paintingInfo.subpixelOffset
            let devicePixelSnappedOffsetForThisLayer = toFloatSize(
              a: roundPointToDevicePixels(
                point: toLayoutPoint(size: offsetForThisLayer),
                pixelSnappingFactor: renderer().document().deviceScaleFactor())
            )
            newRect.move(
              dx: devicePixelSnappedOffsetForThisLayer.width,
              dy: devicePixelSnappedOffsetForThisLayer.height)

            clipRect.intersect(other: newRect)
          }
        }

        // Push the parent coordinate space's clip.
        parent.clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: paintingInfo,
          paintBehavior: paintBehavior, clipRect: clipRect)
      }

      paintLayerByApplyingTransform(
        context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
      return
    }

    paintLayerContentsAndReflection(
      context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
  }

  private func paintLayerContentsAndReflection(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    assert(isNativeImpl())
    assert(isSelfPaintingLayer || hasSelfPaintingLayerDescendant)

    let localPaintFlags = paintFlags.subtracting(.AppliedTransform)

    // Paint the reflection first if we have one.
    if reflection != nil && !paintingInsideReflection {
      // Mark that we are now inside replica painting.
      paintingInsideReflection = true
      reflectionLayer()!.paintLayer(
        context: context, paintingInfo: paintingInfo,
        paintFlags: localPaintFlags.union(.PaintingReflection))
      paintingInsideReflection = false
    }

    paintLayerContents(
      context: context, paintingInfo: paintingInfo,
      paintFlags: localPaintFlags.union(
        RenderLayerWrapper.paintLayerPaintingCompositingAllPhasesFlags))
  }

  private func paintLayerByApplyingTransform(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag,
    translationOffset: LayoutSizeWrapper = LayoutSizeWrapper()
  ) {
    assert(isNativeImpl())
    // This involves subtracting out the position of the layer in our current coordinate space, but preserving
    // the accumulated error for sub-pixel layout.
    // Note: The pixel-snapping logic is disabled for the whole SVG render tree, except the outermost <svg>.
    let deviceScaleFactor = renderer().document().deviceScaleFactor()
    var offsetFromParent = offsetFromAncestor(ancestorLayer: paintingInfo.rootLayer)
    offsetFromParent += translationOffset
    let transform = renderableTransform(paintBehavior: paintingInfo.paintBehavior).deepCopy()
    // Add the subpixel accumulation to the current layer's offset so that we can always snap the translateRight value to where the renderer() is supposed to be painting.
    let offsetForThisLayer = offsetFromParent + paintingInfo.subpixelOffset
    let alignedOffsetForThisLayer =
      rendererNeedsPixelSnapping(renderer: renderer())
      ? toFloatSize(
        a: roundPointToDevicePixels(
          point: toLayoutPoint(size: offsetForThisLayer), pixelSnappingFactor: deviceScaleFactor))
      : offsetForThisLayer.FloatSize()
    // We handle accumulated subpixels through nested layers here. Since the context gets translated to device pixels,
    // all we need to do is add the delta to the accumulated pixels coming from ancestor layers.
    // Translate the graphics context to the snapping position to avoid off-device-pixel positing.
    transform.translateRight(
      tx: Float64(alignedOffsetForThisLayer.width), ty: Float64(alignedOffsetForThisLayer.height))
    // Apply the transform.
    let oldTransform = context.getCTM()
    let affineTransform = transform.toAffineTransform()
    context.concatCTM(transform: affineTransform)

    if let regionContext = paintingInfo.regionContext {
      regionContext.pushTransform(transform: affineTransform)
    }

    // Only propagate the subpixel offsets to the descendant layers, if we're not the root
    // of a SVG subtree, where no pixel snapping is applied -- only the outermost <svg> layer
    // is pixel-snapped "as whole", if it's part of a compound document, e.g. inline SVG in HTML.
    let adjustedSubpixelOffset =
      rendererNeedsPixelSnapping(renderer: renderer()) && !renderer().isRenderSVGRoot()
      ? offsetForThisLayer - LayoutSizeWrapper(size: alignedOffsetForThisLayer)
      : LayoutSizeWrapper()

    // Now do a paint with the root layer shifted to be us.
    var transformedPaintingInfo = paintingInfo
    transformedPaintingInfo.rootLayer = self
    if !transformedPaintingInfo.paintDirtyRect.isInfinite() {
      transformedPaintingInfo.paintDirtyRect = LayoutRectWrapper(
        r: encloseRectToDevicePixels(
          rect: (transform.inverse() ?? TransformationMatrix()).mapRect(
            paintingInfo.paintDirtyRect),
          pixelSnappingFactor: deviceScaleFactor))
    }
    transformedPaintingInfo.subpixelOffset = adjustedSubpixelOffset
    paintLayerContentsAndReflection(
      context: context, paintingInfo: transformedPaintingInfo, paintFlags: paintFlags)

    if let regionContext = paintingInfo.regionContext {
      regionContext.popTransform()
    }

    context.setCTM(transform: oldTransform)
  }

  private func paintLayerContents(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    assert(isNativeImpl())
    assert(isSelfPaintingLayer || hasSelfPaintingLayerDescendant)

    if context.detectingContentfulPaint() && context.contentfulPaintDetected() {
      return
    }

    var localPaintFlags = paintFlags.subtracting(.AppliedTransform)

    let haveTransparency = localPaintFlags.contains(.HaveTransparency)
    let isPaintingOverlayScrollbars = localPaintFlags.contains(.PaintingOverlayScrollbars)
    let isPaintingScrollingContent = localPaintFlags.contains(.PaintingCompositingScrollingPhase)
    let isPaintingCompositedForeground = localPaintFlags.contains(
      .PaintingCompositingForegroundPhase)
    let isPaintingCompositedBackground = localPaintFlags.contains(
      .PaintingCompositingBackgroundPhase)
    let isPaintingOverflowContents = localPaintFlags.contains(.PaintingOverflowContents)
    let isCollectingEventRegion = localPaintFlags.contains(.CollectingEventRegion)
    let isCollectingAccessibilityRegion = paintingInfo.regionContext is AccessibilityRegionContext

    let isSelfPaintingLayer = self.isSelfPaintingLayer

    // Outline always needs to be painted even if we have no visible content. Also,
    // the outline is painted in the background phase during composited scrolling.
    // If it were painted in the foreground phase, it would move with the scrolled
    // content. When not composited scrolling, the outline is painted in the
    // foreground phase. Since scrolled contents are moved by repainting in this
    // case, the outline won't get 'dragged along'.
    let shouldPaintOutline =
      isSelfPaintingLayer && !isPaintingOverlayScrollbars && !isCollectingEventRegion
      && !isCollectingAccessibilityRegion
      && (renderer().view().printing() || renderer().view().hasRenderersWithOutline())
      && ((isPaintingScrollingContent && isPaintingCompositedBackground)
        || (!isPaintingScrollingContent && isPaintingCompositedForeground))

    let shouldPaintContent =
      paintLayerHasVisibleContent() && isSelfPaintingLayer && !isPaintingOverlayScrollbars
      && !isCollectingEventRegion && !isCollectingAccessibilityRegion

    if localPaintFlags.contains(.PaintingRootBackgroundOnly) && !renderer().isRenderView()
      && !renderer().isDocumentElementRenderer()
    {
      // If beginTransparencyLayers was called prior to this, ensure the transparency state is cleaned up before returning.
      if haveTransparency && usedTransparency && !paintingInsideReflection {
        if let savedAlphaForTransparency = self.savedAlphaForTransparency {
          context.setAlpha(alpha: savedAlphaForTransparency)
          self.savedAlphaForTransparency = nil
        } else {
          context.endTransparencyLayer()
          context.restore()
        }
        usedTransparency = false
      }

      return
    }

    updateLayerListsIfNeeded()

    let offsetFromRoot = offsetFromAncestor(ancestorLayer: paintingInfo.rootLayer)

    // FIXME: We shouldn't have to disable subpixel quantization for overflow clips or subframes once we scroll those
    // things on the scrolling thread.
    let (needToAdjustSubpixelQuantization, didQuantizeFonts) = setupFontSubpixelQuantization(
      context: context)

    // Apply clip-path to context.
    var columnAwareOffsetFromRoot = offsetFromRoot
    if renderer().enclosingFragmentedFlow() != nil
      && (renderer().hasClipPath()
        || filtersForPainting(context: context, paintFlags: paintFlags) != nil)
    {
      columnAwareOffsetFromRoot = toLayoutSize(
        point: convertToLayerCoords(
          ancestorLayer: paintingInfo.rootLayer, location: LayoutPointWrapper(),
          adjustForColumns: .AdjustForColumns))
    }

    let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
    let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)

    if shouldApplyClipPath(paintBehavior: paintingInfo.paintBehavior, paintFlags: localPaintFlags) {
      setupClipPath(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: paintingInfo, paintFlags: &localPaintFlags,
        offsetFromRoot: columnAwareOffsetFromRoot)
    }

    let applySVGClippingMask = localPaintFlags.contains(.PaintingSVGClippingMask)
    if applySVGClippingMask {
      localPaintFlags.remove(.PaintingSVGClippingMask)
    }

    let selectionAndBackgroundsOnly = paintingInfo.paintBehavior.contains(
      .SelectionAndBackgroundsOnly)
    let selectionOnly = paintingInfo.paintBehavior.contains(.SelectionOnly)

    paintFrequencyTracker.track(timestamp: page().lastRenderingUpdateTimestamp())

    var layerFragments: LayerFragments = []
    var subtreePaintRootForRenderer: RenderObjectWrapper? = nil

    let paintBehavior = paintBehaviorForContents(
      paintingInfo: paintingInfo, localPaintFlags: localPaintFlags,
      isPaintingOverflowContents: isPaintingOverflowContents,
      isCollectingEventRegion: isCollectingEventRegion,
      isPaintingCompositedForeground: isPaintingCompositedForeground,
      isPaintingCompositedBackground: isPaintingCompositedBackground)

    do {  // Scope for filter-related state changes.
      var backgroundRect = ClipRect()

      if filtersForPainting(context: context, paintFlags: paintFlags) != nil {
        // When we called collectFragments() last time, paintDirtyRect was reset to represent the filter bounds.
        // Now we need to compute the backgroundRect uncontaminated by filters, in order to clip the filtered result.
        // Note that we also use paintingInfo here, not localPaintingInfo which filters also contaminated.
        var layerFragments: LayerFragments = []
        let clipRectOptions =
          isPaintingOverflowContents
          ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
          : RenderLayerWrapper.clipRectDefaultOptions
        collectFragments(
          fragments: &layerFragments, rootLayer: paintingInfo.rootLayer,
          dirtyRect: paintingInfo.paintDirtyRect,
          inclusionMode: .ExcludeCompositedPaginatedLayers,
          clipRectsType: localPaintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects,
          clipRectOptions: clipRectOptions, offsetFromRoot: offsetFromRoot)
        updatePaintingInfoForFragments(
          fragments: &layerFragments, localPaintingInfo: paintingInfo,
          localPaintFlags: localPaintFlags, shouldPaintContent: shouldPaintContent,
          offsetFromRoot: offsetFromRoot)

        // FIXME: Handle more than one fragment.
        backgroundRect = layerFragments.isEmpty ? ClipRect() : layerFragments[0].backgroundRect
      }

      var localPaintingInfo = paintingInfo
      let filterContext = setupFilters(
        destinationContext: context, paintingInfo: &localPaintingInfo, paintFlags: paintFlags,
        offsetFromRoot: columnAwareOffsetFromRoot, backgroundRect: backgroundRect)
      if filterContext != nil && haveTransparency {
        // If we have a filter and transparency, we have to eagerly start a transparency layer here, rather than risk a child layer lazily starts one with the wrong context.
        beginTransparencyLayers(
          context: context, paintingInfo: localPaintingInfo, dirtyRect: paintingInfo.paintDirtyRect)
      }
      let currentContext = filterContext != nil ? filterContext! : context

      if filterContext != nil {
        localPaintingInfo.paintBehavior.update(with: .DontShowVisitedLinks)
      }

      // If this layer's renderer is a child of the subtreePaintRoot, we render unconditionally, which
      // is done by passing a nil subtreePaintRoot down to our renderer (as if no subtreePaintRoot was ever set).
      // Otherwise, our renderer tree may or may not contain the subtreePaintRoot root, so we pass that root along
      // so it will be tested against as we descend through the renderers.
      if localPaintingInfo.subtreePaintRoot != nil
        && !renderer().isDescendantOf(ancestor: localPaintingInfo.subtreePaintRoot)
      {
        subtreePaintRootForRenderer = localPaintingInfo.subtreePaintRoot
      }

      if var overlapTestRequests = localPaintingInfo.overlapTestRequests, isSelfPaintingLayer {
        performOverlapTests(
          overlapTestRequests: &overlapTestRequests,
          rootLayer: localPaintingInfo.rootLayer, layer: self)
      }

      var paintDirtyRect = localPaintingInfo.paintDirtyRect
      if shouldPaintContent || shouldPaintOutline || isPaintingOverlayScrollbars
        || isCollectingEventRegion || isCollectingAccessibilityRegion
      {
        // Collect the fragments. This will compute the clip rectangles and paint offsets for each layer fragment, as well as whether or not the content of each
        // fragment should paint. If the parent's filter dictates full repaint to ensure proper filter effect,
        // use the overflow clip as dirty rect, instead of no clipping. It maintains proper clipping for overflow::scroll.
        if !localPaintingInfo.clipToDirtyRect && renderer().hasNonVisibleOverflow() {
          // We can turn clipping back by requesting full repaint for the overflow area.
          localPaintingInfo.clipToDirtyRect = true
          paintDirtyRect = clipRectRelativeToAncestor(
            ancestor: localPaintingInfo.rootLayer, offsetFromAncestor: offsetFromRoot,
            constrainingRect: LayoutRectWrapper.infiniteRect(),
            temporaryClipRects: localPaintFlags.contains(.TemporaryClipRects))
        }

        let clipRectOptions =
          isPaintingOverflowContents
          ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
          : RenderLayerWrapper.clipRectDefaultOptions
        collectFragments(
          fragments: &layerFragments, rootLayer: localPaintingInfo.rootLayer,
          dirtyRect: paintDirtyRect,
          inclusionMode: .ExcludeCompositedPaginatedLayers,
          clipRectsType: localPaintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects,
          clipRectOptions: clipRectOptions, offsetFromRoot: offsetFromRoot)
        updatePaintingInfoForFragments(
          fragments: &layerFragments, localPaintingInfo: localPaintingInfo,
          localPaintFlags: localPaintFlags, shouldPaintContent: shouldPaintContent,
          offsetFromRoot: offsetFromRoot)
      }

      if isPaintingCompositedBackground {
        // Paint only the backgrounds for all of the fragments of the layer.
        if shouldPaintContent && !selectionOnly {
          paintBackgroundForFragments(
            layerFragments: layerFragments, context: currentContext,
            contextForTransparencyLayer: context,
            transparencyPaintDirtyRect: paintingInfo.paintDirtyRect,
            haveTransparency: haveTransparency,
            localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior,
            subtreePaintRootForRenderer: subtreePaintRootForRenderer)
        }
      }

      // Now walk the sorted list of children with negative z-indices.
      if (isPaintingScrollingContent && isPaintingOverflowContents)
        || (!isPaintingScrollingContent && isPaintingCompositedBackground)
      {
        paintList(
          layerIterator: negativeZOrderLayers(), context: currentContext,
          paintingInfo: paintingInfo, paintFlags: localPaintFlags)
      }

      if isPaintingCompositedForeground {
        if shouldPaintContent {
          paintForegroundForFragments(
            layerFragments: layerFragments, context: currentContext,
            contextForTransparencyLayer: context,
            transparencyPaintDirtyRect: paintingInfo.paintDirtyRect,
            haveTransparency: haveTransparency,
            localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior,
            subtreePaintRootForRenderer: subtreePaintRootForRenderer)
        }
      }

      if isCollectingEventRegion {
        collectEventRegionForFragments(
          layerFragments: layerFragments, context: currentContext,
          localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior)
      }

      if isCollectingAccessibilityRegion {
        collectAccessibilityRegionsForFragments(
          layerFragments: layerFragments, context: currentContext,
          localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior)
      }

      if shouldPaintOutline {
        paintOutlineForFragments(
          layerFragments: layerFragments, context: currentContext,
          localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior,
          subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }

      if isPaintingCompositedForeground {
        // Paint any child layers that have overflow.
        paintList(
          layerIterator: normalFlowLayers(), context: currentContext, paintingInfo: paintingInfo,
          paintFlags: localPaintFlags)

        // Now walk the sorted list of children with positive z-indices.
        paintList(
          layerIterator: positiveZOrderLayers(), context: currentContext,
          paintingInfo: localPaintingInfo, paintFlags: localPaintFlags)
      }

      if let scrollableArea = m_scrollableArea {
        if isPaintingOverlayScrollbars && scrollableArea.hasScrollbars() {
          paintOverflowControlsForFragments(
            layerFragments: layerFragments, context: currentContext,
            localPaintingInfo: localPaintingInfo)
        }
      }

      if filterContext != nil {
        applyFilters(
          originalContext: context, paintingInfo: paintingInfo, behavior: paintBehavior,
          backgroundRect: backgroundRect)
      }
    }

    if shouldPaintContent && !(selectionOnly || selectionAndBackgroundsOnly) {
      if shouldPaintMask(paintBehavior: paintingInfo.paintBehavior, paintFlags: localPaintFlags) {
        // Paint the mask for the fragments.
        paintMaskForFragments(
          layerFragments: layerFragments, context: context, localPaintingInfo: paintingInfo,
          paintBehavior: paintBehavior, subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }

      if applySVGClippingMask
        || (!paintFlags.contains(.PaintingCompositingMaskPhase)
          && paintFlags.contains(.PaintingCompositingClipPathPhase))
      {
        // Re-use paintChildClippingMaskForFragments to paint black for the compositing clipping mask.
        paintChildClippingMaskForFragments(
          layerFragments: layerFragments, context: context, localPaintingInfo: paintingInfo,
          paintBehavior: paintBehavior, subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }

      if localPaintFlags.contains(.PaintingChildClippingMaskPhase) {
        // Paint the border radius mask for the fragments.
        paintChildClippingMaskForFragments(
          layerFragments: layerFragments, context: context, localPaintingInfo: paintingInfo,
          paintBehavior: paintBehavior, subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }
    }

    // End our transparency layer
    if haveTransparency && usedTransparency && !paintingInsideReflection {
      if let savedAlphaForTransparency = self.savedAlphaForTransparency {
        context.setAlpha(alpha: savedAlphaForTransparency)
        self.savedAlphaForTransparency = nil
      } else {
        context.endTransparencyLayer()
        context.restore()
      }
      usedTransparency = false
    }

    // Re-set this to whatever it was before we painted the layer.
    if needToAdjustSubpixelQuantization {
      context.setShouldSubpixelQuantizeFonts(shouldSubpixelQuantizeFonts: didQuantizeFonts)
    }
  }

  private func paintLayerHasVisibleContent() -> Bool {
    assert(isNativeImpl())
    if !hasVisibleContent {
      return false
    }

    if enclosingSVGHiddenOrResourceContainer == nil {
      return true
    }

    // Hidden SVG containers (<defs> / <symbol> ...) and their children are never painted directly.
    if !(enclosingSVGHiddenOrResourceContainer is RenderSVGResourceContainerWrapper) {
      return false
    }

    // SVG resource layers and their children are only painted indirectly, via paintSVGResourceLayer().
    assert(enclosingSVGHiddenOrResourceContainer!.hasLayer())
    return enclosingSVGHiddenOrResourceContainer!.layer()!.isPaintingSVGResourceLayer
  }

  private func paintBehaviorForContents(
    paintingInfo: LayerPaintingInfo, localPaintFlags: PaintLayerFlag,
    isPaintingOverflowContents: Bool, isCollectingEventRegion: Bool,
    isPaintingCompositedForeground: Bool, isPaintingCompositedBackground: Bool
  ) -> PaintBehavior {
    assert(isNativeImpl())
    let flagsToCopy: PaintBehavior = [
      .FlattenCompositingLayers, .Snapshotting, .ExcludeSelection, .ExcludeReplacedContent,
    ]
    var paintBehavior = paintingInfo.paintBehavior.intersection(flagsToCopy)

    if localPaintFlags.contains(.PaintingSkipRootBackground) {
      paintBehavior.update(with: .SkipRootBackground)
    } else if localPaintFlags.contains(.PaintingRootBackgroundOnly) {
      paintBehavior.update(with: .RootBackgroundOnly)
    }

    // FIXME: This seems wrong. We should retain the DefaultAsynchronousImageDecode flag for all RenderLayers painted into the root tile cache.
    if paintingInfo.paintBehavior.contains(.DefaultAsynchronousImageDecode) && isRenderViewLayer {
      paintBehavior.update(with: .DefaultAsynchronousImageDecode)
    }

    if isPaintingOverflowContents {
      paintBehavior.update(with: .CompositedOverflowScrollContent)
    }

    if isCollectingEventRegion {
      paintBehavior = paintBehavior.intersection([.CompositedOverflowScrollContent])
      if isPaintingCompositedForeground {
        paintBehavior.update(with: .EventRegionIncludeForeground)
      }
      if isPaintingCompositedBackground {
        paintBehavior.update(with: .EventRegionIncludeBackground)
      }
    }

    return paintBehavior
  }

  private func paintList(
    layerIterator: LayerList, context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo,
    paintFlags: PaintLayerFlag
  ) {
    assert(isNativeImpl())
    if layerIterator.size() == 0 {
      return
    }

    if !hasSelfPaintingLayerDescendant {
      return
    }

    // TODO(asuhan): mutation checker

    for childLayer in layerIterator {
      if paintFlags.contains(.PaintingSkipDescendantViewTransition) {
        if childLayer.renderer().effectiveCapturedInViewTransition() {
          continue
        }
        if childLayer.renderer().isViewTransitionPseudo() {
          continue
        }
      }
      childLayer.paintLayer(context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
    }
  }

  private func updatePaintingInfoForFragments(
    fragments: inout LayerFragments, localPaintingInfo: LayerPaintingInfo,
    localPaintFlags: PaintLayerFlag, shouldPaintContent: Bool, offsetFromRoot: LayoutSizeWrapper
  ) {
    assert(isNativeImpl())
    for fragment in fragments {
      fragment.shouldPaintContent = shouldPaintContent
      if CPtrToInt(layerId()) != CPtrToInt(localPaintingInfo.rootLayer?.layerId())
        || !localPaintFlags.contains(.PaintingOverflowContents)
      {
        let newOffsetFromRoot = offsetFromRoot + fragment.paginationOffset
        fragment.shouldPaintContent =
          fragment.shouldPaintContent
          && intersectsDamageRect(
            layerBounds: fragment.layerBounds, damageRect: fragment.backgroundRect.rect,
            rootLayer: localPaintingInfo.rootLayer,
            offsetFromRoot: newOffsetFromRoot, cachedBoundingBox: fragment.boundingBox)
      }
    }
  }

  private func paintBackgroundForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    contextForTransparencyLayer: GraphicsContextWrapper,
    transparencyPaintDirtyRect: LayoutRectWrapper, haveTransparency: Bool,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    assert(isNativeImpl())
    for fragment in layerFragments {
      if !fragment.shouldPaintContent {
        continue
      }

      // Begin transparency layers lazily now that we know we have to paint something.
      if haveTransparency {
        beginTransparencyLayers(
          context: contextForTransparencyLayer, paintingInfo: localPaintingInfo,
          dirtyRect: transparencyPaintDirtyRect)
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if localPaintingInfo.clipToDirtyRect {
        // Paint our background first, before painting any child layers.
        // Establish the clip used to paint our background.
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior,
          clipRect: fragment.backgroundRect, rule: .DoNotIncludeSelfForBorderRadius)  // Background painting will handle clipping to self.
      }

      // Paint the background.
      // FIXME: Eventually we will collect the region from the fragment itself instead of just from the paint info.
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .BlockBackground,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)
      renderer().paint(
        paintInfo: &paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintForegroundForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    contextForTransparencyLayer: GraphicsContextWrapper,
    transparencyPaintDirtyRect: LayoutRectWrapper, haveTransparency: Bool,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    assert(isNativeImpl())
    // Begin transparency if we have something to paint.
    if haveTransparency {
      for fragment in layerFragments {
        if fragment.shouldPaintContent && !fragment.foregroundRect.isEmpty() {
          beginTransparencyLayers(
            context: contextForTransparencyLayer, paintingInfo: localPaintingInfo,
            dirtyRect: transparencyPaintDirtyRect)
          break
        }
      }
    }

    var localPaintBehavior = PaintBehavior()
    if localPaintingInfo.paintBehavior.contains(.ForceBlackText) {
      localPaintBehavior = PaintBehavior.ForceBlackText
    } else if localPaintingInfo.paintBehavior.contains(.ForceWhiteText) {
      localPaintBehavior = PaintBehavior.ForceWhiteText
    } else {
      localPaintBehavior = paintBehavior
    }

    // FIXME: It's unclear if this flag copying is necessary.
    let flagsToCopy = PaintBehavior([
      .ExcludeSelection, .Snapshotting, .DefaultAsynchronousImageDecode,
      .CompositedOverflowScrollContent, .ForceSynchronousImageDecode, .ExcludeReplacedContent,
    ])
    localPaintBehavior = localPaintBehavior.union(
      localPaintingInfo.paintBehavior.intersection(flagsToCopy))

    if localPaintingInfo.paintBehavior.contains(.DontShowVisitedLinks) {
      localPaintBehavior.update(with: .DontShowVisitedLinks)
    }

    let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
    let regionContextStateSaver = RegionContextStateSaver(context: localPaintingInfo.regionContext)

    // Optimize clipping for the single fragment case.
    let shouldClip =
      localPaintingInfo.clipToDirtyRect && layerFragments.count == 1
      && layerFragments[0].shouldPaintContent && !layerFragments[0].foregroundRect.isEmpty()
    if shouldClip {
      clipToRect(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        clipRect: layerFragments[0].foregroundRect)
    }

    // We have to loop through every fragment multiple times, since we have to repaint in each specific phase in order for
    // interleaving of the fragments to work properly.
    let selectionOnly = localPaintingInfo.paintBehavior.contains(.SelectionOnly)
    let selectionAndBackgroundsOnly = localPaintingInfo.paintBehavior.contains(
      .SelectionAndBackgroundsOnly)

    if (renderer() is RenderSVGModelObjectWrapper) && !(renderer() is RenderSVGContainerWrapper) {
      // SVG containers need to propagate paint phases. This could be saved if we remember somewhere if a SVG subtree
      // contains e.g. LegacyRenderSVGForeignObject objects that do need the individual paint phases. For SVG shapes & SVG images
      // we can avoid the multiple paintForegroundForFragmentsWithPhase() calls.
      if selectionOnly || selectionAndBackgroundsOnly {
        return
      }
      paintForegroundForFragmentsWithPhase(
        phase: .Foreground, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      return
    }

    if !selectionOnly {
      paintForegroundForFragmentsWithPhase(
        phase: .ChildBlockBackgrounds, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
    }

    if selectionOnly || selectionAndBackgroundsOnly {
      paintForegroundForFragmentsWithPhase(
        phase: .Selection, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
    } else {
      paintForegroundForFragmentsWithPhase(
        phase: .Float, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      paintForegroundForFragmentsWithPhase(
        phase: .Foreground, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      paintForegroundForFragmentsWithPhase(
        phase: .ChildOutlines, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
    }
  }

  private func paintForegroundForFragmentsWithPhase(
    phase: PaintPhase, layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    assert(isNativeImpl())
    let shouldClip = localPaintingInfo.clipToDirtyRect && layerFragments.count > 1

    for fragment in layerFragments {
      if !fragment.shouldPaintContent || fragment.foregroundRect.isEmpty() {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if shouldClip {
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior, clipRect: fragment.foregroundRect)
      }

      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.foregroundRect.rect, newPhase: phase,
        newPaintBehavior: paintBehavior, newSubtreePaintRoot: subtreePaintRootForRenderer,
        newOutlineObjects: nil, overlapTestRequests: nil,
        newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self,
        newRequireSecurityOriginAccessForWidgets: localPaintingInfo
          .requireSecurityOriginAccessForWidgets)
      if phase == .Foreground {
        paintInfo.overlapTestRequests = localPaintingInfo.overlapTestRequests
      }
      renderer().paint(
        paintInfo: &paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintOutlineForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    assert(isNativeImpl())
    for fragment in layerFragments {
      if fragment.backgroundRect.isEmpty() {
        continue
      }

      // Paint our own outline
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .SelfOutline,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      clipToRect(
        context: context, stateSaver: stateSaver,
        regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
        paintBehavior: paintBehavior,
        clipRect: fragment.backgroundRect, rule: .DoNotIncludeSelfForBorderRadius)
      renderer().paint(
        paintInfo: &paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintOverflowControlsForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo
  ) {
    assert(isNativeImpl())
    assert(m_scrollableArea != nil)

    for fragment in layerFragments {
      if fragment.backgroundRect.isEmpty() {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      clipToRect(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: localPaintingInfo, paintBehavior: [], clipRect: fragment.backgroundRect)
      m_scrollableArea!.paintOverflowControls(
        context: context,
        paintOffset: roundedIntPoint(
          point: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo)),
        damageRect: snappedIntRect(rect: fragment.backgroundRect.rect),
        paintingOverlayControls: true)
    }
  }

  private func paintMaskForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    assert(isNativeImpl())
    for fragment in layerFragments {
      if !fragment.shouldPaintContent {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if localPaintingInfo.clipToDirtyRect {
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior,
          clipRect: fragment.backgroundRect, rule: .DoNotIncludeSelfForBorderRadius)  // Mask painting will handle clipping to self.
      }

      // Paint the mask.
      // FIXME: Eventually we will collect the region from the fragment itself instead of just from the paint info.
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .Mask,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)
      renderer().paint(
        paintInfo: &paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintChildClippingMaskForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    assert(isNativeImpl())
    for fragment in layerFragments {
      if !fragment.shouldPaintContent {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if localPaintingInfo.clipToDirtyRect {
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior,
          clipRect: fragment.foregroundRect, rule: .IncludeSelfForBorderRadius)  // Child clipping mask painting will handle clipping to self.
      }

      // Paint the clipped mask.
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .ClippingMask,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)
      renderer().paint(
        paintInfo: &paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintTransformedLayerIntoFragments(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    assert(isNativeImpl())
    let paginatedLayer = enclosingPaginationLayer(mode: .ExcludeCompositedPaginatedLayers)!
    let transformedExtent = RenderLayerWrapper.transparencyClipBox(
      layer: self, rootLayer: paginatedLayer, transparencyBehavior: .PaintingTransparencyClipBox,
      transparencyMode: .RootOfTransparencyClipBox,
      paintBehavior: paintingInfo.paintBehavior)

    let clipRectOptions =
      paintFlags.contains(.PaintingOverflowContents)
      ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
      : RenderLayerWrapper.clipRectDefaultOptions
    var enclosingPaginationFragments: LayerFragments = []
    paginatedLayer.collectFragments(
      fragments: &enclosingPaginationFragments, rootLayer: paintingInfo.rootLayer,
      dirtyRect: paintingInfo.paintDirtyRect,
      inclusionMode: .ExcludeCompositedPaginatedLayers,
      clipRectsType: paintFlags.contains(.TemporaryClipRects)
        ? .TemporaryClipRects : .PaintingClipRects,
      clipRectOptions: clipRectOptions, offsetFromRoot: LayoutSizeWrapper(),
      layerBoundingBox: transformedExtent)

    var offsetOfPaginationLayerFromRoot = LayoutSizeWrapper()
    for fragment in enclosingPaginationFragments {
      // Apply the page/column clip for this fragment, as well as any clips established by layers in between us and
      // the enclosing pagination layer.
      var clipRect = fragment.backgroundRect.rect

      // Now compute the clips within a given fragment
      if CPtrToInt(parent()?.layerId()) != CPtrToInt(paginatedLayer.layerId()) {
        offsetOfPaginationLayerFromRoot = toLayoutSize(
          point: paginatedLayer.convertToLayerCoords(
            ancestorLayer: paintingInfo.rootLayer,
            location: toLayoutPoint(size: offsetOfPaginationLayerFromRoot)))

        let clipRectsContext = ClipRectsContext(
          inRootLayer: paginatedLayer,
          inClipRectsType: paintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects, inOptions: clipRectOptions)
        var parentClipRect = backgroundClipRect(clipRectsContext: clipRectsContext).rect
        parentClipRect.move(size: fragment.paginationOffset + offsetOfPaginationLayerFromRoot)
        clipRect.intersect(other: parentClipRect)
      }

      var paintBehavior: PaintBehavior = .Normal
      if paintFlags.contains(.PaintingOverflowContents) {
        paintBehavior.update(with: .CompositedOverflowScrollContent)
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)

      parent()!.clipToRect(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: paintingInfo, paintBehavior: paintBehavior, clipRect: ClipRect(rect: clipRect)
      )
      paintLayerByApplyingTransform(
        context: context, paintingInfo: paintingInfo, paintFlags: paintFlags,
        translationOffset: fragment.paginationOffset)
    }
  }

  private func collectEventRegionForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior
  ) {
    assert(isNativeImpl())
    assert(localPaintingInfo.regionContext is EventRegionContext)
    for fragment in layerFragments {
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.foregroundRect.rect, newPhase: .EventRegion,
        newPaintBehavior: paintBehavior)
      paintInfo.regionContext = localPaintingInfo.regionContext
      if localPaintingInfo.clipToDirtyRect {  // clip-path?
        paintInfo.regionContext!.pushClip(
          clipRect: enclosingIntRect(rect: fragment.backgroundRect.rect))
      }

      renderer().paint(
        paintInfo: &paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
      if localPaintingInfo.clipToDirtyRect {
        paintInfo.regionContext!.popClip()
      }
    }
  }

  private func collectAccessibilityRegionsForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior
  ) {
    assert(isNativeImpl())
    assert(localPaintingInfo.regionContext is AccessibilityRegionContext)
    for fragment in layerFragments {
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.foregroundRect.rect, newPhase: .Accessibility,
        newPaintBehavior: paintBehavior)
      paintInfo.regionContext = localPaintingInfo.regionContext
      renderer().paint(
        paintInfo: &paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func transparentPaintingAncestor(info: LayerPaintingInfo) -> RenderLayerWrapper? {
    assert(isNativeImpl())
    if CPtrToInt(layerId()) == CPtrToInt(info.rootLayer?.layerId()) || isComposited()
      || paintsIntoProvidedBacking()
    {
      return nil
    }
    var ancestor = parent()
    while ancestor != nil {
      if ancestor!.isStackingContext() {
        if ancestor!.isComposited() || ancestor!.paintsIntoProvidedBacking() {
          return nil
        }
        if ancestor!.isTransparent() {
          return ancestor
        }
      }
      if CPtrToInt(ancestor?.layerId()) == CPtrToInt(info.rootLayer?.layerId()) {
        return nil
      }
      ancestor = ancestor!.parent()
    }
    return nil
  }

  private static func expandClipRectForDescendantsAndReflection(
    clipRect: inout LayoutRectWrapper, layer: RenderLayerWrapper, rootLayer: RenderLayerWrapper?,
    transparencyBehavior: TransparencyClipBoxBehavior, paintBehavior: PaintBehavior,
    paintDirtyRect: LayoutRectWrapper?
  ) {
    // If we have a mask, then the clip is limited to the border box area (and there is
    // no need to examine child layers).
    if !layer.renderer().hasMask() {
      // Note: we don't have to walk z-order lists since transparent elements always establish
      // a stacking container. This means we can just walk the layer tree directly.
      var curr = layer.firstChild()
      while curr != nil {
        if !layer.isReflectionLayer(layer: curr!) {
          clipRect.unite(
            other:
              transparencyClipBox(
                layer: curr!, rootLayer: rootLayer, transparencyBehavior: transparencyBehavior,
                transparencyMode: .DescendantsOfTransparencyClipBox, paintBehavior: paintBehavior,
                paintDirtyRect: paintDirtyRect))
        }
        curr = curr!.nextSibling()
      }
    }

    // If we have a reflection, then we need to account for that when we push the clip.  Reflect our entire
    // current transparencyClipBox to catch all child layers.
    // FIXME: Accelerated compositing will eventually want to do something smart here to avoid incorporating this
    // size into the parent layer.
    if layer.renderer().isRenderBox() && layer.renderer().hasReflection() {
      let delta = layer.offsetFromAncestor(ancestorLayer: rootLayer)
      clipRect.move(size: -delta)
      clipRect.unite(other: layer.renderBox()!.reflectedRect(r: clipRect))
      clipRect.move(size: delta)
    }
  }

  private static func transparencyClipBox(
    layer: RenderLayerWrapper, rootLayer: RenderLayerWrapper?,
    transparencyBehavior: TransparencyClipBoxBehavior, transparencyMode: TransparencyClipBoxMode,
    paintBehavior: PaintBehavior = [], paintDirtyRect: LayoutRectWrapper? = nil
  )
    -> LayoutRectWrapper
  {
    // FIXME: Although this function completely ignores CSS-imposed clipping, we did already intersect with the
    // paintDirtyRect, and that should cut down on the amount we have to paint.  Still it
    // would be better to respect clips.

    if CPtrToInt(rootLayer?.layerId()) == CPtrToInt(layer.layerId())
      && ((transparencyBehavior == .PaintingTransparencyClipBox
        && layer.paintsWithTransform(paintBehavior: paintBehavior))
        || (transparencyBehavior == .HitTestingTransparencyClipBox && layer.isTransformed()))
    {
      // The best we can do here is to use enclosed bounding boxes to establish a "fuzzy" enough clip to encompass
      // the transformed layer and all of its children.
      let mode: PaginationInclusionMode =
        transparencyBehavior == .HitTestingTransparencyClipBox
        ? .IncludeCompositedPaginatedLayers : .ExcludeCompositedPaginatedLayers
      let paginationLayer =
        transparencyMode == .DescendantsOfTransparencyClipBox
        ? layer.enclosingPaginationLayer(mode: mode) : nil
      let rootLayerForTransform = paginationLayer != nil ? paginationLayer : rootLayer
      let delta = layer.offsetFromAncestor(ancestorLayer: rootLayerForTransform)

      let transform = TransformationMatrix()
      transform.translate(tx: delta.width().double(), ty: delta.height().double())
      transform.multiply(mat: layer.transform!)

      // We don't use fragment boxes when collecting a transformed layer's bounding box, since it always
      // paints unfragmented.
      var clipRect = layer.boundingBox(ancestorLayer: layer)
      expandClipRectForDescendantsAndReflection(
        clipRect: &clipRect, layer: layer, rootLayer: layer,
        transparencyBehavior: transparencyBehavior, paintBehavior: paintBehavior,
        paintDirtyRect: paintDirtyRect)
      clipRect.expand(box: toLayoutBoxExtent(extent: layer.filterOutsets()))
      var result = transform.mapRect(clipRect)
      if let paginationLayer = paginationLayer {
        // We have to break up the transformed extent across our columns.
        // Split our box up into the actual fragment boxes that render in the columns/pages and unite those together to
        // get our true bounding box.
        let enclosingFragmentedFlow = paginationLayer.renderer() as! RenderFragmentedFlowWrapper
        result = enclosingFragmentedFlow.fragmentsBoundingBox(layerBoundingBox: result)
        result.move(size: paginationLayer.offsetFromAncestor(ancestorLayer: rootLayer))
      }
      if let paintDirtyRect = paintDirtyRect {
        result = intersection(a: result, b: paintDirtyRect)
      }
      return result
    }

    var flags: CalculateLayerBoundsFlag =
      transparencyBehavior == .HitTestingTransparencyClipBox
      ? .UseFragmentBoxesIncludingCompositing : .UseFragmentBoxesExcludingCompositing
    flags.update(with: .IncludeRootBackgroundPaintingArea)
    var clipRect = layer.boundingBox(
      ancestorLayer: rootLayer, offsetFromRoot: layer.offsetFromAncestor(ancestorLayer: rootLayer),
      flags: flags)
    expandClipRectForDescendantsAndReflection(
      clipRect: &clipRect, layer: layer, rootLayer: rootLayer,
      transparencyBehavior: transparencyBehavior, paintBehavior: paintBehavior,
      paintDirtyRect: paintDirtyRect)
    clipRect.expand(box: toLayoutBoxExtent(extent: layer.filterOutsets()))

    if let paintDirtyRect = paintDirtyRect {
      clipRect = intersection(a: clipRect, b: paintDirtyRect)
    }

    return clipRect
  }

  private func beginTransparencyLayers(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, dirtyRect: LayoutRectWrapper
  ) {
    assert(isNativeImpl())
    if context.paintingDisabled()
      || (paintsWithTransparency(paintBehavior: paintingInfo.paintBehavior) && usedTransparency)
    {
      return
    }

    if let ancestor = transparentPaintingAncestor(info: paintingInfo) {
      ancestor.beginTransparencyLayers(
        context: context, paintingInfo: paintingInfo, dirtyRect: dirtyRect)
    }

    if paintsWithTransparency(paintBehavior: paintingInfo.paintBehavior) {
      assert(isStackingContext())
      usedTransparency = true
      if canPaintTransparencyWithSetOpacity() {
        savedAlphaForTransparency = context.alpha()
        context.setAlpha(alpha: context.alpha() * renderer().opacity())
        return
      }
      context.save()
      var adjustedClipRect = RenderLayerWrapper.transparencyClipBox(
        layer: self, rootLayer: paintingInfo.rootLayer,
        transparencyBehavior: .PaintingTransparencyClipBox,
        transparencyMode: .RootOfTransparencyClipBox,
        paintBehavior: paintingInfo.paintBehavior, paintDirtyRect: dirtyRect)
      adjustedClipRect.move(size: paintingInfo.subpixelOffset)
      let snappedClipRect = snapRectToDevicePixelsIfNeeded(
        rect: adjustedClipRect, renderer: renderer())
      context.clip(rect: snappedClipRect)

      let usesCompositeOperation =
        hasBlendMode()
        && !(renderer().isLegacyRenderSVGRoot() && parent() != nil && parent()!.isRenderViewLayer)
      if usesCompositeOperation {
        context.setCompositeOperation(operation: context.compositeOperation(), blendMode: blendMode)
      }

      context.beginTransparencyLayer(opacity: renderer().opacity())

      if usesCompositeOperation {
        context.setCompositeOperation(operation: context.compositeOperation(), blendMode: .Normal)
      }
    }
  }

  private struct HitLayer {
    let layer: RenderLayerWrapper?
    let zOffset: Float64 = 0
  }
  private func hitTestLayer(
    rootLayer: RenderLayerWrapper?, containerLayer: RenderLayerWrapper?,
    _ request: HitTestRequestWrapper, _ result: HitTestResultWrapper,
    _ hitTestRect: LayoutRectWrapper, _ hitTestLocation: HitTestLocationWrapper,
    _ appliedTransform: Bool, _ transformState: HitTestingTransformState? = nil,
    _ zOffset: Float64? = nil
  ) -> HitLayer {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func listBackgroundIsKnownToBeOpaqueInRect(
    _ list: LayerList, _ localRect: LayoutRectWrapper
  ) -> Bool {
    assert(isNativeImpl())
    if list.size() == 0 {
      return false
    }

    for childLayer in list.reversed() {
      if childLayer.isComposited() {
        continue
      }

      if !childLayer.canUseOffsetFromAncestor() {
        continue
      }

      var childLocalRect = localRect
      childLocalRect.move(size: -childLayer.offsetFromAncestor(ancestorLayer: self))

      if childLayer.backgroundIsKnownToBeOpaqueInRect(childLocalRect) {
        return true
      }
    }
    return false
  }

  private func shouldBeSelfPaintingLayer() -> Bool {
    assert(isNativeImpl())
    if !isNormalFlowOnly {
      return true
    }

    return hasOverlayScrollbars()
      || hasCompositedScrollableOverflow()
      || renderer().isRenderTableRow()
      || renderer().isRenderHTMLCanvas()
      || renderer().isRenderVideo()
      || renderer().isRenderEmbeddedObject()
      || renderer().isRenderIFrame()
      || renderer().isRenderFragmentedFlow()
  }

  private func dirtyAncestorChainVisibleDescendantStatus() {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if layer!.visibleDescendantStatusDirty {
        break
      }

      layer!.visibleDescendantStatusDirty = true
      layer = layer!.parent()
    }
  }

  private func computeHasVisibleContent() -> Bool {
    assert(isNativeImpl())
    if renderer().isAnonymous() && renderer() is RenderSVGViewportContainerWrapper {
      return false
    }

    if isHiddenByOverflowTruncation {
      return false
    }

    if renderer().isSkippedContent() {
      return false
    }

    if renderer().style().usedVisibility() == .Visible {
      return true
    }

    // Layer's renderer has visibility:hidden, but some non-layer child may have visibility:visible.
    var r = renderer().firstChild()
    while r != nil {
      if r!.style().usedVisibility() == .Visible && !r!.hasLayer() {
        return true
      }

      if !r!.hasLayer(), let child = r!.firstChildSlow() {
        r = child
      } else if r!.nextSibling() != nil {
        r = r!.nextSibling()
      } else {
        repeat {
          r = r!.parent()
          if CPtrToInt(r?.id()) == CPtrToInt(renderer().id()) {
            r = nil
          }
        } while r != nil && r!.nextSibling() == nil
        if r != nil {
          r = r!.nextSibling()
        }
      }
    }

    return false
  }

  func dirty3DTransformedDescendantStatus() {
    assert(isNativeImpl())
    var curr: RenderLayerWrapper? = stackingContext()
    if curr != nil {
      curr!.m_3DTransformedDescendantStatusDirty = true
    }

    // This propagates up through preserve-3d hierarchies to the enclosing flattening layer.
    // Note that preserves3D() creates stacking context, so we can just run up the stacking containers.
    while curr != nil && curr!.preserves3D() {
      curr!.m_3DTransformedDescendantStatusDirty = true
      curr = curr!.stackingContext()
    }
  }

  func isInsideSVGForeignObject() -> Bool {
    assert(isNativeImpl())
    return m_insideSVGForeignObject
  }

  private func createReflection() {
    assert(isNativeImpl())
    assert(reflection == nil)
    reflection = RenderReplicaWrapper(
      document: renderer().document(), style: createReflectionStyle())
    // FIXME: A renderer should be a child of its parent!
    reflection!.setParent(parent: renderer())  // We create a 1-way connection.
    reflection!.initializeStyle()
  }

  private func removeReflection() {
    assert(isNativeImpl())
    if !reflection!.renderTreeBeingDestroyed(), let layer = reflection!.layer() {
      removeChild(oldChild: layer)
    }

    reflection!.setParent(parent: nil)
    reflection = nil
  }

  private func createReflectionStyle() -> RenderStyleWrapper {
    assert(isNativeImpl())
    let newStyle = RenderStyleWrapper.create()
    newStyle.inheritFrom(inheritParent: renderer().style())

    // Map in our transform.
    var operations: [TransformOperation] = []

    switch renderer().style().boxReflect()!.direction() {
    case .Below:
      operations = [
        TranslateTransformOperation.create(
          tx: LengthWrapper(value: Int32(0), type: .Fixed),
          ty: LengthWrapper(value: 100.0, type: .Percent),
          type: .Translate),
        TranslateTransformOperation.create(
          tx: LengthWrapper(value: Int32(0), type: .Fixed),
          ty: renderer().style().boxReflect()!.offset(),
          type: .Translate),
        ScaleTransformOperation.create(sx: 1.0, sy: -1.0, type: .Scale),
      ]
    case .Above:
      operations = [
        ScaleTransformOperation.create(sx: 1.0, sy: -1.0, type: .Scale),
        TranslateTransformOperation.create(
          tx: LengthWrapper(value: Int32(0), type: .Fixed),
          ty: LengthWrapper(value: 100.0, type: .Percent),
          type: .Translate),
        TranslateTransformOperation.create(
          tx: LengthWrapper(value: Int32(0), type: .Fixed),
          ty: renderer().style().boxReflect()!.offset(),
          type: .Translate),
      ]
    case .Right:
      operations = [
        TranslateTransformOperation.create(
          tx: LengthWrapper(value: 100.0, type: .Percent),
          ty: LengthWrapper(value: Int32(0), type: .Fixed),
          type: .Translate),
        TranslateTransformOperation.create(
          tx: renderer().style().boxReflect()!.offset(),
          ty: LengthWrapper(value: Int32(0), type: .Fixed), type: .Translate),
        ScaleTransformOperation.create(sx: -1.0, sy: 1.0, type: .Scale),
      ]
    case .Left:
      operations = [
        ScaleTransformOperation.create(sx: -1.0, sy: 1.0, type: .Scale),
        TranslateTransformOperation.create(
          tx: LengthWrapper(value: 100.0, type: .Percent),
          ty: LengthWrapper(value: Int32(0), type: .Fixed),
          type: .Translate),
        TranslateTransformOperation.create(
          tx: renderer().style().boxReflect()!.offset(),
          ty: LengthWrapper(value: Int32(0), type: .Fixed), type: .Translate),
      ]
    }
    newStyle.setTransform(operations: TransformOperations(operations: operations))

    // Map in our mask.
    newStyle.setMaskBorder(image: renderer().style().boxReflect()!.mask())

    // Style has transform and mask, so needs to be stacking context.
    newStyle.setUsedZIndex(index: 0)

    return newStyle
  }

  private func updateFiltersAfterStyleChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    if renderer().style().filter().hasReferenceFilter() {
      ensureLayerFilters()
      filters!.updateReferenceFilterClients(operations: renderer().style().filter())
    } else if !paintsWithFilters() {
      clearLayerFilters()
    } else if let filters = filters {
      filters.removeReferenceFilterClients()
    }

    if diff.rawValue >= StyleDifference.RepaintLayer.rawValue && oldStyle != nil
      && oldStyle!.filter() != renderer().style().filter()
    {
      clearLayerFilters()
    }
  }

  private func updateFilterPaintingStrategy() {
    assert(isNativeImpl())
    // RenderLayerFilters is only used to render the filters in software mode,
    // so we always need to run updateFilterPaintingStrategy() after the composited
    // mode might have changed for this layer.
    if !paintsWithFilters() {
      // Don't delete the whole filter info here, because we might use it
      // for loading SVG reference filter files.
      if filters != nil {
        filters!.clearFilter()
      }

      // Early-return only if we *don't* have reference filters.
      // For reference filters, we still want the FilterEffect graph built
      // for us, even if we're composited.
      if !renderer().style().filter().hasReferenceFilter() {
        return
      }
    }

    ensureLayerFilters()
    filters!.preferredFilterRenderingModes = renderer().page().preferredFilterRenderingModes()
    filters!.filterScale = FloatSize(
      width: page().deviceScaleFactor(), height: page().deviceScaleFactor())
  }

  private func updateAncestorChainHasBlendingDescendants() {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if !layer!.hasNotIsolatedBlendingDescendantsStatusDirty
        && layer!.hasNotIsolatedBlendingDescendants
      {
        break
      }
      layer!.hasNotIsolatedBlendingDescendants = true
      layer!.hasNotIsolatedBlendingDescendantsStatusDirty = false

      layer!.updateSelfPaintingLayer()

      if layer!.isCSSStackingContext() {
        break
      }

      layer = layer!.parent()
    }
  }

  private func dirtyAncestorChainHasBlendingDescendants() {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if layer!.hasNotIsolatedBlendingDescendantsStatusDirty {
        break
      }

      layer!.hasNotIsolatedBlendingDescendantsStatusDirty = true

      layer = layer!.parent()
    }
  }

  private func updateAncestorChainHasIntrinsicallyCompositedDescendants() {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if !layer!.hasIntrinsicallyCompositedDescendantsStatusDirty
        && layer!.hasIntrinsicallyCompositedDescendants
      {
        break
      }
      layer!.hasIntrinsicallyCompositedDescendants = true
      layer!.hasIntrinsicallyCompositedDescendantsStatusDirty = false
      layer = layer!.parent()
    }
  }

  private func dirtyAncestorChainHasIntrinsicallyCompositedDescendants() {
    assert(isNativeImpl())
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if layer!.hasIntrinsicallyCompositedDescendantsStatusDirty {
        break
      }

      layer!.hasIntrinsicallyCompositedDescendantsStatusDirty = true
      layer = layer!.parent()
    }
  }

  private func isIntrinsicallyComposited() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIntrinsicallyComposited(composited: Bool) {
    assert(isNativeImpl())
    if intrinsicallyComposited != composited {
      intrinsicallyComposited = composited
      if composited {
        updateAncestorChainHasIntrinsicallyCompositedDescendants()
      } else {
        dirtyAncestorChainHasIntrinsicallyCompositedDescendants()
      }
      if !hasVisibleContent && !isNormalFlowOnly {
        dirtyHiddenStackingContextAncestorZOrderLists()
      }
    }
  }

  private func parentClipRects(clipRectsContext: ClipRectsContext) -> ClipRects {
    assert(isNativeImpl())
    assert(parent() != nil)

    let containerLayer = parent()!

    if clipRectsContext.clipRectsType == .TemporaryClipRects {
      return RenderLayerWrapper.temporaryParentClipRects(
        clipContext: clipRectsContext, containerLayer: containerLayer)
    }

    if clipRectsContext.clipRectsType != .AbsoluteClipRects && clipCrossesPaintingBoundary() {
      var tempClipRectsContext = clipRectsContext
      tempClipRectsContext.clipRectsType = .TemporaryClipRects
      return RenderLayerWrapper.temporaryParentClipRects(
        clipContext: tempClipRectsContext, containerLayer: containerLayer)
    }

    return containerLayer.updateClipRects(clipRectsContext: clipRectsContext)
  }

  private static func temporaryParentClipRects(
    clipContext: ClipRectsContext, containerLayer: RenderLayerWrapper
  ) -> ClipRects {
    var parentClipRects = ClipRects.create()
    containerLayer.calculateClipRects(clipRectsContext: clipContext, clipRects: &parentClipRects)
    return parentClipRects
  }

  func backgroundClipRect(clipRectsContext: ClipRectsContext) -> ClipRect {
    assert(isNativeImpl())
    assert(parent() != nil)
    let parentRects = parentClipRects(clipRectsContext: clipRectsContext)
    var backgroundClipRect = backgroundClipRectForPosition(
      parentRects: parentRects, position: renderer().style().position())
    let view = renderer().view()
    // Note: infinite clipRects should not be scrolled here, otherwise they will accidentally no longer be considered infinite.
    if parentRects.fixed
      && CPtrToInt(clipRectsContext.rootLayer!.renderer().id()) == CPtrToInt(view.id())
      && !backgroundClipRect.isInfinite()
    {
      backgroundClipRect.moveBy(point: view.frameView().scrollPositionForFixedPosition())
    }

    return backgroundClipRect
  }

  func enclosingTransformedAncestor() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    var curr = parent()
    while curr != nil && !curr!.isRenderViewLayer && curr!.transform == nil {
      curr = curr!.parent()
    }

    return curr
  }

  private func hasNonOpacityTransparency() -> Bool {
    assert(isNativeImpl())
    if renderer().hasMask() {
      return true
    }

    if hasBlendMode() || isolatesBlending() {
      return true
    }

    if !renderer().document().settings().layerBasedSVGEngineEnabled() {
      return false
    }

    // SVG clip-paths may use clipping masks, if so, flag this layer as transparent.
    if let svgClipper = renderer().svgClipperResourceFromStyle(),
      svgClipper.shouldApplyPathClipping() == nil
    {
      return true
    }

    return false
  }

  private func setWasOmittedFromZOrderTree() {
    assert(isNativeImpl())
    if wasOmittedFromZOrderTree {
      return
    }

    assert(!isNormalFlowOnly)
    removeSelfFromCompositor()

    // Omitting a stacking context removes the whole subtree, otherwise collectLayers will
    // visit and omit/include descendants separately.
    if isStackingContext() {
      removeDescendantsFromCompositor()
    }

    if compositor().hasContentCompositingLayers() && parent() != nil {
      parent()!.setDescendantsNeedCompositingRequirementsTraversal()
    }

    wasOmittedFromZOrderTree = true
  }

  private func setWasIncludedInZOrderTree() {
    assert(isNativeImpl())
    wasOmittedFromZOrderTree = false
  }

  private func removeSelfFromCompositor() {
    assert(isNativeImpl())
    if let parent = parent() {
      compositor().layerWillBeRemoved(parent: parent, child: self)
    }
    clearBacking()
  }

  private func removeDescendantsFromCompositor() {
    assert(isNativeImpl())
    var child = firstChild()
    while child != nil {
      child!.removeSelfFromCompositor()
      child!.removeDescendantsFromCompositor()
      child = child!.nextSibling()
    }
  }

  func setHasCompositingDescendant(_ b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasCompositedNonContainedDescendants(_ value: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIndirectCompositingReason(_ reason: IndirectCompositingReason) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func mustCompositeForIndirectReasons() -> Bool {
    assert(isNativeImpl())
    return indirectCompositingReason != .None
  }

  struct OverflowControlRects {
    var horizontalScrollbar = IntRect()
    var verticalScrollbar = IntRect()
    var scrollCorner = IntRect()
    var resizer = IntRect()
    func scrollCornerOrResizerRect() -> IntRect {
      return !scrollCorner.isEmpty() ? scrollCorner : resizer
    }
  }

  func layerId() -> UnsafeMutableRawPointer {
    return pInterop ?? UnsafeMutableRawPointer(
      bitPattern: UInt(bitPattern: ObjectIdentifier(self)))!
  }

  func isNativeImpl() -> Bool { return pInterop == nil }

  private let pInterop: UnsafeMutableRawPointer?
  private let owner: Bool

  // Native fields below.

  private var compositingDirtyBits = Compositing()

  private var savedAlphaForTransparency: Float32? = nil

  var isRenderViewLayer = false
  private var forcedStackingContext = false

  private var isNormalFlowOnly = false
  private var m_isCSSStackingContext = false
  private var canBeBackdropRoot = false
  var hasBackdropFilterDescendantsWithoutRoot = false
  private var isOpportunisticStackingContext = false

  var zOrderListsDirty = false
  var normalFlowListDirty = false
  private var hadNegativeZOrderList = false

  // Keeps track of whether the layer is currently resizing, so events can cause resizing to start and stop.
  private var m_inResizeMode = false

  var isSelfPaintingLayer = false

  // If have no self-painting descendants, we don't have to walk our children during painting. This can lead to
  // significant savings, especially if the tree has lots of non-self-painting layers grouped together (e.g. table cells).
  private var hasSelfPaintingLayerDescendant = false
  private var hasSelfPaintingLayerDescendantDirty = false

  // Tracks whether we need to close a transparent layer, i.e., whether
  // we ended up painting this layer or any descendants (and therefore need to
  // blend).
  private var usedTransparency = false
  private var paintingInsideReflection = false  // A state bit tracking if we are painting inside a replica.
  var repaintStatus: RepaintStatus = .NeedsNormalRepaint

  private var visibleContentStatusDirty = false
  var hasVisibleContent = false
  private var visibleDescendantStatusDirty = false
  var hasVisibleDescendant = false
  private var m_isFixedIntersectingViewport = false
  var behavesAsFixed = false

  private var m_3DTransformedDescendantStatusDirty = false
  // Set on a stacking context layer that has 3D descendants anywhere
  // in a preserves3D hierarchy. Hint to do 3D-aware hit testing.
  private var m_has3DTransformedDescendant = false
  var hasCompositingDescendant = false  // In the z-order tree.
  var hasCompositedNonContainedDescendants = false  // Set when a layer has a composited descendant in z-order which is not a descendant in containing block order (e.g. opacity layer with an abspos descendant).

  var hasCompositedScrollingAncestor = false

  private var m_hasFixedContainingBlockAncestor = false

  private var m_hasTransformedAncestor = false
  var has3DTransformedAncestor = false

  private var m_insideSVGForeignObject = false
  private let isHiddenByOverflowTruncation = false
  private let isPaintingSVGResourceLayer = false

  private var indirectCompositingReason: IndirectCompositingReason = .None
  var viewportConstrainedNotCompositedReason: ViewportConstrainedNotCompositedReason =
    .NoNotCompositedReason

  private var blendMode: BlendMode = .Normal
  var hasNotIsolatedCompositedBlendingDescendants = false
  var hasNotIsolatedBlendingDescendants = false
  private var hasNotIsolatedBlendingDescendantsStatusDirty = false
  private var repaintRectsValid = false

  private var intrinsicallyComposited = false
  private var hasIntrinsicallyCompositedDescendants = false
  private var hasIntrinsicallyCompositedDescendantsStatusDirty = true

  private var wasOmittedFromZOrderTree = false

  private var isSimplifiedLayoutRoot = false

  private let m_renderer: RenderLayerModelObjectWrapper?  // TODO(asuhan): make it non-optional.

  private var m_parent: RenderLayerWrapper? = nil
  private var m_previous: RenderLayerWrapper? = nil
  private var m_next: RenderLayerWrapper? = nil
  private var m_first: RenderLayerWrapper? = nil
  private var m_last: RenderLayerWrapper? = nil

  var backingProviderLayer: RenderLayerWrapper? = nil

  // For layers that establish stacking contexts, m_posZOrderList holds a sorted list of all the
  // descendant layers within the stacking context that have z-indices of 0 or greater
  // (auto will count as 0). negZOrderList holds descendants within our stacking context with negative
  // z-indices.
  private var posZOrderList: [RenderLayerWrapper]? = nil
  private var negZOrderList: [RenderLayerWrapper]? = nil

  // This list contains child layers that cannot create stacking contexts and appear in normal flow order.
  private var normalFlowList: [RenderLayerWrapper]? = nil

  // Only valid if repaintRectsValid is set.
  private var m_repaintRects = RenderObjectWrapper.RepaintRects()

  // Our current relative or absolute position offset.
  private let offsetForPosition = LayoutSizeWrapper()

  // The layer's width/height
  private let layerSize = IntSize()

  private var clipRectsCache: ClipRectsCache? = nil

  // Layers with the same ScrollingScope are scrolled by some common ancestor scroller. Used for async scrolling.
  var boxScrollingScope: ScrollingScope? = nil
  var contentsScrollingScope: ScrollingScope? = nil

  // Note that this transform has the transform-origin baked in.
  var transform: TransformationMatrix? = nil

  // May ultimately be extended to many replicas (with their own paint order).
  private var reflection: RenderReplicaWrapper? = nil

  // Pointer to the enclosing RenderLayer that caused us to be paginated. It is 0 if we are not paginated.
  private let m_enclosingPaginationLayer: RenderLayerWrapper? = nil

  // Pointer to the enclosing RenderSVGHiddenContainer or RenderSVGResourceContainer, if present.
  let enclosingSVGHiddenOrResourceContainer: RenderSVGHiddenContainerWrapper? = nil

  private var filters: RenderLayerFilters? = nil
  var backing: RenderLayerBacking? = nil

  private var m_scrollableArea: RenderLayerScrollableArea? = nil

  private let paintFrequencyTracker = PaintFrequencyTracker()
}
