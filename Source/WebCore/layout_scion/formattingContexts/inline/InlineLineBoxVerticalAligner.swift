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

struct LineBoxVerticalAligner {
  func computeLogicalHeightAndAlign(lineBox: LineBox) -> InlineLayoutUnit {
    if canUseSimplifiedAlignment(lineBox: lineBox) {
      return simplifiedVerticalAlignment(lineBox: lineBox)
    }
    // This function (partially) implements:
    // 2.2. Layout Within Line Boxes
    // https://www.w3.org/TR/css-inline-3/#line-layout
    // 1. Compute the line box height using the layout bounds geometry. This height computation strictly uses layout bounds and not normal inline level box geometries.
    // 2. Compute the baseline/logical top position of the root inline box. Aligned boxes push the root inline box around inside the line box.
    // 3. Finally align the inline level boxes using (mostly) normal inline level box geometries.
    assert(lineBox.hasContent)
    let lineBoxAlignmentContent = computeLineBoxLogicalHeight(lineBox: lineBox)
    computeRootInlineBoxVerticalPosition(
      lineBox: lineBox, lineBoxAlignmentContent: lineBoxAlignmentContent)

    var lineBoxHeight = lineBoxAlignmentContent.height()
    alignInlineLevelBoxes(lineBox: lineBox, lineBoxLogicalHeight: lineBoxHeight)
    if lineBoxAlignmentContent.hasTextEmphasis {
      lineBoxHeight = adjustForAnnotationIfNeeded(lineBox: lineBox, lineBoxHeight: lineBoxHeight)
    }
    return lineBoxHeight
  }

  func simplifiedVerticalAlignment(lineBox: LineBox) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    let rootInlineBox = lineBox.rootInlineBox
    let rootInlineBoxAscent = rootInlineBox.ascent()

    if !lineBox.hasContent {
      rootInlineBox.setLogicalTop(logicalTop: -rootInlineBoxAscent)
      return InlineLayoutUnit()
    }

