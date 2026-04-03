/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

import Foundation
import wk_interop

typealias TrackedRendererListHashSet = ListSet<RenderBoxWrapper, UInt>

private typealias TrackedDescendantsMap = [UInt: TrackedRendererListHashSet]
private typealias TrackedContainerMap = HashMap<RenderBoxWrapper, WeakHashSet<RenderBlockWrapper>>?

private var percentHeightDescendantsMap: TrackedDescendantsMap? = nil
private let percentHeightContainerMap: TrackedContainerMap? = nil

enum CaretType {
  case CursorCaret
  case DragCaret
}

enum ContainingBlockState {
  case NewContainingBlock
  case SameContainingBlock
}

private class PositionedDescendantsMap {
  func addDescendant(containingBlock: RenderBlockWrapper, positionedDescendant: RenderBoxWrapper) {
    // Protect against double insert where a descendant would end up with multiple containing blocks.
    let previousContainingBlockRef = containerMap[ObjectIdentifier(positionedDescendant)]
    let previousContainingBlock =
      previousContainingBlockRef != nil ? *(previousContainingBlockRef!) : nil
    if previousContainingBlock != nil
      && CPtrToInt(previousContainingBlock!.id()) != CPtrToInt(containingBlock.id()),
      let descendants = descendantsMap[ObjectIdentifier(previousContainingBlock!)]
    {
      descendants.remove(value: positionedDescendant)
    }

    let maybeDescendants = descendantsMap[ObjectIdentifier(containingBlock)]
    if maybeDescendants == nil {
      descendantsMap[ObjectIdentifier(containingBlock)] = TrackedRendererListHashSet()
    }
    let descendants = descendantsMap[ObjectIdentifier(containingBlock)]!

    var isNewEntry = false
    if !(containingBlock is RenderViewWrapper) || descendants.isEmptyIgnoringNullReferences() {
      isNewEntry = descendants.add(value: positionedDescendant).isNewEntry
    } else if positionedDescendant.isFixedPositioned()
      || isInTopLayerOrBackdrop(
        style: positionedDescendant.style(), element: positionedDescendant.element())
    {
      isNewEntry = descendants.appendOrMoveToLast(value: positionedDescendant).isNewEntry
    } else {
      let ensureLayoutDependBoxPosition = { () in
        // RenderView is a special containing block as it may hold both absolute and fixed positioned containing blocks.
        // When a fixed positioned box is also a descendant of an absolute positioned box anchored to the RenderView,
        // we have to make sure that the absolute positioned box is inserted before the fixed box to follow
        // block layout dependency.
        let it = descendants.begin()
        while it != descendants.end() {
          if (*it).isFixedPositioned() {
            isNewEntry = descendants.insertBefore(it, positionedDescendant).isNewEntry
            return
          }
          ++it
        }
        isNewEntry = descendants.appendOrMoveToLast(value: positionedDescendant).isNewEntry
      }
      ensureLayoutDependBoxPosition()
    }

    if !isNewEntry {
      assert(containerMap[ObjectIdentifier(positionedDescendant)] != nil)
      return
    }
    containerMap[ObjectIdentifier(positionedDescendant)] = WeakNullableRef(containingBlock)
  }

  func removeDescendant(positionedDescendant: RenderBoxWrapper) {
    guard let containingBlock = containerMap[ObjectIdentifier(positionedDescendant)] else { return }

    let descendants = descendantsMap[ObjectIdentifier(*containingBlock)]!
    assert(descendants.contains(value: positionedDescendant))

    descendants.remove(value: positionedDescendant)
    if descendants.isEmptyIgnoringNullReferences() {
      descendantsMap.removeValue(forKey: ObjectIdentifier(*containingBlock))
    }
  }

  func positionedRenderers(_ containingBlock: RenderBlockWrapper) -> TrackedRendererListHashSet? {
    return descendantsMap[ObjectIdentifier(containingBlock)]
  }

  private typealias DescendantsMap = [ObjectIdentifier: TrackedRendererListHashSet]
  private typealias ContainerMap = [ObjectIdentifier: WeakNullableRef<RenderBlockWrapper>]

  private var descendantsMap = DescendantsMap()
  private var containerMap = ContainerMap()
}

private let positionedDescendantsMap = PositionedDescendantsMap()

private func borderOrPaddingLogicalWidthChanged(
  oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
) -> Bool {
  if newStyle.isHorizontalWritingMode() {
    return oldStyle.borderLeftWidth() != newStyle.borderLeftWidth()
      || oldStyle.borderRightWidth() != newStyle.borderRightWidth()
      || oldStyle.paddingLeft() != newStyle.paddingLeft()
      || oldStyle.paddingRight() != newStyle.paddingRight()
  }

  return oldStyle.borderTopWidth() != newStyle.borderTopWidth()
    || oldStyle.borderBottomWidth() != newStyle.borderBottomWidth()
    || oldStyle.paddingTop() != newStyle.paddingTop()
    || oldStyle.paddingBottom() != newStyle.paddingBottom()
}

private func isEditingBoundary(ancestor: RenderElementWrapper?, child: RenderObjectWrapper) -> Bool
{
  assert(ancestor == nil || ancestor!.nonPseudoElement() != nil)
  assert(child.nonPseudoNode() != nil)
  return ancestor == nil || ancestor!.parent() == nil
    || (ancestor!.hasLayer() && ancestor!.parent()!.isRenderView())
    || ancestor!.nonPseudoElement()!.hasEditableStyle() == child.nonPseudoNode()!.hasEditableStyle()
}

// FIXME: This function should go on RenderObject as an instance method. Then
// all cases in which positionForPoint recurs could call this instead to
// prevent crossing editable boundaries. This would require many tests.
func positionForPointRespectingEditingBoundaries(
  _ parent: RenderBlockWrapper, _ child: RenderBoxWrapper,
  _ pointInParentCoordinates: LayoutPointWrapper, _ source: HitTestSource
) -> VisiblePosition {
  var childLocation = child.location()
  if child.isInFlowPositioned() {
    childLocation += child.offsetForInFlowPosition()
  }

  // FIXME: This is wrong if the child's writing-mode is different from the parent's.
  let pointInChildCoordinates = toLayoutPoint(size: pointInParentCoordinates - childLocation)

  // If this is an anonymous renderer, we just recur normally
  guard let childElement = child.nonPseudoElement() else {
    return child.positionForPoint(pointInChildCoordinates, source, nil)
  }

  // Otherwise, first make sure that the editability of the parent and child agree.
  // If they don't agree, then we return a visible position just before or after the child
  var ancestor: RenderElementWrapper? = parent
  while ancestor != nil && ancestor!.nonPseudoElement() == nil {
    ancestor = ancestor!.parent()
  }

  // If we can't find an ancestor to check editability on, or editability is unchanged, we recur like normal
  if isEditingBoundary(ancestor: ancestor, child: child) {
    return child.positionForPoint(pointInChildCoordinates, source, nil)
  }

  // Otherwise return before or after the child, depending on if the click was to the logical left or logical right of the child
  let childMiddle = parent.logicalWidthForChild(child: child) / 2
  let logicalLeft =
    parent.isHorizontalWritingMode() ? pointInChildCoordinates.x : pointInChildCoordinates.y
  if logicalLeft < childMiddle {
    return ancestor!.createVisiblePosition(Int32(childElement.computeNodeIndex()), .Downstream)
  }
  return ancestor!.createVisiblePosition(Int32(childElement.computeNodeIndex() + 1), .Upstream)
}

private func isChildHitTestCandidate(_ box: RenderBoxWrapper, _ source: HitTestSource) -> Bool {
  let visibility = source == .Script ? box.style().visibility() : box.style().usedVisibility()
  return box.height().bool() && visibility == .Visible && !box.isOutOfFlowPositioned()
    && !box.isRenderFragmentedFlow()
}

// Valid candidates in a FragmentedFlow must be rendered by the fragment.
private func isChildHitTestCandidate(
  _ box: RenderBoxWrapper, _ fragment: RenderFragmentContainerWrapper?, _ point: LayoutPointWrapper,
  _ source: HitTestSource
) -> Bool {
  if !isChildHitTestCandidate(box, source) {
    return false
  }
  if fragment == nil {
    return true
  }
  let block = { () in
    if let block = box as? RenderBlockWrapper {
      return block
    }
    return box.containingBlock()!
  }()
  return CPtrToInt(block.fragmentAtBlockOffset(blockOffset: point.y)?.id())
    == CPtrToInt(fragment?.id())
}

private func isRenderBlockFlowOrRenderButton(renderElement: RenderElementWrapper) -> Bool {
  // We include isRenderButton in this check because buttons are implemented
  // using flex box but should still support first-line|first-letter.
  // The flex box and specs require that flex box and grid do not support
  // first-line|first-letter, though.
  // FIXME: Remove when buttons are implemented with align-items instead of
  // flex box.
  return renderElement.isRenderBlockFlow() || renderElement.isRenderButton()
}

private func findFirstLetterBlock(start: RenderBlockWrapper) -> RenderBlockWrapper? {
  var firstLetterBlock: RenderBlockWrapper? = start
  while true {
    let canHaveFirstLetterRenderer =
      firstLetterBlock!.style().hasPseudoStyle(pseudo: .FirstLetter)
      && firstLetterBlock!.canHaveGeneratedChildren()
      && isRenderBlockFlowOrRenderButton(renderElement: firstLetterBlock!)
    if canHaveFirstLetterRenderer {
      return firstLetterBlock
    }

    let parentBlock = firstLetterBlock!.parent()
    if firstLetterBlock!.isReplacedOrInlineBlock() || parentBlock == nil
      || CPtrToInt(parentBlock!.firstChild()?.id()) != CPtrToInt(firstLetterBlock!.id())
      || !isRenderBlockFlowOrRenderButton(renderElement: parentBlock!)
    {
      return nil
    }
    firstLetterBlock = parentBlock as! RenderBlockWrapper?
  }
}

private func canComputeFragmentRangeForBox(
  parentBlock: RenderBlockWrapper, childBox: RenderBoxWrapper,
  enclosingFragmentedFlow: RenderFragmentedFlowWrapper?
) -> Bool {
  if enclosingFragmentedFlow == nil {
    return false
  }

  if !enclosingFragmentedFlow!.hasFragments() {
    return false
  }

  if !childBox.canHaveOutsideFragmentRange() {
    return false
  }

  return enclosingFragmentedFlow!.hasCachedFragmentRangeForBox(box: parentBlock)
}

struct TextRunFlags: OptionSet {
  let rawValue: UInt8

  static let DefaultTextRunFlags = TextRunFlags([])
  static let RespectDirection = TextRunFlags(rawValue: 1 << 0)
  static let RespectDirectionOverride = TextRunFlags(rawValue: 1 << 1)
}

// Allocated only when some of these fields have non-default values

class RenderBlockRareData {
  var m_paginationStrut = LayoutUnit()
  let m_intrinsicBorderForFieldset = LayoutUnit()
}

class RenderBlockWrapper: RenderBoxWrapper {
  override init(
    _ type: RenderObjectWrapper.`Type`, _ document: Document, _ style: RenderStyleWrapper,
    _ baseTypeFlags: RenderObjectWrapper.TypeFlag,
    _ typeSpecificFlags: RenderObjectWrapper.TypeSpecificFlags =
      RenderObjectWrapper.TypeSpecificFlags()
  ) {
    super.init(type, document, style, baseTypeFlags.union(.IsRenderBlock), typeSpecificFlags)
    assert(isRenderBlock())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  // These two functions are overridden for inline-block.
  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    assert(isNativeImpl())
    // Inline blocks are replaced elements. Otherwise, just pass off to
    // the base class.  If we're being queried as though we're the root line
    // box, then the fact that we're an inline-block is irrelevant, and we behave
    // just like a block.
    if isReplacedOrInlineBlock() && linePositionMode == .PositionOnContainingLine {
      return super.lineHeight(
        firstLine: firstLine, direction: direction, linePositionMode: linePositionMode)
    }

    let lineStyle = firstLine ? firstLineStyle() : style()
    return LayoutUnit.fromFloatCeil(value: lineStyle.computedLineHeight())
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
  func deleteLines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutBlock(
    relayoutChildren: Bool, pageLogicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) { fatalError("Not reached") }

  func insertPositionedObject(positioned: RenderBoxWrapper) {
    assert(isNativeImpl())
    assert(!isAnonymousBlock())

    positioned.clearOverridingContainingBlockContentSize()

    if positioned.isRenderFragmentedFlow() {
      return
    }
    // FIXME: Find out if we can do this as part of positioned.setChildNeedsLayout(MarkOnlyThis)
    if positioned.needsLayout() {
      // We should turn this bit on only while in layout.
      assert(posChildNeedsLayout() || view().frameView().layoutContext().isInLayout())
      setPosChildNeedsLayoutBit(b: true)
    }
    positionedDescendantsMap.addDescendant(containingBlock: self, positionedDescendant: positioned)
  }

  static func removePositionedObject(rendererToRemove: RenderBoxWrapper) {
    positionedDescendantsMap.removeDescendant(positionedDescendant: rendererToRemove)
  }

  func removePositionedObjects(
    newContainingBlockCandidate: RenderBlockWrapper?,
    containingBlockState: ContainingBlockState = .SameContainingBlock
  ) {
    assert(isNativeImpl())
    let positionedDescendants = positionedObjects()
    if positionedDescendants == nil {
      return
    }

    var renderersToRemove: [RenderBoxWrapper] = []
    for renderer in positionedDescendants! {
      if newContainingBlockCandidate != nil
        && !renderer.isDescendantOf(ancestor: newContainingBlockCandidate!)
      {
        continue
      }
      renderersToRemove.append(renderer)
      if containingBlockState == .NewContainingBlock {
        renderer.setChildNeedsLayout(markParents: .MarkOnlyThis)
        if renderer.needsPreferredWidthsRecalculation() {
          renderer.setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)
        }
      }
      // It is the parent block's job to add positioned children to positioned objects list of its containing block.
      // Dirty the parent to ensure this happens. We also need to make sure the new containing block is dirty as well so
      // that it gets to these new positioned objects.
      var parent = renderer.parent()
      while parent != nil && !(parent is RenderBlockWrapper) {
        parent = parent!.parent()
      }
      if parent != nil {
        parent!.setChildNeedsLayout()
      }

      if renderer.isFixedPositioned() {
        view().setNeedsLayout()
      } else {
        var newContainingBlock = containingBlock()
        // During style change, at this point the renderer's containing block is still "this" renderer, and "this" renderer is still positioned.
        // FIXME: During subtree moving, this is mostly invalid but either the subtree is detached (we don't even get here) or renderers
        // are already marked dirty.
        while newContainingBlock != nil
          && !newContainingBlock!.canContainAbsolutelyPositionedObjects()
        {
          newContainingBlock = newContainingBlock!.containingBlock()
        }
        if newContainingBlock != nil {
          newContainingBlock!.setNeedsLayout()
        }
      }
    }
    for renderer in renderersToRemove {
      RenderBlockWrapper.removePositionedObject(rendererToRemove: renderer)
    }
  }

  func positionedObjects() -> TrackedRendererListHashSet? {
    assert(isNativeImpl())
    return positionedDescendantsMap.positionedRenderers(self)
  }

