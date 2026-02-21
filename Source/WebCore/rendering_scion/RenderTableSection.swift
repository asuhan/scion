/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2008, 2009, 2010 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Alexey Proskuryakov (ap@nypop.com)
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
 */

// Helper class for paintObject.
private struct CellSpan {
  var start: UInt32
  var end: UInt32
}

enum CollapsedBorderSide {
  case CBSBefore
  case CBSAfter
  case CBSStart
  case CBSEnd
}

// Those 2 variables are used to balance the memory consumption vs the repaint time on big tables.
private let gMinTableSizeToUseFastPaintPathWithOverflowingCell = 75 * 75
private let gMaxAllowedOverflowingCellRatioForFastPaintPath: Float32 = 0.1

private func setRowLogicalHeightToRowStyleLogicalHeight(
  row: inout RenderTableSectionWrapper.RowStruct
) {
  assert(row.rowRenderer != nil)
  row.logicalHeight = row.rowRenderer!.style().logicalHeight()
}

private func updateLogicalHeightForCell(
  row: inout RenderTableSectionWrapper.RowStruct, cell: RenderTableCellWrapper
) {
  // We ignore height settings on rowspan cells.
  if cell.rowSpan() != 1 {
    return
  }

  let logicalHeight = cell.style().logicalHeight()
  if logicalHeight.isPositive() {
    let cRowLogicalHeight = row.logicalHeight
    switch logicalHeight.type() {
    case .Percent:
      if !cRowLogicalHeight.isPercent() || cRowLogicalHeight.percent() < logicalHeight.percent() {
        row.logicalHeight = logicalHeight
      }
    case .Fixed:
      if cRowLogicalHeight.isAuto() || cRowLogicalHeight.isRelative()
        || (cRowLogicalHeight.isFixed() && cRowLogicalHeight.value() < logicalHeight.value())
      {
        row.logicalHeight = logicalHeight
      }
    default:
      break
    }
  }
}

private func resolveLogicalHeightForRow(rowLogicalHeight: LengthWrapper) -> LayoutUnit {
  if rowLogicalHeight.isFixed() {
    return LayoutUnit(value: rowLogicalHeight.value())
  }
  if rowLogicalHeight.isCalculated() {
    return LayoutUnit(value: rowLogicalHeight.nonNanCalculatedValue(maxValue: 0))
  }
  return LayoutUnit(value: 0)
}

private func shouldFlexCellChild(cell: RenderTableCellWrapper, cellDescendant: RenderBoxWrapper)
  -> Bool
{
  if !cell.style().logicalHeight().isSpecified() {
    return false
  }
  if cellDescendant.scrollsOverflowY() {
    return true
  }
  return cellDescendant.shouldTreatChildAsReplacedInTableCells()
}

private func compareCellPositions(
  elem1: WeakNullableRef<RenderTableCellWrapper>, elem2: WeakNullableRef<RenderTableCellWrapper>
) -> Bool {
  return (*elem1).rowIndex() < (*elem2).rowIndex()
}

// This comparison is used only when we have overflowing cells as we have an unsorted array to sort. We thus need
// to sort both on rows and columns to properly repaint.
private func compareCellPositionsWithOverflowingCells(
  elem1: WeakNullableRef<RenderTableCellWrapper>, elem2: WeakNullableRef<RenderTableCellWrapper>
) -> Bool {
  if (*elem1).rowIndex() != (*elem2).rowIndex() {
    return (*elem1).rowIndex() < (*elem2).rowIndex()
  }

  return (*elem1).col() < (*elem2).col()
}

private func physicalBorderForDirection(
  styleForCellFlow: RenderStyleWrapper, side: CollapsedBorderSide
) -> BoxSide {
  switch side {
  case .CBSStart:
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection() ? .Left : .Right
    }
    return styleForCellFlow.isLeftToRightDirection() ? .Top : .Bottom
  case .CBSEnd:
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection() ? .Right : .Left
    }
    return styleForCellFlow.isLeftToRightDirection() ? .Bottom : .Top
  case .CBSBefore:
    if styleForCellFlow.isHorizontalWritingMode() {
      return .Top
    }
    return styleForCellFlow.isLeftToRightDirection() ? .Right : .Left
  case .CBSAfter:
    if styleForCellFlow.isHorizontalWritingMode() {
      return .Bottom
    }
    return styleForCellFlow.isLeftToRightDirection() ? .Left : .Right
  }
}

final class RenderTableSectionWrapper: RenderBoxWrapper {
  func firstRow() -> RenderTableRowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastRow() -> RenderTableRowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func firstLineBaseline() -> LayoutUnit? {
    if grid.isEmpty {
      return nil
    }

    let firstLineBaseline = grid[0].baseline
    if firstLineBaseline.bool() {
      return firstLineBaseline + rowPos[0]
    }

    return baselineFromCellContentEdges(alignment: .Baseline)
  }

  override func lastLineBaseline() -> LayoutUnit? {
    if grid.isEmpty {
      return nil
    }

    let lastLineBaseline = grid[grid.count - 1].baseline
    if lastLineBaseline.bool() {
      return lastLineBaseline + rowPos[grid.count - 1]
    }

    return baselineFromCellContentEdges(alignment: .LastBaseline)
  }

  private func baselineFromCellContentEdges(alignment: ItemPosition) -> LayoutUnit? {
    assert(alignment == .Baseline || alignment == .LastBaseline)
    let row = alignment == .Baseline ? grid.first!.row : grid.last!.row

    var result: LayoutUnit? = nil
    for cs in row {
      // Only cells with content have a baseline
      if let cell = cs.primaryCell(), cell.contentLogicalHeight().bool() {
        let candidate =
          cell.logicalTop() + cell.borderAndPaddingBefore() + cell.contentLogicalHeight()
        result = max(result ?? candidate, candidate)
      }
    }
    return result
  }

  func addCell(cell: RenderTableCellWrapper, row: RenderTableRowWrapper) {
    // We don't insert the cell if we need cell recalc as our internal columns' representation
    // will have drifted from the table's representation. Also recalcCells will call addCell
    // at a later time after sync'ing our columns' with the table's.
    if needsCellRecalc {
      return
    }

    let rSpan = cell.rowSpan()
    var cSpan = cell.colSpan()
    let columns = table()!.columns()
    let nCols = columns.count
    let insertionRow = row.rowIndex()

    // ### mozilla still seems to do the old HTML way, even for strict DTD
    // (see the annotation on table cell layouting in the CSS specs and the testcase below:
    // <TABLE border>
    // <TR><TD>1 <TD rowspan="2">2 <TD>3 <TD>4
    // <TR><TD colspan="2">5
    // </TABLE>
    while cCol < nCols
      && (cellAt(row: insertionRow, col: cCol).hasCells()
        || cellAt(row: insertionRow, col: cCol).inColSpan)
    {
      cCol += 1
    }

    updateLogicalHeightForCell(row: &grid[Int(insertionRow)], cell: cell)

    ensureRows(numRows: insertionRow + rSpan)

    grid[Int(insertionRow)].rowRenderer = row

    let col = self.cCol
    // tell the cell where it is
    var inColSpan = false
    while cSpan != 0 {
      var currentSpan: UInt32 = 0
      if cCol >= nCols {
        table()!.appendColumn(span: cSpan)
        currentSpan = cSpan
      } else {
        if cSpan < columns[Int(cCol)].span {
          table()!.splitColumn(position: cCol, firstSpan: cSpan)
        }
        currentSpan = columns[Int(cCol)].span
      }
      for r in 0..<rSpan {
        let c = cellAt(row: insertionRow + r, col: cCol)
        c.cells.append(cell)
        // If cells overlap then we take the slow path for painting.
        if c.cells.count > 1 {
          hasMultipleCellLevels = true
        }
        if inColSpan {
          c.inColSpan = true
        }
      }
      cCol += 1
      cSpan -= currentSpan
      inColSpan = true
    }
    cell.setCol(column: table()!.effColToCol(effCol: col))
  }

