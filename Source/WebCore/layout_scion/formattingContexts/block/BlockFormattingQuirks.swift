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

func isQuirkContainer(layoutBox: ElementBoxWrapper) -> Bool {
  return layoutBox.isBodyBox() || layoutBox.isDocumentBox() || layoutBox.isTableCell()
}

internal func needsStretching(layoutBox: ElementBoxWrapper) -> Bool {
  assert(layoutBox.isInFlow())
  // In quirks mode, in-flow body and html stretch to the initial containing block (height: auto only).
  if !layoutBox.isDocumentBox() && !layoutBox.isBodyBox() {
    return false
  }
  return layoutBox.style.logicalHeight().isAuto()
}

enum VerticalMargin {
  case Before
  case After
}

func hasQuirkMarginToCollapse(layoutBox: ElementBoxWrapper, verticalMargin: VerticalMargin)
  -> Bool
{
  if !layoutBox.isInFlow() {
    return false
  }
  let style = layoutBox.style
  return (verticalMargin == .Before && style.marginBefore().hasQuirk())
    || (verticalMargin == .After && style.marginAfter().hasQuirk())
}

class BlockFormattingQuirks: FormattingQuirks {
  init(blockFormattingContext: BlockFormattingContext) {
    super.init(formattingContext: blockFormattingContext)
  }

  func stretchedInFlowHeightIfApplicable(
    layoutBox: ElementBoxWrapper, contentHeightAndMargin: ContentHeightAndMargin
  ) -> LayoutUnit? {
    assert(layoutState().inQuirksMode())
    if !needsStretching(layoutBox: layoutBox) {
      return nil
    }
    let formattingContext = formattingContext as! BlockFormattingContext
    let nonCollapsedVerticalMargin =
      contentHeightAndMargin.nonCollapsedMargin.before
      + contentHeightAndMargin.nonCollapsedMargin.after

    if layoutBox.isDocumentBox() {
      // Let's stretch the inflow document box(<html>) to the height of the initial containing block (view).
      var documentBoxContentHeight = formattingContext.geometryForBox(
        layoutBox: FormattingContext.initialContainingBlock(layoutBox: layoutBox),
        escapeReason: .DocumentBoxStretchesToViewportQuirk
      ).contentBoxHeight()
      // Document box's own vertical margin/border/padding values always shrink the content height.
      let documentBoxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
      documentBoxContentHeight -=
        nonCollapsedVerticalMargin + documentBoxGeometry.verticalBorderAndPadding()
      return max(contentHeightAndMargin.contentHeight, documentBoxContentHeight)
    }

    // Here is the quirky part for body box when it stretches all the way to the ICB even when the document box does not (e.g. out-of-flow positioned).
    assert(layoutBox.isBodyBox())
    let initialContainingBlock = FormattingContext.initialContainingBlock(layoutBox: layoutBox)
    let initialContainingBlockGeometry = formattingContext.geometryForBox(
      layoutBox: initialContainingBlock, escapeReason: .BodyStretchesToViewportQuirk)
    // Start the content height with the ICB.
    var bodyBoxContentHeight = initialContainingBlockGeometry.contentBoxHeight()
    // Body box's own border and padding shrink the content height.
    let bodyBoxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
    bodyBoxContentHeight -= bodyBoxGeometry.verticalBorderAndPadding()
    // Body box never collapses its vertical margins with the document box but it might collapse its margin with its descendants.
    let nonCollapsedMargin = contentHeightAndMargin.nonCollapsedMargin
    let marginCollapse = BlockMarginCollapse(
      layoutState: formattingContext.layoutState,
      blockFormattingState: formattingContext.formattingState())
    let collapsedMargin = marginCollapse.collapsedVerticalValues(
      layoutBox: layoutBox, nonCollapsedValues: nonCollapsedMargin
    ).collapsedValues
    var usedVerticalMargin = collapsedMargin.before ?? nonCollapsedMargin.before
    usedVerticalMargin +=
      collapsedMargin.isCollapsedThrough
      ? nonCollapsedMargin.after : (collapsedMargin.after ?? nonCollapsedMargin.after)
    bodyBoxContentHeight -= usedVerticalMargin
    // Document box's padding and border also shrink the body box's content height.
    let documentBox = layoutBox.parent()
    let documentBoxGeometry = formattingContext.geometryForBox(
      layoutBox: documentBox, escapeReason: .BodyStretchesToViewportQuirk)
    bodyBoxContentHeight -= documentBoxGeometry.verticalBorderAndPadding()
    // However the non-in-flow document box's vertical margins are ignored. They don't affect the body box's content height.
    if documentBox.isInFlow() {
      let formattingGeometry = formattingContext.formattingGeometry()
      let precomputeDocumentBoxVerticalMargin = formattingGeometry.computedVerticalMargin(
        layoutBox: documentBox,
        horizontalConstraints: formattingGeometry.constraintsForInFlowContent(
          elementBox: initialContainingBlock, escapeReason: .BodyStretchesToViewportQuirk
        ).horizontal)
      bodyBoxContentHeight -=
        (precomputeDocumentBoxVerticalMargin.before ?? LayoutUnit(value: 0))
        + (precomputeDocumentBoxVerticalMargin.after ?? LayoutUnit(value: 0))
    }
    return max(contentHeightAndMargin.contentHeight, bodyBoxContentHeight)
  }

  static func shouldIgnoreCollapsedQuirkMargin(layoutBox: ElementBoxWrapper) -> Bool {
    return isQuirkContainer(layoutBox: layoutBox)
  }

  static func shouldCollapseMarginBeforeWithParentMarginBefore(layoutBox: ElementBoxWrapper) -> Bool
  {
    return hasQuirkMarginToCollapse(layoutBox: layoutBox, verticalMargin: .Before)
      && isQuirkContainer(layoutBox: FormattingContext.containingBlock(layoutBox: layoutBox))
  }

  static func shouldCollapseMarginAfterWithParentMarginAfter(layoutBox: ElementBoxWrapper) -> Bool {
    return hasQuirkMarginToCollapse(layoutBox: layoutBox, verticalMargin: .After)
      && isQuirkContainer(layoutBox: FormattingContext.containingBlock(layoutBox: layoutBox))
  }
}
