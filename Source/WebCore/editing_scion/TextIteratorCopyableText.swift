/*
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2015-2018 Google Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov.
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
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

struct TextIteratorCopyableText {
  func text() -> StringWrapperView {
    return singleCharacter != 0
      ? StringWrapperView(characters: WTF.span(character: singleCharacter))
      : StringWrapperView(s: string).substring(start: offset, length: length)
  }

  mutating func reset() {
    singleCharacter = 0
    string = StringWrapper()
    offset = 0
    length = 0
  }

  mutating func set(string: StringWrapper) {
    singleCharacter = 0
    self.string = string
    offset = 0
    length = self.string.length()
  }

  mutating func set(string: StringWrapper, offset: UInt32, length: UInt32) {
    assert(offset < string.length())
    assert(length != 0)
    assert(length <= string.length() - offset)
    singleCharacter = 0
    self.string = string
    self.offset = offset
    self.length = length
  }

  mutating func set(singleCharacter: UInt16) {
    self.singleCharacter = singleCharacter
    string = StringWrapper()
    offset = 0
    length = 0
  }

  func appendToStringBuilder(builder: StringBuilderWrapper) {
    fatalError("Not implemented")
  }

  private var singleCharacter: UInt16 = 0
  private var string: StringWrapper = StringWrapper()
  private var offset: UInt32 = 0
  private var length: UInt32 = 0
}
