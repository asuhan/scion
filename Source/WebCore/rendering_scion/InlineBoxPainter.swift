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

      let containingBlockPaintsContinuationOutline =
        inlineFlow.continuation() != nil || inlineFlow.isContinuation()
      if containingBlockPaintsContinuationOutline {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
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
