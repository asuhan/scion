/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

enum GridPositionType {
  case AutoPosition
  case ExplicitPosition  // [ <integer> || <string> ]
  case SpanPosition  // span && [ <integer> || <string> ]
  case NamedGridAreaPosition  // <ident>
}

enum GridPositionSide {
  case ColumnStartSide
  case ColumnEndSide
  case RowStartSide
  case RowEndSide
}

private let kGridMaxPosition: Int32 = 1_000_000

struct GridPosition: Equatable {
  func isPositive() -> Bool { return integerPosition() > 0 }

  func isAuto() -> Bool { return type == .AutoPosition }

  func isSpan() -> Bool { return type == .SpanPosition }

  mutating func setAutoPosition() {
    type = .AutoPosition
    m_integerPosition = 0
  }

  // 'span' values cannot be negative, yet we reuse the <integer> position which can
  // be. This means that we have to convert the span position to an integer, losing
  // some precision here. It shouldn't be an issue in practice though.
  func setSpanPosition(position: Int32, namedGridLine: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func integerPosition() -> Int32 {
    assert(type == .ExplicitPosition)
    return m_integerPosition
  }

  func namedGridLine() -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func spanPosition() -> Int32 {
    assert(type == .SpanPosition)
    return m_integerPosition
  }

  func shouldBeResolvedAgainstOppositePosition() -> Bool { return isAuto() || isSpan() }

  // Note that grid line 1 is internally represented by the index 0, that's why the max value for
  // a position is kGridMaxTracks instead of kGridMaxTracks + 1.
  static func max() -> Int32 { return gMaxPositionForTesting ?? kGridMaxPosition }

  static func min() -> Int32 { return -max() }

  private static let gMaxPositionForTesting: Int32? = nil

  var type: GridPositionType = .AutoPosition
  private var m_integerPosition: Int32 = 0
}
