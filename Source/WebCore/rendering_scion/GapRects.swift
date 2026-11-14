/*
    Copyright (C) 2005, 2006 Apple Inc. All rights reserved.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.


    Some useful definitions needed for laying out elements
*/

import wk_interop

struct GapRects {
  func left() -> LayoutRectWrapper {
    return m_left
  }

  func center() -> LayoutRectWrapper {
    return m_center
  }

  func right() -> LayoutRectWrapper {
    return m_right
  }

  mutating func uniteLeft(r: LayoutRectWrapper) {
    m_left.unite(other: r)
  }

  mutating func uniteCenter(r: LayoutRectWrapper) {
    m_center.unite(other: r)
  }

  mutating func uniteRight(r: LayoutRectWrapper) {
    m_right.unite(other: r)
  }

  mutating func unite(o: GapRects) {
    uniteLeft(r: o.left())
    uniteCenter(r: o.center())
    uniteRight(r: o.right())
  }

  func toLayoutRect() -> LayoutRectWrapper {
    var result = m_left
    result.unite(other: m_center)
    result.unite(other: m_right)
    return result
  }

  private var m_left: LayoutRectWrapper = LayoutRectWrapper()
  private var m_center: LayoutRectWrapper = LayoutRectWrapper()
  private var m_right: LayoutRectWrapper = LayoutRectWrapper()
}
