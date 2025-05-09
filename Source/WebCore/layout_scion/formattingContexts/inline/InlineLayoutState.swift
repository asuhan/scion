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

class InlineLayoutState {
  init(parentBlockLayoutState: BlockLayoutState) {
    self.parentBlockLayoutState = parentBlockLayoutState
  }

  func setClearGapAfterLastLine(verticalGap: InlineLayoutUnit) {
    assert(verticalGap >= 0)
    clearGapAfterLastLine = verticalGap
  }

  func setClearGapBeforeFirstLine(verticalGap: InlineLayoutUnit) {
    clearGapBeforeFirstLine = verticalGap
  }

  func setAvailableLineWidthOverride(availableLineWidthOverride: AvailableLineWidthOverride) {
    self.availableLineWidthOverride = availableLineWidthOverride
  }

  func placedFloats() -> PlacedFloats {
    return parentBlockLayoutState.placedFloats
  }

  func setLegacyClampedLineIndex(lineIndex: UInt64) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHyphenationLimitLines(hyphenationLimitLines: UInt64) {
    self.hyphenationLimitLines = hyphenationLimitLines
  }

  func incrementSuccessiveHyphenatedLineCount() {
    successiveHyphenatedLineCount += 1
  }

  func resetSuccessiveHyphenatedLineCount() {
    successiveHyphenatedLineCount = 0
  }

  func isHyphenationDisabled() -> Bool {
    if let hyphenationLimitLines = self.hyphenationLimitLines {
      return hyphenationLimitLines <= successiveHyphenatedLineCount
    }
    return false
  }

  func setFirstLineStartTrimForInitialLetter(trimmedThisMuch: InlineLayoutUnit) {
    firstLineStartTrimForInitialLetter = trimmedThisMuch
  }

  func setInStandardsMode() {
    self.inStandardsMode = true
  }

  // Integration codepath only
  func setNestedListMarkerOffsets(nestedListMarkerOffsets: [UInt: LayoutUnit]) {
    self.nestedListMarkerOffsets = nestedListMarkerOffsets
  }

  func nestedListMarkerOffset(listMarkerBox: ElementBoxWrapper) -> LayoutUnit {
    return nestedListMarkerOffsets[CPtrToInt(listMarkerBox.p), default: LayoutUnit()]
  }

  func setShouldNotSynthesizeInlineBlockBaseline() {
    shouldNotSynthesizeInlineBlockBaseline = true
  }

  var parentBlockLayoutState: BlockLayoutState
  var clearGapBeforeFirstLine = InlineLayoutUnit()
  var clearGapAfterLastLine = InlineLayoutUnit()
  var firstLineStartTrimForInitialLetter = InlineLayoutUnit()
  var clampedLineIndex: UInt64? = nil
  var hyphenationLimitLines: UInt64? = nil
  var successiveHyphenatedLineCount: UInt64 = 0
  private var nestedListMarkerOffsets: [UInt: LayoutUnit] = [:]
  var availableLineWidthOverride = AvailableLineWidthOverride()
  var shouldNotSynthesizeInlineBlockBaseline = false
  var inStandardsMode = false
}
