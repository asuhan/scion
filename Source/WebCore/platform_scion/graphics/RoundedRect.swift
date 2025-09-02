/*
 * Copyright (C) 2003, 2006, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2013 Xidorn Quan (quanxunzhen@gmail.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct RoundedRectRadii {
  func isZero() -> Bool {
    return topLeft.isZero() && topRight.isZero() && bottomLeft.isZero() && bottomRight.isZero()
  }

  func areRenderableInRect(rect: LayoutRectWrapper) -> Bool {
    return topLeft.width() >= 0 && topLeft.height() >= 0
      && bottomLeft.width() >= 0 && bottomLeft.height() >= 0
      && topRight.width() >= 0 && topRight.height() >= 0
      && bottomRight.width() >= 0 && bottomRight.height() >= 0
      && topLeft.width() + topRight.width() <= rect.width()
      && bottomLeft.width() + bottomRight.width() <= rect.width()
      && topLeft.height() + bottomLeft.height() <= rect.height()
      && topRight.height() + bottomRight.height() <= rect.height()
  }

  mutating func makeRenderableInRect(rect: LayoutRectWrapper) {
    let maxRadiusWidth = max(
      topLeft.width() + topRight.width(), bottomLeft.width() + bottomRight.width())
    let maxRadiusHeight = max(
      topLeft.height() + bottomLeft.height(), topRight.height() + bottomRight.height())

    if maxRadiusWidth <= 0 || maxRadiusHeight <= 0 {
      scale(factor: 0)
      return
    }

    let widthRatio = rect.width().float() / maxRadiusWidth
    let heightRatio = rect.height().float() / maxRadiusHeight
    scale(factor: widthRatio < heightRatio ? widthRatio : heightRatio)
  }

  func expand(
    topWidth: LayoutUnit, bottomWidth: LayoutUnit, leftWidth: LayoutUnit, rightWidth: LayoutUnit
  ) {
    if topLeft.width() > 0 && topLeft.height() > 0 {
      topLeft.setWidth(width: max(LayoutUnit(value: 0), topLeft.width() + leftWidth))
      topLeft.setHeight(height: max(LayoutUnit(value: 0), topLeft.height() + topWidth))
    }
    if topRight.width() > 0 && topRight.height() > 0 {
      topRight.setWidth(width: max(LayoutUnit(value: 0), topRight.width() + rightWidth))
      topRight.setHeight(height: max(LayoutUnit(value: 0), topRight.height() + topWidth))
    }
    if bottomLeft.width() > 0 && bottomLeft.height() > 0 {
      bottomLeft.setWidth(width: max(LayoutUnit(value: 0), bottomLeft.width() + leftWidth))
      bottomLeft.setHeight(height: max(LayoutUnit(value: 0), bottomLeft.height() + bottomWidth))
    }
    if bottomRight.width() > 0 && bottomRight.height() > 0 {
      bottomRight.setWidth(width: max(LayoutUnit(value: 0), bottomRight.width() + rightWidth))
      bottomRight.setHeight(height: max(LayoutUnit(value: 0), bottomRight.height() + bottomWidth))
    }
  }

  func expand(size: LayoutUnit) {
    expand(topWidth: size, bottomWidth: size, leftWidth: size, rightWidth: size)
  }

  mutating func scale(factor: Float32) {
    if factor == 1 {
      return
    }

    // If either radius on a corner becomes zero, reset both radii on that corner.
    topLeft.scale(scale: factor)
    if !topLeft.width().bool() || !topLeft.height().bool() {
      topLeft = LayoutSizeWrapper()
    }
    topRight.scale(scale: factor)
    if !topRight.width().bool() || !topRight.height().bool() {
      topRight = LayoutSizeWrapper()
    }
    bottomLeft.scale(scale: factor)
    if !bottomLeft.width().bool() || !bottomLeft.height().bool() {
      bottomLeft = LayoutSizeWrapper()
    }
    bottomRight.scale(scale: factor)
    if !bottomRight.width().bool() || !bottomRight.height().bool() {
      bottomRight = LayoutSizeWrapper()
    }
  }

  func shrink(
    topWidth: LayoutUnit, bottomWidth: LayoutUnit, leftWidth: LayoutUnit, rightWidth: LayoutUnit
  ) {
    expand(
      topWidth: -topWidth, bottomWidth: -bottomWidth, leftWidth: -leftWidth, rightWidth: -rightWidth
    )
  }

  var topLeft = LayoutSizeWrapper()
  var topRight = LayoutSizeWrapper()
  var bottomLeft = LayoutSizeWrapper()
  var bottomRight = LayoutSizeWrapper()
}

struct RoundedRect {
  typealias Radii = RoundedRectRadii

  init(rect: LayoutRectWrapper, radii: Radii = Radii()) {
    self.rect = rect
    self.radii = radii
  }

  func isRounded() -> Bool { return !radii.isZero() }

  mutating func move(size: LayoutSizeWrapper) { rect.move(size: size) }

  mutating func inflateWithRadii(amount: LayoutUnit) {
    let old = rect

    if amount < 0 {
      rect.inflateX(dx: max(-rect.width() / 2, amount))
      rect.inflateY(dy: max(-rect.height() / 2, amount))
    } else {
      rect.inflate(d: amount)
    }

    // Considering the inflation factor of shorter size to scale the radii seems appropriate here
    var factor: Float32 = 0
    if rect.width() < rect.height() {
      factor = old.width().bool() ? rect.width().float() / old.width() : 0
    } else {
      factor = old.height().bool() ? rect.height().float() / old.height() : 0
    }

    radii.scale(factor: factor)
  }

  func isRenderable() -> Bool {
    return radii.areRenderableInRect(rect: rect)
  }

  func adjustRadii() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contains(otherRect: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pixelSnappedRoundedRectForPainting(deviceScaleFactor: Float32) -> FloatRoundedRect {
    let originalRect = rect
    if originalRect.isEmpty() {
      return FloatRoundedRect(
        rect: originalRect.FloatRect(), radii: FloatRoundedRect.Radii(intRadii: radii))
    }

    let pixelSnappedRect = snapRectToDevicePixels(
      rect: originalRect, pixelSnappingFactor: deviceScaleFactor)

    if !isRenderable() {
      return FloatRoundedRect(
        rect: pixelSnappedRect, radii: FloatRoundedRect.Radii(intRadii: radii))
    }

    // Snapping usually does not alter size, but when it does, we need to make sure that the final rect is still renderable by distributing the size delta proportionally.
    var adjustedRadii = FloatRoundedRect.Radii(intRadii: radii)
    adjustedRadii.scale(
      horizontalFactor: pixelSnappedRect.width() / originalRect.width().toFloat(),
      verticalFactor: pixelSnappedRect.height() / originalRect.height().toFloat())
    var snappedRoundedRect = FloatRoundedRect(rect: pixelSnappedRect, radii: adjustedRadii)
    if !snappedRoundedRect.isRenderable() {
      // Floating point mantissa overflow can produce a non-renderable rounded rect.
      adjustedRadii.shrink(size: 1 / deviceScaleFactor)
      snappedRoundedRect.radii = adjustedRadii
    }
    assert(snappedRoundedRect.isRenderable())
    return snappedRoundedRect
  }

  var rect = LayoutRectWrapper()
  var radii = Radii()
}
