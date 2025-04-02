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

class InlineTextItemWrapper: InlineItemWrapper {
  override init() {
    super.init()
    self.layoutBox = InlineTextBoxWrapper(
      content: StringWrapper(), isCombined: false, canUseSimplifiedContentMeasuring: false,
      canUseSimpleFontCodePath: false, hasPositionDependentContentWidth: false,
      hasStrongDirectionalityContent: false,
      style: RenderStyleWrapper())
  }

  init(inlineTextBox: InlineTextBoxWrapper) {
    super.init(layoutBox: inlineTextBox, type: Type_.Text, bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR)
  }

  init(
    inlineTextBox: InlineTextBoxWrapper, start: UInt32, length: UInt32, bidiLevel: UBiDiLevel,
    hasTrailingSoftHyphen: Bool, isWordSeparator: Bool, width: InlineLayoutUnit?,
    textItemType: InlineItemWrapper.TextItemType
  ) {
    super.init(layoutBox: inlineTextBox, type: Type_.Text, bidiLevel: bidiLevel)
    self.startOrPosition = start
    self.length = length
    self.hasWidth = width != nil
    self.hasTrailingSoftHyphen = hasTrailingSoftHyphen
    self.isWordSeparator = isWordSeparator
    self.width = width ?? 0
    self.textItemType = textItemType
  }

  static func createWhitespaceItem(
    inlineTextBox: InlineTextBoxWrapper, start: UInt32, length: UInt32, bidiLevel: UBiDiLevel,
    isWordSeparator: Bool, width: InlineLayoutUnit?
  ) -> InlineTextItemWrapper {
    return InlineTextItemWrapper(
      inlineTextBox: inlineTextBox, start: start, length: length, bidiLevel: bidiLevel,
      hasTrailingSoftHyphen: false, isWordSeparator: isWordSeparator, width: width,
      textItemType: .Whitespace)
  }

  static func createNonWhitespaceItem(
    inlineTextBox: InlineTextBoxWrapper, start: UInt32, length: UInt32, bidiLevel: UBiDiLevel,
    hasTrailingSoftHyphen: Bool, width: InlineLayoutUnit?
  ) -> InlineTextItemWrapper {
    // FIXME: Use the following list of non-whitespace characters to set the "isWordSeparator" bit: noBreakSpace, ethiopicWordspace, aegeanWordSeparatorLine aegeanWordSeparatorDot ugariticWordDivider.
    return InlineTextItemWrapper(
      inlineTextBox: inlineTextBox, start: start, length: length, bidiLevel: bidiLevel,
      hasTrailingSoftHyphen: hasTrailingSoftHyphen, isWordSeparator: false, width: width,
      textItemType: .NonWhitespace)
  }

  static func createEmptyItem(inlineTextBox: InlineTextBoxWrapper) -> InlineTextItemWrapper {
    assert(inlineTextBox.content.length() == 0)
    return InlineTextItemWrapper(inlineTextBox: inlineTextBox)
  }

  func start() -> UInt32 {
    return startOrPosition
  }

  func end() -> UInt32 {
    return start() + length
  }

  func isEmpty() -> Bool { return length == 0 && textItemType == .Undefined }

  func isWhitespace() -> Bool {
    return textItemType == .Whitespace
  }

  func isZeroWidthSpaceSeparator() -> Bool {
    // FIXME: We should check for more zero width content and not just U+200B.
    return length == 0
      || (length == 1 && inlineTextBox().content[start()] == CharacterNames.Unicode.zeroWidthSpace)
  }

  func isQuirkNonBreakingSpace() -> Bool {
    if style().nbspMode() != .Space || style().textWrapMode() == .NoWrap
      || style().whiteSpaceCollapse() == .BreakSpaces
    {
      return false
    }
    return length != 0 && inlineTextBox().content[start()] == CharacterNames.Unicode.noBreakSpace
  }

  func isFullyTrimmable() -> Bool {
    return isWhitespace() && !TextUtil.shouldPreserveSpacesAndTabs(layoutBox: layoutBox)
  }

  func width() -> InlineLayoutUnit? { return hasWidth ? width : nil }

  func inlineTextBox() -> InlineTextBoxWrapper {
    return layoutBox as! InlineTextBoxWrapper
  }

  func left(length: UInt32) -> InlineTextItemWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func right(length: UInt32, width: InlineLayoutUnit?) -> InlineTextItemWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func shouldPreserveSpacesAndTabs(inlineTextItem: InlineTextItemWrapper) -> Bool {
    assert(inlineTextItem.isWhitespace())
    return TextUtil.shouldPreserveSpacesAndTabs(layoutBox: inlineTextItem.layoutBox)
  }

  func split(leftSideLength: UInt64) -> InlineTextItemWrapper {
    assert(length > 1)
    assert(leftSideLength != 0 && leftSideLength < length)
    let rightSide = right(length: length - UInt32(leftSideLength), width: nil)
    length -= rightSide.length
    hasWidth = false
    width = InlineLayoutUnit()
    return rightSide
  }

  var hasTrailingSoftHyphen = false
}
