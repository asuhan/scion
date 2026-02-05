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

class LegacyInlineTextBox: LegacyInlineBox, DisplayTextBox {
  func renderer() -> RenderTextWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTextContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
