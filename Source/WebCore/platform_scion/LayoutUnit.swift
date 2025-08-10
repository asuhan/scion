/*
 * Copyright (c) 2012-2017, Google Inc. All rights reserved.
 * Copyright (c) 2012-2024, Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

private let kLayoutUnitFractionalBits = 6
private let kFixedPointDenominator: Int32 = 1 << kLayoutUnitFractionalBits
internal let intMaxForLayoutUnit = Int32.max / kFixedPointDenominator
internal let intMinForLayoutUnit = Int32.min / kFixedPointDenominator

struct LayoutUnit: Comparable {
  static func fromRawValue(value: Int32) -> LayoutUnit {
    var v = LayoutUnit()
    v.value = value
    return v
  }

  func toInt() -> Int32 {
    return value / kFixedPointDenominator
  }

  func toFloat() -> Float32 { return Float32(value) / Float32(kFixedPointDenominator) }

  func toDouble() -> Float64 { return Float64(value) / Float64(kFixedPointDenominator) }

  func bool() -> Bool { return value != 0 }

  func float() -> Float32 { return toFloat() }

  func double() -> Float64 { return toDouble() }

  func mightBeSaturated() -> Bool {
    return rawValue() == Int32.max || rawValue() == Int32.min
  }

  prefix static func - (a: LayoutUnit) -> LayoutUnit {
    // -min() is saturated to max().
    if a == LayoutUnit.min() {
      return LayoutUnit.max()
    }

    var returnVal = LayoutUnit()
    returnVal.value = -a.rawValue()
    return returnVal
  }

  static func - (lhs: LayoutUnit, rhs: LayoutUnit) -> LayoutUnit {
    var returnVal = LayoutUnit()
    // TODO(asuhan): implement this correctly
    returnVal.value = lhs.rawValue() - rhs.rawValue()
    return returnVal
  }

  static func - (a: Float32, b: LayoutUnit) -> Float32 {
    return a - b.toFloat()
  }

  static func - (a: LayoutUnit, b: Int) -> LayoutUnit {
    return a - LayoutUnit(value: b)
  }

  static func - (a: LayoutUnit, b: Float32) -> Float32 {
    return a.toFloat() - b
  }

  static func / (a: LayoutUnit, b: LayoutUnit) -> LayoutUnit {
    let rawVal = Int64(kFixedPointDenominator) * Int64(a.rawValue()) / Int64(b.rawValue())
    return fromRawValue(value: clampTo<Int32>(value: rawVal))
  }

  static func / (a: LayoutUnit, b: Int) -> LayoutUnit {
    return a / LayoutUnit(value: b)
  }

  static func / (a: LayoutUnit, b: Float32) -> Float32 {
    return a.toFloat() / b
  }

  static func / (a: LayoutUnit, b: UInt64) -> LayoutUnit {
    return a / LayoutUnit(value: b)
  }

  static func / (a: Float32, b: LayoutUnit) -> Float32 {
    return a / b.toFloat()
  }

  static func == (a: LayoutUnit, b: LayoutUnit) -> Bool {
    return a.rawValue() == b.rawValue()
  }

  static func fromFloatCeil(value: Float32) -> LayoutUnit {
    var v = LayoutUnit()
    v.value = clampToInteger(value: ceilf(value * Float32(kFixedPointDenominator)))
    return v
  }

  static func fromFloatFloor(value: Float32) -> LayoutUnit {
    var v = LayoutUnit()
    v.value = clampToInteger(value: floorf(value * Float32(kFixedPointDenominator)))
    return v
  }

  static func < (lhs: LayoutUnit, rhs: LayoutUnit) -> Bool {
    return lhs.rawValue() < rhs.rawValue()
  }

  static func < (lhs: LayoutUnit, rhs: Float32) -> Bool {
    return lhs.toFloat() < rhs
  }

  static func < (lhs: Float32, rhs: LayoutUnit) -> Bool {
    return lhs < rhs.toFloat()
  }

  static func <= (lhs: LayoutUnit, rhs: Float32) -> Bool {
    return lhs.toFloat() <= rhs
  }

  static func >= (lhs: LayoutUnit, rhs: Float32) -> Bool {
    return lhs.toFloat() >= rhs
  }

  static func > (lhs: LayoutUnit, rhs: Int) -> Bool {
    return lhs > LayoutUnit(value: rhs)
  }

  static func > (lhs: Float32, rhs: LayoutUnit) -> Bool {
    return lhs > rhs.toFloat()
  }

  func rawValue() -> Int32 { return value }

  func ceil() -> Int32 {
    if value >= Int32.max - kFixedPointDenominator + 1 {
      return intMaxForLayoutUnit
    }
    if value >= 0 {
      return (value + kFixedPointDenominator - 1) / kFixedPointDenominator
    }
    return toInt()
  }

  func round() -> Int32 {
    return toInt()
      + ((fraction().rawValue() + (kFixedPointDenominator / 2)) >> kLayoutUnitFractionalBits)
  }

  func floor() -> Int32 {
    if value <= Int32.min + kFixedPointDenominator - 1 {
      return intMinForLayoutUnit
    }
    return value >> kLayoutUnitFractionalBits
  }

  func fraction() -> LayoutUnit {
    // Add the fraction to the size (as opposed to the full location) to avoid overflows.
    // Compute fraction using the mod operator to preserve the sign of the value as it may affect rounding.
    var fraction = LayoutUnit()
    fraction.value = rawValue() % kFixedPointDenominator
    return fraction
  }

  static func epsilon() -> Float32 {
    return 1 / Float32(kFixedPointDenominator)
  }

  static func max() -> LayoutUnit {
    var m = LayoutUnit()
    m.value = Int32.max
    return m
  }

  static func min() -> LayoutUnit {
    var m = LayoutUnit()
    m.value = Int32.min
    return m
  }

  init() {
    value = 0
  }

  init(value: Float32) {
    self.init(value: Float64(value))
  }

  init(value: Int) {
    // TODO(asuhan): implement this correctly
    self.value = Int32(value)
  }

  init(value: Int32) {
    // TODO(asuhan): implement this correctly
    self.value = value
  }

  init(value: UInt64) {
    self.value = clampTo<Int32>(value: value * UInt64(kFixedPointDenominator))
  }

  init(value: Float64) {
    self.value = clampToInteger(value: value * Float64(kFixedPointDenominator))
  }

  static func * (a: LayoutUnit, b: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func * (a: LayoutUnit, b: Float32) -> Float32 {
    return a.toFloat() * b
  }

  static func * (a: Float32, b: LayoutUnit) -> Float32 {
    return a * b.toFloat()
  }

  static func + (a: LayoutUnit, b: LayoutUnit) -> LayoutUnit {
    var returnVal = LayoutUnit()
    returnVal.value = WTF.saturatedSum(a: a.rawValue(), b: b.rawValue())
    return returnVal
  }

  static func + (a: LayoutUnit, b: Int) -> LayoutUnit {
    return a + LayoutUnit(value: b)
  }

  static func + (a: LayoutUnit, b: Float32) -> Float32 {
    return a.toFloat() + b
  }

  static func + (a: Int, b: LayoutUnit) -> LayoutUnit {
    return LayoutUnit(value: a) + b
  }

  static func + (a: Float32, b: LayoutUnit) -> Float32 {
    return a + b.toFloat()
  }

  @discardableResult
  static func += (a: inout LayoutUnit, b: LayoutUnit) -> LayoutUnit {
    a.value = WTF.saturatedSum(a: a.rawValue(), b: b.rawValue())
    return a
  }

  @discardableResult
  static func += (a: inout LayoutUnit, b: Float32) -> LayoutUnit {
    a = LayoutUnit(value: a + b)
    return a
  }

  @discardableResult
  static func += (a: inout Float32, b: LayoutUnit) -> Float32 {
    a = a + b
    return a
  }

  @discardableResult
  static func *= (a: inout LayoutUnit, b: Float32) -> LayoutUnit {
    a = LayoutUnit(value: a * b)
    return a
  }

  @discardableResult
  static func -= (a: inout LayoutUnit, b: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this correctly
    a.value = a.rawValue() - b.rawValue()
    return a
  }

  private var value: Int32
}

func floorToDevicePixel(value: LayoutUnit, pixelSnappingFactor: Float32) -> Float32 {
  return floorf((Float32(value.rawValue()) * pixelSnappingFactor) / Float32(kFixedPointDenominator))
    / pixelSnappingFactor
}

func ceilToDevicePixel(value: LayoutUnit, pixelSnappingFactor: Float32) -> Float32 {
  return ceilf((Float32(value.rawValue()) * pixelSnappingFactor) / Float32(kFixedPointDenominator))
    / pixelSnappingFactor
}

internal func roundToInt(value: Float32) -> Int {
  return roundToInt(value: LayoutUnit(value: value))
}

func roundToDevicePixel(
  value: LayoutUnit, pixelSnappingFactor: Float32, needsDirectionalRounding: Bool = false
) -> Float32 {
  var valueToRound = value.toDouble()
  if needsDirectionalRounding {
    valueToRound -= Float64(LayoutUnit.epsilon() / (2 * Float32(kFixedPointDenominator)))
  }

  let pixelSnappingFactor = Float64(pixelSnappingFactor)
  if valueToRound >= 0 {
    return Float32(round(valueToRound * pixelSnappingFactor) / pixelSnappingFactor)
  }

  // This adjusts directional rounding on negative halfway values. It produces the same direction for both negative and positive values.
  // Instead of rounding negative halfway cases away from zero, we translate them to positive values before rounding.
  // It helps snapping relative negative coordinates to the same position as if they were positive absolute coordinates.
  let translateOrigin = Float64(WTF.negate(v: value.rawValue()))
  return
    Float32(
      (round((valueToRound + translateOrigin) * pixelSnappingFactor) / pixelSnappingFactor)
        - translateOrigin)
}

func ceilToDevicePixel(value: Float32, pixelSnappingFactor: Float32) -> Float32 {
  return ceilToDevicePixel(
    value: LayoutUnit(value: value), pixelSnappingFactor: pixelSnappingFactor)
}

internal func roundToInt(value: LayoutUnit) -> Int {
  return Int(value.round())
}