  func hasPositionedObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addPercentHeightDescendant(descendant: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func removePercentHeightDescendant(descendant: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func percentHeightDescendants() -> TrackedRendererListHashSet? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasPercentHeightDescendants() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func hasPercentHeightContainerMap() -> Bool { return percentHeightContainerMap != nil }

  static func hasPercentHeightDescendant(descendant: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func clearPercentHeightDescendantsFrom(parent: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func removePercentHeightDescendantIfNeeded(descendant: RenderBoxWrapper) {
    // We query the map directly, rather than looking at style's
    // logicalHeight()/logicalMinHeight()/logicalMaxHeight() since those
    // can change with writing mode/directional changes.
    if !hasPercentHeightContainerMap() {
      return
    }

    if !hasPercentHeightDescendant(descendant: descendant) {
      return
    }

    removePercentHeightDescendant(descendant: descendant)
  }

  func isContainingBlockAncestorFor(renderer: RenderObjectWrapper) -> Bool {
    assert(isNativeImpl())
    var ancestor = renderer.containingBlock()
    while ancestor != nil {
      if CPtrToInt(ancestor!.id()) == CPtrToInt(id()) {
        return true
      }
      ancestor = ancestor!.containingBlock()
    }
    return false
  }

  func setHasMarginBeforeQuirk(b: Bool) {
    assert(isNativeImpl())
    renderBlockHasMarginBeforeQuirk = b
  }

  func setHasMarginAfterQuirk(b: Bool) {
    assert(isNativeImpl())
    renderBlockHasMarginAfterQuirk = b
  }

  func setShouldForceRelayoutChildren(b: Bool) {
    assert(isNativeImpl())
    renderBlockShouldForceRelayoutChildren = b
  }

  func hasMarginBeforeQuirk() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderBlock_hasMarginBeforeQuirk(id())
    }
    return renderBlockHasMarginBeforeQuirk
  }

  func hasMarginAfterQuirk() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderBlock_hasMarginAfterQuirk(id())
    }
    return renderBlockHasMarginAfterQuirk
  }

  private func hasBorderOrPaddingLogicalWidthChanged() -> Bool {
    assert(isNativeImpl())
    return renderBlockShouldForceRelayoutChildren
  }

  func hasMarginBeforeQuirk(child: RenderBoxWrapper) -> Bool {
    assert(isNativeImpl())
    // If the child has the same directionality as we do, then we can just return its
    // margin quirk.
    if !child.isWritingModeRoot() {
      if let childBlock = child as? RenderBlockWrapper {
        return childBlock.hasMarginBeforeQuirk()
      }
      return child.style().marginBefore().hasQuirk()
    }

    // The child has a different directionality. If the child is parallel, then it's just
    // flipped relative to us. We can use the opposite edge.
    if child.isHorizontalWritingMode() == isHorizontalWritingMode() {
      if let childBlock = child as? RenderBlockWrapper {
        return childBlock.hasMarginAfterQuirk()
      }
      return child.style().marginAfter().hasQuirk()
    }

    // The child is perpendicular to us and box sides are never quirky in html.css, and we don't really care about
    // whether or not authors specified quirky ems, since they're an implementation detail.
    return false
  }

  func hasMarginAfterQuirk(child: RenderBoxWrapper) -> Bool {
    assert(isNativeImpl())
    // If the child has the same directionality as we do, then we can just return its
    // margin quirk.
    if !child.isWritingModeRoot() {
      if let childBlock = child as? RenderBlockWrapper {
        return childBlock.hasMarginAfterQuirk()
      }
      return child.style().marginAfter().hasQuirk()
    }

    // The child has a different directionality. If the child is parallel, then it's just
    // flipped relative to us. We can use the opposite edge.
    if child.isHorizontalWritingMode() == isHorizontalWritingMode() {
      if let childBlock = child as? RenderBlockWrapper {
        return childBlock.hasMarginBeforeQuirk()
      }
      return child.style().marginBefore().hasQuirk()
    }

    // The child is perpendicular to us and box sides are never quirky in html.css, and we don't really care about
    // whether or not authors specified quirky ems, since they're an implementation detail.
    return false
  }

  func markPositionedObjectsForLayout() {
    assert(isNativeImpl())
    guard let positionedDescendants = positionedObjects() else { return }

    for descendant in positionedDescendants {
      descendant.setChildNeedsLayout()
    }
  }

