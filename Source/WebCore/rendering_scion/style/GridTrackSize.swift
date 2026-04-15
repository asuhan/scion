/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
 * Copyright (C) 2013, 2014 Igalia S.L.
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

enum GridTrackSizeType {
  case LengthTrackSizing
  case MinMaxTrackSizing
  case FitContentTrackSizing
}

// This class represents a <track-size> from the spec. Althought there are 3 different types of
// <track-size> there is always an equivalent minmax() representation that could represent any of
// them. The only special case is fit-content(argument) which is similar to minmax(auto,
// max-content) except that the track size is clamped at argument if it is greater than the auto
// minimum. At the GridTrackSize level we don't need to worry about clamping so we treat that case
// exactly as auto.
//
// We're using a separate attribute to store fit-content argument even though we could directly use
// m_maxTrackBreadth. The reason why we don't do it is because the maxTrackBreadh() call is a hot
// spot, so adding a conditional statement there (to distinguish between fit-content and any other
// case) was causing a severe performance drop.
struct GridTrackSize: Equatable {
  init(length: GridLength, trackSizeType: GridTrackSizeType = .LengthTrackSizing) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(minTrackBreadth: GridLength, maxTrackBreadth: GridLength) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fitContentTrackBreadth() -> GridLength {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isContentSized() -> Bool {
    return minTrackBreadth.isContentSized() || maxTrackBreadth.isContentSized()
  }

  func isFitContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIntrinsicMinTrackBreadth() -> Bool { return m_minTrackBreadthIsIntrinsic }

  func hasIntrinsicMaxTrackBreadth() -> Bool { return m_maxTrackBreadthIsIntrinsic }

  func hasMinOrMaxContentMinTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoMinTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoMaxTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasMaxContentOrAutoMaxTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasMinContentMaxTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasMaxContentMinTrackBreadth() -> Bool { return m_minTrackBreadthIsMaxContent }

  func hasMinContentMinTrackBreadth() -> Bool { return m_minTrackBreadthIsMinContent }

  func hasMaxContentMinTrackBreadthAndMaxContentMaxTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoOrMinContentMinTrackBreadthAndIntrinsicMaxTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFixedMaxTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let minTrackBreadth: GridLength
  let maxTrackBreadth: GridLength

  private let m_minTrackBreadthIsMaxContent = false
  private let m_minTrackBreadthIsMinContent = false
  private let m_minTrackBreadthIsIntrinsic = false
  private let m_maxTrackBreadthIsIntrinsic = false
}
