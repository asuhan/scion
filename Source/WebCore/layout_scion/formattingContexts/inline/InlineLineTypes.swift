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

enum LineEndingTruncationPolicy: UInt8 {
  case NoTruncation
  case WhenContentOverflowsInInlineDirection
  case WhenContentOverflowsInBlockDirection
}

struct ExpansionInfo {
  var opportunityCount: UInt64 = 0
  var opportunityList: [UInt64] = []
  var behaviorList: [ExpansionBehaviorWrapper] = []
}

struct InlineItemPosition: Equatable {
  var index: UInt64 = 0
  var offset: UInt64 = 0

  func bool() -> Bool { return index != 0 || offset != 0 }
}

struct InlineItemRange {
  init() {}

  init(start: InlineItemPosition, end: InlineItemPosition) {
    self.start = start
    self.end = end
  }

  var start = InlineItemPosition()
  var end = InlineItemPosition()

  func startIndex() -> UInt64 { return start.index }
  func endIndex() -> UInt64 { return end.index }
  func isEmpty() -> Bool { return startIndex() == endIndex() && start.offset == end.offset }
}

struct PreviousLine {
  var lineIndex: UInt64 = 0
  // Content width measured during line breaking (avoid double-measuring).
  var trailingOverflowingContentWidth: InlineLayoutUnit? = nil
  var endsWithLineBreak = false
  var hasInlineContent = false
  var inlineBaseDirection = TextDirection.LTR
  var suspendedFloats: [BoxWrapper] = []
}