  override func markForPaginationRelayoutIfNeeded() {
    if !isNativeImpl() {
      wk_interop.RenderBlock_markForPaginationRelayoutIfNeeded(id())
      return
    }
    let layoutState = view().frameView().layoutContext().layoutState()
    if needsLayout() || layoutState == nil || !layoutState!.isPaginated() {
      return
    }

    if layoutState!.pageLogicalHeightChanged()
      || (layoutState!.pageLogicalHeight().bool()
        && layoutState!.pageLogicalOffset(child: self, childLogicalOffset: logicalTop())
          != pageLogicalOffset())
    {
      setChildNeedsLayout(markParents: .MarkOnlyThis)
    }
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all of the line layout code has been moved out of RenderBlock
  func containsFloats() -> Bool {
    assert(!isNativeImpl())
    return wk_interop.RenderBlock_containsFloats(id())
  }

  // Versions that can compute line offsets with the fragment and page offset passed in. Used for speed to avoid having to
  // compute the fragment all over again when you already know it.
  func availableLogicalWidthForLineInFragment(
    position: LayoutUnit, fragment: RenderFragmentContainerWrapper?,
    logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return max(
      LayoutUnit(value: 0),
      logicalRightOffsetForLineInFragment(position, fragment, logicalHeight)
        - logicalLeftOffsetForLineInFragment(position, fragment, logicalHeight))
  }

  private func logicalRightOffsetForLineInFragment(
    _ position: LayoutUnit, _ fragment: RenderFragmentContainerWrapper?,
    _ logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func logicalLeftOffsetForLineInFragment(
    _ position: LayoutUnit, _ fragment: RenderFragmentContainerWrapper?,
    _ logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func startOffsetForLineInFragment(
    position: LayoutUnit, fragment: RenderFragmentContainerWrapper?,
    logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return style().isLeftToRightDirection()
      ? logicalLeftOffsetForLineInFragment(position, fragment, logicalHeight)
      : logicalWidth() - logicalRightOffsetForLineInFragment(position, fragment, logicalHeight)
  }

  func endOffsetForLineInFragment(
    position: LayoutUnit, fragment: RenderFragmentContainerWrapper?,
    logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return !style().isLeftToRightDirection()
      ? logicalLeftOffsetForLineInFragment(position, fragment, logicalHeight)
      : logicalWidth() - logicalRightOffsetForLineInFragment(position, fragment, logicalHeight)
  }

  func availableLogicalWidthForLine(
    position: LayoutUnit, logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return availableLogicalWidthForLineInFragment(
      position: position, fragment: fragmentAtBlockOffset(blockOffset: position),
      logicalHeight: logicalHeight)
  }

  func logicalRightOffsetForLine(
    position: LayoutUnit, logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalLeftOffsetForLine(
    position: LayoutUnit, logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func startOffsetForLine(
    position: LayoutUnit, logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    assert(isNativeImpl())
    if isRenderTable() {
      return super.positionForPoint(point, source, fragment)
    }

    if isReplacedOrInlineBlock() {
      // FIXME: This seems wrong when the object's writing-mode doesn't match the line's writing-mode.
      let pointLogicalLeft = isHorizontalWritingMode() ? point.x : point.y
      let pointLogicalTop = isHorizontalWritingMode() ? point.y : point.x

      if pointLogicalTop < Int32(0) {
        return createVisiblePosition(caretMinOffset(), .Downstream)
      }
      if pointLogicalLeft >= logicalWidth() {
        return createVisiblePosition(caretMaxOffset(), .Downstream)
      }
      if pointLogicalTop < Int32(0) {
        return createVisiblePosition(caretMinOffset(), .Downstream)
      }
      if pointLogicalTop >= logicalHeight() {
        return createVisiblePosition(caretMaxOffset(), .Downstream)
      }
    }
    if isFlexibleBoxIncludingDeprecated() || isRenderGrid() {
      return super.positionForPoint(point, source, fragment)
    }

    var pointInContents = point
    offsetForContents(&pointInContents)
    var pointInLogicalContents = pointInContents
    if !isHorizontalWritingMode() {
      pointInLogicalContents = pointInLogicalContents.transposedPoint()
    }

    if childrenInline() {
      return positionForPointWithInlineChildren(pointInLogicalContents, source, fragment)
    }

    var lastCandidateBox = lastChildBox()

    var fragment = fragment
    if fragment == nil {
      fragment = fragmentAtBlockOffset(blockOffset: pointInLogicalContents.y)
    }

    while lastCandidateBox != nil
      && !isChildHitTestCandidate(lastCandidateBox!, fragment, pointInLogicalContents, source)
    {
      lastCandidateBox = lastCandidateBox!.previousSiblingBox()
    }

    let blocksAreFlipped = style().isFlippedBlocksWritingMode()
    if lastCandidateBox != nil {
      if pointInLogicalContents.y > logicalTopForChild(child: lastCandidateBox!)
        || (!blocksAreFlipped
          && pointInLogicalContents.y == logicalTopForChild(child: lastCandidateBox!))
      {
        return positionForPointRespectingEditingBoundaries(
          self, lastCandidateBox!, pointInContents, source)
      }

      var childBox = firstChildBox()
      while childBox != nil {
        if !isChildHitTestCandidate(childBox!, fragment, pointInLogicalContents, source) {
          childBox = childBox!.nextSiblingBox()
          continue
        }
        var childLogicalBottom =
          logicalTopForChild(child: childBox!) + logicalHeightForChild(child: childBox!)
        if let blockFlow = childBox as? RenderBlockFlowWrapper {
          childLogicalBottom = max(childLogicalBottom, blockFlow.lowestFloatLogicalBottom())
        }
        // We hit child if our click is above the bottom of its padding box (like IE6/7 and FF3).
        if pointInLogicalContents.y < childLogicalBottom
          || (blocksAreFlipped && pointInLogicalContents.y == childLogicalBottom)
        {
          return positionForPointRespectingEditingBoundaries(
            self, childBox!, pointInContents, source)
        }
        childBox = childBox!.nextSiblingBox()
      }
    }

    // We only get here if there are no hit test candidate children below the click.
    return super.positionForPoint(point, source, fragment)
  }

  func addContinuationWithOutline(flow: RenderInlineWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createAnonymousBlock(display: DisplayType = .Block) -> RenderBlockWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    assert(isNativeImpl())
    return createAnonymousBlockWithStyleAndDisplay(
      document: document(), style: renderer.style(), display: style().display())
  }

  static func constructTextRun(
    _ string: StringWrapper, _ style: RenderStyleWrapper,
    _ expansion: ExpansionBehaviorWrapper = ExpansionBehaviorWrapper.defaultBehavior(),
    _ flags: TextRunFlags = .DefaultTextRunFlags
  ) -> TextRunWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func constructTextRun(
    text: RenderTextWrapper, offset: UInt32, length: UInt32, _ style: RenderStyleWrapper,
    _ expansion: ExpansionBehaviorWrapper = ExpansionBehaviorWrapper.defaultBehavior()
  ) -> TextRunWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func constructTextRun(
    _ characters: CharSpanWrapper<UChar>, _ style: RenderStyleWrapper,
    _ expansion: ExpansionBehaviorWrapper = ExpansionBehaviorWrapper.defaultBehavior()
  ) -> TextRunWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paginationStrut() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPaginationStrut(strut: LayoutUnit) {
    assert(isNativeImpl())
    let rareData = getBlockRareData()
    if rareData == nil {
      if !strut.bool() {
        return
      }
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The page logical offset is the object's offset from the top of the page in the page progression
  // direction (so an x-offset in vertical text and a y-offset for horizontal text).
  func pageLogicalOffset() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The page logical offset is the object's offset from the top of the page in the page progression
  // direction (so an x-offset in vertical text and a y-offset for horizontal text).
  func setPageLogicalOffset(logicalOffset: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Fieldset legends that are taller than the fieldset border add in intrinsic border
  // in order to ensure that content gets properly pushed down across all layout systems
  // (flexbox, block, etc.)
  func intrinsicBorderForFieldset() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.RenderBlock_intrinsicBorderForFieldset(id()))
    }
    return getBlockRareData()?.m_intrinsicBorderForFieldset ?? LayoutUnit(value: UInt64(0))
  }

  private func setIntrinsicBorderForFieldset(padding: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderTop() -> LayoutUnit {
    assert(isNativeImpl())
    if style().blockFlowDirection() != .TopToBottom || !intrinsicBorderForFieldset().bool() {
      return super.borderTop()
    }
    return super.borderTop() + intrinsicBorderForFieldset()
  }

  override func borderBottom() -> LayoutUnit {
    assert(isNativeImpl())
    if style().blockFlowDirection() != .BottomToTop || !intrinsicBorderForFieldset().bool() {
      return super.borderBottom()
    }
    return super.borderBottom() + intrinsicBorderForFieldset()
  }

  override func borderLeft() -> LayoutUnit {
    assert(isNativeImpl())
    if style().blockFlowDirection() != .LeftToRight || !intrinsicBorderForFieldset().bool() {
      return super.borderLeft()
    }
    return super.borderLeft() + intrinsicBorderForFieldset()
  }

  override func borderRight() -> LayoutUnit {
    assert(isNativeImpl())
    if style().blockFlowDirection() != .RightToLeft || !intrinsicBorderForFieldset().bool() {
      return super.borderRight()
    }
    return super.borderRight() + intrinsicBorderForFieldset()
  }

  override func borderBefore() -> LayoutUnit {
    assert(isNativeImpl())
    return boxBorderBefore() + intrinsicBorderForFieldset()
  }

  override func adjustContentBoxLogicalHeightForBoxSizing(height: LayoutUnit?) -> LayoutUnit {
    assert(isNativeImpl())
    // FIXME: We're doing this to match other browsers even though it's questionable.
    // Shouldn't height:100px mean the fieldset content gets 100px of height even if the
    // resulting fieldset becomes much taller because of the legend?
    if height == nil {
      return LayoutUnit(value: 0)
    }
    var result = height!
    if style().boxSizing() == .BorderBox {
      result -= borderAndPaddingLogicalHeight()
    } else {
      result -= intrinsicBorderForFieldset()
    }
    return max(LayoutUnit(value: UInt64(0)), result)
  }

  override func adjustIntrinsicLogicalHeightForBoxSizing(height: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintExcludedChildrenInBorder(
    paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    assert(isNativeImpl())
    if !isFieldset() || isSkippedContentRoot() {
      return
    }

    if let box = findFieldsetLegend() {
      if !box.isExcludedFromNormalLayout() || box.hasSelfPaintingLayerModelObject() {
        return
      }

      let childPoint = flipForWritingModeForChild(child: box, point: paintOffset)
      box.paintAsInlineBlock(paintInfo: &paintInfo, childPoint: childPoint)
    }
  }

  // Accessors for logical width/height and margins in the containing block's block-flow direction.
  enum ApplyLayoutDeltaMode {
    case ApplyLayoutDelta
    case DoNotApplyLayoutDelta
  }

  func logicalWidthForChild(child: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalHeightForChild(child: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalTopForChild(child: RenderBoxWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    return isHorizontalWritingMode() ? child.y() : child.x()
  }

  private func logicalLeftForChild(child: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLogicalLeftForChild(
    child: RenderBoxWrapper, logicalLeft: LayoutUnit,
    applyDelta: ApplyLayoutDeltaMode = .DoNotApplyLayoutDelta
  ) {
    assert(isNativeImpl())
    let zero = LayoutUnit(value: UInt64(0))
    if isHorizontalWritingMode() {
      if applyDelta == .ApplyLayoutDelta {
        view().frameView().layoutContext().addLayoutDelta(
          delta: LayoutSizeWrapper(width: child.x() - logicalLeft, height: zero))
      }
      child.setX(x: logicalLeft)
    } else {
      if applyDelta == .ApplyLayoutDelta {
        view().frameView().layoutContext().addLayoutDelta(
          delta: LayoutSizeWrapper(width: zero, height: child.y() - logicalLeft))
      }
      child.setY(y: logicalLeft)
    }
  }

  func setLogicalTopForChild(
    child: RenderBoxWrapper, logicalTop: LayoutUnit,
    applyDelta: ApplyLayoutDeltaMode = .DoNotApplyLayoutDelta
  ) {
    assert(isNativeImpl())
    let zero = LayoutUnit(value: UInt64(0))
    if isHorizontalWritingMode() {
      if applyDelta == .ApplyLayoutDelta {
        view().frameView().layoutContext().addLayoutDelta(
          delta: LayoutSizeWrapper(width: zero, height: child.y() - logicalTop))
      }
      child.setY(y: logicalTop)
    } else {
      if applyDelta == .ApplyLayoutDelta {
        view().frameView().layoutContext().addLayoutDelta(
          delta: LayoutSizeWrapper(width: child.x() - logicalTop, height: zero))
      }
      child.setX(x: logicalTop)
    }
  }

  func marginBeforeForChild(child: RenderBoxModelObjectWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    return child.marginBefore(otherStyle: style())
  }

  func marginAfterForChild(child: RenderBoxModelObjectWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    return child.marginAfter(otherStyle: style())
  }

  func marginStartForChild(child: RenderBoxModelObjectWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    return child.marginStart(otherStyle: style())
  }

  func marginEndForChild(child: RenderBoxModelObjectWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    return child.marginEnd(otherStyle: style())
  }

  private func setMarginStartForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    assert(isNativeImpl())
    child.setMarginStart(value: value, overrideStyle: style())
  }

  private func setMarginEndForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    assert(isNativeImpl())
    child.setMarginEnd(value: value, overrideStyle: style())
  }

  func setMarginBeforeForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    assert(isNativeImpl())
    child.setMarginBefore(value: value, overrideStyle: style())
  }

  func setMarginAfterForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    assert(isNativeImpl())
    child.setMarginAfter(value: value, overrideStyle: style())
  }

  func setTrimmedMarginForChild(child: RenderBoxWrapper, marginTrimType: MarginTrimType) {
    assert(isNativeImpl())
    let zero = LayoutUnit(value: UInt64(0))
    switch marginTrimType {
    case .BlockStart:
      setMarginBeforeForChild(child: child, value: zero)
      child.markMarginAsTrimmed(newTrimmedMargin: .BlockStart)
    case .BlockEnd:
      setMarginAfterForChild(child: child, value: zero)
      child.markMarginAsTrimmed(newTrimmedMargin: .BlockEnd)
    case .InlineStart:
      setMarginStartForChild(child: child, value: zero)
      child.markMarginAsTrimmed(newTrimmedMargin: .InlineStart)
    case .InlineEnd:
      setMarginEndForChild(child: child, value: zero)
      child.markMarginAsTrimmed(newTrimmedMargin: .InlineEnd)
    default:
      fatalError("Not implemented yet")
    }
  }

  struct FirstLetterRenderObjects {
    let firstLetter: RenderObjectWrapper?
    let firstLetterContainer: RenderElementWrapper?
  }

  func getFirstLetter(skipObject: RenderObjectWrapper? = nil) -> FirstLetterRenderObjects {
    assert(isNativeImpl())
    var firstLetter: RenderObjectWrapper? = nil
    var firstLetterContainer: RenderElementWrapper? = nil

    // Don't recur
    if style().pseudoElementType() == .FirstLetter {
      return FirstLetterRenderObjects(
        firstLetter: firstLetter, firstLetterContainer: firstLetterContainer)
    }

    // FIXME: We need to destroy the first-letter object if it is no longer the first child. Need to find
    // an efficient way to check for that situation though before implementing anything.
    firstLetterContainer = findFirstLetterBlock(start: self)
    if firstLetterContainer == nil {
      return FirstLetterRenderObjects(
        firstLetter: firstLetter, firstLetterContainer: firstLetterContainer)
    }

    // Drill into inlines looking for our first text descendant.
    firstLetter = firstLetterContainer!.firstChild()
    while firstLetter != nil {
      if firstLetter is RenderTextWrapper {
        if CPtrToInt(firstLetter!.id()) == CPtrToInt(skipObject?.id()) {
          firstLetter = firstLetter!.nextSibling()
          continue
        }

        break
      }

      let current = firstLetter as! RenderElementWrapper
      if current is RenderListMarkerWrapper {
        firstLetter = current.nextSibling()
      } else if current.isFloatingOrOutOfFlowPositioned() {
        if current.style().pseudoElementType() == .FirstLetter {
          firstLetter = current.firstChild()
          break
        }
        firstLetter = current.nextSibling()
      } else if current.isReplacedOrInlineBlock() || current is RenderButtonWrapper
        || current is RenderMenuListWrapper
      {
        break
      } else if current.isFlexibleBoxIncludingDeprecated() || current.isRenderGrid() {
        firstLetter = current.nextSibling()
      } else if current.style().hasPseudoStyle(pseudo: .FirstLetter)
        && current.canHaveGeneratedChildren()
      {
        // We found a lower-level node with first-letter, which supersedes the higher-level style
        firstLetterContainer = current
        firstLetter = current.firstChild()
      } else {
        firstLetter = current.firstChild()
      }
    }

    if firstLetter == nil {
      firstLetterContainer = nil
    }

    return FirstLetterRenderObjects(
      firstLetter: firstLetter, firstLetterContainer: firstLetterContainer)
  }

  private func logicalLeftOffsetForContent(_ fragment: RenderFragmentContainerWrapper?)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    var logicalLeftOffset =
      style().isHorizontalWritingMode() ? borderLeft() + paddingLeft() : borderTop() + paddingTop()
    if shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() && isHorizontalWritingMode() {
      logicalLeftOffset += verticalScrollbarWidth()
    }
    if fragment == nil {
      return logicalLeftOffset
    }
    let boxRect = borderBoxRectInFragment(fragment: fragment)
    return logicalLeftOffset + (isHorizontalWritingMode() ? boxRect.x() : boxRect.y())
  }

  private func logicalRightOffsetForContent(_ fragment: RenderFragmentContainerWrapper?)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    var logicalRightOffset =
      style().isHorizontalWritingMode() ? borderLeft() + paddingLeft() : borderTop() + paddingTop()
    if shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() && isHorizontalWritingMode() {
      logicalRightOffset += verticalScrollbarWidth()
    }
    logicalRightOffset += availableLogicalWidth()
    if fragment == nil {
      return logicalRightOffset
    }
    let boxRect = borderBoxRectInFragment(fragment: fragment)
    return logicalRightOffset
      - (logicalWidth() - (isHorizontalWritingMode() ? boxRect.maxX() : boxRect.maxY()))
  }

  func startOffsetForContent(fragment: RenderFragmentContainerWrapper?) -> LayoutUnit {
    assert(isNativeImpl())
    return style().isLeftToRightDirection()
      ? logicalLeftOffsetForContent(fragment)
      : logicalWidth() - logicalRightOffsetForContent(fragment)
  }

  func endOffsetForContent(fragment: RenderFragmentContainerWrapper?) -> LayoutUnit {
    assert(isNativeImpl())
    return !style().isLeftToRightDirection()
      ? logicalLeftOffsetForContent(fragment)
      : logicalWidth() - logicalRightOffsetForContent(fragment)
  }

  func logicalLeftOffsetForContent(blockOffset: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    return logicalLeftOffsetForContent(fragmentAtBlockOffset(blockOffset: blockOffset))
  }

  func logicalRightOffsetForContent(blockOffset: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    return logicalRightOffsetForContent(fragmentAtBlockOffset(blockOffset: blockOffset))
  }

  func startOffsetForContent(blockOffset: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    return startOffsetForContent(fragment: fragmentAtBlockOffset(blockOffset: blockOffset))
  }

  func logicalLeftOffsetForContent() -> LayoutUnit {
    assert(isNativeImpl())
    return isHorizontalWritingMode() ? borderLeft() + paddingLeft() : borderTop() + paddingTop()
  }

  private func logicalRightOffsetForContent() -> LayoutUnit {
    assert(isNativeImpl())
    return logicalLeftOffsetForContent() + availableLogicalWidth()
  }

  func availableLogicalWidthForContent(blockOffset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func startOffsetForContent() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isLeftToRightDirection()
      ? logicalLeftOffsetForContent() : logicalWidth() - logicalRightOffsetForContent()
  }

  #if ASSERT_ENABLED
    func checkPositionedObjectsNeedLayout() {
      assert(isNativeImpl())
      guard let positionedDescendants = positionedObjects() else { return }

      for renderer in positionedDescendants {
        assert(!renderer.needsLayout())
      }
    }
  #endif

  func canDropAnonymousBlockChild() -> Bool {
    assert(isNativeImpl())
    return true
  }

  private func cachedEnclosingFragmentedFlow() -> RenderFragmentedFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCachedEnclosingFragmentedFlowNeedsUpdate() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants(
    fragmentedFlow: RenderFragmentedFlowWrapper? = nil
  ) {
    assert(isNativeImpl())
    if fragmentedFlowState() == .NotInsideFlow {
      return
    }

    var fragmentedFlow = fragmentedFlow
    if let cachedFragmentedFlow = cachedEnclosingFragmentedFlow() {
      fragmentedFlow = cachedFragmentedFlow
    }
    setCachedEnclosingFragmentedFlowNeedsUpdate()
    super.resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants(
      fragmentedFlow: fragmentedFlow)
  }

  func availableLogicalHeightForPercentageComputation() -> LayoutUnit? {
    assert(isNativeImpl())
    // For anonymous blocks that are skipped during percentage height calculation,
    // we consider them to have an indefinite height.
    if skipContainingBlockForPercentHeightCalculation(
      containingBlock: self, isPerpendicularWritingMode: false)
    {
      return nil
    }

    if let overridingLogicalHeightForFlex =
      (isFlexItem()
        ? (parent() as! RenderFlexibleBoxWrapper)
          .usedFlexItemOverridingLogicalHeightForPercentageResolution(flexItem: self) : nil)
    {
      return overridingContentLogicalHeight(overridingLogicalHeight: overridingLogicalHeightForFlex)
    }

    if let overridingLogicalHeightForGrid = isGridItem() ? overridingLogicalHeight() : nil {
      return overridingContentLogicalHeight(overridingLogicalHeight: overridingLogicalHeightForGrid)
    }

    let style = self.style()
    if style.logicalHeight().isFixed() {
      let contentBoxHeight = adjustContentBoxLogicalHeightForBoxSizing(
        height: LayoutUnit(value: style.logicalHeight().value()))
      return max(
        LayoutUnit(value: UInt64(0)),
        constrainContentBoxLogicalHeightByMinMax(
          logicalHeight: contentBoxHeight - scrollbarLogicalHeight(), intrinsicContentHeight: nil))
    }

    if shouldComputeLogicalHeightFromAspectRatio() {
      // Only grid is expected to be in a state where it is calculating pref width and having unknown logical width.
      if isRenderGrid() && preferredLogicalWidthsDirty() && !style.logicalWidth().isSpecified() {
        return nil
      }
      return RenderBoxWrapper.blockSizeFromAspectRatio(
        borderPaddingInlineSum: horizontalBorderAndPaddingExtent(),
        borderPaddingBlockSum: verticalBorderAndPaddingExtent(),
        aspectRatio: style.logicalAspectRatio(), boxSizing: style.boxSizingForAspectRatio(),
        inlineSize: logicalWidth(), aspectRatioType: style.aspectRatioType(),
        isRenderReplaced: isRenderReplaced())
    }

    // A positioned element that specified both top/bottom or that specifies
    // height should be treated as though it has a height explicitly specified
    // that can be used for any percentage computations.
    let isOutOfFlowPositionedWithSpecifiedHeight =
      isOutOfFlowPositioned()
      && (!style.logicalHeight().isAuto()
        || (!style.logicalTop().isAuto() && !style.logicalBottom().isAuto()))
    if isOutOfFlowPositionedWithSpecifiedHeight {
      // Don't allow this to affect the block' size() member variable, since this
      // can get called while the block is still laying out its kids.
      let zero = LayoutUnit(value: UInt64(0))
      return max(
        zero,
        computeLogicalHeight(logicalHeight: logicalHeight(), logicalTop: zero).extent
          - borderAndPaddingLogicalHeight()
          - LayoutUnit(value: scrollbarLogicalHeight()))
    }

    if style.logicalHeight().isPercentOrCalculated() {
      if let heightWithScrollbar = computePercentageLogicalHeight(height: style.logicalHeight()) {
        let contentBoxHeightWithScrollbar = adjustContentBoxLogicalHeightForBoxSizing(
          height: heightWithScrollbar)
        // We need to adjust for min/max height because this method does not handle the min/max of the current block, its caller does.
        // So the return value from the recursive call will not have been adjusted yet.
        return max(
          LayoutUnit(value: UInt64(0)),
          constrainContentBoxLogicalHeightByMinMax(
            logicalHeight: contentBoxHeightWithScrollbar - scrollbarLogicalHeight(),
            intrinsicContentHeight: nil))
      }
      return nil
    }

    if isRenderView() {
      return view().pageOrViewLogicalHeight()
    }

    return nil
  }

  func hasDefiniteLogicalHeight() -> Bool {
    assert(isNativeImpl())
    return renderBlockHasDefiniteLogicalHeight()
  }

  func shouldResetChildLogicalHeightBeforeLayout() -> Bool {
    assert(isNativeImpl())
    return false
  }

  func renderBlockHasDefiniteLogicalHeight() -> Bool {
    assert(isNativeImpl())
    return availableLogicalHeightForPercentageComputation() != nil
  }

  func hasLineIfEmpty() -> Bool {
    assert(isNativeImpl())
    if element() == nil {
      return false
    }

    if element()!.isRootEditableElement() {
      return true
    }

    return false
  }

  func updateDescendantTransformsAfterLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    if !isNativeImpl() {
      wk_interop.RenderBlock_layout(id())
      return
    }
    // TODO(asuhan): add stack stats

    // Table cells call layoutBlock directly, so don't add any logic here.  Put code into
    // layoutBlock().
    layoutBlock(relayoutChildren: false)

    // It's safe to check for control clip here, since controls can never be table cells.
    // If we have a lightweight clip, there can never be any overflow from children.
    let transaction = view().frameView().layoutContext()
      .updateScrollInfoAfterLayoutTransactionIfExists()
    let isDelayingUpdateScrollInfoAfterLayoutInView =
      transaction != nil && transaction!.nestedCount != 0
    if hasControlClip() && overflow != nil && !isDelayingUpdateScrollInfoAfterLayoutInView {
      clearLayoutOverflow()
    }

    invalidateBackgroundObscurationStatus()
  }

  func layoutPositionedObjects(relayoutChildren: Bool, fixedPositionObjectsOnly: Bool = false) {
    assert(isNativeImpl())
    if let positionedDescendants = positionedObjects() {
      // Do not cache positionedDescendants->end() in a local variable, since |positionedDescendants| can be mutated
      // as it is walked. We always need to fetch the new end() value dynamically.
      for descendant in positionedDescendants {
        layoutPositionedObject(
          r: descendant, relayoutChildren: relayoutChildren,
          fixedPositionObjectsOnly: fixedPositionObjectsOnly)
      }
    }
  }

  func layoutPositionedObject(
    r: RenderBoxWrapper, relayoutChildren: Bool, fixedPositionObjectsOnly: Bool
  ) {
    assert(isNativeImpl())
    if isSkippedContentRoot() {
      r.clearNeedsLayoutForSkippedContent()
      return
    }

    estimateFragmentRangeForBoxChild(box: r)

    // A fixed position element with an absolute positioned ancestor has no way of knowing if the latter has changed position. So
    // if this is a fixed position element, mark it for layout if it has an abspos ancestor and needs to move with that ancestor, i.e.
    // it has static position.
    markFixedPositionObjectForLayoutIfNeeded(positionedChild: r)
    if fixedPositionObjectsOnly {
      r.layoutIfNeeded()
      return
    }

    // When a non-positioned block element moves, it may have positioned children that are implicitly positioned relative to the
    // non-positioned block.  Rather than trying to detect all of these movement cases, we just always lay out positioned
    // objects that are positioned implicitly like this.  Such objects are rare, and so in typical DHTML menu usage (where everything is
    // positioned explicitly) this should not incur a performance penalty.
    if relayoutChildren
      || (r.style().hasStaticBlockPosition(horizontal: isHorizontalWritingMode())
        && CPtrToInt(r.parent()?.id()) != CPtrToInt(id()))
    {
      r.setChildNeedsLayout(markParents: .MarkOnlyThis)
    }

    // If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
    if relayoutChildren && r.needsPreferredWidthsRecalculation() {
      r.setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)
    }

    r.markForPaginationRelayoutIfNeeded()

    // We don't have to do a full layout.  We just have to update our position. Try that first. If we have shrink-to-fit width
    // and we hit the available width constraint, the layoutIfNeeded() will catch it and do a full layout.
    if r.needsPositionedMovementLayoutOnly() && r.tryLayoutDoingPositionedMovementOnly() {
      r.clearNeedsLayout()
    }

    // If we are paginated or in a line grid, compute a vertical position for our object now.
    // If it's wrong we'll lay out again.
    var oldLogicalTop = LayoutUnit()
    let layoutState = view().frameView().layoutContext().layoutState()
    let needsBlockDirectionLocationSetBeforeLayout =
      r.needsLayout() && layoutState != nil
      && layoutState!.needsBlockDirectionLocationSetBeforeLayout()
    if needsBlockDirectionLocationSetBeforeLayout {
      if isHorizontalWritingMode() == r.isHorizontalWritingMode() {
        r.updateLogicalHeight()
      } else {
        r.updateLogicalWidth()
      }
      oldLogicalTop = logicalTopForChild(child: r)
    }

    r.layoutIfNeeded()

    let parent = r.parent()
    var layoutChanged = false
    if let flexibleBox = parent as? RenderFlexibleBoxWrapper,
      flexibleBox.setStaticPositionForPositionedLayout(flexItem: r)
    {
      // The static position of an abspos child of a flexbox depends on its size
      // (for example, they can be centered). So we may have to reposition the
      // item after layout.
      // FIXME: We could probably avoid a layout here and just reposition?
      layoutChanged = true
    }

    // Lay out again if our estimate was wrong.
    if layoutChanged
      || (needsBlockDirectionLocationSetBeforeLayout
        && logicalTopForChild(child: r) != oldLogicalTop)
    {
      r.setChildNeedsLayout(markParents: .MarkOnlyThis)
      r.layoutIfNeeded()
    }

    if updateFragmentRangeForBoxChild(box: r) {
      r.setNeedsLayout(markParents: .MarkOnlyThis)
      r.layoutIfNeeded()
    }

    if layoutState != nil && layoutState!.isPaginated(),
      let blockFlow = self as? RenderBlockFlowWrapper
    {
      blockFlow.adjustSizeContainmentChildForPagination(child: r, offset: r.logicalTop())
    }
  }

  private func markFixedPositionObjectForLayoutIfNeeded(positionedChild: RenderBoxWrapper) {
    assert(isNativeImpl())
    if positionedChild.style().position() != .Fixed {
      return
    }

    let hasStaticBlockPosition = positionedChild.style().hasStaticBlockPosition(
      horizontal: isHorizontalWritingMode())
    let hasStaticInlinePosition = positionedChild.style().hasStaticInlinePosition(
      horizontal: isHorizontalWritingMode())
    if !hasStaticBlockPosition && !hasStaticInlinePosition {
      return
    }

    var parent = positionedChild.parent()
    while parent != nil && !(parent is RenderViewWrapper) && parent!.style().position() != .Absolute
    {
      parent = parent!.parent()
    }
    if parent == nil || parent!.style().position() != .Absolute {
      return
    }

    if hasStaticInlinePosition {
      var computedValues = LogicalExtentComputedValues()
      positionedChild.computeLogicalWidthInFragment(computedValues: &computedValues)
      let newLeft = computedValues.position
      if newLeft != positionedChild.logicalLeft() {
        positionedChild.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }
    } else if hasStaticBlockPosition {
      let oldTop = positionedChild.logicalTop()
      positionedChild.updateLogicalHeight()
      if positionedChild.logicalTop() != oldTop {
        positionedChild.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }
    }
  }

  func marginIntrinsicLogicalWidthForChild(child: RenderBoxWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    // A margin has three types: fixed, percentage, and auto (variable).
    // Auto and percentage margins become 0 when computing min/max width.
    // Fixed margins can be added in as is.
    let marginLeft = child.style().marginStartUsing(otherStyle: style())
    let marginRight = child.style().marginEndUsing(otherStyle: style())
    var margin = LayoutUnit()
    if marginLeft.isFixed() && !shouldTrimChildMarginForBox(type: .InlineStart, child: child) {
      margin += marginLeft.value()
    }
    if marginRight.isFixed() && !shouldTrimChildMarginForBox(type: .InlineEnd, child: child) {
      margin += marginRight.value()
    }
    return margin
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    let adjustedPaintOffset = paintOffset + location()
    let phase = paintInfo.phase

    if visualContentIsClippedOut(paintInfo: paintInfo, adjustedPaintOffset: adjustedPaintOffset) {
      return
    }

    let pushedClip = pushContentsClip(paintInfo: &paintInfo, accumulatedOffset: adjustedPaintOffset)
    paintObject(paintInfo: &paintInfo, paintOffset: adjustedPaintOffset)
    if pushedClip {
      popContentsClip(
        paintInfo: &paintInfo, originalPhase: phase, accumulatedOffset: adjustedPaintOffset)
    }

    // Our scrollbar widgets paint exactly when we tell them to, so that they work properly with
    // z-index. We paint after we painted the background/border, so that the scrollbars will
    // sit above the background/border.
    if (phase != .BlockBackground && phase != .ChildBlockBackground) || !hasNonVisibleOverflow() {
      return
    }
    if let layer = layer(), let scrollableArea = layer.scrollableArea(),
      style().usedVisibility() == .Visible
        && paintInfo.shouldPaintWithinRoot(renderer: self) && !paintInfo.paintRootBackgroundOnly()
    {
      scrollableArea.paintOverflowControls(
        context: paintInfo.context(), paintOffset: roundedIntPoint(point: adjustedPaintOffset),
        damageRect: snappedIntRect(rect: paintInfo.rect))
    }
  }

  // FIXME: Could eliminate the isDocumentElementRenderer() check if we fix background painting so that the RenderView paints the root's background.
  private func visualContentIsClippedOut(
    paintInfo: PaintInfoWrapper, adjustedPaintOffset: LayoutPointWrapper
  ) -> Bool {
    assert(isNativeImpl())
    if isDocumentElementRenderer() {
      return false
    }

    if paintInfo.paintBehavior.contains(.CompositedOverflowScrollContent) && hasLayer()
      && layer()!.usesCompositedScrolling()
    {
      return false
    }

    var overflowBox = visualOverflowRect()
    flipForWritingMode(rect: &overflowBox)
    overflowBox.moveBy(offset: adjustedPaintOffset)
    return !overflowBox.intersects(other: paintInfo.rect)
  }

  override func paintObject(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    let paintPhase = paintInfo.phase

    // 1. paint background, borders etc
    if (paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground)
      && style().usedVisibility() == .Visible
    {
      if hasVisibleBoxDecorations() {
        paintBoxDecorations(paintInfo: paintInfo, paintOffset: paintOffset)
      }
      paintDebugBoxShadowIfApplicable(
        context: paintInfo.context(),
        paintRect: LayoutRectWrapper(location: paintOffset, size: size()))
    }

    // Paint legends just above the border before we scroll or clip.
    if paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground
      || paintPhase == .Selection
    {
      paintExcludedChildrenInBorder(paintInfo: &paintInfo, paintOffset: paintOffset)
    }

    if paintPhase == .Mask && style().usedVisibility() == .Visible {
      paintMask(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    if paintPhase == .ClippingMask && style().usedVisibility() == .Visible {
      paintClippingMask(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    // If just painting the root background, then return.
    if paintInfo.paintRootBackgroundOnly() {
      return
    }

    if paintPhase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(renderBox: self, paintOffset: paintOffset)
    }

    if paintPhase == .EventRegion {
      let borderRect = LayoutRectWrapper(location: paintOffset, size: size())

      if paintInfo.paintBehavior.contains(.EventRegionIncludeBackground) && visibleToHitTesting() {
        let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: borderRect)
        let overrideUserModifyIsEditable =
          isRenderTextControl()
          && (self as! RenderTextControlWrapper).textFormControlElement()
            .isInnerTextElementEditable()
        paintInfo.eventRegionContext()!.unite(
          roundedRect: borderShape.deprecatedPixelSnappedRoundedRect(
            deviceScaleFactor: document().deviceScaleFactor()), renderer: self,
          style: style(), overrideUserModifyIsEditable: overrideUserModifyIsEditable)
      }

      if !paintInfo.paintBehavior.contains(.EventRegionIncludeForeground) {
        return
      }

      let needsTraverseDescendants =
        hasVisualOverflow() || containsFloats()
        || !paintInfo.eventRegionContext()!.contains(rect: enclosingIntRect(rect: borderRect))
        || view().needsEventRegionUpdateForNonCompositedFrame()

      if !needsTraverseDescendants {
        return
      }
    }

    // Adjust our painting position if we're inside a scrolled layer (e.g., an overflow:auto div).
    var scrolledOffset = paintOffset
    scrolledOffset.moveBy(offset: LayoutPointWrapper(point: -scrollPosition()))

    // Column rules need to account for scrolling and clipping.
    // FIXME: Clipping of column rules does not work. We will need a separate paint phase for column rules I suspect in order to get
    // clipping correct (since it has to paint as background but is still considered "contents").
    if (paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground)
      && style().usedVisibility() == .Visible
    {
      paintColumnRules(paintInfo, scrolledOffset)
    }

    // Done with backgrounds, borders and column rules.
    if paintPhase == .BlockBackground {
      return
    }

    // 2. paint contents
    if paintPhase != .SelfOutline {
      paintContents(paintInfo: paintInfo, paintOffset: scrolledOffset)
    }

    // 3. paint selection
    // FIXME: Make this work with multi column layouts.  For now don't fill gaps.
    let isPrinting = document().printing()
    if !isPrinting {
      paintSelection(paintInfo: paintInfo, paintOffset: scrolledOffset)  // Fill in gaps in selection on lines and between blocks.
    }

    // 4. paint floats.
    if paintPhase == .Float || paintPhase == .Selection || paintPhase == .TextClip
      || paintPhase == .EventRegion || paintPhase == .Accessibility
    {
      paintFloats(
        paintInfo: paintInfo, paintOffset: scrolledOffset,
        preservePhase: paintPhase == .Selection || paintPhase == .TextClip
          || paintPhase == .EventRegion
          || paintPhase == .Accessibility)
    }

    // 5. paint outline.
    if (paintPhase == .Outline || paintPhase == .SelfOutline) && hasOutline()
      && style().usedVisibility() == .Visible
    {
      // Don't paint focus ring for anonymous block continuation because the
      // inline element having outline-style:auto paints the whole focus ring.
      let hasOutlineStyleAuto = style().outlineStyleIsAuto() == .On
      if !hasOutlineStyleAuto || !isContinuation() {
        paintOutline(
          paintInfo: paintInfo, paintRect: LayoutRectWrapper(location: paintOffset, size: size()))
      }
    }

    // 6. paint continuation outlines.
    if paintPhase == .Outline || paintPhase == .ChildOutlines {
      if let inlineCont = inlineContinuation(), inlineCont.hasOutline(),
        inlineCont.style().usedVisibility() == .Visible
      {
        let inlineRenderer = inlineCont.element()!.renderer() as! RenderInlineWrapper?
        let containingBlock = self.containingBlock()

        var inlineEnclosedInSelfPaintingLayer = false
        var box: RenderBoxModelObjectWrapper? = inlineRenderer
        while CPtrToInt(box?.id()) != CPtrToInt(containingBlock?.id()) {
          if box!.hasSelfPaintingLayer() {
            inlineEnclosedInSelfPaintingLayer = true
            break
          }
          box = box!.parent()!.enclosingBoxModelObject()
        }

        // Do not add continuations for outline painting by our containing block if we are a relative positioned
        // anonymous block (i.e. have our own layer), paint them straightaway instead. This is because a block depends on renderers in its continuation table being
        // in the same layer.
        if !inlineEnclosedInSelfPaintingLayer && !hasLayer() {
          containingBlock!.addContinuationWithOutline(flow: inlineRenderer!)
        } else if !InlineIterator.firstInlineBoxFor(renderInline: inlineRenderer!).bool()
          || (!inlineEnclosedInSelfPaintingLayer && hasLayer())
        {
          inlineRenderer!.paintOutline(
            paintInfo: paintInfo,
            paintOffset: paintOffset - locationOffset()
              + inlineRenderer!.containingBlock()!.location())
        }
      }
      paintContinuationOutlines(info: paintInfo, paintOffset: paintOffset)
    }

    // 7. paint caret.
    // If the caret's node's render object's containing block is this block, and the paint action is PaintPhase::Foreground,
    // then paint the caret.
    paintCarets(paintInfo: paintInfo, paintOffset: paintOffset)
  }

  func paintChildren(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
    paintInfoForChild: inout PaintInfoWrapper, usePrintRect: Bool
  ) {
    assert(isNativeImpl())
    var child = firstChildBox()
    while child != nil {
      if !paintChild(
        child: child!, paintInfo: paintInfo, paintOffset: paintOffset,
        paintInfoForChild: &paintInfoForChild, usePrintRect: usePrintRect)
      {
        return
      }
      child = child!.nextSiblingBox()
    }
  }

  enum PaintBlockType {
    case PaintAsBlock
    case PaintAsInlineBlock
  }

  func paintChild(
    child: RenderBoxWrapper, paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
    paintInfoForChild: inout PaintInfoWrapper, usePrintRect: Bool,
    paintType: PaintBlockType = .PaintAsBlock
  ) -> Bool {
    assert(isNativeImpl())
    if child.isExcludedAndPlacedInBorder() {
      return true
    }

    // Check for page-break-before: always, and if it's set, break and bail.
    let checkBeforeAlways =
      !childrenInline() && (usePrintRect && alwaysPageBreak(between: child.style().breakBefore()))
    let absoluteChildY = paintOffset.y + child.y()
    if checkBeforeAlways
      && absoluteChildY > paintInfo.rect.y()
      && absoluteChildY < paintInfo.rect.maxY()
    {
      view().setBestTruncatedAt(y: absoluteChildY.int(), forRenderer: self, forcedBreak: true)
      return false
    }

    if !child.isFloating() && child.isReplacedOrInlineBlock() && usePrintRect
      && child.height() <= LayoutUnit(value: view().printRect().height())
    {
      // Paginate block-level replaced elements.
      if absoluteChildY + child.height() > Int(view().printRect().maxY()) {
        if absoluteChildY < LayoutUnit(value: view().truncatedAt()) {
          view().setBestTruncatedAt(y: absoluteChildY.int(), forRenderer: child)
        }
        // If we were able to truncate, don't paint.
        if absoluteChildY >= LayoutUnit(value: view().truncatedAt()) {
          return false
        }
      }
    }

    let childPoint = flipForWritingModeForChild(child: child, point: paintOffset)
    if !child.hasSelfPaintingLayer() && !child.isFloating() {
      if paintType == .PaintAsInlineBlock {
        child.paintAsInlineBlock(paintInfo: &paintInfoForChild, childPoint: childPoint)
      } else {
        child.paint(paintInfo: &paintInfoForChild, paintOffset: childPoint)
      }
    }

    // Check for page-break-after: always, and if it's set, break and bail.
    let checkAfterAlways =
      !childrenInline() && (usePrintRect && alwaysPageBreak(between: child.style().breakAfter()))
    if checkAfterAlways
      && (absoluteChildY + child.height()) > paintInfo.rect.y()
      && (absoluteChildY + child.height()) < paintInfo.rect.maxY()
    {
      view().setBestTruncatedAt(
        y: (absoluteChildY + child.height()
          + max(LayoutUnit(value: 0), child.collapsedMarginAfter())).int(),
        forRenderer: self, forcedBreak: true)
      return false
    }

    return true
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    assert(isNativeImpl())
    let adjustedLocation = accumulatedOffset + location()
    let localOffset = toLayoutSize(point: adjustedLocation)

    // Check if we need to do anything at all.
    if !hitTestVisualOverflow(locationInContainer, accumulatedOffset) {
      return false
    }

    if (hitTestAction == .HitTestBlockBackground || hitTestAction == .HitTestChildBlockBackground)
      && visibleToHitTesting(request: request)
      && isPointInOverflowControl(
        &result, locationInContainer: locationInContainer.point(),
        accumulatedOffset: adjustedLocation)
    {
      updateHitTestResult(result: result, point: locationInContainer.point() - localOffset)
      // FIXME: isPointInOverflowControl() doesn't handle rect-based tests yet.
      if result.addNodeToListBasedTestResult(
        node: protectedNodeForHitTest(), request: request,
        locationInContainer: locationInContainer) == .Stop
      {
        return true
      }
    }

    if !hitTestClipPath(locationInContainer, accumulatedOffset) {
      return false
    }

    // If we have clipping, then we can't have any spillout.
    let useClip = (hasControlClip() || hasNonVisibleOverflow())
    let checkChildren =
      !useClip
      || (hasControlClip()
        ? locationInContainer.intersects(rect: controlClipRect(additionalOffset: adjustedLocation))
        : locationInContainer.intersects(
          rect: overflowClipRect(
            location: adjustedLocation, fragment: nil, relevancy: .IncludeOverlayScrollbarSize)))
    if checkChildren
      && hitTestChildren(request, result, locationInContainer, adjustedLocation, hitTestAction)
    {
      return true
    }

    if !checkChildren
      && hitTestExcludedChildrenInBorder(
        request, result, locationInContainer, adjustedLocation, hitTestAction)
    {
      return true
    }

    if !hitTestBorderRadius(locationInContainer, accumulatedOffset) {
      return false
    }

    // Now hit test our background
    if hitTestAction == .HitTestBlockBackground || hitTestAction == .HitTestChildBlockBackground {
      let boundsRect = LayoutRectWrapper(location: adjustedLocation, size: size())
      if visibleToHitTesting(request: request) && locationInContainer.intersects(rect: boundsRect) {
        updateHitTestResult(
          result: result,
          point: flipForWritingMode(position: locationInContainer.point() - localOffset))
        if result.addNodeToListBasedTestResult(
          node: protectedNodeForHitTest(), request: request,
          locationInContainer: locationInContainer, rect: boundsRect) == .Stop
        {
          return true
        }
      }
    }

    return false
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    assert(isNativeImpl())
    assert(!childrenInline())
    if shouldApplySizeOrInlineSizeContainment() {
      if let width = explicitIntrinsicInnerLogicalWidth() {
        minLogicalWidth = width
        maxLogicalWidth = width
      }
    } else if !shouldApplyInlineSizeContainment() {
      computeBlockPreferredLogicalWidths(
        minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
    }

    maxLogicalWidth = max(minLogicalWidth, maxLogicalWidth)

    let scrollbarWidth = intrinsicScrollbarLogicalWidthIncludingGutter()
    maxLogicalWidth += scrollbarWidth
    minLogicalWidth += scrollbarWidth
  }

  override func computePreferredLogicalWidths() {
    assert(isNativeImpl())
    assert(preferredLogicalWidthsDirty())

    m_minPreferredLogicalWidth = LayoutUnit(value: 0)
    m_maxPreferredLogicalWidth = LayoutUnit(value: 0)

    let styleToUse = style()
    let lengthToUse = overridingLogicalWidthLength() ?? styleToUse.logicalWidth()
    if !isRenderTableCell() && lengthToUse.isFixed() && lengthToUse.value() >= 0
      && !(isDeprecatedFlexItem() && lengthToUse.intValue() == 0)
    {
      m_minPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: lengthToUse)
      m_maxPreferredLogicalWidth = m_minPreferredLogicalWidth
    } else if shouldComputeLogicalWidthFromAspectRatio() {
      m_maxPreferredLogicalWidth =
        computeLogicalWidthFromAspectRatio() - borderAndPaddingLogicalWidth()
      m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
      m_minPreferredLogicalWidth = max(LayoutUnit(value: UInt64(0)), m_minPreferredLogicalWidth)
      m_maxPreferredLogicalWidth = max(LayoutUnit(value: UInt64(0)), m_maxPreferredLogicalWidth)
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &m_minPreferredLogicalWidth, maxLogicalWidth: &m_maxPreferredLogicalWidth)
    }

    super.computePreferredLogicalWidths(
      minWidth: styleToUse.logicalMinWidth(), maxWidth: styleToUse.logicalMaxWidth(),
      borderAndPadding: borderAndPaddingLogicalWidth())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override func firstLineBaseline() -> LayoutUnit? {
    assert(isNativeImpl())
    if shouldApplyLayoutContainment() {
      return nil
    }

    if isWritingModeRoot() && !isFlexItem() {
      return nil
    }

    var child = firstInFlowChildBox()
    while child != nil {
      if child!.isLegend() && child!.isExcludedFromNormalLayout() {
        continue
      }
      if let baseline = child!.firstLineBaseline() {
        return LayoutUnit(value: floorToInt(value: child!.logicalTop() + baseline))
      }
      child = child!.nextInFlowSiblingBox()
    }
    return nil
  }

  override func lastLineBaseline() -> LayoutUnit? {
    assert(isNativeImpl())
    if shouldApplyLayoutContainment() {
      return nil
    }

    if isWritingModeRoot() {
      return nil
    }

    var child = lastInFlowChildBox()
    while child != nil {
      if child!.isLegend() && child!.isExcludedFromNormalLayout() {
        continue
      }
      if let baseline = child!.lastLineBaseline() {
        return LayoutUnit(value: floorToInt(value: child!.logicalTop() + baseline))
      }
      child = child!.previousInFlowSiblingBox()
    }
    return nil
  }

  // Delay updating scrollbars until endAndCommitUpdateScrollInfoAfterLayoutTransaction() is called. These functions are used
  // when a flexbox is laying out its descendants. If multiple calls are made to beginUpdateScrollInfoAfterLayoutTransaction()
  // then endAndCommitUpdateScrollInfoAfterLayoutTransaction() will do nothing until it is called the same number of times.
  func beginUpdateScrollInfoAfterLayoutTransaction() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endAndCommitUpdateScrollInfoAfterLayoutTransaction() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateScrollInfoAfterLayout() {
    assert(isNativeImpl())
    if !hasNonVisibleOverflow() {
      return
    }

    // FIXME: https://bugs.webkit.org/show_bug.cgi?id=97937
    // Workaround for now. We cannot delay the scroll info for overflow
    // for items with opposite writing directions, as the contents needs
    // to overflow in that direction
    if !style().isFlippedBlocksWritingMode() {
      if let transaction = view().frameView().layoutContext()
        .updateScrollInfoAfterLayoutTransactionIfExists(), transaction.nestedCount != 0
      {
        transaction.blocks.add(value: self)
        return
      }
    }

    if layer() != nil {
      layer()!.updateScrollInfoAfterLayout()
    }
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    assert(isNativeImpl())
    let oldStyle = hasInitializedStyle ? style() : nil
    // FIXME: Should change the expression below to newStyle.display() == DisplayType::InlineBlock.
    setReplacedOrInlineBlock(newStyle.isDisplayInlineType())
    if oldStyle != nil {
      removePositionedObjectsIfNeeded(oldStyle: oldStyle!, newStyle: newStyle)
      if isLegend() && !oldStyle!.isFloating() && newStyle.isFloating() {
        setIsExcludedFromNormalLayout(excluded: false)
      }
    }
    super.styleWillChange(diff: diff, newStyle: newStyle)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    styleDidChangeRenderBlock(diff: diff, oldStyle: oldStyle)
  }

  func styleDidChangeRenderBlock(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if oldStyle != nil {
      adjustFragmentedFlowStateOnContainingBlockChangeIfNeeded(
        oldStyle: oldStyle!, newStyle: style())
    }

    propagateStyleToAnonymousChildren(propagationType: .BlockAndRubyChildren)

    // It's possible for our border/padding to change, but for the overall logical width of the block to
    // end up being the same. We keep track of this change so in layoutBlock, we can know to set relayoutChildren=true.
    setShouldForceRelayoutChildren(
      b: oldStyle != nil && diff == .Layout && needsLayout()
        && borderOrPaddingLogicalWidthChanged(oldStyle: oldStyle!, newStyle: style()))
  }

  func canPerformSimplifiedLayout() -> Bool {
    assert(isNativeImpl())
    return renderBlockCanPerformSimplifiedLayout()
  }

  func renderBlockCanPerformSimplifiedLayout() -> Bool {
    assert(isNativeImpl())
    if selfNeedsLayout() || normalChildNeedsLayout() || outOfFlowChildNeedsStaticPositionLayout() {
      return false
    }
    if let wasSkippedDuringLastLayout = wasSkippedDuringLastLayoutDueToContentVisibility(),
      wasSkippedDuringLastLayout
    {
      return false
    }
    return posChildNeedsLayout() || needsSimplifiedNormalFlowLayout()
  }

  func simplifiedLayout() -> Bool {
    assert(isNativeImpl())
    if !canPerformSimplifiedLayout() {
      return false
    }

    let unused = LayoutStateMaintainer(
      root: self, offset: locationOffset(),
      disablePaintOffsetCache: isTransformed() || hasReflection()
        || style().isFlippedBlocksWritingMode())
    use(unused)
    if needsPositionedMovementLayout() && !tryLayoutDoingPositionedMovementOnly() {
      return false
    }

    let canContainFixedPosObjects = canContainFixedPositionObjects()
    if isSkippedContentRoot() && (posChildNeedsLayout() || canContainFixedPosObjects) {
      return false
    }

    // Lay out positioned descendants or objects that just need to recompute overflow.
    if needsSimplifiedNormalFlowLayout() {
      simplifiedNormalFlowLayout()
    }

    // Make sure a forced break is applied after the content if we are a flow thread in a simplified layout.
    // This ensures the size information is correctly computed for the last auto-height fragment receiving content.
    if let fragmentedFlow = self as? RenderFragmentedFlowWrapper {
      fragmentedFlow.applyBreakAfterContent(offsetBreak: clientLogicalBottom())
    }

    // Lay out our positioned objects if our positioned child bit is set.
    // Also, if an absolute position element inside a relative positioned container moves, and the absolute element has a fixed position
    // child, neither the fixed element nor its container learn of the movement since posChildNeedsLayout() is only marked as far as the
    // relative positioned container. So if we can have fixed pos objects in our positioned objects list check if any of them
    // are statically positioned and thus need to move with their absolute ancestors.
    if posChildNeedsLayout() || canContainFixedPosObjects {
      layoutPositionedObjects(
        relayoutChildren: false,
        fixedPositionObjectsOnly: !posChildNeedsLayout() && canContainFixedPosObjects)
    }

    // Recompute our overflow information.
    // FIXME: We could do better here by computing a temporary overflow object from layoutPositionedObjects and only
    // updating our overflow if we either used to have overflow or if the new temporary object has overflow.
    // For now just always recompute overflow.  This is no worse performance-wise than the old code that called rightmostPosition and
    // lowestPosition on every relayout so it's not a regression.
    // computeOverflow expects the bottom edge before we clamp our height. Since this information isn't available during
    // simplifiedLayout, we cache the value in overflow.
    let oldClientAfterEdge = overflow?.layoutClientAfterEdge ?? clientLogicalBottom()
    computeOverflow(oldClientAfterEdge: oldClientAfterEdge, recomputeFloats: true)

    updateLayerTransform()

    updateScrollInfoAfterLayout()

    clearNeedsLayout()
    return true
  }

  func simplifiedNormalFlowLayout() {
    assert(isNativeImpl())
    assert(!childrenInline())

    var box = firstChildBox()
    while box != nil {
      if !box!.isOutOfFlowPositioned() {
        box!.layoutIfNeeded()
      }
      box = box!.nextSiblingBox()
    }
  }

  func childBoxIsUnsplittableForFragmentation(child: RenderBoxWrapper) -> Bool {
    assert(isNativeImpl())
    let fragmentedFlow = enclosingFragmentedFlow()
    let checkColumnBreaks = fragmentedFlow != nil && fragmentedFlow!.shouldCheckColumnBreaks()
    let checkPageBreaks =
      !checkColumnBreaks
      && view().frameView().layoutContext().layoutState()!.pageLogicalHeight().bool()
    return child.isUnsplittableForPagination() || child.style().breakInside() == .Avoid
      || (checkColumnBreaks && child.style().breakInside() == .AvoidColumn)
      || (checkPageBreaks && child.style().breakInside() == .AvoidPage)
  }

  static func layoutOverflowLogicalBottom(renderer: RenderBlockWrapper) -> LayoutUnit {
    assert(renderer is RenderGridWrapper || renderer is RenderFlexibleBoxWrapper)
    var maxChildLogicalBottom = LayoutUnit()
    for child: RenderBoxWrapper in childrenOfType(parent: renderer) {
      if child.isOutOfFlowPositioned() {
        continue
      }
      let childLogicalBottom =
        renderer.logicalTopForChild(child: child) + renderer.logicalHeightForChild(child: child)
        + renderer.marginAfterForChild(child: child)
      maxChildLogicalBottom = max(maxChildLogicalBottom, childLogicalBottom)
    }
    return max(renderer.clientLogicalBottom(), maxChildLogicalBottom + renderer.paddingAfter())
  }

  // Overflow is always relative to the border-box of the element in question.
  // Therefore, if the element has a vertical scrollbar placed on the left, an overflow rect at x=2px would conceptually intersect the scrollbar.
  func computeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool = false) {
    assert(isNativeImpl())
    return renderBlockComputeOverflow(
      oldClientAfterEdge: oldClientAfterEdge, recomputeFloats: recomputeFloats)
  }

  private func clearLayoutOverflow() {
    assert(isNativeImpl())
    if overflow == nil {
      return
    }

    if visualOverflowRect() == borderBoxRect() {
      // FIXME: Implement complete solution for fragments overflow.
      clearOverflow()
      return
    }

    overflow!.setLayoutOverflow(borderBoxRect())
  }

  // Adjust from painting offsets to the local coords of this renderer
  private func offsetForContents(_ offset: inout LayoutPointWrapper) {
    assert(isNativeImpl())
    offset = flipForWritingMode(position: offset)
    offset += toLayoutSize(point: LayoutPointWrapper(point: scrollPosition()))
    offset = flipForWritingMode(position: offset)
  }

  func renderBlockComputeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool) {
    assert(isNativeImpl())
    clearOverflow()
    addOverflowFromChildren()

    addOverflowFromPositionedObjects()

    if hasNonVisibleOverflow() {
      includePaddingEnd()

      includePaddingAfter(oldClientAfterEdge: oldClientAfterEdge)
      overflow?.layoutClientAfterEdge = oldClientAfterEdge
    }

    // Add visual overflow from box-shadow, border-image-outset and outline.
    addVisualEffectOverflow()

    // Add visual overflow from theme.
    addVisualOverflowFromTheme()
  }

  private func includePaddingEnd() {
    assert(isNativeImpl())
    // As per https://github.com/w3c/csswg-drafts/issues/3653 padding should contribute to the scrollable overflow area.
    if !paddingEnd().bool() {
      return
    }
    // FIXME: Expand it to non-grid/flex cases when applicable.
    if !(self is RenderGridWrapper) && !(self is RenderFlexibleBoxWrapper) {
      return
    }

    let layoutOverflowRect = layoutOverflowRect()

    if isHorizontalWritingMode() {
      layoutOverflowRect.setWidth(
        width: layoutOverflowLogicalWidthIncludingPaddingEnd(layoutOverflowRect: layoutOverflowRect)
      )
    } else {
      layoutOverflowRect.setHeight(
        height: layoutOverflowLogicalWidthIncludingPaddingEnd(
          layoutOverflowRect: layoutOverflowRect))
    }
    addLayoutOverflow(rect: layoutOverflowRect)
  }

  private func layoutOverflowLogicalWidthIncludingPaddingEnd(layoutOverflowRect: LayoutRectWrapper)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    if hasHorizontalLayoutOverflow() {
      return (isHorizontalWritingMode() ? layoutOverflowRect.width() : layoutOverflowRect.height())
        + paddingEnd()
    }

    // FIXME: This is not sufficient for BFC layout (missing non-formatting-context root descendants).
    var contentLogicalRight = LayoutUnit()
    for child: RenderBoxWrapper in childrenOfType(parent: self) {
      if child.isOutOfFlowPositioned() {
        continue
      }
      let childLogicalRight =
        logicalLeftForChild(child: child) + logicalWidthForChild(child: child)
        + max(LayoutUnit(value: UInt64(0)), marginEndForChild(child: child))
      contentLogicalRight = max(contentLogicalRight, childLogicalRight)
    }
    let logicalRightWithPaddingEnd = contentLogicalRight + paddingEnd()
    // Use padding box as the reference box.
    return logicalRightWithPaddingEnd - (isHorizontalWritingMode() ? borderLeft() : borderTop())
  }

  private func includePaddingAfter(oldClientAfterEdge: LayoutUnit) {
    assert(isNativeImpl())
    // When we have overflow clip, propagate the original spillout since it will include collapsed bottom margins and bottom padding.
    let clientRect = flippedClientBoxRect()
    let zero = LayoutUnit(value: UInt64(0))
    let rectToApply = clientRect
    // Set the axis we don't care about to be 1, since we want this overflow to always be considered reachable.
    if isHorizontalWritingMode() {
      rectToApply.setWidth(width: LayoutUnit(value: 1))
      rectToApply.setHeight(height: max(zero, oldClientAfterEdge - clientRect.y()))
    } else {
      rectToApply.setWidth(width: max(zero, oldClientAfterEdge - clientRect.x()))
      rectToApply.setHeight(height: LayoutUnit(value: 1))
    }
    addLayoutOverflow(rect: rectToApply)
  }

  enum FieldsetFindLegendOption {
    case FieldsetIgnoreFloatingOrOutOfFlow
    case FieldsetIncludeFloatingOrOutOfFlow
  }

  func findFieldsetLegend(option: FieldsetFindLegendOption = .FieldsetIgnoreFloatingOrOutOfFlow)
    -> RenderBoxWrapper?
  {
    assert(isNativeImpl())
    for legend: RenderBoxWrapper in childrenOfType(parent: self) {
      if option == .FieldsetIgnoreFloatingOrOutOfFlow && legend.isFloatingOrOutOfFlowPositioned() {
        continue
      }
      if legend.isLegend() {
        return legend
      }
    }
    return nil
  }

  func layoutExcludedChildren(relayoutChildren: Bool) {
    assert(isNativeImpl())
    if !isFieldset() {
      return
    }

    setIntrinsicBorderForFieldset(padding: LayoutUnit(value: 0))

    let box = findFieldsetLegend()
    if box == nil {
      return
    }

    box!.setIsExcludedFromNormalLayout(excluded: true)
    for child: RenderBoxWrapper in childrenOfType(parent: self) {
      if CPtrToInt(child.id()) == CPtrToInt(box!.id()) || !child.isLegend() {
        continue
      }
      child.setIsExcludedFromNormalLayout(excluded: false)
    }

    let legend = box!
    if relayoutChildren {
      legend.setChildNeedsLayout(markParents: .MarkOnlyThis)
    }
    legend.layoutIfNeeded()

    var logicalLeft = LayoutUnit()
    if style().isLeftToRightDirection() {
      switch legend.style().textAlign() {
      case .Center:
        logicalLeft = (logicalWidth() - logicalWidthForChild(child: legend)) / 2
      case .Right:
        logicalLeft = logicalWidth() - borderAndPaddingEnd() - logicalWidthForChild(child: legend)
      default:
        logicalLeft = borderAndPaddingStart() + marginStartForChild(child: legend)
      }
    } else {
      switch legend.style().textAlign() {
      case .Left:
        logicalLeft = borderAndPaddingStart()
      case .Center:
        // Make sure that the extra pixel goes to the end side in RTL (since it went to the end side
        // in LTR).
        let centeredWidth = logicalWidth() - logicalWidthForChild(child: legend)
        logicalLeft = centeredWidth - centeredWidth / 2
      default:
        logicalLeft =
          logicalWidth() - borderAndPaddingStart() - marginStartForChild(child: legend)
          - logicalWidthForChild(child: legend)
      }
    }

    setLogicalLeftForChild(child: legend, logicalLeft: logicalLeft)

    let fieldsetBorderBefore = borderBefore()
    let legendLogicalHeight = logicalHeightForChild(child: legend)
    let legendAfterMargin = marginAfterForChild(child: legend)
    let topPositionForLegend = max(
      LayoutUnit(value: UInt64(0)), (fieldsetBorderBefore - legendLogicalHeight) / 2)
    let bottomPositionForLegend = topPositionForLegend + legendLogicalHeight + legendAfterMargin

    // Place the legend now.
    setLogicalTopForChild(child: legend, logicalTop: topPositionForLegend)

    // If the bottom of the legend (including its after margin) is below the fieldset border,
    // then we need to add in sufficient intrinsic border to account for this gap.
    // FIXME: Should we support the before margin of the legend? Not entirely clear.
    // FIXME: Consider dropping support for the after margin of the legend. Not sure other
    // browsers support that anyway.
    if bottomPositionForLegend > fieldsetBorderBefore {
      setIntrinsicBorderForFieldset(padding: bottomPositionForLegend - fieldsetBorderBefore)
    }

    // Now that the legend is included in the border extent, we can set our logical height
    // to the borderBefore (which includes the legend and its after margin if they were bigger
    // than the actual fieldset border) and then add in our padding before.
    setLogicalHeight(size: borderAndPaddingBefore())
  }

  func computePreferredWidthsForExcludedChildren() -> (LayoutUnit, LayoutUnit)? {
    assert(isNativeImpl())
    if !isFieldset() {
      return nil
    }

    let legend = findFieldsetLegend()
    if legend == nil {
      return nil
    }

    legend!.setIsExcludedFromNormalLayout(excluded: true)

    var (minWidth, maxWidth) = computeChildPreferredLogicalWidths(child: legend!)

    // These are going to be added in later, so we subtract them out to reflect the
    // fact that the legend is outside the scrollable area.
    let scrollbarWidth = intrinsicScrollbarLogicalWidthIncludingGutter()
    minWidth -= scrollbarWidth
    maxWidth -= scrollbarWidth

    let childStyle = legend!.style()
    let startMarginLength = childStyle.marginStartUsing(otherStyle: style())
    let endMarginLength = childStyle.marginEndUsing(otherStyle: style())
    var marginStart = LayoutUnit()
    var marginEnd = LayoutUnit()
    if startMarginLength.isFixed() {
      marginStart += startMarginLength.value()
    }
    if endMarginLength.isFixed() {
      marginEnd += endMarginLength.value()
    }
    let margin = marginStart + marginEnd

    minWidth += margin
    maxWidth += margin

    return (minWidth, maxWidth)
  }

  override func adjustBorderBoxRectForPainting(paintRect: inout LayoutRectWrapper) {
    assert(isNativeImpl())
    if !isFieldset() || isSkippedContentRoot() || !intrinsicBorderForFieldset().bool() {
      return
    }

    let legend = findFieldsetLegend()
    if legend == nil {
      return
    }

    if style().isHorizontalWritingMode() {
      let yOff = max(LayoutUnit(value: UInt64(0)), (legend!.height() - super.borderBefore()) / 2)
      paintRect.setHeight(height: paintRect.height() - yOff)
      if style().blockFlowDirection() == .TopToBottom {
        paintRect.setY(y: paintRect.y() + yOff)
      }
    } else {
      let xOff = max(LayoutUnit(value: UInt64(0)), (legend!.width() - super.borderBefore()) / 2)
      paintRect.setWidth(width: paintRect.width() - xOff)
      if style().blockFlowDirection() == .LeftToRight {
        paintRect.setX(x: paintRect.x() + xOff)
      }
    }
  }

  override final func isInlineBlockOrInlineTable() -> Bool {
    assert(isNativeImpl())
    return isInline() && isReplacedOrInlineBlock()
  }

  func isPointInOverflowControl(
    _ result: inout HitTestResultWrapper, locationInContainer: LayoutPointWrapper,
    accumulatedOffset: LayoutPointWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addOverflowFromChildren() {
    assert(isNativeImpl())
    if childrenInline() {
      addOverflowFromInlineChildren()

      // If this block is flowed inside a flow thread, make sure its overflow is propagated to the containing fragments.
      if overflow != nil, let flow = enclosingFragmentedFlow() {
        flow.addFragmentsVisualOverflow(box: self, visualOverflow: overflow!.visualOverflowRect())
      }
    } else {
      addOverflowFromBlockChildren()
    }
  }

  // FIXME-BLOCKFLOW: Remove virtualization when all callers have moved to RenderBlockFlow
  func addOverflowFromInlineChildren() {}

  private func addOverflowFromBlockChildren() {
    assert(isNativeImpl())
    var child = firstChildBox()
    while child != nil {
      if !child!.isFloatingOrOutOfFlowPositioned() {
        addOverflowFromChild(child: child!)
      }
      child = child!.nextSiblingBox()
    }
  }

  private func addOverflowFromPositionedObjects() {
    assert(isNativeImpl())
    let positionedDescendants = positionedObjects()
    if positionedDescendants == nil {
      return
    }

    let clientBoxRect = flippedClientBoxRect()
    for positionedObject in positionedDescendants! {
      // Fixed positioned elements don't contribute to layout overflow, since they don't scroll with the content.
      if positionedObject.style().position() != .Fixed {
        addOverflowFromChild(
          child: positionedObject,
          delta: LayoutSizeWrapper(width: positionedObject.x(), height: positionedObject.y()),
          flippedClientRect: clientBoxRect)
      }
    }
  }

  private func addVisualOverflowFromTheme() {
    assert(isNativeImpl())
    if !style().hasUsedAppearance() {
      return
    }

    var inflatedRect = borderBoxRect().FloatRect()
    theme().adjustRepaintRect(renderer: self, rect: &inflatedRect)
    addVisualOverflow(
      rect: LayoutRectWrapper(rect: snappedIntRect(rect: LayoutRectWrapper(r: inflatedRect))))

    if let fragmentedFlow = enclosingFragmentedFlow() {
      fragmentedFlow.addFragmentsVisualOverflowFromTheme(block: self)
    }
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    assert(isNativeImpl())
    // For blocks inside inlines, we include margins so that we run right up to the inline boxes
    // above and below us (thus getting merged with them to form a single irregular shape).
    let inlineContinuation = inlineContinuation()
    if inlineContinuation != nil {
      // FIXME: This check really isn't accurate.
      let nextInlineHasLineBox = inlineContinuation!.firstLegacyInlineBox() != nil
      // FIXME: This is wrong. The principal renderer may not be the continuation preceding this block.
      // FIXME: This is wrong for block-flows that are horizontal.
      // https://bugs.webkit.org/show_bug.cgi?id=46781
      let prevInlineHasLineBox =
        (inlineContinuation!.element()!.renderer() as! RenderInlineWrapper)
        .firstLegacyInlineBox() != nil
      let zero = LayoutUnit(value: UInt64(0))
      let topMargin = prevInlineHasLineBox ? collapsedMarginBefore() : zero
      let bottomMargin = nextInlineHasLineBox ? collapsedMarginAfter() : zero
      let rect = LayoutRectWrapper(
        x: additionalOffset.x, y: additionalOffset.y - topMargin, width: width(),
        height: height() + topMargin + bottomMargin)
      if !rect.isEmpty() {
        rects.append(rect)
      }
    } else if width().bool() && height().bool() {
      rects.append(LayoutRectWrapper(location: additionalOffset, size: size()))
    }

    if !hasNonVisibleOverflow() && !hasControlClip() {
      if childrenInline() {
        addFocusRingRectsForInlineChildren(
          rects: &rects[...], additionalOffset: additionalOffset, paintContainer: paintContainer)
      }

      for box: RenderBoxWrapper in childrenOfType(parent: self) {
        if box is RenderListMarkerWrapper {
          continue
        }

        var pos = FloatPoint()
        // FIXME: This doesn't work correctly with transforms.
        if box.layer() != nil {
          var wasFixed: Bool? = nil
          pos = box.localToContainerPoint(
            localPoint: FloatPoint(), container: paintContainer, wasFixed: &wasFixed)
        } else {
          pos = FloatPoint(
            x: (additionalOffset.x + box.x()).float(), y: (additionalOffset.y + box.y()).float())
        }
        box.addFocusRingRects(
          rects: &rects, additionalOffset: flooredLayoutPoint(p: pos),
          paintContainer: paintContainer
        )
      }
    }

    if inlineContinuation != nil {
      inlineContinuation!.addFocusRingRects(
        rects: &rects,
        additionalOffset: flooredLayoutPoint(
          p: LayoutPointWrapper(
            size: additionalOffset + inlineContinuation!.containingBlock()!.location() - location()
          ).FloatPoint()),
        paintContainer: paintContainer)
    }
  }

  func addFocusRingRectsForInlineChildren(
    rects: inout ArraySlice<LayoutRectWrapper>, additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeFragmentRangeForBoxChild(box: RenderBoxWrapper) {
    assert(isNativeImpl())
    let fragmentedFlow = enclosingFragmentedFlow()
    assert(
      canComputeFragmentRangeForBox(
        parentBlock: self, childBox: box, enclosingFragmentedFlow: fragmentedFlow))

    let offsetFromLogicalTopOfFirstFragment = box.offsetFromLogicalTopOfFirstPage()
    let startFragment = fragmentedFlow!.fragmentAtBlockOffset(
      clampBox: self, offset: offsetFromLogicalTopOfFirstFragment, extendLastFragment: true)
    var endFragment: RenderFragmentContainerWrapper? = nil
    if childBoxIsUnsplittableForFragmentation(child: box) {
      endFragment = startFragment
    } else {
      endFragment = fragmentedFlow!.fragmentAtBlockOffset(
        clampBox: self,
        offset: offsetFromLogicalTopOfFirstFragment + logicalHeightForChild(child: box),
        extendLastFragment: true)
    }

    fragmentedFlow!.setFragmentRangeForBox(
      box: box, startFragment: startFragment!, endFragment: endFragment!)
  }

  func estimateFragmentRangeForBoxChild(box: RenderBoxWrapper) {
    assert(isNativeImpl())
    let fragmentedFlow = enclosingFragmentedFlow()
    if !canComputeFragmentRangeForBox(
      parentBlock: self, childBox: box, enclosingFragmentedFlow: fragmentedFlow)
    {
      return
    }

    if childBoxIsUnsplittableForFragmentation(child: box) {
      computeFragmentRangeForBoxChild(box: box)
      return
    }

    let estimatedValues = box.computeLogicalHeight(
      logicalHeight: RenderFragmentedFlowWrapper.maxLogicalHeight(),
      logicalTop: logicalTopForChild(child: box))
    let offsetFromLogicalTopOfFirstFragment = box.offsetFromLogicalTopOfFirstPage()
    let startFragment = fragmentedFlow!.fragmentAtBlockOffset(
      clampBox: self, offset: offsetFromLogicalTopOfFirstFragment, extendLastFragment: true)
    let endFragment = fragmentedFlow!.fragmentAtBlockOffset(
      clampBox: self, offset: offsetFromLogicalTopOfFirstFragment + estimatedValues.extent,
      extendLastFragment: true)

    fragmentedFlow!.setFragmentRangeForBox(
      box: box, startFragment: startFragment!, endFragment: endFragment!)
  }

  func updateFragmentRangeForBoxChild(box: RenderBoxWrapper) -> Bool {
    assert(isNativeImpl())
    let fragmentedFlow = enclosingFragmentedFlow()
    if !canComputeFragmentRangeForBox(
      parentBlock: self, childBox: box, enclosingFragmentedFlow: fragmentedFlow)
    {
      return false
    }

    let (startFragment, endFragment) =
      fragmentedFlow!.getFragmentRangeForBox(box: box) ?? (nil, nil)

    let (newStartFragment, newEndFragment) =
      fragmentedFlow!.getFragmentRangeForBox(box: box) ?? (nil, nil)

    // Changing the start fragment means we shift everything and a relayout is needed.
    if CPtrToInt(newStartFragment?.id()) != CPtrToInt(startFragment?.id()) {
      return true
    }

    // The fragment range of the box has changed. Some boxes (e.g floats) may have been positioned assuming
    // a different range.
    if box.needsLayoutAfterFragmentRangeChange()
      && CPtrToInt(newEndFragment?.id()) != CPtrToInt(endFragment?.id())
    {
      return true
    }

    return false
  }

  func updateBlockChildDirtyBitsBeforeLayout(relayoutChildren: Bool, child: RenderBoxWrapper) {
    assert(isNativeImpl())
    if child.isOutOfFlowPositioned() {
      return
    }

    // FIXME: Technically percentage height objects only need a relayout if their percentage isn't going to be turned into
    // an auto value. Add a method to determine this, so that we can avoid the relayout.
    if relayoutChildren || (child.hasRelativeLogicalHeight() && !isRenderView()) {
      child.setChildNeedsLayout(markParents: .MarkOnlyThis)
    }

    // If relayoutChildren is set and the child has percentage padding or an embedded content box, we also need to invalidate the childs pref widths.
    if relayoutChildren && child.needsPreferredWidthsRecalculation() {
      child.setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)
    }
  }

  func preparePaginationBeforeBlockLayout(relayoutChildren: inout Bool) {
    assert(isNativeImpl())
    // Fragments changing widths can force us to relayout our children.
    if let fragmentedFlow = enclosingFragmentedFlow() {
      fragmentedFlow.logicalWidthChangedInFragmentsForBlock(
        block: self, relayoutChildren: &relayoutChildren)
    }
  }

  func computeChildPreferredLogicalWidths(child: RenderObjectWrapper) -> (LayoutUnit, LayoutUnit) {
    assert(isNativeImpl())
    if let box = child as? RenderBoxWrapper,
      box.isHorizontalWritingMode() != isHorizontalWritingMode()
    {
      // If the child is an orthogonal flow, child's height determines the width,
      // but the height is not available until layout.
      // http://dev.w3.org/csswg/css-writing-modes-3/#orthogonal-shrink-to-fit
      if !box.needsLayout() {
        let maxPreferredLogicalWidth = box.logicalHeight()
        return (maxPreferredLogicalWidth, maxPreferredLogicalWidth)
      }
      if box.shouldComputeLogicalHeightFromAspectRatio() && box.style().logicalWidth().isFixed() {
        let logicalWidth = LayoutUnit(value: box.style().logicalWidth().value())
        let maxPreferredLogicalWidth = RenderBoxWrapper.blockSizeFromAspectRatio(
          borderPaddingInlineSum: box.horizontalBorderAndPaddingExtent(),
          borderPaddingBlockSum: box.verticalBorderAndPaddingExtent(),
          aspectRatio: LayoutUnit(value: box.style().logicalAspectRatio()).double(),
          boxSizing: box.style().boxSizingForAspectRatio(),
          inlineSize: logicalWidth, aspectRatioType: style().aspectRatioType(),
          isRenderReplaced: isRenderReplaced())
        return (maxPreferredLogicalWidth, maxPreferredLogicalWidth)
      }
      let maxPreferredLogicalWidth = box.computeLogicalHeightWithoutLayout()
      return (maxPreferredLogicalWidth, maxPreferredLogicalWidth)
    }

    var (minPreferredLogicalWidth, maxPreferredLogicalWidth) = computeChildIntrinsicLogicalWidths(
      child: child)

    // For non-replaced blocks if the inline size is min|max-content or a definite
    // size the min|max-content contribution is that size plus border, padding and
    // margin https://drafts.csswg.org/css-sizing/#block-intrinsic
    if child.isRenderBlock() {
      let computedInlineSize = child.style().logicalWidth()
      if computedInlineSize.isMaxContent() {
        minPreferredLogicalWidth = maxPreferredLogicalWidth
      } else if computedInlineSize.isMinContent() {
        maxPreferredLogicalWidth = minPreferredLogicalWidth
      }
    }

    return (minPreferredLogicalWidth, maxPreferredLogicalWidth)
  }

  func computeChildIntrinsicLogicalWidths(child: RenderObjectWrapper) -> (LayoutUnit, LayoutUnit) {
    assert(isNativeImpl())
    return (child.minPreferredLogicalWidth(), child.maxPreferredLogicalWidth())
  }

  private func createAnonymousBlockWithStyleAndDisplay(
    document: Document, style: RenderStyleWrapper, display: DisplayType
  ) -> RenderBlockWrapper? {
    assert(isNativeImpl())
    // FIXME: Do we need to convert all our inline displays to block-type in the anonymous logic ?
    var newBox: RenderBlockWrapper? = nil
    if display == .Flex || display == .InlineFlex {
      newBox = CreateRenderer.RenderFlexibleBox(
        type: .FlexibleBox, document: document,
        style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: style, display: .Flex))
    } else {
      newBox = CreateRenderer.RenderBlockFlow(
        type: .BlockFlow, document: document,
        style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: style, display: .Block))
    }

    newBox!.initializeStyle()
    return newBox
  }

