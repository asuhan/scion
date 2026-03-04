/*
    Copyright (C) 1999 Lars Knoll (knoll@kde.org)
    Copyright (C) 2006, 2008, 2015, 2016 Apple Inc. All rights reserved.
    Copyright (c) 2012, Google Inc. All rights reserved.

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
*/

class LengthBox: Equatable {
  init(top: Int32, right: Int32, bottom: Int32, left: Int32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(top: LengthWrapper, right: LengthWrapper, bottom: LengthWrapper, left: LengthWrapper) {
    base = RectEdges(top: top, right: right, bottom: bottom, left: left)
  }

  func top() -> LengthWrapper { return base.top }
  func right() -> LengthWrapper { return base.right }
  func bottom() -> LengthWrapper { return base.bottom }
  func left() -> LengthWrapper { return base.left }

  static func == (lhs: LengthBox, rhs: LengthBox) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let base: RectEdges<LengthWrapper>
}

typealias IntBoxExtent = RectEdges<Int32>

typealias IntOutsets = IntBoxExtent
typealias LayoutOptionalOutsets = RectEdges<LayoutUnit?>

func toLayoutBoxExtent(extent: IntBoxExtent) -> LayoutBoxExtent {
  return LayoutBoxExtent(
    top: LayoutUnit(value: extent.top), right: LayoutUnit(value: extent.right),
    bottom: LayoutUnit(value: extent.bottom), left: LayoutUnit(value: extent.left))
}
