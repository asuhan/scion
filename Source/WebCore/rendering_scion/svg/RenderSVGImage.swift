/*
 * Copyright (C) 2006 Alexander Kellett <lypanov@kde.org>
 * Copyright (C) 2006, 2009 Apple Inc.
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007, 2008, 2009 Rob Buis <buis@kde.org>
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
 * Copyright (c) 2020, 2021, 2022 Igalia S.L.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

final class RenderSVGImageWrapper: RenderSVGModelObjectWrapper {
  @discardableResult
  private func updateImageViewport() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats

    let repainter = LayoutRepainter(renderer: self)

    updateImageViewport()
    setCurrentSVGLayoutRect(enclosingLayoutRect(rect: objectBoundingBox))

    updateLayerTransform()

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    let relevantPaintPhases: PaintPhase = [
      .Foreground, .ClippingMask, .Mask, .Outline, .SelfOutline,
    ]
    if !shouldPaintSVGRenderer(paintInfo, relevantPaintPhases)
      || imageResource!.cachedImage() == nil
    {
      return
    }

    if paintInfo.phase == .ClippingMask {
      paintSVGClippingMask(paintInfo: paintInfo, objectBoundingBox: objectBoundingBox())
      return
    }

    let adjustedPaintOffset = paintOffset + currentSVGLayoutLocation()
    if paintInfo.phase == .Mask {
      paintSVGMask(paintInfo, adjustedPaintOffset)
      return
    }

    var visualOverflowRect = visualOverflowRectEquivalent()
    visualOverflowRect.moveBy(offset: adjustedPaintOffset)
    if !visualOverflowRect.intersects(other: paintInfo.rect) {
      return
    }

    if paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline {
      paintSVGOutline(paintInfo, adjustedPaintOffset)
      return
    }

    assert(paintInfo.phase == .Foreground)
    let _ = GraphicsContextStateSaver(context: paintInfo.context())

    let coordinateSystemOriginTranslation =
      adjustedPaintOffset - flooredLayoutPoint(p: objectBoundingBox().location())
    paintInfo.context().translate(
      x: coordinateSystemOriginTranslation.width().float(),
      y: coordinateSystemOriginTranslation.height().float())

    if style().svgStyle().bufferedRendering() == .Static
      && bufferForeground(paintInfo, flooredLayoutPoint(p: objectBoundingBox().location()))
    {
      return
    }

    paintForeground(paintInfo, flooredLayoutPoint(p: objectBoundingBox().location()))
  }

  private func paintForeground(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func bufferForeground(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let objectBoundingBox = FloatRectWrapper()
  private let imageResource: RenderImageResource? = nil
}
