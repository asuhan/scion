/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2010-2018 Google Inc. All rights reserved.
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

// Modes for some of the line-related functions.
enum LinePositionMode: UInt8 {
  case PositionOnContainingLine
  case PositionOfInteriorLineBoxes
}

enum LineDirectionMode: UInt8 {
  case HorizontalLine
  case VerticalLine
}

enum BackgroundBleedAvoidance {
  case BackgroundBleedNone
  case BackgroundBleedShrinkBackground
  case BackgroundBleedUseTransparencyLayer
  case BackgroundBleedBackgroundOverBorder
}

enum BaseBackgroundColorUsage {
  case BaseBackgroundColorUse
  case BaseBackgroundColorOnly
  case BaseBackgroundColorSkip
}

private func accumulateInFlowPositionOffsets(child: RenderObjectWrapper) -> LayoutSizeWrapper {
  if !child.isAnonymousBlock() || !child.isInFlowPositioned() {
    return LayoutSizeWrapper()
  }
  var offset = LayoutSizeWrapper()
  var parent: RenderElementWrapper? = (child as! RenderBlockWrapper).inlineContinuation()
  while parent != nil {
    if let parentRenderInline = parent as? RenderInlineWrapper {
      if parent!.isInFlowPositioned() {
        offset += parentRenderInline.offsetForInFlowPosition()
      }
    } else {
      break
    }
    parent = parent!.parent()
  }
  return offset
}

private func isOutOfFlowPositionedWithImplicitHeight(child: RenderBoxModelObjectWrapper) -> Bool {
  return child.isOutOfFlowPositioned() && !child.style().logicalTop().isAuto()
    && !child.style().logicalBottom().isAuto()
}

private func resolveWidthForRatio(height: LayoutUnit, intrinsicRatio: LayoutSizeWrapper)
  -> LayoutUnit
{
  return height * intrinsicRatio.width() / intrinsicRatio.height()
}

private func resolveHeightForRatio(width: LayoutUnit, intrinsicRatio: LayoutSizeWrapper)
  -> LayoutUnit
{
  return width * intrinsicRatio.height() / intrinsicRatio.width()
}

private func resolveAgainstIntrinsicWidthOrHeightAndRatio(
  size: LayoutSizeWrapper, intrinsicRatio: LayoutSizeWrapper, useWidth: LayoutUnit,
  useHeight: LayoutUnit
) -> LayoutSizeWrapper {
  if intrinsicRatio.isEmpty() {
    if useWidth.bool() {
      return LayoutSizeWrapper(width: useWidth, height: size.height())
    }
    return LayoutSizeWrapper(width: size.width(), height: useHeight)
  }

  if useWidth.bool() {
    return LayoutSizeWrapper(
      width: useWidth,
      height: resolveHeightForRatio(width: useWidth, intrinsicRatio: intrinsicRatio))
  }
  return LayoutSizeWrapper(
    width: resolveWidthForRatio(height: useHeight, intrinsicRatio: intrinsicRatio),
    height: useHeight)
}

private func resolveAgainstIntrinsicRatio(
  size: LayoutSizeWrapper, intrinsicRatio: LayoutSizeWrapper
) -> LayoutSizeWrapper {
  // Two possible solutions: (size.width(), solutionHeight) or (solutionWidth, size.height())
  // "... must be assumed to be the largest dimensions..." = easiest answer: the rect with the largest surface area.

  let solutionWidth = resolveWidthForRatio(height: size.height(), intrinsicRatio: intrinsicRatio)
  let solutionHeight = resolveHeightForRatio(width: size.width(), intrinsicRatio: intrinsicRatio)
  if solutionWidth <= size.width() {
    if solutionHeight <= size.height() {
      // If both solutions fit, choose the one covering the larger area.
      let areaOne = solutionWidth * size.height()
      let areaTwo = size.width() * solutionHeight
      if areaOne < areaTwo {
        return LayoutSizeWrapper(width: size.width(), height: solutionHeight)
      }
      return LayoutSizeWrapper(width: solutionWidth, height: size.height())
    }

    // Only the first solution fits.
    return LayoutSizeWrapper(width: solutionWidth, height: size.height())
  }

  // Only the second solution fits, assert that.
  assert(solutionHeight <= size.height())
  return LayoutSizeWrapper(width: size.width(), height: solutionHeight)
}