  func calcRowLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): SetLayoutNeededForbiddenScope
    assert(!needsLayout())

    // We ignore the border-spacing on any non-top section as it is already included in the previous section's last row position.
    var spacing =
      CPtrToInt(table()!.topSection()?.p) == CPtrToInt(p) ? LayoutUnit() : table()!.vBorderSpacing()

    let _ = LayoutStateMaintainer(
      root: self, offset: locationOffset(),
      disablePaintOffsetCache: isTransformed() || hasReflection()
        || style().isFlippedBlocksWritingMode())

    assert(grid.count + 1 >= rowPos.count)
    while rowPos.count < grid.count + 1 {
      rowPos.append(LayoutUnit())
    }
    rowPos[0] = spacing

    let totalRows = grid.count

    for r in 0..<totalRows {
      grid[r].baseline = LayoutUnit(value: 0)
      var baselineDescent = LayoutUnit()

      if grid[r].logicalHeight.isSpecified() {
        // Our base size is the biggest logical height from our cells' styles (excluding row spanning cells).
        rowPos[r + 1] = max(
          rowPos[r] + resolveLogicalHeightForRow(rowLogicalHeight: grid[r].logicalHeight),
          LayoutUnit(value: UInt64(0)))
      } else {
        // Non-specified lengths are ignored because the row already accounts for the cells intrinsic logical height.
        rowPos[r + 1] = max(rowPos[r], LayoutUnit(value: UInt64(0)))
      }

      let totalCols = UInt32(grid[r].row.count)

      for c in 0..<totalCols {
        let current = cellAt(row: UInt32(r), col: c)
        for i in 0..<current.cells.count {
          let cell = current.cells[i]
          if current.inColSpan && cell.rowSpan() == 1 {
            continue
          }

          // FIXME: We are always adding the height of a rowspan to the last rows which doesn't match
          // other browsers. See webkit.org/b/52185 for example.
          if (cell.rowIndex() + cell.rowSpan() - 1) != r {
            // We will apply the height of the rowspan to the current row if next row is not valid.
            if (r + 1) < totalRows {
              var col: UInt32 = 0
              var nextRowCell = cellAt(row: UInt32(r + 1), col: col)

              // We are trying to find that next row is valid or not.
              while !nextRowCell.cells.isEmpty && nextRowCell.cells[0].rowSpan() > 1
                && nextRowCell.cells[0].rowIndex() < (r + 1)
              {
                col += 1
                if col < totalCols {
                  nextRowCell = cellAt(row: UInt32(r + 1), col: col)
                } else {
                  break
                }
              }

              // We are adding the height of the rowspan to the current row if next row is not valid.
              if col < totalCols && !nextRowCell.cells.isEmpty {
                continue
              }
            }
          }

          // For row spanning cells, |r| is the last row in the span.
          let cellStartRow = Int(cell.rowIndex())

          if cell.overridingLogicalHeight() != nil {
            cell.clearIntrinsicPadding()
            cell.clearOverridingContentSize()
            cell.setChildNeedsLayout(markParents: .MarkOnlyThis)
            cell.layoutIfNeeded()
          }

          let cellLogicalHeight = cell.logicalHeightForRowSizing()
          rowPos[r + 1] = max(rowPos[r + 1], rowPos[cellStartRow] + cellLogicalHeight)

          // Find out the baseline. The baseline is set on the first row in a rowspan.
          if cell.isBaselineAligned() {
            let baselinePosition = cell.cellBaselinePosition() - cell.intrinsicPaddingBefore()
            let borderAndComputedPaddingBefore =
              cell.borderAndPaddingBefore() - cell.intrinsicPaddingBefore()
            if baselinePosition > borderAndComputedPaddingBefore {
              grid[cellStartRow].baseline = max(grid[cellStartRow].baseline, baselinePosition)
              // The descent of a cell that spans multiple rows does not affect the height of the first row it spans, so don't let it
              // become the baseline descent applied to the rest of the row. Also we don't account for the baseline descent of
              // non-spanning cells when computing a spanning cell's extent.
              var cellStartRowBaselineDescent = LayoutUnit()
              if cell.rowSpan() == 1 {
                baselineDescent = max(baselineDescent, cellLogicalHeight - baselinePosition)
                cellStartRowBaselineDescent = baselineDescent
              }
              rowPos[cellStartRow + 1] = max(
                rowPos[cellStartRow + 1],
                rowPos[cellStartRow] + grid[cellStartRow].baseline + cellStartRowBaselineDescent)
            }
          }
        }
      }

      // Add the border-spacing to our final position.
      // Use table border-spacing even in non-top sections
      spacing = table()!.vBorderSpacing()
      rowPos[r + 1] += grid[r].rowRenderer != nil ? spacing : LayoutUnit(value: UInt64(0))
      rowPos[r + 1] = max(rowPos[r + 1], rowPos[r])
    }

    assert(!needsLayout())

    return rowPos[grid.count]
  }

  func layoutRows() {
    // TODO(asuhan): SetLayoutNeededForbiddenScope
    assert(!needsLayout())

    let totalRows = grid.count

    // Set the width of our section now.  The rows will also be this width.
    setLogicalWidth(size: table()!.contentLogicalWidth())
    forceSlowPaintPathWithOverflowingCell = false

    let vspacing = table()!.vBorderSpacing()
    let nEffCols = table()!.numEffCols()

    let _ = LayoutStateMaintainer(
      root: self, offset: locationOffset(),
      disablePaintOffsetCache: isTransformed() || style().isFlippedBlocksWritingMode())

    for r in 0..<totalRows {
      // Set the row's x/y position and width/height.
      if let rowRenderer = grid[r].rowRenderer {
        // FIXME: the x() position of the row should be table()->hBorderSpacing() so that it can
        // report the correct offsetLeft. However, that will require a lot of rebaselining of test results.
        rowRenderer.setLogicalLeft(left: LayoutUnit(value: UInt64(0)))
        rowRenderer.setLogicalTop(top: rowPos[r])
        rowRenderer.setLogicalWidth(size: logicalWidth())
        rowRenderer.setLogicalHeight(size: rowPos[r + 1] - rowPos[r] - vspacing)
        rowRenderer.updateLayerTransform()
        rowRenderer.clearOverflow()
        rowRenderer.addVisualEffectOverflow()
      }

      var rowHeightIncreaseForPagination = LayoutUnit()

      for c in 0..<nEffCols {
        let cs = cellAt(row: UInt32(r), col: c)
        let cell = cs.primaryCell()

        if cell == nil || cs.inColSpan {
          continue
        }

        let rowIndex = cell!.rowIndex()
        let rHeight = rowPos[Int(rowIndex + cell!.rowSpan())] - rowPos[Int(rowIndex)] - vspacing

        relayoutCellIfFlexed(cell: cell!, rowIndex: r, rowHeight: rHeight)

        cell!.computeIntrinsicPadding(rowHeight: rHeight)

        let oldCellRect = cell!.frameRect()

        setLogicalPositionForCell(cell: cell!, effectiveColumn: c)

        let layoutState = view().frameView().layoutContext().layoutState()!
        if !cell!.needsLayout() && layoutState.pageLogicalHeight().bool()
          && layoutState.pageLogicalOffset(child: cell!, childLogicalOffset: cell!.logicalTop())
            != cell!.pageLogicalOffset()
        {
          cell!.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }

        cell!.layoutIfNeeded()

        // FIXME: Make pagination work with vertical tables.
        if layoutState.pageLogicalHeight().bool() && cell!.logicalHeight() != rHeight {
          // FIXME: Pagination might have made us change size. For now just shrink or grow the cell to fit without doing a relayout.
          // We'll also do a basic increase of the row height to accommodate the cell if it's bigger, but this isn't quite right
          // either. It's at least stable though and won't result in an infinite # of relayouts that may never stabilize.
          if cell!.logicalHeight() > rHeight {
            rowHeightIncreaseForPagination = max(
              rowHeightIncreaseForPagination, cell!.logicalHeight() - rHeight)
          }
          cell!.setLogicalHeight(size: rHeight)
        }

        let childOffset = cell!.location() - oldCellRect.location()
        if childOffset.width().bool() || childOffset.height().bool() {
          view().frameView().layoutContext().addLayoutDelta(delta: childOffset)

          // If the child moved, we have to repaint it as well as any floating/positioned
          // descendants.  An exception is if we need a layout.  In this case, we know we're going to
          // repaint ourselves (and the child) anyway.
          if !table()!.selfNeedsLayout() && cell!.checkForRepaintDuringLayout() {
            cell!.repaintDuringLayoutIfMoved(oldRect: oldCellRect)
          }
        }
      }
      if rowHeightIncreaseForPagination.bool() {
        for rowIndex in r + 1...totalRows {
          rowPos[rowIndex] += rowHeightIncreaseForPagination
        }
        for c in 0..<nEffCols {
          let cells = cellAt(row: UInt32(r), col: c).cells[...]
          for cell in cells {
            cell.setLogicalHeight(size: cell.logicalHeight() + rowHeightIncreaseForPagination)
          }
        }
      }
    }

    assert(!needsLayout())

    setLogicalHeight(size: rowPos[totalRows])

    updateLayerTransform()

    computeOverflowFromCells(totalRows: UInt32(totalRows), nEffCols: nEffCols)
  }

  func computeOverflowFromCells() {
    let totalRows = UInt32(grid.count)
    let nEffCols = table()!.numEffCols()
    computeOverflowFromCells(totalRows: totalRows, nEffCols: nEffCols)
  }

  func table() -> RenderTableWrapper? { return parent() as! RenderTableWrapper? }

  class CellStruct {
    var cells: [RenderTableCellWrapper] = []
    var inColSpan = false  // true for columns after the first in a colspan

    func primaryCell() -> RenderTableCellWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func hasCells() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  typealias Row = [CellStruct]

  struct RowStruct {
    var row = Row()
    var rowRenderer: RenderTableRowWrapper? = nil
    var baseline = LayoutUnit()
    var logicalHeight = LengthWrapper()
  }

  func borderAdjoiningTableStart() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAdjoiningTableEnd() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAdjoiningStartCell(cell: RenderTableCellWrapper) -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAdjoiningEndCell(cell: RenderTableCellWrapper) -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cellAt(row: UInt32, col: UInt32) -> CellStruct {
    recalcCellsIfNeeded()
    return grid[Int(row)].row[Int(col)]
  }

  func primaryCellAt(row: UInt32, col: UInt32) -> RenderTableCellWrapper? {
    recalcCellsIfNeeded()
    let c = grid[Int(row)].row[Int(col)]
    return c.primaryCell()
  }

  func appendColumn(pos: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func splitColumn(pos: UInt32, first: UInt32) {
    assert(!needsCellRecalc)

    if cCol > pos {
      cCol += 1
    }
    let pos = Int(pos)
    for rowStruct in grid {
      var r = rowStruct.row[...]
      r.insert(CellStruct(), at: pos + 1)
      if r[pos].hasCells() {
        r[pos + 1].cells.append(contentsOf: r[pos].cells)
        let cell = r[pos].primaryCell()!
        assert(cell.colSpan() >= (r[pos].inColSpan ? 1 : 0))
        let colleft = cell.colSpan() - (r[pos].inColSpan ? 1 : 0)
        if first > colleft {
          r[pos + 1].inColSpan = false
        } else {
          r[pos + 1].inColSpan = first != 0 || r[pos].inColSpan
        }
      } else {
        r[pos + 1].inColSpan = false
      }
    }
  }

  func calcOuterBorderBefore() -> LayoutUnit {
    let totalCols = table()!.numEffCols()
    if grid.isEmpty || totalCols == 0 {
      return LayoutUnit(value: 0)
    }

    let sb = style().borderBefore(styleForFlow: table()!.style())
    if sb.style == .Hidden {
      return LayoutUnit(value: -1)
    }

    var borderWidth: Float32 = 0

    if sb.style != .None {
      borderWidth = sb.width
    }

    let rb = firstRow()!.style().borderBefore(styleForFlow: table()!.style())
    if rb.style == .Hidden {
      return LayoutUnit(value: -1)
    }
    if rb.style != .None && rb.width > borderWidth {
      borderWidth = rb.width
    }

    var allHidden = true
    for c in 0..<totalCols {
      let current = cellAt(row: 0, col: c)
      if current.inColSpan || !current.hasCells() {
        continue
      }
      let cb = current.primaryCell()!.style().borderBefore(styleForFlow: table()!.style())  // FIXME: Make this work with perpendicular and flipped cells.
      // FIXME: Don't repeat for the same col group
      if let colGroup = table()!.colElement(col: c) {
        let gb = colGroup.style().borderBefore(styleForFlow: table()!.style())
        if gb.style == .Hidden || cb.style == .Hidden {
          continue
        }
        allHidden = false
        if gb.style != .None && gb.width > borderWidth {
          borderWidth = gb.width
        }
        if cb.style != .None && cb.width > borderWidth {
          borderWidth = cb.width
        }
      } else {
        if cb.style == .Hidden {
          continue
        }
        allHidden = false
        if cb.style != .None && cb.width > borderWidth {
          borderWidth = cb.width
        }
      }
    }
    if allHidden {
      return LayoutUnit(value: -1)
    }
    return CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: borderWidth, deviceScaleFactor: document().deviceScaleFactor(), roundUp: false)
  }

  func calcOuterBorderAfter() -> LayoutUnit {
    let totalCols = table()!.numEffCols()
    if grid.isEmpty || totalCols == 0 {
      return LayoutUnit(value: 0)
    }

    let sb = style().borderAfter(styleForFlow: table()!.style())
    if sb.style == .Hidden {
      return LayoutUnit(value: -1)
    }

    var borderWidth: Float32 = 0

    if sb.style != .None {
      borderWidth = sb.width
    }

    let rb = lastRow()!.style().borderAfter(styleForFlow: table()!.style())
    if rb.style == .Hidden {
      return LayoutUnit(value: -1)
    }
    if rb.style != .None && rb.width > borderWidth {
      borderWidth = rb.width
    }

    var allHidden = true
    for c in 0..<totalCols {
      let current = cellAt(row: UInt32(grid.count - 1), col: c)
      if current.inColSpan || !current.hasCells() {
        continue
      }
      let cb = current.primaryCell()!.style().borderAfter(styleForFlow: table()!.style())  // FIXME: Make this work with perpendicular and flipped cells.
      // FIXME: Don't repeat for the same col group
      if let colGroup = table()!.colElement(col: c) {
        let gb = colGroup.style().borderAfter(styleForFlow: table()!.style())
        if gb.style == .Hidden || cb.style == .Hidden {
          continue
        }
        allHidden = false
        if gb.style != .None && gb.width > borderWidth {
          borderWidth = gb.width
        }
        if cb.style != .None && cb.width > borderWidth {
          borderWidth = cb.width
        }
      } else {
        if cb.style == .Hidden {
          continue
        }
        allHidden = false
        if cb.style != .None && cb.width > borderWidth {
          borderWidth = cb.width
        }
      }
    }
    if allHidden {
      return LayoutUnit(value: -1)
    }
    return CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: borderWidth, deviceScaleFactor: document().deviceScaleFactor(), roundUp: true)
  }

  func calcOuterBorderStart() -> LayoutUnit {
    let totalCols = table()!.numEffCols()
    if grid.isEmpty || totalCols == 0 {
      return LayoutUnit(value: 0)
    }

    let sb = style().borderStart(styleForFlow: table()!.style())
    if sb.style == .Hidden {
      return LayoutUnit(value: -1)
    }

    var borderWidth: Float32 = 0

    if sb.style != .None {
      borderWidth = sb.width
    }

    if let colGroup = table()!.colElement(col: 0) {
      let gb = colGroup.style().borderStart(styleForFlow: table()!.style())
      if gb.style == .Hidden {
        return LayoutUnit(value: -1)
      }
      if gb.style != .None && gb.width > borderWidth {
        borderWidth = gb.width
      }
    }

    var allHidden = true
    for r in 0..<grid.count {
      let current = cellAt(row: UInt32(r), col: 0)
      if !current.hasCells() {
        continue
      }
      // FIXME: Don't repeat for the same cell
      let cb = current.primaryCell()!.style().borderStart(styleForFlow: table()!.style())  // FIXME: Make this work with perpendicular and flipped cells.
      let rb = current.primaryCell()!.parent()!.style().borderStart(styleForFlow: table()!.style())
      if cb.style == .Hidden || rb.style == .Hidden {
        continue
      }
      allHidden = false
      if cb.style != .None && cb.width > borderWidth {
        borderWidth = cb.width
      }
      if rb.style != .None && rb.width > borderWidth {
        borderWidth = rb.width
      }
    }
    if allHidden {
      return LayoutUnit(value: -1)
    }
    return CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: borderWidth, deviceScaleFactor: document().deviceScaleFactor(),
      roundUp: !table()!.style().isLeftToRightDirection())
  }

  func calcOuterBorderEnd() -> LayoutUnit {
    let totalCols = table()!.numEffCols()
    if grid.isEmpty || totalCols == 0 {
      return LayoutUnit(value: 0)
    }

    let sb = style().borderEnd(styleForFlow: table()!.style())
    if sb.style == .Hidden {
      return LayoutUnit(value: -1)
    }

    var borderWidth: Float32 = 0

    if sb.style != .None {
      borderWidth = sb.width
    }

    if let colGroup = table()!.colElement(col: totalCols - 1) {
      let gb = colGroup.style().borderEnd(styleForFlow: table()!.style())
      if gb.style == .Hidden {
        return LayoutUnit(value: -1)
      }
      if gb.style != .None && gb.width > borderWidth {
        borderWidth = gb.width
      }
    }

    var allHidden = true
    for r in 0..<grid.count {
      let current = cellAt(row: UInt32(r), col: totalCols - 1)
      if !current.hasCells() {
        continue
      }
      // FIXME: Don't repeat for the same cell
      let cb = current.primaryCell()!.style().borderEnd(styleForFlow: table()!.style())  // FIXME: Make this work with perpendicular and flipped cells.
      let rb = current.primaryCell()!.parent()!.style().borderEnd(styleForFlow: table()!.style())
      if cb.style == .Hidden || rb.style == .Hidden {
        continue
      }
      allHidden = false
      if cb.style != .None && cb.width > borderWidth {
        borderWidth = cb.width
      }
      if rb.style != .None && rb.width > borderWidth {
        borderWidth = rb.width
      }
    }
    if allHidden {
      return LayoutUnit(value: -1)
    }
    return CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: borderWidth, deviceScaleFactor: document().deviceScaleFactor(),
      roundUp: table()!.style().isLeftToRightDirection())
  }

  func recalcOuterBorder() {
    outerBorderBefore = calcOuterBorderBefore()
    outerBorderAfter = calcOuterBorderAfter()
    outerBorderStart = calcOuterBorderStart()
    outerBorderEnd = calcOuterBorderEnd()
  }

  func outerBorderLeft(styleForCellFlow: RenderStyleWrapper) -> LayoutUnit {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection() ? outerBorderStart : outerBorderEnd
    }
    return styleForCellFlow.isFlippedBlocksWritingMode() ? outerBorderAfter : outerBorderBefore
  }

  func outerBorderRight(styleForCellFlow: RenderStyleWrapper) -> LayoutUnit {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection() ? outerBorderEnd : outerBorderStart
    }
    return styleForCellFlow.isFlippedBlocksWritingMode() ? outerBorderBefore : outerBorderAfter
  }

  func outerBorderTop(styleForCellFlow: RenderStyleWrapper) -> LayoutUnit {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isFlippedBlocksWritingMode() ? outerBorderAfter : outerBorderBefore
    }
    return styleForCellFlow.isLeftToRightDirection() ? outerBorderStart : outerBorderEnd
  }

  func outerBorderBottom(styleForCellFlow: RenderStyleWrapper) -> LayoutUnit {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isFlippedBlocksWritingMode() ? outerBorderBefore : outerBorderAfter
    }
    return styleForCellFlow.isLeftToRightDirection() ? outerBorderEnd : outerBorderStart
  }

  func numRows() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func numColumns() -> UInt32 {
    assert(!needsCellRecalc)
    var result: UInt32 = 0

    for r in 0..<UInt32(grid.count) {
      for c in result..<table()!.numEffCols() {
        let cell = cellAt(row: r, col: c)
        if cell.hasCells() || cell.inColSpan {
          result = c
        }
      }
    }

    return result + 1
  }

  private func recalcCells() {
    assert(needsCellRecalc)
    // We reset the flag here to ensure that addCell() works. This is safe to do because we clear the grid
    // and update its dimensions to be consistent with the table's column representation before we rebuild
    // the grid using addCell().
    needsCellRecalc = false

    cCol = 0
    cRow = 0
    grid.removeAll()

    var row = firstRow()
    while row != nil {
      let insertionRow = cRow
      cRow += 1
      cCol = 0
      ensureRows(numRows: cRow)

      grid[Int(insertionRow)].rowRenderer = row
      row!.setRowIndex(rowIndex: insertionRow)
      setRowLogicalHeightToRowStyleLogicalHeight(row: &grid[Int(insertionRow)])

      var cell = row!.firstCell()
      while cell != nil {
        addCell(cell: cell!, row: row!)
        cell = cell!.nextCell()
      }

      row = row!.nextRow()
    }

    // TODO(asuhan): shrink to size
    setNeedsLayout()
  }

  func recalcCellsIfNeeded() {
    if needsCellRecalc {
      recalcCells()
    }
  }

  func removeRedundantColumns() {
    let maximumNumberOfColumns = table()!.numEffCols()
    for i in 0..<grid.count {
      if grid[i].row.count <= maximumNumberOfColumns {
        continue
      }
      grid[i].row.removeLast(grid[i].row.count - Int(maximumNumberOfColumns))
    }
  }

  func setNeedsCellRecalc() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowBaseline(row: UInt32) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowLogicalHeightChanged(_ rowIndex: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearCachedCollapsedBorders() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCachedCollapsedBorder(
    cell: RenderTableCellWrapper, side: CollapsedBorderSide, border: CollapsedBorderValue
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cachedCollapsedBorder(cell: RenderTableCellWrapper, side: CollapsedBorderSide)
    -> CollapsedBorderValue
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // distributeExtraLogicalHeightToRows methods return the *consumed* extra logical height.
  // FIXME: We may want to introduce a structure holding the in-flux layout information.
  func distributeExtraLogicalHeightToRows(extraLogicalHeight: LayoutUnit) -> LayoutUnit {
    if !extraLogicalHeight.bool() {
      return extraLogicalHeight
    }

    let totalRows = grid.count
    if totalRows == 0 {
      return extraLogicalHeight
    }

    if !rowPos[totalRows].bool() && nextSibling() != nil {
      return extraLogicalHeight
    }

    var autoRowsCount: UInt32 = 0
    var totalPercent = 0
    for row in grid {
      if row.logicalHeight.isAuto() {
        autoRowsCount += 1
      } else if row.logicalHeight.isPercent() {
        totalPercent += Int(row.logicalHeight.percent())
      }
    }

    var remainingExtraLogicalHeight = extraLogicalHeight
    distributeExtraLogicalHeightToPercentRows(
      extraLogicalHeight: &remainingExtraLogicalHeight, totalPercent: totalPercent)
    distributeExtraLogicalHeightToAutoRows(
      extraLogicalHeight: &remainingExtraLogicalHeight, autoRowsCount: autoRowsCount)
    distributeRemainingExtraLogicalHeight(extraLogicalHeight: &remainingExtraLogicalHeight)
    return extraLogicalHeight - remainingExtraLogicalHeight
  }

  static func createAnonymousWithParentRenderer(parent: RenderTableWrapper)
    -> RenderTableSectionWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(!needsLayout())
    // avoid crashing on bugs that cause us to paint with dirty layout
    if needsLayout() {
      return
    }

    let totalRows = grid.count
    let totalCols = table()!.columns().count

    if totalRows == 0 || totalCols == 0 {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    let phase = paintInfo.phase
    let pushedClip = pushContentsClip(paintInfo: &paintInfo, accumulatedOffset: adjustedPaintOffset)
    paintObject(paintInfo: &paintInfo, paintOffset: adjustedPaintOffset)
    if pushedClip {
      popContentsClip(
        paintInfo: &paintInfo, originalPhase: phase, accumulatedOffset: adjustedPaintOffset)
    }

    if (phase == .Outline || phase == .SelfOutline) && style().usedVisibility() == .Visible {
      paintOutline(
        paintInfo: paintInfo,
        paintRect: LayoutRectWrapper(location: adjustedPaintOffset, size: size()))
    }
  }

  func willInsertTableRow(child: RenderTableRowWrapper, beforeChild: RenderObjectWrapper?) {
    if beforeChild != nil {
      setNeedsCellRecalc()
    }

    let insertionRow = cRow
    cRow += 1
    cCol = 0

    ensureRows(numRows: cRow)

    grid[Int(insertionRow)].rowRenderer = child
    child.setRowIndex(rowIndex: insertionRow)

    if beforeChild == nil {
      setRowLogicalHeightToRowStyleLogicalHeight(row: &grid[Int(insertionRow)])
    }
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    propagateStyleToAnonymousChildren(propagationType: .AllChildren)

    // If border was changed, notify table.
    if let table = table(), oldStyle != nil && !oldStyle!.borderIsEquivalentForPainting(style()) {
      table.invalidateCollapsedBorders()
    }
  }

  private enum ShouldIncludeAllIntersectingCells {
    case IncludeAllIntersectingCells
    case DoNotIncludeAllIntersectingCells
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())
    assert(!needsCellRecalc)
    assert(!table()!.needsSectionRecalc)

    forceSlowPaintPathWithOverflowingCell = false
    // addChild may over-grow m_grid but we don't want to throw away the memory too early as addChild
    // can be called in a loop (e.g during parsing). Doing it now ensures we have a stable-enough structure.
    // TODO(asuhan): shrink to size

    let _ = LayoutStateMaintainer(
      root: self, offset: locationOffset(),
      disablePaintOffsetCache: isTransformed() || hasReflection()
        || style().isFlippedBlocksWritingMode())
    let paginated = view().frameView().layoutContext().layoutState()!.isPaginated()

    let columnPos = table()!.columnPositions()

    for (r, rowStruct) in grid.enumerated() {
      let row = rowStruct.row
      let cols = row.count
      // First, propagate our table layout's information to the cells. This will mark the row as needing layout
      // if there was a column logical width change.
      for (startColumn, current) in row.enumerated() {
        let cell = current.primaryCell()
        if cell == nil || current.inColSpan {
          continue
        }

        var endCol = startColumn
        var cspan = cell!.colSpan()
        while cspan != 0 && endCol < cols {
          assert(endCol < table()!.columns().count)
          cspan -= table()!.columns()[endCol].span
          endCol += 1
        }
        let tableLayoutLogicalWidth =
          columnPos[endCol] - columnPos[startColumn] - table()!.hBorderSpacing()
        cell!.setCellLogicalWidth(tableLayoutLogicalWidth)
      }

      if let rowRenderer = grid[r].rowRenderer {
        if !rowRenderer.needsLayout() && paginated
          && view().frameView().layoutContext().layoutState()!.pageLogicalHeightChanged()
        {
          rowRenderer.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }

        rowRenderer.layoutIfNeeded()
      }
    }
    clearNeedsLayout()
  }

  private func paintCell(
    cell: RenderTableCellWrapper, paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    let cellPoint = flipForWritingModeForChild(child: cell, point: paintOffset)
    let paintPhase = paintInfo.phase
    let row = cell.parent() as! RenderTableRowWrapper

    if paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground {
      // We need to handle painting a stack of backgrounds.  This stack (from bottom to top) consists of
      // the column group, column, row group, row, and then the cell.

      // Column groups and columns first.
      // FIXME: Columns and column groups do not currently support opacity, and they are being painted "too late" in
      // the stack, since we have already opened a transparency layer (potentially) for the table row group.
      // Note that we deliberately ignore whether or not the cell has a layer, since these backgrounds paint "behind" the
      // cell.
      if let column = table()!.colElement(col: cell.col()) {
        if let columnGroup = column.enclosingColumnGroup() {
          cell.paintBackgroundsBehindCell(
            paintInfo: paintInfo, paintOffset: cellPoint, backgroundObject: columnGroup,
            backgroundPaintOffset: cellPoint)
        }
        cell.paintBackgroundsBehindCell(
          paintInfo: paintInfo, paintOffset: cellPoint, backgroundObject: column,
          backgroundPaintOffset: cellPoint)
      }

      // Paint the row group next.
      cell.paintBackgroundsBehindCell(
        paintInfo: paintInfo, paintOffset: cellPoint, backgroundObject: self,
        backgroundPaintOffset: paintOffset)

      // Paint the row next, but only if it doesn't have a layer.  If a row has a layer, it will be responsible for
      // painting the row background for the cell.
      if !row.hasSelfPaintingLayer() {
        cell.paintBackgroundsBehindCell(
          paintInfo: paintInfo, paintOffset: cellPoint, backgroundObject: row,
          backgroundPaintOffset: cellPoint)
      }
    }
    if !cell.hasSelfPaintingLayer() && !row.hasSelfPaintingLayer() {
      cell.paint(paintInfo: &paintInfo, paintOffset: cellPoint)
    }
  }

  override func paintObject(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    var localRepaintRect = paintInfo.rect
    localRepaintRect.moveBy(offset: -paintOffset)

    let tableAlignedRect = logicalRectForWritingModeAndDirection(rect: localRepaintRect)

    let dirtiedRows = dirtiedRows(damageRect: tableAlignedRect)
    let dirtiedColumns = dirtiedColumns(damageRect: tableAlignedRect)

    if dirtiedColumns.start >= dirtiedColumns.end {
      return
    }

    if !hasMultipleCellLevels && overflowingCells.isEmptyIgnoringNullReferences() {
      if paintInfo.phase == .CollapsedTableBorders {
        // Collapsed borders are painted from the bottom right to the top left so that precedence
        // due to cell position is respected. We need to paint one row beyond the topmost dirtied
        // row to calculate its collapsed border value.
        let startRow = dirtiedRows.start != 0 ? dirtiedRows.start - 1 : 0
        for r in (startRow + 1...dirtiedRows.end).reversed() {
          let row = r - 1
          var shouldPaintRowGroupBorder = false
          for c in (dirtiedColumns.start + 1...dirtiedColumns.end).reversed() {
            let col = c - 1
            let current = cellAt(row: row, col: col)
            let cell = current.primaryCell()
            if cell == nil {
              if c == 0 {
                paintRowGroupBorderIfRequired(
                  paintInfo: paintInfo, paintOffset: paintOffset, row: row, column: col,
                  borderSide: physicalBorderForDirection(
                    styleForCellFlow: table()!.style(), side: .CBSStart))
              } else if c == table()!.numEffCols() {
                paintRowGroupBorderIfRequired(
                  paintInfo: paintInfo, paintOffset: paintOffset, row: row, column: col,
                  borderSide: physicalBorderForDirection(
                    styleForCellFlow: table()!.style(), side: .CBSEnd))
              }
              shouldPaintRowGroupBorder = true
              continue
            }
            if (row > dirtiedRows.start
              && CPtrToInt(primaryCellAt(row: row - 1, col: col)?.p) == CPtrToInt(cell?.p))
              || (col > dirtiedColumns.start
                && CPtrToInt(primaryCellAt(row: row, col: col - 1)?.p) == CPtrToInt(cell?.p))
            {
              continue
            }

            // If we had a run of null cells paint their corresponding section of the row group's border if necessary. Note that
            // this will only happen once within a row as the null cells will always be clustered together on one end of the row.
            if shouldPaintRowGroupBorder {
              if r == grid.count {
                paintRowGroupBorderIfRequired(
                  paintInfo: paintInfo, paintOffset: paintOffset, row: row, column: col,
                  borderSide: physicalBorderForDirection(
                    styleForCellFlow: table()!.style(), side: .CBSAfter), cell: cell)
              } else if row == 0 && table()!.sectionAbove(section: self) == nil {
                paintRowGroupBorderIfRequired(
                  paintInfo: paintInfo, paintOffset: paintOffset, row: row, column: col,
                  borderSide: physicalBorderForDirection(
                    styleForCellFlow: table()!.style(), side: .CBSBefore), cell: cell)
              }
              shouldPaintRowGroupBorder = false
            }

            let cellPoint = flipForWritingModeForChild(child: cell!, point: paintOffset)
            cell!.paintCollapsedBorders(paintInfo: paintInfo, paintOffset: cellPoint)
          }
        }
      } else {
        // Draw the dirty cells in the order that they appear.
        for r in dirtiedRows.start..<dirtiedRows.end {
          if let row = grid[Int(r)].rowRenderer, !row.hasSelfPaintingLayerModelObject() {
            row.paintOutlineForRowIfNeeded(paintInfo: paintInfo, paintOffset: paintOffset)
          }
          for c in dirtiedColumns.start..<dirtiedColumns.end {
            let current = cellAt(row: r, col: c)
            let cell = current.primaryCell()
            if cell == nil
              || (r > dirtiedRows.start
                && CPtrToInt(primaryCellAt(row: r - 1, col: c)?.p) == CPtrToInt(cell?.p))
              || (c > dirtiedColumns.start
                && CPtrToInt(primaryCellAt(row: r, col: c - 1)?.p) == CPtrToInt(cell?.p))
            {
              continue
            }
            paintCell(cell: cell!, paintInfo: &paintInfo, paintOffset: paintOffset)
          }
        }
      }
    } else {
      // The overflowing cells should be scarce to avoid adding a lot of cells to the HashSet.
      #if ASSERT_ENABLED
        let totalRows = grid.count
        let totalCols = table()!.columns.count
        assert(
          overflowingCells.computeSize()
            < UInt32(
              Float32(totalRows * totalCols) * gMaxAllowedOverflowingCellRatioForFastPaintPath)
        )
      #endif

      // To make sure we properly repaint the section, we repaint all the overflowing cells that we collected.
      var cells = copyToVector(collection: overflowingCells)

      var spanningCells: Set<UInt> = []

      for r in dirtiedRows.start..<dirtiedRows.end {
        if let row = grid[Int(r)].rowRenderer, !row.hasSelfPaintingLayerModelObject() {
          row.paintOutlineForRowIfNeeded(paintInfo: paintInfo, paintOffset: paintOffset)
        }
        for c in dirtiedColumns.start..<dirtiedColumns.end {
          let current = cellAt(row: r, col: c)
          if !current.hasCells() {
            continue
          }
          for currentCell in current.cells {
            if overflowingCells.contains(value: currentCell) {
              continue
            }

            if currentCell.rowSpan() > 1 || currentCell.colSpan() > 1 {
              if !spanningCells.insert(CPtrToInt(currentCell.p)).inserted {
                continue
              }
            }

            cells.append(WeakNullableRef(currentCell))
          }
        }
      }

      // Sort the dirty cells by paint order.
      if overflowingCells.isEmptyIgnoringNullReferences() {
        // TODO(asuhan): use a guaranteed stable sort
        cells.sort(by: compareCellPositions)
      } else {
        cells.sort(by: compareCellPositionsWithOverflowingCells)
      }

      if paintInfo.phase == .CollapsedTableBorders {
        for cell in cells.reversed() {
          let cellPoint = flipForWritingModeForChild(child: *cell, point: paintOffset)
          (*cell).paintCollapsedBorders(paintInfo: paintInfo, paintOffset: cellPoint)
        }
      } else {
        for cell in cells {
          paintCell(cell: *cell, paintInfo: &paintInfo, paintOffset: paintOffset)
        }
      }
    }
  }

  private func paintRowGroupBorder(
    paintInfo: PaintInfoWrapper, antialias: Bool, rect: LayoutRectWrapper, side: BoxSide,
    borderColor: CSSPropertyID, borderStyle: BorderStyle, tableBorderStyle: BorderStyle
  ) {
    if tableBorderStyle == .Hidden {
      return
    }
    var rect = rect
    rect.intersect(other: paintInfo.rect)
    if rect.isEmpty() {
      return
    }
    BorderPainter.drawLineForBoxSide(
      graphicsContext: paintInfo.context(), document: document(), rect: rect.FloatRect(),
      side: side,
      color: style().visitedDependentColorWithColorFilter(colorProperty: borderColor),
      borderStyle: borderStyle,
      adjacentWidth1: 0, adjacentWidth2: 0, antialias: antialias)
  }

  private func paintRowGroupBorderIfRequired(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, row: UInt32, column: UInt32,
    borderSide: BoxSide, cell: RenderTableCellWrapper? = nil
  ) {
    if table()!.currentBorderValue()!.precedence.rawValue > BorderPrecedence.RowGroup.rawValue {
      return
    }
    if paintInfo.context().paintingDisabled() {
      return
    }

    let style = style()
    let antialias = BorderPainter.shouldAntialiasLines(context: paintInfo.context())
    var rowGroupRect = LayoutRectWrapper(location: paintOffset, size: size())
    rowGroupRect.moveBy(
      offset: -LayoutPointWrapper(
        x: outerBorderLeft(styleForCellFlow: style),
        y: borderSide == .Right
          ? LayoutUnit(value: UInt64(0)) : outerBorderTop(styleForCellFlow: style)))

    switch borderSide {
    case .Top:
      paintRowGroupBorder(
        paintInfo: paintInfo, antialias: antialias,
        rect: LayoutRectWrapper(
          x: paintOffset.x
            + offsetLeftForRowGroupBorder(cell: cell, rowGroupRect: rowGroupRect, row: row),
          y: rowGroupRect.y(),
          width: horizontalRowGroupBorderWidth(
            cell: cell, rowGroupRect: rowGroupRect, row: row, column: column),
          height: LayoutUnit(value: style.borderTop().width)), side: .Top,
        borderColor: .CSSPropertyBorderTopColor,
        borderStyle: style.borderTopStyle(), tableBorderStyle: table()!.style().borderTopStyle())
    case .Bottom:
      paintRowGroupBorder(
        paintInfo: paintInfo, antialias: antialias,
        rect: LayoutRectWrapper(
          x: paintOffset.x
            + offsetLeftForRowGroupBorder(cell: cell, rowGroupRect: rowGroupRect, row: row),
          y: rowGroupRect.y() + rowGroupRect.height(),
          width: horizontalRowGroupBorderWidth(
            cell: cell, rowGroupRect: rowGroupRect, row: row, column: column),
          height: LayoutUnit(value: style.borderBottom().width)), side: .Bottom,
        borderColor: .CSSPropertyBorderBottomColor,
        borderStyle: style.borderBottomStyle(),
        tableBorderStyle: table()!.style().borderBottomStyle())
    case .Left:
      paintRowGroupBorder(
        paintInfo: paintInfo, antialias: antialias,
        rect: LayoutRectWrapper(
          x: rowGroupRect.x(),
          y: rowGroupRect.y()
            + offsetTopForRowGroupBorder(cell: cell, borderSide: borderSide, row: row),
          width: LayoutUnit(value: style.borderLeft().width),
          height: verticalRowGroupBorderHeight(cell: cell, rowGroupRect: rowGroupRect, row: row)),
        side: .Left,
        borderColor: .CSSPropertyBorderLeftColor, borderStyle: style.borderLeftStyle(),
        tableBorderStyle: table()!.style().borderLeftStyle())
    case .Right:
      paintRowGroupBorder(
        paintInfo: paintInfo, antialias: antialias,
        rect: LayoutRectWrapper(
          x: rowGroupRect.x() + rowGroupRect.width(),
          y: rowGroupRect.y()
            + offsetTopForRowGroupBorder(cell: cell, borderSide: borderSide, row: row),
          width: LayoutUnit(value: style.borderRight().width),
          height: verticalRowGroupBorderHeight(cell: cell, rowGroupRect: rowGroupRect, row: row)),
        side: .Right,
        borderColor: .CSSPropertyBorderRightColor, borderStyle: style.borderRightStyle(),
        tableBorderStyle: table()!.style().borderRightStyle())
    }
  }

  private func offsetLeftForRowGroupBorder(
    cell: RenderTableCellWrapper?, rowGroupRect: LayoutRectWrapper, row: UInt32
  ) -> LayoutUnit {
    if table()!.style().isHorizontalWritingMode() {
      if table()!.style().isLeftToRightDirection() {
        return cell != nil ? cell!.x() + cell!.width() : LayoutUnit(value: UInt64(0))
      }
      return -outerBorderLeft(styleForCellFlow: style())
    }
    let isLastRow = row + 1 == grid.count
    return rowGroupRect.width() - rowPos[Int(row + 1)]
      + (isLastRow ? -outerBorderLeft(styleForCellFlow: style()) : LayoutUnit(value: UInt64(0)))
  }

  private func offsetTopForRowGroupBorder(
    cell: RenderTableCellWrapper?, borderSide: BoxSide, row: UInt32
  ) -> LayoutUnit {
    let isLastRow = row + 1 == grid.count
    let zero = LayoutUnit(value: UInt64(0))
    if table()!.style().isHorizontalWritingMode() {
      return rowPos[Int(row)]
        + (row == 0 && borderSide == .Right
          ? -outerBorderTop(styleForCellFlow: style())
          : isLastRow && borderSide == .Left
            ? outerBorderTop(styleForCellFlow: style()) : zero)
    }
    if table()!.style().isLeftToRightDirection() {
      return (cell != nil ? cell!.y() + cell!.height() : zero)
        + (borderSide == .Left ? outerBorderTop(styleForCellFlow: style()) : zero)
    }
    return borderSide == .Right ? -outerBorderTop(styleForCellFlow: style()) : zero
  }

  private func verticalRowGroupBorderHeight(
    cell: RenderTableCellWrapper?, rowGroupRect: LayoutRectWrapper, row: UInt32
  ) -> LayoutUnit {
    let zero = LayoutUnit(value: UInt64(0))
    let isLastRow = row + 1 == grid.count
    if table()!.style().isHorizontalWritingMode() {
      return rowPos[Int(row + 1)] - rowPos[Int(row)]
        + (row == 0
          ? outerBorderTop(styleForCellFlow: style())
          : isLastRow ? outerBorderBottom(styleForCellFlow: style()) : zero)
    }
    if table()!.style().isLeftToRightDirection() {
      return rowGroupRect.height() - (cell != nil ? cell!.y() + cell!.height() : zero)
        + outerBorderBottom(styleForCellFlow: style())
    }
    return cell != nil ? rowGroupRect.height() - (cell!.y() - cell!.height()) : zero
  }

  private func horizontalRowGroupBorderWidth(
    cell: RenderTableCellWrapper?, rowGroupRect: LayoutRectWrapper, row: UInt32, column: UInt32
  ) -> LayoutUnit {
    let zero = LayoutUnit(value: UInt64(0))
    if table()!.style().isHorizontalWritingMode() {
      if table()!.style().isLeftToRightDirection() {
        return rowGroupRect.width() - (cell != nil ? cell!.x() + cell!.width() : zero)
          + (column == 0
            ? outerBorderLeft(styleForCellFlow: style())
            : column == table()!.numEffCols() ? outerBorderRight(styleForCellFlow: style()) : zero)
      }
      return cell != nil ? rowGroupRect.width() - (cell!.x() - cell!.width()) : zero
    }
    let isLastRow = row + 1 == grid.count
    return rowPos[Int(row + 1)] - rowPos[Int(row)]
      + (isLastRow
        ? outerBorderLeft(styleForCellFlow: style())
        : row == 0 ? outerBorderRight(styleForCellFlow: style()) : zero)
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ action: HitTestAction
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func ensureRows(numRows: UInt32) {
    if numRows <= grid.count {
      return
    }

    let oldSize = grid.count
    for _ in oldSize..<Int(numRows) {
      grid.append(RowStruct())
    }

    let effectiveColumnCount = Int(max(1, table()!.numEffCols()))
    for row in oldSize..<grid.count {
      let oldCols = grid[row].row.count
      for _ in oldCols..<effectiveColumnCount {
        grid[row].row.append(CellStruct())
      }
    }
  }

  private func relayoutCellIfFlexed(
    cell: RenderTableCellWrapper, rowIndex: Int, rowHeight: LayoutUnit
  ) {
    // Force percent height children to lay themselves out again.
    // This will cause these children to grow to fill the cell.
    // FIXME: There is still more work to do here to fully match WinIE (should
    // it become necessary to do so). In quirks mode, WinIE behaves like we
    // do, but it will clip the cells that spill out of the table section. In
    // strict mode, Mozilla and WinIE both regrow the table to accommodate the
    // new height of the cell (thus letting the percentages cause growth one
    // time only). We may also not be handling row-spanning cells correctly.
    //
    // Note also the oddity where replaced elements always flex, and yet blocks/tables do
    // not necessarily flex. WinIE is crazy and inconsistent, and we can't hope to
    // match the behavior perfectly, but we'll continue to refine it as we discover new
    // bugs. :)
    var cellChildrenFlex = false
    let flexAllChildren =
      cell.style().logicalHeight().isFixed()
      || (!table()!.style().logicalHeight().isAuto() && rowHeight != cell.logicalHeight())

    for renderer: RenderBoxWrapper in childrenOfType(parent: cell) {
      if renderer.style().logicalHeight().isPercentOrCalculated()
        && (flexAllChildren || shouldFlexCellChild(cell: cell, cellDescendant: renderer))
      {
        let renderTable = renderer as? RenderTableWrapper
        if renderTable == nil || renderTable!.hasSections() {
          cellChildrenFlex = true
          break
        }
      }
    }

    if !cellChildrenFlex {
      if let percentHeightDescendants = cell.percentHeightDescendants() {
        for descendant in percentHeightDescendants {
          if flexAllChildren || shouldFlexCellChild(cell: cell, cellDescendant: descendant) {
            cellChildrenFlex = true
            break
          }
        }
      }
    }

    if !cellChildrenFlex {
      return
    }

    cell.setChildNeedsLayout(markParents: .MarkOnlyThis)
    // Alignment within a cell is based off the calculated
    // height, which becomes irrelevant once the cell has
    // been resized based off its percentage.
    cell.setOverridingLogicalHeightFromRowHeight(rowHeight: rowHeight)
    cell.layoutIfNeeded()

    if !cell.isBaselineAligned() {
      return
    }

    // If the baseline moved, we may have to update the data for our row. Find out the new baseline.
    let baseline = cell.cellBaselinePosition()
    if baseline > cell.borderAndPaddingBefore() {
      grid[rowIndex].baseline = max(grid[rowIndex].baseline, baseline)
    }
  }

  private func distributeExtraLogicalHeightToPercentRows(
    extraLogicalHeight: inout LayoutUnit, totalPercent: Int
  ) {
    if totalPercent == 0 {
      return
    }

    let totalRows = grid.count
    let totalHeight = rowPos[totalRows] + extraLogicalHeight
    var totalLogicalHeightAdded = LayoutUnit()
    var totalPercent = min(totalPercent, 100)
    var rowHeight = rowPos[1] - rowPos[0]
    for (r, row) in grid.enumerated() {
      if totalPercent > 0 && row.logicalHeight.isPercent() {
        var toAdd = min(
          extraLogicalHeight,
          LayoutUnit(value: (totalHeight * row.logicalHeight.percent() / 100) - rowHeight))
        // If toAdd is negative, then we don't want to shrink the row (this bug
        // affected Outlook Web Access).
        toAdd = max(LayoutUnit(value: UInt64(0)), toAdd)
        totalLogicalHeightAdded += toAdd
        extraLogicalHeight -= toAdd
        totalPercent -= Int(row.logicalHeight.percent())
      }
      assert(totalRows >= 1)
      if r < totalRows - 1 {
        rowHeight = rowPos[r + 2] - rowPos[r + 1]
      }
      rowPos[r + 1] += totalLogicalHeightAdded
    }
  }

  private func distributeExtraLogicalHeightToAutoRows(
    extraLogicalHeight: inout LayoutUnit, autoRowsCount: UInt32
  ) {
    if autoRowsCount == 0 {
      return
    }

    var totalLogicalHeightAdded = LayoutUnit()
    var autoRowsCount = autoRowsCount
    for (r, row) in grid.enumerated() {
      if autoRowsCount > 0 && row.logicalHeight.isAuto() {
        // Recomputing |extraLogicalHeightForRow| guarantees that we properly ditribute round |extraLogicalHeight|.
        let extraLogicalHeightForRow = extraLogicalHeight / autoRowsCount
        totalLogicalHeightAdded += extraLogicalHeightForRow
        extraLogicalHeight -= extraLogicalHeightForRow
        autoRowsCount -= 1
      }
      rowPos[r + 1] += totalLogicalHeightAdded
    }
  }

  private func distributeRemainingExtraLogicalHeight(extraLogicalHeight: inout LayoutUnit) {
    let totalRows = grid.count

    if extraLogicalHeight <= Int32(0) || !rowPos[totalRows].bool() {
      return
    }

    // FIXME: rowPos[totalRows] - rowPos[0] is the total rows' size.
    let totalRowSize = rowPos[totalRows]
    var totalLogicalHeightAdded = LayoutUnit()
    var previousRowPosition = rowPos[0]
    for r in 0..<totalRows {
      // weight with the original height
      totalLogicalHeightAdded +=
        extraLogicalHeight * (rowPos[r + 1] - previousRowPosition) / totalRowSize
      previousRowPosition = rowPos[r + 1]
      rowPos[r + 1] += totalLogicalHeightAdded
    }

    extraLogicalHeight -= totalLogicalHeightAdded
  }

  private func hasOverflowingCell() -> Bool {
    return overflowingCells.computeSize() != 0 || forceSlowPaintPathWithOverflowingCell
  }

  private func computeOverflowFromCells(totalRows: UInt32, nEffCols: UInt32) {
    clearOverflow()
    overflowingCells.clear()
    let totalCellsCount = nEffCols * totalRows
    let maxAllowedOverflowingCellsCount =
      totalCellsCount < gMinTableSizeToUseFastPaintPathWithOverflowingCell
      ? 0 : UInt32(gMaxAllowedOverflowingCellRatioForFastPaintPath * Float32(totalCellsCount))

    #if ASSERT_ENABLED
      var hasOverflowingCell = false
    #endif
    // Now that our height has been determined, add in overflow from cells.
    for r in 0..<totalRows {
      for c in 0..<nEffCols {
        let cs = cellAt(row: r, col: c)
        let cell = cs.primaryCell()
        if cell == nil || cs.inColSpan {
          continue
        }
        if r < totalRows - 1
          && CPtrToInt(cell!.p) == CPtrToInt(primaryCellAt(row: r + 1, col: c)?.p)
        {
          continue
        }
        addOverflowFromChild(child: cell!)
        #if ASSERT_ENABLED
          hasOverflowingCell = hasOverflowingCell || cell!.hasVisualOverflow()
        #endif
        if cell!.hasVisualOverflow() && !forceSlowPaintPathWithOverflowingCell {
          overflowingCells.add(value: cell!)
          if overflowingCells.computeSize() > maxAllowedOverflowingCellsCount {
            // We need to set m_forcesSlowPaintPath only if there is a least one overflowing cells as the hit testing code rely on this information.
            forceSlowPaintPathWithOverflowingCell = true
            // The slow path does not make any use of the overflowing cells info, don't hold on to the memory.
            overflowingCells.clear()
          }
        }
      }
    }
    #if ASSERT_ENABLED
      assert(hasOverflowingCell == self.hasOverflowingCell())
    #endif
  }

  private func fullTableRowSpan() -> CellSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func fullTableColumnSpan() -> CellSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Flip the rect so it aligns with the coordinates used by the rowPos and columnPos vectors.
  private func logicalRectForWritingModeAndDirection(rect: LayoutRectWrapper) -> LayoutRectWrapper {
    var tableAlignedRect = rect

    flipForWritingMode(rect: &tableAlignedRect)

    if !style().isHorizontalWritingMode() {
      tableAlignedRect = tableAlignedRect.transposedRect()
    }

    let columnPos = table()!.columnPositions()
    // The table's writing mode determines in which direction the rows flow.
    if !table()!.style().isLeftToRightDirection() {
      tableAlignedRect.setX(x: columnPos[columnPos.count - 1] - tableAlignedRect.maxX())
    }

    return tableAlignedRect
  }

  private func dirtiedRows(damageRect: LayoutRectWrapper) -> CellSpan {
    if forceSlowPaintPathWithOverflowingCell {
      return fullTableRowSpan()
    }

    var coveredRows = spannedRows(
      flippedRect: damageRect, shouldIncludeAllIntersectionCells: .IncludeAllIntersectingCells)

    // To repaint the border we might need to repaint first or last row even if they are not spanned themselves.
    if coveredRows.start >= rowPos.count - 1
      && rowPos[rowPos.count - 1] + table()!.outerBorderAfter() >= damageRect.y()
    {
      coveredRows.start -= 1
    }

    if coveredRows.end == 0 && rowPos[0] - table()!.outerBorderBefore() <= damageRect.maxY() {
      coveredRows.end += 1
    }

    return coveredRows
  }

  private func dirtiedColumns(damageRect: LayoutRectWrapper) -> CellSpan {
    if forceSlowPaintPathWithOverflowingCell {
      return fullTableColumnSpan()
    }

    var coveredColumns = spannedColumns(
      flippedRect: damageRect, shouldIncludeAllIntersectionCells: .IncludeAllIntersectingCells)

    let columnPos = table()!.columnPositions()
    // To repaint the border we might need to repaint first or last column even if they are not spanned themselves.
    if coveredColumns.start >= columnPos.count - 1
      && columnPos[columnPos.count - 1] + table()!.outerBorderEnd() >= damageRect.x()
    {
      coveredColumns.start -= 1
    }

    if coveredColumns.end == 0 && columnPos[0] - table()!.outerBorderStart() <= damageRect.maxX() {
      coveredColumns.end += 1
    }

    return coveredColumns
  }

  // These two functions take a rectangle as input that has been flipped by logicalRectForWritingModeAndDirection.
  // The returned span of rows or columns is end-exclusive, and empty if start==end.
  // The IncludeAllIntersectingCells argument is used to determine which cells to include when
  // an edge of the flippedRect lies exactly on a cell boundary. Using IncludeAllIntersectingCells
  // will return both cells, and using DoNotIncludeAllIntersectingCells will return only the cell
  // that hittesting should return.
  private func spannedRows(
    flippedRect: LayoutRectWrapper,
    shouldIncludeAllIntersectionCells: ShouldIncludeAllIntersectingCells
  ) -> CellSpan {
    // Find the first row that starts after rect top.
    var nextRow = rowPos.partitioningIndex(where: { r in r > flippedRect.y() })
    if shouldIncludeAllIntersectionCells == .IncludeAllIntersectingCells && nextRow != 0
      && rowPos[nextRow - 1] == flippedRect.y()
    {
      nextRow -= 1
    }

    if nextRow == rowPos.count {
      return CellSpan(start: UInt32(rowPos.count - 1), end: UInt32(rowPos.count - 1))  // After all rows.
    }

    let startRow = nextRow > 0 ? nextRow - 1 : 0

    // Find the first row that starts after rect bottom.
    var endRow = 0
    if rowPos[nextRow] >= flippedRect.maxY() {
      endRow = nextRow
    } else {
      endRow = rowPos[nextRow...].partitioningIndex(where: { c in c > flippedRect.maxY() })
      if endRow == rowPos.count {
        endRow = rowPos.count - 1
      }
    }

    return CellSpan(start: UInt32(startRow), end: UInt32(endRow))
  }

  private func spannedColumns(
    flippedRect: LayoutRectWrapper,
    shouldIncludeAllIntersectionCells: ShouldIncludeAllIntersectingCells
  ) -> CellSpan {
    let columnPos = table()!.columnPositions()

    // Find the first column that starts after rect left.
    // lower_bound doesn't handle the edge between two cells properly as it would wrongly return the
    // cell on the logical top/left.
    // upper_bound on the other hand properly returns the cell on the logical bottom/right, which also
    // matches the behavior of other browsers.
    var nextColumn = columnPos.partitioningIndex(where: { c in c > flippedRect.x() })
    if shouldIncludeAllIntersectionCells == .IncludeAllIntersectingCells && nextColumn != 0
      && columnPos[nextColumn - 1] == flippedRect.x()
    {
      nextColumn -= 1
    }

    if nextColumn == columnPos.count {
      return CellSpan(start: UInt32(columnPos.count - 1), end: UInt32(columnPos.count - 1))  // After all columns.
    }

    let startColumn = nextColumn > 0 ? nextColumn - 1 : 0

    // Find the first column that starts after rect right.
    var endColumn = 0
    if columnPos[nextColumn] >= flippedRect.maxX() {
      endColumn = nextColumn
    } else {
      endColumn = columnPos[nextColumn...].partitioningIndex(where: { c in c > flippedRect.maxX() })
      if endColumn == columnPos.count {
        endColumn = columnPos.count - 1
      }
    }

    return CellSpan(start: UInt32(startColumn), end: UInt32(endColumn))
  }

  private func setLogicalPositionForCell(cell: RenderTableCellWrapper, effectiveColumn: UInt32) {
    let oldCellLocation = cell.location()

    var cellLocation = LayoutPointWrapper(
      x: LayoutUnit(value: UInt64(0)), y: rowPos[Int(cell.rowIndex())])
    let horizontalBorderSpacing = table()!.hBorderSpacing()

    // The table's writing mode determines in which direction the rows flow.
    if !table()!.style().isLeftToRightDirection() {
      cellLocation.setX(
        x: table()!.columnPositions()[Int(table()!.numEffCols())]
          - table()!.columnPositions()[
            Int(table()!.colToEffCol(column: cell.col() + cell.colSpan()))]
          + horizontalBorderSpacing)
    } else {
      cellLocation.setX(
        x: table()!.columnPositions()[Int(effectiveColumn)] + horizontalBorderSpacing)
    }

    cell.setLogicalLocation(location: cellLocation)
    view().frameView().layoutContext().addLayoutDelta(delta: oldCellLocation - cell.location())
  }

  private var grid: [RowStruct] = []
  private var rowPos: [LayoutUnit] = []

  // the current insertion position
  var cCol: UInt32 = 0
  var cRow: UInt32 = 0

  var outerBorderBefore = LayoutUnit()
  var outerBorderAfter = LayoutUnit()
  var outerBorderStart = LayoutUnit()
  var outerBorderEnd = LayoutUnit()

  // This HashSet holds the overflowing cells for faster painting.
  // If we have more than gMaxAllowedOverflowingCellRatio * total cells, it will be empty
  // and m_forceSlowPaintPathWithOverflowingCell will be set to save memory.
  private let overflowingCells = WeakHashSet<RenderTableCellWrapper>()

  private var forceSlowPaintPathWithOverflowingCell = false
  private var hasMultipleCellLevels = false
  var needsCellRecalc = false
}
