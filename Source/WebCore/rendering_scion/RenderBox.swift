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

private let backgroundObscurationTestMaxDepth: UInt32 = 4

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

private func gridStyleHasNotChanged(style: RenderStyleWrapper, oldStyle: RenderStyleWrapper) -> Bool
{
  return
    (oldStyle.gridItemColumnStart() == style.gridItemColumnStart()
    && oldStyle.gridItemColumnEnd() == style.gridItemColumnEnd()
    && oldStyle.gridItemRowStart() == style.gridItemRowStart()
    && oldStyle.gridItemRowEnd() == style.gridItemRowEnd()
    && oldStyle.order() == style.order()
    && oldStyle.hasOutOfFlowPosition() == style.hasOutOfFlowPosition())
}

private func isCandidateForOpaquenessTest(_ childBox: RenderBoxWrapper) -> Bool {
  let childStyle = childBox.style()
  if childStyle.position() != .Static
    && CPtrToInt(childBox.containingBlock()?.id()) != CPtrToInt(childBox.parent()?.id())
  {
    return false
  }
  if childStyle.usedVisibility() != .Visible {
    return false
  }
  if childStyle.shapeOutside() != nil {
    return false
  }
  if !childBox.width().bool() || !childBox.height().bool() {
    return false
  }
  if let childLayer = childBox.layer() {
    if childLayer.isComposited() {
      return false
    }
    // FIXME: Deal with z-index.
    if !childStyle.hasAutoUsedZIndex() {
      return false
    }
    if childLayer.isTransformed() || childLayer.isTransparent() || childLayer.hasFilter() {
      return false
    }
    if !childBox.scrollPosition().isZero() {
      return false
    }
  }
  return true
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

private func computeInlineStaticDistance(
  logicalLeft: inout LengthWrapper, logicalRight: inout LengthWrapper, child: RenderBoxWrapper,
  containerBlock: RenderBoxModelObjectWrapper, containerLogicalWidth: LayoutUnit,
  fragment: RenderFragmentContainerWrapper?
) {
  if !logicalLeft.isAuto() || !logicalRight.isAuto() {
    return
  }

  let parent = child.parent()!
  let parentDirection = parent.style().direction()

  // This method is using enclosingBox() which is wrong for absolutely
  // positioned grid items, as they rely on the grid area. So for grid items if
  // both "left" and "right" properties are "auto", we can consider that one of
  // them (depending on the direction) is simply "0".
  if parent.isRenderGrid() && CPtrToInt(parent.id()) == CPtrToInt(child.containingBlock()?.id()) {
    if parentDirection == .LTR {
      logicalLeft.setValue(type: .Fixed, value: Int32(0))
    } else {
      logicalRight.setValue(type: .Fixed, value: Int32(0))
    }
    return
  }

  // For orthogonal flows we don't care whether the parent is LTR or RTL because it does not affect the position in our inline axis.
  var fragment = fragment
  if parentDirection == .LTR || isOrthogonal(renderer: child, ancestor: parent) {
    var staticPosition =
      isOrthogonal(renderer: child, ancestor: parent)
      ? child.layer()!.staticBlockPosition() - containerBlock.borderBefore()
      : child.layer()!.staticInlinePosition() - containerBlock.borderLogicalLeft()
    var current: RenderElementWrapper? = parent
    while current != nil && CPtrToInt(current!.id()) != CPtrToInt(containerBlock.id()) {
      let renderBox = current as? RenderBoxWrapper
      if renderBox == nil {
        current = current!.container()
        continue
      }
      staticPosition +=
        isOrthogonal(renderer: child, ancestor: parent)
        ? renderBox!.logicalTop() : renderBox!.logicalLeft()
      if renderBox!.isInFlowPositioned() {
        staticPosition +=
          renderBox!.isHorizontalWritingMode()
          ? renderBox!.offsetForInFlowPosition().width()
          : renderBox!.offsetForInFlowPosition().height()
      }
      if fragment != nil, let currentBlock = current as? RenderBlockWrapper {
        fragment = currentBlock.clampToStartAndEndFragments(fragment: fragment)
        if let boxInfo = currentBlock.renderBoxFragmentInfo(fragment: fragment) {
          staticPosition += boxInfo.logicalLeft
        }
      }
      current = current!.container()
    }
    logicalLeft.setValue(type: .Fixed, value: staticPosition)
  } else {
    assert(!isOrthogonal(renderer: child, ancestor: parent))
    var staticPosition =
      child.layer()!.staticInlinePosition() + containerLogicalWidth
      + containerBlock.borderLogicalLeft()
    let enclosingBox = parent.enclosingBox()
    if CPtrToInt(enclosingBox.id()) != CPtrToInt(containerBlock.id())
      && containerBlock.isDescendantOf(ancestor: enclosingBox)
    {
      logicalRight.setValue(type: .Fixed, value: staticPosition)
      return
    }
    staticPosition -= enclosingBox.logicalWidth()
    var current: RenderElementWrapper? = enclosingBox
    while current != nil {
      let renderBox = current as? RenderBoxWrapper
      if renderBox == nil {
        current = current!.container()
        continue
      }

      if CPtrToInt(current!.id()) != CPtrToInt(containerBlock.id()) {
        staticPosition -= renderBox!.logicalLeft()
        if renderBox!.isInFlowPositioned() {
          staticPosition -=
            renderBox!.isHorizontalWritingMode()
            ? renderBox!.offsetForInFlowPosition().width()
            : renderBox!.offsetForInFlowPosition().height()
        }
      }
      if fragment != nil, let currentBlock = current as? RenderBlockWrapper {
        fragment = currentBlock.clampToStartAndEndFragments(fragment: fragment)
        if let boxInfo = currentBlock.renderBoxFragmentInfo(fragment: fragment) {
          if CPtrToInt(current!.id()) != CPtrToInt(containerBlock.id()) {
            staticPosition -=
              currentBlock.logicalWidth() - (boxInfo.logicalLeft + boxInfo.logicalWidth)
          }
          if CPtrToInt(current!.id()) == CPtrToInt(enclosingBox.id()) {
            staticPosition += enclosingBox.logicalWidth() - boxInfo.logicalWidth
          }
        }
      }
      if CPtrToInt(current!.id()) == CPtrToInt(containerBlock.id()) {
        break
      }
      current = current!.container()
    }
    logicalRight.setValue(type: .Fixed, value: staticPosition)
  }
}

private func computeLogicalLeftPositionedOffset(
  logicalLeftPos: inout LayoutUnit, child: RenderBoxWrapper, logicalWidthValue: LayoutUnit,
  containerBlock: RenderBoxModelObjectWrapper, containerLogicalWidth: LayoutUnit,
  logicalLeftIsAuto: Bool, logicalRightIsAuto: Bool
) {
  let logicalLeftAndRightAreAuto = logicalLeftIsAuto && logicalRightIsAuto
  let isOverconstrained =
    !logicalLeftIsAuto && !logicalRightIsAuto && !child.style().logicalWidth().isAuto()
  // Deal with differing writing modes here. Our offset needs to be in the containing block's coordinate space. If the containing block is flipped
  // along this axis, then we need to flip the coordinate. Auto positioned items do not need this correction as it was properly handled in
  // computeInlineStaticDistance().
  if isOrthogonal(renderer: child, ancestor: containerBlock) && !logicalLeftAndRightAreAuto
    && !isOverconstrained
    && containerBlock.style().isFlippedBlocksWritingMode()
  {
    logicalLeftPos = containerLogicalWidth - logicalWidthValue - logicalLeftPos
    logicalLeftPos +=
      (child.isHorizontalWritingMode()
        ? containerBlock.borderRight() : containerBlock.borderBottom())
  } else {
    logicalLeftPos +=
      (child.isHorizontalWritingMode() ? containerBlock.borderLeft() : containerBlock.borderTop())
  }
}

private func positionWithRTLInlineBoxContainingBlock(
  containingBlock: RenderElementWrapper, logicalLeftValue: LayoutUnit,
  marginLogicalLeftValue: LayoutUnit
) -> Float32? {
  let renderInline = containingBlock as? RenderInlineWrapper
  if renderInline == nil || containingBlock.style().isLeftToRightDirection() {
    return nil
  }

  let firstInlineBox = InlineIterator.firstInlineBoxFor(renderInline: renderInline!)
  if firstInlineBox.bool() {
    return nil
  }

  var lastInlineBox = firstInlineBox
  while lastInlineBox.get().nextInlineBox().bool() {
    lastInlineBox = lastInlineBox.traverseNextInlineBox()
  }
  if firstInlineBox == lastInlineBox {
    return nil
  }

  let lastInlineBoxPaddingBoxVisualRight =
    lastInlineBox.get().logicalLeftIgnoringInlineDirection() + renderInline!.borderLogicalLeft()
  // FIXME: This does not work with decoration break clone.
  let firstInlineBoxPaddingBoxVisualRight = firstInlineBox.get()
    .logicalLeftIgnoringInlineDirection()
  let distance = lastInlineBoxPaddingBoxVisualRight - firstInlineBoxPaddingBoxVisualRight
  return logicalLeftValue + marginLogicalLeftValue + distance
}

private func shouldFlipStaticPositionInParent(
  outOfFlowBox: RenderBoxWrapper, containerBlock: RenderBoxModelObjectWrapper
) -> Bool {
  assert(outOfFlowBox.isOutOfFlowPositioned())

  let parent = outOfFlowBox.parent()
  if parent == nil || CPtrToInt(parent!.id()) == CPtrToInt(containerBlock.id())
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
  while container != nil && CPtrToInt(container?.id()) != CPtrToInt(containerBlock.id()) {
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

enum ShouldComputePreferred {
  case ComputeActual
  case ComputePreferred
}

enum StretchingMode {
  case `Any`
  case Explicit
}

class RenderBoxWrapper: RenderBoxModelObjectWrapper {
  override init(
    _ type: RenderObjectWrapper.`Type`, _ document: Document, _ style: RenderStyleWrapper,
    _ flags: RenderObjectWrapper.TypeFlag = [],
    _ typeSpecificFlags: RenderObjectWrapper.TypeSpecificFlags =
      RenderObjectWrapper.TypeSpecificFlags()
  ) {
    super.init(type, document, style, flags.union(.IsBox), typeSpecificFlags)
    assert(isRenderBox())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  override func requiresLayer() -> Bool {
    assert(isNativeImpl())
    return super.requiresLayer() || hasNonVisibleOverflow() || style().specifiesColumns()
      || style().containsLayout() || !style().hasAutoUsedZIndex()
      || hasRunningAcceleratedAnimations()
  }

  func requiresLayerWithScrollableArea() -> Bool {
    assert(isNativeImpl())
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

  override final func backgroundIsKnownToBeOpaqueInRect(_ localRect: LayoutRectWrapper) -> Bool {
    assert(isNativeImpl())
    if !BackgroundPainter.paintsOwnBackground(renderer: self) {
      return false
    }

    let backgroundColor = style().visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyBackgroundColor)
    if !backgroundColor.isOpaque() {
      return false
    }

    // If the element has appearance, it might be painted by theme.
    // We cannot be sure if theme paints the background opaque.
    // In this case it is safe to not assume opaqueness.
    // FIXME: May be ask theme if it paints opaque.
    if style().hasUsedAppearance() {
      return false
    }
    // FIXME: Check the opaqueness of background images.

    if hasClip() || hasClipPath() {
      return false
    }

    // FIXME: Use rounded rect if border radius is present.
    if style().hasBorderRadius() {
      return false
    }

    // FIXME: The background color clip is defined by the last layer.
    if style().backgroundLayers().next() != nil {
      return false
    }
    var backgroundRect = LayoutRectWrapper()
    switch style().backgroundClip() {
    case .BorderBox:
      backgroundRect = borderBoxRect()
    case .PaddingBox:
      backgroundRect = paddingBoxRect()
    case .ContentBox:
      backgroundRect = contentBoxRect()
    default:
      break
    }
    return backgroundRect.contains(other: localRect)
  }

  func x() -> LayoutUnit {
    if !isNativeImpl() { return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_x(id())) }
    return m_frameRect.x()
  }

  func y() -> LayoutUnit {
    if !isNativeImpl() { return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_y(id())) }
    return m_frameRect.y()
  }

  func width() -> LayoutUnit {
    if !isNativeImpl() { return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_width(id())) }
    return m_frameRect.width()
  }

  func height() -> LayoutUnit {
    if !isNativeImpl() { return LayoutUnit.fromRawValue(value: RenderBox_height(id())) }
    return m_frameRect.height()
  }

  func setX(x: LayoutUnit) {
    if !isNativeImpl() {
      wk_interop.RenderBox_setX(id(), x.rawValue())
      return
    }
    m_frameRect.setX(x: x)
  }

  func setY(y: LayoutUnit) {
    if !isNativeImpl() {
      wk_interop.RenderBox_setY(id(), y.rawValue())
      return
    }
    m_frameRect.setY(y: y)
  }

  func setWidth(width: LayoutUnit) {
    assert(isNativeImpl())
    m_frameRect.setWidth(width: width)
  }

  func setWidth(width: Float32) {
    assert(isNativeImpl())
    m_frameRect.setWidth(width: width)
  }

  func setWidth(width: Int32) {
    assert(isNativeImpl())
    m_frameRect.setWidth(width: width)
  }

  func setHeight(height: LayoutUnit) {
    assert(isNativeImpl())
    m_frameRect.setHeight(height: height)
  }

  func setHeight(height: Float32) {
    assert(isNativeImpl())
    m_frameRect.setHeight(height: height)
  }

  func setHeight(height: Int32) {
    assert(isNativeImpl())
    m_frameRect.setHeight(height: height)
  }

  func logicalLeft() -> LayoutUnit {
    assert(!isNativeImpl())
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_logicalLeft(id()))
  }

  func logicalTop() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? y() : x()
  }

  func logicalBottom() -> LayoutUnit {
    assert(isNativeImpl())
    return logicalTop() + logicalHeight()
  }

  func logicalWidth() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? width() : height()
  }

  func logicalHeight() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? height() : width()
  }

  enum AllowIntrinsic {
    case No
    case Yes
  }

  func constrainLogicalWidthInFragmentByMinMax(
    logicalWidth: LayoutUnit, availableWidth: LayoutUnit, cb: RenderBlockWrapper,
    fragment: RenderFragmentContainerWrapper?, allowIntrinsic: AllowIntrinsic = .Yes
  ) -> LayoutUnit {
    assert(isNativeImpl())
    let styleToUse = style()
    var computedMaxWidth = LayoutUnit.max()
    if !styleToUse.logicalMaxWidth().isUndefined()
      && (allowIntrinsic == .Yes || !styleToUse.logicalMaxWidth().isIntrinsic())
    {
      computedMaxWidth = computeLogicalWidthInFragmentUsing(
        widthType: .MaxSize, logicalWidth: styleToUse.logicalMaxWidth(),
        availableLogicalWidth: availableWidth, cb: cb, fragment: fragment)
    }

    if allowIntrinsic == .No && styleToUse.logicalMinWidth().isIntrinsic() {
      return min(logicalWidth, computedMaxWidth)
    }

    var logicalMinWidth = styleToUse.logicalMinWidth()
    var computedMinWidth = LayoutUnit()
    var minimumSizeType: MinimumSizeIsAutomaticContentBased = .No
    if logicalMinWidth.isAuto() && shouldComputeLogicalWidthFromAspectRatio()
      && (styleToUse.logicalWidth().isAuto() || styleToUse.logicalWidth().isMinContent()
        || styleToUse.logicalWidth().isMaxContent())
      && !(self is RenderReplacedWrapper) && effectiveOverflowInlineDirection() == .Visible
    {
      // The automatic minimum size in the ratio-dependent axis is  its min-content size. See https://www.w3.org/TR/css-sizing-4/#aspect-ratio-minimum
      logicalMinWidth = LengthWrapper(type: .MinContent)
      minimumSizeType = .Yes
    }
    computedMinWidth = computeLogicalWidthInFragmentUsing(
      widthType: .MinSize, logicalWidth: logicalMinWidth, availableLogicalWidth: availableWidth,
      cb: cb, fragment: fragment)

    if styleToUse.hasAspectRatio() {
      constrainLogicalMinMaxSizesByAspectRatio(
        computedMinSize: &computedMinWidth, computedMaxSize: &computedMaxWidth,
        computedSize: logicalWidth, minimumSizeType: minimumSizeType, dimension: .Width)
    }

    return max(min(logicalWidth, computedMaxWidth), computedMinWidth)
  }

  func constrainLogicalHeightByMinMax(
    logicalHeight: LayoutUnit, intrinsicContentHeight: LayoutUnit?
  ) -> LayoutUnit {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func setLogicalLeft(left: LayoutUnit) {
    assert(isNativeImpl())
    if style().isHorizontalWritingMode() {
      setX(x: left)
    } else {
      setY(y: left)
    }
  }

  func setLogicalTop(top: LayoutUnit) {
    assert(isNativeImpl())
    if style().isHorizontalWritingMode() {
      setY(y: top)
    } else {
      setX(x: top)
    }
  }

  func setLogicalLocation(location: LayoutPointWrapper) {
    assert(isNativeImpl())
    setLocation(p: style().isHorizontalWritingMode() ? location : location.transposedPoint())
  }

  func setLogicalWidth(size: LayoutUnit) {
    assert(isNativeImpl())
    if style().isHorizontalWritingMode() {
      setWidth(width: size)
    } else {
      setHeight(height: size)
    }
  }

  func setLogicalHeight(size: LayoutUnit) {
    assert(isNativeImpl())
    if style().isHorizontalWritingMode() {
      setHeight(height: size)
    } else {
      setWidth(width: size)
    }
  }

  func location() -> LayoutPointWrapper {
    if !isNativeImpl() {
      let rawLocation = wk_interop.RenderBox_location(id())
      return LayoutPointWrapper(
        x: LayoutUnit.fromRawValue(value: rawLocation.x),
        y: LayoutUnit.fromRawValue(value: rawLocation.y))
    }
    return m_frameRect.location()
  }

  func locationOffset() -> LayoutSizeWrapper { return LayoutSizeWrapper(width: x(), height: y()) }

  func size() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    return m_frameRect.size()
  }

  func setLocation(p: LayoutPointWrapper) {
    if !isNativeImpl() {
      wk_interop.RenderBox_setLocation(self.id(), p.x.rawValue(), p.y.rawValue())
      return
    }
    m_frameRect.setLocation(location: p)
  }

  func setSize(_ size: LayoutSizeWrapper) {
    assert(isNativeImpl())
    m_frameRect.setSize(size: size)
  }

  func move(dx: LayoutUnit, dy: LayoutUnit) {
    if !isNativeImpl() {
      wk_interop.RenderBox_move(id(), dx.rawValue(), dy.rawValue())
      return
    }
    m_frameRect.move(dx: dx, dy: dy)
  }

  func frameRect() -> LayoutRectWrapper {
    if !isNativeImpl() {
      let raw = wk_interop.RenderBox_frameRect(id())
      return LayoutRectWrapper(
        x: LayoutUnit.fromRawValue(value: raw.x),
        y: LayoutUnit.fromRawValue(value: raw.y),
        width: LayoutUnit.fromRawValue(value: raw.width),
        height: LayoutUnit.fromRawValue(value: raw.height))
    }
    return m_frameRect
  }

  func setFrameRect(rect: LayoutRectWrapper) {
    assert(isNativeImpl())
    m_frameRect = rect
  }

  func marginBoxRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    let left = resolveLengthPercentageUsingContainerLogicalWidth(style().marginLeft())
    let right = resolveLengthPercentageUsingContainerLogicalWidth(style().marginRight())
    let top = resolveLengthPercentageUsingContainerLogicalWidth(style().marginTop())
    let bottom = resolveLengthPercentageUsingContainerLogicalWidth(style().marginBottom())
    return LayoutRectWrapper(
      x: -left, y: -top, width: size().width() + left + right,
      height: size().height() + top + bottom)
  }

  func borderBoxRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return LayoutRectWrapper(location: LayoutPointWrapper(), size: size())
  }

  override final func borderBoundingBox() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return borderBoxRect()
  }

  // The content area of the box (excludes padding - and intrinsic padding for table cells, etc... - and border).
  func contentBoxRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
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

  func contentBoxLocation() -> LayoutPointWrapper {
    assert(isNativeImpl())
    let verticalScrollbarSpace = LayoutUnit(
      value: (shouldPlaceVerticalScrollbarOnLeftForLayerModelObject()
        || style().scrollbarGutter().bothEdges)
        ? verticalScrollbarWidth() : 0)
    let horizontalScrollbarSpace = LayoutUnit(
      value: style().scrollbarGutter().bothEdges ? horizontalScrollbarHeight() : 0)
    return LayoutPointWrapper(
      x: borderLeft() + paddingLeft() + verticalScrollbarSpace,
      y: borderTop() + paddingTop() + horizontalScrollbarSpace)
  }

  // This returns the content area of the box (excluding padding and border). The only difference with contentBoxRect is that computedCSSContentBoxRect
  // does include the intrinsic padding in the content box as this is what some callers expect (like getComputedStyle).
  func computedCSSContentBoxRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return LayoutRectWrapper(
      x: borderLeft() + computedCSSPaddingLeft(), y: borderTop() + computedCSSPaddingTop(),
      width: paddingBoxWidth() - computedCSSPaddingLeft() - computedCSSPaddingRight()
        - (style().scrollbarGutter().bothEdges ? verticalScrollbarWidth() : 0),
      height: paddingBoxHeight() - computedCSSPaddingTop() - computedCSSPaddingBottom()
        - (style().scrollbarGutter().bothEdges ? horizontalScrollbarHeight() : 0))
  }

  // Bounds of the outline box in absolute coords. Respects transforms
  override final func outlineBoundsForRepaint(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap? = nil
  )
    -> LayoutRectWrapper
  {
    assert(isNativeImpl())
    var box = localOutlineBoundsRepaintRect()

    if CPtrToInt(repaintContainer?.id()) != CPtrToInt(id()) {
      var containerRelativeQuad = FloatQuad()
      if geometryMap != nil {
        containerRelativeQuad = geometryMap!.mapToContainer(box.FloatRect(), repaintContainer)
      } else {
        containerRelativeQuad = localToContainerQuad(
          localQuad: FloatQuad(inRect: box.FloatRect()), container: repaintContainer)
      }

      box = LayoutRectWrapper(r: containerRelativeQuad.boundingBox())
    }

    // FIXME: layoutDelta needs to be applied in parts before/after transforms and
    // repaint containers. https://bugs.webkit.org/show_bug.cgi?id=23308
    box.move(size: view().frameView().layoutContext().layoutDelta())

    return LayoutRectWrapper(
      r: snapRectToDevicePixels(rect: box, pixelSnappingFactor: document().deviceScaleFactor()))
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    assert(isNativeImpl())
    if !size().isEmpty() {
      rects.append(LayoutRectWrapper(location: additionalOffset, size: size()))
    }
  }

  override func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    assert(isNativeImpl())
    return borderBoxRect().FloatRect()
  }

  override func objectBoundingBox() -> FloatRectWrapper {
    assert(isNativeImpl())
    return borderBoxRect().FloatRect()
  }

  // Note these functions are not equivalent of childrenOfType<RenderBox>
  func parentBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    if let box = parent() as? RenderBoxWrapper {
      return box
    }

    assert(parent() == nil)
    return nil
  }

  func firstChildBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    if let box = firstChild() as? RenderBoxWrapper {
      return box
    }

    assert(firstChild() == nil)
    return nil
  }

  func firstInFlowChildBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    return firstInFlowChild() as? RenderBoxWrapper
  }

  func lastChildBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    if let box = lastChild() as? RenderBoxWrapper {
      return box
    }

    assert(lastChild() == nil)
    return nil
  }

  func lastInFlowChildBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    return lastInFlowChild() as? RenderBoxWrapper
  }

  func previousSiblingBox() -> RenderBoxWrapper? {
    if !isNativeImpl() {
      guard let prevSiblingBoxPtr = wk_interop.RenderBox_previousSiblingBox(id()) else {
        return nil
      }
      return createRenderObjectWrapper(prevSiblingBoxPtr) as! RenderBoxWrapper?
    }
    if let box = previousSibling() as? RenderBoxWrapper {
      return box
    }

    assert(previousSibling() == nil)
    return nil
  }

  func previousInFlowSiblingBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    var curr = previousSiblingBox()
    while curr != nil {
      if !curr!.isFloatingOrOutOfFlowPositioned() {
        return curr
      }
      curr = curr!.previousSiblingBox()
    }
    return nil
  }

  func nextSiblingBox() -> RenderBoxWrapper? {
    if !isNativeImpl() {
      guard let nextSiblingBoxPtr = wk_interop.RenderBox_nextSiblingBox(id()) else { return nil }
      return createRenderObjectWrapper(nextSiblingBoxPtr) as! RenderBoxWrapper?
    }
    return nextSibling() as? RenderBoxWrapper
  }

  func nextInFlowSiblingBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    var curr = nextSiblingBox()
    while curr != nil {
      if !curr!.isFloatingOrOutOfFlowPositioned() {
        return curr
      }
      curr = curr!.nextSiblingBox()
    }
    return nil
  }

  // Visual and layout overflow are in the coordinate space of the box.  This means that they aren't purely physical directions.
  // For horizontal-tb and vertical-lr they will match physical directions, but for horizontal-bt and vertical-rl, the top/bottom and left/right
  // respectively are flipped when compared to their physical counterparts.  For example minX is on the left in vertical-lr,
  // but it is on the right in vertical-rl.
  func flippedClientBoxRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    // Because of the special coordinate system used for overflow rectangles (not quite logical, not
    // quite physical), we need to flip the block progression coordinate in vertical-rl and
    // horizontal-bt writing modes. Apart from that, this method does the same as clientBoxRect().

    let borderWidths = borderWidths()
    // Calculate physical padding box.
    var rect = LayoutRectWrapper(
      x: borderWidths.left, y: borderWidths.top,
      width: width() - borderWidths.left - borderWidths.right,
      height: height() - borderWidths.top - borderWidths.bottom)
    // Flip block progression axis if writing mode is vertical-rl or horizontal-bt.
    flipForWritingMode(rect: &rect)
    if hasNonVisibleOverflow() {
      // Subtract space occupied by scrollbars. They are at their physical edge in this coordinate
      // system, so order is important here: first flip, then subtract scrollbars.
      if shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() && isHorizontalWritingMode() {
        rect.move(dx: verticalScrollbarWidth(), dy: Int32(0))
      }
      rect.contract(dw: verticalScrollbarWidth(), dh: horizontalScrollbarHeight())
    }
    return rect
  }

  func layoutOverflowRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return overflow?.layoutOverflowRect() ?? flippedClientBoxRect()
  }

  func logicalLeftLayoutOverflow() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? layoutOverflowRect().x() : layoutOverflowRect().y()
  }

  func logicalRightLayoutOverflow() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? layoutOverflowRect().maxX() : layoutOverflowRect().maxY()
  }

  func visualOverflowRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return overflow?.visualOverflowRect() ?? borderBoxRect()
  }

  func logicalLeftVisualOverflow() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? visualOverflowRect().x() : visualOverflowRect().y()
  }

  func logicalRightVisualOverflow() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? visualOverflowRect().maxX() : visualOverflowRect().maxY()
  }

  // RenderBox's basic implementation accounts for the writing mode (only).
  func allowedLayoutOverflowForBox() -> LayoutOptionalOutsets {
    assert(isNativeImpl())
    var allowance = LayoutOptionalOutsets(top: nil, right: nil, bottom: nil, left: nil)

    // Overflow is in the block's coordinate space and thus is flipped
    // for horizontal-bt and vertical-rl writing modes. This means we can
    // treat horizontal-tb/bt as the same and vertical-lr/rl as the same.

    if isHorizontalWritingMode() {
      allowance.top = LayoutUnit(value: UInt64(0))
      if style().isLeftToRightDirection() {
        allowance.left = LayoutUnit(value: UInt64(0))
      } else {
        allowance.right = LayoutUnit(value: UInt64(0))
      }
    } else {
      allowance.left = LayoutUnit(value: UInt64(0))
      if style().isLeftToRightDirection() {
        allowance.top = LayoutUnit(value: UInt64(0))
      } else {
        allowance.bottom = LayoutUnit(value: UInt64(0))
      }
    }

    return allowance
  }

  func allowedLayoutOverflow() -> LayoutOptionalOutsets {
    assert(isNativeImpl())
    return allowedLayoutOverflowForBox()
  }

  func addLayoutOverflow(rect: LayoutRectWrapper) {
    assert(!isNativeImpl())
    wk_interop.RenderBox_addLayoutOverflow(
      id(),
      LayoutRectRaw(
        x: rect.x().rawValue(),
        y: rect.y().rawValue(),
        width: rect.width().rawValue(),
        height: rect.height().rawValue()))
  }

  func addVisualOverflow(rect: LayoutRectWrapper) {
    assert(!isNativeImpl())
    wk_interop.RenderBox_addVisualOverflow(
      id(),
      LayoutRectRaw(
        x: rect.x().rawValue(),
        y: rect.y().rawValue(),
        width: rect.width().rawValue(),
        height: rect.height().rawValue()))
  }

  func clearOverflow() {
    assert(isNativeImpl())
    overflow = nil
    if let fragmentedFlow = enclosingFragmentedFlow() {
      fragmentedFlow.clearFragmentsOverflow(self)
    }
  }

  func addVisualEffectOverflow() {
    assert(isNativeImpl())
    let hasBoxShadow = style().boxShadow()
    let hasBorderImageOutsets = style().hasBorderImageOutsets()
    let hasOutline = outlineStyleForRepaint().hasOutlineInVisualOverflow()
    if hasBoxShadow == nil && !hasBorderImageOutsets && !hasOutline {
      return
    }

    addVisualOverflow(rect: applyVisualEffectOverflow(borderBox: borderBoxRect()))

    if let fragmentedFlow = enclosingFragmentedFlow() {
      fragmentedFlow.addFragmentsVisualEffectOverflow(box: self)
    }
  }

  func applyVisualEffectOverflow(borderBox: LayoutRectWrapper) -> LayoutRectWrapper {
    assert(isNativeImpl())
    var overflowMinX = borderBox.x()
    var overflowMaxX = borderBox.maxX()
    var overflowMinY = borderBox.y()
    var overflowMaxY = borderBox.maxY()

    // Compute box-shadow overflow first.
    if style().boxShadow() != nil {
      let shadowExtent = style().boxShadowExtent()

      // Note that box-shadow extent's left and top are negative when extends to left and top, respectively.
      overflowMinX = borderBox.x() + shadowExtent.left
      overflowMaxX = borderBox.maxX() + shadowExtent.right
      overflowMinY = borderBox.y() + shadowExtent.top
      overflowMaxY = borderBox.maxY() + shadowExtent.bottom
    }

    // Now compute border-image-outset overflow.
    if style().hasBorderImageOutsets() {
      let borderOutsets = style().borderImageOutsets()

      overflowMinX = min(overflowMinX, borderBox.x() - borderOutsets.left)
      overflowMaxX = max(overflowMaxX, borderBox.maxX() + borderOutsets.right)
      overflowMinY = min(overflowMinY, borderBox.y() - borderOutsets.top)
      overflowMaxY = max(overflowMaxY, borderBox.maxY() + borderOutsets.bottom)
    }

    if outlineStyleForRepaint().hasOutlineInVisualOverflow() {
      let outlineSize = LayoutUnit(value: outlineStyleForRepaint().outlineSize())
      overflowMinX = min(overflowMinX, borderBox.x() - outlineSize)
      overflowMaxX = max(overflowMaxX, borderBox.maxX() + outlineSize)
      overflowMinY = min(overflowMinY, borderBox.y() - outlineSize)
      overflowMaxY = max(overflowMaxY, borderBox.maxY() + outlineSize)
    }
    // Add in the final overflow with shadows and outsets combined.
    return LayoutRectWrapper(
      x: overflowMinX, y: overflowMinY, width: overflowMaxX - overflowMinX,
      height: overflowMaxY - overflowMinY)
  }

  func addOverflowFromChild(child: RenderBoxWrapper) {
    assert(isNativeImpl())
    addOverflowFromChild(child: child, delta: child.locationOffset())
  }

  func addOverflowFromChild(child: RenderBoxWrapper, delta: LayoutSizeWrapper) {
    assert(isNativeImpl())
    addOverflowFromChild(child: child, delta: delta, flippedClientRect: flippedClientBoxRect())
  }

  func addOverflowFromChild(
    child: RenderBoxWrapper, delta: LayoutSizeWrapper, flippedClientRect: LayoutRectWrapper
  ) {
    assert(isNativeImpl())
    // Never allow flow threads to propagate overflow up to a parent.
    if child.isRenderFragmentedFlow() {
      return
    }

    let fragmentedFlow = enclosingFragmentedFlow()
    if fragmentedFlow != nil {
      fragmentedFlow!.addFragmentsOverflowFromChild(box: self, child: child, delta: delta)
    }

    // Only propagate layout overflow from the child if the child isn't clipping its overflow.  If it is, then
    // its overflow is internal to it, and we don't care about it. layoutOverflowRectForPropagation takes care of this
    // and just propagates the border box rect instead.
    var childLayoutOverflowRect = child.layoutOverflowRectForPropagation(style: style())
    childLayoutOverflowRect.move(size: delta)
    addLayoutOverflow(rect: childLayoutOverflowRect, clientBox: flippedClientRect)

    if paintContainmentApplies() {
      return
    }

    // Add in visual overflow from the child. Even if the child clips its overflow, it may still
    // have visual overflow of its own set from box shadows or reflections. It is unnecessary to propagate this
    // overflow if we are clipping our own overflow.
    if hasPotentiallyScrollableOverflow() {
      return
    }

    var childVisualOverflowRect: LayoutRectWrapper? = nil
    // If this block is flowed inside a flow thread, make sure its overflow is propagated to the containing fragments.
    if fragmentedFlow != nil {
      childVisualOverflowRect = computeChildVisualOverflowRect(child: child, delta: delta)
      fragmentedFlow!.addFragmentsVisualOverflow(
        box: self, visualOverflow: childVisualOverflowRect!)
    } else if child.hasSelfPaintingLayer() {
      // Update our visual overflow in case the child spills out the block, but only if we were going to paint
      // the child block ourselves.
      return
    }
    if childVisualOverflowRect == nil {
      childVisualOverflowRect = computeChildVisualOverflowRect(child: child, delta: delta)
    }
    addVisualOverflow(rect: childVisualOverflowRect!)
  }

  private func computeChildVisualOverflowRect(child: RenderBoxWrapper, delta: LayoutSizeWrapper)
    -> LayoutRectWrapper?
  {
    assert(isNativeImpl())
    var childVisualOverflowRect = child.visualOverflowRectForPropagation(parentStyle: style())
    childVisualOverflowRect.move(size: delta)
    return childVisualOverflowRect
  }

  func contentSize() -> LayoutSizeWrapper {
    assert(!isNativeImpl())
    return LayoutSizeWrapper(width: contentWidth(), height: contentHeight())
  }

  func contentWidth() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentWidth(id()))
    }
    return max(
      LayoutUnit(value: UInt64(0)),
      paddingBoxWidth() - paddingLeft() - paddingRight()
        - (style().scrollbarGutter().bothEdges ? verticalScrollbarWidth() : 0))
  }

  func contentHeight() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentHeight(id()))
    }
    return max(
      LayoutUnit(value: UInt64(0)),
      paddingBoxHeight() - paddingTop() - paddingBottom()
        - (style().scrollbarGutter().bothEdges ? horizontalScrollbarHeight() : 0))
  }

  func contentLogicalSize() -> LayoutSizeWrapper {
    assert(!isNativeImpl())
    let width = LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentLogicalSize_width(id()))
    let height = LayoutUnit.fromRawValue(
      value: wk_interop.RenderBox_contentLogicalSize_height(id()))
    return LayoutSizeWrapper(width: width, height: height)
  }

  func contentLogicalWidth() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? contentWidth() : contentHeight()
  }

  func contentLogicalHeight() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? contentHeight() : contentWidth()
  }

  func paddingBoxWidth() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxWidth(id()))
    }
    return max(
      LayoutUnit(value: UInt64(0)),
      width() - borderLeft() - borderRight() - verticalScrollbarWidth())
  }

  func paddingBoxHeight() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxHeight(id()))
    }
    return max(
      LayoutUnit(value: UInt64(0)),
      height() - borderTop() - borderBottom() - horizontalScrollbarHeight())
  }

  func paddingBoxRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    let zero = LayoutUnit(value: UInt64(0))
    var offsetForScrollbar = zero
    var verticalScrollbarWidth = zero
    var horizontalScrollbarHeight = zero
    if hasNonVisibleOverflow() {
      verticalScrollbarWidth = LayoutUnit(value: self.verticalScrollbarWidth())
      offsetForScrollbar =
        shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() ? verticalScrollbarWidth : zero
      horizontalScrollbarHeight = LayoutUnit(value: self.horizontalScrollbarHeight())
    }

    let borderWidths = borderWidths()
    return LayoutRectWrapper(
      x: borderWidths.left + offsetForScrollbar, y: borderWidths.top,
      width: width() - borderWidths.left - borderWidths.right - verticalScrollbarWidth,
      height: height() - borderWidths.top - borderWidths.bottom - horizontalScrollbarHeight)
  }

  func paddingBoxRectIncludingScrollbar() -> LayoutRectWrapper {
    if !isNativeImpl() {
      return LayoutRectWrapper(
        x: LayoutUnit.fromRawValue(
          value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_x(id())),
        y: LayoutUnit.fromRawValue(
          value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_y(id())),
        width: LayoutUnit.fromRawValue(
          value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_width(id())),
        height: LayoutUnit.fromRawValue(
          value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_height(id()))
      )
    }
    let borderWidths = borderWidths()
    return LayoutRectWrapper(
      x: borderWidths.left, y: borderWidths.top,
      width: width() - borderWidths.left - borderWidths.right,
      height: height() - borderWidths.top - borderWidths.bottom)
  }

  // More IE extensions.  clientWidth and clientHeight represent the interior of an object
  // excluding border and scrollbar.
  private func clientLeft() -> LayoutUnit {
    assert(isNativeImpl())
    return borderLeft()
  }

  private func clientTop() -> LayoutUnit {
    assert(isNativeImpl())
    return borderTop()
  }

  func clientWidth() -> LayoutUnit {
    assert(isNativeImpl())
    return paddingBoxWidth()
  }

  func clientHeight() -> LayoutUnit {
    assert(isNativeImpl())
    return paddingBoxHeight()
  }

  func clientLogicalWidth() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? clientWidth() : clientHeight()
  }

  func clientLogicalHeight() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? clientHeight() : clientWidth()
  }

  func clientLogicalBottom() -> LayoutUnit {
    assert(isNativeImpl())
    return borderBefore() + clientLogicalHeight()
  }

  func clientBoxRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return LayoutRectWrapper(
      x: clientLeft(), y: clientTop(), width: clientWidth(), height: clientHeight())
  }

  func scrollWidth() -> Int32 {
    assert(isNativeImpl())
    if hasPotentiallyScrollableOverflow() && layer() != nil {
      return layer()!.scrollWidth()
    }
    // For objects with visible overflow, this matches IE.
    // FIXME: Need to work right with writing modes.
    if style().isLeftToRightDirection() {
      // FIXME: This should use snappedIntSize() instead with absolute coordinates.
      return Int32(
        roundToInt(value: max(clientWidth(), layoutOverflowRect().maxX() - borderLeft())))
    }
    return Int32(
      roundToInt(
        value: clientWidth() - min(LayoutUnit(value: 0), layoutOverflowRect().x() - borderLeft())))
  }

  func scrollHeight() -> Int32 {
    assert(isNativeImpl())
    if hasPotentiallyScrollableOverflow() && layer() != nil {
      return layer()!.scrollHeight()
    }
    // For objects with visible overflow, this matches IE.
    // FIXME: Need to work right with writing modes.
    // FIXME: This should use snappedIntSize() instead with absolute coordinates.
    return Int32(roundToInt(value: max(clientHeight(), layoutOverflowRect().maxY() - borderTop())))
  }

  override func marginBottom() -> LayoutUnit {
    assert(isNativeImpl())
    return marginBox.bottom
  }

  override func marginLeft() -> LayoutUnit {
    assert(isNativeImpl())
    return marginBox.left
  }

  func setMarginTop(margin: LayoutUnit) {
    assert(isNativeImpl())
    marginBox.setTop(margin)
  }

  func setMarginBottom(margin: LayoutUnit) {
    assert(isNativeImpl())
    marginBox.setBottom(margin)
  }

  func setMarginLeft(margin: LayoutUnit) {
    assert(isNativeImpl())
    marginBox.setLeft(margin)
  }

  func setMarginRight(margin: LayoutUnit) {
    assert(isNativeImpl())
    marginBox.setRight(margin)
  }

  func marginLogicalLeft(overrideStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    assert(isNativeImpl())
    return marginBox.start((overrideStyle ?? style()).writingMode())
  }

  override func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_marginBefore(id(), otherStyle?.p!))
    }
    return marginBox.before((otherStyle ?? style()).writingMode())
  }

  override func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    assert(isNativeImpl())
    return marginBox.after((otherStyle ?? style()).writingMode())
  }

  override func marginEnd(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    assert(isNativeImpl())
    return marginBox.end((otherStyle ?? style()).writingMode())
  }

  func marginBlockStart(writingMode: WritingMode) -> LayoutUnit {
    assert(isNativeImpl())
    return marginBox.before(writingMode)
  }

  func marginInlineStart(writingMode: WritingMode) -> LayoutUnit {
    assert(isNativeImpl())
    return marginBox.start(writingMode)
  }

  func setMarginBefore(value: LayoutUnit, overrideStyle: RenderStyleWrapper? = nil) {
    if !isNativeImpl() {
      wk_interop.RenderBox_setMarginBefore(id(), value.rawValue(), overrideStyle?.p)
      return
    }
    marginBox.setBefore(value, (overrideStyle ?? style()).writingMode())
  }

  func setMarginAfter(value: LayoutUnit, overrideStyle: RenderStyleWrapper? = nil) {
    if !isNativeImpl() {
      wk_interop.RenderBox_setMarginAfter(id(), value.rawValue(), overrideStyle?.p)
      return
    }
    marginBox.setAfter(value, (overrideStyle ?? style()).writingMode())
  }

  func setMarginStart(value: LayoutUnit, overrideStyle: RenderStyleWrapper? = nil) {
    assert(isNativeImpl())
    let styleToUse = overrideStyle ?? style()
    marginBox.setStart(
      start: value, writingMode: styleToUse.writingMode(), direction: styleToUse.direction())
  }

  func setMarginEnd(value: LayoutUnit, overrideStyle: RenderStyleWrapper? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSelfCollapsingBlock() -> Bool {
    assert(isNativeImpl())
    return false
  }

  func collapsedMarginBefore() -> LayoutUnit {
    assert(isNativeImpl())
    return marginBefore()
  }

  func collapsedMarginAfter() -> LayoutUnit {
    assert(isNativeImpl())
    return marginAfter()
  }

  func constrainBlockMarginInAvailableSpaceOrTrim(
    containingBlock: RenderBoxWrapper, availableSpace: LayoutUnit, marginSide: MarginTrimType
  ) -> LayoutUnit {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  override func layout() {
    assert(isNativeImpl())
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    var child = firstChild()
    if child == nil {
      clearNeedsLayout()
      return
    }

    let unused = LayoutStateMaintainer(
      root: self, offset: locationOffset(),
      disablePaintOffsetCache: style().isFlippedBlocksWritingMode())
    use(unused)
    while child != nil {
      if child!.needsLayout() {
        (child as! RenderElementWrapper).layout()
      }
      assert((!child!.needsLayout()))
      child = child!.nextSibling()
    }
    invalidateBackgroundObscurationStatus()
    clearNeedsLayout()
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ action: HitTestAction
  ) -> Bool {
    assert(isNativeImpl())
    let adjustedLocation = accumulatedOffset + location()

    // Check kids first.
    var child = lastChild()
    while child != nil {
      if !child!.hasLayer()
        && child!.nodeAtPoint(request, &result, locationInContainer, adjustedLocation, action)
      {
        updateHitTestResult(
          result: &result,
          point: locationInContainer.point() - toLayoutSize(point: adjustedLocation)
        )
        return true
      }
      child = child!.previousSibling()
    }

    // Check our bounds next. For this purpose always assume that we can only be hit in the
    // foreground phase (which is true for replaced elements like images).
    var boundsRect = borderBoxRectInFragment(fragment: nil)
    boundsRect.moveBy(offset: adjustedLocation)
    if visibleToHitTesting(request: request) && action == .HitTestForeground
      && locationInContainer.intersects(rect: boundsRect)
    {
      if !hitTestVisualOverflow(locationInContainer, accumulatedOffset) {
        return false
      }

      if !hitTestClipPath(locationInContainer, accumulatedOffset) {
        return false
      }

      if !hitTestBorderRadius(locationInContainer, accumulatedOffset) {
        return false
      }

      updateHitTestResult(
        result: &result, point: locationInContainer.point() - toLayoutSize(point: adjustedLocation))
      if result.addNodeToListBasedTestResult(
        node: protectedNodeForHitTest(), request: request, locationInContainer: locationInContainer,
        rect: boundsRect) == .Stop
      {
        return true
      }
    }

    return super.nodeAtPoint(request, &result, locationInContainer, accumulatedOffset, action)
  }

  // Hit Testing
  func hitTestVisualOverflow(
    _ hitTestLocation: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper
  ) -> Bool {
    assert(isNativeImpl())
    if isRenderView() {
      return true
    }

    let adjustedLocation = accumulatedOffset + location()
    var overflowBox = visualOverflowRect()
    flipForWritingMode(rect: &overflowBox)
    overflowBox.moveBy(offset: adjustedLocation)
    return hitTestLocation.intersects(rect: overflowBox)
  }

  func hitTestClipPath(
    _ hitTestLocation: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper
  ) -> Bool {
    assert(isNativeImpl())
    if style().clipPath() == nil {
      return true
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hitTestBorderRadius(
    _ hitTestLocation: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper
  ) -> Bool {
    assert(isNativeImpl())
    if isRenderView() || !style().hasBorderRadius() {
      return true
    }

    let adjustedLocation = accumulatedOffset + location()
    var borderRect = borderBoxRect()
    borderRect.moveBy(offset: adjustedLocation)

    let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: borderRect)
    // To handle non-round corners, BorderShape should do the hit-testing.
    return hitTestLocation.intersects(borderShape.deprecatedRoundedRect())
  }

  override func minPreferredLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func maxPreferredLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    assert(isNativeImpl())
    minLogicalWidth = minPreferredLogicalWidth() - borderAndPaddingLogicalWidth()
    maxLogicalWidth = maxPreferredLogicalWidth() - borderAndPaddingLogicalWidth()
  }

  func minimumReplacedHeight() -> LayoutUnit {
    assert(isNativeImpl())
    return LayoutUnit(value: 0)
  }

  func overridingLogicalWidth() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingLogicalHeight() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalHeight(height: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalWidth(width: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearOverridingContentSize() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearOverridingLogicalHeight() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearOverridingLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContentLogicalWidth(_ overridingLogicalWidth: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContentLogicalHeight(overridingLogicalHeight: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  typealias ContainingBlockOverrideValue = LayoutUnit?

  func overridingContainingBlockContentWidth(writingMode: WritingMode)
    -> ContainingBlockOverrideValue?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContainingBlockContentHeight(writingMode: WritingMode)
    -> ContainingBlockOverrideValue?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContainingBlockContentLogicalWidth() -> ContainingBlockOverrideValue? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContainingBlockContentLogicalHeight() -> ContainingBlockOverrideValue? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingContainingBlockContentLogicalWidth(logicalWidth: ContainingBlockOverrideValue) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingContainingBlockContentLogicalHeight(logicalHeight: ContainingBlockOverrideValue)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearOverridingContainingBlockContentSize() {
    assert(!isNativeImpl())
    wk_interop.RenderBox_clearOverridingContainingBlockContentSize(id())
  }

  // These are currently only used by Flexbox code. In some cases we must layout flex items with a different main size
  // (the size in the main direction) than the one specified by the item in order to compute the value of flex basis, i.e.,
  // the initial main size of the flex item before the free space is distributed.
  func overridingLogicalHeightLength() -> LengthWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingLogicalWidthLength() -> LengthWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalHeightLength(height: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalWidthLength(height: LengthWrapper) {
    assert(!isNativeImpl())
    wk_interop.RenderBox_setOverridingLogicalWidthLength(id(), height.p)
  }

  func clearOverridingLogicalHeightLength() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearOverridingLogicalWidthLength() {
    assert(!isNativeImpl())
    wk_interop.RenderBox_clearOverridingLogicalWidthLength(id())
  }

  func markMarginAsTrimmed(newTrimmedMargin: MarginTrimType) {
    assert(isNativeImpl())
    ensureRareData().trimmedMargins.formUnion(newTrimmedMargin)
  }

  func clearTrimmedMarginsMarkings() {
    assert(isNativeImpl())
    assert(hasRareData())
    ensureRareData().trimmedMargins = []
  }

  func hasTrimmedMargin(marginTrimType: MarginTrimType?) -> Bool {
    assert(isNativeImpl())
    if !isInFlow() {
      return false
    }
    if !hasRareData() {
      return false
    }
    return marginTrimType != nil
      ? rareData().trimmedMargins.contains(marginTrimType!) : !rareData().trimmedMargins.isEmpty
  }

  override func offsetFromContainer(
    _ container: RenderElementWrapper, _ physicalPoint: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    assert(isNativeImpl())
    // A fragment "has" boxes inside it without being their container.
    assert(
      CPtrToInt(container.id()) == CPtrToInt(self.container()?.id())
        || container is RenderFragmentContainerWrapper)

    var offset = LayoutSizeWrapper()
    if isInFlowPositioned() {
      offset += offsetForInFlowPosition()
    }

    if !isInline() || isReplacedOrInlineBlock() {
      offset += topLeftLocationOffset()
    }

    if let boxContainer = container as? RenderBoxWrapper {
      offset -= toLayoutSize(point: LayoutPointWrapper(point: boxContainer.scrollPosition()))
    }

    if isAbsolutelyPositioned() && container.isInFlowPositioned(),
      let inlineContainer = container as? RenderInlineWrapper
    {
      offset += inlineContainer.offsetForInFlowPositionedInline(self)
    }

    if offsetDependsOnPoint != nil {
      offsetDependsOnPoint = container is RenderFragmentedFlowWrapper || offsetDependsOnPoint!
    }

    return offset
  }

  func adjustBorderBoxLogicalWidthForBoxSizing(logicalWidth: LengthWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    let width = LayoutUnit(value: logicalWidth.value())
    let bordersPlusPadding = borderAndPaddingLogicalWidth()
    if style().boxSizing() == .ContentBox || logicalWidth.isIntrinsicOrAuto() {
      return width + bordersPlusPadding
    }
    return max(width, bordersPlusPadding)
  }

  func adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: LengthWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    let width = LayoutUnit(value: logicalWidth.value())
    if style().boxSizing() == .ContentBox || logicalWidth.isIntrinsicOrAuto() {
      return max(LayoutUnit(value: UInt64(0)), width)
    }
    return max(LayoutUnit(value: UInt64(0)), width - borderAndPaddingLogicalWidth())
  }

  func adjustContentBoxLogicalWidthForBoxSizing(
    computedLogicalWidth: LayoutUnit, originalType: LengthType
  ) -> LayoutUnit {
    assert(isNativeImpl())
    if originalType == .Calculated {
      return adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: LengthWrapper(value: computedLogicalWidth, type: .Fixed, hasQuirk: false))
    }
    return adjustContentBoxLogicalWidthForBoxSizing(
      logicalWidth: LengthWrapper(value: computedLogicalWidth, type: originalType, hasQuirk: false))
  }

  func adjustBorderBoxLogicalWidthForBoxSizing(
    computedLogicalWidth: LayoutUnit, originalType: LengthType
  ) -> LayoutUnit {
    assert(isNativeImpl())
    if originalType == .Calculated {
      return adjustBorderBoxLogicalWidthForBoxSizing(
        logicalWidth: LengthWrapper(value: computedLogicalWidth, type: .Fixed, hasQuirk: false))
    }
    return adjustBorderBoxLogicalWidthForBoxSizing(
      logicalWidth: LengthWrapper(value: computedLogicalWidth, type: originalType, hasQuirk: false))
  }

  private func adjustBorderBoxLogicalWidthForBoxSizing(
    computedLogicalWidth: Int32, originalType: LengthType
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return adjustBorderBoxLogicalWidthForBoxSizing(
      computedLogicalWidth: LayoutUnit(value: computedLogicalWidth), originalType: originalType)
  }

  // Overridden by fieldsets to subtract out the intrinsic border.
  func adjustBorderBoxLogicalHeightForBoxSizing(height: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    let bordersPlusPadding = borderAndPaddingLogicalHeight()
    if style().boxSizing() == .ContentBox {
      return height + bordersPlusPadding
    }
    return max(height, bordersPlusPadding)
  }

  func adjustContentBoxLogicalHeightForBoxSizing(height: LayoutUnit?) -> LayoutUnit {
    assert(isNativeImpl())
    if var result = height {
      if style().boxSizing() == .BorderBox {
        result -= borderAndPaddingLogicalHeight()
      }
      return max(LayoutUnit(value: UInt64(0)), result)
    }
    return LayoutUnit(value: 0)
  }

  func adjustIntrinsicLogicalHeightForBoxSizing(height: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    if style().boxSizing() == .BorderBox {
      return height + borderAndPaddingLogicalHeight()
    }
    return height
  }

  struct ComputedMarginValues {
    var before = LayoutUnit()
    var after = LayoutUnit()
    var start = LayoutUnit()
    var end = LayoutUnit()
  }

  struct LogicalExtentComputedValues {
    init(
      extent: LayoutUnit = LayoutUnit(), position: LayoutUnit = LayoutUnit(),
      margins: ComputedMarginValues = ComputedMarginValues()
    ) {
      self.extent = extent
      self.position = position
      self.margins = margins
    }

    var extent: LayoutUnit
    var position: LayoutUnit
    var margins: ComputedMarginValues
  }

  // Resolve auto margins in the inline direction of the containing block so that objects can be pushed to the start, middle or end
  // of the containing block.
  func computeInlineDirectionMargins(
    containingBlock: RenderBlockWrapper, containerWidth: LayoutUnit,
    availableSpaceAdjustedWithFloats: LayoutUnit?, childWidth: LayoutUnit,
    marginStart: inout LayoutUnit, marginEnd: inout LayoutUnit
  ) {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func computeAndSetBlockDirectionMargins(containingBlock: RenderBlockWrapper) {
    if !isNativeImpl() {
      let containingBlockRaw = (containingBlock as! RenderViewWrapper).getWk()
      wk_interop.RenderBox_computeAndSetBlockDirectionMargins(id(), containingBlockRaw)
      return
    }
    var marginBefore = LayoutUnit()
    var marginAfter = LayoutUnit()
    computeBlockDirectionMargins(
      containingBlock: containingBlock, marginBefore: &marginBefore, marginAfter: &marginAfter)
    containingBlock.setMarginBeforeForChild(child: self, value: marginBefore)
    containingBlock.setMarginAfterForChild(child: self, value: marginAfter)
  }

  enum RenderBoxFragmentInfoFlags {
    case CacheRenderBoxFragmentInfo
    case DoNotCacheRenderBoxFragmentInfo
  }

  func borderBoxRectInFragment(
    fragment: RenderFragmentContainerWrapper?,
    flags: RenderBoxWrapper.RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> LayoutRectWrapper {
    assert(isNativeImpl())
    return borderBoxRect()
  }

  func clientBoxRectInFragment(_ fragment: RenderFragmentContainerWrapper?) -> LayoutRectWrapper {
    assert(isNativeImpl())
    if fragment == nil {
      return clientBoxRect()
    }

    var clientBox = borderBoxRectInFragment(fragment: fragment)
    let borderWidths = borderWidths()

    clientBox.setLocation(
      location: clientBox.location()
        + LayoutSizeWrapper(width: borderWidths.left, height: borderWidths.top))
    clientBox.setSize(
      size: clientBox.size()
        - LayoutSizeWrapper(
          width: borderWidths.left + borderWidths.right + verticalScrollbarWidth(),
          height: borderWidths.top + borderWidths.bottom + horizontalScrollbarHeight()))

    return clientBox
  }

  func clampToStartAndEndFragments(fragment: RenderFragmentContainerWrapper?)
    -> RenderFragmentContainerWrapper?
  {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    let layoutState = view().frameView().layoutContext().layoutState()
    if (layoutState != nil && !layoutState!.isPaginated())
      || (layoutState == nil && enclosingFragmentedFlow() == nil)
    {
      return LayoutUnit(value: 0)
    }

    let containerBlock = containingBlock()!
    return containerBlock.offsetFromLogicalTopOfFirstPage() + logicalTop()
  }

  override func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    assert(isNativeImpl())
    if isInsideEntirelyHiddenLayer() {
      return RepaintRects()
    }

    var overflowRect = visualOverflowRect()
    // FIXME: layoutDelta needs to be applied in parts before/after transforms and
    // repaint containers. https://bugs.webkit.org/show_bug.cgi?id=23308
    overflowRect.move(size: view().frameView().layoutContext().layoutDelta())

    var rects = RepaintRects(rect: overflowRect)
    if repaintOutlineBounds == .Yes {
      rects.outlineBoundsRect = localOutlineBoundsRepaintRect()
    }

    return rects
  }

  override func computeVisibleRectsInContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    assert(isNativeImpl())
    // The rect we compute at each step is shifted by our x/y offset in the parent container's coordinate space.
    // Only when we cross a writing mode boundary will we have to possibly flipForWritingMode (to convert into a more appropriate
    // offset corner for the enclosing container).  This allows for a fully RL or BT document to repaint
    // properly even during layout, since the rect remains flipped all the way until the end.
    //
    // RenderView::computeVisibleRectInContainer then converts the rect to physical coordinates. We also convert to
    // physical when we hit a repaint container boundary. Therefore the final rect returned is always in the
    // physical coordinate space of the container.
    let styleToUse = style()
    // Paint offset cache is only valid for root-relative, non-fixed position repainting
    if view().frameView().layoutContext().isPaintOffsetCacheEnabled() && container == nil
      && styleToUse.position() != .Fixed && !context.options.contains(.UseEdgeInclusiveIntersection)
    {
      return computeVisibleRectsUsingPaintOffset(rects)
    }

    var adjustedRects = rects
    if hasReflection() {
      let reflectedRects = RepaintRects(rect: reflectedRect(r: adjustedRects.clippedOverflowRect))
      adjustedRects.unite(reflectedRects)
    }

    if CPtrToInt(container?.id()) == CPtrToInt(id()) {
      if container!.style().isFlippedBlocksWritingMode() {
        flipForWritingMode(&adjustedRects)
      }
      if context.descendantNeedsEnclosingIntRect {
        adjustedRects.encloseToIntRects()
      }
      return adjustedRects
    }

    let (localContainer, containerIsSkipped) = self.container(container)
    if localContainer == nil {
      return adjustedRects
    }

    var context = context
    if isWritingModeRoot() {
      if !isOutOfFlowPositioned() || !context.dirtyRectIsFlipped {
        flipForWritingMode(&adjustedRects)
        context.dirtyRectIsFlipped = true
      }
    }

    var locationOffset = self.locationOffset()

    // FIXME: This is needed as long as RenderWidget snaps to integral size/position.
    // TODO(asuhan): optimize this to avoid virtual calls on the fast path
    if self is RenderWidgetWrapper {
      let flooredLocationOffset = LayoutSizeWrapper(size: flooredIntSize(locationOffset))
      adjustedRects.expand(locationOffset - flooredLocationOffset)
      locationOffset = flooredLocationOffset
      context.descendantNeedsEnclosingIntRect = true
    } else if let columnFlow = self as? RenderMultiColumnFlowWrapper {
      // We won't normally run this code. Only when the container is null (i.e., we're trying
      // to get the rect in view coordinates) will we come in here, since normally container
      // will be set and we'll stop at the flow thread. This case is mainly hit by the check for whether
      // or not images should animate.
      // FIXME: Just as with offsetFromContainer, we aren't really handling objects that span multiple columns properly.
      let physicalPoint = flipForWritingMode(position: adjustedRects.clippedOverflowRect.location())
      if let fragment = columnFlow.physicalTranslationFromFlowToFragment(
        physicalPoint: physicalPoint)
      {
        adjustedRects.clippedOverflowRect.setLocation(
          location: fragment.flipForWritingMode(position: physicalPoint))
        return fragment.computeVisibleRectsInContainer(adjustedRects, container, context)
      }
    }

    // We are now in our parent container's coordinate space. Apply our transform to obtain a bounding box
    // in the parent's coordinate space that encloses us.
    let position = styleToUse.position()
    if hasLayer() && layer()!.isTransformed() {
      context.hasPositionFixedDescendant = position == .Fixed
      adjustedRects.transform(layer()!.currentTransform(), document().deviceScaleFactor())
    } else if position == .Fixed {
      context.hasPositionFixedDescendant = true
    }

    adjustedRects.move(locationOffset)

    if position == .Absolute && localContainer!.isInFlowPositioned()
      && localContainer is RenderInlineWrapper
    {
      let offsetForInFlowPosition = (localContainer as! RenderInlineWrapper)
        .offsetForInFlowPositionedInline(self)
      adjustedRects.move(offsetForInFlowPosition)
    } else if styleToUse.hasInFlowPosition() && layer() != nil {
      // Apply the relative position offset when invalidating a rectangle.  The layer
      // is translated, but the render box isn't, so we need to do this to get the
      // right dirty rect. Since this is called from render object's setStyle, the relative position
      // flag on the RenderObject has been cleared, so use the one on the style().
      let offsetForInFlowPosition = layer()!.offsetForInFlowPosition()
      adjustedRects.move(offsetForInFlowPosition)
    }

    if localContainer!.hasNonVisibleOverflow() {
      let isEmpty = !(localContainer! as! RenderLayerModelObjectWrapper)
        .applyCachedClipAndScrollPosition(&adjustedRects, container, context)
      if isEmpty {
        if context.options.contains(.UseEdgeInclusiveIntersection) {
          return nil
        }
        return adjustedRects
      }
    }

    if containerIsSkipped {
      // If the container is below localContainer, then we need to map the rect into container's coordinates.
      let containerOffset = container!.offsetFromAncestorContainer(localContainer!)
      adjustedRects.move(-containerOffset)
      return adjustedRects
    }
    return localContainer!.computeVisibleRectsInContainer(adjustedRects, container, context)
  }

  func repaintDuringLayoutIfMoved(oldRect: LayoutRectWrapper) {
    assert(!isNativeImpl())
    wk_interop.RenderBox_repaintDuringLayoutIfMoved(
      id(),
      LayoutRectRaw(
        x: oldRect.x().rawValue(),
        y: oldRect.y().rawValue(),
        width: oldRect.width().rawValue(),
        height: oldRect.height().rawValue()))
  }

  func repaintOverhangingFloats(paintAllDescendants: Bool) {}

  override func containingBlockLogicalWidthForContent() -> LayoutUnit {
    assert(isNativeImpl())
    if let overridingContainingBlockContentLogicalWidth =
      overridingContainingBlockContentLogicalWidth()
    {
      return overridingContainingBlockContentLogicalWidth ?? LayoutUnit(value: UInt64(0))
    }

    if let containingBlock = containingBlock() {
      return isOutOfFlowPositioned()
        ? containingBlock.clientLogicalWidth() : containingBlock.availableLogicalWidth()
    }

    fatalError("Not reached")
  }

  func containingBlockLogicalHeightForContent(heightType: AvailableLogicalHeightType) -> LayoutUnit
  {
    assert(isNativeImpl())
    if let overridingContainingBlockContentLogicalHeight =
      overridingContainingBlockContentLogicalHeight(),
      let value = overridingContainingBlockContentLogicalHeight
    {
      // FIXME: Containing block for a grid item is the grid area it's located in. We need to return whatever
      // height value we get from overridingContainingBlockContentLogicalHeight() here, including nil.
      return value
    }

    if let containingBlock = containingBlock() {
      return containingBlock.availableLogicalHeight(heightType: heightType)
    }

    fatalError("Not reached")
  }

  private func containingBlockLogicalWidthForPositioned(
    containingBlock: RenderBoxModelObjectWrapper, fragment: RenderFragmentContainerWrapper? = nil,
    checkForPerpendicularWritingMode: Bool = true
  ) -> LayoutUnit {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func containingBlockLogicalWidthForContentInFragment(fragment: RenderFragmentContainerWrapper?)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    if fragment == nil {
      return containingBlockLogicalWidthForContent()
    }

    let cb = containingBlock()
    let containingBlockFragment = cb!.clampToStartAndEndFragments(fragment: fragment)
    // FIXME: It's unclear if a fragment's content should use the containing block's override logical width.
    // If it should, the following line should call containingBlockLogicalWidthForContent.
    let result = cb!.availableLogicalWidth()
    if let boxInfo = cb!.renderBoxFragmentInfo(fragment: containingBlockFragment) {
      return max(LayoutUnit(value: 0), result - (cb!.logicalWidth() - boxInfo.logicalWidth))
    }
    return result
  }

  func containingBlockAvailableLineWidthInFragment(fragment: RenderFragmentContainerWrapper?)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    let cb = containingBlock()
    var containingBlockFragment: RenderFragmentContainerWrapper? = nil
    var logicalTopPosition = logicalTop()
    if fragment != nil {
      let offsetFromLogicalTopOfFragment =
        fragment != nil
        ? fragment!.logicalTopForFragmentedFlowContent() - offsetFromLogicalTopOfFirstPage()
        : LayoutUnit(value: UInt64(0))
      logicalTopPosition = max(
        logicalTopPosition, logicalTopPosition + offsetFromLogicalTopOfFragment)
      containingBlockFragment = cb!.clampToStartAndEndFragments(fragment: fragment)
    }
    return cb!.availableLogicalWidthForLineInFragment(
      position: logicalTopPosition, fragment: containingBlockFragment,
      logicalHeight: availableLogicalHeight(heightType: .IncludeMarginBorderPadding))
  }

  func perpendicularContainingBlockLogicalHeight() -> LayoutUnit {
    assert(isNativeImpl())
    if let overridingContainingBlockContentLogicalHeight =
      overridingContainingBlockContentLogicalHeight(),
      let overridingContainingBlockContentLogicalHeightValue =
        overridingContainingBlockContentLogicalHeight
    {
      return overridingContainingBlockContentLogicalHeightValue
    }

    let containingBlock = containingBlock()!
    if let overridingLogicalHeight = containingBlock.overridingLogicalHeight() {
      return containingBlock.overridingContentLogicalHeight(
        overridingLogicalHeight: overridingLogicalHeight)
    }

    let containingBlockStyle = containingBlock.style()
    let logicalHeightLength = containingBlockStyle.logicalHeight()

    // FIXME: For now just support fixed heights.  Eventually should support percentage heights as well.
    if !logicalHeightLength.isFixed() {
      let fillFallbackExtent = LayoutUnit(
        value: containingBlockStyle.isHorizontalWritingMode()
          ? view().frameView().layoutSize().height : view().frameView().layoutSize().width)
      let fillAvailableExtent = containingBlock.availableLogicalHeight(
        heightType: .ExcludeMarginBorderPadding)
      view().addPercentHeightDescendant(descendant: self)
      // FIXME: https://bugs.webkit.org/show_bug.cgi?id=158286 We also need to perform the same percentHeightDescendant treatment to the element which dictates the return value for containingBlock()->availableLogicalHeight() above.
      return min(fillAvailableExtent, fillFallbackExtent)
    }

    // Use the content box logical height as specified by the style.
    return containingBlock.adjustContentBoxLogicalHeightForBoxSizing(
      height: LayoutUnit(value: logicalHeightLength.value()))
  }

  func updateLogicalWidth() {
    assert(isNativeImpl())
    var computedValues = LogicalExtentComputedValues()
    computeLogicalWidthInFragment(computedValues: &computedValues)

    setLogicalWidth(size: computedValues.extent)
    setLogicalLeft(left: computedValues.position)
    setMarginStart(value: computedValues.margins.start)
    setMarginEnd(value: computedValues.margins.end)
  }

  func updateLogicalHeight() {
    assert(isNativeImpl())
    if shouldApplySizeContainment() && !isRenderGrid() {
      overrideLogicalHeightForSizeContainment()
    }

    cacheIntrinsicContentLogicalHeightForFlexItem(height: contentLogicalHeight())
    let computedValues = computeLogicalHeight(
      logicalHeight: logicalHeight(), logicalTop: logicalTop())
    setLogicalHeight(size: computedValues.extent)
    setLogicalTop(top: computedValues.position)
    setMarginBefore(value: computedValues.margins.before)
    setMarginAfter(value: computedValues.margins.after)
  }

  func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    assert(isNativeImpl())
    return boxComputeLogicalHeight(logicalHeight: logicalHeight, logicalTop: logicalTop)
  }

  func boxComputeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    assert(isNativeImpl())
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

  private func overrideLogicalHeightForSizeContainment() {
    assert(isNativeImpl())
    var intrinsicHeight = LayoutUnit()
    if let height = explicitIntrinsicInnerLogicalHeight() {
      intrinsicHeight = height
    } else if isRenderMenuList() {
      // RenderMenuList has its own theme, if there isn't explicitIntrinsicInnerLogicalHeight,
      // as a size containment, it should be treated as if there is no content, and the height
      // should the original logical height for theme.
      return
    }

    // We need the exact width of border and padding here, yet we can't use borderAndPadding* interfaces.
    // Because these interfaces evetually call borderAfter/Before, and RenderBlock::borderBefore
    // adds extra border to fieldset by adding intrinsicBorderForFieldset which is not needed here.
    let borderAndPadding =
      boxBorderBefore() + boxPaddingBefore() + boxBorderAfter() + boxPaddingAfter()
    setLogicalHeight(size: intrinsicHeight + borderAndPadding + scrollbarLogicalHeight())
  }

  func cacheIntrinsicContentLogicalHeightForFlexItem(height: LayoutUnit) {
    assert(isNativeImpl())
    // FIXME: it should be enough with checking hasOverridingLogicalHeight() as this logic could be shared
    // by any layout system using overrides like grid or flex. However this causes a never ending sequence of calls
    // between layoutBlock() <-> relayoutToAvoidWidows().
    if isFloatingOrOutOfFlowPositioned() {
      return
    }
    let flexibleBox = parent() as? RenderFlexibleBoxWrapper
    if flexibleBox == nil {
      return
    }
    if overridingLogicalHeight() != nil || shouldComputeLogicalHeightFromAspectRatio() {
      return
    }
    flexibleBox!.setCachedFlexItemIntrinsicContentLogicalHeight(flexItem: self, height: height)
  }

  private func paginatedContentNeedsBaseHeight(h: LengthWrapper) -> Bool {
    assert(isNativeImpl())
    if !document().printing() || !h.isPercentOrCalculated() || isInline() {
      return false
    }
    if isDocumentElementRenderer() {
      return true
    }
    let documentElementRenderer = document().documentElement()!.renderer()
    return isBody() && CPtrToInt(parent()?.id()) == CPtrToInt(documentElementRenderer?.id())
      && documentElementRenderer!.style().logicalHeight().isPercentOrCalculated()
  }

  // This function will compute the logical border-box height, without laying
  // out the box. This means that the result is only "correct" when the height
  // is explicitly specified. This function exists so that intrinsic width
  // calculations have a way to deal with children that have orthogonal writing modes.
  // When there is no explicit height, this function assumes a content height of
  // zero (and returns just border + padding).
  func computeLogicalHeightWithoutLayout() -> LayoutUnit {
    assert(isNativeImpl())
    var estimatedHeight = borderAndPaddingLogicalHeight()
    if shouldApplySizeContainment(), let height = explicitIntrinsicInnerLogicalHeight() {
      estimatedHeight += height + scrollbarLogicalHeight()
    }
    let computedValues = computeLogicalHeight(
      logicalHeight: estimatedHeight, logicalTop: LayoutUnit(value: UInt64(0)))
    return computedValues.extent
  }

  func renderBoxFragmentInfo(
    fragment: RenderFragmentContainerWrapper?,
    cacheFlag: RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> RenderBoxFragmentInfo? {
    assert(isNativeImpl())
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

  func computeLogicalWidthInFragment(
    computedValues: inout LogicalExtentComputedValues,
    fragment: RenderFragmentContainerWrapper? = nil
  ) {
    assert(isNativeImpl())
    computedValues.extent = logicalWidth()
    computedValues.position = logicalLeft()
    computedValues.margins.start = marginStart()
    computedValues.margins.end = marginEnd()

    if isOutOfFlowPositioned() {
      // FIXME: This calculation is not patched for block-flow yet.
      // https://bugs.webkit.org/show_bug.cgi?id=46500
      computePositionedLogicalWidth(computedValues: &computedValues, fragment: fragment)
      return
    }

    // The parent box is flexing us, so it has increased or decreased our
    // width.  Use the width from the style context.
    // FIXME: Account for block-flow in flexible boxes.
    // https://bugs.webkit.org/show_bug.cgi?id=46418
    if let overridingLogicalWidth =
      (parent()!.isFlexibleBoxIncludingDeprecated() ? overridingLogicalWidth() : nil)
    {
      computedValues.extent = overridingLogicalWidth
      return
    }

    // FIXME: Account for block-flow in flexible boxes.
    // https://bugs.webkit.org/show_bug.cgi?id=46418
    let inVerticalBox =
      parent()!.isRenderDeprecatedFlexibleBox() && (parent()!.style().boxOrient() == .Vertical)
    let stretching = (parent()!.style().boxAlign() == .Stretch)
    // FIXME: Stretching is the only reason why we don't want the box to be treated as a replaced element, so we could perhaps
    // refactor all this logic, not only for flex and grid since alignment is intended to be applied to any block.
    var treatAsReplaced = shouldComputeSizeAsReplaced() && (!inVerticalBox || !stretching)
    treatAsReplaced = treatAsReplaced && (!isGridItem() || !hasStretchedLogicalWidth())

    let styleToUse = style()
    var logicalWidthLength = LengthWrapper()
    var hasOverridingLogicalWidthLength = false
    if let overridingLogicalWidthLength = overridingLogicalWidthLength() {
      logicalWidthLength = overridingLogicalWidthLength
      hasOverridingLogicalWidthLength = true
    } else {
      logicalWidthLength =
        treatAsReplaced
        ? LengthWrapper(value: computeReplacedLogicalWidth(), type: .Fixed)
        : styleToUse.logicalWidth()
    }

    let cb = containingBlock()!
    let containerLogicalWidth = max(
      LayoutUnit(value: 0), containingBlockLogicalWidthForContentInFragment(fragment: fragment))
    let hasPerpendicularContainingBlock = cb.isHorizontalWritingMode() != isHorizontalWritingMode()

    if isInline() && !isInlineBlockOrInlineTable() {
      // just calculate margins
      computedValues.margins.start = minimumValueForLength(
        length: styleToUse.marginStart(), maximumValue: containerLogicalWidth)
      computedValues.margins.end = minimumValueForLength(
        length: styleToUse.marginEnd(), maximumValue: containerLogicalWidth)
      if treatAsReplaced {
        computedValues.extent = max(
          LayoutUnit(
            value: floatValueForLength(
              length: logicalWidthLength, maximumValue: LayoutUnit(value: 0))
              + borderAndPaddingLogicalWidth()),
          minPreferredLogicalWidth())
      }
      return
    }

    let containerWidthInInlineDirection =
      hasPerpendicularContainingBlock
      ? perpendicularContainingBlockLogicalHeight() : containerLogicalWidth

    // Width calculations
    if let overridingLogicalWidth = (isGridItem() ? overridingLogicalWidth() : nil) {
      computedValues.extent = overridingLogicalWidth
    } else if treatAsReplaced {
      computedValues.extent = LayoutUnit(
        value: logicalWidthLength.value() + borderAndPaddingLogicalWidth())
    } else if shouldComputeLogicalWidthFromAspectRatio() && style().logicalWidth().isAuto() {
      computedValues.extent = computeLogicalWidthFromAspectRatio(fragment: fragment)
    } else {
      let preferredWidth = computeLogicalWidthInFragmentUsing(
        widthType: .MainOrPreferredSize,
        logicalWidth: hasOverridingLogicalWidthLength
          ? logicalWidthLength : styleToUse.logicalWidth(),
        availableLogicalWidth: containerWidthInInlineDirection, cb: cb, fragment: fragment)
      computedValues.extent = constrainLogicalWidthInFragmentByMinMax(
        logicalWidth: preferredWidth, availableWidth: containerWidthInInlineDirection, cb: cb,
        fragment: fragment)
    }

    // Margin calculations.
    if hasPerpendicularContainingBlock || isFloating() || isInline() {
      let marginStartLength = styleToUse.marginStart()
      let marginEndLength = styleToUse.marginEnd()
      computedValues.margins.start = computeOrTrimInlineMargin(
        containingBlock: cb, marginSide: .BlockStart,
        computeInlineMargin: {
          return minimumValueForLength(
            length: marginStartLength, maximumValue: containerLogicalWidth)
        })
      computedValues.margins.end = computeOrTrimInlineMargin(
        containingBlock: cb, marginSide: .BlockEnd,
        computeInlineMargin: {
          return minimumValueForLength(length: marginEndLength, maximumValue: containerLogicalWidth)
        })
    } else {
      var containerLogicalWidthForAutoMargins = containerLogicalWidth
      if avoidsFloats() && cb.containsFloats() {
        containerLogicalWidthForAutoMargins = containingBlockAvailableLineWidthInFragment(
          fragment: fragment)
      }
      let hasInvertedDirection =
        cb.style().isLeftToRightDirection() != style().isLeftToRightDirection()
      if hasInvertedDirection {
        computeInlineDirectionMargins(
          containingBlock: cb, containerWidth: containerLogicalWidth,
          availableSpaceAdjustedWithFloats: containerLogicalWidthForAutoMargins,
          childWidth: computedValues.extent,
          marginStart: &computedValues.margins.end,
          marginEnd: &computedValues.margins.start)
      } else {
        computeInlineDirectionMargins(
          containingBlock: cb, containerWidth: containerLogicalWidth,
          availableSpaceAdjustedWithFloats: containerLogicalWidthForAutoMargins,
          childWidth: computedValues.extent,
          marginStart: &computedValues.margins.start,
          marginEnd: &computedValues.margins.end)
      }
    }

    if !hasPerpendicularContainingBlock && containerLogicalWidth.bool()
      && containerLogicalWidth
        != (computedValues.extent + computedValues.margins.start + computedValues.margins.end)
      && !isFloating() && !isInline() && !cb.isFlexibleBoxIncludingDeprecated()
      && !cb.isRenderGrid()
    {
      let newMarginTotal = containerLogicalWidth - computedValues.extent
      let hasInvertedDirection =
        cb.style().isLeftToRightDirection() != style().isLeftToRightDirection()
      if hasInvertedDirection {
        computedValues.margins.start = newMarginTotal - computedValues.margins.end
      } else {
        computedValues.margins.end = newMarginTotal - computedValues.margins.start
      }
    }
  }

  func stretchesToViewport() -> Bool {
    assert(isNativeImpl())
    return document().inQuirksMode() && style().logicalHeight().isAuto()
      && !isFloatingOrOutOfFlowPositioned() && (isDocumentElementRenderer() || isBody())
      && !shouldComputeLogicalHeightFromAspectRatio() && !isInline()
  }

  func intrinsicSize() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    return LayoutSizeWrapper()
  }

  func intrinsicLogicalWidth() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? intrinsicSize().width() : intrinsicSize().height()
  }

  func intrinsicLogicalHeight() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? intrinsicSize().height() : intrinsicSize().width()
  }

  // Whether or not the element shrinks to its intrinsic width (rather than filling the width
  // of a containing block).  HTML4 buttons, <select>s, <input>s, legends, and floating/compact elements do this.
  enum SizeType {
    case MainOrPreferredSize
    case MinSize
    case MaxSize
  }
  private func sizesLogicalWidthToFitContent(widthType: SizeType) -> Bool {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    if parent()!.isRenderDeprecatedFlexibleBox() && parent()!.style().boxOrient() == .Vertical
      && parent()!.style().boxAlign() == .Stretch
    {
      return true
    }

    // We don't stretch multiline flexboxes because they need to apply line spacing (align-content) first.
    return (parent() is RenderFlexibleBoxWrapper) && parent()!.style().flexWrap() == .NoWrap
      && parent()!.style().isColumnFlexDirection() && columnFlexItemHasStretchAlignment()
  }

  private func columnFlexItemHasStretchAlignment() -> Bool {
    assert(isNativeImpl())
    // auto margins mean we don't stretch. Note that this function will only be
    // used for widths, so we don't have to check marginBefore/marginAfter.
    let parentStyle = parent()!.style()
    assert(parentStyle.isColumnFlexDirection())
    if style().marginStart().isAuto() || style().marginEnd().isAuto() {
      return false
    }
    return style().resolvedAlignSelf(
      parentStyle: parentStyle,
      normalValueBehaviour: containingBlock()!.selfAlignmentNormalBehavior()
    )
    .position == .Stretch
  }

  func shrinkLogicalWidthToAvoidFloats(
    childMarginStart: LayoutUnit, childMarginEnd: LayoutUnit, cb: RenderBlockWrapper,
    fragment: RenderFragmentContainerWrapper?
  ) -> LayoutUnit {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func computeReplacedLogicalWidthUsing(_ widthType: SizeType, _ logicalWidth: LengthWrapper)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    assert(widthType == .MinSize || widthType == .MainOrPreferredSize || !logicalWidth.isAuto())
    if widthType == .MinSize && logicalWidth.isAuto() {
      return adjustContentBoxLogicalWidthForBoxSizing(
        computedLogicalWidth: LayoutUnit(value: 0), originalType: logicalWidth.type())
    }

    switch logicalWidth.type() {
    case .Fixed:
      return adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: logicalWidth)
    case .MinContent, .MaxContent:
      // MinContent/MaxContent don't need the availableLogicalWidth argument.
      return computeIntrinsicLogicalWidthUsing(
        logicalWidthLength: logicalWidth, availableLogicalWidth: LayoutUnit(),
        borderAndPadding: borderAndPaddingLogicalWidth())
        - borderAndPaddingLogicalWidth()
    case .FitContent, .FillAvailable, .Percent, .Calculated:
      var containerWidth = LayoutUnit()
      if isOutOfFlowPositioned() {
        containerWidth = containingBlockLogicalWidthForPositioned(
          containingBlock: container() as! RenderBoxModelObjectWrapper)
      } else if isHorizontalWritingMode() == containingBlock()!.isHorizontalWritingMode() {
        containerWidth = containingBlockLogicalWidthForContent()
      } else {
        containerWidth = perpendicularContainingBlockLogicalHeight()
      }
      let containerLogicalWidth = containingBlock()!.style().logicalWidth()
      // FIXME: Handle cases when containing block width is calculated or viewport percent.
      // https://bugs.webkit.org/show_bug.cgi?id=91071
      if logicalWidth.isIntrinsic() {
        return computeIntrinsicLogicalWidthUsing(
          logicalWidthLength: logicalWidth, availableLogicalWidth: containerWidth,
          borderAndPadding: borderAndPaddingLogicalWidth()) - borderAndPaddingLogicalWidth()
      }
      if containerWidth > 0
        || (!containerWidth.bool()
          && (containerLogicalWidth.isFixed() || containerLogicalWidth.isPercentOrCalculated()))
      {
        return adjustContentBoxLogicalWidthForBoxSizing(
          computedLogicalWidth: minimumValueForLength(
            length: logicalWidth, maximumValue: containerWidth),
          originalType: logicalWidth.type())
      }
      return LayoutUnit(value: UInt64(0))
    case .Intrinsic, .MinIntrinsic, .Auto, .Normal, .Content, .Relative, .Undefined:
      return intrinsicLogicalWidth()
    }
  }

  func computeReplacedLogicalWidthRespectingMinMaxWidth(
    _ logicalWidth: LayoutUnit, _ shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  ) -> LayoutUnit {
    assert(isNativeImpl())
    if shouldIgnoreLogicalMinMaxWidthSizes() {
      return logicalWidth
    }

    let logicalMinWidth = style().logicalMinWidth()
    let logicalMaxWidth = style().logicalMaxWidth()
    let useLogicalWidthForMinWidth =
      (shouldComputePreferred == .ComputePreferred && logicalMinWidth.isPercentOrCalculated())
      || logicalMinWidth.isUndefined()
    let useLogicalWidthForMaxWidth =
      (shouldComputePreferred == .ComputePreferred && logicalMaxWidth.isPercentOrCalculated())
      || logicalMaxWidth.isUndefined()
    let minLogicalWidth =
      useLogicalWidthForMinWidth
      ? logicalWidth : computeReplacedLogicalWidthUsing(.MinSize, logicalMinWidth)
    let maxLogicalWidth =
      useLogicalWidthForMaxWidth
      ? logicalWidth : computeReplacedLogicalWidthUsing(.MaxSize, logicalMaxWidth)
    return max(minLogicalWidth, min(logicalWidth, maxLogicalWidth))
  }

  func computeReplacedLogicalHeightUsing(heightType: SizeType, logicalHeight: LengthWrapper)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    assert(heightType == .MinSize || heightType == .MainOrPreferredSize || !logicalHeight.isAuto())
    // This function should get called with .MinSize/.MaxSize only if replacedMinMaxLogicalHeightComputesAsNone
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

  func computeReplacedLogicalHeightRespectingMinMaxHeight(logicalHeight: LayoutUnit)
    -> LayoutUnit
  {
    assert(isNativeImpl())
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

  func computeReplacedLogicalWidthRespectingMinMaxWidth(
    _ logicalWidth: Float32, _ shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return computeReplacedLogicalWidthRespectingMinMaxWidth(
      LayoutUnit(value: logicalWidth), shouldComputePreferred)
  }

  func computeReplacedLogicalWidthRespectingMinMaxWidth(
    _ logicalWidth: Float64, _ shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  ) -> LayoutUnit {
    assert(isNativeImpl())
    return computeReplacedLogicalWidthRespectingMinMaxWidth(
      LayoutUnit(value: logicalWidth), shouldComputePreferred)
  }

  func computeReplacedLogicalHeightRespectingMinMaxHeight(logicalHeight: Float32)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    return computeReplacedLogicalHeightRespectingMinMaxHeight(
      logicalHeight: LayoutUnit(value: logicalHeight))
  }

  func computeReplacedLogicalWidth(shouldComputePreferred: ShouldComputePreferred = .ComputeActual)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    return computeReplacedLogicalWidthRespectingMinMaxWidth(
      computeReplacedLogicalWidthUsing(.MainOrPreferredSize, style().logicalWidth()),
      shouldComputePreferred)
  }

  func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    assert(isNativeImpl())
    return computeReplacedLogicalHeightRespectingMinMaxHeight(
      logicalHeight: computeReplacedLogicalHeightUsing(
        heightType: .MainOrPreferredSize, logicalHeight: style().logicalHeight()))
  }

  func computePercentageLogicalHeight(
    height: LengthWrapper, updateDescendants: UpdatePercentageHeightDescendants = .Yes
  ) -> LayoutUnit? {
    assert(isNativeImpl())
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
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_availableLogicalWidth(id()))
    }
    return contentLogicalWidth()
  }

  func availableLogicalHeight(heightType: AvailableLogicalHeightType) -> LayoutUnit {
    assert(isNativeImpl())
    return constrainContentBoxLogicalHeightByMinMax(
      logicalHeight: availableLogicalHeightUsing(style().logicalHeight(), heightType),
      intrinsicContentHeight: nil)
  }

  private func availableLogicalHeightUsing(
    _ h: LengthWrapper, _ heightType: AvailableLogicalHeightType
  ) -> LayoutUnit {
    assert(isNativeImpl())
    // We need to stop here, since we don't want to increase the height of the table
    // artificially.  We're going to rely on this cell getting expanded to some new
    // height, and then when we lay out again we'll use the calculation below.
    if isRenderTableCell() && (h.isAuto() || h.isPercentOrCalculated()) {
      if let overridingLogicalHeight = overridingLogicalHeight() {
        return overridingLogicalHeight - computedCSSPaddingBefore() - computedCSSPaddingAfter()
          - borderBefore() - borderAfter() - scrollbarLogicalHeight()
      }
      return logicalHeight() - borderAndPaddingLogicalHeight()
    }

    if let usedFlexItemOverridingLogicalHeightForPercentageResolutionForFlex = isFlexItem()
      ? (parent() as! RenderFlexibleBoxWrapper)
        .usedFlexItemOverridingLogicalHeightForPercentageResolution(flexItem: self) : nil
    {
      return overridingContentLogicalHeight(
        overridingLogicalHeight: usedFlexItemOverridingLogicalHeightForPercentageResolutionForFlex)
    }

    if shouldComputeLogicalHeightFromAspectRatio() {
      let borderAndPaddingLogicalHeight = borderAndPaddingLogicalHeight()
      let borderBoxLogicalHeight = RenderBoxWrapper.blockSizeFromAspectRatio(
        borderPaddingInlineSum: borderAndPaddingLogicalWidth(),
        borderPaddingBlockSum: borderAndPaddingLogicalHeight,
        aspectRatio: style().logicalAspectRatio(),
        boxSizing: style().boxSizingForAspectRatio(), inlineSize: logicalWidth(),
        aspectRatioType: style().aspectRatioType(),
        isRenderReplaced: isRenderReplaced())
      if heightType == .ExcludeMarginBorderPadding {
        return borderBoxLogicalHeight - borderAndPaddingLogicalHeight
      }
      return borderBoxLogicalHeight
    }

    if h.isPercentOrCalculated() && isOutOfFlowPositioned() && !isRenderFragmentedFlow() {
      // FIXME: This is wrong if the containingBlock has a perpendicular writing mode.
      let availableHeight = containingBlockLogicalHeightForPositioned(
        containingBlock: containingBlock()!)
      return adjustContentBoxLogicalHeightForBoxSizing(
        height: valueForLength(length: h, maximumValue: availableHeight))
    }

    if let heightIncludingScrollbar = computeContentAndScrollbarLogicalHeightUsing(
      heightType: .MainOrPreferredSize, height: h, intrinsicContentHeight: nil)
    {
      return max(
        LayoutUnit(value: 0),
        adjustContentBoxLogicalHeightForBoxSizing(height: heightIncludingScrollbar)
          - scrollbarLogicalHeight())
    }

    // Height of absolutely positioned, non-replaced elements section 5.3 rule 5
    // https://www.w3.org/TR/css-position-3/#abs-non-replaced-height
    if let block = self as? RenderBlockWrapper,
      isOutOfFlowPositioned() && style().logicalHeight().isAuto()
        && !(style().logicalTop().isAuto() || style().logicalBottom().isAuto())
    {
      let computedValues = block.computeLogicalHeight(
        logicalHeight: block.logicalHeight(), logicalTop: LayoutUnit(value: 0))
      let contentHeight = computedValues.extent - block.borderAndPaddingLogicalHeight()
      return contentHeight - block.scrollbarLogicalHeight()
    }

    var availableHeight =
      isOrthogonal(renderer: self, ancestor: containingBlock()!)
      ? containingBlockLogicalWidthForContent()
      : containingBlockLogicalHeightForContent(heightType: heightType)
    if heightType == .ExcludeMarginBorderPadding {
      // FIXME: Margin collapsing hasn't happened yet, so this incorrectly removes collapsed margins.
      availableHeight -= marginBefore() + marginAfter() + borderAndPaddingLogicalHeight()
    }
    return availableHeight
  }

  // There are a few cases where we need to refer specifically to the available physical width and available physical height.
  // Relative positioning is one of those cases, since left/top offsets are physical.
  func availableWidth() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? availableLogicalWidth() : availableLogicalHeight(heightType: .IncludeMarginBorderPadding)
  }

  func availableHeight() -> LayoutUnit {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? availableLogicalHeight(heightType: .IncludeMarginBorderPadding) : availableLogicalWidth()
  }

  func verticalScrollbarWidth() -> Int32 {
    assert(isNativeImpl())
    if let scrollableArea = layer() != nil ? layer()!.scrollableArea() : nil {
      return includeVerticalScrollbarSize()
        ? scrollableArea.verticalScrollbarWidth(
          relevancy: .IgnoreOverlayScrollbarSize, isHorizontalWritingMode: isHorizontalWritingMode()
        ) : 0
    }
    return 0
  }

  func horizontalScrollbarHeight() -> Int32 {
    assert(isNativeImpl())
    if let scrollableArea = layer() != nil ? layer()!.scrollableArea() : nil {
      return includeHorizontalScrollbarSize()
        ? scrollableArea.horizontalScrollbarHeight(
          relevancy: .IgnoreOverlayScrollbarSize, isHorizontalWritingMode: isHorizontalWritingMode()
        ) : 0
    }
    return 0
  }

  func intrinsicScrollbarLogicalWidthIncludingGutter() -> Int32 {
    assert(isNativeImpl())
    if !hasNonVisibleOverflow() {
      return 0
    }

    if isHorizontalWritingMode()
      && ((style().overflowY() == .Scroll
        || RenderBoxWrapper.shouldIncludeScrollbarGutter(
          gutter: style().scrollbarGutter(), hasVisibleOverflow: hasScrollableOverflowY(),
          overflow: style().overflowY()))
        && !canUseOverlayScrollbars())
    {
      return style().scrollbarGutter().bothEdges
        ? verticalScrollbarWidth() * 2 : verticalScrollbarWidth()
    }

    if !isHorizontalWritingMode()
      && ((style().overflowX() == .Scroll
        || RenderBoxWrapper.shouldIncludeScrollbarGutter(
          gutter: style().scrollbarGutter(), hasVisibleOverflow: hasScrollableOverflowX(),
          overflow: style().overflowX()))
        && !canUseOverlayScrollbars())
    {
      return style().scrollbarGutter().bothEdges
        ? horizontalScrollbarHeight() * 2 : horizontalScrollbarHeight()
    }

    return 0
  }

  private static func shouldIncludeScrollbarGutter(
    gutter: ScrollbarGutter, hasVisibleOverflow: Bool, overflow: Overflow
  ) -> Bool {
    return (overflow == .Auto && (!gutter.isAuto || hasVisibleOverflow))
      || (overflow == .Hidden && !gutter.isAuto)
  }

  func scrollbarLogicalWidth() -> Int32 {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? verticalScrollbarWidth() : horizontalScrollbarHeight()
  }

  func scrollbarLogicalHeight() -> Int32 {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? horizontalScrollbarHeight() : verticalScrollbarWidth()
  }

  func canBeScrolledAndHasScrollableArea() -> Bool {
    assert(isNativeImpl())
    return canBeProgramaticallyScrolled() && (hasHorizontalOverflow() || hasVerticalOverflow())
  }

  func canBeProgramaticallyScrolled() -> Bool {
    assert(isNativeImpl())
    if isRenderView() {
      return true
    }

    if !hasPotentiallyScrollableOverflow() {
      return false
    }

    if hasScrollableOverflowX() || hasScrollableOverflowY() {
      return true
    }

    return element()?.hasEditableStyle() ?? false
  }

  func canAutoscroll() -> Bool {
    assert(isNativeImpl())
    if isRenderView() {
      return view().frameView().isScrollable()
    }

    // Check for a box that can be scrolled in its own right.
    if canBeScrolledAndHasScrollableArea() {
      return true
    }

    return false
  }

  private func canUseOverlayScrollbars() -> Bool {
    assert(isNativeImpl())
    return !style().usesLegacyScrollbarStyle() && ScrollbarTheme.theme().usesOverlayScrollbars()
  }

  func hasAutoScrollbar(_ orientation: ScrollbarOrientation) -> Bool {
    assert(isNativeImpl())
    if !hasNonVisibleOverflow() {
      return false
    }

    let isAutoOrScrollWithOverlayScrollbar = { [self] (overflow: Overflow) in
      return overflow == .Auto || (overflow == .Scroll && canUseOverlayScrollbars())
    }

    switch orientation {
    case .Horizontal:
      return isAutoOrScrollWithOverlayScrollbar(style().overflowX())
    case .Vertical:
      return isAutoOrScrollWithOverlayScrollbar(style().overflowY())
    }
  }

  func hasAlwaysPresentScrollbar(_ orientation: ScrollbarOrientation) -> Bool {
    assert(isNativeImpl())
    if !hasNonVisibleOverflow() {
      return false
    }

    let isAlwaysVisibleScrollbar = { [self] (overflow: Overflow) in
      return overflow == .Scroll && !canUseOverlayScrollbars()
    }

    switch orientation {
    case .Horizontal:
      return isAlwaysVisibleScrollbar(style().overflowX())
    case .Vertical:
      return isAlwaysVisibleScrollbar(style().overflowY())
    }
  }

  func scrollsOverflow() -> Bool {
    assert(isNativeImpl())
    return scrollsOverflowX() || scrollsOverflowY()
  }

  func scrollsOverflowX() -> Bool {
    assert(isNativeImpl())
    return hasNonVisibleOverflow()
      && (style().overflowX() == .Scroll || style().overflowX() == .Auto)
  }

  func scrollsOverflowY() -> Bool {
    assert(isNativeImpl())
    return hasNonVisibleOverflow()
      && (style().overflowY() == .Scroll || style().overflowY() == .Auto)
  }

  func hasHorizontalOverflow() -> Bool {
    assert(isNativeImpl())
    return scrollWidth() != roundToInt(value: paddingBoxWidth())
  }

  func hasVerticalOverflow() -> Bool {
    assert(isNativeImpl())
    return scrollHeight() != roundToInt(value: paddingBoxHeight())
  }

  private func hasScrollableOverflowX() -> Bool {
    assert(isNativeImpl())
    return scrollsOverflowX() && hasHorizontalOverflow()
  }

  private func hasScrollableOverflowY() -> Bool {
    assert(isNativeImpl())
    return scrollsOverflowY() && hasVerticalOverflow()
  }

  func isScrollContainerX() -> Bool {
    assert(isNativeImpl())
    return style().overflowX() == .Scroll || style().overflowX() == .Hidden
      || style().overflowX() == .Auto
  }

  func isScrollContainerY() -> Bool {
    assert(isNativeImpl())
    return style().overflowY() == .Scroll || style().overflowY() == .Hidden
      || style().overflowY() == .Auto
  }

  private func usesCompositedScrolling() -> Bool {
    assert(isNativeImpl())
    return hasNonVisibleOverflow() && hasLayer() && layer()!.usesCompositedScrolling()
  }

  func percentageLogicalHeightIsResolvable() -> Bool {
    assert(isNativeImpl())
    // Do this to avoid duplicating all the logic that already exists when computing
    // an actual percentage height.
    let fakeLength = LengthWrapper(value: Int32(100), type: .Percent)
    return computePercentageLogicalHeight(height: fakeLength) != nil
  }

  func hasUnsplittableScrollingOverflow() -> Bool {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    return isReplacedOrInlineBlock()
      || hasUnsplittableScrollingOverflow()
      || (parent() != nil && isWritingModeRoot())
      || (isFloating() && style().pseudoElementType() == .FirstLetter
        && style().initialLetterDrop() > 0)
      || shouldApplySizeContainment()
  }

  func shouldTreatChildAsReplacedInTableCells() -> Bool {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    return false
  }

  func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    assert(isNativeImpl())
    return LayoutRectWrapper()
  }

  func popContentsClip(
    paintInfo: inout PaintInfoWrapper, originalPhase: PaintPhase,
    accumulatedOffset: LayoutPointWrapper
  ) {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  // Called when a positioned object moves but doesn't necessarily change size.  A simplified layout is attempted
  // that just updates the object's position. If the size does change, the object remains dirty.
  func tryLayoutDoingPositionedMovementOnly() -> Bool {
    assert(isNativeImpl())
    let oldWidth = width()
    updateLogicalWidth()
    // If we shrink to fit our width may have changed, so we still need full layout.
    if oldWidth != width() {
      return false
    }
    updateLogicalHeight()
    return true
  }

  func maskClipRect(paintOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    assert(isNativeImpl())
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

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    assert(isNativeImpl())
    // no children...return this render object's element, if there is one, and offset 0
    if firstChild() == nil {
      return createVisiblePosition(
        nonPseudoElement() != nil ? firstPositionInOrBeforeNode(nonPseudoElement()) : Position())
    }

    if isRenderTable() && nonPseudoElement() != nil {
      let right = contentWidth() + horizontalBorderAndPaddingExtent()
      let bottom = contentHeight() + verticalBorderAndPaddingExtent()

      if point.x < Int32(0) || point.x > right || point.y < Int32(0) || point.y > bottom {
        if point.x <= right / 2 {
          return createVisiblePosition(firstPositionInOrBeforeNode(nonPseudoElement()))
        }
        return createVisiblePosition(lastPositionInOrAfterNode(nonPseudoElement()))
      }
    }

    // Pass off to the closest child.
    var minDist = LayoutUnit.max()
    var closestRenderer: RenderBoxWrapper? = nil
    var adjustedPoint = point
    if isRenderTableRow() {
      adjustedPoint.moveBy(offset: location())
    }

    for renderer: RenderBoxWrapper in childrenOfType(parent: self) {
      if let fragmentedFlow = self as? RenderFragmentedFlowWrapper,
        !fragmentedFlow.objectShouldFragmentInFlowFragment(renderer, fragment!)
      {
        continue
      }

      if (renderer.firstChild() == nil && !renderer.isInline()
        && !(renderer is RenderBlockFlowWrapper))
        || (source == .Script ? renderer.style().visibility() : renderer.style().usedVisibility())
          != .Visible
      {
        continue
      }

      let top =
        renderer.borderTop() + renderer.paddingTop()
        + (self is RenderTableRowWrapper ? LayoutUnit(value: UInt64(0)) : renderer.y())
      let bottom = top + renderer.contentHeight()
      let left =
        renderer.borderLeft() + renderer.paddingLeft()
        + (self is RenderTableRowWrapper ? LayoutUnit(value: UInt64(0)) : renderer.x())
      let right = left + renderer.contentWidth()

      if point.x <= right && point.x >= left && point.y <= top && point.y >= bottom {
        if renderer is RenderTableRowWrapper {
          return renderer.positionForPoint(
            point + adjustedPoint - renderer.locationOffset(), source, fragment)
        }
        return renderer.positionForPoint(point - renderer.locationOffset(), source, fragment)
      }

      // Find the distance from (x, y) to the box.  Split the space around the box into 8 pieces
      // and use a different compare depending on which piece (x, y) is in.
      var cmp = LayoutPointWrapper()
      if point.x > right {
        if point.y < top {
          cmp = LayoutPointWrapper(x: right, y: top)
        } else if point.y > bottom {
          cmp = LayoutPointWrapper(x: right, y: bottom)
        } else {
          cmp = LayoutPointWrapper(x: right, y: point.y)
        }
      } else if point.x < left {
        if point.y < top {
          cmp = LayoutPointWrapper(x: left, y: top)
        } else if point.y > bottom {
          cmp = LayoutPointWrapper(x: left, y: bottom)
        } else {
          cmp = LayoutPointWrapper(x: left, y: point.y)
        }
      } else {
        if point.y < top {
          cmp = LayoutPointWrapper(x: point.x, y: top)
        } else {
          cmp = LayoutPointWrapper(x: point.x, y: bottom)
        }
      }

      let difference = cmp - point

      let dist = difference.width() * difference.width() + difference.height() * difference.height()
      if dist < minDist {
        closestRenderer = renderer
        minDist = dist
      }
    }

    if closestRenderer != nil {
      return closestRenderer!.positionForPoint(
        adjustedPoint - closestRenderer!.locationOffset(), source, fragment)
    }

    return createVisiblePosition(firstPositionInOrBeforeNode(nonPseudoElement()))
  }

  func removeFloatingAndInvalidateForLayout() {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    assert(!renderTreeBeingDestroyed())

    if isFloating() {
      return removeFloatingAndInvalidateForLayout()
    }

    if isOutOfFlowPositioned() {
      return RenderBlockWrapper.removePositionedObject(rendererToRemove: self)
    }

    fatalError("Not reached")
  }

  func enclosingFloatPaintingLayer() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    for box in RenderAncestorIteratorAdapter<RenderBoxWrapper>.lineageOfType(first: self) {
      if box.layer() != nil && box.layer()!.isSelfPaintingLayer {
        return box.layer()
      }
    }
    return nil
  }

  func firstLineBaseline() -> LayoutUnit? {
    assert(isNativeImpl())
    return nil
  }

  func lastLineBaseline() -> LayoutUnit? {
    assert(isNativeImpl())
    return nil
  }

  func shrinkToAvoidFloats() -> Bool {
    if !isNativeImpl() { return wk_interop.RenderBox_shrinkToAvoidFloats(id()) }
    // Floating objects don't shrink.  Objects that don't avoid floats don't shrink.  Marquees don't shrink.
    if (isInline() && !isHTMLMarquee()) || !avoidsFloats() || isFloating() {
      return false
    }

    // Only auto width objects can possibly shrink to avoid floats.
    return style().width().isAuto()
  }

  func avoidsFloats() -> Bool {
    if !isNativeImpl() { return wk_interop.RenderBox_avoidsFloats(id()) }
    return isReplacedOrInlineBlock() || isLegend() || isFieldset() || createsNewFormattingContext()
      || (element()?.isFormControlElement() ?? false)
  }

  func markForPaginationRelayoutIfNeeded() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    assert(isNativeImpl())
    if isReplacedOrInlineBlock() {
      return direction == .HorizontalLine
        ? marginBox.top + height() + marginBox.bottom
        : marginBox.right + width() + marginBox.left
    }
    return LayoutUnit(value: 0)
  }

  func flipForWritingModeForChild(child: RenderBoxWrapper, point: LayoutPointWrapper)
    -> LayoutPointWrapper
  {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    if !style().isFlippedBlocksWritingMode() {
      return position
    }
    return logicalHeight() - position
  }

  func flipForWritingMode(position: LayoutPointWrapper) -> LayoutPointWrapper {
    assert(isNativeImpl())
    if !style().isFlippedBlocksWritingMode() {
      return position
    }
    return isHorizontalWritingMode()
      ? LayoutPointWrapper(x: position.x, y: height() - position.y)
      : LayoutPointWrapper(x: width() - position.x, y: position.y)
  }

  func flipForWritingMode(rect: inout LayoutRectWrapper) {
    if !isNativeImpl() {
      wk_interop.RenderBox_flipForWritingMode(
        id(), LayoutPointRaw(x: rect.x().rawValue(), y: rect.y().rawValue()))
      return
    }
    if !style().isFlippedBlocksWritingMode() {
      return
    }

    if isHorizontalWritingMode() {
      rect.setY(y: height() - rect.maxY())
    } else {
      rect.setX(x: width() - rect.maxX())
    }
  }

  func flipForWritingMode(rect: inout FloatRectWrapper) {
    assert(isNativeImpl())
    if !style().isFlippedBlocksWritingMode() {
      return
    }

    if isHorizontalWritingMode() {
      rect.setY(y: height() - rect.maxY())
    } else {
      rect.setX(x: width() - rect.maxX())
    }
  }

  private func flipForWritingMode(_ rects: inout RepaintRects) {
    assert(isNativeImpl())
    if !style().isFlippedBlocksWritingMode() {
      return
    }

    rects.flipForWritingMode(size(), isHorizontalWritingMode())
  }

  // These represent your location relative to your container as a physical offset.
  // In layout related methods you almost always want the logical location (e.g. x() and y()).
  func topLeftLocation() -> LayoutPointWrapper {
    assert(isNativeImpl())
    // This is inlined for speed, since it is used by updateLayerPosition() during scrolling.
    if document().view() == nil || !document().view()!.hasFlippedBlockRenderers() {
      return location()
    }
    return topLeftLocationWithFlipping()
  }

  func topLeftLocationOffset() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    // This is inlined for speed, since it is used by updateLayerPosition() during scrolling.
    if document().view() == nil || !document().view()!.hasFlippedBlockRenderers() {
      return locationOffset()
    }
    return toLayoutSize(point: topLeftLocationWithFlipping())
  }

  func logicalVisualOverflowRectForPropagation(style: RenderStyleWrapper) -> LayoutRectWrapper {
    assert(!isNativeImpl())
    let raw = wk_interop.RenderBox_logicalVisualOverflowRectForPropagation(id(), style.p!)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  private func visualOverflowRectForPropagation(parentStyle: RenderStyleWrapper)
    -> LayoutRectWrapper
  {
    assert(isNativeImpl())
    // If the writing modes of the child and parent match, then we don't have to
    // do anything fancy. Just return the result.
    var rect = visualOverflowRect()
    if parentStyle.blockFlowDirection() == style().blockFlowDirection() {
      return rect
    }

    // We are putting ourselves into our parent's coordinate space.  If there is a flipped block mismatch
    // in a particular axis, then we have to flip the rect along that axis.
    if style().blockFlowDirection() == .RightToLeft
      || parentStyle.blockFlowDirection() == .RightToLeft
    {
      rect.setX(x: width() - rect.maxX())
    } else if style().blockFlowDirection() == .BottomToTop
      || parentStyle.blockFlowDirection() == .BottomToTop
    {
      rect.setY(y: height() - rect.maxY())
    }

    return rect
  }

  func layoutOverflowRectForPropagation(style: RenderStyleWrapper) -> LayoutRectWrapper {
    assert(!isNativeImpl())
    let raw = wk_interop.RenderBox_layoutOverflowRectForPropagation(id(), style.p!)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  func hasRenderOverflow() -> Bool {
    assert(isNativeImpl())
    return overflow != nil
  }

  func hasVisualOverflow() -> Bool {
    assert(isNativeImpl())
    return overflow != nil && !borderBoxRect().contains(other: overflow!.visualOverflowRect())
  }

  func needsPreferredWidthsRecalculation() -> Bool {
    if !isNativeImpl() { return wk_interop.RenderBox_needsPreferredWidthsRecalculation(id()) }
    return style().paddingStart().isPercentOrCalculated()
      || style().paddingEnd().isPercentOrCalculated()
      || (style().hasAspectRatio()
        && (hasRelativeLogicalHeight() || (isFlexItem() && hasStretchedLogicalHeight())))
  }

  func computeIntrinsicRatioInformation() -> (FloatSize, FloatSize) {
    assert(isNativeImpl())
    return (FloatSize(), FloatSize())
  }

  func scrollPosition() -> ScrollPosition {
    assert(isNativeImpl())
    if !hasPotentiallyScrollableOverflow() {
      return ScrollPosition(x: 0, y: 0)
    }

    assert(hasLayer())
    if let scrollableArea = layer()!.scrollableArea() {
      return scrollableArea.scrollPosition()
    }

    return ScrollPosition(x: 0, y: 0)
  }

  private func cachedSizeForOverflowClip() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    assert(hasNonVisibleOverflow())
    assert(hasLayer())
    return LayoutSizeWrapper(size: layer()!.size())
  }

  // Returns false if the rect has no intersection with the applied clip rect. When the context specifies edge-inclusive
  // intersection, this return value allows distinguishing between no intersection and zero-area intersection.
  @discardableResult
  override final func applyCachedClipAndScrollPosition(
    _ rects: inout RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> Bool {
    assert(isNativeImpl())
    flipForWritingMode(&rects)

    if context.options.contains(.ApplyCompositedContainerScrolls)
      || CPtrToInt(id()) != CPtrToInt(container?.id())
      || !usesCompositedScrolling()
    {
      rects.moveBy(LayoutPointWrapper(point: -scrollPosition()))  // For overflow:auto/scroll/hidden.
    }

    // Do not clip scroll layer contents to reduce the number of repaints while scrolling.
    if (!context.options.contains(.ApplyCompositedClips) && usesCompositedScrolling())
      || (!context.options.contains(.ApplyContainerClip)
        && CPtrToInt(id()) == CPtrToInt(container?.id()))
    {
      flipForWritingMode(&rects)
      return true
    }

    // height() is inaccurate if we're in the middle of a layout of this RenderBox, so use the
    // layer's size instead. Even if the layer's size is wrong, the layer itself will repaint
    // anyway if its size does change.
    var clipRect = LayoutRectWrapper(
      location: LayoutPointWrapper(), size: cachedSizeForOverflowClip())
    if effectiveOverflowX() == .Visible {
      clipRect.expandToInfiniteX()
    }
    if effectiveOverflowY() == .Visible {
      clipRect.expandToInfiniteY()
    }

    let intersects =
      context.options.contains(.UseEdgeInclusiveIntersection)
      ? rects.edgeInclusiveIntersect(clipRect) : rects.intersect(clipRect)

    flipForWritingMode(&rects)
    return intersects
  }

  func hasRelativeDimensions() -> Bool {
    assert(isNativeImpl())
    return style().height().isPercentOrCalculated() || style().width().isPercentOrCalculated()
      || style().maxHeight().isPercentOrCalculated() || style().maxWidth().isPercentOrCalculated()
      || style().minHeight().isPercentOrCalculated() || style().minWidth().isPercentOrCalculated()
  }

  func hasRelativeLogicalHeight() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderBox_hasRelativeLogicalHeight(id())
    }
    return style().logicalHeight().isPercentOrCalculated()
      || style().logicalMinHeight().isPercentOrCalculated()
      || style().logicalMaxHeight().isPercentOrCalculated()
  }

  func hasRelativeLogicalWidth() -> Bool {
    assert(isNativeImpl())
    return style().logicalWidth().isPercentOrCalculated()
      || style().logicalMinWidth().isPercentOrCalculated()
      || style().logicalMaxWidth().isPercentOrCalculated()
  }

  func hasHorizontalLayoutOverflow() -> Bool {
    assert(isNativeImpl())
    if overflow == nil {
      return false
    }

    let layoutOverflowRect = overflow!.layoutOverflowRect()
    let paddingBoxRect = flippedClientBoxRect()
    return layoutOverflowRect.x() < paddingBoxRect.x()
      || layoutOverflowRect.maxX() > paddingBoxRect.maxX()
  }

  func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    fatalError("Not reached")
  }

  func markShapeOutsideDependentsForLayout() {
    assert(isNativeImpl())
    if isFloating() {
      removeFloatingOrPositionedChildFromBlockLists()
    }
  }

  // True if this box can have a range in an outside fragmentation context.
  func canHaveOutsideFragmentRange() -> Bool {
    assert(isNativeImpl())
    return !isRenderFragmentedFlow()
  }

  func needsLayoutAfterFragmentRangeChange() -> Bool {
    assert(isNativeImpl())
    return false
  }

  func isGridItem() -> Bool {
    assert(isNativeImpl())
    return (parent()?.isRenderGrid() ?? false) && !isExcludedFromNormalLayout()
  }

  func isFlexItem() -> Bool {
    assert(!isNativeImpl())
    return wk_interop.RenderBox_isFlexItem(id())
  }

  func adjustBorderBoxRectForPainting(paintRect: inout LayoutRectWrapper) {}

  func shouldComputeLogicalHeightFromAspectRatio() -> Bool {
    assert(isNativeImpl())
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

  func shouldIgnoreLogicalMinMaxWidthSizes() -> Bool {
    assert(isNativeImpl())
    if !isFlexItem() {
      return false
    }
    if let flexBox = parent() as? RenderFlexibleBoxWrapper {
      return flexBox.isComputingFlexBaseSizes
        && style().isHorizontalWritingMode() == flexBox.isHorizontalFlow()
    }
    fatalError("Not reached")
  }

  func shouldIgnoreLogicalMinMaxHeightSizes() -> Bool {
    assert(isNativeImpl())
    if !isFlexItem() {
      return false
    }
    if let flexBox = parent() as? RenderFlexibleBoxWrapper {
      return flexBox.isComputingFlexBaseSizes
        && style().isHorizontalWritingMode() != flexBox.isHorizontalFlow()
    }
    fatalError("Not reached")
  }

  // The explicit intrinsic inner size of contain-intrinsic-size
  func explicitIntrinsicInnerWidth() -> LayoutUnit? {
    assert(isNativeImpl())
    assert(
      isHorizontalWritingMode()
        ? shouldApplySizeOrInlineSizeContainment() : shouldApplySizeContainment())
    if style().containIntrinsicWidthType() == .None {
      return nil
    }

    if element() != nil && style().containIntrinsicWidthHasAuto()
      && layout_scion.isSkippedContentRoot(style: style(), element: element()),
      let width = isHorizontalWritingMode()
        ? element()!.lastRememberedLogicalWidth() : element()!.lastRememberedLogicalHeight()
    {
      return width
    }

    if style().containIntrinsicWidthType() == .AutoAndNone {
      return nil
    }

    let width = style().containIntrinsicWidth()!
    return LayoutUnit(value: width.value())
  }

  func explicitIntrinsicInnerHeight() -> LayoutUnit? {
    assert(isNativeImpl())
    assert(
      isHorizontalWritingMode()
        ? shouldApplySizeContainment() : shouldApplySizeOrInlineSizeContainment())
    if style().containIntrinsicHeightType() == .None {
      return nil
    }

    if element() != nil && style().containIntrinsicHeightHasAuto()
      && layout_scion.isSkippedContentRoot(style: style(), element: element()),
      let height = isHorizontalWritingMode()
        ? element()!.lastRememberedLogicalHeight() : element()!.lastRememberedLogicalWidth()
    {
      return height
    }

    if style().containIntrinsicHeightType() == .AutoAndNone {
      return nil
    }

    let height = style().containIntrinsicHeight()!
    return LayoutUnit(value: height.value())
  }

  func explicitIntrinsicInnerLogicalWidth() -> LayoutUnit? {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? explicitIntrinsicInnerWidth() : explicitIntrinsicInnerHeight()
  }

  func explicitIntrinsicInnerLogicalHeight() -> LayoutUnit? {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode()
      ? explicitIntrinsicInnerHeight() : explicitIntrinsicInnerWidth()
  }

  override func establishesIndependentFormattingContext() -> Bool {
    assert(isNativeImpl())
    return isGridItem() || super.establishesIndependentFormattingContext()
  }

  func updateFloatPainterAfterSelfPaintingLayerChange() {
    assert(isNativeImpl())
    assert(isFloating())
    assert(!hasLayer() || !layer()!.isSelfPaintingLayer)

    if let floatingObject = floatingObjectForFloatPainting() {
      floatingObject.setPaintsFloat(paintsFloat: true)
    }
  }

  // Find the ancestor renderer that is supposed to paint this float now that it is not self painting anymore.
  private func floatingObjectForFloatPainting() -> FloatingObjectWrapper? {
    assert(isNativeImpl())
    let layoutContext = view().frameView().layoutContext()
    if !layoutContext.isInLayout()
      || CPtrToInt(layoutContext.subtreeLayoutRoot()?.id()) != CPtrToInt(id())
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
        blockFlowContainsThisFloat = CPtrToInt(floatingObject.renderer?.id()) == CPtrToInt(id())
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

  func computeHasTransformRelatedProperty(_ styleToUse: RenderStyleWrapper) -> Bool {
    assert(isNativeImpl())
    if styleToUse.hasTransformRelatedProperty() {
      return true
    }

    if !settings().css3DTransformBackfaceVisibilityInteroperabilityEnabled() {
      return false
    }

    if styleToUse.backfaceVisibility() != .Hidden {
      return false
    }

    guard let element = element() else { return false }

    guard let parent = element.parentElement() else { return false }

    guard let parentRenderer = parent.containerRenderer() else { return false }

    return parentRenderer.style().preserves3D()
  }

  func shapeOutsideInfo() -> ShapeOutsideInfoWrapper? {
    assert(!isNativeImpl())
    if let unwrapped = wk_interop.RenderBox_shapeOutsideInfo(id()) {
      return ShapeOutsideInfoWrapper(p: unwrapped)
    }
    return nil
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    assert(isNativeImpl())
    RenderBoxWrapper.hadNonVisibleOverflow = hasNonVisibleOverflow()

    let oldStyle = hasInitializedStyle ? style() : nil
    if oldStyle != nil {
      // The background of the root element or the body element could propagate up to
      // the canvas. Issue full repaint, when our style changes substantially.
      if diff >= .Repaint && (isDocumentElementRenderer() || isBody()) {
        view().repaintRootContents()
        if oldStyle!.hasEntirelyFixedBackground() != newStyle.hasEntirelyFixedBackground() {
          view().compositor().rootLayerConfigurationChanged()
        }
      }

      // When a layout hint happens and an object's position style changes, we have to do a layout
      // to dirty the render tree using the old position value now.
      if diff == .Layout && parent() != nil && oldStyle!.position() != newStyle.position() {
        if !oldStyle!.hasOutOfFlowPosition() && newStyle.hasOutOfFlowPosition() {
          // We are about to go out of flow. Before that takes place, we need to mark the
          // current containing block chain for preferred widths recalculation.
          setNeedsLayoutAndPrefWidthsRecalc()
        } else {
          scheduleLayout(layoutRoot: markContainingBlocksForLayout())
        }

        if oldStyle!.position() != .Static && newStyle.hasOutOfFlowPosition() {
          parent()!.setChildNeedsLayout()
        }
        if isFloating() && !isOutOfFlowPositioned() && newStyle.hasOutOfFlowPosition() {
          removeFloatingOrPositionedChildFromBlockLists()
        }
      }
    } else if isBody() {
      view().repaintRootContents()
    }

    let boxContributesSnapPositions = newStyle.hasSnapPosition()
    if boxContributesSnapPositions || (oldStyle != nil && oldStyle!.hasSnapPosition()) {
      if boxContributesSnapPositions {
        view().registerBoxWithScrollSnapPositions(self)
      } else {
        view().unregisterBoxWithScrollSnapPositions(self)
      }
    }

    if newStyle.containerType() != .Normal {
      view().registerContainerQueryBox(self)
    } else if oldStyle != nil && oldStyle!.containerType() != .Normal {
      view().unregisterContainerQueryBox(self)
    }

    super.styleWillChange(diff: diff, newStyle: newStyle)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    // Horizontal writing mode definition is updated in RenderBoxModelObject::updateFromStyle,
    // (as part of the RenderBoxModelObject::styleDidChange call below). So, we can safely cache the horizontal
    // writing mode value before style change here.
    let oldHorizontalWritingMode = isHorizontalWritingMode()

    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    let newStyle = style()
    if needsLayout() && oldStyle != nil {
      RenderBlockWrapper.removePercentHeightDescendantIfNeeded(descendant: self)

      // Normally we can do optimized positioning layout for absolute/fixed positioned objects. There is one special case, however, which is
      // when the positioned object's margin-before is changed. In this case the parent has to get a layout in order to run margin collapsing
      // to determine the new static position.
      if isOutOfFlowPositioned()
        && newStyle.hasStaticBlockPosition(horizontal: isHorizontalWritingMode())
        && oldStyle!.marginBefore() != newStyle.marginBefore()
        && parent() != nil && !parent()!.normalChildNeedsLayout()
      {
        parent()!.setChildNeedsLayout()
      }
    }

    if RenderBlockWrapper.hasPercentHeightContainerMap() && firstChild() != nil
      && oldHorizontalWritingMode != isHorizontalWritingMode()
    {
      RenderBlockWrapper.clearPercentHeightDescendantsFrom(parent: self)
    }

    // If our zoom factor changes and we have a defined scrollLeft/Top, we need to adjust that value into the
    // new zoomed coordinate space.
    if hasNonVisibleOverflow() && layer() != nil && oldStyle != nil
      && oldStyle!.usedZoom() != newStyle.usedZoom(), let scrollableArea = layer()!.scrollableArea()
    {
      var scrollPosition = scrollableArea.scrollPosition()
      let zoomScaleFactor = newStyle.usedZoom() / oldStyle!.usedZoom()
      scrollPosition.scale(zoomScaleFactor)
      scrollableArea.setPostLayoutScrollPosition(scrollPosition)
    }

    if layer() != nil && oldStyle != nil
      && oldStyle!.shouldPlaceVerticalScrollbarOnLeft()
        != newStyle.shouldPlaceVerticalScrollbarOnLeft(),
      let scrollableArea = layer()!.scrollableArea()
    {
      scrollableArea.scrollbarsController().scrollbarLayoutDirectionChanged(
        shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() ? .RTL : .LTR)
    }

    let isDocElementRenderer = isDocumentElementRenderer()

    if layer() != nil && oldStyle != nil && oldStyle!.scrollbarWidth() != newStyle.scrollbarWidth()
    {
      if isDocElementRenderer {
        view().frameView().scrollbarWidthChanged(newStyle.scrollbarWidth())
      } else if let scrollableArea = layer()!.scrollableArea() {
        scrollableArea.scrollbarWidthChanged(newStyle.scrollbarWidth())
      }
    }

    // Our opaqueness might have changed without triggering layout.
    if diff >= .Repaint && diff <= .RepaintLayer {
      var parentToInvalidate = parent()
      for _ in 0..<backgroundObscurationTestMaxDepth {
        if parentToInvalidate == nil {
          break
        }
        parentToInvalidate!.invalidateBackgroundObscurationStatus()
        parentToInvalidate = parentToInvalidate!.parent()
      }
    }

    let isBodyRenderer = isBody()

    if isDocElementRenderer || isBodyRenderer {
      view().frameView().recalculateScrollbarOverlayStyle()

      if diff != .Equal {
        view().compositor().rootOrBodyStyleChanged(renderer: self, oldStyle: oldStyle)
      }
    }

    if (oldStyle != nil && oldStyle!.shapeOutside() != nil) || style().shapeOutside() != nil {
      updateShapeOutsideInfoAfterStyleChange(style: style(), oldStyle: oldStyle)
    }
    updateGridPositionAfterStyleChange(style: style(), oldStyle: oldStyle)

    // Changing the position from/to absolute can potentially create/remove flex/grid items, as absolutely positioned
    // children of a flex/grid box are out-of-flow, and thus, not flex/grid items. This means that we need to clear
    // any override content size set by our container, because it would likely be incorrect after the style change.
    if isOutOfFlowPositioned() && parent() != nil
      && parent()!.style().isDisplayFlexibleBoxIncludingDeprecatedOrGridBox()
    {
      clearOverridingContentSize()
    }

    if oldStyle != nil && oldStyle!.hasOutOfFlowPosition() != style().hasOutOfFlowPosition() {
      clearOverridingContainingBlockContentSize()
    }
  }

  override func updateFromStyle() {
    assert(isNativeImpl())
    super.updateFromStyle()

    let styleToUse = style()
    let isDocElementRenderer = isDocumentElementRenderer()
    let isViewObject = isRenderView()

    // The root and the RenderView always paint their backgrounds/borders.
    if isDocElementRenderer || isViewObject {
      setHasVisibleBoxDecorations(true)
    }

    setFloating(!isOutOfFlowPositioned() && styleToUse.isFloating())

    // We also handle <body> and <html>, whose overflow applies to the viewport.
    if !(effectiveOverflowX() == .Visible && effectiveOverflowY() == .Visible)
      && !isDocElementRenderer && isRenderBlock()
    {
      var boxHasNonVisibleOverflow = true
      if isBody() {
        // Overflow on the body can propagate to the viewport under the following conditions.
        // (1) The root element is <html>.
        // (2) We are the primary <body> (can be checked by looking at document.body).
        // (3) The root element has visible overflow.
        // (4) No containment is set either on the body or on the html document element.
        let documentElement = document().documentElement()!
        let documentElementRenderer = documentElement.containerRenderer()!
        if documentElement is HTMLHtmlElement
          && CPtrToInt(document().body()?.p) == CPtrToInt(element()?.p)
          && documentElementRenderer.effectiveOverflowX() == .Visible
          && styleToUse.usedContain().isEmpty
          && documentElementRenderer.style().usedContain().isEmpty
        {
          boxHasNonVisibleOverflow = false
        }
      }
      // Check for overflow clip.
      // It's sufficient to just check one direction, since it's illegal to have visible on only one overflow value.
      if boxHasNonVisibleOverflow {
        if !RenderBoxWrapper.hadNonVisibleOverflow && hasRenderOverflow() {
          // Erase the overflow.
          // Overflow changes have to result in immediate repaints of the entire layout overflow area because
          // repaints issued by removal of descendants get clipped using the updated style when they shouldn't.
          issueRepaint(visualOverflowRect(), .Yes, .Yes)
          issueRepaint(layoutOverflowRect(), .Yes, .Yes)
        }
        setHasNonVisibleOverflow()
      }
    }
    setHasTransformRelatedProperty(computeHasTransformRelatedProperty(styleToUse))
    setHasReflection(styleToUse.boxReflect() != nil)
  }

  override func willBeDestroyed() {
    assert(isNativeImpl())
    renderBoxWillBeDestroyed()
  }

  func renderBoxWillBeDestroyed() {
    assert(isNativeImpl())
    if CPtrToInt(frame().eventHandler().autoscrollRenderer()?.id()) == CPtrToInt(id()) {
      frame().eventHandler().stopAutoscrollTimer(true)
    }

    if hasInitializedStyle {
      if style().hasSnapPosition() {
        view().unregisterBoxWithScrollSnapPositions(self)
      }
      if style().containerType() != .Normal {
        view().unregisterContainerQueryBox(self)
      }
    }

    super.willBeDestroyed()
  }

  func shouldTrimChildMarginForBox(type: MarginTrimType, child: RenderBoxWrapper) -> Bool {
    assert(isNativeImpl())
    return style().marginTrim().contains(type) && isChildEligibleForMarginTrim(type, child)
  }

  func isChildEligibleForMarginTrim(_ marginTrimType: MarginTrimType, _ child: RenderBoxWrapper)
    -> Bool
  {
    assert(isNativeImpl())
    return false
  }

  func shouldResetLogicalHeightBeforeLayout() -> Bool { return false }

  func resetLogicalHeightBeforeLayoutIfNeeded() {
    assert(isNativeImpl())
    let shouldSetLogicalHeight = { [self] () in
      if shouldResetLogicalHeightBeforeLayout() {
        return true
      }
      if let parentBlock = parent() as? RenderBlockWrapper {
        return parentBlock.shouldResetChildLogicalHeightBeforeLayout()
      }
      return false
    }

    if shouldSetLogicalHeight() {
      setLogicalHeight(size: LayoutUnit(value: UInt64(0)))
    }
  }

  func selfAlignmentNormalBehavior(gridItem: RenderBoxWrapper? = nil) -> ItemPosition {
    assert(isNativeImpl())
    return .Stretch
  }

  // Returns false if it could not cheaply compute the extent (e.g. fixed background), in which case the returned rect may be incorrect.
  func getBackgroundPaintedExtent(_ paintOffset: LayoutPointWrapper) -> (
    LayoutRectWrapper, Bool
  ) {
    assert(isNativeImpl())
    assert(hasBackground())
    let backgroundRect = LayoutRectWrapper(rect: snappedIntRect(rect: borderBoxRect()))

    let backgroundColor = style().visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyBackgroundColor)
    if backgroundColor.isVisible() {
      return (backgroundRect, true)
    }

    let layers = style().backgroundLayers()
    if layers.image() == nil || layers.next() != nil {
      return (backgroundRect, true)
    }

    let geometry = BackgroundPainter.calculateBackgroundImageGeometry(
      renderer: self, paintContainer: nil, fillLayer: layers, paintOffset: paintOffset,
      borderBoxRect: backgroundRect)
    return (geometry.destinationRect, !geometry.hasNonLocalGeometry)
  }

  func foregroundIsKnownToBeOpaqueInRect(_ localRect: LayoutRectWrapper, _ maxDepthToTest: UInt32)
    -> Bool
  {
    assert(isNativeImpl())
    if maxDepthToTest == 0 {
      return false
    }

    if isSkippedContentRoot() {
      return false
    }

    for childBox: RenderBoxWrapper in childrenOfType(parent: self) {
      if !isCandidateForOpaquenessTest(childBox) {
        continue
      }
      var childLocation = childBox.location()
      if childBox.isRelativelyPositioned() {
        childLocation.move(s: childBox.relativePositionOffset())
      }
      var childLocalRect = localRect
      childLocalRect.moveBy(offset: -childLocation)
      if childLocalRect.y() < Int32(0) || childLocalRect.x() < Int32(0) {
        // If there is unobscured area above/left of a static positioned box then the rect is probably not covered.
        if childBox.style().position() == .Static {
          return false
        }
        continue
      }
      if childLocalRect.maxY() > childBox.height() || childLocalRect.maxX() > childBox.width() {
        continue
      }
      if childBox.backgroundIsKnownToBeOpaqueInRect(childLocalRect) {
        return true
      }
      if childBox.foregroundIsKnownToBeOpaqueInRect(childLocalRect, maxDepthToTest - 1) {
        return true
      }
    }
    return false
  }

  override func computeBackgroundIsKnownToBeObscured(_ paintOffset: LayoutPointWrapper)
    -> Bool
  {
    assert(isNativeImpl())
    // Test to see if the children trivially obscure the background.
    // FIXME: This test can be much more comprehensive.
    if !hasBackground() {
      return false
    }
    // Table and root background painting is special.
    if isRenderTable() || isDocumentElementRenderer() {
      return false
    }

    let (backgroundRect, isBackground) = getBackgroundPaintedExtent(paintOffset)
    if !isBackground {
      return false
    }

    if let scrollableArea = layer()?.scrollableArea() ?? nil,
      scrollableArea.scrollingMayRevealBackground()
    {
      return false
    }
    return foregroundIsKnownToBeOpaqueInRect(backgroundRect, backgroundObscurationTestMaxDepth)
  }

  func paintMaskImages(paintInfo: PaintInfoWrapper, paintRect: LayoutRectWrapper) {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    let borderShape = BorderShape.shapeForBorderRect(
      style: style(), borderRect: LayoutRectWrapper(location: accumulatedOffset, size: size()))
    borderShape.clipToInnerShape(context: context, deviceScaleFactor: deviceScaleFactor)
  }

  func clipToContentBoxShape(
    _ context: GraphicsContextWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ deviceScaleFactor: Float32
  ) {
    assert(isNativeImpl())
    let borderShape = borderShapeForContentClipping(
      borderBoxRect: LayoutRectWrapper(location: accumulatedOffset, size: size()))
    borderShape.clipToInnerShape(context: context, deviceScaleFactor: deviceScaleFactor)
  }

  // --------------------- painting stuff -------------------------------

  func determineBackgroundBleedAvoidance(context: GraphicsContextWrapper)
    -> BackgroundBleedAvoidance
  {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func computePositionedLogicalWidth(
    computedValues: inout LogicalExtentComputedValues,
    fragment: RenderFragmentContainerWrapper? = nil
  ) {
    assert(isNativeImpl())
    if isReplacedOrInlineBlock() {
      // FIXME: Positioned replaced elements inside a flow thread are not working properly
      // with variable width fragments (see https://bugs.webkit.org/show_bug.cgi?id=69896 ).
      computePositionedLogicalWidthReplaced(computedValues: &computedValues)
      return
    }

    // QUESTIONS
    // FIXME 1: Should we still deal with these the cases of 'left' or 'right' having
    // the type 'static' in determining whether to calculate the static distance?
    // NOTE: 'static' is not a legal value for 'left' or 'right' as of CSS 2.1.

    // FIXME 2: Can perhaps optimize out cases when max-width/min-width are greater
    // than or less than the computed width().  Be careful of box-sizing and
    // percentage issues.

    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.3.7 "Absolutely positioned, non-replaced elements"
    // <http://www.w3.org/TR/CSS21/visudet.html#abs-non-replaced-width>
    // (block-style-comments in this function and in computePositionedLogicalWidthUsing()
    // correspond to text from the spec)

    // We don't use containingBlock(), since we may be positioned by an enclosing
    // relative positioned inline.
    let containerBlock = container() as! RenderBoxModelObjectWrapper

    let containerLogicalWidth = containingBlockLogicalWidthForPositioned(
      containingBlock: containerBlock, fragment: fragment)

    // Use the container block's direction except when calculating the static distance
    // This conforms with the reference results for abspos-replaced-width-margin-000.htm
    // of the CSS 2.1 test suite
    let containerDirection = containerBlock.style().direction()

    let isHorizontal = isHorizontalWritingMode()
    let bordersPlusPadding = borderAndPaddingLogicalWidth()
    let marginLogicalLeft = isHorizontal ? style().marginLeft() : style().marginTop()
    let marginLogicalRight = isHorizontal ? style().marginRight() : style().marginBottom()

    var logicalLeftLength = style().logicalLeft()
    var logicalRightLength = style().logicalRight()

    /*---------------------------------------------------------------------------*\
     * For the purposes of this section and the next, the term "static position"
     * (of an element) refers, roughly, to the position an element would have had
     * in the normal flow. More precisely:
     *
     * * The static position for 'left' is the distance from the left edge of the
     *   containing block to the left margin edge of a hypothetical box that would
     *   have been the first box of the element if its 'position' property had
     *   been 'static' and 'float' had been 'none'. The value is negative if the
     *   hypothetical box is to the left of the containing block.
     * * The static position for 'right' is the distance from the right edge of the
     *   containing block to the right margin edge of the same hypothetical box as
     *   above. The value is positive if the hypothetical box is to the left of the
     *   containing block's edge.
     *
     * But rather than actually calculating the dimensions of that hypothetical box,
     * user agents are free to make a guess at its probable position.
     *
     * For the purposes of calculating the static position, the containing block of
     * fixed positioned elements is the initial containing block instead of the
     * viewport, and all scrollable boxes should be assumed to be scrolled to their
     * origin.
    \*---------------------------------------------------------------------------*/

    // see FIXME 1
    // Calculate the static distance if needed.
    computeInlineStaticDistance(
      logicalLeft: &logicalLeftLength, logicalRight: &logicalRightLength, child: self,
      containerBlock: containerBlock, containerLogicalWidth: containerLogicalWidth,
      fragment: fragment)

    // Calculate constraint equation values for 'width' case.
    computePositionedLogicalWidthUsing(
      widthType: .MainOrPreferredSize, logicalWidth: style().logicalWidth(),
      containerBlock: containerBlock, containerDirection: containerDirection,
      containerLogicalWidth: containerLogicalWidth, bordersPlusPadding: bordersPlusPadding,
      logicalLeft: logicalLeftLength, logicalRight: logicalRightLength,
      marginLogicalLeft: marginLogicalLeft, marginLogicalRight: marginLogicalRight,
      computedValues: &computedValues)

    var transferredMinSize = LayoutUnit.min()
    var transferredMaxSize = LayoutUnit.max()
    if shouldComputeLogicalHeightFromAspectRatio() {
      (transferredMinSize, transferredMaxSize) = computeMinMaxLogicalWidthFromAspectRatio()
    }

    var maxValues = LogicalExtentComputedValues()
    maxValues.extent = LayoutUnit.max()
    // Calculate constraint equation values for 'max-width' case.
    if !style().logicalMaxWidth().isUndefined() {
      computePositionedLogicalWidthUsing(
        widthType: .MaxSize, logicalWidth: style().logicalMaxWidth(),
        containerBlock: containerBlock, containerDirection: containerDirection,
        containerLogicalWidth: containerLogicalWidth, bordersPlusPadding: bordersPlusPadding,
        logicalLeft: logicalLeftLength, logicalRight: logicalRightLength,
        marginLogicalLeft: marginLogicalLeft, marginLogicalRight: marginLogicalRight,
        computedValues: &maxValues)
    }
    if transferredMaxSize < maxValues.extent {
      computePositionedLogicalWidthUsing(
        widthType: .MaxSize, logicalWidth: LengthWrapper(value: transferredMaxSize, type: .Fixed),
        containerBlock: containerBlock, containerDirection: containerDirection,
        containerLogicalWidth: containerLogicalWidth, bordersPlusPadding: bordersPlusPadding,
        logicalLeft: logicalLeftLength, logicalRight: logicalRightLength,
        marginLogicalLeft: marginLogicalLeft, marginLogicalRight: marginLogicalRight,
        computedValues: &maxValues)
    }
    if computedValues.extent > maxValues.extent {
      computedValues.extent = maxValues.extent
      computedValues.position = maxValues.position
      computedValues.margins.start = maxValues.margins.start
      computedValues.margins.end = maxValues.margins.end
    }

    var minValues = LogicalExtentComputedValues()
    minValues.extent = LayoutUnit.min()
    // Calculate constraint equation values for 'min-width' case.
    if !style().logicalMinWidth().isZero() || style().logicalMinWidth().isIntrinsic() {
      computePositionedLogicalWidthUsing(
        widthType: .MinSize, logicalWidth: style().logicalMinWidth(),
        containerBlock: containerBlock, containerDirection: containerDirection,
        containerLogicalWidth: containerLogicalWidth, bordersPlusPadding: bordersPlusPadding,
        logicalLeft: logicalLeftLength, logicalRight: logicalRightLength,
        marginLogicalLeft: marginLogicalLeft, marginLogicalRight: marginLogicalRight,
        computedValues: &minValues)
    }
    if transferredMinSize > minValues.extent {
      computePositionedLogicalWidthUsing(
        widthType: .MinSize, logicalWidth: LengthWrapper(value: transferredMinSize, type: .Fixed),
        containerBlock: containerBlock,
        containerDirection: containerDirection,
        containerLogicalWidth: containerLogicalWidth, bordersPlusPadding: bordersPlusPadding,
        logicalLeft: logicalLeftLength, logicalRight: logicalRightLength,
        marginLogicalLeft: marginLogicalLeft, marginLogicalRight: marginLogicalRight,
        computedValues: &minValues)
    }
    if computedValues.extent < minValues.extent {
      computedValues.extent = minValues.extent
      computedValues.position = minValues.position
      computedValues.margins.start = minValues.margins.start
      computedValues.margins.end = minValues.margins.end
    }

    computedValues.extent += bordersPlusPadding
    if let containingBox = containerBlock as? RenderBoxWrapper {
      if containingBox.shouldPlaceVerticalScrollbarOnLeftForLayerModelObject()
        && isHorizontalWritingMode()
      {
        computedValues.position += containingBox.verticalScrollbarWidth()
      }
    }

    // Adjust logicalLeft if we need to for the flipped version of our writing mode in fragments.
    // FIXME: Add support for other types of objects as containerBlock, not only RenderBlock.
    let fragmentedFlow = enclosingFragmentedFlow()
    if fragmentedFlow != nil && fragment == nil && isWritingModeRoot()
      && isHorizontalWritingMode() == containerBlock.isHorizontalWritingMode(),
      let renderBlock = containerBlock as? RenderBlockWrapper
    {
      assert(containerBlock.canHaveBoxInfoInFragment())
      var logicalLeftPos = computedValues.position
      let cbPageOffset = renderBlock.offsetFromLogicalTopOfFirstPage()
      if let cbFragment = renderBlock.fragmentAtBlockOffset(blockOffset: cbPageOffset),
        let boxInfo = renderBlock.renderBoxFragmentInfo(fragment: cbFragment)
      {
        logicalLeftPos += boxInfo.logicalLeft
        computedValues.position = logicalLeftPos
      }
    }
  }

  func computeIntrinsicLogicalWidthUsing(
    logicalWidthLength: LengthWrapper, availableLogicalWidth: LayoutUnit,
    borderAndPadding: LayoutUnit
  ) -> LayoutUnit {
    assert(isNativeImpl())
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
        var minChildrenLogicalWidth = LayoutUnit()
        var maxChildrenLogicalWidth = LayoutUnit()
        computeIntrinsicKeywordLogicalWidths(
          minLogicalWidth: &minChildrenLogicalWidth, maxLogicalWidth: &maxChildrenLogicalWidth)
        minLogicalWidth = max(minLogicalWidth, minChildrenLogicalWidth)
        maxLogicalWidth = max(maxLogicalWidth, maxChildrenLogicalWidth)
      }
    } else {
      computeIntrinsicKeywordLogicalWidths(
        minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
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

  func computeIntrinsicLogicalContentHeightUsing(
    logicalHeightLength: LengthWrapper, intrinsicContentHeight: LayoutUnit?,
    borderAndPadding: LayoutUnit
  ) -> LayoutUnit? {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    return isReplacedOrInlineBlock() && !isInlineBlockOrInlineTable()
  }

  func localOutlineBoundsRepaintRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    let box = borderBoundingBox()
    return applyVisualEffectOverflow(borderBox: box)
  }

  override func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    assert(isNativeImpl())
    if CPtrToInt(ancestorContainer?.id()) == CPtrToInt(id()) {
      return
    }

    if ancestorContainer == nil && view().frameView().layoutContext().isPaintOffsetCacheEnabled() {
      let layoutState = view().frameView().layoutContext().layoutState()!
      var offset = layoutState.paintOffset() + locationOffset()
      if style().hasInFlowPosition() && layer() != nil {
        offset += layer()!.offsetForInFlowPosition()
      }
      transformState.move(offset)
      return
    }

    let (container, containerSkipped) = container(ancestorContainer)
    if container == nil {
      return
    }

    let isFixedPos = isFixedPositioned()
    var mode = mode
    // If this box has a transform, it acts as a fixed position container for fixed descendants,
    // and may itself also be fixed position. So propagate 'fixed' up only if this box is fixed position.
    if isFixedPos {
      mode.update(with: .IsFixed)
    } else if mode.contains(.IsFixed) && canContainFixedPositionObjects() {
      mode.remove(.IsFixed)
    }

    if wasFixed != nil {
      wasFixed = mode.contains(.IsFixed)
    }

    var unused: Bool? = nil
    var containerOffset = offsetFromContainer(
      container!, LayoutPointWrapper(size: transformState.mappedPoint()), &unused)

    // Remove sticky positioning from the offset if it should be ignored. This is done here in
    // order to avoid piping this flag down the method chain.
    if mode.contains(.IgnoreStickyOffsets) && isStickilyPositioned() {
      containerOffset -= stickyPositionOffset()
    }

    pushOntoTransformState(
      transformState, mode, ancestorContainer, container, containerOffset, containerSkipped)
    if containerSkipped {
      return
    }

    mode.remove(.ApplyContainerFlip)

    container!.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixed)
  }

  override func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    assert(isNativeImpl())
    assert(CPtrToInt(ancestorToStopAt?.id()) != CPtrToInt(id()))

    let (container, ancestorSkipped) = container(ancestorToStopAt)
    if container == nil {
      return nil
    }

    pushOntoGeometryMap(geometryMap, ancestorToStopAt, container, ancestorSkipped)
    return ancestorSkipped ? ancestorToStopAt : container
  }

  override func mapAbsoluteToLocalPoint(
    _ mode: MapCoordinatesMode, _ transformState: TransformState
  ) {
    assert(isNativeImpl())
    var mode = mode
    let isFixedPos = isFixedPositioned()
    if isFixedPos {
      mode.update(with: .IsFixed)
    } else if mode.contains(.IsFixed) && canContainFixedPositionObjects() {
      // If this box has a transform, it acts as a fixed position container for fixed descendants,
      // and may itself also be fixed position. So propagate 'fixed' up only if this box is fixed position.
      mode.remove(.IsFixed)
    }

    super.mapAbsoluteToLocalPoint(mode, transformState)
  }

  func skipContainingBlockForPercentHeightCalculation(
    containingBlock: RenderBoxWrapper, isPerpendicularWritingMode: Bool
  ) -> Bool {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
    if let replacedElement = self as? RenderReplacedWrapper {
      return replacedElement.computeIntrinsicAspectRatio()
    }
    if style().hasAspectRatio() {
      return style().logicalAspectRatio()
    }
    fatalError("Not reached")
  }

  func shouldIgnoreAspectRatio() -> Bool {
    assert(isNativeImpl())
    return !style().hasAspectRatio() || isTablePart()
  }

  private func isRenderReplacedWithIntrinsicRatio() -> Bool {
    assert(isNativeImpl())
    if let replaced = self as? RenderReplacedWrapper {
      return replaced.computeIntrinsicAspectRatio() != 0
    }
    return false
  }

  func shouldComputeLogicalWidthFromAspectRatio() -> Bool {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func computeLogicalWidthFromAspectRatio(fragment: RenderFragmentContainerWrapper? = nil)
    -> LayoutUnit
  {
    assert(isNativeImpl())
    let logicalWidth = computeLogicalWidthFromAspectRatioInternal()
    let containerWidthInInlineDirection = max(
      LayoutUnit(value: 0), containingBlockLogicalWidthForContentInFragment(fragment: fragment))
    return constrainLogicalWidthInFragmentByMinMax(
      logicalWidth: logicalWidth, availableWidth: containerWidthInInlineDirection,
      cb: containingBlock()!, fragment: fragment, allowIntrinsic: .No)
  }

  func computeMinMaxLogicalWidthFromAspectRatio() -> (LayoutUnit, LayoutUnit) {
    assert(isNativeImpl())
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

  func computeMinMaxLogicalHeightFromAspectRatio() -> (LayoutUnit, LayoutUnit) {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  func computePreferredLogicalWidths(
    _ minWidth: LengthWrapper, _ maxWidth: LengthWrapper, _ borderAndPadding: LayoutUnit
  ) {
    assert(isNativeImpl())
    renderBoxComputePreferredLogicalWidths(minWidth, maxWidth, borderAndPadding)
  }

  func renderBoxComputePreferredLogicalWidths(
    _ minWidth: LengthWrapper, _ maxWidth: LengthWrapper, _ borderAndPadding: LayoutUnit
  ) {
    assert(isNativeImpl())
    if !style().logicalWidth().isFixed() && shouldComputeLogicalHeightFromAspectRatio() {
      var (logicalMinWidth, logicalMaxWidth) = computeMinMaxLogicalWidthFromAspectRatio()
      logicalMinWidth = max(logicalMinWidth - borderAndPadding, LayoutUnit(value: UInt64(0)))
      logicalMaxWidth = max(logicalMaxWidth - borderAndPadding, LayoutUnit(value: UInt64(0)))
      m_minPreferredLogicalWidth = clamp(
        val: m_minPreferredLogicalWidth, lo: logicalMinWidth, hi: logicalMaxWidth)
      m_maxPreferredLogicalWidth = clamp(
        val: m_maxPreferredLogicalWidth, lo: logicalMinWidth, hi: logicalMaxWidth)
    }

    if maxWidth.isFixed() {
      let adjustContentBoxLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: maxWidth)
      m_maxPreferredLogicalWidth = min(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidth)
      m_minPreferredLogicalWidth = min(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidth)
    }

    if minWidth.isFixed() && minWidth.value() > 0 {
      let adjustContentBoxLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: minWidth)
      m_maxPreferredLogicalWidth = max(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidth)
      m_minPreferredLogicalWidth = max(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidth)
    }

    m_minPreferredLogicalWidth += borderAndPadding
    m_maxPreferredLogicalWidth += borderAndPadding
  }

  private func replacedMinMaxLogicalHeightComputesAsNone(sizeType: SizeType) -> Bool {
    assert(isNativeImpl())
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

  private func updateShapeOutsideInfoAfterStyleChange(
    style: RenderStyleWrapper, oldStyle: RenderStyleWrapper?
  ) {
    assert(isNativeImpl())
    let shapeOutside = style.shapeOutside()
    let oldShapeOutside = oldStyle != nil ? oldStyle!.shapeOutside() : nil

    let shapeMargin = style.shapeMargin()
    let oldShapeMargin =
      oldStyle != nil ? oldStyle!.shapeMargin() : RenderStyleWrapper.initialShapeMargin()

    let shapeImageThreshold = style.shapeImageThreshold()
    let oldShapeImageThreshold =
      oldStyle != nil
      ? oldStyle!.shapeImageThreshold() : RenderStyleWrapper.initialShapeImageThreshold()

    // FIXME: A future optimization would do a deep comparison for equality. (bug 100811)
    if shapeOutside === oldShapeOutside && shapeMargin == oldShapeMargin
      && shapeImageThreshold == oldShapeImageThreshold
    {
      return
    }

    if shapeOutside == nil {
      removeShapeOutsideInfo()
    } else {
      ensureShapeOutsideInfo().markShapeAsDirty()
    }

    if shapeOutside != nil || shapeOutside !== oldShapeOutside {
      markShapeOutsideDependentsForLayout()
    }
  }

  private func updateGridPositionAfterStyleChange(
    style: RenderStyleWrapper, oldStyle: RenderStyleWrapper?
  ) {
    assert(isNativeImpl())
    if oldStyle == nil {
      return
    }
    let parentGrid = parent() as? RenderGridWrapper
    if parentGrid == nil {
      return
    }

    // Positioned items don't participate on the layout of the grid,
    // so we don't need to mark the grid as dirty if they change positions.
    if (oldStyle!.hasOutOfFlowPosition() && style.hasOutOfFlowPosition())
      || gridStyleHasNotChanged(style: style, oldStyle: oldStyle!)
    {
      return
    }

    // It should be possible to not dirty the grid in some cases (like moving an
    // explicitly placed grid item).
    // For now, it's more simple to just always recompute the grid.
    parentGrid!.dirtyGrid()
  }

  private func computeOrTrimInlineMargin(
    containingBlock: RenderBlockWrapper, marginSide: MarginTrimType,
    computeInlineMargin: () -> LayoutUnit
  ) -> LayoutUnit {
    assert(isNativeImpl())
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

  private func includeVerticalScrollbarSize() -> Bool {
    assert(isNativeImpl())
    return hasNonVisibleOverflow() && layer() != nil && !layer()!.hasOverlayScrollbars()
      && (style().overflowY() == .Scroll || style().overflowY() == .Auto
        || (style().overflowY() == .Hidden && !style().scrollbarGutter().isAuto))
  }

  private func includeHorizontalScrollbarSize() -> Bool {
    assert(isNativeImpl())
    return hasNonVisibleOverflow() && layer() != nil && !layer()!.hasOverlayScrollbars()
      && (style().overflowX() == .Scroll || style().overflowX() == .Auto
        || (style().overflowX() == .Hidden && !style().scrollbarGutter().isAuto))
  }

  private func computePositionedLogicalHeight(computedValues: inout LogicalExtentComputedValues) {
    assert(isNativeImpl())
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

  private func computePositionedLogicalWidthUsing(
    widthType: SizeType, logicalWidth: LengthWrapper, containerBlock: RenderBoxModelObjectWrapper,
    containerDirection: TextDirection, containerLogicalWidth: LayoutUnit,
    bordersPlusPadding: LayoutUnit, logicalLeft: LengthWrapper, logicalRight: LengthWrapper,
    marginLogicalLeft: LengthWrapper, marginLogicalRight: LengthWrapper,
    computedValues: inout LogicalExtentComputedValues
  ) {
    assert(isNativeImpl())
    assert(widthType == .MinSize || widthType == .MainOrPreferredSize || !logicalWidth.isAuto())
    let originalLogicalWidthType = logicalWidth.type()
    var logicalWidth = logicalWidth
    if widthType == .MinSize && logicalWidth.isAuto() {
      if shouldComputeLogicalWidthFromAspectRatio() {
        var minLogicalWidth = LayoutUnit()
        var maxLogicalWidth = LayoutUnit()
        computeIntrinsicLogicalWidths(
          minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
        logicalWidth = LengthWrapper(value: minLogicalWidth, type: .Fixed)
      } else {
        logicalWidth = LengthWrapper(value: Int32(0), type: .Fixed)
      }
    } else if widthType == .MainOrPreferredSize && logicalWidth.isAuto()
      && shouldComputeLogicalWidthFromAspectRatio()
    {
      logicalWidth = LengthWrapper(value: computeLogicalWidthFromAspectRatio(), type: .Fixed)
    } else if logicalWidth.isIntrinsic() {
      logicalWidth = LengthWrapper(
        value: computeIntrinsicLogicalWidthUsing(
          logicalWidthLength: logicalWidth, availableLogicalWidth: containerLogicalWidth,
          borderAndPadding: bordersPlusPadding) - bordersPlusPadding,
        type: .Fixed)
    }

    // 'left' and 'right' cannot both be 'auto' because one would of been
    // converted to the static position already
    assert(!(logicalLeft.isAuto() && logicalRight.isAuto()))

    let containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(
      containingBlock: containerBlock, fragment: nil, checkForPerpendicularWritingMode: false)

    let logicalWidthIsAuto =
      logicalWidth.isIntrinsicOrAuto() && !shouldComputeLogicalWidthFromAspectRatio()
    let logicalLeftIsAuto = logicalLeft.isAuto()
    let logicalRightIsAuto = logicalRight.isAuto()
    var marginLogicalLeftValue_ = LayoutUnit()

    var logicalLeftValue = LayoutUnit()

    if !logicalLeftIsAuto && !logicalWidthIsAuto && !logicalRightIsAuto {
      /*-----------------------------------------------------------------------*\
         * If none of the three is 'auto': If both 'margin-left' and 'margin-
         * right' are 'auto', solve the equation under the extra constraint that
         * the two margins get equal values, unless this would make them negative,
         * in which case when direction of the containing block is 'ltr' ('rtl'),
         * set 'margin-left' ('margin-right') to zero and solve for 'margin-right'
         * ('margin-left'). If one of 'margin-left' or 'margin-right' is 'auto',
         * solve the equation for that value. If the values are over-constrained,
         * ignore the value for 'left' (in case the 'direction' property of the
         * containing block is 'rtl') or 'right' (in case 'direction' is 'ltr')
         * and solve for that value.
        \*-----------------------------------------------------------------------*/
      // NOTE:  It is not necessary to solve for 'right' in the over constrained
      // case because the value is not used for any further calculations.

      logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
      computedValues.extent = adjustContentBoxLogicalWidthForBoxSizing(
        computedLogicalWidth: valueForLength(
          length: logicalWidth, maximumValue: containerLogicalWidth),
        originalType: originalLogicalWidthType)

      let availableSpace =
        containerLogicalWidth
        - (logicalLeftValue + computedValues.extent
          + valueForLength(length: logicalRight, maximumValue: containerLogicalWidth)
          + bordersPlusPadding)

      var marginLogicalLeftValue = MarginLogicalLeftValue(
        isLeftToRightDirection: style().isLeftToRightDirection())
      var marginLogicalRightValue = MarginLogicalRightValue(
        isLeftToRightDirection: style().isLeftToRightDirection())

      // Margins are now the only unknown
      if marginLogicalLeft.isAuto() && marginLogicalRight.isAuto() {
        // Both margins auto, solve for equality
        if availableSpace >= Int32(0) {
          marginLogicalLeftValue.set(availableSpace / 2, &computedValues)  // split the difference
          marginLogicalRightValue.set(
            availableSpace - marginLogicalLeftValue.get(computedValues), &computedValues)  // account for odd valued differences
        } else {
          // Use the containing block's direction rather than the parent block's
          // per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
          if containerDirection == .LTR {
            marginLogicalLeftValue.set(LayoutUnit(value: 0), &computedValues)
            marginLogicalRightValue.set(availableSpace, &computedValues)  // will be negative
          } else {
            marginLogicalLeftValue.set(availableSpace, &computedValues)  // will be negative
            marginLogicalRightValue.set(LayoutUnit(value: 0), &computedValues)
          }
        }
      } else if marginLogicalLeft.isAuto() {
        // Solve for left margin
        marginLogicalRightValue.set(
          valueForLength(length: marginLogicalRight, maximumValue: containerRelativeLogicalWidth),
          &computedValues)
        marginLogicalLeftValue.set(
          availableSpace - marginLogicalRightValue.get(computedValues), &computedValues)
      } else if marginLogicalRight.isAuto() {
        // Solve for right margin
        marginLogicalLeftValue.set(
          valueForLength(length: marginLogicalLeft, maximumValue: containerRelativeLogicalWidth),
          &computedValues)
        marginLogicalRightValue.set(
          availableSpace - marginLogicalLeftValue.get(computedValues), &computedValues)
      } else {
        // Over-constrained, solve for left if direction is RTL
        marginLogicalLeftValue.set(
          valueForLength(length: marginLogicalLeft, maximumValue: containerRelativeLogicalWidth),
          &computedValues)
        marginLogicalRightValue.set(
          valueForLength(length: marginLogicalRight, maximumValue: containerRelativeLogicalWidth),
          &computedValues)

        // Use the containing block's direction rather than the parent block's
        // per CSS 2.1 reference test abspos-non-replaced-width-margin-000.
        if !isOrthogonal(renderer: self, ancestor: containerBlock) && containerDirection == .RTL {
          logicalLeftValue =
            (availableSpace + logicalLeftValue) - marginLogicalLeftValue.get(computedValues)
            - marginLogicalRightValue.get(computedValues)
        }
      }
      marginLogicalLeftValue_ = marginLogicalLeftValue.get(computedValues)
    } else {
      /*--------------------------------------------------------------------*\
         * Otherwise, set 'auto' values for 'margin-left' and 'margin-right'
         * to 0, and pick the one of the following six rules that applies.
         *
         * 1. 'left' and 'width' are 'auto' and 'right' is not 'auto', then the
         *    width is shrink-to-fit. Then solve for 'left'
         *
         *              OMIT RULE 2 AS IT SHOULD NEVER BE HIT
         * ------------------------------------------------------------------
         * 2. 'left' and 'right' are 'auto' and 'width' is not 'auto', then if
         *    the 'direction' property of the containing block is 'ltr' set
         *    'left' to the static position, otherwise set 'right' to the
         *    static position. Then solve for 'left' (if 'direction is 'rtl')
         *    or 'right' (if 'direction' is 'ltr').
         * ------------------------------------------------------------------
         *
         * 3. 'width' and 'right' are 'auto' and 'left' is not 'auto', then the
         *    width is shrink-to-fit . Then solve for 'right'
         * 4. 'left' is 'auto', 'width' and 'right' are not 'auto', then solve
         *    for 'left'
         * 5. 'width' is 'auto', 'left' and 'right' are not 'auto', then solve
         *    for 'width'
         * 6. 'right' is 'auto', 'left' and 'width' are not 'auto', then solve
         *    for 'right'
         *
         * Calculation of the shrink-to-fit width is similar to calculating the
         * width of a table cell using the automatic table layout algorithm.
         * Roughly: calculate the preferred width by formatting the content
         * without breaking lines other than where explicit line breaks occur,
         * and also calculate the preferred minimum width, e.g., by trying all
         * possible line breaks. CSS 2.1 does not define the exact algorithm.
         * Thirdly, calculate the available width: this is found by solving
         * for 'width' after setting 'left' (in case 1) or 'right' (in case 3)
         * to 0.
         *
         * Then the shrink-to-fit width is:
         * min(max(preferred minimum width, available width), preferred width).
        \*--------------------------------------------------------------------*/
      // NOTE: For rules 3 and 6 it is not necessary to solve for 'right'
      // because the value is not used for any further calculations.

      // Calculate margins, 'auto' margins are ignored.
      let marginLogicalLeftValue = minimumValueForLength(
        length: marginLogicalLeft, maximumValue: containerRelativeLogicalWidth)
      let marginLogicalRightValue = minimumValueForLength(
        length: marginLogicalRight, maximumValue: containerRelativeLogicalWidth)

      let availableSpace =
        containerLogicalWidth
        - (marginLogicalLeftValue + marginLogicalRightValue + bordersPlusPadding)

      // FIXME: Is there a faster way to find the correct case?
      // Use rule/case that applies.
      if logicalLeftIsAuto && logicalWidthIsAuto && !logicalRightIsAuto {
        // RULE 1: (use shrink-to-fit for width, and solve of left)
        let logicalRightValue = valueForLength(
          length: logicalRight, maximumValue: containerLogicalWidth)
        computedValues.extent = shrinkToFitLogicalWidth(
          availableLogicalWidth: availableSpace - logicalRightValue,
          bordersPlusPadding: bordersPlusPadding)
        logicalLeftValue = availableSpace - (computedValues.extent + logicalRightValue)
      } else if !logicalLeftIsAuto && logicalWidthIsAuto && logicalRightIsAuto {
        // RULE 3: (use shrink-to-fit for width, and no need solve of right)
        logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
        computedValues.extent = shrinkToFitLogicalWidth(
          availableLogicalWidth: availableSpace - logicalLeftValue,
          bordersPlusPadding: bordersPlusPadding)
      } else if logicalLeftIsAuto && !logicalWidthIsAuto && !logicalRightIsAuto {
        // RULE 4: (solve for left)
        computedValues.extent = adjustContentBoxLogicalWidthForBoxSizing(
          computedLogicalWidth: valueForLength(
            length: logicalWidth, maximumValue: containerLogicalWidth),
          originalType: originalLogicalWidthType)
        logicalLeftValue =
          availableSpace
          - (computedValues.extent
            + valueForLength(length: logicalRight, maximumValue: containerLogicalWidth))
      } else if !logicalLeftIsAuto && logicalWidthIsAuto && !logicalRightIsAuto {
        // RULE 5: (solve for width)
        logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
        computedValues.extent =
          availableSpace
          - (logicalLeftValue
            + valueForLength(length: logicalRight, maximumValue: containerLogicalWidth))
      } else if !logicalLeftIsAuto && !logicalWidthIsAuto && logicalRightIsAuto {
        // RULE 6: (no need solve for right)
        logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
        computedValues.extent = adjustContentBoxLogicalWidthForBoxSizing(
          computedLogicalWidth: valueForLength(
            length: logicalWidth, maximumValue: containerLogicalWidth),
          originalType: originalLogicalWidthType)
      }
      marginLogicalLeftValue_ = marginLogicalLeftValue
    }

    // Use computed values to calculate the horizontal position.

    // FIXME: This hack is needed to calculate the logical left position for a 'rtl' relatively
    // positioned, inline because right now, it is using the logical left position
    // of the first line box when really it should use the last line box. When
    // this is fixed elsewhere, this block should be removed.
    if let position = positionWithRTLInlineBoxContainingBlock(
      containingBlock: containerBlock, logicalLeftValue: logicalLeftValue,
      marginLogicalLeftValue: marginLogicalLeftValue_)
    {
      computedValues.position = LayoutUnit(value: position)
      return
    }

    computedValues.position = logicalLeftValue + marginLogicalLeftValue_
    computeLogicalLeftPositionedOffset(
      logicalLeftPos: &computedValues.position, child: self,
      logicalWidthValue: computedValues.extent + bordersPlusPadding, containerBlock: containerBlock,
      containerLogicalWidth: containerLogicalWidth,
      logicalLeftIsAuto: style().logicalLeft().isAuto(),
      logicalRightIsAuto: style().logicalRight().isAuto())
  }

  private func shrinkToFitLogicalWidth(
    availableLogicalWidth: LayoutUnit, bordersPlusPadding: LayoutUnit
  ) -> LayoutUnit {
    assert(isNativeImpl())
    let preferredMaxLogicalWidth = maxPreferredLogicalWidth() - bordersPlusPadding
    let preferredMinLogicalWidth = minPreferredLogicalWidth() - bordersPlusPadding
    return clamp(
      val: availableLogicalWidth, lo: preferredMinLogicalWidth, hi: preferredMaxLogicalWidth)
  }

  private struct MarginLogicalLeftValue {
    init(isLeftToRightDirection: Bool) {
      self.isLeftToRightDirection = isLeftToRightDirection
    }

    mutating func set(_ value: LayoutUnit, _ computedValues: inout LogicalExtentComputedValues) {
      if isLeftToRightDirection {
        computedValues.margins.start = value
      } else {
        computedValues.margins.end = value
      }
    }

    func get(_ computedValues: LogicalExtentComputedValues) -> LayoutUnit {
      return isLeftToRightDirection ? computedValues.margins.start : computedValues.margins.end
    }

    private let isLeftToRightDirection: Bool
  }

  private struct MarginLogicalRightValue {
    init(isLeftToRightDirection: Bool) {
      self.isLeftToRightDirection = isLeftToRightDirection
    }

    mutating func set(_ value: LayoutUnit, _ computedValues: inout LogicalExtentComputedValues) {
      if isLeftToRightDirection {
        computedValues.margins.end = value
      } else {
        computedValues.margins.start = value
      }
    }

    func get(_ computedValues: LogicalExtentComputedValues) -> LayoutUnit {
      return isLeftToRightDirection ? computedValues.margins.end : computedValues.margins.start
    }

    private let isLeftToRightDirection: Bool
  }

  private func computePositionedLogicalHeightUsing(
    heightType: SizeType, logicalHeightLength: LengthWrapper,
    containerBlock: RenderBoxModelObjectWrapper, containerLogicalHeight: LayoutUnit,
    bordersPlusPadding: LayoutUnit, logicalHeight: LayoutUnit, logicalTop: LengthWrapper,
    logicalBottom: LengthWrapper, marginBefore: LengthWrapper, marginAfter: LengthWrapper,
    computedValues: inout LogicalExtentComputedValues
  ) {
    assert(isNativeImpl())
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
    assert(isNativeImpl())
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

  private func computePositionedLogicalWidthReplaced(
    computedValues: inout LogicalExtentComputedValues
  ) {
    assert(isNativeImpl())
    // The following is based off of the W3C Working Draft from April 11, 2006 of
    // CSS 2.1: Section 10.3.8 "Absolutely positioned, replaced elements"
    // <http://www.w3.org/TR/2005/WD-CSS21-20050613/visudet.html#abs-replaced-width>
    // (block-style-comments in this function correspond to text from the spec and
    // the numbers correspond to numbers in spec)

    // We don't use containingBlock(), since we may be positioned by an enclosing
    // relative positioned inline.
    let containerBlock = container() as! RenderBoxModelObjectWrapper

    let containerLogicalWidth = containingBlockLogicalWidthForPositioned(
      containingBlock: containerBlock)
    let containerRelativeLogicalWidth = containingBlockLogicalWidthForPositioned(
      containingBlock: containerBlock, fragment: nil, checkForPerpendicularWritingMode: false)

    // To match WinIE, in quirks mode use the parent's 'direction' property
    // instead of the container block's.
    let containerDirection = containerBlock.style().direction()

    // Variables to solve.
    let isHorizontal = isHorizontalWritingMode()
    let originalLogicalLeft = style().logicalLeft()
    let originalLogicalRight = style().logicalRight()
    var logicalLeft = originalLogicalLeft
    var logicalRight = originalLogicalRight

    let marginLogicalLeft = isHorizontal ? style().marginLeft() : style().marginTop()
    let marginLogicalRight = isHorizontal ? style().marginRight() : style().marginBottom()
    var marginLogicalLeftAlias = MarginLogicalLeftValue(
      isLeftToRightDirection: style().isLeftToRightDirection())
    var marginLogicalRightAlias = MarginLogicalRightValue(
      isLeftToRightDirection: style().isLeftToRightDirection())

    /*-----------------------------------------------------------------------*\
     * 1. The used value of 'width' is determined as for inline replaced
     *    elements.
    \*-----------------------------------------------------------------------*/
    // NOTE: This value of width is final in that the min/max width calculations
    // are dealt with in computeReplacedWidth().  This means that the steps to produce
    // correct max/min in the non-replaced version, are not necessary.
    computedValues.extent = computeReplacedLogicalWidth() + borderAndPaddingLogicalWidth()

    let availableSpace = containerLogicalWidth - computedValues.extent

    /*-----------------------------------------------------------------------*\
     * 2. If both 'left' and 'right' have the value 'auto', then if 'direction'
     *    of the containing block is 'ltr', set 'left' to the static position;
     *    else if 'direction' is 'rtl', set 'right' to the static position.
    \*-----------------------------------------------------------------------*/
    // see FIXME 1
    computeInlineStaticDistance(
      logicalLeft: &logicalLeft, logicalRight: &logicalRight, child: self,
      containerBlock: containerBlock, containerLogicalWidth: containerLogicalWidth, fragment: nil)  // FIXME: Pass the fragment.

    /*-----------------------------------------------------------------------*\
     * 3. If 'left' or 'right' are 'auto', replace any 'auto' on 'margin-left'
     *    or 'margin-right' with '0'.
    \*-----------------------------------------------------------------------*/
    if logicalLeft.isAuto() || logicalRight.isAuto() {
      if marginLogicalLeft.isAuto() {
        marginLogicalLeft.setValue(type: .Fixed, value: Int32(0))
      }
      if marginLogicalRight.isAuto() {
        marginLogicalRight.setValue(type: .Fixed, value: Int32(0))
      }
    }

    /*-----------------------------------------------------------------------*\
     * 4. If at this point both 'margin-left' and 'margin-right' are still
     *    'auto', solve the equation under the extra constraint that the two
     *    margins must get equal values, unless this would make them negative,
     *    in which case when the direction of the containing block is 'ltr'
     *    ('rtl'), set 'margin-left' ('margin-right') to zero and solve for
     *    'margin-right' ('margin-left').
    \*-----------------------------------------------------------------------*/
    var logicalLeftValue = LayoutUnit()
    var logicalRightValue = LayoutUnit()

    if marginLogicalLeft.isAuto() && marginLogicalRight.isAuto() {
      // 'left' and 'right' cannot be 'auto' due to step 3
      assert(!(logicalLeft.isAuto() && logicalRight.isAuto()))

      logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
      logicalRightValue = valueForLength(length: logicalRight, maximumValue: containerLogicalWidth)

      let difference = availableSpace - (logicalLeftValue + logicalRightValue)
      if difference > 0 {
        marginLogicalLeftAlias.set(difference / 2, &computedValues)  // split the difference
        marginLogicalRightAlias.set(
          difference - marginLogicalLeftAlias.get(computedValues), &computedValues)  // account for odd valued differences
      } else {
        // Use the containing block's direction rather than the parent block's
        // per CSS 2.1 reference test abspos-replaced-width-margin-000.
        if containerDirection == .LTR {
          marginLogicalLeftAlias.set(LayoutUnit(value: 0), &computedValues)
          marginLogicalRightAlias.set(difference, &computedValues)  // will be negative
        } else {
          marginLogicalLeftAlias.set(difference, &computedValues)  // will be negative
          marginLogicalRightAlias.set(LayoutUnit(value: 0), &computedValues)
        }
      }

      /*-----------------------------------------------------------------------*\
     * 5. If at this point there is an 'auto' left, solve the equation for
     *    that value.
    \*-----------------------------------------------------------------------*/
    } else if logicalLeft.isAuto() {
      marginLogicalLeftAlias.set(
        valueForLength(
          length: marginLogicalLeft, maximumValue: containerRelativeLogicalWidth), &computedValues)
      marginLogicalRightAlias.set(
        valueForLength(
          length: marginLogicalRight, maximumValue: containerRelativeLogicalWidth), &computedValues)
      logicalRightValue = valueForLength(length: logicalRight, maximumValue: containerLogicalWidth)

      // Solve for 'left'
      logicalLeftValue =
        availableSpace
        - (logicalRightValue + marginLogicalLeftAlias.get(computedValues)
          + marginLogicalRightAlias.get(computedValues))
    } else if logicalRight.isAuto() {
      marginLogicalLeftAlias.set(
        valueForLength(
          length: marginLogicalLeft, maximumValue: containerRelativeLogicalWidth), &computedValues)
      marginLogicalRightAlias.set(
        valueForLength(
          length: marginLogicalRight, maximumValue: containerRelativeLogicalWidth), &computedValues)
      logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)

      // Solve for 'right'
      logicalRightValue =
        availableSpace
        - (logicalLeftValue + marginLogicalLeftAlias.get(computedValues)
          + marginLogicalRightAlias.get(computedValues))
    } else if marginLogicalLeft.isAuto() {
      marginLogicalRightAlias.set(
        valueForLength(
          length: marginLogicalRight, maximumValue: containerRelativeLogicalWidth), &computedValues)
      logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
      logicalRightValue = valueForLength(length: logicalRight, maximumValue: containerLogicalWidth)

      // Solve for 'margin-left'
      marginLogicalLeftAlias.set(
        availableSpace
          - (logicalLeftValue + logicalRightValue + marginLogicalRightAlias.get(computedValues)),
        &computedValues)
    } else if marginLogicalRight.isAuto() {
      marginLogicalLeftAlias.set(
        valueForLength(
          length: marginLogicalLeft, maximumValue: containerRelativeLogicalWidth), &computedValues)
      logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
      logicalRightValue = valueForLength(length: logicalRight, maximumValue: containerLogicalWidth)

      // Solve for 'margin-right'
      marginLogicalRightAlias.set(
        availableSpace
          - (logicalLeftValue + logicalRightValue + marginLogicalLeftAlias.get(computedValues)),
        &computedValues)
    } else {
      // Nothing is 'auto', just calculate the values.
      marginLogicalLeftAlias.set(
        valueForLength(length: marginLogicalLeft, maximumValue: containerRelativeLogicalWidth),
        &computedValues)
      marginLogicalRightAlias.set(
        valueForLength(length: marginLogicalRight, maximumValue: containerRelativeLogicalWidth),
        &computedValues)
      logicalRightValue = valueForLength(length: logicalRight, maximumValue: containerLogicalWidth)
      logicalLeftValue = valueForLength(length: logicalLeft, maximumValue: containerLogicalWidth)
      // If the containing block is right-to-left, then push the left position as far to the right as possible
      if containerDirection == .RTL {
        let totalLogicalWidth =
          computedValues.extent + logicalLeftValue + logicalRightValue
          + marginLogicalLeftAlias.get(computedValues)
          + marginLogicalRightAlias.get(computedValues)
        logicalLeftValue = containerLogicalWidth - (totalLogicalWidth - logicalLeftValue)
      }
    }

    /*-----------------------------------------------------------------------*\
     * 6. If at this point the values are over-constrained, ignore the value
     *    for either 'left' (in case the 'direction' property of the
     *    containing block is 'rtl') or 'right' (in case 'direction' is
     *    'ltr') and solve for that value.
    \*-----------------------------------------------------------------------*/
    // NOTE: Constraints imposed by the width of the containing block and its content have already been accounted for above.

    // FIXME: Deal with differing writing modes here.  Our offset needs to be in the containing block's coordinate space, so that
    // can make the result here rather complicated to compute.

    // Use computed values to calculate the horizontal position.

    // FIXME: This hack is needed to calculate the logical left position for a 'rtl' relatively
    // positioned, inline containing block because right now, it is using the logical left position
    // of the first line box when really it should use the last line box. When
    // this is fixed elsewhere, this block should be removed.
    if let position = positionWithRTLInlineBoxContainingBlock(
      containingBlock: containerBlock, logicalLeftValue: logicalLeftValue,
      marginLogicalLeftValue: marginLogicalLeftAlias.get(computedValues))
    {
      computedValues.position = LayoutUnit(value: position)
      return
    }

    var logicalLeftPos = logicalLeftValue + marginLogicalLeftAlias.get(computedValues)
    // Border and padding have already been included in computedValues.m_extent.
    computeLogicalLeftPositionedOffset(
      logicalLeftPos: &logicalLeftPos, child: self, logicalWidthValue: computedValues.extent,
      containerBlock: containerBlock, containerLogicalWidth: containerLogicalWidth,
      logicalLeftIsAuto: originalLogicalLeft.isAuto(),
      logicalRightIsAuto: originalLogicalRight.isAuto())
    computedValues.position = logicalLeftPos
  }

  private func fillAvailableMeasure(availableLogicalWidth: LayoutUnit) -> LayoutUnit {
    assert(isNativeImpl())
    var marginStart = LayoutUnit()
    var marginEnd = LayoutUnit()
    return fillAvailableMeasure(
      availableLogicalWidth: availableLogicalWidth, marginStart: &marginStart, marginEnd: &marginEnd
    )
  }

  private func fillAvailableMeasure(
    availableLogicalWidth: LayoutUnit, marginStart: inout LayoutUnit, marginEnd: inout LayoutUnit
  ) -> LayoutUnit {
    assert(isNativeImpl())
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

  func computeIntrinsicKeywordLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    assert(isNativeImpl())
    computeIntrinsicLogicalWidths(
      minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
  }

  // This function calculates the minimum and maximum preferred widths for an object.
  // These values are used in shrink-to-fit layout systems.
  // These include tables, positioned objects, floats and flexible boxes.
  func computePreferredLogicalWidths() {
    assert(isNativeImpl())
    assert(preferredLogicalWidthsDirty())

    computePreferredLogicalWidths(
      minWidth: style().logicalMinWidth(), maxWidth: style().logicalMaxWidth(),
      borderAndPadding: borderAndPaddingLogicalWidth())
    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  func computePreferredLogicalWidths(
    minWidth: LengthWrapper, maxWidth: LengthWrapper, borderAndPadding: LayoutUnit
  ) {
    assert(isNativeImpl())
    if !style().logicalWidth().isFixed() && shouldComputeLogicalHeightFromAspectRatio() {
      var (logicalMinWidth, logicalMaxWidth) = computeMinMaxLogicalWidthFromAspectRatio()
      logicalMinWidth = max(logicalMinWidth - borderAndPadding, LayoutUnit(value: UInt64(0)))
      logicalMaxWidth = max(logicalMaxWidth - borderAndPadding, LayoutUnit(value: UInt64(0)))
      m_minPreferredLogicalWidth = clamp(
        val: m_minPreferredLogicalWidth, lo: logicalMinWidth, hi: logicalMaxWidth)
      m_maxPreferredLogicalWidth = clamp(
        val: m_maxPreferredLogicalWidth, lo: logicalMinWidth, hi: logicalMaxWidth)
    }

    if maxWidth.isFixed() {
      let adjustContentBoxLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: maxWidth)
      m_maxPreferredLogicalWidth = min(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidth)
      m_minPreferredLogicalWidth = min(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidth)
    }

    if minWidth.isFixed() && minWidth.value() > 0 {
      let adjustContentBoxLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: minWidth)
      m_maxPreferredLogicalWidth = max(m_maxPreferredLogicalWidth, adjustContentBoxLogicalWidth)
      m_minPreferredLogicalWidth = max(m_minPreferredLogicalWidth, adjustContentBoxLogicalWidth)
    }

    m_minPreferredLogicalWidth += borderAndPadding
    m_maxPreferredLogicalWidth += borderAndPadding
  }

  override func frameRectForStickyPositioning() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return frameRect()
  }

  private func computeVisibleRectsUsingPaintOffset(_ rects: RepaintRects) -> RepaintRects {
    assert(isNativeImpl())
    var adjustedRects = rects
    let layoutState = view().frameView().layoutContext().layoutState()!

    if hasLayer() && layer()!.transform != nil {
      adjustedRects.transform(layer()!.transform!, document().deviceScaleFactor())
    }

    // We can't trust the bits on RenderObject, because this might be called while re-resolving style.
    if style().hasInFlowPosition() && layer() != nil {
      adjustedRects.move(layer()!.offsetForInFlowPosition())
    }

    adjustedRects.moveBy(location())
    adjustedRects.move(layoutState.paintOffset())
    if layoutState.isClipped() {
      adjustedRects.clippedOverflowRect.intersect(other: layoutState.clipRect())
    }
    return adjustedRects
  }

  private func topLeftLocationWithFlipping() -> LayoutPointWrapper {
    assert(isNativeImpl())
    assert(view().frameView().hasFlippedBlockRenderers())

    let containerBlock = containingBlock()
    if containerBlock == nil || CPtrToInt(containerBlock!.id()) == CPtrToInt(id()) {
      return location()
    }

    return containerBlock!.flipForWritingModeForChild(child: self, point: location())
  }

  private func addLayoutOverflow(rect: LayoutRectWrapper, clientBox: LayoutRectWrapper) {
    assert(isNativeImpl())
    if clientBox.contains(other: rect) || rect.isEmpty() {
      return
    }

    // For overflow clip objects, we don't want to propagate overflow into unreachable areas.
    var overflowRect = rect
    if hasPotentiallyScrollableOverflow() || isRenderView() {
      let allowance = allowedLayoutOverflow()
      // Non-negative values indicate a limit, let's apply them.
      if allowance.top != nil {
        overflowRect.shiftYEdgeTo(edge: max(overflowRect.y(), clientBox.y() - allowance.top!))
      }
      if allowance.bottom != nil {
        overflowRect.shiftMaxYEdgeTo(
          edge: min(overflowRect.maxY(), clientBox.maxY() + allowance.bottom!))
      }
      if allowance.left != nil {
        overflowRect.shiftXEdgeTo(edge: max(overflowRect.x(), clientBox.x() - allowance.left!))
      }
      if allowance.right != nil {
        overflowRect.shiftMaxXEdgeTo(
          edge: min(overflowRect.maxX(), clientBox.maxX() + allowance.right!))
      }

      // Now re-test with the adjusted rectangle and see if it has become unreachable or fully
      // contained.
      if clientBox.contains(other: overflowRect) || overflowRect.isEmpty() {
        return
      }
    }

    if overflow == nil {
      overflow = RenderOverflow(layoutRect: clientBox, visualRect: borderBoxRect())
    }

    overflow!.addLayoutOverflow(rect: overflowRect)
  }

  func ensureShapeOutsideInfo() -> ShapeOutsideInfoWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeShapeOutsideInfo() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The width/height of the contents + borders + padding.  The x/y location is relative to our container (which is not always our parent).
  private var m_frameRect = LayoutRectWrapper()

  var marginBox = LayoutBoxExtent(
    top: LayoutUnit(), right: LayoutUnit(), bottom: LayoutUnit(), left: LayoutUnit())

  // The preferred logical width of the element if it were to break its lines at every possible opportunity.
  var m_minPreferredLogicalWidth = LayoutUnit()

  // The preferred logical width of the element if it never breaks any lines at all.
  var m_maxPreferredLogicalWidth = LayoutUnit()

  // Our overflow information.
  var overflow: RenderOverflow? = nil

  // Used to store state between styleWillChange and styleDidChange
  private static var hadNonVisibleOverflow = false
}

func synthesizedBaseline(
  box: RenderBoxWrapper, parentStyle: RenderStyleWrapper, direction: LineDirectionMode,
  edge: BaselineSynthesisEdge
) -> LayoutUnit {
  var boxSize = direction == .HorizontalLine ? box.height() : box.width()
  if edge == .ContentBox {
    boxSize -=
      direction == .HorizontalLine
      ? box.verticalBorderAndPaddingExtent() : box.horizontalBorderAndPaddingExtent()
  } else if edge == .MarginBox {
    boxSize +=
      direction == .HorizontalLine ? box.verticalMarginExtent() : box.horizontalMarginExtent()
  }

  let textOrientation = parentStyle.textOrientation()
  let baselineType = baselineType(parentStyle: parentStyle)
  if baselineType == .AlphabeticBaseline {
    let shouldTreatAsHorizontal =
      direction == .HorizontalLine
      || (textOrientation == .Sideways && parentStyle.writingMode() == .VerticalRl)
    return shouldTreatAsHorizontal ? boxSize : LayoutUnit()
  }
  return boxSize / 2
}

private func baselineType(parentStyle: RenderStyleWrapper) -> FontBaseline {
  // https://drafts.csswg.org/css-inline-3/#alignment-baseline-property
  // https://drafts.csswg.org/css-inline-3/#dominant-baseline-property
  let isInsideHorizontalWritingMode = parentStyle.isHorizontalWritingMode()
  let textOrientation = parentStyle.textOrientation()
  if isInsideHorizontalWritingMode || textOrientation == .Sideways {
    return .AlphabeticBaseline
  }
  if textOrientation == .Upright || textOrientation == .Mixed {
    return .CentralBaseline
  }

  fatalError("Not implemented yet")
}
