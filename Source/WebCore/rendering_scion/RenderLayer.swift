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

private func isContainerForPositioned(
  layer: RenderLayerWrapper, position: PositionType, establishesTopLayer: Bool
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private enum TransparencyClipBoxBehavior {
  case PaintingTransparencyClipBox
  case HitTestingTransparencyClipBox
}

private enum TransparencyClipBoxMode {
  case DescendantsOfTransparencyClipBox
  case RootOfTransparencyClipBox
}

private func transparencyClipBox(
  layer: RenderLayerWrapper, rootLayer: RenderLayerWrapper?,
  transparencyBehavior: TransparencyClipBoxBehavior, transparencyMode: TransparencyClipBoxMode,
  paintBehavior: PaintBehavior = [], paintDirtyRect: LayoutRectWrapper? = nil
)
  -> LayoutRectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

  func parent() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // isStackingContext is true for layers that we've determined should be stacking contexts for painting.
  // Not all stacking contexts are CSS stacking contexts.
  func isStackingContext() -> Bool {
    return isCSSStackingContext() || isOpportunisticStackingContext
  }

  // isCSSStackingContext is true for layers that are stacking contexts from a CSS perspective.
  // isCSSStackingContext() => isStackingContext().
  // FIXME: m_forcedStackingContext should affect isStackingContext(), not isCSSStackingContext(), but doing so breaks media control mix-blend-mode.
  func isCSSStackingContext() -> Bool {
    return self.m_isCSSStackingContext || self.forcedStackingContext
  }

  func location() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> IntSize {
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

  func ancestorLayerIsInContainingBlockChain(
    ancestor: RenderLayerWrapper, checkLimit: RenderLayerWrapper? = nil
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum ColumnOffsetAdjustment {
    case DontAdjustForColumns
    case AdjustForColumns
  }

  // Returns the layer reached on the walk up towards the ancestor.
  private static func accumulateOffsetTowardsAncestor(
    layer: RenderLayerWrapper, ancestorLayer: RenderLayerWrapper?,
    location: inout LayoutPointWrapper,
    adjustForColumns: RenderLayerWrapper.ColumnOffsetAdjustment
  ) -> RenderLayerWrapper? {
    assert(CPtrToInt(ancestorLayer?.p) != CPtrToInt(layer.p))

    let renderer = layer.renderer()
    let position = renderer.style().position()

    // FIXME: Positioning of out-of-flow(fixed, absolute) elements collected in a RenderFragmentedFlow
    // may need to be revisited in a future patch.
    // If the fixed renderer is inside a RenderFragmentedFlow, we should not compute location using localToAbsolute,
    // since localToAbsolute maps the coordinates from named flow to regions coordinates and regions can be
    // positioned in a completely different place in the viewport (RenderView).
    if position == .Fixed
      && (ancestorLayer == nil
        || CPtrToInt(ancestorLayer?.p) == CPtrToInt(renderer.view().layer()?.p))
    {
      // If the fixed layer's container is the root, just add in the offset of the view. We can obtain this by calling
      // localToAbsolute() on the RenderView.
      location.moveBy(
        offset: LayoutPointWrapper(
          size: renderer.localToAbsolute(localPoint: FloatPoint(), mode: .IsFixed)))
      return ancestorLayer
    }

    // For the fixed positioned elements inside a render flow thread, we should also skip the code path below
    // Otherwise, for the case of ancestorLayer == rootLayer and fixed positioned element child of a transformed
    // element in render flow thread, we will hit the fixed positioned container before hitting the ancestor layer.
    if position == .Fixed {
      // For a fixed layers, we need to walk up to the root to see if there's a fixed position container
      // (e.g. a transformed layer). It's an error to call offsetFromAncestor() across a layer with a transform,
      // so we should always find the ancestor at or before we find the fixed position container, if
      // the container is transformed.
      var fixedPositionContainerLayer: RenderLayerWrapper? = nil
      var foundAncestor = false
      var currLayer: RenderLayerWrapper? = layer.parent()
      while currLayer != nil {
        if CPtrToInt(currLayer?.p) == CPtrToInt(ancestorLayer?.p) {
          foundAncestor = true
        }

        if isContainerForPositioned(
          layer: currLayer!, position: .Fixed, establishesTopLayer: layer.establishesTopLayer())
        {
          fixedPositionContainerLayer = currLayer
          // A layer that has a transform-related property but not a
          // transform still acts as a fixed-position container.
          // Accumulating offsets across such layers is allowed.
          if currLayer!.transform() != nil {
            assert(foundAncestor)
          }
          break
        }
        currLayer = currLayer!.parent()
      }

      assert(fixedPositionContainerLayer != nil)  // We should have hit the RenderView's layer at least.

      if CPtrToInt(fixedPositionContainerLayer!.p) != CPtrToInt(ancestorLayer?.p) {
        let fixedContainerCoords = layer.offsetFromAncestor(
          ancestorLayer: fixedPositionContainerLayer)
        let ancestorCoords =
          foundAncestor
          ? ancestorLayer!.offsetFromAncestor(ancestorLayer: fixedPositionContainerLayer)
          : LayoutSizeWrapper()
        location.move(s: fixedContainerCoords - ancestorCoords)
        return foundAncestor ? ancestorLayer : fixedPositionContainerLayer
      }

      assert(ancestorLayer != nil)
      if CPtrToInt(ancestorLayer!.p) == CPtrToInt(renderer.view().layer()?.p) {
        // Add location in flow thread coordinates.
        location.moveBy(offset: layer.location())

        // Add flow thread offset in view coordinates since the view may be scrolled.
        location.moveBy(
          offset: LayoutPointWrapper(
            size: renderer.view().localToAbsolute(localPoint: FloatPoint(), mode: .IsFixed)))
        return ancestorLayer
      }
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func convertToLayerCoords(
    ancestorLayer: RenderLayerWrapper?, location: LayoutPointWrapper,
    adjustForColumns: ColumnOffsetAdjustment = .DontAdjustForColumns
  )
    -> LayoutPointWrapper
  {
    if CPtrToInt(ancestorLayer?.p) == CPtrToInt(p) {
      return location
    }

    var currLayer: RenderLayerWrapper? = self
    var locationInLayerCoords = location
    while currLayer != nil && CPtrToInt(currLayer?.p) != CPtrToInt(ancestorLayer?.p) {
      currLayer = RenderLayerWrapper.accumulateOffsetTowardsAncestor(
        layer: currLayer!, ancestorLayer: ancestorLayer, location: &locationInLayerCoords,
        adjustForColumns: adjustForColumns)
    }

    // Pixel snap the whole SVG subtree as one "block" -- not individual layers down the SVG render tree.
    if renderer().isRenderSVGRoot() {
      return LayoutPointWrapper(
        size: roundPointToDevicePixels(
          point: locationInLayerCoords,
          pixelSnappingFactor: renderer().document().deviceScaleFactor()))
    }

    return locationInLayerCoords
  }

  func offsetFromAncestor(
    ancestorLayer: RenderLayerWrapper?,
    adjustForColumns: ColumnOffsetAdjustment = .DontAdjustForColumns
  ) -> LayoutSizeWrapper {
    return toLayoutSize(
      point: convertToLayerCoords(
        ancestorLayer: ancestorLayer, location: LayoutPointWrapper(),
        adjustForColumns: adjustForColumns))
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

  // Note that this transform has the transform-origin baked in.
  func transform() -> TransformationMatrix? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTransformedAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBlendMode() -> Bool {
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

  func paintsWithTransparency(paintBehavior: PaintBehavior) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // If we will only draw a single item, then we can just apply
  // opacity to the drawing context rather than pushing a transparency
  // layer. This currently only detects a single bitmap image, but could
  // be extended to handle other cases.
  func canPaintTransparencyWithSetOpacity() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func establishesTopLayer() -> Bool {
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
    let deviceScaleFactor = renderer().document().deviceScaleFactor()
    let needsClipping = !clipRect.isInfinite() && clipRect.rect != paintingInfo.paintDirtyRect
    if needsClipping || clipRect.affectedByRadius {
      stateSaver.save()
    }

    if needsClipping {
      var adjustedClipRect = clipRect.rect
      adjustedClipRect.move(size: paintingInfo.subpixelOffset)
      let snappedClipRect = snapRectToDevicePixelsIfNeeded(
        rect: adjustedClipRect, renderer: renderer())
      context.clip(rect: snappedClipRect)
      regionContextStateSaver.pushClip(clipRect: enclosingIntRect(rect: snappedClipRect))
    }

    if clipRect.affectedByRadius {
      // If the clip rect has been tainted by a border radius, then we have to walk up our layer chain applying the clips from
      // any layers with overflow. The condition for being able to apply these clips is that the overflow object be in our
      // containing block chain so we check that also.
      var layer: RenderLayerWrapper? = rule == .IncludeSelfForBorderRadius ? self : parent()
      while layer != nil {
        if paintBehavior.contains(.CompositedOverflowScrollContent)
          && layer!.usesCompositedScrolling()
        {
          break
        }

        if layer!.renderer().hasNonVisibleOverflow() && layer!.renderer().style().hasBorderRadius()
          && ancestorLayerIsInContainingBlockChain(ancestor: layer!)
        {
          var adjustedClipRect = LayoutRectWrapper(
            location: toLayoutPoint(
              size: layer!.offsetFromAncestor(
                ancestorLayer: paintingInfo.rootLayer, adjustForColumns: .AdjustForColumns)),
            size: LayoutSizeWrapper(size: layer!.size()))
          adjustedClipRect.move(size: paintingInfo.subpixelOffset)
          let borderShape = BorderShape.shapeForBorderRect(
            style: layer!.renderer().style(), borderRect: adjustedClipRect)
          if borderShape.innerShapeContains(rect: paintingInfo.paintDirtyRect) {
            context.clip(
              rect: snapRectToDevicePixels(
                rect: intersection(a: paintingInfo.paintDirtyRect, b: adjustedClipRect),
                pixelSnappingFactor: deviceScaleFactor))
          } else {
            borderShape.clipToInnerShape(context: context, deviceScaleFactor: deviceScaleFactor)
          }
        }

        if CPtrToInt(layer!.p) == CPtrToInt(paintingInfo.rootLayer?.p) {
          break
        }

        layer = layer!.parent()
      }
    }
  }

  private func rendererLocation() -> LayoutPointWrapper {
    if let box = renderer() as? RenderBoxWrapper {
      return box.location()
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.currentSVGLayoutLocation()
    }
    return LayoutPointWrapper()
  }

  private func paintForegroundForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    contextForTransparencyLayer: GraphicsContextWrapper,
    transparencyPaintDirtyRect: LayoutRectWrapper, haveTransparency: Bool,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    // Begin transparency if we have something to paint.
    if haveTransparency {
      for fragment in layerFragments {
        if fragment.shouldPaintContent && !fragment.foregroundRect.isEmpty() {
          beginTransparencyLayers(
            context: contextForTransparencyLayer, paintingInfo: localPaintingInfo,
            dirtyRect: transparencyPaintDirtyRect)
          break
        }
      }
    }

    var localPaintBehavior = PaintBehavior()
    if localPaintingInfo.paintBehavior.contains(.ForceBlackText) {
      localPaintBehavior = PaintBehavior.ForceBlackText
    } else if localPaintingInfo.paintBehavior.contains(.ForceWhiteText) {
      localPaintBehavior = PaintBehavior.ForceWhiteText
    } else {
      localPaintBehavior = paintBehavior
    }

    // FIXME: It's unclear if this flag copying is necessary.
    let flagsToCopy = PaintBehavior([
      .ExcludeSelection, .Snapshotting, .DefaultAsynchronousImageDecode,
      .CompositedOverflowScrollContent, .ForceSynchronousImageDecode, .ExcludeReplacedContent,
    ])
    localPaintBehavior = localPaintBehavior.union(
      localPaintingInfo.paintBehavior.intersection(flagsToCopy))

    if localPaintingInfo.paintBehavior.contains(.DontShowVisitedLinks) {
      localPaintBehavior.update(with: .DontShowVisitedLinks)
    }

    let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
    let regionContextStateSaver = RegionContextStateSaver(context: localPaintingInfo.regionContext)

    // Optimize clipping for the single fragment case.
    let shouldClip =
      localPaintingInfo.clipToDirtyRect && layerFragments.count == 1
      && layerFragments[0].shouldPaintContent && !layerFragments[0].foregroundRect.isEmpty()
    if shouldClip {
      clipToRect(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        clipRect: layerFragments[0].foregroundRect)
    }

    // We have to loop through every fragment multiple times, since we have to repaint in each specific phase in order for
    // interleaving of the fragments to work properly.
    let selectionOnly = localPaintingInfo.paintBehavior.contains(.SelectionOnly)
    let selectionAndBackgroundsOnly = localPaintingInfo.paintBehavior.contains(
      .SelectionAndBackgroundsOnly)

    if (renderer() is RenderSVGModelObjectWrapper) && !(renderer() is RenderSVGContainerWrapper) {
      // SVG containers need to propagate paint phases. This could be saved if we remember somewhere if a SVG subtree
      // contains e.g. LegacyRenderSVGForeignObject objects that do need the individual paint phases. For SVG shapes & SVG images
      // we can avoid the multiple paintForegroundForFragmentsWithPhase() calls.
      if selectionOnly || selectionAndBackgroundsOnly {
        return
      }
      paintForegroundForFragmentsWithPhase(
        phase: .Foreground, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      return
    }

    if !selectionOnly {
      paintForegroundForFragmentsWithPhase(
        phase: .ChildBlockBackgrounds, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
    }

    if selectionOnly || selectionAndBackgroundsOnly {
      paintForegroundForFragmentsWithPhase(
        phase: .Selection, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
    } else {
      paintForegroundForFragmentsWithPhase(
        phase: .Float, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      paintForegroundForFragmentsWithPhase(
        phase: .Foreground, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      paintForegroundForFragmentsWithPhase(
        phase: .ChildOutlines, layerFragments: layerFragments, context: context,
        localPaintingInfo: localPaintingInfo, paintBehavior: localPaintBehavior,
        subtreePaintRootForRenderer: subtreePaintRootForRenderer)
    }
  }

  private func paintForegroundForFragmentsWithPhase(
    phase: PaintPhase, layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
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

  private func transparentPaintingAncestor(info: LayerPaintingInfo) -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func beginTransparencyLayers(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, dirtyRect: LayoutRectWrapper
  ) {
    if context.paintingDisabled()
      || (paintsWithTransparency(paintBehavior: paintingInfo.paintBehavior) && usedTransparency)
    {
      return
    }

    if let ancestor = transparentPaintingAncestor(info: paintingInfo) {
      ancestor.beginTransparencyLayers(
        context: context, paintingInfo: paintingInfo, dirtyRect: dirtyRect)
    }

    if paintsWithTransparency(paintBehavior: paintingInfo.paintBehavior) {
      assert(isStackingContext())
      usedTransparency = true
      if canPaintTransparencyWithSetOpacity() {
        savedAlphaForTransparency = context.alpha()
        context.setAlpha(alpha: context.alpha() * renderer().opacity())
        return
      }
      context.save()
      var adjustedClipRect = transparencyClipBox(
        layer: self, rootLayer: paintingInfo.rootLayer,
        transparencyBehavior: .PaintingTransparencyClipBox,
        transparencyMode: .RootOfTransparencyClipBox,
        paintBehavior: paintingInfo.paintBehavior, paintDirtyRect: dirtyRect)
      adjustedClipRect.move(size: paintingInfo.subpixelOffset)
      let snappedClipRect = snapRectToDevicePixelsIfNeeded(
        rect: adjustedClipRect, renderer: renderer())
      context.clip(rect: snappedClipRect)

      let usesCompositeOperation =
        hasBlendMode()
        && !(renderer().isLegacyRenderSVGRoot() && parent() != nil && parent()!.isRenderViewLayer)
      if usesCompositeOperation {
        context.setCompositeOperation(operation: context.compositeOperation(), blendMode: blendMode)
      }

      context.beginTransparencyLayer(opacity: renderer().opacity())

      if usesCompositeOperation {
        context.setCompositeOperation(operation: context.compositeOperation(), blendMode: .Normal)
      }
    }
  }

  private let p: UnsafeMutableRawPointer
  // Native fields below.

  private var savedAlphaForTransparency: Float32? = nil

  private var isRenderViewLayer = false
  private var forcedStackingContext = false
  private var isOpportunisticStackingContext = false

  private var m_isCSSStackingContext = false

  // Tracks whether we need to close a transparent layer, i.e., whether
  // we ended up painting this layer or any descendants (and therefore need to
  // blend).
  private var usedTransparency = false

  private var blendMode: BlendMode = .Normal
}
