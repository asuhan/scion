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

import Foundation

internal func ascentWithTextBoxEdgeForInlineBox(
  inlineBox: InlineLevelBox, fontMetrics: FontMetricsWrapper, fontBaseline: FontBaseline
) -> InlineLayoutUnit {
  switch inlineBox.lineFitEdge().over {
  case .Leading, .Text:
    return InlineLayoutUnit(fontMetrics.intAscent(baselineType: fontBaseline))
  case .CapHeight:
    return InlineLayoutUnit(fontMetrics.intCapHeight())
  case .ExHeight:
    return roundf(fontMetrics.xHeight() ?? 0)
  case .CJKIdeographic:
    return InlineLayoutUnit(fontMetrics.intAscent(baselineType: .IdeographicBaseline))
  case .CJKIdeographicInk:
    fatalError("Not implemented yet")
  default:
    fatalError("Not reached")
  }
}

internal func descentWithTextBoxEdgeForInlineBox(
  inlineBox: InlineLevelBox, fontMetrics: FontMetricsWrapper, fontBaseline: FontBaseline
) -> InlineLayoutUnit {
  switch inlineBox.lineFitEdge().under {
  case .Leading, .Text:
    return InlineLayoutUnit(fontMetrics.intDescent(baselineType: fontBaseline))
  case .Alphabetic:
    return 0
  case .CJKIdeographic:
    return InlineLayoutUnit(fontMetrics.intDescent(baselineType: .IdeographicBaseline))
  case .CJKIdeographicInk:
    fatalError("Not implemented yet")
  default:
    fatalError("Not reached")
  }
}

internal func ascentAndDescentWithTextBoxEdgeForInlineBox(
  inlineBox: InlineLevelBox, fontMetrics: FontMetricsWrapper, fontBaseline: FontBaseline
) -> InlineLevelBox.AscentAndDescent {
  assert(inlineBox.isInlineBox())

  if inlineBox.isRootInlineBox() {
    return InlineLevelBox.AscentAndDescent(
      ascent: InlineLayoutUnit(fontMetrics.intAscent(baselineType: fontBaseline)),
      descent: InlineLayoutUnit(fontMetrics.intDescent(baselineType: fontBaseline))
    )
  }
  return InlineLevelBox.AscentAndDescent(
    ascent: ascentWithTextBoxEdgeForInlineBox(
      inlineBox: inlineBox, fontMetrics: fontMetrics, fontBaseline: fontBaseline),
    descent: descentWithTextBoxEdgeForInlineBox(
      inlineBox: inlineBox, fontMetrics: fontMetrics, fontBaseline: fontBaseline)
  )
}

internal func effectiveTextBoxEdge(
  rootInlineBox: InlineLevelBox, blockLayoutState: BlockLayoutState
) -> TextEdge {
  // TextBoxEdge property specifies the metrics to use for text-box-trim effects. Values have the same meanings as for line-fit-edge;
  // the auto keyword uses the value of line-fit-edge on the root inline of the the affected line box,
  // interpreting leading (the initial value) as text.
  // https://drafts.csswg.org/css-inline-3/#text-box-edge
  let textBoxEdge = blockLayoutState.textBoxEdge
  if textBoxEdge.under != .Auto {
    return textBoxEdge
  }

  let lineFitEdge = rootInlineBox.lineFitEdge()
  if lineFitEdge.under == .Leading {
    return TextEdge(over: .Text, under: .Text)
  }
  return lineFitEdge
}

internal func primaryFontMetricsForInlineBox(
  inlineBox: InlineLevelBox, fontBaseline: FontBaseline = .AlphabeticBaseline
) -> InlineLevelBox.AscentAndDescent {
  assert(inlineBox.isInlineBox())
  let fontMetrics = inlineBox.primarymetricsOfPrimaryFont()
  let ascent = InlineLayoutUnit(fontMetrics.intAscent(baselineType: fontBaseline))
  let descent = InlineLayoutUnit(fontMetrics.intDescent(baselineType: fontBaseline))
  return InlineLevelBox.AscentAndDescent(ascent: ascent, descent: descent)
}

internal func isLineFitEdgeLeading(inlineBox: InlineLevelBox) -> Bool {
  assert(inlineBox.isInlineBox())
  let lineFitEdge = inlineBox.lineFitEdge()
  assert(lineFitEdge.over != .Leading || lineFitEdge.under == .Leading)
  return lineFitEdge.over == .Leading
}

struct LineBoxBuilder {
  init(inlineFormattingContext: InlineFormattingContext, lineLayoutResult: LineLayoutResult) {
    self.inlineFormattingContext = inlineFormattingContext
    self.lineLayoutResult = lineLayoutResult
  }

  mutating func build(lineIndex: UInt64) -> LineBox {
    var lineBox = LineBox(
      rootLayoutBox: rootBox(), contentLogicalLeft: lineLayoutResult.contentGeometry.logicalLeft,
      contentLogicalWidth: contentLogicalWidth(), lineIndex: lineIndex,
      nonSpanningInlineLevelBoxCount: lineLayoutResult.nonSpanningInlineLevelBoxCount)
    constructInlineLevelBoxes(lineBox: &lineBox)
    adjustIdeographicBaselineIfApplicable(lineBox: &lineBox)
    adjustInlineBoxHeightsForLineBoxContainIfApplicable(lineBox: lineBox)
    if lineHasNonLineSpanningRubyContent {
      RubyFormattingContext.applyAnnotationContributionToLayoutBounds(
        lineBox: lineBox, inlineFormattingContext: formattingContext())
    }
    computeLineBoxGeometry(lineBox: &lineBox)
    adjustOutsideListMarkersPosition(lineBox: lineBox)

    if let adjustment = formattingContext().quirks().adjustmentForLineGridLineSnap(lineBox: lineBox)
    {
      expandAboveRootInlineBox(lineBox: lineBox, expansion: adjustment)
    }

    return lineBox
  }

  // FIXME: The overflowing hanging content should be part of the ink overflow.
  private func contentLogicalWidth() -> InlineLayoutUnit {
    if lineLayoutResult.directionality.inlineBaseDirection == .LTR {
      return lineLayoutResult.contentGeometry.logicalWidth
        - lineLayoutResult.hangingContent.logicalWidth
    }
    // FIXME: Currently clients of the inline iterator interface (editing, selection, DOM etc) can't deal with
    // hanging content offsets when they affect the rest of the content.
    // In left-to-right inline direction, hanging content is always trailing hence the width does not impose offset on the rest of the content
    // while with right-to-left, the hanging content is visually leading (left side of the content) and it does offset the rest of the line.
    // What's missing is a way to tell that while the content starts at the left side of the (visually leading) hanging content
    // the root inline box has an offset, the width of the hanging content (essentially decoupling the content and the root inline box visual left).
    // For now just include the hanging content in the root inline box as if it was not hanging (this is how legacy line layout works).
    return lineLayoutResult.contentGeometry.logicalWidth
  }

