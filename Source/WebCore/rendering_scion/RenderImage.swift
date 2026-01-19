/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2003-2021 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

enum ImageSizeChangeType {
  case ImageSizeChangeNone
  case ImageSizeChangeForAltText
}

class RenderImageWrapper: RenderReplacedWrapper {
  private func imageResource() -> RenderImageResource {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cachedImage() -> CachedImageWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setImageSizeForAltText(_ newImage: CachedImageWrapper? = nil) -> ImageSizeChangeType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func imageDevicePixelRatio() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func needsPreferredWidthsRecalculation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func embeddedContentBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicRatioInformation() -> (FloatSize, FloatSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func foregroundIsKnownToBeOpaqueInRect(
    _ localRect: LayoutRectWrapper, _ maxDepthToTest: UInt32
  )
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    if needsToSetSizeForAltText {
      if !altText.isEmpty() && setImageSizeForAltText(cachedImage()) == .ImageSizeChangeForAltText {
        repaintOrMarkForLayout(.ImageSizeChangeForAltText)
      }
      needsToSetSizeForAltText = false
    }

    if oldStyle != nil && diff == .Layout {
      if oldStyle!.imageOrientation() != style().imageOrientation() {
        return repaintOrMarkForLayout(.ImageSizeChangeNone)
      }
    }
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)

    if paintInfo.phase == .Outline {
      paintAreaElementFocusRing(&paintInfo, paintOffset)
    }
  }

  override func layout() {
    // Recomputing overflow is required only when child content is present.
    if needsSimplifiedNormalFlowLayoutOnly() && !hasShadowContent() {
      clearNeedsLayout()
      return
    }

    // TODO(asuhan): add stack stats

    let oldSize = contentBoxRect().size()
    super.layout()

    updateInnerContentRect()

    if hasShadowContent() {
      layoutShadowContent(oldSize: oldSize)
    }
  }

