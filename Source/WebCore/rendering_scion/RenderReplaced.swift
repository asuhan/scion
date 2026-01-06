/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004, 2005, 2006, 2007, 2009 Apple Inc. All rights reserved.
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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func resolveHeightForRatio(
  _ borderAndPaddingLogicalWidthborderAndPaddingLogicalWidth: LayoutUnit,
  _ borderAndPaddingLogicalHeight: LayoutUnit, _ logicalWidth: LayoutUnit, _ aspectRatio: Float64,
  _ boxSizing: BoxSizing
) -> LayoutUnit {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

  func replacedContentRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func intrinsicSize() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func needsPreferredWidthsRecalculation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeIntrinsicAspectRatio() -> Float64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func embeddedContentBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeIntrinsicSizesConstrainedByTransferredMinMaxSizes(
    _ contentRenderer: RenderBoxWrapper?
  ) -> (FloatSize, FloatSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasReplacedLogicalHeight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