  private func setVerticalPropertiesForInlineLevelBox(
    lineBox: LineBox, inlineLevelBox: InlineLevelBox
  ) {
    if inlineLevelBox.isInlineBox() {
      var ascentAndDescent = ascentAndDescentForInlineLevelBox(
        lineBox: lineBox, inlineLevelBox: inlineLevelBox)

      setVerticalProperties(inlineLevelBox: inlineLevelBox, ascentAndDescent: &ascentAndDescent)
      // Override default layout bounds.
      setLayoutBoundsForInlineBox(inlineBox: inlineLevelBox, fontBaseline: lineBox.baselineType)

      // With text-box-trim, the inline box top is not always where the content starts.
      let fontMetricBasedAscent = primaryFontMetricsForInlineBox(
        inlineBox: inlineLevelBox, fontBaseline: lineBox.baselineType
      ).ascent
      inlineLevelBox.setInlineBoxContentOffsetForTextBoxTrim(
        offset: fontMetricBasedAscent - ascentAndDescent.ascent)
      return
    }
    if inlineLevelBox.isLineBreakBox() {
      var parentAscentAndDescent = primaryFontMetricsForInlineBox(
        inlineBox: lineBox.parentInlineBox(inlineLevelBox: inlineLevelBox),
        fontBaseline: lineBox.baselineType)
      setVerticalProperties(
        inlineLevelBox: inlineLevelBox, ascentAndDescent: &parentAscentAndDescent)
      return
    }
    if inlineLevelBox.isListMarker() {
      let layoutBox = inlineLevelBox.layoutBox as! ElementBoxWrapper
      let listMarkerBoxGeometry = formattingContext().geometryForBox(layoutBox: layoutBox)
      let marginBoxHeight = listMarkerBoxGeometry.marginBoxHeight()

      if lineBox.baselineType == .IdeographicBaseline {
        // FIXME: We should rely on the integration baseline.
        var ascentAndDescentInOut = primaryFontMetricsForInlineBox(
          inlineBox: lineBox.parentInlineBox(inlineLevelBox: inlineLevelBox),
          fontBaseline: lineBox.baselineType)
        setVerticalProperties(
          inlineLevelBox: inlineLevelBox,
          ascentAndDescent: &ascentAndDescentInOut)
        inlineLevelBox.setLogicalHeight(logicalHeight: marginBoxHeight.float())
        return
      }
      if let ascent = layoutBox.baselineForIntegration() {
        if layoutBox.isListMarkerImage() {
          var ascentAndDescentInOut = InlineLevelBox.AscentAndDescent(
            ascent: ascent.float(), descent: (marginBoxHeight - ascent).float())
          return setVerticalProperties(
            inlineLevelBox: inlineLevelBox,
            ascentAndDescent: &ascentAndDescentInOut)
        }
        // Special list marker handling. Text driven list markers behave as text when it comes to layout bounds/ascent descent.
        // This needs to consult the list marker's style (and not the root) because we don't follow the DOM insertion point in case like this:
        // <li><div>content</div></li>
        // where the list marker ends up inside the <div> and the <div>'s style != <li>'s style.
        inlineLevelBox.setLayoutBounds(
          layoutBounds: InlineLevelBox.AscentAndDescent(
            ascent: ascent.float(),
            descent: layoutBox.style.computedLineHeight() - ascent.float()
          ))

        let fontMetrics = inlineLevelBox.primarymetricsOfPrimaryFont()
        let fontBaseline = lineBox.baselineType
        inlineLevelBox.setAscentAndDescent(
          ascentAndDescent: InlineLevelBox.AscentAndDescent(
            ascent: InlineLayoutUnit(fontMetrics.intAscent(baselineType: fontBaseline)),
            descent: InlineLayoutUnit(fontMetrics.intDescent(baselineType: fontBaseline))
          )
        )

        inlineLevelBox.setLogicalHeight(logicalHeight: marginBoxHeight.float())
        return
      }
      var ascentAndDescentInOut = InlineLevelBox.AscentAndDescent(ascent: marginBoxHeight.float())
      setVerticalProperties(
        inlineLevelBox: inlineLevelBox,
        ascentAndDescent: &ascentAndDescentInOut)
      return
    }
    if inlineLevelBox.isAtomicInlineBox() {
      let layoutBox = inlineLevelBox.layoutBox
      let inlineLevelBoxGeometry = formattingContext().geometryForBox(layoutBox: layoutBox)
      let marginBoxHeight = inlineLevelBoxGeometry.marginBoxHeight()
      let ascent = ascentForInlineLevelBox(layoutBox: layoutBox, marginBoxHeight: marginBoxHeight)
      var ascentAndDescentInOut = InlineLevelBox.AscentAndDescent(
        ascent: ascent, descent: marginBoxHeight.float() - ascent
      )
      setVerticalProperties(
        inlineLevelBox: inlineLevelBox,
        ascentAndDescent: &ascentAndDescentInOut, applyLegacyRounding: false)
      return
    }
    fatalError("Not reached")
  }

  private func setLayoutBoundsForInlineBox(inlineBox: InlineLevelBox, fontBaseline: FontBaseline) {
    assert(inlineBox.isInlineBox())

    var layoutBounds = layoutBounds(inlineBox: inlineBox, fontBaseline: fontBaseline)

    applyTextBoxEdgeAdjustment(layoutBounds: &layoutBounds, inlineBox: inlineBox)

    layoutBounds.round()
    inlineBox.setLayoutBounds(layoutBounds: layoutBounds)
  }

