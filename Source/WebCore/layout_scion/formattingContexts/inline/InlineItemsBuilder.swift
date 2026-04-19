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

struct WhitespaceContent {
  var length: UInt64 = 0
  var isWordSeparator = false
}

internal func isWhitespaceCharacter(
  character: UChar, preserveNewline: Bool, preserveTab: Bool,
  hasWordSeparatorCharacter: inout Bool,
  isWordSeparatorCharacter: inout Bool
)
  -> Bool
{
  // white space processing in CSS affects only the document white space characters: spaces (U+0020), tabs (U+0009), and segment breaks.
  let isTreatedAsSpaceCharacter =
    character == CharacterNames.Unicode.space
    || (character == CharacterNames.Unicode.newlineCharacter && !preserveNewline)
    || (character == CharacterNames.Unicode.tabCharacter && !preserveTab)
  isWordSeparatorCharacter = isTreatedAsSpaceCharacter
  hasWordSeparatorCharacter = hasWordSeparatorCharacter || isWordSeparatorCharacter
  return isTreatedAsSpaceCharacter || character == CharacterNames.Unicode.tabCharacter
}

func moveToNextNonWhitespacePosition<CharacterType>(
  characters: CharSpanWrapper<CharacterType>, startPosition: UInt64, preserveNewline: Bool,
  preserveTab: Bool, stopAtWordSeparatorBoundary: Bool
)
  -> WhitespaceContent? where CharacterType: BinaryInteger
{
  var hasWordSeparatorCharacter = false
  var isWordSeparatorCharacter = false
  var nextNonWhiteSpacePosition = startPosition
  // TODO(asuhan): Not using characters[nextNonWhiteSpacePosition] to bypass the bounds check.
  while nextNonWhiteSpacePosition < characters.size()
    && isWhitespaceCharacter(
      character: characters[nextNonWhiteSpacePosition],
      preserveNewline: preserveNewline,
      preserveTab: preserveTab, hasWordSeparatorCharacter: &hasWordSeparatorCharacter,
      isWordSeparatorCharacter: &isWordSeparatorCharacter)
  {
    if stopAtWordSeparatorBoundary && hasWordSeparatorCharacter && !isWordSeparatorCharacter {
      break
    }
    nextNonWhiteSpacePosition += 1
  }
  return nextNonWhiteSpacePosition == startPosition
    ? nil
    : WhitespaceContent(
      length: nextNonWhiteSpacePosition - startPosition, isWordSeparator: hasWordSeparatorCharacter)
}

func moveToNextBreakablePosition(
  startPosition: UInt32, lineBreakIteratorFactory: inout CachedLineBreakIteratorFactoryWrapper,
  style: RenderStyleWrapper
) -> UInt32 {
  let textLength = lineBreakIteratorFactory.stringView().length()
  var startPositionForNextBreakablePosition = startPosition
  while startPositionForNextBreakablePosition < textLength {
    let nextBreakablePosition = TextUtil.findNextBreakablePosition(
      lineBreakIteratorFactory: &lineBreakIteratorFactory,
      startPosition: startPositionForNextBreakablePosition, style: style)
    // Oftentimes the next breakable position comes back as the start position (most notably hyphens).
    if nextBreakablePosition != startPosition {
      return nextBreakablePosition - startPosition
    }
    startPositionForNextBreakablePosition += 1
  }
  return textLength - startPosition
}

internal func isTextOrLineBreak(layoutBox: BoxWrapper) -> Bool {
  return layoutBox.isInFlow()
    && (layoutBox.isInlineTextBox()
      || (layoutBox.isLineBreakBox() && !layoutBox.isWordBreakOpportunity()))
}

internal func requiresVisualReordering(layoutBox: BoxWrapper) -> Bool {
  if let inlineTextBox = layoutBox as? InlineTextBoxWrapper {
    return inlineTextBox.hasStrongDirectionalityContent()
  }
  if layoutBox.isInlineBox() && layoutBox.isInFlow() {
    let style = layoutBox.style
    return !style.isLeftToRightDirection()
      || (style.rtlOrdering() == .Logical && style.unicodeBidi() != .Normal)
  }
  return false
}

internal func isNewLineOrTabCharacter(
  textContent: StringWrapper, position: inout UInt64, needsUnicodeHandling: Bool,
  contentLength: UInt32
)
  -> Bool
{
  if needsUnicodeHandling {
    let characters = textContent.span16()
    let character = U16_NEXT(s: characters, i: &position, length: contentLength)
    return character == CharacterNames.Unicode.newlineCharacter
      || character == CharacterNames.Unicode.tabCharacter
  }
  let ch = textContent[UInt32(position)]
  let isNewLineOrTab =
    ch == CharacterNames.Unicode.newlineCharacter || ch == CharacterNames.Unicode.tabCharacter
  position += 1
  return isNewLineOrTab
}

func replaceNonPreservedNewLineAndTabCharactersAndAppend(
  inlineTextBox: InlineTextBoxWrapper, paragraphContentBuilder: StringBuilderWrapper
) {
  // ubidi prefers non-preserved new lines/tabs as space characters.
  assert(!TextUtil.shouldPreserveNewline(layoutBox: inlineTextBox))
  let textContent = inlineTextBox.content
  let contentLength = textContent.length()
  let needsUnicodeHandling = !textContent.is8Bit()
  var nonReplacedContentStartPosition: UInt64 = 0
  var position: UInt64 = 0
  while position < contentLength {
    // Note that because of proper code point boundary handling (see U16_NEXT), position is incremented in an unconventional way here.
    let startPosition = position
    if !isNewLineOrTabCharacter(
      textContent: textContent, position: &position,
      needsUnicodeHandling: needsUnicodeHandling,
      contentLength: contentLength)
    {
      continue
    }

    if nonReplacedContentStartPosition < startPosition {
      paragraphContentBuilder.append(
        string: StringWrapperView(s: textContent).substring(
          start: UInt32(nonReplacedContentStartPosition),
          length: UInt32(startPosition - nonReplacedContentStartPosition)))
    }
    paragraphContentBuilder.append(character: CharacterNames.Unicode.space)
    nonReplacedContentStartPosition = position
  }
  if nonReplacedContentStartPosition < contentLength {
    paragraphContentBuilder.append(
      string: StringWrapperView(s: textContent).right(
        length: contentLength - UInt32(nonReplacedContentStartPosition)))
  }
}

struct BidiContext {
  var unicodeBidi: UnicodeBidi
  var isLeftToRightDirection = false
  var isBlockLevel = false
}

typealias BidiContextStack = [BidiContext]

