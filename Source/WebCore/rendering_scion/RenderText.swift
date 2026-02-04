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

private func isHangablePunctuationAtLineStart(_ c: UChar) -> Bool {
  return
    (UCharMasks.U_GET_GC_MASK(c: Int32(c))
    & (UCharMasks.U_GC_PS_MASK | UCharMasks.U_GC_PI_MASK | UCharMasks.U_GC_PF_MASK)) != 0
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

  private final func length() -> UInt32 { return text().length() }

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
    widths.endsWithBreak = hasBreak && text()[length - 1] == UChar(Character("\n").asciiValue!)

    if text()[0] == UChar(Character(" ").asciiValue!)
      || (text()[0] == UChar(Character("\n").asciiValue!) && !style.preserveNewline())
      || text()[0] == UChar(Character("\t").asciiValue!)
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
        while i + lineLength < length
          && text()[i + lineLength] != UChar(Character("\n").asciiValue!)
        {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstCharacterIndexStrippingSpaces() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastCharacterIndexStrippingSpaces() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setText(newContent: StringWrapper, force: Bool = false) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTextWithOffset(newText: StringWrapper, offset: UInt32, force: Bool = false) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func canBeSelectionLeaf() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func width(
    from: UInt32, len: UInt32, xPos: Float32, firstLine: Bool = false,
    fallbackFonts: Set<UInt>? = nil,
    glyphOverflow: GlyphOverflow? = nil
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func removeAndDestroyLegacyTextBoxes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func widthFromCache(
    fontCascade: FontCascadeWrapper, start: UInt32, length: UInt32, _ xPos: Float32,
    _ fallbackFonts: WeakHashSet<FontWrapper>?, _ glyphOverflow: GlyphOverflow?,
    _ style: RenderStyleWrapper
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let minWidth: Float32? = nil
  private let maxWidth: Float32? = nil
  private let beginMinWidth: Float32 = 0
  private let endMinWidth: Float32 = 0

  var m_canUseSimplifiedTextMeasuring: Bool? = nil
  private let hasBreakableChar = false  // Whether or not we can be broken into multiple lines.
  private let hasBreak = false  // Whether or not we have a hard break (e.g., <pre> with '\n').
  private let hasTab = false  // Whether or not we have a variable width tab character (e.g., <pre> with '\t').
  private let hasBeginWS = false  // Whether or not we begin with WS (only true if we aren't pre)
  private let hasEndWS = false  // Whether or not we end with WS (only true if we aren't pre)
}

func applyTextTransform(
  _ style: RenderStyleWrapper, _ text: StringWrapper, _ previousCharacter: UChar
) -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