  func adjustLogicalRightOffsetForLine(_ offsetFromFloats: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    var right = offsetFromFloats

    if style().lineAlign() == .None {
      return right
    }

    // Push in our right offset so that it is aligned with the character grid.
    let layoutState = view().frameView().layoutContext().layoutState()
    if layoutState == nil {
      return right
    }

    let lineGrid = layoutState!.lineGrid()
    if lineGrid == nil || lineGrid!.style().writingMode() != style().writingMode() {
      return right
    }

    // FIXME: Should letter-spacing apply? This is complicated since it doesn't apply at the edge?
    let maxCharWidth = lineGrid!.style().fontCascade().primaryFont().maxCharWidth()
    if maxCharWidth == 0 {
      return right
    }

    let lineGridOffset =
      lineGrid!.isHorizontalWritingMode()
      ? layoutState!.lineGridOffset().width() : layoutState!.lineGridOffset().height()
    let layoutOffset =
      lineGrid!.isHorizontalWritingMode()
      ? layoutState!.layoutOffset().width() : layoutState!.layoutOffset().height()

    // Push in to the nearest character width (truncated so that we pixel snap right).
    // FIXME: Should be patched when subpixel layout lands, since this calculation doesn't have to pixel snap
    // any more (https://bugs.webkit.org/show_bug.cgi?id=79946).
    // FIXME: This is wrong for RTL (https://bugs.webkit.org/show_bug.cgi?id=79945).
    // FIXME: This doesn't work with columns or fragments (https://bugs.webkit.org/show_bug.cgi?id=79942).
    // FIXME: This doesn't work when the inline position of the object isn't set ahead of time.
    // FIXME: Dynamic changes to the font or to the inline position need to result in a deep relayout.
    // (https://bugs.webkit.org/show_bug.cgi?id=79944)
    let remainder = fmodf(
      fmodf((right + layoutOffset - lineGridOffset).float(), maxCharWidth), maxCharWidth)
    right -= ceilf(remainder)
    return right
  }

