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

enum ClipRectsType {
  case PaintingClipRects  // Relative to painting ancestor. Used for painting.
  case RootRelativeClipRects  // Relative to the ancestor treated as the root (e.g. transformed layer). Used for hit testing.
  case AbsoluteClipRects  // Relative to the RenderView's layer. Used for compositing overlap testing.
  case NumCachedClipRectsTypes
  case AllClipRectTypes
  case TemporaryClipRects
}

enum ShouldApplyRootOffsetToFragments {
  case ApplyRootOffsetToFragments
  case IgnoreRootOffsetForFragments
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

private func performOverlapTests(
  overlapTestRequests: OverlapTestRequestMap, rootLayer: RenderLayerWrapper?,
  layer: RenderLayerWrapper?
) {
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

private func hasVisibleBoxDecorationsOrBackground(renderer: RenderElementWrapper) -> Bool {
  return renderer.hasVisibleBoxDecorations() || renderer.style().hasOutline()
}

class RenderLayerWrapper {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  func scrollableArea() -> RenderLayerScrollableArea? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func page() -> PageWrapper {
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

  struct LayerList {}

  func normalFlowLayers() -> LayerList {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func positiveZOrderLayers() -> LayerList {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func negativeZOrderLayers() -> LayerList {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Update our normal and z-index lists.
  func updateLayerListsIfNeeded() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    if let scrollableArea = m_scrollableArea {
      return scrollableArea.scrollWidth()
    }

    let box = renderBox()!
    var overflowRect = box.layoutOverflowRect()
    box.flipForWritingMode(rect: &overflowRect)
    return Int32(roundToInt(value: overflowRect.maxX() - overflowRect.x()))
  }

  func scrollHeight() -> Int32 {
    if let scrollableArea = m_scrollableArea {
      return scrollableArea.scrollHeight()
    }

    let box = renderBox()!
    var overflowRect = box.layoutOverflowRect()
    box.flipForWritingMode(rect: &overflowRect)
    return Int32(roundToInt(value: overflowRect.maxY() - overflowRect.y()))
  }

  // FIXME: This is terrible. Bring back a cached bit for this someday. This crawl is going to slow down all
  // painting of content inside paginated layers.
  func hasCompositedLayerInEnclosingPaginationChain() -> Bool {
    // No enclosing layer means no compositing in the chain.
    if m_enclosingPaginationLayer == nil {
      return false
    }

    // If the enclosing layer is composited, we don't have to check anything in between us and that
    // layer.
    if m_enclosingPaginationLayer!.isComposited() {
      return true
    }

    // If we are the enclosing pagination layer, then we can't be composited or we'd have passed the
    // previous check.
    if CPtrToInt(m_enclosingPaginationLayer?.p) == CPtrToInt(p) {
      return false
    }

    // The enclosing paginated layer is our ancestor and is not composited, so we have to check
    // intermediate layers between us and the enclosing pagination layer. Start with our own layer.
    if isComposited() {
      return true
    }

    // For normal flow layers, we can recur up the layer tree.
    if isNormalFlowOnly {
      return parent()!.hasCompositedLayerInEnclosingPaginationChain()
    }

    // Otherwise we have to go up the containing block chain. Find the first enclosing
    // containing block layer ancestor, and check that.
    var containingBlock = renderer().containingBlock()
    while containingBlock != nil && containingBlock is RenderViewWrapper {
      if containingBlock!.hasLayer() {
        return containingBlock!.layer()!.hasCompositedLayerInEnclosingPaginationChain()
      }
      containingBlock = containingBlock!.containingBlock()
    }
    return false
  }

  enum PaginationInclusionMode {
    case ExcludeCompositedPaginatedLayers
    case IncludeCompositedPaginatedLayers
  }

  func enclosingPaginationLayer(mode: PaginationInclusionMode) -> RenderLayerWrapper? {
    if mode == .ExcludeCompositedPaginatedLayers && hasCompositedLayerInEnclosingPaginationChain() {
      return nil
    }
    return m_enclosingPaginationLayer
  }

  func hasVisibleBoxDecorationsOrBackground() -> Bool {
    return layout_scion.hasVisibleBoxDecorationsOrBackground(renderer: renderer())
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
    var curr = parent()
    while curr != nil
      && !isContainerForPositioned(
        layer: curr!, position: position, establishesTopLayer: establishesTopLayer())
    {
      curr = curr!.parent()
    }

    if establishesTopLayer() {
      assert(curr == nil || CPtrToInt(curr!.p) == CPtrToInt(renderer().view().layer()!.p))
    }
    return curr
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

  struct PaintLayerFlag: OptionSet {
    let rawValue: UInt32

    static let HaveTransparency = PaintLayerFlag(rawValue: 1)
    static let AppliedTransform = PaintLayerFlag(rawValue: 2)
    static let TemporaryClipRects = PaintLayerFlag(rawValue: 4)
    static let PaintingReflection = PaintLayerFlag(rawValue: 8)
    static let PaintingOverlayScrollbars = PaintLayerFlag(rawValue: 16)
    static let PaintingCompositingBackgroundPhase = PaintLayerFlag(rawValue: 32)
    static let PaintingCompositingForegroundPhase = PaintLayerFlag(rawValue: 64)
    static let PaintingCompositingMaskPhase = PaintLayerFlag(rawValue: 128)
    static let PaintingCompositingClipPathPhase = PaintLayerFlag(rawValue: 256)
    static let PaintingCompositingScrollingPhase = PaintLayerFlag(rawValue: 512)
    static let PaintingOverflowContents = PaintLayerFlag(rawValue: 1024)
    static let PaintingRootBackgroundOnly = PaintLayerFlag(rawValue: 2048)
    static let PaintingSkipRootBackground = PaintLayerFlag(rawValue: 4096)
    static let PaintingChildClippingMaskPhase = PaintLayerFlag(rawValue: 8192)
    static let PaintingSVGClippingMask = PaintLayerFlag(rawValue: 16384)
    static let CollectingEventRegion = PaintLayerFlag(rawValue: 32768)
    static let PaintingSkipDescendantViewTransition = PaintLayerFlag(rawValue: 65536)

  }

  struct ClipRectsOption: OptionSet {
    let rawValue: UInt8

    static let RespectOverflowClip = ClipRectsOption(rawValue: 1 << 0)
    static let IncludeOverlayScrollbarSize = ClipRectsOption(rawValue: 1 << 1)
  }

  static let clipRectOptionsForPaintingOverflowControls: ClipRectsOption = []
  static let clipRectDefaultOptions: ClipRectsOption = [.RespectOverflowClip]

  // Public just for RenderTreeAsText.
  func collectFragments(
    fragments: inout LayerFragments, rootLayer: RenderLayerWrapper?, dirtyRect: LayoutRectWrapper,
    inclusionMode: PaginationInclusionMode, clipRectsType: ClipRectsType,
    clipRectOptions: ClipRectsOption, offsetFromRoot: LayoutSizeWrapper,
    layerBoundingBox: LayoutRectWrapper? = nil,
    applyRootOffsetToFragments: ShouldApplyRootOffsetToFragments = .IgnoreRootOffsetForFragments
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    var result = localBoundingBox(flags: flags)
    if renderer().view().frameView().hasFlippedBlockRenderers() {
      if renderer().isRenderBox() {
        renderBox()!.flipForWritingMode(rect: &result)
      } else {
        renderer().containingBlock()!.flipForWritingMode(rect: &result)
      }
    }

    var inclusionMode: PaginationInclusionMode = .ExcludeCompositedPaginatedLayers
    if flags.contains(.UseFragmentBoxesIncludingCompositing) {
      inclusionMode = .IncludeCompositedPaginatedLayers
    }

    var paginationLayer: RenderLayerWrapper? = nil
    if flags.contains(.UseFragmentBoxesExcludingCompositing)
      || flags.contains(.UseFragmentBoxesIncludingCompositing)
    {
      paginationLayer = enclosingPaginationLayerInSubtree(
        rootLayer: ancestorLayer, mode: inclusionMode)
    }

    var childLayer: RenderLayerWrapper = self
    let isPaginated = paginationLayer != nil
    while paginationLayer != nil {
      // Split our box up into the actual fragment boxes that render in the columns/pages and unite those together to
      // get our true bounding box.
      result.move(size: childLayer.offsetFromAncestor(ancestorLayer: paginationLayer))

      let enclosingFragmentedFlow = paginationLayer!.renderer() as! RenderFragmentedFlowWrapper
      result = enclosingFragmentedFlow.fragmentsBoundingBox(layerBoundingBox: result)

      childLayer = paginationLayer!
      paginationLayer = paginationLayer!.parent()!.enclosingPaginationLayerInSubtree(
        rootLayer: ancestorLayer, mode: inclusionMode)
    }

    if isPaginated {
      result.move(size: childLayer.offsetFromAncestor(ancestorLayer: ancestorLayer))
      return result
    }

    result.move(size: offsetFromRoot)
    return result
  }

  // Bounding box in the coordinates of this layer.
  func localBoundingBox(flags: CalculateLayerBoundsFlag = []) -> LayoutRectWrapper {
    // There are three special cases we need to consider.
    // (1) Inline Flows.  For inline flows we will create a bounding box that fully encompasses all of the lines occupied by the
    // inline.  In other words, if some <span> wraps to three lines, we'll create a bounding box that fully encloses the
    // line boxes of all three lines (including overflow on those lines).
    // (2) Left/Top Overflow.  The width/height of layers already includes right/bottom overflow.  However, in the case of left/top
    // overflow, we have to create a bounding box that will extend to include this overflow.
    // (3) Floats.  When a layer has overhanging floats that it paints, we need to make sure to include these overhanging floats
    // as part of our bounding box.  We do this because we are the responsible layer for both hit testing and painting those
    // floats.
    var result = LayoutRectWrapper()
    if let renderInline = renderer() as? RenderInlineWrapper, renderer().isInline() {
      result = renderInline.linesVisualOverflowBoundingBox()
    } else if let modelObject = renderer() as? RenderSVGModelObjectWrapper {
      result = modelObject.visualOverflowRectEquivalent()
    } else if let tableRow = renderer() as? RenderTableRowWrapper {
      // Our bounding box is just the union of all of our cells' border/overflow rects.
      var cell = tableRow.firstCell()
      while cell != nil {
        let bbox = cell!.borderBoxRect()
        result.unite(other: bbox)
        let overflowRect = tableRow.visualOverflowRect()
        if bbox != overflowRect {
          result.unite(other: overflowRect)
        }
        cell = cell!.nextCell()
      }
    } else {
      let box = renderBox()!
      if !flags.contains(.DontConstrainForMask) && box.hasMask() {
        result = box.maskClipRect(paintOffset: LayoutPointWrapper())
        box.flipForWritingMode(rect: &result)  // The mask clip rect is in physical coordinates, so we have to flip, since localBoundingBox is not.
      } else {
        result = box.visualOverflowRect()
      }

      if flags.contains(.IncludeRootBackgroundPaintingArea)
        && renderer().isDocumentElementRenderer()
      {
        // If the root layer becomes composited (e.g. because some descendant with negative z-index is composited),
        // then it has to be big enough to cover the viewport in order to display the background. This is akin
        // to the code in RenderBox::paintRootBoxFillLayers().
        let frameView = renderer().view().frameView()
        result.setWidth(width: max(result.width(), frameView.contentsWidth() - result.x()))
        result.setHeight(height: max(result.height(), frameView.contentsHeight() - result.y()))
      }
    }
    return result
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
    return hasNotIsolatedBlendingDescendants && isCSSStackingContext()
  }

  func isComposited() -> Bool { return backing != nil }

  func hasCompositedMask() -> Bool {
    if let backing = backing {
      return backing.hasMaskLayer()
    }
    return false
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
    if !renderer().isTransparent() && !hasNonOpacityTransparency() {
      return false
    }
    return paintBehavior.contains(.FlattenCompositingLayers) || !isComposited()
  }

  // If we will only draw a single item, then we can just apply
  // opacity to the drawing context rather than pushing a transparency
  // layer. This currently only detects a single bitmap image, but could
  // be extended to handle other cases.
  func canPaintTransparencyWithSetOpacity() -> Bool {
    return isBitmapOnly() && !hasNonOpacityTransparency()
  }

  func paintsWithTransform(paintBehavior: PaintBehavior) -> Bool {
    let paintsToWindow = !isComposited() || backing!.paintsIntoWindow()
    return transform() != nil
      && (paintBehavior.contains(.FlattenCompositingLayers) || paintsToWindow)
  }

  func shouldApplyClipPath(paintBehavior: PaintBehavior, paintFlags: PaintLayerFlag) -> Bool {
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
    var paintBehavior: PaintBehavior
    let requireSecurityOriginAccessForWidgets: Bool
    var clipToDirtyRect: Bool = true
    let regionContext: RegionContext? = nil
  }

  private func paintOffsetForRenderer(
    fragment: LayerFragment, paintingInfo: LayerPaintingInfo
  ) -> LayoutPointWrapper {
    return toLayoutPoint(
      size: fragment.layerBounds.location() - rendererLocation() + paintingInfo.subpixelOffset)
  }

  private func clipRectRelativeToAncestor(
    ancestor: RenderLayerWrapper?, offsetFromAncestor: LayoutSizeWrapper,
    constrainingRect: LayoutRectWrapper, temporaryClipRects: Bool = false
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func enclosingPaginationLayerInSubtree(
    rootLayer: RenderLayerWrapper?, mode: PaginationInclusionMode
  ) -> RenderLayerWrapper? {
    // If we don't have an enclosing layer, or if the root layer is the same as the enclosing layer,
    // then just return the enclosing pagination layer (it will be 0 in the former case and the rootLayer in the latter case).
    let paginationLayer = enclosingPaginationLayer(mode: mode)
    if paginationLayer == nil || CPtrToInt(rootLayer?.p) == CPtrToInt(paginationLayer!.p) {
      return paginationLayer
    }

    // Walk up the layer tree and see which layer we hit first. If it's the root, then the enclosing pagination
    // layer isn't in our subtree and we return nullptr. If we hit the enclosing pagination layer first, then
    // we can return it.
    var layer: RenderLayerWrapper? = self
    while layer != nil {
      if CPtrToInt(layer!.p) == CPtrToInt(rootLayer?.p) {
        return nil
      }
      if CPtrToInt(layer!.p) == CPtrToInt(paginationLayer?.p) {
        return paginationLayer
      }
      layer = layer!.parent()
    }

    // This should never be reached, since an enclosing layer should always either be the rootLayer or be
    // our enclosing pagination layer.
    fatalError("Not reached")
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

  private func setupFontSubpixelQuantization(context: GraphicsContextWrapper) -> (Bool, Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setupClipPath(
    context: GraphicsContextWrapper, stateSaver: GraphicsContextStateSaver,
    regionContextStateSaver: RegionContextStateSaver, paintingInfo: LayerPaintingInfo,
    paintFlags: PaintLayerFlag, offsetFromRoot: LayoutSizeWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func filtersForPainting(context: GraphicsContextWrapper, paintFlags: PaintLayerFlag)
    -> RenderLayerFilters?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setupFilters(
    destinationContext: GraphicsContextWrapper, paintingInfo: inout LayerPaintingInfo,
    paintFlags: PaintLayerFlag, offsetFromRoot: LayoutSizeWrapper, backgroundRect: ClipRect
  ) -> GraphicsContextWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func applyFilters(
    originalContext: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo,
    behavior: PaintBehavior, backgroundRect: ClipRect
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintLayerContents(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    assert(isSelfPaintingLayer || hasSelfPaintingLayerDescendant)

    if context.detectingContentfulPaint() && context.contentfulPaintDetected() {
      return
    }

    var localPaintFlags = paintFlags.subtracting(.AppliedTransform)

    let haveTransparency = localPaintFlags.contains(.HaveTransparency)
    let isPaintingOverlayScrollbars = localPaintFlags.contains(.PaintingOverlayScrollbars)
    let isPaintingScrollingContent = localPaintFlags.contains(.PaintingCompositingScrollingPhase)
    let isPaintingCompositedForeground = localPaintFlags.contains(
      .PaintingCompositingForegroundPhase)
    let isPaintingCompositedBackground = localPaintFlags.contains(
      .PaintingCompositingBackgroundPhase)
    let isPaintingOverflowContents = localPaintFlags.contains(.PaintingOverflowContents)
    let isCollectingEventRegion = localPaintFlags.contains(.CollectingEventRegion)
    let isCollectingAccessibilityRegion = paintingInfo.regionContext is AccessibilityRegionContext

    let isSelfPaintingLayer = self.isSelfPaintingLayer

    // Outline always needs to be painted even if we have no visible content. Also,
    // the outline is painted in the background phase during composited scrolling.
    // If it were painted in the foreground phase, it would move with the scrolled
    // content. When not composited scrolling, the outline is painted in the
    // foreground phase. Since scrolled contents are moved by repainting in this
    // case, the outline won't get 'dragged along'.
    let shouldPaintOutline =
      isSelfPaintingLayer && !isPaintingOverlayScrollbars && !isCollectingEventRegion
      && !isCollectingAccessibilityRegion
      && (renderer().view().printing() || renderer().view().hasRenderersWithOutline())
      && ((isPaintingScrollingContent && isPaintingCompositedBackground)
        || (!isPaintingScrollingContent && isPaintingCompositedForeground))

    let shouldPaintContent =
      paintLayerHasVisibleContent() && isSelfPaintingLayer && !isPaintingOverlayScrollbars
      && !isCollectingEventRegion && !isCollectingAccessibilityRegion

    if localPaintFlags.contains(.PaintingRootBackgroundOnly) && !renderer().isRenderView()
      && !renderer().isDocumentElementRenderer()
    {
      // If beginTransparencyLayers was called prior to this, ensure the transparency state is cleaned up before returning.
      if haveTransparency && usedTransparency && !paintingInsideReflection {
        if let savedAlphaForTransparency = self.savedAlphaForTransparency {
          context.setAlpha(alpha: savedAlphaForTransparency)
          self.savedAlphaForTransparency = nil
        } else {
          context.endTransparencyLayer()
          context.restore()
        }
        usedTransparency = false
      }

      return
    }

    updateLayerListsIfNeeded()

    let offsetFromRoot = offsetFromAncestor(ancestorLayer: paintingInfo.rootLayer)

    // FIXME: We shouldn't have to disable subpixel quantization for overflow clips or subframes once we scroll those
    // things on the scrolling thread.
    let (needToAdjustSubpixelQuantization, didQuantizeFonts) = setupFontSubpixelQuantization(
      context: context)

    // Apply clip-path to context.
    var columnAwareOffsetFromRoot = offsetFromRoot
    if renderer().enclosingFragmentedFlow() != nil
      && (renderer().hasClipPath()
        || filtersForPainting(context: context, paintFlags: paintFlags) != nil)
    {
      columnAwareOffsetFromRoot = toLayoutSize(
        point: convertToLayerCoords(
          ancestorLayer: paintingInfo.rootLayer, location: LayoutPointWrapper(),
          adjustForColumns: .AdjustForColumns))
    }

    let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
    let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)

    if shouldApplyClipPath(paintBehavior: paintingInfo.paintBehavior, paintFlags: localPaintFlags) {
      setupClipPath(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: paintingInfo, paintFlags: localPaintFlags,
        offsetFromRoot: columnAwareOffsetFromRoot)
    }

    let applySVGClippingMask = localPaintFlags.contains(.PaintingSVGClippingMask)
    if applySVGClippingMask {
      localPaintFlags.remove(.PaintingSVGClippingMask)
    }

    let selectionAndBackgroundsOnly = paintingInfo.paintBehavior.contains(
      .SelectionAndBackgroundsOnly)
    let selectionOnly = paintingInfo.paintBehavior.contains(.SelectionOnly)

    paintFrequencyTracker.track(timestamp: page().lastRenderingUpdateTimestamp())

    var layerFragments: LayerFragments = []
    var subtreePaintRootForRenderer: RenderObjectWrapper? = nil

    let paintBehavior = paintBehaviorForContents()

    do {  // Scope for filter-related state changes.
      var backgroundRect = ClipRect()

      if filtersForPainting(context: context, paintFlags: paintFlags) != nil {
        // When we called collectFragments() last time, paintDirtyRect was reset to represent the filter bounds.
        // Now we need to compute the backgroundRect uncontaminated by filters, in order to clip the filtered result.
        // Note that we also use paintingInfo here, not localPaintingInfo which filters also contaminated.
        var layerFragments: LayerFragments = []
        let clipRectOptions =
          isPaintingOverflowContents
          ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
          : RenderLayerWrapper.clipRectDefaultOptions
        collectFragments(
          fragments: &layerFragments, rootLayer: paintingInfo.rootLayer,
          dirtyRect: paintingInfo.paintDirtyRect,
          inclusionMode: .ExcludeCompositedPaginatedLayers,
          clipRectsType: localPaintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects,
          clipRectOptions: clipRectOptions, offsetFromRoot: offsetFromRoot)
        updatePaintingInfoForFragments(
          fragments: &layerFragments, localPaintingInfo: paintingInfo,
          localPaintFlags: localPaintFlags, shouldPaintContent: shouldPaintContent,
          offsetFromRoot: offsetFromRoot)

        // FIXME: Handle more than one fragment.
        backgroundRect = layerFragments.isEmpty ? ClipRect() : layerFragments[0].backgroundRect
      }

      var localPaintingInfo = paintingInfo
      let filterContext = setupFilters(
        destinationContext: context, paintingInfo: &localPaintingInfo, paintFlags: paintFlags,
        offsetFromRoot: columnAwareOffsetFromRoot, backgroundRect: backgroundRect)
      if filterContext != nil && haveTransparency {
        // If we have a filter and transparency, we have to eagerly start a transparency layer here, rather than risk a child layer lazily starts one with the wrong context.
        beginTransparencyLayers(
          context: context, paintingInfo: localPaintingInfo, dirtyRect: paintingInfo.paintDirtyRect)
      }
      let currentContext = filterContext != nil ? filterContext! : context

      if filterContext != nil {
        localPaintingInfo.paintBehavior.update(with: .DontShowVisitedLinks)
      }

      // If this layer's renderer is a child of the subtreePaintRoot, we render unconditionally, which
      // is done by passing a nil subtreePaintRoot down to our renderer (as if no subtreePaintRoot was ever set).
      // Otherwise, our renderer tree may or may not contain the subtreePaintRoot root, so we pass that root along
      // so it will be tested against as we descend through the renderers.
      if localPaintingInfo.subtreePaintRoot != nil
        && !renderer().isDescendantOf(ancestor: localPaintingInfo.subtreePaintRoot)
      {
        subtreePaintRootForRenderer = localPaintingInfo.subtreePaintRoot
      }

      if let overlapTestRequests = localPaintingInfo.overlapTestRequests, isSelfPaintingLayer {
        performOverlapTests(
          overlapTestRequests: overlapTestRequests,
          rootLayer: localPaintingInfo.rootLayer, layer: self)
      }

      var paintDirtyRect = localPaintingInfo.paintDirtyRect
      if shouldPaintContent || shouldPaintOutline || isPaintingOverlayScrollbars
        || isCollectingEventRegion || isCollectingAccessibilityRegion
      {
        // Collect the fragments. This will compute the clip rectangles and paint offsets for each layer fragment, as well as whether or not the content of each
        // fragment should paint. If the parent's filter dictates full repaint to ensure proper filter effect,
        // use the overflow clip as dirty rect, instead of no clipping. It maintains proper clipping for overflow::scroll.
        if !localPaintingInfo.clipToDirtyRect && renderer().hasNonVisibleOverflow() {
          // We can turn clipping back by requesting full repaint for the overflow area.
          localPaintingInfo.clipToDirtyRect = true
          paintDirtyRect = clipRectRelativeToAncestor(
            ancestor: localPaintingInfo.rootLayer, offsetFromAncestor: offsetFromRoot,
            constrainingRect: LayoutRectWrapper.infiniteRect(),
            temporaryClipRects: localPaintFlags.contains(.TemporaryClipRects))
        }

        let clipRectOptions =
          isPaintingOverflowContents
          ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
          : RenderLayerWrapper.clipRectDefaultOptions
        collectFragments(
          fragments: &layerFragments, rootLayer: localPaintingInfo.rootLayer,
          dirtyRect: paintDirtyRect,
          inclusionMode: .ExcludeCompositedPaginatedLayers,
          clipRectsType: localPaintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects,
          clipRectOptions: clipRectOptions, offsetFromRoot: offsetFromRoot)
        updatePaintingInfoForFragments(
          fragments: &layerFragments, localPaintingInfo: localPaintingInfo,
          localPaintFlags: localPaintFlags, shouldPaintContent: shouldPaintContent,
          offsetFromRoot: offsetFromRoot)
      }

      if isPaintingCompositedBackground {
        // Paint only the backgrounds for all of the fragments of the layer.
        if shouldPaintContent && !selectionOnly {
          paintBackgroundForFragments(
            layerFragments: layerFragments, context: currentContext,
            contextForTransparencyLayer: context,
            transparencyPaintDirtyRect: paintingInfo.paintDirtyRect,
            haveTransparency: haveTransparency,
            localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior,
            subtreePaintRootForRenderer: subtreePaintRootForRenderer)
        }
      }

      // Now walk the sorted list of children with negative z-indices.
      if (isPaintingScrollingContent && isPaintingOverflowContents)
        || (!isPaintingScrollingContent && isPaintingCompositedBackground)
      {
        paintList(
          layerIterator: negativeZOrderLayers(), context: currentContext,
          paintingInfo: paintingInfo, paintFlags: localPaintFlags)
      }

      if isPaintingCompositedForeground {
        if shouldPaintContent {
          paintForegroundForFragments(
            layerFragments: layerFragments, context: currentContext,
            contextForTransparencyLayer: context,
            transparencyPaintDirtyRect: paintingInfo.paintDirtyRect,
            haveTransparency: haveTransparency,
            localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior,
            subtreePaintRootForRenderer: subtreePaintRootForRenderer)
        }
      }

      if isCollectingEventRegion {
        collectEventRegionForFragments(
          layerFragments: layerFragments, context: currentContext,
          localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior)
      }

      if isCollectingAccessibilityRegion {
        collectAccessibilityRegionsForFragments(
          layerFragments: layerFragments, context: currentContext,
          localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior)
      }

      if shouldPaintOutline {
        paintOutlineForFragments(
          layerFragments: layerFragments, context: currentContext,
          localPaintingInfo: localPaintingInfo, paintBehavior: paintBehavior,
          subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }

      if isPaintingCompositedForeground {
        // Paint any child layers that have overflow.
        paintList(
          layerIterator: normalFlowLayers(), context: currentContext, paintingInfo: paintingInfo,
          paintFlags: localPaintFlags)

        // Now walk the sorted list of children with positive z-indices.
        paintList(
          layerIterator: positiveZOrderLayers(), context: currentContext,
          paintingInfo: localPaintingInfo, paintFlags: localPaintFlags)
      }

      if let scrollableArea = m_scrollableArea {
        if isPaintingOverlayScrollbars && scrollableArea.hasScrollbars() {
          paintOverflowControlsForFragments(
            layerFragments: layerFragments, context: currentContext,
            localPaintingInfo: localPaintingInfo)
        }
      }

      if filterContext != nil {
        applyFilters(
          originalContext: context, paintingInfo: paintingInfo, behavior: paintBehavior,
          backgroundRect: backgroundRect)
      }
    }

    if shouldPaintContent && !(selectionOnly || selectionAndBackgroundsOnly) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    // End our transparency layer
    if haveTransparency && usedTransparency && !paintingInsideReflection {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    // Re-set this to whatever it was before we painted the layer.
    if needToAdjustSubpixelQuantization {
      context.setShouldSubpixelQuantizeFonts(shouldSubpixelQuantizeFonts: didQuantizeFonts)
    }
  }

  private func paintList(
    layerIterator: LayerList, context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo,
    paintFlags: PaintLayerFlag
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updatePaintingInfoForFragments(
    fragments: inout LayerFragments, localPaintingInfo: LayerPaintingInfo,
    localPaintFlags: PaintLayerFlag, shouldPaintContent: Bool, offsetFromRoot: LayoutSizeWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintBackgroundForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    contextForTransparencyLayer: GraphicsContextWrapper,
    transparencyPaintDirtyRect: LayoutRectWrapper, haveTransparency: Bool,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintLayerHasVisibleContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintBehaviorForContents() -> PaintBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func paintOutlineForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintOverflowControlsForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func collectEventRegionForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func collectAccessibilityRegionsForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private var isNormalFlowOnly = false
  private var m_isCSSStackingContext = false
  private var isOpportunisticStackingContext = false

  private let isSelfPaintingLayer = false

  // If have no self-painting descendants, we don't have to walk our children during painting. This can lead to
  // significant savings, especially if the tree has lots of non-self-painting layers grouped together (e.g. table cells).
  private let hasSelfPaintingLayerDescendant = false

  // Tracks whether we need to close a transparent layer, i.e., whether
  // we ended up painting this layer or any descendants (and therefore need to
  // blend).
  private var usedTransparency = false
  private let paintingInsideReflection = false  // A state bit tracking if we are painting inside a replica.

  private var blendMode: BlendMode = .Normal
  private var hasNotIsolatedBlendingDescendants = false

  // May ultimately be extended to many replicas (with their own paint order).
  let reflection: RenderReplicaWrapper? = nil

  // Pointer to the enclosing RenderLayer that caused us to be paginated. It is 0 if we are not paginated.
  let m_enclosingPaginationLayer: RenderLayerWrapper? = nil

  let backing: RenderLayerBacking? = nil

  let m_scrollableArea: RenderLayerScrollableArea? = nil

  let paintFrequencyTracker = PaintFrequencyTracker()
}
