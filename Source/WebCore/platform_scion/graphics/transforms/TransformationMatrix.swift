/*
 * Copyright (C) 2005-2016 Apple Inc.  All rights reserved.
 * Copyright (C) 2009 Torch Mobile, Inc.
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

class TransformationMatrix {
  @discardableResult
  func makeIdentity() -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func mapRect(r: LayoutRectWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // this = mat * this.
  @discardableResult
  func multiply(mat: TransformationMatrix) -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func scaleNonUniform(sx: Float64, sy: Float64) -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func translate(tx: Float64, ty: Float64) -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // translation added with a post-multiply
  @discardableResult
  func translateRight(tx: Float64, ty: Float64) -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInvertible() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inverse() -> TransformationMatrix? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAffine() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Throw away the non-affine parts of the matrix (lossy!).
  func makeAffine() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func toAffineTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deepCopy() -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
