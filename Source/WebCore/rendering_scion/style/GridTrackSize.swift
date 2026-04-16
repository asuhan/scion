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
    m_type = trackSizeType
    minTrackBreadth =
      trackSizeType == .FitContentTrackSizing
      ? GridLength(length: LengthWrapper(type: .Auto)) : length
    maxTrackBreadth =
      trackSizeType == .FitContentTrackSizing
      ? GridLength(length: LengthWrapper(type: .Auto)) : length
    m_fitContentTrackBreadth =
      trackSizeType == .FitContentTrackSizing
      ? length : GridLength(length: LengthWrapper(type: .Fixed))
    assert(trackSizeType == .LengthTrackSizing || trackSizeType == .FitContentTrackSizing)
    assert(trackSizeType != .FitContentTrackSizing || length.isLength())
    cacheMinMaxTrackBreadthTypes()
  }

  init(minTrackBreadth: GridLength, maxTrackBreadth: GridLength) {
    m_type = .MinMaxTrackSizing
    self.minTrackBreadth = minTrackBreadth
    self.maxTrackBreadth = maxTrackBreadth
    m_fitContentTrackBreadth = GridLength(length: LengthWrapper(type: .Fixed))
    cacheMinMaxTrackBreadthTypes()
  }

  func fitContentTrackBreadth() -> GridLength {
    assert(m_type == .FitContentTrackSizing)
    return m_fitContentTrackBreadth
  }

  func isContentSized() -> Bool {
    return minTrackBreadth.isContentSized() || maxTrackBreadth.isContentSized()
  }

  func isFitContent() -> Bool { return m_type == .FitContentTrackSizing }

  private mutating func cacheMinMaxTrackBreadthTypes() {
    m_minTrackBreadthIsAuto = minTrackBreadth.isLength() && minTrackBreadth.length().isAuto()
    m_minTrackBreadthIsMinContent =
      minTrackBreadth.isLength() && minTrackBreadth.length().isMinContent()
    m_minTrackBreadthIsMaxContent =
      minTrackBreadth.isLength() && minTrackBreadth.length().isMaxContent()
    m_maxTrackBreadthIsMaxContent =
      maxTrackBreadth.isLength() && maxTrackBreadth.length().isMaxContent()
    m_maxTrackBreadthIsMinContent =
      maxTrackBreadth.isLength() && maxTrackBreadth.length().isMinContent()
    m_maxTrackBreadthIsAuto = maxTrackBreadth.isLength() && maxTrackBreadth.length().isAuto()
    m_maxTrackBreadthIsFixed = maxTrackBreadth.isLength() && maxTrackBreadth.length().isSpecified()

    // These values depend on the above ones so keep them here.
    m_minTrackBreadthIsIntrinsic =
      m_minTrackBreadthIsMaxContent || m_minTrackBreadthIsMinContent
      || m_minTrackBreadthIsAuto || isFitContent()
    m_maxTrackBreadthIsIntrinsic =
      m_maxTrackBreadthIsMaxContent || m_maxTrackBreadthIsMinContent
      || m_maxTrackBreadthIsAuto || isFitContent()
  }

  func hasIntrinsicMinTrackBreadth() -> Bool { return m_minTrackBreadthIsIntrinsic }

  func hasIntrinsicMaxTrackBreadth() -> Bool { return m_maxTrackBreadthIsIntrinsic }

  func hasMinOrMaxContentMinTrackBreadth() -> Bool {
    return m_minTrackBreadthIsMaxContent || m_minTrackBreadthIsMinContent
  }

  func hasAutoMinTrackBreadth() -> Bool { return m_minTrackBreadthIsAuto }

  func hasAutoMaxTrackBreadth() -> Bool { return m_maxTrackBreadthIsAuto }

  func hasMaxContentOrAutoMaxTrackBreadth() -> Bool {
    return m_maxTrackBreadthIsMaxContent || m_maxTrackBreadthIsAuto
  }

  func hasMinContentMaxTrackBreadth() -> Bool { return m_maxTrackBreadthIsMinContent }

  func hasMaxContentMinTrackBreadth() -> Bool { return m_minTrackBreadthIsMaxContent }

  func hasMinContentMinTrackBreadth() -> Bool { return m_minTrackBreadthIsMinContent }

  func hasMaxContentMinTrackBreadthAndMaxContentMaxTrackBreadth() -> Bool {
    return m_minTrackBreadthIsMaxContent && m_maxTrackBreadthIsMaxContent
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

  private let m_type: GridTrackSizeType
  let minTrackBreadth: GridLength
  let maxTrackBreadth: GridLength
  private let m_fitContentTrackBreadth: GridLength

  private var m_minTrackBreadthIsAuto = false
  private var m_maxTrackBreadthIsAuto = false
  private var m_minTrackBreadthIsMaxContent = false
  private var m_minTrackBreadthIsMinContent = false
  private var m_maxTrackBreadthIsMaxContent = false
  private var m_maxTrackBreadthIsMinContent = false
  private var m_minTrackBreadthIsIntrinsic = false
  private var m_maxTrackBreadthIsIntrinsic = false
  private var m_maxTrackBreadthIsFixed = false
}
