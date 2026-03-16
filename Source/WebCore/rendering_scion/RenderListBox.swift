/*
 * This file is part of the select element renderer in WebCore.
 *
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

private let itemBlockSpacing: Int32 = 1

private let optionsSpacingInlineStart: Int32 = 2

// Default size when the multiple attribute is present but size attribute is absent.
private let defaultSize: Int32 = 4

private func itemOffsetForAlignment(
  _ textRun: TextRunWrapper, _ elementStyle: RenderStyleWrapper, _ itemStyle: RenderStyleWrapper,
  _ itemFont: FontCascadeWrapper, _ itemBoundingBox: LayoutRectWrapper
) -> LayoutSizeWrapper {
  var actualAlignment = itemStyle.textAlign()
  // FIXME: Firefox doesn't respect .Justify. Should we?
  // FIXME: Handle .End here
  if actualAlignment == .Start || actualAlignment == .Justify {
    actualAlignment = itemStyle.isLeftToRightDirection() ? .Left : .Right
  }

  let isHorizontalWritingMode = elementStyle.isHorizontalWritingMode()

  let itemBoundingBoxLogicalWidth =
    isHorizontalWritingMode ? itemBoundingBox.width() : itemBoundingBox.height()
  let offset = LayoutSizeWrapper(
    width: Int32(0), height: Int32(itemFont.metricsOfPrimaryFont().intAscent()))
  if actualAlignment == .Right || actualAlignment == .WebKitRight {
    let textWidth = itemFont.width(run: textRun)
    offset.setWidth(
      width: itemBoundingBoxLogicalWidth - textWidth - Float32(optionsSpacingInlineStart))
  } else if actualAlignment == .Center || actualAlignment == .WebKitCenter {
    let textWidth = itemFont.width(run: textRun)
    offset.setWidth(width: (itemBoundingBoxLogicalWidth - textWidth) / 2)
  } else {
    offset.setWidth(width: optionsSpacingInlineStart)
  }

  if !isHorizontalWritingMode {
    return LayoutSizeWrapper(width: -offset.height(), height: offset.width())
  }

  return offset
}

// TODO(asuhan): also inherit from ScrollableArea
final class RenderListBoxWrapper: RenderBlockFlowWrapper {
  // TODO(asuhan): move to ScrollableArea
  private func scrollToOffsetWithoutAnimation(orientation: ScrollbarOrientation, offset: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): move to ScrollableArea
  private func scrollOrigin() -> IntPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): move to ScrollableArea
  private func setScrollOrigin(origin: IntPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func selectElement() -> HTMLSelectElementWrapper {
    return nodeForNonAnonymous() as! HTMLSelectElementWrapper
  }

  private func itemBoundingBoxRect(additionalOffset: LayoutPointWrapper, index: Int32)
    -> LayoutRectWrapper
  {
    var x = additionalOffset.x + borderLeft() + paddingLeft()
    let y = additionalOffset.y + borderTop() + paddingTop()

    if let vBar = verticalScrollbar(), shouldPlaceVerticalScrollbarOnLeft() {
      x += vBar.occupiedWidth()
    }

    var itemOffset = itemLogicalHeight() * (index - indexOffset())
    if style().isFlippedBlocksWritingMode() {
      itemOffset = contentLogicalHeight() - itemLogicalHeight() - itemOffset
    }

    if style().isVerticalWritingMode() {
      return LayoutRectWrapper(
        x: x + itemOffset, y: y, width: itemLogicalHeight(), height: contentHeight())
    }

    return LayoutRectWrapper(
      x: x, y: y + itemOffset, width: contentWidth(), height: itemLogicalHeight())
  }

  @discardableResult
  private func scrollToRevealElementAtListIndex(index: Int32) -> Bool {
    if index < 0 || index >= numItems() || listIndexIsVisible(index: index) {
      return false
    }

    var newOffset = index < indexOffset() ? index : index - numVisibleItems() + 1

    if style().isFlippedBlocksWritingMode() {
      newOffset *= -1
    }

    scrollToPosition(positionIndex: newOffset)
    return true
  }

  private func listIndexIsVisible(index: Int32) -> Bool {
    let firstIndex = indexOfFirstVisibleItemInsidePaddingBeforeArea ?? indexOffset()
    let endIndex =
      indexOfFirstVisibleItemInsidePaddingAfterArea != nil
      ? indexOfFirstVisibleItemInsidePaddingAfterArea! + numberOfVisibleItemsInPaddingAfter()
      : indexOffset() + numVisibleItems()

    return index >= firstIndex && index < endIndex
  }

  private func size() -> UInt32 {
    if style().fieldSizing() == .Content {
      return UInt32(numItems())
    }

    let specifiedSize = selectElement().size()
    if specifiedSize >= 1 {
      return specifiedSize
    }

    return UInt32(defaultSize)
  }

  override func hasControlClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintObject(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if style().usedVisibility() != .Visible {
      return
    }

    if paintInfo.phase == .Foreground {
      paintItem(
        paintInfo, paintOffset,
        { (paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, listItemIndex: Int32) in
          paintItemForeground(paintInfo, paintOffset, listItemIndex)
        })
    }

    // Paint the children.
    super.paintObject(paintInfo: &paintInfo, paintOffset: paintOffset)

    switch paintInfo.phase {
    // Depending on whether we have overlay scrollbars they
    // get rendered in the foreground or background phases
    case .Foreground:
      if scrollbar!.isOverlayScrollbar() {
        paintScrollbar(paintInfo, paintOffset, scrollbar!)
      }
    case .BlockBackground:
      if !scrollbar!.isOverlayScrollbar() {
        paintScrollbar(paintInfo, paintOffset, scrollbar!)
      }
    case .ChildBlockBackground, .ChildBlockBackgrounds:
      paintItem(
        paintInfo, paintOffset,
        { (paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, listItemIndex: Int32) in
          paintItemBackground(paintInfo, paintOffset, listItemIndex)
        })
    default:
      break
    }
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    // Clip against the padding box, to give <option>s and overlay scrollbar some extra space
    // to get painted.
    var clipRect = paddingBoxRect()
    clipRect.moveBy(offset: additionalOffset)
    return clipRect
  }

  override func isPointInOverflowControl(
    _ result: inout HitTestResultWrapper, locationInContainer: LayoutPointWrapper,
    accumulatedOffset: LayoutPointWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if oldStyle != nil && oldStyle!.writingMode() != style().writingMode() && scrollbar != nil {
      setHasScrollbar(scrollbarOrientationForWritingMode())
    }
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    if shouldApplySizeOrInlineSizeContainment() {
      if let logicalWidth = explicitIntrinsicInnerLogicalWidth() {
        maxLogicalWidth = logicalWidth
      } else {
        maxLogicalWidth = LayoutUnit(value: 2 * optionsSpacingInlineStart)
      }
    } else {
      maxLogicalWidth = LayoutUnit(value: 2 * optionsSpacingInlineStart + optionsLogicalWidth)
    }

    if scrollbar != nil {
      maxLogicalWidth +=
        scrollbar!.orientation() == .Vertical ? scrollbar!.width() : scrollbar!.height()
    }

    let logicalWidth = style().logicalWidth()
    if logicalWidth.isCalculated() {
      let zero = LayoutUnit(value: UInt64(0))
      minLogicalWidth = max(zero, valueForLength(length: logicalWidth, maximumValue: zero))
    } else if !logicalWidth.isPercent() {
      minLogicalWidth = maxLogicalWidth
    }
  }

  override func computePreferredLogicalWidths() {
    // Nested style recal do not fire post recal callbacks. see webkit.org/b/153767
    assert(!optionsChanged || Style.postResolutionCallbacksAreSuspended())

    m_minPreferredLogicalWidth = LayoutUnit(value: 0)
    m_maxPreferredLogicalWidth = LayoutUnit(value: 0)

    if style().logicalWidth().isFixed() && style().logicalWidth().value() > 0 {
      m_maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().logicalWidth())
      m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &m_minPreferredLogicalWidth, maxLogicalWidth: &m_maxPreferredLogicalWidth)
    }

    computePreferredLogicalWidths(
      style().logicalMinWidth(), style().logicalMaxWidth(),
      style().isHorizontalWritingMode()
        ? horizontalBorderAndPaddingExtent() : verticalBorderAndPaddingExtent())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    var logicalHeight = itemLogicalHeight() * size() - itemBlockSpacing

    if shouldApplySizeContainment(),
      let explicitIntrinsicHeight = explicitIntrinsicInnerLogicalHeight()
    {
      logicalHeight = explicitIntrinsicHeight
    }

    cacheIntrinsicContentLogicalHeightForFlexItem(height: logicalHeight)
    logicalHeight +=
      style().isHorizontalWritingMode()
      ? verticalBorderAndPaddingExtent() : horizontalBorderAndPaddingExtent()
    return boxComputeLogicalHeight(logicalHeight: logicalHeight, logicalTop: logicalTop)
  }

  override func layout() {
    // TODO(asuhan): add back stack recursion checks
    super.layout()

    if scrollbar != nil {
      let enabled = numVisibleItems() < numItems()
      scrollbar!.setEnabled(e: enabled)
      scrollbar!.setSteps(
        lineStep: 1, pageStep: max(1, numVisibleItems() - 1),
        pixelsPerStep: itemLogicalHeight().int())
      scrollbar!.setProportion(visibleSize: numVisibleItems(), totalSize: numItems())
      if !enabled {
        scrollToOffsetWithoutAnimation(orientation: scrollbar!.orientation(), offset: 0)
        scrollPosition = ScrollPosition()
      }

      if style().isFlippedBlocksWritingMode() {
        var scrollOrigin = IntPoint(x: 0, y: numItems() - numVisibleItems())
        if scrollbar!.orientation() == .Horizontal {
          scrollOrigin = scrollOrigin.transposedPoint()
        }
        setScrollOrigin(origin: scrollOrigin)
        scrollbar!.offsetDidChange()
      } else {
        setScrollOrigin(origin: IntPoint())
      }
    }

    if scrollToRevealSelectionAfterLayout {
      let _ = LayoutStateDisabler(context: view().frameView().layoutContext())
      scrollToRevealSelection()
    }
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    if !selectElement().allowsNonContiguousSelection() {
      return super.addFocusRingRects(
        rects: &rects, additionalOffset: additionalOffset, paintContainer: paintContainer)
    }

    // Focus the last selected item.
    let selectedItem = selectElement().activeSelectionEndListIndex()
    if selectedItem >= 0 {
      rects.append(
        LayoutRectWrapper(
          rect: snappedIntRect(
            rect: itemBoundingBoxRect(additionalOffset: additionalOffset, index: selectedItem))))
      return
    }

    // No selected items, find the first non-disabled item.
    var indexOfFirstEnabledOption: Int32 = 0
    for item in selectElement().listItems() {
      if item is HTMLOptionElementWrapper && !item!.isDisabledFormControl() {
        selectElement().setActiveSelectionEndIndex(indexOfFirstEnabledOption)
        rects.append(
          itemBoundingBoxRect(additionalOffset: additionalOffset, index: indexOfFirstEnabledOption))
        return
      }
      indexOfFirstEnabledOption += 1
    }
  }

  override func verticalScrollbarWidth() -> Int32 {
    return verticalScrollbar()?.occupiedWidth() ?? 0
  }

  override func horizontalScrollbarHeight() -> Int32 {
    return horizontalScrollbar()?.occupiedHeight() ?? 0
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    if !super.nodeAtPoint(request, &result, locationInContainer, accumulatedOffset, hitTestAction) {
      return false
    }
    let listItems = selectElement().listItems()
    let size = numItems()
    let adjustedLocation = accumulatedOffset + location()

    for i in 0..<size {
      if !itemBoundingBoxRect(additionalOffset: adjustedLocation, index: i).contains(
        point: locationInContainer.point())
      {
        continue
      }
      if let node = listItems[Int(i)] {
        result.setInnerNode(node)
        if result.innerNonSharedNode() == nil {
          result.setInnerNonSharedNode(node)
        }
        result.localPoint = locationInContainer.point() - toLayoutSize(point: adjustedLocation)
        break
      }
    }

    return true
  }

  private func verticalScrollbar() -> Scrollbar? {
    if scrollbar != nil && scrollbar!.orientation() == .Vertical {
      return scrollbar
    }

    return nil
  }

  private func horizontalScrollbar() -> Scrollbar? {
    if scrollbar != nil && scrollbar!.orientation() == .Horizontal {
      return scrollbar
    }

    return nil
  }

  final override func useDarkAppearance() -> Bool {
    assert(isNativeImpl())
    return super.useDarkAppearance()
  }

  private func scrollToPosition(positionIndex: Int32) {
    let orientation = scrollbarOrientationForWritingMode()
    let scrollOrigin = self.scrollOrigin()

    var offsetIndex = positionIndex

    switch orientation {
    case .Vertical:
      offsetIndex = positionIndex + scrollOrigin.y
    case .Horizontal:
      offsetIndex = positionIndex + scrollOrigin.x
    }

    scrollToOffsetWithoutAnimation(orientation: orientation, offset: Float32(offsetIndex))
  }

  private func paintItem(
    _ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper,
    _ paintFunction: (PaintInfoWrapper, LayoutPointWrapper, Int32) -> Void
  ) {
    let listItemsSize = numItems()
    let firstVisibleItem = indexOfFirstVisibleItemInsidePaddingBeforeArea ?? indexOffset()
    let endIndex = firstVisibleItem + numVisibleItems(considerPadding: .Yes)
    for i in firstVisibleItem..<min(listItemsSize, endIndex) {
      paintFunction(paintInfo, paintOffset, i)
    }
  }

  private func setHasScrollbar(_ orientation: ScrollbarOrientation) {
    if verticalScrollbar() != nil && orientation == .Vertical {
      return
    }

    if horizontalScrollbar() != nil && orientation == .Horizontal {
      return
    }

    destroyScrollbar()
    scrollbar = createScrollbar(orientation)
    scrollbar!.styleChanged()
  }

  private func createScrollbar(_ orientation: ScrollbarOrientation) -> Scrollbar {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func destroyScrollbar() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func maximumNumberOfItemsThatFitInPaddingAfterArea() -> Int32 {
    assert(isNativeImpl())
    return (paddingAfter() / itemLogicalHeight()).int()
  }

  private func numberOfVisibleItemsInPaddingBefore() -> Int32 {
    assert(isNativeImpl())
    if indexOfFirstVisibleItemInsidePaddingBeforeArea == nil {
      return 0
    }

    return indexOffset() - indexOfFirstVisibleItemInsidePaddingBeforeArea!
  }

  private func numberOfVisibleItemsInPaddingAfter() -> Int32 {
    assert(isNativeImpl())
    if indexOfFirstVisibleItemInsidePaddingAfterArea == nil {
      return 0
    }

    return min(
      maximumNumberOfItemsThatFitInPaddingAfterArea(),
      numItems() - indexOffset() - numVisibleItems())
  }

  private func itemLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private enum ConsiderPadding {
    case No
    case Yes
  }

  private func numVisibleItems(considerPadding: ConsiderPadding = .No) -> Int32 {
    // Only count fully visible rows. But don't return 0 even if only part of a row shows.
    let visibleItemsExcludingPadding = max(
      LayoutUnit(value: 1), (contentLogicalHeight() + itemBlockSpacing) / itemLogicalHeight()
    ).int()
    if considerPadding == .No {
      return visibleItemsExcludingPadding
    }

    return numberOfVisibleItemsInPaddingBefore() + visibleItemsExcludingPadding
      + numberOfVisibleItemsInPaddingAfter()
  }

  private func numItems() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func rectForScrollbar(_ scrollbar: Scrollbar) -> LayoutRectWrapper {
    if scrollbar.orientation() == .Vertical {
      let left =
        shouldPlaceVerticalScrollbarOnLeft()
        ? borderLeft() : width() - borderRight() - scrollbar.width()
      let top = borderTop()
      let width = LayoutUnit(value: scrollbar.width())
      let height = height() - verticalBorderExtent()
      return LayoutRectWrapper(x: left, y: top, width: width, height: height)
    }

    let left: LayoutUnit = borderLeft()
    let top: LayoutUnit = height() - borderBottom() - scrollbar.height()
    let width: LayoutUnit = width() - horizontalBorderExtent()
    let height: LayoutUnit = LayoutUnit(value: scrollbar.height())
    return LayoutRectWrapper(x: left, y: top, width: width, height: height)
  }

  private func paintScrollbar(
    _ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper, _ scrollbar: Scrollbar
  ) {
    var scrollRect = rectForScrollbar(scrollbar)
    scrollRect.moveBy(offset: paintOffset)
    scrollbar.setFrameRect(snappedIntRect(rect: scrollRect))
    scrollbar.paint(paintInfo.context(), snappedIntRect(rect: paintInfo.rect))
  }

  private func paintItemForeground(
    _ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper, _ listIndex: Int32
  ) {
    let listItems = selectElement().listItems()
    let listItemElement = listItems[Int(listIndex)]!

    guard let itemStyle = listItemElement.computedStyleForEditability() else { return }

    if itemStyle.usedVisibility() == .Hidden {
      return
    }

    var itemText = StringWrapper()
    let optionElement = listItemElement as? HTMLOptionElementWrapper
    let optGroupElement = listItemElement as? HTMLOptGroupElementWrapper
    if optionElement != nil {
      itemText = optionElement!.textIndentedToRespectGroupLabel()
    } else if optGroupElement != nil {
      itemText = optGroupElement!.groupLabelText()
    }
    itemText = applyTextTransform(style(), itemText, UChar(Character(" ").asciiValue!))

    if itemText.isNull() {
      return
    }

    var textColor = itemStyle.visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyColor)
    if optionElement?.selected() ?? false {
      if frame().selection().isFocusedAndActive()
        && CPtrToInt(document().focusedElement()?.p) == CPtrToInt(selectElement().p)
      {
        textColor = theme().activeListBoxSelectionForegroundColor(styleColorOptions())
      }  // Honor the foreground color for disabled items
      else if !listItemElement.isDisabledFormControl() && !selectElement().isDisabledFormControl() {
        textColor = theme().inactiveListBoxSelectionForegroundColor(styleColorOptions())
      }
    }

    let _ = GraphicsContextStateSaver(context: paintInfo.context())

    paintInfo.context().setFillColor(color: textColor)

    let textRun = TextRunWrapper(
      text: itemText, xpos: 0, expansion: 0,
      expansionBehavior: ExpansionBehaviorWrapper.allowRightOnly(),
      direction: itemStyle.direction(), directionalOverride: isOverride(itemStyle.unicodeBidi()),
      characterScanForCodePath: true)
    var itemFont = style().fontCascade()
    var r = itemBoundingBoxRect(additionalOffset: paintOffset, index: listIndex)
    r.move(size: itemOffsetForAlignment(textRun, style(), itemStyle, itemFont, r))

    let isHorizontalWritingMode = style().isHorizontalWritingMode()
    if !isHorizontalWritingMode {
      let rotationOrigin = roundedIntPoint(point: r.maxXMinYCorner())
      paintInfo.context().translate(p: FloatPoint(p: rotationOrigin))
      paintInfo.context().rotate(piOverTwoFloat)
      paintInfo.context().translate(p: FloatPoint(p: -rotationOrigin))
    }

    if optGroupElement != nil {
      let description = itemFont.fontDescription()
      description.setWeight(description.bolderWeight())
      itemFont = FontCascadeWrapper(description, itemFont)
      itemFont.update(fontSelector: document().fontSelector())
    }

    // Draw the item text
    paintInfo.context().drawBidiText(
      font: itemFont, run: textRun,
      point: FloatPoint(
        p: roundedIntPoint(point: isHorizontalWritingMode ? r.location() : r.maxXMinYCorner())))
  }

  private func paintItemBackground(
    _ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper, _ listIndex: Int32
  ) {
    let listItems = selectElement().listItems()
    let listItemElement = listItems[Int(listIndex)]!
    guard let itemStyle = listItemElement.computedStyleForEditability() else { return }

    var backColor = ColorWrapper()
    if let option = listItemElement as? HTMLOptionElementWrapper, option.selected() {
      if frame().selection().isFocusedAndActive()
        && CPtrToInt(document().focusedElement()?.p) == CPtrToInt(selectElement().p)
      {
        backColor = theme().activeListBoxSelectionBackgroundColor(styleColorOptions())
      } else {
        backColor = theme().inactiveListBoxSelectionBackgroundColor(styleColorOptions())
      }
    } else {
      backColor = itemStyle.visitedDependentColorWithColorFilter(
        colorProperty: .CSSPropertyBackgroundColor)
    }

    // Draw the background for this list box item
    if itemStyle.usedVisibility() == .Hidden {
      return
    }

    var itemRect = itemBoundingBoxRect(additionalOffset: paintOffset, index: listIndex)
    itemRect.intersect(other: controlClipRect(additionalOffset: paintOffset))
    paintInfo.context().fillRect(
      rect: FloatRectWrapper(r: snappedIntRect(rect: itemRect)), color: backColor)
  }

  private func scrollToRevealSelection() {
    scrollToRevealSelectionAfterLayout = false

    let firstIndex = selectElement().activeSelectionStartListIndex()
    if firstIndex >= 0 && !listIndexIsVisible(index: selectElement().activeSelectionEndListIndex())
    {
      scrollToRevealElementAtListIndex(index: firstIndex)
    }
  }

  private func scrollbarOrientationForWritingMode() -> ScrollbarOrientation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldPlaceVerticalScrollbarOnLeft() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func indexOffset() -> Int32 {
    var scrollPosition = self.scrollPosition
    if !style().isHorizontalWritingMode() {
      scrollPosition = scrollPosition.transposedPoint()
    }
    return abs(scrollPosition.y)
  }

  private let optionsChanged = true
  private var scrollToRevealSelectionAfterLayout = false
  private let optionsLogicalWidth: Int32 = 0

  private var scrollbar: Scrollbar? = nil

  // Note: This is based on item index rather than a pixel offset.
  private var scrollPosition = ScrollPosition()

  private var indexOfFirstVisibleItemInsidePaddingBeforeArea: Int32? = nil
  private var indexOfFirstVisibleItemInsidePaddingAfterArea: Int32? = nil
}
