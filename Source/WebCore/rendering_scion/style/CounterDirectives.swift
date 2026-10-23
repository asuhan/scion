/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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

struct CounterDirectives: Equatable {
  var resetValue: Int32? = nil
  var incrementValue: Int32? = nil
  var setValue: Int32? = nil
}

struct CounterDirectiveMap {
  init(p: UnsafeRawPointer) { self.map = Map(p: p) }

  // Mirrors the HashMap<AtomString, CounterDirectives> member, read through the bridge.
  struct Map {
    func get(_ name: StringWrapper) -> CounterDirectives {
      let raw = wk_interop.CounterDirectiveMap_get(p, name.p)
      return CounterDirectives(
        resetValue: raw.hasResetValue ? raw.resetValue : nil,
        incrementValue: raw.hasIncrementValue ? raw.incrementValue : nil,
        setValue: raw.hasSetValue ? raw.setValue : nil)
    }

    let p: UnsafeRawPointer
  }

  let map: Map
}
