/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2009, 2010, 2014 Apple Inc. All rights reserved.
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

enum SkipEmptySectionsValue {
  case DoNotSkipEmptySections
  case SkipEmptySections
}

class RenderTableWrapper: RenderBlockWrapper {
  // Per CSS 3 writing-mode: "The first and second values of the 'border-spacing' property represent spacing between columns
  // and rows respectively, not necessarily the horizontal and vertical spacing respectively".
  func hBorderSpacing() -> LayoutUnit { return hSpacing }

  func vBorderSpacing() -> LayoutUnit { return vSpacing }

  func collapseBorders() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderEnd() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderAfter() -> LayoutUnit {
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

  override func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderStart() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderEnd() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerBorderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func recalcBordersInRowDirection() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func forceSectionsRecalc() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct ColumnStruct {
    let span: Int32 = 1
  }

  func columnPositions() -> [LayoutUnit] { return columnPos }

  func setColumnPosition(index: Int, position: LayoutUnit) {
    // Note that if our horizontal border-spacing changed, our position will change but not
    // our column's width. In practice, horizontal border-spacing won't change often.
    columnLogicalWidthChanged = columnLogicalWidthChanged || columnPos[index] != position
    columnPos[index] = position
  }

  // This function returns nil if the table has no section.
  func topSection() -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bottomSection() -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func numEffCols() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func spanOfEffCol(effCol: UInt32) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colToEffCol(column: UInt32) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bordersPaddingAndSpacingInRowDirection() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return the first column or column-group.
  func firstColumn() -> RenderTableColWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colElement(col: UInt32) -> RenderTableColWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func sectionAbove(
    section: RenderTableSectionWrapper?,
    skipEmptySections: SkipEmptySectionsValue = .DoNotSkipEmptySections
  ) -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func sectionBelow(
    section: RenderTableSectionWrapper?,
    skipEmptySections: SkipEmptySectionsValue = .DoNotSkipEmptySections
  ) -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  typealias CollapsedBorderValues = [CollapsedBorderValue]

  private func invalidateCollapsedBorders(cellWithStyleChange: RenderTableCellWrapper? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentBorderValue() -> CollapsedBorderValue? { return currentBorder }

  private func recalcSectionsIfNeeded() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func createAnonymousWithParentRenderer(parent: RenderElementWrapper) -> RenderTableWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willInsertTableColumn(child: RenderTableColWrapper, beforeChild: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willInsertTableSection(child: RenderTableSectionWrapper, beforeChild: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func sumCaptionsLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func simplifiedNormalFlowLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func avoidsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private final func paintObject(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    var paintPhase = paintInfo.phase
    if (paintPhase == .BlockBackground || paintPhase == .ChildBlockBackground)
      && hasVisibleBoxDecorations() && style().usedVisibility() == .Visible
    {
      paintBoxDecorations(paintInfo: paintInfo, paintOffset: paintOffset)
    }

    if paintPhase == .Mask {
      paintMask(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    if paintPhase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(renderBox: self, paintOffset: paintOffset)
    }

    // We're done.  We don't bother painting any children.
    if paintPhase == .BlockBackground {
      return
    }

    // We don't paint our own background, but we do let the kids paint their backgrounds.
    if paintPhase == .ChildBlockBackgrounds {
      paintPhase = .ChildBlockBackground
    }

    var info = paintInfo
    info.phase = paintPhase
    info.updateSubtreePaintRootForChildren(renderer: self)

    for box: RenderBoxWrapper in childrenOfType(parent: self) {
      if !box.hasSelfPaintingLayer() && (box.isRenderTableSection() || box.isRenderTableCaption()) {
        let childPoint = flipForWritingModeForChild(child: box, point: paintOffset)
        box.paint(paintInfo: &info, paintOffset: childPoint)
      }
    }

    if collapseBorders() && paintPhase == .ChildBlockBackground
      && style().usedVisibility() == .Visible
    {
      recalcCollapsedBorders()
      // Using our cached sorted styles, we then do individual passes,
      // painting each style of border from lowest precedence to highest precedence.
      info.phase = .CollapsedTableBorders
      for collapsedBorder in collapsedBorders {
        currentBorder = collapsedBorder
        var section = bottomSection()
        while section != nil {
          let childPoint = flipForWritingModeForChild(child: section!, point: paintOffset)
          section!.paint(paintInfo: &info, paintOffset: childPoint)
          section = sectionAbove(section: section)
        }
      }
      currentBorder = nil
    }

    // Paint outline.
    if (paintPhase == .Outline || paintPhase == .SelfOutline) && hasOutline()
      && style().usedVisibility() == .Visible
    {
      paintOutline(
        paintInfo: paintInfo, paintRect: LayoutRectWrapper(location: paintOffset, size: size()))
    }
  }

  final override func paintBoxDecorations(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    var rect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: &rect)

    let backgroundPainter = BackgroundPainter(renderer: self, paintInfo: paintInfo)

    let bleedAvoidance = determineBackgroundBleedAvoidance(context: paintInfo.context())
    if !BackgroundPainter.boxShadowShouldBeAppliedToBackground(
      renderer: self, paintOffset: rect.location(), bleedAvoidance: bleedAvoidance,
      inlineBox: InlineIterator.InlineBoxIterator())
    {
      backgroundPainter.paintBoxShadow(paintRect: rect, style: style(), shadowStyle: .Normal)
    }

    let stateSaver = GraphicsContextStateSaver(context: paintInfo.context(), saveAndRestore: false)
    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      // To avoid the background color bleeding out behind the border, we'll render background and border
      // into a transparency layer, and then clip that in one go (which requires setting up the clip before
      // beginning the layer).
      stateSaver.save()
      let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: rect)
      borderShape.clipToOuterShape(
        context: paintInfo.context(), deviceScaleFactor: document().deviceScaleFactor())
      paintInfo.context().beginTransparencyLayer(opacity: 1)
    }

    backgroundPainter.paintBackground(paintRect: rect, bleedAvoidance: bleedAvoidance)
    backgroundPainter.paintBoxShadow(paintRect: rect, style: style(), shadowStyle: .Inset)

    if style().hasVisibleBorderDecoration() && !collapseBorders() {
      let borderPainter = BorderPainter(renderer: self, paintInfo: paintInfo)
      borderPainter.paintBorder(rect: rect, style: style())
    }

    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      paintInfo.context().endTransparencyLayer()
    }
  }

  final override func paintMask(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if style().usedVisibility() != .Visible || paintInfo.phase != .Mask {
      return
    }

    var rect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: &rect)

    paintMaskImages(paintInfo: paintInfo, paintRect: rect)
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    if simplifiedLayout() {
      return
    }

    recalcSectionsIfNeeded()
    // FIXME: We should do this recalc lazily in borderStart/borderEnd so that we don't have to make sure
    // to call this before we call borderStart/borderEnd to avoid getting a stale value.
    recalcBordersInRowDirection()
    var sectionMoved = false
    var movedSectionLogicalTop = LayoutUnit()
    var sectionCount = 0
    var shouldCacheIntrinsicContentLogicalHeightForFlexItem = false

    let repainter = LayoutRepainter(renderer: self)
    do {
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())

      let oldLogicalWidth = logicalWidth()
      let oldLogicalHeight = logicalHeight()
      resetLogicalHeightBeforeLayoutIfNeeded()
      updateLogicalWidth()

      if logicalWidth() != oldLogicalWidth {
        for caption in captions {
          caption!.setNeedsLayout(markParents: .MarkOnlyThis)
        }
      }
      // FIXME: The optimisation below doesn't work since the internal table
      // layout could have changed. We need to add a flag to the table
      // layout that tells us if something has changed in the min max
      // calculations to do it correctly.
      //     if ( oldWidth != width() || columns.size() + 1 != columnPos.size() )
      tableLayout!.layout()

      var oldTableLogicalTop = LayoutUnit()
      for caption in captions {
        if caption!.style().captionSide() == .Bottom {
          continue
        }
        oldTableLogicalTop +=
          caption!.logicalHeight() + caption!.marginBefore() + caption!.marginAfter()
      }

      let collapsing = collapseBorders()

      var totalSectionLogicalHeight = LayoutUnit()
      for child: RenderElementWrapper in childrenOfType(parent: self) {
        if let section = child as? RenderTableSectionWrapper {
          if columnLogicalWidthChanged {
            section.setChildNeedsLayout(markParents: .MarkOnlyThis)
          }
          section.layoutIfNeeded()
          totalSectionLogicalHeight += section.calcRowLogicalHeight()
          if collapsing {
            section.recalcOuterBorder()
          }
          assert(!section.needsLayout())
        } else if let column = child as? RenderTableColWrapper {
          column.layoutIfNeeded()
          assert(!column.needsLayout())
        }
      }

      // If any table section moved vertically, we will just repaint everything from that
      // section down (it is quite unlikely that any of the following sections
      // did not shift).
      layoutCaptions()
      if !captions.isEmpty && logicalHeight() != oldTableLogicalTop {
        sectionMoved = true
        movedSectionLogicalTop = min(logicalHeight(), oldTableLogicalTop)
      }

      let zero = LayoutUnit(value: UInt64(0))
      let borderAndPaddingBefore = borderBefore() + (collapsing ? zero : paddingBefore())
      let borderAndPaddingAfter = borderAfter() + (collapsing ? zero : paddingAfter())

      setLogicalHeight(size: logicalHeight() + borderAndPaddingBefore)

      if !isOutOfFlowPositioned() {
        updateLogicalHeight()
      }

      var computedLogicalHeight = LayoutUnit()

      let logicalHeightLength = style().logicalHeight()
      if logicalHeightLength.isIntrinsic()
        || (logicalHeightLength.isSpecified() && logicalHeightLength.isPositive())
      {
        computedLogicalHeight = convertStyleLogicalHeightToComputedHeight(
          styleLogicalHeight: logicalHeightLength)
      }

      if let overridingLogicalHeight = overridingLogicalHeight() {
        computedLogicalHeight = max(
          computedLogicalHeight,
          overridingLogicalHeight - borderAndPaddingAfter - sumCaptionsLogicalHeight())
      }

      if !shouldIgnoreLogicalMinMaxHeightSizes() {
        let logicalMaxHeightLength = style().logicalMaxHeight()
        if logicalMaxHeightLength.isFillAvailable()
          || (logicalMaxHeightLength.isSpecified() && !logicalMaxHeightLength.isNegative()
            && !logicalMaxHeightLength.isMinContent() && !logicalMaxHeightLength.isMaxContent()
            && !logicalMaxHeightLength.isFitContent())
        {
          let computedMaxLogicalHeight = convertStyleLogicalHeightToComputedHeight(
            styleLogicalHeight: logicalMaxHeightLength)
          computedLogicalHeight = min(computedLogicalHeight, computedMaxLogicalHeight)
        }

        var logicalMinHeightLength = style().logicalMinHeight()
        if logicalMinHeightLength.isMinContent() || logicalMinHeightLength.isMaxContent()
          || logicalMinHeightLength.isFitContent()
        {
          logicalMinHeightLength = LengthWrapper(type: .Auto)
        }
        if logicalMinHeightLength.isIntrinsic()
          || (logicalMinHeightLength.isSpecified() && !logicalMinHeightLength.isNegative())
        {
          let computedMinLogicalHeight = convertStyleLogicalHeightToComputedHeight(
            styleLogicalHeight: logicalMinHeightLength)
          computedLogicalHeight = max(computedLogicalHeight, computedMinLogicalHeight)
        }
      }

      distributeExtraLogicalHeight(
        extraLogicalHeight: computedLogicalHeight - totalSectionLogicalHeight)

      var section_ = topSection()
      while section_ != nil {
        section_!.layoutRows()
        section_ = sectionBelow(section: section_)
      }

      if topSection() == nil && computedLogicalHeight > totalSectionLogicalHeight
        && !document().inQuirksMode()
      {
        // Completely empty tables (with no sections or anything) should at least honor their
        // overriding or specified height in strict mode, but this value will not be cached.
        shouldCacheIntrinsicContentLogicalHeightForFlexItem = false
        let tableLogicalHeight = { [self] in
          if let overridingLogicalHeight = overridingLogicalHeight() {
            return overridingLogicalHeight - borderAndPaddingAfter
          }
          return logicalHeight() + computedLogicalHeight
        }
        setLogicalHeight(size: tableLogicalHeight())
      }

      var sectionLogicalLeft = style().isLeftToRightDirection() ? borderStart() : borderEnd()
      if !collapsing {
        sectionLogicalLeft += style().isLeftToRightDirection() ? paddingStart() : paddingEnd()
      }

      // position the table sections
      var section = topSection()
      while section != nil {
        sectionCount += 1
        if !sectionMoved && section!.logicalTop() != logicalHeight() {
          sectionMoved = true
          movedSectionLogicalTop =
            min(logicalHeight(), section!.logicalTop())
            + (style().isHorizontalWritingMode()
              ? section!.visualOverflowRect().y() : section!.visualOverflowRect().x())
        }
        section!.setLogicalLocation(
          location: LayoutPointWrapper(x: sectionLogicalLeft, y: logicalHeight()))

        setLogicalHeight(size: logicalHeight() + section!.logicalHeight())
        section!.addVisualEffectOverflow()

        section = sectionBelow(section: section)
      }

      setLogicalHeight(size: logicalHeight() + borderAndPaddingAfter)

      layoutCaptions(bottomCaptionLayoutPhase: .Yes)

      if isOutOfFlowPositioned() {
        updateLogicalHeight()
      }

      // table can be containing block of positioned elements.
      let dimensionChanged =
        oldLogicalWidth != logicalWidth() || oldLogicalHeight != logicalHeight()
      layoutPositionedObjects(relayoutChildren: dimensionChanged)

      updateLayerTransform()

      // Layout was changed, so probably borders too.
      invalidateCollapsedBorders()

      // The location or height of one or more sections may have changed.
      invalidateCachedColumnOffsets()

      computeOverflow(oldClientAfterEdge: clientLogicalBottom())
    }

