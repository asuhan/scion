/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2009 Apple Inc. All rights reserved.
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

final class RenderTableCellWrapper: RenderBlockFlowWrapper {
  func nextCell() -> RenderTableCellWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func previousCell() -> RenderTableCellWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func row() -> RenderTableRowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func section() -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func table() -> RenderTableWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: For now we just assume the cell has the same block flow direction as the table. It's likely we'll
  // create an extra anonymous RenderBlock to handle mixing directionality anyway, in which case we can lock
  // the block flow directionality of the cells to the table's directionality.
  override func paddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func createAnonymousWithParentRenderer(parent: RenderTableRowWrapper)
    -> RenderTableCellWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
