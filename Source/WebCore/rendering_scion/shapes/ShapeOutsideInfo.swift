/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

import wk_interop

private func computeLogicalBoxSize(_ renderer: RenderBoxWrapper, _ isHorizontalWritingMode: Bool)
  -> LayoutSizeWrapper
{
  let shapeValue = renderer.style().shapeOutside()!
  let size = isHorizontalWritingMode ? renderer.size() : renderer.size().transposedSize()
  switch shapeValue.effectiveCSSBox() {
  case .MarginBox:
    if isHorizontalWritingMode {
      size.expand(width: renderer.horizontalMarginExtent(), height: renderer.verticalMarginExtent())
    } else {
      size.expand(width: renderer.verticalMarginExtent(), height: renderer.horizontalMarginExtent())
    }
  case .BorderBox:
    break
  case .PaddingBox:
    if isHorizontalWritingMode {
      size.shrink(renderer.horizontalBorderExtent(), renderer.verticalBorderExtent())
    } else {
      size.shrink(renderer.verticalBorderExtent(), renderer.horizontalBorderExtent())
    }
  case .ContentBox:
    if isHorizontalWritingMode {
      size.shrink(
        renderer.horizontalBorderAndPaddingExtent(), renderer.verticalBorderAndPaddingExtent())
    } else {
      size.shrink(
        renderer.verticalBorderAndPaddingExtent(), renderer.horizontalBorderAndPaddingExtent())
    }
  case .FillBox, .StrokeBox, .ViewBox, .BoxMissing:
    fatalError("Not reached")
  }
  return size
}

private func getShapeImageMarginRect(
  _ renderBox: RenderBoxWrapper, _ referenceBoxLogicalSize: LayoutSizeWrapper
) -> LayoutRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func makeShapeForShapeOutside(_ renderer: RenderBoxWrapper) -> ShapeWrapper {
  let style = renderer.style()
  let containingBlock = renderer.containingBlock()!
  let writingMode = containingBlock.style().writingMode()
  let isHorizontalWritingMode = containingBlock.isHorizontalWritingMode()
  let shapeImageThreshold = style.shapeImageThreshold()
  let shapeValue = style.shapeOutside()!

  let boxSize = computeLogicalBoxSize(renderer, isHorizontalWritingMode)

  let shapeMargin = floatValueForLength(
    length: style.shapeMargin(), maximumValue: containingBlock.contentWidth())
  let margin = shapeMargin.isNaN ? 0 : shapeMargin

  switch shapeValue.type {
  case .Shape:
    assert(shapeValue.shape != nil)
    let offset = LayoutPointWrapper(x: logicalLeftOffset(renderer), y: logicalTopOffset(renderer))
    return ShapeWrapper.createShape(shapeValue.shape!, offset, boxSize, writingMode, margin)
  case .Image:
    assert(shapeValue.isImageValid())
    let styleImage = shapeValue.image()!
    let imageSize = renderer.calculateImageIntrinsicDimensions(
      image: styleImage, positioningAreaSize: boxSize, scaleByUsedZoom: .Yes)
    styleImage.setContainerContextForRenderer(
      renderer: renderer, containerSize: imageSize.FloatSize(), containerZoom: style.usedZoom())

    let marginRect = getShapeImageMarginRect(renderer, boxSize)
    let renderImage = renderer as? RenderImageWrapper
    let imageRect =
      renderImage?.replacedContentRect()
      ?? LayoutRectWrapper(location: LayoutPointWrapper(), size: imageSize)

    assert(!styleImage.isPending())
    let image = styleImage.image(renderer: renderer, size: imageSize.FloatSize())
    return ShapeWrapper.createRasterShape(
      image, shapeImageThreshold, imageRect, marginRect, writingMode, margin)
  case .Box:
    var shapeRect = computeRoundedRectForBoxShape(
      box: shapeValue.effectiveCSSBox(), renderer: renderer)
    if !isHorizontalWritingMode {
      shapeRect = shapeRect.transposedRect()
    }
    return ShapeWrapper.createBoxShape(shapeRect, writingMode, margin)
  }
}

private func borderBeforeInWritingMode(_ renderer: RenderBoxWrapper, _ writingMode: WritingMode)
  -> LayoutUnit
{
  let blockFlowDirection = writingModeToBlockFlowDirection(writingMode: writingMode)
  switch blockFlowDirection {
  case .TopToBottom: return renderer.borderTop()
  case .BottomToTop: return renderer.borderBottom()
  case .LeftToRight: return renderer.borderLeft()
  case .RightToLeft: return renderer.borderRight()
  }
}