    let rootInlineBoxLayoutBounds = rootInlineBox.layoutBounds
    var lineBoxLogicalTop = InlineLayoutUnit()
    var lineBoxLogicalBottom = rootInlineBoxLayoutBounds.height()
    var rootInlineBoxLogicalTop = rootInlineBoxLayoutBounds.ascent - rootInlineBoxAscent
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      // Only baseline alignment for now.
      inlineLevelBox.setLogicalTop(logicalTop: rootInlineBoxAscent - inlineLevelBox.ascent())
      let layoutBounds = inlineLevelBox.layoutBounds
      let layoutBoundsLogicalTop = rootInlineBoxLayoutBounds.ascent - layoutBounds.ascent
      lineBoxLogicalTop = min(lineBoxLogicalTop, layoutBoundsLogicalTop)
      lineBoxLogicalBottom = max(
        lineBoxLogicalBottom, layoutBoundsLogicalTop + layoutBounds.height())
      rootInlineBoxLogicalTop = max(
        rootInlineBoxLogicalTop, layoutBounds.ascent - rootInlineBoxAscent)
    }
    rootInlineBox.setLogicalTop(logicalTop: rootInlineBoxLogicalTop)
    return lineBoxLogicalBottom - lineBoxLogicalTop
  }

  func canUseSimplifiedAlignment(lineBox: LineBox) -> Bool {
    if !lineBox.hasContent {
      return true
    }

    if rootBox().style.lineBoxContain() != RenderStyleWrapper.initialLineBoxContain() {
      return false
    }
    let rootInlineBox = lineBox.rootInlineBox
    if !layoutState().inStandardsMode || rootInlineBox.verticalAlign().type != .Baseline {
      return false
    }
    if rootInlineBox.hasTextEmphasis() {
      return false
    }

    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      if !shouldUseSimplifiedAlignmentForInlineLevelBox(
        inlineLevelBox: inlineLevelBox, rootInlineBox: rootInlineBox)
      {
        return false
      }
    }
    return true
  }

  func shouldUseSimplifiedAlignmentForInlineLevelBox(
    inlineLevelBox: InlineLevelBox, rootInlineBox: InlineLevelBox
  ) -> Bool {
    // TODO(asuhan): implement this
    if inlineLevelBox.hasTextEmphasis() {
      return false
    }
    // Baseline aligned, non-stretchy direct children are considered to be simple for now.
    let layoutBox = inlineLevelBox.layoutBox
    if layoutBox.parent() !== rootInlineBox.layoutBox
      || inlineLevelBox.verticalAlign().type != .Baseline
    {
      return false
    }

    if inlineLevelBox.isAtomicInlineBox() {
      let inlineLevelBoxGeometry = formattingContext().geometryForBox(layoutBox: layoutBox)
      return !inlineLevelBoxGeometry.marginBefore().bool()
        && !inlineLevelBoxGeometry.marginAfter().bool()
        && inlineLevelBoxGeometry.marginBoxHeight() <= rootInlineBox.layoutBounds.ascent
    }
    if inlineLevelBox.isLineBreakBox() {
      // Baseline aligned, non-stretchy line breaks e.g. <div><span><br></span></div> but not <div><span style="font-size: 100px;"><br></span></div>.
      return inlineLevelBox.layoutBounds.ascent <= rootInlineBox.layoutBounds.ascent
    }
    if inlineLevelBox.isInlineBox() {
      // Baseline aligned, non-stretchy inline boxes e.g. <div><span></span></div> but not <div><span style="font-size: 100px;"></span></div>.
      return inlineLevelBox.layoutBounds == rootInlineBox.layoutBounds
    }
    return false
  }

  struct LineBoxAlignmentContent {
    func height() -> InlineLayoutUnit {
      return max(
        nonLineBoxRelativeAlignedMaximumHeight,
        max(topAndBottomAlignedMaximumHeight.top ?? 0, topAndBottomAlignedMaximumHeight.bottom ?? 0)
      )
    }

    var nonLineBoxRelativeAlignedMaximumHeight = InlineLayoutUnit()
    struct TopAndBottomAlignedMaximumHeight {
      var top: InlineLayoutUnit? = nil
      var bottom: InlineLayoutUnit? = nil
    }
    var topAndBottomAlignedMaximumHeight = TopAndBottomAlignedMaximumHeight()
    var hasTextEmphasis = false
  }

  func computeLineBoxLogicalHeight(lineBox: LineBox) -> LineBoxAlignmentContent {
    // This function (partially) implements:
    // 2.2. Layout Within Line Boxes
    // https://www.w3.org/TR/css-inline-3/#line-layout
    // 1. Compute the line box height using the layout bounds geometry. This height computation strictly uses layout bounds and not normal inline level box geometries.
    // 2. Compute the baseline/logical top position of the root inline box. Aligned boxes push the root inline box around inside the line box.
    // 3. Finally align the inline level boxes using (mostly) normal inline level box geometries.
    let rootInlineBox = lineBox.rootInlineBox
    let formattingUtils = formattingUtils()
    var contentHasTextEmphasis = rootInlineBox.hasTextEmphasis()

    // Line box height computation is based on the layout bounds of the inline boxes and not their logical (ascent/descent) dimensions.
    struct AbsoluteTopAndBottom {
      var top = InlineLayoutUnit()
      var bottom = InlineLayoutUnit()
    }
    var inlineLevelBoxAbsoluteTopAndBottomMap: [ObjectIdentifier: AbsoluteTopAndBottom] = [:]

    var minimumLogicalTop: InlineLayoutUnit? = nil
    var maximumLogicalBottom: InlineLayoutUnit? = nil
    if formattingUtils.inlineLevelBoxAffectsLineBox(inlineLevelBox: rootInlineBox) {
      minimumLogicalTop = InlineLayoutUnit()
      maximumLogicalBottom = rootInlineBox.layoutBounds.height()
      inlineLevelBoxAbsoluteTopAndBottomMap.updateValue(
        AbsoluteTopAndBottom(top: minimumLogicalTop!, bottom: maximumLogicalBottom!),
        forKey: ObjectIdentifier(rootInlineBox))
    } else {
      inlineLevelBoxAbsoluteTopAndBottomMap.updateValue(
        AbsoluteTopAndBottom(),
        forKey: ObjectIdentifier(rootInlineBox))
    }

    var lineBoxRelativeInlineLevelBoxes: [InlineLevelBox] = []
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      contentHasTextEmphasis = contentHasTextEmphasis || inlineLevelBox.hasTextEmphasis()

      if inlineLevelBox.hasLineBoxRelativeAlignment() {
        lineBoxRelativeInlineLevelBoxes.append(inlineLevelBox)
        continue
      }
      let parentInlineBox = lineBox.parentInlineBox(inlineLevelBox: inlineLevelBox)
      let inlineBoxTopOffsetFromParentBaseline = logicalTopOffsetFromParentBaseline(
        inlineLevelBox: inlineLevelBox, parentInlineBox: parentInlineBox)
      // Logical top is relative to the parent inline box's layout bounds.
      // Note that this logical top is not the final logical top of the inline level box.
      // This is the logical top in the context of the layout bounds geometry which may be very different from the inline box's normal geometry.
      let inlineLevelBoxLogicalTop =
        parentInlineBox.layoutBounds.ascent - inlineBoxTopOffsetFromParentBaseline
      let parentInlineBoxAbsoluteTopAndBottom = inlineLevelBoxAbsoluteTopAndBottomMap[
        ObjectIdentifier(parentInlineBox), default: AbsoluteTopAndBottom()]
      let absoluteLogicalTop = parentInlineBoxAbsoluteTopAndBottom.top + inlineLevelBoxLogicalTop
      let absoluteLogicalBottom = absoluteLogicalTop + inlineLevelBox.layoutBounds.height()
      inlineLevelBoxAbsoluteTopAndBottomMap.updateValue(
        AbsoluteTopAndBottom(top: absoluteLogicalTop, bottom: absoluteLogicalBottom),
        forKey: ObjectIdentifier(inlineLevelBox))
      // Stretch the min/max absolute values if applicable.
      if formattingUtils.inlineLevelBoxAffectsLineBox(inlineLevelBox: inlineLevelBox) {
        minimumLogicalTop = min(minimumLogicalTop ?? absoluteLogicalTop, absoluteLogicalTop)
        maximumLogicalBottom = max(
          maximumLogicalBottom ?? absoluteLogicalBottom, absoluteLogicalBottom)
      }
    }
    // The line box height computation is as follows:
    // 1. Stretch the line box with the non-line-box relative aligned inline box absolute top and bottom values.
    // 2. Check if the line box relative aligned inline boxes (top, bottom etc) have enough room and stretch the line box further if needed.
    let nonLineBoxRelativeAlignedBoxesMaximumHeight =
      (maximumLogicalBottom ?? InlineLayoutUnit()) - (minimumLogicalTop ?? InlineLayoutUnit())
    var topAlignedBoxesMaximumHeight: InlineLayoutUnit? = nil
    var bottomAlignedBoxesMaximumHeight: InlineLayoutUnit? = nil
    for lineBoxRelativeInlineLevelBox in lineBoxRelativeInlineLevelBoxes {
      if !formattingUtils.inlineLevelBoxAffectsLineBox(
        inlineLevelBox: lineBoxRelativeInlineLevelBox)
      {
        continue
      }
      // This line box relative aligned inline level box stretches the line box.
      let inlineLevelBoxHeight = lineBoxRelativeInlineLevelBox.layoutBounds.height()
      if lineBoxRelativeInlineLevelBox.verticalAlign().type == .Top {
        topAlignedBoxesMaximumHeight = max(inlineLevelBoxHeight, topAlignedBoxesMaximumHeight ?? 0)
        continue
      }
      if lineBoxRelativeInlineLevelBox.verticalAlign().type == .Bottom {
        bottomAlignedBoxesMaximumHeight = max(
          inlineLevelBoxHeight, bottomAlignedBoxesMaximumHeight ?? 0)
        continue
      }
      fatalError("Not reached")
    }
    return LineBoxAlignmentContent(
      nonLineBoxRelativeAlignedMaximumHeight: nonLineBoxRelativeAlignedBoxesMaximumHeight,
      topAndBottomAlignedMaximumHeight: LineBoxAlignmentContent.TopAndBottomAlignedMaximumHeight(
        top: topAlignedBoxesMaximumHeight, bottom: bottomAlignedBoxesMaximumHeight),
      hasTextEmphasis: contentHasTextEmphasis)
  }

  func computeRootInlineBoxVerticalPosition(
    lineBox: LineBox, lineBoxAlignmentContent: LineBoxAlignmentContent
  ) {
    // TODO(asuhan): implement this
    let rootInlineBox = lineBox.rootInlineBox
    let formattingUtils = formattingUtils()
    var hasTopAlignedInlineLevelBox = false

    var inlineLevelBoxAbsoluteBaselineOffsetMap: [ObjectIdentifier: InlineLayoutUnit] = [:]
    inlineLevelBoxAbsoluteBaselineOffsetMap.updateValue(
      InlineLayoutUnit(), forKey: ObjectIdentifier(rootInlineBox))

    var maximumTopOffsetFromRootInlineBoxBaseline: InlineLayoutUnit? = nil
    if formattingUtils.inlineLevelBoxAffectsLineBox(inlineLevelBox: rootInlineBox) {
      maximumTopOffsetFromRootInlineBoxBaseline = rootInlineBox.layoutBounds.ascent
    }

    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      let layoutBounds = inlineLevelBox.layoutBounds

      if inlineLevelBox.hasLineBoxRelativeAlignment() {
        let verticalAlign = inlineLevelBox.verticalAlign()
        if verticalAlign.type == .Top {
          hasTopAlignedInlineLevelBox =
            hasTopAlignedInlineLevelBox
            || affectsRootInlineBoxVerticalPosition(
              inlineLevelBox: inlineLevelBox, formattingUtils: formattingUtils)
          inlineLevelBoxAbsoluteBaselineOffsetMap.updateValue(
            rootInlineBox.layoutBounds.ascent - layoutBounds.ascent,
            forKey: ObjectIdentifier(inlineLevelBox))
        } else if verticalAlign.type == .Bottom {
          inlineLevelBoxAbsoluteBaselineOffsetMap.updateValue(
            layoutBounds.descent - rootInlineBox.layoutBounds.descent,
            forKey: ObjectIdentifier(inlineLevelBox))
        } else {
          fatalError("Not reached")
        }
        continue
      }
      let parentInlineBox = lineBox.parentInlineBox(inlineLevelBox: inlineLevelBox)
      let inlineBoxTopOffsetFromParentBaseline = logicalTopOffsetFromParentBaseline(
        inlineLevelBox: inlineLevelBox, parentInlineBox: parentInlineBox)
      let baselineOffsetFromParentBaseline =
        inlineBoxTopOffsetFromParentBaseline - layoutBounds.ascent
      let absoluteBaselineOffset =
        inlineLevelBoxAbsoluteBaselineOffsetMap[ObjectIdentifier(parentInlineBox)]!
        + baselineOffsetFromParentBaseline
      inlineLevelBoxAbsoluteBaselineOffsetMap.updateValue(
        absoluteBaselineOffset, forKey: ObjectIdentifier(inlineLevelBox))

      if affectsRootInlineBoxVerticalPosition(
        inlineLevelBox: inlineLevelBox, formattingUtils: formattingUtils)
      {
        let topOffsetFromRootInlineBoxBaseline = absoluteBaselineOffset + layoutBounds.ascent
        if maximumTopOffsetFromRootInlineBoxBaseline != nil {
          maximumTopOffsetFromRootInlineBoxBaseline = max(
            maximumTopOffsetFromRootInlineBoxBaseline!, topOffsetFromRootInlineBoxBaseline)
        } else {
          // We are is quirk mode and the root inline box has no content. The root inline box's baseline is anchored at 0.
          // However negative ascent (e.g negative top margin) can "push" the root inline box upwards and have a negative value.
          maximumTopOffsetFromRootInlineBoxBaseline =
            layoutBounds.ascent >= 0
            ? max(0, topOffsetFromRootInlineBoxBaseline)
            : topOffsetFromRootInlineBoxBaseline
        }
      }
    }

    if maximumTopOffsetFromRootInlineBoxBaseline == nil && hasTopAlignedInlineLevelBox {
      // vertical-align: top is a line box relative alignment. It stretches the line box downwards meaning that it does not affect
      // the root inline box's baseline position, but in quirks mode we have to ensure that the root inline box does not end up at 0px.
      maximumTopOffsetFromRootInlineBoxBaseline = rootInlineBox.ascent()
    }
    // vertical-align: bottom stretches the top of the line box pushing the root inline box downwards.
    var bottomAlignedBoxStretch =
      lineBoxAlignmentContent.topAndBottomAlignedMaximumHeight.bottom ?? 0
    if bottomAlignedBoxStretch != 0 {
      // If top happens to stretch the line box, we don't need to push the root inline box anymore.
      if bottomAlignedBoxStretch <= lineBoxAlignmentContent.topAndBottomAlignedMaximumHeight.top
        ?? 0
      {
        bottomAlignedBoxStretch = 0
      }

      // However non-line box relative content needs some space. Root inline box may not end up being at the very bottom.
      if bottomAlignedBoxStretch != 0 {
        if lineBoxAlignmentContent.nonLineBoxRelativeAlignedMaximumHeight > 0 {
          // Negative vertical margin can make aligned boxes have negative height.
          bottomAlignedBoxStretch -= max(
            0, lineBoxAlignmentContent.nonLineBoxRelativeAlignedMaximumHeight)
        }
        bottomAlignedBoxStretch = max(0, bottomAlignedBoxStretch)
      }
    }
    let rootInlineBoxLogicalTop =
      bottomAlignedBoxStretch + (maximumTopOffsetFromRootInlineBoxBaseline ?? 0)
      - rootInlineBox.ascent()
    rootInlineBox.setLogicalTop(logicalTop: rootInlineBoxLogicalTop)
  }

  func affectsRootInlineBoxVerticalPosition(
    inlineLevelBox: InlineLevelBox, formattingUtils: InlineFormattingUtils
  ) -> Bool {
    return formattingUtils.inlineLevelBoxAffectsLineBox(inlineLevelBox: inlineLevelBox)
  }

  func alignInlineLevelBoxes(lineBox: LineBox, lineBoxLogicalHeight: InlineLayoutUnit) {
    // TODO(asuhan): implement this
    var lineBoxRelativeInlineLevelBoxes: [UInt64] = []
    let nonRootInlineLevelBoxes = lineBox.nonRootInlineLevelBoxes()
    for (index, inlineLevelBox) in nonRootInlineLevelBoxes.enumerated() {
      if inlineLevelBox.hasLineBoxRelativeAlignment() {
        lineBoxRelativeInlineLevelBoxes.append(UInt64(index))
        continue
      }
      let parentInlineBox = lineBox.parentInlineBox(inlineLevelBox: inlineLevelBox)
      let inlineBoxTopOffsetFromParentBaseline = logicalTopOffsetFromParentBaseline(
        inlineLevelBox: inlineLevelBox, parentInlineBox: parentInlineBox,
        isInlineLeveBoxAlignment: .Yes)
      let inlineLevelBoxLogicalTop = parentInlineBox.ascent() - inlineBoxTopOffsetFromParentBaseline
      inlineLevelBox.setLogicalTop(logicalTop: inlineLevelBoxLogicalTop)
    }

    for index in lineBoxRelativeInlineLevelBoxes {
      let inlineLevelBox = nonRootInlineLevelBoxes[Int(index)]
      var logicalTop = InlineLayoutUnit()
      switch inlineLevelBox.verticalAlign().type {
      case .Top:
        var ascent = inlineLevelBox.layoutBounds.ascent
        if inlineLevelBox.isInlineBox() {
          if let descendantsEnclosingGeometry = layoutBoundsForInlineBoxSubtree(
            nonRootInlineLevelBoxes: nonRootInlineLevelBoxes, inlineBoxIndex: index)
          {
            ascent =
              !inlineLevelBox.hasContent
              ? descendantsEnclosingGeometry.ascent
              : max(descendantsEnclosingGeometry.ascent, ascent)
          }
        }
        // Note that this logical top is not relative to the parent inline box.
        logicalTop = ascent - inlineLevelBox.ascent()
      case .Bottom:
        var descent = inlineLevelBox.layoutBounds.descent
        if inlineLevelBox.isInlineBox() {
          if let descendantsEnclosingGeometry = layoutBoundsForInlineBoxSubtree(
            nonRootInlineLevelBoxes: nonRootInlineLevelBoxes, inlineBoxIndex: index)
          {
            descent =
              !inlineLevelBox.hasContent
              ? descendantsEnclosingGeometry.descent
              : max(descendantsEnclosingGeometry.descent, descent)
          }
        }
        // Note that this logical top is not relative to the parent inline box.
        logicalTop = lineBoxLogicalHeight - (inlineLevelBox.ascent() + descent)
      default:
        fatalError("Not reached")
      }
      inlineLevelBox.setLogicalTop(logicalTop: logicalTop)
    }
  }

  func adjustForAnnotationIfNeeded(lineBox: LineBox, lineBoxHeight: InlineLayoutUnit)
    -> InlineLayoutUnit
  {
    var lineBoxTop = InlineLayoutUnit()
    var lineBoxBottom = lineBoxHeight
    // At this point we have a properly aligned set of inline level boxes. Let's find out if annotation marks have enough space.
    let adjustedLineBoxHeight = adjustLineBoxHeightIfNeeded(
      lineBox: lineBox, lineBoxTop: &lineBoxTop, lineBoxBottom: &lineBoxBottom)

    if lineBoxHeight != adjustedLineBoxHeight {
      // Annotations needs some space.
      let rootInlineBox = lineBox.rootInlineBox
      let rootInlineBoxTop = rootInlineBox.logicalTop()
      let annotationOffset = -lineBoxTop
      rootInlineBox.setLogicalTop(logicalTop: annotationOffset + rootInlineBoxTop)

      for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
        switch inlineLevelBox.verticalAlign().type {
        case .Top:
          let inlineBoxTop = inlineLevelBox.layoutBounds.ascent - inlineLevelBox.ascent()
          inlineLevelBox.setLogicalTop(
            logicalTop: (inlineLevelBox.textEmphasisAbove() ?? 0) + inlineBoxTop)
        case .Bottom:
          let inlineBoxTop =
            adjustedLineBoxHeight - (inlineLevelBox.layoutBounds.descent + inlineLevelBox.ascent())
          inlineLevelBox.setLogicalTop(
            logicalTop: inlineBoxTop - (inlineLevelBox.textEmphasisBelow() ?? 0))
        default:
          // These alignment positions are relative to the root inline box's baseline.
          break
        }
      }
    }
    return adjustedLineBoxHeight
  }

  func adjustLineBoxHeightIfNeeded(
    lineBox: LineBox, lineBoxTop: inout InlineLayoutUnit, lineBoxBottom: inout InlineLayoutUnit
  )
    -> InlineLayoutUnit
  {
    adjustLineBoxTopAndBottomForInlineBox(
      inlineLevelBox: lineBox.rootInlineBox, lineBox: lineBox, lineBoxTop: &lineBoxTop,
      lineBoxBottom: &lineBoxBottom)
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      if inlineLevelBox.isInlineBox() || inlineLevelBox.isAtomicInlineBox() {
        adjustLineBoxTopAndBottomForInlineBox(
          inlineLevelBox: inlineLevelBox, lineBox: lineBox, lineBoxTop: &lineBoxTop,
          lineBoxBottom: &lineBoxBottom)
      }
    }

    return lineBoxBottom - lineBoxTop
  }

  func adjustLineBoxTopAndBottomForInlineBox(
    inlineLevelBox: InlineLevelBox, lineBox: LineBox, lineBoxTop: inout InlineLayoutUnit,
    lineBoxBottom: inout InlineLayoutUnit
  ) {
    assert(inlineLevelBox.isInlineBox() || inlineLevelBox.isAtomicInlineBox())
    let inlineBoxTop = lineBox.inlineLevelBoxAbsoluteTop(inlineLevelBox: inlineLevelBox)
    let inlineBoxBottom = inlineBoxTop + inlineLevelBox.logicalHeight()

    switch inlineLevelBox.verticalAlign().type {
    case .Baseline, .Middle, .BaselineMiddle, .Length, .Sub, .Super, .TextTop, .TextBottom, .Bottom:
      if let aboveSpace = inlineLevelBox.textEmphasisAbove() {
        lineBoxTop = min(lineBoxTop, inlineBoxTop - aboveSpace)
      }
      if let belowSpace = inlineLevelBox.textEmphasisBelow() {
        lineBoxBottom = max(lineBoxBottom, inlineBoxBottom + belowSpace)
      }
    case .Top:
      // FIXME: Check if horizontal vs. vertical writing mode should be taking into account.
      let annotationSpace =
        (inlineLevelBox.textEmphasisAbove() ?? 0) + (inlineLevelBox.textEmphasisBelow() ?? 0)
      lineBoxBottom = max(lineBoxBottom, inlineBoxBottom + annotationSpace)
    }
  }

  func layoutBoundsForInlineBoxSubtree(
    nonRootInlineLevelBoxes: LineBox.InlineLevelBoxList, inlineBoxIndex: UInt64
  ) -> InlineLevelBox.AscentAndDescent? {
    // https://w3c.github.io/csswg-drafts/css2/#propdef-vertical-align
    //
    // top/bottom values align the element relative to the line box.
    // Since the element may have children aligned relative to it (which in turn may have descendants aligned relative to them),
    // these values use the bounds of the aligned subtree.
    // The aligned subtree of an inline element contains that element and the aligned subtrees of all children
    // inline elements whose computed vertical-align value is not top or bottom.
    // The top of the aligned subtree is the highest of the tops of the boxes in the subtree, and the bottom is analogous.
    assert(nonRootInlineLevelBoxes[Int(inlineBoxIndex)].isInlineBox())
    let formattingUtils = formattingUtils()
    var maximumAscent: InlineLayoutUnit? = nil
    var maximumDescent: InlineLayoutUnit? = nil
    let inlineBox = nonRootInlineLevelBoxes[Int(inlineBoxIndex)]
    let inlineBoxParent = inlineBox.layoutBox.parent()
    for index in Int(inlineBoxIndex + 1)..<nonRootInlineLevelBoxes.count {
      let descendantInlineLevelBox = nonRootInlineLevelBoxes[index]
      if descendantInlineLevelBox.layoutBox.parent() === inlineBoxParent {
        // We are at the end of the descendant list.
        break
      }
      if !formattingUtils.inlineLevelBoxAffectsLineBox(inlineLevelBox: descendantInlineLevelBox)
        || descendantInlineLevelBox.hasLineBoxRelativeAlignment()
      {
        continue
      }

      // ascent/descent here really mean enclosing geometry adjusted by vertical alignemnt, which is in case of baseline alignment is simply layout bounds but
      // e.g. with middle alignment, "ascent and descent" are inline level box height / 2.
      let ascent = logicalTopOffsetFromParentBaseline(
        inlineLevelBox: descendantInlineLevelBox, parentInlineBox: inlineBox)
      let descent = descendantInlineLevelBox.layoutBounds.height() - ascent
      maximumAscent = max(ascent, maximumAscent ?? ascent)
      maximumDescent = max(descent, maximumDescent ?? descent)
    }
    if maximumAscent != nil {
      assert(maximumDescent != nil)
      return InlineLevelBox.AscentAndDescent(ascent: maximumAscent!, descent: maximumDescent!)
    }
    return nil
  }

  enum IsInlineLeveBoxAlignment: UInt8 {
    case No
    case Yes
  }

  func logicalTopOffsetFromParentBaseline(
    inlineLevelBox: InlineLevelBox, parentInlineBox: InlineLevelBox,
    isInlineLeveBoxAlignment: IsInlineLeveBoxAlignment = .No
  ) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    assert(parentInlineBox.isInlineBox())

    let verticalAlign = inlineLevelBox.verticalAlign()
    let ascent =
      isInlineLeveBoxAlignment == .Yes
      ? inlineLevelBox.ascent() : inlineLevelBox.layoutBounds.ascent
    let height =
      isInlineLeveBoxAlignment == .Yes
      ? inlineLevelBox.logicalHeight() : inlineLevelBox.layoutBounds.height()

    switch verticalAlign.type {
    case .Baseline:
      return ascent
    case .Middle:
      return height / 2 + (parentInlineBox.primarymetricsOfPrimaryFont().xHeight() ?? 0) / 2
    case .BaselineMiddle:
      return height / 2
    case .Length:
      return verticalAlign.baselineOffset! + ascent
    case .TextTop:
      if isInlineLeveBoxAlignment == .No {
        return parentInlineBox.ascent()
      }
      // Note that text-top aligns with the inline box's font metrics top (ascent) and not the layout bounds top.
      return parentInlineBox.ascent()
        + (inlineLevelBox.ascent() - inlineLevelBox.layoutBounds.ascent)
    case .TextBottom:
      if isInlineLeveBoxAlignment == .No {
        return height - parentInlineBox.descent()
      }
      // Note that text-bottom aligns with the inline box's font metrics bottom (descent) and not the layout bounds bottom.
      return (inlineLevelBox.ascent() + inlineLevelBox.layoutBounds.descent)
        - parentInlineBox.descent()
    case .Sub:
      return ascent - (parentInlineBox.fontSize() / 5 + 1)
    case .Super:
      return ascent + parentInlineBox.fontSize() / 3 + 1
    default:
      fatalError("Not implemented yet")
    }
  }

  func formattingUtils() -> InlineFormattingUtils {
    return formattingContext().formattingUtils()
  }

  func formattingContext() -> InlineFormattingContext {
    return inlineFormattingContext
  }

  func rootBox() -> ElementBoxWrapper {
    return inlineFormattingContext.root()
  }

  func layoutState() -> InlineLayoutState { return formattingContext().layoutState() }

  var inlineFormattingContext: InlineFormattingContext
}
