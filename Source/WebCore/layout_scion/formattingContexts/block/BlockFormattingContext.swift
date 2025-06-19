/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

// This class implements the layout logic for block formatting contexts.
// https://www.w3.org/TR/CSS22/visuren.html#block-formatting
class BlockFormattingContext: FormattingContext {
  init(formattingContextRoot: ElementBoxWrapper, blockFormattingState: BlockFormattingState) {
    super.init(
      formattingContextRoot: formattingContextRoot, layoutState: blockFormattingState.layoutState)
    self.blockFormattingState = blockFormattingState
    self.blockFormattingGeometry = BlockFormattingGeometry(formattingContext: self)
    self.blockFormattingQuirks = BlockFormattingQuirks(blockFormattingContext: self)
  }

  internal enum LayoutDirection {
    case Child
    case Sibling
  }

  override func layoutInFlowContent(constraints: ConstraintsForInFlowContent) {
    // 9.4.1 Block formatting contexts
    // In a block formatting context, boxes are laid out one after the other, vertically, beginning at the top of a containing block.
    // The vertical distance between two sibling boxes is determined by the 'margin' properties.
    // Vertical margins between adjacent block-level boxes in a block formatting context collapse.
    let formattingRoot = root
    assert(formattingRoot.hasInFlowOrFloatingChild())
    let placedFloats = formattingState().placedFloats!
    let floatingContext = FloatingContext(
      formattingContextRoot: root, layoutState: layoutState, placedFloats: placedFloats)

    var layoutQueue: [ElementBoxWrapper] = []

    // This is a post-order tree traversal layout.
    // The root container layout is done in the formatting context it lives in, not that one it creates, so let's start with the first child.
    BlockFormattingContext.appendNextToLayoutQueue(
      layoutBox: formattingRoot, direction: LayoutDirection.Child, layoutQueue: &layoutQueue)
    // 1. Go all the way down to the leaf node
    // 2. Compute static position and width as we traverse down
    // 3. As we climb back on the tree, compute height and finialize position
    // (Any subtrees with new formatting contexts need to layout synchronously)
    while !layoutQueue.isEmpty {
      // Traverse down on the descendants and compute width/static position until we find a leaf node.
      while true {
        let layoutBox = layoutQueue.last!
        let containingBlockConstraints = constraintsForLayoutBoxInFlow(
          layoutBox: layoutBox, constraints: constraints, formattingRoot: formattingRoot)

        computeBorderAndPadding(
          layoutBox: layoutBox, horizontalConstraint: containingBlockConstraints.horizontal)
        computeStaticVerticalPosition(
          layoutBox: layoutBox,
          containingBlockContentBoxTop: containingBlockConstraints.logicalTop)
        computeWidthAndMargin(
          floatingContext: floatingContext, layoutBox: layoutBox,
          constraintsPair: ConstraintsPair(
            formattingContextRoot: constraints, containingBlock: containingBlockConstraints))
        computeStaticHorizontalPosition(
          layoutBox: layoutBox, horizontalConstraints: containingBlockConstraints.horizontal)
        computePositionToAvoidFloats(
          floatingContext: floatingContext, layoutBox: layoutBox,
          constraintsPair: ConstraintsPair(
            formattingContextRoot: constraints, containingBlock: containingBlockConstraints))

        if layoutBox.establishesFormattingContext() {
          if layoutBox.hasInFlowOrFloatingChild() {
            if layoutBox.establishesInlineFormattingContext() {
              // IFCs inherit floats from parent FCs. We need final vertical position to find intruding floats.
              precomputeVerticalPositionForBoxAndAncestors(
                layoutBox: layoutBox,
                constraintsPair: ConstraintsPair(
                  formattingContextRoot: constraints, containingBlock: containingBlockConstraints))
            }
            // Layout the inflow descendants of this formatting context root.
            let formattingContext = LayoutContext.createFormattingContext(
              formattingContextRoot: layoutBox, layoutState: layoutState)
            if layoutBox.isTableWrapperBox() {
              (formattingContext as! TableWrapperBlockFormattingContext)
                .setHorizontalConstraintsIgnoringFloats(
                  horizontalConstraints: containingBlockConstraints.horizontal)
            }
            formattingContext.layoutInFlowContent(
              constraints: formattingGeometry().constraintsForInFlowContent(elementBox: layoutBox))
          }
          break
        }
        if !BlockFormattingContext.appendNextToLayoutQueue(
          layoutBox: layoutBox, direction: .Child, layoutQueue: &layoutQueue)
        {
          break
        }
      }

      // Climb back on the ancestors and compute height/final position.
      while !layoutQueue.isEmpty {
        let layoutBox = layoutQueue.removeLast()
        let containingBlockConstraints = constraintsForLayoutBoxInFlow(
          layoutBox: layoutBox, constraints: constraints, formattingRoot: formattingRoot)

        // All inflow descendants (if there are any) are laid out by now. Let's compute the box's height and vertical margin.
        computeHeightAndMargin(layoutBox: layoutBox, constraints: containingBlockConstraints)
        if layoutBox.isFloatingPositioned() {
          placedFloats.append(
            newFloatItem:
              floatingContext.makeFloatItem(
                floatBox: layoutBox, boxGeometry: geometryForBox(layoutBox: layoutBox)))
        } else {
          // Adjust the vertical position now that we've got final margin values for non-float avoider boxes.
          // Float avoiders have pre-computed vertical positions when floats are present.
          if !layoutBox.isFloatAvoider() || floatingContext.isEmpty() {
            let formattingState = formattingState()
            let boxGeometry = formattingState.boxGeometry(layoutBox: layoutBox)
            boxGeometry.setTop(
              top:
                verticalPositionWithMargin(
                  layoutBox: layoutBox,
                  verticalMargin: formattingState.usedVerticalMargin(layoutBox: layoutBox),
                  containingBlockContentBoxTop: containingBlockConstraints.logicalTop))
          }
        }
        let establishesBlockFormattingContext = layoutBox.establishesBlockFormattingContext()
        if establishesBlockFormattingContext {
          // Now that we computed the box's height, we can layout the out-of-flow descendants.
          if layoutBox.hasChild() {
            (LayoutContext.createFormattingContext(
              formattingContextRoot: layoutBox, layoutState: layoutState)
              as! BlockFormattingContext).layoutOutOfFlowContent(
                constraints:
                  formattingGeometry().constraintsForOutOfFlowContent(elementBox: layoutBox))
          }
        }
        if !layoutBox.establishesFormattingContext() {
          placeInFlowPositionedChildren(
            elementBox: layoutBox, horizontalConstraints: containingBlockConstraints.horizontal)
        }

        if BlockFormattingContext.appendNextToLayoutQueue(
          layoutBox: layoutBox, direction: .Sibling, layoutQueue: &layoutQueue)
        {
          break
        }
      }
    }
    // Place the inflow positioned children.
    placeInFlowPositionedChildren(
      elementBox: formattingRoot, horizontalConstraints: constraints.horizontal)
  }

