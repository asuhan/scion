/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
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

func hasBorderBefore(layoutBox: ElementBoxWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func hasBorderAfter(layoutBox: ElementBoxWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func hasPaddingBefore(layoutBox: ElementBoxWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func hasPaddingAfter(layoutBox: ElementBoxWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func establishesBlockFormattingContext(layoutBox: ElementBoxWrapper) -> Bool {
  // WebKit treats the document element renderer as a block formatting context root. It probably only impacts margin collapsing, so let's not do
  // a layout wide quirk on this for now.
  if layoutBox.isDocumentBox() {
    return true
  }
  return layoutBox.establishesBlockFormattingContext()
}

// This class implements margin collapsing for block formatting context.
struct BlockMarginCollapse {
  init(layoutState: LayoutStateWrapper, blockFormattingState: BlockFormattingState) {
    self.layoutState = layoutState
    self.blockFormattingState = blockFormattingState
    self.inQuirksMode = layoutState.inQuirksMode()
  }

  func collapsedVerticalValues(
    layoutBox: ElementBoxWrapper, nonCollapsedValues: UsedVerticalMargin.NonCollapsedValues
  ) -> UsedVerticalMargin {
    assert(layoutBox.isBlockLevelBox())
    // 1. Get min/max margin top values from the first in-flow child if we are collapsing margin top with it.
    // 2. Get min/max margin top values from the previous in-flow sibling, if we are collapsing margin top with it.
    // 3. Get this layout box's computed margin top value.
    // 4. Update the min/max value and compute the final margin.
    var positiveAndNegativeVerticalMargin = UsedVerticalMargin.PositiveAndNegativePair(
      before: positiveNegativeMarginBefore(
        layoutBox: layoutBox, nonCollapsedValues: nonCollapsedValues),
      after: positiveNegativeMarginAfter(
        layoutBox: layoutBox, nonCollapsedValues: nonCollapsedValues))

    let marginsCollapseThrough = marginsCollapseThrough(layoutBox: layoutBox)
    if marginsCollapseThrough {
      positiveAndNegativeVerticalMargin.before = computedPositiveAndNegativeMargin(
        a: positiveAndNegativeVerticalMargin.before, b: positiveAndNegativeVerticalMargin.after)
      positiveAndNegativeVerticalMargin.after = positiveAndNegativeVerticalMargin.before
    }

    let hasCollapsedMarginBefore =
      marginBeforeCollapsesWithFirstInFlowChildMarginBefore(layoutBox: layoutBox)
      || marginBeforeCollapsesWithPreviousSiblingMarginAfter(layoutBox: layoutBox)
    let hasCollapsedMarginAfter = marginAfterCollapsesWithLastInFlowChildMarginAfter(
      layoutBox: layoutBox)
    var usedVerticalMargin = UsedVerticalMargin(
      nonCollapsedValues: nonCollapsedValues, collapsedValues: UsedVerticalMargin.CollapsedValues(),
      positiveAndNegativeValues: positiveAndNegativeVerticalMargin)

    if (hasCollapsedMarginBefore && hasCollapsedMarginAfter) || marginsCollapseThrough {
      usedVerticalMargin.collapsedValues = UsedVerticalMargin.CollapsedValues(
        before: marginValue(marginValues: positiveAndNegativeVerticalMargin.before),
        after: marginValue(marginValues: positiveAndNegativeVerticalMargin.after),
        isCollapsedThrough: marginsCollapseThrough)
    } else if hasCollapsedMarginBefore {
      usedVerticalMargin.collapsedValues = UsedVerticalMargin.CollapsedValues(
        before: marginValue(marginValues: positiveAndNegativeVerticalMargin.before), after: nil,
        isCollapsedThrough: false)
    } else if hasCollapsedMarginAfter {
      usedVerticalMargin.collapsedValues = UsedVerticalMargin.CollapsedValues(
        before: nil, after: marginValue(marginValues: positiveAndNegativeVerticalMargin.after),
        isCollapsedThrough: false)
    }
    return usedVerticalMargin
  }

  func marginBeforeIgnoringCollapsingThrough(
    layoutBox: ElementBoxWrapper, nonCollapsedValues: UsedVerticalMargin.NonCollapsedValues
  ) -> LayoutUnit {
    assert(layoutBox.isBlockLevelBox())
    return marginValue(
      marginValues: positiveNegativeMarginBefore(
        layoutBox: layoutBox, nonCollapsedValues: nonCollapsedValues))
      ?? nonCollapsedValues.before
  }

  func marginBeforeCollapsesWithParentMarginBefore(layoutBox: ElementBoxWrapper) -> Bool {
    // The first inflow child could propagate its top margin to parent.
    // https://www.w3.org/TR/CSS21/box.html#collapsing-margins
    assert(layoutBox.isBlockLevelBox())

    if inQuirksMode
      && BlockFormattingQuirks.shouldCollapseMarginBeforeWithParentMarginBefore(
        layoutBox: layoutBox)
    {
      return true
    }

    // Margins between a floated box and any other box do not collapse.
    if layoutBox.isFloatingPositioned() {
      return false
    }

    // Margins of absolutely positioned boxes do not collapse.
    if layoutBox.isOutOfFlowPositioned() {
      return false
    }

    // Margins of inline-block boxes do not collapse.
    if layoutBox.isInlineBlockBox() {
      return false
    }

    // Only the first inlflow child collapses with parent.
    if layoutBox.previousInFlowSibling() != nil {
      return false
    }

    let containingBlock = FormattingContext.containingBlock(layoutBox: layoutBox)
    // Margins of elements that establish new block formatting contexts do not collapse with their in-flow children
    if establishesBlockFormattingContext(layoutBox: containingBlock) {
      return false
    }

    if hasBorderBefore(layoutBox: containingBlock) {
      return false
    }

    if hasPaddingBefore(layoutBox: containingBlock) {
      return false
    }

    // ...and the child has no clearance.
    if hasClearance(layoutBox: layoutBox) {
      return false
    }

    return true
  }

  func marginBeforeCollapsesWithFirstInFlowChildMarginBefore(layoutBox: ElementBoxWrapper) -> Bool {
    assert(layoutBox.isBlockLevelBox())
    // Margins of elements that establish new block formatting contexts do not collapse with their in-flow children.
    if establishesBlockFormattingContext(layoutBox: layoutBox) {
      return false
    }

    // The top margin of an in-flow block element collapses with its first in-flow block-level
    // child's top margin if the element has no top border...
    if hasBorderBefore(layoutBox: layoutBox) {
      return false
    }

    // ...no top padding
    if hasPaddingBefore(layoutBox: layoutBox) {
      return false
    }

    if let firstInFlowChild = layoutBox.firstInFlowChild() as? ElementBoxWrapper {
      if !firstInFlowChild.isBlockLevelBox() {
        return false
      }

      // ...and the child has no clearance.
      if hasClearance(layoutBox: firstInFlowChild) {
        return false
      }

      // Margins of inline-block boxes do not collapse.
      if firstInFlowChild.isInlineBlockBox() {
        return false
      }

      return true
    } else {
      return false
    }
  }

  func marginBeforeCollapsesWithParentMarginAfter(layoutBox: ElementBoxWrapper) -> Bool {
    // 1. This is the last in-flow child and its margins collapse through and the margin after collapses with parent's margin after or
    // 2. This box's margin after collapses with the next sibling's margin before and that sibling collapses through and
    // we can get to the last in-flow child like that.
    let lastInFlowChild = FormattingContext.containingBlock(layoutBox: layoutBox).lastInFlowChild()
    var currentBox: ElementBoxWrapper? = layoutBox
    while currentBox != nil {
      if !marginsCollapseThrough(layoutBox: currentBox!) {
        return false
      }
      if currentBox === lastInFlowChild {
        return marginAfterCollapsesWithParentMarginAfter(layoutBox: currentBox!)
      }
      if !marginAfterCollapsesWithNextSiblingMarginBefore(layoutBox: currentBox!) {
        return false
      }
      currentBox = currentBox!.nextInFlowSibling() as! ElementBoxWrapper?
    }
    fatalError("Not reached")
  }

  func marginBeforeCollapsesWithPreviousSiblingMarginAfter(layoutBox: ElementBoxWrapper) -> Bool {
    assert(layoutBox.isBlockLevelBox())

    if let previousInFlowSibling = layoutBox.previousInFlowSibling() {
      // Margins between a floated box and any other box do not collapse.
      if layoutBox.isFloatingPositioned() || previousInFlowSibling.isFloatingPositioned() {
        return false
      }

      // Margins of absolutely positioned boxes do not collapse.
      if (layoutBox.isOutOfFlowPositioned() && !layoutBox.style.top().isAuto())
        || (previousInFlowSibling.isOutOfFlowPositioned()
          && !previousInFlowSibling.style.bottom().isAuto())
      {
        return false
      }

      // Margins of inline-block boxes do not collapse.
      if layoutBox.isInlineBlockBox() || previousInFlowSibling.isInlineBlockBox() {
        return false
      }

      // The bottom margin of an in-flow block-level element always collapses with the top margin of
      // its next in-flow block-level sibling, unless that sibling has clearance.
      if hasClearance(layoutBox: layoutBox) {
        return false
      }

      return true
    }

    return false
  }

  func marginAfterCollapsesWithParentMarginAfter(layoutBox: ElementBoxWrapper) -> Bool {
    assert(layoutBox.isBlockLevelBox())

    if inQuirksMode
      && BlockFormattingQuirks.shouldCollapseMarginAfterWithParentMarginAfter(layoutBox: layoutBox)
    {
      return true
    }

    // Margins between a floated box and any other box do not collapse.
    if layoutBox.isFloatingPositioned() {
      return false
    }

    // Margins of absolutely positioned boxes do not collapse.
    if layoutBox.isOutOfFlowPositioned() {
      return false
    }

    // Margins of inline-block boxes do not collapse.
    if layoutBox.isInlineBlockBox() {
      return false
    }

    // Only the last inlflow child collapses with parent.
    if layoutBox.nextInFlowSibling() != nil {
      return false
    }

    let containingBlock = FormattingContext.containingBlock(layoutBox: layoutBox)
    // Margins of elements that establish new block formatting contexts do not collapse with their in-flow children.
    if establishesBlockFormattingContext(layoutBox: containingBlock) {
      return false
    }

    // The bottom margin of an in-flow block box with a 'height' of 'auto' collapses with its last in-flow block-level child's bottom margin, if:
    if !containingBlock.style.height().isAuto() {
      return false
    }

    // the box has no bottom padding, and
    if hasPaddingAfter(layoutBox: containingBlock) {
      return false
    }

    // the box has no bottom border, and
    if hasBorderAfter(layoutBox: containingBlock) {
      return false
    }

    // the child's bottom margin neither collapses with a top margin that has clearance...
    if marginAfterCollapsesWithSiblingMarginBeforeWithClearance(layoutBox: layoutBox) {
      return false
    }

    // nor (if the box's min-height is non-zero) with the box's top margin.
    let computedMinHeight = containingBlock.style.logicalMinHeight()
    if !computedMinHeight.isAuto() && computedMinHeight.value() != 0
      && marginAfterCollapsesWithParentMarginBefore(layoutBox: layoutBox)
    {
      return false
    }

    return true
  }

  func marginAfterCollapsesWithLastInFlowChildMarginAfter(layoutBox: ElementBoxWrapper) -> Bool {
    assert(layoutBox.isBlockLevelBox())

    // Margins of elements that establish new block formatting contexts do not collapse with their in-flow children.
    if establishesBlockFormattingContext(layoutBox: layoutBox) {
      return false
    }

    if let lastInFlowChild = layoutBox.lastInFlowChild() as? ElementBoxWrapper {
      if !lastInFlowChild.isBlockLevelBox() {
        return false
      }

      // The bottom margin of an in-flow block box with a 'height' of 'auto' collapses with its last in-flow block-level child's bottom margin, if:
      if !layoutBox.style.height().isAuto() {
        return false
      }

      // the box has no bottom padding, and
      if hasPaddingAfter(layoutBox: layoutBox) {
        return false
      }

      // the box has no bottom border, and
      if hasBorderAfter(layoutBox: layoutBox) {
        return false
      }

      // the child's bottom margin neither collapses with a top margin that has clearance...
      if marginAfterCollapsesWithSiblingMarginBeforeWithClearance(layoutBox: lastInFlowChild) {
        return false
      }

      // nor (if the box's min-height is non-zero) with the box's top margin.
      let computedMinHeight = layoutBox.style.logicalMinHeight()
      if !computedMinHeight.isAuto() && computedMinHeight.value() != 0
        && (marginAfterCollapsesWithParentMarginBefore(layoutBox: lastInFlowChild)
          || hasClearance(layoutBox: lastInFlowChild))
      {
        return false
      }

      // Margins of inline-block boxes do not collapse.
      if lastInFlowChild.isInlineBlockBox() {
        return false
      }

      // This is a quirk behavior: When the margin after of the last inflow child (or a previous sibling with collapsed through margins)
      // collapses with a quirk parent's the margin before, then the same margin after does not collapses with the parent's margin after.
      let shouldIgnoreCollapsedMargin =
        inQuirksMode
        && BlockFormattingQuirks.shouldIgnoreCollapsedQuirkMargin(layoutBox: layoutBox)
      if shouldIgnoreCollapsedMargin
        && marginAfterCollapsesWithParentMarginBefore(layoutBox: lastInFlowChild)
      {
        return false
      }

      return true
    }

    return false
  }

  func marginsCollapseThrough(layoutBox: ElementBoxWrapper) -> Bool {
    assert(layoutBox.isBlockLevelBox())

    // A box's own margins collapse if the 'min-height' property is zero, and it has neither top or bottom borders nor top or bottom padding,
    // and it has a 'height' of either 0 or 'auto', and it does not contain a line box, and all of its in-flow children's margins (if any) collapse.
    if hasBorderBefore(layoutBox: layoutBox) || hasBorderAfter(layoutBox: layoutBox) {
      return false
    }

    if hasPaddingBefore(layoutBox: layoutBox) || hasPaddingAfter(layoutBox: layoutBox) {
      return false
    }

    // Margins are not adjoining when the box has clearance.
    if hasClearance(layoutBox: layoutBox) {
      return false
    }

    let style = layoutBox.style
    let computedHeightValueIsZero = style.height().isFixed() && style.height().value() == 0
    if !(style.height().isAuto() || computedHeightValueIsZero) {
      return false
    }

    // FIXME: Check for computed 0 height.
    if !style.minHeight().isAuto() {
      return false
    }

    // FIXME: Block replaced boxes clearly don't collapse through their margins, but I couldn't find it in the spec yet (and no, it's not a quirk).
    if layoutBox.isReplacedBox() {
      return false
    }

    if !layoutBox.hasInFlowChild() {
      return !establishesBlockFormattingContext(layoutBox: layoutBox)
    }

    if layoutBox.establishesFormattingContext() {
      if layoutBox.establishesInlineFormattingContext() {
        // FIXME: If we get here through margin estimation, we don't necessarily have an actual state for this layout box since
        // we haven't started laying it out yet.
        // FIXME: Check for non-empty inline formatting context if applicable.
        // FIXME: Any float box in this formatting context prevents collapsing through.
        return true
      }

      // A root of a non-inline formatting context (table, flex etc) with inflow descendants should not collapse through.
      return false
    }

    var inflowChild = layoutBox.firstInFlowOrFloatingChild() as! ElementBoxWrapper?
    while inflowChild != nil {
      if establishesBlockFormattingContext(layoutBox: inflowChild!) {
        return false
      }
      if !marginsCollapseThrough(layoutBox: inflowChild!) {
        return false
      }
      inflowChild = inflowChild!.nextInFlowOrFloatingSibling() as! ElementBoxWrapper?
    }
    return true
  }

  func marginAfterCollapsesWithParentMarginBefore(layoutBox: ElementBoxWrapper) -> Bool {
    // 1. This is the first in-flow child and its margins collapse through and the margin before collapses with parent's margin before or
    // 2. This box's margin before collapses with the previous sibling's margin after and that sibling collapses through and
    // we can get to the first in-flow child like that.
    let firstInFlowChild = FormattingContext.containingBlock(layoutBox: layoutBox)
      .firstInFlowChild()
    var currentBox: ElementBoxWrapper? = layoutBox
    while currentBox != nil {
      if !marginsCollapseThrough(layoutBox: currentBox!) {
        return false
      }
      if currentBox === firstInFlowChild {
        return marginBeforeCollapsesWithParentMarginBefore(layoutBox: currentBox!)
      }
      if !marginBeforeCollapsesWithPreviousSiblingMarginAfter(layoutBox: currentBox!) {
        return false
      }
      currentBox = currentBox!.previousInFlowSibling() as! ElementBoxWrapper?
    }
    fatalError("Not reached")
  }

  func marginAfterCollapsesWithNextSiblingMarginBefore(layoutBox: ElementBoxWrapper) -> Bool {
    assert(layoutBox.isBlockLevelBox())

    if let nextInFlowSibling = layoutBox.nextInFlowSibling() {
      return marginBeforeCollapsesWithPreviousSiblingMarginAfter(
        layoutBox: nextInFlowSibling as! ElementBoxWrapper)
    }

    return false
  }

  func marginAfterCollapsesWithSiblingMarginBeforeWithClearance(layoutBox: ElementBoxWrapper)
    -> Bool
  {
    // If the top and bottom margins of an element with clearance are adjoining, its margins collapse with the adjoining margins
    // of following siblings but that resulting margin does not collapse with the bottom margin of the parent block.
    if !marginsCollapseThrough(layoutBox: layoutBox) {
      return false
    }

    var previousSibling = layoutBox.previousInFlowSibling() as! ElementBoxWrapper?
    while previousSibling != nil {
      if !marginsCollapseThrough(layoutBox: previousSibling!) {
        return false
      }
      if hasClearance(layoutBox: previousSibling!) {
        return true
      }
      previousSibling = previousSibling!.previousInFlowSibling() as! ElementBoxWrapper?
    }
    return false
  }

  func computedPositiveAndNegativeMargin(
    a: UsedVerticalMargin.PositiveAndNegativePair.Values,
    b: UsedVerticalMargin.PositiveAndNegativePair.Values
  ) -> UsedVerticalMargin.PositiveAndNegativePair.Values {
    var computedValues = UsedVerticalMargin.PositiveAndNegativePair.Values()
    if a.positive != nil && b.positive != nil {
      computedValues.positive = max(a.positive!, b.positive!)
    } else {
      computedValues.positive = a.positive != nil ? a.positive : b.positive
    }

    if a.negative != nil && b.negative != nil {
      computedValues.negative = min(a.negative!, b.negative!)
    } else {
      computedValues.negative = a.negative != nil ? a.negative : b.negative
    }

    if a.isNonZero() && b.isNonZero() {
      computedValues.isQuirk = a.isQuirk || b.isQuirk
    } else if a.isNonZero() {
      computedValues.isQuirk = a.isQuirk
    } else {
      computedValues.isQuirk = b.isQuirk
    }

    return computedValues
  }

  func precomputedMarginBefore(
    layoutBox: ElementBoxWrapper, usedNonCollapsedMargin: UsedVerticalMargin.NonCollapsedValues,
    formattingGeometry: BlockFormattingGeometry
  ) -> PrecomputedMarginBefore {
    assert(layoutBox.isBlockLevelBox())
    // Don't pre-compute vertical margins for out of flow boxes.
    assert(layoutBox.isInFlow() || layoutBox.isFloatingPositioned())
    assert(!layoutBox.isReplacedBox())

    let positiveNegativeMarginBefore = precomputedPositiveNegativeMarginBefore(
      layoutBox: layoutBox, nonCollapsedValues: usedNonCollapsedMargin,
      formattingGeometry: formattingGeometry)
    let collapsedMarginBefore = marginValue(marginValues: positiveNegativeMarginBefore)
    return PrecomputedMarginBefore(
      nonCollapsedValue: usedNonCollapsedMargin.before,
      collapsedValue: collapsedMarginBefore,
      positiveAndNegativeMarginBefore: positiveNegativeMarginBefore)
  }

  enum MarginType: UInt8 {
    case Before
    case After
  }

  func positiveNegativeValues(layoutBox: ElementBoxWrapper, marginType: MarginType)
    -> UsedVerticalMargin.PositiveAndNegativePair.Values
  {
    // By the time we get here in BFC layout to gather positive and negative margin values for either a previous sibling or a child box,
    // we mush have computed and cached those values.
    assert(formattingState().hasUsedVerticalMargin(layoutBox: layoutBox))
    let positiveAndNegativeVerticalMargin = formattingState().usedVerticalMargin(
      layoutBox: layoutBox
    ).positiveAndNegativeValues
    return marginType == .Before
      ? positiveAndNegativeVerticalMargin.before : positiveAndNegativeVerticalMargin.after
  }

  func positiveNegativeMarginBefore(
    layoutBox: ElementBoxWrapper, nonCollapsedValues: UsedVerticalMargin.NonCollapsedValues
  ) -> UsedVerticalMargin.PositiveAndNegativePair.Values {
    // 1. Gather positive and negative margin values from first child if margins are adjoining.
    // 2. Gather positive and negative margin values from previous inflow sibling if margins are adjoining.
    // 3. Compute min/max positive and negative collapsed margin values using non-collpased computed margin before.
    var collapsedMarginBefore = computedPositiveAndNegativeMargin(
      a: firstChildCollapsedMarginBefore(layoutBox: layoutBox),
      b: previouSiblingCollapsedMarginAfter(layoutBox: layoutBox))
    let shouldIgnoreCollapsedMargin =
      collapsedMarginBefore.isQuirk && inQuirksMode
      && BlockFormattingQuirks.shouldIgnoreCollapsedQuirkMargin(layoutBox: layoutBox)
    if shouldIgnoreCollapsedMargin {
      collapsedMarginBefore = UsedVerticalMargin.PositiveAndNegativePair.Values()
    }

    var nonCollapsedBefore = UsedVerticalMargin.PositiveAndNegativePair.Values()
    if nonCollapsedValues.before > 0 {
      nonCollapsedBefore = UsedVerticalMargin.PositiveAndNegativePair.Values(
        positive: nonCollapsedValues.before, negative: nil,
        isQuirk: layoutBox.style.marginBefore().hasQuirk())
    } else if nonCollapsedValues.before < 0 {
      nonCollapsedBefore = UsedVerticalMargin.PositiveAndNegativePair.Values(
        positive: nil, negative: nonCollapsedValues.before,
        isQuirk: layoutBox.style.marginBefore().hasQuirk())
    }

    return computedPositiveAndNegativeMargin(a: collapsedMarginBefore, b: nonCollapsedBefore)
  }

  func firstChildCollapsedMarginBefore(layoutBox: ElementBoxWrapper)
    -> UsedVerticalMargin.PositiveAndNegativePair.Values
  {
    if !marginBeforeCollapsesWithFirstInFlowChildMarginBefore(layoutBox: layoutBox) {
      return UsedVerticalMargin.PositiveAndNegativePair.Values()
    }
    return positiveNegativeValues(
      layoutBox: layoutBox.firstInFlowChild()! as! ElementBoxWrapper, marginType: .Before)
  }

  func previouSiblingCollapsedMarginAfter(layoutBox: ElementBoxWrapper)
    -> UsedVerticalMargin.PositiveAndNegativePair.Values
  {
    if !marginBeforeCollapsesWithPreviousSiblingMarginAfter(layoutBox: layoutBox) {
      return UsedVerticalMargin.PositiveAndNegativePair.Values()
    }
    return positiveNegativeValues(
      layoutBox: layoutBox.previousInFlowSibling()! as! ElementBoxWrapper, marginType: .After)
  }

  func positiveNegativeMarginAfter(
    layoutBox: ElementBoxWrapper, nonCollapsedValues: UsedVerticalMargin.NonCollapsedValues
  ) -> UsedVerticalMargin.PositiveAndNegativePair.Values {
    // We don't know yet the margin before value of the next sibling. Let's just pretend it does not have one and
    // update it later when we compute the next sibling's margin before. See updateMarginAfterForPreviousSibling.
    var nonCollapsedAfter = UsedVerticalMargin.PositiveAndNegativePair.Values()
    if nonCollapsedValues.after > 0 {
      nonCollapsedAfter = UsedVerticalMargin.PositiveAndNegativePair.Values(
        positive: nonCollapsedValues.after, negative: nil,
        isQuirk: layoutBox.style.marginAfter().hasQuirk())
    } else if nonCollapsedValues.after < 0 {
      nonCollapsedAfter = UsedVerticalMargin.PositiveAndNegativePair.Values(
        positive: nil, negative: nonCollapsedValues.after,
        isQuirk: layoutBox.style.marginAfter().hasQuirk())
    }

    return computedPositiveAndNegativeMargin(
      a: lastChildCollapsedMarginAfter(layoutBox: layoutBox), b: nonCollapsedAfter)
  }

  func lastChildCollapsedMarginAfter(layoutBox: ElementBoxWrapper)
    -> UsedVerticalMargin.PositiveAndNegativePair.Values
  {
    if !marginAfterCollapsesWithLastInFlowChildMarginAfter(layoutBox: layoutBox) {
      return UsedVerticalMargin.PositiveAndNegativePair.Values()
    }
    return positiveNegativeValues(
      layoutBox: layoutBox.lastInFlowChild()! as! ElementBoxWrapper, marginType: .After)
  }

  func precomputedPositiveNegativeMarginBefore(
    layoutBox: ElementBoxWrapper, nonCollapsedValues: UsedVerticalMargin.NonCollapsedValues,
    formattingGeometry: BlockFormattingGeometry
  )
    -> UsedVerticalMargin.PositiveAndNegativePair.Values
  {
    // 1. Gather positive and negative margin values from first child if margins are adjoining.
    // 2. Gather positive and negative margin values from previous inflow sibling if margins are adjoining.
    // 3. Compute min/max positive and negative collapsed margin values using non-collpased computed margin before.
    var collapsedMarginBefore = computedPositiveAndNegativeMargin(
      a: precomputedFirstChildCollapsedMarginBefore(
        layoutBox: layoutBox, formattingGeometry: formattingGeometry),
      b: precomputedPreviouSiblingCollapsedMarginAfter(layoutBox: layoutBox))
    let shouldIgnoreCollapsedMargin =
      collapsedMarginBefore.isQuirk && inQuirksMode
      && BlockFormattingQuirks.shouldIgnoreCollapsedQuirkMargin(layoutBox: layoutBox)
    if shouldIgnoreCollapsedMargin {
      collapsedMarginBefore = UsedVerticalMargin.PositiveAndNegativePair.Values()
    }

    var nonCollapsedBefore = UsedVerticalMargin.PositiveAndNegativePair.Values()
    if nonCollapsedValues.before > 0 {
      nonCollapsedBefore = UsedVerticalMargin.PositiveAndNegativePair.Values(
        positive: nonCollapsedValues.before, negative: nil,
        isQuirk: layoutBox.style.marginBefore().hasQuirk())
    } else if nonCollapsedValues.before < 0 {
      nonCollapsedBefore = UsedVerticalMargin.PositiveAndNegativePair.Values(
        positive: nil, negative: nonCollapsedValues.before,
        isQuirk: layoutBox.style.marginBefore().hasQuirk())
    }

    return computedPositiveAndNegativeMargin(a: collapsedMarginBefore, b: nonCollapsedBefore)
  }

  func precomputedPositiveNegativeValues(
    layoutBox: ElementBoxWrapper, formattingGeometry: BlockFormattingGeometry
  ) -> UsedVerticalMargin.PositiveAndNegativePair.Values {
    if formattingState().hasUsedVerticalMargin(layoutBox: layoutBox) {
      return formattingState().usedVerticalMargin(layoutBox: layoutBox).positiveAndNegativeValues
        .before
    }

    let horizontalConstraints = formattingGeometry.constraintsForInFlowContent(
      elementBox: FormattingContext.containingBlock(layoutBox: layoutBox)
    ).horizontal
    let computedVerticalMargin = formattingGeometry.computedVerticalMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
    let nonCollapsedMargin = UsedVerticalMargin.NonCollapsedValues(
      before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
      after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
    return precomputedPositiveNegativeMarginBefore(
      layoutBox: layoutBox, nonCollapsedValues: nonCollapsedMargin,
      formattingGeometry: formattingGeometry)
  }

  func precomputedFirstChildCollapsedMarginBefore(
    layoutBox: ElementBoxWrapper, formattingGeometry: BlockFormattingGeometry
  )
    -> UsedVerticalMargin.PositiveAndNegativePair.Values
  {
    if !marginBeforeCollapsesWithFirstInFlowChildMarginBefore(layoutBox: layoutBox) {
      return UsedVerticalMargin.PositiveAndNegativePair.Values()
    }
    return precomputedPositiveNegativeValues(
      layoutBox: layoutBox.firstInFlowChild()! as! ElementBoxWrapper,
      formattingGeometry: formattingGeometry)
  }

  func precomputedPreviouSiblingCollapsedMarginAfter(layoutBox: ElementBoxWrapper)
    -> UsedVerticalMargin.PositiveAndNegativePair.Values
  {
    if !marginBeforeCollapsesWithPreviousSiblingMarginAfter(layoutBox: layoutBox) {
      return UsedVerticalMargin.PositiveAndNegativePair.Values()
    }
    let previousInFlowSibling = layoutBox.previousInFlowSibling()!
    return formattingState().usedVerticalMargin(layoutBox: previousInFlowSibling)
      .positiveAndNegativeValues.after
  }

  func marginValue(marginValues: UsedVerticalMargin.PositiveAndNegativePair.Values) -> LayoutUnit? {
    // When two or more margins collapse, the resulting margin width is the maximum of the collapsing margins' widths.
    // In the case of negative margins, the maximum of the absolute values of the negative adjoining margins is deducted from the maximum
    // of the positive adjoining margins. If there are no positive margins, the maximum of the absolute values of the adjoining margins is deducted from zero.
    if marginValues.negative == nil {
      return marginValues.positive
    }

    if marginValues.positive == nil {
      return marginValues.negative
    }

    return marginValues.positive! + marginValues.negative!
  }

  func hasClearance(layoutBox: ElementBoxWrapper) -> Bool {
    if !layoutBox.hasFloatClear() {
      return false
    }
    // FIXME: precomputedVerticalPositionForFormattingRoot logic ends up calling into this function when the layoutBox (first inflow child) has
    // not been laid out.
    return formattingState().hasClearance(layoutBox: layoutBox)
  }

  func formattingState() -> BlockFormattingState { return blockFormattingState }

  var layoutState: LayoutStateWrapper
  var blockFormattingState: BlockFormattingState
  var inQuirksMode = false
}
