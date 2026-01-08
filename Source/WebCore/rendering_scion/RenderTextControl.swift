/*
 * Copyright (C) 2006, 2007 Apple Inc. All rights reserved.
 *           (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

class RenderTextControlWrapper: RenderBlockFlowWrapper {
  func textFormControlElement() -> HTMLTextFormControlElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This convenience function should not be made public because innerTextElement may outlive the render tree.
  private func innerTextElement() -> TextControlInnerTextElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getAverageCharWidth() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func preferredContentLogicalWidth(_ charWidth: Float32) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layoutExcludedChildren(relayoutChildren: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // FIXME: Fix field-sizing: content with size containment
    // https://bugs.webkit.org/show_bug.cgi?id=269169
    if style().fieldSizing() == .Content {
      return super.computeIntrinsicLogicalWidths(
        minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
    }

    if shouldApplySizeOrInlineSizeContainment() {
      if let width = explicitIntrinsicInnerLogicalWidth() {
        minLogicalWidth = width
        maxLogicalWidth = width
      }
      return
    }
    // Use average character width. Matches IE.
    maxLogicalWidth = preferredContentLogicalWidth(getAverageCharWidth())
    if let innerTextRenderBox = innerTextElement() != nil ? innerTextElement()!.renderBox() : nil {
      maxLogicalWidth += innerTextRenderBox.paddingStart() + innerTextRenderBox.paddingEnd()
    }
    let logicalWidth = style().logicalWidth()
    if logicalWidth.isCalculated() {
      let zero = LayoutUnit(value: UInt64(0))
      minLogicalWidth = max(zero, valueForLength(length: logicalWidth, maximumValue: zero))
    } else if !logicalWidth.isPercent() {
      minLogicalWidth = maxLogicalWidth
    }
  }

  override func computePreferredLogicalWidths() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func avoidsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

// Renderer for our inner container, for <search> and others.
// We can't use RenderFlexibleBox directly, because flexboxes have a different
// baseline definition, and then inputs of different types wouldn't line up
// anymore.
final class RenderTextControlInnerContainerWrapper: RenderFlexibleBoxWrapper {
  override func isFlexibleBoxImpl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
