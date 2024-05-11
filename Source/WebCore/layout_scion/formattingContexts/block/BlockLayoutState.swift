/*
 * Copyright (C) 2022 Apple Inc. All rights reserved.
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

// This class holds block level information shared across child inline formatting contexts.
struct BlockLayoutState {
  struct LineClamp {
    var maximumLines: UInt64 = 0
    var shouldDiscardOverflow = false
    var isLegacy = true
  }
  struct TextBoxTrim: OptionSet {
    let rawValue: UInt8
    static let Start = TextBoxTrim(rawValue: 1 << 0)
    static let End = TextBoxTrim(rawValue: 1 << 1)
  }

  struct LineGrid {
    var layoutOffset = LayoutSizeWrapper()
    var gridOffset = LayoutSizeWrapper()
    var columnWidth = InlineLayoutUnit()
    var rowHeight = LayoutUnit()
    var topRowOffset = LayoutUnit()
    var primaryFont: FontWrapper? = nil
    var paginationOrigin: LayoutSizeWrapper? = nil
    var pageLogicalTop = LayoutUnit()
  }

  init(
    placedFloats: PlacedFloats, lineClamp: LineClamp? = nil,
    textBoxTrim: TextBoxTrim = TextBoxTrim(),
    textBoxEdge: TextEdge = TextEdge(), intrusiveInitialLetterLogicalBottom: LayoutUnit? = nil,
    lineGrid: LineGrid? = nil
  ) {
    self.placedFloats = placedFloats
    self.lineClamp = lineClamp
    self.textBoxTrim = textBoxTrim
    self.textBoxEdge = textBoxEdge
    self.intrusiveInitialLetterLogicalBottom = intrusiveInitialLetterLogicalBottom
    self.lineGrid = lineGrid
  }

  var placedFloats: PlacedFloats
  var lineClamp: LineClamp? = nil
  var textBoxTrim = TextBoxTrim()
  var textBoxEdge = TextEdge()
  var intrusiveInitialLetterLogicalBottom: LayoutUnit? = nil
  var lineGrid: LineGrid? = nil
}
