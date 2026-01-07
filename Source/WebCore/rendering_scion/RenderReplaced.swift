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

  override func intrinsicSize() -> LayoutSizeWrapper {
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

  override func needsPreferredWidthsRecalculation() -> Bool {
    // If the height is a percentage and the width is auto, then the containingBlocks's height changing can cause this node to change it's preferred width because it maintains aspect ratio.
    return (hasRelativeLogicalHeight() || (isGridItem() && hasStretchedLogicalHeight()))
      && style().logicalWidth().isAuto()
  }

  func computeIntrinsicAspectRatio() -> Float64 {
    let (_, intrinsicRatio) = computeAspectRatioInformationForRenderBox(embeddedContentBox())
    return intrinsicRatio.aspectRatioDouble()
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

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    let previousUsedZoom = oldStyle != nil ? oldStyle!.usedZoom() : RenderStyleWrapper.initialZoom()
    if previousUsedZoom != style().usedZoom() {
      intrinsicSizeChanged()
    }
  }

  func intrinsicSizeChanged() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func embeddedContentBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeAspectRatioInformationForRenderBox(_ contentRenderer: RenderBoxWrapper?) -> (
    FloatSize, FloatSize
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private let m_intrinsicSize = LayoutSizeWrapper()
}
