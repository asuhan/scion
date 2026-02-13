/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.  All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
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

private func shouldSuspendRepaintForChildren(_ container: LegacyRenderSVGContainer) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class LegacyRenderSVGContainer: LegacyRenderSVGModelObject {
  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.phase != .EventRegion && paintInfo.context().paintingDisabled() {
      return
    }

    // Spec: groups w/o children still may render filter content.
    if firstChild() == nil && !selfWillPaint() {
      return
    }

    let repaintRect = repaintRectInLocalCoordinates()
    if !SVGRenderSupport.paintInfoIntersectsRepaintRect(
      repaintRect, localToParentTransform(), paintInfo)
    {
      return
    }

    var childPaintInfo = paintInfo.deepCopy()
    do {
      let _ = GraphicsContextStateSaver(context: childPaintInfo.context())

      // Let the LegacyRenderSVGViewportContainer subclass clip if necessary
      applyViewportClip(childPaintInfo)

      let transform = localToParentTransform()
      childPaintInfo.applyTransform(transform)
      if paintInfo.phase == .EventRegion && childPaintInfo.eventRegionContext() != nil {
        childPaintInfo.eventRegionContext()!.pushTransform(transform: transform)
      }

      let renderingContext = SVGRenderingContext()
      var continueRendering = true
      if childPaintInfo.phase == .Foreground {
        renderingContext.prepareToRenderSVGContent(self, childPaintInfo)
        continueRendering = renderingContext.isRenderingPrepared()
      }

      if continueRendering {
        childPaintInfo.updateSubtreePaintRootForChildren(renderer: self)
        for child: RenderElementWrapper in childrenOfType(parent: self) {
          child.paint(paintInfo: &childPaintInfo, paintOffset: LayoutPointWrapper())
        }
      }

      if paintInfo.phase == .EventRegion && childPaintInfo.eventRegionContext() != nil {
        childPaintInfo.eventRegionContext()!.popTransform()
      }
    }

    // FIXME: This really should be drawn from local coordinates, but currently we hack it
    // to avoid our clip killing our outline rect. Thus we translate our
    // outline rect into parent coords before drawing.
    // FIXME: This means our focus ring won't share our rotation like it should.
    // We should instead disable our clip during PaintPhase::Outline
    if paintInfo.phase == .SelfOutline && style().outlineWidth() != 0
      && style().usedVisibility() == .Visible
    {
      let paintRectInParent = enclosingIntRect(
        rect: localToParentTransform().mapRect(rect: repaintRect))
      paintOutline(paintInfo: paintInfo, paintRect: LayoutRectWrapper(rect: paintRectInParent))
    }
  }

  func didTransformToRootUpdate() -> Bool { return false }

  func isObjectBoundingBoxValid() -> Bool { return objectBoundingBoxValid }

  func isRepaintSuspendedForChildren() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    legacyRenderSVGContainerLayout()
  }

  func legacyRenderSVGContainerLayout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    // LegacyRenderSVGRoot disables paint offset cache for the SVG rendering tree.
    assert(!view().frameView().layoutContext().isPaintOffsetCacheEnabled())
    let _ = SetForScope(
      scopedVariable: &repaintIsSuspendedForChildrenDuringLayout,
      newValue: shouldSuspendRepaintForChildren(self))

    let checkForRepaintOverride =
      repaintIsSuspendedForChildrenDuringLayout || selfWillPaint()
      ? .Yes : SVGRenderSupport.checkForSVGRepaintDuringLayout(self)
    let shouldIssueFullRepaint: LayoutRepainter.ShouldAlwaysIssueFullRepaint =
      repaintIsSuspendedForChildrenDuringLayout ? .Yes : .No
    let repainter = LayoutRepainter(
      renderer: self, checkForRepaintOverride: checkForRepaintOverride,
      shouldAlwaysIssueFullRepaint: shouldIssueFullRepaint, repaintOutlineBounds: .No)

    // Allow LegacyRenderSVGViewportContainer to update its viewport.
    calcViewport()

    // Allow LegacyRenderSVGTransformableContainer to update its transform.
    let updatedTransform = calculateLocalTransform()

    // LegacyRenderSVGViewportContainer needs to set the 'layout size changed' flag.
    determineIfLayoutSizeChanged()

    SVGRenderSupport.layoutChildren(
      self, selfNeedsLayout() || SVGRenderSupport.filtersForceContainerLayout(self))

    // Invalidate all resources of this client if our layout changed.
    if everHadLayout() && needsLayout() {
      SVGResourcesCache.clientLayoutChanged(self)
    }

    // At this point LayoutRepainter already grabbed the old bounds,
    // recalculate them now so repaintAfterLayout() uses the new bounds.
    if needsBoundariesUpdate || updatedTransform {
      updateCachedBoundaries()
      needsBoundariesUpdate = false

      // New bounds can affect transforms, so recompute them here if needed.
      calculateLocalTransform()

      parent()?.invalidateCachedBoundaries()
    }

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    if repaintRectCalculation == .Fast {
      return repaintBoundingBox
    }

    if accurateRepaintBoundingBox == nil {
      // Initialize accurateRepaintBoundingBox before calling computeContainerBoundingBoxes, since recursively referenced markers can cause us to re-enter here.
      accurateRepaintBoundingBox = FloatRectWrapper()
      let bbs = SVGRenderSupport.computeContainerBoundingBoxes(self, .Accurate)
      var objectBoundingBoxValid = bbs.repaint
      SVGRenderSupport.intersectRepaintRectWithResources(self, &objectBoundingBoxValid, .Accurate)
      accurateRepaintBoundingBox = repaintBoundingBox
    }
    return accurateRepaintBoundingBox!
  }

  // Allow LegacyRenderSVGTransformableContainer to hook in at the right time in layout()
  @discardableResult
  func calculateLocalTransform() -> Bool { return false }

  // Allow RenderSVGViewportContainer to hook in at the right times in layout(), paint() and nodeAtFloatPoint()
  func calcViewport() {}

  func applyViewportClip(_ paintInfo: PaintInfoWrapper) {}

  func determineIfLayoutSizeChanged() {}

  private func selfWillPaint() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateCachedBoundaries() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let repaintBoundingBox = FloatRectWrapper()
  private var accurateRepaintBoundingBox: FloatRectWrapper? = nil

  private let objectBoundingBoxValid = false
  private var needsBoundariesUpdate = true
  private var repaintIsSuspendedForChildrenDuringLayout = false
}
