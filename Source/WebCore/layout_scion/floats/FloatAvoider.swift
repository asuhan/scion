/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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

// Floating boxes intersect their margin box with the other floats in the context,
// while other float avoiders (e.g. non-floating formatting context roots) intersect their border box.
struct FloatAvoider {
  mutating func setHorizontalPosition(horizontalPosition: LayoutUnit) {
    var horizontalPositionMutable = horizontalPosition
    if isLeftAligned && isFloatingBox() {
      horizontalPositionMutable += marginStart()
    }
    if !isLeftAligned {
      horizontalPositionMutable -= borderBoxWidth
      if isFloatingBox() {
        horizontalPositionMutable -= marginEnd()
      }
    }
    absoluteTopLeft.setX(
      x: constrainedByContainingBlock(horizontalPosition: horizontalPositionMutable))
  }

  private func constrainedByContainingBlock(horizontalPosition: LayoutUnit) -> LayoutUnit {
    // Horizontal position is constrained by the containing block's content box.
    // Compute the horizontal position for the new floating by taking both the contining block and the current left/right floats into account.
    if isLeftAligned {
      return max(containingBlockAbsoluteContentBox.start + marginStart(), horizontalPosition)
    }
    // Make sure it does not overflow the containing block on the right.
    return min(
      horizontalPosition, containingBlockAbsoluteContentBox.end - marginBoxWidth() + marginStart())
  }

  mutating func setVerticalPosition(verticalPosition: LayoutUnit) {
    var verticalPositionMutable = verticalPosition
    if isFloatingBox() {
      verticalPositionMutable += marginBefore()
    }
    absoluteTopLeft.setY(y: verticalPositionMutable)
  }

  mutating func resetHorizontalPosition() { absoluteTopLeft.setX(x: initialHorizontalPosition()) }

  private func initialHorizontalPosition() -> LayoutUnit {
    if isLeftAligned {
      return containingBlockAbsoluteContentBox.start + marginStart()
    }
    return containingBlockAbsoluteContentBox.end - marginEnd() - borderBoxWidth
  }

  func overflowsContainingBlock() -> Bool {
    let left = absoluteTopLeft.x - marginStart()
    if containingBlockAbsoluteContentBox.start > left {
      return true
    }

    let right = left + marginBoxWidth()
    return containingBlockAbsoluteContentBox.end < right
  }

  func top() -> LayoutUnit {
    var top = absoluteTopLeft.y
    if isFloatingBox() {
      top -= marginBefore()
    }
    return top
  }

  func left() -> LayoutUnit {
    var left = absoluteTopLeft.x
    if isFloatingBox() {
      left -= marginStart()
    }
    return left
  }

  func right() -> LayoutUnit {
    var right = left() + borderBoxWidth
    if isFloatingBox() {
      right += marginEnd()
    }
    return right
  }

  private func marginBefore() -> LayoutUnit { return margin.vertical.before }

  private func marginStart() -> LayoutUnit { return margin.horizontal.start }

  private func marginEnd() -> LayoutUnit { return margin.horizontal.end }

  private func marginBoxWidth() -> LayoutUnit {
    return marginStart() + borderBoxWidth + marginEnd()
  }

  private func isFloatingBox() -> Bool { return isFloatingPositioned }

  // These coordinate values are relative to the formatting root's border box.
  var absoluteTopLeft = LayoutPointWrapper()
  // Note that float avoider should work with no height value.
  var borderBoxWidth = LayoutUnit()
  var margin = BoxGeometry.Edges()
  var containingBlockAbsoluteContentBox = BoxGeometry.HorizontalEdges()
  var isFloatingPositioned = true
  var isLeftAligned = true
}