  private func layoutBounds(inlineBox: InlineLevelBox, fontBaseline: FontBaseline)
    -> InlineLevelBox.AscentAndDescent
  {
    let ascentDescent = ascentAndDescentWithTextBoxEdgeForInlineBox(
      inlineBox: inlineBox, fontMetrics: inlineBox.primarymetricsOfPrimaryFont(),
      fontBaseline: fontBaseline)

    // FIXME: Annotation root should not have any impact here with the proper annotation box handling (dedicated IFC line for annotations and line-height is 1).
    if rootBox().isRubyAnnotationBox() {
      return ascentDescent
    }

    var ascent = ascentDescent.ascent
    var descent = ascentDescent.descent

    if !inlineBox.isPreferredLineHeightFontMetricsBased() {
      // https://www.w3.org/TR/css-inline-3/#inline-height
      // When computed line-height is not normal, calculate the leading L as L = line-height - (A + D).
      // Half the leading (its half-leading) is added above A, and the other half below D,
      // giving an effective ascent above the baseline of A′ = A + L/2, and an effective descent of D′ = D + L/2.
      var halfLeading = (floor(inlineBox.preferredLineHeight()) - (ascent + descent)) / 2
      if !isLineFitEdgeLeading(inlineBox: inlineBox) && !inlineBox.isRootInlineBox() {
        // However, if text-box-edge is not leading and this is not the root inline box, if the half-leading is positive, treat it as zero.
        halfLeading = min(halfLeading, 0)
      }
      ascent += halfLeading
      descent += halfLeading
    } else {
      // https://www.w3.org/TR/css-inline-3/#inline-height
      // If line-height computes to normal and either text-box-edge is leading or this is the root inline box,
      // the font’s line gap metric may also be incorporated into A and D by adding half to each side as half-leading.
      let shouldIncorporateHalfLeading =
        inlineBox.isRootInlineBox() || isLineFitEdgeLeading(inlineBox: inlineBox)
      if shouldIncorporateHalfLeading {
        let lineGap = Float32(inlineBox.primarymetricsOfPrimaryFont().intLineSpacing())
        let halfLeading = (lineGap - (ascent + descent)) / 2
        ascent += halfLeading
        descent += halfLeading
      }
    }
    return InlineLevelBox.AscentAndDescent(ascent: ascent, descent: descent)
  }

  private func applyTextBoxEdgeAdjustment(
    layoutBounds: inout InlineLevelBox.AscentAndDescent, inlineBox: InlineLevelBox
  ) {
    if isLineFitEdgeLeading(inlineBox: inlineBox) || inlineBox.isRootInlineBox() {
      return
    }
    // Additionally, when text-box-edge is not leading, the layout bounds are inflated by the sum of the margin,
    // border, and padding on each side.
    assert(!inlineBox.isRootInlineBox())
    let inlineBoxGeometry = formattingContext().geometryForBox(layoutBox: inlineBox.layoutBox)
    layoutBounds.ascent += inlineBoxGeometry.marginBorderAndPaddingBefore().float()
    layoutBounds.descent += inlineBoxGeometry.marginBorderAndPaddingAfter().float()
  }

  private func setVerticalProperties(
    inlineLevelBox: InlineLevelBox, ascentAndDescent: inout InlineLevelBox.AscentAndDescent,
    applyLegacyRounding: Bool = true
  ) {
    if applyLegacyRounding {
      ascentAndDescent.round()
    }
    inlineLevelBox.setAscentAndDescent(ascentAndDescent: ascentAndDescent)
    inlineLevelBox.setLayoutBounds(layoutBounds: ascentAndDescent)
    inlineLevelBox.setLogicalHeight(logicalHeight: ascentAndDescent.height())
  }

  private func ascentAndDescentForInlineLevelBox(lineBox: LineBox, inlineLevelBox: InlineLevelBox)
    -> InlineLevelBox.AscentAndDescent
  {
    let fontBaseline = lineBox.baselineType
    if inlineLevelBox.isRootInlineBox() {
      return primaryFontMetricsForInlineBox(inlineBox: inlineLevelBox, fontBaseline: fontBaseline)
    }
    let fontMetrics = inlineLevelBox.primarymetricsOfPrimaryFont()
    return ascentAndDescentWithTextBoxEdgeForInlineBox(
      inlineBox: inlineLevelBox, fontMetrics: fontMetrics, fontBaseline: fontBaseline)
  }

  private func ascentForInlineLevelBox(layoutBox: BoxWrapper, marginBoxHeight: LayoutUnit)
    -> InlineLayoutUnit
  {
    if layoutState().shouldNotSynthesizeInlineBlockBaseline {
      return ((layoutBox as! ElementBoxWrapper).baselineForIntegration() ?? marginBoxHeight).float()
    }

    if layoutBox.isInlineBlockBox() {
      // The baseline of an 'inline-block' is the baseline of its last line box in the normal flow, unless it has either no in-flow line boxes or
      // if its 'overflow' property has a computed value other than 'visible', in which case the baseline is the bottom margin edge.
      let synthesizeBaseline =
        !layoutBox.establishesInlineFormattingContext() || !layoutBox.style.isOverflowVisible()
      if synthesizeBaseline {
        return marginBoxHeight.float()
      }

      // FIXME: Grab the first/last baseline off of the inline formatting context (display content).
      fatalError("NOT IMPLEMENTED YET")
    }
    return marginBoxHeight.float()
  }

  private func adjustInlineBoxHeightsForLineBoxContainIfApplicable(lineBox: LineBox) {
    // While line-box-contain normally tells whether a certain type of content should be included when computing the line box height,
    // font and Glyphs values affect the "size" of the associated inline boxes (which then affect the line box height).
    let lineBoxContain = rootBox().style.lineBoxContain()
    // Collect layout bounds based on the contain property and set them on the inline boxes when they are applicable.
    var inlineBoxBoundsMap: [ObjectIdentifier: TextUtil.EnclosingAscentDescent] = [:]
    var idToObj: [ObjectIdentifier: InlineLevelBox] = [:]

    if lineBoxContain.contains(.InlineBox) {
      for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
        if !inlineLevelBox.isInlineBox() {
          continue
        }
        let inlineBoxGeometry = formattingContext().geometryForBox(
          layoutBox: inlineLevelBox.layoutBox)
        let ascent =
          inlineLevelBox.ascent() + inlineBoxGeometry.marginBorderAndPaddingBefore().float()
        let descent =
          inlineLevelBox.descent() + inlineBoxGeometry.marginBorderAndPaddingAfter().float()
        inlineBoxBoundsMap.updateValue(
          TextUtil.EnclosingAscentDescent(ascent: ascent, descent: descent),
          forKey: ObjectIdentifier(inlineLevelBox))
        idToObj.updateValue(inlineLevelBox, forKey: ObjectIdentifier(inlineLevelBox))
      }
    }

