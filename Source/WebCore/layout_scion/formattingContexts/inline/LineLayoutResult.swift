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

struct LineLayoutResult {
  typealias PlacedFloatList = PlacedFloats.List
  typealias SuspendedFloatList = [BoxWrapper]

  var inlineItemRange = InlineItemRange()
  var inlineContent = Line.RunList()

  struct FloatContent {
    var placedFloats = PlacedFloatList()
    var suspendedFloats = SuspendedFloatList()
    var hasIntrusiveFloat = UsedFloat()
  }
  var floatContent = FloatContent()

  struct ContentGeometry {
    var logicalLeft = InlineLayoutUnit()
    var logicalWidth = InlineLayoutUnit()
    var logicalRightIncludingNegativeMargin = InlineLayoutUnit()  // Note that with negative horizontal margin value, contentLogicalLeft + contentLogicalWidth is not necessarily contentLogicalRight.
    var trailingOverflowingContentWidth: InlineLayoutUnit? = nil
  }
  var contentGeometry = ContentGeometry()

  struct LineGeometry {
    var logicalTopLeft = InlineLayoutPoint()
    var logicalWidth = InlineLayoutUnit()
    var initialLogicalLeftIncludingIntrusiveFloats = InlineLayoutUnit()
    var initialLetterClearGap: InlineLayoutUnit? = nil
  }
  var lineGeometry = LineGeometry()

  struct HangingContent {
    var shouldContributeToScrollableOverflow = false
    var logicalWidth = InlineLayoutUnit()
    var hangablePunctuationStartWidth = InlineLayoutUnit()
  }
  var hangingContent = HangingContent()

  struct Directionality {
    var visualOrderList: [Int32] = []
    var inlineBaseDirection: TextDirection = .LTR
  }
  var directionality = Directionality()

  struct IsFirstLast {
    enum FirstFormattedLine: UInt8 {
      case No
      case WithinIFC
      case WithinBFC
    }
    var isFirstFormattedLine: FirstFormattedLine = .WithinIFC
    var isLastLineWithInlineContent = true
  }
  var isFirstLast = IsFirstLast()

  struct Ruby {
    var baseAlignmentOffsetList: [UInt: InlineLayoutUnit] = [:]
    var annotationAlignmentOffset = InlineLayoutUnit()
  }
  var ruby = Ruby()

  // Misc
  var endsWithHyphen: Bool = false
  var nonSpanningInlineLevelBoxCount: UInt64 = 0
  var trimmedTrailingWhitespaceWidth = InlineLayoutUnit()  // only used for line-break: after-white-space currently
  var firstLineStartTrim = InlineLayoutUnit()  // This is how much text-box-trim: start adjusts the first line box. We only need it to adjust the initial letter float position (which will not be needed once we drop the float behavior)
  var hintForNextLineTopToAvoidIntrusiveFloat: InlineLayoutUnit? = nil  // This is only used for cases when intrusive floats prevent any content placement at current vertical position.
}
