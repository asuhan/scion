/*
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
 * Copyright (c) 2020 Igalia S.L.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

import wk_interop

private enum BorderRadiusClippingRule {
  case IncludeSelfForBorderRadius
  case DoNotIncludeSelfForBorderRadius
}

class RenderLayerWrapper {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  func scrollableArea() -> RenderLayerScrollableArea? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func renderer() -> RenderLayerModelObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollWidth() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func staticInlinePosition() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderLayer_staticInlinePosition(p))
  }

  func staticBlockPosition() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderLayer_staticBlockPosition(p))
  }

  func setStaticInlinePosition(position: LayoutUnit) {
    wk_interop.RenderLayer_setStaticInlinePosition(p, position.rawValue())
  }

  func setStaticBlockPosition(position: LayoutUnit) {
    wk_interop.RenderLayer_setStaticBlockPosition(p, position.rawValue())
  }

  func hasTransformedAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasCompositedMask() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usesCompositedScrolling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsHiddenByOverflowTruncation(isHidden: Bool) {
    wk_interop.RenderLayer_setIsHiddenByOverflowTruncation(p, isHidden)
  }

  private struct LayerPaintingInfo {
    init(
      inRootLayer: RenderLayerWrapper?, inDirtyRect: LayoutRectWrapper,
      inPaintBehavior: PaintBehavior, inSubpixelOffset: LayoutSizeWrapper,
      inSubtreePaintRoot: RenderObjectWrapper? = nil,
      inOverlapTestRequests: OverlapTestRequestMap? = nil,
      inRequireSecurityOriginAccessForWidgets: Bool = false
    ) {
      self.rootLayer = inRootLayer
      self.subtreePaintRoot = inSubtreePaintRoot
      self.paintDirtyRect = inDirtyRect
      self.subpixelOffset = inSubpixelOffset
      self.overlapTestRequests = inOverlapTestRequests
      self.paintBehavior = inPaintBehavior
      self.requireSecurityOriginAccessForWidgets = inRequireSecurityOriginAccessForWidgets
    }

    let rootLayer: RenderLayerWrapper?
    let subtreePaintRoot: RenderObjectWrapper?  // Only paint descendants of this object.
    let paintDirtyRect: LayoutRectWrapper  // Relative to rootLayer;
    let subpixelOffset: LayoutSizeWrapper
    let overlapTestRequests: OverlapTestRequestMap?
    let paintBehavior: PaintBehavior
    let requireSecurityOriginAccessForWidgets: Bool
    let clipToDirtyRect: Bool = true
    let regionContext: RegionContext? = nil
  }

  private func paintOffsetForRenderer(
    fragment: LayerFragment, paintingInfo: LayerPaintingInfo
  ) -> LayoutPointWrapper {
    return toLayoutPoint(
      size: fragment.layerBounds.location() - rendererLocation() + paintingInfo.subpixelOffset)
  }

  private func clipToRect(
    context: GraphicsContextWrapper, stateSaver: GraphicsContextStateSaver,
    regionContextStateSaver: RegionContextStateSaver, paintingInfo: LayerPaintingInfo,
    paintBehavior: PaintBehavior, clipRect: ClipRect,
    rule: BorderRadiusClippingRule = .IncludeSelfForBorderRadius
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func rendererLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintForegroundForFragmentsWithPhase(
    phase: PaintPhase, layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper
  ) {
    let shouldClip = localPaintingInfo.clipToDirtyRect && layerFragments.count > 1

    for fragment in layerFragments {
      if !fragment.shouldPaintContent || fragment.foregroundRect.isEmpty() {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if shouldClip {
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior, clipRect: fragment.foregroundRect)
      }

      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.foregroundRect.rect, newPhase: phase,
        newPaintBehavior: paintBehavior, newSubtreePaintRoot: subtreePaintRootForRenderer,
        newOutlineObjects: nil, overlapTestRequests: nil,
        newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self,
        newRequireSecurityOriginAccessForWidgets: localPaintingInfo
          .requireSecurityOriginAccessForWidgets)
      if phase == .Foreground {
        paintInfo.overlapTestRequests = localPaintingInfo.overlapTestRequests
      }
      renderer().paint(
        paintInfo: paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private let p: UnsafeMutableRawPointer
}
