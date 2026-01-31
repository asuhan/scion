/*
 * This file is part of the select element renderer in WebCore.
 *
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2015 Apple Inc. All rights reserved.
 *               2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

// TODO(asuhan): inherit from PopupMenuClient as well
final class RenderMenuListWrapper: RenderFlexibleBoxWrapper {
  func innerRenderer() -> RenderBlockWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInnerRenderer(innerRenderer: RenderBlockWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createsAnonymousWrapper() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    // Clip to the intersection of the content box and the content box for the inner box
    // This will leave room for the arrows which sit in the inner box padding,
    // and if the inner box ever spills out of the outer box, that will get clipped too.
    let outerBox = LayoutRectWrapper(
      x: additionalOffset.x + borderLeft() + paddingLeft(),
      y: additionalOffset.y + borderTop() + paddingTop(),
      width: contentWidth(),
      height: contentHeight())

    let innerBox = LayoutRectWrapper(
      x: additionalOffset.x + innerBlock!.x() + innerBlock!.paddingLeft(),
      y: additionalOffset.y + innerBlock!.y() + innerBlock!.paddingTop(),
      width: innerBlock!.contentWidth(),
      height: innerBlock!.contentHeight())

    return intersection(a: outerBox, b: innerBox)
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

    maxLogicalWidth = LayoutUnit(
      value: shouldApplySizeContainment()
        ? theme().minimumMenuListSize(style())
        : max(optionsWidth, theme().minimumMenuListSize(style())))
    maxLogicalWidth += innerBlock!.paddingStart() + innerBlock!.paddingEnd()
    if shouldApplySizeOrInlineSizeContainment(),
      let logicalWidth = explicitIntrinsicInnerLogicalWidth()
    {
      maxLogicalWidth = logicalWidth
    }
    let logicalWidth = style().logicalWidth()
    if logicalWidth.isCalculated() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    } else if !logicalWidth.isPercent() {
      minLogicalWidth = maxLogicalWidth
    }
  }

  override func computePreferredLogicalWidths() {
    if style().fieldSizing() == .Content {
      super.computePreferredLogicalWidths()
      return
    }

    minPreferredLogicalWidth = LayoutUnit(value: 0)
    maxPreferredLogicalWidth = LayoutUnit(value: 0)

    if style().logicalWidth().isFixed() && style().logicalWidth().value() > 0 {
      maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().logicalWidth())
      minPreferredLogicalWidth = maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &minPreferredLogicalWidth, maxLogicalWidth: &maxPreferredLogicalWidth)
    }

    super.computePreferredLogicalWidths(
      style().logicalMinWidth(), style().logicalMaxWidth(),
      style().isHorizontalWritingMode()
        ? horizontalBorderAndPaddingExtent() : verticalBorderAndPaddingExtent())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
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

  private let innerBlock: RenderBlockWrapper? = nil

  private let optionsWidth: Int32 = 0
}
