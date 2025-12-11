/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2013-2017 Igalia S.L.
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

// A span in a single direction (either rows or columns). Note that |startLine|
// and |endLine| are grid lines' indexes.
// Despite line numbers in the spec start in "1", the indexes here start in "0".
struct GridSpan: Sequence, IteratorProtocol {
  static func untranslatedDefiniteGridSpan(startLine: Int32, endLine: Int32) -> GridSpan {
    return GridSpan(startLine: startLine, endLine: endLine, type: .UntranslatedDefinite)
  }

  static func translatedDefiniteGridSpan(startLine: Int32, endLine: Int32) -> GridSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func indefiniteGridSpan() -> GridSpan {
    return GridSpan(startLine: 0, endLine: 1, type: .Indefinite)
  }

  func integerSpan() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func untranslatedStartLine() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func untranslatedEndLine() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func startLine() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endLine() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func next() -> UInt32? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTranslatedDefinite() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isIndefinite() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func translate(offset: UInt32) {
    assert(m_type == .UntranslatedDefinite)

    m_type = .TranslatedDefinite
    m_startLine += Int32(offset)
    m_endLine += Int32(offset)

    assert(m_startLine >= 0)
    assert(m_endLine > 0)
  }

  // Moves this span to be in the same coordinate space as |parent|.
  // If reverse is specified, then swaps the direction to handle RTL/LTR changes.
  mutating func translateTo(parent: GridSpan, reverse: Bool) {
    assert(m_type == .TranslatedDefinite)
    assert(parent.m_type == .TranslatedDefinite)
    if reverse {
      let start = m_startLine
      m_startLine = Int32(parent.endLine()) - m_endLine
      m_endLine = Int32(parent.endLine()) - start
    } else {
      m_startLine += parent.m_startLine
      m_endLine += parent.m_startLine
    }
  }

  mutating func clamp(max: Int32) {
    assert(m_type != .Indefinite)
    m_startLine = Swift.max(m_startLine, 0)
    m_endLine = Swift.max(Swift.min(m_endLine, max), 1)
    if m_startLine >= m_endLine {
      m_startLine = m_endLine - 1
    }
  }

  private enum GridSpanType {
    case UntranslatedDefinite
    case TranslatedDefinite
    case Indefinite
  }

  private init(startLine: Int32, endLine: Int32, type: GridSpanType) {
    #if ASSERT_ENABLED
      assert(startLine < endLine)
      if type == .TranslatedDefinite {
        assert(startLine >= 0)
        assert(endLine > 0)
      }
    #endif

    m_type = type
    m_startLine = Swift.max(GridPosition.min(), Swift.min(startLine, GridPosition.max() - 1))
    m_endLine = Swift.max(GridPosition.min() + 1, Swift.min(endLine, GridPosition.max()))
  }

  private var m_startLine: Int32
  private var m_endLine: Int32
  private var m_type: GridSpanType
}

// This represents a grid area that spans in both rows' and columns' direction.
struct GridArea {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(r: GridSpan, c: GridSpan) {
    columns = c
    rows = r
  }

  var columns: GridSpan
  var rows: GridSpan
}
