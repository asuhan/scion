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

enum AspectRatioFit {
  case AspectRatioFitShrink
  case AspectRatioFitGrow
}

class LayoutSizeWrapper: Equatable {
  init() {}

  init(size: IntSize) {
    width_ = LayoutUnit(value: size.width)
    height_ = LayoutUnit(value: size.height)
  }

  init(width: LayoutUnit, height: LayoutUnit) {
    width_ = width
    height_ = height
  }

  init(width: InlineLayoutUnit, height: InlineLayoutUnit) {
    width_ = LayoutUnit(value: width)
    height_ = LayoutUnit(value: height)
  }

  init(width: Float64, height: Float64) {
    width_ = LayoutUnit(value: width)
    height_ = LayoutUnit(value: height)
  }

  init(width: Int32, height: Int32) {
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

  func setWidth(width: Float32) { width_ = LayoutUnit(value: width) }

  func setWidth(width: Int32) { width_ = LayoutUnit(value: width) }

  func setHeight(height: LayoutUnit) { height_ = height }

  func setHeight(height: Float32) { height_ = LayoutUnit(value: height) }

  func isEmpty() -> Bool { return width_.rawValue() <= 0 || height_.rawValue() <= 0 }

  func isZero() -> Bool { return !width_.bool() && !height_.bool() }

  func expand(width: LayoutUnit, height: LayoutUnit) {
    width_ += width
    height_ += height
  }

  func expand(width: Float32, height: Float32) {
    width_ += width
    height_ += height
  }

  func shrink(_ width: LayoutUnit, _ height: LayoutUnit) {
    width_ -= width
    height_ -= height
  }

  func scale(scale: Float32) {
    width_ *= scale
    height_ *= scale
  }

  func scale(widthScale: Float32, heightScale: Float32) {
    width_ *= widthScale
    height_ *= heightScale
  }

  func expandedTo(other: LayoutSizeWrapper) -> LayoutSizeWrapper {
    return LayoutSizeWrapper(
      width: width_ > other.width_ ? width_ : other.width_,
      height: height_ > other.height_ ? height_ : other.height_)
  }

  func clampNegativeToZero() {
    let clamped = expandedTo(other: LayoutSizeWrapper())
    self.width_ = clamped.width_
    self.height_ = clamped.height_
  }

  func clampToMinimumSize(minimumSize: LayoutSizeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transposedSize() -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: height_, height: width_)
  }

  @discardableResult
  static func += (a: inout LayoutSizeWrapper, b: LayoutSizeWrapper) -> LayoutSizeWrapper {
    a.setWidth(width: a.width() + b.width())
    a.setHeight(height: a.height() + b.height())
    return a
  }

  @discardableResult
  static func -= (a: inout LayoutSizeWrapper, b: LayoutSizeWrapper) -> LayoutSizeWrapper {
    a.setWidth(width: a.width() - b.width())
    a.setHeight(height: a.height() - b.height())
    return a
  }

  static func + (a: LayoutSizeWrapper, b: LayoutSizeWrapper) -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: a.width() + b.width(), height: a.height() + b.height())
  }

  static func - (a: LayoutSizeWrapper, b: LayoutSizeWrapper) -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: a.width() - b.width(), height: a.height() - b.height())
  }

  prefix static func - (size: LayoutSizeWrapper) -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: -size.width(), height: -size.height())
  }

  func FloatSize() -> FloatSize {
    return layout_scion.FloatSize(width: width_.float(), height: height_.float())
  }

  func fitToAspectRatio(_ aspectRatio: LayoutSizeWrapper, _ fit: AspectRatioFit)
    -> LayoutSizeWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deepCopy() -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: width_, height: height_)
  }

  func mightBeSaturated() -> Bool {
    return width_.mightBeSaturated() || height_.mightBeSaturated()
  }

  static func == (lhs: LayoutSizeWrapper, rhs: LayoutSizeWrapper) -> Bool {
    return lhs.width_ == rhs.width_ && lhs.height_ == rhs.height_
  }

  private var width_: LayoutUnit = LayoutUnit()
  private var height_: LayoutUnit = LayoutUnit()
}

func flooredIntSize(_ s: LayoutSizeWrapper) -> IntSize {
  return IntSize(width: s.width().floor(), height: s.height().floor())
}

internal func ceiledIntSize(s: LayoutSizeWrapper) -> IntSize {
  return IntSize(width: s.width().ceil(), height: s.height().ceil())
}

func roundedIntSize(s: LayoutSizeWrapper) -> IntSize {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func floorSizeToDevicePixels(_ size: LayoutSizeWrapper, _ pixelSnappingFactor: Float32) -> FloatSize
{
  return FloatSize(
    width: floorToDevicePixel(value: size.width(), pixelSnappingFactor: pixelSnappingFactor),
    height: floorToDevicePixel(value: size.height(), pixelSnappingFactor: pixelSnappingFactor))
}

func roundSizeToDevicePixels(size: LayoutSizeWrapper, pixelSnappingFactor: Float32) -> FloatSize {
  return FloatSize(
    width: roundToDevicePixel(value: size.width(), pixelSnappingFactor: pixelSnappingFactor),
    height: roundToDevicePixel(value: size.height(), pixelSnappingFactor: pixelSnappingFactor))
}
