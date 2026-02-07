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

class LegacyRenderSVGShapeWrapper: LegacyRenderSVGModelObject, RenderSVGShapeProto {
  private func graphicsElement() -> SVGGraphicsElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setNeedsTransformUpdate() { needsTransformUpdate = true }

  func hasPath() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func path() -> PathWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateShapeFromElement() { fatalError("Not reached") }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeWidth() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasNonScalingStroke() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nonScalingStrokeTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nonScalingStrokePath(_ path: PathWrapper, _ strokeTransform: AffineTransform)
    -> PathWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustStrokeBoundingBoxForMarkersAndZeroLengthLinecaps(
    _ repaintRectCalculation: RepaintRectCalculation, _ strokeBoundingBox: FloatRectWrapper
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localToParentTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func localTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    let checkForRepaintOverride: LayoutRepainter.CheckForRepaint =
      !selfNeedsLayout() ? .No : SVGRenderSupport.checkForSVGRepaintDuringLayout(self)
    let repainter = LayoutRepainter(
      renderer: self, checkForRepaintOverride: checkForRepaintOverride,
      shouldAlwaysIssueFullRepaint: nil, repaintOutlineBounds: .No)

    var updateCachedBoundariesInParents = false

    if needsShapeUpdate || needsBoundariesUpdate {
      updateShapeFromElement()
      needsShapeUpdate = false
      updateRepaintBoundingBox()
      needsBoundariesUpdate = false
      updateCachedBoundariesInParents = true
    }

    if needsTransformUpdate {
      m_localTransform = graphicsElement().animatedLocalTransform()
      needsTransformUpdate = false
      updateCachedBoundariesInParents = true
    }

    // Invalidate all resources of this client if our layout changed.
    if everHadLayout() && selfNeedsLayout() {
      SVGResourcesCache.clientLayoutChanged(self)
    }

    // If our bounds changed, notify the parents.
    if updateCachedBoundariesInParents, let parent = parent() {
      parent.invalidateCachedBoundaries()
    }

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if style().usedVisibility() == .Hidden || isEmpty() {
      return
    }

    if paintInfo.phase == .EventRegion {
      paintInfo.eventRegionContext()!.unite(
        roundedRect: FloatRoundedRect(rect: fillBoundingBox), renderer: self, style: style(),
        overrideUserModifyIsEditable: false)
      return
    }

    if paintInfo.context().paintingDisabled() || paintInfo.phase != .Foreground {
      return
    }

    let boundingBox = repaintRectInLocalCoordinates()
    if !SVGRenderSupport.paintInfoIntersectsRepaintRect(boundingBox, m_localTransform, paintInfo) {
      return
    }

    let childPaintInfo = paintInfo.deepCopy()
    let _ = GraphicsContextStateSaver(context: childPaintInfo.context())
    childPaintInfo.applyTransform(m_localTransform)

    if childPaintInfo.phase == .Foreground {
      let renderingContext = SVGRenderingContext(self, childPaintInfo)

      if renderingContext.isRenderingPrepared() {
        let svgStyle = style().svgStyle()
        if svgStyle.shapeRendering() == .CrispEdges {
          childPaintInfo.context().setShouldAntialias(shouldAntialias: false)
        }

        m_fillRequiresClip = !renderingContext.pathClippingIsEntirelyWithinRendererContents()
        fillStrokeMarkers(childPaintInfo)
        m_fillRequiresClip = true
      }
    }

    if style().outlineWidth() != 0 {
      paintOutline(
        paintInfo: childPaintInfo, paintRect: LayoutRectWrapper(rect: IntRect(boundingBox)))
    }
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateRepaintBoundingBox() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func fillStrokeMarkers(_ childPaintInfo: PaintInfoWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let fillBoundingBox = FloatRectWrapper()
  var needsBoundariesUpdate = false
  var needsShapeUpdate = false
  private var needsTransformUpdate = false
  private var m_fillRequiresClip = true
  let shapeType: ShapeType = .Empty
  private var m_localTransform = AffineTransform()
}