enum EnterExitType: UInt8 {
  case EnteringBlock
  case ExitingBlock
  case EnteringInlineBox
  case ExitingInlineBox
}

func handleEnterExitBidiContext(
  paragraphContentBuilder: StringBuilderWrapper, unicodeBidi: UnicodeBidi, isLTR: Bool,
  enterExitType: EnterExitType, bidiContextStack: inout BidiContextStack
) {
  if enterExitType == .ExitingInlineBox && bidiContextStack.count == 1 {
    // Refuse to pop the initial block entry off of the stack. It indicates unbalanced InlineBoxStart/End pairs.
    fatalError("Not reached")
  }

  let isEnteringBidi = enterExitType == .EnteringBlock || enterExitType == .EnteringInlineBox
  switch unicodeBidi {
  case .Normal:
    // The box does not open an additional level of embedding with respect to the bidirectional algorithm.
    // For inline boxes, implicit reordering works across box boundaries.
    break
  case .Embed:
    // Isolate and embed values are enforced by default and redundant on the block level boxes.
    if enterExitType == .EnteringBlock {
      break
    }
    paragraphContentBuilder.append(
      character:
        isEnteringBidi
        ? (isLTR
          ? CharacterNames.Unicode.leftToRightEmbed : CharacterNames.Unicode.rightToLeftEmbed)
        : CharacterNames.Unicode.popDirectionalFormatting)
  case .Override:
    paragraphContentBuilder.append(
      character:
        isEnteringBidi
        ? (isLTR
          ? CharacterNames.Unicode.leftToRightOverride : CharacterNames.Unicode.rightToLeftOverride)
        : CharacterNames.Unicode.popDirectionalFormatting)
  case .Isolate:
    // Isolate and embed values are enforced by default and redundant on the block level boxes.
    if enterExitType == .EnteringBlock {
      break
    }
    paragraphContentBuilder.append(
      character:
        isEnteringBidi
        ? (isLTR
          ? CharacterNames.Unicode.leftToRightIsolate : CharacterNames.Unicode.rightToLeftIsolate)
        : CharacterNames.Unicode.popDirectionalIsolate)
  case .Plaintext:
    paragraphContentBuilder.append(
      character:
        isEnteringBidi
        ? CharacterNames.Unicode.firstStrongIsolate : CharacterNames.Unicode.popDirectionalIsolate)
  case .IsolateOverride:
    if isEnteringBidi {
      paragraphContentBuilder.append(character: CharacterNames.Unicode.firstStrongIsolate)
      paragraphContentBuilder.append(
        character:
          isLTR
          ? CharacterNames.Unicode.leftToRightOverride : CharacterNames.Unicode.rightToLeftOverride)
    } else {
      paragraphContentBuilder.append(character: CharacterNames.Unicode.popDirectionalFormatting)
      paragraphContentBuilder.append(character: CharacterNames.Unicode.popDirectionalIsolate)
    }
  }

  if isEnteringBidi {
    bidiContextStack.append(
      BidiContext(
        unicodeBidi: unicodeBidi, isLeftToRightDirection: isLTR,
        isBlockLevel: enterExitType == .EnteringBlock))
  } else {
    bidiContextStack.removeLast()
  }
}

internal func unwindBidiContextStack(
  paragraphContentBuilder: StringBuilderWrapper, bidiContextStack: inout BidiContextStack,
  copyOfBidiStack: BidiContextStack, blockLevelBidiContextIndex: inout UInt64
) {
  if bidiContextStack.isEmpty {
    fatalError("Not reached")
  }
  // Unwind all the way up to the block entry.
  var unwindingIndex = bidiContextStack.count - 1
  while unwindingIndex != 0 && !copyOfBidiStack[unwindingIndex].isBlockLevel {
    handleEnterExitBidiContext(
      paragraphContentBuilder: paragraphContentBuilder,
      unicodeBidi: copyOfBidiStack[unwindingIndex].unicodeBidi,
      isLTR: copyOfBidiStack[unwindingIndex].isLeftToRightDirection,
      enterExitType: .ExitingInlineBox, bidiContextStack: &bidiContextStack)
    unwindingIndex -= 1
  }
  blockLevelBidiContextIndex = UInt64(unwindingIndex)
  // and unwind the block entries as well.
  while true {
    assert(copyOfBidiStack[unwindingIndex].isBlockLevel)
    handleEnterExitBidiContext(
      paragraphContentBuilder: paragraphContentBuilder,
      unicodeBidi: copyOfBidiStack[unwindingIndex].unicodeBidi,
      isLTR: copyOfBidiStack[unwindingIndex].isLeftToRightDirection,
      enterExitType: .ExitingBlock, bidiContextStack: &bidiContextStack)
    if unwindingIndex == 0 {
      break
    }
    unwindingIndex -= 1
  }
}

internal func rewindBidiContextStack(
  paragraphContentBuilder: StringBuilderWrapper, bidiContextStack: inout BidiContextStack,
  copyOfBidiStack: BidiContextStack, blockLevelBidiContextIndex: UInt64
) {
  if copyOfBidiStack.isEmpty {
    fatalError("Not reached")
  }

  for blockLevelIndex in 0...Int(blockLevelBidiContextIndex) {
    handleEnterExitBidiContext(
      paragraphContentBuilder: paragraphContentBuilder,
      unicodeBidi: copyOfBidiStack[blockLevelIndex].unicodeBidi,
      isLTR: copyOfBidiStack[blockLevelIndex].isLeftToRightDirection,
      enterExitType: .EnteringBlock, bidiContextStack: &bidiContextStack)
  }

  for inlineLevelIndex in Int(blockLevelBidiContextIndex + 1)..<copyOfBidiStack.count {
    handleEnterExitBidiContext(
      paragraphContentBuilder: paragraphContentBuilder,
      unicodeBidi: copyOfBidiStack[inlineLevelIndex].unicodeBidi,
      isLTR: copyOfBidiStack[inlineLevelIndex].isLeftToRightDirection,
      enterExitType: .EnteringInlineBox, bidiContextStack: &bidiContextStack)
  }
}

typealias InlineItemOffsetList = [UInt64?]

