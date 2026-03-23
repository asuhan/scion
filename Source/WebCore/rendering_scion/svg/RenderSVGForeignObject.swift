/*
 * Copyright (C) 2006 Apple Inc.
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2020, 2021, 2022 Igalia S.L.
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

final class RenderSVGForeignObjectWrapper: RenderSVGBlockWrapper {
  private func foreignObjectElement() -> SVGForeignObjectElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !shouldPaintSVGRenderer(paintInfo) {
      return
    }

    if paintInfo.phase == .ClippingMask {
      paintSVGClippingMask(paintInfo: paintInfo, objectBoundingBox: objectBoundingBox())
      return
    }

    let adjustedPaintOffset = paintOffset + location()
    if paintInfo.phase == .Mask {
      paintSVGMask(paintInfo, adjustedPaintOffset)
      return
    }

    let unused = GraphicsContextStateSaver(context: paintInfo.context())
    use(unused)
    paintInfo.context().translate(
      x: adjustedPaintOffset.x.float(), y: adjustedPaintOffset.y.float())
    super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    let repainter = LayoutRepainter(renderer: self)

    let useForeignObjectElement = foreignObjectElement()
    let lengthContext = SVGLengthContext(context: useForeignObjectElement)

    // Cache viewport boundaries
    let x = useForeignObjectElement.x().value(lengthContext)
    let y = useForeignObjectElement.y().value(lengthContext)
    let width = useForeignObjectElement.width().value(lengthContext)
    let height = useForeignObjectElement.height().value(lengthContext)
    viewport = FloatRectWrapper(x: x, y: y, width: width, height: height)

    super.layout()
    assert(!needsLayout())

    setLocation(p: enclosingLayoutRect(rect: viewport).location())
    updateLayerTransform()

    repainter.repaintAfterLayout()
  }

  override final func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func updateFromStyle() {
    super.updateFromStyle()

    if SVGRenderSupport.isOverflowHidden(self) {
      setHasNonVisibleOverflow()
    }
  }

  private var viewport = FloatRectWrapper()
}
