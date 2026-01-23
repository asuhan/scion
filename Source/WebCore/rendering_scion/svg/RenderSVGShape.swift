/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2005, 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2006 Apple Inc.
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2009 Jeff Schiller <codedread@gmail.com>
 * Copyright (C) 2011 Renata Hodovan <reni@webkit.org>
 * Copyright (C) 2011 University of Szeged
 * Copyright (C) 2018 Adobe Systems Incorporated. All rights reserved.
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

class RenderSVGShapeWrapper: RenderSVGModelObjectWrapper {
  enum ShapeType {
    case Empty
    case Path
    case Line
    case Rectangle
    case RoundedRectangle
    case Ellipse
    case Circle
  }

  func setNeedsShapeUpdate() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillShape(_ context: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderingDisabled() -> Bool { fatalError("Not reached") }

  func approximateStrokeBoundingBox() -> FloatRectWrapper {
    if shapeType == .Empty {
      return FloatRectWrapper()
    }
    if m_approximateStrokeBoundingBox == nil {
      // Initialize m_approximateStrokeBoundingBox before calling calculateApproximateStrokeBoundingBox, since recursively referenced markers can cause us to re-enter here.
      m_approximateStrokeBoundingBox = FloatRectWrapper()
      m_approximateStrokeBoundingBox = calculateApproximateStrokeBoundingBox()
    }
    return m_approximateStrokeBoundingBox!
  }

  func nonScalingStrokeTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateShapeFromElement() { fatalError("Not reached") }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasNonScalingStroke() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats

    let repainter = LayoutRepainter(renderer: self)
    if needsShapeUpdate {
      updateShapeFromElement()

      needsShapeUpdate = false
      setCurrentSVGLayoutRect(enclosingLayoutRect(rect: fillBoundingBox))
    }

    updateLayerTransform()

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    let relevantPaintPhases: PaintPhase = [
      .Foreground, .ClippingMask, .Mask, .Outline, .SelfOutline,
    ]
    if !shouldPaintSVGRenderer(paintInfo, relevantPaintPhases) || isEmpty() {
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

    let coordinateSystemOriginTranslation = adjustedPaintOffset - nominalSVGLayoutLocation()
    paintInfo.context().translate(
      x: coordinateSystemOriginTranslation.width().float(),
      y: coordinateSystemOriginTranslation.height().float())

    if style().svgStyle().shapeRendering() == .CrispEdges {
      paintInfo.context().setShouldAntialias(shouldAntialias: false)
    }

    fillStrokeMarkers(paintInfo)
  }

  private func setupNonScalingStrokeContext(
    _ strokeTransform: AffineTransform, _ stateSaver: GraphicsContextStateSaver
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func fillStrokeMarkers(_ childPaintInfo: PaintInfoWrapper) {
    for type in RenderStyleWrapper.paintTypesForPaintOrder(order: style().paintOrder()) {
      switch type {
      case .Fill:
        fillShape(style(), childPaintInfo.context())
      case .Stroke:
        strokeShape(style(), childPaintInfo.context())
      case .Markers:
        drawMarkers(childPaintInfo)
      }
    }
  }

  private func fillShape(_ style: RenderStyleWrapper, _ context: GraphicsContextWrapper) {
    let paintServerHandling = SVGPaintServerHandling(context)
    if paintServerHandling.preparePaintOperation(.Fill, self, style) {
      fillShape(context)
    }
  }

  func strokeShape(_ context: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func strokeShape(_ style: RenderStyleWrapper, _ context: GraphicsContextWrapper) {
    if !style.hasVisibleStroke() {
      return
    }

    let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
    if hasNonScalingStroke() {
      let nonScalingTransform = nonScalingStrokeTransform()
      if !setupNonScalingStrokeContext(nonScalingTransform, stateSaver) {
        return
      }
    }

    let paintServerHandling = SVGPaintServerHandling(context)
    if paintServerHandling.preparePaintOperation(.Stroke, self, style) {
      strokeShape(context)
    }
  }

  func drawMarkers(_ paintInfo: PaintInfoWrapper) {}

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateApproximateStrokeBoundingBox() -> FloatRectWrapper {
    return m_strokeBoundingBox ?? SVGRenderSupport.calculateApproximateStrokeBoundingBox(self)
  }

  private let fillBoundingBox = FloatRectWrapper()
  private let m_strokeBoundingBox: FloatRectWrapper? = nil
  private var m_approximateStrokeBoundingBox: FloatRectWrapper? = nil
  private var needsShapeUpdate = true
  private let shapeType: ShapeType = .Empty
}
