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

private func areCursorsEqual(_ a: RenderStyleWrapper, _ b: RenderStyleWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func paintPhase(
  element: RenderElementWrapper, phase: PaintPhase, paintInfo: inout PaintInfoWrapper,
  childPoint: LayoutPointWrapper
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func mustRepaintFillLayers(_ renderer: RenderElementWrapper, _ layer: FillLayerWrapper)
  -> Bool
{
  // Nobody will use multiple layers without wanting fancy positioning.
  if layer.next() != nil {
    return true
  }

  // Make sure we have a valid image.
  let image = layer.image()
  if image == nil || !image!.canRender(renderer: renderer, multiplier: renderer.style().usedZoom())
  {
    return false
  }

  if !layer.xPosition.isZero() || !layer.yPosition.isZero() {
    return true
  }

  let sizeType = layer.sizeType

  if sizeType == .Contain || sizeType == .Cover {
    return true
  }

  if sizeType == .Size {
    let size = layer.sizeLength
    if size.width.isPercentOrCalculated() || size.height.isPercentOrCalculated() {
      return true
    }
    // If the image has neither an intrinsic width nor an intrinsic height, its size is determined as for 'contain'.
    if (size.width.isAuto() || size.height.isAuto()) && image!.isGeneratedImage() {
      return true
    }
  } else if image!.usesImageContainerSize() {
    return true
  }

  return false
}

private func usePlatformFocusRingColorForOutlineStyleAuto() -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func useShrinkWrappedFocusRingForOutlineStyleAuto() -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func drawFocusRing(
  context: GraphicsContextWrapper, path: PathWrapper, style: RenderStyleWrapper, color: ColorWrapper
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func drawFocusRing(
  context: GraphicsContextWrapper, rects: [FloatRectWrapper], style: RenderStyleWrapper,
  color: ColorWrapper
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class RenderElementWrapper: RenderObjectWrapper {
  init(
    type: RenderObjectWrapper.`Type`, document: Document, _ style: RenderStyleWrapper,
    _ baseTypeFlags: RenderObjectWrapper.TypeFlag,
    _ typeSpecificFlags: RenderObjectWrapper.TypeSpecificFlags
  ) {
    m_firstChild = nil
    hasInitializedStyle = false
    m_hasPausedImageAnimations = false
    m_hasCounterNodeMap = false
    m_hasContinuationChainNode = false
    m_isContinuation = false
    m_isFirstLetter = false
    renderBlockHasMarginBeforeQuirk = false
    renderBlockHasMarginAfterQuirk = false
    renderBlockShouldForceRelayoutChildren = false
    m_renderBlockFlowLineLayoutPath = .UndeterminedPath
    m_lastChild = nil
    m_isRegisteredForVisibleInViewportCallback = false
    m_visibleInViewportState = .Unknown
    m_didContributeToVisuallyNonEmptyPixelCount = false
    self.style = style
    super.init(type, document.ContainerNode(), baseTypeFlags, typeSpecificFlags)
    assert(super.isRenderElement())
  }

  override init(p: UnsafeMutableRawPointer) {
    m_firstChild = nil
    hasInitializedStyle = false
    m_hasPausedImageAnimations = false
    m_hasCounterNodeMap = false
    m_hasContinuationChainNode = false
    m_isContinuation = false
    m_isFirstLetter = false
    renderBlockHasMarginBeforeQuirk = false
    renderBlockHasMarginAfterQuirk = false
    renderBlockShouldForceRelayoutChildren = false
    m_renderBlockFlowLineLayoutPath = .UndeterminedPath
    m_lastChild = nil
    m_isRegisteredForVisibleInViewportCallback = false
    m_visibleInViewportState = .Unknown
    m_didContributeToVisuallyNonEmptyPixelCount = false
    self.style = nil
    super.init(p: p)
  }

  func elementStyle() -> RenderStyleWrapper {
    assert(isNativeImpl())
    return self.style!
  }

  // FIXME: Style shouldn't be mutated.
  func mutableStyle() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func initializeStyle() {
    Style.loadPendingResources(style!, protectedDocument(), protectedElement())

    styleWillChange(diff: .NewStyle, newStyle: style())
    hasInitializedStyle = true
    styleDidChange(diff: .NewStyle, oldStyle: nil)

    // We shouldn't have any text children that would need styleDidChange at this point.
    let it: RenderChildIteratorAdapter<RenderTextWrapper> = childrenOfType(parent: self)
    assert(it.first() == nil)

    // It would be nice to assert that !parent() here, but some RenderLayer subrenderers
    // have their parent set before getting a call to initializeStyle() :|

    if let styleable = StyleableWrapper.fromRenderer(self) {
      setCapturedInViewTransition(styleable.capturedInViewTransition())
    }
  }

  // Calling with minimalStyleDifference > StyleDifference::Equal indicates that
  // out-of-band state (e.g. animations) requires that styleDidChange processing
  // continue even if the style isn't different from the current style.
  func setStyle(style: RenderStyleWrapper, minimalStyleDifference: StyleDifference = .Equal) {
    // FIXME: Should change RenderView so it can use initializeStyle too.
    // If we do that, we can assert m_hasInitializedStyle unconditionally,
    // and remove the check of m_hasInitializedStyle below too.
    assert(hasInitializedStyle || isRenderView())

    var diff: StyleDifference = .Equal
    var contextSensitiveProperties = StyleDifferenceContextSensitiveProperty()
    if hasInitializedStyle {
      (diff, contextSensitiveProperties) = self.style!.diff(style)
    }

    diff = max(diff, minimalStyleDifference)

    diff = adjustStyleDifference(diff, contextSensitiveProperties)

    Style.loadPendingResources(style, protectedDocument(), protectedElement())

    let didRepaint = repaintBeforeStyleChange(diff: diff, oldStyle: self.style!, newStyle: style)
    styleWillChange(diff: diff, newStyle: style)
    let oldStyle = self.style!.replace(style)
    let detachedFromParent = parent() == nil

    adjustFragmentedFlowStateOnContainingBlockChangeIfNeeded(
      oldStyle: oldStyle, newStyle: self.style!)

    styleDidChange(diff: diff, oldStyle: oldStyle)

    // Text renderers use their parent style. Notify them about the change.
    for child: RenderTextWrapper in childrenOfType(parent: self) {
      child.styleDidChange(diff: diff, oldStyle: oldStyle)
    }

    // FIXME: |this| might be destroyed here. This can currently happen for a RenderTextFragment when
    // its first-letter block gets an update in RenderTextFragment::styleDidChange. For RenderTextFragment(s),
    // we will safely bail out with the detachedFromParent flag. We might want to broaden this condition
    // in the future as we move renderer changes out of layout and into style changes.
    if detachedFromParent {
      return
    }

    // Now that the layer (if any) has been updated, we need to adjust the diff again,
    // check whether we should layout now, and decide if we need to repaint.
    let updatedDiff = adjustStyleDifference(diff, contextSensitiveProperties)

    if diff <= .LayoutPositionedMovementOnly {
      if updatedDiff == .Layout {
        setNeedsLayoutAndPrefWidthsRecalc()
      } else if updatedDiff == .LayoutPositionedMovementOnly {
        setNeedsPositionedMovementLayout(oldStyle)
      } else if updatedDiff == .SimplifiedLayoutAndPositionedMovement {
        setNeedsPositionedMovementLayout(oldStyle)
        setNeedsSimplifiedNormalFlowLayout()
      } else if updatedDiff == .SimplifiedLayout {
        setNeedsSimplifiedNormalFlowLayout()
      }
    }

    if !didRepaint && (updatedDiff == .RepaintLayer || shouldRepaintForStyleDifference(updatedDiff))
    {
      // Do a repaint with the new style now, e.g., for example if we go from
      // not having an outline to having an outline.
      repaint()
    }
  }

  // The pseudo element style can be cached or uncached. Use the uncached method if the pseudo element
  // has the concept of changing state (like ::-webkit-scrollbar-thumb:hover), or if it takes additional
  // parameters (like ::highlight(name)).
  func getCachedPseudoStyle(
    pseudoElementIdentifier: Style.PseudoElementIdentifier, parentStyle: RenderStyleWrapper? = nil
  ) -> RenderStyleWrapper? {
    if pseudoElementIdentifier.pseudoId < PseudoId.FirstInternalPseudoId
      && !style().hasPseudoStyle(pseudo: pseudoElementIdentifier.pseudoId)
    {
      return nil
    }

    if let cachedStyle = style().getCachedPseudoStyle(
      pseudoElementIdentifier: pseudoElementIdentifier)
    {
      return cachedStyle
    }

    if let result = getUncachedPseudoStyle(
      pseudoElementRequest: Style.PseudoElementRequest(
        pseudoElementIdentifier: pseudoElementIdentifier),
      parentStyle: parentStyle)
    {
      return style!.addCachedPseudoStyle(pseudo: result)
    }
    return nil
  }

  func getUncachedPseudoStyle(
    pseudoElementRequest: Style.PseudoElementRequest, parentStyle: RenderStyleWrapper? = nil,
    ownStyle: RenderStyleWrapper? = nil
  )
    -> RenderStyleWrapper?
  {
    if pseudoElementRequest.pseudoId() < PseudoId.FirstInternalPseudoId && ownStyle == nil
      && !style().hasPseudoStyle(pseudo: pseudoElementRequest.pseudoId())
    {
      return nil
    }

    var parentStyle = parentStyle
    if parentStyle == nil {
      assert(ownStyle == nil)
      parentStyle = style()
    }

    if isAnonymous() {
      return nil
    }

    let element = element()!
    let styleResolver = element.styleResolver()

    guard
      let resolvedStyle = styleResolver.styleForPseudoElement(
        element, pseudoElementRequest, Style.ResolutionContext(parentStyle: parentStyle))
    else { return nil }

    Style.loadPendingResources(resolvedStyle.style!, protectedDocument(), element)

    return resolvedStyle.style
  }

  // This is null for anonymous renderers.
  func element() -> ElementWrapper? {
    if !isNativeImpl() {
      if let elementRaw = wk_interop.RenderElement_element(id()) {
        return ElementWrapper(p: elementRaw)
      }
      return nil
    }
    return super.node() != nil ? (super.node()! as! ElementWrapper) : nil
  }

  func protectedElement() -> ElementWrapper? {
    return element()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func nonPseudoElement() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstChild() -> RenderObjectWrapper? {
    if !isNativeImpl() {
      if let childRaw = wk_interop.RenderElement_firstChild(id()) {
        return RenderObjectWrapper(p: childRaw)
      }
      return nil
    }
    return m_firstChild
  }

  func lastChild() -> RenderObjectWrapper? {
    assert(isNativeImpl())
    return m_lastChild
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
    assert(isNativeImpl())
    return shouldApplyLayoutOrPaintContainment(
      style().containsLayout() || style().contentVisibility() != .Visible)
  }

  func shouldApplySizeContainment() -> Bool {
    assert(isNativeImpl())
    return layout_scion.isSkippedContentRoot(style: style(), element: element())
      || shouldApplySizeOrStyleContainment(style().containsSize())
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
    return shouldApplyLayoutOrPaintContainment(style().containsPaint())
      || shouldApplySizeOrStyleContainment(style().contentVisibility() != .Visible)
  }

  func shouldApplyLayoutOrPaintContainment() -> Bool {
    return shouldApplyLayoutOrPaintContainment(style().containsLayoutOrPaint())
      || shouldApplySizeOrStyleContainment(style().contentVisibility() != .Visible)
  }

  func shouldApplyAnyContainment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func selectionColor(colorProperty: CSSPropertyID) -> ColorWrapper {
    // If the element is unselectable, or we are only painting the selection,
    // don't override the foreground color with the selection foreground color.
    if style().usedUserSelect() == .None
      || !view().frameView().paintBehavior().isDisjoint(with: [
        .SelectionOnly, .SelectionAndBackgroundsOnly,
      ])
    {
      return ColorWrapper()
    }

    if let pseudoStyle = selectionPseudoStyle() {
      var color = pseudoStyle.visitedDependentColorWithColorFilter(colorProperty: colorProperty)
      if !color.isValid() {
        color = pseudoStyle.visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyColor)
      }
      return color
    }

    if frame().selection().isFocusedAndActive() {
      return theme().activeSelectionForegroundColor(options: styleColorOptions())
    }
    return theme().inactiveSelectionForegroundColor(options: styleColorOptions())
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
    return selectionColor(colorProperty: .CSSPropertyWebkitTextFillColor)
  }

  func isChildAllowed(_ child: RenderObjectWrapper, _ style: RenderStyleWrapper) -> Bool {
    assert(isNativeImpl())
    return true
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

  // The following functions are used when the render tree hierarchy changes to make sure layers get
  // properly added and removed. Since containership can be implemented by any subclass, and since a hierarchy
  // can contain a mixture of boxes and other object types, these functions need to be in the base class.
  func layerParent() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    assert(!isInTopLayerOrBackdrop(style: style(), element: protectedElement()) || hasLayer())

    if hasLayer() && isInTopLayerOrBackdrop(style: style(), element: protectedElement()) {
      return view().layer()
    }

    return parent()!.enclosingLayer()
  }

  func layerNextSibling(_ parentLayer: RenderLayerWrapper) -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func moveLayers(_ newParent: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dirtyLineFromChangedChild() {}

  func setChildNeedsLayout(markParents: MarkingBehavior = .MarkContainingBlockChain) {
    assert(!isNativeImpl())
    wk_interop.RenderElement_setChildNeedsLayout(id(), markParents.rawValue)
  }

  func setOutOfFlowChildNeedsStaticPositionLayout() {
    // FIXME: Currently this dirty bit has a very limited useage but should be expanded to
    // optimize all kinds of out-of-flow cases.
    // It's also assumed that regular, positioned child related bits are already set.
    assert(!isSetNeedsLayoutForbidden())
    assert(
      posChildNeedsLayout() || selfNeedsLayout() || needsSimplifiedNormalFlowLayout()
        || parent() == nil)
    setOutOfFlowChildNeedsStaticPositionLayoutBit(b: true)
  }

  func clearChildNeedsLayout() {
    setNormalChildNeedsLayoutBit(b: false)
    setPosChildNeedsLayoutBit(b: false)
    setNeedsSimplifiedNormalFlowLayoutBit(b: false)
    setNeedsPositionedMovementLayoutBit(b: false)
    setOutOfFlowChildNeedsStaticPositionLayoutBit(b: false)
  }

  private func setNeedsPositionedMovementLayout(_ oldStyle: RenderStyleWrapper?) {
    assert(!isSetNeedsLayoutForbidden())
    if needsPositionedMovementLayout() {
      return
    }
    setNeedsPositionedMovementLayoutBit(b: true)
    scheduleLayout(layoutRoot: markContainingBlocksForLayout())
    if hasLayer() {
      if oldStyle != nil
        && style().diffRequiresLayerRepaint(
          oldStyle!, isComposited: (self as! RenderLayerModelObjectWrapper).layer()!.isComposited())
      {
        setLayerNeedsFullRepaint()
      } else {
        setLayerNeedsFullRepaintForPositionedMovementLayout()
      }
    }
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
    // TODO(asuhan): add stack stats
    assert(needsLayout())
    var child = firstChild()
    while child != nil {
      if child!.needsLayout() {
        (child! as! RenderElementWrapper).layout()
      }
      assert(!child!.needsLayout())
      child = child!.nextSibling()
    }
    clearNeedsLayout()
  }

  /* This function performs a layout only if one is needed. */
  func layoutIfNeeded() {
    assert(!isNativeImpl())
    wk_interop.RenderElement_layoutIfNeeded(id())
  }

  // Repaint only if our old bounds and new bounds are different. The caller may pass in newBounds and newOutlineBox if they are known.
  func repaintAfterLayoutIfNeeded(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ requiresFullRepaint: RequiresFullRepaint,
    oldRects: RenderObjectWrapper.RepaintRects, newRects: RenderObjectWrapper.RepaintRects
  ) -> Bool {
    if view().printing() {
      return false  // Don't repaint if we're printing.
    }

    let oldClippedOverflowRect = oldRects.clippedOverflowRect
    let newClippedOverflowRect = newRects.clippedOverflowRect
    let haveOutlinesBoundsRects =
      oldRects.outlineBoundsRect != nil && newRects.outlineBoundsRect != nil

    if oldClippedOverflowRect.isEmpty() && newClippedOverflowRect.isEmpty() {
      return true
    }

    let mustRepaintBackgroundOrBorderOnSizeChange = {
      [self] (oldOutlineBounds: LayoutRectWrapper, newOutlineBounds: LayoutRectWrapper) in
      if hasMask() && mustRepaintFillLayers(self, style!.maskLayers()) {
        return true
      }

      if style!.hasBorderRadius() {
        // If the border radius changed, repaints at style change time will take care of that.
        // This code is attempting to detect whether border-radius constraining based on box size
        // affects the radii, using the outlineBoundsRect as a proxy for the border box.
        let oldShapeApproximation = BorderShape.shapeForBorderRect(
          style: style!, borderRect: oldOutlineBounds)
        let newShapeApproximation = BorderShape.shapeForBorderRect(
          style: style!, borderRect: newOutlineBounds)
        if oldShapeApproximation.radii() != newShapeApproximation.radii() {
          return true
        }
      }

      // If we don't have a background/border/mask, then nothing to do.
      if !hasVisibleBoxDecorations() {
        return false
      }

      if mustRepaintFillLayers(self, style!.backgroundLayers()) {
        return true
      }

      // Our fill layers are ok. Let's check border.
      if style!.hasBorder() && borderImageIsLoadedAndCanBeRendered() {
        return true
      }

      return false
    }

    let fullRepaint = { () in
      if requiresFullRepaint == .Yes {
        return true
      }

      if oldClippedOverflowRect.isEmpty() || newClippedOverflowRect.isEmpty() {
        return true
      }

      if !oldClippedOverflowRect.intersects(other: newClippedOverflowRect) {
        return true
      }

      if !haveOutlinesBoundsRects {
        return false
      }

      // If our outline bounds rect moved, we have to repaint everything.
      if oldRects.outlineBoundsRect!.location() != newRects.outlineBoundsRect!.location() {
        return true
      }

      // If our outline bounds rect resized (as a proxy for a border box resize),
      // we have to repaint if we paint content that scales with the size.
      if oldRects.outlineBoundsRect!.size() != newRects.outlineBoundsRect!.size()
        && mustRepaintBackgroundOrBorderOnSizeChange(
          oldRects.outlineBoundsRect!, newRects.outlineBoundsRect!)
      {
        return true
      }

      return false
    }()

    var repaintContainer = repaintContainer
    if repaintContainer == nil {
      repaintContainer = view()
    }

    if fullRepaint {
      if newClippedOverflowRect.contains(other: oldClippedOverflowRect) {
        repaintUsingContainer(repaintContainer, newClippedOverflowRect)
      } else if oldClippedOverflowRect.contains(other: newClippedOverflowRect) {
        repaintUsingContainer(repaintContainer, oldClippedOverflowRect)
      } else {
        repaintUsingContainer(repaintContainer, oldClippedOverflowRect)
        repaintUsingContainer(repaintContainer, newClippedOverflowRect)
      }
      return true
    }

    if oldRects == newRects {
      return false
    }

    let deltaLeft = newClippedOverflowRect.x() - oldClippedOverflowRect.x()
    if deltaLeft > 0 {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: oldClippedOverflowRect.x(), y: oldClippedOverflowRect.y(), width: deltaLeft,
          height: oldClippedOverflowRect.height()))
    } else if deltaLeft < Int32(0) {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: newClippedOverflowRect.x(), y: newClippedOverflowRect.y(), width: -deltaLeft,
          height: newClippedOverflowRect.height()))
    }

    let deltaRight = newClippedOverflowRect.maxX() - oldClippedOverflowRect.maxX()
    if deltaRight > 0 {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: oldClippedOverflowRect.maxX(), y: newClippedOverflowRect.y(), width: deltaRight,
          height: newClippedOverflowRect.height()))
    } else if deltaRight < Int32(0) {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: newClippedOverflowRect.maxX(), y: oldClippedOverflowRect.y(), width: -deltaRight,
          height: oldClippedOverflowRect.height()))
    }

    let deltaTop = newClippedOverflowRect.y() - oldClippedOverflowRect.y()
    if deltaTop > 0 {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: oldClippedOverflowRect.x(), y: oldClippedOverflowRect.y(),
          width: oldClippedOverflowRect.width(), height: deltaTop))
    } else if deltaTop < Int32(0) {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: newClippedOverflowRect.x(), y: newClippedOverflowRect.y(),
          width: newClippedOverflowRect.width(), height: -deltaTop))
    }

    let deltaBottom = newClippedOverflowRect.maxY() - oldClippedOverflowRect.maxY()
    if deltaBottom > 0 {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: newClippedOverflowRect.x(), y: oldClippedOverflowRect.maxY(),
          width: newClippedOverflowRect.width(), height: deltaBottom))
    } else if deltaBottom < Int32(0) {
      repaintUsingContainer(
        repaintContainer,
        LayoutRectWrapper(
          x: oldClippedOverflowRect.x(), y: newClippedOverflowRect.maxY(),
          width: oldClippedOverflowRect.width(), height: -deltaBottom))
    }

    if !haveOutlinesBoundsRects || oldRects.outlineBoundsRect! == newRects.outlineBoundsRect! {
      return false
    }

    let oldOutlineBoundsRect = oldRects.outlineBoundsRect!
    let newOutlineBoundsRect = newRects.outlineBoundsRect!

    // Repainting the delta of the old and new clipped overflow rects is not sufficient when the box has outlines border and shadows,
    // because a size change has to repaint those areas affected by such decorations.
    // It's not really correct to do math here with oldOutlineBoundsRect/newOutlineBoundsRect and local shadow/radius values, since
    // oldOutlineBoundsRect/newOutlineBoundsRect are in the coordinate space of the repaint container, and have been mapped through ancestor transforms.

    let outlineStyle = outlineStyleForRepaint()
    let outlineWidth = LayoutUnit(value: outlineStyle.outlineSize())
    let insetShadowExtent = style!.boxShadowInsetExtent()
    let sizeDelta = LayoutSizeWrapper(
      width: (newOutlineBoundsRect.width() - oldOutlineBoundsRect.width()).abs(),
      height: (newOutlineBoundsRect.height() - oldOutlineBoundsRect.height()).abs())
    if sizeDelta.width() != 0 {
      var shadowLeft = LayoutUnit()
      var shadowRight = LayoutUnit()
      style!.getBoxShadowHorizontalExtent(left: &shadowLeft, right: &shadowRight)

      let insetExtent = { [self] () in
        // Inset "content" is inside the border box (e.g. border, negative outline and box shadow).
        let borderRightExtent = { [self] () in
          guard let renderBox = self as? RenderBoxWrapper else { return LayoutUnit() }
          let borderBoxWidth = renderBox.width()
          return max(
            renderBox.borderRight(),
            valueForLength(
              length: style!.borderTopRightRadius().width, maximumValue: borderBoxWidth),
            valueForLength(
              length: style!.borderBottomRightRadius().width, maximumValue: borderBoxWidth))
        }
        let outlineRightInsetExtent = { () in
          let offset = LayoutUnit(value: outlineStyle.outlineOffset())
          return offset < Int32(0) ? -offset : LayoutUnit(value: UInt64(0))
        }
        let boxShadowRightInsetExtent = { () in
          // Turn negative box shadow offset into inset.
          let inset = min(insetShadowExtent.right, shadowLeft)
          // Clip inset shadow at the clipped overflow rect. We would never paint outside.
          return inset < Int32(0)
            ? min(-inset, newClippedOverflowRect.width(), oldClippedOverflowRect.width())
            : LayoutUnit(value: UInt64(0))
        }
        // Outline starts at the border box while box shadow starts at the padding box.
        return max(outlineRightInsetExtent(), borderRightExtent() + boxShadowRightInsetExtent())
      }
      // Outset "content" is outside of the border box (e.g. regular outline and box shadow).
      let outsetExtent = max(outlineWidth, shadowRight)
      let decorationRightExtent = insetExtent() + outsetExtent
      // Both inset and outset "decorations" are within the "outline and box shadow" box.
      let decorationLeft =
        newOutlineBoundsRect.x() + min(newOutlineBoundsRect.width(), oldOutlineBoundsRect.width())
        - decorationRightExtent
      let clippedBoundsRight = min(newClippedOverflowRect.maxX(), oldClippedOverflowRect.maxX())
      var damageExtentWithinClippedOverflow = clippedBoundsRight - decorationLeft
      if damageExtentWithinClippedOverflow > 0 {
        damageExtentWithinClippedOverflow = min(
          sizeDelta.width() + decorationRightExtent, damageExtentWithinClippedOverflow)
        let damagedRect = LayoutRectWrapper(
          x: decorationLeft, y: newOutlineBoundsRect.y(), width: damageExtentWithinClippedOverflow,
          height: max(newOutlineBoundsRect.height(), oldOutlineBoundsRect.height()))
        repaintUsingContainer(repaintContainer, damagedRect)
      }
    }
    if sizeDelta.height() != 0 {
      var shadowTop = LayoutUnit()
      var shadowBottom = LayoutUnit()
      style!.getBoxShadowVerticalExtent(top: &shadowTop, bottom: &shadowBottom)

      let insetExtent = { () in
        // Inset "content" is inside the border box (e.g. border, negative outline and box shadow).
        let borderBottomExtent = { [self] () in
          guard let renderBox = self as? RenderBoxWrapper else { return LayoutUnit() }
          let borderBoxHeight = renderBox.height()
          return max(
            renderBox.borderBottom(),
            valueForLength(
              length: style!.borderBottomLeftRadius().height, maximumValue: borderBoxHeight),
            valueForLength(
              length: style!.borderBottomRightRadius().height, maximumValue: borderBoxHeight))
        }
        let outlineBottomInsetExtent = { () in
          let offset = LayoutUnit(value: outlineStyle.outlineOffset())
          return offset < Int32(0) ? -offset : LayoutUnit(value: 0)
        }
        let boxShadowBottomInsetExtent = { () in
          // Turn negative box shadow offset into inset.
          let inset = min(insetShadowExtent.bottom, shadowTop)
          // Clip inset shadow at the clipped overflow rect. We would never paint outside.
          return inset < Int32(0)
            ? min(-inset, newClippedOverflowRect.height(), oldClippedOverflowRect.height())
            : LayoutUnit(value: UInt64(0))
        }
        // Outline starts at the border box while box shadow starts at the padding box.
        return max(outlineBottomInsetExtent(), borderBottomExtent() + boxShadowBottomInsetExtent())
      }
      // Outset "content" is outside of the border box (e.g. regular outline and box shadow).
      let outsetExtent = max(outlineWidth, shadowBottom)
      let decorationBottomExtent = insetExtent() + outsetExtent
      // Both inset and outset "decorations" are within the "outline and box shadow" box.
      let decorationTop =
        min(newOutlineBoundsRect.maxY(), oldOutlineBoundsRect.maxY()) - decorationBottomExtent
      let clippedBoundsBottom = min(newClippedOverflowRect.maxY(), oldClippedOverflowRect.maxY())
      var damageExtentWithinClippedOverflow = clippedBoundsBottom - decorationTop
      if damageExtentWithinClippedOverflow > 0 {
        damageExtentWithinClippedOverflow = min(
          sizeDelta.height() + decorationBottomExtent, damageExtentWithinClippedOverflow)
        let damagedRect = LayoutRectWrapper(
          x: newOutlineBoundsRect.x(), y: decorationTop,
          width: max(newOutlineBoundsRect.width(), oldOutlineBoundsRect.width()),
          height: damageExtentWithinClippedOverflow)
        repaintUsingContainer(repaintContainer, damagedRect)
      }
    }
    return false
  }

  private func repaintClientsOfReferencedSVGResources() {
    if !document().settings().layerBasedSVGEngineEnabled() {
      return
    }

    if let enclosingResourceContainer = RenderAncestorIteratorAdapter<
      RenderSVGResourceContainerWrapper
    >.lineageOfType(first: self).first() {
      enclosingResourceContainer.repaintAllClients()
    }
  }

  func borderImageIsLoadedAndCanBeRendered() -> Bool {
    assert(style().hasBorder())

    if let borderImage = style().borderImage().image() {
      return borderImage.canRender(renderer: self, multiplier: style().usedZoom())
        && borderImage.isLoaded(renderer: self)
    }
    return false
  }

  func isVisibleIgnoringGeometry() -> Bool {
    if document().activeDOMObjectsAreSuspended() {
      return false
    }
    if style().usedVisibility() != .Visible {
      return false
    }
    if view().frameView().isOffscreen() {
      return false
    }

    return true
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

  func isInsideEntirelyHiddenLayer() -> Bool {
    if isSVGLayerAwareRenderer() && document().settings().layerBasedSVGEngineEnabled()
      && enclosingLayer()!.enclosingSVGHiddenOrResourceContainer != nil
    {
      return true
    }
    return style().usedVisibility() != .Visible && !enclosingLayer()!.hasVisibleContent
  }

  // Returns true if this renderer requires a new stacking context.
  static func createsGroupForStyle(style: RenderStyleWrapper) -> Bool {
    return style.hasOpacity() || style.hasMask() || style.clipPath() != nil || style.hasFilter()
      || style.hasBackdropFilter() || style.hasBlendMode()
  }

  func createsGroup() -> Bool {
    assert(isNativeImpl())
    return RenderElementWrapper.createsGroupForStyle(style: style())
  }

  func isTransparent() -> Bool {
    assert(isNativeImpl())
    return style().hasOpacity()
  }

  func opacity() -> Float32 {
    assert(isNativeImpl())
    return style().opacity()
  }

  func visibleToHitTesting(request: HitTestRequestWrapper? = nil) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackground() -> Bool {
    assert(isNativeImpl())
    return style().hasBackground()
  }

  func hasMask() -> Bool {
    assert(isNativeImpl())
    return style().hasMask()
  }

  func hasClip() -> Bool {
    assert(isNativeImpl())
    return isOutOfFlowPositioned() && style().hasClip()
  }

  func hasClipOrNonVisibleOverflow() -> Bool {
    assert(isNativeImpl())
    return hasClip() || hasNonVisibleOverflow()
  }

  func hasClipPath() -> Bool {
    assert(isNativeImpl())
    return style().clipPath() != nil
  }

  func hasHiddenBackface() -> Bool {
    assert(isNativeImpl())
    return style().backfaceVisibility() == .Hidden
  }

  func hasViewTransitionName() -> Bool {
    assert(isNativeImpl())
    return style().viewTransitionName() != nil
  }

  func isViewTransitionRoot() -> Bool {
    assert(isNativeImpl())
    return style().pseudoElementType() == .ViewTransition
  }

  func requiresRenderingConsolidationForViewTransition() -> Bool {
    return hasViewTransitionName() || capturedInViewTransition()
  }

  func hasOutlineAnnotation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutline() -> Bool {
    assert(isNativeImpl())
    return style().hasOutline() || hasOutlineAnnotation()
  }

  func hasSelfPaintingLayer() -> Bool {
    assert(!isNativeImpl())
    return wk_interop.RenderElement_hasSelfPaintingLayer(id())
  }

  func checkForRepaintDuringLayout() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderElement_checkForRepaintDuringLayout(id())
    }
    return everHadLayout() && !hasSelfPaintingLayer()
      && !document().view()!.layoutContext().needsFullRepaint()
  }

  func hasFilter() -> Bool {
    assert(isNativeImpl())
    return style().hasFilter()
  }

  func hasBackdropFilter() -> Bool {
    assert(isNativeImpl())
    return style().hasBackdropFilter()
  }

  func hasBlendMode() -> Bool {
    assert(isNativeImpl())
    return style().hasBlendMode()
  }

  private func visibleInViewportState() -> VisibleInViewportState {
    assert(isNativeImpl())
    return m_visibleInViewportState
  }

  func setVisibleInViewportState(_ state: VisibleInViewportState) {
    assert(isNativeImpl())
    if state == visibleInViewportState() {
      return
    }
    m_visibleInViewportState = state
    visibleInViewportStateChanged()
  }

  func visibleInViewportStateChanged() { fatalError("Not reached") }

  func repaintForPausedImageAnimationsIfNeeded(
    _ visibleRect: IntRect, _ cachedImage: CachedImageWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func imageOrientation() -> ImageOrientation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeFromRenderFragmentedFlow() {
    assert(fragmentedFlowState() != .NotInsideFlow)
    // Sometimes we remove the element from the flow, but it's not destroyed at that time.
    // It's only until later when we actually destroy it and remove all the children from it.
    // Currently, that happens for firstLetter elements and list markers.
    // Pass in the flow thread so that we don't have to look it up for all the children.
    removeFromRenderFragmentedFlowIncludingDescendants(true)
  }

  func resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants(
    fragmentedFlow: RenderFragmentedFlowWrapper? = nil
  ) {
    fragmentedFlow?.removeFlowChildInfo(self)

    for child: RenderElementWrapper in childrenOfType(parent: self) {
      child.resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants(
        fragmentedFlow: fragmentedFlow)
    }
  }

  // Called before anonymousChild.setStyle(). Override to set custom styles for
  // the child.
  func updateAnonymousChildStyle(_ childStyle: RenderStyleWrapper) {}

  func hasContinuationChainNode() -> Bool {
    assert(isNativeImpl())
    return m_hasContinuationChainNode
  }

  func isContinuation() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderElement_isContinuation(id())
    }
    return m_isContinuation
  }

  func setIsContinuation() {
    assert(isNativeImpl())
    m_isContinuation = true
  }

  func setIsFirstLetter() {
    assert(isNativeImpl())
    m_isFirstLetter = true
  }

  @discardableResult
  func attachRendererInternal(child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?)
    -> RenderObjectWrapper?
  {
    child!.setParent(parent: self)

    if CPtrToInt(m_firstChild?.id()) == CPtrToInt(beforeChild?.id()) {
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

    if CPtrToInt(parent.firstChild()?.id()) == CPtrToInt(renderer.id()) {
      parent.m_firstChild = nextSibling
    }
    if CPtrToInt(parent.lastChild()?.id()) == CPtrToInt(renderer.id()) {
      parent.m_lastChild = renderer
    }

    renderer.setPreviousSibling(previous: nil)
    renderer.setNextSibling(next: nil)
    renderer.setParent(parent: nil)
    return renderer
  }

  // https://www.w3.org/TR/css-transforms-1/#transform-box
  func transformReferenceBoxRect(style: RenderStyleWrapper) -> FloatRectWrapper {
    assert(isNativeImpl())
    return referenceBoxRect(boxType: transformBoxToCSSBoxType(style.transformBox()))
  }

  func transformReferenceBoxRect() -> FloatRectWrapper {
    assert(isNativeImpl())
    return transformReferenceBoxRect(style: style())
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
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? effectiveOverflowX() : effectiveOverflowY()
  }

  func effectiveOverflowBlockDirection() -> Overflow {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? effectiveOverflowY() : effectiveOverflowX()
  }

  func isWritingModeRoot() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderElement_isWritingModeRoot(id())
    }
    return parent() == nil || parent()!.style().writingMode() != style().writingMode()
  }

  func isDeprecatedFlexItem() -> Bool {
    return !isInline() && !isFloatingOrOutOfFlowPositioned() && parent() != nil
      && parent()!.isRenderDeprecatedFlexibleBox()
  }

  func isFlexItemIncludingDeprecated() -> Bool {
    assert(isNativeImpl())
    return !isInline() && !isFloatingOrOutOfFlowPositioned()
      && (parent()?.isFlexibleBoxIncludingDeprecated() ?? false)
  }

  func paintRectToClipOutFromBorder(paintRect: LayoutRectWrapper) -> LayoutRectWrapper {
    assert(isNativeImpl())
    return LayoutRectWrapper()
  }

  func paintFocusRing(
    paintInfo: PaintInfoWrapper, style: RenderStyleWrapper,
    focusRingRects: ArraySlice<LayoutRectWrapper>
  ) {
    assert(style.outlineStyleIsAuto() == .On)
    let outlineOffset = style.outlineOffset()
    var pixelSnappedFocusRingRects: [FloatRectWrapper] = []
    let deviceScaleFactor = document().deviceScaleFactor()
    for rect in focusRingRects {
      var rect = rect
      rect.inflate(d: outlineOffset)
      pixelSnappedFocusRingRects.append(
        snapRectToDevicePixels(rect: rect, pixelSnappingFactor: deviceScaleFactor))
    }
    var styleOptions = styleColorOptions()
    styleOptions.update(with: .UseSystemAppearance)
    let focusRingColor =
      usePlatformFocusRingColorForOutlineStyleAuto()
      ? RenderTheme.singleton().focusRingColor(options: styleOptions)
      : style.visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyOutlineColor)
    if useShrinkWrappedFocusRingForOutlineStyleAuto() && style.hasBorderRadius() {
      let path = PathUtilities.pathWithShrinkWrappedRectsForOutline(
        rects: pixelSnappedFocusRingRects, borderData: style.border(), outlineOffset: outlineOffset,
        direction: style.direction(),
        writingMode: style.writingMode(),
        deviceScaleFactor: document().deviceScaleFactor())
      if path.isEmpty() {
        for rect in pixelSnappedFocusRingRects {
          path.addRect(rect: rect)
        }
      }
      drawFocusRing(context: paintInfo.context(), path: path, style: style, color: focusRingColor)
    } else {
      drawFocusRing(
        context: paintInfo.context(), rects: pixelSnappedFocusRingRects, style: style,
        color: focusRingColor)
    }
  }

  func establishesIndependentFormattingContext() -> Bool {
    return renderElementEstablishesIndependentFormattingContext()
  }

  func renderElementEstablishesIndependentFormattingContext() -> Bool {
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

  typealias LayoutIdentifier = UInt32
  func setLayoutIdentifier(_ layoutIdentifier: LayoutIdentifier) {
    assert(isNativeImpl())
    m_layoutIdentifier = layoutIdentifier
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

  enum StylePropagationType {
    case AllChildren
    case BlockAndRubyChildren
  }

  func propagateStyleToAnonymousChildren(propagationType: StylePropagationType) {
    // FIXME: We could save this call when the change only affected non-inherited properties.
    for elementChild: RenderElementWrapper in childrenOfType(parent: self) {
      if !elementChild.isAnonymous() || elementChild.style().pseudoElementType() != .None {
        continue
      }

      let isBlockOrRuby =
        (elementChild is RenderBlockWrapper) || elementChild.style().display() == .Ruby
      if propagationType == .BlockAndRubyChildren && !isBlockOrRuby {
        continue
      }

      // RenderFragmentedFlows are updated through the RenderView::styleDidChange function.
      if elementChild is RenderFragmentedFlowWrapper {
        continue
      }

      let newStyle = { () in
        let display = elementChild.style().display()
        if display == .RubyBase || display == .Ruby {
          return createAnonymousStyleForRuby(parentStyle: style(), display: display)
        }
        return RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: style(), display: display)
      }()

      if style().specifiesColumns() {
        if elementChild.style().specifiesColumns() {
          newStyle.inheritColumnPropertiesFrom(style())
        }
        if elementChild.style().columnSpan() == .All {
          newStyle.setColumnSpan(.All)
        }
      }

      // Preserve the position style of anonymous block continuations as they can have relative or sticky position when
      // they contain block descendants of relative or sticky positioned inlines.
      if elementChild.isInFlowPositioned() && elementChild.isContinuation() {
        newStyle.setPosition(v: elementChild.style().position())
      }

      updateAnonymousChildStyle(newStyle)

      elementChild.setStyle(style: newStyle)
    }
  }

  private func repaintBeforeStyleChange(
    diff: StyleDifference, oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
  ) -> Bool {
    if oldStyle.usedVisibility() == .Hidden {
      // Repaint on hidden renderer is a no-op.
      return false
    }

    enum RequiredRepaint {
      case None
      case RendererOnly
      case RendererAndDescendantsRenderersWithLayers
    }

    let shouldRepaintBeforeStyleChange = { [self] () -> RequiredRepaint in
      if parent() == nil {
        // Can't resolve absolute coordinates.
        return .None
      }

      if self is RenderLayerModelObjectWrapper && hasLayer() {
        if diff == .RepaintLayer {
          return .RendererAndDescendantsRenderersWithLayers
        }

        if diff == .Layout || diff == .SimplifiedLayout {
          // Certain style changes require layer repaint, since the layer could end up being destroyed.
          let layerMayGetDestroyed =
            oldStyle.position() != newStyle.position()
            || oldStyle.usedZIndex() != newStyle.usedZIndex()
            || oldStyle.hasAutoUsedZIndex() != newStyle.hasAutoUsedZIndex()
            || oldStyle.clip() != newStyle.clip()
            || oldStyle.hasClip() != newStyle.hasClip()
            || oldStyle.hasOpacity() != newStyle.hasOpacity()
            || oldStyle.hasTransform() != newStyle.hasTransform()
            || oldStyle.hasFilter() != newStyle.hasFilter()
          if layerMayGetDestroyed {
            return .RendererAndDescendantsRenderersWithLayers
          }
        }
      }

      if shouldRepaintForStyleDifference(diff) {
        return .RendererOnly
      }

      if newStyle.outlineSize() < oldStyle.outlineSize() {
        return .RendererOnly
      }

      if let modelObject = self as? RenderLayerModelObjectWrapper {
        // If we don't have a layer yet, but we are going to get one because of transform or opacity, then we need to repaint the old position of the object.
        let hasLayer = modelObject.hasLayer()
        let willHaveLayer =
          newStyle.affectsTransform() || newStyle.hasOpacity() || newStyle.hasFilter()
          || newStyle.hasBackdropFilter()
        if !hasLayer && willHaveLayer {
          return .RendererOnly
        }
      }

      if self is RenderBoxWrapper {
        if diff == .Layout && oldStyle.position() != newStyle.position()
          && oldStyle.position() == .Static
        {
          return .RendererOnly
        }
      }

      if diff > .RepaintLayer
        && oldStyle.usedVisibility() != newStyle.usedVisibility(),
        let enclosingLayer = enclosingLayer()
      {
        let rendererWillBeHidden = newStyle.usedVisibility() != .Visible
        if rendererWillBeHidden && enclosingLayer.hasVisibleContent
          && (CPtrToInt(id()) == CPtrToInt(enclosingLayer.renderer().id())
            || enclosingLayer.renderer().style().usedVisibility() != .Visible)
        {
          return .RendererOnly
        }
      }

      if diff > .RepaintLayer
        && oldStyle.usedContentVisibility() != newStyle.usedContentVisibility()
        && isOutOfFlowPositioned(), let enclosingLayer = enclosingLayer()
      {
        let rendererWillBeHidden = isSkippedContent()
        if rendererWillBeHidden && enclosingLayer.hasVisibleContent
          && (CPtrToInt(id()) == CPtrToInt(enclosingLayer.renderer().id())
            || enclosingLayer.renderer().style().usedVisibility() != .Visible)
        {
          return .RendererOnly
        }
      }

      if diff == .Layout && parent()!.style().isFlippedBlocksWritingMode() {
        // FIXME: Repaint during (after) layout is currently broken for flipped writing modes in block direction (mostly affecting vertical-rl) (see webkit.org/b/70762)
        // This repaint call here ensures we invalidate at least the current rect which should cover the non-moving type of cases.
        return .RendererOnly
      }

      return .None
    }()

    if shouldRepaintBeforeStyleChange == .RendererAndDescendantsRenderersWithLayers {
      assert(hasLayer())
      (self as! RenderLayerModelObjectWrapper).checkedLayer()!.repaintIncludingDescendants()
      return true
    }

    if shouldRepaintBeforeStyleChange == .RendererOnly {
      if isOutOfFlowPositioned()
        && (self as! RenderLayerModelObjectWrapper).checkedLayer()!.isSelfPaintingLayer
      {
        if let cachedClippedOverflowRect = (self as! RenderLayerModelObjectWrapper).checkedLayer()!
          .cachedClippedOverflowRect()
        {
          repaintUsingContainer(containerForRepaint().renderer, cachedClippedOverflowRect)
          return true
        }
      }
      repaint()
      return true
    }

    return false
  }

  func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    assert(
      settings().shouldAllowUserInstalledFonts()
        || newStyle.fontDescription().shouldAllowUserInstalledFonts() == .No)

    let oldStyle = hasInitializedStyle ? style() : nil

    let updateContentVisibilityDocumentStateIfNeeded = { [self] () in
      if element() == nil {
        return
      }
      let contentVisibilityChanged =
        oldStyle != nil && oldStyle!.contentVisibility() != newStyle.contentVisibility()
      if contentVisibilityChanged {
        if oldStyle!.contentVisibility() == .Auto {
          ContentVisibilityDocumentState.unobserve(protectedElement()!)
        }
        let wasSkippedContent: IsSkippedContent =
          oldStyle!.contentVisibility() == .Hidden ? .Yes : .No
        let isSkippedContent: IsSkippedContent =
          newStyle.contentVisibility() == .Hidden ? .Yes : .No
        ContentVisibilityDocumentState.updateAnimations(
          element()!, wasSkippedContent, isSkippedContent)
      }
      if (contentVisibilityChanged || oldStyle == nil) && newStyle.contentVisibility() == .Auto {
        ContentVisibilityDocumentState.observe(protectedElement()!)
      }
    }

    if oldStyle != nil {
      if diff >= .Repaint && layoutBox() != nil {
        // FIXME: It is highly unlikely that a style mutation has effect on both the formatting context the box lives in
        // and the one it establishes but calling only one would require to come up with a list of properties that only affects one or the other.
        if let inlineFormattingContextRoot = self as? RenderBlockFlowWrapper,
          inlineFormattingContextRoot.inlineLayout() != nil
        {
          inlineFormattingContextRoot.inlineLayout()!.rootStyleWillChange(
            root: inlineFormattingContextRoot, newStyle: newStyle)
        }
        if let lineLayout = LayoutIntegration.LineLayout.containing(renderer: self) {
          lineLayout.styleWillChange(renderer: self, newStyle: newStyle, diff: diff)
        }
      }
      // If our z-index changes value or our visibility changes,
      // we need to dirty our stacking context's z-order list.
      let visibilityChanged =
        style!.usedVisibility() != newStyle.usedVisibility()
        || style!.usedZIndex() != newStyle.usedZIndex()
        || style!.hasAutoUsedZIndex() != newStyle.hasAutoUsedZIndex()

      if visibilityChanged {
        protectedDocument().invalidateRenderingDependentRegions()
      }

      let inertChanged = style!.effectiveInert() != newStyle.effectiveInert()

      if visibilityChanged || inertChanged {
        if let cache = document().existingAXObjectCache() {
          cache.childrenChanged(renderer: checkedParent()!, changedChild: self)
        }
      }

      // Keep layer hierarchy visibility bits up to date if visibility or skipped content state changes.
      let wasVisible = style!.usedVisibility() == .Visible && !style!.hasSkippedContent()
      let willBeVisible = newStyle.usedVisibility() == .Visible && !newStyle.hasSkippedContent()
      if wasVisible != willBeVisible, let layer = enclosingLayer() {
        if willBeVisible {
          if style!.hasSkippedContent() && isSkippedContentRoot() {
            layer.dirtyVisibleContentStatus()
          } else {
            layer.setHasVisibleContent()
          }
        } else if layer.hasVisibleContent
          && (CPtrToInt(id()) == CPtrToInt(layer.renderer().id())
            || layer.renderer().style().usedVisibility() != .Visible)
        {
          layer.dirtyVisibleContentStatus()
        }
      }

      let needsInvalidateEventRegion = { [self] () in
        if style!.usedPointerEvents() != newStyle.usedPointerEvents() {
          return true
        }

        if style!.eventListenerRegionTypes() != newStyle.eventListenerRegionTypes() {
          return true
        }

        return false
      }

      if needsInvalidateEventRegion(), let layer = enclosingLayer() {
        // Usually the event region gets updated as a result of paint invalidation. Here we need to request an update explicitly.
        layer.invalidateEventRegion(reason: .Style)
      }

      if isFloating() && style!.floating() != newStyle.floating() {
        // For changes in float styles, we need to conceivably remove ourselves
        // from the floating objects list.
        (self as! RenderBoxWrapper).removeFloatingOrPositionedChildFromBlockLists()
      } else if isOutOfFlowPositioned() && style!.position() != newStyle.position() {
        // For changes in positioning styles, we need to conceivably remove ourselves
        // from the positioned objects list.
        (self as! RenderBoxWrapper).removeFloatingOrPositionedChildFromBlockLists()
      }

      // reset style flags
      if diff == .Layout || diff == .LayoutPositionedMovementOnly {
        setFloating(false)
        clearPositionedState()
      }

      setHorizontalWritingMode(true)
      setHasVisibleBoxDecorations(false)
      setHasNonVisibleOverflow(false)
      setHasTransformRelatedProperty(false)
      setHasReflection(false)
    }

    updateContentVisibilityDocumentStateIfNeeded()

    let hadOutline = oldStyle != nil && oldStyle!.hasOutline()
    let hasOutline = newStyle.hasOutline()
    if hadOutline != hasOutline {
      if hasOutline {
        checkedView().incrementRendersWithOutline()
      } else {
        checkedView().decrementRendersWithOutline()
      }
    }

    var newStyleSlowScroll = false
    if newStyle.hasAnyFixedBackground() && !settings().fixedBackgroundsPaintRelativeToDocument() {
      newStyleSlowScroll = true
      let drawsRootBackground =
        isDocumentElementRenderer()
        || (isBody()
          && !rendererHasBackground(renderer: document().documentElement()!.containerRenderer()))
      if drawsRootBackground && newStyle.hasEntirelyFixedBackground()
        && view().compositor().supportsFixedRootBackgroundCompositing()
      {
        newStyleSlowScroll = false
      }
    }

    if view().frameView().hasSlowRepaintObject(self) {
      if !newStyleSlowScroll {
        view().protectedFrameView().removeSlowRepaintObject(self)
      }
    } else if newStyleSlowScroll {
      view().protectedFrameView().addSlowRepaintObject(self)
    }

    if isDocumentElementRenderer() || isBody() {
      view().protectedFrameView().updateExtendBackgroundIfNecessary()
    }
  }

  func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    let registerImages = { [self] (style: RenderStyleWrapper?, oldStyle: RenderStyleWrapper?) in
      if style == nil && oldStyle == nil {
        return
      }
      updateFillImages(
        oldLayers: oldStyle?.protectedBackgroundLayers(),
        newLayers: style?.protectedBackgroundLayers())
      updateFillImages(
        oldLayers: oldStyle?.protectedMaskLayers(), newLayers: style?.protectedMaskLayers())
      updateImage(
        oldImage: oldStyle?.borderImage().protectedImage(),
        newImage: style?.borderImage().protectedImage())
      updateShapeImage(
        oldShapeValue: oldStyle?.protectedShapeOutside(),
        newShapeValue: style?.protectedShapeOutside())
    }

    registerImages(style(), oldStyle)

    // Are there other pseudo-elements that need the resources to be registered?
    registerImages(
      style().getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .FirstLine)),
      oldStyle?.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .FirstLine)))

    SVGRenderSupport.styleChanged(renderer: self, oldStyle: oldStyle)

    if diff >= .Repaint {
      updateReferencedSVGResources()
      if oldStyle != nil && diff <= .RepaintLayer {
        repaintClientsOfReferencedSVGResources()
      }
    }

    if parent() == nil {
      return
    }

    if diff == .Layout || diff == .SimplifiedLayout {
      RenderCounter.rendererStyleChanged(renderer: self, oldStyle: oldStyle, newStyle: style!)

      // If the object already needs layout, then setNeedsLayout won't do
      // any work. But if the containing block has changed, then we may need
      // to mark the new containing blocks for layout. The change that can
      // directly affect the containing block of this object is a change to
      // the position style.
      if needsLayout() && oldStyle != nil && oldStyle!.position() != style!.position() {
        scheduleLayout(layoutRoot: markContainingBlocksForLayout())
      }

      if diff == .Layout {
        setNeedsLayoutAndPrefWidthsRecalc()
      } else {
        setNeedsSimplifiedNormalFlowLayout()
      }
    } else if diff == .SimplifiedLayoutAndPositionedMovement {
      setNeedsPositionedMovementLayout(oldStyle)
      setNeedsSimplifiedNormalFlowLayout()
    } else if diff == .LayoutPositionedMovementOnly {
      setNeedsPositionedMovementLayout(oldStyle)
    }

    // Don't check for repaint here; we need to wait until the layer has been
    // updated by subclasses before we know if we have to repaint (in setStyle()).

    if oldStyle != nil && !areCursorsEqual(oldStyle!, style()) {
      protectedFrame().checkedEventHandler().scheduleCursorUpdate()
    }

    let hadOutlineAuto = oldStyle != nil && oldStyle!.outlineStyleIsAuto() == .On
    let hasOutlineAuto = outlineStyleForRepaint().outlineStyleIsAuto() == .On
    if hasOutlineAuto != hadOutlineAuto {
      updateOutlineAutoAncestor(hasOutlineAuto)
      issueRepaintForOutlineAuto(
        hasOutlineAuto ? outlineStyleForRepaint().outlineSize() : oldStyle!.outlineSize())
    }

    let notifyChildHadSuppressingStyleChange = { (shouldCheckIfInAncestorChain: Bool) in
      if let controller = RenderObjectWrapper.searchParentChainForScrollAnchoringController(self),
        !shouldCheckIfInAncestorChain
          || (shouldCheckIfInAncestorChain && controller.isInScrollAnchoringAncestorChain(self))
      {
        controller.notifyChildHadSuppressingStyleChange()
      }
    }

    if frame().settings().cssScrollAnchoringEnabled()
      && (style().outOfFlowPositionStyleDidChange(oldStyle)
        || style().scrollAnchoringSuppressionStyleDidChange(oldStyle))
    {
      if style().outOfFlowPositionStyleDidChange(oldStyle) {
        notifyChildHadSuppressingStyleChange(false)
      } else {
        notifyChildHadSuppressingStyleChange(
          style().scrollAnchoringSuppressionStyleDidChange(oldStyle))
      }
    }

    // FIXME: First line change on the block comes in as equal on inline boxes.
    let needsLayoutBoxStyleUpdate =
      (diff >= .Repaint
        || ((self is RenderInlineWrapper) && CPtrToInt(style().p) != CPtrToInt(firstLineStyle().p)))
      && layoutBox() != nil
    if needsLayoutBoxStyleUpdate {
      LayoutIntegration.LineLayout.updateStyle(self)
    }
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

  private func updateOutlineAutoAncestor(_ hasOutlineAuto: Bool) {
    if let placeholder = self as? RenderMultiColumnSpannerPlaceholderWrapper {
      let spanner = placeholder.spanner()!
      spanner.setHasOutlineAutoAncestor(hasOutlineAutoAncestor: hasOutlineAuto)
      spanner.updateOutlineAutoAncestor(hasOutlineAuto)
    }

    for child: RenderObjectWrapper in childrenOfType(parent: self) {
      if hasOutlineAuto == child.hasOutlineAutoAncestor() {
        continue
      }
      child.setHasOutlineAutoAncestor(hasOutlineAutoAncestor: hasOutlineAuto)
      let childHasOutlineAuto = child.outlineStyleForRepaint().outlineStyleIsAuto() == .On
      if childHasOutlineAuto {
        continue
      }
      if let element = child as? RenderElementWrapper {
        element.updateOutlineAutoAncestor(hasOutlineAuto)
      }
    }
    if let modelObject = self as? RenderBoxModelObjectWrapper,
      let continuation = modelObject.continuation()
    {
      continuation.updateOutlineAutoAncestor(hasOutlineAuto)
    }
  }

  private func removeFromRenderFragmentedFlowIncludingDescendants(_ shouldUpdateState: Bool) {
    var shouldUpdateState = shouldUpdateState
    // Once we reach another flow thread we don't need to update the flow thread state
    // but we have to continue cleanup the flow thread info.
    if isRenderFragmentedFlow() {
      shouldUpdateState = false
    }

    for child: RenderObjectWrapper in childrenOfType(parent: self) {
      if let element = child as? RenderElementWrapper {
        element.removeFromRenderFragmentedFlowIncludingDescendants(shouldUpdateState)
        continue
      }
      if shouldUpdateState {
        child.setFragmentedFlowState(.NotInsideFlow)
      }
    }

    // We have to ask for our containing flow thread as it may be above the removed sub-tree.
    var enclosingFragmentedFlow = enclosingFragmentedFlow()
    while enclosingFragmentedFlow != nil {
      enclosingFragmentedFlow!.removeFlowChildInfo(self)

      if enclosingFragmentedFlow!.fragmentedFlowState() == .NotInsideFlow {
        break
      }
      guard let parent = enclosingFragmentedFlow!.parent() else { break }
      enclosingFragmentedFlow = parent.enclosingFragmentedFlow()
    }
    if let block = self as? RenderBlockWrapper {
      block.setCachedEnclosingFragmentedFlowNeedsUpdate()
    }

    if shouldUpdateState {
      setFragmentedFlowState(.NotInsideFlow)
    }
  }

  func adjustFragmentedFlowStateOnContainingBlockChangeIfNeeded(
    oldStyle: RenderStyleWrapper, newStyle: RenderStyleWrapper
  ) {
    if fragmentedFlowState() == .NotInsideFlow {
      return
    }

    // Make sure we invalidate the containing block cache for flows when the contianing block context changes
    // so that styleDidChange can safely use RenderBlock::locateEnclosingFragmentedFlow()
    // FIXME: Share some code with RenderElement::canContain*.
    let mayNotBeContainingBlockForDescendantsAnymore =
      oldStyle.position() != style!.position()
      || oldStyle.hasTransformRelatedProperty() != style!.hasTransformRelatedProperty()
      || oldStyle.willChange() != newStyle.willChange()
      || oldStyle.hasBackdropFilter() != newStyle.hasBackdropFilter()
      || oldStyle.containsLayout() != newStyle.containsLayout()
      || oldStyle.containsSize() != newStyle.containsSize()
    if !mayNotBeContainingBlockForDescendantsAnymore {
      return
    }

    // Invalidate the containing block caches.
    if let block = self as? RenderBlockWrapper {
      block.resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants()
    } else {
      // Relatively positioned inline boxes can have absolutely positioned block descendants. We need to reset them as well.
      for descendant: RenderBlockWrapper in descendantsOfType(root: self) {
        descendant.resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants()
      }
    }

    // Adjust the flow tread state on the subtree.
    setFragmentedFlowState(RenderObjectWrapper.computedFragmentedFlowState(self))
    for descendant: RenderObjectWrapper in descendantsOfType(root: self) {
      descendant.setFragmentedFlowState(RenderObjectWrapper.computedFragmentedFlowState(descendant))
    }
  }

  func isVisibleInViewport() -> Bool {
    let frameView = view().frameView()
    let visibleRect = frameView.windowToContents(windowRect: frameView.windowClipRect())
    return isVisibleInDocumentRect(documentRect: visibleRect)
  }

  private func shouldApplyLayoutOrPaintContainment(_ containsAccordingToStyle: Bool) -> Bool {
    return containsAccordingToStyle && (!isInline() || isAtomicInlineLevelBox())
      && style().display() != .RubyAnnotation && (!isTablePart() || isRenderBlockFlow())
  }

  // FIXME: try to avoid duplication with isSkippedContentRoot.
  private func shouldApplySizeOrStyleContainment(_ containsAccordingToStyle: Bool) -> Bool {
    return containsAccordingToStyle && (!isInline() || isAtomicInlineLevelBox())
      && style().display() != .RubyAnnotation && (!isTablePart() || isRenderTableCaption())
      && !isRenderTable()
  }

  override func lastChildSlow() -> RenderObjectWrapper? { return lastChild() }

  private func rendererForPseudoStyleAcrossShadowBoundary() -> RenderElementWrapper? {
    guard let root = element()!.containingShadowRoot() else { return nil }
    if root.mode() != .UserAgent {
      return nil
    }
    var currentElement = element()!.shadowHost()
    // When an element has display: contents, this element doesn't have a renderer
    // and its children will render as children of the parent element.
    while currentElement != nil && currentElement!.hasDisplayContents() {
      currentElement = currentElement!.parentElement()
    }
    return currentElement?.containerRenderer()
  }

  private func shouldRepaintForStyleDifference(_ diff: StyleDifference) -> Bool {
    let hasImmediateNonWhitespaceTextChild = { () in
      for child: RenderTextWrapper in childrenOfType(parent: self) {
        if !child.containsOnlyCollapsibleWhitespace() {
          return true
        }
      }
      return false
    }
    return diff == .Repaint || (diff == .RepaintIfText && hasImmediateNonWhitespaceTextChild())
  }

  private func updateFillImages(oldLayers: FillLayerWrapper?, newLayers: FillLayerWrapper?) {
    let fillImagesAreIdentical = { (layer1: FillLayerWrapper?, layer2: FillLayerWrapper?) in
      if (layer1 == nil && layer2 == nil)
        || (ObjectIdentifier(layer1!) == ObjectIdentifier(layer2!))
      {
        return true
      }

      var layer1 = layer1
      var layer2 = layer2
      while layer1 != nil && layer2 != nil {
        if !arePointingToEqualData(layer1!.image(), layer2!.image()) {
          return false
        }
        if layer1!.image() != nil && layer1!.image()!.usesDataProtocol() {
          return false
        }
        if let styleImage = layer1!.image() {
          if styleImage.errorOccurred() || !styleImage.hasImage() || styleImage.usesDataProtocol() {
            return false
          }
        }
        layer1 = layer1!.next()
        layer2 = layer2!.next()
      }

      return layer1 == nil && layer2 == nil
    }

    let isRegisteredWithNewFillImages = { () in
      var layer = newLayers
      while layer != nil {
        if layer!.image() != nil && !layer!.image()!.hasClient(self) {
          return false
        }
        layer = layer!.next()
      }
      return true
    }

    // If images have the same characteristics and this element is already registered as a
    // client to the new images, there is nothing to do.
    if fillImagesAreIdentical(oldLayers, newLayers) && isRegisteredWithNewFillImages() {
      return
    }

    // Add before removing, to avoid removing all clients of an image that is in both sets.
    do {
      var layer = newLayers
      while layer != nil {
        if let image = layer!.image() {
          image.addClient(self)
        }
        layer = layer!.next()
      }
    }
    do {
      var layer = oldLayers
      while layer != nil {
        if let image = layer!.image() {
          image.removeClient(self)
        }
        layer = layer!.next()
      }
    }
  }

  private func updateImage(oldImage: StyleImage?, newImage: StyleImage?) {
    if oldImage === newImage {
      return
    }
    oldImage?.removeClient(self)
    newImage?.addClient(self)
  }

  private func updateShapeImage(oldShapeValue: ShapeValue?, newShapeValue: ShapeValue?) {
    if oldShapeValue != nil || newShapeValue != nil {
      updateImage(oldImage: oldShapeValue?.image(), newImage: newShapeValue?.protectedImage())
    }
  }

  private func adjustStyleDifference(
    _ diff: StyleDifference, _ contextSensitiveProperties: StyleDifferenceContextSensitiveProperty
  ) -> StyleDifference {
    var diff = diff
    // If transform changed, and we are not composited, need to do a layout.
    if contextSensitiveProperties.contains(.Transform) {
      // FIXME: when transforms are taken into account for overflow, we will need to do a layout.
      if !hasLayer() || !(self as! RenderLayerModelObjectWrapper).layer()!.isComposited() {
        if !hasLayer() {
          diff = max(diff, .Layout)
        } else {
          // We need to set at least SimplifiedLayout, but if PositionedMovementOnly is already set
          // then we actually need SimplifiedLayoutAndPositionedMovement.
          diff = max(
            diff,
            (diff == .LayoutPositionedMovementOnly)
              ? .SimplifiedLayoutAndPositionedMovement : .SimplifiedLayout)
        }

      } else {
        diff = max(diff, .RecompositeLayer)
      }
    }

    if contextSensitiveProperties.contains(.Opacity) {
      if !hasLayer() || !(self as! RenderLayerModelObjectWrapper).layer()!.isComposited() {
        diff = max(diff, .RepaintLayer)
      } else {
        diff = max(diff, .RecompositeLayer)
      }
    }

    if contextSensitiveProperties.contains(.ClipPath) {
      if hasLayer() && (self as! RenderLayerModelObjectWrapper).layer()!.willCompositeClipPath() {
        diff = max(diff, .RecompositeLayer)
      } else {
        diff = max(diff, .Repaint)
      }
    }

    if contextSensitiveProperties.contains(.WillChange) {
      if style().willChange() != nil && style().willChange()!.canTriggerCompositing() {
        diff = max(diff, .RecompositeLayer)
      }
    }

    if contextSensitiveProperties.contains(.Filter) && hasLayer() {
      let layer = (self as! RenderLayerModelObjectWrapper).layer()!
      if !layer.isComposited() || layer.paintsWithFilters() {
        diff = max(diff, .RepaintLayer)
      } else {
        diff = max(diff, .RecompositeLayer)
      }
    }

    // The answer to requiresLayer() for plugins, iframes, and canvas can change without the actual
    // style changing, since it depends on whether we decide to composite these elements. When the
    // layer status of one of these elements changes, we need to force a layout.
    if diff < .Layout {
      if let modelObject = self as? RenderLayerModelObjectWrapper {
        if hasLayer() != modelObject.requiresLayer() {
          diff = .Layout
        }
      }
    }

    // If we have no layer(), just treat a RepaintLayer hint as a normal Repaint.
    if diff == .RepaintLayer && !hasLayer() {
      diff = .Repaint
    }

    return diff
  }

  private func issueRepaintForOutlineAuto(_ outlineSize: Float32) {
    var repaintRect = LayoutRectWrapper()
    var focusRingRects: [LayoutRectWrapper] = []
    addFocusRingRects(
      rects: &focusRingRects, additionalOffset: LayoutPointWrapper(),
      paintContainer: containerForRepaint().renderer)
    for var rect in focusRingRects {
      rect.inflate(d: outlineSize)
      repaintRect.unite(other: rect)
    }
    repaintRectangle(repaintRect: repaintRect)
  }

  // This needs to run when the entire render tree has been constructed, so can't be called from styleDidChange.
  private func updateReferencedSVGResources() {
    let referencedElementIDs = ReferencedSVGResources.referencedSVGResourceIDs(style(), document())
    if !referencedElementIDs.isEmpty {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    } else {
      clearReferencedSVGResources()
    }
  }

  private func clearReferencedSVGResources() {
    if !hasRareData() {
      return
    }

    ensureRareData().referencedSVGResources = nil
  }

  private var m_firstChild: RenderObjectWrapper?
  var hasInitializedStyle: Bool

  private let m_hasPausedImageAnimations: Bool
  private let m_hasCounterNodeMap: Bool
  private let m_hasContinuationChainNode: Bool

  private var m_isContinuation: Bool
  private var m_isFirstLetter: Bool
  var renderBlockHasMarginBeforeQuirk: Bool
  var renderBlockHasMarginAfterQuirk: Bool
  var renderBlockShouldForceRelayoutChildren: Bool
  private let m_renderBlockFlowLineLayoutPath: RenderBlockFlowWrapper.LineLayoutPath

  private var m_lastChild: RenderObjectWrapper?

  private let m_isRegisteredForVisibleInViewportCallback: Bool
  private var m_visibleInViewportState: VisibleInViewportState
  private let m_didContributeToVisuallyNonEmptyPixelCount: Bool
  private var m_layoutIdentifier: LayoutIdentifier = 0

  private let style: RenderStyleWrapper?  // TODO(asuhan): not nil once we have initializers
}
