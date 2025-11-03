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
  let start: UInt32
  let end: UInt32
}

enum CollapsedBorderSide {
  case CBSBefore
  case CBSAfter
  case CBSStart
  case CBSEnd
}

private let gMaxAllowedOverflowingCellRatioForFastPaintPath: Float32 = 0.1

private func setRowLogicalHeightToRowStyleLogicalHeight(row: RenderTableSectionWrapper.RowStruct) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func compareCellPositions(
  elem1: WeakNullableRef<RenderTableCellWrapper>, elem2: WeakNullableRef<RenderTableCellWrapper>
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

// This comparison is used only when we have overflowing cells as we have an unsorted array to sort. We thus need
// to sort both on rows and columns to properly repaint.
private func compareCellPositionsWithOverflowingCells(
  elem1: WeakNullableRef<RenderTableCellWrapper>, elem2: WeakNullableRef<RenderTableCellWrapper>
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

  func table() -> RenderTableWrapper? { return parent() as! RenderTableWrapper? }

  class CellStruct {
    let cells: [RenderTableCellWrapper] = []

    func primaryCell() -> RenderTableCellWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func hasCells() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  struct RowStruct {
    var rowRenderer: RenderTableRowWrapper? = nil
  }

  func cellAt(row: UInt32, col: UInt32) -> CellStruct {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func primaryCellAt(row: UInt32, col: UInt32) -> RenderTableCellWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderLeft(styleForCellFlow: RenderStyleWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderTop(styleForCellFlow: RenderStyleWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsCellRecalc() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    let totalCols = table()!.columns.count

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
      setRowLogicalHeightToRowStyleLogicalHeight(row: grid[Int(insertionRow)])
    }
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func horizontalRowGroupBorderWidth(
    cell: RenderTableCellWrapper?, rowGroupRect: LayoutRectWrapper, row: UInt32, column: UInt32
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func ensureRows(numRows: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Flip the rect so it aligns with the coordinates used by the rowPos and columnPos vectors.
  private func logicalRectForWritingModeAndDirection(rect: LayoutRectWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func dirtiedRows(damageRect: LayoutRectWrapper) -> CellSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func dirtiedColumns(damageRect: LayoutRectWrapper) -> CellSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var grid: [RowStruct] = []
  private let rowPos: [LayoutUnit] = []

  // the current insertion position
  var cCol: UInt32 = 0
  var cRow: UInt32 = 0

  // This HashSet holds the overflowing cells for faster painting.
  // If we have more than gMaxAllowedOverflowingCellRatio * total cells, it will be empty
  // and m_forceSlowPaintPathWithOverflowingCell will be set to save memory.
  private let overflowingCells = WeakHashSet<RenderTableCellWrapper>()

  private let hasMultipleCellLevels = false
}
