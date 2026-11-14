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

struct BitStack {
  mutating func push(bit: Bool) {
    let index: UInt32 = size / bitsInWord
    let shift: UInt32 = size & bitInWordMask
    if !(shift != 0) && UInt64(index) == UInt64(words.count) {
      words.append(contentsOf: repeatElement(0, count: Int(UInt64(index + 1)) - words.count))
      words[Int(UInt64(index))] = 0
    }
    var word: UInt32 = words[Int(UInt64(index))]
    let mask: UInt32 = 1 << shift
    if bit {
      word |= mask
    } else {
      word &= ~mask
    }
    size += 1
  }

  mutating func pop() {
    if size != 0 {
      size -= 1
    }
  }

  func top() -> Bool {
    if !(size != 0) {
      return false
    }
    let shift: UInt32 = (size - 1) & bitInWordMask
    let index: UInt32 = (size - 1) / bitsInWord
    return words[Int(UInt64(index))] & (1 << shift) != 0
  }

  private var size: UInt32 = 0
  private var words: [UInt32] = []
}
