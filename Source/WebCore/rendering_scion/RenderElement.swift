/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

private func rendererHasBackground(renderer: RenderElementWrapper?) -> Bool {
  return renderer != nil && renderer!.hasBackground()
}

private func paintPhase(
  element: RenderElementWrapper, phase: PaintPhase, paintInfo: inout PaintInfoWrapper,
  childPoint: LayoutPointWrapper
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class RenderElementWrapper: RenderObjectWrapper {
  func initializeStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Calling with minimalStyleDifference > StyleDifference::Equal indicates that
  // out-of-band state (e.g. animations) requires that styleDidChange processing
  // continue even if the style isn't different from the current style.
  func setStyle(style: RenderStyleWrapper, minimalStyleDifference: StyleDifference = .Equal) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The pseudo element style can be cached or uncached. Use the uncached method if the pseudo element
  // has the concept of changing state (like ::-webkit-scrollbar-thumb:hover), or if it takes additional
  // parameters (like ::highlight(name)).
  func getCachedPseudoStyle(
    pseudoElementIdentifier: Style.PseudoElementIdentifier, parentStyle: RenderStyleWrapper? = nil
  ) -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getUncachedPseudoStyle(
    pseudoElementRequest: Style.PseudoElementRequest, parentStyle: RenderStyleWrapper? = nil,
    ownStyle: RenderStyleWrapper? = nil
  )
    -> RenderStyleWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func element() -> ElementWrapper? {
    if let elementRaw = wk_interop.RenderElement_element(p) {
      return ElementWrapper(p: elementRaw)
    }
    return nil
  }

  func firstChild() -> RenderObjectWrapper? {
    if let childRaw = wk_interop.RenderElement_firstChild(p) {
      return RenderObjectWrapper(p: childRaw)
    }
    return nil
  }

  func lastChild() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstInFlowChild() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layoutBox() -> ElementBoxWrapper? {
    return super.layoutBox() as? ElementBoxWrapper
  }

  // Note that even if these 2 "canContain" functions return true for a particular renderer, it does not necessarily mean the renderer is the containing block (see containingBlockForAbsolute(Fixed)Position).
  func canContainFixedPositionObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canContainAbsolutelyPositionedObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyLayoutContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplySizeContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyInlineSizeContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplySizeOrInlineSizeContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyPaintContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyLayoutOrPaintContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionPseudoStyle() -> RenderStyleWrapper? {
    if isAnonymous() {
      return nil
    }

    if let selectionStyle = getUncachedPseudoStyle(
      pseudoElementRequest: Style.PseudoElementRequest(pseudoId: .Selection))
    {
      // We intentionally return the pseudo selection style here if it exists before ascending to
      // the shadow host element. This allows us to apply selection pseudo styles in user agent
      // shadow roots, instead of always deferring to the shadow host's selection pseudo style.
      return selectionStyle
    }

    if let renderer = rendererForPseudoStyleAcrossShadowBoundary() {
      return renderer.getUncachedPseudoStyle(
        pseudoElementRequest: Style.PseudoElementRequest(pseudoId: .Selection))
    }

    return nil
  }

  // Obtains the selection colors that should be used when painting a selection.
  func selectionBackgroundColor() -> ColorWrapper {
    if style().usedUserSelect() == .None {
      return ColorWrapper()
    }

    if frame().selection().shouldShowBlockCursor() && frame().selection().isCaret() {
      return theme().transformSelectionBackgroundColor(
        color: style().visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyColor),
        options: styleColorOptions())
    }

    var pseudoStyleCandidate: RenderElementWrapper? = self
    if pseudoStyleCandidate!.isAnonymous() {
      pseudoStyleCandidate = pseudoStyleCandidate!.firstNonAnonymousAncestor()
    }

    if pseudoStyleCandidate != nil {
      if let pseudoStyle = pseudoStyleCandidate!.selectionPseudoStyle(),
        pseudoStyle.visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyBackgroundColor)
          .isValid()
      {
        return theme().transformSelectionBackgroundColor(
          color: pseudoStyle.visitedDependentColorWithColorFilter(
            colorProperty: .CSSPropertyBackgroundColor),
          options: styleColorOptions())
      }
    }

    if frame().selection().isFocusedAndActive() {
      return theme().activeSelectionBackgroundColor(options: styleColorOptions())
    }
    return theme().inactiveSelectionBackgroundColor(options: styleColorOptions())
  }

  func selectionForegroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isChildAllowed(child: RenderObjectWrapper, style: RenderStyleWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func didAttachChild(child: RenderObjectWrapper) {
    if let textRenderer = child as? RenderTextWrapper {
      textRenderer.styleDidChange(diff: .Equal, oldStyle: nil)
    }

    // The following only applies to the legacy SVG engine -- LBSE always creates layers
    // independant of the position in the render tree, see comment in layerCreationAllowedForSubtree().

    // SVG creates renderers for <g display="none">, as SVG requires children of hidden
    // <g>s to have renderers - at least that's how our implementation works. Consider:
    // <g display="none"><foreignObject><body style="position: relative">FOO...
    // - requiresLayer() would return true for the <body>, creating a new RenderLayer
    // - when the document is painted, both layers are painted. The <body> layer doesn't
    //   know that it's inside a "hidden SVG subtree", and thus paints, even if it shouldn't.
    // To avoid the problem alltogether, detect early if we're inside a hidden SVG subtree
    // and stop creating layers at all for these cases - they're not used anyways.
    if child.hasLayer() && !layerCreationAllowedForSubtree() {
      (child as! RenderLayerModelObjectWrapper).checkedLayer()!.removeOnlyThisLayer(
        timing: .RenderTreeConstruction)
    }
  }

  func setChildNeedsLayout(markParents: MarkingBehavior = .MarkContainingBlockChain) {
    wk_interop.RenderElement_setChildNeedsLayout(p, markParents.rawValue)
  }

  func setOutOfFlowChildNeedsStaticPositionLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsSimplifiedNormalFlowLayout() {
    assert(!isSetNeedsLayoutForbidden())
    if needsSimplifiedNormalFlowLayout() {
      return
    }
    setNeedsSimplifiedNormalFlowLayoutBit(b: true)
    scheduleLayout(layoutRoot: markContainingBlocksForLayout())
    if hasLayer() {
      setLayerNeedsFullRepaint()
    }
  }

  // paintOffset is the offset from the origin of the GraphicsContext at which to paint the current object.
  func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    fatalError("Not reached")
  }

  // inline-block elements paint all phases atomically. This function ensures that. Certain other elements
  // (grid items, flex items) require this behavior as well, and this function exists as a helper for them.
  // It is expected that the caller will call this function independent of the value of paintInfo.phase.
  func paintAsInlineBlock(paintInfo: inout PaintInfoWrapper, childPoint: LayoutPointWrapper) {
    // Paint all phases atomically, as though the element established its own stacking context.
    // (See Appendix E.2, section 6.4 on inline block/table/replaced elements in the CSS2.1 specification.)
    // This is also used by other elements (e.g. flex items and grid items).
    let paintPhaseToUse = isExcludedAndPlacedInBorder() ? paintInfo.phase : .Foreground
    if paintInfo.phase == .Selection || paintInfo.phase == .EventRegion
      || paintInfo.phase == .TextClip || paintInfo.phase == .Accessibility
    {
      paint(paintInfo: &paintInfo, paintOffset: childPoint)
    } else if paintInfo.phase == paintPhaseToUse {
      paintPhase(
        element: self, phase: .BlockBackground, paintInfo: &paintInfo, childPoint: childPoint)
      paintPhase(
        element: self, phase: .ChildBlockBackgrounds, paintInfo: &paintInfo, childPoint: childPoint)
      paintPhase(element: self, phase: .Float, paintInfo: &paintInfo, childPoint: childPoint)
      paintPhase(element: self, phase: .Foreground, paintInfo: &paintInfo, childPoint: childPoint)
      paintPhase(element: self, phase: .Outline, paintInfo: &paintInfo, childPoint: childPoint)

      // Reset |paintInfo| to the original phase.
      paintInfo.phase = paintPhaseToUse
    }
  }

  // Recursive function that computes the size and position of this object and all its descendants.
  func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  /* This function performs a layout only if one is needed. */
  func layoutIfNeeded() {
    wk_interop.RenderElement_layoutIfNeeded(p)
  }

  func borderImageIsLoadedAndCanBeRendered() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isVisibleIgnoringGeometry() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isVisibleInDocumentRect(documentRect: IntRect) -> Bool {
    if !isVisibleIgnoringGeometry() {
      return false
    }

    // Use background rect if we are the root or if we are the body and the background is propagated to the root.
    // FIXME: This is overly conservative as the image may not be a background-image, in which case it will not
    // be propagated to the root. At this point, we unfortunately don't have access to the image anymore so we
    // can no longer check if it is a background image.
    let backgroundIsPaintedByRoot =
      isDocumentElementRenderer()
      || (isBody()
        && !rendererHasBackground(renderer: document().documentElement()!.containerRenderer()))
    let backgroundPaintingRect =
      backgroundIsPaintedByRoot ? view().backgroundRect() : absoluteClippedOverflowRectForRepaint()
    if !documentRect.intersects(other: enclosingIntRect(rect: backgroundPaintingRect)) {
      return false
    }

    return true
  }

  // Returns true if this renderer requires a new stacking context.
  static func createsGroupForStyle(style: RenderStyleWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func opacity() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visibleToHitTesting(request: HitTestRequestWrapper? = nil) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackground() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasMask() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClipOrNonVisibleOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClipPath() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func requiresRenderingConsolidationForViewTransition() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSelfPaintingLayer() -> Bool {
    return wk_interop.RenderElement_hasSelfPaintingLayer(p)
  }

  func checkForRepaintDuringLayout() -> Bool {
    return wk_interop.RenderElement_checkForRepaintDuringLayout(p)
  }

  func hasFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackdropFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBlendMode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasContinuationChainNode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isContinuation() -> Bool {
    return wk_interop.RenderElement_isContinuation(p)
  }

  func setIsContinuation() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsFirstLetter() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func attachRendererInternal(child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?)
    -> RenderObjectWrapper?
  {
    child!.setParent(parent: self)

    if CPtrToInt(m_firstChild?.p) == CPtrToInt(beforeChild?.p) {
      m_firstChild = child
    }

    if beforeChild != nil {
      let previousSibling = beforeChild!.previousSibling()
      if previousSibling != nil {
        previousSibling!.setNextSibling(next: child)
      }
      child!.setPreviousSibling(previous: previousSibling)
      child!.setNextSibling(next: beforeChild)
      beforeChild!.setPreviousSibling(previous: child)
      return child
    }
    if m_lastChild != nil {
      m_lastChild!.setNextSibling(next: child)
    }
    child!.setPreviousSibling(previous: m_lastChild)
    m_lastChild = child
    return child
  }

  func detachRendererInternal(renderer: RenderObjectWrapper) -> RenderObjectWrapper? {
    let parent = renderer.parent()!
    let nextSibling = renderer.nextSibling()

    if let previousSibling = renderer.previousSibling() {
      previousSibling.setNextSibling(next: nextSibling)
    }
    if nextSibling != nil {
      nextSibling!.setPreviousSibling(previous: renderer.previousSibling())
    }

    if CPtrToInt(parent.firstChild()?.p) == CPtrToInt(renderer.p) {
      parent.m_firstChild = nextSibling
    }
    if CPtrToInt(parent.lastChild()?.p) == CPtrToInt(renderer.p) {
      parent.m_lastChild = renderer
    }

    renderer.setPreviousSibling(previous: nil)
    renderer.setNextSibling(next: nil)
    renderer.setParent(parent: nil)
    return renderer
  }

  // https://www.w3.org/TR/css-transforms-1/#transform-box
  func transformReferenceBoxRect(style: RenderStyleWrapper) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // https://www.w3.org/TR/css-transforms-1/#reference-box
  func referenceBoxRect(boxType: CSSBoxType) -> FloatRectWrapper {
    // CSS box model code is implemented in RenderBox::referenceBoxRect().

    // For the legacy SVG engine, RenderElement is the only class that's
    // present in the ancestor chain of all SVG renderers. In LBSE the
    // common class is RenderLayerModelObject. Once the legacy SVG engine
    // is removed this function should be moved to RenderLayerModelObject.
    // As this method is used by both SVG engines, we need to place it
    // here in RenderElement, as temporary solution.
    if element() != nil && !(element() is SVGElementWrapper) {
      return FloatRectWrapper()
    }

    switch boxType {
    case .ContentBox, .PaddingBox, .FillBox:
      return alignReferenceBox(referenceBox: objectBoundingBox())
    case .BoxMissing, .BorderBox, .MarginBox, .StrokeBox:
      return alignReferenceBox(referenceBox: strokeBoundingBox())
    case .ViewBox:
      return alignReferenceBox(referenceBox: determineSVGViewport())
    }
  }

  private func alignReferenceBox(referenceBox: FloatRectWrapper) -> FloatRectWrapper {
    // The CSS borderBoxRect() is defined to start at an origin of (0, 0).
    // A possible shift of a CSS box (e.g. due to non-static position + top/left properties)
    // does not effect the borderBoxRect() location. The location information
    // is propagated upon paint time, e.g. via 'paintOffset' when calling RenderObject::paint(),
    // or by altering the RenderLayer TransformationMatrix to include the 'offsetFromAncestor'
    // right in the transformation matrix, when CSS transformations are present (see RenderLayer
    // paintLayerByApplyingTransform() for details).
    //
    // To mimic the expectation for SVG, 'fill-box' must behave the same: if we'd include
    // the 'referenceBox' location in the returned rect, we'd apply the (x, y) location
    // information for the SVG renderer twice. We would shift the 'transform-origin' by (x, y)
    // and at the same time alter the CTM in RenderLayer::paintLayerByApplyingTransform() by
    // including a translation to the enclosing transformed ancestor ('offsetFromAncestor').
    // Avoid that, and move by -nominalSVGLayoutLocation().
    var referenceBox = referenceBox
    if isSVGLayerAwareRenderer() && !isRenderSVGRoot()
      && document().settings().layerBasedSVGEngineEnabled()
    {
      referenceBox.moveBy(
        delta: -(self as! RenderLayerModelObjectWrapper).nominalSVGLayoutLocation().FloatPoint())
    }
    return referenceBox
  }

  private func determineSVGViewport() -> FloatRectWrapper {
    var viewportElement = element() as! SVGElementWrapper?

    // RenderSVGViewportContainer is the only possible anonymous renderer in the SVG tree.
    if viewportElement == nil && document().settings().layerBasedSVGEngineEnabled() {
      assert(isAnonymous())
      viewportElement = (self as! RenderSVGViewportContainerWrapper).svgSVGElement()
    }

    // FIXME: [LBSE] Upstream: Cache the immutable SVGLengthContext per SVGElement, to avoid the repeated RenderSVGRoot size queries in determineViewport().
    assert(viewportElement != nil)
    let viewportSize = SVGLengthContext(context: viewportElement).viewportSize() ?? FloatSize()
    return FloatRectWrapper(location: FloatPoint(), size: viewportSize)
  }

  func backdropRenderer() -> RenderBlockFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBackdropRenderer(renderer: RenderBlockFlowWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func effectiveOverflowX() -> Overflow {
    let overflowX = style().overflowX()
    if paintContainmentApplies() && overflowX == .Visible {
      return .Clip
    }
    return overflowX
  }

  func effectiveOverflowY() -> Overflow {
    let overflowY = style().overflowY()
    if paintContainmentApplies() && overflowY == .Visible {
      return .Clip
    }
    return overflowY
  }

  func effectiveOverflowInlineDirection() -> Overflow {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func effectiveOverflowBlockDirection() -> Overflow {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isWritingModeRoot() -> Bool {
    return wk_interop.RenderElement_isWritingModeRoot(p)
  }

  func isFlexItemIncludingDeprecated() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintRectToClipOutFromBorder(paintRect: LayoutRectWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func establishesIndependentFormattingContext() -> Bool {
    return isFloatingOrOutOfFlowPositioned() || (isBlockBox() && hasPotentiallyScrollableOverflow())
      || style().containsLayout() || paintContainmentApplies()
      || (style().isDisplayBlockLevel() && style().blockStepSize() != nil)
  }

  func createsNewFormattingContext() -> Bool {
    // Writing-mode changes establish an independent block formatting context
    // if the box is a block-container.
    // https://drafts.csswg.org/css-writing-modes/#block-flow
    if isWritingModeRoot() && isBlockContainer() {
      return true
    }
    if isBlockContainer() && !style().alignContent().isNormal() {
      return true
    }
    return isInlineBlockOrInlineTable() || isFlexItemIncludingDeprecated()
      || isRenderTableCell() || isRenderTableCaption() || isFieldset()
      || isDocumentElementRenderer() || isRenderFragmentedFlow() || isRenderSVGForeignObject()
      || style().specifiesColumns() || style().columnSpan() == .All
      || style().display() == .FlowRoot || establishesIndependentFormattingContext()
  }

  func isSkippedContentRoot() -> Bool {
    return layout_scion.isSkippedContentRoot(style: style(), element: element())
      && !view().frameView().layoutContext().needsSkippedContentLayout()
  }

  func clearNeedsLayoutForSkippedContent() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerCreationAllowedForSubtree() -> Bool {
    // In LBSE layers are always created regardless of there position in the render tree.
    // Consider the SVG document fragment: "<defs><mask><rect transform="scale(2)".../>"
    // To paint the <rect> into the mask image, the rect needs to be transformed -
    // which is handled via RenderLayer in LBSE, unlike as in the legacy engine where no
    // layers are involved for any SVG painting features. In the legacy engine we could
    // simply omit the layer creation for any children of a <defs> element (or in general
    // any "hidden container"). For LBSE layers are needed for painting, even if a
    // RenderSVGHiddenContainer is in the render tree ancestor chain -- however they are
    // never painted directly, only indirectly through the "LegacyRenderSVGResourceContainer
    // elements (such as LegacyRenderSVGResourceClipper, RenderSVGResourceMasker, etc.)
    if document().settings().layerBasedSVGEngineEnabled() {
      return true
    }

    var parentRenderer = parent()
    while parentRenderer != nil {
      if parentRenderer!.isLegacyRenderSVGHiddenContainer() {
        return false
      }
      parentRenderer = parentRenderer!.parent()
    }

    return true
  }

  func paintOutline(paintInfo: PaintInfoWrapper, paintRect: LayoutRectWrapper) {
    if paintInfo.context().paintingDisabled() {
      return
    }

    if !hasOutline() {
      return
    }

    let painter = BorderPainter(renderer: self, paintInfo: paintInfo)
    painter.paintOutline(paintRect: paintRect)
  }

  func isVisibleInViewport() -> Bool {
    let frameView = view().frameView()
    let visibleRect = frameView.windowToContents(windowRect: frameView.windowClipRect())
    return isVisibleInDocumentRect(documentRect: visibleRect)
  }

  private func rendererForPseudoStyleAcrossShadowBoundary() -> RenderElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var m_firstChild: RenderObjectWrapper? = nil
  private var m_lastChild: RenderObjectWrapper? = nil
}
