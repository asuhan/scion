/*
 * Copyright (C) 2024 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

// BorderShape is used to fill and clip to the shape formed by the border and padding boxes with border-radius.
// In future, this may be a more complex shape than a rounded rect, so accessors that return rounded rects
// are deprecated.
class BorderShape {
  static func shapeForBorderRect(
    style: RenderStyleWrapper, borderRect: LayoutRectWrapper, includeLogicalLeftEdge: Bool = true,
    includeLogicalRightEdge: Bool = true
  ) -> BorderShape {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipToOuterShape(context: GraphicsContextWrapper, deviceScaleFactor: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipToInnerShape(context: GraphicsContextWrapper, deviceScaleFactor: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillOuterShape(
    context: GraphicsContextWrapper, color: ColorWrapper, deviceScaleFactor: Float32
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillInnerShape(
    context: GraphicsContextWrapper, color: ColorWrapper, deviceScaleFactor: Float32
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