class RenderBoxModelObjectWrapper: RenderLayerModelObjectWrapper {
  func relativePositionOffset() -> LayoutSizeWrapper {
    // This function has been optimized to avoid calls to containingBlock() in the common case
    // where all values are either auto or fixed.
    let containingBlock = containingBlock()

    let style = style()
    let left = style.left()
    let right = style.right()
    let top = style.top()
    let bottom = style.bottom()

    let offset = accumulateInFlowPositionOffsets(child: self)
    if top.isFixed() && bottom.isAuto() && left.isFixed() && right.isAuto()
      && containingBlock!.style().isLeftToRightDirection()
    {
      offset.expand(width: left.value(), height: top.value())
      return offset
    }

    let zero = LayoutUnit(value: UInt64(0))
    // Objects that shrink to avoid floats normally use available line width when computing containing block width.  However
    // in the case of relative positioning using percentages, we can't do this.  The offset should always be resolved using the
    // available width of the containing block.  Therefore we don't use containingBlockLogicalWidthForContent() here, but instead explicitly
    // call availableWidth on our containing block.
    // However for grid items the containing block is the grid area, so offsets should be resolved against that:
    // https://drafts.csswg.org/css-grid/#grid-item-sizing
    if !left.isAuto() || !right.isAuto() {
      if !left.isAuto() {
        if !right.isAuto() && !containingBlock!.style().isLeftToRightDirection() {
          offset.setWidth(
            width: -valueForLength(
              length: right,
              maximumValue: !right.isFixed()
                ? availableWidth(containingBlock: containingBlock) : zero))
        } else {
          offset.expand(
            width: valueForLength(
              length: left,
              maximumValue: !left.isFixed()
                ? availableWidth(containingBlock: containingBlock) : zero),
            height: zero
          )
        }
      } else if !right.isAuto() {
        offset.expand(
          width: -valueForLength(
            length: right,
            maximumValue: !right.isFixed() ? availableWidth(containingBlock: containingBlock) : zero
          ),
          height: zero
        )
      }
    }

    // If the containing block of a relatively positioned element does not
    // specify a height, a percentage top or bottom offset should be resolved as
    // auto. An exception to this is if the containing block has the WinIE quirk
    // where <html> and <body> assume the size of the viewport. In this case,
    // calculate the percent offset based on this height.
    // See <https://bugs.webkit.org/show_bug.cgi?id=26396>.
    // Another exception is a grid item, as the containing block is the grid area:
    // https://drafts.csswg.org/css-grid/#grid-item-sizing
    if top.isAuto() && bottom.isAuto() {
      return offset
    }

    let overridingContainingBlockContentHeight = overridingContainingBlockContentHeight(
      containingBlock: containingBlock)
    let containingBlockHasDefiniteHeight =
      !containingBlock!.hasAutoHeightOrContainingBlockWithAutoHeight()
      || containingBlock!.stretchesToViewport() || overridingContainingBlockContentHeight != nil
    if !top.isAuto() && (!top.isPercentOrCalculated() || containingBlockHasDefiniteHeight) {
      // FIXME: The computation of the available height is repeated later for "bottom".
      // We could refactor this and move it to some common code for both ifs, however moving it outside of the ifs
      // is not possible as it'd cause performance regressions.
      offset.expand(
        width: zero,
        height: valueForLength(
          length: top,
          maximumValue: !top.isFixed()
            ? RenderBoxModelObjectWrapper.containingBlockContentHeight(
              containingBlock: containingBlock,
              overridingContainingBlockContentHeight: overridingContainingBlockContentHeight) : zero
        ))
    } else if !bottom.isAuto()
      && (!bottom.isPercentOrCalculated() || containingBlockHasDefiniteHeight)
    {
      // FIXME: Check comment above for "top", it applies here too.
      offset.expand(
        width: zero,
        height: -valueForLength(
          length: bottom,
          maximumValue: !bottom.isFixed()
            ? RenderBoxModelObjectWrapper.containingBlockContentHeight(
              containingBlock: containingBlock,
              overridingContainingBlockContentHeight: overridingContainingBlockContentHeight) : zero
        ))
    }
    return offset
  }

