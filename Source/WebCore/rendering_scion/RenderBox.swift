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

enum OverlayScrollbarSizeRelevancy {
  case IgnoreOverlayScrollbarSize
  case IncludeOverlayScrollbarSize
}

private func outermostBlockContainingFloatingObject(box: RenderBoxWrapper)
  -> RenderBlockFlowWrapper?
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

  func logicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func collapsedMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func overridingLogicalHeight() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  typealias ContainingBlockOverrideValue = LayoutUnit?

  func overridingContainingBlockContentLogicalWidth() -> ContainingBlockOverrideValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overridingContainingBlockContentLogicalHeight() -> ContainingBlockOverrideValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalWidthLength(height: LengthWrapper) {
    wk_interop.RenderBox_setOverridingLogicalWidthLength(p, height.p)
  }

  func clearOverridingLogicalWidthLength() {
    wk_interop.RenderBox_clearOverridingLogicalWidthLength(p)
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
      paintObject(paintInfo: paintInfo, paintOffset: accumulatedOffset)
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
      paintObject(paintInfo: paintInfo, paintOffset: accumulatedOffset)
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

  func paintObject(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    fatalError("Not reached")
  }

  func paintBoxDecorations(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    var paintRect = borderBoxRectInFragment(fragment: nil)
    paintRect.moveBy(offset: paintOffset)
    adjustBorderBoxRectForPainting(paintRect: paintRect)

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

    let paintRect = LayoutRectWrapper(location: paintOffset, size: size())
    adjustBorderBoxRectForPainting(paintRect: paintRect)
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func scrollPosition() -> ScrollPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func adjustBorderBoxRectForPainting(paintRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func paintMaskImages(paintInfo: PaintInfoWrapper, paintRect: LayoutRectWrapper) {
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

  private func determineBackgroundBleedAvoidance(context: GraphicsContextWrapper)
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
}
