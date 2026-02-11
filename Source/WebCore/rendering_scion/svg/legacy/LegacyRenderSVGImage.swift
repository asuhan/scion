/*
 * Copyright (C) 2006 Alexander Kellett <lypanov@kde.org>
 * Copyright (C) 2006, 2009 Apple Inc.
 * Copyright (C) 2007 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007, 2008, 2009 Rob Buis <buis@kde.org>
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
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

final class LegacyRenderSVGImageWrapper: LegacyRenderSVGModelObject {
  private func imageElement() -> SVGImageElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  private func updateImageViewport() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setNeedsTransformUpdate() { needsTransformUpdate = true }

  // Note: Assumes the PaintInfo context has had all local transforms applied.
  func paintForeground(_ paintInfo: PaintInfoWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localToParentTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    let checkForRepaintOverride =
      !selfNeedsLayout() ? .No : SVGRenderSupport.checkForSVGRepaintDuringLayout(self)
    let repainter = LayoutRepainter(
      renderer: self, checkForRepaintOverride: checkForRepaintOverride,
      shouldAlwaysIssueFullRepaint: nil, repaintOutlineBounds: .No)
    updateImageViewport()

    let transformOrBoundariesUpdate = needsTransformUpdate || needsBoundariesUpdate
    if needsTransformUpdate {
      m_localTransform = imageElement().animatedLocalTransform()
      needsTransformUpdate = false
    }

    if needsBoundariesUpdate {
      repaintBoundingBox = m_objectBoundingBox
      SVGRenderSupport.intersectRepaintRectWithResources(self, &repaintBoundingBox)
      needsBoundariesUpdate = false
    }

    // Invalidate all resources of this client if our layout changed.
    if everHadLayout() && selfNeedsLayout() {
      SVGResourcesCache.clientLayoutChanged(self)
    }

    // If our bounds changed, notify the parents.
    if transformOrBoundariesUpdate, let parent = parent() {
      parent.invalidateCachedBoundaries()
    }

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.context().paintingDisabled() || paintInfo.phase != .Foreground
      || style().usedVisibility() == .Hidden || imageResource.cachedImage() == nil
    {
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
        if style().svgStyle().bufferedRendering() == .Static
          && renderingContext.bufferForeground(bufferedForeground)
        {
          return
        }

        paintForeground(childPaintInfo)
      }
    }

    if style().outlineWidth() != 0 {
      paintOutline(
        paintInfo: childPaintInfo, paintRect: LayoutRectWrapper(rect: IntRect(boundingBox)))
    }
  }

  override func localTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var needsBoundariesUpdate = false
  private var needsTransformUpdate = true
  private var m_localTransform = AffineTransform()
  private let m_objectBoundingBox = FloatRectWrapper()
  private var repaintBoundingBox = FloatRectWrapper()
  private let imageResource = RenderImageResource()
  private let bufferedForeground: ImageBufferWrapper? = nil
}
