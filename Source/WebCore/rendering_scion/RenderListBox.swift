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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
      if item is HTMLOptionElementWrapper && !item.isDisabledFormControl() {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      indexOfFirstEnabledOption += 1
    }
  }

  override func verticalScrollbarWidth() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func horizontalScrollbarHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  final override func useDarkAppearance() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func numberOfVisibleItemsInPaddingBefore() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func numberOfVisibleItemsInPaddingAfter() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func paintScrollbar(
    _ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper, _ scrollbar: Scrollbar
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintItemForeground(
    _ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper, _ listIndex: Int32
  ) {
    let listItems = selectElement().listItems()
    let listItemElement = listItems[Int(listIndex)]

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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func indexOffset() -> Int32 {
    var scrollPosition = self.scrollPosition
    if !style().isHorizontalWritingMode() {
      scrollPosition = scrollPosition.transposedPoint()
    }
    return abs(scrollPosition.y)
  }

  private var scrollToRevealSelectionAfterLayout = false
  private let optionsLogicalWidth: Int32 = 0

  private let scrollbar: Scrollbar? = nil

  // Note: This is based on item index rather than a pixel offset.
  private var scrollPosition = ScrollPosition()
}
