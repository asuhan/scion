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
  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.context().paintingDisabled() {
      return
    }

    if paintInfo.phase != .Foreground && paintInfo.phase != .Selection {
      return
    }

    var childPaintInfo = paintInfo.deepCopy()
    let _ = GraphicsContextStateSaver(context: childPaintInfo.context())
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let viewport = FloatRectWrapper()
  private var needsTransformUpdate = true
}
