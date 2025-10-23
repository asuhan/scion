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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func findOrCreateParentForChild(
      parent: RenderTableWrapper, child: RenderObjectWrapper,
      beforeChild: inout RenderObjectWrapper?
    ) -> RenderElementWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func attach(
      parent: RenderTableWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func attach(
      parent: RenderTableSectionWrapper, child: RenderObjectWrapper?,
      beforeChild: RenderObjectWrapper?
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func attach(
      parent: RenderTableRowWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func collapseAndDestroyAnonymousSiblingRows(willBeDestroyed: RenderTableRowWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let builder: RenderTreeBuilder
  }
}
