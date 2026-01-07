/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2018 Google Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011-2012. All rights reserved.
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

private let cDefaultWidth: Int32 = 300
private let cDefaultHeight: Int32 = 150

private func contentContainsReplacedElement(
  _ markers: ArraySlice<RenderedDocumentMarker>, _ element: ElementWrapper
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func isVideoWithDefaultObjectSize(_ maybeVideo: RenderReplacedWrapper?) -> Bool {
  return (maybeVideo as? RenderVideoWrapper)?.hasDefaultObjectSize() ?? false
}

private func resolveWidthForRatio(
  _ borderAndPaddingLogicalHeight: LayoutUnit, _ borderAndPaddingLogicalWidth: LayoutUnit,
  _ logicalHeight: LayoutUnit, _ aspectRatio: Float64, _ boxSizing: BoxSizing
) -> LayoutUnit {
  if boxSizing == .BorderBox {
    return LayoutUnit(value: (logicalHeight + borderAndPaddingLogicalHeight) * aspectRatio)
      - borderAndPaddingLogicalWidth
  }
  return LayoutUnit(value: logicalHeight * aspectRatio)
}

private func hasIntrinsicSize(
  _ contentRenderer: RenderBoxWrapper?, hasIntrinsicWidth: Bool, hasIntrinsicHeight: Bool
) -> Bool {
  if hasIntrinsicWidth && hasIntrinsicHeight {
    return true
  }
  if hasIntrinsicWidth || hasIntrinsicHeight {
    return contentRenderer != nil && contentRenderer!.isRenderOrLegacyRenderSVGRoot()
  }
  return false
}

private func resolveHeightForRatio(
  _ borderAndPaddingLogicalWidth: LayoutUnit, _ borderAndPaddingLogicalHeight: LayoutUnit,
  _ logicalWidth: LayoutUnit, _ aspectRatio: Float64, _ boxSizing: BoxSizing
) -> LayoutUnit {
  if boxSizing == .BorderBox {
    return LayoutUnit(value: (logicalWidth + borderAndPaddingLogicalWidth) * aspectRatio)
      - borderAndPaddingLogicalHeight
  }
  return LayoutUnit(value: logicalWidth * aspectRatio)
}

class RenderReplacedWrapper: RenderBoxWrapper {
  override func computeReplacedLogicalWidth(
    shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  )
    -> LayoutUnit
  {
    if style().logicalWidth().isSpecified() {
      return computeReplacedLogicalWidthRespectingMinMaxWidth(
        computeReplacedLogicalWidthUsing(.MainOrPreferredSize, style().logicalWidth()),
        shouldComputePreferred)
    }
    if style().logicalWidth().isIntrinsic() {
      return computeReplacedLogicalWidthRespectingMinMaxWidth(
        computeReplacedLogicalWidthUsing(.MainOrPreferredSize, style().logicalWidth()),
        shouldComputePreferred)
    }

    let contentRenderer = embeddedContentBox()

    // 10.3.2 Inline, replaced elements: http://www.w3.org/TR/CSS21/visudet.html#inline-replaced-width
    let (constrainedSize, intrinsicRatio) =
      computeIntrinsicSizesConstrainedByTransferredMinMaxSizes(contentRenderer)

    if style().logicalWidth().isAuto() {
      let computedHeightIsAuto = style().logicalHeight().isAuto()
      let hasIntrinsicWidth = constrainedSize.width > 0 || shouldApplySizeOrInlineSizeContainment()
      let hasIntrinsicHeight = constrainedSize.height > 0 || shouldApplySizeContainment()

      // For flex or grid items where the logical height has been overriden then we should use that size to compute the replaced width as long as the flex or
      // grid item has an intrinsic size. It is possible (indeed, common) for an SVG graphic to have an intrinsic aspect ratio but not to have an intrinsic
      // width or height. There are also elements with intrinsic sizes but without intrinsic ratio (like an iframe).
      if let overridingLogicalHeight =
        (!intrinsicRatio.isEmpty() && (isFlexItem() || isGridItem())
          && hasIntrinsicSize(
            contentRenderer, hasIntrinsicWidth: hasIntrinsicWidth,
            hasIntrinsicHeight: hasIntrinsicHeight)
          ? overridingLogicalHeight() : nil)
      {
        return computeReplacedLogicalWidthRespectingMinMaxWidth(
          overridingContentLogicalHeight(overridingLogicalHeight: overridingLogicalHeight)
            * intrinsicRatio.aspectRatioDouble(), shouldComputePreferred)
      }

      // If 'height' and 'width' both have computed values of 'auto' and the element also has an intrinsic width, then that intrinsic width is the used value of 'width'.
      if computedHeightIsAuto && hasIntrinsicWidth {
        return computeReplacedLogicalWidthRespectingMinMaxWidth(
          constrainedSize.width, shouldComputePreferred)
      }

      if !intrinsicRatio.isEmpty() {
        // If 'height' and 'width' both have computed values of 'auto' and the element has no intrinsic width, but does have an intrinsic height and intrinsic ratio;
        // or if 'width' has a computed value of 'auto', 'height' has some other computed value, and the element does have an intrinsic ratio; then the used value
        // of 'width' is: (used height) * (intrinsic ratio)
        if !computedHeightIsAuto || (!hasIntrinsicWidth && hasIntrinsicHeight) {
          let estimatedUsedWidth =
            hasIntrinsicWidth
            ? LayoutUnit(value: constrainedSize.width)
            : computeConstrainedLogicalWidth(shouldComputePreferred)
          let logicalHeight = computeReplacedLogicalHeight(estimatedUsedWidth: estimatedUsedWidth)
          let boxSizing = style().hasAspectRatio() ? style().boxSizingForAspectRatio() : .ContentBox
          return computeReplacedLogicalWidthRespectingMinMaxWidth(
            resolveWidthForRatio(
              borderAndPaddingLogicalHeight(), borderAndPaddingLogicalWidth(), logicalHeight,
              intrinsicRatio.aspectRatioDouble(), boxSizing), shouldComputePreferred)
        }

        // If 'height' and 'width' both have computed values of 'auto' and the
        // element has an intrinsic ratio but no intrinsic height or width, then
        // the used value of 'width' is undefined in CSS 2.1. However, it is
        // suggested that, if the containing block's width does not itself depend
        // on the replaced element's width, then the used value of 'width' is
        // calculated from the constraint equation used for block-level,
        // non-replaced elements in normal flow.
        if computedHeightIsAuto && !hasIntrinsicWidth && !hasIntrinsicHeight {
          return computeConstrainedLogicalWidth(shouldComputePreferred)
        }
      }

      // Otherwise, if 'width' has a computed value of 'auto', and the element has an intrinsic width, then that intrinsic width is the used value of 'width'.
      if hasIntrinsicWidth {
        return computeReplacedLogicalWidthRespectingMinMaxWidth(
          constrainedSize.width, shouldComputePreferred)
      }

      // Otherwise, if 'width' has a computed value of 'auto', but none of the conditions above are met, then the used value of 'width' becomes 300px. If 300px is too
      // wide to fit the device, UAs should use the width of the largest rectangle that has a 2:1 ratio and fits the device instead.
      // Note: We fall through and instead return intrinsicLogicalWidth() here - to preserve existing WebKit behavior, which might or might not be correct, or desired.
      // Changing this to return cDefaultWidth, will affect lots of test results. Eg. some tests assume that a blank <img> tag (which implies width/height=auto)
      // has no intrinsic size, which is wrong per CSS 2.1, but matches our behavior since a long time.
    }

    return computeReplacedLogicalWidthRespectingMinMaxWidth(
      intrinsicLogicalWidth(), shouldComputePreferred)
  }

  override func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    // 10.5 Content height: the 'height' property: http://www.w3.org/TR/CSS21/visudet.html#propdef-height
    if hasReplacedLogicalHeight() {
      return computeReplacedLogicalHeightRespectingMinMaxHeight(
        logicalHeight: computeReplacedLogicalHeightUsing(
          heightType: .MainOrPreferredSize, logicalHeight: style().logicalHeight()))
    }

    let contentRenderer = embeddedContentBox()

    // 10.6.2 Inline, replaced elements: http://www.w3.org/TR/CSS21/visudet.html#inline-replaced-height
    let (constrainedSize, intrinsicRatio) =
      computeIntrinsicSizesConstrainedByTransferredMinMaxSizes(contentRenderer)

    let widthIsAuto = style().logicalWidth().isAuto()
    let hasIntrinsicHeight = constrainedSize.height > 0 || shouldApplySizeContainment()
    let hasIntrinsicWidth = constrainedSize.width > 0 || shouldApplySizeOrInlineSizeContainment()

    // See computeReplacedLogicalHeight() for a similar check for heights.
    if let overridinglogicalWidth =
      (!intrinsicRatio.isEmpty() && (isFlexItem() || isGridItem())
        && hasIntrinsicSize(
          contentRenderer, hasIntrinsicWidth: hasIntrinsicWidth,
          hasIntrinsicHeight: hasIntrinsicHeight)
        ? overridingLogicalWidth() : nil)
    {
      return computeReplacedLogicalHeightRespectingMinMaxHeight(
        logicalHeight: LayoutUnit(
          value: overridingContentLogicalWidth(overridinglogicalWidth)
            * intrinsicRatio.transposedSize().aspectRatioDouble()))
    }

    // If 'height' and 'width' both have computed values of 'auto' and the element also has an intrinsic height, then that intrinsic height is the used value of 'height'.
    if widthIsAuto && hasIntrinsicHeight {
      return computeReplacedLogicalHeightRespectingMinMaxHeight(
        logicalHeight: constrainedSize.height)
    }

    // Otherwise, if 'height' has a computed value of 'auto', and the element has an intrinsic ratio then the used value of 'height' is:
    // (used width) / (intrinsic ratio)
    if !intrinsicRatio.isEmpty() {
      let usedWidth = estimatedUsedWidth ?? availableLogicalWidth()
      var boxSizing: BoxSizing = .ContentBox
      if style().hasAspectRatio() {
        boxSizing = style().boxSizingForAspectRatio()
      }
      return computeReplacedLogicalHeightRespectingMinMaxHeight(
        logicalHeight: resolveHeightForRatio(
          borderAndPaddingLogicalWidth(), borderAndPaddingLogicalHeight(), usedWidth,
          intrinsicRatio.transposedSize().aspectRatioDouble(), boxSizing))
    }

    // Otherwise, if 'height' has a computed value of 'auto', and the element has an intrinsic height, then that intrinsic height is the used value of 'height'.
    if hasIntrinsicHeight {
      return computeReplacedLogicalHeightRespectingMinMaxHeight(
        logicalHeight: constrainedSize.height)
    }

    // Otherwise, if 'height' has a computed value of 'auto', but none of the conditions above are met, then the used value of 'height' must be set to the height
    // of the largest rectangle that has a 2:1 ratio, has a height not greater than 150px, and has a width not greater than the device width.
    return computeReplacedLogicalHeightRespectingMinMaxHeight(
      logicalHeight: intrinsicLogicalHeight())
  }

  private func replacedContentRect(_ intrinsicSize: LayoutSizeWrapper) -> LayoutRectWrapper {
    let contentRect = contentBoxRect()
    if intrinsicSize.isEmpty() {
      return contentRect
    }

    let objectFit = style().objectFit()

    var finalRect = contentRect
    switch objectFit {
    case .Contain, .ScaleDown, .Cover:
      finalRect.setSize(
        size: finalRect.size().fitToAspectRatio(
          intrinsicSize, objectFit == .Cover ? .AspectRatioFitGrow : .AspectRatioFitShrink))
      if objectFit != .ScaleDown || finalRect.width() <= intrinsicSize.width() {
        break
      }
      fallthrough
    case .None:
      finalRect.setSize(size: intrinsicSize)
    case .Fill:
      break
    }

    let objectPosition = style().objectPosition()

    let xOffset = minimumValueForLength(
      length: objectPosition.x, maximumValue: contentRect.width() - finalRect.width())
    let yOffset = minimumValueForLength(
      length: objectPosition.y, maximumValue: contentRect.height() - finalRect.height())

    finalRect.move(dx: xOffset, dy: yOffset)

    return finalRect
  }

  func replacedContentRect() -> LayoutRectWrapper { return replacedContentRect(intrinsicSize()) }

  func setNeedsLayoutIfNeededAfterIntrinsicSizeChange() -> Bool {
    setPreferredLogicalWidthsDirty(shouldBeDirty: true)

    // If the actual area occupied by the image has changed and it is not constrained by style then a layout is required.
    let imageSizeIsConstrained =
      style().logicalWidth().isSpecified() && style().logicalHeight().isSpecified()
      && !style().logicalMinWidth().isIntrinsic() && !style().logicalMaxWidth().isIntrinsic()
      && !hasAutoHeightOrContainingBlockWithAutoHeight(updatePercentageDescendants: .No)

    // FIXME: We only need to recompute the containing block's preferred size
    // if the containing block's size depends on the image's size (i.e., the container uses shrink-to-fit sizing).
    // There's no easy way to detect that shrink-to-fit is needed, always force a layout.
    let containingBlockNeedsToRecomputePreferredSize =
      style().logicalWidth().isPercentOrCalculated()
      || style().logicalMaxWidth().isPercentOrCalculated()
      || style().logicalMinWidth().isPercentOrCalculated()

    // Flex and grid layout use the intrinsic image width/height even if width/height are specified.
    if !imageSizeIsConstrained || containingBlockNeedsToRecomputePreferredSize || isFlexItem()
      || isGridItem()
    {
      setNeedsLayout()
      return true
    }

    return false
  }

  override final func intrinsicSize() -> LayoutSizeWrapper {
    let size = m_intrinsicSize.deepCopy()
    if isHorizontalWritingMode()
      ? shouldApplySizeOrInlineSizeContainment() : shouldApplySizeContainment()
    {
      size.setWidth(width: explicitIntrinsicInnerWidth() ?? LayoutUnit(value: 0))
    }
    if isHorizontalWritingMode()
      ? shouldApplySizeContainment() : shouldApplySizeOrInlineSizeContainment()
    {
      size.setHeight(height: explicitIntrinsicInnerHeight() ?? LayoutUnit(value: 0))
    }
    return size
  }

  func isContentLikelyVisibleInViewport() -> Bool {
    if !isVisibleIgnoringGeometry() {
      return false
    }

    let frameView = view().frameView()
    let visibleRect = LayoutRectWrapper(
      rect: frameView.windowToContents(windowRect: frameView.windowClipRect()))
    let contentRect = computeRectForRepaint(rect: replacedContentRect(), repaintContainer: nil)

    // Content rectangle may be empty because it is intrinsically sized and the content has not loaded yet.
    if contentRect.isEmpty()
      && (style().logicalWidth().isAuto() || style().logicalHeight().isAuto())
    {
      return visibleRect.contains(point: contentRect.location())
    }

    return visibleRect.intersects(other: contentRect)
  }

  override func needsPreferredWidthsRecalculation() -> Bool {
    // If the height is a percentage and the width is auto, then the containingBlocks's height changing can cause this node to change it's preferred width because it maintains aspect ratio.
    return (hasRelativeLogicalHeight() || (isGridItem() && hasStretchedLogicalHeight()))
      && style().logicalWidth().isAuto()
  }

  func computeIntrinsicAspectRatio() -> Float64 {
    let (_, intrinsicRatio) = computeAspectRatioInformationForRenderBox(embeddedContentBox())
    return intrinsicRatio.aspectRatioDouble()
  }

  override func computeIntrinsicRatioInformation() -> (FloatSize, FloatSize) {
    // If there's an embeddedContentBox() of a remote, referenced document available, this code-path should never be used.
    assert(embeddedContentBox() == nil || shouldApplySizeOrInlineSizeContainment())
    let intrinsicSize = FloatSize(
      width: intrinsicLogicalWidth().float(), height: intrinsicLogicalHeight().float())

    var intrinsicRatio = FloatSize()
    if style().hasAspectRatio() {
      intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
      if style().aspectRatioType() == .Ratio || isVideoWithDefaultObjectSize(self) {
        return (intrinsicSize, intrinsicRatio)
      }
    }
    // Figure out if we need to compute an intrinsic ratio.
    if !hasIntrinsicAspectRatio() && !isRenderOrLegacyRenderSVGRoot() {
      return (intrinsicSize, intrinsicRatio)
    }

    // After supporting contain-intrinsic-size, the intrinsicSize of size containment is not always empty.
    if intrinsicSize.isEmpty() || shouldApplySizeContainment() {
      return (intrinsicSize, intrinsicRatio)
    }

    return (intrinsicSize, FloatSize(width: intrinsicSize.width, height: intrinsicSize.height))
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    let repainter = LayoutRepainter(renderer: self)

    let oldContentRect = replacedContentRect()

    setHeight(height: minimumReplacedHeight())

    updateLogicalWidth()
    updateLogicalHeight()

    clearOverflow()
    addVisualEffectOverflow()
    updateLayerTransform()
    invalidateBackgroundObscurationStatus()

    repainter.repaintAfterLayout()
    clearNeedsLayout()

    if replacedContentRect() != oldContentRect {
      setPreferredLogicalWidthsDirty(shouldBeDirty: true)
    }
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    maxLogicalWidth = intrinsicLogicalWidth()
    minLogicalWidth = maxLogicalWidth
  }

  private func isSelected() -> Bool {
    return isHighlighted(selectionState(), view().selection())
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    let previousUsedZoom = oldStyle != nil ? oldStyle!.usedZoom() : RenderStyleWrapper.initialZoom()
    if previousUsedZoom != style().usedZoom() {
      intrinsicSizeChanged()
    }
  }

  func intrinsicSizeChanged() {
    let scaledWidth = Int32(Float32(cDefaultWidth) * style().usedZoom())
    let scaledHeight = Int32(Float32(cDefaultHeight) * style().usedZoom())
    m_intrinsicSize = LayoutSizeWrapper(size: IntSize(width: scaledWidth, height: scaledHeight))
    setNeedsLayoutAndPrefWidthsRecalc()
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !shouldPaint(&paintInfo, paintOffset) {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    if paintInfo.phase == .EventRegion {
      if visibleToHitTesting() {
        let borderRect = LayoutRectWrapper(location: adjustedPaintOffset, size: size())
        let borderShape = BorderShape.shapeForBorderRect(style: style(), borderRect: borderRect)
        paintInfo.eventRegionContext()!.unite(
          roundedRect: borderShape.deprecatedPixelSnappedRoundedRect(
            deviceScaleFactor: document().deviceScaleFactor()), renderer: self, style: style())
      }
      return
    }

    if paintInfo.phase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(
        renderBox: self, paintOffset: adjustedPaintOffset)
      return
    }

    // TODO(asuhan): add layout needed forbidden scope

    let savedGraphicsContext = GraphicsContextStateSaver(
      context: paintInfo.context(), saveAndRestore: false)
    if let element = element(), let parentContainer = element.parentOrShadowHostElement(),
      let markers = document().markersIfExists()
    {
      if contentContainsReplacedElement(
        markers.markersFor(node: parentContainer, .DraggedContent)[...], element)
      {
        savedGraphicsContext.save()
        paintInfo.context().setAlpha(alpha: 0.25)
      }
      if contentContainsReplacedElement(
        markers.markersFor(node: parentContainer, .TransparentContent)[...], element)
      {
        savedGraphicsContext.save()
        paintInfo.context().setAlpha(alpha: 0)
      }
    }

    if hasVisibleBoxDecorations() && paintInfo.phase == .Foreground {
      paintBoxDecorations(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
    }

    if paintInfo.phase == .Mask {
      paintMask(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
      return
    }

    let paintRect = LayoutRectWrapper(location: adjustedPaintOffset, size: size())
    if paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline {
      if style().outlineWidth() != 0 {
        paintOutline(paintInfo: paintInfo, paintRect: paintRect)
      }
      return
    }

    if paintInfo.phase != .Foreground && paintInfo.phase != .Selection {
      return
    }

    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    var highlightColor = ColorWrapper()
    if !document().printing() && !paintInfo.paintBehavior.contains(.ExcludeSelection) {
      highlightColor = calculateHighlightColor()
    }

    var drawSelectionTint = shouldDrawSelectionTint()
    if paintInfo.phase == .Selection {
      if selectionState() == .None {
        return
      }
      drawSelectionTint = false
    }

    var completelyClippedOut = false
    if style().hasBorderRadius() {
      completelyClippedOut = size().isEmpty()
      if !completelyClippedOut {
        // Push a clip if we have a border radius, since we want to round the foreground content that gets painted.
        paintInfo.context().save()
        clipToContentBoxShape(
          paintInfo.context(), adjustedPaintOffset, document().deviceScaleFactor())
      }
    }

    if !completelyClippedOut {
      if !isSkippedContentRoot() {
        paintReplaced(&paintInfo, adjustedPaintOffset)
      }

      if style().hasBorderRadius() {
        paintInfo.context().restore()
      }
    }

    // The selection tint never gets clipped by border-radius rounding, since we want it to run right up to the edges of
    // surrounding content.
    if drawSelectionTint {
      var selectionPaintingRect = localSelectionRect()
      selectionPaintingRect.moveBy(offset: adjustedPaintOffset)
      paintInfo.context().fillRect(
        rect: FloatRectWrapper(r: snappedIntRect(rect: selectionPaintingRect)),
        color: selectionBackgroundColor())
    }

    if highlightColor.isVisible() {
      var selectionPaintingRect = localSelectionRect(false)
      selectionPaintingRect.moveBy(offset: adjustedPaintOffset)
      paintInfo.context().fillRect(
        rect: FloatRectWrapper(r: snappedIntRect(rect: selectionPaintingRect)),
        color: highlightColor)
    }
  }

  private func shouldPaint(_ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper)
    -> Bool
  {
    if (paintInfo.paintBehavior.contains(.ExcludeSelection)) && isSelected() {
      return false
    }

    if paintInfo.paintBehavior.contains(.ExcludeReplacedContent) {
      return false
    }

    if paintInfo.phase != .Foreground
      && paintInfo.phase != .Outline
      && paintInfo.phase != .SelfOutline
      && paintInfo.phase != .Selection
      && paintInfo.phase != .Mask
      && paintInfo.phase != .EventRegion
      && paintInfo.phase != .Accessibility
    {
      return false
    }

    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return false
    }

    // if we're invisible or haven't received a layout yet, then just bail.
    if style().usedVisibility() != .Visible {
      return false
    }

    var paintRect = visualOverflowRect()
    paintRect.moveBy(offset: paintOffset + location())

    // Early exit if the element touches the edges.
    let top = paintRect.y()
    let bottom = paintRect.maxY()

    let localRepaintRect = paintInfo.rect
    if paintRect.x() >= localRepaintRect.maxX() || paintRect.maxX() <= localRepaintRect.x() {
      return false
    }

    if top >= localRepaintRect.maxY() || bottom <= localRepaintRect.y() {
      return false
    }

    return true
  }

  // This is in local coordinates, but it's a physical rect (so the top left corner is physical top left).
  private func localSelectionRect(_ checkWhetherSelected: Bool = true) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeConstrainedLogicalWidth(_ shouldComputePreferred: ShouldComputePreferred)
    -> LayoutUnit
  {
    if shouldComputePreferred == .ComputePreferred {
      return computeReplacedLogicalWidthRespectingMinMaxWidth(
        LayoutUnit(value: UInt64(0)), .ComputePreferred)
    }

    // The aforementioned 'constraint equation' used for block-level, non-replaced
    // elements in normal flow:
    // 'margin-left' + 'border-left-width' + 'padding-left' + 'width' +
    // 'padding-right' + 'border-right-width' + 'margin-right' = width of
    // containing block
    // see https://www.w3.org/TR/CSS22/visudet.html#blockwidth
    var logicalWidth = containingBlock()!.availableLogicalWidth()

    // This solves above equation for 'width' (== logicalWidth).
    let marginStart = minimumValueForLength(
      length: style().marginStart(), maximumValue: logicalWidth)
    let marginEnd = minimumValueForLength(length: style().marginEnd(), maximumValue: logicalWidth)

    logicalWidth = max(
      LayoutUnit(value: 0),
      (logicalWidth
        - (marginStart + marginEnd + borderLeft() + borderRight() + paddingLeft() + paddingRight()))
    )
    return computeReplacedLogicalWidthRespectingMinMaxWidth(logicalWidth, shouldComputePreferred)
  }

  func embeddedContentBox() -> RenderBoxWrapper? { return nil }

  override final func computePreferredLogicalWidths() {
    assert(preferredLogicalWidthsDirty())

    // We cannot resolve any percent logical width here as the available logical
    // width may not be set on our containing block.
    if style().logicalWidth().isPercentOrCalculated() {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &minPreferredLogicalWidth, maxLogicalWidth: &maxPreferredLogicalWidth)
    } else {
      maxPreferredLogicalWidth = computeReplacedLogicalWidth(
        shouldComputePreferred: .ComputePreferred)
      minPreferredLogicalWidth = maxPreferredLogicalWidth
    }

    let ignoreMinMaxSizes = shouldIgnoreLogicalMinMaxWidthSizes()
    let styleToUse = style()
    if styleToUse.logicalWidth().isPercentOrCalculated()
      || styleToUse.logicalMaxWidth().isPercentOrCalculated()
    {
      minPreferredLogicalWidth = LayoutUnit(value: 0)
    }

    if !ignoreMinMaxSizes && styleToUse.logicalMinWidth().isFixed()
      && styleToUse.logicalMinWidth().value() > 0
    {
      maxPreferredLogicalWidth = max(
        maxPreferredLogicalWidth,
        adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: styleToUse.logicalMinWidth()))
      minPreferredLogicalWidth = max(
        minPreferredLogicalWidth,
        adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: styleToUse.logicalMinWidth()))
    }

    if !ignoreMinMaxSizes && styleToUse.logicalMaxWidth().isFixed() {
      maxPreferredLogicalWidth = min(
        maxPreferredLogicalWidth,
        adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: styleToUse.logicalMaxWidth()))
      minPreferredLogicalWidth = min(
        minPreferredLogicalWidth,
        adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: styleToUse.logicalMaxWidth()))
    }

    let borderAndPadding = borderAndPaddingLogicalWidth()
    minPreferredLogicalWidth += borderAndPadding
    maxPreferredLogicalWidth += borderAndPadding

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  func paintReplaced(_ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper) {}

  private func computeAspectRatioInformationForRenderBox(_ contentRenderer: RenderBoxWrapper?) -> (
    FloatSize, FloatSize
  ) {
    var intrinsicSize = FloatSize()
    var intrinsicRatio = FloatSize()
    if shouldApplySizeOrInlineSizeContainment() {
      (intrinsicSize, intrinsicRatio) = computeIntrinsicRatioInformation()
    } else if contentRenderer != nil {
      (intrinsicSize, intrinsicRatio) = contentRenderer!.computeIntrinsicRatioInformation()

      if style().aspectRatioType() == .Ratio
        || (style().aspectRatioType() == .AutoAndRatio && intrinsicRatio.isEmpty())
      {
        intrinsicRatio = FloatSize.narrowPrecision(
          width: style().aspectRatioWidth(), height: style().aspectRatioHeight())
      }

      // Handle zoom & vertical writing modes here, as the embedded document doesn't know about them.
      intrinsicSize.scale(style().usedZoom())

      if let image = self as? RenderImageWrapper {
        intrinsicSize.scale(image.imageDevicePixelRatio())
      }

      // Update our intrinsic size to match what the content renderer has computed, so that when we
      // constrain the size below, the correct intrinsic size will be obtained for comparison against
      // min and max widths.
      if !intrinsicRatio.isEmpty() && !intrinsicSize.isZero() {
        m_intrinsicSize = LayoutSizeWrapper(size: intrinsicSize)
      }

      if !isHorizontalWritingMode() {
        if !intrinsicRatio.isEmpty() {
          intrinsicRatio = intrinsicRatio.transposedSize()
        }
        intrinsicSize = intrinsicSize.transposedSize()
      }
    } else {
      (intrinsicSize, intrinsicRatio) = computeIntrinsicRatioInformation()
      if !intrinsicRatio.isEmpty() && !intrinsicSize.isZero() {
        m_intrinsicSize = LayoutSizeWrapper(
          size: isHorizontalWritingMode() ? intrinsicSize : intrinsicSize.transposedSize())
      }
    }
    return (intrinsicSize, intrinsicRatio)
  }

  private func computeIntrinsicSizesConstrainedByTransferredMinMaxSizes(
    _ contentRenderer: RenderBoxWrapper?
  ) -> (FloatSize, FloatSize) {
    var (intrinsicSize, intrinsicRatio) = computeAspectRatioInformationForRenderBox(contentRenderer)

    // Now constrain the intrinsic size along each axis according to minimum and maximum width/heights along the
    // opposite axis. So for example a maximum width that shrinks our width will result in the height we compute here
    // having to shrink in order to preserve the aspect ratio. Because we compute these values independently along
    // each axis, the final returned size may in fact not preserve the aspect ratio.
    if !intrinsicRatio.isZero() && style().logicalWidth().isAuto()
      && style().logicalHeight().isAuto()
    {
      let removeBorderAndPaddingFromMinMaxSizes = {
        (minSize: inout LayoutUnit, maxSize: inout LayoutUnit, borderAndPadding: LayoutUnit) in
        minSize = max(LayoutUnit(value: UInt64(0)), minSize - borderAndPadding)
        maxSize = max(LayoutUnit(value: UInt64(0)), maxSize - borderAndPadding)
      }

      var (minLogicalWidth, maxLogicalWidth) = computeMinMaxLogicalWidthFromAspectRatio()
      removeBorderAndPaddingFromMinMaxSizes(
        &minLogicalWidth, &maxLogicalWidth, borderAndPaddingLogicalWidth())

      var (minLogicalHeight, maxLogicalHeight) = computeMinMaxLogicalHeightFromAspectRatio()
      removeBorderAndPaddingFromMinMaxSizes(
        &minLogicalHeight, &maxLogicalHeight, borderAndPaddingLogicalHeight())

      intrinsicSize.setWidth(
        width: clamp(
          val: LayoutUnit(value: intrinsicSize.width), lo: minLogicalWidth, hi: maxLogicalWidth
        ).float()
      )
      intrinsicSize.setHeight(
        height: clamp(
          val: LayoutUnit(value: intrinsicSize.height), lo: minLogicalHeight, hi: maxLogicalHeight
        ).float())
    }
    return (intrinsicSize, intrinsicRatio)
  }

  private func shouldDrawSelectionTint() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateHighlightColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isHighlighted(_ state: HighlightState, _ rangeData: RenderHighlight) -> Bool {
    if state == .None {
      return false
    }
    if state == .Inside {
      return true
    }

    let selectionStart = rangeData.startOffset()
    let selectionEnd = rangeData.endOffset()
    if state == .Start {
      return selectionStart == 0
    }

    let end = element()!.nodeHasChildNodes() ? element()!.countChildNodes() : 1
    if state == .End {
      return selectionEnd == end
    }
    if state == .Both {
      return selectionStart == 0 && selectionEnd == end
    }
    fatalError("Not reached")
  }

  private func hasReplacedLogicalHeight() -> Bool {
    if style().logicalHeight().isAuto() {
      return false
    }

    if style().logicalHeight().isFixed() {
      return true
    }

    if style().logicalHeight().isPercentOrCalculated() {
      return !hasAutoHeightOrContainingBlockWithAutoHeight()
    }

    if style().logicalHeight().isIntrinsic() {
      return !style().hasAspectRatio()
    }

    return false
  }

  private var m_intrinsicSize = LayoutSizeWrapper()
}
