/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008, 2022 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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

struct BorderValue {
  init() {}

  // Snapshot of a C++ BorderValue. The color is not mirrored yet, only whether it is transparent.
  init(raw: BorderValueRaw) {
    width = raw.width
    style = BorderStyle(rawValue: raw.style)!
    m_isTransparent = raw.isTransparent
  }

  func nonZero() -> Bool {
    return width != 0 && style != .None
  }

  func isTransparent() -> Bool { return m_isTransparent }

  private(set) var width: Float32 = 3
  private(set) var style: BorderStyle = .None
  private var m_isTransparent = false
}
