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

class RenderImageWrapper: RenderReplacedWrapper {
  private func imageResource() -> RenderImageResource {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cachedImage() -> CachedImageWrapper? {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  // Update the size of the image to be rendered. Object-fit may cause this to be different from the CSS box's content rect.
  private func updateInnerContentRect() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
}