  func layoutOutOfFlowContent(constraints: ConstraintsForOutOfFlowContent) {
    collectOutOfFlowDescendantsIfNeeded()

    for outOfFlowBox in formattingState().outOfFlowBoxes {
      assert(outOfFlowBox.establishesFormattingContext())
      let containingBlockConstraints = constraintsForLayoutBox(
        outOfFlowBox: outOfFlowBox, constraints: constraints)
      let horizontalConstraintsForBorderAndPadding = HorizontalConstraints(
        logicalLeft: containingBlockConstraints.horizontal.logicalLeft,
        logicalWidth: containingBlockConstraints.borderAndPaddingConstraints)
      computeBorderAndPadding(
        layoutBox: outOfFlowBox, horizontalConstraint: horizontalConstraintsForBorderAndPadding)

      computeOutOfFlowHorizontalGeometry(
        layoutBox: outOfFlowBox, constraints: containingBlockConstraints)
      let elementBox = outOfFlowBox as? ElementBoxWrapper
      if elementBox != nil && elementBox!.hasChild() {
        let formattingContext = LayoutContext.createFormattingContext(
          formattingContextRoot: elementBox!, layoutState: layoutState)
        if elementBox!.hasInFlowOrFloatingChild() {
          formattingContext.layoutInFlowContent(
            constraints: formattingGeometry().constraintsForInFlowContent(elementBox: elementBox!))
        }
        computeOutOfFlowVerticalGeometry(
          layoutBox: elementBox!, constraints: containingBlockConstraints)
      } else {
        computeOutOfFlowVerticalGeometry(
          layoutBox: outOfFlowBox, constraints: containingBlockConstraints)
      }
    }
  }

  func constraintsForLayoutBox(
    outOfFlowBox: BoxWrapper, constraints: ConstraintsForOutOfFlowContent
  ) -> ConstraintsForOutOfFlowContent {
    let containingBlock = FormattingContext.containingBlock(layoutBox: outOfFlowBox)
    return containingBlock == root
      ? constraints
      : formattingGeometry().constraintsForOutOfFlowContent(elementBox: containingBlock)
  }

  @discardableResult
  static func appendNextToLayoutQueue(
    layoutBox: ElementBoxWrapper, direction: LayoutDirection, layoutQueue: inout [ElementBoxWrapper]
  )
    -> Bool
  {
    if direction == .Child {
      if let child = layoutBox.firstInFlowOrFloatingChild() {
        layoutQueue.append(child as! ElementBoxWrapper)
        return true
      }
      return false
    }

    if direction == .Sibling {
      if let nextSibling = layoutBox.nextInFlowOrFloatingSibling() {
        layoutQueue.append(nextSibling as! ElementBoxWrapper)
        return true
      }
      return false
    }
    fatalError("Not reached")
  }

  func constraintsForLayoutBoxInFlow(
    layoutBox: ElementBoxWrapper, constraints: ConstraintsForInFlowContent,
    formattingRoot: ElementBoxWrapper
  )
    -> ConstraintsForInFlowContent
  {
    let containingBlock = FormattingContext.containingBlock(layoutBox: layoutBox)
    return containingBlock == formattingRoot
      ? constraints : formattingGeometry().constraintsForInFlowContent(elementBox: containingBlock)
  }

