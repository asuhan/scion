/*
 * Copyright (C) 2006-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2007-2008 Torch Mobile, Inc.
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

class FontWrapper: Hashable {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  static func == (lhs: FontWrapper, rhs: FontWrapper) -> Bool {
    return lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }

  func hasVerticalGlyphs() -> Bool {
    return wk_interop.Font_hasVerticalGlyphs(p)
  }

  func fontMetrics() -> FontMetricsWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var p: UnsafeRawPointer
}
