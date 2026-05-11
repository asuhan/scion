/*
 * Copyright (C) 2018-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

import wk_interop

func spaceWidth(fontCascade: FontCascadeWrapper, canUseSimplifiedContentMeasuring: Bool)
  -> InlineLayoutUnit
{
  if canUseSimplifiedContentMeasuring {
    return fontCascade.primaryFontSpaceWidth()
  }
  return fontCascade.widthOfSpaceString()
}

func fallbackFontsForRunWithIterator(
  fallbackFonts: inout Set<UInt>, fontCascade: FontCascadeWrapper, run: TextRunWrapper,
  textIterator: inout TextIterator
) {
  let isRTL = run.rtl()
  let isSmallCaps = fontCascade.isSmallCaps()
  let primaryFont = fontCascade.primaryFont()

  var currentCharacter: UInt32 = 0
  var clusterLength: UInt32 = 0
  while textIterator.consume(character: &currentCharacter, clusterLength: &clusterLength) {
    addFallbackFontForCharacterIfApplicable(
      characterIn: Int32(currentCharacter), fontCascade: fontCascade, primaryFont: primaryFont,
      isSmallCaps: isSmallCaps, isRTL: isRTL, fallbackFonts: &fallbackFonts)
    textIterator.advance(advanceLength: clusterLength)
  }
}

func addFallbackFontForCharacterIfApplicable(
  characterIn: Int32, fontCascade: FontCascadeWrapper, primaryFont: FontWrapper, isSmallCaps: Bool,
  isRTL: Bool, fallbackFonts: inout Set<UInt>
) {
  var character = characterIn
  if isSmallCaps {
    character = u_toupper(c: character)
  }

  let glyphData = fontCascade.glyphDataForCharacter(c: UInt32(character), mirror: isRTL)
  if glyphData.glyph != 0 && glyphData.font != nil
    && CPtrToInt(glyphData.font!.p) != CPtrToInt(primaryFont.p)
  {
    let isNonSpacingMark =
      (UCharMasks.U_MASK(x: UInt32(u_charType(c: Int32(character)))) & UCharMasks.U_GC_MN_MASK) != 0

    // https://drafts.csswg.org/css-text-3/#white-space-processing
    // "Unsupported Default_ignorable characters must be ignored for text rendering."
    let isIgnored = isDefaultIgnorableCodePoint(character: UInt32(character))

    // If we include the synthetic bold expansion, then even zero-width glyphs will have their fonts added.
    if isNonSpacingMark
      || glyphData.font!.widthForGlyph(glyph: glyphData.glyph, syntheticBoldInclusion: .Exclude)
        != 0
    {
      if !isIgnored {
        fallbackFonts.update(with: UInt(CPtrToInt(glyphData.font!.p)))
      }
    }
  }
}

class TextUtil {
  enum UseTrailingWhitespaceMeasuringOptimization {
    case No
    case Yes
  }

  static func width(
    inlineTextItem: InlineTextItemWrapper, fontCascade: FontCascadeWrapper,
    contentLogicalLeft: InlineLayoutUnit
  ) -> InlineLayoutUnit {
    return width(
      inlineTextItem: inlineTextItem, fontCascade: fontCascade, from: inlineTextItem.start(),
      to: inlineTextItem.end(), contentLogicalLeft: contentLogicalLeft)
  }

  static func width(
    inlineTextItem: InlineTextItemWrapper, fontCascade: FontCascadeWrapper, from: UInt32,
    to: UInt32,
    contentLogicalLeft: InlineLayoutUnit,
    useTrailingWhitespaceMeasuringOptimization: UseTrailingWhitespaceMeasuringOptimization = .Yes
  )
    -> InlineLayoutUnit
  {
    assert(from >= inlineTextItem.start())
    assert(to <= inlineTextItem.end())

    if inlineTextItem.isWhitespace() {
      let inlineTextBox = inlineTextItem.inlineTextBox()
      let useSimplifiedContentMeasuring = inlineTextBox.canUseSimplifiedContentMeasuring()
      let length = from &- to  // FIXME(asuhan): shouldn't this be to - from, actually?
      let singleWhiteSpace = length == 1 || !shouldPreserveSpacesAndTabs(layoutBox: inlineTextBox)

      if singleWhiteSpace {
        let width = spaceWidth(
          fontCascade: fontCascade, canUseSimplifiedContentMeasuring: useSimplifiedContentMeasuring)
        if width.isNaN || width.isInfinite {
          return width.isNaN ? 0 : maxInlineLayoutUnit()
        }
        return max(0, width)
      }
    }
    return width(
      inlineTextBox: inlineTextItem.inlineTextBox(), fontCascade: fontCascade, from: from, toIn: to,
      contentLogicalLeft: contentLogicalLeft,
      useTrailingWhitespaceMeasuringOptimization: useTrailingWhitespaceMeasuringOptimization)
  }

  static func width(
    inlineTextBox: InlineTextBoxWrapper, fontCascade: FontCascadeWrapper, from: UInt32,
    toIn: UInt32,
    contentLogicalLeft: InlineLayoutUnit,
    useTrailingWhitespaceMeasuringOptimization: UseTrailingWhitespaceMeasuringOptimization = .Yes,
    spacingStatePtr: UnsafeRawPointer? = nil
  ) -> InlineLayoutUnit {
    var to = toIn

    if from == to {
      return 0
    }

    if inlineTextBox.isCombined {
      return fontCascade.size()
    }

    let text = inlineTextBox.content
    assert(to <= text.length())
    let hasKerningOrLigatures = fontCascade.enableKerning() || fontCascade.requiresShaping()
    // The "non-whitespace" + "whitespace" pattern is very common for inline
    // content and since most of the "non-whitespace" runs end up with their
    // "whitespace" pair on the line (notable exception is when trailing
    // whitespace is trimmed). Including the trailing whitespace here
    // enables us to cut the number of text measures when placing content on
    // the line.
    let extendedMeasuring =
      useTrailingWhitespaceMeasuringOptimization == .Yes && hasKerningOrLigatures
      && to < text.length() && text[to] == CharacterNames.Unicode.space
    if extendedMeasuring {
      to += 1
    }
    var width = Float32(0)
    let useSimplifiedContentMeasuring = inlineTextBox.canUseSimplifiedContentMeasuring()
    if useSimplifiedContentMeasuring {
      let view = StringWrapperView(s: text).substring(start: from, length: to - from)
      if fontCascade.canTakeFixedPitchFastContentMeasuring() {
        width = fontCascade.widthForSimpleTextWithFixedPitch(
          text: view, whitespaceIsCollapsed: inlineTextBox.style.collapseWhiteSpace())
      } else {
        width = fontCascade.widthForTextUsingSimplifiedMeasuring(text: view)
      }
    } else {
      let style = inlineTextBox.style
      let directionalOverride = style.unicodeBidi() == .Override
      let run = TextRunWrapper(
        stringView: StringWrapperView(s: text).substring(start: from, length: to - from),
        xpos: contentLogicalLeft,
        expansion: 0,
        expansionBehavior: ExpansionBehaviorWrapper.defaultBehavior(),
        direction: directionalOverride ? style.direction() : .LTR,
        directionalOverride: directionalOverride)
      if !style.collapseWhiteSpace() && style.tabSize().bool() {
        run.setTabSize(allow: true, size: style.tabSize())
      }
      // FIXME: consider moving this to TextRun ctor
      run.setTextSpacingState(spacingStatePtr: spacingStatePtr)
      width = fontCascade.width(run: run)
    }

    if extendedMeasuring {
      width -=
        (spaceWidth(
          fontCascade: fontCascade, canUseSimplifiedContentMeasuring: useSimplifiedContentMeasuring)
          + fontCascade.wordSpacing())
    }

    if width.isNaN || width.isInfinite {
      return width.isNaN ? 0 : maxInlineLayoutUnit()
    }
    return max(Float32(0), width)
  }

  static func trailingWhitespaceWidth(
    inlineTextBox: InlineTextBoxWrapper, fontCascade: FontCascadeWrapper, startPosition: UInt32,
    endPosition: UInt32
  ) -> InlineLayoutUnit {
    let text = inlineTextBox.content
    assert(endPosition > startPosition + 1)
    assert(text[endPosition - 1] == CharacterNames.Unicode.space)
    return width(
      inlineTextBox: inlineTextBox, fontCascade: fontCascade, from: startPosition,
      toIn: endPosition, contentLogicalLeft: 0, useTrailingWhitespaceMeasuringOptimization: .Yes)
      - width(
        inlineTextBox: inlineTextBox, fontCascade: fontCascade, from: startPosition,
        toIn: endPosition - 1, contentLogicalLeft: 0,
        useTrailingWhitespaceMeasuringOptimization: .No)
  }

  typealias FallbackFontList = Set<UInt>
  enum IncludeHyphen: UInt8 {
    case No
    case Yes
  }
  static func fallbackFontsForText(
    textContent: StringWrapperView, style: RenderStyleWrapper, includeHyphen: IncludeHyphen
  ) -> FallbackFontList {
    var fallbackFonts = FallbackFontList()
    if includeHyphen == .Yes {
      collectFallbackFonts(
        textRun: TextRunWrapper(
          stringView: StringWrapperView(s: style.hyphenString().string()),
          xpos: 0,
          expansion: 0,
          expansionBehavior: ExpansionBehaviorWrapper.defaultBehavior(),
          direction: style.direction()),
        style: style, fallbackFonts: &fallbackFonts)
    }
    collectFallbackFonts(
      textRun: TextRunWrapper(
        stringView: textContent,
        xpos: 0,
        expansion: 0,
        expansionBehavior: ExpansionBehaviorWrapper.defaultBehavior(),
        direction: style.direction()), style: style, fallbackFonts: &fallbackFonts)
    return fallbackFonts
  }

  private static func collectFallbackFonts(
    textRun: TextRunWrapper, style: RenderStyleWrapper, fallbackFonts: inout FallbackFontList
  ) {
    if textRun.text().isEmpty() {
      return
    }

    if textRun.is8Bit() {
      var textIterator: any TextIterator = Latin1TextIterator(
        characters: textRun.span8(), currentIndex: 0, lastIndex: textRun.length())
      fallbackFontsForRunWithIterator(
        fallbackFonts: &fallbackFonts, fontCascade: style.fontCascade(), run: textRun,
        textIterator: &textIterator)
      return
    }
    var textIterator: any TextIterator = SurrogatePairAwareTextIterator(
      characters: textRun.span16(), currentIndex: 0, lastIndex: textRun.length())
    fallbackFontsForRunWithIterator(
      fallbackFonts: &fallbackFonts, fontCascade: style.fontCascade(), run: textRun,
      textIterator: &textIterator)
  }

  struct EnclosingAscentDescent {
    var ascent = InlineLayoutUnit()
    var descent = InlineLayoutUnit()
  }

  static func enclosingGlyphBoundsForText(textContent: StringWrapperView, style: RenderStyleWrapper)
    -> EnclosingAscentDescent
  {
    let raw = wk_interop.TextUtil_enclosingGlyphBoundsForText(textContent.p, style.p!)
    return EnclosingAscentDescent(
      ascent: raw.ascent, descent: raw.descent)
  }

  struct WordBreakLeft {
    var length: UInt64 = 0
    var logicalWidth = InlineLayoutUnit()
  }

  static func breakWord(
    inlineTextBox: InlineTextBoxWrapper, startPosition: UInt64, length: UInt64,
    textWidth: InlineLayoutUnit, availableWidth: InlineLayoutUnit,
    contentLogicalLeft: InlineLayoutUnit, fontCascade: FontCascadeWrapper
  ) -> WordBreakLeft {
    let raw = wk_interop.TextUtil_breakWord(
      inlineTextBox.p!, startPosition, length, textWidth, availableWidth, contentLogicalLeft,
      fontCascade.p!)
    return WordBreakLeft(length: raw.length, logicalWidth: raw.logicalWidth)
  }

  static func breakWord(
    inlineTextItem: InlineTextItemWrapper, fontCascade: FontCascadeWrapper,
    textWidth: InlineLayoutUnit, availableWidth: InlineLayoutUnit,
    contentLogicalLeft: InlineLayoutUnit
  ) -> WordBreakLeft {
    return breakWord(
      inlineTextBox: inlineTextItem.inlineTextBox(), startPosition: UInt64(inlineTextItem.start()),
      length: UInt64(inlineTextItem.length), textWidth: textWidth,
      availableWidth: availableWidth, contentLogicalLeft: contentLogicalLeft,
      fontCascade: fontCascade)
  }

  static func mayBreakInBetween(
    previousInlineItem: InlineTextItemWrapper, nextInlineItem: InlineTextItemWrapper
  ) -> Bool {
    // Check if these 2 adjacent non-whitespace inline items are connected at a breakable position.
    assert(!previousInlineItem.isWhitespace() && !nextInlineItem.isWhitespace())

    let previousContent = previousInlineItem.inlineTextBox().content
    let nextContent = nextInlineItem.inlineTextBox().content
    // Now we need to collect at least 3 adjacent characters to be able to make a decision whether the previous text item ends with breaking opportunity.
    // [ex-][ample] <- second to last[x] last[-] current[a]
    // We need at least 1 character in the current inline text item and 2 more from previous inline items.
    if !previousContent.is8Bit() {
      // FIXME: Remove this workaround when we move over to a better way of handling prior-context with Unicode.
      // See the templated CharacterType in nextBreakablePosition for last and lastlast characters.
      nextContent.convertTo16Bit()
    }
    let previousContentStyle = previousInlineItem.style()
    let nextContentStyle = nextInlineItem.style()
    var lineBreakIteratorFactory = CachedLineBreakIteratorFactoryWrapper(
      stringView: StringWrapperView(s: nextContent),
      locale: nextContentStyle.computedLocale(),
      mode: TextUtil.lineBreakIteratorMode(lineBreak: nextContentStyle.lineBreak()),
      contentAnalysis: TextUtil.contentAnalysis(wordBreak: nextContentStyle.wordBreak())
    )
    let previousContentLength = previousContent.length()
    // FIXME: We should look into the entire uncommitted content for more text context.
    let lastCharacter = previousContentLength != 0 ? previousContent[previousContentLength - 1] : 0
    if lastCharacter == CharacterNames.Unicode.softHyphen && previousContentStyle.hyphens() == .None
    {
      return false
    }
    let secondToLastCharacter =
      previousContentLength > 1 ? previousContent[previousContentLength - 2] : 0
    lineBreakIteratorFactory.priorContext().set(newPriorContext: [
      secondToLastCharacter, lastCharacter,
    ])
    // Now check if we can break right at the inline item boundary.
    // With the [ex-ample], findNextBreakablePosition should return the startPosition (0).
    // FIXME: Check if there's a more correct way of finding breaking opportunities.
    return findNextBreakablePosition(
      lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: 0, style: nextContentStyle
    )
      == 0
  }

  static func findNextBreakablePosition(
    lineBreakIteratorFactory: inout CachedLineBreakIteratorFactoryWrapper, startPosition: UInt32,
    style: RenderStyleWrapper
  ) -> UInt32 {
    let wordBreak = style.wordBreak()
    let breakNBSP = style.autoWrap() && style.nbspMode() == .Space

    if wordBreak == .KeepAll {
      if breakNBSP {
        return BreakLines.nextBreakablePosition(
          rules: .Special, words: .KeepAll, spaces: .Break,
          lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: UInt64(startPosition))
      }
      return BreakLines.nextBreakablePosition(
        rules: .Special, words: .KeepAll, spaces: .Normal,
        lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: UInt64(startPosition))
    }

    if wordBreak == .AutoPhrase {
      return BreakLines.nextBreakablePosition(
        rules: .Special, words: .AutoPhrase, spaces: .Normal,
        lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: UInt64(startPosition))
    }

    if lineBreakIteratorFactory.mode() == .Default {
      if breakNBSP {
        return BreakLines.nextBreakablePosition(
          rules: .Normal, words: .Normal, spaces: .Break,
          lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: UInt64(startPosition))
      }
      return BreakLines.nextBreakablePosition(
        rules: .Normal, words: .Normal, spaces: .Normal,
        lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: UInt64(startPosition))
    }

    if breakNBSP {
      return BreakLines.nextBreakablePosition(
        rules: .Special, words: .Normal, spaces: .Break,
        lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: UInt64(startPosition))
    }

    return BreakLines.nextBreakablePosition(
      rules: .Special, words: .Normal, spaces: .Normal,
      lineBreakIteratorFactory: &lineBreakIteratorFactory, startPosition: UInt64(startPosition))
  }

  static func lineBreakIteratorMode(lineBreak: LineBreak)
    -> WTF.TextBreakIteratorWrapper.LineMode.Behavior
  {
    switch lineBreak {
    case .Auto, .AfterWhiteSpace, .Anywhere:
      return .Default
    case .Loose:
      return .Loose
    case .Normal:
      return .Normal
    case .Strict:
      return .Strict
    }
  }

  static func contentAnalysis(wordBreak: WordBreak) -> WTF.TextBreakIteratorWrapper.ContentAnalysis
  {
    switch wordBreak {
    case .Normal, .BreakAll, .KeepAll, .BreakWord:
      return .Mechanical
    case .AutoPhrase:
      return .Linguistic
    }
  }

  static func shouldPreserveSpacesAndTabs(layoutBox: BoxWrapper) -> Bool {
    // https://www.w3.org/TR/css-text-4/#white-space-collapsing
    let whitespaceCollapse = layoutBox.style.whiteSpaceCollapse()
    return whitespaceCollapse == .Preserve || whitespaceCollapse == .BreakSpaces
  }

  static func shouldPreserveNewline(layoutBox: BoxWrapper) -> Bool {
    // https://www.w3.org/TR/css-text-4/#white-space-collapsing
    let whitespaceCollapse = layoutBox.style.whiteSpaceCollapse()
    return whitespaceCollapse == .Preserve || whitespaceCollapse == .PreserveBreaks
      || whitespaceCollapse == .BreakSpaces
  }

  static func isWrappingAllowed(style: RenderStyleWrapper) -> Bool {
    // https://www.w3.org/TR/css-text-4/#text-wrap
    return style.textWrapMode() != .NoWrap
  }

  static func shouldTrailingWhitespaceHang(style: RenderStyleWrapper) -> Bool {
    // https://www.w3.org/TR/css-text-4/#white-space-phase-2
    return style.whiteSpaceCollapse() == .Preserve && style.textWrapMode() != .NoWrap
  }

  static func containsStrongDirectionalityText(text: StringWrapperView) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func ellipsisTextInInlineDirection(isHorizontal: Bool = true) -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.TextUtil_ellipsisTextInInlineDirection(isHorizontal))
  }

  static func hyphenWidth(style: RenderStyleWrapper) -> InlineLayoutUnit {
    return wk_interop.TextUtil_hyphenWidth(style.p!)
  }

  static func firstUserPerceivedCharacterLength(inlineTextItem: InlineTextItemWrapper) -> UInt64 {
    let length = firstUserPerceivedCharacterLength(
      inlineTextBox: inlineTextItem.inlineTextBox(), startPosition: UInt64(inlineTextItem.start()),
      length: UInt64(inlineTextItem.length))
    return min(UInt64(inlineTextItem.length), length)
  }

  static func firstUserPerceivedCharacterLength(
    inlineTextBox: InlineTextBoxWrapper, startPosition: UInt64, length: UInt64
  ) -> UInt64 {
    return wk_interop.TextUtil_firstUserPerceivedCharacterLength(
      inlineTextBox.p!, startPosition, length)
  }

  static func directionForTextContent(content: StringWrapperView) -> TextDirection {
    if content.is8Bit() {
      return .LTR
    }
    let characters = content.span16()
    return ubidi_getBaseDirection(text: characters.data(), length: Int32(characters.size()))
      == .UBIDI_RTL
      ? .RTL : .LTR
  }

  static func hasHangablePunctuationStart(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper
  ) -> Bool {
    if inlineTextItem.length == 0 || !style.hangingPunctuation().contains(.First) {
      return false
    }
    let leadingCharacter = inlineTextItem.inlineTextBox().content[inlineTextItem.start()]
    return UCharMasks.U_GET_GC_MASK(c: Int32(leadingCharacter))
      & (UCharMasks.U_GC_PS_MASK | UCharMasks.U_GC_PI_MASK | UCharMasks.U_GC_PF_MASK) != 0
  }

  static func hangablePunctuationStartWidth(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper
  ) -> Float32 {
    if !hasHangablePunctuationStart(inlineTextItem: inlineTextItem, style: style) {
      return 0
    }
    assert(inlineTextItem.length != 0)
    let leadingPosition = inlineTextItem.start()
    return width(
      inlineTextItem: inlineTextItem, fontCascade: style.fontCascade(), from: leadingPosition,
      to: leadingPosition + 1, contentLogicalLeft: 0)
  }

  static func hasHangablePunctuationEnd(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper
  ) -> Bool {
    if inlineTextItem.length == 0 || !style.hangingPunctuation().contains(.Last) {
      return false
    }
    let trailingCharacter = inlineTextItem.inlineTextBox().content[inlineTextItem.end() - 1]
    return UCharMasks.U_GET_GC_MASK(c: Int32(trailingCharacter))
      & (UCharMasks.U_GC_PE_MASK | UCharMasks.U_GC_PI_MASK | UCharMasks.U_GC_PF_MASK) != 0
  }

  static func hangablePunctuationEndWidth(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper
  ) -> Float32 {
    if !hasHangablePunctuationEnd(inlineTextItem: inlineTextItem, style: style) {
      return 0
    }
    assert(inlineTextItem.length != 0)
    let trailingPosition = inlineTextItem.end() - 1
    return width(
      inlineTextItem: inlineTextItem, fontCascade: style.fontCascade(), from: trailingPosition,
      to: trailingPosition + 1, contentLogicalLeft: 0)
  }

  static func hasHangableStopOrCommaEnd(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper
  ) -> Bool {
    if inlineTextItem.length == 0
      || !(style.hangingPunctuation().contains(.AllowEnd)
        || style.hangingPunctuation().contains(.ForceEnd))
    {
      return false
    }
    let trailingPosition = inlineTextItem.end() - 1
    let trailingCharacter = inlineTextItem.inlineTextBox().content[trailingPosition]
    let isHangableStopOrComma =
      trailingCharacter == 0x002C
      || trailingCharacter == 0x002E || trailingCharacter == 0x060C
      || trailingCharacter == 0x06D4 || trailingCharacter == 0x3001
      || trailingCharacter == 0x3002 || trailingCharacter == 0xFF0C
      || trailingCharacter == 0xFF0E || trailingCharacter == 0xFE50
      || trailingCharacter == 0xFE51 || trailingCharacter == 0xFE52
      || trailingCharacter == 0xFF61 || trailingCharacter == 0xFF64
    return isHangableStopOrComma
  }

  static func hangableStopOrCommaEndWidth(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper
  ) -> Float32 {
    if !hasHangableStopOrCommaEnd(inlineTextItem: inlineTextItem, style: style) {
      return 0
    }
    assert(inlineTextItem.length != 0)
    let trailingPosition = inlineTextItem.end() - 1
    return width(
      inlineTextItem: inlineTextItem, fontCascade: style.fontCascade(), from: trailingPosition,
      to: trailingPosition + 1, contentLogicalLeft: 0)
  }

  static func canUseSimplifiedTextMeasuring(
    _ textContent: StringWrapperView, _ fontCascade: FontCascadeWrapper,
    _ whitespaceIsCollapsed: Bool, _ firstLineStyle: RenderStyleWrapper?
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
