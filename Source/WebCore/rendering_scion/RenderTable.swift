/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2009, 2010, 2014 Apple Inc. All rights reserved.
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

enum SkipEmptySectionsValue {
  case DoNotSkipEmptySections
  case SkipEmptySections
}

enum TableIntrinsics {
  case ForLayout
  case ForKeyword
}

private func resetSectionPointerIfNotBefore(
  section: inout RenderTableSectionWrapper?, before: RenderObjectWrapper?
) {
  if before == nil || section == nil {
    return
  }
  var previousSibling = before!.previousSibling()
  while previousSibling != nil && CPtrToInt(previousSibling!.p) != CPtrToInt(section!.p) {
    previousSibling = previousSibling!.previousSibling()
  }
  if previousSibling == nil {
    section = nil
  }
}

class RenderTableWrapper: RenderBlockWrapper {
  // Per CSS 3 writing-mode: "The first and second values of the 'border-spacing' property represent spacing between columns
  // and rows respectively, not necessarily the horizontal and vertical spacing respectively".
  func hBorderSpacing() -> LayoutUnit { return hSpacing }

  func vBorderSpacing() -> LayoutUnit { return vSpacing }

  func collapseBorders() -> Bool { return style().borderCollapse() == .Collapse }

  override final func borderStart() -> LayoutUnit { return m_borderStart }

  override final func borderEnd() -> LayoutUnit { return m_borderEnd }

  override func borderBefore() -> LayoutUnit {
    if collapseBorders() {
      recalcSectionsIfNeeded()
      return outerBorderBefore()
    }
    return super.borderBefore()
  }

  override func borderAfter() -> LayoutUnit {
    if collapseBorders() {
      recalcSectionsIfNeeded()
      return outerBorderAfter()
    }
    return super.borderAfter()
  }