internal func handleBidiParagraphStart(
  paragraphContentBuilder: StringBuilderWrapper, bidiContextStack: inout BidiContextStack,
  inlineItemOffsetList: inout InlineItemOffsetList
) {
  // Bidi handling requires us to close all the nested bidi contexts at the end of the line triggered by forced line breaks
  // and re-open it for the content on the next line (i.e. paragraph handling).
  let copyOfBidiStack = bidiContextStack

  var blockLevelBidiContextIndex: UInt64 = 0
  unwindBidiContextStack(
    paragraphContentBuilder: paragraphContentBuilder, bidiContextStack: &bidiContextStack,
    copyOfBidiStack: copyOfBidiStack, blockLevelBidiContextIndex: &blockLevelBidiContextIndex)

  inlineItemOffsetList.append(UInt64(paragraphContentBuilder.length()))
  paragraphContentBuilder.append(character: CharacterNames.Unicode.newlineCharacter)

  rewindBidiContextStack(
    paragraphContentBuilder: paragraphContentBuilder, bidiContextStack: &bidiContextStack,
    copyOfBidiStack: copyOfBidiStack, blockLevelBidiContextIndex: blockLevelBidiContextIndex)
}

func buildBidiParagraph(
  rootStyle: RenderStyleWrapper, inlineItemList: InlineItemList,
  paragraphContentBuilder: StringBuilderWrapper,
  inlineItemOffsetList: inout InlineItemOffsetList
) {
  var bidiContextStack = BidiContextStack()
  handleEnterExitBidiContext(
    paragraphContentBuilder: paragraphContentBuilder, unicodeBidi: rootStyle.unicodeBidi(),
    isLTR: rootStyle.isLeftToRightDirection(), enterExitType: .EnteringBlock,
    bidiContextStack: &bidiContextStack)
  if rootStyle.rtlOrdering() != .Logical {
    handleEnterExitBidiContext(
      paragraphContentBuilder: paragraphContentBuilder, unicodeBidi: .Override,
      isLTR: rootStyle.isLeftToRightDirection(), enterExitType: .EnteringBlock,
      bidiContextStack: &bidiContextStack)
  }

  var lastInlineTextBox: BoxWrapper? = nil
  var inlineTextBoxOffset: UInt32 = 0
  for inlineItem in inlineItemList {
    let layoutBox = inlineItem.layoutBox

    if inlineItem.isText() || inlineItem.isSoftLineBreak() {
      let inlineTextBox = layoutBox as? InlineTextBoxWrapper
      let mayAppendTextContentAsOneEntry =
        inlineTextBox != nil && !TextUtil.shouldPreserveNewline(layoutBox: inlineTextBox!)
      if mayAppendTextContentAsOneEntry {
        // Append the entire InlineTextBox content and keep track of individual inline item positions as we process them.
        if lastInlineTextBox?.p != layoutBox.p {
          inlineTextBoxOffset = paragraphContentBuilder.length()
          replaceNonPreservedNewLineAndTabCharactersAndAppend(
            inlineTextBox: inlineTextBox!, paragraphContentBuilder: paragraphContentBuilder)
          lastInlineTextBox = layoutBox
        }
        let inlineTextItem = inlineItem as? InlineTextItemWrapper
        inlineItemOffsetList.append(
          UInt64(
            inlineTextBoxOffset
              + (inlineTextItem != nil
                ? inlineTextItem!.start()
                : (inlineItem as! InlineSoftLineBreakItemWrapper).position())))
      } else if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
        inlineItemOffsetList.append(UInt64(paragraphContentBuilder.length()))
        paragraphContentBuilder.append(
          string: StringWrapperView(s: inlineTextItem.inlineTextBox().content).substring(
            start: inlineTextItem.start(), length: inlineTextItem.length))
      } else if inlineItem is InlineSoftLineBreakItemWrapper {
        handleBidiParagraphStart(
          paragraphContentBuilder: paragraphContentBuilder,
          bidiContextStack: &bidiContextStack,
          inlineItemOffsetList: &inlineItemOffsetList)
      } else {
        fatalError("Not reached")
      }
    } else if inlineItem.isAtomicInlineBox() {
      inlineItemOffsetList.append(UInt64(paragraphContentBuilder.length()))
      paragraphContentBuilder.append(character: CharacterNames.Unicode.objectReplacementCharacter)
    } else if inlineItem.isInlineBoxStart() || inlineItem.isInlineBoxEnd() {
      // https://drafts.csswg.org/css-writing-modes/#unicode-bidi
      let style = inlineItem.style()
      let initiatesControlCharacter =
        style.rtlOrdering() == .Logical && style.unicodeBidi() != .Normal
      if !initiatesControlCharacter {
        // Opaque items do not have position in the bidi paragraph. They inherit their bidi level from the next inline item.
        inlineItemOffsetList.append(nil)
        continue
      }
      inlineItemOffsetList.append(UInt64(paragraphContentBuilder.length()))
      let isEnteringBidi = inlineItem.isInlineBoxStart()
      handleEnterExitBidiContext(
        paragraphContentBuilder: paragraphContentBuilder,
        unicodeBidi: style.unicodeBidi(),
        isLTR: style.isLeftToRightDirection(),
        enterExitType: isEnteringBidi ? .EnteringInlineBox : .ExitingInlineBox,
        bidiContextStack: &bidiContextStack)
    } else if inlineItem.isHardLineBreak() {
      handleBidiParagraphStart(
        paragraphContentBuilder: paragraphContentBuilder,
        bidiContextStack: &bidiContextStack,
        inlineItemOffsetList: &inlineItemOffsetList)
    } else if inlineItem.isWordBreakOpportunity() {
      // Soft wrap opportunity markers are opaque to bidi.
      inlineItemOffsetList.append(nil)
    } else if inlineItem.isFloat() {
      // Floats are not part of the inline content which make them opaque to bidi.
      inlineItemOffsetList.append(nil)
    } else if inlineItem.isOpaque() {
      if inlineItem.layoutBox.isOutOfFlowPositioned() {
        // Out of flow boxes participate in inflow layout as if they were static positioned.
        inlineItemOffsetList.append(UInt64(paragraphContentBuilder.length()))
        paragraphContentBuilder.append(character: CharacterNames.Unicode.objectReplacementCharacter)
      } else {
        // truly opaque items are also opaque to bidi.
        inlineItemOffsetList.append(nil)
      }
    } else {
      fatalError("Not implemented yet")
    }
  }
}

func canCacheMeasuredWidthOnInlineTextItem(inlineTextBox: InlineTextBoxWrapper, isWhitespace: Bool)
  -> Bool
{
  // Do not cache when:
  // 1. first-line style's unique font properties may produce non-matching width values.
  // 2. position dependent content is present (preserved tab character atm).
  if inlineTextBox.style.p != inlineTextBox.firstLineStyle().p
    && inlineTextBox.style.fontCascade().p != inlineTextBox.firstLineStyle().fontCascade().p
  {
    return false
  }
  if !isWhitespace || !TextUtil.shouldPreserveSpacesAndTabs(layoutBox: inlineTextBox) {
    return true
  }
  return !inlineTextBox.hasPositionDependentContentWidth()
}

