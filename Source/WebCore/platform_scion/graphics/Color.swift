/*
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
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

// TODO(asuhan): Support more color types, not just sRGB.
struct ColorWrapper: Equatable {
  struct Flags: OptionSet {
    let rawValue: UInt8

    static let Semantic = Flags(rawValue: 1 << 0)
    static let UseColorFunctionSerialization = Flags(rawValue: 1 << 1)
  }

  init() {
    srgba = SRGBA(red: 0, green: 0, blue: 0, alpha: 0)
    valid = false
  }

  init(_ color: SRGBA<UInt8>, _ flags: Flags = []) {
    assert(flags.isEmpty)
    srgba = color
    valid = true
  }

  func isValid() -> Bool { return valid }

  func isOpaque() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isVisible() -> Bool { return srgba.alpha > 0 }

  func alphaAsFloat() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func luminance() -> Float64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lightened() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func darkened() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invertedColorWithAlpha(alpha: Float32) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colorWithAlphaMultipliedBy(amount: Float32) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colorWithAlpha(_ alpha: Float32) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colorWithAlphaByte(_ overrideAlpha: UInt8) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func opaqueColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static var transparentBlack: ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static var black: ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static var white: ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static var lightGray: ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let srgba: SRGBA<UInt8>
  private let valid: Bool
}

func equalIgnoringSemanticColor(a: ColorWrapper, b: ColorWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
