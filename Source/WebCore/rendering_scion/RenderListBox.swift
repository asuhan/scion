/*
 * This file is part of the select element renderer in WebCore.
 *
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

private let itemBlockSpacing: Int32 = 1

private let optionsSpacingInlineStart: Int32 = 2

// Default size when the multiple attribute is present but size attribute is absent.
private let defaultSize: Int32 = 4

final class RenderListBoxWrapper: RenderBlockFlowWrapper {
  private func selectElement() -> HTMLSelectElementWrapper {
    return nodeForNonAnonymous() as! HTMLSelectElementWrapper
  }

  private func size() -> UInt32 {
    if style().fieldSizing() == .Content {
      return UInt32(numItems())
    }

    let specifiedSize = selectElement().size()
    if specifiedSize >= 1 {
      return specifiedSize
    }

    return UInt32(defaultSize)
  }

  override func hasControlClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    // Clip against the padding box, to give <option>s and overlay scrollbar some extra space
    // to get painted.
    var clipRect = paddingBoxRect()
    clipRect.moveBy(offset: additionalOffset)
    return clipRect
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    if shouldApplySizeOrInlineSizeContainment() {
      if let logicalWidth = explicitIntrinsicInnerLogicalWidth() {
        maxLogicalWidth = logicalWidth
      } else {
        maxLogicalWidth = LayoutUnit(value: 2 * optionsSpacingInlineStart)
      }
    } else {
      maxLogicalWidth = LayoutUnit(value: 2 * optionsSpacingInlineStart + optionsLogicalWidth)
    }

    if scrollbar != nil {
      maxLogicalWidth +=
        scrollbar!.orientation() == .Vertical ? scrollbar!.width() : scrollbar!.height()
    }

    let logicalWidth = style().logicalWidth()
    if logicalWidth.isCalculated() {
      let zero = LayoutUnit(value: UInt64(0))
      minLogicalWidth = max(zero, valueForLength(length: logicalWidth, maximumValue: zero))
    } else if !logicalWidth.isPercent() {
      minLogicalWidth = maxLogicalWidth
    }
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    var logicalHeight = itemLogicalHeight() * size() - itemBlockSpacing

    if shouldApplySizeContainment(),
      let explicitIntrinsicHeight = explicitIntrinsicInnerLogicalHeight()
    {
      logicalHeight = explicitIntrinsicHeight
    }

    cacheIntrinsicContentLogicalHeightForFlexItem(height: logicalHeight)
    logicalHeight +=
      style().isHorizontalWritingMode()
      ? verticalBorderAndPaddingExtent() : horizontalBorderAndPaddingExtent()
    return boxComputeLogicalHeight(logicalHeight: logicalHeight, logicalTop: logicalTop)
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func verticalScrollbarWidth() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func horizontalScrollbarHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  final override func useDarkAppearance() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func itemLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func numItems() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let optionsLogicalWidth: Int32 = 0

  private let scrollbar: Scrollbar? = nil
}
