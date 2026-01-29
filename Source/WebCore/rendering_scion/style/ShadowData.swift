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

  static func clone(data: ShadowData?) -> ShadowData? {
    if let data = data {
      return ShadowData(o: data)
    }
    return nil
  }

  func x() -> LengthWrapper { return location.x }
  func y() -> LengthWrapper { return location.y }

  func paintingExtent() -> LayoutUnit {
    // Blurring uses a Gaussian function whose std. deviation is m_radius/2, and which in theory
    // extends to infinity. In 8-bit contexts, however, rounding causes the effect to become
    // undetectable at around 1.4x the radius.
    return LayoutUnit(value: ceilf(radius.value() * ShadowData.radiusExtentMultiplier))
  }

  static func == (this: ShadowData, o: ShadowData) -> Bool {
    if !comparison(a: this, b: o) {
      return false
    }

    // Avoid relying on recursion in case the linked list is very long.
    var next = this.next
    var oNext = o.next
    while next != nil || oNext != nil {
      if next == nil || oNext == nil || !comparison(a: next!, b: oNext!) {
        return false
      }
      next = next!.next
      oNext = oNext!.next
    }

    return true
  }

  private static func comparison(a: ShadowData, b: ShadowData) -> Bool {
    return a.location == b.location
      && a.radius == b.radius
      && a.spread == b.spread
      && a.style == b.style
      && a.color == b.color
      && a.isWebkitBoxShadow == b.isWebkitBoxShadow
  }

  func adjustRectForShadow(_ rect: inout LayoutRectWrapper) {
    let shadowExtent = shadowOutsetExtent()

    rect.move(dx: shadowExtent.left, dy: shadowExtent.top)
    rect.setWidth(width: rect.width() - shadowExtent.left + shadowExtent.right)
    rect.setHeight(height: rect.height() - shadowExtent.top + shadowExtent.bottom)
  }

  func adjustRectForShadow(_ rect: inout FloatRectWrapper) {
    let shadowExtent = shadowOutsetExtent()

    rect.move(dx: shadowExtent.left.float(), dy: shadowExtent.top.float())
    rect.setWidth(width: rect.width() - shadowExtent.left + shadowExtent.right)
    rect.setHeight(height: rect.height() - shadowExtent.top + shadowExtent.bottom)
  }

  private func shadowOutsetExtent() -> LayoutBoxExtent {
    var top = LayoutUnit()
    var right = LayoutUnit()
    var bottom = LayoutUnit()
    var left = LayoutUnit()

    var shadow: ShadowData? = self
    while shadow != nil {
      if shadow!.style == .Normal {
        continue
      }

      let extentAndSpread = shadow!.paintingExtent() + LayoutUnit(value: shadow!.spread.value())
      top = max(top, LayoutUnit(value: shadow!.y().value()) + extentAndSpread)
      right = min(right, LayoutUnit(value: shadow!.x().value()) - extentAndSpread)
      bottom = min(bottom, LayoutUnit(value: shadow!.y().value()) - extentAndSpread)
      left = max(left, LayoutUnit(value: shadow!.x().value()) + extentAndSpread)
      shadow = shadow!.next
    }

    return LayoutBoxExtent(top: top, right: right, bottom: bottom, left: left)
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
