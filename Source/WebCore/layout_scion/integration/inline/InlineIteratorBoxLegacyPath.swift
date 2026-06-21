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

  enum TextRunMode {
    case Painting
    case Editing
  }

  class BoxLegacyPath: BoxPath {
    init(_ inlineBox: LegacyInlineBox?) { m_inlineBox = inlineBox }

    func isText() -> Bool { return m_inlineBox!.isInlineTextBox() }

    func isRootInlineBox() -> Bool { return m_inlineBox!.isRootInlineBox() }

    func visualRectIgnoringBlockDirection() -> FloatRectWrapper { return m_inlineBox!.frameRect() }

    func isHorizontal() -> Bool { return m_inlineBox!.isHorizontal() }

    func isLineBreak() -> Bool { return m_inlineBox!.isLineBreak() }

    func bidiLevel() -> UInt8 { return m_inlineBox!.bidiLevel() }

    func hasHyphen() -> Bool { return false }

    func originalText() -> StringWrapperView {
      return StringWrapperView(s: inlineTextBox().renderer().text()).substring(
        start: inlineTextBox().start(), length: inlineTextBox().len())
    }

    func start() -> UInt32 { return inlineTextBox().start() }

    func end() -> UInt32 { return inlineTextBox().end() }

    func length() -> UInt32 { return inlineTextBox().len() }

    func selectableRange() -> TextBoxSelectableRange { return inlineTextBox().selectableRange() }

    func textRun() -> TextRunWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func renderer() -> RenderObjectWrapper { return m_inlineBox!.renderer }

    func formattingContextRoot() -> RenderBlockFlowWrapper {
      return m_inlineBox!.root().blockFlow()
    }

    func style() -> RenderStyleWrapper { return m_inlineBox!.lineStyle() }

    func traverseNextTextBox() { m_inlineBox = inlineTextBox().nextTextBox() }

    func traverseNextInlineBox() { m_inlineBox = inlineFlowBox().nextLineBox() }

    func traversePreviousInlineBox() { m_inlineBox = inlineFlowBox().prevLineBox() }

    func direction() -> TextDirection { return bidiLevel() % 2 != 0 ? .RTL : .LTR }

    func isFirstLine() -> Bool { return rootInlineBox().prevRootBox() == nil }

    func deepCopy() -> BoxPath { return BoxLegacyPath(m_inlineBox) }

    func atEnd() -> Bool { return m_inlineBox == nil }

    func legacyInlineBox() -> LegacyInlineBox? { return m_inlineBox }

    func rootInlineBox() -> LegacyRootInlineBox { return m_inlineBox!.root() }

    private func inlineTextBox() -> LegacyInlineTextBox {
      return m_inlineBox! as! LegacyInlineTextBox
    }

    private func inlineFlowBox() -> LegacyInlineFlowBox {
      return m_inlineBox as! LegacyInlineFlowBox
    }

    private var m_inlineBox: LegacyInlineBox?
  }

}