  func verticalPositionWithMargin(
    layoutBox: ElementBoxWrapper, verticalMargin: UsedVerticalMargin,
    containingBlockContentBoxTop: LayoutUnit
  ) -> LayoutUnit {
    assert(!layoutBox.isOutOfFlowPositioned())
    // Now that we've computed the final margin before, let's shift the box's vertical position if needed.
    // 1. Check if the box has clearance. If so, we've already precomputed/finalized the top value and vertical margin does not impact it anymore.
    // 2. Check if the margin before collapses with the previous box's margin after. if not -> return previous box's bottom including margin after + marginBefore
    // 3. Check if the previous box's margins collapse through. If not -> return previous box' bottom excluding margin after + marginBefore (they are supposed to be equal)
    // 4. Go to previous box and start from step #1 until we hit the parent box.
    let boxGeometry = geometryForBox(layoutBox: layoutBox)
    if formattingState().hasClearance(layoutBox: layoutBox) {
      return BoxGeometry.borderBoxTop(box: boxGeometry)
    }

    var currentLayoutBox = layoutBox
    while true {
      if currentLayoutBox.previousInFlowSibling() == nil {
        break
      }
      let previousInFlowSibling = currentLayoutBox.previousInFlowSibling() as! ElementBoxWrapper
      if !marginCollapse().marginBeforeCollapsesWithPreviousSiblingMarginAfter(
        layoutBox: currentLayoutBox)
      {
        let previousBoxGeometry = geometryForBox(layoutBox: previousInFlowSibling)
        return BoxGeometry.marginBoxRect(box: previousBoxGeometry).bottom()
          + marginBefore(usedVerticalMargin: verticalMargin)
      }

      if !marginCollapse().marginsCollapseThrough(layoutBox: previousInFlowSibling) {
        let previousBoxGeometry = geometryForBox(layoutBox: previousInFlowSibling)
        return BoxGeometry.borderBoxRect(box: previousBoxGeometry).bottom()
          + marginBefore(usedVerticalMargin: verticalMargin)
      }
      currentLayoutBox = previousInFlowSibling
    }

    // Adjust vertical position depending whether this box directly or indirectly adjoins with its parent.
    let directlyAdjoinsParent = layoutBox.previousInFlowSibling() == nil
    if directlyAdjoinsParent {
      // If the top and bottom margins of a box are adjoining, then it is possible for margins to collapse through it.
      // In this case, the position of the element depends on its relationship with the other elements whose margins are being collapsed.
      if verticalMargin.collapsedValues.isCollapsedThrough {
        // If the element's margins are collapsed with its parent's top margin, the top border edge of the box is defined to be the same as the parent's.
        if marginCollapse().marginBeforeCollapsesWithParentMarginBefore(layoutBox: layoutBox) {
          return containingBlockContentBoxTop
        }
        // Otherwise, either the element's parent is not taking part in the margin collapsing, or only the parent's bottom margin is involved.
        // The position of the element's top border edge is the same as it would have been if the element had a non-zero bottom border.
        let beforeMarginWithBottomBorder = marginCollapse().marginBeforeIgnoringCollapsingThrough(
          layoutBox: layoutBox, nonCollapsedValues: verticalMargin.nonCollapsedValues)
        return containingBlockContentBoxTop + beforeMarginWithBottomBorder
      }
      // Non-collapsed through box vertical position depending whether the margin collapses.
      if marginCollapse().marginBeforeCollapsesWithParentMarginBefore(layoutBox: layoutBox) {
        return containingBlockContentBoxTop
      }
      return containingBlockContentBoxTop + marginBefore(usedVerticalMargin: verticalMargin)
    }
    // At this point this box indirectly (via collapsed through previous in-flow siblings) adjoins the parent. Let's check if it margin collapses with the parent.
    let containingBlock = FormattingContext.containingBlock(layoutBox: layoutBox)
    assert(containingBlock.firstInFlowChild() != nil)
    assert(containingBlock.firstInFlowChild() != layoutBox)
    if marginCollapse().marginBeforeCollapsesWithParentMarginBefore(
      layoutBox: containingBlock.firstInFlowChild() as! ElementBoxWrapper)
    {
      return containingBlockContentBoxTop
    }

    return containingBlockContentBoxTop + marginBefore(usedVerticalMargin: verticalMargin)
  }

  func formattingState() -> BlockFormattingState {
    return blockFormattingState!
  }

  func formattingGeometry() -> BlockFormattingGeometry {
    return blockFormattingGeometry!
  }

  func formattingQuirks() -> BlockFormattingQuirks {
    return blockFormattingQuirks!
  }

  struct ConstraintsPair {
    var formattingContextRoot: ConstraintsForInFlowContent
    var containingBlock: ConstraintsForInFlowContent
  }

  func placeInFlowPositionedChildren(
    elementBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints
  ) {
    let childBoxes: LayoutChildIteratorAdapter<ElementBoxWrapper> = childrenOfType(
      parent: elementBox)
    for childBox in childBoxes {
      if !childBox.isInFlowPositioned() {
        continue
      }
      let positionOffset = formattingGeometry().inFlowPositionedPositionOffset(
        layoutBox: childBox, horizontalConstraints: horizontalConstraints)
      formattingState().boxGeometry(layoutBox: childBox).move(size: positionOffset)
    }
  }

  func computeWidthAndMargin(
    floatingContext: FloatingContext, layoutBox: ElementBoxWrapper, constraintsPair: ConstraintsPair
  ) {
    var availableWidthFloatAvoider: LayoutUnit? = nil
    if layoutBox.isFloatAvoider() {
      // Float avoiders' available width might be shrunk by existing floats in the context.
      availableWidthFloatAvoider = usedAvailableWidthForFloatAvoider(
        floatingContext: floatingContext, layoutBox: layoutBox, constraintsPair: constraintsPair)
    }
    let contentWidthAndMargin = formattingGeometry().computedContentWidthAndMargin(
      layoutBox: layoutBox, horizontalConstraints: constraintsPair.containingBlock.horizontal,
      availableWidthFloatAvoider: availableWidthFloatAvoider)
    let boxGeometry = formattingState().boxGeometry(layoutBox: layoutBox)
    boxGeometry.setContentBoxWidth(width: contentWidthAndMargin.contentWidth)
    boxGeometry.setHorizontalMargin(
      margin: BoxGeometry.HorizontalEdges(
        start: contentWidthAndMargin.usedMargin.start, end: contentWidthAndMargin.usedMargin.end))
  }

