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
  init(_ element: HTMLTextAreaElementWrapper, _ style: RenderStyleWrapper) {
    super.init(type: .TextControlMultiLine, element: element, style: style)
    assert(isRenderTextControlMultiLine())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  private func textAreaElement() -> HTMLTextAreaElementWrapper {
    assert(isNativeImpl())
    return textFormControlElement() as! HTMLTextAreaElementWrapper
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    if !super.nodeAtPoint(request, &result, locationInContainer, accumulatedOffset, hitTestAction) {
      return false
    }

    let adjustedPoint = accumulatedOffset + location()
    if isPointInOverflowControl(
      &result, locationInContainer: locationInContainer.point(), accumulatedOffset: adjustedPoint)
    {
      return true
    }

    if optEq(result.innerNode(), textAreaElement()) || optEq(result.innerNode(), innerTextElement())
    {
      hitInnerTextElement(&result, locationInContainer.point(), accumulatedOffset)
    }

    return true
  }

  override final func getAverageCharWidth() -> Float32 {
    assert(isNativeImpl())
    // TODO(asuhan): add iOS support
    // Since Lucida Grande is the default font, we want this to match the width
    // of Courier New, the default font for textareas in IE, Firefox and Safari Win.
    // 1229 is the avgCharWidth value in the OS/2 table for Courier New.
    if style().fontCascade().firstFamily().string() == StringWrapper(ASCIILiteral("Lucida Grande"))
    {
      return scaleEmToUnits(1229)
    }

    return super.getAverageCharWidth()
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
    assert(isNativeImpl())
    return lineHeight * textAreaElement().rows() + nonContentHeight
  }

  override final func baselinePosition(
    baselineType: FontBaseline, firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return boxBaselinePosition(
      baselineType: baselineType, firstLine: firstLine, direction: direction,
      linePositionMode: linePositionMode)
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
