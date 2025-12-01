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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isHorizontal() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

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

    func textRun(mode: InlineIterator.TextRunMode) -> TextRunWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func textRun() -> TextRunWrapper {
      return self.textRun(mode: .Painting)
    }

    func renderer() -> RenderObjectWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func formattingContextRoot() -> RenderBlockFlowWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func style() -> RenderStyleWrapper {
      return box().style()
    }

    func direction() -> TextDirection {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isFirstLine() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func box() -> InlineDisplay.Box {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func deepCopy() -> BoxPath {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    let inlineContent: LayoutIntegration.InlineContent
    private let boxIndex: UInt64
  }

}