  func computeHeightAndMargin(
    layoutBox: ElementBoxWrapper, constraints: ConstraintsForInFlowContent
  ) {
    var contentHeightAndMargin = computeHeightAndMarginHelper(
      usedHeight: nil, layoutBox: layoutBox, constraints: constraints)
    if let maxHeight = formattingGeometry().computedMaxHeight(layoutBox: layoutBox) {
      if contentHeightAndMargin.contentHeight > maxHeight {
        let maxHeightAndMargin = computeHeightAndMarginHelper(
          usedHeight: maxHeight, layoutBox: layoutBox, constraints: constraints)
        // Used height should remain the same.
        assert(
          (layoutState.inQuirksMode() && (layoutBox.isBodyBox() || layoutBox.isDocumentBox()))
            || maxHeightAndMargin.contentHeight == maxHeight)
        contentHeightAndMargin = ContentHeightAndMargin(
          contentHeight: maxHeight, nonCollapsedMargin: maxHeightAndMargin.nonCollapsedMargin)
      }
    }

    // 1. Compute collapsed margins.
    // 2. Adjust vertical position using the collapsed values.
    // 3. Adjust previous in-flow sibling margin after using this margin.
    let marginCollapse = marginCollapse()
    let verticalMargin = marginCollapse.collapsedVerticalValues(
      layoutBox: layoutBox, nonCollapsedValues: contentHeightAndMargin.nonCollapsedMargin)
    // Cache the computed positive and negative margin value pair.
    formattingState().setUsedVerticalMargin(
      layoutBox: layoutBox, usedVerticalMargin: verticalMargin)

    if hasPrecomputedMarginBefore(layoutBox: layoutBox)
      && precomputedMarginBefore(layoutBox: layoutBox).usedValue()
        != marginBefore(usedVerticalMargin: verticalMargin)
    {
      // When the pre-computed margin turns out to be incorrect, we need to re-layout this subtree with the correct margin values.
      // <div style="float: left"></div>
      // <div>
      //   <div style="margin-bottom: 200px"></div>
      // </div>
      // The float box triggers margin before computation on the ancestor chain to be able to intersect with other floats in the same floating context.
      // However in some cases the parent margin-top collapses with some next siblings (nephews) and there's no way to be able to properly
      // account for that without laying out every node in the FC (in the example, the margin-bottom pushes down the float).
      fatalError("Not implemented yet")
    }
    let boxGeometry = formattingState().boxGeometry(layoutBox: layoutBox)
    boxGeometry.setContentBoxHeight(height: contentHeightAndMargin.contentHeight)
    boxGeometry.setVerticalMargin(
      margin: BoxGeometry.VerticalEdges(
        before: marginBefore(usedVerticalMargin: verticalMargin),
        after: marginAfter(usedVerticalMargin: verticalMargin)))
    // Adjust the previous sibling's margin bottom now that this box's vertical margin is computed.
    updateMarginAfterForPreviousSibling(layoutBox: layoutBox)
  }

  func computeHeightAndMarginHelper(
    usedHeight: LayoutUnit?, layoutBox: ElementBoxWrapper, constraints: ConstraintsForInFlowContent
  )
    -> ContentHeightAndMargin
  {
    if layoutBox.isInFlow() {
      return formattingGeometry().inFlowContentHeightAndMargin(
        layoutBox: layoutBox, horizontalConstraints: constraints.horizontal,
        overriddenVerticalValues: OverriddenVerticalValues(height: usedHeight))
    }
    if layoutBox.isFloatingPositioned() {
      return formattingGeometry().floatingContentHeightAndMargin(
        layoutBox: layoutBox, horizontalConstraints: constraints.horizontal,
        overriddenVerticalValues: OverriddenVerticalValues(height: usedHeight))
    }
    fatalError("Not reached")
  }

  func computeStaticHorizontalPosition(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints
  ) {
    formattingState().boxGeometry(layoutBox: layoutBox).setLeft(
      left: formattingGeometry().staticHorizontalPosition(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints))
  }

  func computeStaticVerticalPosition(
    layoutBox: ElementBoxWrapper, containingBlockContentBoxTop: LayoutUnit
  ) {
    formattingState().boxGeometry(layoutBox: layoutBox).setTop(
      top: formattingGeometry().staticVerticalPosition(
        layoutBox: layoutBox, containingBlockContentBoxTop: containingBlockContentBoxTop))
  }

