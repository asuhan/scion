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

import wk_interop

typealias TrackedRendererListHashSet = ListSet<RenderBoxWrapper, UInt>

enum CaretType {
  case CursorCaret
  case DragCaret
}

enum ContainingBlockState {
  case NewContainingBlock
  case SameContainingBlock
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
      || CPtrToInt(parentBlock!.firstChild()?.p) != CPtrToInt(firstLetterBlock!.p)
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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class RenderBlockWrapper: RenderBoxWrapper {
  // These two functions are overridden for inline-block.
  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
  func deleteLines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutBlock(
    relayoutChildren: Bool, pageLogicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func insertPositionedObject(positioned: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func removePositionedObject(rendererToRemove: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removePositionedObjects(
    newContainingBlockCandidate: RenderBlockWrapper?,
    containingBlockState: ContainingBlockState = .SameContainingBlock
  ) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  static func hasPercentHeightContainerMap() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func hasPercentHeightDescendant(descendant: RenderBoxWrapper) -> Bool {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasMarginBeforeQuirk(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasMarginAfterQuirk(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasMarginBeforeQuirk(child: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasMarginAfterQuirk(child: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all of the line layout code has been moved out of RenderBlock
  func containsFloats() -> Bool {
    return wk_interop.RenderBlock_containsFloats(p)
  }

  // Versions that can compute line offsets with the fragment and page offset passed in. Used for speed to avoid having to
  // compute the fragment all over again when you already know it.
  func availableLogicalWidthForLineInFragment(
    position: LayoutUnit, fragment: RenderFragmentContainerWrapper?,
    logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func startOffsetForLineInFragment(
    position: LayoutUnit, fragment: RenderFragmentContainerWrapper?,
    logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endOffsetForLineInFragment(
    position: LayoutUnit, fragment: RenderFragmentContainerWrapper?,
    logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func availableLogicalWidthForLine(
    position: LayoutUnit, logicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func addContinuationWithOutline(flow: RenderInlineWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createAnonymousBlock(display: DisplayType = .Block) -> RenderBlockWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    return createAnonymousBlockWithStyleAndDisplay(
      document: document(), style: renderer.style(), display: style().display())
  }

  func paginationStrut() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPaginationStrut(strut: LayoutUnit) {
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
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBlock_intrinsicBorderForFieldset(p))
  }

  private func setIntrinsicBorderForFieldset(padding: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func adjustContentBoxLogicalHeightForBoxSizing(height: LayoutUnit?) -> LayoutUnit {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func logicalLeftForChild(child: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLogicalLeftForChild(
    child: RenderBoxWrapper, logicalLeft: LayoutUnit,
    applyDelta: ApplyLayoutDeltaMode = .DoNotApplyLayoutDelta
  ) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginAfterForChild(child: RenderBoxModelObjectWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginStartForChild(child: RenderBoxModelObjectWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func marginEndForChild(child: RenderBoxModelObjectWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setMarginStartForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setMarginEndForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMarginBeforeForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setMarginAfterForChild(child: RenderBoxWrapper, value: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTrimmedMarginForChild(child: RenderBoxWrapper, marginTrimType: MarginTrimType) {
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
        if CPtrToInt(firstLetter!.p) == CPtrToInt(skipObject?.p) {
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

  func startOffsetForContent(fragment: RenderFragmentContainerWrapper?) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endOffsetForContent(fragment: RenderFragmentContainerWrapper?) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func startOffsetForContent(blockOffset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalLeftOffsetForContent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func availableLogicalWidthForContent(blockOffset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canDropAnonymousBlockChild() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  final func resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants(
    fragmentedFlow: RenderFragmentedFlowWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func availableLogicalHeightForPercentageComputation() -> LayoutUnit? {
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

  func hasDefiniteLogicalHeight() -> Bool { return renderBlockHasDefiniteLogicalHeight() }

  func renderBlockHasDefiniteLogicalHeight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasLineIfEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateDescendantTransformsAfterLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutPositionedObjects(relayoutChildren: Bool, fixedPositionObjectsOnly: Bool = false) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginIntrinsicLogicalWidthForChild(child: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
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
      paintColumnRules(paintInfo: paintInfo, point: scrolledOffset)
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
        while CPtrToInt(box?.p) != CPtrToInt(containingBlock?.p) {
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

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
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

  override func firstLineBaseline() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func lastLineBaseline() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func canPerformSimplifiedLayout() -> Bool {
    return renderBlockCanPerformSimplifiedLayout()
  }

  func renderBlockCanPerformSimplifiedLayout() -> Bool {
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
    if !canPerformSimplifiedLayout() {
      return false
    }

    let _ = LayoutStateMaintainer(
      root: self, offset: locationOffset(),
      disablePaintOffsetCache: isTransformed() || hasReflection()
        || style().isFlippedBlocksWritingMode())
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Overflow is always relative to the border-box of the element in question.
  // Therefore, if the element has a vertical scrollbar placed on the left, an overflow rect at x=2px would conceptually intersect the scrollbar.
  func computeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool = false) {
    return renderBlockComputeOverflow(
      oldClientAfterEdge: oldClientAfterEdge, recomputeFloats: recomputeFloats)
  }

  func renderBlockComputeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool) {
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
      if CPtrToInt(child.p) == CPtrToInt(box!.p) || !child.isLegend() {
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
    return isInline() && isReplacedOrInlineBlock()
  }

  func addOverflowFromChildren() {
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
    var child = firstChildBox()
    while child != nil {
      if !child!.isFloatingOrOutOfFlowPositioned() {
        addOverflowFromChild(child: child!)
      }
      child = child!.nextSiblingBox()
    }
  }

  private func addOverflowFromPositionedObjects() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func addVisualOverflowFromTheme() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeFragmentRangeForBoxChild(box: RenderBoxWrapper) {
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
      box: box, startFragment: startFragment, endFragment: endFragment)
  }

  func estimateFragmentRangeForBoxChild(box: RenderBoxWrapper) {
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
      box: box, startFragment: startFragment, endFragment: endFragment)
  }

  func updateFragmentRangeForBoxChild(box: RenderBoxWrapper) -> Bool {
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
    if CPtrToInt(newStartFragment?.p) != CPtrToInt(startFragment?.p) {
      return true
    }

    // The fragment range of the box has changed. Some boxes (e.g floats) may have been positioned assuming
    // a different range.
    if box.needsLayoutAfterFragmentRangeChange()
      && CPtrToInt(newEndFragment?.p) != CPtrToInt(endFragment?.p)
    {
      return true
    }

    return false
  }

  func updateBlockChildDirtyBitsBeforeLayout(relayoutChildren: Bool, child: RenderBoxWrapper) {
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
    // Fragments changing widths can force us to relayout our children.
    if let fragmentedFlow = enclosingFragmentedFlow() {
      fragmentedFlow.logicalWidthChangedInFragmentsForBlock(
        block: self, relayoutChildren: &relayoutChildren)
    }
  }

  func computeChildPreferredLogicalWidths(child: RenderObjectWrapper) -> (LayoutUnit, LayoutUnit) {
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
    return (child.minPreferredLogicalWidth(), child.maxPreferredLogicalWidth())
  }

  private func createAnonymousBlockWithStyleAndDisplay(
    document: Document, style: RenderStyleWrapper, display: DisplayType
  ) -> RenderBlockWrapper? {
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

  override func isSelfCollapsingBlock() -> Bool {
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

  func paintColumnRules(paintInfo: PaintInfoWrapper, point: LayoutPointWrapper) {}

  private func paintSelection(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintCaret(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, type: CaretType
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintCarets(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.phase == .Foreground {
      paintCaret(paintInfo: paintInfo, paintOffset: paintOffset, type: .CursorCaret)
      paintCaret(paintInfo: paintInfo, paintOffset: paintOffset, type: .DragCaret)
    }
  }

  func computeBlockPreferredLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
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

  private func paintContinuationOutlines(info: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintDebugBoxShadowIfApplicable(
    context: GraphicsContextWrapper, paintRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dirtyForLayoutFromPercentageHeightDescendants() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func recomputeLogicalWidth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func offsetFromLogicalTopOfFirstPage() -> LayoutUnit {
    let layoutState = view().frameView().layoutContext().layoutState()
    if layoutState != nil && !layoutState!.isPaginated() {
      return LayoutUnit(value: 0)
    }

    if let fragmentedFlow = enclosingFragmentedFlow() {
      return fragmentedFlow.offsetFromLogicalTopOfFirstFragment(currentBlock: self)
    }

    if layoutState != nil {
      assert(CPtrToInt(layoutState!.renderer()?.p) == CPtrToInt(p))

      let offsetDelta = layoutState!.layoutOffset() - layoutState!.pageOffset()
      return isHorizontalWritingMode() ? offsetDelta.height() : offsetDelta.width()
    }

    fatalError("Not reached")
  }

  func fragmentAtBlockOffset(blockOffset: LayoutUnit) -> RenderFragmentContainerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var floatingObjectSet: FloatingObjectSet? = nil
}
