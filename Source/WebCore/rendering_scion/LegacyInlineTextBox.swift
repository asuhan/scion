/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2017 Apple Inc. All rights reserved.
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

class LegacyInlineTextBox: LegacyInlineBox, DisplayTextBox {
  init(_ renderer: RenderTextWrapper) { super.init(renderer) }

  func renderer() -> RenderTextWrapper { return rendererObject() as! RenderTextWrapper }

  func nextTextBox() -> LegacyInlineTextBox? { return m_nextTextBox }

  func hasTextContent() -> Bool { return m_len != 0 }

  func start() -> UInt32 { return m_start }

  func end() -> UInt32 { return m_start + m_len }

  func len() -> UInt32 { return m_len }

  func selectableRange() -> TextBoxSelectableRange {
    // Fix up the offset if we are combined text because we manage these embellishments.
    // That is, they are not reflected in renderer().text(). We treat combined text as a single unit.
    return TextBoxSelectableRange(
      start: m_start, length: m_len, additionalLengthAtEnd: 0, isLineBreak: isLineBreak(),
      truncation: nil)
  }

  func logicalLeftVisualOverflow() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalRightVisualOverflow() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeFromGlyphDisplayListCache() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isLineBreak() -> Bool {
    return renderer().style().preserveNewline() && len() == 1
      && renderer().text()[start()] == UChar(Character("\n").asciiValue!)
  }

  override func paint(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, lineTop: LayoutUnit,
    lineBottom: LayoutUnit
  ) {
    if isLineBreak() || !paintInfo.shouldPaintWithinRoot(renderer: renderer())
      || renderer().style().usedVisibility() != .Visible
      || paintInfo.phase == .Outline || !hasTextContent()
    {
      return
    }

    assert(paintInfo.phase != .SelfOutline && paintInfo.phase != .ChildOutlines)

    let logicalLeftSide = logicalLeftVisualOverflow()
    let logicalRightSide = logicalRightVisualOverflow()
    let logicalStart = logicalLeftSide + (isHorizontal() ? paintOffset.x : paintOffset.y)
    let logicalExtent = logicalRightSide - logicalLeftSide

    let paintEnd = isHorizontal() ? paintInfo.rect.maxX() : paintInfo.rect.maxY()
    let paintStart = isHorizontal() ? paintInfo.rect.x() : paintInfo.rect.y()

    if logicalStart >= paintEnd || logicalStart + logicalExtent <= paintStart {
      return
    }

    let textBoxPainter = LegacyTextBoxPainter(
      textBox: self, paintInfo: paintInfo, paintOffset: paintOffset)
    textBoxPainter.paint()
  }

  override final func selectionState() -> RenderObjectWrapper.HighlightState {
    return renderer().view().selection().highlightStateForTextBox(
      renderer: renderer(), textBoxRange: selectableRange())
  }

  override final func isInlineTextBox() -> Bool { return true }

  // TODO(asuhan): remove when native GlyphDisplayListCache is available
  func getWkHandle() -> UnsafeMutableRawPointer {
    if self.wkHandle == nil {
      self.wkHandle = wk_interop.LegacyInlineTextBoxScion_create(
        Unmanaged.passUnretained(self).toOpaque())
    }
    return wkHandle!
  }

  deinit { if wkHandle != nil { wk_interop.LegacyInlineTextBoxScion_destroy(wkHandle!) } }

  private let m_nextTextBox: LegacyInlineTextBox? = nil  // The next box that also uses our RenderObject

  private let m_start: UInt32 = 0
  private let m_len: UInt32 = 0

  private var wkHandle: UnsafeMutableRawPointer? = nil
}
