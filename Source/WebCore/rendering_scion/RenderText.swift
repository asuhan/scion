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

  struct Widths {
    let min: Float32 = 0
    let max: Float32 = 0
    var beginMin: Float32 = 0
    let endMin: Float32 = 0
    var beginMax: Float32 = 0
    let endMax: Float32 = 0
    let beginWS = false
    let endWS = false
    let endZeroSpace = false
    let hasBreakableChar = false
    let hasBreak = false
    let endsWithBreak = false
  }

  func trimmedPreferredWidths(leadWidth: Float32, stripFrontSpaces: inout Bool) -> Widths {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hangablePunctuationStartWidth(index: UInt32) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override final func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
