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

struct LengthWrapper: Equatable {
  init(type: LengthType = .Auto) {
    self.p = wk_interop.Length_empty_new(type.rawValue)
  }

  init(value: LayoutUnit, type: LengthType, hasQuirk: Bool = false) {
    self.p = wk_interop.Length_new(value.rawValue(), type.rawValue, hasQuirk)
  }

  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func value() -> Float32 {
    return wk_interop.Length_value(p)
  }

  func percent() -> Float32 {
    return wk_interop.Length_percent(p)
  }

  func type() -> LengthType {
    return LengthType(rawValue: wk_interop.Length_type(p))!
  }

  func isAuto() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isCalculated() -> Bool {
    return type() == .Calculated
  }

  func isFixed() -> Bool {
    return wk_interop.Length_isFixed(p)
  }

  func isMaxContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isMinContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isNormal() -> Bool { return type() == .Normal }

  func isPercent() -> Bool {
    return type() == .Percent
  }

  func isRelative() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isUndefined() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFitContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasQuirk() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME calc: https://bugs.webkit.org/show_bug.cgi?id=80357. A calculated Length
  // always contains a percentage, and without a maxValue passed to these functions
  // it's impossible to determine the sign or zero-ness. The following three functions
  // act as if all calculated values are positive.
  func isZero() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPercentOrCalculated() -> Bool {
    return isPercent() || isCalculated()
  }

  func isSpecified() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nonNanCalculatedValue(maxValue: Float32) -> Float32 {
    return wk_interop.Length_nonNanCalculatedValue(p, maxValue)
  }

  static func == (a: LengthWrapper, b: LengthWrapper) -> Bool {
    return wk_interop.Length_eq(a.p, b.p)
  }

  var p: UnsafeRawPointer
}
