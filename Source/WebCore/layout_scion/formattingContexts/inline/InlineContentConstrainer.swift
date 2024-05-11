/*
 * Copyright (C) 2021-2023 Apple Inc. All rights reserved.
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

// Ideally, the act of balancing inline content will use the same number of lines as if the inline content
// was laid out via `text-wrap: wrap`. However, adhering to this ideal is expensive (quadratic in the number
// of break opportunities), and not caring about this ideal will allow us to use a more efficient algorithm.
// Typically, if inline content spans many lines, the likelihood of someone caring about the vertical space
// used decreases. So, we ignore this ideal number of lines requirement beyond this threshold.
internal var maximumLinesToBalanceWithLineRequirement = UInt64(12)

internal func computeCost(candidateLineWidth: InlineLayoutUnit, idealLineWidth: InlineLayoutUnit)
  -> Float32
{
  let difference = idealLineWidth - candidateLineWidth
  return difference * difference
}

struct InlineContentConstrainer {
  init(
    inlineFormattingContext: InlineFormattingContext, inlineItemList: InlineItemList,
    horizontalConstraints: HorizontalConstraints
  ) {
    // TODO(asuhan): implement this
    self.inlineItemList = inlineItemList
    fatalError("Not implemented")
  }

  func computeParagraphLevelConstraints(wrapStyle: TextWrapStyle) -> [LayoutUnit]? {
    assert(wrapStyle == .Balance || wrapStyle == .Pretty)

    if cannotConstrainContent || hasSingleLineVisibleContent {
      return nil
    }

    // If forced line breaks exist, then we can constrain each forced-break-delimited
    // chunk of text separately. This helps simplify first line/indentation logic.
    var chunkSizes: [UInt64] = []  // Number of lines per chunk of text
    var currentChunkSize = UInt64(0)
    for i in 0..<originalLineInlineItemRanges.count {
      currentChunkSize += 1
      if originalLineEndsWithForcedBreak[i] {
        chunkSizes.append(currentChunkSize)
        currentChunkSize = 0
      }
    }
    if currentChunkSize > 0 {
      chunkSizes.append(currentChunkSize)
    }

    var chunkStart = UInt64(0)
    var constrainedLineWidths: [LayoutUnit] = []
    for chunkSize in chunkSizes {
      if let constrainedLineWidthsForChunk = constrainChunk(
        chunkStart: chunkStart, chunkSize: chunkSize, wrapStyle: wrapStyle)
      {
        for constrainedLineWidth in constrainedLineWidthsForChunk {
          constrainedLineWidths.append(constrainedLineWidth)
        }
      } else {
        for _ in 0..<chunkSize {
          constrainedLineWidths.append(LayoutUnit(value: maximumLineWidth))
        }
      }
      chunkStart += chunkSize
    }

    return constrainedLineWidths
  }

  // Constrain each chunk
  func constrainChunk(chunkStart: UInt64, chunkSize: UInt64, wrapStyle: TextWrapStyle)
    -> [LayoutUnit]?
  {
    let isFirstChunk = (chunkStart == 0)
    let rangeToConstrain = InlineItemRange(
      start: InlineItemPosition(index: originalLineInlineItemRanges[Int(chunkStart)].startIndex()),
      end: InlineItemPosition(
        index: originalLineInlineItemRanges[Int(chunkStart + chunkSize - 1)].endIndex())
    )
    if rangeToConstrain.startIndex() >= rangeToConstrain.endIndex() {
      return nil
    }
    var totalWidth = InlineLayoutUnit()
    for line in 0..<chunkSize {
      totalWidth += originalLineWidths[Int(chunkStart + line)]
    }

    if wrapStyle == .Balance {
      let idealLineWidth = totalWidth / InlineLayoutUnit(chunkSize)
      if numberOfLinesInOriginalLayout <= maximumLinesToBalanceWithLineRequirement {
        return balanceRangeWithLineRequirement(
          range: rangeToConstrain, idealLineWidth: idealLineWidth, numberOfLines: chunkSize,
          isFirstChunk: isFirstChunk)
      }
      return balanceRangeWithNoLineRequirement(
        range: rangeToConstrain, idealLineWidth: idealLineWidth, isFirstChunk: isFirstChunk)
    }

    if wrapStyle == .Pretty {
      // Targetting a line length slightly shorter than the maximum allows the algorithm to both
      // overshoot and undershoot the target line length, giving more flexibility in the solution search
      let idealLineWidth = InlineLayoutUnit(maximumLineWidth * 0.95)
      return prettifyRange(
        range: rangeToConstrain, idealLineWidth: idealLineWidth, isFirstChunk: isFirstChunk)
    }

    fatalError("Not reached")
  }

  func balanceRangeWithLineRequirement(
    range: InlineItemRange, idealLineWidth: InlineLayoutUnit, numberOfLines: UInt64,
    isFirstChunk: Bool
  ) -> [LayoutUnit]? {
    assert(range.startIndex() < range.endIndex())

    // breakOpportunities holds the indices i such that a line break can occur before m_inlineItemList[i].
    var breakOpportunities = computeBreakOpportunities(range: range)

    // We need a dummy break opportunity at the beginning for algorithmic base case purposes
    breakOpportunities.insert(range.startIndex(), at: 0)
    let numberOfBreakOpportunities = breakOpportunities.count

    // Indentation offsets
    let previousLineEndsWithLineBreak = isFirstChunk ? nil : true
    let firstLineTextIndent = computeTextIndent(
      previousLineEndsWithLineBreak: previousLineEndsWithLineBreak)
    let textIndent = computeTextIndent(previousLineEndsWithLineBreak: false)

    struct Entry {
      var accumulatedCost = Float32.infinity
      var previousBreakIndex: UInt64 = 0
    }

    // state[i][j] holds the optimal set of line breaks where the jth line break (1-indexed) is
    // right before m_inlineItemList[breakOpportunities[i]]. "Optimal" in this context means the
    // lowest possible accumulated cost.
    var state = [[Entry]](
      repeating: [Entry](repeating: Entry(), count: Int(numberOfLines + 1)),
      count: numberOfBreakOpportunities)
    state[0][0].accumulatedCost = 0

    // Special case the first line because of ::first-line styling, indentation, etc.
    var firstLineSlidingWidth = SlidingWidth(
      inlineContentConstrainer: self, inlineItemList: inlineItemList, start: range.startIndex(),
      end: range.startIndex(), useFirstLineStyle: isFirstChunk, isFirstLineInChunk: true)
    for breakIndex in 1..<numberOfBreakOpportunities {
      let end = breakOpportunities[breakIndex]
      firstLineSlidingWidth.advanceEndTo(newEnd: end)

      let firstLineCandidateWidth = firstLineSlidingWidth.width() + firstLineTextIndent
      if Float64(firstLineCandidateWidth) > maximumLineWidth {
        break
      }

      let cost = computeCost(
        candidateLineWidth: firstLineCandidateWidth, idealLineWidth: idealLineWidth)
      state[breakIndex][1].accumulatedCost = cost
    }

    // breakOpportunities[firstStartIndex] is the first possible starting position for a candidate line that is NOT the first line
    var firstStartIndex = UInt64(1)
    var slidingWidth = SlidingWidth(
      inlineContentConstrainer: self, inlineItemList: inlineItemList,
      start: breakOpportunities[Int(firstStartIndex)],
      end: breakOpportunities[Int(firstStartIndex)], useFirstLineStyle: false,
      isFirstLineInChunk: false)
    for breakIndex in 1..<numberOfBreakOpportunities {
      let end = breakOpportunities[breakIndex]
      slidingWidth.advanceEndTo(newEnd: end)

      // We prune our search space by limiting the possible starting positions for our candidate line.
      while Float64(textIndent + slidingWidth.width()) > maximumLineWidth {
        firstStartIndex += 1
        if firstStartIndex > breakIndex {
          break
        }
        slidingWidth.advanceStartTo(newStart: breakOpportunities[Int(firstStartIndex)])
      }

      // Evaluate all possible lines that break before m_inlineItemList[end]
      var innerSlidingWidth = slidingWidth
      for startIndex in Int(firstStartIndex)..<breakIndex {
        let start = breakOpportunities[startIndex]
        assert(start != range.startIndex())
        innerSlidingWidth.advanceStartTo(newStart: start)
        let candidateLineWidth = textIndent + innerSlidingWidth.width()
        let candidateLineCost = computeCost(
          candidateLineWidth: candidateLineWidth, idealLineWidth: idealLineWidth)
        assert(Float64(candidateLineWidth) <= maximumLineWidth)

        // Compute the cost of this line based on the line index
        for lineIndex in 1...numberOfLines {
          let accumulatedCost =
            candidateLineCost + state[startIndex][Int(lineIndex - 1)].accumulatedCost
          let currentAccumulatedCost = state[breakIndex][Int(lineIndex)].accumulatedCost
          if accumulatedCost < currentAccumulatedCost
            || WTF.areEssentiallyEqual(u: accumulatedCost, v: currentAccumulatedCost)
          {
            state[breakIndex][Int(lineIndex)].accumulatedCost = accumulatedCost
            state[breakIndex][Int(lineIndex)].previousBreakIndex = UInt64(startIndex)
          }
        }
      }
    }

    // Check if we found no solution
    if state[numberOfBreakOpportunities - 1][Int(numberOfLines)].accumulatedCost.isInfinite {
      return nil
    }

    // breaks[i] equals the index into m_inlineItemList before which the ith line will break
    var breaks = [UInt64](repeating: 0, count: Int(numberOfLines))
    var breakIndex = UInt64(numberOfBreakOpportunities - 1)
    for line in (1...numberOfLines).reversed() {
      breaks[Int(line - 1)] = breakOpportunities[Int(breakIndex)]
      breakIndex = state[Int(breakIndex)][Int(line)].previousBreakIndex
    }

    return computeLineWidthsFromBreaks(
      inlineItems: range, breaks: breaks, isFirstChunk: isFirstChunk)
  }

  func balanceRangeWithNoLineRequirement(
    range: InlineItemRange, idealLineWidth: InlineLayoutUnit, isFirstChunk: Bool
  ) -> [LayoutUnit]? {
    assert(range.startIndex() < range.endIndex())

    // breakOpportunities holds the indices i such that a line break can occur before m_inlineItemList[i].
    var breakOpportunities = computeBreakOpportunities(range: range)

    // We need a dummy break opportunity at the beginning for algorithmic base case purposes
    breakOpportunities.insert(range.startIndex(), at: 0)
    let numberOfBreakOpportunities = breakOpportunities.count

    // Indentation offsets
    let previousLineEndsWithLineBreak = isFirstChunk ? nil : true
    let firstLineTextIndent = computeTextIndent(
      previousLineEndsWithLineBreak: previousLineEndsWithLineBreak)
    let textIndent = computeTextIndent(previousLineEndsWithLineBreak: false)

    struct Entry {
      var accumulatedCost = Float32.infinity
      var previousBreakIndex: UInt64 = 0
    }

    // state[i] holds the optimal set of line breaks where the last line break is right
    // before m_inlineItemList[breakOpportunities[i]]. "Optimal" in this context means the
    // lowest possible accumulated cost.
    var state = [Entry](repeating: Entry(), count: numberOfBreakOpportunities)
    state[0].accumulatedCost = 0

    // Special case the first line because of ::first-line styling, indentation, etc.
    var firstLineSlidingWidth = SlidingWidth(
      inlineContentConstrainer: self, inlineItemList: inlineItemList, start: range.startIndex(),
      end: range.startIndex(), useFirstLineStyle: isFirstChunk, isFirstLineInChunk: true)
    for breakIndex in 1..<numberOfBreakOpportunities {
      let end = breakOpportunities[breakIndex]
      firstLineSlidingWidth.advanceEndTo(newEnd: end)

      let firstLineCandidateWidth = firstLineSlidingWidth.width() + firstLineTextIndent
      if Float64(firstLineCandidateWidth) > maximumLineWidth {
        break
      }

      let cost = computeCost(
        candidateLineWidth: firstLineCandidateWidth, idealLineWidth: idealLineWidth)
      state[breakIndex].accumulatedCost = cost
    }

    // breakOpportunities[firstStartIndex] is the first possible starting position for a candidate line that is NOT the first line
    var firstStartIndex = UInt64(1)
    var slidingWidth = SlidingWidth(
      inlineContentConstrainer: self, inlineItemList: inlineItemList,
      start: breakOpportunities[Int(firstStartIndex)],
      end: breakOpportunities[Int(firstStartIndex)], useFirstLineStyle: false,
      isFirstLineInChunk: false)
    for breakIndex in 1..<numberOfBreakOpportunities {
      let end = breakOpportunities[breakIndex]
      slidingWidth.advanceEndTo(newEnd: end)

      // We prune our search space by limiting the possible starting positions for our candidate line.
      while Float64(textIndent + slidingWidth.width()) > maximumLineWidth {
        firstStartIndex += 1
        if firstStartIndex > breakIndex {
          break
        }
        slidingWidth.advanceStartTo(newStart: breakOpportunities[Int(firstStartIndex)])
      }

      // Evaluate all possible lines that break before m_inlineItemList[end]
      var innerSlidingWidth = slidingWidth
      for startIndex in Int(firstStartIndex)..<breakIndex {
        let start = breakOpportunities[startIndex]
        assert(start != range.startIndex())
        innerSlidingWidth.advanceStartTo(newStart: start)
        let candidateLineWidth = textIndent + innerSlidingWidth.width()
        let candidateLineCost = computeCost(
          candidateLineWidth: candidateLineWidth, idealLineWidth: idealLineWidth)
        assert(Float64(candidateLineWidth) <= maximumLineWidth)

        let accumulatedCost = candidateLineCost + state[startIndex].accumulatedCost
        if accumulatedCost < state[breakIndex].accumulatedCost {
          state[breakIndex].accumulatedCost = accumulatedCost
          state[breakIndex].previousBreakIndex = UInt64(startIndex)
        }
      }
    }

    // Check if we found no solution
    if state[numberOfBreakOpportunities - 1].accumulatedCost.isInfinite {
      return nil
    }

    // breaks[i] equals the index into m_inlineItemList before which the ith line will break
    var breaks: [UInt64] = []
    var breakIndex = UInt64(numberOfBreakOpportunities - 1)
    repeat {
      breaks.append(breakOpportunities[Int(breakIndex)])
      breakIndex = state[Int(breakIndex)].previousBreakIndex
    } while breakIndex != 0
    breaks.reverse()

    return computeLineWidthsFromBreaks(
      inlineItems: range, breaks: breaks, isFirstChunk: isFirstChunk)
  }

  struct PrettifyRangeEntry: Comparable {
    var accumulatedCost = Float32.infinity
    var previousBreakIndex: UInt64 = 0
    var lastLineWidth = InlineLayoutUnit()
    var endsWithHyphen = false

    static func < (lhs: Self, rhs: Self) -> Bool {
      return (
        accumulatedCost: lhs.accumulatedCost, previousBreakIndex: lhs.previousBreakIndex,
        lastLineWidth: lhs.lastLineWidth, endsWithHyphen: lhs.endsWithHyphen ? 1 : 0
      )
        < (
          accumulatedCost: rhs.accumulatedCost, previousBreakIndex: rhs.previousBreakIndex,
          lastLineWidth: rhs.lastLineWidth, endsWithHyphen: rhs.endsWithHyphen ? 1 : 0
        )
    }
  }

  func prettifyRange(range: InlineItemRange, idealLineWidth: InlineLayoutUnit, isFirstChunk: Bool)
    -> [LayoutUnit]?
  {
    assert(range.startIndex() < range.endIndex())

    // breakOpportunities holds the indices i such that a line break can occur before m_inlineItemList[i].
    var breakOpportunities = computeBreakOpportunities(range: range)

    // We need a dummy break opportunity at the beginning for algorithmic base case purposes
    breakOpportunities.insert(range.startIndex(), at: 0)
    let numberOfBreakOpportunities = breakOpportunities.count

    // Indentation offsets
    let previousLineEndsWithLineBreak = isFirstChunk ? nil : true
    let firstLineTextIndent = inlineFormattingContext.formattingUtils().computedTextIndent(
      isIntrinsicWidthMode: .No, previousLineEndsWithLineBreak: previousLineEndsWithLineBreak,
      availableWidth: Float32(maximumLineWidth))
    let textIndent = inlineFormattingContext.formattingUtils().computedTextIndent(
      isIntrinsicWidthMode: .No, previousLineEndsWithLineBreak: false,
      availableWidth: Float32(maximumLineWidth))

    // state[i] holds the optimal set of line breaks where the last line break is right
    // before m_inlineItemList[breakOpportunities[i]]. "Optimal" in this context means the
    // lowest possible accumulated cost.
    //
    // We keep track of the `numberOfBestSolutions` best solutions for each breakpoint,
    // so that if one solution leads to an invalid breaking (e.g. due to an orphan),
    // we can backtrack and find a valid breaking.
    //
    // The `numberOfBestSolutions` constant represents a tradeoff: a higher number gives
    // higher quality breakings at the cost of speed.
    let state = [WTF.PriorityQueue<PrettifyRangeEntry>](
      repeating: WTF.PriorityQueue<PrettifyRangeEntry>(), count: numberOfBreakOpportunities)
    recordAndMaintainBestSolutions(
      breakIndex: 0, solution: PrettifyRangeEntry(accumulatedCost: 0), state: state)

    // Special case the first line because of ::first-line styling, indentation, etc.
    var firstLineSlidingWidth = SlidingWidth(
      inlineContentConstrainer: self, inlineItemList: inlineItemList, start: range.startIndex(),
      end: range.startIndex(), useFirstLineStyle: isFirstChunk, isFirstLineInChunk: true)
    for breakIndex in 1..<numberOfBreakOpportunities {
      let end = breakOpportunities[breakIndex]
      firstLineSlidingWidth.advanceEndTo(newEnd: end)

      let firstLineCandidateWidth = firstLineSlidingWidth.width() + firstLineTextIndent
      if Float64(firstLineCandidateWidth) > maximumLineWidth {
        break
      }

      let cost = computeCost(
        candidateLineWidth: firstLineCandidateWidth, idealLineWidth: idealLineWidth)
      recordAndMaintainBestSolutions(
        breakIndex: breakIndex,
        solution: PrettifyRangeEntry(
          accumulatedCost: cost, previousBreakIndex: 0, lastLineWidth: firstLineCandidateWidth),
        state: state)
    }

    // breakOpportunities[firstStartIndex] is the first possible starting position for a candidate line that is NOT the first line
    var firstStartIndex = UInt64(1)
    var slidingWidth = SlidingWidth(
      inlineContentConstrainer: self, inlineItemList: inlineItemList,
      start: breakOpportunities[Int(firstStartIndex)],
      end: breakOpportunities[Int(firstStartIndex)], useFirstLineStyle: false,
      isFirstLineInChunk: false)
    for breakIndex in 1..<numberOfBreakOpportunities {
      let end = breakOpportunities[breakIndex]
      slidingWidth.advanceEndTo(newEnd: end)

      // We prune our search space by limiting the possible starting positions for our candidate line.
      while Float64(textIndent + slidingWidth.width()) > maximumLineWidth {
        firstStartIndex += 1
        if firstStartIndex > breakIndex {
          break
        }
        slidingWidth.advanceStartTo(newStart: breakOpportunities[Int(firstStartIndex)])
      }

      // Evaluate all possible lines that break before m_inlineItemList[end]
      var innerSlidingWidth = slidingWidth
      for startIndex in Int(firstStartIndex)..<breakIndex {
        let start = breakOpportunities[startIndex]
        assert(start != range.startIndex())
        innerSlidingWidth.advanceStartTo(newStart: start)
        let candidateLineWidth = textIndent + innerSlidingWidth.width()
        for entry in state[startIndex] {
          let previousLineWidth = entry.lastLineWidth
          var candidateLineCost = computeCost(
            candidateLineWidth: candidateLineWidth, idealLineWidth: idealLineWidth)
          if breakIndex == numberOfBreakOpportunities - 1 {
            // Keeping the last line width longer than 20% of the previous is a heuristic to avoid orphan and "orphan-like" paragraph endings
            // (lines that have more than one word but are still sufficiently short to appear like an orphan)
            let minimumLastLineWidth = previousLineWidth * 0.2
            let maximumLastLineWidth = previousLineWidth
            candidateLineCost = 0
            if candidateLineWidth < minimumLastLineWidth
              || candidateLineWidth > maximumLastLineWidth
            {
              candidateLineCost = Float32.infinity
            }
          }
          let accumulatedCost = candidateLineCost + entry.accumulatedCost
          recordAndMaintainBestSolutions(
            breakIndex: breakIndex,
            solution: PrettifyRangeEntry(
              accumulatedCost: accumulatedCost, previousBreakIndex: UInt64(startIndex),
              lastLineWidth: candidateLineWidth),
            state: state)
          if breakIndex + 100 < numberOfBreakOpportunities {
            break
          }
        }
      }
    }

    // Check if we found no solution
    if minBestSolution(solutions: state[numberOfBreakOpportunities - 1]).accumulatedCost.isInfinite
    {
      return nil
    }

    // breaks[i] equals the index into m_inlineItemList before which the ith line will break
    var breaks: [UInt64] = []
    var breakIndex = UInt64(numberOfBreakOpportunities - 1)
    repeat {
      breaks.append(breakOpportunities[Int(breakIndex)])
      breakIndex = minBestSolution(solutions: state[Int(breakIndex)]).previousBreakIndex
    } while breakIndex != 0
    breaks.reverse()

    return computeLineWidthsFromBreaks(
      inlineItems: range, breaks: breaks, isFirstChunk: isFirstChunk)
  }

  func minBestSolution(solutions: WTF.PriorityQueue<PrettifyRangeEntry>) -> PrettifyRangeEntry {
    var bestSolution = solutions.first(where: { _ in true })!
    for solution in solutions {
      bestSolution = min(bestSolution, solution)
    }
    return bestSolution
  }

  func recordAndMaintainBestSolutions(
    breakIndex: Int, solution: PrettifyRangeEntry, state: [WTF.PriorityQueue<PrettifyRangeEntry>]
  ) {
    let numberOfBestSolutions = 3
    state[breakIndex].enqueue(element: solution)
    while state[breakIndex].size() > numberOfBestSolutions {
      state[breakIndex].dequeue()
    }
  }

  func inlineItemWidth(inlineItemIndex: UInt64, useFirstLineStyle: Bool) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldTrimLeading(inlineItemIndex: UInt64, useFirstLineStyle: Bool, isFirstLineInChunk: Bool)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldTrimTrailing(inlineItemIndex: UInt64, useFirstLineStyle: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeBreakOpportunities(range: InlineItemRange) -> [UInt64] {
    var breakOpportunities: [UInt64] = []
    var currentIndex = range.startIndex()
    while currentIndex < range.endIndex() {
      currentIndex = inlineFormattingContext.formattingUtils().nextWrapOpportunity(
        startIndex: currentIndex, layoutRange: range,
        inlineItemList: inlineItemList[0..<inlineItemList.count])
      breakOpportunities.append(currentIndex)
    }
    return breakOpportunities
  }

  func computeLineWidthsFromBreaks(
    inlineItems: InlineItemRange, breaks: [UInt64], isFirstChunk: Bool
  ) -> [LayoutUnit] {
    var lineWidths = [LayoutUnit](repeating: LayoutUnit(), count: breaks.count)
    let firstLineTextIndent = computeTextIndent(
      previousLineEndsWithLineBreak: isFirstChunk ? nil : true)
    let textIndent = computeTextIndent(previousLineEndsWithLineBreak: false)
    for i in 0..<breaks.count {
      let start = i == 0 ? inlineItems.startIndex() : breaks[i - 1]
      let end = breaks[i]
      let indentWidth = i == 0 ? firstLineTextIndent : textIndent
      let slidingWidth = SlidingWidth(
        inlineContentConstrainer: self, inlineItemList: inlineItemList, start: start, end: end,
        useFirstLineStyle: i == 0 && isFirstChunk, isFirstLineInChunk: i == 0)
      lineWidths[i] = LayoutUnit.fromFloatCeil(
        value: indentWidth + slidingWidth.width() + LayoutUnit.epsilon())
    }
    return lineWidths
  }

  func computeTextIndent(previousLineEndsWithLineBreak: Bool?) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var inlineItemList: InlineItemList

  struct SlidingWidth {
    init(
      inlineContentConstrainer: InlineContentConstrainer, inlineItemList: InlineItemList,
      start: UInt64, end: UInt64, useFirstLineStyle: Bool, isFirstLineInChunk: Bool
    ) {
      self.inlineContentConstrainer = inlineContentConstrainer
      self.inlineItemList = inlineItemList
      self.start = start
      self.end = start
      self.useFirstLineStyle = useFirstLineStyle
      self.isFirstLineInChunk = isFirstLineInChunk
      assert(start <= end)
      while self.end < end {
        advanceEnd()
      }
    }

    func width() -> InlineLayoutUnit {
      return totalWidth - leadingTrimmableWidth - trailingTrimmableWidth
    }

    mutating func advanceStart() {
      assert(start < end)
      let startItemIndex = start
      let startItemWidth = inlineContentConstrainer.inlineItemWidth(
        inlineItemIndex: startItemIndex, useFirstLineStyle: useFirstLineStyle)
      totalWidth -= startItemWidth
      start += 1

      if inlineContentConstrainer.shouldTrimLeading(
        inlineItemIndex: startItemIndex, useFirstLineStyle: useFirstLineStyle,
        isFirstLineInChunk: isFirstLineInChunk)
      {
        leadingTrimmableWidth -= startItemWidth
        return
      }

      firstLeadingNonTrimmedItem = nil
      leadingTrimmableWidth = 0
      for current in start..<end {
        if !inlineContentConstrainer.shouldTrimLeading(
          inlineItemIndex: current, useFirstLineStyle: useFirstLineStyle,
          isFirstLineInChunk: isFirstLineInChunk)
        {
          firstLeadingNonTrimmedItem = current
          break
        }
        leadingTrimmableWidth += inlineContentConstrainer.inlineItemWidth(
          inlineItemIndex: current, useFirstLineStyle: useFirstLineStyle)
      }

      // Update trailing logic if necessary:
      //   1: Check if the removed start item was the first trailing item
      //   2: Check if the first non trimmed leading item surpassed the first trailing item
      // In both cases, we should have m_leadingTrimmableWidth + m_trailingTrimmableWidth = m_totalWidth
      if leadingTrimmableWidth + trailingTrimmableWidth > totalWidth {
        trailingTrimmableWidth = totalWidth - leadingTrimmableWidth
      }
    }

    mutating func advanceStartTo(newStart: UInt64) {
      assert(start <= newStart)
      while start < newStart {
        advanceStart()
      }
    }

    mutating func advanceEnd() {
      assert(end < inlineItemList.count)
      let endItemIndex = end
      let endItemWidth = inlineContentConstrainer.inlineItemWidth(
        inlineItemIndex: endItemIndex, useFirstLineStyle: useFirstLineStyle)
      totalWidth += endItemWidth
      end += 1

      if firstLeadingNonTrimmedItem == nil {
        if inlineContentConstrainer.shouldTrimLeading(
          inlineItemIndex: endItemIndex, useFirstLineStyle: useFirstLineStyle,
          isFirstLineInChunk: isFirstLineInChunk)
        {
          leadingTrimmableWidth += endItemWidth
          return
        }
        firstLeadingNonTrimmedItem = endItemIndex
        return
      }

      if inlineContentConstrainer.shouldTrimTrailing(
        inlineItemIndex: end - 1, useFirstLineStyle: useFirstLineStyle)
      {
        trailingTrimmableWidth += endItemWidth
        return
      }

      trailingTrimmableWidth = 0
    }

    mutating func advanceEndTo(newEnd: UInt64) {
      assert(end <= newEnd)
      while end < newEnd {
        advanceEnd()
      }
    }

    var inlineContentConstrainer: InlineContentConstrainer
    var inlineItemList: InlineItemList
    var start: UInt64 = 0
    var end: UInt64 = 0
    var useFirstLineStyle = false
    var isFirstLineInChunk = false
    var totalWidth = InlineLayoutUnit()
    var leadingTrimmableWidth = InlineLayoutUnit()
    var trailingTrimmableWidth = InlineLayoutUnit()
    var firstLeadingNonTrimmedItem: UInt64? = nil
  }

  var inlineFormattingContext: InlineFormattingContext

  var originalLineInlineItemRanges: [InlineItemRange] = []
  var originalLineWidths: [Float32] = []
  var originalLineEndsWithForcedBreak: [Bool] = []
  var numberOfLinesInOriginalLayout: UInt64 = 0
  var maximumLineWidth: Float64 = 0
  var cannotConstrainContent = false
  var hasSingleLineVisibleContent = false
}
