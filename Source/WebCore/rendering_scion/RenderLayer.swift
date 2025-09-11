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
  if establishesTopLayer {
    return layer.isRenderViewLayer
  }

  switch position {
  case .Fixed:
    return layer.renderer().canContainFixedPositionObjects()

  case .Absolute:
    return layer.renderer().canContainAbsolutelyPositionedObjects()

  default:
    fatalError("Not reached")
  }
}

private enum TransparencyClipBoxBehavior {
  case PaintingTransparencyClipBox
  case HitTestingTransparencyClipBox
}

private enum TransparencyClipBoxMode {
  case DescendantsOfTransparencyClipBox
  case RootOfTransparencyClipBox
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

  func renderBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parent() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSibling() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstChild() -> RenderLayerWrapper? {
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

  func isTransparent() -> Bool { return renderer().isTransparent() || renderer().hasMask() }

  func isReflectionLayer(layer: RenderLayerWrapper) -> Bool {
    if let reflection = reflection {
      return CPtrToInt(layer.p) == CPtrToInt(reflection.layer()?.p)
    }
    return false
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

  enum PaginationInclusionMode {
    case ExcludeCompositedPaginatedLayers
    case IncludeCompositedPaginatedLayers
  }

  func enclosingPaginationLayer(mode: PaginationInclusionMode) -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisibleBoxDecorationsOrBackground() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ancestorLayerIsInContainingBlockChain(
    ancestor: RenderLayerWrapper, checkLimit: RenderLayerWrapper? = nil
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Gets the nearest enclosing positioned ancestor layer (also includes
  // the <html> layer and the root layer).
  func enclosingAncestorForPosition(position: PositionType) -> RenderLayerWrapper? {
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

    var parentLayer: RenderLayerWrapper? = nil
    if position == .Absolute || position == .Fixed {
      // Do what enclosingAncestorForPosition() does, but check for ancestorLayer along the way.
      parentLayer = layer.parent()
      var foundAncestorFirst = false
      while parentLayer != nil {
        // RenderFragmentedFlow is a positioned container, child of RenderView, positioned at (0,0).
        // This implies that, for out-of-flow positioned elements inside a RenderFragmentedFlow,
        // we are bailing out before reaching root layer.
        if isContainerForPositioned(
          layer: parentLayer!, position: position, establishesTopLayer: layer.establishesTopLayer())
        {
          break
        }

        if CPtrToInt(parentLayer?.p) == CPtrToInt(ancestorLayer?.p) {
          foundAncestorFirst = true
          break
        }

        parentLayer = parentLayer!.parent()
      }

      // We should not reach RenderView layer past the RenderFragmentedFlow layer for any
      // children of the RenderFragmentedFlow.
      if renderer.enclosingFragmentedFlow() != nil {
        assert(CPtrToInt(parentLayer?.p) != CPtrToInt(renderer.view().layer()?.p))
      }

      if foundAncestorFirst {
        // Found ancestorLayer before the abs. positioned container, so compute offset of both relative
        // to enclosingAncestorForPosition and subtract.
        let positionedAncestor = parentLayer!.enclosingAncestorForPosition(position: position)
        let thisCoords = layer.offsetFromAncestor(ancestorLayer: positionedAncestor)
        let ancestorCoords = ancestorLayer!.offsetFromAncestor(ancestorLayer: positionedAncestor)
        location.move(s: thisCoords - ancestorCoords)
        return ancestorLayer
      }
    } else {
      parentLayer = layer.parent()
    }

    if parentLayer == nil {
      return nil
    }

    location.moveBy(offset: layer.location())

    if adjustForColumns == .AdjustForColumns {
      if let parentLayer = layer.parent(), CPtrToInt(parentLayer.p) != CPtrToInt(ancestorLayer?.p) {
        if let multiColumnFlow = parentLayer.renderer() as? RenderMultiColumnFlowWrapper {
          if let fragment = multiColumnFlow.physicalTranslationFromFlowToFragment(
            physicalPoint: location)
          {
            location.move(
              s: fragment.topLeftLocation() - parentLayer.renderBox()!.topLeftLocation())
          }
        }
      }
    }

    return parentLayer
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

  struct CalculateLayerBoundsFlag: OptionSet {
    let rawValue: UInt16

    static let IncludeSelfTransform = CalculateLayerBoundsFlag(rawValue: 1)
    static let UseLocalClipRectIfPossible = CalculateLayerBoundsFlag(rawValue: 2)
    static let IncludeFilterOutsets = CalculateLayerBoundsFlag(rawValue: 4)
    static let IncludePaintedFilterOutsets = CalculateLayerBoundsFlag(rawValue: 8)
    static let ExcludeHiddenDescendants = CalculateLayerBoundsFlag(rawValue: 16)
    static let DontConstrainForMask = CalculateLayerBoundsFlag(rawValue: 32)
    static let IncludeCompositedDescendants = CalculateLayerBoundsFlag(rawValue: 64)
    static let UseFragmentBoxesExcludingCompositing = CalculateLayerBoundsFlag(rawValue: 128)
    static let UseFragmentBoxesIncludingCompositing = CalculateLayerBoundsFlag(rawValue: 256)
    static let IncludeRootBackgroundPaintingArea = CalculateLayerBoundsFlag(rawValue: 512)
    static let PreserveAncestorFlags = CalculateLayerBoundsFlag(rawValue: 1024)
    static let UseLocalClipRectExcludingCompositingIfPossible = CalculateLayerBoundsFlag(
      rawValue: 2048)
  }

  // Bounding box relative to some ancestor layer. Pass offsetFromRoot if known.
  func boundingBox(
    ancestorLayer: RenderLayerWrapper?, offsetFromRoot: LayoutSizeWrapper = LayoutSizeWrapper(),
    flags: CalculateLayerBoundsFlag = []
  ) -> LayoutRectWrapper {
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

  func isTransformed() -> Bool { return renderer().isTransformed() }

  // Note that this transform has the transform-origin baked in.
  func transform() -> TransformationMatrix? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTransformedAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func filterOutsets() -> IntOutsets {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBlendMode() -> Bool {
    return renderer().hasBlendMode()  // FIXME: Why ask the renderer this given we have blendMode?
  }

  func isolatesBlending() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isComposited() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasCompositedMask() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintsIntoProvidedBacking() -> Bool {
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
    return isBitmapOnly() && !hasNonOpacityTransparency()
  }

  func paintsWithTransform(paintBehavior: PaintBehavior) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func establishesTopLayer() -> Bool {
    return isInTopLayerOrBackdrop(style: renderer().style(), element: renderer().element())
  }

  func isBitmapOnly() -> Bool {
    if hasVisibleBoxDecorationsOrBackground() {
      return false
    }

    if renderer() is RenderHTMLCanvasWrapper {
      return true
    }

    if let imageRenderer = renderer() as? RenderImageWrapper {
      if let cachedImage = imageRenderer.cachedImage() {
        if !cachedImage.hasImage() {
          return false
        }
        return cachedImage.imageForRenderer(renderer: imageRenderer) is BitmapImageWrapper
      }
      return false
    }

    return false
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
    if CPtrToInt(p) == CPtrToInt(info.rootLayer?.p) || isComposited() || paintsIntoProvidedBacking()
    {
      return nil
    }
    var ancestor = parent()
    while ancestor != nil {
      if ancestor!.isStackingContext() {
        if ancestor!.isComposited() || ancestor!.paintsIntoProvidedBacking() {
          return nil
        }
        if ancestor!.isTransparent() {
          return ancestor
        }
      }
      if CPtrToInt(ancestor?.p) == CPtrToInt(info.rootLayer?.p) {
        return nil
      }
      ancestor = ancestor!.parent()
    }
    return nil
  }

  private static func expandClipRectForDescendantsAndReflection(
    clipRect: inout LayoutRectWrapper, layer: RenderLayerWrapper, rootLayer: RenderLayerWrapper?,
    transparencyBehavior: TransparencyClipBoxBehavior, paintBehavior: PaintBehavior,
    paintDirtyRect: LayoutRectWrapper?
  ) {
    // If we have a mask, then the clip is limited to the border box area (and there is
    // no need to examine child layers).
    if !layer.renderer().hasMask() {
      // Note: we don't have to walk z-order lists since transparent elements always establish
      // a stacking container. This means we can just walk the layer tree directly.
      var curr = layer.firstChild()
      while curr != nil {
        if !layer.isReflectionLayer(layer: curr!) {
          clipRect.unite(
            other:
              transparencyClipBox(
                layer: curr!, rootLayer: rootLayer, transparencyBehavior: transparencyBehavior,
                transparencyMode: .DescendantsOfTransparencyClipBox, paintBehavior: paintBehavior,
                paintDirtyRect: paintDirtyRect))
        }
        curr = curr!.nextSibling()
      }
    }

    // If we have a reflection, then we need to account for that when we push the clip.  Reflect our entire
    // current transparencyClipBox to catch all child layers.
    // FIXME: Accelerated compositing will eventually want to do something smart here to avoid incorporating this
    // size into the parent layer.
    if layer.renderer().isRenderBox() && layer.renderer().hasReflection() {
      let delta = layer.offsetFromAncestor(ancestorLayer: rootLayer)
      clipRect.move(size: -delta)
      clipRect.unite(other: layer.renderBox()!.reflectedRect(r: clipRect))
      clipRect.move(size: delta)
    }
  }

  private static func transparencyClipBox(
    layer: RenderLayerWrapper, rootLayer: RenderLayerWrapper?,
    transparencyBehavior: TransparencyClipBoxBehavior, transparencyMode: TransparencyClipBoxMode,
    paintBehavior: PaintBehavior = [], paintDirtyRect: LayoutRectWrapper? = nil
  )
    -> LayoutRectWrapper
  {
    // FIXME: Although this function completely ignores CSS-imposed clipping, we did already intersect with the
    // paintDirtyRect, and that should cut down on the amount we have to paint.  Still it
    // would be better to respect clips.

    if CPtrToInt(rootLayer?.p) == CPtrToInt(layer.p)
      && ((transparencyBehavior == .PaintingTransparencyClipBox
        && layer.paintsWithTransform(paintBehavior: paintBehavior))
        || (transparencyBehavior == .HitTestingTransparencyClipBox && layer.isTransformed()))
    {
      // The best we can do here is to use enclosed bounding boxes to establish a "fuzzy" enough clip to encompass
      // the transformed layer and all of its children.
      let mode: PaginationInclusionMode =
        transparencyBehavior == .HitTestingTransparencyClipBox
        ? .IncludeCompositedPaginatedLayers : .ExcludeCompositedPaginatedLayers
      let paginationLayer =
        transparencyMode == .DescendantsOfTransparencyClipBox
        ? layer.enclosingPaginationLayer(mode: mode) : nil
      let rootLayerForTransform = paginationLayer != nil ? paginationLayer : rootLayer
      let delta = layer.offsetFromAncestor(ancestorLayer: rootLayerForTransform)

      let transform = TransformationMatrix()
      transform.translate(tx: delta.width().double(), ty: delta.height().double())
      transform.multiply(mat: layer.transform()!)

      // We don't use fragment boxes when collecting a transformed layer's bounding box, since it always
      // paints unfragmented.
      var clipRect = layer.boundingBox(ancestorLayer: layer)
      expandClipRectForDescendantsAndReflection(
        clipRect: &clipRect, layer: layer, rootLayer: layer,
        transparencyBehavior: transparencyBehavior, paintBehavior: paintBehavior,
        paintDirtyRect: paintDirtyRect)
      clipRect.expand(box: toLayoutBoxExtent(extent: layer.filterOutsets()))
      var result = transform.mapRect(r: clipRect)
      if let paginationLayer = paginationLayer {
        // We have to break up the transformed extent across our columns.
        // Split our box up into the actual fragment boxes that render in the columns/pages and unite those together to
        // get our true bounding box.
        let enclosingFragmentedFlow = paginationLayer.renderer() as! RenderFragmentedFlowWrapper
        result = enclosingFragmentedFlow.fragmentsBoundingBox(layerBoundingBox: result)
        result.move(size: paginationLayer.offsetFromAncestor(ancestorLayer: rootLayer))
      }
      if let paintDirtyRect = paintDirtyRect {
        result = intersection(a: result, b: paintDirtyRect)
      }
      return result
    }

    var flags: CalculateLayerBoundsFlag =
      transparencyBehavior == .HitTestingTransparencyClipBox
      ? .UseFragmentBoxesIncludingCompositing : .UseFragmentBoxesExcludingCompositing
    flags.update(with: .IncludeRootBackgroundPaintingArea)
    var clipRect = layer.boundingBox(
      ancestorLayer: rootLayer, offsetFromRoot: layer.offsetFromAncestor(ancestorLayer: rootLayer),
      flags: flags)
    expandClipRectForDescendantsAndReflection(
      clipRect: &clipRect, layer: layer, rootLayer: rootLayer,
      transparencyBehavior: transparencyBehavior, paintBehavior: paintBehavior,
      paintDirtyRect: paintDirtyRect)
    clipRect.expand(box: toLayoutBoxExtent(extent: layer.filterOutsets()))

    if let paintDirtyRect = paintDirtyRect {
      clipRect = intersection(a: clipRect, b: paintDirtyRect)
    }

    return clipRect
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
      var adjustedClipRect = RenderLayerWrapper.transparencyClipBox(
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

  private func hasNonOpacityTransparency() -> Bool {
    if renderer().hasMask() {
      return true
    }

    if hasBlendMode() || isolatesBlending() {
      return true
    }

    if !renderer().document().settings().layerBasedSVGEngineEnabled() {
      return false
    }

    // SVG clip-paths may use clipping masks, if so, flag this layer as transparent.
    if let svgClipper = renderer().svgClipperResourceFromStyle(),
      !svgClipper.shouldApplyPathClipping()
    {
      return true
    }

    return false
  }

  private let p: UnsafeMutableRawPointer
  // Native fields below.

  private var savedAlphaForTransparency: Float32? = nil

  var isRenderViewLayer = false
  private var forcedStackingContext = false
  private var isOpportunisticStackingContext = false

  private var m_isCSSStackingContext = false

  // Tracks whether we need to close a transparent layer, i.e., whether
  // we ended up painting this layer or any descendants (and therefore need to
  // blend).
  private var usedTransparency = false

  private var blendMode: BlendMode = .Normal

  // May ultimately be extended to many replicas (with their own paint order).
  let reflection: RenderReplicaWrapper? = nil
}