  override func intrinsicSizeChanged() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintReplaced(
    _ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func computeBackgroundIsKnownToBeObscured(_ paintOffset: LayoutPointWrapper)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func minimumReplacedHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func repaintOrMarkForLayout(
    _ imageSizeChange: ImageSizeChangeType, _ rect: IntRect? = nil
  ) {
    let newIntrinsicSize = imageResource().intrinsicSize(style().usedZoom())
    let oldIntrinsicSize = intrinsicSize()

    updateIntrinsicSizeIfNeeded(newIntrinsicSize)

    // In the case of generated image content using :before/:after/content, we might not be
    // in the render tree yet. In that case, we just need to update our intrinsic size.
    // layout() will be called after we are inserted in the tree which will take care of
    // what we are doing here.
    if containingBlock() == nil {
      return
    }

    let imageSourceHasChangedSize =
      oldIntrinsicSize != newIntrinsicSize || imageSizeChange != .ImageSizeChangeNone

    if imageSourceHasChangedSize && setNeedsLayoutIfNeededAfterIntrinsicSizeChange() {
      return
    }

    if everHadLayout() && !selfNeedsLayout() {
      // The inner content rectangle is calculated during layout, but may need an update now
      // (unless the box has already been scheduled for layout). In order to calculate it, we
      // may need values from the containing block, though, so make sure that we're not too
      // early. It may be that layout hasn't even taken place once yet.

      // FIXME: we should not have to trigger another call to setContainerContextForRenderer()
      // from here, since it's already being done during layout.
      updateInnerContentRect()
    }

    if parent() != nil {
      var repaintRect = contentBoxRect()
      if rect != nil {
        // The image changed rect is in source image coordinates (pre-zooming),
        // so map from the bounds of the image to the contentsBox.
        repaintRect.intersect(
          other: LayoutRectWrapper(
            rect: enclosingIntRect(
              rect: mapRect(
                FloatRectWrapper(r: rect!),
                srcRect: FloatRectWrapper(
                  location: FloatPoint(), size: imageResource().imageSize(1.0).FloatSize()),
                destRect: repaintRect.FloatRect()))))
      }
      repaintRectangle(repaintRect: repaintRect)
    }

    // Tell any potential compositing layers that the image needs updating.
    contentChanged(.ImageChanged)
  }

  private func updateIntrinsicSizeIfNeeded(_ newSize: LayoutSizeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Update the size of the image to be rendered. Object-fit may cause this to be different from the CSS box's content rect.
  private func updateInnerContentRect() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintAreaElementFocusRing(
    _ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    if document().printing() || !frame().selection().isFocusedAndActive() {
      return
    }

    if paintInfo.context().paintingDisabled() && !paintInfo.context().performingPaintInvalidation()
    {
      return
    }

    guard let areaElement = document().focusedElement() as? HTMLAreaElementWrapper else { return }
    if CPtrToInt(areaElement.imageElement()?.p) != CPtrToInt(element()?.p) {
      return
    }

    guard let areaElementStyle = areaElement.computedStyle() else { return }

    let outlineWidth = areaElementStyle.outlineWidth()
    if outlineWidth == 0 {
      return
    }

    // Even if the theme handles focus ring drawing for entire elements, it won't do it for
    // an area within an image, so we don't call RenderTheme::supportsFocusRing here.
    let path = areaElement.computePathForFocusRing(size())
    if path.isEmpty() {
      return
    }

    let zoomTransform = AffineTransform()
    zoomTransform.scale(Float64(style().usedZoom()))
    path.transform(zoomTransform)

    var adjustedOffset = paintOffset
    adjustedOffset.moveBy(offset: location())
    path.translate(toFloatSize(a: adjustedOffset.FloatPoint()))

    paintInfo.context().drawFocusRing(
      path, outlineWidth,
      areaElementStyle.visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyOutlineColor)
    )
  }

  private func layoutShadowContent(oldSize: LayoutSizeWrapper) {
    for renderBox: RenderBoxWrapper in childrenOfType(parent: self) {
      var childNeedsLayout = renderBox.needsLayout()
      // If the region chain has changed we also need to relayout the children to update the region box info.
      // FIXME: We can do better once we compute region box info for RenderReplaced, not only for RenderBlock.
      if let fragmentedFlow = enclosingFragmentedFlow(), !childNeedsLayout {
        if fragmentedFlow.pageLogicalSizeChanged {
          childNeedsLayout = true
        }
      }

      let newSize = contentBoxRect().size()
      if newSize == oldSize && !childNeedsLayout {
        continue
      }

      // When calling layout() on a child node, a parent must either push a LayoutStateMaintainer, or
      // instantiate LayoutStateDisabler. Since using a LayoutStateMaintainer is slightly more efficient,
      // and this method might be called many times per second during video playback, use a LayoutStateMaintainer:
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())
      renderBox.setLocation(
        p: LayoutPointWrapper(x: borderLeft(), y: borderTop())
          + LayoutSizeWrapper(width: paddingLeft(), height: paddingTop()))
      renderBox.mutableStyle().setHeight(
        length: LengthWrapper(value: newSize.height(), type: .Fixed))
      renderBox.mutableStyle().setWidth(length: LengthWrapper(value: newSize.width(), type: .Fixed))
      renderBox.setNeedsLayout(markParents: .MarkOnlyThis)
      renderBox.layout()
    }

    clearChildNeedsLayout()
  }

  private func hasShadowContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeReplacedLogicalWidth(
    shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  )
    -> LayoutUnit
  {
    if shouldCollapseToEmpty() {
      return LayoutUnit()
    }
    return super.computeReplacedLogicalWidth(shouldComputePreferred: shouldComputePreferred)
  }

  override func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    if shouldCollapseToEmpty() {
      return LayoutUnit()
    }
    return super.computeReplacedLogicalHeight(estimatedUsedWidth: estimatedUsedWidth)
  }

  private func shouldCollapseToEmpty() -> Bool {
    let imageRepresentsNothing = { [self] () in
      if !element()!.hasAltAttr() {
        return false
      }
      return imageResource().errorOccurred() && altText.isEmpty()
    }
    if element() == nil {
      // Images with no associated elements do not fall under the category of unwanted content.
      return false
    }
    if !isInline() {
      return false
    }
    if !imageRepresentsNothing() {
      return false
    }
    return document().inNoQuirksMode()
      || (style().logicalWidth().isAuto() && style().logicalHeight().isAuto())
  }

  // Text to display as long as the image isn't available.
  private let altText = StringWrapper()
  private var needsToSetSizeForAltText = false
}
