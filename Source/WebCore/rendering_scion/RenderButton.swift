/*
 * Copyright (C) 2005-2022 Apple Inc.
 * Copyright (C) 2022 Google Inc. All rights reserved.
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

final class RenderButtonWrapper: RenderFlexibleBoxWrapper {
  override func canBeSelectionLeaf() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createsAnonymousWrapper() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func hasControlClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    // Clip to the padding box to at least give content the extra padding space.
    return LayoutRectWrapper(
      x: additionalOffset.x + borderLeft(), y: additionalOffset.y + borderTop(),
      width: width() - borderLeft() - borderRight(), height: height() - borderTop() - borderBottom()
    )
  }

  override func updateAnonymousChildStyle(_ childStyle: RenderStyleWrapper) {
    childStyle.setFlexGrow(1)

    // min-inline-size: 0; is needed for correct shrinking.
    // Use margin-block:auto instead of align-items:center to get safe centering, i.e.
    // when the content overflows, treat it the same as align-items: flex-start.
    if isHorizontalWritingMode() {
      childStyle.setMinWidth(LengthWrapper(value: Int32(0), type: .Fixed))
      childStyle.setMarginTop(LengthWrapper())
      childStyle.setMarginBottom(LengthWrapper())
    } else {
      childStyle.setMinHeight(LengthWrapper(value: Int32(0), type: .Fixed))
      childStyle.setMarginLeft(LengthWrapper())
      childStyle.setMarginRight(LengthWrapper())
    }
    childStyle.setFlexDirection(style().flexDirection())
    childStyle.setJustifyContent(style().justifyContent())
    childStyle.setFlexWrap(style().flexWrap())
    childStyle.setAlignItems(style().alignItems())
    childStyle.setAlignContent(style().alignContent())
  }

  func innerRenderer() -> RenderBlockWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInnerRenderer(innerRenderer: RenderBlockWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func hasLineIfEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isFlexibleBoxImpl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
