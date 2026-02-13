/*
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

let sqrtOfTwoDouble = Float64(2).squareRoot()
let sqrtOfTwoFloat = Float32(2).squareRoot()

private let radiansPerDegreeDouble = Float64.pi / 180

func deg2rad(_ d: Float64) -> Float64 { return d * radiansPerDegreeDouble }

private let degreesPerRadianFloat = 180 / Float32.pi

func rad2deg(_ r: Float32) -> Float32 { return r * degreesPerRadianFloat }

func clampTo(
  value: InlineLayoutUnit, min: InlineLayoutUnit = -Float32.greatestFiniteMagnitude,
  max: InlineLayoutUnit = Float32.greatestFiniteMagnitude
) -> InlineLayoutUnit {
  return Swift.max(min, Swift.min(value, max))
}

func clampTo<TargetType, SourceType>(value: SourceType) -> TargetType
where TargetType: BinaryInteger & FixedWidthInteger, SourceType: BinaryInteger & FixedWidthInteger {
  if value >= TargetType.max {
    return TargetType.max
  }
  if value <= TargetType.min {
    return TargetType.min
  }
  return TargetType(value)
}

func clampToInteger<SourceType>(value: SourceType) -> Int32 where SourceType: BinaryFloatingPoint {
  if value >= SourceType(Int32.max) {
    return Int32.max
  }
  // This will return min if value is NaN.
  if !(value > SourceType(Int32.min)) {
    return Int32.min
  }
  return Int32(value)
}

extension WTF {
  static func areEssentiallyEqual(u: Float32, v: Float32) -> Bool {
    return wk_interop.WTF_areEssentiallyEqual(u, v)
  }

  // For use in places where we could negate T.min and would like to avoid overflow.
  static func negate<T: FixedWidthInteger>(v: T) -> T {
    return 0 &- v
  }
}

let piOverTwoFloat: Float32 = 1.57079632679489661923