  func adjustLogicalLeftOffsetForLine(_ offsetFromFloats: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    var left = offsetFromFloats

    if style().lineAlign() == .None {
      return left
    }

    // Push in our left offset so that it is aligned with the character grid.
    let layoutState = view().frameView().layoutContext().layoutState()
    if layoutState == nil {
      return left
    }

    let lineGrid = layoutState!.lineGrid()
    if lineGrid == nil || lineGrid!.style().writingMode() != style().writingMode() {
      return left
    }

    // FIXME: Should letter-spacing apply? This is complicated since it doesn't apply at the edge?
    let maxCharWidth = lineGrid!.style().fontCascade().primaryFont().maxCharWidth()
    if maxCharWidth == 0 {
      return left
    }

    let lineGridOffset =
      lineGrid!.isHorizontalWritingMode()
      ? layoutState!.lineGridOffset().width() : layoutState!.lineGridOffset().height()
    let layoutOffset =
      lineGrid!.isHorizontalWritingMode()
      ? layoutState!.layoutOffset().width() : layoutState!.layoutOffset().height()

    // Push in to the nearest character width (truncated so that we pixel snap left).
    // FIXME: Should be patched when subpixel layout lands, since this calculation doesn't have to pixel snap
    // any more (https://bugs.webkit.org/show_bug.cgi?id=79946).
    // FIXME: This is wrong for RTL (https://bugs.webkit.org/show_bug.cgi?id=79945).
    // FIXME: This doesn't work with columns or fragments (https://bugs.webkit.org/show_bug.cgi?id=79942).
    // FIXME: This doesn't work when the inline position of the object isn't set ahead of time.
    // FIXME: Dynamic changes to the font or to the inline position need to result in a deep relayout.
    // (https://bugs.webkit.org/show_bug.cgi?id=79944)
    let remainder = fmodf(
      maxCharWidth - fmodf((left + layoutOffset - lineGridOffset).float(), maxCharWidth),
      maxCharWidth)
    left += remainder
    return left
  }

