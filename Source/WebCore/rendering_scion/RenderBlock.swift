/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

import wk_interop

class RenderBlockWrapper: RenderBoxWrapper {
  func containsFloats() -> Bool {
    return wk_interop.RenderBlock_containsFloats(p)
  }

  func addContinuationWithOutline(flow: RenderInlineWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Fieldset legends that are taller than the fieldset border add in intrinsic border
  // in order to ensure that content gets properly pushed down across all layout systems
  // (flexbox, block, etc.)
  func intrinsicBorderForFieldset() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBlock_intrinsicBorderForFieldset(p))
  }

  func paintExcludedChildrenInBorder(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintObject(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    let paintPhase = paintInfo.phase

    // 1. paint background, borders etc
    if (paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground)
      && style().usedVisibility() == .Visible
    {
      if hasVisibleBoxDecorations() {
        paintBoxDecorations(paintInfo: paintInfo, paintOffset: paintOffset)
      }
      paintDebugBoxShadowIfApplicable(
        context: paintInfo.context(),
        paintRect: LayoutRectWrapper(location: paintOffset, size: size()))
    }

    // Paint legends just above the border before we scroll or clip.
    if paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground
      || paintPhase == .Selection
    {
      paintExcludedChildrenInBorder(paintInfo: paintInfo, paintOffset: paintOffset)
    }

    if paintPhase == .Mask && style().usedVisibility() == .Visible {
      paintMask(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    if paintPhase == .ClippingMask && style().usedVisibility() == .Visible {
      paintClippingMask(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    // If just painting the root background, then return.
    if paintInfo.paintRootBackgroundOnly() {
      return
    }

    if paintPhase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(renderBox: self, paintOffset: paintOffset)
    }

    if paintPhase == .EventRegion {
      let borderRect = LayoutRectWrapper(location: paintOffset, size: size())

      if paintInfo.paintBehavior.contains(.EventRegionIncludeBackground) && visibleToHitTesting() {
        let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: borderRect)
        let overrideUserModifyIsEditable =
          isRenderTextControl()
          && (self as! RenderTextControlWrapper).textFormControlElement()
            .isInnerTextElementEditable()
        paintInfo.eventRegionContext()!.unite(
          roundedRect: borderShape.deprecatedPixelSnappedRoundedRect(
            deviceScaleFactor: document().deviceScaleFactor()), renderer: self,
          style: style(), overrideUserModifyIsEditable: overrideUserModifyIsEditable)
      }

      if !paintInfo.paintBehavior.contains(.EventRegionIncludeForeground) {
        return
      }

      let needsTraverseDescendants =
        hasVisualOverflow() || containsFloats()
        || !paintInfo.eventRegionContext()!.contains(rect: enclosingIntRect(rect: borderRect))
        || view().needsEventRegionUpdateForNonCompositedFrame()

      if !needsTraverseDescendants {
        return
      }
    }

    // Adjust our painting position if we're inside a scrolled layer (e.g., an overflow:auto div).
    var scrolledOffset = paintOffset
    scrolledOffset.moveBy(offset: LayoutPointWrapper(point: -scrollPosition()))

    // Column rules need to account for scrolling and clipping.
    // FIXME: Clipping of column rules does not work. We will need a separate paint phase for column rules I suspect in order to get
    // clipping correct (since it has to paint as background but is still considered "contents").
    if (paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground)
      && style().usedVisibility() == .Visible
    {
      paintColumnRules(paintInfo: paintInfo, point: scrolledOffset)
    }

    // Done with backgrounds, borders and column rules.
    if paintPhase == .BlockBackground {
      return
    }

    // 2. paint contents
    if paintPhase != .SelfOutline {
      paintContents(paintInfo: paintInfo, paintOffset: scrolledOffset)
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintContents(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintColumnRules(paintInfo: PaintInfoWrapper, point: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintDebugBoxShadowIfApplicable(
    context: GraphicsContextWrapper, paintRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var floatingObjectSet: FloatingObjectSet? = nil
}
