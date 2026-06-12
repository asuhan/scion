/*
 * Copyright (C) 2019-2021 Apple Inc. All rights reserved.
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

  class TextBox: Box {
    override init(_ path: PathVariant) { super.init(path) }

    func start() -> UInt32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.start()
      case .legacy(let path):
        return path.start()
      }
    }

    func end() -> UInt32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.end()
      case .legacy(let path):
        return path.end()
      }
    }

    func length() -> UInt32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.length()
      case .legacy(let path):
        return path.length()
      }
    }

    func selectableRange() -> TextBoxSelectableRange {
      switch m_pathVariant {
      case .modern(let path):
        return path.selectableRange()
      case .legacy(let path):
        return path.selectableRange()
      }
    }

    func fontCascade() -> FontCascadeWrapper {
      if let renderer = renderer() as? RenderCombineTextWrapper, renderer.isCombined() {
        return renderer.textCombineFont()
      }

      return style().fontCascade()
    }

    func textRun(mode: TextRunMode = .Painting) -> TextRunWrapper {
      switch m_pathVariant {
      case .modern(let path):
        return path.textRun()
      case .legacy(let path):
        return path.textRun()
      }
    }

    override func renderer() -> RenderTextWrapper { return super.renderer() as! RenderTextWrapper }

    // FIXME: Remove. For intermediate porting steps only.
    func legacyInlineBoxForTextBox() -> LegacyInlineTextBox? {
      return super.legacyInlineBox() as! LegacyInlineTextBox?
    }
  }

  class TextBoxIterator: LeafBoxIterator {
    override init() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    init(pathVariant: BoxPath) {
      if let modernPath = pathVariant as? BoxModernPath {
        super.init(.modern(modernPath), isInline: false)
      } else {
        super.init(.legacy(pathVariant as! BoxLegacyPath), isInline: false)
      }
    }

    @discardableResult
    static prefix func ++ (this: TextBoxIterator) -> TextBoxIterator {
      return this.traverseNextTextBox()
    }

    override func get() -> TextBox { return m_box as! TextBox }

    // This traverses to the next text box generated for the same RenderText/Layout::InlineTextBox.
    @discardableResult
    func traverseNextTextBox() -> TextBoxIterator {
      switch m_box.m_pathVariant {
      case .modern(let path):
        path.traverseNextTextBox()
      case .legacy(let path):
        path.traverseNextTextBox()
      }
      return self
    }
  }

  static func firstTextBoxFor(_ text: RenderTextWrapper) -> TextBoxIterator {
    if let lineLayout = LayoutIntegration.LineLayout.containing(renderer: text) {
      return lineLayout.textBoxesFor(text)
    }

    return TextBoxIterator(pathVariant: BoxLegacyPath(text.firstLegacyTextBox()))
  }

  static func textBoxFor(_ content: LayoutIntegration.InlineContent, _ boxIndex: UInt64)
    -> TextBoxIterator
  {
    assert(content.displayContent.boxes[Int(boxIndex)].isTextOrSoftLineBreak())
    return TextBoxIterator(pathVariant: BoxModernPath(inlineContent: content, startIndex: boxIndex))
  }
}