  override func isSelfCollapsingBlock() -> Bool {
    if !isNativeImpl() { return wk_interop.RenderBlock_isSelfCollapsingBlock(id()) }
    // We are not self-collapsing if we
    // (a) have a non-zero height according to layout (an optimization to avoid wasting time)
    // (b) are a table,
    // (c) have border/padding,
    // (d) have a min-height
    // (e) have specified that one of our margins can't collapse using a CSS extension
    if logicalHeight() > 0
      || isRenderTable() || borderAndPaddingLogicalHeight().bool()
      || style().logicalMinHeight().isPositive()
    {
      return false
    }

    let logicalHeightLength = style().logicalHeight()
    var hasAutoHeight = logicalHeightLength.isAuto()
    if logicalHeightLength.isPercentOrCalculated() && !document().inQuirksMode() {
      hasAutoHeight = true
      var cb = containingBlock()
      while cb != nil && !(cb is RenderViewWrapper) {
        if cb!.style().logicalHeight().isFixed() || cb!.isRenderTableCell() {
          hasAutoHeight = false
        }
        cb = cb!.containingBlock()
      }
    }

    // If the height is 0 or auto, then whether or not we are a self-collapsing block depends
    // on whether we have content that is all self-collapsing or not.
    if hasAutoHeight
      || ((logicalHeightLength.isFixed() || logicalHeightLength.isPercentOrCalculated())
        && logicalHeightLength.isZero())
    {
      return !createsNewFormattingContext() && !childrenPreventSelfCollapsing()
    }

    return false
  }

