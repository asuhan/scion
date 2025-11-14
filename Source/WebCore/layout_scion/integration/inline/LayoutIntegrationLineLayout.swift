/*
 * Copyright (C) 2020 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

class LayoutIntegration {
  static func flipMarginsIfApplicable(
    isHorizontalWritingMode: Bool, isLeftToRightDirection: Bool, isFlippedBlocksWritingMode: Bool,
    horizontalMargin: inout BoxGeometry.HorizontalEdges,
    verticalMargin: inout BoxGeometry.VerticalEdges
  ) {
    if isHorizontalWritingMode && isLeftToRightDirection && !isFlippedBlocksWritingMode {
      return
    }

    if !isHorizontalWritingMode {
      let logicalHorizontalMargin = horizontalMargin
      horizontalMargin =
        !isFlippedBlocksWritingMode
        ? BoxGeometry.HorizontalEdges(start: verticalMargin.after, end: verticalMargin.before)
        : BoxGeometry.HorizontalEdges(start: verticalMargin.before, end: verticalMargin.after)
      verticalMargin = BoxGeometry.VerticalEdges(
        before: logicalHorizontalMargin.start, after: logicalHorizontalMargin.end)
    }
    if !isLeftToRightDirection {
      if isHorizontalWritingMode {
        horizontalMargin = BoxGeometry.HorizontalEdges(
          start: horizontalMargin.end, end: horizontalMargin.start)
      } else {
        verticalMargin = BoxGeometry.VerticalEdges(
          before: verticalMargin.after, after: verticalMargin.before)
      }
    }
  }

  static func toMarginAndBorderBoxVisualRect(
    logicalGeometry: BoxGeometry, containerLogicalWidth: LayoutUnit, writingMode: WritingMode,
    isLeftToRightDirection: Bool
  ) -> (LayoutRectWrapper, LayoutRectWrapper) {
    let isFlippedBlocksWritingMode = isFlippedWritingMode(writingMode: writingMode)
    let isHorizontalWritingMode = isHorizontalWritingMode(writingMode: writingMode)

    let borderBoxLogicalRect = BoxGeometry.borderBoxRect(box: logicalGeometry)
    var horizontalMargin = BoxGeometry.HorizontalEdges(
      start: logicalGeometry.marginStart(), end: logicalGeometry.marginEnd())
    var verticalMargin = BoxGeometry.VerticalEdges(
      before: logicalGeometry.marginBefore(), after: logicalGeometry.marginAfter())

    flipMarginsIfApplicable(
      isHorizontalWritingMode: isHorizontalWritingMode,
      isLeftToRightDirection: isLeftToRightDirection,
      isFlippedBlocksWritingMode: isFlippedBlocksWritingMode, horizontalMargin: &horizontalMargin,
      verticalMargin: &verticalMargin)

    var borderBoxVisualTopLeft = LayoutPointWrapper()
    let borderBoxLeft =
      isLeftToRightDirection
      ? borderBoxLogicalRect.left()
      : containerLogicalWidth - (borderBoxLogicalRect.left() + borderBoxLogicalRect.width())
    if isHorizontalWritingMode {
      borderBoxVisualTopLeft = LayoutPointWrapper(x: borderBoxLeft, y: borderBoxLogicalRect.top())
    } else {
      let marginBoxVisualLeft = borderBoxLogicalRect.top() - logicalGeometry.marginBefore()
      let marginBoxVisualTop = borderBoxLeft - logicalGeometry.marginStart()
      if isLeftToRightDirection {
        borderBoxVisualTopLeft = LayoutPointWrapper(
          x: marginBoxVisualLeft + horizontalMargin.start,
          y: marginBoxVisualTop + verticalMargin.before)
      } else {
        borderBoxVisualTopLeft = LayoutPointWrapper(
          x: marginBoxVisualLeft + horizontalMargin.start,
          y: marginBoxVisualTop + verticalMargin.after)
      }
    }

    let borderBoxVisualRect = LayoutRectWrapper(
      location: borderBoxVisualTopLeft,
      size: isHorizontalWritingMode
        ? borderBoxLogicalRect.size() : borderBoxLogicalRect.size().transposedSize())
    var marginBoxVisualRect = borderBoxVisualRect

    marginBoxVisualRect.move(dx: -horizontalMargin.start, dy: -verticalMargin.before)
    marginBoxVisualRect.expand(
      dw: horizontalMargin.start + horizontalMargin.end,
      dh: verticalMargin.before + verticalMargin.after)
    return (marginBoxVisualRect, borderBoxVisualRect)
  }

  static func lastLineWithInlineContent(lines: InlineDisplay.Lines) -> InlineDisplay.Line {
    // Out-of-flow/float content only don't produce lines with inline content. They should not be taken into
    // account when computing content box height/baselines.
    for line in lines.reversed() {
      assert(line.boxCount() != 0)
      if line.boxCount() > 1 {
        return line
      }
    }
    return lines.first!
  }

  static func isContentRenderer(renderer: RenderObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func lineClamp(rootRenderer: RenderBlockFlowWrapper) -> BlockLayoutState.LineClamp? {
    let layoutState = rootRenderer.view().frameView().layoutContext().layoutState()!
    if let legacyLineClamp = layoutState.legacyLineClamp() {
      return BlockLayoutState.LineClamp(
        maximumLines: max(legacyLineClamp.maximumLineCount - legacyLineClamp.currentLineCount, 0),
        shouldDiscardOverflow: false, isLegacy: true)
    }
    if let lineClamp = layoutState.lineClamp() {
      return BlockLayoutState.LineClamp(
        maximumLines: lineClamp.maximumLines,
        shouldDiscardOverflow: lineClamp.shouldDiscardOverflow, isLegacy: false)
    }
    return nil
  }

  static func textBoxTrim(rootRenderer: RenderBlockFlowWrapper) -> BlockLayoutState.TextBoxTrim {
    if let layoutState = rootRenderer.view().frameView().layoutContext().layoutState() {
      var textBoxTrimForIFC = BlockLayoutState.TextBoxTrim()
      let isFlippedLinesWritingMode = rootRenderer.style().isFlippedLinesWritingMode()
      if layoutState.hasTextBoxTrimStart() {
        textBoxTrimForIFC.update(with: isFlippedLinesWritingMode ? .End : .Start)
      }
      if layoutState.hasTextBoxTrimEnd(candidate: rootRenderer) {
        textBoxTrimForIFC.update(with: isFlippedLinesWritingMode ? .Start : .End)
      }
      return textBoxTrimForIFC
    }
    return BlockLayoutState.TextBoxTrim()
  }

  static func textBoxEdge(rootRenderer: RenderBlockFlowWrapper) -> TextEdge {
    if let layoutState = rootRenderer.view().frameView().layoutContext().layoutState() {
      if let textBoxTrim = layoutState.textBoxTrim() {
        return textBoxTrim.propagatedTextBoxEdge
      }
    }
    return TextEdge()
  }

  static func lineGrid(rootRenderer: RenderBlockFlowWrapper) -> BlockLayoutState.LineGrid? {
    let layoutState = rootRenderer.view().frameView().layoutContext().layoutState()!
    if layoutState.lineGrid() != nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    return nil
  }

  static func flippedContentOffsetIfNeeded(
    root: RenderBlockFlowWrapper, childRenderer: RenderBoxWrapper, contentOffset: LayoutPointWrapper
  ) -> LayoutPointWrapper {
    if root.style().isFlippedBlocksWritingMode() {
      return root.flipForWritingModeForChild(child: childRenderer, point: contentOffset)
    }
    return contentOffset
  }

  static func flippedRectForWritingMode(root: RenderBlockFlowWrapper, rect: FloatRectWrapper)
    -> LayoutRectWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  class LineLayout {
    init(flow: RenderBlockFlowWrapper) {
      self.boxTree = BoxTree(rootRenderer: flow)
      self.layoutState = flow.view().layoutState()
      let formattingContextRoot = LineLayout.rootLayoutBox(boxTree: self.boxTree)
      self.blockFormattingState = self.layoutState!.ensureBlockFormattingStateWrapper(
        formattingContextRoot: formattingContextRoot)
      self.inlineContentCache = self.layoutState!.inlineContentCache(
        formattingContextRoot: formattingContextRoot)
      self.boxGeometryUpdater = BoxGeometryUpdater(
        layoutState: flow.view().layoutState(), rootLayoutBox: boxTree.rootLayoutBox())
    }

    enum TypeOfChangeForInvalidation: UInt8 {
      case NodeInsertion
      case NodeRemoval
      case NodeMutation
    }

    static func shouldInvalidateLineLayoutPathAfterChangeFor(
      rootBlockContainer: RenderBlockFlowWrapper, renderer: RenderObjectWrapper,
      lineLayout: LineLayout, typeOfChange: TypeOfChangeForInvalidation
    ) -> Bool {
      if !isSupportedRendererWithChange(renderer: renderer, typeOfChange: typeOfChange) {
        return true
      }

      if !isSupportedParent(renderer: renderer) {
        return true
      }
      if rootBlockContainer.containsFloats() {
        return true
      }

      if isBidiContent(renderer: renderer, lineLayout: lineLayout) {
        // FIXME: InlineItemsBuilder needs some work to support paragraph level bidi handling.
        return true
      }

      if hasFirstLetter(rootBlockContainer: rootBlockContainer) {
        return true
      }

      if let previousDamage = lineLayout.damage() {
        if previousDamage.reasons() != .Append || previousDamage.layoutStartPosition() == nil {
          // Only support subsequent append operations where we managed to invalidate the content for partial layout.
          return true
        }
      }

      let shouldBalance =
        rootBlockContainer.style().textWrapMode() == .Wrap
        && rootBlockContainer.style().textWrapStyle() == .Balance
      let shouldPrettify =
        rootBlockContainer.style().textWrapMode() == .Wrap
        && rootBlockContainer.style().textWrapStyle() == .Pretty
      if rootBlockContainer.style().direction() == .RTL || shouldBalance || shouldPrettify {
        return true
      }

      switch typeOfChange {
      case .NodeRemoval:
        return (renderer.previousSibling() == nil && renderer.nextSibling() == nil)
          || rootHasNonSupportedRenderer(rootBlockContainer: rootBlockContainer)
      case .NodeInsertion:
        return rootHasNonSupportedRenderer(
          rootBlockContainer: rootBlockContainer,
          shouldOnlyCheckForRelativeDimension: renderer.nextSibling() == nil)
      case .NodeMutation:
        return rootHasNonSupportedRenderer(rootBlockContainer: rootBlockContainer)
      }
    }

    static func rootHasNonSupportedRenderer(
      rootBlockContainer: RenderBlockFlowWrapper, shouldOnlyCheckForRelativeDimension: Bool = false
    ) -> Bool {
      var sibling = rootBlockContainer.firstChild()
      while sibling != nil {
        var siblingHasRelativeDimensions = false
        if let renderBox = sibling as? RenderBoxWrapper {
          siblingHasRelativeDimensions = renderBox.hasRelativeDimensions()
        }

        if shouldOnlyCheckForRelativeDimension && !siblingHasRelativeDimensions {
          continue
        }

        if siblingHasRelativeDimensions
          || (sibling as? RenderTextWrapper == nil && sibling as? RenderLineBreakWrapper == nil
            && sibling as? RenderReplacedWrapper == nil)
        {
          return true
        }

        sibling = sibling!.nextSibling()
      }
      return !canUseForLineLayout(rootContainer: rootBlockContainer)
    }

    static func hasFirstLetter(rootBlockContainer: RenderBlockFlowWrapper) -> Bool {
      // FIXME: RenderTreeUpdater::updateTextRenderer produces odd values for offset/length when first-letter is present webkit.org/b/263343
      if rootBlockContainer.style().hasPseudoStyle(pseudo: .FirstLetter) {
        return true
      }
      if rootBlockContainer.isAnonymous() {
        return rootBlockContainer.containingBlock() != nil
          && rootBlockContainer.containingBlock()!.style().hasPseudoStyle(pseudo: .FirstLetter)
      }
      return false
    }

    static func isBidiContent(renderer: RenderObjectWrapper, lineLayout: LineLayout) -> Bool {
      if lineLayout.contentNeedsVisualReordering() {
        return true
      }
      if let textRenderer = renderer as? RenderTextWrapper {
        var hasStrongDirectionalityContent = textRenderer.hasStrongDirectionalityContent()
        if hasStrongDirectionalityContent == nil {
          hasStrongDirectionalityContent = TextUtil.containsStrongDirectionalityText(
            text: StringWrapperView(s: textRenderer.text()))
          textRenderer.setHasStrongDirectionalityContent(
            hasStrongDirectionalityContent: hasStrongDirectionalityContent!)
        }
        return hasStrongDirectionalityContent!
      }
      if renderer as? RenderInlineWrapper != nil {
        let style = renderer.style()
        return !style.isLeftToRightDirection()
          || (style.rtlOrdering() == .Logical && style.unicodeBidi() != .Normal)
      }
      return false
    }

    static func isSupportedParent(renderer: RenderObjectWrapper) -> Bool {
      if let parent = renderer.parent() {
        // Content append under existing inline box is not yet supported.
        if parent as? RenderBlockFlowWrapper != nil {
          return true
        }
        if (parent as? RenderInlineWrapper != nil) && !parent.everHadLayout() {
          return true
        }
      }
      return false
    }

    static func isSupportedRendererWithChange(
      renderer: RenderObjectWrapper, typeOfChange: TypeOfChangeForInvalidation
    ) -> Bool {
      if renderer as? RenderTextWrapper != nil {
        return true
      }
      if !renderer.isInFlow() {
        return false
      }
      if renderer as? RenderLineBreakWrapper != nil {
        return true
      }
      if let renderBox = renderer as? RenderBoxWrapper {
        if renderBox.hasRelativeDimensions() {
          return false
        }
      }
      if renderer as? RenderReplacedWrapper != nil {
        return typeOfChange == .NodeInsertion
      }
      if let inlineRenderer = renderer as? RenderInlineWrapper {
        return typeOfChange == .NodeInsertion && inlineRenderer.firstChild() != nil
      }
      return false
    }

    static func blockContainer(renderer: RenderObjectWrapper) -> RenderBlockFlowWrapper? {
      if !LayoutIntegration.isContentRenderer(renderer: renderer) {
        return nil
      }

      var parent = renderer.parent()
      while parent != nil {
        if !parent!.childrenInline() {
          return nil
        }
        if let renderBlockFlow = parent as? RenderBlockFlowWrapper {
          return renderBlockFlow
        }
        parent = parent!.parent()
      }

      return nil
    }

    static func containing(renderer: RenderObjectWrapper) -> LineLayout? {
      if !LayoutIntegration.isContentRenderer(renderer: renderer) {
        return nil
      }

      if !renderer.isInline() {
        // IFC may contain block level boxes (floats and out-of-flow boxes).
        if renderer.isRenderSVGBlock() {
          // SVG content inside svg root shows up as block (see RenderSVGBlock). We only support inline root svg as "atomic content".
          return nil
        }
        if renderer.isRenderFrameSet() {
          // Since RenderFrameSet is not a RenderBlock, finding container for nested framesets can't use containingBlock ancestor walk.
          if let parent = renderer.parent() as? RenderBlockFlowWrapper {
            return parent.inlineLayout()
          }
          return nil
        }
        if let blockContainer = adjustedContainingBlock(renderer: renderer) {
          return blockContainer.inlineLayout()
        }
        return nil
      }

      if let container = blockContainer(renderer: renderer) {
        return container.inlineLayout()
      }

      return nil
    }

    static func adjustedContainingBlock(renderer: RenderObjectWrapper) -> RenderBlockFlowWrapper? {
      var containingBlock: RenderElementWrapper? = nil
      // Only out of flow and floating block level boxes may participate in IFC.
      if renderer.isOutOfFlowPositioned() {
        // Here we are looking for the containing block as if the out-of-flow box was inflow (for static position purpose).
        containingBlock = renderer.parent()
        if (containingBlock as? RenderInlineWrapper) != nil {
          containingBlock = containingBlock!.containingBlock()
        }
      } else if renderer.isFloating() {
        // Note that containigBlock() on boxes in top layer (i.e. dialog) may return incorrect result during style change even with not-yet-updated style.
        containingBlock = RenderObjectWrapper.containingBlockForPositionType(
          positionType: renderer.style().position(), renderer: renderer)
      }
      return containingBlock as? RenderBlockFlowWrapper
    }

    static func canUseForPreferredWidthComputation(flow: RenderBlockFlowWrapper) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    static func shouldInvalidateLineLayoutPathAfterContentChange(
      parent: RenderBlockFlowWrapper, rendererWithNewContent: RenderObjectWrapper,
      lineLayout: LineLayout
    ) -> Bool {
      return shouldInvalidateLineLayoutPathAfterChangeFor(
        rootBlockContainer: parent, renderer: rendererWithNewContent,
        lineLayout: lineLayout,
        typeOfChange: .NodeMutation)
    }

    static func shouldInvalidateLineLayoutPathAfterTreeMutation(
      parent: RenderBlockFlowWrapper, renderer: RenderObjectWrapper, lineLayout: LineLayout,
      isRemoval: Bool
    ) -> Bool {
      return shouldInvalidateLineLayoutPathAfterChangeFor(
        rootBlockContainer: parent, renderer: renderer, lineLayout: lineLayout,
        typeOfChange: isRemoval ? .NodeRemoval : .NodeInsertion)
    }

    func updateFormattingContexGeometries(availableLogicalWidth: LayoutUnit) {
      boxGeometryUpdater.setFormattingContextRootGeometry(availableWidth: availableLogicalWidth)
      inlineContentConstraints = boxGeometryUpdater.formattingContextConstraints(
        availableWidth: availableLogicalWidth)
      boxGeometryUpdater.setFormattingContextContentGeometry(
        availableLogicalWidth: inlineContentConstraints!.horizontal.logicalWidth,
        intrinsicWidthMode: nil)
    }

    // Partial invalidation.
    func insertedIntoTree(parent: RenderElementWrapper, child: RenderObjectWrapper) -> Bool {
      if inlineContent == nil {
        // This should only be called on partial layout.
        fatalError("Not reached")
      }

      let childLayoutBox = boxTree.insert(
        parent: parent, child: child, beforeChild: child.previousSibling())
      if let childInlineTextBox = childLayoutBox as? InlineTextBoxWrapper {
        let invalidation = InlineInvalidation(
          inlineDamage: ensureLineDamage(),
          inlineItemList: inlineContentCache!.inlineItems.content(),
          displayContent: inlineContent!.displayContent)
        return invalidation.textInserted(newOrDamagedInlineTextBox: childInlineTextBox)
      }

      if childLayoutBox.isLineBreakBox() || childLayoutBox.isReplacedBox()
        || childLayoutBox.isInlineBox()
      {
        let invalidation = InlineInvalidation(
          inlineDamage: ensureLineDamage(),
          inlineItemList: inlineContentCache!.inlineItems.content(),
          displayContent: inlineContent!.displayContent)
        return invalidation.inlineLevelBoxInserted(layoutBox: childLayoutBox)
      }

      fatalError("Not implemented yet")
    }

    func removedFromTree(parent: RenderElementWrapper, child: RenderObjectWrapper) -> Bool {
      if inlineContent == nil {
        // This should only be called on partial layout.
        fatalError("Not reached")
      }

      let childLayoutBox = child.layoutBox()!
      let childInlineTextBox = childLayoutBox as? InlineTextBoxWrapper
      let invalidation = InlineInvalidation(
        inlineDamage: ensureLineDamage(),
        inlineItemList: inlineContentCache!.inlineItems.content(),
        displayContent: inlineContent!.displayContent)
      let boxIsInvalidated =
        childInlineTextBox != nil
        ? invalidation.textWillBeRemoved(damagedInlineTextBox: childInlineTextBox!)
        : childLayoutBox.isLineBreakBox()
          ? invalidation.inlineLevelBoxWillBeRemoved(layoutBox: childLayoutBox) : false
      if boxIsInvalidated {
        lineDamage!.addDetachedBox(layoutBox: boxTree.remove(parent: parent, child: child))
      }
      return boxIsInvalidated
    }

    func updateTextContent(textRenderer: RenderTextWrapper, offset: UInt64, delta: Int) -> Bool {
      if inlineContent == nil {
        // This is supposed to be only called on partial layout, but
        // RenderText::setText may be (force) called after min/max size computation and before layout.
        // We may need to invalidate anyway to clean up inline item list.
        return false
      }

      boxTree.updateContent(textRenderer: textRenderer)
      let invalidation = InlineInvalidation(
        inlineDamage: ensureLineDamage(),
        inlineItemList: inlineContentCache!.inlineItems.content(),
        displayContent: inlineContent!.displayContent)
      let inlineTextBox: InlineTextBoxWrapper = textRenderer.layoutBox()!
      return delta >= 0
        ? invalidation.textInserted(newOrDamagedInlineTextBox: inlineTextBox, offset: offset)
        : invalidation.textWillBeRemoved(damagedInlineTextBox: inlineTextBox, offset: offset)
    }

    func rootStyleWillChange(root: RenderBlockFlowWrapper, newStyle: RenderStyleWrapper) -> Bool {
      if root.layoutBox() == nil || !root.layoutBox()!.isElementBox() {
        fatalError("Not reached")
      }
      if inlineContent == nil {
        return false
      }

      return InlineInvalidation(
        inlineDamage: ensureLineDamage(),
        inlineItemList: inlineContentCache!.inlineItems.content(),
        displayContent: inlineContent!.displayContent
      ).rootStyleWillChange(
        formattingContextRoot: root.layoutBox()!, newStyle: newStyle)
    }

    func styleWillChange(
      renderer: RenderElementWrapper, newStyle: RenderStyleWrapper, diff: StyleDifference
    ) -> Bool {
      if renderer.layoutBox() == nil {
        fatalError("Not reached")
      }
      if inlineContent == nil {
        return false
      }

      return InlineInvalidation(
        inlineDamage: ensureLineDamage(),
        inlineItemList: inlineContentCache!.inlineItems.content(),
        displayContent: inlineContent!.displayContent
      ).styleWillChange(layoutBox: renderer.layoutBox()!, newStyle: newStyle, diff: diff)
    }

    @discardableResult
    func boxContentWillChange(renderer: RenderBoxWrapper) -> Bool {
      if inlineContent == nil || renderer.layoutBox() == nil {
        return false
      }

      return InlineInvalidation(
        inlineDamage: ensureLineDamage(),
        inlineItemList: inlineContentCache!.inlineItems.content(),
        displayContent: inlineContent!.displayContent
      ).inlineLevelBoxContentWillChange(layoutBox: renderer.layoutBox()!)
    }

    func computeIntrinsicWidthConstraints() -> (LayoutUnit, LayoutUnit) {
      let parentBlockLayoutState = BlockLayoutState(
        placedFloats: blockFormattingState.placedFloats!)
      let inlineFormattingContext = InlineFormattingContext(
        rootBlockContainer: rootLayoutBox(), globalLayoutState: layoutState!,
        parentBlockLayoutState: parentBlockLayoutState)
      if lineDamage != nil {
        inlineContentCache!.resetMinimumMaximumContentSizes()
      }
      // FIXME: This is where we need to switch between minimum and maximum box geometries.
      // Currently we only support content where min == max.
      boxGeometryUpdater.setFormattingContextContentGeometry(
        availableLogicalWidth: nil, intrinsicWidthMode: .Minimum)
      return inlineFormattingContext.minimumMaximumContentSize(lineDamage: lineDamage)
    }

    @discardableResult
    func layout() -> LayoutRectWrapper? {
      preparePlacedFloats()

      let isPartialLayout = InlineInvalidation.mayOnlyNeedPartialLayout(inlineDamage: lineDamage)
      if !isPartialLayout {
        // FIXME: Partial layout should not rely on previous inline display content.
        clearInlineContent()
      }

      assert(inlineContentConstraints != nil)

      let parentBlockLayoutState = BlockLayoutState(
        placedFloats: blockFormattingState.placedFloats!,
        lineClamp: lineClamp(rootRenderer: flow()),
        textBoxTrim: textBoxTrim(rootRenderer: flow()),
        textBoxEdge: textBoxEdge(rootRenderer: flow()),
        intrusiveInitialLetterLogicalBottom: intrusiveInitialLetterBottom(),
        lineGrid: lineGrid(rootRenderer: flow())
      )
      let inlineFormattingContext = InlineFormattingContext(
        rootBlockContainer: rootLayoutBox(), globalLayoutState: layoutState!,
        parentBlockLayoutState: parentBlockLayoutState)
      // Temporary, integration only.
      inlineFormattingContext.layoutState().setNestedListMarkerOffsets(
        nestedListMarkerOffsets: boxGeometryUpdater.takeNestedListMarkerOffsets())

      let layoutResult = inlineFormattingContext.layout(
        constraints: inlineContentConstraints(isPartialLayout: isPartialLayout),
        lineDamage: &lineDamage)
      let repaintRect = LayoutRectWrapper(
        r: constructContent(
          inlineLayoutState: inlineFormattingContext.layoutState(), layoutResult: layoutResult
        ))

      lineDamage = nil

      let adjustments = adjustContentForPagination(
        blockLayoutState: parentBlockLayoutState, isPartialLayout: isPartialLayout)

      updateRenderTreePositions(
        lineAdjustments: adjustments, inlineLayoutState: inlineFormattingContext.layoutState())

      if lineDamage != nil {
        // Pagination may require another layout pass.
        layout()

        assert(lineDamage == nil)
      }

      return isPartialLayout ? repaintRect : nil
    }

    func intrusiveInitialLetterBottom() -> LayoutUnit? {
      if let lowestInitialLetterLogicalBottom = flow().lowestInitialLetterLogicalBottom() {
        return lowestInitialLetterLogicalBottom - inlineContentConstraints!.logicalTop
      }
      return nil
    }

    func inlineContentConstraints(isPartialLayout: Bool) -> ConstraintsForInlineContent {
      if !isPartialLayout || inlineContent == nil {
        return inlineContentConstraints!
      }
      let damagedLineIndex = lineDamage!.layoutStartPosition()!.lineIndex
      if damagedLineIndex == 0 {
        return inlineContentConstraints!
      }
      if damagedLineIndex >= inlineContent!.displayContent.lines.count {
        fatalError("Not reached")
      }
      let constraintsForInFlowContent = ConstraintsForInFlowContent(
        horizontal: inlineContentConstraints!.horizontal,
        logicalTop: lineDamage!.layoutStartPosition()!.partialContentTop)
      return ConstraintsForInlineContent(
        genericContraints: constraintsForInFlowContent,
        visualLeft: inlineContentConstraints!.visualLeft)
    }

    static func shouldPaintForPhase(paintInfo: PaintInfoWrapper) -> Bool {
      switch paintInfo.phase {
      case .Accessibility, .Foreground, .EventRegion, .TextClip, .Mask, .Selection, .Outline,
        .ChildOutlines, .SelfOutline:
        return true
      default:
        return false
      }
    }

    func paint(
      paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
      layerRenderer: RenderInlineWrapper? = nil
    ) {
      if inlineContent == nil {
        return
      }

      if !LineLayout.shouldPaintForPhase(paintInfo: paintInfo) {
        return
      }

      var painter = InlineContentPainter(
        paintInfo: paintInfo, paintOffset: paintOffset, inlineBoxWithLayer: layerRenderer,
        inlineContent: inlineContent!, boxTree: boxTree)
      painter.paint()
    }

    func hitTest(
      request: HitTestRequestWrapper, result: HitTestResultWrapper,
      locationInContainer: HitTestLocationWrapper, accumulatedOffset: LayoutPointWrapper,
      hitTestAction: HitTestAction, layerRenderer: RenderInlineWrapper
    ) -> Bool {
      if hitTestAction != .HitTestForeground {
        return false
      }

      if inlineContent == nil {
        return false
      }

      var hitTestBoundingBox = locationInContainer.boundingBox()
      hitTestBoundingBox.moveBy(offset: -accumulatedOffset)
      let boxRange = inlineContent!.boxesForRect(rect: hitTestBoundingBox)

      var layerPaintScope = LayerPaintScope(boxTree: boxTree, inlineBoxWithLayer: layerRenderer)

      for box in boxRange.reversed() {
        let visibleForHitTesting =
          request.userTriggered() ? box.isVisible() : box.isVisibleIgnoringUsedVisibility()
        if !visibleForHitTesting {
          continue
        }

        let renderer = box.layoutBox.rendererForIntegration()!

        if !layerPaintScope.includes(box: box) {
          continue
        }

        if box.isAtomicInlineBox() {
          if renderer.hitTest(
            request: request, result: result, locationInContainer: locationInContainer,
            accumulatedOffset: flippedContentOffsetIfNeeded(
              root: flow(), childRenderer: renderer as! RenderBoxWrapper,
              contentOffset: accumulatedOffset))
          {
            return true
          }
          continue
        }

        let currentLine = inlineContent!.displayContent.lines[Int(box.lineIndex)]
        var boxRect = flippedRectForWritingMode(
          root: flow(),
          rect: InlineDisplay.Box.visibleRectIgnoringBlockDirection(
            box: box, visibleLineRect: currentLine.visibleRectIgnoringBlockDirection()))
        boxRect.moveBy(offset: accumulatedOffset)

        if !locationInContainer.intersects(rect: boxRect) {
          continue
        }

        var elementRenderer = renderer as? RenderElementWrapper
        if elementRenderer == nil {
          elementRenderer = renderer.parent()
        }
        if !elementRenderer!.visibleToHitTesting(request: request) {
          continue
        }

        renderer.updateHitTestResult(
          result: result,
          point: flow().flipForWritingMode(
            position: locationInContainer.point() - toLayoutSize(point: accumulatedOffset)))
        if result.addNodeToListBasedTestResult(
          node: renderer.protectedNodeForHitTest(), request: request,
          locationInContainer: locationInContainer, rect: boxRect) == .Stop
        {
          return true
        }
      }

      return false
    }

    func shiftLinesBy(blockShift: LayoutUnit) {
      if inlineContent == nil {
        return
      }
      let isHorizontalWritingMode = isHorizontalWritingMode(
        writingMode: flow().style().writingMode())

      for line in inlineContent!.displayContent.lines {
        line.moveInBlockDirection(
          offset: blockShift.float(), isHorizontalWritingMode: isHorizontalWritingMode)
      }

      let deltaX = isHorizontalWritingMode ? LayoutUnit(value: 0) : blockShift
      let deltaY = isHorizontalWritingMode ? blockShift : LayoutUnit(value: 0)
      for box in inlineContent!.displayContent.boxes {
        if isHorizontalWritingMode {
          box.moveVertically(offset: blockShift.float())
        } else {
          box.moveHorizontally(offset: blockShift.float())
        }

        if box.isAtomicInlineBox() {
          let renderer = box.layoutBox.rendererForIntegration() as! RenderBoxWrapper
          renderer.move(dx: deltaX, dy: deltaY)
        }
      }

      for layoutBox in formattingContextBoxes(root: rootLayoutBox()) {
        if layoutBox.isOutOfFlowPositioned()
          && layoutBox.style.hasStaticBlockPosition(horizontal: isHorizontalWritingMode)
        {
          let renderer = layoutBox.rendererForIntegration()! as! RenderLayerModelObjectWrapper
          if let layer = renderer.layer() {
            layer.setStaticBlockPosition(position: layer.staticBlockPosition() + blockShift)
            renderer.setChildNeedsLayout(markParents: .MarkOnlyThis)
          }
        }
      }
    }

    func collectOverflow() {
      if inlineContent == nil {
        return
      }

      for line in inlineContent!.displayContent.lines {
        flow().addLayoutOverflow(rect: toLayoutRect(rect: line.scrollableOverflow))
        if !flow().hasNonVisibleOverflow() {
          flow().addVisualOverflow(rect: toLayoutRect(rect: line.inkOverflow))
        }
      }
    }

    func visualOverflowBoundingBoxRectFor(renderInline: RenderInlineWrapper) -> LayoutRectWrapper {
      if inlineContent == nil {
        return LayoutRectWrapper()
      }

      let layoutBox = renderInline.layoutBox()!

      var result = LayoutRectWrapper()
      inlineContent!.traverseNonRootInlineBoxes(
        layoutBox: layoutBox,
        function: {
          (inlineBox: InlineDisplay.Box) in
          result.unite(other: toLayoutRect(rect: inlineBox.inkOverflow))
        })

      return result
    }

    func collectInlineBoxRects(renderInline: RenderInlineWrapper) -> [FloatRectWrapper] {
      if inlineContent == nil {
        return []
      }

      let layoutBox = renderInline.layoutBox()!

      var result: [FloatRectWrapper] = []
      inlineContent!.traverseNonRootInlineBoxes(
        layoutBox: layoutBox,
        function: {
          (inlineBox: InlineDisplay.Box) in
          result.append(inlineBox.visualRectIgnoringBlockDirection())
        })

      return result
    }

    func clampedContentLogicalHeight() -> LayoutUnit? {
      if inlineContent == nil {
        return nil
      }

      let lines = inlineContent!.displayContent.lines
      if lines.isEmpty {
        // Out-of-flow only content (and/or with floats) may produce blank inline content.
        return nil
      }

      let firstTruncatedLineIndex = LineLayout.firstTruncatedLineIndex(lines: lines)
      if firstTruncatedLineIndex == nil {
        return nil
      }
      if firstTruncatedLineIndex! == 0 {
        // This content is fully truncated in the block direction.
        return LayoutUnit()
      }

      let contentHeight =
        lines[Int(firstTruncatedLineIndex! - 1)].lineBoxLogicalRect.maxY()
        - lines.first!.lineBoxLogicalRect.y()
      let additionalHeight =
        inlineContent!.firstLinePaginationOffset + inlineContent!.clearGapBeforeFirstLine
        + inlineContent!.clearGapAfterLastLine
      return LayoutUnit(value: contentHeight + additionalHeight)
    }

    func contains(renderer: RenderElementWrapper) -> Bool {
      if !boxTree.contains(rendererToFind: renderer) {
        return false
      }
      return layoutState!.hasBoxGeometry(layoutBox: renderer.layoutBox()!)
    }

    static func firstTruncatedLineIndex(lines: [InlineDisplay.Line]) -> UInt64? {
      for (lineIndex, line) in lines.enumerated() {
        if line.isFullyTruncatedInBlockDirection {
          return UInt64(lineIndex)
        }
      }
      return nil
    }

    func contentBoxLogicalHeight() -> LayoutUnit {
      if inlineContent == nil {
        return LayoutUnit()
      }

      let lines = inlineContent!.displayContent.lines
      if lines.isEmpty {
        // Out-of-flow only content (and/or with floats) may produce blank inline content.
        return LayoutUnit()
      }

      let contentHeight =
        lastLineWithInlineContent(lines: lines).lineBoxLogicalRect.maxY()
        - lines.first!.lineBoxLogicalRect.y()
      let additionalHeight =
        inlineContent!.firstLinePaginationOffset + inlineContent!.clearGapBeforeFirstLine
        + inlineContent!.clearGapAfterLastLine
      return LayoutUnit(value: contentHeight + additionalHeight)
    }

    func lineCount() -> UInt64 {
      if inlineContent == nil {
        return 0
      }
      if !inlineContent!.hasContent() {
        return 0
      }

      return UInt64(inlineContent!.displayContent.lines.count)
    }

    func firstLinePhysicalBaseline() -> LayoutUnit {
      if inlineContent == nil || inlineContent!.displayContent.boxes.isEmpty {
        fatalError("Not reached")
      }

      let firstLine = inlineContent!.displayContent.lines.first!
      return physicalBaselineForLine(line: firstLine)
    }

    func lastLinePhysicalBaseline() -> LayoutUnit {
      if inlineContent == nil || inlineContent!.displayContent.lines.isEmpty {
        fatalError("Not reached")
      }

      return physicalBaselineForLine(
        line: lastLineWithInlineContent(lines: inlineContent!.displayContent.lines))
    }

    func lastLineLogicalBaseline(line: InlineDisplay.Line) -> LayoutUnit {
      if inlineContent == nil || inlineContent!.displayContent.lines.isEmpty {
        fatalError("Not reached")
      }

      let lastLine = lastLineWithInlineContent(lines: inlineContent!.displayContent.lines)
      switch writingModeToBlockFlowDirection(writingMode: rootLayoutBox().style.writingMode()) {
      case .TopToBottom, .BottomToTop:
        return LayoutUnit(value: lastLine.lineBoxTop() + lastLine.baseline())
      case .LeftToRight:
        // FIXME: We should set the computed height on the root's box geometry (in RenderBlockFlow) so that
        // we could call m_layoutState.geometryForRootBox().borderBoxHeight() instead.

        // Line is always visual coordinates while logicalHeight is not (i.e. this translate to "box visual width" - "line visual right")
        let lineLogicalTop = flow().logicalHeight() - lastLine.lineBoxRight()
        return LayoutUnit(value: lineLogicalTop + lastLine.baseline())
      case .RightToLeft:
        return LayoutUnit(value: lastLine.lineBoxLeft() + lastLine.baseline())
      }
    }

    func firstInlineBoxRect(renderInline: RenderInlineWrapper) -> LayoutRectWrapper {
      if inlineContent == nil {
        return LayoutRectWrapper()
      }

      let layoutBox = renderInline.layoutBox()!
      let firstBox = inlineContent!.firstBoxForLayoutBox(layoutBox: layoutBox)
      if firstBox == nil {
        return LayoutRectWrapper()
      }

      // FIXME: We should be able to flip the display boxes soon after the root block
      // is finished sizing in one go.
      var firstBoxRect = toLayoutRect(rect: firstBox!.visualRectIgnoringBlockDirection())
      switch writingModeToBlockFlowDirection(writingMode: rootLayoutBox().style.writingMode()) {
      case .TopToBottom, .BottomToTop, .LeftToRight:
        return firstBoxRect
      case .RightToLeft:
        firstBoxRect.setX(x: flow().width() - firstBoxRect.maxX())
        return firstBoxRect
      }
    }

    func enclosingBorderBoxRectFor(renderInline: RenderInlineWrapper) -> LayoutRectWrapper {
      if inlineContent == nil {
        return LayoutRectWrapper()
      }

      // FIXME: This keeps the existing output.
      if !inlineContent!.hasContent() {
        return LayoutRectWrapper()
      }

      let borderBoxLogicalRect = BoxGeometry.borderBoxRect(
        box: layoutState!.geometryForBox(layoutBox: renderInline.layoutBox()!)
      ).LayoutRect()
      return isHorizontalWritingMode(writingMode: flow().style().writingMode())
        ? borderBoxLogicalRect : borderBoxLogicalRect.transposedRect()
    }

    func flow() -> RenderBlockFlowWrapper { return boxTree.rootRenderer as! RenderBlockFlowWrapper }

    func contentNeedsVisualReordering() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func damage() -> InlineDamageWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func hasDetachedContent() -> Bool {
      if let lineDamage = lineDamage {
        return lineDamage.hasDetachedContent()
      }
      return false
    }

    func preparePlacedFloats() {
      let placedFloats = blockFormattingState.placedFloats!
      placedFloats.clear()

      if !flow().containsFloats() {
        return
      }

      let isHorizontalWritingMode =
        flow().containingBlock() != nil
        ? flow().containingBlock()!.style().isHorizontalWritingMode() : true
      let placedFloatsIsLeftToRightInlineDirection =
        flow().containingBlock() != nil
        ? flow().containingBlock()!.style().isLeftToRightDirection() : true
      placedFloats.setIsLeftToRightDirection(
        isLeftToRightDirection: placedFloatsIsLeftToRightInlineDirection)
      for floatingObject in flow().floatingObjectSet! {
        let visualRect = floatingObject.frameRect

        let boxGeometry = BoxGeometry()
        let logicalRect = logicalRectForFloatingObject(
          visualRect: visualRect, isHorizontalWritingMode: isHorizontalWritingMode,
          placedFloatsIsLeftToRightInlineDirection: placedFloatsIsLeftToRightInlineDirection)

        boxGeometry.setTopLeft(topLeft: logicalRect.location())
        boxGeometry.setContentBoxWidth(width: logicalRect.width())
        boxGeometry.setContentBoxHeight(height: logicalRect.height())
        boxGeometry.setBorder(border: BoxGeometry.Edges())
        boxGeometry.setPadding(padding: BoxGeometry.Edges())
        boxGeometry.setHorizontalMargin(margin: BoxGeometry.HorizontalEdges())
        boxGeometry.setVerticalMargin(margin: BoxGeometry.VerticalEdges())

        let shapeOutsideInfo = floatingObject.renderer!.shapeOutsideInfo()
        let shape = shapeOutsideInfo != nil ? shapeOutsideInfo!.computedShape() : nil

        placedFloats.append(
          newFloatItem: PlacedFloats.Item(
            position: LineLayout.logicalPositionForFloatingObject(
              floatingObject: floatingObject,
              placedFloatsIsLeftToRightInlineDirection: placedFloatsIsLeftToRightInlineDirection),
            absoluteBoxGeometry: boxGeometry,
            localTopLeft: logicalRect.location(), shape: shape))
      }
    }

    static func logicalPositionForFloatingObject(
      floatingObject: FloatingObjectWrapper, placedFloatsIsLeftToRightInlineDirection: Bool
    )
      -> PlacedFloats.Item.Position
    {
      switch floatingObject.renderer!.style().floating() {
      case .Left:
        return placedFloatsIsLeftToRightInlineDirection ? .Left : .Right
      case .Right:
        return placedFloatsIsLeftToRightInlineDirection ? .Right : .Left
      case .InlineStart:
        if let floatBoxContainingBlock = floatingObject.renderer!.containingBlock() {
          return floatBoxContainingBlock.style().isLeftToRightDirection()
            == placedFloatsIsLeftToRightInlineDirection ? .Left : .Right
        }
        return .Left
      case .InlineEnd:
        if let floatBoxContainingBlock = floatingObject.renderer!.containingBlock() {
          return floatBoxContainingBlock.style().isLeftToRightDirection()
            == placedFloatsIsLeftToRightInlineDirection ? .Right : .Left
        }
        return .Right
      case .None:
        fatalError("Not reached")
      }
    }

    func logicalRectForFloatingObject(
      visualRect: LayoutRectWrapper, isHorizontalWritingMode: Bool,
      placedFloatsIsLeftToRightInlineDirection: Bool
    ) -> LayoutRectWrapper {
      // FIXME: We are flooring here for legacy compatibility. See FloatingObjects::intervalForFloatingObject and RenderBlockFlow::clearFloats.
      let logicalTop =
        isHorizontalWritingMode ? LayoutUnit(value: visualRect.y().floor()) : visualRect.x()
      var logicalLeft =
        isHorizontalWritingMode ? visualRect.x() : LayoutUnit(value: visualRect.y().floor())
      let logicalHeight =
        (isHorizontalWritingMode ? LayoutUnit(value: visualRect.maxY().floor()) : visualRect.maxX())
        - logicalTop
      let logicalWidth =
        (isHorizontalWritingMode ? visualRect.maxX() : LayoutUnit(value: visualRect.maxY().floor()))
        - logicalLeft
      if !placedFloatsIsLeftToRightInlineDirection {
        let rootBorderBoxWidth =
          inlineContentConstraints!.visualLeft
          + inlineContentConstraints!.horizontal.logicalWidth
          + inlineContentConstraints!.horizontal.logicalLeft
        logicalLeft = rootBorderBoxWidth - (logicalLeft + logicalWidth)
      }
      return LayoutRectWrapper(
        x: logicalLeft, y: logicalTop, width: logicalWidth, height: logicalHeight)
    }

    func constructContent(inlineLayoutState: InlineLayoutState, layoutResult: InlineLayoutResult)
      -> FloatRectWrapper
    {
      var damagedRect = InlineContentBuilder(blockFlow: flow(), boxTree: boxTree).build(
        layoutResult: layoutResult, inlineContent: ensureInlineContent(), lineDamage: lineDamage)

      inlineContent!.clearGapBeforeFirstLine = inlineLayoutState.clearGapBeforeFirstLine
      inlineContent!.clearGapAfterLastLine = inlineLayoutState.clearGapAfterLastLine
      inlineContent!.shrinkToFit()

      inlineContentCache!.inlineItems.shrinkToFit()
      blockFormattingState.shrinkToFit()

      // FIXME: These needs to be incorporated into the partial damage.
      let additionalHeight =
        inlineContent!.firstLinePaginationOffset + inlineContent!.clearGapBeforeFirstLine
        + inlineContent!.clearGapAfterLastLine
      damagedRect.expand(size: FloatSize(width: 0, height: additionalHeight))
      return damagedRect
    }

    func adjustContentForPagination(blockLayoutState: BlockLayoutState, isPartialLayout: Bool)
      -> [LineAdjustment]
    {
      assert(lineDamage == nil)

      if inlineContent == nil {
        return []
      }

      let layoutState = flow().view().frameView().layoutContext().layoutState()!
      if !layoutState.isPaginated() {
        return []
      }

      let allowLayoutRestart = !isPartialLayout
      let (adjustments, layoutRestartLine) = computeAdjustmentsForPagination(
        inlineContent: inlineContent!, placedFloats: blockFormattingState.placedFloats!,
        allowLayoutRestart: allowLayoutRestart, blockLayoutState: blockLayoutState,
        flow: flow())

      adjustLinePositionsForPagination(inlineContent: &inlineContent!, adjustments: adjustments)

      if layoutRestartLine != nil {
        let invalidation = InlineInvalidation(
          inlineDamage: ensureLineDamage(),
          inlineItemList: inlineContentCache!.inlineItems.content(),
          displayContent: inlineContent!.displayContent)
        let canRestart = invalidation.restartForPagination(
          lineIndex: layoutRestartLine!.index, pageTopAdjustment: layoutRestartLine!.offset)
        if !canRestart {
          lineDamage = nil
        }
      }

      return adjustments
    }

    func updateRenderTreePositions(
      lineAdjustments: [LineAdjustment], inlineLayoutState: InlineLayoutState
    ) {
      if inlineContent == nil {
        return
      }

      let blockFlow = flow()
      let rootStyle = blockFlow.style()
      let isLeftToRightPlacedFloatsInlineDirection = blockFormattingState.placedFloats!
        .isLeftToRightDirection
      let writingMode = rootStyle.writingMode()
      let isHorizontalWritingMode = isHorizontalWritingMode(writingMode: writingMode)

      for box in inlineContent!.displayContent.boxes {
        if box.isInlineBox() || box.isText() {
          continue
        }

        let layoutBox = box.layoutBox
        if !layoutBox.isAtomicInlineBox() {
          continue
        }

        let renderer = box.layoutBox.rendererForIntegration() as! RenderBoxWrapper
        if let layer = renderer.layer() {
          layer.setIsHiddenByOverflowTruncation(isHidden: box.isFullyTruncated)
        }

        renderer.setLocation(
          p: toLayoutPoint(point: box.visualRectIgnoringBlockDirection().location()))
      }

      var floatPaginationOffsetMap: [BoxWrapper: LayoutSizeWrapper] = [:]
      if !lineAdjustments.isEmpty {
        for floatItem in blockFormattingState.placedFloats!.list {
          if floatItem.layoutBox() == nil || floatItem.placedByLine == nil {
            continue
          }
          let adjustmentOffset = LineLayout.visualAdjustmentOffset(
            lineIndex: Int(floatItem.placedByLine!),
            lineAdjustments: lineAdjustments,
            isHorizontalWritingMode: isHorizontalWritingMode)
          if floatPaginationOffsetMap[floatItem.layoutBox()!] == nil {
            floatPaginationOffsetMap[floatItem.layoutBox()!] = adjustmentOffset
          }
        }
      }

      for layoutBox in formattingContextBoxes(root: rootLayoutBox()) {
        if !layoutBox.isFloatingPositioned() && !layoutBox.isOutOfFlowPositioned() {
          continue
        }
        if layoutBox.isLineBreakBox() {
          continue
        }
        let renderer = layoutBox.rendererForIntegration() as! RenderBoxWrapper
        let logicalGeometry = layoutState!.geometryForBox(layoutBox: layoutBox)

        if layoutBox.isFloatingPositioned() {
          let isInitialLetter = layoutBox.style.pseudoElementType() == .FirstLetter
          let floatingObject = flow().insertFloatingObjectForIFC(floatBox: renderer)
          let containerLogicalWidth =
            inlineContentConstraints!.visualLeft
            + inlineContentConstraints!.horizontal.logicalWidth
            + inlineContentConstraints!.horizontal.logicalLeft
          var (marginBoxVisualRect, borderBoxVisualRect) =
            LayoutIntegration.toMarginAndBorderBoxVisualRect(
              logicalGeometry: logicalGeometry, containerLogicalWidth: containerLogicalWidth,
              writingMode: writingMode,
              isLeftToRightDirection: isLeftToRightPlacedFloatsInlineDirection)

          let paginationOffset = floatPaginationOffsetMap[layoutBox]
          if let paginationOffset = paginationOffset {
            marginBoxVisualRect.move(size: paginationOffset)
            borderBoxVisualRect.move(size: paginationOffset)
          }
          if isInitialLetter {
            let firstLineTrim = LayoutUnit(
              value: inlineLayoutState.firstLineStartTrimForInitialLetter)
            marginBoxVisualRect.move(dx: LayoutUnit(value: 0), dy: -firstLineTrim)
            borderBoxVisualRect.move(dx: LayoutUnit(value: 0), dy: -firstLineTrim)
          }

          floatingObject.setFrameRect(frameRect: marginBoxVisualRect)
          floatingObject.setMarginOffset(
            offset: LayoutSizeWrapper(
              width: borderBoxVisualRect.x() - marginBoxVisualRect.x(),
              height: borderBoxVisualRect.y() - marginBoxVisualRect.y()))
          floatingObject.setIsPlaced(placed: true)

          let oldRect = renderer.frameRect()
          renderer.setLocation(p: borderBoxVisualRect.location())

          if renderer.checkForRepaintDuringLayout() {
            let hasMoved = oldRect.location() != renderer.location()
            if hasMoved {
              renderer.repaintDuringLayoutIfMoved(oldRect: oldRect)
            } else {
              renderer.repaint()
            }
          }

          if paginationOffset != nil {
            // Float content may be affected by the new position.
            renderer.markForPaginationRelayoutIfNeeded()
            renderer.layoutIfNeeded()
          }

          continue
        }

        if layoutBox.isOutOfFlowPositioned() {
          assert(renderer.layer() != nil)
          let layer = renderer.layer()!
          let borderBoxLogicalTopLeft = BoxGeometry.borderBoxRect(box: logicalGeometry).topLeft()
          let previousStaticPosition = LayoutPointWrapper(
            x: layer.staticInlinePosition(), y: layer.staticBlockPosition())
          let delta = borderBoxLogicalTopLeft - previousStaticPosition
          let hasStaticInlinePositioning = layoutBox.style.hasStaticInlinePosition(
            horizontal: renderer.isHorizontalWritingMode())

          if layoutBox.style.isOriginalDisplayInlineType() {
            blockFlow.setStaticInlinePositionForChild(
              child: renderer, blockOffset: borderBoxLogicalTopLeft.y,
              inlinePosition: borderBoxLogicalTopLeft.x)
            if hasStaticInlinePositioning {
              renderer.move(dx: delta.width(), dy: delta.height())
            }
          }

          layer.setStaticBlockPosition(position: borderBoxLogicalTopLeft.y)
          layer.setStaticInlinePosition(position: borderBoxLogicalTopLeft.x)

          if !delta.isZero() && hasStaticInlinePositioning {
            renderer.setChildNeedsLayout(markParents: .MarkOnlyThis)
          }
          continue
        }
      }
    }

    static func visualAdjustmentOffset(
      lineIndex: Int, lineAdjustments: [LineAdjustment], isHorizontalWritingMode: Bool
    )
      -> LayoutSizeWrapper
    {
      if lineAdjustments.isEmpty {
        return LayoutSizeWrapper()
      }
      if !isHorizontalWritingMode {
        return LayoutSizeWrapper(
          width: lineAdjustments[lineIndex].offset, height: LayoutUnit(value: 0))
      }
      return LayoutSizeWrapper(
        width: LayoutUnit(value: 0), height: lineAdjustments[lineIndex].offset)
    }

    func ensureInlineContent() -> InlineContent {
      if inlineContent == nil {
        inlineContent = InlineContent(lineLayout: self)
      }
      return inlineContent!
    }

    func ensureLineDamage() -> InlineDamageWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func rootLayoutBox() -> ElementBoxWrapper {
      return LineLayout.rootLayoutBox(boxTree: boxTree)
    }

    private static func rootLayoutBox(boxTree: BoxTree) -> ElementBoxWrapper {
      return boxTree.rootLayoutBox()
    }

    func clearInlineContent() {
      if inlineContent == nil {
        return
      }
      inlineContent = nil
    }

    func releaseCachesAndResetDamage() {
      inlineContentCache!.inlineItems.clearContent()
      if inlineContent != nil {
        inlineContent!.releaseCaches()
      }
      if let lineDamage = lineDamage {
        InlineInvalidation.resetInlineDamage(inlineDamage: lineDamage)
      }
    }

    func physicalBaselineForLine(line: InlineDisplay.Line) -> LayoutUnit {
      switch writingModeToBlockFlowDirection(writingMode: rootLayoutBox().style.writingMode()) {
      case .TopToBottom, .BottomToTop:
        return LayoutUnit(value: line.lineBoxTop() + line.baseline())
      case .LeftToRight:
        return LayoutUnit(value: line.lineBoxLeft() + (line.lineBoxWidth() - line.baseline()))
      case .RightToLeft:
        return LayoutUnit(value: line.lineBoxLeft() + line.baseline())
      }
    }

    var boxTree: BoxTree
    var layoutState: LayoutStateWrapper?
    var blockFormattingState: BlockFormattingState
    var inlineContentCache: InlineContentCache? = nil
    var inlineContentConstraints: ConstraintsForInlineContent? = nil
    // FIXME: This should be part of LayoutState.
    var lineDamage: InlineDamageWrapper? = nil
    var inlineContent: InlineContent? = nil
    var boxGeometryUpdater: BoxGeometryUpdater
  }
}
