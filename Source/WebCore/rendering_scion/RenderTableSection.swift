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

private func physicalBorderForDirection(
  styleForCellFlow: RenderStyleWrapper, side: CollapsedBorderSide
) -> BoxSide {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
    func primaryCell() -> RenderTableCellWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  struct RowStruct {
    let rowRenderer: RenderTableRowWrapper? = nil
  }

  func cellAt(row: UInt32, col: UInt32) -> CellStruct {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func primaryCellAt(row: UInt32, col: UInt32) -> RenderTableCellWrapper? {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintCell(
    cell: RenderTableCellWrapper, paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
            paintCell(cell: cell!, paintInfo: paintInfo, paintOffset: paintOffset)
          }
        }
      }
    } else {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private func paintRowGroupBorderIfRequired(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, row: UInt32, column: UInt32,
    borderSide: BoxSide, cell: RenderTableCellWrapper? = nil
  ) {
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

  private let grid: [RowStruct] = []

  // This HashSet holds the overflowing cells for faster painting.
  // If we have more than gMaxAllowedOverflowingCellRatio * total cells, it will be empty
  // and m_forceSlowPaintPathWithOverflowingCell will be set to save memory.
  private let overflowingCells = WeakHashSet<RenderTableCellWrapper>()

  private let hasMultipleCellLevels = false
}
