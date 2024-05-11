/*
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
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
 *
 */

import wk_interop

class AtomStringWrapper {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  init() {}

  func string() -> StringWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return StringWrapper(p: wk_interop.AtomString_string(p))
  }

  func isNull() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.AtomString_isNull(p)
  }

  var p: UnsafeRawPointer? = nil
}

func nullAtom() -> AtomStringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