struct InlineItemsBuilder {
  init(
    inlineContentCache: InlineContentCache, root: ElementBoxWrapper,
    securityOrigin: SecurityOriginWrapper
  ) {
    self.inlineContentCache = inlineContentCache
    self.root = root
  }

  mutating func build(startPosition: InlineItemPosition) {
    var inlineItemList = collectInlineItems(startPosition: startPosition)

    if !root.style.isLeftToRightDirection() || contentRequiresVisualReordering {
      // FIXME: Add support for partial, yet paragraph level bidi content handling.
      breakAndComputeBidiLevels(inlineItemList: &inlineItemList)
    }
    InlineItemsBuilder.computeInlineTextItemWidths(inlineItemList: inlineItemList)

    let contentAttributes = InlineContentCache.InlineItems.ContentAttributes(
      requiresVisualReordering: contentRequiresVisualReordering,
      hasTextAndLineBreakOnlyContent: isTextAndForcedLineBreakOnlyContent,
      inlineBoxCount: inlineBoxCount)
    let inlineItemCache = inlineContentCache.inlineItems
    if !startPosition.bool() {
      inlineItemCache.set(inlineItemList: inlineItemList, contentAttributes: contentAttributes)
      return
    }
    // Let's first remove the dirty inline items if there are any.
    if startPosition.index >= inlineItemCache.content().count {
      fatalError("Not reached")
    }
    inlineItemCache.replace(
      insertionPosition: startPosition.index, inlineItemList: inlineItemList,
      contentAttributes: contentAttributes)
  }

  private func breakAndComputeBidiLevels(inlineItemList: inout InlineItemList) {
    assert(!inlineItemList.isEmpty)

    let paragraphContentBuilder = StringBuilderWrapper()
    var inlineItemOffsets = InlineItemOffsetList()
    buildBidiParagraph(
      rootStyle: root.style, inlineItemList: inlineItemList,
      paragraphContentBuilder: paragraphContentBuilder, inlineItemOffsetList: &inlineItemOffsets)
    if paragraphContentBuilder.isEmpty() {
      // Style may trigger visual reordering even on a completely empty content.
      // e.g. <div><span style="direction:rtl"></span></div>
      // Let's not try to do bidi handling when there's no content to reorder.
      return
    }
    let mayNotUseBlockDirection = root.style.unicodeBidi() == .Plaintext
    if !contentRequiresVisualReordering && mayNotUseBlockDirection
      && TextUtil.directionForTextContent(content: paragraphContentBuilder.view()) == .LTR
    {
      // UnicodeBidi::Plaintext makes directionality calculated without taking parent direction property into account.
      return
    }
    assert(inlineItemOffsets.count == inlineItemList.count)
    // 1. Setup the bidi boundary loop by calling ubidi_setPara with the paragraph text.
    // 2. Call ubidi_getLogicalRun to advance to the next bidi boundary until we hit the end of the content.
    // 3. Set the computed bidi level on the associated inline items. Split them as needed.
    let ubidi = ubidi_open()

    defer {
      ubidi_close(ubidi: ubidi)
    }

    var rootBidiLevel = UBiDiLevel.UBIDI_DEFAULT_LTR
    let useHeuristicBaseDirection = root.style.unicodeBidi() == .Plaintext
    if !useHeuristicBaseDirection {
      rootBidiLevel =
        root.style.isLeftToRightDirection() ? UBiDiLevel.UBIDI_LTR : UBiDiLevel.UBIDI_RTL
    }

    let bidiContent = paragraphContentBuilder.view().upconvertedCharacters()
    let bidiContentLength = paragraphContentBuilder.length()
    assert(bidiContentLength != 0)
    let error = ubidi_setPara(
      pBiDi: ubidi, text: bidiContent, length: bidiContentLength, paraLevel: rootBidiLevel)

    if U_FAILURE(errorCode: error) {
      fatalError("Not reached")
    }

    var inlineItemIndex: UInt64 = 0
    var hasSeenOpaqueItem = false
    var currentPosition: Int32 = 0
    while currentPosition < bidiContentLength {
      var bidiLevel = UBiDiLevel.UBIDI_LTR
      var endPosition = currentPosition
      ubidi_getLogicalRun(
        pBiDi: ubidi, logicalPosition: currentPosition, pLogicalLimit: &endPosition,
        pLevel: &bidiLevel)
      setBidiLevelOnRange(
        inlineItemList: &inlineItemList,
        inlineItemOffsets: &inlineItemOffsets,
        bidiEnd: UInt64(endPosition), bidiLevelForRange: bidiLevel,
        inlineItemIndex: &inlineItemIndex, hasSeenOpaqueItem: &hasSeenOpaqueItem)
      currentPosition = endPosition
    }
    setBidiLevelForOpaqueInlineItems(
      inlineItemList: inlineItemList, hasSeenOpaqueItem: hasSeenOpaqueItem)
  }

