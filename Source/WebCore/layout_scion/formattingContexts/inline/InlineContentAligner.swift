/*
 * Copyright (C) 2023 Apple Inc. All rights reserved.
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

enum IgnoreRubyRange: UInt8 {
  case No
  case Yes
}

internal func computedExpansions(
  runs: Line.RunList, runRange: Range<UInt64>, hangingTrailingWhitespaceLength: UInt64,
  expansionInfo: inout ExpansionInfo, ignoreRuby: IgnoreRubyRange
) {
  // Collect and distribute the expansion opportunities.
  expansionInfo.opportunityCount = 0
  let rangeSize = runRange.upperBound - runRange.lowerBound
  if rangeSize > runs.count {
    fatalError("Not reached")
  }
  expansionInfo.opportunityList.reserveCapacity(Int(rangeSize))
  while expansionInfo.opportunityList.count < rangeSize {
    expansionInfo.opportunityList.append(0)
  }
  expansionInfo.behaviorList.reserveCapacity(Int(rangeSize))
  while expansionInfo.behaviorList.count < rangeSize {
    expansionInfo.behaviorList.append(ExpansionBehaviorWrapper())
  }
  var lastExpansionIndexWithContent: UInt64? = nil

  // Line start behaves as if we had an expansion here (i.e. first runs should not start with allowing left expansion).
  var runIsAfterExpansion = true
  let lastTextRunIndexForTrimming = lastTextRunIndexForTrimming(
    runs: runs, hangingTrailingWhitespaceLength: hangingTrailingWhitespaceLength)
  var index: UInt64 = 0
  while index < rangeSize {
    skipRubyContentIfApplicable(
      runs: runs, runRange: runRange, rangeSize: rangeSize, ignoreRuby: ignoreRuby,
      expansionInfo: &expansionInfo, index: &index, runIsAfterExpansion: &runIsAfterExpansion)
    if index >= rangeSize {
      break
    }
    let run = runs[Int(runIndex(runRange: runRange, index: index))]

    var expansionBehavior = ExpansionBehaviorWrapper.defaultBehavior()
    var expansionOpportunitiesInRun: UInt64 = 0

    // According to the CSS3 spec, a UA can determine whether or not
    // it wishes to apply text-align: justify to text with collapsible spaces (and this behavior matches Blink).
    let mayAlterSpacingWithinText =
      !TextUtil.shouldPreserveSpacesAndTabs(layoutBox: run.layoutBox)
      || hangingTrailingWhitespaceLength != 0
    if run.isText() && mayAlterSpacingWithinText {
      if run.hasTextCombine() {
        expansionBehavior = ExpansionBehaviorWrapper.forbidAll()
      } else {
        expansionBehavior.left = runIsAfterExpansion ? .Forbid : .Allow
        expansionBehavior.right = .Allow
        let textContent = run.textContent!
        var length = textContent.length
        if let lastTextRunIndexForTrimming = lastTextRunIndexForTrimming {
          if runIndex(runRange: runRange, index: index) == lastTextRunIndexForTrimming {
            // Trailing hanging whitespace sequence is ignored when computing the expansion opportunities.
            length -= hangingTrailingWhitespaceLength
          }
        }
        (expansionOpportunitiesInRun, runIsAfterExpansion) =
          FontCascadeWrapper.expansionOpportunityCount(
            stringView: StringWrapperView(s: (run.layoutBox as! InlineTextBoxWrapper).content)
              .substring(
                start: UInt32(textContent.start), length: UInt32(length)),
            direction: run.inlineDirection(), expansionBehavior: expansionBehavior)
      }
    } else if run.isAtomicInlineBox() {
      runIsAfterExpansion = false
    }

    expansionInfo.behaviorList[Int(index)] = expansionBehavior
    expansionInfo.opportunityList[Int(index)] = expansionOpportunitiesInRun
    expansionInfo.opportunityCount += expansionOpportunitiesInRun

    if run.isText() || run.isAtomicInlineBox() {
      lastExpansionIndexWithContent = index
    }
    index += 1
  }
  // Forbid right expansion in the last run to prevent trailing expansion at the end of the line.
  if let lastExpansionIndexWithContent = lastExpansionIndexWithContent {
    let expansionOpportunity = expansionInfo.opportunityList[Int(lastExpansionIndexWithContent)]
    if expansionOpportunity == 0 {
      return
    }
    expansionInfo.behaviorList[Int(lastExpansionIndexWithContent)].right = .Forbid
    if runIsAfterExpansion {
      // When the last run has an after expansion (e.g. CJK ideograph) we need to remove this trailing expansion opportunity.
      // Note that this is not about trailing collapsible whitespace as at this point we trimmed them all.
      assert(expansionInfo.opportunityCount != 0 && expansionOpportunity != 0)
      expansionInfo.opportunityCount -= 1
      expansionInfo.opportunityList[Int(lastExpansionIndexWithContent)] -= 1
    }
  }
}

internal func lastTextRunIndexForTrimming(
  runs: Line.RunList, hangingTrailingWhitespaceLength: UInt64
) -> UInt64? {
  if hangingTrailingWhitespaceLength == 0 {
    return nil
  }
  for (index, run) in runs.enumerated().reversed() {
    if run.isText() {
      return UInt64(index)
    }
  }
  return nil
}

internal func runIndex(runRange: Range<UInt64>, index: UInt64) -> UInt64 {
  return runRange.lowerBound + index
}

internal func skipRubyContentIfApplicable(
  runs: Line.RunList, runRange: Range<UInt64>, rangeSize: UInt64, ignoreRuby: IgnoreRubyRange,
  expansionInfo: inout ExpansionInfo, index: inout UInt64, runIsAfterExpansion: inout Bool
) {
  let rubyBox = runs[Int(runIndex(runRange: runRange, index: index))].layoutBox
  if ignoreRuby == .No || !rubyBox.isRuby() {
    return
  }
  runIsAfterExpansion = false
  while index < rangeSize {
    expansionInfo.behaviorList[Int(index)] = ExpansionBehaviorWrapper.defaultBehavior()
    expansionInfo.opportunityList[Int(index)] = 0
    let run = runs[Int(runIndex(runRange: runRange, index: index))]
    if run.isInlineBoxEnd() && run.layoutBox === rubyBox {
      index += 1
      return
    }
    index += 1
  }
}

class InlineContentAligner {
  static func applyTextAlignJustify(
    runs: Line.RunList, spaceToDistribute: InlineLayoutUnit, hangingTrailingWhitespaceLength: UInt64
  ) -> InlineLayoutUnit {
    if runs.isEmpty {
      fatalError("Not reached")
    }

    if spaceToDistribute <= 0 {
      return InlineLayoutUnit()
    }

    var expansion = ExpansionInfo()
    let fullRange = 0..<UInt64(runs.count)
    computedExpansions(
      runs: runs, runRange: fullRange,
      hangingTrailingWhitespaceLength: hangingTrailingWhitespaceLength, expansionInfo: &expansion,
      ignoreRuby: .Yes)
    // Anything to distribute?
    if expansion.opportunityCount == 0 {
      return InlineLayoutUnit()
    }
    return applyExpansionOnRange(
      runs: runs, range: fullRange, expansion: expansion, spaceToDistribute: spaceToDistribute)
  }

  static func applyRubyAlign(
    rubyAlign: RubyAlign, runs: Line.RunList, range: Range<UInt64>,
    spaceToDistribute: InlineLayoutUnit
  ) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func applyExpansionOnRange(
    runs: Line.RunList, range: Range<UInt64>, expansion: ExpansionInfo,
    spaceToDistribute: InlineLayoutUnit
  ) -> InlineLayoutUnit {
    assert(spaceToDistribute > 0)
    assert(expansion.opportunityCount != 0)
    // Distribute the extra space.
    let expansionToDistribute = spaceToDistribute / InlineLayoutUnit(expansion.opportunityCount)
    var accumulatedExpansion = InlineLayoutUnit()
    let rangeSize = range.upperBound - range.lowerBound
    if range.upperBound > runs.count {
      fatalError("Not reached")
    }
    for index in 0..<rangeSize {
      let run = runs[Int(range.lowerBound + index)]
      // Move runs by the accumulated expansion first
      run.moveHorizontally(offset: accumulatedExpansion)
      // and expand.
      let computedExpansion =
        expansionToDistribute * InlineLayoutUnit(expansion.opportunityList[Int(index)])
      run.setExpansion(
        expansion: InlineDisplay.Box.Expansion(
          behavior: expansion.behaviorList[Int(index)], horizontalExpansion: computedExpansion))
      run.shrinkHorizontally(width: -computedExpansion)
      accumulatedExpansion += computedExpansion
    }
    // Content grows as runs expand.
    return accumulatedExpansion
  }
}
