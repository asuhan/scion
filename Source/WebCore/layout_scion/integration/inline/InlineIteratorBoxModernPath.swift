/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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

extension InlineIterator {

  class BoxModernPath: BoxPath {
    init(inlineContent: LayoutIntegration.InlineContent, startIndex: UInt64) {
      self.inlineContent = inlineContent
      self.boxIndex = startIndex
    }

    func visualRectIgnoringBlockDirection() -> FloatRectWrapper {
      return box().visualRectIgnoringBlockDirection()
    }

    func isText() -> Bool { return box().isTextOrSoftLineBreak() }

    func isHorizontal() -> Bool { return box().isHorizontal() }

    private func bidiLevel() -> UBiDiLevel { return box().bidiLevel }

    private func originalText() -> StringWrapperView { return box().text().originalContent() }

    func start() -> UInt32 { return box().text().start }

    func end() -> UInt32 { return UInt32(box().text().end()) }

    func length() -> UInt32 { return box().text().length }

    func selectableRange() -> TextBoxSelectableRange {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func textRun(mode: InlineIterator.TextRunMode) -> TextRunWrapper {
      let style = box().style()
      let expansion = box().expansion()
      let logicalLeft = { () in
        if style.isLeftToRightDirection() {
          return self.visualRectIgnoringBlockDirection().x()
            - (self.line().lineBoxLeft() + self.line().contentLogicalLeft)
        }
        return self.line().lineBoxRight()
          - (self.visualRectIgnoringBlockDirection().maxX() + self.line().contentLogicalLeft)
      }
      let characterScanForCodePath = isText() && !renderText().canUseSimpleFontCodePath()
      let textRun = TextRunWrapper(
        stringView: mode == .Editing ? originalText() : box().text().renderedContent(),
        xpos: logicalLeft(),
        expansion: expansion.horizontalExpansion, expansionBehavior: expansion.behavior,
        direction: direction(),
        directionalOverride: style.rtlOrdering() == .Visual,
        characterScanForCodePath: characterScanForCodePath)
      textRun.setTabSize(allow: !style.collapseWhiteSpace(), size: style.tabSize())
      return textRun
    }

    func textRun() -> TextRunWrapper {
      return self.textRun(mode: .Painting)
    }

    func renderer() -> RenderObjectWrapper { return box().layoutBox.rendererForIntegration()! }

    func formattingContextRoot() -> RenderBlockFlowWrapper {
      return inlineContent.formattingContextRoot()
    }

    func style() -> RenderStyleWrapper {
      return box().style()
    }

    func direction() -> TextDirection { return bidiLevel().rawValue % 2 != 0 ? .RTL : .LTR }

    func isFirstLine() -> Bool { return box().lineIndex == 0 }

    func box() -> InlineDisplay.Box { return boxes()[Int(boxIndex)] }

    private func boxes() -> ArraySlice<InlineDisplay.Box> {
      return inlineContent.displayContent.boxes[...]
    }

    private func line() -> InlineDisplay.Line { return inlineContent.lineForBox(box()) }

    private func renderText() -> RenderTextWrapper { return renderer() as! RenderTextWrapper }

    func deepCopy() -> BoxPath {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    let inlineContent: LayoutIntegration.InlineContent
    private let boxIndex: UInt64
  }

}
