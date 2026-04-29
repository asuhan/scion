/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Simon Hausmann (hausmann@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2017 Apple Inc. All rights reserved.
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

import wk_interop

final class HTMLFrameSetElementWrapper: HTMLElementWrapper {
  func noResize() -> Bool { return wk_interop.HTMLFrameSetElement_noResize(p) }

  func totalRows() -> Int32 { return wk_interop.HTMLFrameSetElement_totalRows(p) }

  func totalCols() -> Int32 { return wk_interop.HTMLFrameSetElement_totalCols(p) }

  func border() -> Int32 { return wk_interop.HTMLFrameSetElement_border(p) }

  func hasBorderColor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowLengths() -> ArraySlice<LengthWrapper> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colLengths() -> ArraySlice<LengthWrapper> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
