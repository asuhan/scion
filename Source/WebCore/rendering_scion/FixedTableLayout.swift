/*
 * Copyright (C) 2002 Lars Knoll (knoll@kde.org)
 *           (C) 2002 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2024 Apple Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License.
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
 */

final class FixedTableLayout: TableLayout {
  override init(table: RenderTableWrapper) {
    super.init(table: table)
  }

  override func layout() {
    let tableLogicalWidth = (table.logicalWidth() - table.bordersPaddingAndSpacingInRowDirection())
      .float()
    var nEffCols = table.numEffCols()

    // FIXME: It is possible to be called without having properly updated our internal representation.
    // This means that our preferred logical widths were not recomputed as expected.
    if nEffCols != width.count {
      calcWidthArray()
      // FIXME: Table layout shouldn't modify our table structure (but does due to columns and column-groups).
      nEffCols = table.numEffCols()
    }

    var calcWidth = [Float32](repeating: 0, count: Int(nEffCols))

    var numAuto: UInt32 = 0
    var autoSpan: UInt32 = 0
    var totalFixedWidth: Float32 = 0
    var totalPercentWidth: Float32 = 0
    var totalPercent: Float32 = 0

    // Compute requirements and try to satisfy fixed and percent widths.
    // Percentages are of the table's width, so for example
    // for a table width of 100px with columns (40px, 10%), the 10% compute
    // to 10px here, and will scale up to 20px in the final (80px, 20px).
    for i in 0..<Int(nEffCols) {
      if width[i].isFixed() {
        calcWidth[i] = width[i].value()
        totalFixedWidth += calcWidth[i]
      } else if width[i].isPercent() {
        calcWidth[i] = valueForLength(length: width[i], maximumValue: tableLogicalWidth).float()
        totalPercentWidth += calcWidth[i]
        totalPercent += width[i].percent()
      } else if width[i].isAuto() {
        numAuto += 1
        autoSpan += table.spanOfEffCol(effCol: UInt32(i))
      }
    }

    let hspacing = table.hBorderSpacing()
    var totalWidth = totalFixedWidth + totalPercentWidth
    if numAuto == 0 || totalWidth > tableLogicalWidth {
      // If there are no auto columns, or if the total is too wide, take
      // what we have and scale it to fit as necessary.
      if totalWidth != tableLogicalWidth {
        // Fixed widths only scale up
        if totalFixedWidth != 0 && totalWidth < tableLogicalWidth {
          totalFixedWidth = 0
          for i in 0..<Int(nEffCols) {
            if width[i].isFixed() {
              calcWidth[i] = calcWidth[i] * tableLogicalWidth / totalWidth
              totalFixedWidth += calcWidth[i]
            }
          }
        }
        if totalPercent != 0 {
          totalPercentWidth = 0
          for i in 0..<Int(nEffCols) {
            if width[i].isPercent() {
              calcWidth[i] =
                width[i].percent() * (tableLogicalWidth - totalFixedWidth) / totalPercent
              totalPercentWidth += calcWidth[i]
            }
          }
        }
        totalWidth = totalFixedWidth + totalPercentWidth
      }
    } else {
      // Divide the remaining width among the auto columns.
      assert(autoSpan >= numAuto)
      var remainingWidth =
        tableLogicalWidth - totalFixedWidth - totalPercentWidth - hspacing
        * Float32(autoSpan - numAuto)
      var lastAuto = 0
      for i in 0..<Int(nEffCols) {
        if width[i].isAuto() {
          let span = table.spanOfEffCol(effCol: UInt32(i))
          let w = remainingWidth * Float32(span) / Float32(autoSpan)
          calcWidth[i] = w + hspacing * (span - 1)
          remainingWidth -= w
          if remainingWidth == 0 {
            break
          }
          lastAuto = i
          numAuto -= 1
          assert(autoSpan >= span)
          autoSpan -= span
        }
      }
      // Last one gets the remainder.
      if remainingWidth != 0 {
        calcWidth[lastAuto] += remainingWidth
      }
      totalWidth = tableLogicalWidth
    }

    if totalWidth < tableLogicalWidth {
      // Spread extra space over columns.
      var remainingWidth = tableLogicalWidth - totalWidth
      var total = Int(nEffCols)
      while total != 0 {
        let w = remainingWidth / Float32(total)
        remainingWidth -= w
        total -= 1
        calcWidth[total] += w
      }
      if nEffCols > 0 {
        calcWidth[Int(nEffCols) - 1] += remainingWidth
      }
    }

    var pos: Float32 = 0
    for i in 0..<Int(nEffCols) {
      table.setColumnPosition(index: i, position: LayoutUnit(value: pos))
      pos += calcWidth[i] + hspacing
    }
    let colPositionsSize = table.columnPositions().count
    if colPositionsSize > 0 {
      table.setColumnPosition(index: colPositionsSize - 1, position: LayoutUnit(value: pos))
    }
  }

  @discardableResult
  private func calcWidthArray() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let width: [LengthWrapper] = []
}
