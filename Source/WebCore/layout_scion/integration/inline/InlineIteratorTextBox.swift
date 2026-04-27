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
    func start() -> UInt32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func end() -> UInt32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func length() -> UInt32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func selectableRange() -> TextBoxSelectableRange {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func fontCascade() -> FontCascadeWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func textRun(mode: TextRunMode = .Painting) -> TextRunWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    override func renderer() -> RenderTextWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  class TextBoxIterator: LeafBoxIterator {
    override init() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    init(pathVariant: BoxPath) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    @discardableResult
    static prefix func ++ (this: TextBoxIterator) -> TextBoxIterator {
      return this.traverseNextTextBox()
    }

    override func get() -> TextBox {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    // This traverses to the next text box generated for the same RenderText/Layout::InlineTextBox.
    @discardableResult
    func traverseNextTextBox() -> TextBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  static func firstTextBoxFor(_ text: RenderTextWrapper) -> TextBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

}