  override final func borderLeft() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isLeftToRightDirection() ? borderStart() : borderEnd()
    }
    return style().isFlippedBlocksWritingMode() ? borderAfter() : borderBefore()
  }

  override final func borderRight() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isLeftToRightDirection() ? borderEnd() : borderStart()
    }
    return style().isFlippedBlocksWritingMode() ? borderBefore() : borderAfter()
  }

  override final func borderTop() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isFlippedBlocksWritingMode() ? borderAfter() : borderBefore()
    }
    return style().isLeftToRightDirection() ? borderStart() : borderEnd()
  }

  override final func borderBottom() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isFlippedBlocksWritingMode() ? borderBefore() : borderAfter()
    }
    return style().isLeftToRightDirection() ? borderEnd() : borderStart()
  }

  func outerBorderBefore() -> LayoutUnit {
    if !collapseBorders() {
      return LayoutUnit(value: 0)
    }
    var borderWidth = LayoutUnit()

    if let topSection = topSection() {
      borderWidth = topSection.outerBorderBefore
      if borderWidth < Int32(0) {
        return LayoutUnit(value: 0)  // Overridden by hidden
      }
    }
    let tb = style().borderBefore()
    if tb.style == .Hidden {
      return LayoutUnit(value: 0)
    }
    if tb.style != .None {
      let collapsedBorderWidth = max(borderWidth, LayoutUnit(value: tb.width / 2))
      borderWidth = LayoutUnit(
        value: floorToDevicePixel(
          value: collapsedBorderWidth, pixelSnappingFactor: document().deviceScaleFactor()))
    }
    return borderWidth
  }

  func outerBorderAfter() -> LayoutUnit {
    if !collapseBorders() {
      return LayoutUnit(value: 0)
    }
    var borderWidth = LayoutUnit()

    if let section = bottomSection() {
      borderWidth = section.outerBorderAfter
      if borderWidth < Int32(0) {
        return LayoutUnit(value: 0)  // Overridden by hidden
      }
    }
    let tb = style().borderAfter()
    if tb.style == .Hidden {
      return LayoutUnit(value: 0)
    }
    if tb.style != .None {
      let deviceScaleFactor = document().deviceScaleFactor()
      let collapsedBorderWidth = max(
        borderWidth, LayoutUnit(value: (tb.width + (1 / deviceScaleFactor)) / 2))
      borderWidth = LayoutUnit(
        value: floorToDevicePixel(
          value: collapsedBorderWidth, pixelSnappingFactor: deviceScaleFactor))
    }
    return borderWidth
  }

  func outerBorderStart() -> LayoutUnit {
    if !collapseBorders() {
      return LayoutUnit(value: 0)
    }

    var borderWidth = LayoutUnit()

    let tb = style().borderStart()
    if tb.style == .Hidden {
      return LayoutUnit(value: 0)
    }
    if tb.style != .None {
      return CollapsedBorderValue.adjustedCollapsedBorderWidth(
        borderWidth: tb.width, deviceScaleFactor: document().deviceScaleFactor(),
        roundUp: !style().isLeftToRightDirection())
    }

    var allHidden = true
    var section = topSection()
    while section != nil {
      let sw = section!.outerBorderStart
      if sw < Int32(0) {
        section = sectionBelow(section: section)
        continue
      }
      allHidden = false
      borderWidth = max(borderWidth, sw)
      section = sectionBelow(section: section)
    }
    if allHidden {
      return LayoutUnit(value: 0)
    }

    return borderWidth
  }

  func outerBorderEnd() -> LayoutUnit {
    if !collapseBorders() {
      return LayoutUnit(value: 0)
    }

    var borderWidth = LayoutUnit()

    let tb = style().borderEnd()
    if tb.style == .Hidden {
      return LayoutUnit(value: 0)
    }
    if tb.style != .None {
      return CollapsedBorderValue.adjustedCollapsedBorderWidth(
        borderWidth: tb.width, deviceScaleFactor: document().deviceScaleFactor(),
        roundUp: style().isLeftToRightDirection())
    }

    var allHidden = true
    var section = topSection()
    while section != nil {
      let sw = section!.outerBorderEnd
      if sw < Int32(0) {
        section = sectionBelow(section: section)
        continue
      }
      allHidden = false
      borderWidth = max(borderWidth, sw)
      section = sectionBelow(section: section)
    }
    if allHidden {
      return LayoutUnit(value: 0)
    }

    return borderWidth
  }

  func outerBorderLeft() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isLeftToRightDirection() ? outerBorderStart() : outerBorderEnd()
    }
    return style().isFlippedBlocksWritingMode() ? outerBorderAfter() : outerBorderBefore()
  }

  func outerBorderRight() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isLeftToRightDirection() ? outerBorderEnd() : outerBorderStart()
    }
    return style().isFlippedBlocksWritingMode() ? outerBorderBefore() : outerBorderAfter()
  }

  func outerBorderTop() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isFlippedBlocksWritingMode() ? outerBorderAfter() : outerBorderBefore()
    }
    return style().isLeftToRightDirection() ? outerBorderStart() : outerBorderEnd()
  }

  func outerBorderBottom() -> LayoutUnit {
    if style().isHorizontalWritingMode() {
      return style().isFlippedBlocksWritingMode() ? outerBorderBefore() : outerBorderAfter()
    }
    return style().isLeftToRightDirection() ? outerBorderEnd() : outerBorderStart()
  }

  private func calcBorderStart() -> LayoutUnit {
    if !collapseBorders() {
      return super.borderStart()
    }

    // Determined by the first cell of the first row. See the CSS 2.1 spec, section 17.6.2.
    if numEffCols() == 0 {
      return LayoutUnit(value: 0)
    }

    var borderWidth: Float32 = 0

    let tableStartBorder = style().borderStart()
    if tableStartBorder.style == .Hidden {
      return LayoutUnit(value: 0)
    }
    if tableStartBorder.style != .None {
      borderWidth = tableStartBorder.width
    }

    if let column = colElement(col: 0) {
      // FIXME: We don't account for direction on columns and column groups.
      let columnAdjoiningBorder = column.style().borderStart()
      if columnAdjoiningBorder.style == .Hidden {
        return LayoutUnit(value: 0)
      }
      if columnAdjoiningBorder.style != .None {
        borderWidth = max(borderWidth, columnAdjoiningBorder.width)
      }
      // FIXME: This logic doesn't properly account for the first column in the first column-group case.
    }

    if let topNonEmptySection = topNonEmptySection() {
      let sectionAdjoiningBorder = topNonEmptySection.borderAdjoiningTableStart()
      if sectionAdjoiningBorder.style == .Hidden {
        return LayoutUnit(value: 0)
      }

      if sectionAdjoiningBorder.style != .None {
        borderWidth = max(borderWidth, sectionAdjoiningBorder.width)
      }

      if let adjoiningStartCell = topNonEmptySection.cellAt(row: 0, col: 0).primaryCell() {
        // FIXME: Make this work with perpendicular and flipped cells.
        let startCellAdjoiningBorder = adjoiningStartCell.borderAdjoiningTableStart()
        if startCellAdjoiningBorder.style == .Hidden {
          return LayoutUnit(value: 0)
        }

        let firstRowAdjoiningBorder = adjoiningStartCell.row()!.borderAdjoiningTableStart()
        if firstRowAdjoiningBorder.style == .Hidden {
          return LayoutUnit(value: 0)
        }

        if startCellAdjoiningBorder.style != .None {
          borderWidth = max(borderWidth, startCellAdjoiningBorder.width)
        }
        if firstRowAdjoiningBorder.style != .None {
          borderWidth = max(borderWidth, firstRowAdjoiningBorder.width)
        }
      }
    }
    return CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: borderWidth, deviceScaleFactor: document().deviceScaleFactor(),
      roundUp: !style().isLeftToRightDirection())
  }

  private func calcBorderEnd() -> LayoutUnit {
    if !collapseBorders() {
      return super.borderEnd()
    }

    // Determined by the last cell of the first row. See the CSS 2.1 spec, section 17.6.2.
    if numEffCols() == 0 {
      return LayoutUnit(value: 0)
    }

    var borderWidth: Float32 = 0

    let tableEndBorder = style().borderEnd()
    if tableEndBorder.style == .Hidden {
      return LayoutUnit(value: 0)
    }
    if tableEndBorder.style != .None {
      borderWidth = tableEndBorder.width
    }

    let endColumn = numEffCols() - 1
    if let column = colElement(col: endColumn) {
      // FIXME: We don't account for direction on columns and column groups.
      let columnAdjoiningBorder = column.style().borderEnd()
      if columnAdjoiningBorder.style == .Hidden {
        return LayoutUnit(value: 0)
      }
      if columnAdjoiningBorder.style != .None {
        borderWidth = max(borderWidth, columnAdjoiningBorder.width)
      }
      // FIXME: This logic doesn't properly account for the last column in the last column-group case.
    }

    if let topNonEmptySection = topNonEmptySection() {
      let sectionAdjoiningBorder = topNonEmptySection.borderAdjoiningTableEnd()
      if sectionAdjoiningBorder.style == .Hidden {
        return LayoutUnit(value: 0)
      }

      if sectionAdjoiningBorder.style != .None {
        borderWidth = max(borderWidth, sectionAdjoiningBorder.width)
      }

      if let adjoiningEndCell = topNonEmptySection.cellAt(row: 0, col: lastColumnIndex())
        .primaryCell()
      {
        // FIXME: Make this work with perpendicular and flipped cells.
        let endCellAdjoiningBorder = adjoiningEndCell.borderAdjoiningTableEnd()
        if endCellAdjoiningBorder.style == .Hidden {
          return LayoutUnit(value: 0)
        }

        let firstRowAdjoiningBorder = adjoiningEndCell.row()!.borderAdjoiningTableEnd()
        if firstRowAdjoiningBorder.style == .Hidden {
          return LayoutUnit(value: 0)
        }

        if endCellAdjoiningBorder.style != .None {
          borderWidth = max(borderWidth, endCellAdjoiningBorder.width)
        }
        if firstRowAdjoiningBorder.style != .None {
          borderWidth = max(borderWidth, firstRowAdjoiningBorder.width)
        }
      }
    }
    return CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: borderWidth, deviceScaleFactor: document().deviceScaleFactor(),
      roundUp: style().isLeftToRightDirection())
  }

  func recalcBordersInRowDirection() {
    // FIXME: We need to compute the collapsed before / after borders in the same fashion.
    self.m_borderStart = calcBorderStart()
    self.m_borderEnd = calcBorderEnd()
  }

  func forceSectionsRecalc() {
    setNeedsSectionRecalc()
    recalcSections()
  }

  struct ColumnStruct {
    var span: UInt32 = 1
  }

  func columns() -> ArraySlice<ColumnStruct> { return m_columns[...] }

  func columnPositions() -> ArraySlice<LayoutUnit> { return columnPos[...] }

  func setColumnPosition(index: Int, position: LayoutUnit) {
    // Note that if our horizontal border-spacing changed, our position will change but not
    // our column's width. In practice, horizontal border-spacing won't change often.
    columnLogicalWidthChanged = columnLogicalWidthChanged || columnPos[index] != position
    columnPos[index] = position
  }

  // This function returns nil if the table has no section.
  func topSection() -> RenderTableSectionWrapper? {
    assert(!needsSectionRecalc)
    if head != nil {
      return head
    }
    if firstBody != nil {
      return firstBody
    }
    return foot
  }

  func bottomSection() -> RenderTableSectionWrapper? {
    recalcSectionsIfNeeded()
    if foot != nil {
      return foot
    }
    var child = lastChild()
    while child != nil {
      if let tableSection = child as? RenderTableSectionWrapper {
        return tableSection
      }
      child = child!.previousSibling()
    }
    return nil
  }

  // This function returns 0 if the table has no non-empty sections.
  func topNonEmptySection() -> RenderTableSectionWrapper? {
    var section = topSection()
    if section != nil && section!.numRows() == 0 {
      section = sectionBelow(section: section, skipEmptySections: .SkipEmptySections)
    }
    return section
  }

  func bottomNonEmptySection() -> RenderTableSectionWrapper? {
    var section = bottomSection()
    if section != nil && section!.numRows() == 0 {
      section = sectionAbove(section: section, skipEmptySections: .SkipEmptySections)
    }
    return section
  }

  private func lastColumnIndex() -> UInt32 { return numEffCols() - 1 }

  func splitColumn(position: UInt32, firstSpan: UInt32) {
    // We split the column at "position", taking "firstSpan" cells from the span.
    assert(m_columns[Int(position)].span > firstSpan)
    m_columns.insert(ColumnStruct(span: firstSpan), at: Int(position))
    m_columns[Int(position + 1)].span -= firstSpan

    // Propagate the change in our columns representation to the sections that don't need
    // cell recalc. If they do, they will be synced up directly with m_columns later.
    for section: RenderTableSectionWrapper in childrenOfType(parent: self) {
      if section.needsCellRecalc {
        continue
      }

      section.splitColumn(pos: position, first: firstSpan)
    }

    while columnPos.count < numEffCols() + 1 {
      columnPos.append(LayoutUnit())
    }
  }

  func appendColumn(span: UInt32) {
    let newColumnIndex = UInt32(m_columns.count)
    m_columns.append(ColumnStruct(span: span))

    // Unless the table has cell(s) with colspan that exceed the number of columns afforded
    // by the other rows in the table we can use the fast path when mapping columns to effective columns.
    hasCellColspanThatDeterminesTableWidth = hasCellColspanThatDeterminesTableWidth || span > 1

    // Propagate the change in our columns representation to the sections that don't need
    // cell recalc. If they do, they will be synced up directly with m_columns later.
    for section: RenderTableSectionWrapper in childrenOfType(parent: self) {
      if section.needsCellRecalc {
        continue
      }

      section.appendColumn(pos: newColumnIndex)
    }

    while columnPos.count < numEffCols() + 1 {
      columnPos.append(LayoutUnit())
    }
  }

  func numEffCols() -> UInt32 { return UInt32(m_columns.count) }

  func spanOfEffCol(effCol: UInt32) -> UInt32 { return m_columns[Int(effCol)].span }

  func colToEffCol(column: UInt32) -> UInt32 {
    if !hasCellColspanThatDeterminesTableWidth {
      return column
    }

    var effColumn: UInt32 = 0
    let numColumns = numEffCols()
    var c: UInt32 = 0
    while effColumn < numColumns && c + m_columns[Int(effColumn)].span - 1 < column {
      c += m_columns[Int(effColumn)].span
      effColumn += 1
    }
    return effColumn
  }

  func effColToCol(effCol: UInt32) -> UInt32 {
    if !hasCellColspanThatDeterminesTableWidth {
      return effCol
    }

    var c: UInt32 = 0
    for i in 0..<effCol {
      c += m_columns[Int(i)].span
    }
    return c
  }

  private func borderSpacingInRowDirection() -> LayoutUnit {
    let effectiveColumnCount = numEffCols()
    if effectiveColumnCount != 0 {
      return (effectiveColumnCount + 1) * hBorderSpacing()
    }

    return LayoutUnit(value: 0)
  }

  func bordersPaddingAndSpacingInRowDirection() -> LayoutUnit {
    // 'border-spacing' only applies to separate borders (see 17.6.1 The separated borders model).
    return borderStart() + borderEnd()
      + (collapseBorders()
        ? LayoutUnit(value: UInt64(0))
        : (paddingStart() + paddingEnd() + borderSpacingInRowDirection()))
  }

  // Return the first column or column-group.
  func firstColumn() -> RenderTableColWrapper? {
    for child: RenderObjectWrapper in childrenOfType(parent: self) {
      if let column = child as? RenderTableColWrapper {
        return column
      }
    }
    return nil
  }

  func colElement(col: UInt32) -> RenderTableColWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colElement(col: UInt32, startEdge: inout Bool, endEdge: inout Bool) -> RenderTableColWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setNeedsSectionRecalc() {
    if renderTreeBeingDestroyed() {
      return
    }
    needsSectionRecalc = true
    setNeedsLayout()
  }

  func sectionAbove(
    section: RenderTableSectionWrapper?,
    skipEmptySections: SkipEmptySectionsValue = .DoNotSkipEmptySections
  ) -> RenderTableSectionWrapper? {
    recalcSectionsIfNeeded()

    if CPtrToInt(section?.p) == CPtrToInt(head?.p) {
      return nil
    }

    var prevSection =
      CPtrToInt(section?.p) == CPtrToInt(foot?.p) ? lastChild() : section!.previousSibling()
    while prevSection != nil {
      let tableSection = prevSection as? RenderTableSectionWrapper
      if tableSection != nil && CPtrToInt(prevSection!.p) != CPtrToInt(head?.p)
        && CPtrToInt(prevSection!.p) != CPtrToInt(foot?.p)
        && (skipEmptySections == .DoNotSkipEmptySections
          || (prevSection as! RenderTableSectionWrapper).numRows() != 0)
      {
        return tableSection
      }
      prevSection = prevSection!.previousSibling()
    }
    if prevSection == nil && head != nil
      && (skipEmptySections == .DoNotSkipEmptySections || head!.numRows() != 0)
    {
      return head
    }
    return nil
  }

  func sectionBelow(
    section: RenderTableSectionWrapper?,
    skipEmptySections: SkipEmptySectionsValue = .DoNotSkipEmptySections
  ) -> RenderTableSectionWrapper? {
    recalcSectionsIfNeeded()

    if CPtrToInt(section?.p) == CPtrToInt(foot?.p) {
      return nil
    }

    var nextSection =
      CPtrToInt(section?.p) == CPtrToInt(head?.p) ? firstChild() : section!.nextSibling()
    while nextSection != nil {
      let tableSection = nextSection as? RenderTableSectionWrapper
      if tableSection != nil && CPtrToInt(nextSection!.p) != CPtrToInt(head?.p)
        && CPtrToInt(nextSection!.p) != CPtrToInt(foot?.p)
        && (skipEmptySections == .DoNotSkipEmptySections
          || (nextSection as! RenderTableSectionWrapper).numRows() != 0)
      {
        return tableSection
      }
      nextSection = nextSection!.nextSibling()
    }
    if nextSection == nil && foot != nil
      && (skipEmptySections == .DoNotSkipEmptySections || foot!.numRows() != 0)
    {
      return foot
    }
    return nil
  }

  func cellAbove(cell: RenderTableCellWrapper) -> RenderTableCellWrapper? {
    recalcSectionsIfNeeded()

    // Find the section and row to look in
    let r = cell.rowIndex()
    var section: RenderTableSectionWrapper? = nil
    var rAbove: UInt32 = 0
    if r > 0 {
      // cell is not in the first row, so use the above row in its own section
      section = cell.section()
      rAbove = r - 1
    } else {
      section = sectionAbove(section: cell.section(), skipEmptySections: .SkipEmptySections)
      if section != nil {
        assert(section!.numRows() != 0)
        rAbove = section!.numRows() - 1
      }
    }

    // Look up the cell in the section's grid, which requires effective col index
    if section != nil {
      let effCol = colToEffCol(column: cell.col())
      let aboveCell = section!.cellAt(row: rAbove, col: effCol)
      return aboveCell.primaryCell()
    }

    return nil
  }

  func cellBelow(cell: RenderTableCellWrapper) -> RenderTableCellWrapper? {
    recalcSectionsIfNeeded()

    // Find the section and row to look in
    let r = cell.rowIndex() + cell.rowSpan() - 1
    var section: RenderTableSectionWrapper? = nil
    var rBelow: UInt32 = 0
    if r < cell.section()!.numRows() - 1 {
      // The cell is not in the last row, so use the next row in the section.
      section = cell.section()
      rBelow = r + 1
    } else {
      section = sectionBelow(section: cell.section(), skipEmptySections: .SkipEmptySections)
      if section != nil {
        rBelow = 0
      }
    }

    // Look up the cell in the section's grid, which requires effective col index
    if section != nil {
      let effCol = colToEffCol(column: cell.col())
      let belowCell = section!.cellAt(row: rBelow, col: effCol)
      return belowCell.primaryCell()
    }

    return nil
  }

  func cellBefore(cell: RenderTableCellWrapper) -> RenderTableCellWrapper? {
    recalcSectionsIfNeeded()

    let section = cell.section()
    let effCol = colToEffCol(column: cell.col())
    if effCol == 0 {
      return nil
    }

    // If we hit a colspan back up to a real cell.
    let prevCell = section!.cellAt(row: cell.rowIndex(), col: effCol - 1)
    return prevCell.primaryCell()
  }

  func cellAfter(cell: RenderTableCellWrapper) -> RenderTableCellWrapper? {
    recalcSectionsIfNeeded()

    let effCol = colToEffCol(column: cell.col() + cell.colSpan())
    if effCol >= numEffCols() {
      return nil
    }
    return cell.section()!.primaryCellAt(row: cell.rowIndex(), col: effCol)
  }

  typealias CollapsedBorderValues = [CollapsedBorderValue]

  func collapsedBordersAreValid() -> Bool { return collapsedBordersValid }

  func invalidateCollapsedBorders(cellWithStyleChange: RenderTableCellWrapper? = nil) {
    collapsedBordersValid = false
    collapsedBorders.removeAll()

    for section: RenderTableSectionWrapper in childrenOfType(parent: self) {
      section.clearCachedCollapsedBorders()
    }

    if !collapsedEmptyBorderIsPresent {
      return
    }

    if cellWithStyleChange != nil {
      // It is enough to invalidate just the surrounding cells when cell border style changes.
      cellWithStyleChange!.invalidateHasEmptyCollapsedBorders()
      if let below = cellBelow(cell: cellWithStyleChange!) {
        below.invalidateHasEmptyCollapsedBorders()
      }
      if let above = cellAbove(cell: cellWithStyleChange!) {
        above.invalidateHasEmptyCollapsedBorders()
      }
      if let before = cellBefore(cell: cellWithStyleChange!) {
        before.invalidateHasEmptyCollapsedBorders()
      }
      if let after = cellAfter(cell: cellWithStyleChange!) {
        after.invalidateHasEmptyCollapsedBorders()
      }
      return
    }

    for section: RenderTableSectionWrapper in childrenOfType(parent: self) {
      var row = section.firstRow()
      while row != nil {
        var cell = row!.firstCell()
        while cell != nil {
          assert(CPtrToInt(cell!.table()?.p) == CPtrToInt(p))
          cell!.invalidateHasEmptyCollapsedBorders()
          cell = cell!.nextCell()
        }
        row = row!.nextRow()
      }
    }
    collapsedEmptyBorderIsPresent = false
  }

  func currentBorderValue() -> CollapsedBorderValue? { return currentBorder }

  func hasSections() -> Bool { return head != nil || foot != nil || firstBody != nil }

  func recalcSectionsIfNeeded() {
    if needsSectionRecalc {
      recalcSections()
    }
  }

  static func createAnonymousWithParentRenderer(parent: RenderElementWrapper) -> RenderTableWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willInsertTableColumn(child: RenderTableColWrapper, beforeChild: RenderObjectWrapper?) {
    hasColElements = true
  }

  func willInsertTableSection(child: RenderTableSectionWrapper, beforeChild: RenderObjectWrapper?) {
    switch child.style().display() {
    case .TableHeaderGroup:
      resetSectionPointerIfNotBefore(section: &head, before: beforeChild)
      if head == nil {
        head = child
      } else {
        resetSectionPointerIfNotBefore(section: &firstBody, before: beforeChild)
        if firstBody == nil {
          firstBody = child
        }
      }
    case .TableFooterGroup:
      resetSectionPointerIfNotBefore(section: &foot, before: beforeChild)
      if foot == nil {
        foot = child
        break
      }
      fallthrough
    case .TableRowGroup:
      resetSectionPointerIfNotBefore(section: &firstBody, before: beforeChild)
      if firstBody == nil {
        firstBody = child
      }
    default:
      fatalError("Not reached")
    }

    setNeedsSectionRecalc()
  }

  func sumCaptionsLogicalHeight() -> LayoutUnit {
    var height = LayoutUnit()
    for caption in captions {
      height += caption!.logicalHeight() + caption!.marginBefore() + caption!.marginAfter()
    }
    return height
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func simplifiedNormalFlowLayout() {
    for caption in captions {
      caption!.layoutIfNeeded()
    }
    var section = topSection()
    while section != nil {
      section!.layoutIfNeeded()
      section!.layoutRows()
      section!.computeOverflowFromCells()
      section!.addVisualEffectOverflow()
      section = sectionBelow(section: section)
    }
  }

  override final func avoidsFloats() -> Bool { return true }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func paintObject(
    paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    var paintPhase = paintInfo.phase
    if (paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground)
      && hasVisibleBoxDecorations() && style().usedVisibility() == .Visible
    {
      paintBoxDecorations(paintInfo: paintInfo, paintOffset: paintOffset)
    }

    if paintPhase == .Mask {
      paintMask(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    if paintPhase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(renderBox: self, paintOffset: paintOffset)
    }

    // We're done.  We don't bother painting any children.
    if paintPhase == .BlockBackground {
      return
    }

    // We don't paint our own background, but we do let the kids paint their backgrounds.
    if paintPhase == .ChildBlockBackgrounds {
      paintPhase = .ChildBlockBackground
    }

    var info = paintInfo
    info.phase = paintPhase
    info.updateSubtreePaintRootForChildren(renderer: self)

    for box: RenderBoxWrapper in childrenOfType(parent: self) {
      if !box.hasSelfPaintingLayer() && (box.isRenderTableSection() || box.isRenderTableCaption()) {
        let childPoint = flipForWritingModeForChild(child: box, point: paintOffset)
        box.paint(paintInfo: &info, paintOffset: childPoint)
      }
    }

    if collapseBorders() && paintPhase == .ChildBlockBackground
      && style().usedVisibility() == .Visible
    {
      recalcCollapsedBorders()
      // Using our cached sorted styles, we then do individual passes,
      // painting each style of border from lowest precedence to highest precedence.
      info.phase = .CollapsedTableBorders
      for collapsedBorder in collapsedBorders {
        currentBorder = collapsedBorder
        var section = bottomSection()
        while section != nil {
          let childPoint = flipForWritingModeForChild(child: section!, point: paintOffset)
          section!.paint(paintInfo: &info, paintOffset: childPoint)
          section = sectionAbove(section: section)
        }
      }
      currentBorder = nil
    }

    // Paint outline.
    if (paintPhase == .Outline || paintPhase == .SelfOutline) && hasOutline()
      && style().usedVisibility() == .Visible
    {
      paintOutline(
        paintInfo: paintInfo, paintRect: LayoutRectWrapper(location: paintOffset, size: size()))
    }
  }

  final override func paintBoxDecorations(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    var rect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: &rect)

    let backgroundPainter = BackgroundPainter(renderer: self, paintInfo: paintInfo)

    let bleedAvoidance = determineBackgroundBleedAvoidance(context: paintInfo.context())
    if !BackgroundPainter.boxShadowShouldBeAppliedToBackground(
      renderer: self, paintOffset: rect.location(), bleedAvoidance: bleedAvoidance,
      inlineBox: InlineIterator.InlineBoxIterator())
    {
      backgroundPainter.paintBoxShadow(paintRect: rect, style: style(), shadowStyle: .Normal)
    }

    let stateSaver = GraphicsContextStateSaver(context: paintInfo.context(), saveAndRestore: false)
    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      // To avoid the background color bleeding out behind the border, we'll render background and border
      // into a transparency layer, and then clip that in one go (which requires setting up the clip before
      // beginning the layer).
      stateSaver.save()
      let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: rect)
      borderShape.clipToOuterShape(
        context: paintInfo.context(), deviceScaleFactor: document().deviceScaleFactor())
      paintInfo.context().beginTransparencyLayer(opacity: 1)
    }

    backgroundPainter.paintBackground(paintRect: rect, bleedAvoidance: bleedAvoidance)
    backgroundPainter.paintBoxShadow(paintRect: rect, style: style(), shadowStyle: .Inset)

    if style().hasVisibleBorderDecoration() && !collapseBorders() {
      let borderPainter = BorderPainter(renderer: self, paintInfo: paintInfo)
      borderPainter.paintBorder(rect: rect, style: style())
    }

    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      paintInfo.context().endTransparencyLayer()
    }
  }

  final override func paintMask(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if style().usedVisibility() != .Visible || paintInfo.phase != .Mask {
      return
    }

    var rect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: &rect)

    paintMaskImages(paintInfo: paintInfo, paintRect: rect)
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    if simplifiedLayout() {
      return
    }

    recalcSectionsIfNeeded()
    // FIXME: We should do this recalc lazily in borderStart/borderEnd so that we don't have to make sure
    // to call this before we call borderStart/borderEnd to avoid getting a stale value.
    recalcBordersInRowDirection()
    var sectionMoved = false
    var movedSectionLogicalTop = LayoutUnit()
    var sectionCount = 0
    var shouldCacheIntrinsicContentLogicalHeightForFlexItem = false

    let repainter = LayoutRepainter(renderer: self)
    do {
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())

      let oldLogicalWidth = logicalWidth()
      let oldLogicalHeight = logicalHeight()
      resetLogicalHeightBeforeLayoutIfNeeded()
      updateLogicalWidth()

      if logicalWidth() != oldLogicalWidth {
        for caption in captions {
          caption!.setNeedsLayout(markParents: .MarkOnlyThis)
        }
      }
      // FIXME: The optimisation below doesn't work since the internal table
      // layout could have changed. We need to add a flag to the table
      // layout that tells us if something has changed in the min max
      // calculations to do it correctly.
      //     if ( oldWidth != width() || columns.size() + 1 != columnPos.size() )
      tableLayout!.layout()

      var oldTableLogicalTop = LayoutUnit()
      for caption in captions {
        if caption!.style().captionSide() == .Bottom {
          continue
        }
        oldTableLogicalTop +=
          caption!.logicalHeight() + caption!.marginBefore() + caption!.marginAfter()
      }

      let collapsing = collapseBorders()

      var totalSectionLogicalHeight = LayoutUnit()
      for child: RenderElementWrapper in childrenOfType(parent: self) {
        if let section = child as? RenderTableSectionWrapper {
          if columnLogicalWidthChanged {
            section.setChildNeedsLayout(markParents: .MarkOnlyThis)
          }
          section.layoutIfNeeded()
          totalSectionLogicalHeight += section.calcRowLogicalHeight()
          if collapsing {
            section.recalcOuterBorder()
          }
          assert(!section.needsLayout())
        } else if let column = child as? RenderTableColWrapper {
          column.layoutIfNeeded()
          assert(!column.needsLayout())
        }
      }

      // If any table section moved vertically, we will just repaint everything from that
      // section down (it is quite unlikely that any of the following sections
      // did not shift).
      layoutCaptions()
      if !captions.isEmpty && logicalHeight() != oldTableLogicalTop {
        sectionMoved = true
        movedSectionLogicalTop = min(logicalHeight(), oldTableLogicalTop)
      }

      let zero = LayoutUnit(value: UInt64(0))
      let borderAndPaddingBefore = borderBefore() + (collapsing ? zero : paddingBefore())
      let borderAndPaddingAfter = borderAfter() + (collapsing ? zero : paddingAfter())

      setLogicalHeight(size: logicalHeight() + borderAndPaddingBefore)

      if !isOutOfFlowPositioned() {
        updateLogicalHeight()
      }

      var computedLogicalHeight = LayoutUnit()

      let logicalHeightLength = style().logicalHeight()
      if logicalHeightLength.isIntrinsic()
        || (logicalHeightLength.isSpecified() && logicalHeightLength.isPositive())
      {
        computedLogicalHeight = convertStyleLogicalHeightToComputedHeight(
          styleLogicalHeight: logicalHeightLength)
      }

      if let overridingLogicalHeight = overridingLogicalHeight() {
        computedLogicalHeight = max(
          computedLogicalHeight,
          overridingLogicalHeight - borderAndPaddingAfter - sumCaptionsLogicalHeight())
      }

      if !shouldIgnoreLogicalMinMaxHeightSizes() {
        let logicalMaxHeightLength = style().logicalMaxHeight()
        if logicalMaxHeightLength.isFillAvailable()
          || (logicalMaxHeightLength.isSpecified() && !logicalMaxHeightLength.isNegative()
            && !logicalMaxHeightLength.isMinContent() && !logicalMaxHeightLength.isMaxContent()
            && !logicalMaxHeightLength.isFitContent())
        {
          let computedMaxLogicalHeight = convertStyleLogicalHeightToComputedHeight(
            styleLogicalHeight: logicalMaxHeightLength)
          computedLogicalHeight = min(computedLogicalHeight, computedMaxLogicalHeight)
        }

        var logicalMinHeightLength = style().logicalMinHeight()
        if logicalMinHeightLength.isMinContent() || logicalMinHeightLength.isMaxContent()
          || logicalMinHeightLength.isFitContent()
        {
          logicalMinHeightLength = LengthWrapper(type: .Auto)
        }
        if logicalMinHeightLength.isIntrinsic()
          || (logicalMinHeightLength.isSpecified() && !logicalMinHeightLength.isNegative())
        {
          let computedMinLogicalHeight = convertStyleLogicalHeightToComputedHeight(
            styleLogicalHeight: logicalMinHeightLength)
          computedLogicalHeight = max(computedLogicalHeight, computedMinLogicalHeight)
        }
      }

      distributeExtraLogicalHeight(
        extraLogicalHeight: computedLogicalHeight - totalSectionLogicalHeight)

      var section_ = topSection()
      while section_ != nil {
        section_!.layoutRows()
        section_ = sectionBelow(section: section_)
      }

      if topSection() == nil && computedLogicalHeight > totalSectionLogicalHeight
        && !document().inQuirksMode()
      {
        // Completely empty tables (with no sections or anything) should at least honor their
        // overriding or specified height in strict mode, but this value will not be cached.
        shouldCacheIntrinsicContentLogicalHeightForFlexItem = false
        let tableLogicalHeight = { [self] in
          if let overridingLogicalHeight = overridingLogicalHeight() {
            return overridingLogicalHeight - borderAndPaddingAfter
          }
          return logicalHeight() + computedLogicalHeight
        }
        setLogicalHeight(size: tableLogicalHeight())
      }

      var sectionLogicalLeft = style().isLeftToRightDirection() ? borderStart() : borderEnd()
      if !collapsing {
        sectionLogicalLeft += style().isLeftToRightDirection() ? paddingStart() : paddingEnd()
      }

      // position the table sections
      var section = topSection()
      while section != nil {
        sectionCount += 1
        if !sectionMoved && section!.logicalTop() != logicalHeight() {
          sectionMoved = true
          movedSectionLogicalTop =
            min(logicalHeight(), section!.logicalTop())
            + (style().isHorizontalWritingMode()
              ? section!.visualOverflowRect().y() : section!.visualOverflowRect().x())
        }
        section!.setLogicalLocation(
          location: LayoutPointWrapper(x: sectionLogicalLeft, y: logicalHeight()))

        setLogicalHeight(size: logicalHeight() + section!.logicalHeight())
        section!.addVisualEffectOverflow()

        section = sectionBelow(section: section)
      }

      setLogicalHeight(size: logicalHeight() + borderAndPaddingAfter)

      layoutCaptions(bottomCaptionLayoutPhase: .Yes)

      if isOutOfFlowPositioned() {
        updateLogicalHeight()
      }

      // table can be containing block of positioned elements.
      let dimensionChanged =
        oldLogicalWidth != logicalWidth() || oldLogicalHeight != logicalHeight()
      layoutPositionedObjects(relayoutChildren: dimensionChanged)

      updateLayerTransform()

      // Layout was changed, so probably borders too.
      invalidateCollapsedBorders()

      // The location or height of one or more sections may have changed.
      invalidateCachedColumnOffsets()

      computeOverflow(oldClientAfterEdge: clientLogicalBottom())
    }

    let layoutState = view().frameView().layoutContext().layoutState()
    if layoutState != nil && layoutState!.pageLogicalHeight().bool() {
      setPageLogicalOffset(
        logicalOffset: layoutState!.pageLogicalOffset(child: self, childLogicalOffset: logicalTop())
      )
    }

    let didFullRepaint = repainter.repaintAfterLayout()
    // Repaint with our new bounds if they are different from our old bounds.
    if !didFullRepaint && sectionMoved {
      if style().isHorizontalWritingMode() {
        repaintRectangle(
          repaintRect: LayoutRectWrapper(
            x: visualOverflowRect().x(), y: movedSectionLogicalTop,
            width: visualOverflowRect().width(),
            height: visualOverflowRect().maxY() - movedSectionLogicalTop))
      } else {
        repaintRectangle(
          repaintRect: LayoutRectWrapper(
            x: movedSectionLogicalTop, y: visualOverflowRect().y(),
            width: visualOverflowRect().maxX() - movedSectionLogicalTop,
            height: visualOverflowRect().height()))
      }
    }

    let paginated = layoutState != nil && layoutState!.isPaginated()
    if sectionMoved && paginated {
      // FIXME: Table layout should always stabilize even when section moves (see webkit.org/b/174412).
      if recursiveSectionMovedWithPaginationLevel < sectionCount {
        let _ = SetForScope(
          scopedVariable: &recursiveSectionMovedWithPaginationLevel,
          newValue: recursiveSectionMovedWithPaginationLevel + 1)
        markForPaginationRelayoutIfNeeded()
        layoutIfNeeded()
      } else {
        fatalError("Not reached")
      }
    }

    // FIXME: This value isn't the intrinsic content logical height, but we need
    // to update the value as its used by flexbox layout. crbug.com/367324
    if shouldCacheIntrinsicContentLogicalHeightForFlexItem {
      cacheIntrinsicContentLogicalHeightForFlexItem(height: contentLogicalHeight())
    }

    columnLogicalWidthChanged = false
    clearNeedsLayout()
  }

  private func computeIntrinsicLogicalWidths(intrinsics: TableIntrinsics) -> (
    LayoutUnit, LayoutUnit
  ) {
    recalcSectionsIfNeeded()
    // FIXME: Do the recalc in borderStart/borderEnd and make those const_cast this call.
    // Then m_borderStart/m_borderEnd will be transparent a cache and it removes the possibility
    // of reading out stale values.
    recalcBordersInRowDirection()
    // FIXME: We should include captions widths here like we do in computePreferredLogicalWidths.
    return tableLayout!.computeIntrinsicLogicalWidths(intrinsics: intrinsics)
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    (minLogicalWidth, maxLogicalWidth) = computeIntrinsicLogicalWidths(intrinsics: .ForLayout)
  }

  override func computeIntrinsicKeywordLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    (minLogicalWidth, maxLogicalWidth) = computeIntrinsicLogicalWidths(intrinsics: .ForKeyword)
  }

  override func computePreferredLogicalWidths() {
    assert(preferredLogicalWidthsDirty())

    computeIntrinsicLogicalWidths(
      minLogicalWidth: &m_minPreferredLogicalWidth, maxLogicalWidth: &m_maxPreferredLogicalWidth)

    let bordersPaddingAndSpacing = bordersPaddingAndSpacingInRowDirection()
    m_minPreferredLogicalWidth += bordersPaddingAndSpacing
    m_maxPreferredLogicalWidth += bordersPaddingAndSpacing

    tableLayout!.applyPreferredLogicalWidthQuirks(
      minWidth: &m_minPreferredLogicalWidth, maxWidth: &m_maxPreferredLogicalWidth)

    for caption in captions {
      m_minPreferredLogicalWidth = max(
        m_minPreferredLogicalWidth, caption!.minPreferredLogicalWidth())
    }

    let styleToUse = style()
    // FIXME: This should probably be checking for isSpecified since you should be able to use percentage or calc values for min-width.
    if styleToUse.logicalMinWidth().isFixed() && styleToUse.logicalMinWidth().value() > 0 {
      m_maxPreferredLogicalWidth = max(
        m_maxPreferredLogicalWidth,
        adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: styleToUse.logicalMinWidth()))
      m_minPreferredLogicalWidth = max(
        m_minPreferredLogicalWidth,
        adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: styleToUse.logicalMinWidth()))
    }

    // FIXME: This should probably be checking for isSpecified since you should be able to use percentage or calc values for maxWidth.
    if styleToUse.logicalMaxWidth().isFixed() {
      m_maxPreferredLogicalWidth = min(
        m_maxPreferredLogicalWidth,
        adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: styleToUse.logicalMaxWidth()))
      m_maxPreferredLogicalWidth = max(m_maxPreferredLogicalWidth, m_minPreferredLogicalWidth)
    }

    // FIXME: We should be adding borderAndPaddingLogicalWidth here, but m_tableLayout->computePreferredLogicalWidths already does,
    // so a bunch of tests break doing this naively.
    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override func firstLineBaseline() -> LayoutUnit? {
    // The baseline of a 'table' is the same as the 'inline-table' baseline per CSS 3 Flexbox (CSS 2.1
    // doesn't define the baseline of a 'table' only an 'inline-table').
    // This is also needed to properly determine the baseline of a cell if it has a table child.

    if (isWritingModeRoot() && !isFlexItem()) || shouldApplyLayoutContainment() {
      return nil
    }

    recalcSectionsIfNeeded()

    if let topNonEmptySection = topNonEmptySection(),
      let baseline = topNonEmptySection.firstLineBaseline()
    {
      return topNonEmptySection.logicalTop() + baseline
    }

    // FIXME: A table row always has a baseline per CSS 2.1. Will this return the right value?
    return nil
  }

  override func lastLineBaseline() -> LayoutUnit? {
    if isWritingModeRoot() || shouldApplyLayoutContainment() {
      return nil
    }

    recalcSectionsIfNeeded()

    if let tableSection = bottomNonEmptySection(), let baseline = tableSection.lastLineBaseline() {
      return baseline + tableSection.logicalTop()
    }

    return nil
  }

  private func invalidateCachedColumnOffsets() {
    columnOffsetTop = LayoutUnit(value: -1)
    columnOffsetHeight = LayoutUnit(value: -1)
  }

  override func updateLogicalWidth() {
    recalcSectionsIfNeeded()

    if isGridItem() {
      // FIXME: Investigate whether the grid layout algorithm provides all the logic
      // needed and that we're not skipping anything essential due to the early return here.
      super.updateLogicalWidth()
      return
    }

    if isOutOfFlowPositioned() {
      var computedValues = LogicalExtentComputedValues()
      computePositionedLogicalWidth(computedValues: &computedValues)
      setLogicalWidth(size: computedValues.extent)
      setLogicalLeft(left: computedValues.position)
      setMarginStart(value: computedValues.margins.start)
      setMarginEnd(value: computedValues.margins.end)
    }

    let cb = containingBlock()!

    let availableLogicalWidth = containingBlockLogicalWidthForContent()
    let hasPerpendicularContainingBlock =
      cb.style().isHorizontalWritingMode() != style().isHorizontalWritingMode()
    let containerWidthInInlineDirection =
      hasPerpendicularContainingBlock
      ? perpendicularContainingBlockLogicalHeight() : availableLogicalWidth

    let styleLogicalWidth = style().logicalWidth()
    if let overridingLogicalWidth = overridingLogicalWidth() {
      setLogicalWidth(size: overridingLogicalWidth)
    } else if (styleLogicalWidth.isSpecified() && styleLogicalWidth.isPositive())
      || styleLogicalWidth.isIntrinsic()
    {
      setLogicalWidth(
        size: convertStyleLogicalWidthToComputedWidth(
          styleLogicalWidth: styleLogicalWidth, availableWidth: containerWidthInInlineDirection))
    } else {
      // Subtract out any fixed margins from our available width for auto width tables.
      let marginStart = minimumValueForLength(
        length: style().marginStart(), maximumValue: availableLogicalWidth)
      let marginEnd = minimumValueForLength(
        length: style().marginEnd(), maximumValue: availableLogicalWidth)
      let marginTotal = marginStart + marginEnd

      // Subtract out our margins to get the available content width.
      var availableContentLogicalWidth = max(
        LayoutUnit(value: 0), containerWidthInInlineDirection - marginTotal)
      if shrinkToAvoidFloats() && cb.containsFloats() && !hasPerpendicularContainingBlock {
        // FIXME: Work with regions someday.
        availableContentLogicalWidth = shrinkLogicalWidthToAvoidFloats(
          childMarginStart: marginStart, childMarginEnd: marginEnd, cb: cb, fragment: nil)
      }

      // Ensure we aren't bigger than our available width.
      setLogicalWidth(size: min(availableContentLogicalWidth, maxPreferredLogicalWidth()))
      var maxWidth = maxPreferredLogicalWidth()
      // scaledWidthFromPercentColumns depends on m_layoutStruct in TableLayoutAlgorithmAuto, which
      // maxPreferredLogicalWidth fills in. So scaledWidthFromPercentColumns has to be called after
      // maxPreferredLogicalWidth.
      let scaledWidth =
        tableLayout!.scaledWidthFromPercentColumns() + bordersPaddingAndSpacingInRowDirection()
      maxWidth = max(scaledWidth, maxWidth)
      setLogicalWidth(size: min(availableContentLogicalWidth, maxWidth))
    }

    // Ensure we aren't bigger than our max-width style.
    let styleMaxLogicalWidth = style().logicalMaxWidth()
    if (styleMaxLogicalWidth.isSpecified() && !styleMaxLogicalWidth.isNegative())
      || styleMaxLogicalWidth.isIntrinsic()
    {
      let computedMaxLogicalWidth = convertStyleLogicalWidthToComputedWidth(
        styleLogicalWidth: styleMaxLogicalWidth, availableWidth: availableLogicalWidth)
      setLogicalWidth(size: min(logicalWidth(), computedMaxLogicalWidth))
    }

    // Ensure we aren't smaller than our min preferred width.
    setLogicalWidth(size: max(logicalWidth(), minPreferredLogicalWidth()))

    // Ensure we aren't smaller than our min-width style.
    let styleMinLogicalWidth = style().logicalMinWidth()
    if (styleMinLogicalWidth.isSpecified() && !styleMinLogicalWidth.isNegative())
      || styleMinLogicalWidth.isIntrinsic()
    {
      let computedMinLogicalWidth = convertStyleLogicalWidthToComputedWidth(
        styleLogicalWidth: styleMinLogicalWidth, availableWidth: availableLogicalWidth)
      setLogicalWidth(size: max(logicalWidth(), computedMinLogicalWidth))
    }

    // Finally, with our true width determined, compute our margins for real.
    setMarginStart(value: LayoutUnit(value: 0))
    setMarginEnd(value: LayoutUnit(value: 0))
    if !hasPerpendicularContainingBlock {
      var containerLogicalWidthForAutoMargins = availableLogicalWidth
      if avoidsFloats() && cb.containsFloats() {
        containerLogicalWidthForAutoMargins = containingBlockAvailableLineWidthInFragment(
          fragment: nil)  // FIXME: Work with regions someday.
      }
      var marginValues = ComputedMarginValues()
      let hasInvertedDirection =
        cb.style().isLeftToRightDirection() == style().isLeftToRightDirection()
      if hasInvertedDirection {
        computeInlineDirectionMargins(
          containingBlock: cb, containerWidth: availableLogicalWidth,
          availableSpaceAdjustedWithFloats: containerLogicalWidthForAutoMargins,
          childWidth: logicalWidth(),
          marginStart: &marginValues.start, marginEnd: &marginValues.end)
      } else {
        computeInlineDirectionMargins(
          containingBlock: cb, containerWidth: availableLogicalWidth,
          availableSpaceAdjustedWithFloats: containerLogicalWidthForAutoMargins,
          childWidth: logicalWidth(),
          marginStart: &marginValues.end, marginEnd: &marginValues.start)
      }
      setMarginStart(value: marginValues.start)
      setMarginEnd(value: marginValues.end)
    } else {
      setMarginStart(
        value: minimumValueForLength(
          length: style().marginStart(), maximumValue: availableLogicalWidth))
      setMarginEnd(
        value: minimumValueForLength(
          length: style().marginEnd(), maximumValue: availableLogicalWidth))
    }
  }

  // This method takes a RenderStyle's logical width, min-width, or max-width length and computes its actual value.
  private func convertStyleLogicalWidthToComputedWidth(
    styleLogicalWidth: LengthWrapper, availableWidth: LayoutUnit
  ) -> LayoutUnit {
    if styleLogicalWidth.isIntrinsic() {
      return computeIntrinsicLogicalWidthUsing(
        logicalWidthLength: styleLogicalWidth, availableLogicalWidth: availableWidth,
        borderAndPadding: bordersPaddingAndSpacingInRowDirection())
    }

    // HTML tables' width styles already include borders and padding, but CSS tables' width styles do not.
    var borders = LayoutUnit()
    let isCSSTable = !(element() is HTMLTableElementWrapper)
    if isCSSTable && styleLogicalWidth.isSpecified() && styleLogicalWidth.isPositive()
      && style().boxSizing() == .ContentBox
    {
      borders =
        borderStart() + borderEnd()
        + (collapseBorders() ? LayoutUnit(value: UInt64(0)) : paddingStart() + paddingEnd())
    }

    return minimumValueForLength(length: styleLogicalWidth, maximumValue: availableWidth) + borders
  }

  private func convertStyleLogicalHeightToComputedHeight(styleLogicalHeight: LengthWrapper)
    -> LayoutUnit
  {
    let zero = LayoutUnit(value: UInt64(0))
    let borderAndPaddingBefore = borderBefore() + (collapseBorders() ? zero : paddingBefore())
    let borderAndPaddingAfter = borderAfter() + (collapseBorders() ? zero : paddingAfter())
    let borderAndPadding = borderAndPaddingBefore + borderAndPaddingAfter
    if styleLogicalHeight.isFixed() {
      // HTML tables size as though CSS height includes border/padding, CSS tables do not.
      var borders = LayoutUnit()
      // FIXME: We cannot apply box-sizing: content-box on <table> which other browsers allow.
      if (element() is HTMLTableElementWrapper) || style().boxSizing() == .BorderBox {
        borders = borderAndPadding
      }
      return LayoutUnit(value: styleLogicalHeight.value() - borders)
    } else if styleLogicalHeight.isPercentOrCalculated() {
      return computePercentageLogicalHeight(height: styleLogicalHeight) ?? LayoutUnit(value: 0)
    } else if styleLogicalHeight.isIntrinsic() {
      return computeIntrinsicLogicalContentHeightUsing(
        logicalHeightLength: styleLogicalHeight,
        intrinsicContentHeight: logicalHeight() - borderAndPadding,
        borderAndPadding: borderAndPadding) ?? LayoutUnit(value: 0)
    } else {
      fatalError("Not reached")
    }
  }

  override func addOverflowFromChildren() {
    // Add overflow from borders.
    // Technically it's odd that we are incorporating the borders into layout overflow, which is only supposed to be about overflow from our
    // descendant objects, but since tables don't support overflow:auto, this works out fine.
    if collapseBorders() {
      let rightBorderOverflow = width() + outerBorderRight() - borderRight()
      let leftBorderOverflow = borderLeft() - outerBorderLeft()
      let bottomBorderOverflow = height() + outerBorderBottom() - borderBottom()
      let topBorderOverflow = borderTop() - outerBorderTop()
      let borderOverflowRect = LayoutRectWrapper(
        x: leftBorderOverflow, y: topBorderOverflow,
        width: rightBorderOverflow - leftBorderOverflow,
        height: bottomBorderOverflow - topBorderOverflow)
      if borderOverflowRect != borderBoxRect() {
        addLayoutOverflow(rect: borderOverflowRect)
        addVisualOverflow(rect: borderOverflowRect)
      }
    }

    // Add overflow from our caption.
    for caption in captions {
      if caption != nil {
        addOverflowFromChild(child: caption!)
      }
    }

    // Add overflow from our sections.
    var section = topSection()
    while section != nil {
      addOverflowFromChild(child: section!)
      section = sectionBelow(section: section)
    }
  }

  override func adjustBorderBoxRectForPainting(paintRect: inout LayoutRectWrapper) {
    for caption in captions {
      let captionLogicalHeight =
        caption!.logicalHeight() + caption!.marginBefore() + caption!.marginAfter()
      let captionIsBefore =
        (caption!.style().captionSide() != .Bottom) != style().isFlippedBlocksWritingMode()
      if style().isHorizontalWritingMode() {
        paintRect.setHeight(height: paintRect.height() - captionLogicalHeight)
        if captionIsBefore {
          paintRect.move(dx: LayoutUnit(value: UInt64(0)), dy: captionLogicalHeight)
        }
      } else {
        paintRect.setWidth(width: paintRect.width() - captionLogicalHeight)
        if captionIsBefore {
          paintRect.move(dx: captionLogicalHeight, dy: LayoutUnit(value: UInt64(0)))
        }
      }
    }

    super.adjustBorderBoxRectForPainting(paintRect: &paintRect)
  }

  // Collect all the unique border values that we want to paint in a sorted list.
  private func recalcCollapsedBorders() {
    if collapsedBordersValid {
      return
    }
    collapsedBorders.removeAll()
    for section: RenderTableSectionWrapper in childrenOfType(parent: self) {
      var row = section.firstRow()
      while row != nil {
        var cell = row!.firstCell()
        while cell != nil {
          assert(CPtrToInt(cell!.table()?.p) == CPtrToInt(p))
          cell!.collectBorderValues(borderValues: &collapsedBorders)
          cell = cell!.nextCell()
        }
        row = row!.nextRow()
      }
    }
    RenderTableCellWrapper.sortBorderValues(borderValues: &collapsedBorders)
    collapsedBordersValid = true
  }

  private func recalcSections() {
    assert(needsSectionRecalc)

    head = nil
    foot = nil
    firstBody = nil
    hasColElements = false
    hasCellColspanThatDeterminesTableWidth = computeHasCellColspanThatDeterminesTableWidth()

    // We need to get valid pointers to caption, head, foot and first body again
    var nextSibling: RenderObjectWrapper? = nil
    var child = firstChild()
    while child != nil {
      nextSibling = child!.nextSibling()
      switch child!.style().display() {
      case .TableColumn, .TableColumnGroup:
        hasColElements = true
      case .TableHeaderGroup:
        if let section = child as? RenderTableSectionWrapper {
          if head == nil {
            head = section
          } else if firstBody == nil {
            firstBody = section
          }
          section.recalcCellsIfNeeded()
        }
      case .TableFooterGroup:
        if let section = child as? RenderTableSectionWrapper {
          if foot == nil {
            foot = section
          } else if firstBody == nil {
            firstBody = section
          }
          section.recalcCellsIfNeeded()
        }
      case .TableRowGroup:
        if let section = child as? RenderTableSectionWrapper {
          if firstBody == nil {
            firstBody = section
          }
          section.recalcCellsIfNeeded()
        }
      default:
        break
      }
      child = nextSibling
    }

    // repair column count (addChild can grow it too much, because it always adds elements to the last row of a section)
    var maxCols: UInt32 = 0
    for section: RenderTableSectionWrapper in childrenOfType(parent: self) {
      let sectionCols = section.numColumns()
      if sectionCols > maxCols {
        maxCols = sectionCols
      }
    }

    assert(maxCols >= m_columns.count)
    while m_columns.count < maxCols {
      m_columns.append(ColumnStruct())
    }
    assert(maxCols + 1 >= columnPos.count)
    while columnPos.count < maxCols + 1 {
      columnPos.append(LayoutUnit())
    }

    // Now that we know the number of maximum number of columns, let's shrink the sections grids if needed.
    for section: RenderTableSectionWrapper in childrenOfType(parent: self) {
      section.removeRedundantColumns()
    }

    assert(selfNeedsLayout() || wasSkippedDuringLastLayoutDueToContentVisibility() ?? true)

    needsSectionRecalc = false
  }

  enum BottomCaptionLayoutPhase {
    case No
    case Yes
  }

  private func layoutCaptions(bottomCaptionLayoutPhase: BottomCaptionLayoutPhase = .No) {
    if captions.isEmpty {
      return
    }
    // FIXME: Collapse caption margin.
    for caption in captions {
      if (bottomCaptionLayoutPhase == .Yes && caption!.style().captionSide() != .Bottom)
        || (bottomCaptionLayoutPhase == .No && caption!.style().captionSide() == .Bottom)
      {
        continue
      }
      layoutCaption(caption: caption!)
    }
  }

  private func layoutCaption(caption: RenderTableCaptionWrapper) {
    let captionRect = caption.frameRect()

    if caption.needsLayout() {
      // The margins may not be available but ensure the caption is at least located beneath any previous sibling caption
      // so that it does not mistakenly think any floats in the previous caption intrude into it.
      caption.setLogicalLocation(
        location: LayoutPointWrapper(
          x: caption.marginStart(), y: caption.marginBefore() + logicalHeight()))
      // If RenderTableCaption ever gets a layout() function, use it here.
      caption.layoutIfNeeded()
    }
    // Apply the margins to the location now that they are definitely available from layout
    caption.setLogicalLocation(
      location: LayoutPointWrapper(
        x: caption.marginStart(), y: caption.marginBefore() + logicalHeight()))

    if !selfNeedsLayout() && caption.checkForRepaintDuringLayout() {
      caption.repaintDuringLayoutIfMoved(oldRect: captionRect)
    }

    setLogicalHeight(
      size: logicalHeight() + caption.logicalHeight() + caption.marginBefore()
        + caption.marginAfter())
  }

  private func distributeExtraLogicalHeight(extraLogicalHeight: LayoutUnit) {
    if extraLogicalHeight <= Int32(0) {
      return
    }

    // FIXME: Distribute the extra logical height between all table sections instead of giving it all to the first one.
    var extraLogicalHeight = extraLogicalHeight
    if let section = firstBody {
      extraLogicalHeight -= section.distributeExtraLogicalHeightToRows(
        extraLogicalHeight: extraLogicalHeight)
    }

    // FIXME: We really would like to enable this ASSERT to ensure that all the extra space has been distributed.
    // However our current distribution algorithm does not round properly and thus we can have some remaining height.
    // ASSERT(!topSection() || !extraLogicalHeight);
  }

  private func computeHasCellColspanThatDeterminesTableWidth() -> Bool {
    for c in 0..<Int(numEffCols()) {
      if m_columns[c].span > 1 {
        return true
      }
    }
    return false
  }

  override func shouldResetLogicalHeightBeforeLayout() -> Bool { return true }

  private var columnPos: [LayoutUnit] = []
  private var m_columns: [ColumnStruct] = []
  private let captions: [RenderTableCaptionWrapper?] = []

  private var head: RenderTableSectionWrapper? = nil
  private var foot: RenderTableSectionWrapper? = nil
  private var firstBody: RenderTableSectionWrapper? = nil

  private let tableLayout: TableLayout? = nil

  private var collapsedBorders = CollapsedBorderValues()
  private var currentBorder: CollapsedBorderValue? = nil
  private var collapsedBordersValid = false
  private var collapsedEmptyBorderIsPresent = false

  private var hasColElements = false
  var needsSectionRecalc = false

  private var columnLogicalWidthChanged = false
  private var hasCellColspanThatDeterminesTableWidth = false

  private let hSpacing = LayoutUnit()
  private let vSpacing = LayoutUnit()
  private var m_borderStart = LayoutUnit()
  private var m_borderEnd = LayoutUnit()
  private var columnOffsetTop = LayoutUnit()
  private var columnOffsetHeight = LayoutUnit()
  private var recursiveSectionMovedWithPaginationLevel = 0
}