private func borderAndPaddingBeforeInWritingMode(
  _ renderer: RenderBoxWrapper, _ writingMode: WritingMode
) -> LayoutUnit {
  let blockFlowDirection = writingModeToBlockFlowDirection(writingMode: writingMode)
  switch blockFlowDirection {
  case .TopToBottom: return renderer.borderTop() + renderer.paddingTop()
  case .BottomToTop: return renderer.borderBottom() + renderer.paddingBottom()
  case .LeftToRight: return renderer.borderLeft() + renderer.paddingLeft()
  case .RightToLeft: return renderer.borderRight() + renderer.paddingRight()
  }
}

private func logicalTopOffset(_ renderer: RenderBoxWrapper) -> LayoutUnit {
  switch renderer.style().shapeOutside()!.effectiveCSSBox() {
  case .MarginBox:
    return -renderer.marginBefore(otherStyle: renderer.containingBlock()!.style())
  case .BorderBox:
    return LayoutUnit(value: UInt64(0))
  case .PaddingBox:
    return borderBeforeInWritingMode(renderer, renderer.containingBlock()!.style().writingMode())
  case .ContentBox:
    return borderAndPaddingBeforeInWritingMode(
      renderer, renderer.containingBlock()!.style().writingMode())
  case .FillBox, .StrokeBox, .ViewBox, .BoxMissing:
    fatalError("Not reached")
  }
}

private func borderStartWithStyleForWritingMode(
  _ renderer: RenderBoxWrapper, _ style: RenderStyleWrapper
) -> LayoutUnit {
  if style.isHorizontalWritingMode() {
    if style.isLeftToRightDirection() {
      return renderer.borderLeft()
    }

    return renderer.borderRight()
  }
  if style.isLeftToRightDirection() {
    return renderer.borderTop()
  }

  return renderer.borderBottom()
}

private func borderAndPaddingStartWithStyleForWritingMode(
  _ renderer: RenderBoxWrapper, _ style: RenderStyleWrapper
) -> LayoutUnit {
  if style.isHorizontalWritingMode() {
    if style.isLeftToRightDirection() {
      return renderer.borderLeft() + renderer.paddingLeft()
    }

    return renderer.borderRight() + renderer.paddingRight()
  }
  if style.isLeftToRightDirection() {
    return renderer.borderTop() + renderer.paddingTop()
  }

  return renderer.borderBottom() + renderer.paddingBottom()
}

private func logicalLeftOffset(_ renderer: RenderBoxWrapper) -> LayoutUnit {
  if renderer.isRenderFragmentContainer() {
    return LayoutUnit(value: UInt64(0))
  }

  switch renderer.style().shapeOutside()!.effectiveCSSBox() {
  case .MarginBox:
    return -renderer.marginStart(otherStyle: renderer.containingBlock()!.style())
  case .BorderBox:
    return LayoutUnit(value: UInt64(0))
  case .PaddingBox:
    return borderStartWithStyleForWritingMode(renderer, renderer.containingBlock()!.style())
  case .ContentBox:
    return borderAndPaddingStartWithStyleForWritingMode(
      renderer, renderer.containingBlock()!.style())
  case .FillBox, .StrokeBox, .ViewBox, .BoxMissing:
    fatalError("Not reached")
  }
}

class ShapeOutsideInfoWrapper {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func invalidateForSizeChangeIfNeeded() {
    let newSize = computeLogicalBoxSize(
      renderer!, renderer!.containingBlock()!.isHorizontalWritingMode())
    if cachedShapeLogicalSize == newSize {
      return
    }

    markShapeAsDirty()
    cachedShapeLogicalSize = newSize
  }

  func markShapeAsDirty() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedShape() -> ShapeWrapper {
    if renderer == nil {
      return ShapeWrapper(p: wk_interop.ShapeOutsideInfo_computedShape(p))
    }
    if shape == nil {
      shape = makeShapeForShapeOutside(renderer!)
    }

    return shape!
  }

  private var p: UnsafeRawPointer

  private let renderer: RenderBoxWrapper? = nil

  private var shape: ShapeWrapper? = nil
  private var cachedShapeLogicalSize = LayoutSizeWrapper()
}