    let layoutState = view().frameView().layoutContext().layoutState()
    if layoutState != nil && layoutState!.pageLogicalHeight().bool() {
      setPageLogicalOffset(
        logicalOffset: layoutState!.pageLogicalOffset(child: self, childLogicalOffset: logicalTop())
      )
    }

    let didFullRepaint = repainter.repaintAfterLayout()
    // Repaint with our new bounds if they are different from our old bounds.
    if !didFullRepaint && sectionMoved {
      if style().isHorizontalWritingMode() {
        repaintRectangle(
          repaintRect: LayoutRectWrapper(
            x: visualOverflowRect().x(), y: movedSectionLogicalTop,
            width: visualOverflowRect().width(),
            height: visualOverflowRect().maxY() - movedSectionLogicalTop))
      } else {
        repaintRectangle(
          repaintRect: LayoutRectWrapper(
            x: movedSectionLogicalTop, y: visualOverflowRect().y(),
            width: visualOverflowRect().maxX() - movedSectionLogicalTop,
            height: visualOverflowRect().height()))
      }
    }

    let paginated = layoutState != nil && layoutState!.isPaginated()
    if sectionMoved && paginated {
      // FIXME: Table layout should always stabilize even when section moves (see webkit.org/b/174412).
      if recursiveSectionMovedWithPaginationLevel < sectionCount {
        let _ = SetForScope(
          scopedVariable: &recursiveSectionMovedWithPaginationLevel,
          newValue: recursiveSectionMovedWithPaginationLevel + 1)
        markForPaginationRelayoutIfNeeded()
        layoutIfNeeded()
      } else {
        fatalError("Not reached")
      }
    }

