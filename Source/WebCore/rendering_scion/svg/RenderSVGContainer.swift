/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.  All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
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

class RenderSVGContainerWrapper: RenderSVGModelObjectWrapper {
  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    let relevantPaintPhases: PaintPhase = [
      .Foreground, .ClippingMask, .Mask, .Outline, .SelfOutline,
    ]
    if !shouldPaintSVGRenderer(paintInfo, relevantPaintPhases) {
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
  }

  func isObjectBoundingBoxValid() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    let checkForRepaintOverride: LayoutRepainter.CheckForRepaint? =
      isRenderSVGResourceMarker() ? .No : nil
    let repainter = LayoutRepainter(
      renderer: self, checkForRepaintOverride: checkForRepaintOverride)

    // Update layer transform before laying out children (SVG needs access to the transform matrices during layout for on-screen text font-size calculations).
    // Eventually re-update if the transform reference box, relevant for transform-origin, has changed during layout.
    //
    // FIXME: LBSE should not repeat the same mistake -- remove the on-screen text font-size hacks that predate the modern solutions to this.
    do {
      assert(!isLayoutSizeChanged)
      let trackLayoutSizeChanges = SetForScope(
        scopedVariable: &isLayoutSizeChanged, newValue: updateLayoutSizeIfNeeded())
      use(trackLayoutSizeChanges)

      assert(!didTransformToRootUpdate)
      let transformUpdater = SVGLayerTransformUpdater(self)
      let trackTransformChanges = SetForScope(
        scopedVariable: &didTransformToRootUpdate,
        newValue: transformUpdater.layerTransformChanged()
          || SVGContainerLayout.transformToRootChanged(parent()))
      use(trackTransformChanges)
      layoutChildren()
    }

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  func layoutRenderSVGContainer() { return layout() }

  private func layoutChildren() {
    var containerLayout = SVGContainerLayout(self)
    containerLayout.layoutChildren(selfNeedsLayout())

    let boundingBoxComputation = SVGBoundingBoxComputation(self)
    m_objectBoundingBox = boundingBoxComputation.computeDecoratedBoundingBox(
      SVGBoundingBoxComputation.objectBoundingBoxDecoration, &objectBoundingBoxValid)
    strokeBoundingBox = nil

    if let objectBoundingBoxWithoutTransformations =
      overridenObjectBoundingBoxWithoutTransformations()
    {
      m_objectBoundingBoxWithoutTransformations = objectBoundingBoxWithoutTransformations
    } else {
      let objectBoundingBoxDecorationWithoutTransformations = SVGBoundingBoxComputation
        .objectBoundingBoxDecoration.union(.IgnoreTransformations)
      m_objectBoundingBoxWithoutTransformations =
        boundingBoxComputation.computeDecoratedBoundingBox(
          objectBoundingBoxDecorationWithoutTransformations)
    }

    setCurrentSVGLayoutRect(enclosingLayoutRect(rect: m_objectBoundingBoxWithoutTransformations))

    containerLayout.positionChildrenRelativeToContainer()
  }

  func pointIsInsideViewportClip(_ pointInParent: FloatPoint) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateLayoutSizeIfNeeded() -> Bool { return false }

  func overridenObjectBoundingBoxWithoutTransformations() -> FloatRectWrapper? { return nil }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    let adjustedLocation = accumulatedOffset + currentSVGLayoutLocation()

    var visualOverflowRect = visualOverflowRectEquivalent()
    visualOverflowRect.moveBy(offset: adjustedLocation)
    if !locationInContainer.intersects(rect: visualOverflowRect) {
      return false
    }

    let recursionTracking = SVGVisitedRendererTracking(RenderSVGContainerWrapper.s_visitedSet)
    if recursionTracking.isVisiting(self) {
      return false
    }

    let _ = SVGVisitedRendererTracking.Scope(recursionTracking, self)

    var localPoint = locationInContainer.point()
    let coordinateSystemOriginTranslation = nominalSVGLayoutLocation() - adjustedLocation
    localPoint.move(s: coordinateSystemOriginTranslation)

    if !pointInSVGClippingArea(localPoint.FloatPoint()) {
      return false
    }

    // Give RenderSVGViewportContainer a chance to apply its viewport clip.
    if !pointIsInsideViewportClip(localPoint.FloatPoint()) {
      return false
    }

    var child = lastChild()
    while child != nil {
      if !child!.hasLayer()
        && child!.nodeAtPoint(
          request, &result, locationInContainer, adjustedLocation, hitTestAction)
      {
        updateHitTestResult(
          result: result, point: locationInContainer.point() - toLayoutSize(point: adjustedLocation)
        )
        if result.addNodeToListBasedTestResult(
          node: child!.protectedNode(), request: request, locationInContainer: locationInContainer,
          rect: visualOverflowRect) == .Stop
        {
          return true
        }
      }
      child = child!.previousSibling()
    }

    // Accessibility wants to return SVG containers, if appropriate.
    if request.type.contains(.AccessibilityHitTest)
      && m_objectBoundingBox.contains(localPoint.FloatPoint())
    {
      updateHitTestResult(
        result: result, point: locationInContainer.point() - toLayoutSize(point: adjustedLocation))
      if result.addNodeToListBasedTestResult(
        node: protectedNodeForHitTest(), request: request, locationInContainer: locationInContainer,
        rect: visualOverflowRect) == .Stop
      {
        return true
      }
    }

    // Spec: Only graphical elements can be targeted by the mouse, period.
    // 16.4: "If there are no graphics elements whose relevant graphics content is under the pointer (i.e., there is no target element), the event is not dispatched."
    return false
  }

  private static let s_visitedSet = SVGVisitedRendererTracking.VisitedSet()

  private var objectBoundingBoxValid = false
  var isLayoutSizeChanged = false
  var didTransformToRootUpdate = false
  private var m_objectBoundingBox = FloatRectWrapper()
  private var m_objectBoundingBoxWithoutTransformations = FloatRectWrapper()
  private var strokeBoundingBox: FloatRectWrapper? = nil
}
