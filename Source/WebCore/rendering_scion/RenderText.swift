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

private func combineTextWidth(
  _ renderer: RenderTextWrapper, _ fontCascade: FontCascadeWrapper, _ style: RenderStyleWrapper
) -> Float32? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
    _ fallbackFonts: WeakHashSet<FontWrapper>? = nil, _ glyphOverflow: GlyphOverflow? = nil
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
            computePreferredLogicalWidths(0, fallbackFonts!, glyphOverflow!)
            if fallbackFonts!.isEmptyIgnoringNullReferences() && glyphOverflow!.left == 0
              && glyphOverflow!.right == 0 && glyphOverflow!.top == 0 && glyphOverflow!.bottom == 0
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
    from: UInt32, len: UInt32, xPos: Float32, firstLine: Bool = false,
    fallbackFonts: WeakHashSet<FontWrapper>? = nil,
    glyphOverflow: GlyphOverflow? = nil
  ) -> Float32 {
    if from >= text().length() {
      return 0
    }

    let lineStyle = firstLine ? firstLineStyle() : style()
    return width(
      from, from + len > text().length() ? text().length() - from : len, lineStyle.fontCascade(),
      xPos, fallbackFonts, glyphOverflow)
  }

  func hasRenderedText() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsVisualReordering() {
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

  func contentRangesBetweenOffsetsForType(
    type: DocumentMarker.`Type`, startOffset: UInt32, endOffset: UInt32
  ) -> [(UInt32, UInt32)] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func setTextInternal(_ text: StringWrapper, _ force: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    _ leadWidth: Float32, _ fallbackFonts: WeakHashSet<FontWrapper>, _ glyphOverflow: GlyphOverflow,
    _ forcedMinMaxWidthComputation: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func widthFromCache(
    fontCascade: FontCascadeWrapper, start: UInt32, length: UInt32, _ xPos: Float32,
    _ fallbackFonts: WeakHashSet<FontWrapper>?, _ glyphOverflow: GlyphOverflow?,
    _ style: RenderStyleWrapper
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeUseBackslashAsYenSymbol() -> Bool {
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

  private let minWidth: Float32? = nil
  private let maxWidth: Float32? = nil
  private let beginMinWidth: Float32 = 0
  private let endMinWidth: Float32 = 0

  private let m_text: StringWrapper? = nil

  var m_canUseSimplifiedTextMeasuring: Bool? = nil
  private let hasBreakableChar = false  // Whether or not we can be broken into multiple lines.
  private let hasBreak = false  // Whether or not we have a hard break (e.g., <pre> with '\n').
  private let hasTab = false  // Whether or not we have a variable width tab character (e.g., <pre> with '\t').
  private let hasBeginWS = false  // Whether or not we begin with WS (only true if we aren't pre)
  private let hasEndWS = false  // Whether or not we end with WS (only true if we aren't pre)
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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
