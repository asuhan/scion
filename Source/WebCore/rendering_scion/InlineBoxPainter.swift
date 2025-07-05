/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class InlineBoxPainter {
  convenience init(
    inlineContent: LayoutIntegration.InlineContent, box: InlineDisplay.Box,
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    self.init(
      inlineBox: InlineIterator.inlineBoxFor(content: inlineContent, box: box).get(),
      paintInfo: paintInfo,
      paintOffset: paintOffset)
  }

  private init(
    inlineBox: InlineIterator.InlineBox, paintInfo: PaintInfoWrapper,
    paintOffset: LayoutPointWrapper
  ) {
    self.inlineBox = inlineBox
    self.paintInfo = paintInfo
    self.paintOffset = paintOffset
    self.renderer = inlineBox.renderer()
    self.isFirstLineBox = inlineBox.lineBox().get().isFirst()
    self.isRootInlineBox = inlineBox.isRootInlineBox()
    self.isHorizontal = inlineBox.isHorizontal()
  }

  func paint() {
    if paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline {
      if renderer.style().usedVisibility() != .Visible || !renderer.hasOutline()
        || isRootInlineBox
      {
        return
      }

      let inlineFlow = renderer as! RenderInlineWrapper
      var containingBlock: RenderBlockWrapper? = nil

      var containingBlockPaintsContinuationOutline =
        inlineFlow.continuation() != nil || inlineFlow.isContinuation()
      if containingBlockPaintsContinuationOutline {
        // FIXME: See https://bugs.webkit.org/show_bug.cgi?id=54690. We currently don't reconnect inline continuations
        // after a child removal. As a result, those merged inlines do not get seperated and hence not get enclosed by
        // anonymous blocks. In this case, it is better to bail out and paint it ourself.
        let enclosingAnonymousBlock = renderer.containingBlock()!
        if !enclosingAnonymousBlock.isAnonymousBlock() {
          containingBlockPaintsContinuationOutline = false
        } else {
          containingBlock = enclosingAnonymousBlock.containingBlock()
          let containingBlockPtr = CPtrToInt(containingBlock?.p)
          var box = renderer
          while CPtrToInt(box.p) != containingBlockPtr {
            if box.hasSelfPaintingLayer() {
              containingBlockPaintsContinuationOutline = false
              break
            }
            box = box.parent()!.enclosingBoxModelObject()
          }
        }
      }

      if containingBlockPaintsContinuationOutline {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      } else if !inlineFlow.isContinuation() {
        paintInfo.outlineObjects!.add(value: inlineFlow)
      }

      return
    }

    if paintInfo.phase == .Mask {
      paintMask()
      return
    }

    if paintInfo.phase == .Accessibility {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    paintDecorations()
  }

  private func paintMask() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintDecorations() {
    if !paintInfo.shouldPaintWithinRoot(renderer: renderer)
      || renderer.style().usedVisibility() != .Visible || paintInfo.phase != .Foreground
    {
      return
    }

    if !isRootInlineBox && !renderer.hasVisibleBoxDecorations() {
      return
    }

    let style = self.style()
    // You can use p::first-line to specify a background. If so, the root inline boxes for
    // a line may actually have to paint a background.
    if isRootInlineBox
      && (!isFirstLineBox || CPtrToInt(style.p) == CPtrToInt(renderer.style().p))
    {
      return
    }

    // Move x/y to our coordinates.
    let localRect = LayoutRectWrapper(r: inlineBox.visualRect())
    let adjustedPaintoffset = paintOffset + localRect.location()
    let paintRect = LayoutRectWrapper(location: adjustedPaintoffset, size: localRect.size())
    // Shadow comes first and is behind the background and border.
    if !BackgroundPainter.boxShadowShouldBeAppliedToBackground(
      renderer: renderer, paintOffset: adjustedPaintoffset, bleedAvoidance: .BackgroundBleedNone,
      inlineBox: InlineIterator.InlineBoxIterator(box: inlineBox))
    {
      paintBoxShadow(shadowStyle: .Normal, paintRect: paintRect)
    }

    var color = style.visitedDependentColor(
      colorProperty: .CSSPropertyBackgroundColor, paintBehavior: paintInfo.paintBehavior)
    let compositeOp = renderer.document().compositeOperatorForBackgroundColor(
      color: color, renderer: renderer)

    color = style.colorByApplyingColorFilter(color: color)

    paintFillLayers(
      color: color, fillLayer: style.backgroundLayers(), rect: paintRect, op: compositeOp)
    paintBoxShadow(shadowStyle: .Inset, paintRect: paintRect)

    // :first-line cannot be used to put borders on a line. Always paint borders with our
    // non-first-line style.
    if isRootInlineBox || !renderer.style().hasVisibleBorderDecoration() {
      return
    }

    let borderImage = renderer.style().borderImage()
    let borderImageSource = borderImage.image()
    let hasBorderImage =
      borderImageSource != nil
      && borderImageSource!.canRender(renderer: renderer, multiplier: style.usedZoom())
    if hasBorderImage && !borderImageSource!.isLoaded(renderer: renderer) {
      return  // Don't paint anything while we wait for the image to load.
    }

    let borderPainter = BorderPainter(renderer: renderer, paintInfo: paintInfo)

    let hasSingleLine = !inlineBox.previousInlineBox().bool() && !inlineBox.nextInlineBox().bool()
    if !hasBorderImage || hasSingleLine {
      let (hasClosedLeftEdge, hasClosedRightEdge) = inlineBox.hasClosedLeftAndRightEdge()
      borderPainter.paintBorder(
        rect: paintRect, style: style, bleedAvoidance: .BackgroundBleedNone,
        includeLogicalLeftEdge: hasClosedLeftEdge, includeLogicalRightEdge: hasClosedRightEdge)
      return
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintFillLayers(
    color: ColorWrapper, fillLayer: FillLayerWrapper, rect: LayoutRectWrapper, op: CompositeOperator
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintBoxShadow(shadowStyle: ShadowStyle, paintRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func style() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let inlineBox: InlineIterator.InlineBox
  private let paintInfo: PaintInfoWrapper
  private let paintOffset: LayoutPointWrapper
  private let renderer: RenderBoxModelObjectWrapper
  private let isFirstLineBox: Bool
  private let isRootInlineBox: Bool
  private let isHorizontal: Bool
}
