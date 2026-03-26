/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

private func calcScrollbarThicknessUsing(
  _ sizeType: RenderBoxWrapper.SizeType, _ length: LengthWrapper
) -> Int32 {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class RenderScrollbarPartWrapper: RenderBlockWrapper {
  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    setLocation(p: LayoutPointWrapper())  // We don't worry about positioning ourselves. We're just determining our minimum width/height.
    if scrollbar!.orientation() == .Horizontal {
      layoutHorizontalPart()
    } else {
      layoutVerticalPart()
    }

    clearNeedsLayout()
  }

  func paintIntoRect(
    graphicsContext: GraphicsContextWrapper, paintOffset: LayoutPointWrapper,
    rect: LayoutRectWrapper
  ) {
    // Make sure our dimensions match the rect.
    setLocation(p: rect.location() - toLayoutSize(point: paintOffset))
    setWidth(width: rect.width())
    setHeight(height: rect.height())

    if graphicsContext.paintingDisabled() || style().opacity() == 0 {
      return
    }

    // We don't use RenderLayers for scrollbar parts, so we need to handle opacity here.
    // Opacity for ScrollbarBGPart is handled by RenderScrollbarTheme::willPaintScrollbar().
    let needsTransparencyLayer = part != .ScrollbarBGPart && style().opacity() < 1
    if needsTransparencyLayer {
      graphicsContext.save()
      graphicsContext.clip(rect: rect.FloatRect())
      graphicsContext.beginTransparencyLayer(opacity: style().opacity())
    }

    // Now do the paint.
    var paintInfo = PaintInfoWrapper(
      newContext: graphicsContext, newRect: LayoutRectWrapper(rect: snappedIntRect(rect: rect)),
      newPhase: .BlockBackground,
      newPaintBehavior: .Normal)
    paint(paintInfo: &paintInfo, paintOffset: paintOffset)
    paintInfo.phase = .ChildBlockBackgrounds
    paint(paintInfo: &paintInfo, paintOffset: paintOffset)
    paintInfo.phase = .Float
    paint(paintInfo: &paintInfo, paintOffset: paintOffset)
    paintInfo.phase = .Foreground
    paint(paintInfo: &paintInfo, paintOffset: paintOffset)
    paintInfo.phase = .Outline
    paint(paintInfo: &paintInfo, paintOffset: paintOffset)

    if needsTransparencyLayer {
      graphicsContext.endTransparencyLayer()
      graphicsContext.restore()
    }
  }

  override func marginBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    setInline(false)
    clearPositionedState()
    setFloating(false)
    setHasNonVisibleOverflow(false)
    if oldStyle != nil && scrollbar != nil && part != .NoPart && diff >= .Repaint {
      scrollbar!.theme().invalidatePart(scrollbar!, part)
    }
  }

  private func layoutHorizontalPart() {
    if part == .ScrollbarBGPart {
      setWidth(width: scrollbar!.width())
      computeScrollbarHeight()
    } else {
      computeScrollbarWidth()
      setHeight(height: scrollbar!.height())
    }
  }

  private func layoutVerticalPart() {
    if part == .ScrollbarBGPart {
      computeScrollbarWidth()
      setHeight(height: scrollbar!.height())
    } else {
      setWidth(width: scrollbar!.width())
      computeScrollbarHeight()
    }
  }

  private func computeScrollbarWidth() {
    if scrollbar!.owningRenderer() == nil {
      return
    }
    let width = calcScrollbarThicknessUsing(.MainOrPreferredSize, style().width())
    let minWidth = calcScrollbarThicknessUsing(.MinSize, style().minWidth())
    let maxWidth =
      style().maxWidth().isUndefined()
      ? width : calcScrollbarThicknessUsing(.MaxSize, style().maxWidth())
    setWidth(width: max(minWidth, min(maxWidth, width)))

    // Buttons and track pieces can all have margins along the axis of the scrollbar.
    marginBox.setLeft(
      minimumValueForLength(length: style().marginLeft(), maximumValue: LayoutUnit()))
    marginBox.setRight(
      minimumValueForLength(length: style().marginRight(), maximumValue: LayoutUnit()))
  }

  private func computeScrollbarHeight() {
    if scrollbar!.owningRenderer() == nil {
      return
    }
    let height = calcScrollbarThicknessUsing(.MainOrPreferredSize, style().height())
    let minHeight = calcScrollbarThicknessUsing(.MinSize, style().minHeight())
    let maxHeight =
      style().maxHeight().isUndefined()
      ? height : calcScrollbarThicknessUsing(.MaxSize, style().maxHeight())
    setHeight(height: max(minHeight, min(maxHeight, height)))

    // Buttons and track pieces can all have margins along the axis of the scrollbar.
    marginBox.setTop(
      minimumValueForLength(length: style().marginTop(), maximumValue: LayoutUnit()))
    marginBox.setBottom(
      minimumValueForLength(length: style().marginBottom(), maximumValue: LayoutUnit()))
  }

  private var scrollbar: RenderScrollbar? = nil
  private let part: ScrollbarPart = .NoPart
}
