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
      self.outlineObjects = ListSet<RenderInlineWrapper, UInt>()
    }

    func paint() {
      var layerPaintScope = LayerPaintScope(
        boxTree: boxTree, inlineBoxWithLayer: inlineBoxWithLayer)
      var lastBoxLineIndex: UInt64? = nil

      for box in inlineContent.boxesForRect(rect: damageRect) {
        if shouldPaintBoxForPhase(box: box) && layerPaintScope.includes(box: box) {
          paintLineEndingEllipsisIfApplicable(
            currentLineIndex: UInt64(box.lineIndex), lastBoxLineIndex: lastBoxLineIndex)
          paintDisplayBox(box: box)
        }
        lastBoxLineIndex = UInt64(box.lineIndex)
      }
      paintLineEndingEllipsisIfApplicable(currentLineIndex: nil, lastBoxLineIndex: lastBoxLineIndex)

      for renderInline in outlineObjects {
        renderInline.paintOutline(paintInfo: paintInfo, paintOffset: paintOffset)
      }
    }

    private func paintLineEndingEllipsisIfApplicable(
      currentLineIndex: UInt64?, lastBoxLineIndex: UInt64?
    ) {
      // Since line ending ellipsis belongs to the line structure but we don't have the concept of painting the line itself
      // let's paint it when we are either at the end of the content or finished painting a line with ellipsis.
      // While normally ellipsis is on the last line, -webkit-line-clamp can make us put ellipsis on any line.
      if inlineBoxWithLayer != nil {
        // Line ending ellipsis is never on the inline box (with layer).
        return
      }
      if let lastBoxLineIndex = lastBoxLineIndex {
        if currentLineIndex == nil || lastBoxLineIndex != currentLineIndex! {
          paintEllipsis(lineIndex: lastBoxLineIndex)
        }
      }
    }

    private func shouldPaintBoxForPhase(box: InlineDisplay.Box) -> Bool {
      switch paintInfo.phase {
      case .ChildOutlines:
        return box.isNonRootInlineBox()
      case .SelfOutline:
        return box.isRootInlineBox()
      case .Outline:
        return box.isInlineBox()
      case .Mask:
        return box.isInlineBox()
      default:
        return true
      }
    }

    private func paintDisplayBox(box: InlineDisplay.Box) {
      if box.isFullyTruncated {
        // Fully truncated boxes are visually empty and they don't show their descendants either (unlike visibility property).
        return
      }

      if box.isLineBreak() {
        return
      }

      if box.isInlineBox() {
        if !box.isVisible() || !boxHasDamage(box: box) {
          return
        }

        var inlineBoxPaintInfo = paintInfo.deepCopy()
        inlineBoxPaintInfo.phase = paintInfo.phase == .ChildOutlines ? .Outline : paintInfo.phase
        inlineBoxPaintInfo.outlineObjects = outlineObjects

        InlineBoxPainter(
          inlineContent: inlineContent, box: box, paintInfo: inlineBoxPaintInfo,
          paintOffset: paintOffset
        ).paint()
        return
      }

      if box.isText() {
        let hasVisibleDamage = box.text().length != 0 && box.isVisible() && boxHasDamage(box: box)
        if !hasVisibleDamage {
          return
        }
        ModernTextBoxPainterWrapper(
          inlineContent: inlineContent, box: box, paintInfo: paintInfo, paintOffset: paintOffset
        ).paint()
        return
      }

      if let renderer = box.layoutBox.rendererForIntegration() as? RenderBoxWrapper {
        if !renderer.isReplacedOrInlineBlock() {
          return
        }
        if paintInfo.shouldPaintWithinRoot(renderer: renderer) {
          // FIXME: Painting should not require a non-const renderer.
          renderer.paintAsInlineBlock(
            paintInfo: paintInfo, childPoint: flippedContentOffsetIfNeeded(childRenderer: renderer))
        }
      }
    }

    private func boxHasDamage(box: InlineDisplay.Box) -> Bool {
      let rect = enclosingLayoutRect(rect: box.inkOverflow)
      root().flipForWritingMode(rect: rect)
      // FIXME: This should test for intersection but horizontal ink overflow is miscomputed in a few cases (like with negative letter-spacing).
      return damageRect.maxY() > rect.y() && damageRect.y() < rect.maxY()
    }

    private func paintEllipsis(lineIndex: UInt64) {
      if (paintInfo.phase != .Foreground && paintInfo.phase != .TextClip)
        || root().style().usedVisibility() != .Visible
      {
        return
      }
      let lineBox = InlineIterator.LineBox(
        path: InlineIterator.LineBoxIteratorModernPath(
          inlineContent: inlineContent, lineIndex: lineIndex)
      )
      EllipsisBoxPainter(
        lineBox: lineBox, paintInfo: paintInfo, paintOffset: paintOffset,
        selectionForegroundColor: root().selectionForegroundColor(),
        selectionBackgroundColor: root().selectionBackgroundColor()
      ).paint()
    }

    private func flippedContentOffsetIfNeeded(childRenderer: RenderBoxWrapper) -> LayoutPointWrapper
    {
      if root().style().isFlippedBlocksWritingMode() {
        return root().flipForWritingModeForChild(child: childRenderer, point: paintOffset)
      }
      return paintOffset
    }

    private func root() -> RenderBlockWrapper { return boxTree.rootRenderer }

    private let paintInfo: PaintInfoWrapper
    private let paintOffset: LayoutPointWrapper
    private var damageRect: LayoutRectWrapper
    private let inlineBoxWithLayer: RenderInlineWrapper?
    private let inlineContent: InlineContent
    private let boxTree: BoxTree
    private let outlineObjects: ListSet<RenderInlineWrapper, UInt>
  }

  struct LayerPaintScope {
    init(boxTree: BoxTree, inlineBoxWithLayer: RenderInlineWrapper?) {
      self.boxTree = boxTree
      if let inlineBoxWithLayer = inlineBoxWithLayer {
        self.inlineBoxWithLayer = inlineBoxWithLayer.layoutBox()
      } else {
        self.inlineBoxWithLayer = nil
      }
    }

    mutating func includes(box: InlineDisplay.Box) -> Bool {
      if CPtrToInt(inlineBoxWithLayer?.p) == CPtrToInt(box.layoutBox.p) {
        return true
      }

      if let inlineBoxWithLayer = inlineBoxWithLayer {
        if !LayerPaintScope.displayBoxIsInsideInlineBox(
          displayBox: box, inlineBox: inlineBoxWithLayer)
        {
          return false
        }
      }
      if let currentExcludedInlineBox = currentExcludedInlineBox {
        if LayerPaintScope.displayBoxIsInsideInlineBox(
          displayBox: box, inlineBox: currentExcludedInlineBox)
        {
          return false
        }
      }

      currentExcludedInlineBox = nil

      if box.isRootInlineBox() || box.isText() || box.isLineBreak() {
        return true
      }

      var hasSelfPaintingLayer = false
      if let renderer = box.layoutBox.rendererForIntegration() as? RenderLayerModelObjectWrapper {
        hasSelfPaintingLayer = renderer.hasSelfPaintingLayer()
      }

      if hasSelfPaintingLayer && box.isNonRootInlineBox() {
        currentExcludedInlineBox = (box.layoutBox as! ElementBoxWrapper)
      }

      return !hasSelfPaintingLayer
    }

    private static func displayBoxIsInsideInlineBox(
      displayBox: InlineDisplay.Box, inlineBox: ElementBoxWrapper
    ) -> Bool {
      assert(inlineBox.isInlineBox())

      if displayBox.isRootInlineBox() {
        return false
      }

      var box = displayBox.layoutBox.parent()
      while box.isInlineBox() {
        if CPtrToInt(box.p) == CPtrToInt(inlineBox.p) {
          return true
        }
        box = box.parent()
      }
      return false
    }

    private let boxTree: BoxTree
    private let inlineBoxWithLayer: ElementBoxWrapper?
    private var currentExcludedInlineBox: ElementBoxWrapper? = nil
  }
}
