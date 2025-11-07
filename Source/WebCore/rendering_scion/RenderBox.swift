/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
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
 *
 */

import wk_interop

enum AvailableLogicalHeightType {
  case ExcludeMarginBorderPadding
  case IncludeMarginBorderPadding
}

enum OverlayScrollbarSizeRelevancy {
  case IgnoreOverlayScrollbarSize
  case IncludeOverlayScrollbarSize
}

private func outermostBlockContainingFloatingObject(box: RenderBoxWrapper)
  -> RenderBlockFlowWrapper?
{
  assert(box.isFloating())
  var parentBlock: RenderBlockFlowWrapper? = nil
  for ancestor: RenderBlockFlowWrapper in ancestorsOfType(descendant: box) {
    if parentBlock == nil || ancestor.containsFloat(renderer: box) {
      parentBlock = ancestor
    }
  }
  return parentBlock
}

private func inlineSizeFromAspectRatio(
  borderPaddingInlineSum: LayoutUnit, borderPaddingBlockSum: LayoutUnit, aspectRatio: Float64,
  boxSizing: BoxSizing, blockSize: LayoutUnit, aspectRatioType: AspectRatioType,
  isRenderReplaced: Bool
) -> LayoutUnit {
  if boxSizing == .BorderBox && aspectRatioType == .Ratio && !isRenderReplaced {
    return max(borderPaddingInlineSum, LayoutUnit(value: blockSize * aspectRatio))
  }

  return LayoutUnit(value: (blockSize - borderPaddingBlockSum) * aspectRatio)
    + borderPaddingInlineSum
}

private func shouldFlipBeforeAfterMargins(
  containingBlockStyle: RenderStyleWrapper, childStyle: RenderStyleWrapper
) -> Bool {
  assert(containingBlockStyle.isHorizontalWritingMode() != childStyle.isHorizontalWritingMode())
  let childBlockFlowDirection = childStyle.blockFlowDirection()
  var shouldFlip = false
  switch containingBlockStyle.blockFlowDirection() {
  case .TopToBottom:
    shouldFlip = (childBlockFlowDirection == .RightToLeft)
  case .BottomToTop:
    shouldFlip = (childBlockFlowDirection == .RightToLeft)
  case .RightToLeft:
    shouldFlip = (childBlockFlowDirection == .BottomToTop)
  case .LeftToRight:
    shouldFlip = (childBlockFlowDirection == .BottomToTop)
  }

  if !containingBlockStyle.isLeftToRightDirection() {
    shouldFlip = !shouldFlip
  }

  return shouldFlip
}

private func isOrthogonal(renderer: RenderBoxWrapper, ancestor: RenderElementWrapper) -> Bool {
  return renderer.isHorizontalWritingMode() != ancestor.isHorizontalWritingMode()
}

private func tableCellShouldHaveZeroInitialSize(
  block: RenderBlockWrapper, child: RenderBoxWrapper, scrollsOverflowY: Bool
) -> Bool {
  // Normally we would let the cell size intrinsically, but scrolling overflow has to be
  // treated differently, since WinIE lets scrolled overflow fragments shrink as needed.
  // While we can't get all cases right, we can at least detect when the cell has a specified
  // height or when the table has a specified height. In these cases we want to initially have
  // no size and allow the flexing of the table or the cell to its specified height to cause us
  // to grow to fill the space. This could end up being wrong in some cases, but it is
  // preferable to the alternative (sizing intrinsically and making the row end up too big).
  let cell = block as! RenderTableCellWrapper
  return scrollsOverflowY && !child.shouldTreatChildAsReplacedInTableCells()
    && (!cell.style().logicalHeight().isAuto() || !cell.table()!.style().logicalHeight().isAuto())
}

private func allowMinMaxPercentagesInAutoHeightBlocksQuirk() -> Bool {
  return false
}

private func shouldFlipStaticPositionInParent(
  outOfFlowBox: RenderBoxWrapper, containerBlock: RenderBoxModelObjectWrapper
) -> Bool {
  assert(outOfFlowBox.isOutOfFlowPositioned())

  let parent = outOfFlowBox.parent()
  if parent == nil || CPtrToInt(parent!.p) == CPtrToInt(containerBlock.p)
    || parent is RenderBlockWrapper
  {
    return false
  }
  if parent is RenderGridWrapper {
    // FIXME: Out-of-flow grid item's static position computation is non-existent and enabling proper flipping
    // without implementing the logic in grid layout makes us fail a couple of WPT tests -we pass them now accidentally.
    return false
  }
  // FIXME: While this ensures flipping when parent is a writing root, computeBlockStaticDistance still does not
  // properly flip when the parent itself is not a writing root but an ancestor between this parent and out-of-flow's containing block.
  return parent!.style().isFlippedBlocksWritingMode() && parent!.isWritingModeRoot()
}

private func computeBlockStaticDistance(
  logicalTop: LengthWrapper, logicalBottom: LengthWrapper, child: RenderBoxWrapper?,
  containerBlock: RenderBoxModelObjectWrapper
) {
  if !logicalTop.isAuto() || !logicalBottom.isAuto() {
    return
  }

  let parent = child!.parent()!
  let haveOrthogonalWritingModes = isOrthogonal(renderer: child!, ancestor: parent)
  // The static positions from the child's layer are relative to the container block's coordinate space (which is determined
  // by the writing mode and text direction), meaning that for orthogonal flows the logical top of the child (which depends on
  // the child's writing mode) is retrieved from the static inline position instead of the static block position.
  var staticLogicalTop =
    haveOrthogonalWritingModes
    ? child!.layer()!.staticInlinePosition() : child!.layer()!.staticBlockPosition()
  if shouldFlipStaticPositionInParent(outOfFlowBox: child!, containerBlock: containerBlock) {
    // Note that at this point we can't resolve static top position completely in flipped case as at this point the height of the child box has not been computed yet.
    // What we can compute here is essentially the "bottom position".
    staticLogicalTop = (parent as! RenderBoxWrapper).flipForWritingMode(position: staticLogicalTop)
  }
  staticLogicalTop -=
    haveOrthogonalWritingModes ? containerBlock.borderLogicalLeft() : containerBlock.borderBefore()
  var container = child!.parent()
  while container != nil && CPtrToInt(container?.p) != CPtrToInt(containerBlock.p) {
    let renderBox = container as? RenderBoxWrapper
    if renderBox == nil {
      container = container!.container()
      continue
    }
    if !(renderBox is RenderTableRowWrapper) {
      staticLogicalTop +=
        haveOrthogonalWritingModes ? renderBox!.logicalLeft() : renderBox!.logicalTop()
    }
    if renderBox!.isInFlowPositioned() {
      staticLogicalTop +=
        renderBox!.isHorizontalWritingMode()
        ? renderBox!.offsetForInFlowPosition().height()
        : renderBox!.offsetForInFlowPosition().width()
    }
    container = container!.container()
  }

  // If the parent is RTL then we need to flip the coordinate by setting the logical bottom instead of the logical top. That only needs
  // to be done in case of orthogonal writing modes, for horizontal ones the text direction of the parent does not affect the block position.
  if haveOrthogonalWritingModes && parent.style().direction() != .LTR {
    logicalBottom.setValue(type: .Fixed, value: staticLogicalTop)
  } else {
    logicalTop.setValue(type: .Fixed, value: staticLogicalTop)
  }
}

// The |containerLogicalHeightForPositioned| is already aware of orthogonal flows.
// The logicalTop concept is confusing here. It's the logical top from the child's POV. This means that is the physical
// y if the child is vertical or the physical x if the child is horizontal.
private func computeLogicalTopPositionedOffset(
  logicalTopPos: inout LayoutUnit, child: RenderBoxWrapper, logicalHeightValue: LayoutUnit,
  containerBlock: RenderBoxModelObjectWrapper, containerLogicalHeightForPositioned: LayoutUnit,
  logicalTopIsAuto: Bool, logicalBottomIsAuto: Bool
) {
  let logicalTopAndBottomAreAuto = logicalTopIsAuto && logicalBottomIsAuto
  let haveOrthogonalWritingModes = isOrthogonal(renderer: child, ancestor: containerBlock)
  let haveFlippedBlockAxis =
    child.style().isFlippedBlocksWritingMode()
    != containerBlock.style().isFlippedBlocksWritingMode()
  let isOverconstrained =
    !logicalTopIsAuto && !logicalBottomIsAuto && !child.style().logicalHeight().isAuto()

  // Deal with differing writing modes here.  Our offset needs to be in the containing block's coordinate space. If the containing block is flipped
  // along this axis, then we need to flip the coordinate.  This can only happen if the containing block is both a flipped mode and perpendicular to us.
  if !isOverconstrained {
    if logicalTopIsAuto && logicalBottomIsAuto
      && shouldFlipStaticPositionInParent(outOfFlowBox: child, containerBlock: containerBlock)
    {
      // Let's finish computing static top postion inside parents with flipped writing mode now that we've got final height value.
      // see details in computeBlockStaticDistance.
      logicalTopPos -= logicalHeightValue
    }
    if (haveOrthogonalWritingModes && !logicalTopAndBottomAreAuto
      && child.style().isFlippedBlocksWritingMode())
      || (haveFlippedBlockAxis && !haveOrthogonalWritingModes)
    {
      logicalTopPos = containerLogicalHeightForPositioned - logicalHeightValue - logicalTopPos
    }
  }

  // Our offset is from the logical bottom edge in a flipped environment, e.g., right for vertical-rl and bottom for horizontal-bt.
  if containerBlock.style().isFlippedBlocksWritingMode() && !haveOrthogonalWritingModes {
    if child.isHorizontalWritingMode() {
      logicalTopPos += containerBlock.borderBottom()
    } else {
      logicalTopPos += containerBlock.borderRight()
    }
  } else {
    if child.isHorizontalWritingMode() {
      logicalTopPos += containerBlock.borderTop()
    } else {
      logicalTopPos += containerBlock.borderLeft()
    }
  }
}

private func shouldComputeLogicalWidthFromAspectRatioAndInsets(renderer: RenderBoxWrapper) -> Bool {
  if !renderer.isOutOfFlowPositioned() {
    return false
  }

  let style = renderer.style()
  if !style.logicalWidth().isAuto() {
    // Not applicable for aspect ratio computation.
    return false
  }
  // When both left and right are set, the out-of-flow positioned box is horizontally constrained and aspect ratio for the logical width is not applicable.
  let hasConstrainedWidth =
    (!style.logicalLeft().isAuto() && !style.logicalRight().isAuto())
    || renderer.intrinsicLogicalWidth().bool()
  if hasConstrainedWidth {
    return false
  }

  // When both top and bottom are set, the out-of-flow positioned box is vertically constrained and it can be used as if it had a non-auto height value.
  let hasConstrainedHeight = !style.logicalTop().isAuto() && !style.logicalBottom().isAuto()
  if !hasConstrainedHeight {
    return false
  }
  // FIXME: This could probably be omitted and let the callers handle the height check (as they seem to be doing anyway).
  return style.logicalHeight().isAuto()
}

enum StretchingMode {
  case `Any`
  case Explicit
}

class RenderBoxWrapper: RenderBoxModelObjectWrapper {
  func requiresLayerWithScrollableArea() -> Bool {
    // FIXME: This is wrong; these boxes' layers should not need ScrollableAreas via RenderLayer.
    if isRenderView() || isDocumentElementRenderer() {
      return true
    }

    if hasPotentiallyScrollableOverflow() {
      return true
    }

    if style().resize() != .None {
      return true
    }

    if isHTMLMarquee() && style().marqueeBehavior() != .None {
      return true
    }

    return false
  }

