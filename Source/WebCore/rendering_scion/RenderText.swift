/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

import wk_interop

private func capitalize(_ string: StringWrapper, _ previousCharacter: UChar) -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func offsetForPositionInRun(_ textBox: InlineIterator.TextBox, _ x: Float32) -> UInt32 {
  if textBox.isLineBreak() {
    return 0
  }
  if x - textBox.logicalLeftIgnoringInlineDirection() > textBox.logicalWidth() {
    return textBox.isLeftToRightDirection() ? textBox.length() : 0
  }
  if x - textBox.logicalLeftIgnoringInlineDirection() < 0 {
    return textBox.isLeftToRightDirection() ? 0 : textBox.length()
  }
  return UInt32(
    textBox.fontCascade().offsetForPosition(
      textBox.textRun(mode: .Editing), x - textBox.logicalLeftIgnoringInlineDirection(), true))
}

private enum ShouldAffinityBeDownstream {
  case AlwaysDownstream
  case AlwaysUpstream
  case UpstreamIfPositionIsNotAtStart
}

private func lineDirectionPointFitsInBox(
  _ pointLineDirection: Int32, _ textRun: InlineIterator.TextBoxIterator
) -> (Bool, ShouldAffinityBeDownstream) {
  var shouldAffinityBeDownstream: ShouldAffinityBeDownstream = .AlwaysDownstream

  // the x coordinate is equal to the left edge of this box
  // the affinity must be downstream so the position doesn't jump back to the previous line
  // except when box is the first box in the line
  if Float32(pointLineDirection) <= textRun.get().logicalLeftIgnoringInlineDirection() {
    shouldAffinityBeDownstream =
      !textRun.get().previousOnLine().bool() ? .UpstreamIfPositionIsNotAtStart : .AlwaysDownstream
    return (true, shouldAffinityBeDownstream)
  }

  #if WTF_PLATFORM_IOS_FAMILY
    // and the x coordinate is to the left of the right edge of this box
    // check to see if position goes in this box
    if Float32(pointLineDirection) < textRun.get().logicalRightIgnoringInlineDirection() {
      shouldAffinityBeDownstream = .UpstreamIfPositionIsNotAtStart
      return (true, shouldAffinityBeDownstream)
    }
  #endif

  // box is first on line
  // and the x coordinate is to the left of the first text box left edge
  if !textRun.get().previousOnLineIgnoringLineBreak().bool()
    && Float32(pointLineDirection) < textRun.get().logicalLeftIgnoringInlineDirection()
  {
    return (true, shouldAffinityBeDownstream)
  }

  if !textRun.get().nextOnLineIgnoringLineBreak().bool() {
    // box is last on line
    // and the x coordinate is to the right of the last text box right edge
    // generate VisiblePosition, use Affinity::Upstream affinity if possible
    shouldAffinityBeDownstream = .UpstreamIfPositionIsNotAtStart
    return (true, shouldAffinityBeDownstream)
  }

  return (false, shouldAffinityBeDownstream)
}

private func createVisiblePositionForBox(
  _ run: InlineIterator.BoxIterator<InlineIterator.Box>, _ offset: UInt32,
  _ shouldAffinityBeDownstream: ShouldAffinityBeDownstream
) -> VisiblePosition {
  var affinity = VisiblePosition.defaultAffinity
  switch shouldAffinityBeDownstream {
  case .AlwaysDownstream:
    affinity = .Downstream
  case .AlwaysUpstream:
    affinity = .Upstream
  case .UpstreamIfPositionIsNotAtStart:
    affinity = offset > run.get().minimumCaretOffset() ? .Upstream : .Downstream
  }
  return run.get().renderer().createVisiblePosition(Int32(offset), affinity)
}

private func createVisiblePositionAfterAdjustingOffsetForBiDi(
  _ run: InlineIterator.TextBoxIterator, _ offset: UInt32,
  _ shouldAffinityBeDownstream: ShouldAffinityBeDownstream
) -> VisiblePosition {
  if offset != 0 && offset < run.get().length() {
    return createVisiblePositionForBox(run, run.get().start() + offset, shouldAffinityBeDownstream)
  }

  let positionIsAtStartOfBox = offset == 0
  if positionIsAtStartOfBox == run.get().isLeftToRightDirection() {
    // offset is on the left edge

    let previousRun = run.get().previousOnLineIgnoringLineBreak()
    if (previousRun.bool() && previousRun.get().bidiLevel() == run.get().bidiLevel())
      || run.get().renderer().containingBlock()!.style().direction() == run.get().direction()
    {  // FIXME: left on 12CBA
      return createVisiblePositionForBox(
        run, run.get().leftmostCaretOffset(), shouldAffinityBeDownstream)
    }

    if previousRun.bool() && previousRun.get().bidiLevel() > run.get().bidiLevel() {
      // e.g. left of B in aDC12BAb
      var leftmostRun = previousRun
      while previousRun.bool() {
        if previousRun.get().bidiLevel() <= run.get().bidiLevel() {
          break
        }
        leftmostRun = previousRun
        previousRun.traversePreviousOnLineIgnoringLineBreak()
      }
      return createVisiblePositionForBox(
        leftmostRun, leftmostRun.get().rightmostCaretOffset(), shouldAffinityBeDownstream)
    }

    if !previousRun.bool() || previousRun.get().bidiLevel() < run.get().bidiLevel() {
      // e.g. left of D in aDC12BAb
      var rightmostRun: InlineIterator.BoxIterator<InlineIterator.Box> = run
      let nextRun = run.get().nextOnLineIgnoringLineBreak()
      while nextRun.bool() {
        if nextRun.get().bidiLevel() < run.get().bidiLevel() {
          break
        }
        rightmostRun = nextRun
        nextRun.traverseNextOnLineIgnoringLineBreak()
      }
      return createVisiblePositionForBox(
        rightmostRun,
        run.get().isLeftToRightDirection()
          ? rightmostRun.get().maximumCaretOffset() : rightmostRun.get().minimumCaretOffset(),
        shouldAffinityBeDownstream)
    }

    return createVisiblePositionForBox(
      run, run.get().rightmostCaretOffset(), shouldAffinityBeDownstream)
  }

  let nextRun = run.get().nextOnLineIgnoringLineBreak()
  if (nextRun.bool() && nextRun.get().bidiLevel() == run.get().bidiLevel())
    || run.get().renderer().containingBlock()!.style().direction() == run.get().direction()
  {
    return createVisiblePositionForBox(
      run, run.get().rightmostCaretOffset(), shouldAffinityBeDownstream)
  }

  // offset is on the right edge
  if nextRun.bool() && nextRun.get().bidiLevel() > run.get().bidiLevel() {
    // e.g. right of C in aDC12BAb
    var rightmostRun = nextRun
    while nextRun.bool() {
      if nextRun.get().bidiLevel() <= run.get().bidiLevel() {
        break
      }
      rightmostRun = nextRun
      nextRun.traverseNextOnLineIgnoringLineBreak()
    }

    return createVisiblePositionForBox(
      rightmostRun, rightmostRun.get().leftmostCaretOffset(), shouldAffinityBeDownstream)
  }

  if !nextRun.bool() || nextRun.get().bidiLevel() < run.get().bidiLevel() {
    // e.g. right of A in aDC12BAb
    var leftmostRun: InlineIterator.BoxIterator<InlineIterator.Box> = run
    let previousRun = run.get().previousOnLineIgnoringLineBreak()
    while previousRun.bool() {
      if previousRun.get().bidiLevel() < run.get().bidiLevel() {
        break
      }
      leftmostRun = previousRun
      previousRun.traversePreviousOnLineIgnoringLineBreak()
    }

    return createVisiblePositionForBox(
      leftmostRun,
      run.get().isLeftToRightDirection()
        ? leftmostRun.get().minimumCaretOffset() : leftmostRun.get().maximumCaretOffset(),
      shouldAffinityBeDownstream)
  }

  return createVisiblePositionForBox(
    run, run.get().leftmostCaretOffset(), shouldAffinityBeDownstream)
}

