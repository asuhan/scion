/*
 * Copyright (C) 2006 Apple Inc.
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

final class LegacyRenderSVGForeignObjectWrapper: RenderSVGBlockWrapper {
  private func foreignObjectElement() -> SVGForeignObjectElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.context().paintingDisabled() {
      return
    }

    if paintInfo.phase != .Foreground && paintInfo.phase != .Selection {
      return
    }

    var childPaintInfo = paintInfo.deepCopy()
    let unused = GraphicsContextStateSaver(context: childPaintInfo.context())
    use(unused)
    childPaintInfo.applyTransform(localTransform())

    if SVGRenderSupport.isOverflowHidden(self) {
      childPaintInfo.context().clip(rect: viewport)
    }

    let renderingContext = SVGRenderingContext()
    if paintInfo.phase == .Foreground {
      renderingContext.prepareToRenderSVGContent(self, childPaintInfo)
      if !renderingContext.isRenderingPrepared() {
        return
      }
    }

    let childPoint = LayoutPointWrapper(point: IntPoint())
    if paintInfo.phase == .Selection {
      super.paint(paintInfo: &childPaintInfo, paintOffset: childPoint)
      return
    }

    // Paint all phases of FO elements atomically, as though the FO element established its
    // own stacking context.
    childPaintInfo.phase = .BlockBackground
    super.paint(paintInfo: &childPaintInfo, paintOffset: childPoint)
    childPaintInfo.phase = .ChildBlockBackgrounds
    super.paint(paintInfo: &childPaintInfo, paintOffset: childPoint)
    childPaintInfo.phase = .Float
    super.paint(paintInfo: &childPaintInfo, paintOffset: childPoint)
    childPaintInfo.phase = .Foreground
    super.paint(paintInfo: &childPaintInfo, paintOffset: childPoint)
    childPaintInfo.phase = .Outline
    super.paint(paintInfo: &childPaintInfo, paintOffset: childPoint)
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())
    assert(!view().frameView().layoutContext().isPaintOffsetCacheEnabled())  // LegacyRenderSVGRoot disables paint offset cache for the SVG rendering tree.

    let repainter = LayoutRepainter(
      renderer: self, checkForRepaintOverride: SVGRenderSupport.checkForSVGRepaintDuringLayout(self)
    )

    var updateCachedBoundariesInParents = false
    if needsTransformUpdate {
      m_localTransform = foreignObjectElement().animatedLocalTransform()
      needsTransformUpdate = false
      updateCachedBoundariesInParents = true
    }

    let oldViewport = viewport

    // Cache viewport boundaries
    let foreignObjectElement = foreignObjectElement()
    let lengthContext = SVGLengthContext(context: foreignObjectElement)
    let viewportLocation = FloatPoint(
      x: foreignObjectElement.x().value(lengthContext),
      y: foreignObjectElement.y().value(lengthContext))
    viewport = FloatRectWrapper(
      location: viewportLocation,
      size: FloatSize(
        width: foreignObjectElement.width().value(lengthContext),
        height: foreignObjectElement.height().value(lengthContext)))
    if !updateCachedBoundariesInParents {
      updateCachedBoundariesInParents = oldViewport != viewport
    }

    // Set box origin to the foreignObject x/y translation, so positioned objects in XHTML content get correct
    // positions. A regular RenderBoxModelObject would pull this information from RenderStyle - in SVG those
    // properties are ignored for non <svg> elements, so we mimic what happens when specifying them through CSS.

    // FIXME: Investigate in location rounding issues - only affects LegacyRenderSVGForeignObject & RenderSVGText
    setLocation(p: LayoutPointWrapper(point: roundedIntPoint(viewportLocation)))

    let layoutChanged = everHadLayout() && selfNeedsLayout()
    super.layout()
    assert(!needsLayout())

    // If our bounds changed, notify the parents.
    if updateCachedBoundariesInParents, let parent = parent() {
      parent.invalidateCachedBoundaries()
    }

    // Invalidate all resources of this client if our layout changed.
    if layoutChanged {
      SVGResourcesCache.clientLayoutChanged(self)
    }

    repainter.repaintAfterLayout()
  }

  override func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setNeedsTransformUpdate() { needsTransformUpdate = true }

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

  override func localToParentTransform() -> AffineTransform {
    assert(isNativeImpl())
    m_localToParentTransform = localTransform()
    m_localToParentTransform.translate(viewport.location())
    return m_localToParentTransform
  }

  override func localTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func offsetFromContainer(
    _ container: RenderElementWrapper, _ physicalPoint: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    assert(CPtrToInt(container.id()) == CPtrToInt(self.container()?.id()))
    assert(!isInFlowPositioned())
    assert(!isAbsolutelyPositioned())
    assert(!isInline())
    return locationOffset()
  }

  private var m_localTransform = AffineTransform()
  private var m_localToParentTransform = AffineTransform()
  private var viewport = FloatRectWrapper()
  private var needsTransformUpdate = true
}