  func x() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func y() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func width() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func height() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalLeft() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_logicalLeft(p))
  }

  func logicalTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func constrainLogicalHeightByMinMax(
    logicalHeight: LayoutUnit, intrinsicContentHeight: LayoutUnit?
  ) -> LayoutUnit {
    let styleToUse = style()
    var computedLogicalMaxHeight: LayoutUnit? = nil
    if !styleToUse.logicalMaxHeight().isUndefined() {
      computedLogicalMaxHeight = computeLogicalHeightUsing(
        heightType: .MaxSize, height: styleToUse.logicalMaxHeight(),
        intrinsicContentHeight: intrinsicContentHeight)
    }

    var minimumSizeType: MinimumSizeIsAutomaticContentBased = .No
    var logicalMinHeight = styleToUse.logicalMinHeight()
    if logicalMinHeight.isAuto() && shouldComputeLogicalHeightFromAspectRatio()
      && intrinsicContentHeight != nil && !(self is RenderReplacedWrapper)
      && effectiveOverflowBlockDirection() == .Visible
    {
      var heightFromAspectRatio =
        RenderBoxWrapper.blockSizeFromAspectRatio(
          borderPaddingInlineSum: borderAndPaddingLogicalWidth(),
          borderPaddingBlockSum: borderAndPaddingLogicalHeight(),
          aspectRatio: style().logicalAspectRatio(), boxSizing: style().boxSizingForAspectRatio(),
          inlineSize: logicalWidth(),
          aspectRatioType: style().aspectRatioType(), isRenderReplaced: isRenderReplaced())
        - borderAndPaddingLogicalHeight()
      if firstChild() == nil {
        heightFromAspectRatio = max(heightFromAspectRatio, intrinsicContentHeight!)
      }
      logicalMinHeight = LengthWrapper(value: heightFromAspectRatio, type: .Fixed)
      minimumSizeType = .Yes
    }
    if logicalMinHeight.isMinContent() || logicalMinHeight.isMaxContent() {
      logicalMinHeight = LengthWrapper()
    }
    let computedLogicalMinHeight = computeLogicalHeightUsing(
      heightType: .MinSize, height: logicalMinHeight, intrinsicContentHeight: intrinsicContentHeight
    )
    var maxHeight = computedLogicalMaxHeight ?? LayoutUnit.max()
    var minHeight = computedLogicalMinHeight ?? LayoutUnit()
    if styleToUse.hasAspectRatio() {
      constrainLogicalMinMaxSizesByAspectRatio(
        computedMinSize: &minHeight, computedMaxSize: &maxHeight, computedSize: logicalHeight,
        minimumSizeType: minimumSizeType, dimension: .Height)
    }
    let logicalHeight = min(logicalHeight, maxHeight)
    return max(logicalHeight, minHeight)
  }

  func constrainContentBoxLogicalHeightByMinMax(
    logicalHeight: LayoutUnit, intrinsicContentHeight: LayoutUnit?
  ) -> LayoutUnit {
    // If the min/max height and logical height are both percentages we take advantage of already knowing the current resolved percentage height
    // to avoid recursing up through our containing blocks again to determine it.
    let styleToUse = style()
    var logicalHeight = logicalHeight
    if !styleToUse.logicalMaxHeight().isUndefined() {
      if styleToUse.logicalMaxHeight().isPercent() && styleToUse.logicalHeight().isPercent() {
        let availableLogicalHeight = logicalHeight / styleToUse.logicalHeight().value() * 100
        logicalHeight = min(
          logicalHeight,
          valueForLength(
            length: styleToUse.logicalMaxHeight(), maximumValue: availableLogicalHeight))
      } else if let maxH = computeContentLogicalHeight(
        heightType: .MaxSize, height: styleToUse.logicalMaxHeight(),
        intrinsicContentHeight: intrinsicContentHeight)
      {
        logicalHeight = min(logicalHeight, maxH)
      }
    }

    if styleToUse.logicalMinHeight().isPercent() && styleToUse.logicalHeight().isPercent() {
      let availableLogicalHeight = logicalHeight / styleToUse.logicalHeight().value() * 100
      logicalHeight = max(
        logicalHeight,
        valueForLength(length: styleToUse.logicalMinHeight(), maximumValue: availableLogicalHeight))
    } else if let computedContentLogicalHeight = computeContentLogicalHeight(
      heightType: .MinSize, height: styleToUse.logicalMinHeight(),
      intrinsicContentHeight: intrinsicContentHeight)
    {
      logicalHeight = max(logicalHeight, computedContentLogicalHeight)
    }
    return logicalHeight
  }

  func location() -> LayoutPointWrapper {
    let rawLocation = wk_interop.RenderBox_location(p)
    return LayoutPointWrapper(
      x: LayoutUnit.fromRawValue(value: rawLocation.x),
      y: LayoutUnit.fromRawValue(value: rawLocation.y))
  }

  func locationOffset() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLocation(p: LayoutPointWrapper) {
    wk_interop.RenderBox_setLocation(self.p, p.x.rawValue(), p.y.rawValue())
  }

  func move(dx: LayoutUnit, dy: LayoutUnit) {
    wk_interop.RenderBox_move(p, dx.rawValue(), dy.rawValue())
  }

  func frameRect() -> LayoutRectWrapper {
    let raw = wk_interop.RenderBox_frameRect(p)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  func borderBoxRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The content area of the box (excludes padding - and intrinsic padding for table cells, etc... - and border).
  func contentBoxRect() -> LayoutRectWrapper {
    var verticalScrollbarWidth = LayoutUnit(value: UInt64(0))
    var horizontalScrollbarHeight = LayoutUnit(value: UInt64(0))
    var leftScrollbarSpace = LayoutUnit(value: UInt64(0))
    var topScrollbarSpace = LayoutUnit(value: UInt64(0))

    if hasNonVisibleOverflow() {
      verticalScrollbarWidth = LayoutUnit(value: self.verticalScrollbarWidth())
      horizontalScrollbarHeight = LayoutUnit(value: self.horizontalScrollbarHeight())

      let bothEdgeScrollbarGutters = style().scrollbarGutter().bothEdges

      if shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() || bothEdgeScrollbarGutters {
        leftScrollbarSpace = verticalScrollbarWidth
      }
      // FIXME: It's wrong that scrollbar-gutter: both-edges affects height: webkit.org/b/266938
      if bothEdgeScrollbarGutters {
        topScrollbarSpace = horizontalScrollbarHeight
      }
    }

    let padding = self.padding()
    let borderWidths = self.borderWidths()
    let location = LayoutPointWrapper(
      x: borderWidths.left + padding.left + leftScrollbarSpace,
      y: borderWidths.top + padding.top + topScrollbarSpace)

    let zero = LayoutUnit(value: UInt64(0))
    let paddingBoxWidth = max(
      zero, width() - borderWidths.left - borderWidths.right - verticalScrollbarWidth)
    let paddingBoxHeight = max(
      zero, height() - borderWidths.top - borderWidths.bottom - horizontalScrollbarHeight)

    let width = max(zero, paddingBoxWidth - padding.left - padding.right - leftScrollbarSpace)
    let height = max(zero, paddingBoxHeight - padding.top - padding.bottom - topScrollbarSpace)

    let size = LayoutSizeWrapper(width: width, height: height)

    return LayoutRectWrapper(location: location, size: size)
  }

  // Note these functions are not equivalent of childrenOfType<RenderBox>
  func parentBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstChildBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSiblingBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutOverflowRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visualOverflowRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addLayoutOverflow(rect: LayoutRectWrapper) {
    wk_interop.RenderBox_addLayoutOverflow(
      p,
      LayoutRectRaw(
        x: rect.x().rawValue(),
        y: rect.y().rawValue(),
        width: rect.width().rawValue(),
        height: rect.height().rawValue()))
  }

  func addVisualOverflow(rect: LayoutRectWrapper) {
    wk_interop.RenderBox_addVisualOverflow(
      p,
      LayoutRectRaw(
        x: rect.x().rawValue(),
        y: rect.y().rawValue(),
        width: rect.width().rawValue(),
        height: rect.height().rawValue()))
  }

  func contentWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentWidth(p))
  }

  func contentHeight() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentHeight(p))
  }

  func contentLogicalSize() -> LayoutSizeWrapper {
    let width = LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentLogicalSize_width(p))
    let height = LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentLogicalSize_height(p))
    return LayoutSizeWrapper(width: width, height: height)
  }

  func contentLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingBoxWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxWidth(p))
  }

  func paddingBoxHeight() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxHeight(p))
  }

  func paddingBoxRectIncludingScrollbar() -> LayoutRectWrapper {
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_x(p)),
      y: LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_y(p)),
      width: LayoutUnit.fromRawValue(
        value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_width(p)),
      height: LayoutUnit.fromRawValue(
        value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_height(p))
    )
  }

  func clientLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clientLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func collapsedMarginBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func collapsedMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func constrainBlockMarginInAvailableSpaceOrTrim(
    containingBlock: RenderBoxWrapper, availableSpace: LayoutUnit, marginSide: MarginTrimType
  ) -> LayoutUnit {
    assert(marginSide == .BlockStart || marginSide == .BlockEnd)
    if containingBlock.shouldTrimChildMarginForBox(type: marginSide, child: self) {
      // FIXME(255434): This should be set when the margin is being trimmed
      // within the context of its layout system (block, flex, grid) and should not
      // be done at this level within RenderBox. We should be able to leave the
      // trimming responsibility to each of those contexts and not need to
      // do any of it here (trimming the margin and setting the rare data bit)
      if isGridItem() {
        markMarginAsTrimmed(newTrimmedMargin: marginSide)
      }
      return LayoutUnit(value: UInt64(0))
    }

    return marginSide == .BlockStart
      ? minimumValueForLength(
        length: style().marginBeforeUsing(otherStyle: containingBlock.style()),
        maximumValue: availableSpace)
      : minimumValueForLength(
        length: style().marginAfterUsing(otherStyle: containingBlock.style()),
        maximumValue: availableSpace)
  }

  func reflectionOffset() -> Int32 {
    if style().boxReflect() == nil {
      return 0
    }
    if style().boxReflect()!.direction() == .Left || style().boxReflect()!.direction() == .Right {
      return valueForLength(
        length: style().boxReflect()!.offset(), maximumValue: borderBoxRect().width()
      ).int()
    }
    return valueForLength(
      length: style().boxReflect()!.offset(), maximumValue: borderBoxRect().height()
    ).int()
  }

  // Given a rect in the object's coordinate space, returns the corresponding rect in the reflection.
  func reflectedRect(r: LayoutRectWrapper) -> LayoutRectWrapper {
    if style().boxReflect() == nil {
      return LayoutRectWrapper()
    }

    let box = borderBoxRect()
    var result = r
    switch style().boxReflect()!.direction() {
    case .Below:
      result.setY(y: box.maxY() + reflectionOffset() + (box.maxY() - r.maxY()))
    case .Above:
      result.setY(y: box.y() - reflectionOffset() - box.height() + (box.maxY() - r.maxY()))
    case .Left:
      result.setX(x: box.x() - reflectionOffset() - box.width() + (box.maxX() - r.maxX()))
    case .Right:
      result.setX(x: box.maxX() + reflectionOffset() + (box.maxX() - r.maxX()))
      break
    }
    return result
  }

  func computeIntrinsicLogicalWidths() -> (LayoutUnit, LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingLogicalHeight() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContentLogicalHeight(overridingLogicalHeight: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  typealias ContainingBlockOverrideValue = LayoutUnit?

  func overridingContainingBlockContentLogicalWidth() -> ContainingBlockOverrideValue? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContainingBlockContentLogicalHeight() -> ContainingBlockOverrideValue? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // These are currently only used by Flexbox code. In some cases we must layout flex items with a different main size
  // (the size in the main direction) than the one specified by the item in order to compute the value of flex basis, i.e.,
  // the initial main size of the flex item before the free space is distributed.
  func overridingLogicalHeightLength() -> LengthWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalWidthLength(height: LengthWrapper) {
    wk_interop.RenderBox_setOverridingLogicalWidthLength(p, height.p)
  }

  func clearOverridingLogicalWidthLength() {
    wk_interop.RenderBox_clearOverridingLogicalWidthLength(p)
  }

  private func markMarginAsTrimmed(newTrimmedMargin: MarginTrimType) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func adjustBorderBoxLogicalWidthForBoxSizing(
    computedLogicalWidth: LayoutUnit, originalType: LengthType
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func adjustBorderBoxLogicalWidthForBoxSizing(
    computedLogicalWidth: Int32, originalType: LengthType
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Overridden by fieldsets to subtract out the intrinsic border.
  func adjustBorderBoxLogicalHeightForBoxSizing(height: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustContentBoxLogicalHeightForBoxSizing(height: LayoutUnit?) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustIntrinsicLogicalHeightForBoxSizing(height: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct ComputedMarginValues {
    var before = LayoutUnit()
    var after = LayoutUnit()
    let start = LayoutUnit()
    let end = LayoutUnit()
  }

  struct LogicalExtentComputedValues {
    init(extent: LayoutUnit = LayoutUnit(), position: LayoutUnit = LayoutUnit()) {
      self.extent = extent
      self.position = position
    }

    var extent: LayoutUnit
    var position: LayoutUnit
    var margins = ComputedMarginValues()
  }

  // Resolve auto margins in the inline direction of the containing block so that objects can be pushed to the start, middle or end
  // of the containing block.
  func computeInlineDirectionMargins(
    containingBlock: RenderBlockWrapper, containerWidth: LayoutUnit,
    availableSpaceAdjustedWithFloats: LayoutUnit?, childWidth: LayoutUnit,
    marginStart: inout LayoutUnit, marginEnd: inout LayoutUnit
  ) {
    let containingBlockStyle = containingBlock.style()
    var marginStartLength = style().marginStartUsing(otherStyle: containingBlockStyle)
    var marginEndLength = style().marginEndUsing(otherStyle: containingBlockStyle)

    if isFloating() {
      marginStart = minimumValueForLength(length: marginStartLength, maximumValue: containerWidth)
      marginEnd = minimumValueForLength(length: marginEndLength, maximumValue: containerWidth)
      return
    }

    if isInline() {
      // Inline blocks/tables don't have their margins increased.
      marginStart = computeOrTrimInlineMargin(
        containingBlock: containingBlock, marginSide: .InlineStart,
        computeInlineMargin: {
          return minimumValueForLength(length: marginStartLength, maximumValue: containerWidth)
        })
      marginEnd = computeOrTrimInlineMargin(
        containingBlock: containingBlock, marginSide: .InlineStart,
        computeInlineMargin: {
          return minimumValueForLength(length: marginEndLength, maximumValue: containerWidth)
        })
      return
    }

    if containingBlock is RenderFlexibleBoxWrapper {
      // We need to let flexbox handle the margin adjustment - otherwise, flexbox
      // will think we're wider than we actually are and calculate line sizes
      // wrong. See also http://dev.w3.org/csswg/css-flexbox/#auto-margins
      if marginStartLength.isAuto() {
        marginStartLength = LengthWrapper(value: Int32(0), type: .Fixed)
      }
      if marginEndLength.isAuto() {
        marginEndLength = LengthWrapper(value: Int32(0), type: .Fixed)
      }
    }

    if handleMarginAuto(
      containingBlock: containingBlock, containerWidth: containerWidth,
      availableSpaceAdjustedWithFloats: availableSpaceAdjustedWithFloats, childWidth: childWidth,
      marginStart: &marginStart, marginEnd: &marginEnd, containingBlockStyle: containingBlockStyle,
      marginStartLength: marginStartLength, marginEndLength: marginEndLength)
    {
      return
    }

    // Case Four: Either no auto margins, or our width is >= the container width (css2.1, 10.3.3). In that case
    // auto margins will just turn into 0.
    marginStart = computeOrTrimInlineMargin(
      containingBlock: containingBlock, marginSide: .InlineStart,
      computeInlineMargin: {
        return minimumValueForLength(length: marginStartLength, maximumValue: containerWidth)
      })
    marginEnd = computeOrTrimInlineMargin(
      containingBlock: containingBlock, marginSide: .InlineEnd,
      computeInlineMargin: {
        return minimumValueForLength(length: marginEndLength, maximumValue: containerWidth)
      })
  }

  private func handleMarginAuto(
    containingBlock: RenderBlockWrapper, containerWidth: LayoutUnit,
    availableSpaceAdjustedWithFloats: LayoutUnit?,
    childWidth: LayoutUnit, marginStart: inout LayoutUnit, marginEnd: inout LayoutUnit,
    containingBlockStyle: RenderStyleWrapper, marginStartLength: LengthWrapper,
    marginEndLength: LengthWrapper
  ) -> Bool {
    let containerWidthForMarginAuto = availableSpaceAdjustedWithFloats ?? containerWidth
    // Case One: The object is being centered in the containing block's available logical width.
    let marginAutoCenter =
      marginStartLength.isAuto() && marginEndLength.isAuto()
      && childWidth < containerWidthForMarginAuto
    let alignModeCenter =
      containingBlock.style().textAlign() == .WebKitCenter && !marginStartLength.isAuto()
      && !marginEndLength.isAuto()
    if marginAutoCenter || alignModeCenter {
      // Other browsers center the margin box for align=center elements so we match them here.
      marginStart = computeOrTrimInlineMargin(
        containingBlock: containingBlock, marginSide: .InlineStart,
        computeInlineMargin: {
          let marginStartWidth = minimumValueForLength(
            length: marginStartLength, maximumValue: containerWidthForMarginAuto)
          let marginEndWidth = minimumValueForLength(
            length: marginEndLength, maximumValue: containerWidthForMarginAuto)
          let centeredMarginBoxStart = max(
            LayoutUnit(value: 0),
            (containerWidthForMarginAuto - childWidth - marginStartWidth - marginEndWidth) / 2)
          return centeredMarginBoxStart + marginStartWidth
        })
      marginEnd = computeOrTrimInlineMargin(
        containingBlock: containingBlock, marginSide: .InlineEnd,
        computeInlineMargin: {
          let marginEndWidth = minimumValueForLength(
            length: marginEndLength, maximumValue: containerWidthForMarginAuto)
          return containerWidthForMarginAuto - childWidth - marginStart + marginEndWidth
        })
      return true
    }

    // Case Two: The object is being pushed to the start of the containing block's available logical width.
    if marginEndLength.isAuto() && childWidth < containerWidthForMarginAuto {
      marginStart = valueForLength(
        length: marginStartLength, maximumValue: containerWidthForMarginAuto)
      marginEnd = containerWidthForMarginAuto - childWidth - marginStart
      return true
    }

    // Case Three: The object is being pushed to the end of the containing block's available logical width.
    let pushToEndFromTextAlign =
      !marginEndLength.isAuto()
      && ((!containingBlockStyle.isLeftToRightDirection()
        && containingBlockStyle.textAlign() == .WebKitLeft)
        || (containingBlockStyle.isLeftToRightDirection()
          && containingBlockStyle.textAlign() == .WebKitRight))
    if (marginStartLength.isAuto() || pushToEndFromTextAlign)
      && childWidth < containerWidthForMarginAuto
    {
      marginEnd = computeOrTrimInlineMargin(
        containingBlock: containingBlock, marginSide: .InlineEnd,
        computeInlineMargin: {
          return valueForLength(length: marginEndLength, maximumValue: containerWidthForMarginAuto)
        })
      marginStart = computeOrTrimInlineMargin(
        containingBlock: containingBlock, marginSide: .InlineStart,
        computeInlineMargin: {
          return containerWidthForMarginAuto - childWidth - marginEnd
        })
      return true
    }
    return false
  }

  // Used to resolve margins in the containing block's block-flow direction.
  func computeBlockDirectionMargins(
    containingBlock: RenderBlockWrapper, marginBefore: inout LayoutUnit,
    marginAfter: inout LayoutUnit
  ) {
    // First assert that we're not calling this method on box types that don't support margins.
    assert(!isRenderTableCell())
    assert(!isRenderTableRow())
    assert(!isRenderTableSection())
    assert(!isRenderTableCol())

    // Margins are calculated with respect to the logical width of
    // the containing block (8.3)
    let cw = containingBlockLogicalWidthForContent()
    marginBefore = constrainBlockMarginInAvailableSpaceOrTrim(
      containingBlock: containingBlock, availableSpace: cw, marginSide: .BlockStart)
    marginAfter = constrainBlockMarginInAvailableSpaceOrTrim(
      containingBlock: containingBlock, availableSpace: cw, marginSide: .BlockEnd)
  }

  enum RenderBoxFragmentInfoFlags {
    case CacheRenderBoxFragmentInfo
    case DoNotCacheRenderBoxFragmentInfo
  }

  func borderBoxRectInFragment(
    fragment: RenderFragmentContainerWrapper?,
    flags: RenderBoxWrapper.RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clampToStartAndEndFragments(fragment: RenderFragmentContainerWrapper?)
    -> RenderFragmentContainerWrapper?
  {
    let fragmentedFlow = enclosingFragmentedFlow()

    assert(isRenderView() || (fragment != nil && fragmentedFlow != nil))
    if isRenderView() {
      return fragment
    }

    // We need to clamp to the block, since we want any lines or blocks that overflow out of the
    // logical top or logical bottom of the block to size as though the border box in the first and
    // last fragments extended infinitely. Otherwise the lines are going to size according to the fragments
    // they overflow into, which makes no sense when this block doesn't exist in |fragment| at all.
    if let (startFragment, endFragment) = fragmentedFlow!.getFragmentRangeForBox(box: self) {
      if fragment!.logicalTopForFragmentedFlowContent()
        < startFragment.logicalTopForFragmentedFlowContent()
      {
        return startFragment
      }
      if fragment!.logicalTopForFragmentedFlowContent()
        > endFragment.logicalTopForFragmentedFlowContent()
      {
        return endFragment
      }
    }

    return fragment
  }

  func offsetFromLogicalTopOfFirstPage() -> LayoutUnit {
    let layoutState = view().frameView().layoutContext().layoutState()
    if (layoutState != nil && !layoutState!.isPaginated())
      || (layoutState == nil && enclosingFragmentedFlow() == nil)
    {
      return LayoutUnit(value: 0)
    }

    let containerBlock = containingBlock()!
    return containerBlock.offsetFromLogicalTopOfFirstPage() + logicalTop()
  }

  func repaintDuringLayoutIfMoved(oldRect: LayoutRectWrapper) {
    wk_interop.RenderBox_repaintDuringLayoutIfMoved(
      p,
      LayoutRectRaw(
        x: oldRect.x().rawValue(),
        y: oldRect.y().rawValue(),
        width: oldRect.width().rawValue(),
        height: oldRect.height().rawValue()))
  }

  override func containingBlockLogicalWidthForContent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func containingBlockLogicalHeightForContent(heightType: AvailableLogicalHeightType)
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func containingBlockLogicalWidthForPositioned(
    containingBlock: RenderBoxModelObjectWrapper, fragment: RenderFragmentContainerWrapper? = nil,
    checkForPerpendicularWritingMode: Bool = true
  ) -> LayoutUnit {
    assert(
      containingBlock.canContainAbsolutelyPositionedObjects()
        || containingBlock.canContainFixedPositionObjects())

    if checkForPerpendicularWritingMode
      && containingBlock.isHorizontalWritingMode() != isHorizontalWritingMode()
    {
      return containingBlockLogicalHeightForPositioned(
        containingBlock: containingBlock, checkForPerpendicularWritingMode: false)
    }

    if let overridingContainingBlockContentLogicalWidth =
      overridingContainingBlockContentLogicalWidth(),
      let value = overridingContainingBlockContentLogicalWidth
    {
      return value
    }

    if let box = containingBlock as? RenderBoxWrapper {
      let isFixedPosition = isFixedPositioned()

      let fragmentedFlow = enclosingFragmentedFlow()
      if fragmentedFlow == nil {
        if isFixedPosition, let renderView = containingBlock as? RenderViewWrapper {
          return renderView.clientLogicalWidthForFixedPosition()
        }
        return (containingBlock as! RenderBoxWrapper).clientLogicalWidth()
      }

      let cb = containingBlock as? RenderBlockWrapper
      if cb == nil {
        return box.clientLogicalWidth()
      }

      var boxInfo: RenderBoxFragmentInfo? = nil
      if fragment == nil {
        if let fragmentedFlow = containingBlock as? RenderFragmentedFlowWrapper,
          !checkForPerpendicularWritingMode
        {
          return fragmentedFlow.contentLogicalWidthOfFirstFragment()
        }
        if isWritingModeRoot() {
          let cbPageOffset = cb!.offsetFromLogicalTopOfFirstPage()
          if let cbFragment = cb!.fragmentAtBlockOffset(blockOffset: cbPageOffset) {
            boxInfo = cb!.renderBoxFragmentInfo(fragment: cbFragment)
          }
        }
      } else if fragmentedFlow!.isHorizontalWritingMode()
        == containingBlock.isHorizontalWritingMode()
      {
        let containingBlockFragment = cb!.clampToStartAndEndFragments(fragment: fragment)
        boxInfo = cb!.renderBoxFragmentInfo(fragment: containingBlockFragment)
      }
      return boxInfo != nil
        ? max(
          LayoutUnit(value: 0),
          cb!.clientLogicalWidth() - (cb!.logicalWidth() - boxInfo!.logicalWidth))
        : cb!.clientLogicalWidth()
    }

    if let inlineBox = containingBlock as? RenderInlineWrapper {
      return inlineBox.innerPaddingBoxWidth()
    }

    fatalError("Not reached")
  }

  private func containingBlockLogicalHeightForPositioned(
    containingBlock: RenderBoxModelObjectWrapper, checkForPerpendicularWritingMode: Bool = true
  ) -> LayoutUnit {
    assert(
      containingBlock.canContainAbsolutelyPositionedObjects()
        || containingBlock.canContainFixedPositionObjects())

    if checkForPerpendicularWritingMode
      && containingBlock.isHorizontalWritingMode() != isHorizontalWritingMode()
    {
      return containingBlockLogicalWidthForPositioned(
        containingBlock: containingBlock, fragment: nil, checkForPerpendicularWritingMode: false)
    }

    if let overridingContainingBlockContentLogicalHeight =
      overridingContainingBlockContentLogicalHeight(),
      let value = overridingContainingBlockContentLogicalHeight
    {
      return value
    }

    if let box = containingBlock as? RenderBoxWrapper {
      let isFixedPosition = isFixedPositioned()

      if isFixedPosition, let renderView = box as? RenderViewWrapper {
        return renderView.clientLogicalHeightForFixedPosition()
      }

      let containingBlockAsRenderBlock = box as? RenderBlockWrapper
      let cb =
        containingBlockAsRenderBlock != nil ? containingBlockAsRenderBlock! : box.containingBlock()!
      let result = cb.clientLogicalHeight()
      if let fragmentedFlow = enclosingFragmentedFlow(),
        fragmentedFlow.isHorizontalWritingMode() == containingBlock.isHorizontalWritingMode(),
        let containingBlockFragmentedFlow = containingBlock as? RenderFragmentedFlowWrapper
      {
        return containingBlockFragmentedFlow.contentLogicalHeightOfFirstFragment()
      }
      return result
    }

    if let inlineBox = containingBlock as? RenderInlineWrapper {
      return inlineBox.innerPaddingBoxHeight()
    }

    fatalError("Not reached")
  }

  func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    var computedValues = LogicalExtentComputedValues(extent: logicalHeight, position: logicalTop)

    // Cell height is managed by the table and inline non-replaced elements do not support a height property.
    if isRenderTableCell() || (isInline() && !isReplacedOrInlineBlock()) {
      return computedValues
    }

    var h = LengthWrapper()
    if isOutOfFlowPositioned() {
      computePositionedLogicalHeight(computedValues: &computedValues)
    } else {
      let cb = containingBlock()!
      let hasPerpendicularContainingBlock =
        cb.isHorizontalWritingMode() != isHorizontalWritingMode()

      if !hasPerpendicularContainingBlock {
        let shouldFlipBeforeAfter = cb.style().writingMode() != style().writingMode()
        if shouldFlipBeforeAfter {
          computeBlockDirectionMargins(
            containingBlock: cb,
            marginBefore: &computedValues.margins.after,
            marginAfter: &computedValues.margins.before)
        } else {
          computeBlockDirectionMargins(
            containingBlock: cb,
            marginBefore: &computedValues.margins.before,
            marginAfter: &computedValues.margins.after)
        }
      }

      // For tables, calculate margins only.
      if isRenderTable() {
        if shouldComputeLogicalHeightFromAspectRatio() {
          computedValues.extent = RenderBoxWrapper.blockSizeFromAspectRatio(
            borderPaddingInlineSum: horizontalBorderAndPaddingExtent(),
            borderPaddingBlockSum: verticalBorderAndPaddingExtent(),
            aspectRatio: style().logicalAspectRatio(), boxSizing: style().boxSizingForAspectRatio(),
            inlineSize: logicalWidth(),
            aspectRatioType: style().aspectRatioType(), isRenderReplaced: isRenderReplaced())
        }
        if hasPerpendicularContainingBlock {
          let shouldFlipBeforeAfter = shouldFlipBeforeAfterMargins(
            containingBlockStyle: cb.style(), childStyle: style())
          if shouldFlipBeforeAfter {
            computeInlineDirectionMargins(
              containingBlock: cb, containerWidth: containingBlockLogicalWidthForContent(),
              availableSpaceAdjustedWithFloats: nil, childWidth: computedValues.extent,
              marginStart: &computedValues.margins.after, marginEnd: &computedValues.margins.before)
          } else {
            computeInlineDirectionMargins(
              containingBlock: cb, containerWidth: containingBlockLogicalWidthForContent(),
              availableSpaceAdjustedWithFloats: nil, childWidth: computedValues.extent,
              marginStart: &computedValues.margins.before, marginEnd: &computedValues.margins.after)
          }
        }
        return computedValues
      }

      // FIXME: Account for block-flow in flexible boxes.
      // https://bugs.webkit.org/show_bug.cgi?id=46418
      let inHorizontalBox =
        parent()!.isRenderDeprecatedFlexibleBox() && parent()!.style().boxOrient() == .Horizontal
      let stretching = parent()!.style().boxAlign() == .Stretch
      let treatAsReplaced = shouldComputeSizeAsReplaced() && (!inHorizontalBox || !stretching)
      var checkMinMaxHeight = false

      // The parent box is flexing us, so it has increased or decreased our height.  We have to
      // grab our cached flexible height.
      // FIXME: Account for block-flow in flexible boxes.
      // https://bugs.webkit.org/show_bug.cgi?id=46418
      if let overridingLogicalHeightForFlexOrGrid =
        (parent()!.isFlexibleBoxIncludingDeprecated() || parent()!.isRenderGrid()
          ? overridingLogicalHeight() : nil)
      {
        h = LengthWrapper(value: overridingLogicalHeightForFlexOrGrid, type: .Fixed)
      } else if treatAsReplaced {
        h = LengthWrapper(
          value: computeReplacedLogicalHeight() + borderAndPaddingLogicalHeight(), type: .Fixed)
      } else {
        h = overridingLogicalHeightLength() ?? style().logicalHeight()
        checkMinMaxHeight = true
      }

      // Block children of horizontal flexible boxes fill the height of the box.
      // FIXME: Account for block-flow in flexible boxes.
      // https://bugs.webkit.org/show_bug.cgi?id=46418
      if h.isAuto() && (parent() is RenderDeprecatedFlexibleBoxWrapper)
        && parent()!.style().boxOrient() == .Horizontal
        && (parent() as! RenderDeprecatedFlexibleBoxWrapper).isStretchingChildren()
      {
        h = LengthWrapper(
          value: parentBox()!.contentLogicalHeight() - marginBefore() - marginAfter(), type: .Fixed)
        checkMinMaxHeight = false
      }

      var heightResult = LayoutUnit()
      if checkMinMaxHeight {
        // Callers passing LayoutUnit::max() for logicalHeight means an indefinite height, so
        // translate this to a nullopt intrinsic height for further logical height computations.
        var intrinsicHeight: LayoutUnit? = nil
        if computedValues.extent != LayoutUnit.max() {
          intrinsicHeight = computedValues.extent
        }
        if shouldComputeLogicalHeightFromAspectRatio() {
          if intrinsicHeight != nil && style().boxSizing() == .ContentBox {
            intrinsicHeight! -=
              boxBorderBefore() + boxPaddingBefore() + boxBorderAfter() + boxPaddingAfter()
          }
          heightResult = RenderBoxWrapper.blockSizeFromAspectRatio(
            borderPaddingInlineSum: horizontalBorderAndPaddingExtent(),
            borderPaddingBlockSum: verticalBorderAndPaddingExtent(),
            aspectRatio: style().logicalAspectRatio(), boxSizing: style().boxSizingForAspectRatio(),
            inlineSize: logicalWidth(),
            aspectRatioType: style().aspectRatioType(), isRenderReplaced: isRenderReplaced())
        } else {
          if intrinsicHeight != nil {
            intrinsicHeight! -= borderAndPaddingLogicalHeight()
          }
          heightResult =
            computeLogicalHeightUsing(
              heightType: .MainOrPreferredSize, height: h, intrinsicContentHeight: intrinsicHeight)
            ?? computedValues.extent
        }
        heightResult = constrainLogicalHeightByMinMax(
          logicalHeight: heightResult, intrinsicContentHeight: intrinsicHeight)
      } else {
        assert(h.isFixed())
        heightResult = LayoutUnit(value: h.value())
      }

      computedValues.extent = heightResult

      if hasPerpendicularContainingBlock {
        let shouldFlipBeforeAfter = shouldFlipBeforeAfterMargins(
          containingBlockStyle: cb.style(), childStyle: style())
        if shouldFlipBeforeAfter {
          computeInlineDirectionMargins(
            containingBlock: cb, containerWidth: containingBlockLogicalWidthForContent(),
            availableSpaceAdjustedWithFloats: nil, childWidth: heightResult,
            marginStart: &computedValues.margins.after,
            marginEnd: &computedValues.margins.before)
        } else {
          computeInlineDirectionMargins(
            containingBlock: cb, containerWidth: containingBlockLogicalWidthForContent(),
            availableSpaceAdjustedWithFloats: nil, childWidth: heightResult,
            marginStart: &computedValues.margins.before,
            marginEnd: &computedValues.margins.after)
        }
      }
    }

    // WinIE quirk: The <html> block always fills the entire canvas in quirks mode. The <body> always fills the
    // <html> block in quirks mode. Only apply this quirk if the block is normal flow and no height
    // is specified. When we're printing, we also need this quirk if the body or root has a percentage
    // height since we don't set a height in RenderView when we're printing. So without this quirk, the
    // height has nothing to be a percentage of, and it ends up being 0. That is bad.
    if stretchesToViewport() || paginatedContentNeedsBaseHeight(h: h) {
      let margins = collapsedMarginBefore() + collapsedMarginAfter()
      let visibleHeight = view().pageOrViewLogicalHeight()
      if isDocumentElementRenderer() {
        computedValues.extent = max(computedValues.extent, visibleHeight - margins)
      } else {
        let marginsBordersPadding =
          margins + parentBox()!.marginBefore() + parentBox()!.marginAfter()
          + parentBox()!.borderAndPaddingLogicalHeight()
        computedValues.extent = max(computedValues.extent, visibleHeight - marginsBordersPadding)
      }
    }
    return computedValues
  }

  private func paginatedContentNeedsBaseHeight(h: LengthWrapper) -> Bool {
    if !document().printing() || !h.isPercentOrCalculated() || isInline() {
      return false
    }
    if isDocumentElementRenderer() {
      return true
    }
    let documentElementRenderer = document().documentElement()!.renderer()
    return isBody() && CPtrToInt(parent()?.p) == CPtrToInt(documentElementRenderer?.p)
      && documentElementRenderer!.style().logicalHeight().isPercentOrCalculated()
  }

  private func boxBorderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func boxBorderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func boxPaddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func boxPaddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func renderBoxFragmentInfo(
    fragment: RenderFragmentContainerWrapper?,
    cacheFlag: RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> RenderBoxFragmentInfo? {
    // Make sure nobody is trying to call this with a null fragment.
    if fragment == nil {
      return nil
    }

    // If we have computed our width in this fragment already, it will be cached, and we can
    // just return it.
    if let boxInfo = fragment!.renderBoxFragmentInfo(box: self),
      cacheFlag == .CacheRenderBoxFragmentInfo
    {
      return boxInfo
    }

    return nil
  }

  private func stretchesToViewport() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intrinsicLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func intrinsicLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Whether or not the element shrinks to its intrinsic width (rather than filling the width
  // of a containing block).  HTML4 buttons, <select>s, <input>s, legends, and floating/compact elements do this.
  enum SizeType {
    case MainOrPreferredSize
    case MinSize
    case MaxSize
  }
  private func sizesLogicalWidthToFitContent(widthType: SizeType) -> Bool {
    // Marquees in WinIE are like a mixture of blocks and inline-blocks.  They size as though they're blocks,
    // but they allow text to sit on the same line as the marquee.
    if isFloating() || (isInlineBlockOrInlineTable() && !isHTMLMarquee()) {
      return true
    }

    if isGridItem() {
      return (parent() as! RenderGridWrapper).areMasonryColumns() || !hasStretchedLogicalWidth()
    }

    // This code may look a bit strange.  Basically width:intrinsic should clamp the size when testing both
    // min-width and width.  max-width is only clamped if it is also intrinsic.
    let logicalWidth = (widthType == .MaxSize) ? style().logicalMaxWidth() : style().logicalWidth()
    if logicalWidth.type() == .Intrinsic {
      return true
    }

    // Children of a horizontal marquee do not fill the container by default.
    // FIXME: Need to deal with MarqueeDirection::Auto value properly. It could be vertical.
    // FIXME: Think about block-flow here.  Need to find out how marquee direction relates to
    // block-flow (as well as how marquee overflow should relate to block flow).
    // https://bugs.webkit.org/show_bug.cgi?id=46472
    if parent()!.isHTMLMarquee() {
      let dir = parent()!.style().marqueeDirection()
      if dir == .Auto || dir == .Forward || dir == .Backward || dir == .Left || dir == .Right {
        return true
      }
    }

    // Flexible box items should shrink wrap, so we lay them out at their intrinsic widths.
    // In the case of columns that have a stretch alignment, we layout at the stretched size
    // to avoid an extra layout when applying alignment.
    if parent() is RenderFlexibleBoxWrapper {
      // For multiline columns, we need to apply align-content first, so we can't stretch now.
      if !parent()!.style().isColumnFlexDirection() || parent()!.style().flexWrap() != .NoWrap {
        return true
      }
      if !columnFlexItemHasStretchAlignment() {
        return true
      }
    }

    // Flexible horizontal boxes lay out children at their intrinsic widths.  Also vertical boxes
    // that don't stretch their kids lay out their children at their intrinsic widths.
    // FIXME: Think about block-flow here.
    // https://bugs.webkit.org/show_bug.cgi?id=46473
    if parent()!.isRenderDeprecatedFlexibleBox()
      && (parent()!.style().boxOrient() == .Horizontal || parent()!.style().boxAlign() != .Stretch)
    {
      return true
    }

    // Button, input, select, textarea, and legend treat width value of 'auto' as 'intrinsic' unless it's in a
    // stretching column flexbox.
    // FIXME: Think about block-flow here.
    // https://bugs.webkit.org/show_bug.cgi?id=46473
    if logicalWidth.isAuto() && !isStretchingColumnFlexItem() && element() != nil
      && (element() is HTMLInputElementWrapper || element() is HTMLSelectElementWrapper
        || element() is HTMLButtonElementWrapper || element() is HTMLTextAreaElementWrapper
        || element() is HTMLLegendElementWrapper)
    {
      return true
    }

    if isHorizontalWritingMode() != containingBlock()!.isHorizontalWritingMode() {
      return true
    }

    return false
  }

  // FIXME: Can/Should we move this inside specific layout classes (flex. grid)? Can we refactor columnFlexItemHasStretchAlignment logic?
  func hasStretchedLogicalHeight() -> Bool {
    let style = style()
    if !style.logicalHeight().isAuto() || style.marginBefore().isAuto()
      || style.marginAfter().isAuto()
    {
      return false
    }
    let containingBlock = containingBlock()
    if containingBlock == nil {
      // We are evaluating align-self/justify-self, which default to 'normal' for the root element.
      // The 'normal' value behaves like 'start' except for Flexbox Items, which obviously should have a container.
      return false
    }
    if containingBlock!.isHorizontalWritingMode() != isHorizontalWritingMode() {
      if let grid = self as? RenderGridWrapper,
        grid.isSubgridInParentDirection(parentDirection: .ForColumns)
      {
        return true
      }
      return style.resolvedJustifySelf(
        parentStyle: containingBlock!.style(),
        normalValueBehaviour: containingBlock!.selfAlignmentNormalBehavior(gridItem: self)
      ).position == .Stretch
    }
    if let grid = self as? RenderGridWrapper,
      grid.isSubgridInParentDirection(parentDirection: .ForRows)
    {
      return true
    }
    return style.resolvedAlignSelf(
      parentStyle: containingBlock!.style(),
      normalValueBehaviour: containingBlock!.selfAlignmentNormalBehavior(gridItem: self)
    ).position == .Stretch
  }

  // FIXME: Can/Should we move this inside specific layout classes (flex. grid)? Can we refactor columnFlexItemHasStretchAlignment logic?
  private func hasStretchedLogicalWidth(stretchingMode: StretchingMode = .`Any`) -> Bool {
    let style = style()
    if !style.logicalWidth().isAuto() || style.marginStart().isAuto() || style.marginEnd().isAuto()
    {
      return false
    }
    let containingBlock = containingBlock()
    if containingBlock == nil {
      // We are evaluating align-self/justify-self, which default to 'normal' for the root element.
      // The 'normal' value behaves like 'start' except for Flexbox Items, which obviously should have a container.
      return false
    }
    let normalItemPosition =
      stretchingMode == .Any
      ? containingBlock!.selfAlignmentNormalBehavior(gridItem: self) : .Normal
    if containingBlock!.isHorizontalWritingMode() != isHorizontalWritingMode() {
      if let grid = self as? RenderGridWrapper,
        grid.isSubgridInParentDirection(parentDirection: .ForRows)
      {
        return true
      }
      return style.resolvedAlignSelf(
        parentStyle: containingBlock!.style(), normalValueBehaviour: normalItemPosition
      ).position
        == .Stretch
    }
    if let grid = self as? RenderGridWrapper,
      grid.isSubgridInParentDirection(parentDirection: .ForColumns)
    {
      return true
    }
    return style.resolvedJustifySelf(
      parentStyle: containingBlock!.style(), normalValueBehaviour: normalItemPosition
    ).position == .Stretch
  }

  private func isStretchingColumnFlexItem() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnFlexItemHasStretchAlignment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shrinkLogicalWidthToAvoidFloats(
    childMarginStart: LayoutUnit, childMarginEnd: LayoutUnit, cb: RenderBlockWrapper,
    fragment: RenderFragmentContainerWrapper?
  ) -> LayoutUnit {
    var containingBlockFragment: RenderFragmentContainerWrapper? = nil
    var logicalTopPosition = logicalTop()
    if fragment != nil {
      let offsetFromLogicalTopOfFragment =
        fragment != nil
        ? fragment!.logicalTopForFragmentedFlowContent() - offsetFromLogicalTopOfFirstPage()
        : LayoutUnit(value: UInt64(0))
      logicalTopPosition = max(
        logicalTopPosition, logicalTopPosition + offsetFromLogicalTopOfFragment)
      containingBlockFragment = cb.clampToStartAndEndFragments(fragment: fragment)
    }

    let logicalHeight = cb.logicalHeightForChild(child: self)
    var availableLogicalWidthAtLogicalTopPosition = cb.availableLogicalWidthForLineInFragment(
      position: logicalTopPosition, fragment: containingBlockFragment, logicalHeight: logicalHeight)
    // We need to see if margins on either the start side or the end side can contain the floats in question. If they can,
    // then just using the line width is inaccurate. In the case where a float completely fits, we don't need to use the line
    // offset at all, but can instead push all the way to the content edge of the containing block. In the case where the float
    // doesn't fit, we can use the line offset, but we need to grow it by the margin to reflect the fact that the margin was
    // "consumed" by the float. Negative margins aren't consumed by the float, and so we ignore them.
    if childMarginStart > 0 {
      let startContentSide = cb.startOffsetForContent(fragment: containingBlockFragment)
      let startContentSideWithMargin = startContentSide + childMarginStart
      let startOffset = cb.startOffsetForLineInFragment(
        position: logicalTopPosition, fragment: containingBlockFragment,
        logicalHeight: logicalHeight)
      if startOffset <= startContentSideWithMargin {
        availableLogicalWidthAtLogicalTopPosition -= childMarginStart
        availableLogicalWidthAtLogicalTopPosition += startOffset - startContentSide
      }
    }

    if childMarginEnd > 0 {
      let endContentSide = cb.endOffsetForContent(fragment: containingBlockFragment)
      let endContentSideWithMargin = endContentSide + childMarginEnd
      let endOffset = cb.endOffsetForLineInFragment(
        position: logicalTopPosition, fragment: containingBlockFragment,
        logicalHeight: logicalHeight)
      if endOffset <= endContentSideWithMargin {
        availableLogicalWidthAtLogicalTopPosition -= childMarginEnd
        availableLogicalWidthAtLogicalTopPosition += endOffset - endContentSide
      }
    }

    return availableLogicalWidthAtLogicalTopPosition
  }

  func computeLogicalWidthInFragmentUsing(
    widthType: SizeType, logicalWidth: LengthWrapper, availableLogicalWidth: LayoutUnit,
    cb: RenderBlockWrapper, fragment: RenderFragmentContainerWrapper?
  ) -> LayoutUnit {
    assert(widthType == .MinSize || widthType == .MainOrPreferredSize || !logicalWidth.isAuto())
    if widthType == .MinSize && logicalWidth.isAuto() {
      return adjustBorderBoxLogicalWidthForBoxSizing(
        computedLogicalWidth: Int32(0), originalType: logicalWidth.type())
    }

    if !logicalWidth.isIntrinsicOrAuto() {
      // FIXME: If the containing block flow is perpendicular to our direction we need to use the available logical height instead.
      return adjustBorderBoxLogicalWidthForBoxSizing(
        computedLogicalWidth: valueForLength(
          length: logicalWidth, maximumValue: availableLogicalWidth),
        originalType: logicalWidth.type())
    }

    if logicalWidth.isIntrinsic() || logicalWidth.isMinIntrinsic() {
      return computeIntrinsicLogicalWidthUsing(
        logicalWidthLength: logicalWidth, availableLogicalWidth: availableLogicalWidth,
        borderAndPadding: borderAndPaddingLogicalWidth())
    }

    var marginStart = LayoutUnit()
    var marginEnd = LayoutUnit()
    var logicalWidthResult = fillAvailableMeasure(
      availableLogicalWidth: availableLogicalWidth, marginStart: &marginStart, marginEnd: &marginEnd
    )

    if shrinkToAvoidFloats() && cb.containsFloats() {
      logicalWidthResult = min(
        logicalWidthResult,
        shrinkLogicalWidthToAvoidFloats(
          childMarginStart: marginStart, childMarginEnd: marginEnd, cb: cb, fragment: fragment))
    }

    if widthType == .MainOrPreferredSize && sizesLogicalWidthToFitContent(widthType: widthType) {
      return max(minPreferredLogicalWidth(), min(maxPreferredLogicalWidth(), logicalWidthResult))
    }
    return logicalWidthResult
  }

  func computeLogicalHeightUsing(
    heightType: SizeType, height: LengthWrapper, intrinsicContentHeight: LayoutUnit?
  ) -> LayoutUnit? {
    if self is RenderReplacedWrapper {
      if (heightType == .MinSize || heightType == .MaxSize)
        && !replacedMinMaxLogicalHeightComputesAsNone(sizeType: heightType)
      {
        return computeReplacedLogicalHeightUsing(heightType: heightType, logicalHeight: height)
          + borderAndPaddingLogicalHeight()
      }
      return nil
    }
    if let logicalHeight = computeContentAndScrollbarLogicalHeightUsing(
      heightType: heightType, height: height, intrinsicContentHeight: intrinsicContentHeight)
    {
      return adjustBorderBoxLogicalHeightForBoxSizing(height: logicalHeight)
    }
    return nil
  }

  func computeContentLogicalHeight(
    heightType: SizeType, height: LengthWrapper, intrinsicContentHeight: LayoutUnit?
  ) -> LayoutUnit? {
    if let heightIncludingScrollbar = computeContentAndScrollbarLogicalHeightUsing(
      heightType: heightType, height: height, intrinsicContentHeight: intrinsicContentHeight)
    {
      return max(
        LayoutUnit(value: 0),
        adjustContentBoxLogicalHeightForBoxSizing(height: heightIncludingScrollbar)
          - scrollbarLogicalHeight())
    }
    return nil
  }

  func computeContentAndScrollbarLogicalHeightUsing(
    heightType: SizeType, height: LengthWrapper, intrinsicContentHeight: LayoutUnit?
  ) -> LayoutUnit? {
    if height.isAuto() {
      if heightType != .MinSize {
        return nil
      }
      if intrinsicContentHeight != nil && isFlexItem()
        && (parent() as! RenderFlexibleBoxWrapper).shouldApplyMinBlockSizeAutoForFlexItem(
          flexItem: self)
      {
        return adjustIntrinsicLogicalHeightForBoxSizing(height: intrinsicContentHeight!)
      }
      return LayoutUnit(value: 0)
    }
    // FIXME: The CSS sizing spec is considering changing what min-content/max-content should resolve to.
    // If that happens, this code will have to change.
    if height.isIntrinsic() || height.isLegacyIntrinsic() {
      return computeIntrinsicLogicalContentHeightUsing(
        logicalHeightLength: height, intrinsicContentHeight: intrinsicContentHeight,
        borderAndPadding: borderAndPaddingLogicalHeight())
    }
    if height.isFixed() {
      return LayoutUnit(value: height.value())
    }
    if height.isPercentOrCalculated() {
      return computePercentageLogicalHeight(height: height)
    }
    return nil
  }

  func computeReplacedLogicalHeightUsing(heightType: SizeType, logicalHeight: LengthWrapper)
    -> LayoutUnit
  {
    assert(heightType == .MinSize || heightType == .MainOrPreferredSize || !logicalHeight.isAuto())
    // This function should get called with SizeType::MinSize/SizeType::MaxSize only if replacedMinMaxLogicalHeightComputesAsNone
    // returns false, otherwise we should not try to compute those values as they may be incorrect. The caller
    // should make sure this condition holds before calling this function
    if heightType == .MinSize || heightType == .MaxSize {
      assert(!replacedMinMaxLogicalHeightComputesAsNone(sizeType: heightType))
    }
    if heightType == .MinSize && logicalHeight.isAuto() {
      return adjustContentBoxLogicalHeightForBoxSizing(height: LayoutUnit(value: 0))
    }

    switch logicalHeight.type() {
    case .Fixed:
      return adjustContentBoxLogicalHeightForBoxSizing(
        height: LayoutUnit(value: logicalHeight.value()))
    case .Percent, .Calculated:
      var container = isOutOfFlowPositioned() ? self.container() : containingBlock()
      while container != nil && container!.isAnonymousForPercentageResolution() {
        // Stop at rendering context root.
        if container is RenderViewWrapper {
          break
        }
        container = container!.containingBlock()
      }
      let hasPerpendicularContainingBlock =
        container!.isHorizontalWritingMode() != isHorizontalWritingMode()
      var stretchedHeight: LayoutUnit? = nil
      if let block = container as? RenderBlockWrapper {
        block.addPercentHeightDescendant(descendant: self)
        if let usedFlexItemOverridingLogicalHeightForPercentageResolutionForFlex =
          (block.isFlexItem()
            ? (block.parent() as! RenderFlexibleBoxWrapper)
              .usedFlexItemOverridingLogicalHeightForPercentageResolution(flexItem: block) : nil)
        {
          stretchedHeight = block.overridingContentLogicalHeight(
            overridingLogicalHeight:
              usedFlexItemOverridingLogicalHeightForPercentageResolutionForFlex)
        } else if let usedChildOverridingLogicalHeightForGrid =
          (block.isGridItem() && !hasPerpendicularContainingBlock
            ? block.overridingLogicalHeight() : nil)
        {
          stretchedHeight = block.overridingContentLogicalHeight(
            overridingLogicalHeight: usedChildOverridingLogicalHeightForGrid)
        }
      }

      // FIXME: This calculation is not patched for block-flow yet.
      // https://bugs.webkit.org/show_bug.cgi?id=46500
      if container!.isOutOfFlowPositioned()
        && container!.style().height().isAuto()
        && !(container!.style().top().isAuto() || container!.style().bottom().isAuto())
      {
        let block = container as! RenderBlockWrapper
        let computedValues = block.computeLogicalHeight(
          logicalHeight: block.logicalHeight(), logicalTop: LayoutUnit(value: 0))
        let newContentWithScrollbarHeight =
          computedValues.extent - block.borderAndPaddingLogicalHeight()
        let newContentHeight = newContentWithScrollbarHeight - block.scrollbarLogicalHeight()
        return adjustContentBoxLogicalHeightForBoxSizing(
          height: valueForLength(length: logicalHeight, maximumValue: newContentHeight))
      }

      var availableHeight = LayoutUnit()
      if isOutOfFlowPositioned() {
        availableHeight = containingBlockLogicalHeightForPositioned(
          containingBlock: container as! RenderBoxModelObjectWrapper)
      } else if stretchedHeight != nil {
        availableHeight = stretchedHeight!
      } else if let gridAreaLogicalHeight =
        isGridItem() ? overridingContainingBlockContentLogicalHeight() : nil,
        let value = gridAreaLogicalHeight
      {
        availableHeight = value
      } else {
        availableHeight =
          hasPerpendicularContainingBlock
          ? containingBlockLogicalWidthForContent()
          : containingBlockLogicalHeightForContent(heightType: .IncludeMarginBorderPadding)
        // It is necessary to use the border-box to match WinIE's broken
        // box model. This is essential for sizing inside
        // table cells using percentage heights.
        // FIXME: This needs to be made block-flow-aware. If the cell and image are perpendicular block-flows, this isn't right.
        // https://bugs.webkit.org/show_bug.cgi?id=46997
        while container != nil && !(container is RenderViewWrapper)
          && (container!.style().logicalHeight().isAuto()
            || container!.style().logicalHeight().isPercentOrCalculated())
        {
          if container!.isRenderTableCell() {
            // Don't let table cells squeeze percent-height replaced elements
            // <http://bugs.webkit.org/show_bug.cgi?id=15359>
            availableHeight = max(availableHeight, intrinsicLogicalHeight())
            return valueForLength(
              length: logicalHeight, maximumValue: availableHeight - borderAndPaddingLogicalHeight()
            )
          }
          (container as! RenderBlockWrapper).addPercentHeightDescendant(descendant: self)
          container = container!.containingBlock()
        }
      }
      return adjustContentBoxLogicalHeightForBoxSizing(
        height: valueForLength(length: logicalHeight, maximumValue: availableHeight))
    case .MinContent, .MaxContent, .FitContent, .FillAvailable:
      return adjustContentBoxLogicalHeightForBoxSizing(
        height: computeIntrinsicLogicalContentHeightUsing(
          logicalHeightLength: logicalHeight, intrinsicContentHeight: intrinsicLogicalHeight(),
          borderAndPadding: borderAndPaddingLogicalHeight()))
    default:
      return intrinsicLogicalHeight()
    }
  }

  private func computeReplacedLogicalHeightRespectingMinMaxHeight(logicalHeight: LayoutUnit)
    -> LayoutUnit
  {
    var minLogicalHeight = LayoutUnit()
    if !replacedMinMaxLogicalHeightComputesAsNone(sizeType: .MinSize) {
      minLogicalHeight = computeReplacedLogicalHeightUsing(
        heightType: .MinSize, logicalHeight: style().logicalMinHeight())
    }
    var maxLogicalHeight = logicalHeight
    if !replacedMinMaxLogicalHeightComputesAsNone(sizeType: .MaxSize) {
      maxLogicalHeight = computeReplacedLogicalHeightUsing(
        heightType: .MaxSize, logicalHeight: style().logicalMaxHeight())
    }
    return max(minLogicalHeight, min(logicalHeight, maxLogicalHeight))
  }

  func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    return computeReplacedLogicalHeightRespectingMinMaxHeight(
      logicalHeight: computeReplacedLogicalHeightUsing(
        heightType: .MainOrPreferredSize, logicalHeight: style().logicalHeight()))
  }

  func computePercentageLogicalHeight(
    height: LengthWrapper, updateDescendants: UpdatePercentageHeightDescendants = .Yes
  ) -> LayoutUnit? {
    var skippedAutoHeightContainingBlock = false
    var cb = containingBlock()
    var containingBlockChild = self
    var rootMarginBorderPaddingHeight = LayoutUnit()
    let isHorizontal = isHorizontalWritingMode()
    while cb != nil && !(cb is RenderViewWrapper)
      && skipContainingBlockForPercentHeightCalculation(
        containingBlock: cb!,
        isPerpendicularWritingMode: isHorizontal != cb!.isHorizontalWritingMode())
    {
      if cb!.isBody() || cb!.isDocumentElementRenderer() {
        rootMarginBorderPaddingHeight +=
          cb!.marginBefore() + cb!.marginAfter() + cb!.borderAndPaddingLogicalHeight()
      }
      skippedAutoHeightContainingBlock = true
      containingBlockChild = cb!
      cb = cb!.containingBlock()
    }
    if updateDescendants == .Yes {
      cb!.addPercentHeightDescendant(descendant: self)
    }

    var availableHeight: LayoutUnit? = nil
    let isOrthogonal = isHorizontal != cb!.isHorizontalWritingMode()
    if let overridingAvailableHeight = isOrthogonal
      ? overridingContainingBlockContentLogicalWidth()
      : overridingContainingBlockContentLogicalHeight()
    {
      availableHeight = overridingAvailableHeight
    } else {
      if isOrthogonal {
        availableHeight = containingBlockChild.containingBlockLogicalWidthForContent()
      } else if cb is RenderTableCellWrapper {
        if !skippedAutoHeightContainingBlock {
          // Table cells violate what the CSS spec says to do with heights. Basically we
          // don't care if the cell specified a height or not. We just always make ourselves
          // be a percentage of the cell's current content height.
          if let overridingLogicalHeight = cb!.overridingLogicalHeight() {
            availableHeight =
              overridingLogicalHeight - cb!.computedCSSPaddingBefore()
              - cb!.computedCSSPaddingAfter() - cb!.borderBefore() - cb!.borderAfter()
              - cb!.scrollbarLogicalHeight()
          } else {
            return tableCellShouldHaveZeroInitialSize(
              block: cb!, child: self, scrollsOverflowY: scrollsOverflowY())
              ? LayoutUnit(value: 0) : nil
          }
        }
      } else {
        availableHeight = cb!.availableLogicalHeightForPercentageComputation()
      }
    }

    if availableHeight == nil {
      return nil
    }

    var result = valueForLength(
      length: height,
      maximumValue: availableHeight! - rootMarginBorderPaddingHeight
        + (isRenderTable() && isOutOfFlowPositioned()
          ? cb!.paddingBefore() + cb!.paddingAfter() : LayoutUnit(value: UInt64(0))))

    // |overridingLogicalHeight| is the maximum height made available by the
    // cell to its percent height children when we decide they can determine the
    // height of the cell. If the percent height child is box-sizing:content-box
    // then we must subtract the border and padding from the cell's
    // |availableHeight| (given by |overridingLogicalHeight|) to arrive
    // at the child's computed height.
    let subtractBorderAndPadding =
      isRenderTable()
      || (cb is RenderTableCellWrapper && !skippedAutoHeightContainingBlock
        && cb!.overridingLogicalHeight() != nil && style().boxSizing() == .ContentBox)
    if subtractBorderAndPadding {
      result -= borderAndPaddingLogicalHeight()
      return max(LayoutUnit(value: UInt64(0)), result)
    }
    return result
  }

  func availableLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_availableLogicalWidth(p))
  }

  func availableLogicalHeight(heightType: AvailableLogicalHeightType) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func verticalScrollbarWidth() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func horizontalScrollbarHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollbarLogicalHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollsOverflowX() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollsOverflowY() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func percentageLogicalHeightIsResolvable() -> Bool {
    // Do this to avoid duplicating all the logic that already exists when computing
    // an actual percentage height.
    let fakeLength = LengthWrapper(value: Int32(100), type: .Percent)
    return computePercentageLogicalHeight(height: fakeLength) != nil
  }

  func hasUnsplittableScrollingOverflow() -> Bool {
    // We will paginate as long as we don't scroll overflow in the pagination direction.
    let isHorizontal = isHorizontalWritingMode()
    if (isHorizontal && !scrollsOverflowY()) || (!isHorizontal && !scrollsOverflowX()) {
      return false
    }

    // Fragmenting scrollbars is only problematic in interactive media, e.g. multicol on a
    // screen. If we're printing, which is non-interactive media, we should allow objects with
    // non-visible overflow to be paginated as normally.
    if document().printing() {
      return false
    }

    // We do have overflow. We'll still be willing to paginate as long as the block
    // has auto logical height, auto or undefined max-logical-height and a zero or auto min-logical-height.
    // Note this is just a heuristic, and it's still possible to have overflow under these
    // conditions, but it should work out to be good enough for common cases. Paginating overflow
    // with scrollbars present is not the end of the world and is what we used to do in the old model anyway.
    return !style().logicalHeight().isIntrinsicOrAuto()
      || (!style().logicalMaxHeight().isIntrinsicOrAuto()
        && !style().logicalMaxHeight().isUndefined()
        && (!style().logicalMaxHeight().isPercentOrCalculated()
          || percentageLogicalHeightIsResolvable()))
      || (!style().logicalMinHeight().isIntrinsicOrAuto() && style().logicalMinHeight().isPositive()
        && (!style().logicalMinHeight().isPercentOrCalculated()
          || percentageLogicalHeightIsResolvable()))
  }

  func isUnsplittableForPagination() -> Bool {
    return isReplacedOrInlineBlock()
      || hasUnsplittableScrollingOverflow()
      || (parent() != nil && isWritingModeRoot())
      || (isFloating() && style().pseudoElementType() == .FirstLetter
        && style().initialLetterDrop() > 0)
      || shouldApplySizeContainment()
  }

  func shouldTreatChildAsReplacedInTableCells() -> Bool {
    if isReplacedOrInlineBlock() {
      return true
    }
    return element() != nil
      && (element()!.isFormControlElement() || element() is HTMLImageElementWrapper)
  }

  func overflowClipRect(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper? = nil,
    relevancy: OverlayScrollbarSizeRelevancy = .IgnoreOverlayScrollbarSize,
    phase: PaintPhase = .BlockBackground
  ) -> LayoutRectWrapper {
    var clipRect = borderBoxRectInFragment(fragment: fragment)
    let topLeft = location + clipRect.location()
    clipRect.setLocation(
      location: topLeft + LayoutSizeWrapper(width: borderLeft(), height: borderTop()))
    clipRect.setSize(
      size: clipRect.size()
        - LayoutSizeWrapper(
          width: borderLeft() + borderRight(), height: borderTop() + borderBottom()))
    if style().overflowX() == .Clip && style().overflowY() == .Visible {
      clipRect.expandToInfiniteY()
    } else if style().overflowY() == .Clip && style().overflowX() == .Visible {
      clipRect.expandToInfiniteX()
    }

    // Subtract out scrollbars if we have them.
    if let scrollableArea = layer() != nil ? layer()!.scrollableArea() : nil {
      if shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() {
        clipRect.move(
          dx: scrollableArea.verticalScrollbarWidth(
            relevancy: relevancy, isHorizontalWritingMode: isHorizontalWritingMode()), dy: 0)
      }
      clipRect.contract(
        dw: scrollableArea.verticalScrollbarWidth(
          relevancy: relevancy, isHorizontalWritingMode: isHorizontalWritingMode()),
        dh: scrollableArea.horizontalScrollbarHeight(
          relevancy: relevancy, isHorizontalWritingMode: isHorizontalWritingMode()))
    }

    return clipRect
  }

  func overflowClipRectForChildLayers(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?,
    relevancy: OverlayScrollbarSizeRelevancy
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pushContentsClip(paintInfo: inout PaintInfoWrapper, accumulatedOffset: LayoutPointWrapper)
    -> Bool
  {
    if paintInfo.phase == .BlockBackground || paintInfo.phase == .SelfOutline
      || paintInfo.phase == .Mask
    {
      return false
    }

    let isControlClip = paintInfo.phase != .EventRegion && hasControlClip()
    let isOverflowClip = hasNonVisibleOverflow() && !layer()!.isSelfPaintingLayer

    if !isControlClip && !isOverflowClip {
      return false
    }

    if paintInfo.phase == .Outline {
      paintInfo.phase = .ChildOutlines
    } else if paintInfo.phase == .ChildBlockBackground {
      paintInfo.phase = .BlockBackground
      paintObject(paintInfo: &paintInfo, paintOffset: accumulatedOffset)
      paintInfo.phase = .ChildBlockBackgrounds
    }
    let deviceScaleFactor = document().deviceScaleFactor()
    let clipRect = snapRectToDevicePixels(
      rect: (isControlClip
        ? controlClipRect(additionalOffset: accumulatedOffset)
        : overflowClipRect(
          location: accumulatedOffset, fragment: nil, relevancy: .IgnoreOverlayScrollbarSize,
          phase: paintInfo.phase)),
      pixelSnappingFactor: deviceScaleFactor)
    if style().hasBorderRadius() {
      clipToPaddingBoxShape(
        context: paintInfo.context(), accumulatedOffset: accumulatedOffset,
        deviceScaleFactor: deviceScaleFactor)
    }

    paintInfo.context().clip(rect: clipRect)

    if paintInfo.phase == .EventRegion || paintInfo.phase == .Accessibility {
      paintInfo.regionContext!.pushClip(clipRect: enclosingIntRect(rect: clipRect))
    }

    return true
  }

  func clipRect(location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?)
    -> LayoutRectWrapper
  {
    let borderBoxRect = borderBoxRectInFragment(fragment: fragment)
    var clipRect = LayoutRectWrapper(
      location: borderBoxRect.location() + location, size: borderBoxRect.size())

    let zero = LayoutUnit(value: UInt64(0))
    if !style().clipLeft().isAuto() {
      let c = valueForLength(length: style().clipLeft(), maximumValue: borderBoxRect.width())
      clipRect.move(dx: c, dy: zero)
      clipRect.contract(dw: c, dh: zero)
    }

    // We don't use the fragment-specific border box's width and height since clip offsets are (stupidly) specified
    // from the left and top edges. Therefore it's better to avoid constraining to smaller widths and heights.

    if !style().clipRight().isAuto() {
      clipRect.contract(
        dw: width() - valueForLength(length: style().clipRight(), maximumValue: width()), dh: zero)
    }

    if !style().clipTop().isAuto() {
      let c = valueForLength(length: style().clipTop(), maximumValue: borderBoxRect.height())
      clipRect.move(dx: zero, dy: c)
      clipRect.contract(dw: zero, dh: c)
    }

    if !style().clipBottom().isAuto() {
      clipRect.contract(
        dw: zero,
        dh: height() - valueForLength(length: style().clipBottom(), maximumValue: height()))
    }

    return clipRect
  }

  func hasControlClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func popContentsClip(
    paintInfo: inout PaintInfoWrapper, originalPhase: PaintPhase,
    accumulatedOffset: LayoutPointWrapper
  ) {
    assert(hasControlClip() || (hasNonVisibleOverflow() && !layer()!.isSelfPaintingLayer))

    if paintInfo.phase == .EventRegion || paintInfo.phase == .Accessibility {
      paintInfo.regionContext!.popClip()
    }

    paintInfo.context().restore()
    if originalPhase == .Outline {
      paintInfo.phase = .SelfOutline
      paintObject(paintInfo: &paintInfo, paintOffset: accumulatedOffset)
      paintInfo.phase = originalPhase
    } else if originalPhase == .ChildBlockBackground {
      paintInfo.phase = originalPhase
    }
  }

  func ensureControlPartForRenderer() -> ControlPartWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ensureControlPartForBorderOnly() -> ControlPartWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ensureControlPartForDecorations() -> ControlPartWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintObject(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    fatalError("Not reached")
  }

  func paintBoxDecorations(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    var paintRect = borderBoxRectInFragment(fragment: nil)
    paintRect.moveBy(offset: paintOffset)
    adjustBorderBoxRectForPainting(paintRect: &paintRect)

    paintRect = theme().adjustedPaintRect(box: self, paintRect: paintRect)
    let bleedAvoidance = determineBackgroundBleedAvoidance(context: paintInfo.context())

    let backgroundPainter = BackgroundPainter(renderer: self, paintInfo: paintInfo)

    // FIXME: Should eventually give the theme control over whether the box shadow should paint, since controls could have
    // custom shadows of their own.
    if !BackgroundPainter.boxShadowShouldBeAppliedToBackground(
      renderer: self, paintOffset: paintRect.location(), bleedAvoidance: bleedAvoidance,
      inlineBox: InlineIterator.InlineBoxIterator())
    {
      backgroundPainter.paintBoxShadow(paintRect: paintRect, style: style(), shadowStyle: .Normal)
    }

    let stateSaver = GraphicsContextStateSaver(context: paintInfo.context(), saveAndRestore: false)
    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      // To avoid the background color bleeding out behind the border, we'll render background and border
      // into a transparency layer, and then clip that in one go (which requires setting up the clip before
      // beginning the layer).
      stateSaver.save()
      let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: paintRect)
      borderShape.clipToOuterShape(
        context: paintInfo.context(), deviceScaleFactor: document().deviceScaleFactor())
      paintInfo.context().beginTransparencyLayer(opacity: 1)
    }

    // If we have a native theme appearance, paint that before painting our background.
    // The theme will tell us whether or not we should also paint the CSS background.
    var borderOrBackgroundPaintingIsNeeded = true
    if style().hasUsedAppearance() {
      if let control = ensureControlPartForRenderer() {
        borderOrBackgroundPaintingIsNeeded = theme().paint(
          box: self, part: control, paintInfo: paintInfo, rect: paintRect)
      } else {
        borderOrBackgroundPaintingIsNeeded = theme().paint(
          box: self, paintInfo: paintInfo, rect: paintRect)
      }
    }

    let borderPainter = BorderPainter(renderer: self, paintInfo: paintInfo)

    if borderOrBackgroundPaintingIsNeeded {
      if bleedAvoidance == .BackgroundBleedBackgroundOverBorder {
        borderPainter.paintBorder(rect: paintRect, style: style(), bleedAvoidance: bleedAvoidance)
      }

      backgroundPainter.paintBackground(paintRect: paintRect, bleedAvoidance: bleedAvoidance)

      if style().hasUsedAppearance() {
        if let control = ensureControlPartForDecorations() {
          theme().paint(
            box: self, part: control, paintInfo: paintInfo, rect: paintRect)
        } else {
          theme().paintDecorations(box: self, paintInfo: paintInfo, rect: paintRect)
        }
      }
    }

    backgroundPainter.paintBoxShadow(paintRect: paintRect, style: style(), shadowStyle: .Inset)

    if bleedAvoidance != .BackgroundBleedBackgroundOverBorder {
      var paintCSSBorder = false

      if !style().hasUsedAppearance() {
        paintCSSBorder = true
      } else if borderOrBackgroundPaintingIsNeeded {
        // The theme will tell us whether or not we should also paint the CSS border.
        if let control = ensureControlPartForBorderOnly() {
          paintCSSBorder = theme().paint(
            box: self, part: control, paintInfo: paintInfo, rect: paintRect)
        } else {
          paintCSSBorder = theme().paintBorderOnly(box: self, paintInfo: paintInfo, rect: paintRect)
        }
      }

      if paintCSSBorder && style().hasVisibleBorderDecoration() {
        borderPainter.paintBorder(
          rect: paintRect, style: style(), bleedAvoidance: bleedAvoidance)
      }
    }

    if bleedAvoidance == .BackgroundBleedUseTransparencyLayer {
      paintInfo.context().endTransparencyLayer()
    }
  }

  func paintMask(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) || style().usedVisibility() != .Visible
      || paintInfo.phase != .Mask || paintInfo.context().paintingDisabled()
    {
      return
    }

    var paintRect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: &paintRect)
    paintMaskImages(paintInfo: paintInfo, paintRect: paintRect)
  }

  func paintClippingMask(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) || style().usedVisibility() != .Visible
      || paintInfo.phase != .ClippingMask || paintInfo.context().paintingDisabled()
    {
      return
    }

    let paintRect = LayoutRectWrapper(location: paintOffset, size: size())

    if document().settings().layerBasedSVGEngineEnabled() && style().clipPath() != nil
      && style().clipPath()!.type == .Reference
    {
      paintSVGClippingMask(paintInfo: paintInfo, objectBoundingBox: paintRect.FloatRect())
      return
    }

    paintInfo.context().fillRect(
      rect: FloatRectWrapper(r: snappedIntRect(rect: paintRect)), color: ColorWrapper.black)
  }

  func maskClipRect(paintOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    let maskBorder = style().maskBorder()
    if maskBorder.image() != nil {
      var borderImageRect = borderBoxRect()

      // Apply outsets to the border box.
      borderImageRect.expand(box: style().maskBorderOutsets())
      return borderImageRect
    }

    var result = LayoutRectWrapper()
    let borderBox = borderBoxRect()
    var maskLayer: FillLayerWrapper? = style().maskLayers()
    while maskLayer != nil {
      if maskLayer!.image() != nil {
        // Masks should never have fixed attachment, so it's OK for paintContainer to be null.
        result.unite(
          other: BackgroundPainter.calculateBackgroundImageGeometry(
            renderer: self, paintContainer: nil, fillLayer: maskLayer!, paintOffset: paintOffset,
            borderBoxRect: borderBox
          ).destinationRect)
      }
      maskLayer = maskLayer!.next()
    }
    return result
  }

  func removeFloatingAndInvalidateForLayout() {
    assert(isFloating())

    if renderTreeBeingDestroyed() {
      return
    }

    if let ancestor = outermostBlockContainingFloatingObject(box: self) {
      ancestor.markSiblingsWithFloatsForLayout(floatToRemove: self)
      ancestor.markAllDescendantsWithFloatsForLayout(floatToRemove: self, inLayout: false)
    }
  }

  func removeFloatingOrPositionedChildFromBlockLists() {
    assert(!renderTreeBeingDestroyed())

    if isFloating() {
      return removeFloatingAndInvalidateForLayout()
    }

    if isOutOfFlowPositioned() {
      return RenderBlockWrapper.removePositionedObject(rendererToRemove: self)
    }

    fatalError("Not reached")
  }

  func shrinkToAvoidFloats() -> Bool {
    // Floating objects don't shrink.  Objects that don't avoid floats don't shrink.  Marquees don't shrink.
    if (isInline() && !isHTMLMarquee()) || !avoidsFloats() || isFloating() {
      return false
    }

    // Only auto width objects can possibly shrink to avoid floats.
    return style().width().isAuto()
  }

  func avoidsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markForPaginationRelayoutIfNeeded() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flipForWritingModeForChild(child: RenderBoxWrapper, point: LayoutPointWrapper)
    -> LayoutPointWrapper
  {
    if !style().isFlippedBlocksWritingMode() {
      return point
    }

    // The child is going to add in its x() and y(), so we have to make sure it ends up in
    // the right place.
    if isHorizontalWritingMode() {
      return LayoutPointWrapper(
        x: point.x, y: point.y + height() - child.height() - (2 * child.y()))
    }
    return LayoutPointWrapper(
      x: point.x + width() - child.width() - (2 * child.x()), y: point.y)
  }

  func flipForWritingMode(position: LayoutUnit) -> LayoutUnit {
    if !style().isFlippedBlocksWritingMode() {
      return position
    }
    return logicalHeight() - position
  }

  func flipForWritingMode(position: LayoutPointWrapper) -> LayoutPointWrapper {
    if !style().isFlippedBlocksWritingMode() {
      return position
    }
    return isHorizontalWritingMode()
      ? LayoutPointWrapper(x: position.x, y: height() - position.y)
      : LayoutPointWrapper(x: width() - position.x, y: position.y)
  }

  func flipForWritingMode(rect: inout LayoutRectWrapper) {
    wk_interop.RenderBox_flipForWritingMode(
      p, LayoutPointRaw(x: rect.x().rawValue(), y: rect.y().rawValue()))
  }

  func flipForWritingMode(rect: inout FloatRectWrapper) {
    if !style().isFlippedBlocksWritingMode() {
      return
    }

    if isHorizontalWritingMode() {
      rect.setY(y: height() - rect.maxY())
    } else {
      rect.setX(x: width() - rect.maxX())
    }
  }

  // These represent your location relative to your container as a physical offset.
  // In layout related methods you almost always want the logical location (e.g. x() and y()).
  func topLeftLocation() -> LayoutPointWrapper {
    // This is inlined for speed, since it is used by updateLayerPosition() during scrolling.
    if document().view() == nil || !document().view()!.hasFlippedBlockRenderers() {
      return location()
    }
    return topLeftLocationWithFlipping()
  }

  func logicalVisualOverflowRectForPropagation(style: RenderStyleWrapper) -> LayoutRectWrapper {
    if style.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let raw = wk_interop.RenderBox_logicalVisualOverflowRectForPropagation(p, style.p)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  func layoutOverflowRectForPropagation(style: RenderStyleWrapper) -> LayoutRectWrapper {
    if style.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let raw = wk_interop.RenderBox_layoutOverflowRectForPropagation(p, style.p)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  func hasVisualOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsPreferredWidthsRecalculation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollPosition() -> ScrollPosition {
    if !hasPotentiallyScrollableOverflow() {
      return ScrollPosition(x: 0, y: 0)
    }

    assert(hasLayer())
    if let scrollableArea = layer()!.scrollableArea() {
      return scrollableArea.scrollPosition()
    }

    return ScrollPosition(x: 0, y: 0)
  }

  func hasRelativeDimensions() -> Bool {
    return style().height().isPercentOrCalculated() || style().width().isPercentOrCalculated()
      || style().maxHeight().isPercentOrCalculated() || style().maxWidth().isPercentOrCalculated()
      || style().minHeight().isPercentOrCalculated() || style().minWidth().isPercentOrCalculated()
  }

  func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isGridItem() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFlexItem() -> Bool { return wk_interop.RenderBox_isFlexItem(p) }

  func adjustBorderBoxRectForPainting(paintRect: inout LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldComputeLogicalHeightFromAspectRatio() -> Bool {
    if shouldIgnoreAspectRatio() {
      return false
    }

    if shouldComputeLogicalWidthFromAspectRatioAndInsets(renderer: self) {
      return false
    }

    let h = style().logicalHeight()
    return h.isAuto() || h.isIntrinsic()
      || (!isOutOfFlowPositioned() && h.isPercentOrCalculated()
        && !percentageLogicalHeightIsResolvable())
  }

  func updateFloatPainterAfterSelfPaintingLayerChange() {
    assert(isFloating())
    assert(!hasLayer() || !layer()!.isSelfPaintingLayer)

    if let floatingObject = floatingObjectForFloatPainting() {
      floatingObject.setPaintsFloat(paintsFloat: true)
    }
  }

  // Find the ancestor renderer that is supposed to paint this float now that it is not self painting anymore.
  private func floatingObjectForFloatPainting() -> FloatingObjectWrapper? {
    let layoutContext = view().frameView().layoutContext()
    if !layoutContext.isInLayout()
      || CPtrToInt(layoutContext.subtreeLayoutRoot()?.p) != CPtrToInt(p)
    {
      return nil
    }

    var floatPainter: FloatingObjectWrapper? = nil
    var ancestor = containingBlock()
    while ancestor != nil {
      let blockFlow = ancestor as? RenderBlockFlowWrapper
      if blockFlow == nil {
        fatalError("Not reached")
      }
      let floatingObjects = blockFlow!.floatingObjectSet()
      if floatingObjects == nil {
        break
      }
      var blockFlowContainsThisFloat = false
      for floatingObject in floatingObjects! {
        blockFlowContainsThisFloat = CPtrToInt(floatingObject.renderer?.p) == CPtrToInt(p)
        if blockFlowContainsThisFloat {
          floatPainter = floatingObject
          if blockFlow!.hasLayer() && blockFlow!.layer()!.isSelfPaintingLayer {
            return floatPainter
          }
          break
        }
      }
      if !blockFlowContainsThisFloat {
        break
      }
      ancestor = ancestor!.containingBlock()
    }
    // There has to be an ancestor with a floating object assigned to this renderer.
    assert(floatPainter != nil)
    return floatPainter
  }

  func shapeOutsideInfo() -> ShapeOutsideInfoWrapper? {
    if let unwrapped = wk_interop.RenderBox_shapeOutsideInfo(p) {
      return ShapeOutsideInfoWrapper(p: unwrapped)
    }
    return nil
  }

  private func shouldTrimChildMarginForBox(type: MarginTrimType, child: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selfAlignmentNormalBehavior(gridItem: RenderBoxWrapper? = nil) -> ItemPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMaskImages(paintInfo: PaintInfoWrapper, paintRect: LayoutRectWrapper) {
    // Figure out if we need to push a transparency layer to render our mask.
    var pushTransparencyLayer = false
    let compositedMask = hasLayer() && layer()!.hasCompositedMask()
    let flattenCompositingLayers = paintInfo.paintBehavior.contains(.FlattenCompositingLayers)
    var compositeOp: CompositeOperator = .SourceOver

    var allMaskImagesLoaded = true

    if !compositedMask || flattenCompositingLayers {
      pushTransparencyLayer = true

      // Don't render a masked element until all the mask images have loaded, to prevent a flash of unmasked content.
      if let maskBorder = style().maskBorder().image() {
        allMaskImagesLoaded = allMaskImagesLoaded && maskBorder.isLoaded(renderer: self)
      }

      allMaskImagesLoaded =
        allMaskImagesLoaded && style().maskLayers().imagesAreLoaded(renderer: self)

      paintInfo.context().setCompositeOperation(operation: .DestinationIn)
      paintInfo.context().beginTransparencyLayer(opacity: 1)
      compositeOp = .SourceOver
    }

    if allMaskImagesLoaded {
      BackgroundPainter(renderer: self, paintInfo: paintInfo).paintFillLayers(
        color: ColorWrapper(), fillLayer: style().maskLayers(), rect: paintRect,
        bleedAvoidance: .BackgroundBleedNone, op: compositeOp)
      BorderPainter(renderer: self, paintInfo: paintInfo).paintNinePieceImage(
        rect: paintRect, style: style(), ninePieceImage: style().maskBorder(), op: compositeOp)
    }

    if pushTransparencyLayer {
      paintInfo.context().endTransparencyLayer()
    }
  }

  private func clipToPaddingBoxShape(
    context: GraphicsContextWrapper, accumulatedOffset: LayoutPointWrapper,
    deviceScaleFactor: Float32
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // --------------------- painting stuff -------------------------------

  func determineBackgroundBleedAvoidance(context: GraphicsContextWrapper)
    -> BackgroundBleedAvoidance
  {
    if context.paintingDisabled() {
      return .BackgroundBleedNone
    }

    let style = self.style()

    if !style.hasBackground() || !style.hasBorder() || !style.hasBorderRadius()
      || borderImageIsLoadedAndCanBeRendered()
    {
      return .BackgroundBleedNone
    }

    let ctm = context.getCTM()
    var contextScaling = FloatSize(width: Float32(ctm.xScale()), height: Float32(ctm.yScale()))

    // Because RoundedRect uses IntRect internally the inset applied by the
    // BackgroundBleedShrinkBackground strategy cannot be less than one integer
    // layout coordinate, even with subpixel layout enabled. To take that into
    // account, we clamp the contextScaling to 1.0 for the following test so
    // that borderObscuresBackgroundEdge can only return true if the border
    // widths are greater than 2 in both layout coordinates and screen
    // coordinates.
    // This precaution will become obsolete if RoundedRect is ever promoted to
    // a sub-pixel representation.
    if contextScaling.width > 1 {
      contextScaling.setWidth(width: 1)
    }
    if contextScaling.height > 1 {
      contextScaling.setHeight(height: 1)
    }

    if borderObscuresBackgroundEdge(contextScale: contextScaling) {
      return .BackgroundBleedShrinkBackground
    }
    if !style.hasUsedAppearance() && borderObscuresBackground() && backgroundHasOpaqueTopLayer() {
      return .BackgroundBleedBackgroundOverBorder
    }

    return .BackgroundBleedUseTransparencyLayer
  }

  func backgroundHasOpaqueTopLayer() -> Bool {
    let fillLayer = style().backgroundLayers()
    if fillLayer.clip != .BorderBox {
      return false
    }

    // Clipped with local scrolling
    if hasNonVisibleOverflow() && fillLayer.attachment == .LocalBackground {
      return false
    }

    if fillLayer.hasOpaqueImage(renderer: self) && fillLayer.hasRepeatXY()
      && fillLayer.image()!.canRender(renderer: self, multiplier: style().usedZoom())
    {
      return true
    }

    // If there is only one layer and no image, check whether the background color is opaque.
    if fillLayer.next() == nil && !fillLayer.hasImage() {
      let bgColor = style().visitedDependentColorWithColorFilter(
        colorProperty: .CSSPropertyBackgroundColor)
      if bgColor.isOpaque() {
        return true
      }
    }

    return false
  }

  private func computeIntrinsicLogicalWidthUsing(
    logicalWidthLength: LengthWrapper, availableLogicalWidth: LayoutUnit,
    borderAndPadding: LayoutUnit
  ) -> LayoutUnit {
    if logicalWidthLength.isFillAvailable() {
      return max(
        borderAndPadding, fillAvailableMeasure(availableLogicalWidth: availableLogicalWidth))
    }

    var minLogicalWidth = LayoutUnit()
    var maxLogicalWidth = LayoutUnit()
    if !logicalWidthLength.isMinIntrinsic() && shouldComputeLogicalWidthFromAspectRatio() {
      maxLogicalWidth = computeLogicalWidthFromAspectRatioInternal() - borderAndPadding
      minLogicalWidth = maxLogicalWidth
      if firstChild() != nil {
        let (minChildrenLogicalWidth, maxChildrenLogicalWidth) =
          computeIntrinsicKeywordLogicalWidths()
        minLogicalWidth = max(minLogicalWidth, minChildrenLogicalWidth)
        maxLogicalWidth = max(maxLogicalWidth, maxChildrenLogicalWidth)
      }
    } else {
      (minLogicalWidth, maxLogicalWidth) = computeIntrinsicKeywordLogicalWidths()
    }

    if logicalWidthLength.isMinContent() || logicalWidthLength.isMinIntrinsic() {
      return minLogicalWidth + borderAndPadding
    }

    if logicalWidthLength.isMaxContent() {
      return maxLogicalWidth + borderAndPadding
    }

    if logicalWidthLength.isFitContent() {
      minLogicalWidth += borderAndPadding
      maxLogicalWidth += borderAndPadding
      return max(
        minLogicalWidth,
        min(maxLogicalWidth, fillAvailableMeasure(availableLogicalWidth: availableLogicalWidth)))
    }

    fatalError("Not reached")
  }

  private func computeIntrinsicLogicalContentHeightUsing(
    logicalHeightLength: LengthWrapper, intrinsicContentHeight: LayoutUnit?,
    borderAndPadding: LayoutUnit
  ) -> LayoutUnit? {
    // FIXME: The CSS sizing spec is considering changing what min-content/max-content should resolve to.
    // If that happens, this code will have to change.
    if logicalHeightLength.isMinContent() || logicalHeightLength.isMaxContent()
      || logicalHeightLength.isFitContent() || logicalHeightLength.isLegacyIntrinsic()
    {
      if intrinsicContentHeight != nil {
        return adjustIntrinsicLogicalHeightForBoxSizing(height: intrinsicContentHeight!)
      }
      return nil
    }
    if logicalHeightLength.isFillAvailable() {
      return containingBlock()!.availableLogicalHeight(heightType: .ExcludeMarginBorderPadding)
        - borderAndPadding
    }
    fatalError("Not reached")
  }

  func shouldComputeSizeAsReplaced() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func skipContainingBlockForPercentHeightCalculation(
    containingBlock: RenderBoxWrapper, isPerpendicularWritingMode: Bool
  ) -> Bool {
    // Flow threads for multicol or paged overflow should be skipped. They are invisible to the DOM,
    // and percent heights of children should be resolved against the multicol or paged container.
    if containingBlock.isRenderFragmentedFlow() && !isPerpendicularWritingMode {
      return true
    }

    // Render view is not considered auto height.
    if containingBlock is RenderViewWrapper {
      return false
    }

    // If the writing mode of the containing block is orthogonal to ours, it means
    // that we shouldn't skip anything, since we're going to resolve the
    // percentage height against a containing block *width*.
    if isPerpendicularWritingMode {
      return false
    }

    // Anonymous blocks should not impede percentage resolution on a child.
    // Examples of such anonymous blocks are blocks wrapped around inlines that
    // have block siblings (from the CSS spec) and multicol flow threads (an
    // implementation detail). Another implementation detail, ruby runs, create
    // anonymous inline-blocks, so skip those too. All other types of anonymous
    // objects, such as table-cells and flexboxes, will be treated as if they were
    // non-anonymous.
    if containingBlock.isAnonymousForPercentageResolution() {
      return containingBlock.style().display() == .Block
        || containingBlock.style().display() == .InlineBlock
    }

    // For quirks mode, we skip most auto-height containing blocks when computing
    // percentages.
    return document().inQuirksMode() && !containingBlock.isRenderTableCell()
      && !containingBlock.isOutOfFlowPositioned() && !containingBlock.isRenderGrid()
      && !containingBlock.isFlexibleBoxIncludingDeprecated()
      && containingBlock.style().logicalHeight().isAuto()
  }

  private func resolveAspectRatio() -> Float64? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldIgnoreAspectRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isRenderReplacedWithIntrinsicRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldComputeLogicalWidthFromAspectRatio() -> Bool {
    if shouldIgnoreAspectRatio() {
      return false
    }

    if isGridItem() {
      if shouldComputeSizeAsReplaced() {
        if hasStretchedLogicalWidth() && hasStretchedLogicalHeight() {
          return false
        }
      } else if hasStretchedLogicalWidth(stretchingMode: .Explicit) {
        return false
      }
      if style().logicalWidth().isPercentOrCalculated()
        && parent()!.style().logicalWidth().isFixed()
      {
        return false
      }
    }

    let isResolvablePercentageHeight =
      style().logicalHeight().isPercentOrCalculated()
      && (isOutOfFlowPositioned() || percentageLogicalHeightIsResolvable())
    return overridingLogicalHeight() != nil
      || shouldComputeLogicalWidthFromAspectRatioAndInsets(renderer: self)
      || style().logicalHeight().isFixed() || isResolvablePercentageHeight
  }

  private func computeLogicalWidthFromAspectRatioInternal() -> LayoutUnit {
    assert(shouldComputeLogicalWidthFromAspectRatio())
    let computedValues = computeLogicalHeight(
      logicalHeight: logicalHeight(), logicalTop: logicalTop())
    let logicalHeightforAspectRatio = computedValues.extent

    return inlineSizeFromAspectRatio(
      borderPaddingInlineSum: horizontalBorderAndPaddingExtent(),
      borderPaddingBlockSum: verticalBorderAndPaddingExtent(),
      aspectRatio: style().logicalAspectRatio(), boxSizing: style().boxSizingForAspectRatio(),
      blockSize: logicalHeightforAspectRatio,
      aspectRatioType: style().aspectRatioType(), isRenderReplaced: isRenderReplaced())
  }

  private func computeMinMaxLogicalWidthFromAspectRatio() -> (LayoutUnit, LayoutUnit) {
    var transferredMinSize = LayoutUnit()
    var transferredMaxSize = LayoutUnit.max()
    let aspectRatio = resolveAspectRatio()
    if aspectRatio == nil {
      return (transferredMinSize, transferredMaxSize)
    }

    if style().logicalMinHeight().isSpecified() {
      let blockMinSize = constrainLogicalHeightByMinMax(
        logicalHeight: LayoutUnit(), intrinsicContentHeight: nil)
      if blockMinSize > LayoutUnit() {
        transferredMinSize = inlineSizeFromAspectRatio(
          borderPaddingInlineSum: borderAndPaddingLogicalWidth(),
          borderPaddingBlockSum: borderAndPaddingLogicalHeight(), aspectRatio: aspectRatio!,
          boxSizing: style().boxSizingForAspectRatio(), blockSize: blockMinSize,
          aspectRatioType: style().aspectRatioType(),
          isRenderReplaced: isRenderReplaced())
      }
    }
    if style().logicalMaxHeight().isSpecified() {
      let blockMaxSize = constrainLogicalHeightByMinMax(
        logicalHeight: LayoutUnit.max(), intrinsicContentHeight: nil)
      if blockMaxSize != LayoutUnit.max() {
        transferredMaxSize = inlineSizeFromAspectRatio(
          borderPaddingInlineSum: borderAndPaddingLogicalWidth(),
          borderPaddingBlockSum: borderAndPaddingLogicalHeight(), aspectRatio: aspectRatio!,
          boxSizing: style().boxSizingForAspectRatio(), blockSize: blockMaxSize,
          aspectRatioType: style().aspectRatioType(),
          isRenderReplaced: isRenderReplaced())
      }
    }
    // Spec says the transferred max size should be floored by the transferred min size
    transferredMaxSize = max(transferredMinSize, transferredMaxSize)
    return (transferredMinSize, transferredMaxSize)
  }

  private func computeMinMaxLogicalHeightFromAspectRatio() -> (LayoutUnit, LayoutUnit) {
    var transferredMinSize = LayoutUnit()
    var transferredMaxSize = LayoutUnit.max()
    let aspectRatio = resolveAspectRatio()
    if aspectRatio == nil {
      return (transferredMinSize, transferredMaxSize)
    }

    if style().logicalMinWidth().isSpecified() {
      let inlineMinSize = computeLogicalWidthInFragmentUsing(
        widthType: .MinSize, logicalWidth: style().logicalMinWidth(),
        availableLogicalWidth: containingBlockLogicalWidthForContent(),
        cb: containingBlock()!, fragment: nil)
      if inlineMinSize > LayoutUnit() {
        transferredMinSize = RenderBoxWrapper.blockSizeFromAspectRatio(
          borderPaddingInlineSum: borderAndPaddingLogicalWidth(),
          borderPaddingBlockSum: borderAndPaddingLogicalHeight(),
          aspectRatio: aspectRatio!, boxSizing: style().boxSizingForAspectRatio(),
          inlineSize: inlineMinSize,
          aspectRatioType: style().aspectRatioType(), isRenderReplaced: isRenderReplaced())
      }
    }

    if style().logicalMaxWidth().isSpecified() {
      let inlineMaxSize = computeLogicalWidthInFragmentUsing(
        widthType: .MaxSize, logicalWidth: style().logicalMaxWidth(),
        availableLogicalWidth: containingBlockLogicalWidthForContent(),
        cb: containingBlock()!, fragment: nil)
      if inlineMaxSize != LayoutUnit.max() {
        transferredMaxSize = RenderBoxWrapper.blockSizeFromAspectRatio(
          borderPaddingInlineSum: borderAndPaddingLogicalWidth(),
          borderPaddingBlockSum: borderAndPaddingLogicalHeight(),
          aspectRatio: aspectRatio!, boxSizing: style().boxSizingForAspectRatio(),
          inlineSize: inlineMaxSize,
          aspectRatioType: style().aspectRatioType(), isRenderReplaced: isRenderReplaced())
      }
    }
    // Spec says the transferred max size should be floored by the transferred min size
    transferredMaxSize = max(transferredMinSize, transferredMaxSize)
    return (transferredMinSize, transferredMaxSize)
  }

  private enum ConstrainDimension {
    case Width
    case Height
  }

  private enum MinimumSizeIsAutomaticContentBased {
    case No
    case Yes
  }

  private func constrainLogicalMinMaxSizesByAspectRatio(
    computedMinSize: inout LayoutUnit, computedMaxSize: inout LayoutUnit, computedSize: LayoutUnit,
    minimumSizeType: MinimumSizeIsAutomaticContentBased, dimension: ConstrainDimension
  ) {
    // TODO: Here we use isSpecified() to present the definite value. This is not quite correct, for the definite value should also include
    // a size of the initial containing block and the “stretch-fit” sizing of non-replaced blocks if they have definite values.
    // See https://www.w3.org/TR/css-sizing-3/#definite
    let styleToUse = style()
    assert(styleToUse.hasAspectRatio() || isRenderReplacedWithIntrinsicRatio())
    let logicalSize = dimension == .Width ? styleToUse.logicalWidth() : styleToUse.logicalHeight()
    // https://www.w3.org/TR/css-sizing-4/#aspect-ratio-minimum
    if minimumSizeType == .Yes {
      // Only use Automatic Content-based Minimum Sizes in the ratio-dependent axis.
      if logicalSize.isSpecified() {
        computedMinSize = min(computedMinSize, computedSize)
      }
      computedMinSize = min(computedMinSize, computedMaxSize)
    }

    if logicalSize.isSpecified() {
      return
    }

    // Sizing constraints in either axis (the origin axis) should be transferred through the preferred aspect ratio. See https://www.w3.org/TR/css-sizing-4/#aspect-ratio-size-transfers
    let shouldCheckTransferredMinSize =
      dimension == .Width
      ? !styleToUse.logicalMinWidth().isSpecified() : !styleToUse.logicalMinHeight().isSpecified()
    let shouldCheckTransferredMaxSize =
      dimension == .Width
      ? !styleToUse.logicalMaxWidth().isSpecified() : !styleToUse.logicalMaxHeight().isSpecified()
    if !shouldCheckTransferredMaxSize && !shouldCheckTransferredMinSize {
      return
    }

    var (transferredLogicalMinSize, transferredLogicalMaxSize) =
      dimension == .Width
      ? computeMinMaxLogicalWidthFromAspectRatio() : computeMinMaxLogicalHeightFromAspectRatio()
    if shouldCheckTransferredMaxSize && transferredLogicalMaxSize != LayoutUnit.max() {
      // The transferred max size should be floored by the definite minimum size.
      if !shouldCheckTransferredMinSize && minimumSizeType == .No {
        transferredLogicalMaxSize = max(transferredLogicalMaxSize, computedMinSize)
      }
      computedMaxSize = min(computedMaxSize, transferredLogicalMaxSize)
      if minimumSizeType == .Yes {
        computedMinSize = min(computedMinSize, computedMaxSize)
      }
    }

    if shouldCheckTransferredMinSize && transferredLogicalMinSize > LayoutUnit() {
      // The transferred min size should be capped by the definite maximum size.
      if !shouldCheckTransferredMaxSize {
        transferredLogicalMinSize = min(transferredLogicalMinSize, computedMaxSize)
      }
      computedMinSize = max(computedMinSize, transferredLogicalMinSize)
    }
  }

  static func blockSizeFromAspectRatio(
    borderPaddingInlineSum: LayoutUnit, borderPaddingBlockSum: LayoutUnit, aspectRatio: Float64,
    boxSizing: BoxSizing, inlineSize: LayoutUnit, aspectRatioType: AspectRatioType,
    isRenderReplaced: Bool
  ) -> LayoutUnit {
    if boxSizing == .BorderBox && aspectRatioType == .Ratio && !isRenderReplaced {
      return max(borderPaddingBlockSum, LayoutUnit(value: inlineSize / aspectRatio))
    }
    return LayoutUnit(value: (inlineSize - borderPaddingInlineSum) / aspectRatio)
      + borderPaddingBlockSum
  }

  private func replacedMinMaxLogicalHeightComputesAsNone(sizeType: SizeType) -> Bool {
    assert(sizeType == .MinSize || sizeType == .MaxSize)

    let logicalHeight =
      sizeType == .MinSize ? style().logicalMinHeight() : style().logicalMaxHeight()
    let initialLogicalHeight =
      sizeType == .MinSize
      ? RenderStyleWrapper.initialMinSize() : RenderStyleWrapper.initialMaxSize()

    if logicalHeight == initialLogicalHeight {
      return true
    }

    if logicalHeight.isPercentOrCalculated(),
      let overridingContainingBlockContentLogicalHeight =
        overridingContainingBlockContentLogicalHeight()
    {
      return !overridingContainingBlockContentLogicalHeight!.bool()
    }

    // Make sure % min-height and % max-height resolve to none if the containing block has auto height.
    // Note that the "height" case for replaced elements was handled by hasReplacedLogicalHeight, which is why
    // min and max-height are the only ones handled here.
    // FIXME: For now we put in a quirk for iBooks until we can move them to viewport units.
    if let cb = containingBlockForAutoHeightDetection(logicalHeight: logicalHeight) {
      return allowMinMaxPercentagesInAutoHeightBlocksQuirk()
        ? false : cb.hasAutoHeightOrContainingBlockWithAutoHeight()
    }

    return false
  }

  private func computeOrTrimInlineMargin(
    containingBlock: RenderBlockWrapper, marginSide: MarginTrimType,
    computeInlineMargin: () -> LayoutUnit
  ) -> LayoutUnit {
    if containingBlock.shouldTrimChildMarginForBox(type: marginSide, child: self) {
      // FIXME(255434): This should be set when the margin is being trimmed
      // within the context of its layout system (block, flex, grid) and should not
      // be done at this level within RenderBox. We should be able to leave the
      // trimming responsibility to each of those contexts and not need to
      // do any of it here (trimming the margin and setting the rare data bit)
      if isGridItem() && (marginSide == .InlineStart || marginSide == .InlineEnd) {
        markMarginAsTrimmed(newTrimmedMargin: marginSide)
      }
      return LayoutUnit(value: UInt64(0))
    }
    return computeInlineMargin()
  }

  private func computePositionedLogicalHeight(computedValues: inout LogicalExtentComputedValues) {
    if isReplacedOrInlineBlock() {
      computePositionedLogicalHeightReplaced(computedValues: &computedValues)
      return
    }

    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.6.4 "Absolutely positioned, non-replaced elements"
    // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-non-replaced-height>
    // (block-style-comments in this function and in computePositionedLogicalHeightUsing()
    // correspond to text from the spec)

    // We don't use containingBlock(), since we may be positioned by an enclosing relpositioned inline.
    let containerBlock = container() as! RenderBoxModelObjectWrapper

    let containerLogicalHeight = containingBlockLogicalHeightForPositioned(
      containingBlock: containerBlock)

    let styleToUse = style()
    let bordersPlusPadding = borderAndPaddingLogicalHeight()
    let marginBefore = styleToUse.marginBefore()
    let marginAfter = styleToUse.marginAfter()
    let logicalTopLength = styleToUse.logicalTop()
    let logicalBottomLength = styleToUse.logicalBottom()

    /*---------------------------------------------------------------------------*\
     * For the purposes of this section and the next, the term "static position"
     * (of an element) refers, roughly, to the position an element would have had
     * in the normal flow. More precisely, the static position for 'top' is the
     * distance from the top edge of the containing block to the top margin edge
     * of a hypothetical box that would have been the first box of the element if
     * its 'position' property had been 'static' and 'float' had been 'none'. The
     * value is negative if the hypothetical box is above the containing block.
     *
     * But rather than actually calculating the dimensions of that hypothetical
     * box, user agents are free to make a guess at its probable position.
     *
     * For the purposes of calculating the static position, the containing block
     * of fixed positioned elements is the initial containing block instead of
     * the viewport.
    \*---------------------------------------------------------------------------*/

    // see FIXME 1
    // Calculate the static distance if needed.
    computeBlockStaticDistance(
      logicalTop: logicalTopLength, logicalBottom: logicalBottomLength, child: self,
      containerBlock: containerBlock)

    // Calculate constraint equation values for 'height' case.
    let logicalHeight = computedValues.extent
    computePositionedLogicalHeightUsing(
      heightType: .MainOrPreferredSize, logicalHeightLength: styleToUse.logicalHeight(),
      containerBlock: containerBlock, containerLogicalHeight: containerLogicalHeight,
      bordersPlusPadding: bordersPlusPadding, logicalHeight: logicalHeight,
      logicalTop: logicalTopLength, logicalBottom: logicalBottomLength, marginBefore: marginBefore,
      marginAfter: marginAfter,
      computedValues: &computedValues)

    // Avoid doing any work in the common case (where the values of min-height and max-height are their defaults).
    // see FIXME 2

    // Calculate constraint equation values for 'max-height' case.
    if !styleToUse.logicalMaxHeight().isUndefined() {
      var maxValues = LogicalExtentComputedValues()

      computePositionedLogicalHeightUsing(
        heightType: .MaxSize, logicalHeightLength: styleToUse.logicalMaxHeight(),
        containerBlock: containerBlock, containerLogicalHeight: containerLogicalHeight,
        bordersPlusPadding: bordersPlusPadding, logicalHeight: logicalHeight,
        logicalTop: logicalTopLength, logicalBottom: logicalBottomLength,
        marginBefore: marginBefore,
        marginAfter: marginAfter,
        computedValues: &maxValues)

      if computedValues.extent > maxValues.extent {
        computedValues.extent = maxValues.extent
        computedValues.position = maxValues.position
        computedValues.margins.before = maxValues.margins.before
        computedValues.margins.after = maxValues.margins.after
      }
    }

    // Calculate constraint equation values for 'min-height' case.
    let logicalMinHeight = styleToUse.logicalMinHeight()
    if logicalMinHeight.isAuto() || !logicalMinHeight.isZero() || logicalMinHeight.isIntrinsic() {
      var minValues = LogicalExtentComputedValues()

      computePositionedLogicalHeightUsing(
        heightType: .MinSize, logicalHeightLength: styleToUse.logicalMinHeight(),
        containerBlock: containerBlock, containerLogicalHeight: containerLogicalHeight,
        bordersPlusPadding: bordersPlusPadding, logicalHeight: logicalHeight,
        logicalTop: logicalTopLength, logicalBottom: logicalBottomLength,
        marginBefore: marginBefore,
        marginAfter: marginAfter,
        computedValues: &minValues)

      if computedValues.extent < minValues.extent {
        computedValues.extent = minValues.extent
        computedValues.position = minValues.position
        computedValues.margins.before = minValues.margins.before
        computedValues.margins.after = minValues.margins.after
      }
    }

    // Set final height value.
    computedValues.extent += bordersPlusPadding

    // Adjust logicalTop if we need to for perpendicular writing modes in fragments.
    // FIXME: Add support for other types of objects as containerBlock, not only RenderBlock.
    if enclosingFragmentedFlow() != nil
      && isHorizontalWritingMode() != containerBlock.isHorizontalWritingMode(),
      let renderBox = containerBlock as? RenderBlockWrapper
    {
      assert(containerBlock.canHaveBoxInfoInFragment())
      let cbPageOffset = renderBox.offsetFromLogicalTopOfFirstPage() - logicalLeft()
      if let cbFragment = renderBox.fragmentAtBlockOffset(blockOffset: cbPageOffset),
        let boxInfo = renderBox.renderBoxFragmentInfo(fragment: cbFragment)
      {
        computedValues.position = computedValues.position + boxInfo.logicalLeft
      }
    }
  }

  private func computePositionedLogicalHeightUsing(
    heightType: SizeType, logicalHeightLength: LengthWrapper,
    containerBlock: RenderBoxModelObjectWrapper, containerLogicalHeight: LayoutUnit,
    bordersPlusPadding: LayoutUnit, logicalHeight: LayoutUnit, logicalTop: LengthWrapper,
    logicalBottom: LengthWrapper, marginBefore: LengthWrapper, marginAfter: LengthWrapper,
    computedValues: inout LogicalExtentComputedValues
  ) {
    assert(
      heightType == .MinSize || heightType == .MainOrPreferredSize || !logicalHeightLength.isAuto())
    var logicalHeightLength = logicalHeightLength
    if heightType == .MinSize && logicalHeightLength.isAuto() {
      if shouldComputeLogicalHeightFromAspectRatio() {
        logicalHeightLength = LengthWrapper(value: logicalHeight, type: .Fixed)
      } else {
        logicalHeightLength = LengthWrapper(value: Int32(0), type: .Fixed)
      }
    }

    // 'top' and 'bottom' cannot both be 'auto' because 'top would of been
    // converted to the static position in computePositionedLogicalHeight()
    assert(!(logicalTop.isAuto() && logicalBottom.isAuto()))

    let contentLogicalHeight = logicalHeight - bordersPlusPadding

    let containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(
      containingBlock: containerBlock, fragment: nil, checkForPerpendicularWritingMode: false)

    let fromAspectRatio =
      heightType == .MainOrPreferredSize && shouldComputeLogicalHeightFromAspectRatio()
    var logicalHeightIsAuto = logicalHeightLength.isAuto() && !fromAspectRatio
    let logicalTopIsAuto = logicalTop.isAuto()
    let logicalBottomIsAuto = logicalBottom.isAuto()

    // Height is never unsolved for tables.
    var resolvedLogicalHeight = LayoutUnit()
    if isRenderTable() {
      resolvedLogicalHeight = contentLogicalHeight
      logicalHeightIsAuto = false
    } else {
      if logicalHeightLength.isIntrinsic() {
        resolvedLogicalHeight = adjustContentBoxLogicalHeightForBoxSizing(
          height: computeIntrinsicLogicalContentHeightUsing(
            logicalHeightLength: logicalHeightLength, intrinsicContentHeight: contentLogicalHeight,
            borderAndPadding: bordersPlusPadding)
            ?? LayoutUnit(value: UInt64(0)))
      } else if fromAspectRatio {
        resolvedLogicalHeight = RenderBoxWrapper.blockSizeFromAspectRatio(
          borderPaddingInlineSum: horizontalBorderAndPaddingExtent(),
          borderPaddingBlockSum: verticalBorderAndPaddingExtent(),
          aspectRatio: style().logicalAspectRatio(), boxSizing: style().boxSizingForAspectRatio(),
          inlineSize: logicalWidth(),
          aspectRatioType: style().aspectRatioType(), isRenderReplaced: isRenderReplaced())
        resolvedLogicalHeight = max(LayoutUnit(), resolvedLogicalHeight - bordersPlusPadding)
      } else {
        resolvedLogicalHeight = adjustContentBoxLogicalHeightForBoxSizing(
          height: valueForLength(length: logicalHeightLength, maximumValue: containerLogicalHeight))
      }
    }

    var logicalHeightValue = LayoutUnit()
    var logicalTopValue = LayoutUnit()

    if !logicalTopIsAuto && !logicalHeightIsAuto && !logicalBottomIsAuto {
      /*-----------------------------------------------------------------------*\
         * If none of the three are 'auto': If both 'margin-top' and 'margin-
         * bottom' are 'auto', solve the equation under the extra constraint that
         * the two margins get equal values. If one of 'margin-top' or 'margin-
         * bottom' is 'auto', solve the equation for that value. If the values
         * are over-constrained, ignore the value for 'bottom' and solve for that
         * value.
        \*-----------------------------------------------------------------------*/
      // NOTE:  It is not necessary to solve for 'bottom' in the over constrained
      // case because the value is not used for any further calculations.

      logicalHeightValue = resolvedLogicalHeight
      logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)

      let availableSpace =
        containerLogicalHeight
        - (logicalTopValue + logicalHeightValue
          + valueForLength(length: logicalBottom, maximumValue: containerLogicalHeight)
          + bordersPlusPadding)

      // Margins are now the only unknown
      if marginBefore.isAuto() && marginAfter.isAuto() {
        // Both margins auto, solve for equality
        // NOTE: This may result in negative values.
        computedValues.margins.before = availableSpace / 2  // split the difference
        computedValues.margins.after = availableSpace - computedValues.margins.before  // account for odd valued differences
      } else if marginBefore.isAuto() {
        // Solve for top margin
        computedValues.margins.after = valueForLength(
          length: marginAfter, maximumValue: containerRelativeLogicalWidth)
        computedValues.margins.before = availableSpace - computedValues.margins.after
      } else if marginAfter.isAuto() {
        // Solve for bottom margin
        computedValues.margins.before = valueForLength(
          length: marginBefore, maximumValue: containerRelativeLogicalWidth)
        computedValues.margins.after = availableSpace - computedValues.margins.before
      } else {
        // Over-constrained, (no need solve for bottom)
        computedValues.margins.before = valueForLength(
          length: marginBefore, maximumValue: containerRelativeLogicalWidth)
        computedValues.margins.after = valueForLength(
          length: marginAfter, maximumValue: containerRelativeLogicalWidth)

        if isOrthogonal(renderer: self, ancestor: containerBlock) {
          // When orthogonal we want to explicitly deal with left/right instead of top/bottom, so compute physical left next.
          logicalTopValue = valueForLength(
            length: style().left(), maximumValue: containerLogicalHeight)
          if containerBlock.style().direction() == .RTL {
            // Recompute availableSpace with physical left.
            let availableSpace =
              containerLogicalHeight
              - (logicalTopValue + logicalHeightValue
                + valueForLength(length: style().right(), maximumValue: containerLogicalHeight)
                + bordersPlusPadding)
            logicalTopValue =
              (availableSpace + logicalTopValue) - computedValues.margins.before
              - computedValues.margins.after
          }
        }
      }
    } else {
      /*--------------------------------------------------------------------*\
         * Otherwise, set 'auto' values for 'margin-top' and 'margin-bottom'
         * to 0, and pick the one of the following six rules that applies.
         *
         * 1. 'top' and 'height' are 'auto' and 'bottom' is not 'auto', then
         *    the height is based on the content, and solve for 'top'.
         *
         *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
         * ------------------------------------------------------------------
         * 2. 'top' and 'bottom' are 'auto' and 'height' is not 'auto', then
         *    set 'top' to the static position, and solve for 'bottom'.
         * ------------------------------------------------------------------
         *
         * 3. 'height' and 'bottom' are 'auto' and 'top' is not 'auto', then
         *    the height is based on the content, and solve for 'bottom'.
         * 4. 'top' is 'auto', 'height' and 'bottom' are not 'auto', and
         *    solve for 'top'.
         * 5. 'height' is 'auto', 'top' and 'bottom' are not 'auto', and
         *    solve for 'height'.
         * 6. 'bottom' is 'auto', 'top' and 'height' are not 'auto', and
         *    solve for 'bottom'.
        \*--------------------------------------------------------------------*/
      // NOTE: For rules 3 and 6 it is not necessary to solve for 'bottom'
      // because the value is not used for any further calculations.

      // Calculate margins, 'auto' margins are ignored.
      computedValues.margins.before = minimumValueForLength(
        length: marginBefore, maximumValue: containerRelativeLogicalWidth)
      computedValues.margins.after = minimumValueForLength(
        length: marginAfter, maximumValue: containerRelativeLogicalWidth)

      let availableSpace =
        containerLogicalHeight
        - (computedValues.margins.before + computedValues.margins.after + bordersPlusPadding)

      // Use rule/case that applies.
      if logicalTopIsAuto && logicalHeightIsAuto && !logicalBottomIsAuto {
        // RULE 1: (height is content based, solve of top)
        logicalHeightValue = contentLogicalHeight
        logicalTopValue =
          availableSpace
          - (logicalHeightValue
            + valueForLength(length: logicalBottom, maximumValue: containerLogicalHeight))
      } else if !logicalTopIsAuto && logicalHeightIsAuto && logicalBottomIsAuto {
        // RULE 3: (height is content based, no need solve of bottom)
        logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)
        logicalHeightValue = contentLogicalHeight
      } else if logicalTopIsAuto && !logicalHeightIsAuto && !logicalBottomIsAuto {
        // RULE 4: (solve of top)
        logicalHeightValue = resolvedLogicalHeight
        logicalTopValue =
          availableSpace
          - (logicalHeightValue
            + valueForLength(length: logicalBottom, maximumValue: containerLogicalHeight))
      } else if !logicalTopIsAuto && logicalHeightIsAuto && !logicalBottomIsAuto {
        // RULE 5: (solve of height)
        logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)
        logicalHeightValue = max(
          LayoutUnit(value: 0),
          availableSpace
            - (logicalTopValue
              + valueForLength(length: logicalBottom, maximumValue: containerLogicalHeight))
        )
      } else if !logicalTopIsAuto && !logicalHeightIsAuto && logicalBottomIsAuto {
        // RULE 6: (no need solve of bottom)
        logicalHeightValue = resolvedLogicalHeight
        logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)
      }
    }
    computedValues.extent = logicalHeightValue

    // Use computed values to calculate the vertical position.
    computedValues.position = logicalTopValue + computedValues.margins.before
    computeLogicalTopPositionedOffset(
      logicalTopPos: &computedValues.position, child: self,
      logicalHeightValue: logicalHeightValue + bordersPlusPadding, containerBlock: containerBlock,
      containerLogicalHeightForPositioned: containerLogicalHeight,
      logicalTopIsAuto: style().logicalTop().isAuto(),
      logicalBottomIsAuto: style().logicalBottom().isAuto())
  }

  private func computePositionedLogicalHeightReplaced(
    computedValues: inout LogicalExtentComputedValues
  ) {
    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.6.5 "Absolutely positioned, replaced elements"
    // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-replaced-height>
    // (block-style-comments in this function correspond to text from the spec and
    // the numbers correspond to numbers in spec)

    // We don't use containingBlock(), since we may be positioned by an enclosing relpositioned inline.
    let containerBlock = container() as! RenderBoxModelObjectWrapper

    let containerLogicalHeight = containingBlockLogicalHeightForPositioned(
      containingBlock: containerBlock)
    let containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(
      containingBlock: containerBlock, fragment: nil, checkForPerpendicularWritingMode: false)

    // Variables to solve.
    let marginBefore = style().marginBefore()
    let marginAfter = style().marginAfter()

    let originalLogicalTop = style().logicalTop()
    let originalLogicalBottom = style().logicalBottom()
    let logicalTop = originalLogicalTop
    let logicalBottom = originalLogicalBottom

    /*-----------------------------------------------------------------------*\
     * 1. The used value of 'height' is determined as for inline replaced
     *    elements.
    \*-----------------------------------------------------------------------*/
    // NOTE: This value of height is final in that the min/max height calculations
    // are dealt with in computeReplacedHeight().  This means that the steps to produce
    // correct max/min in the non-replaced version, are not necessary.
    computedValues.extent = computeReplacedLogicalHeight() + borderAndPaddingLogicalHeight()
    let availableSpace = containerLogicalHeight - computedValues.extent

    /*-----------------------------------------------------------------------*\
     * 2. If both 'top' and 'bottom' have the value 'auto', replace 'top'
     *    with the element's static position.
    \*-----------------------------------------------------------------------*/
    // see FIXME 1
    computeBlockStaticDistance(
      logicalTop: logicalTop, logicalBottom: logicalBottom, child: self,
      containerBlock: containerBlock)

    /*-----------------------------------------------------------------------*\
     * 3. If 'bottom' is 'auto', replace any 'auto' on 'margin-top' or
     *    'margin-bottom' with '0'.
    \*-----------------------------------------------------------------------*/
    // FIXME: The spec. says that this step should only be taken when bottom is
    // auto, but if only top is auto, this makes step 4 impossible.
    if logicalTop.isAuto() || logicalBottom.isAuto() {
      if marginBefore.isAuto() {
        marginBefore.setValue(type: .Fixed, value: Int32(0))
      }
      if marginAfter.isAuto() {
        marginAfter.setValue(type: .Fixed, value: Int32(0))
      }
    }

    /*-----------------------------------------------------------------------*\
     * 4. If at this point both 'margin-top' and 'margin-bottom' are still
     *    'auto', solve the equation under the extra constraint that the two
     *    margins must get equal values.
    \*-----------------------------------------------------------------------*/
    var logicalTopValue = LayoutUnit()
    var logicalBottomValue = LayoutUnit()

    if marginBefore.isAuto() && marginAfter.isAuto() {
      // 'top' and 'bottom' cannot be 'auto' due to step 2 and 3 combined.
      assert(!(logicalTop.isAuto() || logicalBottom.isAuto()))

      logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)
      logicalBottomValue = valueForLength(
        length: logicalBottom, maximumValue: containerLogicalHeight)

      let difference = availableSpace - (logicalTopValue + logicalBottomValue)
      // NOTE: This may result in negative values.
      computedValues.margins.before = difference / 2  // split the difference
      computedValues.margins.after = difference - computedValues.margins.before  // account for odd valued differences

      /*-----------------------------------------------------------------------*\
     * 5. If at this point there is only one 'auto' left, solve the equation
     *    for that value.
    \*-----------------------------------------------------------------------*/
    } else if logicalTop.isAuto() {
      computedValues.margins.before = valueForLength(
        length: marginBefore, maximumValue: containerRelativeLogicalWidth)
      computedValues.margins.after = valueForLength(
        length: marginAfter, maximumValue: containerRelativeLogicalWidth)
      logicalBottomValue = valueForLength(
        length: logicalBottom, maximumValue: containerLogicalHeight)

      // Solve for 'top'
      logicalTopValue =
        availableSpace
        - (logicalBottomValue + computedValues.margins.before + computedValues.margins.after)
    } else if logicalBottom.isAuto() {
      computedValues.margins.before = valueForLength(
        length: marginBefore, maximumValue: containerRelativeLogicalWidth)
      computedValues.margins.after = valueForLength(
        length: marginAfter, maximumValue: containerRelativeLogicalWidth)
      logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)

      // Solve for 'bottom'
      // NOTE: It is not necessary to solve for 'bottom' because we don't ever
      // use the value.
    } else if marginBefore.isAuto() {
      computedValues.margins.after = valueForLength(
        length: marginAfter, maximumValue: containerRelativeLogicalWidth)
      logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)
      logicalBottomValue = valueForLength(
        length: logicalBottom, maximumValue: containerLogicalHeight)

      // Solve for 'margin-top'
      computedValues.margins.before =
        availableSpace - (logicalTopValue + logicalBottomValue + computedValues.margins.after)
    } else if marginAfter.isAuto() {
      computedValues.margins.before = valueForLength(
        length: marginBefore, maximumValue: containerRelativeLogicalWidth)
      logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)
      logicalBottomValue = valueForLength(
        length: logicalBottom, maximumValue: containerLogicalHeight)

      // Solve for 'margin-bottom'
      computedValues.margins.after =
        availableSpace - (logicalTopValue + logicalBottomValue + computedValues.margins.before)
    } else {
      // Nothing is 'auto', just calculate the values.
      computedValues.margins.before = valueForLength(
        length: marginBefore, maximumValue: containerRelativeLogicalWidth)
      computedValues.margins.after = valueForLength(
        length: marginAfter, maximumValue: containerRelativeLogicalWidth)
      logicalTopValue = valueForLength(length: logicalTop, maximumValue: containerLogicalHeight)
      // NOTE: It is not necessary to solve for 'bottom' because we don't ever
      // use the value.
    }

    /*-----------------------------------------------------------------------*\
     * 6. If at this point the values are over-constrained, ignore the value
     *    for 'bottom' and solve for that value.
    \*-----------------------------------------------------------------------*/
    // NOTE: It is not necessary to do this step because we don't end up using
    // the value of 'bottom' regardless of whether the values are over-constrained
    // or not.

    // Use computed values to calculate the vertical position.
    var logicalTopPos = logicalTopValue + computedValues.margins.before
    // Border and padding have already been included in computedValues.m_extent.
    computeLogicalTopPositionedOffset(
      logicalTopPos: &logicalTopPos, child: self, logicalHeightValue: computedValues.extent,
      containerBlock: containerBlock, containerLogicalHeightForPositioned: containerLogicalHeight,
      logicalTopIsAuto: originalLogicalTop.isAuto(),
      logicalBottomIsAuto: originalLogicalBottom.isAuto())
    computedValues.position = logicalTopPos
  }

  private func fillAvailableMeasure(availableLogicalWidth: LayoutUnit) -> LayoutUnit {
    var marginStart = LayoutUnit()
    var marginEnd = LayoutUnit()
    return fillAvailableMeasure(
      availableLogicalWidth: availableLogicalWidth, marginStart: &marginStart, marginEnd: &marginEnd
    )
  }

  private func fillAvailableMeasure(
    availableLogicalWidth: LayoutUnit, marginStart: inout LayoutUnit, marginEnd: inout LayoutUnit
  ) -> LayoutUnit {
    let container = containingBlock()
    let isOrthogonalElement = isHorizontalWritingMode() != container!.isHorizontalWritingMode()
    let marginStartLength = style().marginStart()
    let marginEndLength = style().marginEnd()
    let availableSizeForResolvingMargin =
      isOrthogonalElement ? containingBlockLogicalWidthForContent() : availableLogicalWidth
    marginStart = computeOrTrimInlineMargin(
      containingBlock: container!, marginSide: .InlineStart,
      computeInlineMargin: {
        return minimumValueForLength(
          length: marginStartLength, maximumValue: availableSizeForResolvingMargin)
      })
    marginEnd = computeOrTrimInlineMargin(
      containingBlock: container!, marginSide: .InlineEnd,
      computeInlineMargin: {
        return minimumValueForLength(
          length: marginEndLength, maximumValue: availableSizeForResolvingMargin)
      })
    return availableLogicalWidth - marginStart - marginEnd
  }

  func computeIntrinsicKeywordLogicalWidths() -> (LayoutUnit, LayoutUnit) {
    return computeIntrinsicLogicalWidths()
  }

  private func topLeftLocationWithFlipping() -> LayoutPointWrapper {
    assert(view().frameView().hasFlippedBlockRenderers())

    let containerBlock = containingBlock()
    if containerBlock == nil || CPtrToInt(containerBlock!.p) == CPtrToInt(p) {
      return location()
    }

    return containerBlock!.flipForWritingModeForChild(child: self, point: location())
  }
}
