/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct FloatRoundedRect {
  struct Radii {
    init() {}

    init(intRadii: RoundedRect.Radii) {
      topLeft = intRadii.topLeft.FloatSize()
      topRight = intRadii.topRight.FloatSize()
      bottomLeft = intRadii.bottomLeft.FloatSize()
      bottomRight = intRadii.bottomRight.FloatSize()
    }

    init(uniformRadius: Float32) {
      topLeft = FloatSize(width: uniformRadius, height: uniformRadius)
      topRight = FloatSize(width: uniformRadius, height: uniformRadius)
      bottomLeft = FloatSize(width: uniformRadius, height: uniformRadius)
      bottomRight = FloatSize(width: uniformRadius, height: uniformRadius)
    }

    func isZero() -> Bool {
      return topLeft.isZero() && topRight.isZero() && bottomLeft.isZero() && bottomRight.isZero()
    }

    mutating func scale(horizontalFactor: Float32, verticalFactor: Float32) {
      if horizontalFactor == 1 && verticalFactor == 1 {
        return
      }

      // If either radius on a corner becomes zero, reset both radii on that corner.
      topLeft.scale(scaleX: horizontalFactor, scaleY: verticalFactor)
      if topLeft.width == 0 || topLeft.height == 0 {
        topLeft = FloatSize()
      }
      topRight.scale(scaleX: horizontalFactor, scaleY: verticalFactor)
      if topRight.width == 0 || topRight.height == 0 {
        topRight = FloatSize()
      }
      bottomLeft.scale(scaleX: horizontalFactor, scaleY: verticalFactor)
      if bottomLeft.width == 0 || bottomLeft.height == 0 {
        bottomLeft = FloatSize()
      }
      bottomRight.scale(scaleX: horizontalFactor, scaleY: verticalFactor)
      if bottomRight.width == 0 || bottomRight.height == 0 {
        bottomRight = FloatSize()
      }
    }

    mutating func expand(
      topWidth: Float32, bottomWidth: Float32, leftWidth: Float32, rightWidth: Float32
    ) {
      if topLeft.width > 0 && topLeft.height > 0 {
        topLeft.setWidth(width: max(0, topLeft.width + leftWidth))
        topLeft.setHeight(height: max(0, topLeft.height + topWidth))
      }
      if topRight.width > 0 && topRight.height > 0 {
        topRight.setWidth(width: max(0, topRight.width + rightWidth))
        topRight.setHeight(height: max(0, topRight.height + topWidth))
      }
      if bottomLeft.width > 0 && bottomLeft.height > 0 {
        bottomLeft.setWidth(width: max(0, bottomLeft.width + leftWidth))
        bottomLeft.setHeight(height: max(0, bottomLeft.height + bottomWidth))
      }
      if bottomRight.width > 0 && bottomRight.height > 0 {
        bottomRight.setWidth(width: max(0, bottomRight.width + rightWidth))
        bottomRight.setHeight(height: max(0, bottomRight.height + bottomWidth))
      }
    }

    mutating func shrink(
      topWidth: Float32, bottomWidth: Float32, leftWidth: Float32, rightWidth: Float32
    ) {
      expand(
        topWidth: -topWidth, bottomWidth: -bottomWidth, leftWidth: -leftWidth,
        rightWidth: -rightWidth)
    }

    mutating func shrink(size: Float32) {
      shrink(topWidth: size, bottomWidth: size, leftWidth: size, rightWidth: size)
    }

    var topLeft = FloatSize()
    var topRight = FloatSize()
    var bottomLeft = FloatSize()
    var bottomRight = FloatSize()
  }

  init(rect: FloatRectWrapper = FloatRectWrapper(), radii: Radii = Radii()) {
    self.rect = rect
    self.radii = radii
  }

  init(rect: RoundedRect) {
    self.rect = rect.rect.FloatRect()
    self.radii = Radii(intRadii: rect.radii)
  }

  func isRounded() -> Bool { return !radii.isZero() }

  func isEmpty() -> Bool { return rect.isEmpty() }

  mutating func move(size: FloatSize) { rect.move(delta: size) }

  func isRenderable() -> Bool {
    return radii.topLeft.width >= 0 && radii.topLeft.height >= 0
      && radii.bottomLeft.width >= 0 && radii.bottomLeft.height >= 0
      && radii.topRight.width >= 0 && radii.topRight.height >= 0
      && radii.bottomRight.width >= 0 && radii.bottomRight.height >= 0
      && radii.topLeft.width + radii.topRight.width <= rect.width()
      && radii.bottomLeft.width + radii.bottomRight.width <= rect.width()
      && radii.topLeft.height + radii.bottomLeft.height <= rect.height()
      && radii.topRight.height + radii.bottomRight.height <= rect.height()
  }

  var rect: FloatRectWrapper
  var radii: Radii
}

func calcBorderRadiiConstraintScaleFor(rect: FloatRectWrapper, radii: FloatRoundedRect.Radii)
  -> Float32
{
  // Constrain corner radii using CSS3 rules:
  // http://www.w3.org/TR/css3-background/#the-border-radius

  var factor: Float32 = 1

  // top
  var radiiSum = radii.topLeft.width + radii.topRight.width  // Casts to avoid integer overflow.
  if radiiSum > rect.width() {
    factor = min(rect.width() / radiiSum, factor)
  }

  // bottom
  radiiSum = radii.bottomLeft.width + radii.bottomRight.width
  if radiiSum > rect.width() {
    factor = min(rect.width() / radiiSum, factor)
  }

  // left
  radiiSum = radii.topLeft.height + radii.bottomLeft.height
  if radiiSum > rect.height() {
    factor = min(rect.height() / radiiSum, factor)
  }

  // right
  radiiSum = radii.topRight.height + radii.bottomRight.height
  if radiiSum > rect.height() {
    factor = min(rect.height() / radiiSum, factor)
  }

  assert(factor <= 1)
  return factor
}