  private func availableWidth(containingBlock: RenderBlockWrapper?) -> LayoutUnit {
    if let renderBox = self as? RenderBoxWrapper,
      let overridingContainingBlockContentWidth = renderBox.overridingContainingBlockContentWidth(
        writingMode: containingBlock!.style().writingMode())
    {
      return overridingContainingBlockContentWidth ?? LayoutUnit(value: UInt64(0))
    }
    return containingBlock!.availableWidth()
  }

  private func overridingContainingBlockContentHeight(containingBlock: RenderBlockWrapper?)
    -> LayoutUnit?
  {
    if let renderBox = self as? RenderBoxWrapper,
      let overridingContainingBlockContentHeight = renderBox.overridingContainingBlockContentHeight(
        writingMode: containingBlock!.style().writingMode())
    {
      return overridingContainingBlockContentHeight
    }
    return nil
  }

  private static func containingBlockContentHeight(
    containingBlock: RenderBlockWrapper?, overridingContainingBlockContentHeight: LayoutUnit?
  ) -> LayoutUnit {
    return overridingContainingBlockContentHeight ?? containingBlock!.availableHeight()
  }

  private func constrainingRectForStickyPosition() -> FloatRectWrapper {
    if let enclosingClippingLayer =
      hasLayer() ? layer()!.enclosingOverflowClipLayer(includeSelf: .ExcludeSelf) : nil
    {
      let enclosingClippingBox = enclosingClippingLayer.renderer() as! RenderBoxWrapper
      var clipRect = enclosingClippingBox.overflowClipRect(
        location: LayoutPointWrapper(), fragment: nil)  // FIXME: make this work in regions.
      clipRect.contract(
        size: LayoutSizeWrapper(
          width: enclosingClippingBox.paddingLeft() + enclosingClippingBox.paddingRight(),
          height: enclosingClippingBox.paddingTop() + enclosingClippingBox.paddingBottom()
        ))

      var constrainingRect = enclosingClippingBox.localToContainerQuad(
        localQuad: FloatQuad(inRect: clipRect.FloatRect()), container: view()
      ).boundingBox()

      let scrollableArea = enclosingClippingLayer.scrollableArea()
      let scrollOffset =
        scrollableArea != nil
        ? FloatPoint() + FloatPoint(p: scrollableArea!.scrollOffset()) : FloatPoint()

      let scrollbarOffset =
        Float32(
          (enclosingClippingBox.hasLayer()
            && enclosingClippingBox.shouldPlaceVerticalScrollbarOnLeftForLayerModelObject()
            && scrollableArea != nil)
            ? scrollableArea!.verticalScrollbarWidth(
              relevancy: .IgnoreOverlayScrollbarSize,
              isHorizontalWritingMode: isHorizontalWritingMode()) : 0)

      constrainingRect.setLocation(
        location: FloatPoint(x: scrollOffset.x + scrollbarOffset, y: scrollOffset.y))
      return constrainingRect
    }

    return view().frameView().rectForFixedPositionLayout().FloatRect()
  }

  private func computeStickyPositionConstraints(constrainingRect: FloatRectWrapper)
    -> StickyPositionViewportConstraints
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func stickyPositionOffset() -> LayoutSizeWrapper {
    let constrainingRect = constrainingRectForStickyPosition()
    let constraints = computeStickyPositionConstraints(constrainingRect: constrainingRect)

    // The sticky offset is physical, so we can just return the delta computed in absolute coords (though it may be wrong with transforms).
    return LayoutSizeWrapper(
      size: constraints.computeStickyOffset(constrainingRect: constrainingRect))
  }

  func offsetForInFlowPosition() -> LayoutSizeWrapper {
    if isRelativelyPositioned() {
      return relativePositionOffset()
    }

    if isStickilyPositioned() {
      return stickyPositionOffset()
    }

    return LayoutSizeWrapper()
  }

