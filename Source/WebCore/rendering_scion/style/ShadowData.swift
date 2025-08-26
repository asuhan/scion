/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

import Foundation

enum ShadowStyle {
  case Normal
  case Inset
}

// This class holds information about shadows for the text-shadow and box-shadow properties.

class ShadowData: Equatable {
  init() {
    self.location = LengthPoint()
    self.spread = LengthWrapper()
    self.radius = LengthWrapper()
    self.color = StyleColorWrapper()
    self.style = .Normal
    self.isWebkitBoxShadow = false
    self.next = nil
  }

  init(o: ShadowData) {
    self.location = LengthPoint(x: o.location.x, y: o.location.y)
    self.spread = o.spread
    self.radius = o.radius
    self.color = o.color
    self.style = o.style
    self.isWebkitBoxShadow = o.isWebkitBoxShadow
    self.next = o.next != nil ? ShadowData(o: o.next!) : nil
  }

  func x() -> LengthWrapper { return location.x }
  func y() -> LengthWrapper { return location.y }

  func paintingExtent() -> LayoutUnit {
    // Blurring uses a Gaussian function whose std. deviation is m_radius/2, and which in theory
    // extends to infinity. In 8-bit contexts, however, rounding causes the effect to become
    // undetectable at around 1.4x the radius.
    return LayoutUnit(value: ceilf(radius.value() * ShadowData.radiusExtentMultiplier))
  }

  static func == (this: ShadowData, other: ShadowData) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let location: LengthPoint
  let spread: LengthWrapper
  let radius: LengthWrapper  // This is the "blur radius", or twice the standard deviation of the Gaussian blur.
  let color: StyleColorWrapper
  let style: ShadowStyle
  let isWebkitBoxShadow: Bool
  let next: ShadowData?
  private static let radiusExtentMultiplier: Float32 = 1.4
}
