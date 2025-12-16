/*
 * Copyright (C) 2002 Lars Knoll (knoll@kde.org)
 *           (C) 2002 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
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

final class AutoTableLayout: TableLayout {
  override func layout() {
    // table layout based on the values collected in the layout structure.
    let tableLogicalWidth = (table.logicalWidth() - table.bordersPaddingAndSpacingInRowDirection())
      .float()
    var available = tableLogicalWidth
    var nEffCols = Int(table.numEffCols())

    // FIXME: It is possible to be called without having properly updated our internal representation.
    // This means that our preferred logical widths were not recomputed as expected.
    if nEffCols != layoutStruct.count {
      fullRecalc()
      // FIXME: Table layout shouldn't modify our table structure (but does due to columns and column-groups).
      nEffCols = Int(table.numEffCols())
    }

    if effectiveLogicalWidthDirty {
      calcEffectiveLogicalWidth()
    }

    var havePercent = false
    var numFixed = 0
    var numberOfNonEmptyAuto = 0
    var totalAuto: Float32? = nil
    var totalFixed: Float32 = 0
    var totalPercent: Float32 = 0
    var allocAuto: Float32 = 0
    var numAutoEmptyCellsOnly = 0

    // fill up every cell with its minWidth
    for i in 0..<nEffCols {
      let cellLogicalWidth = layoutStruct[i].effectiveMinLogicalWidth
      layoutStruct[i].computedLogicalWidth = cellLogicalWidth
      available -= cellLogicalWidth
      let logicalWidth = layoutStruct[i].effectiveLogicalWidth
      switch logicalWidth.type() {
      case .Percent:
        havePercent = true
        totalPercent += logicalWidth.percent()
      case .Fixed:
        numFixed += 1
        totalFixed += layoutStruct[i].effectiveMaxLogicalWidth
      case .Auto:
        if layoutStruct[i].emptyCellsOnly {
          numAutoEmptyCellsOnly += 1
        } else {
          numberOfNonEmptyAuto += 1
          totalAuto = (totalAuto ?? 0) + layoutStruct[i].effectiveMaxLogicalWidth
          allocAuto += cellLogicalWidth
        }
      default:
        break
      }
    }

    // allocate width to percent cols
    if available > 0 && havePercent {
      for i in 0..<nEffCols {
        let logicalWidth = layoutStruct[i].effectiveLogicalWidth
        if logicalWidth.isPercentOrCalculated() {
          let cellLogicalWidth = max(
            layoutStruct[i].effectiveMinLogicalWidth,
            minimumValueForLength(length: logicalWidth, maximumValue: tableLogicalWidth).float())
          available += layoutStruct[i].computedLogicalWidth - cellLogicalWidth
          layoutStruct[i].computedLogicalWidth = cellLogicalWidth
        }
      }
      if totalPercent > 100 {
        // remove overallocated space from the last columns
        var excess = tableLogicalWidth * (totalPercent - 100) / 100
        for i in (0..<nEffCols).reversed() {
          if layoutStruct[i].effectiveLogicalWidth.isPercentOrCalculated() {
            let cellLogicalWidth = layoutStruct[i].computedLogicalWidth
            let reduction = min(cellLogicalWidth, excess)
            // the lines below might look inconsistent, but that's the way it's handled in mozilla
            excess -= reduction
            let newLogicalWidth = max(
              layoutStruct[i].effectiveMinLogicalWidth, cellLogicalWidth - reduction)
            available += cellLogicalWidth - newLogicalWidth
            layoutStruct[i].computedLogicalWidth = newLogicalWidth
          }
        }
      }
    }

    // then allocate width to fixed cols
    if available > 0 {
      for i in 0..<nEffCols {
        let logicalWidth = layoutStruct[i].effectiveLogicalWidth
        if logicalWidth.isFixed() && logicalWidth.value() > layoutStruct[i].computedLogicalWidth {
          available += layoutStruct[i].computedLogicalWidth - logicalWidth.value()
          layoutStruct[i].computedLogicalWidth = logicalWidth.value()
        }
      }
    }

    // now satisfy variable
    if available > 0 && numberOfNonEmptyAuto != 0 {
      assert(totalAuto != nil)
      available += allocAuto  // this gets redistributed.
      var equalWidthForZeroLengthColumns: Float32? = nil
      if totalAuto! == 0 {
        // All columns in this table are (non-empty)zero length with 'width: auto'.
        equalWidthForZeroLengthColumns = available / Float32(numberOfNonEmptyAuto)
      }
      for i in 0..<nEffCols {
        if !layoutStruct[i].effectiveLogicalWidth.isAuto() || layoutStruct[i].emptyCellsOnly {
          continue
        }
        let columnWidthCandidate =
          equalWidthForZeroLengthColumns != nil
          ? equalWidthForZeroLengthColumns!
          : available * layoutStruct[i].effectiveMaxLogicalWidth / totalAuto!
        layoutStruct[i].computedLogicalWidth = max(
          layoutStruct[i].computedLogicalWidth, columnWidthCandidate)
        available -= layoutStruct[i].computedLogicalWidth
        if equalWidthForZeroLengthColumns == nil {
          totalAuto! -= layoutStruct[i].effectiveMaxLogicalWidth
          if totalAuto! <= 0 {
            break
          }
        }
      }
    }

    // spread over fixed columns
    if available > 0 && numFixed != 0 {
      for i in 0..<nEffCols {
        let logicalWidth = layoutStruct[i].effectiveLogicalWidth
        if logicalWidth.isFixed() {
          let cellLogicalWidth = available * layoutStruct[i].effectiveMaxLogicalWidth / totalFixed
          available -= cellLogicalWidth
          totalFixed -= layoutStruct[i].effectiveMaxLogicalWidth
          layoutStruct[i].computedLogicalWidth += cellLogicalWidth
        }
      }
    }

    // spread over percent colums
    if available > 0 && hasPercent && totalPercent < 100 {
      for i in 0..<nEffCols {
        let logicalWidth = layoutStruct[i].effectiveLogicalWidth
        if logicalWidth.isPercent() {
          let cellLogicalWidth = available * logicalWidth.percent() / totalPercent
          available -= cellLogicalWidth
          totalPercent -= logicalWidth.percent()
          layoutStruct[i].computedLogicalWidth += cellLogicalWidth
          if available == 0 || totalPercent == 0 {
            break
          }
        }
      }
    }

    // spread over the rest
    if available > 0 && nEffCols > numAutoEmptyCellsOnly {
      var total = nEffCols - numAutoEmptyCellsOnly
      // still have some width to spread
      for i in (0..<nEffCols).reversed() {
        // variable columns with empty cells only don't get any width
        if layoutStruct[i].effectiveLogicalWidth.isAuto() && layoutStruct[i].emptyCellsOnly {
          continue
        }
        let cellLogicalWidth = available / Float32(total)
        available -= cellLogicalWidth
        total -= 1
        layoutStruct[i].computedLogicalWidth += cellLogicalWidth
      }
    }

    if available > 0 && numAutoEmptyCellsOnly != 0 && nEffCols == numAutoEmptyCellsOnly {
      // All columns in this table are empty with 'width: auto'.
      let equalWidthForColumns = available / Float32(numAutoEmptyCellsOnly)
      for i in 0..<nEffCols {
        layoutStruct[i].computedLogicalWidth = equalWidthForColumns
        available -= layoutStruct[i].computedLogicalWidth
      }
    }

    // If we have overallocated, reduce every cell according to the difference between desired width and minwidth
    // this seems to produce to the pixel exact results with IE. Wonder if some of this also holds for width distributing.
    if available < 0 {
      // Need to reduce cells with the following prioritization:
      // (1) Auto
      // (2) Fixed
      // (3) Percent
      // This is basically the reverse of how we grew the cells.
      var logicalWidthBeyondMin: Float32 = 0
      for i in (0..<nEffCols).reversed() {
        let logicalWidth = layoutStruct[i].effectiveLogicalWidth
        if logicalWidth.isAuto() {
          logicalWidthBeyondMin +=
            layoutStruct[i].computedLogicalWidth - layoutStruct[i].effectiveMinLogicalWidth
        }
      }

      for i in (0..<nEffCols).reversed() {
        if logicalWidthBeyondMin <= 0 {
          break
        }
        let logicalWidth = layoutStruct[i].effectiveLogicalWidth
        if logicalWidth.isAuto() {
          let minMaxDiff =
            layoutStruct[i].computedLogicalWidth - layoutStruct[i].effectiveMinLogicalWidth
          let reduce = available * minMaxDiff / logicalWidthBeyondMin
          layoutStruct[i].computedLogicalWidth += reduce
          available -= reduce
          logicalWidthBeyondMin -= minMaxDiff
          if available >= 0 {
            break
          }
        }
      }

      if available < 0 {
        var logicalWidthBeyondMin: Float32 = 0
        for i in (0..<nEffCols).reversed() {
          let logicalWidth = layoutStruct[i].effectiveLogicalWidth
          if logicalWidth.isFixed() {
            logicalWidthBeyondMin +=
              layoutStruct[i].computedLogicalWidth - layoutStruct[i].effectiveMinLogicalWidth
          }
        }

        for i in (0..<nEffCols).reversed() {
          if logicalWidthBeyondMin <= 0 {
            break
          }
          let logicalWidth = layoutStruct[i].effectiveLogicalWidth
          if logicalWidth.isFixed() {
            let minMaxDiff =
              layoutStruct[i].computedLogicalWidth - layoutStruct[i].effectiveMinLogicalWidth
            let reduce = available * minMaxDiff / logicalWidthBeyondMin
            layoutStruct[i].computedLogicalWidth += reduce
            available -= reduce
            logicalWidthBeyondMin -= minMaxDiff
            if available >= 0 {
              break
            }
          }
        }
      }

      if available < 0 {
        var logicalWidthBeyondMin: Float32 = 0
        for i in (0..<nEffCols).reversed() {
          let logicalWidth = layoutStruct[i].effectiveLogicalWidth
          if logicalWidth.isPercentOrCalculated() {
            logicalWidthBeyondMin +=
              layoutStruct[i].computedLogicalWidth - layoutStruct[i].effectiveMinLogicalWidth
          }
        }

        for i in (0..<nEffCols).reversed() {
          if logicalWidthBeyondMin <= 0 {
            break
          }
          let logicalWidth = layoutStruct[i].effectiveLogicalWidth
          if logicalWidth.isPercentOrCalculated() {
            let minMaxDiff =
              layoutStruct[i].computedLogicalWidth - layoutStruct[i].effectiveMinLogicalWidth
            let reduce = available * minMaxDiff / logicalWidthBeyondMin
            layoutStruct[i].computedLogicalWidth += reduce
            available -= reduce
            logicalWidthBeyondMin -= minMaxDiff
            if available >= 0 {
              break
            }
          }
        }
      }
    }

    var pos = LayoutUnit()
    for i in 0..<nEffCols {
      table.setColumnPosition(index: i, position: pos)
      pos +=
        LayoutUnit.fromFloatCeil(value: layoutStruct[i].computedLogicalWidth)
        + table.hBorderSpacing()
    }
    table.setColumnPosition(index: table.columnPositions().count - 1, position: pos)
  }

  private func fullRecalc() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calcEffectiveLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private struct Layout {
    let logicalWidth = LengthWrapper()
    let effectiveLogicalWidth = LengthWrapper()
    let minLogicalWidth: Float32 = 0
    let maxLogicalWidth: Float32 = 0
    let effectiveMinLogicalWidth: Float32 = 0
    let effectiveMaxLogicalWidth: Float32 = 0
    var computedLogicalWidth: Float32 = 0
    let emptyCellsOnly = true
  }

  private var layoutStruct: [Layout] = []
  private let hasPercent = false
  private let effectiveLogicalWidthDirty = false
}