  func computedCSSPaddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedCSSPaddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // These functions are used during layout. Table cells and the MathML
  // code override them to include some extra intrinsic padding.
  func padding() -> RectEdges<LayoutUnit> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingStart() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_paddingStart(p))
  }

  func paddingEnd() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_paddingEnd(p))
  }

  func borderWidths() -> RectEdges<LayoutUnit> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderStart() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_borderStart(p))
  }

  func borderEnd() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAndPaddingStart() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAndPaddingEnd() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAndPaddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAndPaddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func verticalBorderAndPaddingExtent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func horizontalBorderAndPaddingExtent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAndPaddingLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAndPaddingLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderLogicalLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginStart(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderBoxModelObject_marginStart(p, otherStyle?.p))
  }

  func marginEnd(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func verticalMarginExtent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func horizontalMarginExtent() -> LayoutUnit { return marginLeft() + marginRight() }

  func borderShapeForContentClipping(
    borderBoxRect: LayoutRectWrapper, includeLeftEdge: Bool = true, includeRightEdge: Bool = true
  ) -> BorderShape {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containingBlockLogicalWidthForContent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Overridden by subclasses to determine line height and baseline position.
  func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baselinePosition(
    baselineType: FontBaseline, firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  ) -> LayoutUnit {
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderBoxModelObject_baselinePosition(
        p, baselineType.rawValue, firstLine, direction.rawValue, linePositionMode.rawValue))
  }

  func canHaveBoxInfoInFragment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func continuation() -> RenderBoxModelObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inlineContinuation() -> RenderInlineWrapper? {
    if let raw = wk_interop.RenderBoxModelObject_inlineContinuation(p) {
      return RenderInlineWrapper(p: raw)
    }
    return nil
  }

  func insertIntoContinuationChainAfter(afterRenderer: RenderBoxModelObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeFromContinuationChain() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderObscuresBackgroundEdge(contextScale: FloatSize) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderObscuresBackground() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum UpdatePercentageHeightDescendants {
    case No
    case Yes
  }

  func hasAutoHeightOrContainingBlockWithAutoHeight(
    updatePercentageDescendants: UpdatePercentageHeightDescendants = .Yes
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fixedBackgroundPaintsInLocalCoordinates() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func chooseInterpolationQuality(
    context: GraphicsContextWrapper, image: ImageWrapper, layer: FillLayerWrapper,
    size: LayoutSizeWrapper
  ) -> InterpolationQuality {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func decodingModeForImageDraw(image: ImageWrapper, paintInfo: PaintInfoWrapper) -> DecodingMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMaskForTextFillBox(
    context: GraphicsContextWrapper, paintRect: FloatRectWrapper,
    inlineBox: InlineIterator.InlineBoxIterator, scrolledPaintRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // For RenderBlocks and RenderInlines with m_style->pseudoElementType() == PseudoId::FirstLetter, this tracks their remaining text fragments
  func firstLetterRemainingText() -> RenderTextFragmentWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFirstLetterRemainingText(remainingText: RenderTextFragmentWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum ScaleByUsedZoom {
    case No
    case Yes
  }

  func calculateImageIntrinsicDimensions(
    image: StyleImage, positioningAreaSize: LayoutSizeWrapper, scaleByUsedZoom: ScaleByUsedZoom
  )
    -> LayoutSizeWrapper
  {
    // A generated image without a fixed size, will always return the container size as intrinsic size.
    if !image.imageHasNaturalDimensions() {
      return LayoutSizeWrapper(
        width: positioningAreaSize.width(), height: positioningAreaSize.height())
    }

    var intrinsicWidth = LengthWrapper()
    var intrinsicHeight = LengthWrapper()
    var intrinsicRatio = FloatSize()
    image.computeIntrinsicDimensions(
      renderer: self, intrinsicWidth: &intrinsicWidth, intrinsicHeight: &intrinsicHeight,
      intrinsicRatio: &intrinsicRatio)

    assert(!intrinsicWidth.isPercentOrCalculated())
    assert(!intrinsicHeight.isPercentOrCalculated())

    let resolvedSize = LayoutSizeWrapper(
      width: intrinsicWidth.value(), height: intrinsicHeight.value())
    let minimumSize = LayoutSizeWrapper(
      width: Int32(resolvedSize.width() > 0 ? 1 : 0),
      height: Int32(resolvedSize.height() > 0 ? 1 : 0))

    if scaleByUsedZoom == .Yes {
      resolvedSize.scale(scale: style().usedZoom())
    }
    resolvedSize.clampToMinimumSize(minimumSize: minimumSize)

    if !resolvedSize.isEmpty() {
      return resolvedSize
    }

    // If the image has one of either an intrinsic width or an intrinsic height:
    // * and an intrinsic aspect ratio, then the missing dimension is calculated from the given dimension and the ratio.
    // * and no intrinsic aspect ratio, then the missing dimension is assumed to be the size of the rectangle that
    //   establishes the coordinate system for the 'background-position' property.
    if resolvedSize.width() > 0 || resolvedSize.height() > 0 {
      return resolveAgainstIntrinsicWidthOrHeightAndRatio(
        size: positioningAreaSize, intrinsicRatio: LayoutSizeWrapper(size: intrinsicRatio),
        useWidth: resolvedSize.width(),
        useHeight: resolvedSize.height())
    }

    // If the image has no intrinsic dimensions and has an intrinsic ratio the dimensions must be assumed to be the
    // largest dimensions at that ratio such that neither dimension exceeds the dimensions of the rectangle that
    // establishes the coordinate system for the 'background-position' property.
    if !intrinsicRatio.isEmpty() {
      return resolveAgainstIntrinsicRatio(
        size: positioningAreaSize, intrinsicRatio: LayoutSizeWrapper(size: intrinsicRatio))
    }

    // If the image has no intrinsic ratio either, then the dimensions must be assumed to be the rectangle that
    // establishes the coordinate system for the 'background-position' property.
    return positioningAreaSize
  }

  func containingBlockForAutoHeightDetection(logicalHeight: LengthWrapper) -> RenderBlockWrapper? {
    // For percentage heights: The percentage is calculated with respect to the
    // height of the generated box's containing block. If the height of the
    // containing block is not specified explicitly (i.e., it depends on content
    // height), and this element is not absolutely positioned, the used height is
    // calculated as if 'auto' was specified.
    if !logicalHeight.isPercentOrCalculated() || isOutOfFlowPositioned() {
      return nil
    }

    // Anonymous block boxes are ignored when resolving percentage values that
    // would refer to it: the closest non-anonymous ancestor box is used instead.
    var cb = containingBlock()
    while cb != nil && cb!.isAnonymousForPercentageResolution() && !(cb is RenderViewWrapper) {
      cb = cb!.containingBlock()
    }
    if cb == nil {
      return nil
    }

    // Matching RenderBox::percentageLogicalHeightIsResolvable() by
    // ignoring table cell's attribute value, where it says that table cells
    // violate what the CSS spec says to do with heights. Basically we don't care
    // if the cell specified a height or not.
    if cb!.isRenderTableCell() {
      return nil
    }

    // Match RenderBox::availableLogicalHeightUsing by special casing the layout
    // view. The available height is taken from the frame.
    if cb!.isRenderView() {
      return nil
    }

    if isOutOfFlowPositionedWithImplicitHeight(child: cb!) {
      return nil
    }

    return cb
  }

  class ContinuationChainNode {
    // The HashMap for storing continuation pointers.
    // An inline can be split with blocks occuring in between the inline content.
    // When this occurs we need a pointer to the next object. We can basically be
    // split into a sequence of inlines and blocks. The continuation will either be
    // an anonymous block (that houses other blocks) or it will be an inline flow.
    // <b><i><p>Hello</p></i></b>. In this example the <i> will have a block as
    // its continuation but the <b> will just have an inline as its continuation.
    init(renderer: RenderBoxModelObjectWrapper) { self.renderer = renderer }

    deinit {
      if next != nil {
        assert(previous != nil)
        assert(ObjectIdentifier(next!.previous!) == ObjectIdentifier(self))
        next!.previous = previous
      }
      if previous != nil {
        assert(ObjectIdentifier(previous!.next!) == ObjectIdentifier(self))
        previous!.next = next
      }
    }

    let renderer: RenderBoxModelObjectWrapper?
    var previous: ContinuationChainNode? = nil
    var next: ContinuationChainNode? = nil
  }

  func continuationChainNode() -> ContinuationChainNode? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
