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
    init() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    init(intRadii: RoundedRect.Radii) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    init(uniformRadius: Float32) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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

    func shrink(size: Float32) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private var topLeft: FloatSize
    private var topRight: FloatSize
    private var bottomLeft: FloatSize
    private var bottomRight: FloatSize
  }

  init(rect: FloatRectWrapper = FloatRectWrapper(), radii: Radii = Radii()) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(rect: RoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rect() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRounded() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func setRect(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var radii: Radii
}

func calcBorderRadiiConstraintScaleFor(rect: FloatRectWrapper, radii: FloatRoundedRect.Radii)
  -> Float32
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
