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

import wk_interop

private func convertIntRect(_ r: IntRect) -> IntRectRaw {
  return IntRectRaw(
    location: IntPointRaw(x: r.location.x, y: r.location.y),
    size: IntSizeRaw(width: r.size.width, height: r.size.height))
}

class TransformationMatrix {
  init(_ p: UnsafeMutableRawPointer, _ owner: Bool) {
    self.pInterop = p
    self.owner = owner
  }

  deinit {
    if self.owner {
      wk_interop.TransformationMatrix_destroy(pInterop)
    }
  }

  convenience init() { self.init(wk_interop.TransformationMatrix_create(), true) }

  init(_ t: AffineTransform) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func makeIdentity() -> TransformationMatrix {
    return TransformationMatrix(wk_interop.TransformationMatrix_makeIdentity(pInterop), false)
  }

  // If the matrix has 3D components, the z component of the result is
  // dropped, effectively projecting the rect into the z=0 plane.
  func mapRect(_ rect: FloatRectWrapper) -> FloatRectWrapper {
    return toFloatRect(wk_interop.TransformationMatrix_mapFloatRect(pInterop, toFloatRectRaw(rect)))
  }

  // Rounds the resulting mapped rectangle out. This is helpful for bounding
  // box computations but may not be what is wanted in other contexts.
  func mapRect(_ rect: IntRect) -> IntRect {
    return convertIntRect(
      wk_interop.TransformationMatrix_mapIntRect(pInterop, convertIntRect(rect)))
  }

  func mapRect(_ r: LayoutRectWrapper) -> LayoutRectWrapper {
    return convertLayoutRect(
      wk_interop.TransformationMatrix_mapLayoutRect(pInterop, convertLayoutRect(r)))
  }

  func e() -> Float64 { return wk_interop.TransformationMatrix_e(pInterop) }

  func setE(_ e: Float64) { wk_interop.TransformationMatrix_setE(pInterop, e) }

  func f() -> Float64 { return wk_interop.TransformationMatrix_f(pInterop) }

  func setF(_ f: Float64) { wk_interop.TransformationMatrix_setF(pInterop, f) }

  // this = mat * this.
  @discardableResult
  func multiply(mat: TransformationMatrix) -> TransformationMatrix {
    return TransformationMatrix(
      wk_interop.TransformationMatrix_multiply(pInterop, mat.pInterop), false)
  }

  func scale(_ s: Float64) -> TransformationMatrix { return scaleNonUniform(sx: s, sy: s) }

  @discardableResult
  func scaleNonUniform(sx: Float64, sy: Float64) -> TransformationMatrix {
    return TransformationMatrix(
      wk_interop.TransformationMatrix_scaleNonUniform(pInterop, sx, sy), false)
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

  @discardableResult
  func translateRight3d(tx: Float64, ty: Float64, tz: Float64) -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func applyPerspective(_ p: Float64) -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInvertible() -> Bool { return wk_interop.TransformationMatrix_isInvertible(pInterop) }

  func inverse() -> TransformationMatrix? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAffine() -> Bool { return wk_interop.TransformationMatrix_isAffine(pInterop) }

  // Throw away the non-affine parts of the matrix (lossy!).
  func makeAffine() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func toAffineTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func * (_ this: TransformationMatrix, _ t: TransformationMatrix) -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isIntegerTranslation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deepCopy() -> TransformationMatrix {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func interop() -> UnsafeMutableRawPointer { return pInterop }

  private let pInterop: UnsafeMutableRawPointer
  private let owner: Bool
}