  func childrenPreventSelfCollapsing() -> Bool {
    assert(isNativeImpl())
    // Whether or not we collapse is dependent on whether all our normal flow children
    // are also self-collapsing.
    var child = firstChildBox()
    while child != nil {
      if child!.isFloatingOrOutOfFlowPositioned() {
        child = child!.nextSiblingBox()
        continue
      }
      if !child!.isSelfCollapsingBlock() {
        return true
      }
      child = child!.nextSiblingBox()
    }
    return false
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
  func paintFloats(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, preservePhase: Bool = false
  ) {}

  func paintInlineChildren(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {}

  private func paintContents(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    if isSkippedContentRoot() {
      return
    }

    if childrenInline() {
      paintInlineChildren(paintInfo: paintInfo, paintOffset: paintOffset)
    } else {
      var newPhase = (paintInfo.phase == .ChildOutlines) ? .Outline : paintInfo.phase
      newPhase = (newPhase == .ChildBlockBackgrounds) ? .ChildBlockBackground : newPhase

      // We don't paint our own background, but we do let the kids paint their backgrounds.
      var paintInfoForChild = paintInfo
      paintInfoForChild.phase = newPhase
      paintInfoForChild.updateSubtreePaintRootForChildren(renderer: self)

      if paintInfo.eventRegionContext() != nil {
        paintInfoForChild.paintBehavior.update(with: .EventRegionIncludeBackground)
      }

      // FIXME: Paint-time pagination is obsolete and is now only used by embedded WebViews inside AppKit
      // NSViews. Do not add any more code for this.
      let usePrintRect = !view().printRect().isEmpty()
      paintChildren(
        paintInfo: paintInfo, paintOffset: paintOffset, paintInfoForChild: &paintInfoForChild,
        usePrintRect: usePrintRect)
    }
  }

  func paintColumnRules(_ paintInfo: PaintInfoWrapper, _ point: LayoutPointWrapper) {}

  private func paintSelection(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintCaret(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, type: CaretType
  ) {
    assert(isNativeImpl())
    let shouldPaintCaret = {
      [self] (_ caretPainter: RenderBlockWrapper, _ isContentEditable: Bool) in
      if CPtrToInt(caretPainter.id()) != CPtrToInt(id()) {
        return false
      }

      return isContentEditable || settings().caretBrowsingEnabled()
    }

    switch type {
    case .CursorCaret:
      if let caretPainter = frame().selection().caretRendererWithoutUpdatingLayout() {
        let isContentEditable = frame().selection().selection().hasEditableStyle()

        if shouldPaintCaret(caretPainter, isContentEditable) {
          frame().selection().paintCaret(context: paintInfo.context(), paintOffset: paintOffset)
        }
      }
    case .DragCaret:
      if let caretPainter = page().dragCaretController().caretRenderer() {
        let isContentEditable = page().dragCaretController().isContentEditable()

        if shouldPaintCaret(caretPainter, isContentEditable) {
          page().dragCaretController().paintDragCaret(
            frame: frame(), p: paintInfo.context(), paintOffset: paintOffset)
        }
      }
    }
  }

  private func paintCarets(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    if paintInfo.phase == .Foreground {
      paintCaret(paintInfo: paintInfo, paintOffset: paintOffset, type: .CursorCaret)
      paintCaret(paintInfo: paintInfo, paintOffset: paintOffset, type: .DragCaret)
    }
  }

  func hitTestChildren(
    _ request: HitTestRequestWrapper, _ result: HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ adjustedLocation: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hitTestExcludedChildrenInBorder(
    _ request: HitTestRequestWrapper, _ result: HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeBlockPreferredLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    assert(isNativeImpl())
    assert(!shouldApplyInlineSizeContainment())

    let styleToUse = style()
    let nowrap =
      styleToUse.textWrapMode() == .NoWrap && styleToUse.whiteSpaceCollapse() == .Collapse

    var child = firstChild()
    let containingBlock = containingBlock()
    var floatLeftWidth = LayoutUnit()
    var floatRightWidth = LayoutUnit()

    if let (childMinWidth, childMaxWidth) = computePreferredWidthsForExcludedChildren() {
      minLogicalWidth = max(childMinWidth, minLogicalWidth)
      maxLogicalWidth = max(childMaxWidth, maxLogicalWidth)
    }

    while child != nil {
      // Positioned children don't affect the min/max width. Legends in fieldsets are skipped here
      // since they compute outside of any one layout system. Other children excluded from
      // normal layout are only used with block flows, so it's ok to calculate them here.
      if child!.isOutOfFlowPositioned() || child!.isExcludedAndPlacedInBorder() {
        child = child!.nextSibling()
        continue
      }

      let childStyle = child!.style()
      // Either the box itself of its content avoids floats.
      let childBox = child as? RenderBoxWrapper
      let childAvoidsFloats =
        childBox != nil
        ? childBox!.avoidsFloats() || (childBox!.isAnonymousBlock() && childBox!.childrenInline())
        : false
      if child!.isFloating() || childAvoidsFloats {
        let floatTotalWidth = floatLeftWidth + floatRightWidth
        let childUsedClear = RenderStyleWrapper.usedClear(renderer: child!)
        if childUsedClear == .Left || childUsedClear == .Both {
          maxLogicalWidth = max(floatTotalWidth, maxLogicalWidth)
          floatLeftWidth = LayoutUnit(value: 0)
        }
        if childUsedClear == .Right || childUsedClear == .Both {
          maxLogicalWidth = max(floatTotalWidth, maxLogicalWidth)
          floatRightWidth = LayoutUnit(value: 0)
        }
      }

      // A margin basically has three types: fixed, percentage, and auto (variable).
      // Auto and percentage margins simply become 0 when computing min/max width.
      // Fixed margins can be added in as is.
      let startMarginLength = childStyle.marginStartUsing(otherStyle: styleToUse)
      let endMarginLength = childStyle.marginEndUsing(otherStyle: styleToUse)
      var margin = LayoutUnit()
      var marginStart = LayoutUnit()
      var marginEnd = LayoutUnit()
      if startMarginLength.isFixed() {
        marginStart += startMarginLength.value()
      }
      if endMarginLength.isFixed() {
        marginEnd += endMarginLength.value()
      }
      margin = marginStart + marginEnd

      let (childMinPreferredLogicalWidth, childMaxPreferredLogicalWidth) =
        computeChildPreferredLogicalWidths(child: child!)

      var w = childMinPreferredLogicalWidth + margin
      minLogicalWidth = max(w, minLogicalWidth)

      // IE ignores tables for calculation of nowrap. Makes some sense.
      if nowrap && !child!.isRenderTable() {
        maxLogicalWidth = max(w, maxLogicalWidth)
      }

      w = childMaxPreferredLogicalWidth + margin

      if !child!.isFloating() {
        if childAvoidsFloats {
          // Determine a left and right max value based off whether or not the floats can fit in the
          // margins of the object.  For negative margins, we will attempt to overlap the float if the negative margin
          // is smaller than the float width.
          let ltr =
            containingBlock != nil
            ? containingBlock!.style().isLeftToRightDirection()
            : styleToUse.isLeftToRightDirection()
          let marginLogicalLeft = ltr ? marginStart : marginEnd
          let marginLogicalRight = ltr ? marginEnd : marginStart
          let maxLeft =
            marginLogicalLeft > 0
            ? max(floatLeftWidth, marginLogicalLeft) : floatLeftWidth + marginLogicalLeft
          let maxRight =
            marginLogicalRight > 0
            ? max(floatRightWidth, marginLogicalRight) : floatRightWidth + marginLogicalRight
          w = childMaxPreferredLogicalWidth + maxLeft + maxRight
          w = max(w, floatLeftWidth + floatRightWidth)
        } else {
          maxLogicalWidth = max(floatLeftWidth + floatRightWidth, maxLogicalWidth)
        }
        floatLeftWidth = LayoutUnit(value: 0)
        floatRightWidth = LayoutUnit(value: 0)
      }

      if child!.isFloating() {
        if RenderStyleWrapper.usedFloat(renderer: child!) == .Left {
          floatLeftWidth += w
        } else {
          floatRightWidth += w
        }
      } else {
        maxLogicalWidth = max(w, maxLogicalWidth)
      }

      child = child!.nextSibling()
    }

    // Always make sure these values are non-negative.
    minLogicalWidth = max(LayoutUnit(value: 0), minLogicalWidth)
    maxLogicalWidth = max(LayoutUnit(value: 0), maxLogicalWidth)

    maxLogicalWidth = max(floatLeftWidth + floatRightWidth, maxLogicalWidth)
  }

  override final func rectWithOutlineForRepaint(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ outlineWidth: LayoutUnit
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintContinuationOutlines(info: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
  func positionForPointWithInlineChildren(
    _ pointInLogicalContents: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    fatalError("Not reached")
  }

  private func removePositionedObjectsIfNeeded(
    oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
  ) {
    assert(isNativeImpl())
    let hadTransform = oldStyle.hasTransformRelatedProperty()
    let willHaveTransform = newStyle.hasTransformRelatedProperty()
    let hadLayoutContainment = oldStyle.containsLayout()
    let willHaveLayoutContainment = newStyle.containsLayout()
    if oldStyle.position() == newStyle.position() && hadTransform == willHaveTransform
      && hadLayoutContainment == willHaveLayoutContainment
    {
      return
    }

    // We are no longer the containing block for out-of-flow descendants.
    var outOfFlowDescendantsHaveNewContainingBlock =
      (hadTransform && !willHaveTransform) || (newStyle.position() == .Static && !willHaveTransform)
    if hadLayoutContainment != willHaveLayoutContainment {
      outOfFlowDescendantsHaveNewContainingBlock =
        hadLayoutContainment && !willHaveLayoutContainment
    }
    if outOfFlowDescendantsHaveNewContainingBlock {
      // Our out-of-flow descendants will be inserted into a new containing block's positioned objects list during the next layout.
      removePositionedObjects(
        newContainingBlockCandidate: nil, containingBlockState: .NewContainingBlock)
      return
    }

    // We are a new containing block.
    if oldStyle.position() == .Static && !hadTransform {
      // Remove our absolutely positioned descendants from their current containing block.
      // They will be inserted into our positioned objects list during layout.
      var containingBlock = parent()
      while containingBlock != nil && !(containingBlock is RenderViewWrapper)
        && (containingBlock!.style().position() == .Static
          || (containingBlock!.isInline() && !containingBlock!.isReplacedOrInlineBlock()))
      {
        if containingBlock!.style().position() == .Relative && containingBlock!.isInline()
          && !containingBlock!.isReplacedOrInlineBlock()
        {
          containingBlock = containingBlock!.containingBlock()
          break
        }
        containingBlock = containingBlock!.parent()
      }
      if let renderBlock = containingBlock as? RenderBlockWrapper {
        renderBlock.removePositionedObjects(
          newContainingBlockCandidate: self, containingBlockState: .NewContainingBlock)
      }
    }
  }

  private func paintDebugBoxShadowIfApplicable(
    context: GraphicsContextWrapper, paintRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dirtyForLayoutFromPercentageHeightDescendants() {
    assert(isNativeImpl())
    if percentHeightDescendantsMap == nil {
      return
    }

    let descendants = percentHeightDescendantsMap![CPtrToInt(id())]
    if descendants == nil {
      return
    }

    for descendant in descendants! {
      // Let's not dirty the height perecentage descendant when it has an absolutely positioned containing block ancestor. We should be able to dirty such boxes through the regular invalidation logic.
      var descendantNeedsLayout = true
      var ancestor = descendant.containingBlock()
      while ancestor != nil && CPtrToInt(ancestor!.id()) != CPtrToInt(id()) {
        if ancestor!.isOutOfFlowPositioned() {
          descendantNeedsLayout = false
          break
        }
        ancestor = ancestor!.containingBlock()
      }
      if !descendantNeedsLayout {
        continue
      }

      var renderer: RenderElementWrapper = descendant
      while CPtrToInt(renderer.id()) != CPtrToInt(id()) {
        if renderer.normalChildNeedsLayout() {
          break
        }
        renderer.setChildNeedsLayout(markParents: .MarkOnlyThis)

        // If the width of an image is affected by the height of a child (e.g., an image with an aspect ratio),
        // then we have to dirty preferred widths, since even enclosing blocks can become dirty as a result.
        // (A horizontal flexbox that contains an inline image wrapped in an anonymous block for example.)
        if renderer.hasIntrinsicAspectRatio() || renderer.style().hasAspectRatio() {
          renderer.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
        }
        renderer = renderer.container()!
      }
    }
  }

  private func getBlockRareData() -> RenderBlockRareData? {
    assert(isNativeImpl())
    if !renderBlockHasRareData {
      return nil
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func recomputeLogicalWidth() -> Bool {
    assert(isNativeImpl())
    let oldWidth = logicalWidth()

    updateLogicalWidth()

    let hasBorderOrPaddingLogicalWidthChanged = hasBorderOrPaddingLogicalWidthChanged()
    setShouldForceRelayoutChildren(b: false)

    return oldWidth != logicalWidth() || hasBorderOrPaddingLogicalWidthChanged
  }

  override func offsetFromLogicalTopOfFirstPage() -> LayoutUnit {
    assert(isNativeImpl())
    let layoutState = view().frameView().layoutContext().layoutState()
    if layoutState != nil && !layoutState!.isPaginated() {
      return LayoutUnit(value: 0)
    }

    if let fragmentedFlow = enclosingFragmentedFlow() {
      return fragmentedFlow.offsetFromLogicalTopOfFirstFragment(currentBlock: self)
    }

    if layoutState != nil {
      assert(CPtrToInt(layoutState!.renderer()?.id()) == CPtrToInt(id()))

      let offsetDelta = layoutState!.layoutOffset() - layoutState!.pageOffset()
      return isHorizontalWritingMode() ? offsetDelta.height() : offsetDelta.width()
    }

    fatalError("Not reached")
  }

  func fragmentAtBlockOffset(blockOffset: LayoutUnit) -> RenderFragmentContainerWrapper? {
    assert(isNativeImpl())
    if let fragmentedFlow = enclosingFragmentedFlow(), fragmentedFlow.hasValidFragmentInfo() {
      return fragmentedFlow.fragmentAtBlockOffset(
        clampBox: self, offset: offsetFromLogicalTopOfFirstPage() + blockOffset,
        extendLastFragment: true)
    }
    return nil
  }

  var floatingObjectSet: FloatingObjectSet? = nil

  // Used to store state between styleWillChange and styleDidChange
  static var canPropagateFloatIntoSibling = false
}
