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

enum IncludeSelfOrNot {
  case IncludeSelf
  case ExcludeSelf
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

private func makeMatrixRenderable(matrix: TransformationMatrix, has3DRendering: Bool) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func compositedWithOwnBackingStore(layer: RenderLayerWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func performOverlapTests(
  overlapTestRequests: inout OverlapTestRequestMap, rootLayer: RenderLayerWrapper?,
  layer: RenderLayerWrapper
) {
  if overlapTestRequests.isEmpty {
    return
  }

  var overlappedRequestClients: [OverlapTestRequestClient] = []
  let boundingBox = layer.boundingBox(
    ancestorLayer: rootLayer, offsetFromRoot: layer.offsetFromAncestor(ancestorLayer: rootLayer))
  for (client, clientRect) in overlapTestRequests {
    if !boundingBox.intersects(other: LayoutRectWrapper(rect: clientRect)) {
      continue
    }

    client.setOverlapTestResult(isOverlapped: true)
    overlappedRequestClients.append(client)
  }
  for client in overlappedRequestClients {
    overlapTestRequests.removeValue(forKey: client)
  }
}

private func shouldDoSoftwarePaint(layer: RenderLayerWrapper, paintingReflection: Bool) -> Bool {
  return paintingReflection && !layer.has3DTransform()
}

private func shouldSuppressPaintingLayer(layer: RenderLayerWrapper) -> Bool {
  // Avoid painting all layers if the document is in a state where visual updates aren't allowed.
  // A full repaint will occur in Document::setVisualUpdatesAllowed(bool) if painting is suppressed here.
  if !layer.renderer().document().visualUpdatesAllowed() {
    return true
  }
  return false
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

class ClipRects: Equatable {
  static func create() -> ClipRects {
    return ClipRects()
  }

  func reset() {
    overflowClipRect.reset()
    fixedClipRect.reset()
    posClipRect.reset()
    fixed = false
  }

  func setOverflowClipRectAffectedByRadius() { overflowClipRect.affectedByRadius = true }

  static func == (this: ClipRects, other: ClipRects) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var fixed = false
  var overflowClipRect = ClipRect()
  var fixedClipRect = ClipRect()
  var posClipRect = ClipRect()
}

class ClipRectsCache {
  func getClipRects(clipRectsType: ClipRectsType, respectOverflowClip: Bool) -> ClipRects? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setClipRects(clipRectsType: ClipRectsType, respectOverflowClip: Bool, clipRects: ClipRects) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private func backgroundClipRectForPosition(parentRects: ClipRects, position: PositionType)
  -> ClipRect
{
  if position == .Fixed {
    return parentRects.fixedClipRect
  }

  if position == .Absolute {
    return parentRects.posClipRect
  }

  return parentRects.overflowClipRect
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

  func paintOrderParent() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct LayerList: Sequence, IteratorProtocol {
    func next() -> RenderLayerWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func size() -> UInt64 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

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
    updateDescendantDependentFlags()
    updateZOrderLists()
    updateNormalFlowList()

    if let reflectionLayer = self.reflectionLayer() {
      reflectionLayer.updateZOrderLists()
      reflectionLayer.updateNormalFlowList()
    }
  }

  func updateDescendantDependentFlags() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTransparent() -> Bool { return renderer().isTransparent() || renderer().hasMask() }

  func reflectionLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  private static func isContainerForPositioned(
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

  func ancestorLayerIsInContainingBlockChain(
    ancestor: RenderLayerWrapper, checkLimit: RenderLayerWrapper? = nil
  ) -> Bool {
    if CPtrToInt(ancestor.p) == CPtrToInt(p) {
      return true
    }

    var currentBlock = renderer().containingBlock()
    while currentBlock != nil && !(currentBlock! is RenderViewWrapper) {
      let currLayer = currentBlock!.layer()
      if CPtrToInt(currLayer?.p) == CPtrToInt(ancestor.p) {
        return true
      }

      if currLayer != nil && CPtrToInt(currLayer?.p) == CPtrToInt(checkLimit?.p) {
        return false
      }

      currentBlock = currentBlock!.containingBlock()
    }

    return false
  }

  // Gets the nearest enclosing positioned ancestor layer (also includes
  // the <html> layer and the root layer).
  func enclosingAncestorForPosition(position: PositionType) -> RenderLayerWrapper? {
    var curr = parent()
    while curr != nil
      && !RenderLayerWrapper.isContainerForPositioned(
        layer: curr!, position: position, establishesTopLayer: establishesTopLayer())
    {
      curr = curr!.parent()
    }

    if establishesTopLayer() {
      assert(curr == nil || CPtrToInt(curr!.p) == CPtrToInt(renderer().view().layer()!.p))
    }
    return curr
  }

  // The layer relative to which clipping rects for this layer are computed.
  func clippingRootForPainting() -> RenderLayerWrapper? {
    if isComposited() {
      return self
    }

    if paintsIntoProvidedBacking() {
      return backingProviderLayer
    }

    var current: RenderLayerWrapper? = self
    while current != nil {
      if current!.isRenderViewLayer {
        return current
      }

      current = current!.paintOrderParent()
      assert(current != nil)
      if current!.transform != nil || compositedWithOwnBackingStore(layer: current!) {
        return current
      }

      if renderer().settings().css3DTransformBackfaceVisibilityInteroperabilityEnabled()
        && current!.participatesInPreserve3D()
        && current!.renderer().style().backfaceVisibility() == .Hidden
      {
        return current
      }

      if current!.paintsIntoProvidedBacking() {
        return current!.backingProviderLayer
      }
    }

    fatalError("Not reached")
  }

  struct EnclosingCompositingLayerStatus {
    let fullRepaintAlreadyScheduled = false
    let layer: RenderLayerWrapper? = nil
  }

  func enclosingCompositingLayerForRepaint(includeSelf: IncludeSelfOrNot = .IncludeSelf)
    -> EnclosingCompositingLayerStatus
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canUseOffsetFromAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canUseOffsetFromAncestor(ancestor: RenderLayerWrapper) -> Bool {
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

        if RenderLayerWrapper.isContainerForPositioned(
          layer: currLayer!, position: .Fixed, establishesTopLayer: layer.establishesTopLayer())
        {
          fixedPositionContainerLayer = currLayer
          // A layer that has a transform-related property but not a
          // transform still acts as a fixed-position container.
          // Accumulating offsets across such layers is allowed.
          if currLayer!.transform != nil {
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
        if RenderLayerWrapper.isContainerForPositioned(
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

  static let paintLayerPaintingCompositingAllPhasesFlags: PaintLayerFlag = [
    .PaintingCompositingBackgroundPhase, .PaintingCompositingForegroundPhase,
  ]

  struct ClipRectsOption: OptionSet {
    let rawValue: UInt8

    static let RespectOverflowClip = ClipRectsOption(rawValue: 1 << 0)
    static let IncludeOverlayScrollbarSize = ClipRectsOption(rawValue: 1 << 1)
  }

  static let clipRectOptionsForPaintingOverflowControls: ClipRectsOption = []
  static let clipRectDefaultOptions: ClipRectsOption = [.RespectOverflowClip]

  struct ClipRectsContext {
    init(
      inRootLayer: RenderLayerWrapper?, inClipRectsType: ClipRectsType,
      inOptions: ClipRectsOption = RenderLayerWrapper.clipRectDefaultOptions
    ) {
      rootLayer = inRootLayer
      clipRectsType = inClipRectsType
      options = inOptions
    }

    func respectOverflowClip() -> Bool { return options.contains(.RespectOverflowClip) }

    func overlayScrollbarSizeRelevancy() -> OverlayScrollbarSizeRelevancy {
      return options.contains(.IncludeOverlayScrollbarSize)
        ? .IncludeOverlayScrollbarSize : .IgnoreOverlayScrollbarSize
    }

    let rootLayer: RenderLayerWrapper?
    var clipRectsType: ClipRectsType
    let options: ClipRectsOption
  }

  // This method figures out our layerBounds in coordinates relative to
  // |rootLayer|. It also computes our background and foreground clip rects
  // for painting/event handling.
  // Pass offsetFromRoot if known.
  func calculateRects(
    clipRectsContext: ClipRectsContext, paintDirtyRect: LayoutRectWrapper,
    layerBounds: inout LayoutRectWrapper, backgroundRect: inout ClipRect,
    foregroundRect: inout ClipRect,
    offsetFromRoot: LayoutSizeWrapper
  ) {
    if CPtrToInt(clipRectsContext.rootLayer?.p) != CPtrToInt(p) && parent() != nil {
      backgroundRect = backgroundClipRect(clipRectsContext: clipRectsContext)
      backgroundRect.intersect(other: paintDirtyRect)
    } else {
      backgroundRect = ClipRect(rect: paintDirtyRect)
    }

    let offsetFromRootLocal = offsetFromRoot

    layerBounds = LayoutRectWrapper(
      location: toLayoutPoint(size: offsetFromRootLocal), size: LayoutSizeWrapper(size: size()))

    foregroundRect = backgroundRect

    // Update the clip rects that will be passed to child layers.
    if renderer().hasClipOrNonVisibleOverflow() {
      // This layer establishes a clip of some kind.
      if renderer().hasNonVisibleOverflow() {
        if CPtrToInt(p) != CPtrToInt(clipRectsContext.rootLayer?.p)
          || clipRectsContext.respectOverflowClip()
        {
          let overflowClipRect = rendererOverflowClipRect(
            location: toLayoutPoint(size: offsetFromRootLocal), fragment: nil,
            relevancy: clipRectsContext.overlayScrollbarSizeRelevancy())
          foregroundRect.intersect(other: overflowClipRect)
          foregroundRect.affectedByRadius = true
        } else if transform != nil && renderer().style().hasBorderRadius() {
          foregroundRect.affectedByRadius = true
        }
      }

      if renderer().hasClip(), let box = renderer() as? RenderBoxWrapper {
        // Clip applies to *us* as well, so update the damageRect.
        let newPosClip = box.clipRect(
          location: toLayoutPoint(size: offsetFromRootLocal), fragment: nil)
        backgroundRect.intersect(other: newPosClip)
        foregroundRect.intersect(other: newPosClip)
      }

      // If we establish a clip at all, then make sure our background rect is intersected with our layer's bounds including our visual overflow,
      // since any visual overflow like box-shadow or border-outset is not clipped by overflow:auto/hidden.
      if rendererHasVisualOverflow() {
        // FIXME: Does not do the right thing with CSS regions yet, since we don't yet factor in the
        // individual region boxes as overflow.
        var layerBoundsWithVisualOverflow = rendererVisualOverflowRect()
        if renderer().isRenderBox() {
          renderBox()!.flipForWritingMode(rect: &layerBoundsWithVisualOverflow)  // Layers are in physical coordinates, so the overflow has to be flipped.
        }
        layerBoundsWithVisualOverflow.move(size: offsetFromRootLocal)
        if CPtrToInt(p) != CPtrToInt(clipRectsContext.rootLayer?.p)
          || clipRectsContext.respectOverflowClip()
        {
          backgroundRect.intersect(other: layerBoundsWithVisualOverflow)
        }
      } else {
        // Shift the bounds to be for our region only.
        var bounds = rendererBorderBoxRectInFragment(fragment: nil)

        bounds.move(size: offsetFromRootLocal)
        if CPtrToInt(p) != CPtrToInt(clipRectsContext.rootLayer?.p)
          || clipRectsContext.respectOverflowClip()
        {
          backgroundRect.intersect(other: bounds)
        }
      }
    }
  }

  // Public just for RenderTreeAsText.
  func collectFragments(
    fragments: inout LayerFragments, rootLayer: RenderLayerWrapper?, dirtyRect: LayoutRectWrapper,
    inclusionMode: PaginationInclusionMode, clipRectsType: ClipRectsType,
    clipRectOptions: ClipRectsOption, offsetFromRoot: LayoutSizeWrapper,
    layerBoundingBox: LayoutRectWrapper? = nil,
    applyRootOffsetToFragments: ShouldApplyRootOffsetToFragments = .IgnoreRootOffsetForFragments
  ) {
    let paginationLayer = enclosingPaginationLayerInSubtree(
      rootLayer: rootLayer, mode: inclusionMode)
    if paginationLayer == nil || isTransformed() {
      // For unpaginated layers, there is only one fragment.
      let fragment = LayerFragment()
      let clipRectsContext = ClipRectsContext(
        inRootLayer: rootLayer, inClipRectsType: clipRectsType, inOptions: clipRectOptions)
      calculateRects(
        clipRectsContext: clipRectsContext, paintDirtyRect: dirtyRect,
        layerBounds: &fragment.layerBounds, backgroundRect: &fragment.backgroundRect,
        foregroundRect: &fragment.foregroundRect, offsetFromRoot: offsetFromRoot)
      fragments.append(fragment)
      return
    }

    // Compute our offset within the enclosing pagination layer.
    let offsetWithinPaginatedLayer = offsetFromAncestor(ancestorLayer: paginationLayer)

    // Calculate clip rects relative to the enclosingPaginationLayer. The purpose of this call is to determine our bounds clipped to intermediate
    // layers between us and the pagination context. It's important to minimize the number of fragments we need to create and this helps with that.
    let paginationClipRectsContext = ClipRectsContext(
      inRootLayer: paginationLayer, inClipRectsType: clipRectsType, inOptions: clipRectOptions)
    var layerBoundsInFragmentedFlow = LayoutRectWrapper()
    var backgroundRectInFragmentedFlow = ClipRect()
    var foregroundRectInFragmentedFlow = ClipRect()
    calculateRects(
      clipRectsContext: paginationClipRectsContext,
      paintDirtyRect: LayoutRectWrapper.infiniteRect(), layerBounds: &layerBoundsInFragmentedFlow,
      backgroundRect: &backgroundRectInFragmentedFlow,
      foregroundRect: &foregroundRectInFragmentedFlow,
      offsetFromRoot: offsetWithinPaginatedLayer)

    // Take our bounding box within the flow thread and clip it.
    var layerBoundingBoxInFragmentedFlow =
      layerBoundingBox != nil
      ? layerBoundingBox!
      : boundingBox(ancestorLayer: paginationLayer, offsetFromRoot: offsetWithinPaginatedLayer)
    layerBoundingBoxInFragmentedFlow.intersect(other: backgroundRectInFragmentedFlow.rect)

    let enclosingFragmentedFlow = paginationLayer!.renderer() as! RenderFragmentedFlowWrapper
    let parentPaginationLayer = paginationLayer!.parent()!.enclosingPaginationLayerInSubtree(
      rootLayer: rootLayer, mode: inclusionMode)
    var ancestorFragments: LayerFragments = []
    if parentPaginationLayer != nil {
      // Compute a bounding box accounting for fragments.
      var layerFragmentBoundingBoxInParentPaginationLayer =
        enclosingFragmentedFlow.fragmentsBoundingBox(
          layerBoundingBox: layerBoundingBoxInFragmentedFlow)

      // Convert to be in the ancestor pagination context's coordinate space.
      let offsetWithinParentPaginatedLayer = paginationLayer!.offsetFromAncestor(
        ancestorLayer: parentPaginationLayer)
      layerFragmentBoundingBoxInParentPaginationLayer.move(size: offsetWithinParentPaginatedLayer)

      // Now collect ancestor fragments.
      parentPaginationLayer!.collectFragments(
        fragments: &ancestorFragments, rootLayer: rootLayer, dirtyRect: dirtyRect,
        inclusionMode: inclusionMode, clipRectsType: clipRectsType,
        clipRectOptions: clipRectOptions,
        offsetFromRoot: offsetFromAncestor(ancestorLayer: rootLayer),
        layerBoundingBox: layerFragmentBoundingBoxInParentPaginationLayer,
        applyRootOffsetToFragments: .ApplyRootOffsetToFragments)

      if ancestorFragments.isEmpty {
        return
      }

      for ancestorFragment in ancestorFragments {
        // Shift the dirty rect into flow thread coordinates.
        var dirtyRectInFragmentedFlow = dirtyRect
        dirtyRectInFragmentedFlow.move(
          size:
            -offsetWithinParentPaginatedLayer - ancestorFragment.paginationOffset)

        let oldSize = fragments.count

        // Tell the flow thread to collect the fragments. We pass enough information to create a minimal number of fragments based off the pages/columns
        // that intersect the actual dirtyRect as well as the pages/columns that intersect our layer's bounding box.
        enclosingFragmentedFlow.collectLayerFragments(
          layerFragments: &fragments, layerBoundingBox: layerBoundingBoxInFragmentedFlow,
          dirtyRect: dirtyRectInFragmentedFlow)

        let newSize = fragments.count

        if oldSize == newSize {
          continue
        }

        for fragment in fragments[oldSize..<newSize] {
          // Set our four rects with all clipping applied that was internal to the flow thread.
          fragment.setRects(
            bounds: layerBoundsInFragmentedFlow, background: backgroundRectInFragmentedFlow,
            foreground: foregroundRectInFragmentedFlow,
            bbox: layerBoundingBoxInFragmentedFlow)

          // Shift to the root-relative physical position used when painting the flow thread in this fragment.
          fragment.moveBy(
            offset:
              toLayoutPoint(
                size: ancestorFragment.paginationOffset + fragment.paginationOffset
                  + offsetWithinParentPaginatedLayer))

          // Intersect the fragment with our ancestor's background clip so that e.g., columns in an overflow:hidden block are
          // properly clipped by the overflow.
          fragment.intersect(rect: ancestorFragment.paginationClip)

          // Now intersect with our pagination clip. This will typically mean we're just intersecting the dirty rect with the column
          // clip, so the column clip ends up being all we apply.
          fragment.intersect(rect: fragment.paginationClip)

          if applyRootOffsetToFragments == .ApplyRootOffsetToFragments {
            fragment.paginationOffset = fragment.paginationOffset + offsetWithinParentPaginatedLayer
          }
        }
      }

      return
    }

    // Shift the dirty rect into flow thread coordinates.
    let offsetOfPaginationLayerFromRoot = enclosingPaginationLayer(mode: inclusionMode)!
      .offsetFromAncestor(ancestorLayer: rootLayer)
    var dirtyRectInFragmentedFlow = dirtyRect
    dirtyRectInFragmentedFlow.move(size: -offsetOfPaginationLayerFromRoot)

    // Tell the flow thread to collect the fragments. We pass enough information to create a minimal number of fragments based off the pages/columns
    // that intersect the actual dirtyRect as well as the pages/columns that intersect our layer's bounding box.
    enclosingFragmentedFlow.collectLayerFragments(
      layerFragments: &fragments, layerBoundingBox: layerBoundingBoxInFragmentedFlow,
      dirtyRect: dirtyRectInFragmentedFlow)

    if fragments.isEmpty {
      return
    }

    // Get the parent clip rects of the pagination layer, since we need to intersect with that when painting column contents.
    var ancestorClipRect = ClipRect(rect: dirtyRect)
    if paginationLayer!.parent() != nil {
      let clipRectsContext = ClipRectsContext(
        inRootLayer: rootLayer, inClipRectsType: clipRectsType, inOptions: clipRectOptions)
      ancestorClipRect = paginationLayer!.backgroundClipRect(clipRectsContext: clipRectsContext)
      ancestorClipRect.intersect(other: dirtyRect)
    }

    for fragment in fragments {
      // Set our four rects with all clipping applied that was internal to the flow thread.
      fragment.setRects(
        bounds: layerBoundsInFragmentedFlow, background: backgroundRectInFragmentedFlow,
        foreground: foregroundRectInFragmentedFlow,
        bbox: layerBoundingBoxInFragmentedFlow)

      // Shift to the root-relative physical position used when painting the flow thread in this fragment.
      fragment.moveBy(
        offset: toLayoutPoint(size: fragment.paginationOffset + offsetOfPaginationLayerFromRoot))

      // Intersect the fragment with our ancestor's background clip so that e.g., columns in an overflow:hidden block are
      // properly clipped by the overflow.
      fragment.intersect(clipRect: ancestorClipRect)

      // Now intersect with our pagination clip. This will typically mean we're just intersecting the dirty rect with the column
      // clip, so the column clip ends up being all we apply.
      fragment.intersect(rect: fragment.paginationClip)

      if applyRootOffsetToFragments == .ApplyRootOffsetToFragments {
        fragment.paginationOffset = fragment.paginationOffset + offsetOfPaginationLayerFromRoot
      }
    }
  }

  enum LocalClipRectMode {
    case IncludeCompositingState
    case ExcludeCompositingState
  }

  func localClipRect(
    clipExceedsBounds: inout Bool, mode: LocalClipRectMode = .IncludeCompositingState
  ) -> LayoutRectWrapper {
    clipExceedsBounds = false
    // FIXME: border-radius not accounted for.
    // FIXME: Regions not accounted for.
    let clippingRootLayer = mode == .ExcludeCompositingState ? self : clippingRootForPainting()
    let offsetFromRoot = offsetFromAncestor(ancestorLayer: clippingRootLayer)
    var clipRect = clipRectRelativeToAncestor(
      ancestor: clippingRootLayer, offsetFromAncestor: offsetFromRoot,
      constrainingRect: LayoutRectWrapper.infiniteRect())
    if clipRect.isInfinite() {
      return clipRect
    }

    if renderer().hasClip() {
      if let box = renderer() as? RenderBoxWrapper {
        // CSS clip may be larger than our border box.
        let cssClipRect = box.clipRect(location: LayoutPointWrapper(), fragment: nil)
        clipExceedsBounds =
          !cssClipRect.isEmpty()
          && (clipRect.width() < cssClipRect.width() || clipRect.height() < cssClipRect.height())
      }
    }

    clipRect.move(size: -offsetFromRoot)
    return clipRect
  }

  func clipCrossesPaintingBoundary() -> Bool {
    return CPtrToInt(parent()!.enclosingPaginationLayer(mode: .IncludeCompositedPaginatedLayers)?.p)
      != CPtrToInt(enclosingPaginationLayer(mode: .IncludeCompositedPaginatedLayers)?.p)
      || CPtrToInt(parent()!.enclosingCompositingLayerForRepaint().layer?.p)
        != CPtrToInt(enclosingCompositingLayerForRepaint().layer?.p)
  }

  // Pass offsetFromRoot if known.
  func intersectsDamageRect(
    layerBounds: LayoutRectWrapper, damageRect: LayoutRectWrapper, rootLayer: RenderLayerWrapper?,
    offsetFromRoot: LayoutSizeWrapper, cachedBoundingBox: LayoutRectWrapper? = nil
  ) -> Bool {
    // Always examine the canvas and the root.
    // FIXME: Could eliminate the isDocumentElementRenderer() check if we fix background painting so that the RenderView
    // paints the root's background.
    if isRenderViewLayer || renderer().isDocumentElementRenderer() {
      return true
    }

    if damageRect.isInfinite() {
      return true
    }

    if damageRect.isEmpty() {
      return false
    }

    // If we aren't an inline flow, and our layer bounds do intersect the damage rect, then we can return true.
    if !renderer().isRenderInline() && layerBounds.intersects(other: damageRect) {
      return true
    }

    // Otherwise we need to compute the bounding box of this single layer and see if it intersects
    // the damage rect. It's possible the fragment computed the bounding box already, in which case we
    // can use the cached value.
    if let cachedBoundingBox = cachedBoundingBox {
      return cachedBoundingBox.intersects(other: damageRect)
    }

    return boundingBox(ancestorLayer: rootLayer, offsetFromRoot: offsetFromRoot).intersects(
      other: damageRect)
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

  private static let defaultCalculateLayerBoundsFlags: CalculateLayerBoundsFlag = [
    .IncludeSelfTransform, .UseLocalClipRectIfPossible, .IncludePaintedFilterOutsets,
    .UseFragmentBoxesExcludingCompositing,
  ]

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

  // Returns the 'reference box' used for clip-path handling (different rules for inlines, wrt. to boxes).
  func referenceBoxRectForClipPath(
    boxType: CSSBoxType, offsetFromRoot: LayoutSizeWrapper, rootRelativeBounds: LayoutRectWrapper
  ) -> FloatRectWrapper {
    var isReferenceBox = false

    if renderer().document().settings().layerBasedSVGEngineEnabled()
      && renderer().isSVGLayerAwareRenderer()
    {
      isReferenceBox = true
    } else {
      isReferenceBox = renderer().isRenderBox()
    }

    // FIXME: Support different reference boxes for inline content.
    // https://bugs.webkit.org/show_bug.cgi?id=129047
    if !isReferenceBox {
      return rootRelativeBounds.FloatRect()
    }

    var referenceBoxRect = renderer().referenceBoxRect(boxType: boxType)
    referenceBoxRect.move(delta: offsetFromRoot.FloatSize())
    return referenceBoxRect
  }

  // Can pass offsetFromRoot if known.
  func calculateLayerBounds(
    ancestorLayer: RenderLayerWrapper?, offsetFromRoot: LayoutSizeWrapper,
    flags: CalculateLayerBoundsFlag = RenderLayerWrapper.defaultCalculateLayerBoundsFlags
  ) -> LayoutRectWrapper {
    if !isSelfPaintingLayer {
      return LayoutRectWrapper()
    }

    // FIXME: This could be improved to do a check like hasVisibleNonCompositingDescendantLayers() (bug 92580).
    if flags.contains(.ExcludeHiddenDescendants) && CPtrToInt(p) != CPtrToInt(ancestorLayer?.p)
      && !hasVisibleContent && !hasVisibleDescendant
    {
      return LayoutRectWrapper()
    }

    if isRenderViewLayer {
      // The root layer is always just the size of the document.
      return LayoutRectWrapper(rect: renderer().view().unscaledDocumentRect())
    }

    var boundingBoxRect = localBoundingBox(flags: flags.union([.IncludeRootBackgroundPaintingArea]))
    if renderer().view().frameView().hasFlippedBlockRenderers() {
      if let box = renderer() as? RenderBoxWrapper {
        box.flipForWritingMode(rect: &boundingBoxRect)
      } else {
        renderer().containingBlock()!.flipForWritingMode(rect: &boundingBoxRect)
      }
    }

    var unionBounds = boundingBoxRect

    if flags.contains(.UseLocalClipRectIfPossible)
      || flags.contains(.UseLocalClipRectExcludingCompositingIfPossible)
    {
      var clipExceedsBounds = false
      var localClipRect = self.localClipRect(
        clipExceedsBounds: &clipExceedsBounds,
        mode: flags.contains(.UseLocalClipRectExcludingCompositingIfPossible)
          ? .ExcludeCompositingState : .IncludeCompositingState)
      if !localClipRect.isInfinite() && !clipExceedsBounds {
        if flags.contains(.IncludeSelfTransform) && paintsWithTransform(paintBehavior: .Normal) {
          localClipRect = transform!.mapRect(r: localClipRect)
        }

        localClipRect.move(size: offsetFromAncestor(ancestorLayer: ancestorLayer))
        return localClipRect
      }
    }

    // FIXME: should probably just pass 'flags' down to descendants.
    let descendantFlags =
      flags.contains(.PreserveAncestorFlags)
      ? flags
      : RenderLayerWrapper.defaultCalculateLayerBoundsFlags.union(
        flags.intersection([.ExcludeHiddenDescendants, .IncludeCompositedDescendants]))

    updateLayerListsIfNeeded()

    if let reflection = reflectionLayer() {
      if !reflection.isComposited() {
        let childUnionBounds = reflection.calculateLayerBounds(
          ancestorLayer: self, offsetFromRoot: reflection.offsetFromAncestor(ancestorLayer: self),
          flags: descendantFlags)
        unionBounds.unite(other: childUnionBounds)
      }
    }

    assert(isStackingContext() || positiveZOrderLayers().size() == 0)

    for childLayer in negativeZOrderLayers() {
      computeLayersUnion(
        childLayer: childLayer, unionBounds: &unionBounds, flags: flags,
        descendantFlags: descendantFlags)
    }

    for childLayer in positiveZOrderLayers() {
      computeLayersUnion(
        childLayer: childLayer, unionBounds: &unionBounds, flags: flags,
        descendantFlags: descendantFlags)
    }

    for childLayer in normalFlowLayers() {
      computeLayersUnion(
        childLayer: childLayer, unionBounds: &unionBounds, flags: flags,
        descendantFlags: descendantFlags)
    }

    if flags.contains(.IncludeFilterOutsets)
      || (flags.contains(.IncludePaintedFilterOutsets) && paintsWithFilters())
    {
      unionBounds.expand(box: toLayoutBoxExtent(extent: filterOutsets()))
    }

    if flags.contains(.IncludeSelfTransform) && paintsWithTransform(paintBehavior: .Normal) {
      boundingBoxRect = transform!.mapRect(r: boundingBoxRect)
      unionBounds = transform!.mapRect(r: unionBounds)
    }
    unionBounds.move(size: offsetFromRoot)
    return unionBounds
  }

  private func computeLayersUnion(
    childLayer: RenderLayerWrapper, unionBounds: inout LayoutRectWrapper,
    flags: CalculateLayerBoundsFlag, descendantFlags: CalculateLayerBoundsFlag
  ) {
    if !flags.contains(.IncludeCompositedDescendants)
      && (childLayer.isComposited() || childLayer.paintsIntoProvidedBacking())
    {
      return
    }
    let childBounds = childLayer.calculateLayerBounds(
      ancestorLayer: self, offsetFromRoot: childLayer.offsetFromAncestor(ancestorLayer: self),
      flags: descendantFlags)
    // Ignore child layer (and behave as if we had overflow: hidden) when it is positioned off the parent layer so much
    // that we hit the max LayoutUnit value.
    unionBounds.checkedUnite(other: childBounds)
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

  func renderableTransform(paintBehavior: PaintBehavior) -> TransformationMatrix {
    if let matrix = transform {
      if paintBehavior.contains(.FlattenCompositingLayers) {
        makeMatrixRenderable(matrix: matrix, has3DRendering: false)
        return matrix
      }

      return matrix
    }

    return TransformationMatrix()
  }

  func has3DTransform() -> Bool {
    if let transform = transform {
      return !transform.isAffine()
    }
    return false
  }

  func hasTransformedAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func participatesInPreserve3D() -> Bool {
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

  func paintsIntoProvidedBacking() -> Bool { return backingProviderLayer != nil }

  func usesCompositedScrolling() -> Bool {
    return m_scrollableArea?.usesCompositedScrolling() ?? false
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
    return transform != nil
      && (paintBehavior.contains(.FlattenCompositingLayers) || paintsToWindow)
  }

  func shouldPaintMask(paintBehavior: PaintBehavior, paintFlags: PaintLayerFlag) -> Bool {
    if !renderer().hasMask() {
      return false
    }

    let paintsToWindow = !isComposited() || backing!.paintsIntoWindow()
    if paintsToWindow || paintBehavior.contains(.FlattenCompositingLayers) {
      return true
    }

    return paintFlags.contains(.PaintingCompositingMaskPhase)
  }

  func shouldApplyClipPath(paintBehavior: PaintBehavior, paintFlags: PaintLayerFlag) -> Bool {
    if !renderer().hasClipPath() {
      return false
    }

    let paintsToWindow = !isComposited() || backing!.paintsIntoWindow()
    if paintsToWindow || paintBehavior.contains(.FlattenCompositingLayers) {
      return true
    }

    return paintFlags.contains(.PaintingCompositingClipPathPhase)
      || paintFlags.contains(.CollectingEventRegion)
  }

  func paintsWithFilters() -> Bool {
    let filter = renderer().style().filter()
    if filter.isEmpty() {
      return false
    }

    if renderer().isRenderOrLegacyRenderSVGRoot() && filter.isReferenceFilter() {
      return false
    }

    if RenderLayerFilters.isIdentity(renderer: renderer()) {
      return false
    }

    if !isComposited() {
      return true
    }

    return !backing!.canCompositeFilters()
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

  enum ViewportConstrainedNotCompositedReason {
    case NoNotCompositedReason
    case NotCompositedForBoundsOutOfView
    case NotCompositedForNonViewContainer
    case NotCompositedForNoVisibleContent
  }

  func setIsHiddenByOverflowTruncation(isHidden: Bool) {
    wk_interop.RenderLayer_setIsHiddenByOverflowTruncation(p, isHidden)
  }

  private func updateZOrderLists() {
    if !zOrderListsDirty {
      return
    }

    if !isStackingContext() {
      clearZOrderLists()
      zOrderListsDirty = false
      return
    }

    rebuildZOrderLists()
  }

  private func rebuildZOrderLists() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func clearZOrderLists() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateNormalFlowList() {
    if !normalFlowListDirty {
      return
    }

    var child = firstChild()
    while child != nil {
      // Ignore non-overflow layers and reflections.
      if child!.isNormalFlowOnly && !isReflectionLayer(layer: child!) {
        if normalFlowList == nil {
          normalFlowList = []
        }
        normalFlowList!.append(child!)
        child!.setWasIncludedInZOrderTree()
      }
      child = child!.nextSibling()
    }

    // TODO(asuhan): shrink capacity to size

    normalFlowListDirty = false
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

    var rootLayer: RenderLayerWrapper?
    let subtreePaintRoot: RenderObjectWrapper?  // Only paint descendants of this object.
    var paintDirtyRect: LayoutRectWrapper  // Relative to rootLayer;
    var subpixelOffset: LayoutSizeWrapper
    let overlapTestRequests: OverlapTestRequestMap?
    var paintBehavior: PaintBehavior
    var requireSecurityOriginAccessForWidgets: Bool
    var clipToDirtyRect: Bool = true
    let regionContext: RegionContext? = nil
  }

  private func paintOffsetForRenderer(
    fragment: LayerFragment, paintingInfo: LayerPaintingInfo
  ) -> LayoutPointWrapper {
    return toLayoutPoint(
      size: fragment.layerBounds.location() - rendererLocation() + paintingInfo.subpixelOffset)
  }

  // Compute, cache and return clip rects computed with the given layer as the root.
  private func updateClipRects(clipRectsContext: ClipRectsContext) -> ClipRects {
    let clipRectsType = clipRectsContext.clipRectsType
    if let clipRectsCache = clipRectsCache,
      let clipRects = clipRectsCache.getClipRects(
        clipRectsType: clipRectsType, respectOverflowClip: clipRectsContext.respectOverflowClip())
    {
      return clipRects
    }

    if clipRectsCache == nil {
      clipRectsCache = ClipRectsCache()
    }

    // For transformed layers, the root layer was shifted to be us, so there is no need to
    // examine the parent. We want to cache clip rects with us as the root.
    let parentClipRects =
      (CPtrToInt(clipRectsContext.rootLayer?.p) != CPtrToInt(p) && parent() != nil)
      ? self.parentClipRects(clipRectsContext: clipRectsContext) : nil

    var clipRects = ClipRects.create()
    calculateClipRects(clipRectsContext: clipRectsContext, clipRects: &clipRects)

    if parentClipRects != nil && parentClipRects! == clipRects {
      clipRectsCache!.setClipRects(
        clipRectsType: clipRectsType, respectOverflowClip: clipRectsContext.respectOverflowClip(),
        clipRects: parentClipRects!)
      return parentClipRects!
    }
    clipRectsCache!.setClipRects(
      clipRectsType: clipRectsType, respectOverflowClip: clipRectsContext.respectOverflowClip(),
      clipRects: clipRects)
    return clipRects
  }

  // Compute and return the clip rects. If useCached is true, will used previously computed clip rects on ancestors
  // (rather than computing them all from scratch up the parent chain).
  private func calculateClipRects(clipRectsContext: ClipRectsContext, clipRects: inout ClipRects) {
    if parent() == nil {
      // The root layer's clip rect is always infinite.
      clipRects.reset()
      return
    }

    let clipRectsType = clipRectsContext.clipRectsType
    let useCached = clipRectsType != .TemporaryClipRects

    // For transformed layers, the root layer was shifted to be us, so there is no need to
    // examine the parent. We want to cache clip rects with us as the root.

    // Ensure that our parent's clip has been calculated so that we can examine the values.
    if let parentLayer = CPtrToInt(clipRectsContext.rootLayer?.p) != CPtrToInt(p) ? parent() : nil {
      if useCached, let parentClipRects = parentLayer.clipRects(context: clipRectsContext) {
        clipRects = parentClipRects
      } else {
        var parentContext = clipRectsContext

        if (parentContext.clipRectsType != .TemporaryClipRects
          && parentContext.clipRectsType != .AbsoluteClipRects) && clipCrossesPaintingBoundary()
        {
          parentContext.clipRectsType = .TemporaryClipRects
        }

        parentLayer.calculateClipRects(clipRectsContext: parentContext, clipRects: &clipRects)
      }
    } else {
      clipRects.reset()
    }

    // A fixed object is essentially the root of its containing block hierarchy, so when
    // we encounter such an object, we reset our clip rects to the fixedClipRect.
    if renderer().isFixedPositioned() {
      clipRects.posClipRect = clipRects.fixedClipRect
      clipRects.overflowClipRect = clipRects.fixedClipRect
      clipRects.fixed = true
    } else if renderer().isInFlowPositioned() {
      clipRects.posClipRect = clipRects.overflowClipRect
    } else if renderer().shouldUsePositionedClipping() {
      clipRects.overflowClipRect = clipRects.posClipRect
    }

    if (renderer().hasNonVisibleOverflow()
      && (clipRectsContext.respectOverflowClip()
        || CPtrToInt(p) != CPtrToInt(clipRectsContext.rootLayer?.p)))
      || renderer().hasClip()
    {
      // This layer establishes a clip of some kind.

      // FIXME: Transforming a clip doesn't make a whole lot of sense, since it we have to round out to the
      // bounding box of the transformed quad.
      // It would be better for callers to transform rects into the coordinate space of the nearest clipped layer, apply
      // the clip in local space, and then repeat until the required coordinate space is reached.
      let needsTransform =
        clipRectsType == .AbsoluteClipRects
        ? m_hasTransformedAncestor || !canUseOffsetFromAncestor()
        : !canUseOffsetFromAncestor(ancestor: clipRectsContext.rootLayer!)

      var offset = LayoutPointWrapper()
      if !needsTransform {
        offset = toLayoutPoint(
          size: offsetFromAncestor(
            ancestorLayer: clipRectsContext.rootLayer, adjustForColumns: .AdjustForColumns))
      }

      if clipRects.fixed
        && CPtrToInt(clipRectsContext.rootLayer!.renderer().p) == CPtrToInt(renderer().view().p)
      {
        offset -= toLayoutSize(
          point: renderer().view().frameView().scrollPositionForFixedPosition())
      }

      if renderer().hasNonVisibleOverflow() {
        var newOverflowClip = ClipRect(
          rect: rendererOverflowClipRectForChildLayers(
            location: LayoutPointWrapper(), fragment: nil,
            relevancy: clipRectsContext.overlayScrollbarSizeRelevancy()))
        if needsTransform {
          newOverflowClip = ClipRect(
            rect: LayoutRectWrapper(
              r: renderer().localToContainerQuad(
                localQuad: FloatQuad(inRect: newOverflowClip.rect.FloatRect()),
                container: clipRectsContext.rootLayer!.renderer()
              ).boundingBox()))
        }
        newOverflowClip.moveBy(point: offset)
        newOverflowClip.affectedByRadius = renderer().style().hasBorderRadius()
        clipRects.overflowClipRect = intersection(
          a: newOverflowClip, b: clipRects.overflowClipRect)
        if renderer().canContainAbsolutelyPositionedObjects() {
          clipRects.posClipRect = intersection(a: newOverflowClip, b: clipRects.posClipRect)
        }
        if renderer().canContainFixedPositionObjects() {
          clipRects.fixedClipRect = intersection(a: newOverflowClip, b: clipRects.fixedClipRect)
        }
      }
      if renderer().hasClip(), let box = renderer() as? RenderBoxWrapper {
        var newPosClip = box.clipRect(location: LayoutPointWrapper(), fragment: nil)
        if needsTransform {
          newPosClip = LayoutRectWrapper(
            r: renderer().localToContainerQuad(
              localQuad: FloatQuad(inRect: newPosClip.FloatRect()),
              container: clipRectsContext.rootLayer!.renderer()
            ).boundingBox())
        }
        newPosClip.moveBy(offset: offset)
        let newPosClipCR = ClipRect(rect: newPosClip)
        clipRects.posClipRect = intersection(a: newPosClipCR, b: clipRects.posClipRect)
        clipRects.overflowClipRect = intersection(a: newPosClipCR, b: clipRects.overflowClipRect)
        clipRects.fixedClipRect = intersection(a: newPosClipCR, b: clipRects.fixedClipRect)
      }
    } else if renderer().hasNonVisibleOverflow() && transform != nil
      && renderer().style().hasBorderRadius()
    {
      clipRects.setOverflowClipRectAffectedByRadius()
    }
  }

  private func clipRects(context: ClipRectsContext) -> ClipRects? {
    if let clipRectsCache = clipRectsCache {
      return clipRectsCache.getClipRects(
        clipRectsType: context.clipRectsType, respectOverflowClip: context.respectOverflowClip())
    }
    return nil
  }

  private func clipRectRelativeToAncestor(
    ancestor: RenderLayerWrapper?, offsetFromAncestor: LayoutSizeWrapper,
    constrainingRect: LayoutRectWrapper, temporaryClipRects: Bool = false
  ) -> LayoutRectWrapper {
    var layerBounds = LayoutRectWrapper()
    var backgroundRect = ClipRect()
    var foregroundRect = ClipRect()
    let clipRectType: ClipRectsType =
      (m_enclosingPaginationLayer == nil
        || CPtrToInt(m_enclosingPaginationLayer!.p) == CPtrToInt(ancestor?.p))
        && !temporaryClipRects
      ? .PaintingClipRects : .TemporaryClipRects
    let clipRectsContext = ClipRectsContext(inRootLayer: ancestor, inClipRectsType: clipRectType)
    calculateRects(
      clipRectsContext: clipRectsContext, paintDirtyRect: constrainingRect,
      layerBounds: &layerBounds,
      backgroundRect: &backgroundRect, foregroundRect: &foregroundRect,
      offsetFromRoot: offsetFromAncestor)
    return backgroundRect.rect
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

  private func rendererBorderBoxRectInFragment(
    fragment: RenderFragmentContainerWrapper?,
    flags: RenderBoxWrapper.RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> LayoutRectWrapper {
    if let box = renderer() as? RenderBoxWrapper {
      return box.borderBoxRectInFragment(fragment: fragment, flags: flags)
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.borderBoxRectInFragmentEquivalent(fragment: fragment, flags: flags)
    }
    return LayoutRectWrapper()
  }

  private func rendererVisualOverflowRect() -> LayoutRectWrapper {
    if let box = renderer() as? RenderBoxWrapper {
      return box.visualOverflowRect()
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.visualOverflowRectEquivalent()
    }
    return LayoutRectWrapper()
  }

  private func rendererOverflowClipRect(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?,
    relevancy: OverlayScrollbarSizeRelevancy
  ) -> LayoutRectWrapper {
    if let box = renderer() as? RenderBoxWrapper {
      return box.overflowClipRect(location: location, fragment: fragment, relevancy: relevancy)
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.overflowClipRect(
        location: location, fragment: fragment, relevancy: relevancy)
    }
    return LayoutRectWrapper()
  }

  private func rendererOverflowClipRectForChildLayers(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?,
    relevancy: OverlayScrollbarSizeRelevancy
  )
    -> LayoutRectWrapper
  {
    if let box = renderer() as? RenderBoxWrapper {
      return box.overflowClipRectForChildLayers(
        location: location, fragment: fragment, relevancy: relevancy)
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.overflowClipRectForChildLayers(
        location: location, fragment: fragment, relevancy: relevancy)
    }
    return LayoutRectWrapper()
  }

  private func rendererHasVisualOverflow() -> Bool {
    if let box = renderer() as? RenderBoxWrapper {
      return box.hasVisualOverflow()
    }
    if let svgModelObject = renderer() as? RenderSVGModelObjectWrapper {
      return svgModelObject.hasVisualOverflow()
    }
    return false
  }

  private func setupFontSubpixelQuantization(context: GraphicsContextWrapper) -> (Bool, Bool) {
    if context.paintingDisabled() {
      return (false, true)
    }

    // FIXME: We shouldn't have to disable subpixel quantization for overflow clips or subframes once we scroll those
    // things on the scrolling thread.
    let didQuantizeFonts = context.shouldSubpixelQuantizeFonts()
    context.setShouldSubpixelQuantizeFonts(shouldSubpixelQuantizeFonts: false)
    return (true, didQuantizeFonts)
  }

  private func computeClipPath(
    offsetFromRoot: LayoutSizeWrapper, rootRelativeBoundsForNonBoxes: LayoutRectWrapper
  ) -> (PathWrapper, WindRule) {
    let style = renderer().style()

    if let clipPath = style.clipPath()! as? ShapePathOperation {
      let referenceBoxRect = referenceBoxRectForClipPath(
        boxType: clipPath.referenceBox, offsetFromRoot: offsetFromRoot,
        rootRelativeBounds: rootRelativeBoundsForNonBoxes)
      let snappedReferenceBoxRect = snapRectToDevicePixelsIfNeeded(
        rect: referenceBoxRect, renderer: renderer())
      return (
        clipPath.pathForReferenceRect(boundingRect: snappedReferenceBoxRect), clipPath.windRule()
      )
    }

    if let clipPath = style.clipPath()! as? BoxPathOperation,
      let box = renderer() as? RenderBoxWrapper
    {
      var shapeRect = computeRoundedRectForBoxShape(box: clipPath.referenceBox, renderer: box)
        .pixelSnappedRoundedRectForPainting(
          deviceScaleFactor: renderer().document().deviceScaleFactor())
      shapeRect.move(size: offsetFromRoot.FloatSize())

      return (
        clipPath.pathForReferenceRect(boundingRect: shapeRect), .NonZero
      )
    }

    return (PathWrapper(), .NonZero)
  }

  private func setupClipPath(
    context: GraphicsContextWrapper, stateSaver: GraphicsContextStateSaver,
    regionContextStateSaver: RegionContextStateSaver, paintingInfo: LayerPaintingInfo,
    paintFlags: inout PaintLayerFlag, offsetFromRoot: LayoutSizeWrapper
  ) {
    let isCollectingRegions =
      paintFlags.contains(.CollectingEventRegion)
      || (paintingInfo.regionContext is AccessibilityRegionContext)
    if !renderer().hasClipPath() || (context.paintingDisabled() && !isCollectingRegions)
      || paintingInfo.paintDirtyRect.isEmpty()
    {
      return
    }

    // Applying clip-path on <clipPath> enforces us to use mask based clipping, so return false here to disable path based clipping.
    // Furthermore if we're the child of a resource container (<clipPath> / <mask> / ...) disabled path based clipping.
    if enclosingSVGHiddenOrResourceContainer is RenderSVGResourceClipperWrapper {
      // If isPaintingSVGResourceLayer is true, this function was invoked via paintSVGResourceLayer() -- clipping on <clipPath> is already
      // handled in RenderSVGResourceClipper::applyMaskClipping(), so do not set paintSVGClippingMask to true here.
      if isPaintingSVGResourceLayer {
        paintFlags.remove(.PaintingSVGClippingMask)
      } else {
        paintFlags.update(with: .PaintingSVGClippingMask)
      }
      return
    }

    let clippedContentBounds = calculateLayerBounds(
      ancestorLayer: paintingInfo.rootLayer, offsetFromRoot: offsetFromRoot,
      flags: [.UseLocalClipRectIfPossible])

    let style = renderer().style()
    let paintingOffsetFromRoot = LayoutSizeWrapper(
      size: snapSizeToDevicePixel(
        size: offsetFromRoot + paintingInfo.subpixelOffset, location: LayoutPointWrapper(),
        pixelSnappingFactor: renderer().document().deviceScaleFactor()))
    let clipPath = style.clipPath()!
    if (clipPath is ShapePathOperation)
      || (clipPath is BoxPathOperation && renderer() is RenderBoxWrapper)
    {
      // clippedContentBounds is used as the reference box for inlines, which is also poorly specified: https://github.com/w3c/csswg-drafts/issues/6383.
      let (path, windRule) = computeClipPath(
        offsetFromRoot: paintingOffsetFromRoot, rootRelativeBoundsForNonBoxes: clippedContentBounds)

      if isCollectingRegions {
        regionContextStateSaver.pushClip(path: path)
        return
      }

      stateSaver.save()
      context.clipPath(path: path, clipRule: windRule)
      return
    }

    if let referenceClipPathOperation = style.clipPath() as? ReferencePathOperation {
      if let svgClipper = renderer().svgClipperResourceFromStyle() {
        if let graphicsElement = svgClipper.shouldApplyPathClipping() {
          stateSaver.save()
          var svgReferenceBox = FloatRectWrapper()
          var coordinateSystemOriginTranslation = FloatSize()
          if renderer().isSVGLayerAwareRenderer() {
            assert(paintingInfo.subpixelOffset.isZero())
            let boundingBoxTopLeftCorner = renderer().nominalSVGLayoutLocation()
            svgReferenceBox = renderer().objectBoundingBox()
            coordinateSystemOriginTranslation =
              (toLayoutPoint(size: offsetFromRoot) - boundingBoxTopLeftCorner).FloatSize()
          } else {
            let clipPathObjectBoundingBox = referenceBoxRectForClipPath(
              boxType: .BorderBox, offsetFromRoot: offsetFromRoot,
              rootRelativeBounds: clippedContentBounds)
            svgReferenceBox = snapRectToDevicePixels(
              rect: LayoutRectWrapper(r: clipPathObjectBoundingBox),
              pixelSnappingFactor: renderer().document().deviceScaleFactor())
          }

          if !coordinateSystemOriginTranslation.isZero() {
            context.translate(size: coordinateSystemOriginTranslation)
          }

          svgClipper.applyPathClipping(
            context: context, targetRenderer: renderer(), objectBoundingBox: svgReferenceBox,
            graphicsElement: graphicsElement)

          if !coordinateSystemOriginTranslation.isZero() {
            context.translate(size: -coordinateSystemOriginTranslation)
          }
          return
        } else {
          paintFlags.update(with: .PaintingSVGClippingMask)
          return
        }
      }

      if let clipperRenderer = ReferencedSVGResources.referencedClipperRenderer(
        treeScope: renderer().treeScopeForSVGReferences(), clipPath: referenceClipPathOperation)
      {
        // Use the border box as the reference box, even though this is not clearly specified: https://github.com/w3c/csswg-drafts/issues/5786.
        // clippedContentBounds is used as the reference box for inlines, which is also poorly specified: https://github.com/w3c/csswg-drafts/issues/6383.
        let referenceBox = referenceBoxRectForClipPath(
          boxType: .BorderBox, offsetFromRoot: offsetFromRoot,
          rootRelativeBounds: clippedContentBounds)
        let snappedReferenceBox = snapRectToDevicePixelsIfNeeded(
          rect: referenceBox, renderer: renderer())
        let offset = snappedReferenceBox.location()

        var snappedClippingBounds = snapRectToDevicePixelsIfNeeded(
          rect: clippedContentBounds, renderer: renderer())
        snappedClippingBounds.moveBy(delta: -offset)

        stateSaver.save()
        context.translate(p: offset)
        clipperRenderer.applyClippingToContext(
          context: context, renderer: renderer(),
          objectBoundingBox: FloatRectWrapper(location: FloatPoint(), size: referenceBox.size()),
          clippedContentBounds: snappedClippingBounds, usedZoom: renderer().style().usedZoom())
        context.translate(p: -offset)

        // FIXME: Support event regions.
      }
    }
  }

  private func filtersForPainting(context: GraphicsContextWrapper, paintFlags: PaintLayerFlag)
    -> RenderLayerFilters?
  {
    if context.paintingDisabled() {
      return nil
    }

    if paintFlags.contains(.PaintingOverlayScrollbars) {
      return nil
    }

    if !paintsWithFilters() {
      return nil
    }

    return filters
  }

  private func setupFilters(
    destinationContext: GraphicsContextWrapper, paintingInfo: inout LayerPaintingInfo,
    paintFlags: PaintLayerFlag, offsetFromRoot: LayoutSizeWrapper, backgroundRect: ClipRect
  ) -> GraphicsContextWrapper? {
    if let paintingFilters = filtersForPainting(context: destinationContext, paintFlags: paintFlags)
    {
      var filterRepaintRect = paintingFilters.dirtySourceRect
      filterRepaintRect.move(size: offsetFromRoot)

      let rootRelativeBounds = calculateLayerBounds(
        ancestorLayer: paintingInfo.rootLayer, offsetFromRoot: offsetFromRoot, flags: [])

      if let filterContext =
        paintingFilters.beginFilterEffect(
          renderer: renderer(), context: destinationContext,
          filterBoxRect: LayoutRectWrapper(rect: enclosingIntRect(rect: rootRelativeBounds)),
          dirtyRect: LayoutRectWrapper(rect: enclosingIntRect(rect: paintingInfo.paintDirtyRect)),
          layerRepaintRect: LayoutRectWrapper(rect: enclosingIntRect(rect: filterRepaintRect)),
          clipRect: backgroundRect.rect)
      {
        paintingInfo.paintDirtyRect = paintingFilters.repaintRect

        // If the filter needs the full source image, we need to avoid using the clip rectangles.
        // Otherwise, if for example this layer has overflow:hidden, a drop shadow will not compute correctly.
        // Note that we will still apply the clipping on the final rendering of the filter.
        paintingInfo.clipToDirtyRect = !paintingFilters.hasFilterThatMovesPixels()

        paintingInfo.requireSecurityOriginAccessForWidgets =
          paintingFilters.hasFilterThatShouldBeRestrictedBySecurityOrigin()

        return filterContext
      }

      return nil
    }
    return nil
  }

  private func applyFilters(
    originalContext: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo,
    behavior: PaintBehavior, backgroundRect: ClipRect
  ) {
    let stateSaver = GraphicsContextStateSaver(context: originalContext, saveAndRestore: false)
    let needsClipping = filters!.hasSourceImage()

    if needsClipping {
      let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)

      clipToRect(
        context: originalContext, stateSaver: stateSaver,
        regionContextStateSaver: regionContextStateSaver, paintingInfo: paintingInfo,
        paintBehavior: behavior, clipRect: backgroundRect
      )
    }

    filters!.applyFilterEffect(destinationContext: originalContext)
  }

  private static func paintForFixedRootBackground(
    layer: RenderLayerWrapper, paintFlags: PaintLayerFlag
  )
    -> Bool
  {
    return layer.renderer().isDocumentElementRenderer()
      && paintFlags.contains(.PaintingRootBackgroundOnly)
  }

  private func paintLayer(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    var paintFlags = paintFlags
    if paintsIntoDifferentCompositedDestination(paintFlags: paintFlags) {
      if !context.performingPaintInvalidation()
        && !paintingInfo.paintBehavior.contains(.FlattenCompositingLayers)
      {
        return
      }

      paintFlags.update(with: .TemporaryClipRects)
    }

    if viewportConstrainedNotCompositedReason == .NotCompositedForBoundsOutOfView
      && !paintingInfo.paintBehavior.contains(.Snapshotting)
    {
      // Don't paint out-of-view viewport constrained layers (when doing prepainting) because they will never be visible
      // unless their position or viewport size is changed.
      assert(renderer().isFixedPositioned())
      return
    }

    paintLayerWithEffects(context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
  }

  private func shouldContinuePaint(paintFlags: PaintLayerFlag) -> Bool {
    return backing!.paintsIntoWindow()
      || backing!.paintsIntoCompositedAncestor()
      || shouldDoSoftwarePaint(
        layer: self, paintingReflection: paintFlags.contains(.PaintingReflection))
      || RenderLayerWrapper.paintForFixedRootBackground(layer: self, paintFlags: paintFlags)
  }

  private func paintsIntoDifferentCompositedDestination(paintFlags: PaintLayerFlag) -> Bool {
    if paintsIntoProvidedBacking() {
      return true
    }

    if isComposited() && !shouldContinuePaint(paintFlags: paintFlags) {
      return true
    }

    return false
  }

  private func paintLayerWithEffects(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    // Non self-painting leaf layers don't need to be painted as their renderer() should properly paint itself.
    if !isSelfPaintingLayer && !hasSelfPaintingLayerDescendant {
      return
    }

    if shouldSuppressPaintingLayer(layer: self) {
      return
    }

    // If this layer is totally invisible then there is nothing to paint.
    if renderer().opacity() == 0 {
      return
    }

    var paintFlags = paintFlags
    if paintsWithTransparency(paintBehavior: paintingInfo.paintBehavior) {
      paintFlags.update(with: .HaveTransparency)
    }

    // PaintLayerFlag::AppliedTransform is used in RenderReplica, to avoid applying the transform twice.
    if paintsWithTransform(paintBehavior: paintingInfo.paintBehavior)
      && !paintFlags.contains(.AppliedTransform)
    {
      let layerTransform = renderableTransform(paintBehavior: paintingInfo.paintBehavior)
      // If the transform can't be inverted, then don't paint anything.
      if !layerTransform.isInvertible() {
        return
      }

      // If we have a transparency layer enclosing us and we are the root of a transform, then we need to establish the transparency
      // layer from the parent now, assuming there is a parent
      if paintFlags.contains(.HaveTransparency) {
        if CPtrToInt(p) != CPtrToInt(paintingInfo.rootLayer?.p), let parent = parent() {
          parent.beginTransparencyLayers(
            context: context, paintingInfo: paintingInfo, dirtyRect: paintingInfo.paintDirtyRect)
        } else {
          beginTransparencyLayers(
            context: context, paintingInfo: paintingInfo, dirtyRect: paintingInfo.paintDirtyRect)
        }
      }

      if enclosingPaginationLayer(mode: .ExcludeCompositedPaginatedLayers) != nil {
        paintTransformedLayerIntoFragments(
          context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
        return
      }

      // Make sure the parent's clip rects have been calculated.
      var clipRect = ClipRect(rect: paintingInfo.paintDirtyRect)
      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)
      if let parent = parent() {
        let options =
          paintFlags.contains(.PaintingOverflowContents)
          ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
          : RenderLayerWrapper.clipRectDefaultOptions
        let clipRectsContext = ClipRectsContext(
          inRootLayer: paintingInfo.rootLayer,
          inClipRectsType: paintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects,
          inOptions: options)
        clipRect = backgroundClipRect(clipRectsContext: clipRectsContext)
        clipRect.intersect(other: paintingInfo.paintDirtyRect)

        var paintBehavior: PaintBehavior = [.Normal]
        if paintFlags.contains(.PaintingOverflowContents) {
          paintBehavior.update(with: .CompositedOverflowScrollContent)
        }

        // Always apply SVG viewport clipping in coordinate system before the SVG viewBox transformation is applied.
        if let svgRoot = renderer() as? RenderSVGRootWrapper {
          if svgRoot.shouldApplyViewportClip() {
            var newRect = svgRoot.borderBoxRect()

            let offsetFromParent = offsetFromAncestor(ancestorLayer: clipRectsContext.rootLayer)
            let offsetForThisLayer = offsetFromParent + paintingInfo.subpixelOffset
            let devicePixelSnappedOffsetForThisLayer = toFloatSize(
              a: roundPointToDevicePixels(
                point: toLayoutPoint(size: offsetForThisLayer),
                pixelSnappingFactor: renderer().document().deviceScaleFactor())
            )
            newRect.move(
              dx: devicePixelSnappedOffsetForThisLayer.width,
              dy: devicePixelSnappedOffsetForThisLayer.height)

            clipRect.intersect(other: newRect)
          }
        }

        // Push the parent coordinate space's clip.
        parent.clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: paintingInfo,
          paintBehavior: paintBehavior, clipRect: clipRect)
      }

      paintLayerByApplyingTransform(
        context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
      return
    }

    paintLayerContentsAndReflection(
      context: context, paintingInfo: paintingInfo, paintFlags: paintFlags)
  }

  private func paintLayerContentsAndReflection(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    assert(isSelfPaintingLayer || hasSelfPaintingLayerDescendant)

    let localPaintFlags = paintFlags.subtracting(.AppliedTransform)

    // Paint the reflection first if we have one.
    if reflection != nil && !paintingInsideReflection {
      // Mark that we are now inside replica painting.
      paintingInsideReflection = true
      reflectionLayer()!.paintLayer(
        context: context, paintingInfo: paintingInfo,
        paintFlags: localPaintFlags.union(.PaintingReflection))
      paintingInsideReflection = false
    }

    paintLayerContents(
      context: context, paintingInfo: paintingInfo,
      paintFlags: localPaintFlags.union(
        RenderLayerWrapper.paintLayerPaintingCompositingAllPhasesFlags))
  }

  private func paintLayerByApplyingTransform(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag,
    translationOffset: LayoutSizeWrapper = LayoutSizeWrapper()
  ) {
    // This involves subtracting out the position of the layer in our current coordinate space, but preserving
    // the accumulated error for sub-pixel layout.
    // Note: The pixel-snapping logic is disabled for the whole SVG render tree, except the outermost <svg>.
    let deviceScaleFactor = renderer().document().deviceScaleFactor()
    var offsetFromParent = offsetFromAncestor(ancestorLayer: paintingInfo.rootLayer)
    offsetFromParent += translationOffset
    let transform = renderableTransform(paintBehavior: paintingInfo.paintBehavior).deepCopy()
    // Add the subpixel accumulation to the current layer's offset so that we can always snap the translateRight value to where the renderer() is supposed to be painting.
    let offsetForThisLayer = offsetFromParent + paintingInfo.subpixelOffset
    let alignedOffsetForThisLayer =
      rendererNeedsPixelSnapping(renderer: renderer())
      ? toFloatSize(
        a: roundPointToDevicePixels(
          point: toLayoutPoint(size: offsetForThisLayer), pixelSnappingFactor: deviceScaleFactor))
      : offsetForThisLayer.FloatSize()
    // We handle accumulated subpixels through nested layers here. Since the context gets translated to device pixels,
    // all we need to do is add the delta to the accumulated pixels coming from ancestor layers.
    // Translate the graphics context to the snapping position to avoid off-device-pixel positing.
    transform.translateRight(
      tx: Float64(alignedOffsetForThisLayer.width), ty: Float64(alignedOffsetForThisLayer.height))
    // Apply the transform.
    let oldTransform = context.getCTM()
    let affineTransform = transform.toAffineTransform()
    context.concatCTM(transform: affineTransform)

    if let regionContext = paintingInfo.regionContext {
      regionContext.pushTransform(transform: affineTransform)
    }

    // Only propagate the subpixel offsets to the descendant layers, if we're not the root
    // of a SVG subtree, where no pixel snapping is applied -- only the outermost <svg> layer
    // is pixel-snapped "as whole", if it's part of a compound document, e.g. inline SVG in HTML.
    let adjustedSubpixelOffset =
      rendererNeedsPixelSnapping(renderer: renderer()) && !renderer().isRenderSVGRoot()
      ? offsetForThisLayer - LayoutSizeWrapper(size: alignedOffsetForThisLayer)
      : LayoutSizeWrapper()

    // Now do a paint with the root layer shifted to be us.
    var transformedPaintingInfo = paintingInfo
    transformedPaintingInfo.rootLayer = self
    if !transformedPaintingInfo.paintDirtyRect.isInfinite() {
      transformedPaintingInfo.paintDirtyRect = LayoutRectWrapper(
        r: encloseRectToDevicePixels(
          rect: (transform.inverse() ?? TransformationMatrix()).mapRect(
            r: paintingInfo.paintDirtyRect),
          pixelSnappingFactor: deviceScaleFactor))
    }
    transformedPaintingInfo.subpixelOffset = adjustedSubpixelOffset
    paintLayerContentsAndReflection(
      context: context, paintingInfo: transformedPaintingInfo, paintFlags: paintFlags)

    if let regionContext = paintingInfo.regionContext {
      regionContext.popTransform()
    }

    context.setCTM(transform: oldTransform)
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
        paintingInfo: paintingInfo, paintFlags: &localPaintFlags,
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

    let paintBehavior = paintBehaviorForContents(
      paintingInfo: paintingInfo, localPaintFlags: localPaintFlags,
      isPaintingOverflowContents: isPaintingOverflowContents,
      isCollectingEventRegion: isCollectingEventRegion,
      isPaintingCompositedForeground: isPaintingCompositedForeground,
      isPaintingCompositedBackground: isPaintingCompositedBackground)

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

      if var overlapTestRequests = localPaintingInfo.overlapTestRequests, isSelfPaintingLayer {
        performOverlapTests(
          overlapTestRequests: &overlapTestRequests,
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
      if shouldPaintMask(paintBehavior: paintingInfo.paintBehavior, paintFlags: localPaintFlags) {
        // Paint the mask for the fragments.
        paintMaskForFragments(
          layerFragments: layerFragments, context: context, localPaintingInfo: paintingInfo,
          paintBehavior: paintBehavior, subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }

      if applySVGClippingMask
        || (!paintFlags.contains(.PaintingCompositingMaskPhase)
          && paintFlags.contains(.PaintingCompositingClipPathPhase))
      {
        // Re-use paintChildClippingMaskForFragments to paint black for the compositing clipping mask.
        paintChildClippingMaskForFragments(
          layerFragments: layerFragments, context: context, localPaintingInfo: paintingInfo,
          paintBehavior: paintBehavior, subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }

      if localPaintFlags.contains(.PaintingChildClippingMaskPhase) {
        // Paint the border radius mask for the fragments.
        paintChildClippingMaskForFragments(
          layerFragments: layerFragments, context: context, localPaintingInfo: paintingInfo,
          paintBehavior: paintBehavior, subtreePaintRootForRenderer: subtreePaintRootForRenderer)
      }
    }

    // End our transparency layer
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

    // Re-set this to whatever it was before we painted the layer.
    if needToAdjustSubpixelQuantization {
      context.setShouldSubpixelQuantizeFonts(shouldSubpixelQuantizeFonts: didQuantizeFonts)
    }
  }

  private func paintLayerHasVisibleContent() -> Bool {
    if !hasVisibleContent {
      return false
    }

    if enclosingSVGHiddenOrResourceContainer == nil {
      return true
    }

    // Hidden SVG containers (<defs> / <symbol> ...) and their children are never painted directly.
    if !(enclosingSVGHiddenOrResourceContainer is RenderSVGResourceContainerWrapper) {
      return false
    }

    // SVG resource layers and their children are only painted indirectly, via paintSVGResourceLayer().
    assert(enclosingSVGHiddenOrResourceContainer!.hasLayer())
    return enclosingSVGHiddenOrResourceContainer!.layer()!.isPaintingSVGResourceLayer
  }

  private func paintBehaviorForContents(
    paintingInfo: LayerPaintingInfo, localPaintFlags: PaintLayerFlag,
    isPaintingOverflowContents: Bool, isCollectingEventRegion: Bool,
    isPaintingCompositedForeground: Bool, isPaintingCompositedBackground: Bool
  ) -> PaintBehavior {
    let flagsToCopy: PaintBehavior = [
      .FlattenCompositingLayers, .Snapshotting, .ExcludeSelection, .ExcludeReplacedContent,
    ]
    var paintBehavior = paintingInfo.paintBehavior.intersection(flagsToCopy)

    if localPaintFlags.contains(.PaintingSkipRootBackground) {
      paintBehavior.update(with: .SkipRootBackground)
    } else if localPaintFlags.contains(.PaintingRootBackgroundOnly) {
      paintBehavior.update(with: .RootBackgroundOnly)
    }

    // FIXME: This seems wrong. We should retain the DefaultAsynchronousImageDecode flag for all RenderLayers painted into the root tile cache.
    if paintingInfo.paintBehavior.contains(.DefaultAsynchronousImageDecode) && isRenderViewLayer {
      paintBehavior.update(with: .DefaultAsynchronousImageDecode)
    }

    if isPaintingOverflowContents {
      paintBehavior.update(with: .CompositedOverflowScrollContent)
    }

    if isCollectingEventRegion {
      paintBehavior = paintBehavior.intersection([.CompositedOverflowScrollContent])
      if isPaintingCompositedForeground {
        paintBehavior.update(with: .EventRegionIncludeForeground)
      }
      if isPaintingCompositedBackground {
        paintBehavior.update(with: .EventRegionIncludeBackground)
      }
    }

    return paintBehavior
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
    for fragment in fragments {
      fragment.shouldPaintContent = shouldPaintContent
      if CPtrToInt(p) != CPtrToInt(localPaintingInfo.rootLayer?.p)
        || !localPaintFlags.contains(.PaintingOverflowContents)
      {
        let newOffsetFromRoot = offsetFromRoot + fragment.paginationOffset
        fragment.shouldPaintContent =
          fragment.shouldPaintContent
          && intersectsDamageRect(
            layerBounds: fragment.layerBounds, damageRect: fragment.backgroundRect.rect,
            rootLayer: localPaintingInfo.rootLayer,
            offsetFromRoot: newOffsetFromRoot, cachedBoundingBox: fragment.boundingBox)
      }
    }
  }

  private func paintBackgroundForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    contextForTransparencyLayer: GraphicsContextWrapper,
    transparencyPaintDirtyRect: LayoutRectWrapper, haveTransparency: Bool,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    for fragment in layerFragments {
      if !fragment.shouldPaintContent {
        continue
      }

      // Begin transparency layers lazily now that we know we have to paint something.
      if haveTransparency {
        beginTransparencyLayers(
          context: contextForTransparencyLayer, paintingInfo: localPaintingInfo,
          dirtyRect: transparencyPaintDirtyRect)
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if localPaintingInfo.clipToDirtyRect {
        // Paint our background first, before painting any child layers.
        // Establish the clip used to paint our background.
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior,
          clipRect: fragment.backgroundRect, rule: .DoNotIncludeSelfForBorderRadius)  // Background painting will handle clipping to self.
      }

      // Paint the background.
      // FIXME: Eventually we will collect the region from the fragment itself instead of just from the paint info.
      let paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .BlockBackground,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)
      renderer().paint(
        paintInfo: paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
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
    for fragment in layerFragments {
      if fragment.backgroundRect.isEmpty() {
        continue
      }

      // Paint our own outline
      let paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .SelfOutline,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      clipToRect(
        context: context, stateSaver: stateSaver,
        regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
        paintBehavior: paintBehavior,
        clipRect: fragment.backgroundRect, rule: .DoNotIncludeSelfForBorderRadius)
      renderer().paint(
        paintInfo: paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintOverflowControlsForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo
  ) {
    assert(m_scrollableArea != nil)

    for fragment in layerFragments {
      if fragment.backgroundRect.isEmpty() {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      clipToRect(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: localPaintingInfo, paintBehavior: [], clipRect: fragment.backgroundRect)
      m_scrollableArea!.paintOverflowControls(
        context: context,
        paintOffset: roundedIntPoint(
          point: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo)),
        damageRect: snappedIntRect(rect: fragment.backgroundRect.rect),
        paintingOverlayControls: true)
    }
  }

  private func paintMaskForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    for fragment in layerFragments {
      if !fragment.shouldPaintContent {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if localPaintingInfo.clipToDirtyRect {
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior,
          clipRect: fragment.backgroundRect, rule: .DoNotIncludeSelfForBorderRadius)  // Mask painting will handle clipping to self.
      }

      // Paint the mask.
      // FIXME: Eventually we will collect the region from the fragment itself instead of just from the paint info.
      let paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .Mask,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)
      renderer().paint(
        paintInfo: paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintChildClippingMaskForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior,
    subtreePaintRootForRenderer: RenderObjectWrapper?
  ) {
    for fragment in layerFragments {
      if !fragment.shouldPaintContent {
        continue
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(
        context: localPaintingInfo.regionContext)

      if localPaintingInfo.clipToDirtyRect {
        clipToRect(
          context: context, stateSaver: stateSaver,
          regionContextStateSaver: regionContextStateSaver, paintingInfo: localPaintingInfo,
          paintBehavior: paintBehavior,
          clipRect: fragment.foregroundRect, rule: .IncludeSelfForBorderRadius)  // Child clipping mask painting will handle clipping to self.
      }

      // Paint the clipped mask.
      let paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.backgroundRect.rect, newPhase: .ClippingMask,
        newPaintBehavior: paintBehavior,
        newSubtreePaintRoot: subtreePaintRootForRenderer, newOutlineObjects: nil,
        overlapTestRequests: nil, newPaintContainer: localPaintingInfo.rootLayer!.renderer(),
        enclosingSelfPaintingLayer: self)
      renderer().paint(
        paintInfo: paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
    }
  }

  private func paintTransformedLayerIntoFragments(
    context: GraphicsContextWrapper, paintingInfo: LayerPaintingInfo, paintFlags: PaintLayerFlag
  ) {
    let paginatedLayer = enclosingPaginationLayer(mode: .ExcludeCompositedPaginatedLayers)!
    let transformedExtent = RenderLayerWrapper.transparencyClipBox(
      layer: self, rootLayer: paginatedLayer, transparencyBehavior: .PaintingTransparencyClipBox,
      transparencyMode: .RootOfTransparencyClipBox,
      paintBehavior: paintingInfo.paintBehavior)

    let clipRectOptions =
      paintFlags.contains(.PaintingOverflowContents)
      ? RenderLayerWrapper.clipRectOptionsForPaintingOverflowControls
      : RenderLayerWrapper.clipRectDefaultOptions
    var enclosingPaginationFragments: LayerFragments = []
    paginatedLayer.collectFragments(
      fragments: &enclosingPaginationFragments, rootLayer: paintingInfo.rootLayer,
      dirtyRect: paintingInfo.paintDirtyRect,
      inclusionMode: .ExcludeCompositedPaginatedLayers,
      clipRectsType: paintFlags.contains(.TemporaryClipRects)
        ? .TemporaryClipRects : .PaintingClipRects,
      clipRectOptions: clipRectOptions, offsetFromRoot: LayoutSizeWrapper(),
      layerBoundingBox: transformedExtent)

    var offsetOfPaginationLayerFromRoot = LayoutSizeWrapper()
    for fragment in enclosingPaginationFragments {
      // Apply the page/column clip for this fragment, as well as any clips established by layers in between us and
      // the enclosing pagination layer.
      var clipRect = fragment.backgroundRect.rect

      // Now compute the clips within a given fragment
      if CPtrToInt(parent()?.p) != CPtrToInt(paginatedLayer.p) {
        offsetOfPaginationLayerFromRoot = toLayoutSize(
          point: paginatedLayer.convertToLayerCoords(
            ancestorLayer: paintingInfo.rootLayer,
            location: toLayoutPoint(size: offsetOfPaginationLayerFromRoot)))

        let clipRectsContext = ClipRectsContext(
          inRootLayer: paginatedLayer,
          inClipRectsType: paintFlags.contains(.TemporaryClipRects)
            ? .TemporaryClipRects : .PaintingClipRects, inOptions: clipRectOptions)
        var parentClipRect = backgroundClipRect(clipRectsContext: clipRectsContext).rect
        parentClipRect.move(size: fragment.paginationOffset + offsetOfPaginationLayerFromRoot)
        clipRect.intersect(other: parentClipRect)
      }

      var paintBehavior: PaintBehavior = .Normal
      if paintFlags.contains(.PaintingOverflowContents) {
        paintBehavior.update(with: .CompositedOverflowScrollContent)
      }

      let stateSaver = GraphicsContextStateSaver(context: context, saveAndRestore: false)
      let regionContextStateSaver = RegionContextStateSaver(context: paintingInfo.regionContext)

      parent()!.clipToRect(
        context: context, stateSaver: stateSaver, regionContextStateSaver: regionContextStateSaver,
        paintingInfo: paintingInfo, paintBehavior: paintBehavior, clipRect: ClipRect(rect: clipRect)
      )
      paintLayerByApplyingTransform(
        context: context, paintingInfo: paintingInfo, paintFlags: paintFlags,
        translationOffset: fragment.paginationOffset)
    }
  }

  private func collectEventRegionForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior
  ) {
    assert(localPaintingInfo.regionContext is EventRegionContext)
    for fragment in layerFragments {
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.foregroundRect.rect, newPhase: .EventRegion,
        newPaintBehavior: paintBehavior)
      paintInfo.regionContext = localPaintingInfo.regionContext
      if localPaintingInfo.clipToDirtyRect {  // clip-path?
        paintInfo.regionContext!.pushClip(
          clipRect: enclosingIntRect(rect: fragment.backgroundRect.rect))
      }

      renderer().paint(
        paintInfo: paintInfo,
        paintOffset: paintOffsetForRenderer(fragment: fragment, paintingInfo: localPaintingInfo))
      if localPaintingInfo.clipToDirtyRect {
        paintInfo.regionContext!.popClip()
      }
    }
  }

  private func collectAccessibilityRegionsForFragments(
    layerFragments: LayerFragments, context: GraphicsContextWrapper,
    localPaintingInfo: LayerPaintingInfo, paintBehavior: PaintBehavior
  ) {
    assert(localPaintingInfo.regionContext is AccessibilityRegionContext)
    for fragment in layerFragments {
      var paintInfo = PaintInfoWrapper(
        newContext: context, newRect: fragment.foregroundRect.rect, newPhase: .Accessibility,
        newPaintBehavior: paintBehavior)
      paintInfo.regionContext = localPaintingInfo.regionContext
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
      transform.multiply(mat: layer.transform!)

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

  private func parentClipRects(clipRectsContext: ClipRectsContext) -> ClipRects {
    assert(parent() != nil)

    let containerLayer = parent()!

    if clipRectsContext.clipRectsType == .TemporaryClipRects {
      return RenderLayerWrapper.temporaryParentClipRects(
        clipContext: clipRectsContext, containerLayer: containerLayer)
    }

    if clipRectsContext.clipRectsType != .AbsoluteClipRects && clipCrossesPaintingBoundary() {
      var tempClipRectsContext = clipRectsContext
      tempClipRectsContext.clipRectsType = .TemporaryClipRects
      return RenderLayerWrapper.temporaryParentClipRects(
        clipContext: tempClipRectsContext, containerLayer: containerLayer)
    }

    return containerLayer.updateClipRects(clipRectsContext: clipRectsContext)
  }

  private static func temporaryParentClipRects(
    clipContext: ClipRectsContext, containerLayer: RenderLayerWrapper
  ) -> ClipRects {
    var parentClipRects = ClipRects.create()
    containerLayer.calculateClipRects(clipRectsContext: clipContext, clipRects: &parentClipRects)
    return parentClipRects
  }

  private func backgroundClipRect(clipRectsContext: ClipRectsContext) -> ClipRect {
    assert(parent() != nil)
    let parentRects = parentClipRects(clipRectsContext: clipRectsContext)
    var backgroundClipRect = backgroundClipRectForPosition(
      parentRects: parentRects, position: renderer().style().position())
    let view = renderer().view()
    // Note: infinite clipRects should not be scrolled here, otherwise they will accidentally no longer be considered infinite.
    if parentRects.fixed
      && CPtrToInt(clipRectsContext.rootLayer!.renderer().p) == CPtrToInt(view.p)
      && !backgroundClipRect.isInfinite()
    {
      backgroundClipRect.moveBy(point: view.frameView().scrollPositionForFixedPosition())
    }

    return backgroundClipRect
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
      svgClipper.shouldApplyPathClipping() == nil
    {
      return true
    }

    return false
  }

  private func setWasIncludedInZOrderTree() { wasOmittedFromZOrderTree = false }

  private let p: UnsafeMutableRawPointer
  // Native fields below.

  private var savedAlphaForTransparency: Float32? = nil

  private var isRenderViewLayer = false
  private var forcedStackingContext = false

  private var isNormalFlowOnly = false
  private var m_isCSSStackingContext = false
  private var isOpportunisticStackingContext = false

  private var zOrderListsDirty = false
  private var normalFlowListDirty = false

  private let isSelfPaintingLayer = false

  // If have no self-painting descendants, we don't have to walk our children during painting. This can lead to
  // significant savings, especially if the tree has lots of non-self-painting layers grouped together (e.g. table cells).
  private let hasSelfPaintingLayerDescendant = false

  // Tracks whether we need to close a transparent layer, i.e., whether
  // we ended up painting this layer or any descendants (and therefore need to
  // blend).
  private var usedTransparency = false
  private var paintingInsideReflection = false  // A state bit tracking if we are painting inside a replica.

  private let hasVisibleContent = false
  private let hasVisibleDescendant = false

  private let m_hasTransformedAncestor = false

  private let isPaintingSVGResourceLayer = false

  private let viewportConstrainedNotCompositedReason: ViewportConstrainedNotCompositedReason =
    .NoNotCompositedReason

  private var blendMode: BlendMode = .Normal
  private var hasNotIsolatedBlendingDescendants = false

  private var wasOmittedFromZOrderTree = false

  private let backingProviderLayer: RenderLayerWrapper? = nil

  // This list contains child layers that cannot create stacking contexts and appear in normal flow order.
  private var normalFlowList: [RenderLayerWrapper]? = nil

  private var clipRectsCache: ClipRectsCache? = nil

  // Note that this transform has the transform-origin baked in.
  private let transform: TransformationMatrix? = nil

  // May ultimately be extended to many replicas (with their own paint order).
  private let reflection: RenderReplicaWrapper? = nil

  // Pointer to the enclosing RenderLayer that caused us to be paginated. It is 0 if we are not paginated.
  private let m_enclosingPaginationLayer: RenderLayerWrapper? = nil

  // Pointer to the enclosing RenderSVGHiddenContainer or RenderSVGResourceContainer, if present.
  private let enclosingSVGHiddenOrResourceContainer: RenderSVGHiddenContainerWrapper? = nil

  private let filters: RenderLayerFilters? = nil
  private let backing: RenderLayerBacking? = nil

  private let m_scrollableArea: RenderLayerScrollableArea? = nil

  private let paintFrequencyTracker = PaintFrequencyTracker()
}
