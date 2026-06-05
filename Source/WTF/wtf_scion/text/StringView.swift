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

extension WTF {

  static func containsOnly<CharacterType: BinaryInteger>(
    _ isSpecialCharacter: (UChar) -> Bool, _ characters: CharSpanWrapper<CharacterType>
  ) -> Bool {
    let data = characters.data()
    for character in data {
      if !isSpecialCharacter(UChar(character)) {
        return false
      }
    }
    return true
  }

}

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

  func codePoints() -> CodePoints { return CodePoints(self) }

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

    deinit { wk_interop.UpconvertedCharactersWithSize_destroy(p) }

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
    if is8Bit() {
      return WTF.containsOnly(isSpecialCharacter, span8())
    }
    return WTF.containsOnly(isSpecialCharacter, span16())
  }

  class CodePoints: Sequence {
    init(_ stringView: StringWrapperView) { m_stringView = stringView }

    func makeIterator() -> Iterator { return Iterator(m_stringView) }

    class Iterator: IteratorProtocol {
      init(_ stringView: StringWrapperView) {
        m_is8Bit = stringView.is8Bit()
        m_stringView = stringView
        if m_is8Bit {
          let begin = stringView.span8().data()
          m_current = UnsafeRawPointer(begin.baseAddress!)
          m_end = UnsafeRawPointer(begin.baseAddress!.advanced(by: Int(stringView.length())))
        } else {
          let begin = stringView.span16().data()
          m_current = UnsafeRawPointer(begin.baseAddress!)
          m_end = UnsafeRawPointer(begin.baseAddress!.advanced(by: Int(stringView.length())))
        }
      }

      func next() -> UInt32? {
        if m_current == m_end {
          return nil
        }
        // TODO(asuhan): check that the underlying string of m_stringView is valid
        if m_is8Bit {
          let asLChar = m_current.assumingMemoryBound(to: LChar.self)
          let codePoint = UInt32(asLChar.pointee)
          m_current = UnsafeRawPointer(
            UnsafePointer<LChar>(m_current.assumingMemoryBound(to: LChar.self)).advanced(by: 1))
          return codePoint
        } else {
          let endAsUChar = m_end.assumingMemoryBound(to: UChar.self)
          let currentAsUChar = m_current.assumingMemoryBound(to: UChar.self)
          let length = UInt32(endAsUChar - currentAsUChar)
          let codePoint = U16_GET(s: currentAsUChar, start: 0, i: 0, length: length)
          var i: UInt32 = 0
          U16_FWD_1(s: currentAsUChar, i: &i, length: length)
          m_current = UnsafeRawPointer(
            UnsafePointer<LChar>(m_current.assumingMemoryBound(to: LChar.self)).advanced(by: Int(i))
          )
          return codePoint
        }
      }

      private var m_current: UnsafeRawPointer
      private let m_end: UnsafeRawPointer
      private let m_is8Bit: Bool
      private let m_stringView: StringWrapperView
    }

    private let m_stringView: StringWrapperView
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