private func combineTextWidth(
  _ renderer: RenderTextWrapper, _ fontCascade: FontCascadeWrapper, _ style: RenderStyleWrapper
) -> Float32? {
  if !style.hasTextCombine() {
    return nil
  }
  guard let combineTextRenderer = renderer as? RenderCombineTextWrapper else { return nil }
  return combineTextRenderer.isCombined() ? combineTextRenderer.combinedTextWidth(fontCascade) : nil
}

private func isHangablePunctuationAtLineStart(_ c: UChar) -> Bool {
  return
    (UCharMasks.U_GET_GC_MASK(c: Int32(c))
    & (UCharMasks.U_GC_PS_MASK | UCharMasks.U_GC_PI_MASK | UCharMasks.U_GC_PF_MASK)) != 0
}

private func isHangablePunctuationAtLineEnd(_ c: UChar) -> Bool {
  return
    (UCharMasks.U_GET_GC_MASK(c: Int32(c))
    & (UCharMasks.U_GC_PE_MASK | UCharMasks.U_GC_PI_MASK | UCharMasks.U_GC_PF_MASK)) != 0
}

private func isSpaceAccordingToStyle(_ c: UChar, _ style: RenderStyleWrapper) -> Bool {
  return c == Character(" ").asciiValue!
    || (c == CharacterNames.Unicode.noBreakSpace && style.nbspMode() == .Space)
}

private func mapLineBreakToIteratorMode(_ lineBreak: LineBreak)
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

private func mapWordBreakToContentAnalysis(_ wordBreak: WordBreak)
  -> WTF.TextBreakIteratorWrapper.ContentAnalysis
{
  switch wordBreak {
  case .Normal, .BreakAll, .KeepAll, .BreakWord:
    return .Mechanical
  case .AutoPhrase:
    return .Linguistic
  }
}