    if lineBoxContain.contains(.Font) {
      // Assign font based layout bounds to all inline boxes.
      ensureFontMetricsBasedHeight(
        inlineBox: lineBox.rootInlineBox, lineBox: lineBox, inlineBoxBoundsMap: &inlineBoxBoundsMap,
        idToObj: &idToObj)
      for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
        if !inlineLevelBox.isInlineBox() {
          continue
        }
        ensureFontMetricsBasedHeight(
          inlineBox: inlineLevelBox, lineBox: lineBox, inlineBoxBoundsMap: &inlineBoxBoundsMap,
          idToObj: &idToObj)
      }
    }

    if lineBoxContain.contains(.Glyphs) {
      // Compute text content (glyphs) hugging inline box layout bounds.
      for run in lineLayoutResult.inlineContent {
        if !run.isText() {
          continue
        }

        let textBox = run.layoutBox as! InlineTextBoxWrapper
        let textContent = run.textContent!
        let style = isFirstLine() ? textBox.firstLineStyle() : textBox.style
        let enclosingAscentDescentForRun = TextUtil.enclosingGlyphBoundsForText(
          textContent: StringWrapperView(s: textBox.content).substring(
            start: UInt32(textContent.start), length: UInt32(textContent.length)), style: style)

        let parentInlineBox = lineBox.parentInlineBox(lineRun: run)
        var enclosingAscentDescentForInlineBox = inlineBoxBoundsMap[
          ObjectIdentifier(parentInlineBox), default: TextUtil.EnclosingAscentDescent()]
        enclosingAscentDescentForInlineBox.ascent = max(
          enclosingAscentDescentForInlineBox.ascent, -enclosingAscentDescentForRun.ascent)
        enclosingAscentDescentForInlineBox.descent = max(
          enclosingAscentDescentForInlineBox.descent, enclosingAscentDescentForRun.descent)

        inlineBoxBoundsMap.updateValue(
          enclosingAscentDescentForInlineBox, forKey: ObjectIdentifier(parentInlineBox))
        idToObj.updateValue(parentInlineBox, forKey: ObjectIdentifier(parentInlineBox))
      }
    }

    if lineBoxContain.contains(.InitialLetter) {
      // Initial letter contain is based on the font metrics cap geometry and we hug descent.
      let rootInlineBox = lineBox.rootInlineBox
      let fontMetrics = rootInlineBox.primarymetricsOfPrimaryFont()
      var initialLetterAscent = InlineLayoutUnit(fontMetrics.intCapHeight())
      var initialLetterDescent = InlineLayoutUnit()

      for run in lineLayoutResult.inlineContent {
        // We really should only have one text run for initial letter.
        if !run.isText() {
          continue
        }

        let textBox = run.layoutBox as! InlineTextBoxWrapper
        let textContent = run.textContent!
        let style = isFirstLine() ? textBox.firstLineStyle() : textBox.style
        let ascentAndDescent = TextUtil.enclosingGlyphBoundsForText(
          textContent: StringWrapperView(s: textBox.content).substring(
            start: UInt32(textContent.start), length: UInt32(textContent.length)), style: style)

        initialLetterDescent = ascentAndDescent.descent
        if lineBox.baselineType != .AlphabeticBaseline {
          initialLetterAscent = -ascentAndDescent.ascent
        }
        break
      }
      inlineBoxBoundsMap.updateValue(
        TextUtil.EnclosingAscentDescent(ascent: initialLetterAscent, descent: initialLetterDescent),
        forKey: ObjectIdentifier(rootInlineBox))
      idToObj.updateValue(rootInlineBox, forKey: ObjectIdentifier(rootInlineBox))
    }

    if inlineBoxBoundsMap.isEmpty {
      return
    }

    // XXX: why is this segfaulting?
    for (inlineBoxObjId, inlineBox) in idToObj {
      let enclosingAscentDescentForInlineBox = inlineBoxBoundsMap[inlineBoxObjId]!
      let inlineBoxLayoutBounds = inlineBox.layoutBounds

      // "line-box-container: block" The extended block progression dimension of the root inline box must fit within the line box.
      let mayShrinkLineBox =
        inlineBox.isRootInlineBox() ? !lineBoxContain.contains(.Block) : true
      let ascent =
        mayShrinkLineBox
        ? enclosingAscentDescentForInlineBox.ascent
        : max(enclosingAscentDescentForInlineBox.ascent, inlineBoxLayoutBounds.ascent)
      let descent =
        mayShrinkLineBox
        ? enclosingAscentDescentForInlineBox.descent
        : max(enclosingAscentDescentForInlineBox.descent, inlineBoxLayoutBounds.descent)
      inlineBox.setLayoutBounds(
        layoutBounds: InlineLevelBox.AscentAndDescent(
          ascent: ceilf(ascent), descent: ceilf(descent)))
    }
  }

  private func ensureFontMetricsBasedHeight(
    inlineBox: InlineLevelBox, lineBox: LineBox,
    inlineBoxBoundsMap: inout [ObjectIdentifier: TextUtil.EnclosingAscentDescent],
    idToObj: inout [ObjectIdentifier: InlineLevelBox]
  ) {
    assert(inlineBox.isInlineBox())
    let ascentAndDescent = primaryFontMetricsForInlineBox(
      inlineBox: inlineBox, fontBaseline: lineBox.baselineType)
    var ascent = ascentAndDescent.ascent
    var descent = ascentAndDescent.descent
    let lineGap = InlineLayoutUnit(inlineBox.primarymetricsOfPrimaryFont().intLineSpacing())
    let halfLeading =
      !rootBox().isRubyAnnotationBox() ? (lineGap - (ascent + descent)) / 2 : 0
    ascent += halfLeading
    descent += halfLeading
    // FIXME(asuhan): isEmptyIgnoringNullReferences
    if let fallbackFonts = fallbackFontsForInlineBoxes[ObjectIdentifier(inlineBox)] {
      if fallbackFonts.isEmpty {
        let enclosingAscentAndDescent = enclosingAscentDescentWithFallbackFonts(
          inlineBox: inlineBox, fallbackFontsForContent: fallbackFonts,
          fontBaseline: lineBox.baselineType)
        ascent = max(ascent, enclosingAscentAndDescent.ascent)
        descent = max(descent, enclosingAscentAndDescent.descent)
      }
    }
    inlineBoxBoundsMap.updateValue(
      TextUtil.EnclosingAscentDescent(ascent: ascent, descent: descent),
      forKey: ObjectIdentifier(inlineBox))
    idToObj.updateValue(inlineBox, forKey: ObjectIdentifier(inlineBox))
  }

  private mutating func computeLineBoxGeometry(lineBox: inout LineBox) {
    let lineBoxLogicalHeight = applyTextBoxTrimIfNeeded(
      lineBoxLogicalHeightIn: LineBoxVerticalAligner(inlineFormattingContext: formattingContext())
        .computeLogicalHeightAndAlign(lineBox: lineBox),
      rootInlineBox: lineBox.rootInlineBox)
    lineBox.setLogicalRect(
      logicalRect:
        InlineRect(
          topLeft: lineLayoutResult.lineGeometry.logicalTopLeft,
          width: lineLayoutResult.lineGeometry.logicalWidth, height: lineBoxLogicalHeight))
  }

  private func enclosingAscentDescentWithFallbackFonts(
    inlineBox: InlineLevelBox, fallbackFontsForContent: TextUtil.FallbackFontList,
    fontBaseline: FontBaseline
  ) -> InlineLevelBox.AscentAndDescent {
    // FIXME(asuhan): isEmptyIgnoringNullReferences
    assert(!fallbackFontsForContent.isEmpty)
    assert(inlineBox.isInlineBox())

    // https://www.w3.org/TR/css-inline-3/#inline-height
    // When the computed line-height is normal, the layout bounds of an inline box encloses all its glyphs, going from the highest A to the deepest D.
    var maxAscent = InlineLayoutUnit()
    var maxDescent = InlineLayoutUnit()
    // If line-height computes to normal and either text-box-edge is leading or this is the root inline box,
    // the font's line gap metric may also be incorporated into A and D by adding half to each side as half-leading.
    let shouldUseLineGapToAdjustAscentDescent =
      (inlineBox.isRootInlineBox() || isLineFitEdgeLeading(inlineBox: inlineBox))
      && !rootBox().isRubyAnnotationBox()
    for fontPtr in fallbackFontsForContent {
      let font = FontWrapper(p: UnsafeRawPointer(bitPattern: fontPtr)!)
      let fontMetrics = font.fontMetrics()
      let ascentAndDescent = ascentAndDescentWithTextBoxEdgeForInlineBox(
        inlineBox: inlineBox, fontMetrics: fontMetrics, fontBaseline: fontBaseline)
      var ascent = ascentAndDescent.ascent
      var descent = ascentAndDescent.descent
      if shouldUseLineGapToAdjustAscentDescent {
        let halfLeading = (InlineLayoutUnit(fontMetrics.intLineSpacing()) - (ascent + descent)) / 2
        ascent += halfLeading
        descent += halfLeading
      }
      maxAscent = max(maxAscent, ascent)
      maxDescent = max(maxDescent, descent)
    }
    // We need floor/ceil to match legacy layout integral positioning.
    return InlineLevelBox.AscentAndDescent(ascent: floorf(maxAscent), descent: ceilf(maxDescent))
  }

  private mutating func collectFallbackFonts(
    parentInlineBox: InlineLevelBox, run: Line.Run, style: RenderStyleWrapper
  ) -> TextUtil.FallbackFontList {
    assert(parentInlineBox.isInlineBox())
    let inlineTextBox = run.layoutBox as! InlineTextBoxWrapper
    if inlineTextBox.canUseSimplifiedContentMeasuring() {
      // Simplified text measuring works with primary font only.
      return []
    }
    let text = run.textContent!
    let fallbackFonts = TextUtil.fallbackFontsForText(
      textContent: StringWrapperView(s: inlineTextBox.content).substring(
        start: UInt32(text.start),
        length: UInt32(text.length)),
      style: style,
      includeHyphen: text.needsHyphen ? .Yes : .No)
    // FIXME(asuhan): isEmptyIgnoringNullReferences
    if fallbackFonts.isEmpty {
      return []
    }

    var fallbackFontsForInlineBox = fallbackFontsForInlineBoxes[
      ObjectIdentifier(parentInlineBox), default: TextUtil.FallbackFontList()]
    // FIXME(asuhan): computeSize
    let numberOfFallbackFontsForInlineBox = fallbackFontsForInlineBox.count
    for fontPtr in fallbackFonts {
      let font = FontWrapper(p: UnsafeRawPointer(bitPattern: fontPtr)!)
      fallbackFontsForInlineBox.update(with: fontPtr)
      fallbackFontRequiresIdeographicBaseline =
        fallbackFontRequiresIdeographicBaseline || font.hasVerticalGlyphs()
    }
    if fallbackFontsForInlineBox.count != numberOfFallbackFontsForInlineBox {
      fallbackFontsForInlineBoxes.updateValue(
        fallbackFontsForInlineBox, forKey: ObjectIdentifier(parentInlineBox))
    }
    return fallbackFonts
  }

  private func adjustMarginStartForListMarker(
    listMarkerBox: ElementBoxWrapper, nestedListMarkerMarginStart: LayoutUnit,
    rootInlineBoxOffset: InlineLayoutUnit
  ) {
    if !nestedListMarkerMarginStart.bool() && rootInlineBoxOffset == 0 {
      return
    }
    let listMarkerGeometry = formattingContext().geometryForBox(layoutBox: listMarkerBox)
    // Make sure that the line content does not get pulled in to logical left direction due to
    // the large negative margin (i.e. this ensures that logical left of the list content stays at the line start)
    listMarkerGeometry.setHorizontalMargin(
      margin: BoxGeometry.HorizontalEdges(
        start: listMarkerGeometry.marginStart() + nestedListMarkerMarginStart
          - LayoutUnit(value: rootInlineBoxOffset),
        end: listMarkerGeometry.marginEnd() - nestedListMarkerMarginStart
          + LayoutUnit(value: rootInlineBoxOffset)))
  }

  private mutating func applyTextBoxTrimIfNeeded(
    lineBoxLogicalHeightIn: InlineLayoutUnit, rootInlineBox: InlineLevelBox
  ) -> InlineLayoutUnit {
    var lineBoxLogicalHeight = lineBoxLogicalHeightIn
    let textBoxTrim = blockLayoutState().textBoxTrim
    let textBoxEdge = effectiveTextBoxEdge(
      rootInlineBox: rootInlineBox, blockLayoutState: blockLayoutState())
    let shouldTrimBlockStartOfLineBox =
      isFirstLine() && textBoxTrim.contains(.Start)
      && textBoxEdge.over != .Auto
    let shouldTrimBlockEndOfLineBox =
      isLastLine() && textBoxTrim.contains(.End) && textBoxEdge.under != .Auto
    if !shouldTrimBlockStartOfLineBox && !shouldTrimBlockEndOfLineBox {
      return lineBoxLogicalHeight
    }

    let primaryFontMetrics = rootInlineBox.primarymetricsOfPrimaryFont()
    if shouldTrimBlockEndOfLineBox {
      let textBoxEdgeUnderForRootInlineBox = textBoxEdgeUnderForRootInlineBox(
        primaryFontMetrics: primaryFontMetrics, textBoxEdge: textBoxEdge)
      let needToTrimThisMuch = max(
        0, (lineBoxLogicalHeight - rootInlineBox.logicalBottom()) + textBoxEdgeUnderForRootInlineBox
      )
      lineBoxLogicalHeight -= needToTrimThisMuch
    }
    if shouldTrimBlockStartOfLineBox {
      let needToTrimThisMuch = max(
        0,
        lineLayoutResult.lineGeometry.initialLetterClearGap ?? 0 + rootInlineBox.logicalTop()
          + textBoxEdgeOverForRootInlineBox(
            primaryFontMetrics: primaryFontMetrics, textBoxEdge: textBoxEdge))
      lineBoxLogicalHeight -= needToTrimThisMuch

      rootInlineBox.setLogicalTop(logicalTop: rootInlineBox.logicalTop() - needToTrimThisMuch)
      lineLayoutResult.firstLineStartTrim = needToTrimThisMuch
    }
    return lineBoxLogicalHeight
  }

  private func textBoxEdgeUnderForRootInlineBox(
    primaryFontMetrics: FontMetricsWrapper, textBoxEdge: TextEdge
  ) -> InlineLayoutUnit {
    switch textBoxEdge.under {
    case .Text:
      return 0
    case .Alphabetic:
      return InlineLayoutUnit(primaryFontMetrics.intDescent())
    case .CJKIdeographic, .CJKIdeographicInk:
      fatalError("Not implemented yet")
    case .Auto:
      fallthrough
    default:
      fatalError("Not reached")
    }
  }

  private func textBoxEdgeOverForRootInlineBox(
    primaryFontMetrics: FontMetricsWrapper, textBoxEdge: TextEdge
  ) -> InlineLayoutUnit {
    switch textBoxEdge.over {
    case .Text:
      return 0
    case .CapHeight:
      return InlineLayoutUnit(primaryFontMetrics.intAscent() - primaryFontMetrics.intCapHeight())
    case .ExHeight:
      return Float32(primaryFontMetrics.intAscent()) - roundf(primaryFontMetrics.xHeight() ?? 0)
    case .CJKIdeographic, .CJKIdeographicInk:
      fatalError("Not implemented yet")
    case .Auto:
      fallthrough
    default:
      fatalError("Not reached")
    }
  }

  private mutating func constructInlineLevelBoxes(lineBox: inout LineBox) {
    let formattingContext = formattingContext()
    let rootInlineBox = lineBox.rootInlineBox
    setVerticalPropertiesForInlineLevelBox(lineBox: lineBox, inlineLevelBox: rootInlineBox)

    var lineHasContent = false
    let inlineContent = lineLayoutResult.inlineContent
    for (index, run) in inlineContent.enumerated() {
      let layoutBox = run.layoutBox
      let style = isFirstLine() ? layoutBox.firstLineStyle() : layoutBox.style
      lineHasContent =
        lineHasContent
        || Line.Run.isContentfulOrHasDecoration(run: run, formattingContext: formattingContext)
      var logicalLeft = rootInlineBox.logicalLeft() + run.logicalLeft

      if run.isText() {
        let parentInlineBox = lineBox.parentInlineBox(lineRun: run)
        parentInlineBox.setHasContent()
        let fallbackFonts = collectFallbackFonts(
          parentInlineBox: parentInlineBox, run: run, style: style)
        // FIXME(asuhan): isEmptyIgnoringNullReferences
        if !fallbackFonts.isEmpty {
          // Adjust non-empty inline box height when glyphs from the non-primary font stretch the box.
          if parentInlineBox.isPreferredLineHeightFontMetricsBased() {
            let enclosingAscentAndDescent = enclosingAscentDescentWithFallbackFonts(
              inlineBox: parentInlineBox, fallbackFontsForContent: fallbackFonts,
              fontBaseline: .AlphabeticBaseline)
            let layoutBounds = parentInlineBox.layoutBounds
            parentInlineBox.setLayoutBounds(
              layoutBounds:
                InlineLevelBox.AscentAndDescent(
                  ascent: max(layoutBounds.ascent, enclosingAscentAndDescent.ascent),
                  descent: max(layoutBounds.descent, enclosingAscentAndDescent.descent)))
          }
        }
        continue
      }
      if run.isSoftLineBreak() {
        lineBox.parentInlineBox(lineRun: run).setHasContent()
        continue
      }
      if run.isHardLineBreak() {
        let lineBreakBox = InlineLevelBox.createLineBreakBox(
          layoutBox: layoutBox, style: style, logicalLeft: logicalLeft)
        setVerticalPropertiesForInlineLevelBox(lineBox: lineBox, inlineLevelBox: lineBreakBox)
        lineBox.addInlineLevelBox(inlineLevelBox: lineBreakBox)

        if layoutState().inStandardsMode
          || InlineQuirks.lineBreakBoxAffectsParentInlineBox(lineBox: lineBox)
        {
          lineBox.parentInlineBox(lineRun: run).setHasContent()
        }
        continue
      }
      if run.isAtomicInlineBox() {
        let inlineLevelBoxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
        logicalLeft += max(0, inlineLevelBoxGeometry.marginStart().float())
        let atomicInlineBox = InlineLevelBox.createAtomicInlineBox(
          layoutBox: layoutBox, style: style, logicalLeft: logicalLeft,
          logicalWidth: inlineLevelBoxGeometry.borderBoxWidth().float())
        setVerticalPropertiesForInlineLevelBox(lineBox: lineBox, inlineLevelBox: atomicInlineBox)
        lineBox.addInlineLevelBox(inlineLevelBox: atomicInlineBox)
        continue
      }
      if run.isInlineBoxStart() || run.isLineSpanningInlineBoxStart() {
        let marginStart =
          run.isInlineBoxStart() || style.boxDecorationBreak() == .Clone
          ? formattingContext.geometryForBox(layoutBox: layoutBox).marginStart() : LayoutUnit()
        // At this point we don't know yet how wide this inline box is. Let's assume it's as long as the line is
        // and adjust it later if we come across an inlineBoxEnd run (see below).
        // Inline box run is based on margin box. Let's convert it to border box.
        logicalLeft += max(0, marginStart.float())
        var initialLogicalWidth = rootInlineBox.logicalRight() - logicalLeft
        // We (editing, DOM etc) can't yet handle RTL hanging content (see contentLogicalWidth in LineBoxBuilder::build).
        if lineLayoutResult.directionality.inlineBaseDirection == .LTR {
          initialLogicalWidth += lineLayoutResult.hangingContent.logicalWidth
        }
        initialLogicalWidth = max(initialLogicalWidth, 0)
        let inlineBox = InlineLevelBox.createInlineBox(
          layoutBox: layoutBox, style: style, logicalLeft: logicalLeft,
          logicalWidth: initialLogicalWidth, isLineSpanning: run.isInlineBoxStart() ? .No : .Yes)
        inlineBox.setTextEmphasis(
          textEmphasis: InlineFormattingUtils.textEmphasisForInlineBox(
            layoutBox: layoutBox, rootBox: rootBox()))
        setVerticalPropertiesForInlineLevelBox(lineBox: lineBox, inlineLevelBox: inlineBox)
        if run.isInlineBoxStart() {
          inlineBox.setIsFirstBox()
          lineHasNonLineSpanningRubyContent =
            lineHasNonLineSpanningRubyContent || layoutBox.isRubyBase()
        }
        lineBox.addInlineLevelBox(inlineLevelBox: inlineBox)
        continue
      }
      if run.isInlineBoxEnd() {
        // Adjust the logical width when the inline box closes on this line.
        // Note that margin end does not affect the logical width (e.g. positive margin right does not make the run wider).
        let inlineBox = lineBox.inlineLevelBoxFor(lineRun: run)
        assert(inlineBox.isInlineBox())
        // Inline box run is based on margin box. Let's convert it to border box.
        // Negative margin end makes the run have negative width.
        let marginEndAdjustemnt = -formattingContext.geometryForBox(layoutBox: layoutBox)
          .marginEnd()
        let logicalWidth = run.logicalWidth + marginEndAdjustemnt.float()
        let inlineBoxLogicalRight = logicalLeft + logicalWidth
        // When the content pulls the </span> to the logical left direction (e.g. negative letter space)
        // make sure we don't end up with negative logical width on the inline box.
        inlineBox.setLogicalWidth(
          logicalWidth: max(0, inlineBoxLogicalRight - inlineBox.logicalLeft()))
        inlineBox.setIsLastBox()
        continue
      }
      if run.isListMarker() {
        let listMarkerBox = layoutBox as! ElementBoxWrapper
        if !listMarkerBox.isListMarkerImage() {
          // Non-image type of list markers make their parent inline boxes (e.g. root inline box) contentful (and stretch them vertically).
          lineBox.parentInlineBox(lineRun: run).setHasContent()
        }

        if run.isListMarkerOutside() {
          outsideListMarkers.append(UInt64(index))
        }

        let atomicInlineBox = InlineLevelBox.createAtomicInlineBox(
          layoutBox: listMarkerBox, style: style, logicalLeft: logicalLeft,
          logicalWidth: formattingContext.geometryForBox(layoutBox: listMarkerBox).borderBoxWidth()
            .float())
        setVerticalPropertiesForInlineLevelBox(lineBox: lineBox, inlineLevelBox: atomicInlineBox)
        lineBox.addInlineLevelBox(inlineLevelBox: atomicInlineBox)
        continue
      }
      if run.isWordBreakOpportunity() {
        lineBox.addInlineLevelBox(
          inlineLevelBox:
            InlineLevelBox.createGenericInlineLevelBox(
              layoutBox: layoutBox, style: style, logicalLeft: logicalLeft))
        continue
      }
      assert(run.isOpaque())
    }
    lineBox.setHasContent(hasContent: lineHasContent)
  }

  private func adjustIdeographicBaselineIfApplicable(lineBox: inout LineBox) {
    // Re-compute the ascent/descent values for the inline boxes on the line (including the root inline box)
    // when the style/content needs ideographic baseline setup in vertical writing mode.
    let rootInlineBox = lineBox.rootInlineBox

    if !lineNeedsIdeographicBaseline(rootInlineBox: rootInlineBox, lineBox: lineBox) {
      return
    }

    lineBox.setBaselineType(baselineType: .IdeographicBaseline)

    adjustLayoutBoundsWithIdeographicBaseline(inlineLevelBox: rootInlineBox, lineBox: lineBox)
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      if inlineLevelBox.isAtomicInlineBox() {
        let layoutBox = inlineLevelBox.layoutBox
        if layoutBox.isInlineTableBox() {
          // This is the integration codepath where inline table boxes are represented as atomic inline boxes.
          // Integration codepath sets ideographic baseline by default for non-horizontal content.
          continue
        }
        let isInlineBlockWithNonSyntheticBaseline =
          layoutBox.isInlineBlockBox()
          && (layoutBox as! ElementBoxWrapper).baselineForIntegration() != nil
        if isInlineBlockWithNonSyntheticBaseline && !layoutBox.style.isHorizontalWritingMode() {
          continue
        }
      }
      adjustLayoutBoundsWithIdeographicBaseline(inlineLevelBox: inlineLevelBox, lineBox: lineBox)
    }
  }

  private func lineNeedsIdeographicBaseline(rootInlineBox: InlineLevelBox, lineBox: LineBox) -> Bool
  {
    let rootInlineBoxStyle = styleToUseForInlineLevelBox(inlineLevelBox: rootInlineBox)
    if rootInlineBoxStyle.isHorizontalWritingMode() {
      return false
    }

    if fallbackFontRequiresIdeographicBaseline
      || primaryFontRequiresIdeographicBaseline(style: rootInlineBoxStyle)
    {
      return true
    }
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      if inlineLevelBox.isInlineBox()
        && primaryFontRequiresIdeographicBaseline(
          style: styleToUseForInlineLevelBox(inlineLevelBox: inlineLevelBox))
      {
        return true
      }
    }
    return false
  }

  private func styleToUseForInlineLevelBox(inlineLevelBox: InlineLevelBox) -> RenderStyleWrapper {
    return isFirstLine()
      ? inlineLevelBox.layoutBox.firstLineStyle() : inlineLevelBox.layoutBox.style
  }

  private func primaryFontRequiresIdeographicBaseline(style: RenderStyleWrapper) -> Bool {
    return style.fontDescription().orientation() == .Vertical
      || style.fontCascade().primaryFont().hasVerticalGlyphs()
  }

  private func adjustLayoutBoundsWithIdeographicBaseline(
    inlineLevelBox: InlineLevelBox, lineBox: LineBox
  ) {
    let initiatesLayoutBoundsChange =
      inlineLevelBox.isInlineBox() || inlineLevelBox.isAtomicInlineBox()
      || inlineLevelBox.isLineBreakBox()
    if !initiatesLayoutBoundsChange {
      return
    }

    if inlineLevelBox.isInlineBox() || inlineLevelBox.isLineBreakBox()
      || (inlineLevelBox.isListMarker()
        && !(inlineLevelBox.layoutBox as! ElementBoxWrapper).isListMarkerImage())
    {
      setVerticalPropertiesForInlineLevelBox(lineBox: lineBox, inlineLevelBox: inlineLevelBox)
    } else if inlineLevelBox.isAtomicInlineBox() {
      let inlineLevelBoxHeight = inlineLevelBox.logicalHeight()
      let ideographicBaseline = InlineLayoutUnit(roundToInt(value: inlineLevelBoxHeight / 2))
      // Move the baseline position but keep the same logical height.
      inlineLevelBox.setAscentAndDescent(
        ascentAndDescent:
          InlineLevelBox.AscentAndDescent(
            ascent: ideographicBaseline, descent: inlineLevelBoxHeight - ideographicBaseline))
      inlineLevelBox.setLayoutBounds(
        layoutBounds:
          InlineLevelBox.AscentAndDescent(
            ascent: ideographicBaseline, descent: inlineLevelBoxHeight - ideographicBaseline))
    }

    let needsFontFallbackAdjustment = inlineLevelBox.isInlineBox()
    if needsFontFallbackAdjustment {
      if let fallbackFonts = fallbackFontsForInlineBoxes[ObjectIdentifier(inlineLevelBox)] {
        // FIXME(asuhan): isEmptyIgnoringNullReferences
        if !fallbackFonts.isEmpty && inlineLevelBox.isPreferredLineHeightFontMetricsBased() {
          let enclosingAscentAndDescent = enclosingAscentDescentWithFallbackFonts(
            inlineBox: inlineLevelBox, fallbackFontsForContent: fallbackFonts,
            fontBaseline: .IdeographicBaseline)
          let layoutBounds = inlineLevelBox.layoutBounds
          inlineLevelBox.setLayoutBounds(
            layoutBounds:
              InlineLevelBox.AscentAndDescent(
                ascent: max(layoutBounds.ascent, enclosingAscentAndDescent.ascent),
                descent: max(layoutBounds.descent, enclosingAscentAndDescent.descent)
              )
          )
        }
      }
    }
  }

  private func adjustOutsideListMarkersPosition(lineBox: LineBox) {
    let lineBoxRect = lineBox.logicalRect
    let floatConstraints = formattingContext().floatingContext!.constraints(
      candidateTop: LayoutUnit(value: lineBoxRect.top()),
      candidateBottom: LayoutUnit(value: lineBoxRect.bottom()),
      mayBeAboveLastFloat: FloatingContext.MayBeAboveLastFloat.No)

    let lineBoxOffset =
      lineBoxRect.left()
      - lineLayoutResult.lineGeometry.initialLogicalLeftIncludingIntrusiveFloats
    let rootInlineBoxLogicalLeft = lineBox.logicalRectForRootInlineBox().left()
    let rootInlineBoxOffsetFromContentBoxOrIntrusiveFloat = lineBoxOffset + rootInlineBoxLogicalLeft
    for listMarkerBoxIndex in outsideListMarkers {
      let listMarkerRun = lineLayoutResult.inlineContent[Int(listMarkerBoxIndex)]
      assert(listMarkerRun.isListMarkerOutside())
      let listMarkerBox = listMarkerRun.layoutBox as! ElementBoxWrapper
      let listMarkerInlineLevelBox = lineBox.inlineLevelBoxFor(lineRun: listMarkerRun)
      // Move it to the logical left of the line box (from the logical left of the root inline box).
      let listMarkerInitialOffsetFromRootInlineBox =
        listMarkerInlineLevelBox.logicalLeft() - rootInlineBoxOffsetFromContentBoxOrIntrusiveFloat
      var logicalLeft = listMarkerInitialOffsetFromRootInlineBox
      let nestedListMarkerMarginStart = nestedListMarkerMarginStart(
        listMarkerBox: listMarkerBox, floatConstraints: floatConstraints)
      adjustMarginStartForListMarker(
        listMarkerBox: listMarkerBox, nestedListMarkerMarginStart: nestedListMarkerMarginStart,
        rootInlineBoxOffset: rootInlineBoxOffsetFromContentBoxOrIntrusiveFloat)
      logicalLeft += nestedListMarkerMarginStart.float()
      listMarkerInlineLevelBox.setLogicalLeft(logicalLeft: logicalLeft)
    }
  }

  private func nestedListMarkerMarginStart(
    listMarkerBox: ElementBoxWrapper, floatConstraints: FloatingContext.Constraints
  ) -> LayoutUnit {
    let nestedOffset = layoutState().nestedListMarkerOffset(listMarkerBox: listMarkerBox)
    if nestedOffset == LayoutUnit.min() {
      return LayoutUnit(value: 0)
    }
    // Nested list markers (in standards mode) share the same line and have offsets as if they had dedicated lines.
    // <!DOCTYPE html>
    // <ul><li><ul><li>markers on the same line in standards mode
    // vs.
    // <ul><li><ul><li>markers with dedicated lines in quirks mode
    // or
    // <!DOCTYPE html>
    // <ul><li>markers<ul><li>with dedicated lines
    // While a float may not constrain the line, it could constrain the nested list marker (being it outside of the line box to the logical left).
    // FIXME: We may need to do this in a post-process task after the line box geometry is computed.
    return floatConstraints.left != nil
      ? min(LayoutUnit(value: 0), max(floatConstraints.left!.x, nestedOffset)) : nestedOffset
  }

  private func expandAboveRootInlineBox(lineBox: LineBox, expansion: InlineLayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isFirstLine() -> Bool {
    return lineLayoutResult.isFirstLast.isFirstFormattedLine != .No
  }

  private func isLastLine() -> Bool {
    return lineLayoutResult.isFirstLast.isLastLineWithInlineContent
  }

  private func formattingContext() -> InlineFormattingContext {
    return inlineFormattingContext
  }

  private func rootBox() -> ElementBoxWrapper {
    return formattingContext().root()
  }

  private func layoutState() -> InlineLayoutState {
    return formattingContext().layoutState()
  }

  private func blockLayoutState() -> BlockLayoutState {
    return layoutState().parentBlockLayoutState
  }

  var inlineFormattingContext: InlineFormattingContext
  var lineLayoutResult = LineLayoutResult()
  var fallbackFontRequiresIdeographicBaseline = false
  var lineHasNonLineSpanningRubyContent = false
  var fallbackFontsForInlineBoxes: [ObjectIdentifier: TextUtil.FallbackFontList] = [:]
  var outsideListMarkers: [UInt64] = []
}
