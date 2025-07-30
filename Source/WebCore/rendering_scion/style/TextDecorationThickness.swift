/*
 * Copyright (C) 2018-2020 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

struct TextDecorationThickness {
  static func createWithAuto() -> TextDecorationThickness {
    return TextDecorationThickness(type: .Auto)
  }

  func isAuto() -> Bool {
    return type == .Auto
  }

  func isFromFont() -> Bool {
    return type == .FromFont
  }

  func isLength() -> Bool {
    return type == .Length
  }

  func resolve(fontSize: Float32, metrics: FontMetricsWrapper) -> Float32 {
    if isAuto() {
      return fontSize / Float32(TextDecorationThickness.textDecorationBaseFontSize)
    }
    if isFromFont() {
      return metrics.underlineThickness() ?? 0
    }

    assert(isLength())
    if length.isPercent() {
      return fontSize * (length.percent() / 100)
    }
    if length.isCalculated() {
      return length.nonNanCalculatedValue(maxValue: fontSize)
    }
    return length.value()
  }

  private enum `Type` {
    case Auto
    case FromFont
    case Length
  }

  private init(type: `Type`) { self.type = type }

  private let type: `Type`
  private let length = LengthWrapper()
  private static let textDecorationBaseFontSize = 16
}
