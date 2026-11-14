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

struct CharacterIterator {
  func atEnd() -> Bool {
    return underlyingIterator.atEnd()
  }

  func text() -> StringWrapperView {
    return underlyingIterator.text().substring(start: runOffset)
  }

  func atBreak() -> Bool {
    return m_atBreak
  }

  func characterOffset() -> UInt32 {
    return offset
  }

  init(range: SimpleRange, behaviors: TextIteratorBehavior = []) {
    self.underlyingIterator = EditingTextIterator(range: range, behaviors: behaviors)
    while !atEnd() && !(underlyingIterator.text().length() != 0) {
      underlyingIterator.advance()
    }
  }

  mutating func range() -> SimpleRange {
    var range = underlyingIterator.range()
    if !underlyingIterator.atEnd() {
      if underlyingIterator.text().length() <= 1 {
        assert(runOffset == 0)
      } else {
        let offset: UInt32 = range.startOffset() + runOffset
        range = SimpleRange(
          start: BoundaryPoint(container: range.start.container, offset: offset),
          end: BoundaryPoint(container: range.start.container, offset: offset + 1))
      }
    }
    return range
  }

  mutating func advance(count: Int32) {
    var count = count
    if count <= 0 {
      assert(count == 0)
      return
    }
    m_atBreak = false
    // easy if there is enough left in the current m_underlyingIterator run
    let remaining: Int32 = Int32(underlyingIterator.text().length() - runOffset)
    if count < remaining {
      runOffset += UInt32(count)
      offset += UInt32(count)
      return
    }
    // exhaust the current m_underlyingIterator run
    count -= remaining
    offset += UInt32(remaining)
    // move to a subsequent m_underlyingIterator run
    underlyingIterator.advance()
    while !atEnd() {
      let runLength: Int32 = Int32(underlyingIterator.text().length())
      if !(runLength != 0) {
        m_atBreak = true
      } else {
        // see whether this is m_underlyingIterator to use
        if count < runLength {
          runOffset = UInt32(count)
          offset += UInt32(count)
          return
        }
        // exhaust this m_underlyingIterator run
        count -= runLength
        offset += UInt32(runLength)
      }
      underlyingIterator.advance()
    }
    // ran to the end of the m_underlyingIterator... no more runs left
    m_atBreak = true
    runOffset = 0
  }

  private var underlyingIterator: EditingTextIterator
  private var offset: UInt32 = 0
  private var runOffset: UInt32 = 0
  private var m_atBreak: Bool = true
}