  private func setBidiLevelOnRange(
    inlineItemList: inout InlineItemList, inlineItemOffsets: inout InlineItemOffsetList,
    bidiEnd: UInt64,
    bidiLevelForRange: UBiDiLevel,
    inlineItemIndex: inout UInt64,
    hasSeenOpaqueItem: inout Bool
  ) {
    // We should always have inline item(s) associated with a bidi range.
    assert(inlineItemIndex < inlineItemOffsets.count)
    // Start of the range is always where we left off (bidi ranges do not have gaps).
    while inlineItemIndex < inlineItemOffsets.count {
      let offset = inlineItemOffsets[Int(inlineItemIndex)]
      let inlineItem = inlineItemList[Int(inlineItemIndex)]
      if offset == nil {
        // This is an opaque item. Let's post-process it.
        hasSeenOpaqueItem = true
        inlineItem.setBidiLevel(bidiLevel: bidiLevelForRange)
        inlineItemIndex += 1
        continue
      }
      if offset! >= bidiEnd {
        // This inline item is outside of the bidi range.
        break
      }
      inlineItem.setBidiLevel(bidiLevel: bidiLevelForRange)
      inlineItemIndex += 1
      if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
        // Check if this text item is on bidi boundary and needs splitting.
        let endPosition = offset! + UInt64(inlineTextItem.length)
        if endPosition > bidiEnd {
          inlineItemList.insert(
            inlineTextItem.split(leftSideLength: bidiEnd - offset!), at: Int(inlineItemIndex))
          // Right side is going to be processed at the next bidi range.
          inlineItemOffsets.insert(bidiEnd, at: Int(inlineItemIndex))
          break
        }
      }
    }
  }

  private func setBidiLevelForOpaqueInlineItems(
    inlineItemList: InlineItemList, hasSeenOpaqueItem: Bool
  ) {
    if !hasSeenOpaqueItem {
      return
    }
    // Let's not confuse ubidi with non-content entries.
    // Opaque runs are excluded from the visual list (ie. only empty inline boxes should be kept around as bidi content -to figure out their visual order).
    enum InlineBoxHasContent {
      case No
      case Yes
    }
    var inlineBoxContentFlagStack: [InlineBoxHasContent] = []
    for inlineItem in inlineItemList.reversed() {
      let style = inlineItem.style()
      let initiatesControlCharacter =
        style.rtlOrdering() == .Logical && style.unicodeBidi() != .Normal

      if inlineItem.isInlineBoxStart() {
        assert(!inlineBoxContentFlagStack.isEmpty)
        if inlineBoxContentFlagStack.removeLast() == .Yes {
          if !initiatesControlCharacter {
            inlineItem.setBidiLevel(bidiLevel: InlineItemWrapper.opaqueBidiLevel)
          }
        }
        continue
      }
      if inlineItem.isInlineBoxEnd() {
        inlineBoxContentFlagStack.append(.No)
        if !initiatesControlCharacter {
          inlineItem.setBidiLevel(bidiLevel: InlineItemWrapper.opaqueBidiLevel)
        }
        continue
      }
      if inlineItem.isWordBreakOpportunity() {
        inlineItem.setBidiLevel(bidiLevel: InlineItemWrapper.opaqueBidiLevel)
        continue
      }
      // Mark the inline box stack with "content yes", when we come across a content type of inline item.
      let inlineTextItem = inlineItem as? InlineTextItemWrapper
      if inlineTextItem == nil || !inlineTextItem!.isWhitespace()
        || TextUtil.shouldPreserveSpacesAndTabs(layoutBox: inlineTextItem!.layoutBox)
      {
        for i in 0..<inlineBoxContentFlagStack.count {
          inlineBoxContentFlagStack[i] = .Yes
        }
      }
    }
  }

  private static func computeInlineTextItemWidths(inlineItemList: InlineItemList) {
    for inlineItem in inlineItemList {
      let inlineTextItem = inlineItem as? InlineTextItemWrapper
      if inlineTextItem == nil {
        continue
      }

      let inlineTextBox = inlineTextItem!.inlineTextBox()
      let start = inlineTextItem!.start()
      let length = inlineTextItem!.length
      let needsMeasuring = length != 0 && !inlineTextItem!.isZeroWidthSpaceSeparator()
      if !needsMeasuring
        || !canCacheMeasuredWidthOnInlineTextItem(
          inlineTextBox: inlineTextBox, isWhitespace: inlineTextItem!.isWhitespace())
      {
        continue
      }
      inlineTextItem!.setWidth(
        width: TextUtil.width(
          inlineTextItem: inlineTextItem!, fontCascade: inlineTextItem!.style().fontCascade(),
          from: start, to: start + length, contentLogicalLeft: 0))
    }
  }

  private func partialContentOffset(
    inlineTextBox: InlineTextBoxWrapper, startPosition: InlineItemPosition
  )
    -> UInt64?
  {
    let inlineItemCache = inlineContentCache.inlineItems

    if !startPosition.bool() {
      return nil
    }
    let currentInlineItems = inlineItemCache.content()
    if startPosition.index >= currentInlineItems.count {
      fatalError("Not reached")
    }
    let damagedInlineItem = currentInlineItems[Int(startPosition.index)]
    if inlineTextBox !== damagedInlineItem.layoutBox {
      return nil
    }
    if let inlineTextItem = damagedInlineItem as? InlineTextItemWrapper {
      return UInt64(inlineTextItem.start())
    }
    if let inlineSoftLineBreakItem = damagedInlineItem as? InlineSoftLineBreakItemWrapper {
      return UInt64(inlineSoftLineBreakItem.position())
    }
    fatalError("Not reached")
  }

  private mutating func collectInlineItems(startPosition: InlineItemPosition) -> InlineItemList {
    // Traverse the tree and create inline items out of inline boxes and leaf nodes. This essentially turns the tree inline structure into a flat one.
    // <span>text<span></span><img></span> -> [InlineBoxStart][InlineLevelBox][InlineBoxStart][InlineBoxEnd][InlineLevelBox][InlineBoxEnd]
    var layoutQueue = initializeLayoutQueue(startPosition: startPosition)
    var inlineItemList: [InlineItemWrapper] = []

    while !layoutQueue.isEmpty {
      while true {
        let layoutBox = layoutQueue.last!
        let isInlineBoxWithInlineContent =
          layoutBox.isInlineBox() && !layoutBox.isInlineTextBox() && !layoutBox.isLineBreakBox()
          && !layoutBox.isOutOfFlowPositioned()
        if !isInlineBoxWithInlineContent {
          break
        }
        // This is the start of an inline box (e.g. <span>).
        handleInlineBoxStart(inlineBox: layoutBox, inlineItemList: &inlineItemList)
        let inlineBox = layoutBox as! ElementBoxWrapper
        if !inlineBox.hasChild() {
          break
        }
        layoutQueue.append(inlineBox.firstChild()!)
      }

      while !layoutQueue.isEmpty {
        let layoutBox = layoutQueue.removeLast()
        if layoutBox.isOutOfFlowPositioned() {
          isTextAndForcedLineBreakOnlyContent = false
          inlineItemList.append(
            InlineItemWrapper(layoutBox: layoutBox, type: InlineItemWrapper.Type_.Opaque))
        } else if let inlineTextBox = layoutBox as? InlineTextBoxWrapper {
          handleTextContent(
            inlineTextBox: inlineTextBox, inlineItemList: &inlineItemList,
            partialContentOffset: partialContentOffset(
              inlineTextBox: inlineTextBox, startPosition: startPosition))
        } else if layoutBox.isAtomicInlineBox() || layoutBox.isLineBreakBox() {
          handleInlineLevelBox(layoutBox: layoutBox, inlineItemList: &inlineItemList)
        } else if layoutBox.isInlineBox() {
          handleInlineBoxEnd(inlineBox: layoutBox, inlineItemList: &inlineItemList)
        } else if layoutBox.isFloatingPositioned() {
          inlineItemList.append(
            InlineItemWrapper(layoutBox: layoutBox, type: InlineItemWrapper.Type_.Float))
          isTextAndForcedLineBreakOnlyContent = false
        } else {
          fatalError("Not reached")
        }

        if let nextSibling = layoutBox.nextSibling() {
          layoutQueue.append(nextSibling)
          break
        }
      }
    }

    return inlineItemList
  }

  private typealias LayoutQueue = [BoxWrapper]

  private mutating func appendAndCheckForDamage(
    layoutBox: BoxWrapper, firstDamagedLayoutBox: BoxWrapper, queue: inout LayoutQueue
  ) -> Bool {
    queue.append(layoutBox)

    contentRequiresVisualReordering =
      contentRequiresVisualReordering
      || requiresVisualReordering(
        layoutBox: layoutBox)
    if !isTextOrLineBreak(layoutBox: layoutBox) {
      isTextAndForcedLineBreakOnlyContent = false
      if layoutBox.isInlineBox() {
        inlineBoxCount += 1
      }
    }
    return layoutBox.p == firstDamagedLayoutBox.p
  }

  private mutating func traverseUntilDamaged(firstDamagedLayoutBox: BoxWrapper) -> LayoutQueue {
    var queue = LayoutQueue()

    if appendAndCheckForDamage(
      layoutBox: root.firstChild()!, firstDamagedLayoutBox: firstDamagedLayoutBox, queue: &queue)
    {
      return queue
    }

    while !queue.isEmpty {
      while true {
        let layoutBox = queue.last!
        let isInlineBoxWithInlineContent =
          layoutBox.isInlineBox() && !layoutBox.isInlineTextBox() && !layoutBox.isLineBreakBox()
          && !layoutBox.isOutOfFlowPositioned()
        if !isInlineBoxWithInlineContent {
          break
        }
        if let firstChild = (layoutBox as! ElementBoxWrapper).firstChild() {
          if appendAndCheckForDamage(
            layoutBox: firstChild, firstDamagedLayoutBox: firstDamagedLayoutBox, queue: &queue)
          {
            return queue
          }
        } else {
          break
        }
      }

      while !queue.isEmpty {
        if let nextSibling = queue.removeLast().nextSibling() {
          if appendAndCheckForDamage(
            layoutBox: nextSibling, firstDamagedLayoutBox: firstDamagedLayoutBox, queue: &queue)
          {
            return queue
          }
          break
        }
      }
    }
    // How did we miss the damaged box?
    fatalError("Not reached")
  }

  private mutating func initializeLayoutQueue(startPosition: InlineItemPosition) -> LayoutQueue {
    if root.firstChild() == nil {
      // There should always be at least one inflow child in this inline formatting context.
      fatalError("Not reached")
    }

    if !startPosition.bool() {
      return [root.firstChild()!]
    }

    // For partial layout we need to build the layout queue up to the point where the new content is in order
    // to be able to produce non-content type of trailing inline items.
    // e.g <div><span<span>text</span></span> produces
    // [inline box start][inline box start][text][inline box end][inline box end]
    // and inserting new content after text
    // <div><span><span>text more_text</span></span> should produce
    // [inline box start][inline box start][text][ ][more_text][inline box end][inline box end]
    // where we start processing the content at the new layout box and continue with whatever we have on the stack (layout queue).
    let existingInlineItems = inlineContentCache.inlineItems.content()
    if startPosition.index >= existingInlineItems.count {
      fatalError("Not reached")
    }

    let firstDamagedLayoutBox = existingInlineItems[Int(startPosition.index)].layoutBox
    return traverseUntilDamaged(firstDamagedLayoutBox: firstDamagedLayoutBox)
  }

  private func handleSegmentBreak(
    text: StringWrapper, inlineTextBox: InlineTextBoxWrapper, shouldPreserveNewline: Bool,
    inlineItemList: inout InlineItemList,
    currentPosition: inout UInt64
  )
    -> Bool
  {
    // Segment breaks with preserve new line style (white-space: pre, pre-wrap, break-spaces and pre-line) compute to forced line break.
    let isSegmentBreakCandidate =
      text[UInt32(currentPosition)] == CharacterNames.Unicode.newlineCharacter
    if !isSegmentBreakCandidate || !shouldPreserveNewline {
      return false
    }
    inlineItemList.append(
      InlineSoftLineBreakItemWrapper.createSoftLineBreakItem(
        inlineTextBox: inlineTextBox, position: UInt32(currentPosition)))
    currentPosition += 1
    return true
  }

  private func handleWhitespace(
    inlineTextBox: InlineTextBoxWrapper, text: StringWrapper, style: RenderStyleWrapper,
    shouldPreserveSpacesAndTabs: Bool, shouldPreserveNewline: Bool,
    inlineItemList: inout InlineItemList, currentPosition: inout UInt64
  ) -> Bool {
    let stopAtWordSeparatorBoundary =
      shouldPreserveSpacesAndTabs && style.fontCascade().wordSpacing() > 0
    let whitespaceContent =
      text.is8Bit()
      ? moveToNextNonWhitespacePosition(
        characters: text.span8(), startPosition: currentPosition,
        preserveNewline: shouldPreserveNewline, preserveTab: shouldPreserveSpacesAndTabs,
        stopAtWordSeparatorBoundary: stopAtWordSeparatorBoundary)
      : moveToNextNonWhitespacePosition(
        characters: text.span16(), startPosition: currentPosition,
        preserveNewline: shouldPreserveNewline, preserveTab: shouldPreserveSpacesAndTabs,
        stopAtWordSeparatorBoundary: stopAtWordSeparatorBoundary)
    if whitespaceContent == nil {
      return false
    }

    assert(whitespaceContent!.length != 0)
    if style.whiteSpaceCollapse() == .BreakSpaces {
      // https://www.w3.org/TR/css-text-3/#white-space-phase-1
      // For break-spaces, a soft wrap opportunity exists after every space and every tab.
      // FIXME: if this turns out to be a perf hit with too many individual whitespace inline items, we should transition this logic to line breaking.
      for offset in 0..<whitespaceContent!.length {
        inlineItemList.append(
          InlineTextItemWrapper.createWhitespaceItem(
            inlineTextBox: inlineTextBox, start: UInt32(currentPosition + offset), length: 1,
            bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR,
            isWordSeparator: whitespaceContent!.isWordSeparator, width: nil))
      }
    } else {
      inlineItemList.append(
        InlineTextItemWrapper.createWhitespaceItem(
          inlineTextBox: inlineTextBox, start: UInt32(currentPosition),
          length: UInt32(whitespaceContent!.length),
          bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR,
          isWordSeparator: whitespaceContent!.isWordSeparator, width: nil))
    }
    currentPosition += whitespaceContent!.length
    return true
  }

  private func handleNonBreakingSpace(
    inlineTextBox: InlineTextBoxWrapper,
    text: StringWrapper, style: RenderStyleWrapper, contentLength: UInt32,
    inlineItemList: inout InlineItemList,
    currentPosition: inout UInt64
  ) -> Bool {
    if style.nbspMode() != .Space {
      // Let's just defer to regular non-whitespace inline items when non breaking space needs no special handling.
      return false
    }
    let startPosition = currentPosition
    var endPosition = startPosition
    while endPosition < contentLength {
      if text[UInt32(endPosition)] != CharacterNames.Unicode.noBreakSpace {
        break
      }
      endPosition += 1
    }
    if startPosition == endPosition {
      return false
    }
    for offset in 0..<endPosition - startPosition {
      inlineItemList.append(
        InlineTextItemWrapper.createNonWhitespaceItem(
          inlineTextBox: inlineTextBox, start: UInt32(startPosition + offset), length: 1,
          bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR, hasTrailingSoftHyphen: false, width: nil))
    }
    currentPosition = endPosition
    return true
  }

  private func handleNonWhitespace(
    inlineTextBox: InlineTextBoxWrapper,
    text: StringWrapper, contentLength: UInt32, style: RenderStyleWrapper,
    lineBreakIteratorFactory: inout CachedLineBreakIteratorFactoryWrapper,
    inlineItemList: inout InlineItemList,
    currentPosition: inout UInt64
  ) -> Bool {
    let startPosition = currentPosition
    var endPosition = startPosition
    var hasTrailingSoftHyphen = false
    if style.hyphens() == .None {
      // Let's merge candidate InlineTextItems separated by soft hyphen when the style says so.
      repeat {
        endPosition += UInt64(
          moveToNextBreakablePosition(
            startPosition: UInt32(endPosition), lineBreakIteratorFactory: &lineBreakIteratorFactory,
            style: style))
        assert(startPosition < endPosition)
      } while endPosition < contentLength
        && text[UInt32(endPosition - 1)] == CharacterNames.Unicode.softHyphen
    } else {
      endPosition += UInt64(
        moveToNextBreakablePosition(
          startPosition: UInt32(startPosition), lineBreakIteratorFactory: &lineBreakIteratorFactory,
          style: style))
      assert(startPosition < endPosition)
      hasTrailingSoftHyphen = text[UInt32(endPosition - 1)] == CharacterNames.Unicode.softHyphen
    }
    assert(style.hyphens() != .None || !hasTrailingSoftHyphen)
    inlineItemList.append(
      InlineTextItemWrapper.createNonWhitespaceItem(
        inlineTextBox: inlineTextBox, start: UInt32(startPosition),
        length: UInt32(endPosition - startPosition),
        bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR, hasTrailingSoftHyphen: hasTrailingSoftHyphen,
        width: nil))
    currentPosition = endPosition
    return true
  }

  private mutating func handleTextContent(
    inlineTextBox: InlineTextBoxWrapper,
    inlineItemList: inout InlineItemList,
    partialContentOffset: UInt64?
  ) {
    let text = inlineTextBox.content
    let contentLength = text.length()
    if contentLength == 0 {
      return inlineItemList.append(
        InlineTextItemWrapper.createEmptyItem(inlineTextBox: inlineTextBox))
    }

    contentRequiresVisualReordering =
      contentRequiresVisualReordering || requiresVisualReordering(layoutBox: inlineTextBox)

    if inlineTextBox.isCombined {
      return inlineItemList.append(
        InlineTextItemWrapper.createNonWhitespaceItem(
          inlineTextBox: inlineTextBox, start: 0, length: contentLength,
          bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR, hasTrailingSoftHyphen: false, width: nil))
    }

    if partialContentOffset != nil
      && buildInlineItemListForTextFromBreakingPositionsCache(
        inlineTextBox: inlineTextBox, inlineItemList: &inlineItemList)
    {
      return
    }

    let style = inlineTextBox.style
    let shouldPreserveSpacesAndTabs = TextUtil.shouldPreserveSpacesAndTabs(layoutBox: inlineTextBox)
    let shouldPreserveNewline = TextUtil.shouldPreserveNewline(layoutBox: inlineTextBox)
    var lineBreakIteratorFactory = CachedLineBreakIteratorFactoryWrapper(
      stringView: StringWrapperView(s: text), locale: style.computedLocale(),
      mode: TextUtil.lineBreakIteratorMode(lineBreak: style.lineBreak()),
      contentAnalysis: TextUtil.contentAnalysis(wordBreak: style.wordBreak()))
    var currentPosition = partialContentOffset ?? 0
    assert(currentPosition <= contentLength)

    while currentPosition < contentLength {
      if handleSegmentBreak(
        text: text, inlineTextBox: inlineTextBox, shouldPreserveNewline: shouldPreserveNewline,
        inlineItemList: &inlineItemList,
        currentPosition: &currentPosition)
      {
        continue
      }

      if handleWhitespace(
        inlineTextBox: inlineTextBox, text: text, style: style,
        shouldPreserveSpacesAndTabs: shouldPreserveSpacesAndTabs,
        shouldPreserveNewline: shouldPreserveNewline, inlineItemList: &inlineItemList,
        currentPosition: &currentPosition)
      {
        continue
      }

      if handleNonBreakingSpace(
        inlineTextBox: inlineTextBox,
        text: text, style: style, contentLength: contentLength, inlineItemList: &inlineItemList,
        currentPosition: &currentPosition)
      {
        continue
      }

      if handleNonWhitespace(
        inlineTextBox: inlineTextBox,
        text: text, contentLength: contentLength, style: style,
        lineBreakIteratorFactory: &lineBreakIteratorFactory, inlineItemList: &inlineItemList,
        currentPosition: &currentPosition)
      {
        continue
      }
      // Unsupported content?
      fatalError("Not reached")
    }
  }

  private func buildInlineItemListForTextFromBreakingPositionsCache(
    inlineTextBox: InlineTextBoxWrapper, inlineItemList: inout InlineItemList
  ) -> Bool {
    let text = inlineTextBox.content
    let breakingPositions = TextBreakingPositionCache.singleton().get(
      key: TextBreakingPositionCache.Key(
        text: text, TextBreakingPositionContext(style: inlineTextBox.style),
        securityOrigin: securityOrigin.data))
    if breakingPositions == nil {
      return false
    }

    let shouldPreserveNewline = TextUtil.shouldPreserveNewline(layoutBox: inlineTextBox)
    let shouldPreserveSpacesAndTabs = TextUtil.shouldPreserveSpacesAndTabs(layoutBox: inlineTextBox)

    let contentLength = text.length()
    assert(contentLength != 0)
    var previousPosition: UInt64 = 0
    for endPosition in breakingPositions! {
      let startPosition = previousPosition
      previousPosition = endPosition
      if endPosition > contentLength || startPosition >= endPosition {
        fatalError("Not reached")
      }

      let character = text[UInt32(startPosition)]
      if character == CharacterNames.Unicode.newlineCharacter && shouldPreserveNewline {
        inlineItemList.append(
          InlineSoftLineBreakItemWrapper.createSoftLineBreakItem(
            inlineTextBox: inlineTextBox, position: UInt32(startPosition)))
        continue
      }

      let isWhitespaceCharacter =
        character == CharacterNames.Unicode.space
        || character == CharacterNames.Unicode.newlineCharacter
        || character == CharacterNames.Unicode.tabCharacter
      if isWhitespaceCharacter {
        let isWordSeparator =
          character != CharacterNames.Unicode.tabCharacter || !shouldPreserveSpacesAndTabs
        inlineItemList.append(
          InlineTextItemWrapper.createWhitespaceItem(
            inlineTextBox: inlineTextBox, start: UInt32(startPosition),
            length: UInt32(endPosition - startPosition),
            bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR, isWordSeparator: isWordSeparator, width: nil))
        continue
      }

      assert(endPosition != 0)
      let hasTrailingSoftHyphen = text[UInt32(endPosition - 1)] == CharacterNames.Unicode.softHyphen
      inlineItemList.append(
        InlineTextItemWrapper.createNonWhitespaceItem(
          inlineTextBox: inlineTextBox, start: UInt32(startPosition),
          length: UInt32(endPosition - startPosition),
          bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR, hasTrailingSoftHyphen: hasTrailingSoftHyphen,
          width: nil))
    }
    return true
  }

  private mutating func handleInlineBoxStart(
    inlineBox: BoxWrapper, inlineItemList: inout InlineItemList
  ) {
    inlineItemList.append(
      InlineItemWrapper(layoutBox: inlineBox, type: InlineItemWrapper.Type_.InlineBoxStart))
    contentRequiresVisualReordering =
      contentRequiresVisualReordering || requiresVisualReordering(layoutBox: inlineBox)
    inlineBoxCount += 1
  }

  private func handleInlineBoxEnd(inlineBox: BoxWrapper, inlineItemList: inout InlineItemList) {
    inlineItemList.append(
      InlineItemWrapper(layoutBox: inlineBox, type: InlineItemWrapper.Type_.InlineBoxEnd))
    // Inline box end item itself can not trigger bidi content.
    assert(inlineBoxCount != 0)
    assert(
      contentRequiresVisualReordering || inlineBox.style.isLeftToRightDirection()
        || inlineBox.style.rtlOrdering() == .Visual || inlineBox.style.unicodeBidi() == .Normal)
  }

  private mutating func handleInlineLevelBox(
    layoutBox: BoxWrapper, inlineItemList: inout InlineItemList
  ) {
    if layoutBox.isRubyAnnotationBox() {
      return inlineItemList.append(InlineItemWrapper(layoutBox: layoutBox, type: .Opaque))
    }

    if layoutBox.isAtomicInlineBox() {
      isTextAndForcedLineBreakOnlyContent = false
      return inlineItemList.append(InlineItemWrapper(layoutBox: layoutBox, type: .AtomicInlineBox))
    }

    if layoutBox.isLineBreakBox() {
      isTextAndForcedLineBreakOnlyContent =
        isTextAndForcedLineBreakOnlyContent && isTextOrLineBreak(layoutBox: layoutBox)
      return inlineItemList.append(
        InlineItemWrapper(
          layoutBox: layoutBox,
          type: layoutBox.isWordBreakOpportunity() ? .WordBreakOpportunity : .HardLineBreak
        ))
    }

    fatalError("Not reached")
  }

  private static func inlineTextBoxContentSpan(
    inlineItemList: InlineItemList, index: UInt64, inlineTextBox: InlineTextBoxWrapper
  ) -> ArraySlice<InlineItemWrapper> {
    var length: UInt64 = 0
    for item in inlineItemList[Int(index)...] {
      if item.layoutBox.p != inlineTextBox.p {
        break
      }
      length += 1
    }
    return inlineItemList[Int(index)..<Int(index + length)]
  }

  func populateBreakingPositionCache(inlineItemList: InlineItemList, document: Document) {
    if inlineItemList.count < TextBreakingPositionCache.minimumRequiredContentBreaks {
      return
    }

    // Preserve breaking positions across content mutation.
    let securityOrigin = document.securityOrigin()
    let breakingPositionCache = TextBreakingPositionCache.singleton()
    var index = 0
    while index < inlineItemList.count {
      let inlineTextBox = inlineItemList[index].layoutBox as? InlineTextBoxWrapper
      if inlineTextBox == nil {
        index += 1
        continue
      }

      let span = InlineItemsBuilder.inlineTextBoxContentSpan(
        inlineItemList: inlineItemList, index: UInt64(index), inlineTextBox: inlineTextBox!)
      if span.count < TextBreakingPositionCache.minimumRequiredContentBreaks {
        // Inline text box content's span is too short.
        index += span.count
        continue
      }

      let isInlineTextBoxEligibleForBreakingPositionCache =
        Int(inlineTextBox!.content.length())
        >= TextBreakingPositionCache.minimumRequiredContentBreaks
      if !isInlineTextBoxEligibleForBreakingPositionCache {
        // Text is too short.
        index += span.count
        continue
      }

      let context = TextBreakingPositionContext(style: inlineTextBox!.style)
      if breakingPositionCache.get(key: (inlineTextBox!.content, context, securityOrigin.data))
        != nil
      {
        // Cache is already populated.
        index += span.count
        continue
      }

      var breakingPositionList = TextBreakingPositionCache.List()
      for inlineItem in span {
        if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
          breakingPositionList.append(UInt64(inlineTextItem.end()))
        } else if let softLineBreakItem = inlineItem as? InlineSoftLineBreakItemWrapper {
          breakingPositionList.append(UInt64(softLineBreakItem.position() + 1))
        } else {
          fatalError("Not reached")
        }
      }

      assert(!breakingPositionList.isEmpty)
      if breakingPositionList.count >= TextBreakingPositionCache.minimumRequiredContentBreaks {
        breakingPositionCache.set(
          key: (inlineTextBox!.content, context, securityOrigin.data),
          breakingPositionList: breakingPositionList)
      }
      index += span.count
    }
  }

  private var inlineContentCache: InlineContentCache
  private var root: ElementBoxWrapper
  private var securityOrigin = SecurityOriginWrapper(p: nil)

  private var contentRequiresVisualReordering = false
  private var isTextAndForcedLineBreakOnlyContent = true
  private var inlineBoxCount: UInt64 = 0
}