    // FIXME: This value isn't the intrinsic content logical height, but we need
    // to update the value as its used by flexbox layout. crbug.com/367324
    if shouldCacheIntrinsicContentLogicalHeightForFlexItem {
      cacheIntrinsicContentLogicalHeightForFlexItem(height: contentLogicalHeight())
    }

    columnLogicalWidthChanged = false
    clearNeedsLayout()
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicKeywordLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func firstLineBaseline() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func lastLineBaseline() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func invalidateCachedColumnOffsets() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateLogicalWidth() {
    recalcSectionsIfNeeded()

    if isGridItem() {
      // FIXME: Investigate whether the grid layout algorithm provides all the logic
      // needed and that we're not skipping anything essential due to the early return here.
      super.updateLogicalWidth()
      return
    }

    if isOutOfFlowPositioned() {
      var computedValues = LogicalExtentComputedValues()
      computePositionedLogicalWidth(computedValues: &computedValues)
      setLogicalWidth(size: computedValues.extent)
      setLogicalLeft(left: computedValues.position)
      setMarginStart(value: computedValues.margins.start)
      setMarginEnd(value: computedValues.margins.end)
    }

    let cb = containingBlock()!

    let availableLogicalWidth = containingBlockLogicalWidthForContent()
    let hasPerpendicularContainingBlock =
      cb.style().isHorizontalWritingMode() != style().isHorizontalWritingMode()
    let containerWidthInInlineDirection =
      hasPerpendicularContainingBlock
      ? perpendicularContainingBlockLogicalHeight() : availableLogicalWidth

    let styleLogicalWidth = style().logicalWidth()
    if let overridingLogicalWidth = overridingLogicalWidth() {
      setLogicalWidth(size: overridingLogicalWidth)
    } else if (styleLogicalWidth.isSpecified() && styleLogicalWidth.isPositive())
      || styleLogicalWidth.isIntrinsic()
    {
      setLogicalWidth(
        size: convertStyleLogicalWidthToComputedWidth(
          styleLogicalWidth: styleLogicalWidth, availableWidth: containerWidthInInlineDirection))
    } else {
      // Subtract out any fixed margins from our available width for auto width tables.
      let marginStart = minimumValueForLength(
        length: style().marginStart(), maximumValue: availableLogicalWidth)
      let marginEnd = minimumValueForLength(
        length: style().marginEnd(), maximumValue: availableLogicalWidth)
      let marginTotal = marginStart + marginEnd

      // Subtract out our margins to get the available content width.
      var availableContentLogicalWidth = max(
        LayoutUnit(value: 0), containerWidthInInlineDirection - marginTotal)
      if shrinkToAvoidFloats() && cb.containsFloats() && !hasPerpendicularContainingBlock {
        // FIXME: Work with regions someday.
        availableContentLogicalWidth = shrinkLogicalWidthToAvoidFloats(
          childMarginStart: marginStart, childMarginEnd: marginEnd, cb: cb, fragment: nil)
      }

      // Ensure we aren't bigger than our available width.
      setLogicalWidth(size: min(availableContentLogicalWidth, maxPreferredLogicalWidth()))
      var maxWidth = maxPreferredLogicalWidth()
      // scaledWidthFromPercentColumns depends on m_layoutStruct in TableLayoutAlgorithmAuto, which
      // maxPreferredLogicalWidth fills in. So scaledWidthFromPercentColumns has to be called after
      // maxPreferredLogicalWidth.
      let scaledWidth =
        tableLayout!.scaledWidthFromPercentColumns() + bordersPaddingAndSpacingInRowDirection()
      maxWidth = max(scaledWidth, maxWidth)
      setLogicalWidth(size: min(availableContentLogicalWidth, maxWidth))
    }

    // Ensure we aren't bigger than our max-width style.
    let styleMaxLogicalWidth = style().logicalMaxWidth()
    if (styleMaxLogicalWidth.isSpecified() && !styleMaxLogicalWidth.isNegative())
      || styleMaxLogicalWidth.isIntrinsic()
    {
      let computedMaxLogicalWidth = convertStyleLogicalWidthToComputedWidth(
        styleLogicalWidth: styleMaxLogicalWidth, availableWidth: availableLogicalWidth)
      setLogicalWidth(size: min(logicalWidth(), computedMaxLogicalWidth))
    }

    // Ensure we aren't smaller than our min preferred width.
    setLogicalWidth(size: max(logicalWidth(), minPreferredLogicalWidth()))

    // Ensure we aren't smaller than our min-width style.
    let styleMinLogicalWidth = style().logicalMinWidth()
    if (styleMinLogicalWidth.isSpecified() && !styleMinLogicalWidth.isNegative())
      || styleMinLogicalWidth.isIntrinsic()
    {
      let computedMinLogicalWidth = convertStyleLogicalWidthToComputedWidth(
        styleLogicalWidth: styleMinLogicalWidth, availableWidth: availableLogicalWidth)
      setLogicalWidth(size: max(logicalWidth(), computedMinLogicalWidth))
    }

    // Finally, with our true width determined, compute our margins for real.
    setMarginStart(value: LayoutUnit(value: 0))
    setMarginEnd(value: LayoutUnit(value: 0))
    if !hasPerpendicularContainingBlock {
      var containerLogicalWidthForAutoMargins = availableLogicalWidth
      if avoidsFloats() && cb.containsFloats() {
        containerLogicalWidthForAutoMargins = containingBlockAvailableLineWidthInFragment(
          fragment: nil)  // FIXME: Work with regions someday.
      }
      var marginValues = ComputedMarginValues()
      let hasInvertedDirection =
        cb.style().isLeftToRightDirection() == style().isLeftToRightDirection()
      if hasInvertedDirection {
        computeInlineDirectionMargins(
          containingBlock: cb, containerWidth: availableLogicalWidth,
          availableSpaceAdjustedWithFloats: containerLogicalWidthForAutoMargins,
          childWidth: logicalWidth(),
          marginStart: &marginValues.start, marginEnd: &marginValues.end)
      } else {
        computeInlineDirectionMargins(
          containingBlock: cb, containerWidth: availableLogicalWidth,
          availableSpaceAdjustedWithFloats: containerLogicalWidthForAutoMargins,
          childWidth: logicalWidth(),
          marginStart: &marginValues.end, marginEnd: &marginValues.start)
      }
      setMarginStart(value: marginValues.start)
      setMarginEnd(value: marginValues.end)
    } else {
      setMarginStart(
        value: minimumValueForLength(
          length: style().marginStart(), maximumValue: availableLogicalWidth))
      setMarginEnd(
        value: minimumValueForLength(
          length: style().marginEnd(), maximumValue: availableLogicalWidth))
    }
  }

