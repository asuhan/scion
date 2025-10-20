/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2019 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

typealias FloatingObjectSet = ListSet<FloatingObjectWrapper, ObjectIdentifier>

class FloatingObjectWrapper: Hashable {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  static func == (lhs: FloatingObjectWrapper, rhs: FloatingObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hash(into hasher: inout Hasher) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsPlaced(placed: Bool) {
    wk_interop.FloatingObject_setIsPlaced(p, placed)
  }

  func setMarginOffset(offset: LayoutSizeWrapper) {
    wk_interop.FloatingObject_setMarginOffset(
      p, offset.width().rawValue(), offset.height().rawValue())
  }

  func setFrameRect(frameRect: LayoutRectWrapper) {
    wk_interop.FloatingObject_setFrameRect(
      p, frameRect.x().rawValue(), frameRect.y().rawValue(),
      frameRect.width().rawValue(),
      frameRect.height().rawValue())
  }

  var renderer: RenderBoxWrapper? = nil
  var frameRect = LayoutRectWrapper()
  private var p: UnsafeMutableRawPointer
}
