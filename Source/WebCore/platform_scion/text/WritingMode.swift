/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
 * Copyright (C) 2015-2024 Apple Inc. All rights reserved.
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

enum FlowDirection: UInt8 {
  case TopToBottom
  case BottomToTop
  case LeftToRight
  case RightToLeft
}

enum WritingMode: UInt8 {
  case HorizontalTb
  case HorizontalBt  // Non-standard
  case VerticalLr
  case VerticalRl
  case SidewaysLr
  case SidewaysRl
}

func writingModeToBlockFlowDirection(writingMode: WritingMode) -> FlowDirection {
  switch writingMode {
  case .HorizontalTb:
    return .TopToBottom
  case .HorizontalBt:
    return .BottomToTop
  case .SidewaysLr, .VerticalLr:
    return .LeftToRight
  case .SidewaysRl, .VerticalRl:
    return .RightToLeft
  }
}

// Define the text flow in terms of the writing mode and the text direction. The first
// part is the block flow direction and the second part is the inline base direction.
struct TextFlow {
  var blockDirection: FlowDirection
  var textDirection: TextDirection

  func isFlipped() -> Bool {
    return blockDirection == .BottomToTop || blockDirection == .RightToLeft
  }

  func isVertical() -> Bool {
    return blockDirection == .LeftToRight || blockDirection == .RightToLeft
  }
}

func makeTextFlow(writingMode: WritingMode, direction: TextDirection) -> TextFlow {
  var textDirection = direction

  // FIXME: Remove this erronous logic and remove `makeTextFlow` helper (webkit.org/b/276028).
  if writingMode == .SidewaysLr {
    textDirection = direction == .RTL ? .LTR : .RTL
  }

  return TextFlow(
    blockDirection: writingModeToBlockFlowDirection(writingMode: writingMode),
    textDirection: textDirection)
}

// Lines have vertical orientation; modes vertical-lr or vertical-rl.
func isVerticalWritingMode(writingMode: WritingMode) -> Bool {
  return makeTextFlow(writingMode: writingMode, direction: .LTR).isVertical()
}

// Block progression increases in the opposite direction to normal; modes vertical-rl or horizontal-bt.
func isFlippedWritingMode(writingMode: WritingMode) -> Bool {
  return makeTextFlow(writingMode: writingMode, direction: .LTR).isFlipped()
}

// Lines have horizontal orientation; modes horizontal-tb or horizontal-bt.
func isHorizontalWritingMode(writingMode: WritingMode) -> Bool {
  return !isVerticalWritingMode(writingMode: writingMode)
}

enum BoxSide: UInt8 {
  case Top
  case Right
  case Bottom
  case Left
}

let allBoxSides: [BoxSide] = [.Top, .Right, .Bottom, .Left]