private func hyphenWidth(_ renderer: RenderTextWrapper, _ font: FontCascadeWrapper) -> Float32 {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func convertToFullSizeKana(_ string: StringWrapper) -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func invalidateLineLayoutPathOnContentChangeIfNeeded(
  _ renderer: RenderTextWrapper, offset: UInt64, delta: Int32
) {
  guard let container = LayoutIntegration.LineLayout.blockContainer(renderer: renderer) else {
    return
  }
  guard let inlineLayout = container.inlineLayout() else { return }

  if LayoutIntegration.LineLayout.shouldInvalidateLineLayoutPathAfterContentChange(
    parent: container, rendererWithNewContent: renderer, lineLayout: inlineLayout)
  {
    container.invalidateLineLayoutPath(invalidationReason: .ContentChange)
    return
  }
  if !inlineLayout.updateTextContent(textRenderer: renderer, offset: offset, delta: delta) {
    container.invalidateLineLayoutPath(invalidationReason: .ContentChange)
  }
}

class RenderTextWrapper: RenderObjectWrapper {
  convenience init(type: `Type`, textNode: TextWrapper, text: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  convenience init(type: `Type`, document: Document, text: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layoutBox() -> InlineTextBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textNode() -> TextWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getCachedPseudoStyle(
    pseudoElementIdentifier: Style.PseudoElementIdentifier, parentStyle: RenderStyleWrapper? = nil
  ) -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionBackgroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionForegroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionEmphasisMarkColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionPseudoStyle() -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func spellingErrorPseudoStyle() -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func grammarErrorPseudoStyle() -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func targetTextPseudoStyle() -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func originalText() -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func text() -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dirtyLegacyLineBoxes(fullLayout: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func characterAt(_ i: UInt32) -> UChar {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private final func length() -> UInt32 { return text().length() }

  private func maxLogicalWidth() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct Widths {
    var min: Float32 = 0
    var max: Float32 = 0
    var beginMin: Float32 = 0
    var endMin: Float32 = 0
    var beginMax: Float32 = 0
    var endMax: Float32 = 0
    var beginWS = false
    var endWS = false
    var endZeroSpace = false
    var hasBreakableChar = false
    var hasBreak = false
    var endsWithBreak = false
  }

  func trimmedPreferredWidths(leadWidth: Float32, stripFrontSpaces: inout Bool) -> Widths {
    let style = style()
    let collapseWhiteSpace = style.collapseWhiteSpace()

    if !collapseWhiteSpace {
      stripFrontSpaces = false
    }

    if hasTab || preferredLogicalWidthsDirty() || minWidth == nil || maxWidth == nil {
      computePreferredLogicalWidths(leadWidth, minWidth == nil || maxWidth == nil)
    }

    var widths = Widths()

    widths.beginWS = !stripFrontSpaces && hasBeginWS
    widths.endWS = hasEndWS

    let length = length()
    if length == 0 || (stripFrontSpaces && text().containsOnly(isASCIIWhitespace)) {
      return widths
    }

    widths.endZeroSpace = text()[length - 1] == CharacterNames.Unicode.zeroWidthSpace

    widths.min = minWidth ?? -1
    widths.max = maxWidth ?? -1

    widths.beginMin = beginMinWidth
    widths.endMin = endMinWidth

    widths.hasBreakableChar = hasBreakableChar
    widths.hasBreak = hasBreak
    widths.endsWithBreak = hasBreak && text()[length - 1] == Character("\n").asciiValue!

    if text()[0] == Character(" ").asciiValue!
      || (text()[0] == Character("\n").asciiValue! && !style.preserveNewline())
      || text()[0] == Character("\t").asciiValue!
    {
      let font = style.fontCascade()  // FIXME: This ignores first-line.
      if stripFrontSpaces {
        widths.max -= font.width(
          run: RenderBlockWrapper.constructTextRun(
            WTF.span(character: CharacterNames.Unicode.space), style))
      } else {
        widths.max += font.wordSpacing()
      }
    }

    stripFrontSpaces = collapseWhiteSpace && hasEndWS

    if !style.autoWrap() || widths.min > widths.max {
      widths.min = widths.max
    }

    // Compute our max widths by scanning the string for newlines.
    var leadWidth = leadWidth
    if widths.hasBreak {
      let font = style.fontCascade()  // FIXME: This ignores first-line.
      var firstLine = true
      widths.beginMax = widths.max
      widths.endMax = widths.max
      var i: UInt32 = 0
      while i < length {
        var lineLength: UInt32 = 0
        while i + lineLength < length && text()[i + lineLength] != Character("\n").asciiValue! {
          lineLength += 1
        }

        if lineLength != 0 {
          widths.endMax = widthFromCache(
            fontCascade: font, start: i, length: lineLength, leadWidth + widths.endMax, nil, nil,
            style)
          if firstLine {
            firstLine = false
            leadWidth = 0
            widths.beginMax = widths.endMax
          }
          i += lineLength
        } else if firstLine {
          widths.beginMax = 0
          firstLine = false
          leadWidth = 0
        }

        if i == length - 1 {
          // A <pre> run that ends with a newline, as in, e.g.,
          // <pre>Some text\n\n<span>More text</pre>
          widths.endMax = 0
        }
        i += 1
      }
    }

    return widths
  }

  func hangablePunctuationStartWidth(index: UInt32) -> Float32 {
    let length = text().length()
    if index >= length {
      return 0
    }

    if !isHangablePunctuationAtLineStart(text()[index]) {
      return 0
    }

    let style = style()
    return widthFromCache(
      fontCascade: style.fontCascade(), start: index, length: 1, 0, nil, nil, style)
  }

  func hangablePunctuationEndWidth(index: UInt32) -> Float32 {
    let length = text().length()
    if index >= length {
      return 0
    }

    if !isHangablePunctuationAtLineEnd(text()[index]) {
      return 0
    }

    let style = style()
    return widthFromCache(
      fontCascade: style.fontCascade(), start: index, length: 1, 0, nil, nil, style)
  }

  func firstCharacterIndexStrippingSpaces() -> UInt32 {
    if !style().collapseWhiteSpace() {
      return 0
    }

    var i: UInt32 = 0
    let length = text().length()
    while i < length {
      if text()[i] != Character(" ").asciiValue!
        && (text()[i] != Character("\n").asciiValue! || style().preserveNewline())
        && text()[i] != Character("\t").asciiValue!
      {
        break
      }
      i += 1
    }
    return i
  }

  func lastCharacterIndexStrippingSpaces() -> UInt32 {
    if text().length() == 0 {
      return 0
    }

    if !style().collapseWhiteSpace() {
      return text().length() - 1
    }

    for i in (0..<text().length()).reversed() {
      if text()[i] != Character(" ").asciiValue!
        && (text()[i] != Character("\n").asciiValue! || style().preserveNewline())
        && text()[i] != Character("\t").asciiValue!
      {
        return i
      }
    }
    return UInt32.max
  }

  func setText(newContent: StringWrapper, force: Bool = false) {
    let isDifferent = newContent != text()
    setTextInternal(newContent, force)
    if isDifferent || force {
      invalidateLineLayoutPathOnContentChangeIfNeeded(
        self, offset: 0, delta: Int32(text().length()))
    }
  }

  func setTextWithOffset(newText: StringWrapper, offset: UInt32, force: Bool = false) {
    if !force && text() == newText {
      return
    }

    let delta = Int32(newText.length() - text().length())

    linesDirty = legacyLineBoxes!.dirtyForTextChange(self)

    setTextInternal(newText, force || linesDirty)
    invalidateLineLayoutPathOnContentChangeIfNeeded(self, offset: UInt64(offset), delta: delta)
  }

  override func canBeSelectionLeaf() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func width(
    _ from: UInt32, _ length: UInt32, _ fontCascade: FontCascadeWrapper, _ xPos: Float32,
    _ fallbackFonts: WeakHashSet<FontWrapper>?, _ glyphOverflow: inout GlyphOverflow?
  ) -> Float32 {
    assert(from + length <= text().length())
    if text().length() == 0 || length == 0 {
      return 0
    }

    let style = style()
    if let width = combineTextWidth(self, fontCascade, style) {
      return width
    }

    if length == 1 && (characterAt(from) == CharacterNames.Unicode.space) {
      return fontCascade.widthOfSpaceString()
    }

    var width: Float32 = 0
    if CPtrToInt(fontCascade.p) == CPtrToInt(style.fontCascade().p) {
      if !style.preserveNewline() && from == 0 && length == text().length()
        && !(glyphOverflow?.computeBounds ?? false)
      {
        if fallbackFonts != nil {
          assert(glyphOverflow != nil)
          if preferredLogicalWidthsDirty() || !knownToHaveNoOverflowAndNoFallbackFonts {
            computePreferredLogicalWidths(0, fallbackFonts!, &glyphOverflow!)
            if fallbackFonts!.isEmptyIgnoringNullReferences() && !glyphOverflow!.left.bool()
              && !glyphOverflow!.right.bool() && !glyphOverflow!.top.bool()
              && !glyphOverflow!.bottom.bool()
            {
              knownToHaveNoOverflowAndNoFallbackFonts = true
            }
          }
          // The rare case of when we switch between IFC and legacy preferred width computation.
          width = maxWidth ?? maxLogicalWidth()
        } else {
          width = maxLogicalWidth()
        }
      } else {
        width = widthFromCache(
          fontCascade: fontCascade, start: from, length: length, xPos, fallbackFonts, glyphOverflow,
          style)
      }
    } else {
      let run = RenderBlockWrapper.constructTextRun(text: self, offset: from, length: length, style)
      run.setCharacterScanForCodePath(!canUseSimpleFontCodePath())
      run.setTabSize(allow: !style.collapseWhiteSpace(), size: style.tabSize())
      run.setXPos(xPos)

      width = fontCascade.width(run: run, fallbackFonts, glyphOverflow)
    }

    return clampTo(value: width, min: 0)
  }

  func width(
    from: UInt32, len: UInt32, xPos: Float32, firstLine: Bool,
    fallbackFonts: WeakHashSet<FontWrapper>?, glyphOverflow: inout GlyphOverflow?
  ) -> Float32 {
    if from >= text().length() {
      return 0
    }

    let lineStyle = firstLine ? firstLineStyle() : style()
    return width(
      from, from + len > text().length() ? text().length() - from : len, lineStyle.fontCascade(),
      xPos, fallbackFonts, &glyphOverflow)
  }

  func width(
    from: UInt32, length: UInt32, fontCascade: FontCascadeWrapper, xPos: Float32,
    fallbackFonts: WeakHashSet<FontWrapper>?, glyphOverflow: inout GlyphOverflow?
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func caretMinOffset() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func caretMaxOffset() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasRenderedText() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsVisualReordering() {
    assert(!isNativeImpl())
    wk_interop.RenderText_setNeedsVisualReordering(p)
  }

  func containsOnlyCollapsibleWhitespace() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canUseSimpleFontCodePath() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeAndDestroyLegacyTextBoxes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // There is no need to ever schedule repaints from a style change of a text run, since
    // we already did this for the parent of the text run.
    // We do have to schedule layouts, though, since a style change can force us to
    // need to relayout.
    if diff == .Layout {
      setNeedsLayoutAndPrefWidthsRecalc()
      knownToHaveNoOverflowAndNoFallbackFonts = false
    }

    let newStyle = style()
    if oldStyle == nil {
      initiateFontLoadingByAccessingGlyphDataAndComputeCanUseSimplifiedTextMeasuring(m_text!)
    }
    if oldStyle != nil
      && CPtrToInt(oldStyle!.fontCascade().p) != CPtrToInt(newStyle.fontCascade().p)
    {
      m_canUseSimplifiedTextMeasuring = nil
    }

    var needsResetText = false
    if oldStyle == nil {
      useBackslashAsYenSymbol = computeUseBackslashAsYenSymbol()
      needsResetText = useBackslashAsYenSymbol
    } else if oldStyle!.fontCascade().useBackslashAsYenSymbol()
      != newStyle.fontCascade().useBackslashAsYenSymbol()
    {
      useBackslashAsYenSymbol = computeUseBackslashAsYenSymbol()
      needsResetText = true
    }

    let oldTransform: TextTransform = oldStyle?.textTransform() ?? []
    let oldSecurity: TextSecurity = oldStyle?.textSecurity() ?? .None
    if needsResetText || oldTransform != newStyle.textTransform()
      || oldSecurity != newStyle.textSecurity()
    {
      setText(newContent: originalText(), force: true)
    }

    // FIXME: First line change on the block comes in as equal on text with inline box parent.
    let needsLayoutBoxStyleUpdate =
      (diff >= .Repaint
        || ((parent() is RenderInlineWrapper)
          && CPtrToInt(style().p) != CPtrToInt(firstLineStyle().p)))
      && layoutBox() != nil
    if needsLayoutBoxStyleUpdate {
      LayoutIntegration.LineLayout.updateStyle(self)
    }
  }

  // FIXME: merge this with isCSSSpace somehow
  func containsOnlyPossiblyCollapsibleWhitespace<CharacterType>(
    _ characters: CharSpanWrapper<CharacterType>
  ) -> Bool {
    for i in 0..<characters.size() {
      let character = characters[i]
      if !(character == UChar(Character("\n").asciiValue!)
        || character == UChar(Character(" ").asciiValue!)
        || character == UChar(Character("\t").asciiValue!))
      {
        return false
      }
    }
    return true
  }

  private func containsOnlyCSSWhitespace(from: UInt32, length: UInt32) -> Bool {
    assert(from <= text().length())
    assert(length <= text().length())
    assert(from + length <= text().length())
    if text().is8Bit() {
      return containsOnlyPossiblyCollapsibleWhitespace(text().span8().subspan(from, length))
    }
    return containsOnlyPossiblyCollapsibleWhitespace(text().span16().subspan(from, length))
  }

  func contentRangesBetweenOffsetsForType(
    type: DocumentMarker.`Type`, startOffset: UInt32, endOffset: UInt32
  ) -> [(UInt32, UInt32)] {
    if textNode() == nil {
      return []
    }

    guard let markerController = document().markersIfExists() else { return [] }
    let markers = markerController.markersFor(node: textNode()!, type)
    if markers.isEmpty {
      return []
    }

    var contentRanges: [(UInt32, UInt32)] = []
    for marker in markers {
      let markerStart = max(marker.startOffset(), startOffset)
      let markerEnd = min(marker.endOffset(), endOffset)
      if markerStart >= markerEnd || markerStart > endOffset || markerEnd < startOffset {
        continue
      }

      contentRanges.append((markerStart, markerEnd))
    }
    return contentRanges
  }

  func inlineWrapperForDisplayContents() -> RenderInlineWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInlineWrapperForDisplayContents(wrapper: RenderInlineWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func emphasisMarkExistsAndIsAbove(renderer: RenderTextWrapper, style: RenderStyleWrapper)
    -> Bool?
  {
    // This function returns true if there are text emphasis marks and they are suppressed by ruby text.
    if style.textEmphasisMark() == .None {
      return nil
    }

    let emphasisPosition = style.textEmphasisPosition()
    var isAbove = !emphasisPosition.contains(.Under)
    if style.isVerticalWritingMode() {
      isAbove = !emphasisPosition.contains(.Left)
    }

    let findRubyAnnotation = { () -> RenderBlockFlowWrapper? in
      var baseCandidate = renderer.parent()
      while baseCandidate != nil {
        if !baseCandidate!.isInline() {
          return nil
        }
        if baseCandidate!.style().display() == .RubyBase {
          if let annotationCandidate = baseCandidate!.nextSibling(),
            annotationCandidate.style().display() == .RubyAnnotation
          {
            return annotationCandidate as? RenderBlockFlowWrapper
          }
          return nil
        }
        baseCandidate = baseCandidate!.parent()
      }
      return nil
    }

    if let annotation = findRubyAnnotation() {
      // The emphasis marks are suppressed only if there is a ruby annotation box on the same side and it is not empty.
      if annotation.hasLines() && isAbove == (annotation.style().rubyPosition() == .Over) {
        return nil
      }
    }

    return isAbove
  }

  func resetMinMaxWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCanUseSimplifiedTextMeasuring(_ canUseSimplifiedTextMeasuring: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canUseSimplifiedTextMeasuring() -> Bool? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasStrongDirectionalityContent(hasStrongDirectionalityContent: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasStrongDirectionalityContent() -> Bool? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computePreferredLogicalWidths(
    _ leadWidth: Float32, _ forcedMinMaxWidthComputation: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setRenderedText(_ newText: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTextInternal(_ text: StringWrapper, _ force: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    let firstRun = InlineIterator.firstTextBoxFor(self)

    if !firstRun.bool() || text().length() == 0 {
      return createVisiblePosition(0, .Downstream)
    }

    let pointLineDirection = firstRun.get().isHorizontal() ? point.x : point.y
    let pointBlockDirection = firstRun.get().isHorizontal() ? point.y : point.x
    let blocksAreFlipped = style().isFlippedBlocksWritingMode()

    var lastRun = InlineIterator.TextBoxIterator()
    let run = firstRun
    while run.bool() {
      if run.get().isLineBreak() && !run.get().previousOnLine().bool()
        && run.get().nextOnLine().bool()
        && !run.get().nextOnLine().get().isLineBreak()
      {
        run.traverseNextTextBox()
      }

      let lineBox = run.get().lineBox()
      let top = LayoutUnit(
        value: min(
          InlineIterator.previousLineBoxContentBottomOrBorderAndPadding(lineBox.get()),
          lineBox.get().contentLogicalTop()))
      if pointBlockDirection > top || (!blocksAreFlipped && pointBlockDirection == top) {
        var bottom = LayoutUnit(value: LineSelection.logicalBottom(lineBox: lineBox.get()))
        let nextLineBox = lineBox.get().next()
        if nextLineBox.bool() {
          bottom = min(bottom, LayoutUnit(value: nextLineBox.get().contentLogicalTop()))
        }

        if pointBlockDirection < bottom || (blocksAreFlipped && pointBlockDirection == bottom) {
          let (fitsInBox, shouldAffinityBeDownstream) = lineDirectionPointFitsInBox(
            pointLineDirection.int(), run)
          if fitsInBox {
            // TODO(asuhan): add iOS support
            return createVisiblePositionAfterAdjustingOffsetForBiDi(
              run, offsetForPositionInRun(run.get(), pointLineDirection.float()),
              shouldAffinityBeDownstream
            )
          }
        }
      }
      lastRun = run
      run.traverseNextTextBox()
    }

    if lastRun.bool() {
      let (_, shouldAffinityBeDownstream) = lineDirectionPointFitsInBox(
        pointLineDirection.int(), lastRun)
      return createVisiblePositionAfterAdjustingOffsetForBiDi(
        lastRun,
        offsetForPositionInRun(lastRun.get(), pointLineDirection.float()) + lastRun.get().start(),
        shouldAffinityBeDownstream)
    }
    return createVisiblePosition(0, .Downstream)
  }

  override final func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    var rendererToRepaint: RenderObjectWrapper? = containingBlock()

    // Do not cross self-painting layer boundaries.
    let enclosingLayerRenderer = enclosingLayer()!.renderer()
    if CPtrToInt(enclosingLayerRenderer.p) != CPtrToInt(rendererToRepaint?.p)
      && !rendererToRepaint!.isDescendantOf(ancestor: enclosingLayerRenderer)
    {
      rendererToRepaint = enclosingLayerRenderer
    }

    // The renderer we chose to repaint may be an ancestor of repaintContainer, but we need to do a repaintContainer-relative repaint.
    if repaintContainer != nil && CPtrToInt(repaintContainer!.p) != CPtrToInt(rendererToRepaint?.p)
      && !rendererToRepaint!.isDescendantOf(ancestor: repaintContainer)
    {
      return repaintContainer!.clippedOverflowRect(repaintContainer, context)
    }

    return rendererToRepaint!.clippedOverflowRect(repaintContainer, context)
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computePreferredLogicalWidths(
    _ leadWidth: Float32, _ fallbackFonts: WeakHashSet<FontWrapper>,
    _ glyphOverflow: inout GlyphOverflow,
    _ forcedMinMaxWidthComputation: Bool = false
  ) {
    assert(
      hasTab || preferredLogicalWidthsDirty() || forcedMinMaxWidthComputation
        || !knownToHaveNoOverflowAndNoFallbackFonts)

    minWidth = 0
    beginMinWidth = 0
    endMinWidth = 0
    maxWidth = 0

    var currMaxWidth: Float32 = 0
    hasBreakableChar = false
    hasBreak = false
    hasTab = false
    hasBeginWS = false
    hasEndWS = false

    let style = style()
    let font = style.fontCascade()  // FIXME: This ignores first-line.
    let wordSpacing = font.wordSpacing()
    let string = text()
    let length = string.length()
    let iteratorMode = mapLineBreakToIteratorMode(style.lineBreak())
    let contentAnalysis = mapWordBreakToContentAnalysis(style.wordBreak())
    let lineBreakIteratorFactory = CachedLineBreakIteratorFactoryWrapper(
      stringView: StringWrapperView(s: string), locale: style.computedLocale(), mode: iteratorMode,
      contentAnalysis: contentAnalysis)
    var needsWordSpacing = false
    var ignoringSpaces = false
    var isSpace = false
    var firstWord = true
    var firstLine = true
    var lastWordBoundary: UInt32 = 0

    var wordTrailingSpace = WordTrailingSpace(style)
    // If automatic hyphenation is allowed, we keep track of the width of the widest word (or word
    // fragment) encountered so far, and only try hyphenating words that are wider.
    var maxWordWidth = Float32.greatestFiniteMagnitude
    var minimumPrefixLength: UInt32 = 0
    var minimumSuffixLength: UInt32 = 0
    if style.hyphens() == .Auto && canHyphenate(localeIdentifier: style.computedLocale()) {
      maxWordWidth = 0

      // Map 'hyphenate-limit-{before,after}: auto;' to 2.
      let before = style.hyphenationLimitBefore()
      minimumPrefixLength = UInt32(before < 0 ? 2 : before)

      let after = style.hyphenationLimitAfter()
      minimumSuffixLength = UInt32(after < 0 ? 2 : after)
    }

    let breakNBSP = style.autoWrap() && style.nbspMode() == .Space

    let breakAnywhere = style.lineBreak() == .Anywhere && style.autoWrap()
    // Note the deliberate omission of word-wrap/overflow-wrap's break-word value from this breakAll check.
    // Those do not affect minimum preferred sizes. Note that break-word is a non-standard value for
    // word-break, but we support it as though it means break-all.
    let breakAll =
      (style.wordBreak() == .BreakAll || style.wordBreak() == .BreakWord
        || style.overflowWrap() == .Anywhere) && style.autoWrap()
    let keepAllWords = style.wordBreak() == .KeepAll
    let canUseLineBreakShortcut = iteratorMode == .Default && contentAnalysis == .Mechanical

    var firstGlyphLeftOverflow: LayoutUnit? = nil
    var leadWidth = leadWidth
    var i: UInt32 = 0
    while i < length {
      var c = string[i]

      let previousCharacterIsSpace = isSpace

      var isNewline = false
      if c == Character("\n").asciiValue! {
        if style.preserveNewline() {
          hasBreak = true
          isNewline = true
          isSpace = false
        } else {
          isSpace = true
        }
      } else if c == Character("\t").asciiValue! {
        if !style.collapseWhiteSpace() {
          hasTab = true
          isSpace = false
        } else {
          isSpace = true
        }
      } else {
        isSpace = c == Character(" ").asciiValue!
      }

      if (isSpace || isNewline) && i == 0 {
        hasBeginWS = true
      }
      if (isSpace || isNewline) && i == length - 1 {
        hasEndWS = true
      }

      ignoringSpaces =
        (style.collapseWhiteSpace() && previousCharacterIsSpace && isSpace) || ignoringSpaces
      ignoringSpaces = isSpace && ignoringSpaces

      // Ignore spaces and soft hyphens
      if ignoringSpaces {
        assert(lastWordBoundary == i)
        lastWordBoundary += 1
        i += 1
        continue
      } else if c == CharacterNames.Unicode.softHyphen && style.hyphens() != .None {
        assert(i >= lastWordBoundary)
        currMaxWidth += widthFromCache(
          fontCascade: font, start: lastWordBoundary, length: i - lastWordBoundary,
          leadWidth + currMaxWidth, fallbackFonts, glyphOverflow, style)
        if firstGlyphLeftOverflow == nil {
          firstGlyphLeftOverflow = glyphOverflow.left
        }
        lastWordBoundary = i + 1
        i += 1
        continue
      }

      let hasBreak =
        breakAll
        || BreakLines.isBreakable(
          lineBreakIteratorFactory, i, nil, breakNBSP: breakNBSP,
          canUseShortcut: canUseLineBreakShortcut,
          keepAllWords: keepAllWords, breakAnywhere: breakAnywhere)
      var betweenWords = true
      var j = i
      while c != Character("\n").asciiValue! && !isSpaceAccordingToStyle(c, style)
        && c != Character("\t").asciiValue! && c != CharacterNames.Unicode.zeroWidthSpace
        && (c != CharacterNames.Unicode.softHyphen || style.hyphens() == .None)
      {
        let previousCharacter = c
        j += 1
        if j == length {
          break
        }
        c = string[j]
        if UTF16.isLeadSurrogate(previousCharacter) && UTF16.isTrailSurrogate(c) {
          continue
        }
        if BreakLines.isBreakable(
          lineBreakIteratorFactory, j, nil, breakNBSP: breakNBSP,
          canUseShortcut: canUseLineBreakShortcut,
          keepAllWords: keepAllWords, breakAnywhere: breakAnywhere)
          && characterAt(j - 1) != CharacterNames.Unicode.softHyphen
        {
          break
        }
        if breakAll {
          // FIXME: This code is ultra wrong.
          // The spec says "word-break: break-all: Any typographic letter units are treated as ID(“ideographic characters”) for the purpose of line-breaking."
          // The spec describes how a "typographic letter unit" is a cluster, not a code point: https://drafts.csswg.org/css-text-3/#typographic-character-unit
          betweenWords = false
          break
        }
      }

      let wordLen = j - i
      if wordLen != 0 {
        var currMinWidth: Float32 = 0
        let isSpace = (j < length) && isSpaceAccordingToStyle(c, style)
        let w = widthFromCacheConsideringPossibleTrailingSpace(
          style: style, font: font, startIndex: i, wordLen: wordLen, leadWidth + currMaxWidth,
          isSpace, &wordTrailingSpace,
          fallbackFonts, &glyphOverflow)
        if c == CharacterNames.Unicode.softHyphen && style.hyphens() != .None {
          currMinWidth = hyphenWidth(self, font)
        }

        if w > maxWordWidth {
          let maxFragmentWidth = maxWordFragmentWidth(
            style, font, StringWrapperView(s: string).substring(start: i, length: wordLen),
            minimumPrefixLength: minimumPrefixLength,
            minimumSuffixLength: minimumSuffixLength, currentCharacterIsSpace: isSpace,
            characterIndex: i, xPos: leadWidth + currMaxWidth, entireWordWidth: w,
            wordTrailingSpace: &wordTrailingSpace,
            fallbackFonts: fallbackFonts, glyphOverflow: &glyphOverflow)
          currMinWidth += maxFragmentWidth - w  // This, when combined with "currMinWidth += w" below, has the effect of executing "currMinWidth += maxFragmentWidth" instead.
          maxWordWidth = max(maxWordWidth, maxFragmentWidth)
        }

        if firstGlyphLeftOverflow == nil {
          firstGlyphLeftOverflow = glyphOverflow.left
        }
        currMinWidth += w
        if betweenWords {
          if lastWordBoundary == i {
            currMaxWidth += w
          } else {
            assert(j >= lastWordBoundary)
            currMaxWidth += widthFromCache(
              fontCascade: font, start: lastWordBoundary, length: j - lastWordBoundary,
              leadWidth + currMaxWidth,
              fallbackFonts, glyphOverflow, style)
          }
          lastWordBoundary = j
        }

        let isCollapsibleWhiteSpace = (j < length) && style.isCollapsibleWhiteSpace(c)
        if j < length && style.autoWrap() {
          hasBreakableChar = true
        }

        // Add in wordSpacing to our currMaxWidth, but not if this is the last word on a line or the
        // last word in the run.
        if (isSpace || isCollapsibleWhiteSpace)
          && !containsOnlyCSSWhitespace(from: j, length: length - j)
        {
          currMaxWidth += wordSpacing
        }

        if firstWord {
          firstWord = false
          // If the first character in the run is breakable, then we consider ourselves to have a beginning
          // minimum width of 0, since a break could occur right before our run starts, preventing us from ever
          // being appended to a previous text run when considering the total minimum width of the containing block.
          if hasBreak {
            hasBreakableChar = true
          }
          beginMinWidth = hasBreak ? 0 : currMinWidth
        }
        endMinWidth = currMinWidth

        minWidth = max(currMinWidth, minWidth!)

        i += wordLen - 1
      } else {
        // Nowrap can never be broken, so don't bother setting the
        // breakable character boolean. Pre can only be broken if we encounter a newline.
        if style.autoWrap() || isNewline {
          hasBreakableChar = true
        }

        if isNewline {  // Only set if preserveNewline was true and we saw a newline.
          if firstLine {
            firstLine = false
            leadWidth = 0
            if !style.autoWrap() {
              beginMinWidth = currMaxWidth
            }
          }

          if currMaxWidth > maxWidth! {
            maxWidth = currMaxWidth
          }
          currMaxWidth = 0
        } else {
          let run = RenderBlockWrapper.constructTextRun(text: self, offset: i, length: 1, style)
          run.setTabSize(allow: !style.collapseWhiteSpace(), size: style.tabSize())
          run.setXPos(leadWidth + currMaxWidth)

          currMaxWidth += font.width(run: run, fallbackFonts)
          glyphOverflow.right = LayoutUnit(value: 0)
          needsWordSpacing = isSpace && !previousCharacterIsSpace && i == length - 1
        }
        assert(lastWordBoundary == i)
        lastWordBoundary += 1
      }
      i += 1
    }

    glyphOverflow.left = firstGlyphLeftOverflow ?? glyphOverflow.left

    if (needsWordSpacing && length > 1) || (ignoringSpaces && !firstWord) {
      currMaxWidth += wordSpacing
    }

    maxWidth = max(currMaxWidth, maxWidth!)

    if !style.autoWrap() {
      minWidth = maxWidth
    }

    if style.whiteSpaceCollapse() == .Preserve && style.textWrapMode() == .NoWrap {
      if firstLine {
        beginMinWidth = maxWidth!
      }
      endMinWidth = currMaxWidth
    }

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override final func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ action: HitTestAction
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func widthFromCache(
    fontCascade: FontCascadeWrapper, start: UInt32, length: UInt32, _ xPos: Float32,
    _ fallbackFonts: WeakHashSet<FontWrapper>?, _ glyphOverflow: GlyphOverflow?,
    _ style: RenderStyleWrapper
  ) -> Float32 {
    if let width = combineTextWidth(self, fontCascade, style) {
      return width
    }

    let run = RenderBlockWrapper.constructTextRun(text: self, offset: start, length: length, style)
    run.setCharacterScanForCodePath(!canUseSimpleFontCodePath())
    run.setTabSize(allow: !style.collapseWhiteSpace(), size: style.tabSize())
    run.setXPos(xPos)
    return fontCascade.width(run: run, fallbackFonts, glyphOverflow)
  }

  private func computeUseBackslashAsYenSymbol() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func maxWordFragmentWidth(
    _ style: RenderStyleWrapper, _ font: FontCascadeWrapper, _ word: StringWrapperView,
    minimumPrefixLength: UInt32, minimumSuffixLength: UInt32, currentCharacterIsSpace: Bool,
    characterIndex: UInt32, xPos: Float32, entireWordWidth: Float32,
    wordTrailingSpace: inout WordTrailingSpace, fallbackFonts: WeakHashSet<FontWrapper>,
    glyphOverflow: inout GlyphOverflow
  ) -> Float32 {
    var suffixStart: UInt32 = 0
    if word.length() <= minimumSuffixLength {
      return entireWordWidth
    }

    var hyphenLocations: [Int32] = []  // TODO(asuhan): use array with inline storage
    assert(word.length() >= minimumSuffixLength)
    var hyphenLocation = word.length() - minimumSuffixLength
    while true {
      hyphenLocation = UInt32(
        lastHyphenLocation(
          string: word, beforeIndex: UInt64(hyphenLocation),
          localeIdentifier: style.computedLocale()))
      if hyphenLocation >= max(minimumPrefixLength, 1) {
        break
      }
      hyphenLocations.append(Int32(hyphenLocation))
    }

    if hyphenLocations.isEmpty {
      return entireWordWidth
    }

    hyphenLocations.reverse()

    // Consider the word "ABC-DEF-GHI" (where the '-' characters are hyphenation opportunities). We want to measure the width
    // of "ABC-" and "DEF-", but not "GHI-". Instead, we should measure "GHI" the same way we measure regular unhyphenated
    // words (by using wordTrailingSpace). Therefore, this function is split up into two parts - one that measures each prefix,
    // and one that measures the single last suffix.

    // FIXME: Breaking the string at these places in the middle of words doesn't work with complex text.
    let minimumFragmentWidthToConsider = font.size() * 5 / 4 + hyphenWidth(self, font)
    var maxFragmentWidth: Float32 = 0
    for hyphenLocation in hyphenLocations {
      let fragmentLength = hyphenLocation - Int32(suffixStart)
      let fragmentWithHyphen = StringBuilderWrapper()
      fragmentWithHyphen.append(
        string: word.substring(start: suffixStart, length: UInt32(fragmentLength)))
      fragmentWithHyphen.append(string: style.hyphenString())

      let run = RenderBlockWrapper.constructTextRun(fragmentWithHyphen.toString(), style)
      run.setCharacterScanForCodePath(!canUseSimpleFontCodePath())
      let fragmentWidth = font.width(run: run, fallbackFonts, glyphOverflow)

      // Narrow prefixes are ignored. See tryHyphenating in RenderBlockLineLayout.cpp.
      if fragmentWidth <= minimumFragmentWidthToConsider {
        continue
      }

      suffixStart += UInt32(fragmentLength)
      maxFragmentWidth = max(maxFragmentWidth, fragmentWidth)
    }

    if suffixStart == 0 {
      // We didn't find any hyphenation opportunities that we're willing to actually use.
      // Therefore, the width of the maximum fragment is just ... the width of the entire word.
      return entireWordWidth
    }

    let suffixWidth = widthFromCacheConsideringPossibleTrailingSpace(
      style: style, font: font, startIndex: characterIndex + suffixStart,
      wordLen: word.length() - suffixStart, xPos,
      currentCharacterIsSpace, &wordTrailingSpace, fallbackFonts, &glyphOverflow)
    return max(maxFragmentWidth, suffixWidth)
  }

  private func widthFromCacheConsideringPossibleTrailingSpace(
    style: RenderStyleWrapper, font: FontCascadeWrapper, startIndex: UInt32, wordLen: UInt32,
    _ xPos: Float32, _ currentCharacterIsSpace: Bool, _ wordTrailingSpace: inout WordTrailingSpace,
    _ fallbackFonts: WeakHashSet<FontWrapper>, _ glyphOverflow: inout GlyphOverflow
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func initiateFontLoadingByAccessingGlyphDataAndComputeCanUseSimplifiedTextMeasuring(
    _ textContent: StringWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let legacyLineBoxes: RenderTextLineBoxes? = nil

  private var minWidth: Float32? = nil
  private var maxWidth: Float32? = nil
  private var beginMinWidth: Float32 = 0
  private var endMinWidth: Float32 = 0

  private let m_text: StringWrapper? = nil

  var m_canUseSimplifiedTextMeasuring: Bool? = nil
  private var hasBreakableChar = false  // Whether or not we can be broken into multiple lines.
  private var hasBreak = false  // Whether or not we have a hard break (e.g., <pre> with '\n').
  private var hasTab = false  // Whether or not we have a variable width tab character (e.g., <pre> with '\t').
  private var hasBeginWS = false  // Whether or not we begin with WS (only true if we aren't pre)
  private var hasEndWS = false  // Whether or not we end with WS (only true if we aren't pre)
  // This bit indicates that the text run has already dirtied specific
  // line boxes, and this hint will enable layoutInlineChildren to avoid
  // just dirtying everything when character data is modified (e.g., appended/inserted
  // or removed).
  private var linesDirty = false
  private var knownToHaveNoOverflowAndNoFallbackFonts = false
  private var useBackslashAsYenSymbol = false
}

func applyTextTransform(
  _ style: RenderStyleWrapper, _ text: StringWrapper, _ previousCharacter: UChar
) -> StringWrapper {
  let transform = style.textTransform()

  if transform.isEmpty {
    return text
  }

  // https://w3c.github.io/csswg-drafts/css-text/#text-transform-order
  var modified = text
  if transform.contains(.Capitalize) {
    modified = capitalize(modified, previousCharacter)  // FIXME: Need to take locale into account.
  } else if transform.contains(.Uppercase) {
    modified = modified.convertToUppercaseWithLocale(style.computedLocale())
  } else if transform.contains(.Lowercase) {
    modified = modified.convertToLowercaseWithLocale(style.computedLocale())
  }

  if transform.contains(.FullWidth) {
    modified = transformToFullWidth(modified)
  }

  if transform.contains(.FullSizeKana) {
    modified = convertToFullSizeKana(modified)
  }

  return modified
}
