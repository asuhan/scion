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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let span: UInt32 = 1
}
