/**
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
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

final class RenderTableRowWrapper: RenderBoxWrapper {
  func nextRow() -> RenderTableRowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func previousRow() -> RenderTableRowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstCell() -> RenderTableCellWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastCell() -> RenderTableCellWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func table() -> RenderTableWrapper? {
    if let section = section() {
      return section.parent() as! RenderTableWrapper?
    }
    return nil
  }

  func paintOutlineForRowIfNeeded(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    let adjustedPaintOffset = paintOffset + location()
    let paintPhase = paintInfo.phase
    if (paintPhase == .Outline || paintPhase == .SelfOutline)
      && style().usedVisibility() == .Visible
    {
      paintOutline(
        paintInfo: paintInfo,
        paintRect: LayoutRectWrapper(location: adjustedPaintOffset, size: size()))
    }
  }

  static func createAnonymousWithParentRenderer(parent: RenderTableSectionWrapper)
    -> RenderTableRowWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setRowIndex(rowIndex: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    #if ASSERT_ENABLED
      assert(cell.isFirstOrLastCellInRow())
    #endif
    // FIXME: https://webkit.org/b/79272 - Add support for mixed directionality at the cell level.
    return style().borderStart(styleForFlow: table()!.style())
  }

  func borderAdjoiningEndCell(cell: RenderTableCellWrapper) -> BorderValue {
    #if ASSERT_ENABLED
      assert(cell.isFirstOrLastCellInRow())
    #endif
    // FIXME: https://webkit.org/b/79272 - Add support for mixed directionality at the cell level.
    return style().borderEnd(styleForFlow: table()!.style())
  }

  func section() -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func didInsertTableCell(child: RenderTableCellWrapper, beforeChild: RenderObjectWrapper?) {
    // Generated content can result in us having a null section so make sure to null check our parent.
    if let section = section() {
      section.addCell(cell: child, row: self)
      if beforeChild != nil || nextRow() != nil {
        section.setNeedsCellRecalc()
      }
    }
    if let table = table() {
      table.invalidateCollapsedBorders()
    }
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    // Table rows do not add translation.
    let _ = LayoutStateMaintainer(
      root: self, offset: LayoutSizeWrapper(),
      disablePaintOffsetCache: isTransformed() || hasReflection()
        || style().isFlippedBlocksWritingMode())

    let layoutState = view().frameView().layoutContext().layoutState()!
    let paginated = layoutState.isPaginated()

    var cell = firstCell()
    while cell != nil {
      if !cell!.needsLayout() && paginated
        && (layoutState.pageLogicalHeightChanged()
          || (layoutState.pageLogicalHeight().bool()
            && layoutState.pageLogicalOffset(child: cell!, childLogicalOffset: cell!.logicalTop())
              != cell!.pageLogicalOffset()))
      {
        cell!.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }

      if cell!.needsLayout() {
        cell!.layout()
      }
      cell = cell!.nextCell()
    }

    clearOverflow()
    addVisualEffectOverflow()
    // We only ever need to repaint if our cells didn't, which menas that they didn't need
    // layout, so we know that our bounds didn't change. This code is just making up for
    // the fact that we did not repaint in setStyle() because we had a layout hint.
    // We cannot call repaint() because our clippedOverflowRect() is taken from the
    // parent table, and being mid-layout, that is invalid. Instead, we repaint our cells.
    if selfNeedsLayout() && checkForRepaintDuringLayout() {
      var cell = firstCell()
      while cell != nil {
        cell!.repaint()
        cell = cell!.nextCell()
      }
    }

    // RenderTableSection.layoutRows will set our logical height and width later, so it calls updateLayerTransform().
    clearNeedsLayout()
  }
}
