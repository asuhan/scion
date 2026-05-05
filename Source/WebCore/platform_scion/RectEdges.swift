/*
 * Copyright (C) 2017-2024 Apple Inc. All rights reserved.
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
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct BoxSideFlag: OptionSet {
  let rawValue: UInt8

  static let Top = BoxSideFlag(rawValue: 1)
  static let Right = BoxSideFlag(rawValue: 2)
  static let Bottom = BoxSideFlag(rawValue: 4)
  static let Left = BoxSideFlag(rawValue: 8)
}

typealias BoxSideSet = BoxSideFlag

struct RectEdges<T: Equatable>: Equatable {
  init(top: T, right: T, bottom: T, left: T) {
    self.top = top
    self.right = right
    self.bottom = bottom
    self.left = left
  }

  func at(side: BoxSide) -> T {
    switch side {
    case .Top:
      return top
    case .Right:
      return right
    case .Bottom:
      return bottom
    case .Left:
      return left
    }
  }

  mutating func setTop(_ top: T) { self.top = top }

  mutating func setRight(_ right: T) { self.right = right }

  mutating func setBottom(_ bottom: T) { self.bottom = bottom }

  mutating func setLeft(_ left: T) { self.left = left }

  func xFlippedCopy() -> RectEdges<T> {
    var copy = self
    copy.left = right
    copy.right = left
    return copy
  }

  func yFlippedCopy() -> RectEdges<T> {
    var copy = self
    copy.top = bottom
    copy.bottom = top
    return copy
  }

  func setStart(start: T, writingMode: WritingMode, direction: TextDirection = .LTR) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isZero() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var top: T
  var right: T
  var bottom: T
  var left: T
}

private func + (a: IntOutsets, b: IntOutsets) -> IntOutsets {
  return IntOutsets(
    top: a.top + b.top, right: a.right + b.right, bottom: a.bottom + b.bottom, left: a.left + b.left
  )
}

@discardableResult
func += (a: inout IntOutsets, b: IntOutsets) -> IntOutsets {
  a = a + b
  return a
}

extension LayoutBoxExtent {

  private func at(_ side: BoxSide) -> LayoutUnit {
    switch side {
    case .Top:
      return top
    case .Right:
      return right
    case .Bottom:
      return bottom
    case .Left:
      return left
    }
  }

  private mutating func setSide(_ side: BoxSide, _ value: LayoutUnit) {
    switch side {
    case .Top:
      top = value
    case .Right:
      right = value
    case .Bottom:
      bottom = value
    case .Left:
      left = value
    }
  }

  func before(_ writingMode: WritingMode) -> LayoutUnit {
    return at(mapLogicalSideToPhysicalSide(writingMode, .BlockStart))
  }

  func after(_ writingMode: WritingMode) -> LayoutUnit {
    return at(mapLogicalSideToPhysicalSide(writingMode, .BlockEnd))
  }

  func start(_ writingMode: WritingMode, _ direction: TextDirection = .LTR) -> LayoutUnit {
    return at(
      mapLogicalSideToPhysicalSide(
        makeTextFlow(writingMode: writingMode, direction: direction), .InlineStart))
  }

  func end(_ writingMode: WritingMode, _ direction: TextDirection = .LTR) -> LayoutUnit {
    return at(
      mapLogicalSideToPhysicalSide(
        makeTextFlow(writingMode: writingMode, direction: direction), .InlineEnd))
  }

  // TODO(asuhan): Make this a method of RectEdges once the segfault root cause is fixed.
  mutating func setBefore(_ before: LayoutUnit, _ writingMode: WritingMode) {
    setSide(mapLogicalSideToPhysicalSide(writingMode, .BlockStart), before)
  }

  // TODO(asuhan): Make this a method of RectEdges once the segfault root cause is fixed.
  mutating func setAfter(_ after: LayoutUnit, _ writingMode: WritingMode) {
    setSide(mapLogicalSideToPhysicalSide(writingMode, .BlockEnd), after)
  }

}
