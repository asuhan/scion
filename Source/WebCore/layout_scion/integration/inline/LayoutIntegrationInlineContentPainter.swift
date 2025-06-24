/*
 * Copyright (C) 2022 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

extension LayoutIntegration {
  static func flippedContentOffsetIfNeeded(
    root: RenderBlockFlowWrapper, childRenderer: RenderBoxWrapper, contentOffset: LayoutPointWrapper
  ) -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct InlineContentPainter {
    init(
      paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
      inlineBoxWithLayer: RenderInlineWrapper?, inlineContent: InlineContent, boxTree: BoxTree
    ) {
      self.paintInfo = paintInfo
      self.paintOffset = paintOffset
      self.inlineBoxWithLayer = inlineBoxWithLayer
      self.inlineContent = inlineContent
      self.boxTree = boxTree
      self.damageRect = paintInfo.rect
      self.damageRect.moveBy(offset: -self.paintOffset)
    }

    func paint() {
      let layerPaintScope = LayerPaintScope(
        boxTree: boxTree, inlineBoxWithLayer: inlineBoxWithLayer)
      var lastBoxLineIndex: UInt64? = nil

      for box in inlineContent.boxesForRect(rect: damageRect) {
        if shouldPaintBoxForPhase() && layerPaintScope.includes(box: box) {
          paintLineEndingEllipsisIfApplicable(
            currentLineIndex: UInt64(box.lineIndex), lastBoxLineIndex: lastBoxLineIndex)
          paintDisplayBox(box: box)
        }
        lastBoxLineIndex = UInt64(box.lineIndex)
      }
      paintLineEndingEllipsisIfApplicable(currentLineIndex: nil, lastBoxLineIndex: lastBoxLineIndex)

      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func paintLineEndingEllipsisIfApplicable(
      currentLineIndex: UInt64?, lastBoxLineIndex: UInt64?
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func shouldPaintBoxForPhase() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func paintDisplayBox(box: InlineDisplay.Box) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let paintInfo: PaintInfoWrapper
    private let paintOffset: LayoutPointWrapper
    private var damageRect: LayoutRectWrapper
    private let inlineBoxWithLayer: RenderInlineWrapper?
    private let inlineContent: InlineContent
    private let boxTree: BoxTree
  }

  struct LayerPaintScope {
    init(boxTree: BoxTree, inlineBoxWithLayer: RenderInlineWrapper?) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func includes(box: InlineDisplay.Box) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }
}
