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

struct RoundedRectRadii: Equatable {
  func isZero() -> Bool {
    return topLeft.isZero() && topRight.isZero() && bottomLeft.isZero() && bottomRight.isZero()
  }

  func areRenderableInRect(rect: LayoutRectWrapper) -> Bool {
    return topLeft.width() >= Int32(0) && topLeft.height() >= Int32(0)
      && bottomLeft.width() >= Int32(0) && bottomLeft.height() >= Int32(0)
      && topRight.width() >= Int32(0) && topRight.height() >= Int32(0)
      && bottomRight.width() >= Int32(0) && bottomRight.height() >= Int32(0)
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

    if maxRadiusWidth <= Int32(0) || maxRadiusHeight <= Int32(0) {
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

  func transposedRadii() -> RoundedRectRadii {
    return RoundedRectRadii(
      topLeft: topLeft.transposedSize(), topRight: topRight.transposedSize(),
      bottomLeft: bottomLeft.transposedSize(), bottomRight: bottomRight.transposedSize())
  }

  var topLeft = LayoutSizeWrapper()
  var topRight = LayoutSizeWrapper()
  var bottomLeft = LayoutSizeWrapper()
  var bottomRight = LayoutSizeWrapper()
}

struct RoundedRect {
  typealias Radii = RoundedRectRadii

  init(rect: LayoutRectWrapper, radii: Radii = Radii()) {
    self.m_rect = rect
    self.radii = radii
  }

  func rect() -> LayoutRectWrapper { return m_rect }

  func isRounded() -> Bool { return !radii.isZero() }

  mutating func setRect(_ rect: LayoutRectWrapper) { m_rect = rect }

  mutating func move(size: LayoutSizeWrapper) { m_rect.move(size: size) }

  mutating func inflateWithRadii(amount: LayoutUnit) {
    let old = m_rect

    if amount < Int32(0) {
      m_rect.inflateX(dx: max(-m_rect.width() / 2, amount))
      m_rect.inflateY(dy: max(-m_rect.height() / 2, amount))
    } else {
      m_rect.inflate(d: amount)
    }

    // Considering the inflation factor of shorter size to scale the radii seems appropriate here
    var factor: Float32 = 0
    if m_rect.width() < m_rect.height() {
      factor = old.width().bool() ? m_rect.width().float() / old.width() : 0
    } else {
      factor = old.height().bool() ? m_rect.height().float() / old.height() : 0
    }

    radii.scale(factor: factor)
  }

  func isRenderable() -> Bool {
    return radii.areRenderableInRect(rect: m_rect)
  }

  mutating func adjustRadii() {
    radii.makeRenderableInRect(rect: m_rect)
  }

  // Tests whether the quad intersects any part of this rounded rectangle.
  // This only works for convex quads.
  func intersectsQuad(_ quad: FloatQuad) -> Bool {
    let rect = m_rect.FloatRect()
    if !quad.intersectsRect(rect) {
      return false
    }

    let topLeft = radii.topLeft
    if !topLeft.isEmpty() {
      let rect = FloatRectWrapper(
        x: m_rect.x().float(), y: m_rect.y().float(), width: topLeft.width().float(),
        height: topLeft.height().float()
      )
      if quad.intersectsRect(rect) {
        let center = FloatPoint(
          x: (m_rect.x() + topLeft.width()).float(), y: (m_rect.y() + topLeft.height()).float())
        let size = FloatSize(width: topLeft.width().float(), height: topLeft.height().float())
        if !quad.intersectsEllipse(center, size) {
          return false
        }
      }
    }

    let topRight = radii.topRight
    if !topRight.isEmpty() {
      let rect = FloatRectWrapper(
        x: (m_rect.maxX() - topRight.width()).float(), y: m_rect.y().float(),
        width: topRight.width().float(), height: topRight.height().float())
      if quad.intersectsRect(rect) {
        let center = FloatPoint(
          x: (m_rect.maxX() - topRight.width()).float(), y: (m_rect.y() + topRight.height()).float()
        )
        let size = FloatSize(width: topRight.width().float(), height: topRight.height().float())
        if !quad.intersectsEllipse(center, size) {
          return false
        }
      }
    }

    let bottomLeft = radii.bottomLeft
    if !bottomLeft.isEmpty() {
      let rect = FloatRectWrapper(
        x: m_rect.x().float(), y: (m_rect.maxY() - bottomLeft.height()).float(),
        width: bottomLeft.width().float(), height: bottomLeft.height().float())
      if quad.intersectsRect(rect) {
        let center = FloatPoint(
          x: (m_rect.x() + bottomLeft.width()).float(),
          y: (m_rect.maxY() - bottomLeft.height()).float())
        let size = FloatSize(width: bottomLeft.width().float(), height: bottomLeft.height().float())
        if !quad.intersectsEllipse(center, size) {
          return false
        }
      }
    }

    let bottomRight = radii.bottomRight
    if !bottomRight.isEmpty() {
      let rect = FloatRectWrapper(
        x: (m_rect.maxX() - bottomRight.width()).float(),
        y: (m_rect.maxY() - bottomRight.height()).float(), width: bottomRight.width().float(),
        height: bottomRight.height().float())
      if quad.intersectsRect(rect) {
        let center = FloatPoint(
          x: (m_rect.maxX() - bottomRight.width()).float(),
          y: (m_rect.maxY() - bottomRight.height()).float())
        let size = FloatSize(
          width: bottomRight.width().float(), height: bottomRight.height().float())
        if !quad.intersectsEllipse(center, size) {
          return false
        }
      }
    }

    return true
  }

  func contains(otherRect: LayoutRectWrapper) -> Bool {
    if !rect().contains(other: otherRect) || !isRenderable() {
      return false
    }

    let topLeft = radii.topLeft
    if !topLeft.isEmpty() {
      let center = FloatPoint(
        x: (m_rect.x() + topLeft.width()).float(), y: (m_rect.y() + topLeft.height()).float())
      if otherRect.x() <= center.x && otherRect.y() <= center.y {
        if !ellipseContainsPoint(
          center: center, radii: topLeft.FloatSize(), point: otherRect.minXMinYCorner().FloatPoint()
        ) {
          return false
        }
      }
    }

    let topRight = radii.topRight
    if !topRight.isEmpty() {
      let center = FloatPoint(
        x: (m_rect.maxX() - topRight.width()).float(), y: (m_rect.y() + topRight.height()).float())
      if otherRect.maxX() >= center.x && otherRect.y() <= center.y {
        if !ellipseContainsPoint(
          center: center, radii: topRight.FloatSize(),
          point: otherRect.maxXMinYCorner().FloatPoint())
        {
          return false
        }
      }
    }

    let bottomLeft = radii.bottomLeft
    if !bottomLeft.isEmpty() {
      let center = FloatPoint(
        x: (m_rect.x() + bottomLeft.width()).float(),
        y: (m_rect.maxY() - bottomLeft.height()).float())
      if otherRect.x() <= center.x && otherRect.maxY() >= center.y {
        if !ellipseContainsPoint(
          center: center, radii: bottomLeft.FloatSize(),
          point: otherRect.minXMaxYCorner().FloatPoint())
        {
          return false
        }
      }
    }

    let bottomRight = radii.bottomRight
    if !bottomRight.isEmpty() {
      let center = FloatPoint(
        x: (m_rect.maxX() - bottomRight.width()).float(),
        y: (m_rect.maxY() - bottomRight.height()).float())
      if otherRect.maxX() >= center.x && otherRect.maxY() >= center.y {
        if !ellipseContainsPoint(
          center: center, radii: bottomRight.FloatSize(),
          point: otherRect.maxXMaxYCorner().FloatPoint())
        {
          return false
        }
      }
    }

    return true
  }

  func pixelSnappedRoundedRectForPainting(deviceScaleFactor: Float32) -> FloatRoundedRect {
    let originalRect = rect()
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

  func transposedRect() -> RoundedRect {
    return RoundedRect(rect: m_rect.transposedRect(), radii: radii.transposedRadii())
  }

  private var m_rect = LayoutRectWrapper()
  var radii = Radii()
}