  func computePositionToAvoidFloats(
    floatingContext: FloatingContext, layoutBox: ElementBoxWrapper, constraintsPair: ConstraintsPair
  ) {
    if !layoutBox.isFloatAvoider() {
      return
    }
    // In order to position a float avoider we need to know its vertical position relative to its formatting context root (and not just its containing block),
    // because all the already-placed floats (floats that we are trying to avoid here) in this BFC might belong
    // to a different set of containing blocks (but they all descendants of the BFC root).
    // However according to the BFC rules, at this point of the layout flow we don't yet have computed vertical positions for the ancestors.
    let boxGeometry = formattingState().boxGeometry(layoutBox: layoutBox)
    if layoutBox.isFloatingPositioned() {
      precomputeVerticalPositionForBoxAndAncestors(
        layoutBox: layoutBox, constraintsPair: constraintsPair)
      let borderBoxTopLeft = floatingContext.positionForFloat(
        layoutBox: layoutBox, boxGeometry: boxGeometry,
        horizontalConstraints: constraintsPair.containingBlock.horizontal)
      boxGeometry.setTopLeft(topLeft: borderBoxTopLeft)
      return
    }
    // Non-float positioned float avoiders (formatting context roots and clear boxes) should be fine unless there are floats in this context.
    if floatingContext.isEmpty() {
      return
    }
    precomputeVerticalPositionForBoxAndAncestors(
      layoutBox: layoutBox, constraintsPair: constraintsPair)
    if layoutBox.hasFloatClear() {
      return computeVerticalPositionForFloatClear(
        floatingContext: floatingContext, layoutBox: layoutBox)
    }
    assert(layoutBox.establishesFormattingContext())
    let borderBoxTopLeft = floatingContext.positionForNonFloatingFloatAvoider(
      layoutBox: layoutBox, boxGeometry: boxGeometry)
    boxGeometry.setTopLeft(topLeft: borderBoxTopLeft)
  }

  func computeVerticalPositionForFloatClear(
    floatingContext: FloatingContext, layoutBox: ElementBoxWrapper
  ) {
    assert(layoutBox.hasFloatClear())
    if floatingContext.isEmpty() {
      return
    }
    let boxGeometry = formattingState().boxGeometry(layoutBox: layoutBox)
    if let verticalPositionAndClearance = floatingContext.verticalPositionWithClearance(
      layoutBox: layoutBox, boxGeometry: boxGeometry)
    {
      assert(verticalPositionAndClearance.position >= BoxGeometry.borderBoxTop(box: boxGeometry))
      boxGeometry.setTop(top: verticalPositionAndClearance.position)
      if verticalPositionAndClearance.clearance != nil {
        formattingState().setHasClearance(layoutBox: layoutBox)
      }
      // FIXME: Reset the margin values on the ancestors/previous siblings now that the float avoider with clearance does not margin collapse anymore.
    } else {
      return
    }
  }

