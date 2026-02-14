/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
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

final class RenderTableColWrapper: RenderBoxWrapper {
  init(document: Document, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearPreferredLogicalWidthsDirtyBits() {
    setPreferredLogicalWidthsDirty(shouldBeDirty: false)

    for child: RenderObjectWrapper in childrenOfType(parent: self) {
      child.setPreferredLogicalWidthsDirty(shouldBeDirty: false)
    }
  }

  func isTableColumnGroupWithColumnChildren() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTableColumn() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTableColumnGroup() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingColumnGroup() -> RenderTableColWrapper? {
    guard let parentColumnGroup = parent() as? RenderTableColWrapper else { return nil }

    assert(parentColumnGroup.isTableColumnGroup())
    assert(isTableColumn())
    return parentColumnGroup
  }

  func enclosingColumnGroupIfAdjacentBefore() -> RenderTableColWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingColumnGroupIfAdjacentAfter() -> RenderTableColWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the next column or column-group.
  func nextColumn() -> RenderTableColWrapper? {
    // If |this| is a column-group, the next column is the colgroup's first child column.
    if let firstChild = firstChild() {
      return firstChild as! RenderTableColWrapper?
    }

    // Otherwise it's the next column along.
    var next = nextSibling()

    // Failing that, the child is the last column in a column-group, so the next column is the next column/column-group after its column-group.
    if next == nil && parent() is RenderTableColWrapper {
      next = parent()!.nextSibling()
    }

    while next != nil {
      if let column = next as? RenderTableColWrapper {
        return column
      }
      next = next!.nextSibling()
    }

    return nil
  }

  func borderAdjoiningCellStartBorder() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAdjoiningCellEndBorder() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAdjoiningCellBefore(cell: RenderTableCellWrapper) -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAdjoiningCellAfter(cell: RenderTableCellWrapper) -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computePreferredLogicalWidths() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    // For now, just repaint the whole table.
    // FIXME: Find a better way to do this, e.g., need to repaint all the cells that we
    // might have propagated a background color or borders into.
    // FIXME: check for repaintContainer each time here?

    guard let parentTable = table() else { return LayoutRectWrapper() }

    return parentTable.clippedOverflowRect(repaintContainer, context)
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    guard let table = table() else {
      return
    }
    // If border was changed, notify table.
    guard let oldStyle = oldStyle else {
      return
    }
    if !oldStyle.borderIsEquivalentForPainting(style()) {
      table.invalidateCollapsedBorders()
      return
    }
    if oldStyle.width() != style().width() {
      table.recalcSectionsIfNeeded()
      for section: RenderTableSectionWrapper in childrenOfType(parent: table) {
        let nEffCols = table.numEffCols()
        for j in 0..<nEffCols {
          let rowCount = section.numRows()
          for i in 0..<rowCount {
            if let cell = section.primaryCellAt(row: i, col: j) {
              cell.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
            }
          }
        }
      }
    }
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {}

  private func table() -> RenderTableWrapper? {
    var table = parent()
    if table != nil && !(table is RenderTableWrapper) {
      table = table!.parent()
    }
    return table as? RenderTableWrapper
  }

  let span: UInt32 = 1
}
