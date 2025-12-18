/*
 * Copyright (C) 2002 Lars Knoll (knoll@kde.org)
 *           (C) 2002 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2019 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License.
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

class TableLayout {
  init(table: RenderTableWrapper) {
    self.table = table
  }

  func computeIntrinsicLogicalWidths(intrinsics: TableIntrinsics) -> (LayoutUnit, LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scaledWidthFromPercentColumns() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layout() { fatalError("Not reached") }

  // FIXME: Once we enable SATURATED_LAYOUT_ARITHMETHIC, this should just be LayoutUnit.nearlyMax().
  // Until then though, using nearlyMax causes overflow in some tests, so we just pick a large number.
  static let tableMaxWidth = 1_000_000

  let table: RenderTableWrapper
}
