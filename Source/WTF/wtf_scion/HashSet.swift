/*
 * Copyright (C) 2025 Scion authors. All rights reserved.
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

class HashSet<KeyType: Equatable & Hashable> {
  struct AddResult {
    let isNewEntry: Bool
  }

  func size() -> UInt32 { return UInt32(m_impl.count) }

  func contains(value: KeyType) -> Bool { return m_impl.contains(value) }

  @discardableResult
  func add(_ value: KeyType) -> AddResult {
    let (inserted, _) = m_impl.insert(value)
    return AddResult(isNewEntry: inserted)
  }

  @discardableResult
  func remove(_ value: KeyType) -> Bool { return m_impl.remove(value) != nil }

  func clear() { m_impl.removeAll() }

  private var m_impl = Set<KeyType>()
}
