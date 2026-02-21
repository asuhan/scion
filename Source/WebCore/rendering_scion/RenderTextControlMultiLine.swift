/*
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2009 Apple Inc. All rights reserved.
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

import Foundation

final class RenderTextControlMultiLineWrapper: RenderTextControlWrapper {
  private func textAreaElement() -> HTMLTextAreaElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ action: HitTestAction
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func getAverageCharWidth() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func preferredContentLogicalWidth(_ charWidth: Float32) -> LayoutUnit {
    var width = ceilf(charWidth * Float32(textAreaElement().cols()))

    let overflow = style().isHorizontalWritingMode() ? style().overflowY() : style().overflowX()

    // We are able to have a vertical scrollbar if the overflow style is scroll or auto
    if (overflow == .Scroll) || (overflow == .Auto) {
      width += Float32(scrollbarThickness())
    }

    return LayoutUnit(value: width)
  }

  override final func computeControlLogicalHeight(
    lineHeight: LayoutUnit, nonContentHeight: LayoutUnit
  )
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layoutExcludedChildren(relayoutChildren: Bool) {
    super.layoutExcludedChildren(relayoutChildren: relayoutChildren)
    let placeholder = textFormControlElement().placeholderElement()
    guard let placeholderRenderer = placeholder?.renderer() else {
      return
    }
    guard let placeholderBox = placeholderRenderer as? RenderBoxWrapper else {
      return
    }
    placeholderBox.mutableStyle().setLogicalWidth(
      LengthWrapper(
        value: contentLogicalWidth() - placeholderBox.borderAndPaddingLogicalWidth(), type: .Fixed))
    placeholderBox.layoutIfNeeded()
    placeholderBox.setX(x: borderLeft() + paddingLeft())
    placeholderBox.setY(y: borderTop() + paddingTop())
  }
}
