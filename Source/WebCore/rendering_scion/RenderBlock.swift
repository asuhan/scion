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

enum CaretType {
  case CursorCaret
  case DragCaret
}

enum ContainingBlockState {
  case NewContainingBlock
  case SameContainingBlock
}

private func findFirstLetterBlock(start: RenderBlockWrapper) -> RenderBlockWrapper? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class RenderBlockWrapper: RenderBoxWrapper {
  // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
  func deleteLines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func removePositionedObject(rendererToRemove: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removePositionedObjects(
    newContainingBlockCandidate: RenderBlockWrapper?,
    containingBlockState: ContainingBlockState = .SameContainingBlock
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasPositionedObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addPercentHeightDescendant(descendant: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func removePercentHeightDescendant(descendant: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func hasPercentHeightContainerMap() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func hasPercentHeightDescendant(descendant: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func removePercentHeightDescendantIfNeeded(descendant: RenderBoxWrapper) {
    // We query the map directly, rather than looking at style's
    // logicalHeight()/logicalMinHeight()/logicalMaxHeight() since those
    // can change with writing mode/directional changes.
    if !hasPercentHeightContainerMap() {
      return
    }

    if !hasPercentHeightDescendant(descendant: descendant) {
      return
    }

    removePercentHeightDescendant(descendant: descendant)
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all of the line layout code has been moved out of RenderBlock
  func containsFloats() -> Bool {
    return wk_interop.RenderBlock_containsFloats(p)
  }

  func addContinuationWithOutline(flow: RenderInlineWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createAnonymousBlock(display: DisplayType = .Block) -> RenderBlockWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    return createAnonymousBlockWithStyleAndDisplay(
      document: document(), style: renderer.style(), display: style().display())
  }

  func setPaginationStrut(strut: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Fieldset legends that are taller than the fieldset border add in intrinsic border
  // in order to ensure that content gets properly pushed down across all layout systems
  // (flexbox, block, etc.)
  func intrinsicBorderForFieldset() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBlock_intrinsicBorderForFieldset(p))
  }

  override func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintExcludedChildrenInBorder(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !isFieldset() || isSkippedContentRoot() {
      return
    }

    if let box = findFieldsetLegend() {
      if !box.isExcludedFromNormalLayout() || box.hasSelfPaintingLayerModelObject() {
        return
      }

      let childPoint = flipForWritingModeForChild(child: box, point: paintOffset)
      box.paintAsInlineBlock(paintInfo: paintInfo, childPoint: childPoint)
    }
  }

  struct FirstLetterRenderObjects {
    let firstLetter: RenderObjectWrapper?
    let firstLetterContainer: RenderElementWrapper?
  }

  func getFirstLetter(skipObject: RenderObjectWrapper? = nil) -> FirstLetterRenderObjects {
    var firstLetter: RenderObjectWrapper? = nil
    var firstLetterContainer: RenderElementWrapper? = nil

    // Don't recur
    if style().pseudoElementType() == .FirstLetter {
      return FirstLetterRenderObjects(
        firstLetter: firstLetter, firstLetterContainer: firstLetterContainer)
    }

    // FIXME: We need to destroy the first-letter object if it is no longer the first child. Need to find
    // an efficient way to check for that situation though before implementing anything.
    firstLetterContainer = findFirstLetterBlock(start: self)
    if firstLetterContainer == nil {
      return FirstLetterRenderObjects(
        firstLetter: firstLetter, firstLetterContainer: firstLetterContainer)
    }

    // Drill into inlines looking for our first text descendant.
    firstLetter = firstLetterContainer!.firstChild()
    while firstLetter != nil {
      if firstLetter is RenderTextWrapper {
        if CPtrToInt(firstLetter!.p) == CPtrToInt(skipObject?.p) {
          firstLetter = firstLetter!.nextSibling()
          continue
        }

        break
      }

      let current = firstLetter as! RenderElementWrapper
      if current is RenderListMarkerWrapper {
        firstLetter = current.nextSibling()
      } else if current.isFloatingOrOutOfFlowPositioned() {
        if current.style().pseudoElementType() == .FirstLetter {
          firstLetter = current.firstChild()
          break
        }
        firstLetter = current.nextSibling()
      } else if current.isReplacedOrInlineBlock() || current is RenderButtonWrapper
        || current is RenderMenuListWrapper
      {
        break
      } else if current.isFlexibleBoxIncludingDeprecated() || current.isRenderGrid() {
        firstLetter = current.nextSibling()
      } else if current.style().hasPseudoStyle(pseudo: .FirstLetter)
        && current.canHaveGeneratedChildren()
      {
        // We found a lower-level node with first-letter, which supersedes the higher-level style
        firstLetterContainer = current
        firstLetter = current.firstChild()
      } else {
        firstLetter = current.firstChild()
      }
    }

    if firstLetter == nil {
      firstLetterContainer = nil
    }

    return FirstLetterRenderObjects(
      firstLetter: firstLetter, firstLetterContainer: firstLetterContainer)
  }

  func canDropAnonymousBlockChild() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  final func resetEnclosingFragmentedFlowAndChildInfoIncludingDescendants(
    fragmentedFlow: RenderFragmentedFlowWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func availableLogicalHeightForPercentageComputation() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    let adjustedPaintOffset = paintOffset + location()
    let phase = paintInfo.phase

    if visualContentIsClippedOut(paintInfo: paintInfo, adjustedPaintOffset: adjustedPaintOffset) {
      return
    }

    let pushedClip = pushContentsClip(paintInfo: &paintInfo, accumulatedOffset: adjustedPaintOffset)
    paintObject(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
    if pushedClip {
      popContentsClip(
        paintInfo: &paintInfo, originalPhase: phase, accumulatedOffset: adjustedPaintOffset)
    }

    // Our scrollbar widgets paint exactly when we tell them to, so that they work properly with
    // z-index. We paint after we painted the background/border, so that the scrollbars will
    // sit above the background/border.
    if (phase != .BlockBackground && phase != .ChildBlockBackground) || !hasNonVisibleOverflow() {
      return
    }
    if let layer = layer(), let scrollableArea = layer.scrollableArea(),
      style().usedVisibility() == .Visible
        && paintInfo.shouldPaintWithinRoot(renderer: self) && !paintInfo.paintRootBackgroundOnly()
    {
      scrollableArea.paintOverflowControls(
        context: paintInfo.context(), paintOffset: roundedIntPoint(point: adjustedPaintOffset),
        damageRect: snappedIntRect(rect: paintInfo.rect))
    }
  }

  // FIXME: Could eliminate the isDocumentElementRenderer() check if we fix background painting so that the RenderView paints the root's background.
  private func visualContentIsClippedOut(
    paintInfo: PaintInfoWrapper, adjustedPaintOffset: LayoutPointWrapper
  ) -> Bool {
    if isDocumentElementRenderer() {
      return false
    }

    if paintInfo.paintBehavior.contains(.CompositedOverflowScrollContent) && hasLayer()
      && layer()!.usesCompositedScrolling()
    {
      return false
    }

    var overflowBox = visualOverflowRect()
    flipForWritingMode(rect: &overflowBox)
    overflowBox.moveBy(offset: adjustedPaintOffset)
    return !overflowBox.intersects(other: paintInfo.rect)
  }

  override func paintObject(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
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

    // 3. paint selection
    // FIXME: Make this work with multi column layouts.  For now don't fill gaps.
    let isPrinting = document().printing()
    if !isPrinting {
      paintSelection(paintInfo: paintInfo, paintOffset: scrolledOffset)  // Fill in gaps in selection on lines and between blocks.
    }

    // 4. paint floats.
    if paintPhase == .Float || paintPhase == .Selection || paintPhase == .TextClip
      || paintPhase == .EventRegion || paintPhase == .Accessibility
    {
      paintFloats(
        paintInfo: paintInfo, paintOffset: scrolledOffset,
        preservePhase: paintPhase == .Selection || paintPhase == .TextClip
          || paintPhase == .EventRegion
          || paintPhase == .Accessibility)
    }

    // 5. paint outline.
    if (paintPhase == .Outline || paintPhase == .SelfOutline) && hasOutline()
      && style().usedVisibility() == .Visible
    {
      // Don't paint focus ring for anonymous block continuation because the
      // inline element having outline-style:auto paints the whole focus ring.
      let hasOutlineStyleAuto = style().outlineStyleIsAuto() == .On
      if !hasOutlineStyleAuto || !isContinuation() {
        paintOutline(
          paintInfo: paintInfo, paintRect: LayoutRectWrapper(location: paintOffset, size: size()))
      }
    }

    // 6. paint continuation outlines.
    if paintPhase == .Outline || paintPhase == .ChildOutlines {
      if let inlineCont = inlineContinuation(), inlineCont.hasOutline(),
        inlineCont.style().usedVisibility() == .Visible
      {
        let inlineRenderer = inlineCont.element()!.renderer() as! RenderInlineWrapper?
        let containingBlock = self.containingBlock()

        var inlineEnclosedInSelfPaintingLayer = false
        var box: RenderBoxModelObjectWrapper? = inlineRenderer
        while CPtrToInt(box?.p) != CPtrToInt(containingBlock?.p) {
          if box!.hasSelfPaintingLayer() {
            inlineEnclosedInSelfPaintingLayer = true
            break
          }
          box = box!.parent()!.enclosingBoxModelObject()
        }

        // Do not add continuations for outline painting by our containing block if we are a relative positioned
        // anonymous block (i.e. have our own layer), paint them straightaway instead. This is because a block depends on renderers in its continuation table being
        // in the same layer.
        if !inlineEnclosedInSelfPaintingLayer && !hasLayer() {
          containingBlock!.addContinuationWithOutline(flow: inlineRenderer!)
        } else if !InlineIterator.firstInlineBoxFor(renderInline: inlineRenderer!).bool()
          || (!inlineEnclosedInSelfPaintingLayer && hasLayer())
        {
          inlineRenderer!.paintOutline(
            paintInfo: paintInfo,
            paintOffset: paintOffset - locationOffset()
              + inlineRenderer!.containingBlock()!.location())
        }
      }
      paintContinuationOutlines(info: paintInfo, paintOffset: paintOffset)
    }

    // 7. paint caret.
    // If the caret's node's render object's containing block is this block, and the paint action is PaintPhase::Foreground,
    // then paint the caret.
    paintCarets(paintInfo: paintInfo, paintOffset: paintOffset)
  }

  func paintChildren(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
    paintInfoForChild: inout PaintInfoWrapper, usePrintRect: Bool
  ) {
    var child = firstChildBox()
    while child != nil {
      if !paintChild(
        child: child!, paintInfo: paintInfo, paintOffset: paintOffset,
        paintInfoForChild: &paintInfoForChild, usePrintRect: usePrintRect)
      {
        return
      }
      child = child!.nextSiblingBox()
    }
  }

  enum PaintBlockType {
    case PaintAsBlock
    case PaintAsInlineBlock
  }

  func paintChild(
    child: RenderBoxWrapper, paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
    paintInfoForChild: inout PaintInfoWrapper, usePrintRect: Bool,
    paintType: PaintBlockType = .PaintAsBlock
  ) -> Bool {
    if child.isExcludedAndPlacedInBorder() {
      return true
    }

    // Check for page-break-before: always, and if it's set, break and bail.
    let checkBeforeAlways =
      !childrenInline() && (usePrintRect && alwaysPageBreak(between: child.style().breakBefore()))
    let absoluteChildY = paintOffset.y + child.y()
    if checkBeforeAlways
      && absoluteChildY > paintInfo.rect.y()
      && absoluteChildY < paintInfo.rect.maxY()
    {
      view().setBestTruncatedAt(y: absoluteChildY.int(), forRenderer: self, forcedBreak: true)
      return false
    }

    if !child.isFloating() && child.isReplacedOrInlineBlock() && usePrintRect
      && child.height() <= LayoutUnit(value: view().printRect().height())
    {
      // Paginate block-level replaced elements.
      if absoluteChildY + child.height() > Int(view().printRect().maxY()) {
        if absoluteChildY < LayoutUnit(value: view().truncatedAt()) {
          view().setBestTruncatedAt(y: absoluteChildY.int(), forRenderer: child)
        }
        // If we were able to truncate, don't paint.
        if absoluteChildY >= LayoutUnit(value: view().truncatedAt()) {
          return false
        }
      }
    }

    let childPoint = flipForWritingModeForChild(child: child, point: paintOffset)
    if !child.hasSelfPaintingLayer() && !child.isFloating() {
      if paintType == .PaintAsInlineBlock {
        child.paintAsInlineBlock(paintInfo: paintInfoForChild, childPoint: childPoint)
      } else {
        child.paint(paintInfo: &paintInfoForChild, paintOffset: childPoint)
      }
    }

    // Check for page-break-after: always, and if it's set, break and bail.
    let checkAfterAlways =
      !childrenInline() && (usePrintRect && alwaysPageBreak(between: child.style().breakAfter()))
    if checkAfterAlways
      && (absoluteChildY + child.height()) > paintInfo.rect.y()
      && (absoluteChildY + child.height()) < paintInfo.rect.maxY()
    {
      view().setBestTruncatedAt(
        y: (absoluteChildY + child.height()
          + max(LayoutUnit(value: 0), child.collapsedMarginAfter())).int(),
        forRenderer: self, forcedBreak: true)
      return false
    }

    return true
  }

  enum FieldsetFindLegendOption {
    case FieldsetIgnoreFloatingOrOutOfFlow
    case FieldsetIncludeFloatingOrOutOfFlow
  }

  func findFieldsetLegend(option: FieldsetFindLegendOption = .FieldsetIgnoreFloatingOrOutOfFlow)
    -> RenderBoxWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func adjustBorderBoxRectForPainting(paintRect: inout LayoutRectWrapper) {
    if !isFieldset() || isSkippedContentRoot() || !intrinsicBorderForFieldset().bool() {
      return
    }

    let legend = findFieldsetLegend()
    if legend == nil {
      return
    }

    if style().isHorizontalWritingMode() {
      let yOff = max(LayoutUnit(value: UInt64(0)), (legend!.height() - super.borderBefore()) / 2)
      paintRect.setHeight(height: paintRect.height() - yOff)
      if style().blockFlowDirection() == .TopToBottom {
        paintRect.setY(y: paintRect.y() + yOff)
      }
    } else {
      let xOff = max(LayoutUnit(value: UInt64(0)), (legend!.width() - super.borderBefore()) / 2)
      paintRect.setWidth(width: paintRect.width() - xOff)
      if style().blockFlowDirection() == .LeftToRight {
        paintRect.setX(x: paintRect.x() + xOff)
      }
    }
  }

  override func isInlineBlockOrInlineTable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func createAnonymousBlockWithStyleAndDisplay(
    document: Document, style: RenderStyleWrapper, display: DisplayType
  ) -> RenderBlockWrapper? {
    // FIXME: Do we need to convert all our inline displays to block-type in the anonymous logic ?
    var newBox: RenderBlockWrapper? = nil
    if display == .Flex || display == .InlineFlex {
      newBox = CreateRenderer.RenderFlexibleBox(
        type: .FlexibleBox, document: document,
        style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: style, display: .Flex))
    } else {
      newBox = CreateRenderer.RenderBlockFlow(
        type: .BlockFlow, document: document,
        style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: style, display: .Block))
    }

    newBox!.initializeStyle()
    return newBox
  }

  // FIXME-BLOCKFLOW: Remove virtualizaion when all callers have moved to RenderBlockFlow
  func paintFloats(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, preservePhase: Bool = false
  ) {}

  func paintInlineChildren(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {}

  private func paintContents(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if isSkippedContentRoot() {
      return
    }

    if childrenInline() {
      paintInlineChildren(paintInfo: paintInfo, paintOffset: paintOffset)
    } else {
      var newPhase = (paintInfo.phase == .ChildOutlines) ? .Outline : paintInfo.phase
      newPhase = (newPhase == .ChildBlockBackgrounds) ? .ChildBlockBackground : newPhase

      // We don't paint our own background, but we do let the kids paint their backgrounds.
      var paintInfoForChild = paintInfo
      paintInfoForChild.phase = newPhase
      paintInfoForChild.updateSubtreePaintRootForChildren(renderer: self)

      if paintInfo.eventRegionContext() != nil {
        paintInfoForChild.paintBehavior.update(with: .EventRegionIncludeBackground)
      }

      // FIXME: Paint-time pagination is obsolete and is now only used by embedded WebViews inside AppKit
      // NSViews. Do not add any more code for this.
      let usePrintRect = !view().printRect().isEmpty()
      paintChildren(
        paintInfo: paintInfo, paintOffset: paintOffset, paintInfoForChild: &paintInfoForChild,
        usePrintRect: usePrintRect)
    }
  }

  func paintColumnRules(paintInfo: PaintInfoWrapper, point: LayoutPointWrapper) {}

  private func paintSelection(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintCaret(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, type: CaretType
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintCarets(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.phase == .Foreground {
      paintCaret(paintInfo: paintInfo, paintOffset: paintOffset, type: .CursorCaret)
      paintCaret(paintInfo: paintInfo, paintOffset: paintOffset, type: .DragCaret)
    }
  }

  private func paintContinuationOutlines(info: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintDebugBoxShadowIfApplicable(
    context: GraphicsContextWrapper, paintRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func offsetFromLogicalTopOfFirstPage() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var floatingObjectSet: FloatingObjectSet? = nil
}
