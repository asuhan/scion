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
  init(s: StringWrapper) {
    if s.p != nil {
      self.p = string_view_from_string(p: s.p!)
    } else {
      self.p = nil
    }
  }

  init(p: UnsafeRawPointer?) {
    self.p = p
  }

  func length() -> UInt32 {
    if self.p != nil {
      return wk_interop.StringView_length(self.p)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func is8Bit() -> Bool {
    if self.p != nil {
      return wk_interop.StringView_is8Bit(self.p)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func span8() -> CharSpanWrapper<LChar> {
    if self.p != nil {
      return CharSpanWrapper<LChar>(p: wk_interop.StringView_span8(self.p))
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func span16() -> CharSpanWrapper<UChar> {
    if self.p != nil {
      return CharSpanWrapper<UChar>(p: wk_interop.StringView_span16(self.p))
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func substring(start: UInt32, length: UInt32) -> StringWrapperView {
    if self.p != nil {
      return string_view_substring(s: self, start: start, length: length)
    }
    return StringWrapperView(s: StringWrapper())
  }

  func right(length: UInt32) -> StringWrapperView {
    return substring(start: self.length() - length, length: length)
  }

  class UpconvertedCharactersWithSize {
    init(p: UnsafeRawPointer) {
      self.p = p
    }

    var p: UnsafeRawPointer
  }

  func upconvertedCharacters() -> UpconvertedCharactersWithSize {
    return UpconvertedCharactersWithSize(p: wk_interop.StringView_upconvertedCharacters(p))
  }

  var p: UnsafeRawPointer?
}
