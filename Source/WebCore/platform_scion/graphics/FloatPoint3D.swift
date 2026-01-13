/*
    Copyright (C) 2004, 2005, 2006 Nikolas Zimmermann <wildfox@kde.org>
                  2004, 2005 Rob Buis <buis@kde.org>
                  2005 Eric Seidel <eric@webkit.org>
                  2010 Zoltan Herczeg <zherczeg@webkit.org>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    aint with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

struct FloatPoint3D {
  init() { self.init(x: 0, y: 0, z: 0) }

  init(x: Float32, y: Float32, z: Float32) {
    self.x = x
    self.y = y
    self.z = z
  }

  init(_ p: FloatPoint) { self.init(x: p.x, y: p.y, z: 0) }

  func xy() -> FloatPoint { return FloatPoint(x: x, y: y) }

  mutating func setXY(_ p: FloatPoint) {
    x = p.x
    y = p.y
  }

  var x: Float32
  var y: Float32
  let z: Float32
}
