/*
    Copyright (C) 1999 Lars Knoll (knoll@kde.org)
    Copyright (C) 2006-2024 Apple Inc. All rights reserved.
    Copyright (C) 2011 Rik Cabanier (cabanier@adobe.com)
    Copyright (C) 2011 Adobe Systems Incorporated. All rights reserved.

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

import wk_interop

enum LengthType: UInt8 {
  case Auto
  case Normal
  case Relative
  case Percent
  case Fixed
  case Intrinsic
  case MinIntrinsic
  case MinContent
  case MaxContent
  case FillAvailable
  case FitContent
  case Calculated
  case Content
  case Undefined
}

class LengthWrapper: Equatable {
  init(type: LengthType = .Auto) {
    self.p = wk_interop.Length_empty_new(type.rawValue)
    self.owner = true
  }

  init(value: Int32, type: LengthType, hasQuirk: Bool = false) {
    self.p = wk_interop.Length_new_int32(value, type.rawValue, hasQuirk)
    self.owner = true
  }

  init(value: LayoutUnit, type: LengthType, hasQuirk: Bool = false) {
    self.p = wk_interop.Length_new(value.rawValue(), type.rawValue, hasQuirk)
    self.owner = true
  }

  init(value: Float32, type: LengthType, hasQuirk: Bool = false) {
    self.p = wk_interop.Length_new_float32(value, type.rawValue, hasQuirk)
    self.owner = true
  }

  init(value: Float64, type: LengthType, hasQuirk: Bool = false) {
    self.p = wk_interop.Length_new_float64(value, type.rawValue, hasQuirk)
    self.owner = true
  }

  init(p: UnsafeRawPointer) {
    self.p = p
    self.owner = false
  }

  deinit { if self.owner { wk_interop.Length_destroy(p) } }

  func setValue(type: LengthType, value: Int32) {
    wk_interop.Length_setValue_i32(p, type.rawValue, value)
  }

  func setValue(type: LengthType, value: Float32) {
    wk_interop.Length_setValue_f32(p, type.rawValue, value)
  }

  func setValue(type: LengthType, value: LayoutUnit) {
    wk_interop.Length_setValue(p, type.rawValue, value.rawValue())
  }

  @discardableResult
  static func *= (this: LengthWrapper, value: Float32) -> LengthWrapper {
    wk_interop.Length_imul(this.p, value)
    return this
  }

  func value() -> Float32 {
    return wk_interop.Length_value(p)
  }

  func intValue() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func percent() -> Float32 {
    return wk_interop.Length_percent(p)
  }

  func type() -> LengthType {
    return LengthType(rawValue: wk_interop.Length_type(p))!
  }

  func isAuto() -> Bool {
    return type() == .Auto
  }

  func isCalculated() -> Bool {
    return type() == .Calculated
  }

  func isFixed() -> Bool {
    return wk_interop.Length_isFixed(p)
  }

  func isMaxContent() -> Bool {
    return type() == .MaxContent
  }

  func isMinContent() -> Bool {
    return type() == .MinContent
  }

  func isNormal() -> Bool { return type() == .Normal }

  func isPercent() -> Bool {
    return type() == .Percent
  }

  func isRelative() -> Bool {
    return type() == .Relative
  }

  func isUndefined() -> Bool {
    return type() == .Undefined
  }

  func isFillAvailable() -> Bool {
    return type() == .FillAvailable
  }

  func isFitContent() -> Bool {
    return type() == .FitContent
  }

  func isMinIntrinsic() -> Bool {
    return type() == .MinIntrinsic
  }

  func isContent() -> Bool {
    return type() == .Content
  }

  func hasQuirk() -> Bool { return wk_interop.Length_hasQuirk(p) }

  // FIXME calc: https://bugs.webkit.org/show_bug.cgi?id=80357. A calculated Length
  // always contains a percentage, and without a maxValue passed to these functions
  // it's impossible to determine the sign or zero-ness. The following three functions
  // act as if all calculated values are positive.
  func isZero() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPositive() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isNegative() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPercentOrCalculated() -> Bool {
    return isPercent() || isCalculated()
  }

  func isIntrinsic() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isIntrinsicOrAuto() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSpecified() -> Bool {
    return isFixed() || isPercentOrCalculated()
  }

  func isSpecifiedOrIntrinsic() -> Bool {
    return isSpecified() || isIntrinsic()
  }

  func nonNanCalculatedValue(maxValue: Float32) -> Float32 {
    return wk_interop.Length_nonNanCalculatedValue(p, maxValue)
  }

  func isLegacyIntrinsic() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (a: LengthWrapper, b: LengthWrapper) -> Bool {
    return wk_interop.Length_eq(a.p, b.p)
  }

  var p: UnsafeRawPointer
  private let owner: Bool
}