  // This method takes a RenderStyle's logical width, min-width, or max-width length and computes its actual value.
  private func convertStyleLogicalWidthToComputedWidth(
    styleLogicalWidth: LengthWrapper, availableWidth: LayoutUnit
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func convertStyleLogicalHeightToComputedHeight(styleLogicalHeight: LengthWrapper)
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addOverflowFromChildren() {
    // Add overflow from borders.
    // Technically it's odd that we are incorporating the borders into layout overflow, which is only supposed to be about overflow from our
    // descendant objects, but since tables don't support overflow:auto, this works out fine.
    if collapseBorders() {
      let rightBorderOverflow = width() + outerBorderRight() - borderRight()
      let leftBorderOverflow = borderLeft() - outerBorderLeft()
      let bottomBorderOverflow = height() + outerBorderBottom() - borderBottom()
      let topBorderOverflow = borderTop() - outerBorderTop()
      let borderOverflowRect = LayoutRectWrapper(
        x: leftBorderOverflow, y: topBorderOverflow,
        width: rightBorderOverflow - leftBorderOverflow,
        height: bottomBorderOverflow - topBorderOverflow)
      if borderOverflowRect != borderBoxRect() {
        addLayoutOverflow(rect: borderOverflowRect)
        addVisualOverflow(rect: borderOverflowRect)
      }
    }

    // Add overflow from our caption.
    for caption in captions {
      if caption != nil {
        addOverflowFromChild(child: caption!)
      }
    }

    // Add overflow from our sections.
    var section = topSection()
    while section != nil {
      addOverflowFromChild(child: section!)
      section = sectionBelow(section: section)
    }
  }

  override func adjustBorderBoxRectForPainting(paintRect: inout LayoutRectWrapper) {
    for caption in captions {
      let captionLogicalHeight =
        caption!.logicalHeight() + caption!.marginBefore() + caption!.marginAfter()
      let captionIsBefore =
        (caption!.style().captionSide() != .Bottom) != style().isFlippedBlocksWritingMode()
      if style().isHorizontalWritingMode() {
        paintRect.setHeight(height: paintRect.height() - captionLogicalHeight)
        if captionIsBefore {
          paintRect.move(dx: LayoutUnit(value: UInt64(0)), dy: captionLogicalHeight)
        }
      } else {
        paintRect.setWidth(width: paintRect.width() - captionLogicalHeight)
        if captionIsBefore {
          paintRect.move(dx: captionLogicalHeight, dy: LayoutUnit(value: UInt64(0)))
        }
      }
    }

    super.adjustBorderBoxRectForPainting(paintRect: &paintRect)
  }

  private func recalcCollapsedBorders() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum BottomCaptionLayoutPhase {
    case No
    case Yes
  }

  private func layoutCaptions(bottomCaptionLayoutPhase: BottomCaptionLayoutPhase = .No) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func distributeExtraLogicalHeight(extraLogicalHeight: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var columnPos: [LayoutUnit] = []
  let columns: [ColumnStruct] = []
  private let captions: [RenderTableCaptionWrapper?] = []

  private let tableLayout: TableLayout? = nil

  private let collapsedBorders = CollapsedBorderValues()
  private var currentBorder: CollapsedBorderValue? = nil

  private var columnLogicalWidthChanged = false

  private let hSpacing = LayoutUnit()
  private let vSpacing = LayoutUnit()
  private var recursiveSectionMovedWithPaginationLevel = 0
}
