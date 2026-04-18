/*
 * Copyright (C) 2014-2019 Apple Inc. All rights reserved.
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

import wk_interop

class StringWrapperView {
  init(s: StringWrapper) { self.p = string_view_from_string(p: s.p) }

  init(p: UnsafeRawPointer) { self.p = p }

  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  deinit { wk_interop.StringView_destroy(p) }

  func length() -> UInt32 { return wk_interop.StringView_length(p) }

  func isEmpty() -> Bool { return wk_interop.StringView_isEmpty(p) }

  func characterAt(index: UInt32) -> UChar {
    if is8Bit() {
      return span8()[UInt64(index)]
    }
    return span16()[UInt64(index)]
  }

  subscript(index: UInt32) -> UChar {
    return characterAt(index: index)
  }

  func is8Bit() -> Bool {
    return wk_interop.StringView_is8Bit(p)
  }

  func span8() -> CharSpanWrapper<LChar> {
    return CharSpanWrapper<LChar>(p: wk_interop.StringView_span8(p))
  }

  func span16() -> CharSpanWrapper<UChar> {
    return CharSpanWrapper<UChar>(p: wk_interop.StringView_span16(p))
  }

  func substring(start: UInt32, length: UInt32 = UInt32.max) -> StringWrapperView {
    return string_view_substring(s: self, start: start, length: length)
  }

  func left(length: UInt32) -> StringWrapperView {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func right(length: UInt32) -> StringWrapperView {
    return substring(start: self.length() - length, length: length)
  }

  class UpconvertedCharactersWithSize {
    init(p: UnsafeRawPointer) {
      self.p = p
    }

    var uchars: ArraySlice<UChar> {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    var p: UnsafeRawPointer
  }

  func upconvertedCharacters() -> UpconvertedCharactersWithSize {
    return UpconvertedCharactersWithSize(p: wk_interop.StringView_upconvertedCharacters(p))
  }

  func containsOnly(isSpecialCharacter: (UChar) -> Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var p: UnsafeRawPointer
}

func makeStringByReplacingAll(_ string: StringWrapper, target: UChar, replacement: UChar)
  -> StringWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func makeStringByReplacingAll(_ string: StringWrapper, target: UChar, literal: ASCIILiteral)
  -> StringWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
