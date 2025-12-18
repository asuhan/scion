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
    hasPercent = false
    effectiveLogicalWidthDirty = true

    let nEffCols = table.numEffCols()
    layoutStruct = [Layout](repeating: Layout(), count: Int(nEffCols))
    for i in 0..<spanCells.count {
      spanCells[i] = nil
    }

    var groupLogicalWidth = LengthWrapper()
    var currentColumn: UInt32 = 0
    var column = table.firstColumn()
    while column != nil {
      if column!.isTableColumnGroupWithColumnChildren() {
        groupLogicalWidth = column!.style().logicalWidth()
      } else {
        var colLogicalWidth = column!.style().logicalWidth()
        // FIXME: calc() on tables should be handled consistently with other lengths.
        if colLogicalWidth.isCalculated() || colLogicalWidth.isAuto() {
          colLogicalWidth = groupLogicalWidth
        }
        if (colLogicalWidth.isFixed() || colLogicalWidth.isPercentOrCalculated())
          && colLogicalWidth.isZero()
        {
          colLogicalWidth = LengthWrapper()
        }
        let effCol = Int(table.colToEffCol(column: currentColumn))
        let span = column!.span
        if !colLogicalWidth.isAuto() && span == 1 && effCol < nEffCols
          && table.spanOfEffCol(effCol: UInt32(effCol)) == 1
        {
          layoutStruct[effCol].logicalWidth = colLogicalWidth
          if colLogicalWidth.isFixed()
            && layoutStruct[effCol].maxLogicalWidth < colLogicalWidth.value()
          {
            layoutStruct[effCol].maxLogicalWidth = colLogicalWidth.value()
          }
        }
        currentColumn += span
      }

      // For the last column in a column-group, we invalidate our group logical width.
      if column!.isTableColumn() && column!.nextSibling() == nil {
        groupLogicalWidth = LengthWrapper()
      }

      column = column!.nextColumn()
    }

    for i in 0..<UInt32(nEffCols) {
      recalcColumn(effCol: i)
    }

    for section: RenderTableSectionWrapper in childrenOfType(parent: table) {
      section.setPreferredLogicalWidthsDirty(shouldBeDirty: false)
      var row = section.firstRow()
      while row != nil {
        row!.setPreferredLogicalWidthsDirty(shouldBeDirty: false)
        row = row!.nextRow()
      }
    }
  }

  func recalcColumn(effCol: UInt32) {
    var fixedContributor: RenderTableCellWrapper? = nil
    var maxContributor: RenderTableCellWrapper? = nil
    let ec = Int(effCol)

    for child: RenderObjectWrapper in childrenOfType(parent: table) {
      if let column = child as? RenderTableColWrapper {
        // RenderTableCols don't have the concept of preferred logical width, but we need to clear their dirty bits
        // so that if we call setPreferredWidthsDirty(true) on a col or one of its descendants, we'll mark its
        // ancestors as dirty.
        column.clearPreferredLogicalWidthsDirtyBits()
      } else if let section = child as? RenderTableSectionWrapper {
        let numRows = section.numRows()
        for i in 0..<numRows {
          let current = section.cellAt(row: i, col: effCol)
          let cell = current.primaryCell()

          if current.inColSpan || cell == nil {
            continue
          }

          let cellHasContent =
            cell!.firstChild() != nil || cell!.style().hasBorder() || cell!.style().hasPadding()
            || cell!.style().hasBackground()
          if cellHasContent {
            layoutStruct[ec].emptyCellsOnly = false
          }

          // A cell originates in this column. Ensure we have
          // a min/max width of at least 1px for this column now.
          layoutStruct[ec].minLogicalWidth = max(layoutStruct[ec].minLogicalWidth, 0.0)
          layoutStruct[ec].maxLogicalWidth = max(layoutStruct[ec].maxLogicalWidth, 0.0)

          if cell!.colSpan() == 1 {
            layoutStruct[ec].minLogicalWidth = max(
              cell!.minPreferredLogicalWidth().ceilToFloat(), layoutStruct[ec].minLogicalWidth)
            let maxPreferredWidth = cell!.maxPreferredLogicalWidth().ceilToFloat()
            if maxPreferredWidth > layoutStruct[ec].maxLogicalWidth {
              layoutStruct[ec].maxLogicalWidth = maxPreferredWidth
              maxContributor = cell
            }

            // All browsers implement a size limit on the cell's max width.
            // Our limit is based on KHTML's representation that used 16 bits widths.
            // FIXME: Other browsers have a lower limit for the cell's max width.
            let cCellMaxWidth: Float32 = 32760
            let cellLogicalWidth = cell!.styleOrColLogicalWidth()
            if cellLogicalWidth.isFixed() {
              if cellLogicalWidth.value() > cCellMaxWidth {
                cellLogicalWidth.setValue(type: .Fixed, value: cCellMaxWidth)
              }
              if cellLogicalWidth.isNegative() {
                cellLogicalWidth.setValue(type: .Fixed, value: Int32(0))
              }
            }
            switch cellLogicalWidth.type() {
            case .Fixed:
              // ignore width=0
              if cellLogicalWidth.isPositive()
                && !layoutStruct[ec].logicalWidth.isPercentOrCalculated()
              {
                let logicalWidth = cell!.adjustBorderBoxLogicalWidthForBoxSizing(
                  logicalWidth: cellLogicalWidth
                ).float()
                if layoutStruct[ec].logicalWidth.isFixed() {
                  // Nav/IE weirdness
                  if (logicalWidth > layoutStruct[ec].logicalWidth.value())
                    || ((layoutStruct[ec].logicalWidth.value() == logicalWidth)
                      && (CPtrToInt(maxContributor?.p) == CPtrToInt(cell!.p)))
                  {
                    layoutStruct[ec].logicalWidth.setValue(type: .Fixed, value: logicalWidth)
                    fixedContributor = cell
                  }
                } else {
                  layoutStruct[ec].logicalWidth.setValue(type: .Fixed, value: logicalWidth)
                  fixedContributor = cell
                }
              }
            case .Percent:
              hasPercent = true
              if cellLogicalWidth.isPositive()
                && (!layoutStruct[ec].logicalWidth.isPercent()
                  || cellLogicalWidth.percent() > layoutStruct[ec].logicalWidth.percent())
              {
                layoutStruct[ec].logicalWidth = cellLogicalWidth
              }
            case .Calculated:
              layoutStruct[ec].logicalWidth = LengthWrapper()
            default:
              break
            }
          } else if effCol == 0
            || CPtrToInt(section.primaryCellAt(row: i, col: effCol - 1)?.p) != CPtrToInt(cell!.p)
          {
            // This spanning cell originates in this column. Insert the cell into spanning cells list.
            insertSpanCell(cell: cell)
          }
        }
      }
    }

    // Nav/IE weirdness
    if layoutStruct[ec].logicalWidth.isFixed() {
      if table.document().inQuirksMode()
        && layoutStruct[ec].maxLogicalWidth > layoutStruct[ec].logicalWidth.value()
        && CPtrToInt(fixedContributor?.p) != CPtrToInt(maxContributor?.p)
      {
        layoutStruct[ec].logicalWidth = LengthWrapper()
        fixedContributor = nil
      }
    }

    layoutStruct[ec].maxLogicalWidth = max(
      layoutStruct[ec].maxLogicalWidth, layoutStruct[ec].minLogicalWidth)
  }

  /*
  This method takes care of colspans.
  effWidth is the same as width for cells without colspans. If we have colspans, they get modified.
 */
  @discardableResult
  private func calcEffectiveLogicalWidth() -> Float32 {
    var maxLogicalWidth: Float32 = 0

    let nEffCols = layoutStruct.count
    let spacingInRowDirection = table.hBorderSpacing().float()

    for i in 0..<nEffCols {
      layoutStruct[i].effectiveLogicalWidth = layoutStruct[i].logicalWidth
      layoutStruct[i].effectiveMinLogicalWidth = layoutStruct[i].minLogicalWidth
      layoutStruct[i].effectiveMaxLogicalWidth = layoutStruct[i].maxLogicalWidth
    }

    for cell in spanCells {
      if cell == nil {
        break
      }

      var span = cell!.colSpan()

      var cellLogicalWidth = cell!.styleOrColLogicalWidth()
      if cellLogicalWidth.isZero() {
        cellLogicalWidth = LengthWrapper()  // make it Auto
      }

      let effCol = table.colToEffCol(column: cell!.col())
      var lastCol = effCol
      var cellMinLogicalWidth = cell!.minPreferredLogicalWidth() + spacingInRowDirection
      var cellMaxLogicalWidth = cell!.maxPreferredLogicalWidth() + spacingInRowDirection
      var totalPercent: Float32 = 0
      var spanMinLogicalWidth: Float32 = 0
      var spanMaxLogicalWidth: Float32 = 0
      var allColsArePercent = true
      var allColsAreFixed = true
      var haveAuto = false
      var spanHasEmptyCellsOnly = true
      var fixedWidth: Float32 = 0
      while lastCol < nEffCols && span > 0 {
        var columnLayout = layoutStruct[Int(lastCol)]
        switch columnLayout.logicalWidth.type() {
        case .Percent:
          totalPercent += columnLayout.logicalWidth.percent()
          allColsAreFixed = false
        case .Fixed:
          if columnLayout.logicalWidth.value() > 0 {
            fixedWidth += columnLayout.logicalWidth.value()
            allColsArePercent = false
            // IE resets effWidth to Auto here, but this breaks the konqueror about page and seems to be some bad
            // legacy behaviour anyway. mozilla doesn't do this so I decided we don't neither.
            break
          }
          fallthrough
        case .Auto:
          haveAuto = true
          fallthrough
        default:
          // If the column is a percentage width, do not let the spanning cell overwrite the
          // width value.  This caused a mis-rendering on amazon.com.
          // Sample snippet:
          // <table border=2 width=100%><
          //   <tr><td>1</td><td colspan=2>2-3</tr>
          //   <tr><td>1</td><td colspan=2 width=100%>2-3</td></tr>
          // </table>
          if !columnLayout.effectiveLogicalWidth.isPercent() {
            columnLayout.effectiveLogicalWidth = LengthWrapper()
            allColsArePercent = false
          } else {
            totalPercent += columnLayout.effectiveLogicalWidth.percent()
          }
          allColsAreFixed = false
        }
        if !columnLayout.emptyCellsOnly {
          spanHasEmptyCellsOnly = false
        }
        span -= table.spanOfEffCol(effCol: lastCol)
        spanMinLogicalWidth += columnLayout.effectiveMinLogicalWidth
        spanMaxLogicalWidth += columnLayout.effectiveMaxLogicalWidth
        lastCol += 1
        cellMinLogicalWidth -= spacingInRowDirection
        cellMaxLogicalWidth -= spacingInRowDirection
      }

      // adjust table max width if needed
      if cellLogicalWidth.isPercent() {
        if totalPercent > cellLogicalWidth.percent() || allColsArePercent {
          // can't satify this condition, treat as variable
          cellLogicalWidth = LengthWrapper()
        } else {
          maxLogicalWidth = max(
            maxLogicalWidth,
            max(spanMaxLogicalWidth, cellMaxLogicalWidth) * 100 / cellLogicalWidth.percent())

          // all non percent columns in the span get percent values to sum up correctly.
          var percentMissing = cellLogicalWidth.percent() - totalPercent
          var totalWidth: Float32 = 0
          for pos in Int(effCol)..<Int(lastCol) {
            if !layoutStruct[pos].effectiveLogicalWidth.isPercentOrCalculated() {
              totalWidth += layoutStruct[pos].effectiveMaxLogicalWidth
            }
          }

          for pos in Int(effCol)..<Int(lastCol) {
            if !layoutStruct[pos].effectiveLogicalWidth.isPercentOrCalculated() {
              // Handle the case when there's only one cell with 'width: percent' and it's empty.
              let percent =
                percentMissing
                * (totalWidth != 0 ? layoutStruct[pos].effectiveMaxLogicalWidth / totalWidth : 1)
              totalWidth -= layoutStruct[pos].effectiveMaxLogicalWidth
              percentMissing -= percent
              if percent > 0 {
                layoutStruct[pos].effectiveLogicalWidth.setValue(type: .Percent, value: percent)
              } else {
                layoutStruct[pos].effectiveLogicalWidth = LengthWrapper()
              }
            }
            if totalWidth <= 0 {
              break
            }
          }
        }
      }

      // make sure minWidth and maxWidth of the spanning cell are honoured
      if cellMinLogicalWidth > spanMinLogicalWidth {
        if allColsAreFixed {
          for pos in Int(effCol)..<Int(lastCol) {
            if fixedWidth <= 0 {
              break
            }
            let cellLogicalWidth = max(
              layoutStruct[pos].effectiveMinLogicalWidth,
              cellMinLogicalWidth * layoutStruct[pos].logicalWidth.value() / fixedWidth)
            fixedWidth -= layoutStruct[pos].logicalWidth.value()
            cellMinLogicalWidth -= cellLogicalWidth
            layoutStruct[pos].effectiveMinLogicalWidth = cellLogicalWidth
          }
        } else if allColsArePercent {
          // In this case, we just split the colspan's min amd max widths following the percentage.
          #if ASSERT_ENABLED
            var allocatedMinLogicalWidth: Float32 = 0
          #endif
          var allocatedMaxLogicalWidth: Float32 = 0
          for pos in Int(effCol)..<Int(lastCol) {
            assert(
              layoutStruct[pos].logicalWidth.isPercent()
                || layoutStruct[pos].effectiveLogicalWidth.isPercent())
            // |allColsArePercent| means that either the logicalWidth *or* the effectiveLogicalWidth are percents, handle both of them here.
            let percent =
              layoutStruct[pos].logicalWidth.isPercent()
              ? layoutStruct[pos].logicalWidth.percent()
              : layoutStruct[pos].effectiveLogicalWidth.percent()
            let columnMinLogicalWidth = percent * cellMinLogicalWidth / totalPercent
            let columnMaxLogicalWidth = percent * cellMaxLogicalWidth / totalPercent
            layoutStruct[pos].effectiveMinLogicalWidth = max(
              layoutStruct[pos].effectiveMinLogicalWidth, columnMinLogicalWidth)
            layoutStruct[pos].effectiveMaxLogicalWidth = columnMaxLogicalWidth
            #if ASSERT_ENABLED
              allocatedMinLogicalWidth += columnMinLogicalWidth
            #endif
            allocatedMaxLogicalWidth += columnMaxLogicalWidth
          }
          #if ASSERT_ENABLED
            assert(
              allocatedMinLogicalWidth < cellMinLogicalWidth
                || WTF.areEssentiallyEqual(u: allocatedMinLogicalWidth, v: cellMinLogicalWidth))
          #endif
          assert(
            allocatedMaxLogicalWidth < cellMaxLogicalWidth
              || WTF.areEssentiallyEqual(u: allocatedMaxLogicalWidth, v: cellMaxLogicalWidth))
          cellMaxLogicalWidth -= allocatedMaxLogicalWidth
        } else {
          var remainingMaxLogicalWidth = spanMaxLogicalWidth
          var remainingMinLogicalWidth = spanMinLogicalWidth

          // Give min to variable first, to fixed second, and to others third.
          for pos in Int(effCol)..<Int(lastCol) {
            if remainingMaxLogicalWidth < 0 {
              break
            }
            if layoutStruct[pos].logicalWidth.isFixed() && haveAuto
              && fixedWidth <= cellMinLogicalWidth
            {
              let colMinLogicalWidth = max(
                layoutStruct[pos].effectiveMinLogicalWidth, layoutStruct[pos].logicalWidth.value())
              fixedWidth -= layoutStruct[pos].logicalWidth.value()
              remainingMinLogicalWidth -= layoutStruct[pos].effectiveMinLogicalWidth
              remainingMaxLogicalWidth -= layoutStruct[pos].effectiveMaxLogicalWidth
              cellMinLogicalWidth -= colMinLogicalWidth
              layoutStruct[pos].effectiveMinLogicalWidth = colMinLogicalWidth
            }
          }

          for pos in Int(effCol)..<Int(lastCol) {
            if remainingMaxLogicalWidth < 0 || remainingMinLogicalWidth >= cellMinLogicalWidth {
              break
            }
            if layoutStruct[pos].logicalWidth.isFixed() && haveAuto
              && fixedWidth <= cellMinLogicalWidth
            {
              continue
            }
            var colMinLogicalWidth = max(
              layoutStruct[pos].effectiveMinLogicalWidth,
              remainingMaxLogicalWidth != 0
                ? cellMinLogicalWidth * layoutStruct[pos].effectiveMaxLogicalWidth
                  / remainingMaxLogicalWidth : cellMinLogicalWidth)
            colMinLogicalWidth = min(
              layoutStruct[pos].effectiveMinLogicalWidth
                + (cellMinLogicalWidth - remainingMinLogicalWidth), colMinLogicalWidth)
            remainingMaxLogicalWidth -= layoutStruct[pos].effectiveMaxLogicalWidth
            remainingMinLogicalWidth -= layoutStruct[pos].effectiveMinLogicalWidth
            cellMinLogicalWidth -= colMinLogicalWidth
            layoutStruct[pos].effectiveMinLogicalWidth = colMinLogicalWidth
          }
        }
      }
      if !cellLogicalWidth.isPercentOrCalculated() {
        if cellMaxLogicalWidth > spanMaxLogicalWidth {
          for pos in Int(effCol)..<Int(lastCol) {
            if spanMaxLogicalWidth < 0 {
              break
            }
            let colMaxLogicalWidth = max(
              layoutStruct[pos].effectiveMaxLogicalWidth,
              spanMaxLogicalWidth != 0
                ? cellMaxLogicalWidth * layoutStruct[pos].effectiveMaxLogicalWidth
                  / spanMaxLogicalWidth : cellMaxLogicalWidth)
            spanMaxLogicalWidth -= layoutStruct[pos].effectiveMaxLogicalWidth
            cellMaxLogicalWidth -= colMaxLogicalWidth
            layoutStruct[pos].effectiveMaxLogicalWidth = colMaxLogicalWidth
          }
        }
      } else {
        for pos in Int(effCol)..<Int(lastCol) {
          layoutStruct[pos].maxLogicalWidth = max(
            layoutStruct[pos].maxLogicalWidth, layoutStruct[pos].minLogicalWidth)
        }
      }
      // treat span ranges consisting of empty cells only as if they had content
      if spanHasEmptyCellsOnly {
        for pos in Int(effCol)..<Int(lastCol) {
          layoutStruct[pos].emptyCellsOnly = false
        }
      }
    }
    effectiveLogicalWidthDirty = false

    return min(maxLogicalWidth, Float32(TableLayout.tableMaxWidth))
  }

  private func insertSpanCell(cell: RenderTableCellWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private struct Layout {
    var logicalWidth = LengthWrapper()
    var effectiveLogicalWidth = LengthWrapper()
    var minLogicalWidth: Float32 = 0
    var maxLogicalWidth: Float32 = 0
    var effectiveMinLogicalWidth: Float32 = 0
    var effectiveMaxLogicalWidth: Float32 = 0
    var computedLogicalWidth: Float32 = 0
    var emptyCellsOnly = true
  }

  private var layoutStruct: [Layout] = []
  private var spanCells: [RenderTableCellWrapper?] = []
  private var hasPercent = false
  private var effectiveLogicalWidthDirty = false
}
