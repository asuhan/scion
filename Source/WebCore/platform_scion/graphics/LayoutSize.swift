/*
 * Copyright (c) 2012-2013, Google Inc. All rights reserved.
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

class LayoutSizeWrapper {
  init() {}

  init(width: LayoutUnit, height: LayoutUnit) {
    width_ = width
    height_ = height
  }

  init(width: InlineLayoutUnit, height: InlineLayoutUnit) {
    width_ = LayoutUnit(value: width)
    height_ = LayoutUnit(value: height)
  }

  init(size: FloatSize) {
    width_ = LayoutUnit(value: size.width)
    height_ = LayoutUnit(value: size.height)
  }

  func width() -> LayoutUnit { return width_ }

  func height() -> LayoutUnit { return height_ }

  func setWidth(width: LayoutUnit) { width_ = width }

  func setHeight(height: LayoutUnit) { height_ = height }

  func isEmpty() -> Bool { return width_.rawValue() <= 0 || height_.rawValue() <= 0 }

  func isZero() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transposedSize() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): implement this
  @discardableResult
  static func += (a: inout LayoutSizeWrapper, b: LayoutSizeWrapper) -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  prefix static func - (size: LayoutSizeWrapper) -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func FloatSize() -> FloatSize {
    return layout_scion.FloatSize(width: width_.float(), height: height_.float())
  }

  private var width_: LayoutUnit = LayoutUnit()
  private var height_: LayoutUnit = LayoutUnit()
}

internal func ceiledIntSize(s: LayoutSizeWrapper) -> IntSize {
  return IntSize(width: s.width().ceil(), height: s.height().ceil())
}
