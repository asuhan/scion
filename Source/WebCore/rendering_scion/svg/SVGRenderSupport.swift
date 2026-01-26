/*
 * Copyright (C) 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.  All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2018 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

// SVGRendererSupport is a helper class sharing code between all SVG renderers.
class SVGRenderSupport {
  // Helper function determining wheter overflow is hidden
  static func isOverflowHidden(_ renderer: RenderElementWrapper) -> Bool {
    // LegacyRenderSVGRoot should never query for overflow state - it should always clip itself to the initial viewport size.
    assert(!renderer.isDocumentElementRenderer())

    return isNonVisibleOverflow(renderer.style().overflowX())
  }

  // Important functions used by nearly all SVG renderers centralizing coordinate transformations / repaint rect calculations
  static func clippedOverflowRectForRepaint(
    _ renderer: RenderElementWrapper, _ repaintContainer: RenderLayerModelObjectWrapper?,
    _ context: RenderObjectWrapper.VisibleRectContext
  ) -> LayoutRectWrapper {
    // Return early for any cases where we don't actually paint
    if renderer.isInsideEntirelyHiddenLayer() {
      return LayoutRectWrapper()
    }

    // Pass our local paint rect to computeFloatVisibleRectInContainer() which will
    // map to parent coords and recurse up the parent chain.
    return enclosingLayoutRect(
      rect: renderer.computeFloatRectForRepaint(
        renderer.repaintRectInLocalCoordinates(context.repaintRectCalculation()), repaintContainer))
  }

  static func checkForSVGRepaintDuringLayout(_ renderer: RenderElementWrapper)
    -> LayoutRepainter.CheckForRepaint
  {
    if !renderer.checkForRepaintDuringLayout() {
      return .No
    }
    // When a parent container is transformed in SVG, all children will be painted automatically
    // so we are able to skip redundant repaint checks.
    if let parent = renderer.parent() as? LegacyRenderSVGContainer,
      parent.isRepaintSuspendedForChildren() || parent.didTransformToRootUpdate()
    {
      return .No
    }
    return .Yes
  }

  static func calculateApproximateStrokeBoundingBox(_ renderer: RenderElementWrapper)
    -> FloatRectWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func styleChanged(renderer: RenderElementWrapper, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func findTreeRootObject(start: RenderElementWrapper) -> LegacyRenderSVGRootWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
