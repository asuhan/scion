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

private func borderWidthChanged(_ oldStyle: RenderStyleWrapper, _ newStyle: RenderStyleWrapper)
  -> Bool
{
  return oldStyle.borderLeftWidth() != newStyle.borderLeftWidth()
    || oldStyle.borderTopWidth() != newStyle.borderTopWidth()
    || oldStyle.borderRightWidth() != newStyle.borderRightWidth()
    || oldStyle.borderBottomWidth() != newStyle.borderBottomWidth()
}

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

  func rowIndexWasSet() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowIndex() -> UInt32 {
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

  override func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    assert(parent() != nil)
    // Rows and cells are in the same coordinate space. We need to both compute our overflow rect (which
    // will accommodate a row outline and any visual effects on the row itself), but we also need to add in
    // the repaint rects of cells.
    var result = super.clippedOverflowRect(repaintContainer, context)
    var cell = firstCell()
    while cell != nil {
      // Even if a cell is a repaint container, it's the row that paints the background behind it.
      // So we don't care if a cell is a repaintContainer here.
      result.uniteIfNonZero(cell!.clippedOverflowRect(repaintContainer, context))
      cell = cell!.nextCell()
    }
    return result
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    var rects = RepaintRects(
      rect: clippedOverflowRect(repaintContainer, RenderObjectWrapper.visibleRectContextForRepaint))
    if repaintOutlineBounds == .Yes {
      rects.outlineBoundsRect = outlineBoundsForRepaint(repaintContainer)
    }

    return rects
  }

  override final func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(hasSelfPaintingLayer())

    paintOutlineForRowIfNeeded(paintInfo: paintInfo, paintOffset: paintOffset)
    var cell = firstCell()
    while cell != nil {
      // Paint the row background behind the cell.
      if paintInfo.phase == .BlockBackground || paintInfo.phase == .ChildBlockBackground {
        cell!.paintBackgroundsBehindCell(
          paintInfo: paintInfo, paintOffset: paintOffset, backgroundObject: self,
          backgroundPaintOffset: paintOffset)
      }
      if !cell!.hasSelfPaintingLayer() {
        cell!.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
      }
      cell = cell!.nextCell()
    }
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(style().display() == .TableRow)

    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    propagateStyleToAnonymousChildren(propagationType: .AllChildren)

    if section() != nil && oldStyle != nil && style().logicalHeight() != oldStyle!.logicalHeight() {
      section()!.rowLogicalHeightChanged(rowIndex())
    }

    // If border was changed, notify table.
    guard let table = table() else {
      return
    }

    if oldStyle != nil && !oldStyle!.borderIsEquivalentForPainting(style()) {
      table.invalidateCollapsedBorders()
    }

    if oldStyle != nil && diff == .Layout && needsLayout() && table.collapseBorders()
      && borderWidthChanged(oldStyle!, style())
    {
      // If the border width changes on a row, we need to make sure the cells in the row know to lay out again.
      // This only happens when borders are collapsed, since they end up affecting the border sides of the cell
      // itself.
      let propagageNeedsLayoutOnBorderSizeChange = { (row: RenderTableRowWrapper) in
        var cell = row.firstCell()
        while cell != nil {
          cell!.setNeedsLayoutAndPrefWidthsRecalc()
          cell = cell!.nextCell()
        }
      }
      propagageNeedsLayoutOnBorderSizeChange(self)
      if let previousRow = previousRow() {
        propagageNeedsLayoutOnBorderSizeChange(previousRow)
      }
      if let nextRow = nextRow() {
        propagageNeedsLayoutOnBorderSizeChange(nextRow)
      }
    }
  }
}
