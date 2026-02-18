/*
 * Copyright (C) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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

final class RenderProgressWrapper: RenderBlockFlowWrapper {
  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    var computedValues = boxComputeLogicalHeight(
      logicalHeight: logicalHeight, logicalTop: logicalTop)
    let frame = frameRect()
    if isHorizontalWritingMode() {
      frame.setHeight(height: computedValues.extent)
    } else {
      frame.setWidth(width: computedValues.extent)
    }
    let frameSize = theme().progressBarRectForBounds(self, snappedIntRect(rect: frame)).size
    computedValues.extent = LayoutUnit(
      value: isHorizontalWritingMode() ? frameSize.height : frameSize.width)
    return computedValues
  }
}