  func precomputeVerticalPositionForBoxAndAncestors(
    layoutBox: ElementBoxWrapper, constraintsPair: ConstraintsPair
  ) {
    // In order to figure out whether a box should avoid a float, we need to know the final positions of both (ignore relative positioning for now).
    // In block formatting context the final position for a normal flow box includes
    // 1. the static position and
    // 2. the corresponding (non)collapsed margins.
    // Now the vertical margins are computed when all the descendants are finalized, because the margin values might be depending on the height of the box
    // (and the height might be based on the content).
    // So when we get to the point where we intersect the box with the float to decide if the box needs to move, we don't yet have the final vertical position.
    //
    // The idea here is that as long as we don't cross the block formatting context boundary, we should be able to pre-compute the final top position.
    // FIXME: we currently don't account for the "clear" property when computing the final position for an ancestor.
    let formattingGeometry = formattingGeometry()
    var ancestor = layoutBox
    while ancestor !== root {
      let constraintsForAncestor = BlockFormattingContext.constraintsForAncestor()

      let computedVerticalMargin = formattingGeometry.computedVerticalMargin(
        layoutBox: ancestor, horizontalConstraints: constraintsForAncestor.horizontal)
      let usedNonCollapsedMargin = UsedVerticalMargin.NonCollapsedValues(
        before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
        after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
      let precomputedMarginBefore = marginCollapse().precomputedMarginBefore(
        layoutBox: ancestor, usedNonCollapsedMargin: usedNonCollapsedMargin,
        formattingGeometry: formattingGeometry)

      let boxGeometry = formattingState().boxGeometry(layoutBox: ancestor)
      let nonCollapsedValues = UsedVerticalMargin.NonCollapsedValues(
        before: precomputedMarginBefore.nonCollapsedValue, after: LayoutUnit())
      let collapsedValues = UsedVerticalMargin.CollapsedValues(
        before: precomputedMarginBefore.collapsedValue, after: nil, isCollapsedThrough: false)
      let verticalMargin = UsedVerticalMargin(
        nonCollapsedValues: nonCollapsedValues, collapsedValues: collapsedValues,
        positiveAndNegativeValues: UsedVerticalMargin.PositiveAndNegativePair(
          before: precomputedMarginBefore.positiveAndNegativeMarginBefore,
          after: UsedVerticalMargin.PositiveAndNegativePair.Values()))

      formattingState().setUsedVerticalMargin(
        layoutBox: ancestor, usedVerticalMargin: verticalMargin)
      boxGeometry.setVerticalMargin(
        margin: BoxGeometry.VerticalEdges(
          before: marginBefore(usedVerticalMargin: verticalMargin),
          after: marginAfter(usedVerticalMargin: verticalMargin)))
      boxGeometry.setTop(
        top: verticalPositionWithMargin(
          layoutBox: ancestor, verticalMargin: verticalMargin,
          containingBlockContentBoxTop: constraintsForAncestor.logicalTop))
      setPrecomputedMarginBefore(
        layoutBox: ancestor, precomputedMarginBefore: precomputedMarginBefore)
      boxGeometry.setHasPrecomputedMarginBefore()
      ancestor = FormattingContext.containingBlock(layoutBox: ancestor)
    }
  }

  static func constraintsForAncestor() -> ConstraintsForInFlowContent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computedIntrinsicWidthConstraints() -> IntrinsicWidthConstraints {
    let formattingState = formattingState()
    assert(formattingState.intrinsicWidthConstraints == nil)
    // Visit the in-flow descendants and compute their min/max intrinsic width if needed.
    // 1. Go all the way down to the leaf node
    // 2. Check if actually need to visit all the boxes as we traverse down (already computed, container's min/max does not depend on descendants etc)
    // 3. As we climb back on the tree, compute min/max intrinsic width
    // (Any subtrees with new formatting contexts need to layout synchronously)
    var queue: [ElementBoxWrapper] = []
    if root.hasInFlowOrFloatingChild() {
      queue.append(root.firstInFlowOrFloatingChild() as! ElementBoxWrapper)
    }

    var constraints = IntrinsicWidthConstraints()
    var maximumHorizontalStackingWidth = LayoutUnit()
    var currentHorizontalStackingWidth = LayoutUnit()
    while !queue.isEmpty {
      while true {
        // Check if we have to deal with descendant content.
        let layoutBox = queue.last!
        // Float avoiders are all establish a new formatting context. No need to look inside them.
        if layoutBox.isFloatAvoider() && !layoutBox.hasFloatClear() {
          break
        }
        // Non-floating block level boxes reset the current horizontal float stacking.
        // SPEC: This is a bit odd as floating positioning is a formatting context level concept:
        // e.g.
        // <div style="float: left; width: 10px;"></div>
        // <div></div>
        // <div style="float: left; width: 40px;"></div>
        // ...will produce a max width of 40px which makes the floats vertically stacked.
        // Vertically stacked floats makes me think we haven't managed to provide the maximum preferred width for the content.
        maximumHorizontalStackingWidth = max(
          currentHorizontalStackingWidth, maximumHorizontalStackingWidth)
        currentHorizontalStackingWidth = LayoutUnit()
        // Already has computed intrinsic constraints.
        if formattingState.intrinsicWidthConstraintsForBox(layoutBox: layoutBox) != nil {
          break
        }
        // Box with fixed width defines their descendant content intrinsic width.
        if layoutBox.style.width().isFixed() {
          break
        }
        // Non-float avoider formatting context roots are opaque to intrinsic width computation.
        if layoutBox.establishesFormattingContext() {
          break
        }
        // No relevant child content.
        if !layoutBox.hasInFlowOrFloatingChild() {
          break
        }
        queue.append(layoutBox.firstInFlowOrFloatingChild() as! ElementBoxWrapper)
      }
      // Compute min/max intrinsic width bottom up if needed.
      while !queue.isEmpty {
        let layoutBox = queue.removeLast()
        var desdendantConstraints = formattingState.intrinsicWidthConstraintsForBox(
          layoutBox: layoutBox)
        if desdendantConstraints == nil {
          desdendantConstraints = formattingGeometry().intrinsicWidthConstraints(
            layoutBox: layoutBox)
          formattingState.setIntrinsicWidthConstraintsForBox(
            layoutBox: layoutBox, intrinsicWidthConstraints: desdendantConstraints!)
        }
        constraints.minimum = max(constraints.minimum, desdendantConstraints!.minimum)
        let willStackHorizontally = layoutBox.isFloatAvoider() && !layoutBox.hasFloatClear()
        if willStackHorizontally {
          currentHorizontalStackingWidth += desdendantConstraints!.maximum
        } else {
          constraints.maximum = max(constraints.maximum, desdendantConstraints!.maximum)
        }
        // Move over to the next sibling or take the next box in the queue.
        if let nextSibling = layoutBox.nextInFlowOrFloatingSibling() as? ElementBoxWrapper {
          queue.append(nextSibling)
          break
        }
      }
    }
    maximumHorizontalStackingWidth = max(
      currentHorizontalStackingWidth, maximumHorizontalStackingWidth)
    constraints.maximum = max(constraints.maximum, maximumHorizontalStackingWidth)
    formattingState.setIntrinsicWidthConstraints(intrinsicWidthConstraints: constraints)
    return constraints
  }

  func usedAvailableWidthForFloatAvoider(
    floatingContext: FloatingContext, layoutBox: ElementBoxWrapper, constraintsPair: ConstraintsPair
  ) -> LayoutUnit? {
    // Normally the available width for an in-flow block level box is the width of the containing block's content box.
    // However (and can't find it anywhere in the spec) non-floating positioned float avoider block level boxes are constrained by existing floats.
    assert(layoutBox.isFloatAvoider())
    if floatingContext.isEmpty() {
      return nil
    }
    // Float clear pushes the block level box either below the floats, or just one side below but the other side could overlap.
    // What it means is that the used available width always matches the containing block's constraint.
    if layoutBox.hasFloatClear() {
      return nil
    }

    assert(layoutBox.establishesFormattingContext())
    // Vertical static position is not computed yet for this formatting context root, so let's just pre-compute it for now.
    precomputeVerticalPositionForBoxAndAncestors(
      layoutBox: layoutBox, constraintsPair: constraintsPair)

    // FIXME: Check if the non-yet-computed height affects this computation - and whether we have to resolve it at a later point.
    let logicalTop = logicalTopInFormattingContextRootCoordinate(floatAvoider: layoutBox)
    var floatConstraints = floatingContext.constraints(
      candidateTop: logicalTop, candidateBottom: logicalTop, mayBeAboveLastFloat: .No)
    let constraints = floatConstraintsInContainingBlockCoordinate(
      floatConstraints: &floatConstraints,
      layoutBox: layoutBox)
    if constraints.left == nil && constraints.right == nil {
      return nil
    }
    // Shrink the available space if the floats are actually intruding at this vertical position.
    var availableWidth = constraintsPair.containingBlock.horizontal.logicalWidth
    if let constraintsLeft = constraints.left {
      availableWidth -= constraintsLeft.x
    }
    if let constraintsRight = constraints.right {
      availableWidth -= max(
        LayoutUnit(value: 0),
        constraintsPair.containingBlock.horizontal.logicalRight() - constraintsRight.x)
    }
    return availableWidth
  }

  func logicalTopInFormattingContextRootCoordinate(floatAvoider: ElementBoxWrapper) -> LayoutUnit {
    var top = BoxGeometry.borderBoxTop(box: geometryForBox(layoutBox: floatAvoider))
    for ancestor in containingBlockChainWithinFormattingContext(layoutBox: floatAvoider, root: root)
    {
      top += BoxGeometry.borderBoxTop(box: geometryForBox(layoutBox: ancestor))
    }
    return top
  }

  func floatConstraintsInContainingBlockCoordinate(
    floatConstraints: inout FloatingContext.Constraints, layoutBox: ElementBoxWrapper
  )
    -> FloatingContext.Constraints
  {
    if floatConstraints.left == nil && floatConstraints.right == nil {
      return FloatingContext.Constraints()
    }
    var offset = LayoutSizeWrapper()
    for ancestor in containingBlockChainWithinFormattingContext(layoutBox: layoutBox, root: root) {
      offset += toLayoutSize(
        point: BoxGeometry.borderBoxTopLeft(box: geometryForBox(layoutBox: ancestor)))
    }
    if let floatConstraintsLeft = floatConstraints.left {
      floatConstraints.left = PointInContextRoot(point: floatConstraintsLeft.LayoutPoint() - offset)
    }
    if let floatConstraintsRight = floatConstraints.right {
      floatConstraints.right = PointInContextRoot(
        point: floatConstraintsRight.LayoutPoint() - offset)
    }
    return floatConstraints
  }

  func updateMarginAfterForPreviousSibling(layoutBox: ElementBoxWrapper) {
    let marginCollapse = marginCollapse()
    let formattingState = formattingState()
    // 1. Get the margin before value from the next in-flow sibling. This is the same as this box's margin after value now since they are collapsed.
    // 2. Update the collapsed margin after value as well as the positive/negative cache.
    // 3. Check if the box's margins collapse through.
    // 4. If so, update the positive/negative cache.
    // 5. In case of collapsed through margins check if the before margin collapes with the previous inflow sibling's after margin.
    // 6. If so, jump to #2.
    // 7. No need to propagate to parent because its margin is not computed yet (pre-computed at most).
    var currentBox = layoutBox
    while marginCollapse.marginBeforeCollapsesWithPreviousSiblingMarginAfter(layoutBox: currentBox)
    {
      let previousSibling = currentBox.previousInFlowSibling() as! ElementBoxWrapper
      let previousSiblingVerticalMargin = formattingState.usedVerticalMargin(
        layoutBox: previousSibling)

      let marginsCollapseThrough = marginCollapse.marginsCollapseThrough(layoutBox: previousSibling)

      // Update positive/negative cache.
      let previousSiblingPositiveNegativeMargin = formattingState.usedVerticalMargin(
        layoutBox: previousSibling
      ).positiveAndNegativeValues
      let positiveNegativeMarginBefore = formattingState.usedVerticalMargin(layoutBox: currentBox)
        .positiveAndNegativeValues.before

      var adjustedPreviousSiblingVerticalMargin = previousSiblingVerticalMargin
      adjustedPreviousSiblingVerticalMargin.positiveAndNegativeValues.after =
        marginCollapse.computedPositiveAndNegativeMargin(
          a: positiveNegativeMarginBefore, b: previousSiblingPositiveNegativeMargin.after)
      if marginsCollapseThrough {
        adjustedPreviousSiblingVerticalMargin.positiveAndNegativeValues.before =
          marginCollapse.computedPositiveAndNegativeMargin(
            a: previousSiblingPositiveNegativeMargin.before,
            b: adjustedPreviousSiblingVerticalMargin.positiveAndNegativeValues.after)
        adjustedPreviousSiblingVerticalMargin.positiveAndNegativeValues.after =
          adjustedPreviousSiblingVerticalMargin.positiveAndNegativeValues.before
      }
      formattingState.setUsedVerticalMargin(
        layoutBox: previousSibling, usedVerticalMargin: adjustedPreviousSiblingVerticalMargin)

      if !marginsCollapseThrough {
        break
      }

      currentBox = previousSibling
    }
  }

  func computeBorderAndPadding(layoutBox: BoxWrapper, horizontalConstraint: HorizontalConstraints) {
    let boxGeometry = formattingState().boxGeometry(layoutBox: layoutBox)
    boxGeometry.setBorder(border: formattingGeometry().computedBorder(layoutBox: layoutBox))
    boxGeometry.setPadding(
      padding: formattingGeometry().computedPadding(
        layoutBox: layoutBox, containingBlockWidth: horizontalConstraint.logicalWidth))
  }

  func collectOutOfFlowDescendantsIfNeeded() {
    if !formattingState().outOfFlowBoxes.isEmpty {
      return
    }
    if !root.hasChild() {
      return
    }
    if !root.isPositioned() && (root as? InitialContainingBlock) == nil {
      return
    }
    // Collect the out-of-flow descendants at the formatting root level (as opposed to at the containing block level, though they might be the same).
    // FIXME: Turn this into a register-self as boxes are being inserted.
    for descendant in descendantsOfType(root: root) {
      if !descendant.isOutOfFlowPositioned() {
        continue
      }
      if BlockFormattingContext.nearestFormattingContextRoot(descendant: descendant) !== root {
        continue
      }
      formattingState().addOutOfFlowBox(outOfFlowBox: descendant)
    }
  }

  static func nearestFormattingContextRoot(descendant: BoxWrapper) -> ElementBoxWrapper {
    for containingBlock in containingBlockChain(layoutBox: descendant) {
      if containingBlock.establishesBlockFormattingContext() {
        return containingBlock
      }
    }
    fatalError("Not reached")
  }

  func computeOutOfFlowVerticalGeometry(
    layoutBox: BoxWrapper, constraints: ConstraintsForOutOfFlowContent
  ) {
    assert(layoutBox.isOutOfFlowPositioned())

    let containingBlockHeight = constraints.vertical.logicalHeight
    var verticalGeometry = computeOutOfFlowVerticalGeometryHelper(usedHeight: LayoutUnit())
    if let maxHeight = formattingGeometry().computedMaxHeight(
      layoutBox: layoutBox, containingBlockHeight: containingBlockHeight)
    {
      let maxVerticalGeometry = computeOutOfFlowVerticalGeometryHelper(usedHeight: maxHeight)
      if verticalGeometry.contentHeightAndMargin.contentHeight
        > maxVerticalGeometry.contentHeightAndMargin.contentHeight
      {
        verticalGeometry = maxVerticalGeometry
      }
    }

    if let minHeight = formattingGeometry().computedMinHeight(
      layoutBox: layoutBox, containingBlockHeight: containingBlockHeight)
    {
      let minVerticalGeometry = computeOutOfFlowVerticalGeometryHelper(usedHeight: minHeight)
      if verticalGeometry.contentHeightAndMargin.contentHeight
        < minVerticalGeometry.contentHeightAndMargin.contentHeight
      {
        verticalGeometry = minVerticalGeometry
      }
    }

    let boxGeometry = formattingState().boxGeometry(layoutBox: layoutBox)
    let nonCollapsedVerticalMargin = verticalGeometry.contentHeightAndMargin.nonCollapsedMargin
    boxGeometry.setTop(top: verticalGeometry.top + nonCollapsedVerticalMargin.before)
    boxGeometry.setContentBoxHeight(height: verticalGeometry.contentHeightAndMargin.contentHeight)
    // Margins of absolutely positioned boxes do not collapse.
    boxGeometry.setVerticalMargin(
      margin: BoxGeometry.VerticalEdges(
        before: nonCollapsedVerticalMargin.before, after: nonCollapsedVerticalMargin.after))
  }

  func computeOutOfFlowVerticalGeometryHelper(usedHeight: LayoutUnit?) -> VerticalGeometry {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeOutOfFlowHorizontalGeometry(
    layoutBox: BoxWrapper, constraints: ConstraintsForOutOfFlowContent
  ) {
    assert(layoutBox.isOutOfFlowPositioned())

    let containingBlockWidth = constraints.horizontal.logicalWidth
    var horizontalGeometry = computeOutOfFlowHorizontalGeometryHelper(usedWidth: LayoutUnit())
    if let maxWidth = formattingGeometry().computedMaxWidth(
      layoutBox: layoutBox, containingBlockWidth: containingBlockWidth)
    {
      let maxHorizontalGeometry = computeOutOfFlowHorizontalGeometryHelper(usedWidth: maxWidth)
      if horizontalGeometry.contentWidthAndMargin.contentWidth
        > maxHorizontalGeometry.contentWidthAndMargin.contentWidth
      {
        horizontalGeometry = maxHorizontalGeometry
      }
    }

    if let minWidth = formattingGeometry().computedMinWidth(
      layoutBox: layoutBox, containingBlockWidth: containingBlockWidth)
    {
      let minHorizontalGeometry = computeOutOfFlowHorizontalGeometryHelper(usedWidth: minWidth)
      if horizontalGeometry.contentWidthAndMargin.contentWidth
        < minHorizontalGeometry.contentWidthAndMargin.contentWidth
      {
        horizontalGeometry = minHorizontalGeometry
      }
    }

    let boxGeometry = formattingState().boxGeometry(layoutBox: layoutBox)
    boxGeometry.setLeft(
      left: horizontalGeometry.left + horizontalGeometry.contentWidthAndMargin.usedMargin.start)
    boxGeometry.setContentBoxWidth(width: horizontalGeometry.contentWidthAndMargin.contentWidth)
    let usedHorizontalMargin = horizontalGeometry.contentWidthAndMargin.usedMargin
    boxGeometry.setHorizontalMargin(
      margin: BoxGeometry.HorizontalEdges(
        start: usedHorizontalMargin.start, end: usedHorizontalMargin.end))
  }

  func computeOutOfFlowHorizontalGeometryHelper(usedWidth: LayoutUnit?) -> HorizontalGeometry {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginCollapse() -> BlockMarginCollapse {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPrecomputedMarginBefore(
    layoutBox: ElementBoxWrapper, precomputedMarginBefore: PrecomputedMarginBefore
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func precomputedMarginBefore(layoutBox: ElementBoxWrapper) -> PrecomputedMarginBefore {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasPrecomputedMarginBefore(layoutBox: ElementBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var blockFormattingState: BlockFormattingState? = nil
  var blockFormattingGeometry: BlockFormattingGeometry? = nil
  var blockFormattingQuirks: BlockFormattingQuirks? = nil
}
