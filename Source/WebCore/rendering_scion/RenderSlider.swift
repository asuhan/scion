/*
 * Copyright (C) 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

final class RenderSliderWrapper: RenderFlexibleBoxWrapper {
  private static let defaultTrackLength: Int32 = 129

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    if shouldApplySizeOrInlineSizeContainment() {
      if let width = explicitIntrinsicInnerLogicalWidth() {
        minLogicalWidth = width
        maxLogicalWidth = width
      }
      return
    }
    maxLogicalWidth = LayoutUnit(
      value: Float32(RenderSliderWrapper.defaultTrackLength) * style().usedZoom())
    let logicalWidth = style().logicalWidth()
    if logicalWidth.isCalculated() {
      let zero = LayoutUnit(value: UInt64(0))
      minLogicalWidth = max(zero, valueForLength(length: logicalWidth, maximumValue: zero))
    } else if !logicalWidth.isPercent() {
      minLogicalWidth = maxLogicalWidth
    }
  }

  override func computePreferredLogicalWidths() {
    m_minPreferredLogicalWidth = LayoutUnit(value: 0)
    m_maxPreferredLogicalWidth = LayoutUnit(value: 0)

    if style().width().isFixed() && style().width().value() > 0 {
      m_maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().width())
      m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &m_minPreferredLogicalWidth, maxLogicalWidth: &m_maxPreferredLogicalWidth)
    }

    renderBoxComputePreferredLogicalWidths(
      style().minWidth(), style().maxWidth(), horizontalBorderAndPaddingExtent())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override func isFlexibleBoxImpl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
