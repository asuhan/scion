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

class InlineItemWrapper {
  enum Type_ {
    case Text
    case HardLineBreak
    case SoftLineBreak
    case WordBreakOpportunity
    case AtomicInlineBox
    case InlineBoxStart
    case InlineBoxEnd
    case Float
    case Opaque
  }
  init(layoutBox: BoxWrapper, type: Type_, bidiLevel: UBiDiLevel = UBiDiLevel.UBIDI_DEFAULT_LTR) {
    self.layoutBox = layoutBox
    self.width = 0
    self.length = 0
    self.startOrPosition = 0
    self.hasWidth = false
    self.type = type
    self.bidiLevel = bidiLevel
  }

  init() {
    layoutBox = BoxWrapper()
    width = 0
    length = 0
    startOrPosition = 0
    hasWidth = false
    type = .Text
    bidiLevel = UBiDiLevel.UBIDI_DEFAULT_LTR
  }

  static let opaqueBidiLevel = UBiDiLevel.OPAQUE

  func style() -> RenderStyleWrapper {
    return layoutBox.style
  }

  func firstLineStyle() -> RenderStyleWrapper {
    return layoutBox.firstLineStyle()
  }

  func setWidth(width: InlineLayoutUnit) {
    self.width = width
    self.hasWidth = true
  }

  func isText() -> Bool {
    return type == .Text
  }

  func isAtomicInlineBox() -> Bool { return type == .AtomicInlineBox }

  func isFloat() -> Bool { return type == .Float }

  func isLineBreak() -> Bool { return isSoftLineBreak() || isHardLineBreak() }

  func isWordBreakOpportunity() -> Bool { return type == .WordBreakOpportunity }

  func isSoftLineBreak() -> Bool { return type == .SoftLineBreak }

  func isHardLineBreak() -> Bool { return type == .HardLineBreak }

  func isInlineBoxStart() -> Bool { return type == .InlineBoxStart }

  func isInlineBoxEnd() -> Bool { return type == .InlineBoxEnd }

  func isInlineBoxStartOrEnd() -> Bool { return isInlineBoxStart() || isInlineBoxEnd() }

  func isOpaque() -> Bool { return type == .Opaque }

  func setBidiLevel(bidiLevel: UBiDiLevel) { self.bidiLevel = bidiLevel }

  // For InlineTextItem
  enum TextItemType: UInt8 {
    case Undefined
    case Whitespace
    case NonWhitespace
  }

  var layoutBox: BoxWrapper
  var width: InlineLayoutUnit
  var length: UInt32
  var startOrPosition: UInt32
  var bidiLevel: UBiDiLevel
  var textItemType: TextItemType = .Undefined
  var hasWidth: Bool
  var isWordSeparator = false
  var type: Type_
}

typealias InlineItemList = [InlineItemWrapper]
