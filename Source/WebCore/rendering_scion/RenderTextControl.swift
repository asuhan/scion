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

  private func scrollbarThickness() -> Int32 {
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

  func computeControlLogicalHeight(lineHeight: LayoutUnit, nonContentHeight: LayoutUnit)
    -> LayoutUnit
  {
    fatalError("Not reached")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    guard let innerText = innerTextElement() else {
      return boxComputeLogicalHeight(logicalHeight: LayoutUnit(), logicalTop: LayoutUnit())
    }

    if style().fieldSizing() == .Content {
      return boxComputeLogicalHeight(logicalHeight: logicalHeight, logicalTop: logicalTop)
    }

    var logicalHeight = logicalHeight
    if let innerTextBox = innerText.renderBox() {
      let nonContentHeight =
        innerTextBox.borderAndPaddingLogicalHeight() + innerTextBox.marginLogicalHeight()
      logicalHeight = computeControlLogicalHeight(
        lineHeight: innerTextBox.lineHeight(
          firstLine: true, direction: .HorizontalLine,
          linePositionMode: .PositionOfInteriorLineBoxes),
        nonContentHeight: nonContentHeight)

      // We are able to have a horizontal scrollbar if the overflow style is scroll, or if its auto and there's no word wrap.
      let style = style()
      let isHorizontalWritingMode = isHorizontalWritingMode()
      let shouldIncludeScrollbarHeight =
        (isHorizontalWritingMode && style.overflowX() == .Scroll)
        || (!isHorizontalWritingMode && style.overflowY() == .Scroll)
      if shouldIncludeScrollbarHeight {
        logicalHeight += scrollbarThickness()
      }

      // FIXME: The logical height of the inner text box should have been added
      // before calling computeLogicalHeight to avoid this hack.
      cacheIntrinsicContentLogicalHeightForFlexItem(height: logicalHeight)

      logicalHeight += borderAndPaddingLogicalHeight()
    }

    return boxComputeLogicalHeight(logicalHeight: logicalHeight, logicalTop: logicalTop)
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
    assert(preferredLogicalWidthsDirty())
    if style().fieldSizing() == .Content {
      super.computePreferredLogicalWidths()
      return
    }

    minPreferredLogicalWidth = LayoutUnit(value: 0)
    maxPreferredLogicalWidth = LayoutUnit(value: 0)

    if style().logicalWidth().isFixed() && style().logicalWidth().value() >= 0 {
      maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().logicalWidth())
      minPreferredLogicalWidth = maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &minPreferredLogicalWidth, maxLogicalWidth: &maxPreferredLogicalWidth)
    }

    super.computePreferredLogicalWidths(
      minWidth: style().logicalMinWidth(), maxWidth: style().logicalMaxWidth(),
      borderAndPadding: borderAndPaddingLogicalWidth())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
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
