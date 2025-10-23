/*
 * Copyright (C) 2017 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

private func canCollapseNextSibling(
  previousSibling: RenderBoxWrapper, nextSibling: RenderBoxWrapper
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

extension RenderTreeBuilder {
  class Table {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func findOrCreateParentForChild(
      parent: RenderTableRowWrapper, child: RenderObjectWrapper,
      beforeChild: inout RenderObjectWrapper?
    ) -> RenderElementWrapper {
      if child is RenderTableCellWrapper {
        return parent
      }

      if beforeChild != nil && !beforeChild!.isAnonymous()
        && CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p)
      {
        let previousSibling = beforeChild!.previousSibling()
        if let tableCell = previousSibling as? RenderTableCellWrapper, tableCell.isAnonymous() {
          beforeChild = nil
          return tableCell
        }
      }

      let lastChild = beforeChild ?? parent.lastCell()
      if lastChild != nil {
        if let tableCell = lastChild as? RenderTableCellWrapper,
          tableCell.isAnonymous() && !tableCell.isBeforeOrAfterContent()
        {
          if CPtrToInt(beforeChild?.p) == CPtrToInt(lastChild!.p) {
            beforeChild = tableCell.firstChild()
          }
          return tableCell
        }

        // Try to find an anonymous container for the child.
        if let lastChildParent = lastChild!.parent() {
          if lastChildParent.isAnonymous() && !lastChildParent.isBeforeOrAfterContent() {
            // If beforeChild is inside an anonymous COLGROUP, create a cell for the new renderer.
            if lastChildParent is RenderTableColWrapper {
              return createAnonymousTableCell(parent: parent, beforeChild: &beforeChild)
            }
            // If beforeChild is inside an anonymous cell, insert into the cell.
            if lastChild is RenderTableCellWrapper {
              return lastChildParent
            }
            // If beforeChild is inside an anonymous row, insert into the row.
            if let tableRow = lastChildParent as? RenderTableRowWrapper {
              return createAnonymousTableCell(parent: tableRow, beforeChild: &beforeChild)
            }
          }
        }
      }
      return createAnonymousTableCell(parent: parent, beforeChild: &beforeChild)
    }

    private func createAnonymousTableCell(
      parent: RenderTableRowWrapper, beforeChild: inout RenderObjectWrapper?
    ) -> RenderTableCellWrapper {
      let cell = RenderTableCellWrapper.createAnonymousWithParentRenderer(parent: parent)
      builder.attach(parent: parent, child: cell, beforeChild: beforeChild)
      beforeChild = nil
      return cell
    }

    func findOrCreateParentForChild(
      parent: RenderTableSectionWrapper, child: RenderObjectWrapper,
      beforeChild: inout RenderObjectWrapper?
    ) -> RenderElementWrapper {
      if child is RenderTableRowWrapper {
        return parent
      }

      let lastChild = beforeChild ?? parent.lastRow()
      if let tableRow = lastChild as? RenderTableRowWrapper,
        tableRow.isAnonymous() && !tableRow.isBeforeOrAfterContent()
      {
        if CPtrToInt(beforeChild?.p) == CPtrToInt(lastChild?.p) {
          beforeChild = tableRow.firstCell()
        }
        return tableRow
      }

      if beforeChild != nil && !beforeChild!.isAnonymous()
        && CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p)
      {
        if let tableRow = beforeChild!.previousSibling() as? RenderTableRowWrapper,
          tableRow.isAnonymous()
        {
          beforeChild = nil
          return tableRow
        }
      }

      // If beforeChild is inside an anonymous cell/row, insert into the cell or into
      // the anonymous row containing it, if there is one.
      var parentCandidate = lastChild
      while parentCandidate != nil && parentCandidate!.parent() != nil
        && parentCandidate!.parent()!.isAnonymous() && !(parentCandidate is RenderTableRowWrapper)
      {
        parentCandidate = parentCandidate!.parent()
      }
      if let tableRow = parentCandidate as? RenderTableRowWrapper,
        tableRow.isAnonymous() && !tableRow.isBeforeOrAfterContent()
      {
        return tableRow
      }

      let row = RenderTableRowWrapper.createAnonymousWithParentRenderer(parent: parent)
      builder.attach(parent: parent, child: row, beforeChild: beforeChild)
      beforeChild = nil
      return row
    }

    func findOrCreateParentForChild(
      parent: RenderTableWrapper, child: RenderObjectWrapper,
      beforeChild: inout RenderObjectWrapper?
    ) -> RenderElementWrapper {
      if child is RenderTableCaptionWrapper || child is RenderTableSectionWrapper {
        return parent
      }

      if child is RenderTableColWrapper {
        if child.node() == nil || child.style().display() == .TableColumnGroup {
          // COLGROUPs and anonymous RenderTableCols (generated wrappers for COLs) are direct children of the table renderer.
          return parent
        }
        let colGroup = CreateRenderer.RenderTableCol(
          document: parent.document(),
          style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
            parentStyle: parent.style(), display: .TableColumnGroup))
        colGroup.initializeStyle()
        builder.attach(parent: parent, child: colGroup, beforeChild: beforeChild)
        beforeChild = nil
        return colGroup
      }

      let lastChild = parent.lastChild()
      if let tableSection = lastChild as? RenderTableSectionWrapper,
        beforeChild == nil && tableSection.isAnonymous() && !tableSection.isBeforeContent()
      {
        return tableSection
      }

      if beforeChild != nil && !beforeChild!.isAnonymous()
        && CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p)
      {
        if let tableSection = beforeChild!.previousSibling() as? RenderTableSectionWrapper,
          tableSection.isAnonymous()
        {
          beforeChild = nil
          return tableSection
        }
      }

      var parentCandidate = beforeChild
      while parentCandidate != nil && parentCandidate!.parent()!.isAnonymous()
        && !(parentCandidate is RenderTableSectionWrapper)
        && parentCandidate!.style().display() != .TableCaption
        && parentCandidate!.style().display() != .TableColumnGroup
      {
        parentCandidate = parentCandidate!.parent()
      }

      if parentCandidate != nil {
        if beforeChild != nil && !beforeChild!.isAnonymous()
          && CPtrToInt(parentCandidate!.parent()?.p) == CPtrToInt(parent.p)
        {
          if let tableSection = parentCandidate!.previousSibling() as? RenderTableSectionWrapper,
            tableSection.isAnonymous()
          {
            beforeChild = nil
            return tableSection
          }
        }

        if let parentTableSection = parentCandidate as? RenderTableSectionWrapper,
          parentTableSection.isAnonymous() && !parent.isAfterContent(obj: parentTableSection)
        {
          if CPtrToInt(beforeChild?.p) == CPtrToInt(parentCandidate?.p) {
            beforeChild = parentTableSection.firstRow()
          }
          return parentTableSection
        }
      }

      if beforeChild != nil && !(beforeChild is RenderTableSectionWrapper)
        && beforeChild!.style().display() != .TableCaption
        && beforeChild!.style().display() != .TableColumnGroup
      {
        beforeChild = nil
      }

      let section = RenderTableSectionWrapper.createAnonymousWithParentRenderer(parent: parent)
      builder.attach(parent: parent, child: section, beforeChild: beforeChild)
      beforeChild = nil
      return section
    }

    func attach(
      parent: RenderTableWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      var beforeChild = beforeChild
      if beforeChild != nil && CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p) {
        beforeChild = builder.splitAnonymousBoxesAroundChild(
          parent: parent, originalBeforeChild: beforeChild!)
      }

      let newChild = child!
      if let renderTableSection = newChild as? RenderTableSectionWrapper {
        parent.willInsertTableSection(child: renderTableSection, beforeChild: beforeChild)
      } else if let renderTableCol = newChild as? RenderTableColWrapper {
        parent.willInsertTableColumn(child: renderTableCol, beforeChild: beforeChild)
      }

      builder.attachToRenderElement(parent: parent, child: newChild, beforeChild: beforeChild)
    }

    func attach(
      parent: RenderTableSectionWrapper, child: RenderObjectWrapper?,
      beforeChild: RenderObjectWrapper?
    ) {
      var beforeChild = beforeChild
      if beforeChild != nil && CPtrToInt(beforeChild!.parent()?.p) != CPtrToInt(parent.p) {
        beforeChild = builder.splitAnonymousBoxesAroundChild(
          parent: parent, originalBeforeChild: beforeChild!)
      }

      // FIXME: child should always be a RenderTableRow at this point.
      if let renderTableRow = child as? RenderTableRowWrapper {
        parent.willInsertTableRow(child: renderTableRow, beforeChild: beforeChild)
      }
      assert(beforeChild == nil || beforeChild is RenderTableRowWrapper)
      builder.attachToRenderElement(parent: parent, child: child!, beforeChild: beforeChild)
    }

    func attach(
      parent: RenderTableRowWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      var beforeChild = beforeChild
      if beforeChild != nil && CPtrToInt(beforeChild!.parent()?.p) != CPtrToInt(parent.p) {
        beforeChild = builder.splitAnonymousBoxesAroundChild(
          parent: parent, originalBeforeChild: beforeChild!)
      }

      assert(beforeChild == nil || beforeChild is RenderTableCellWrapper)
      builder.attachToRenderElement(parent: parent, child: child!, beforeChild: beforeChild)
      // FIXME: child should always be a RenderTableCell at this point.
      if let renderTableCell = child as? RenderTableCellWrapper {
        parent.didInsertTableCell(child: renderTableCell, beforeChild: beforeChild)
      }
    }

    func childRequiresTable(parent: RenderElementWrapper, child: RenderObjectWrapper) -> Bool {
      if let newTableColumn = child as? RenderTableColWrapper {
        let isColumnInColumnGroup =
          newTableColumn.isTableColumn() && parent is RenderTableColWrapper
        return !(parent is RenderTableWrapper) && !isColumnInColumnGroup
      }
      if child is RenderTableCaptionWrapper {
        return !(parent is RenderTableWrapper)
      }

      if child is RenderTableSectionWrapper {
        return !(parent is RenderTableWrapper)
      }

      if child is RenderTableRowWrapper {
        return !(parent is RenderTableSectionWrapper)
      }

      if child is RenderTableCellWrapper {
        return !(parent is RenderTableRowWrapper)
      }

      return false
    }

    func collapseAndDestroyAnonymousSiblingCells(willBeDestroyed: RenderTableCellWrapper) {
      if let nextCellToDestroy = collapseAndDetachAnonymousNextSibling(
        parent: willBeDestroyed.row(), previousSibling: willBeDestroyed.previousCell(),
        nextSibling: willBeDestroyed.nextCell())
      {
        (nextCellToDestroy as! RenderTableCellWrapper).deleteLines()
      }
    }

    func collapseAndDestroyAnonymousSiblingRows(willBeDestroyed: RenderTableRowWrapper) {
      let _ = collapseAndDetachAnonymousNextSibling(
        parent: willBeDestroyed.section(), previousSibling: willBeDestroyed.previousRow(),
        nextSibling: willBeDestroyed.nextRow())
    }

    private func collapseAndDetachAnonymousNextSibling<
      Parent: RenderElementWrapper, Child: RenderBoxWrapper
    >(
      parent: Parent?, previousSibling: Child?, nextSibling: Child?
    ) -> RenderObjectWrapper? {
      if parent == nil || previousSibling == nil || nextSibling == nil {
        return nil
      }
      if !canCollapseNextSibling(previousSibling: previousSibling!, nextSibling: nextSibling!) {
        return nil
      }
      builder.moveAllChildren(
        from: nextSibling!, to: previousSibling!, normalizeAfterInsertion: .No)
      previousSibling!.setChildrenInline(
        b: previousSibling!.firstInFlowChild() == nil
          || previousSibling!.firstInFlowChild()!.isInline())
      return builder.detach(parent: parent!, child: nextSibling!, willBeDestroyed: .Yes)
    }

    private let builder: RenderTreeBuilder
  }
}
