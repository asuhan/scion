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

class AtomStringWrapper: Hashable, CustomStringConvertible {
  init(p: UnsafeRawPointer, _ owner: Bool = false) {
    self.p = p
    self.owner = owner
  }

  init() { self.owner = false }

  deinit {
    if self.owner {
      wk_interop.AtomString_destroy(p)
    }
  }

  func string() -> StringWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return StringWrapper(p: wk_interop.AtomString_string(p), owner: false)
  }

  func isNull() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.AtomString_isNull(p)
  }

  func isEmpty() -> Bool { return wk_interop.AtomString_isEmpty(p!) }

  func hash(into hasher: inout Hasher) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (lhs: AtomStringWrapper, rhs: AtomStringWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  public var description: String {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var p: UnsafeRawPointer? = nil
  private let owner: Bool
}

func nullAtom() -> AtomStringWrapper {
  return AtomStringWrapper(p: wk_interop.AtomString_nullAtom())
}
