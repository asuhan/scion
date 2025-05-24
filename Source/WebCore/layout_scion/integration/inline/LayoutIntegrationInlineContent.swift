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

extension LayoutIntegration {
  class InlineContent {
    init(lineLayout: LayoutIntegration.LineLayout) {
      self.lineLayout = lineLayout
    }

    func hasContent() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func setHasVisualOverflow() { hasVisualOverflow = true }

    func boxesForRect(rect: LayoutRectWrapper) -> any Sequence<InlineDisplay.Box> {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func shrinkToFit() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func formattingContextRoot() -> RenderBlockFlowWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func firstBoxForLayoutBox(layoutBox: BoxWrapper) -> InlineDisplay.Box? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func traverseNonRootInlineBoxes<Function>(layoutBox: BoxWrapper, function: Function) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func releaseCaches() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    var clearGapBeforeFirstLine: Float32 = 0
    var clearGapAfterLastLine: Float32 = 0
    var firstLinePaginationOffset: Float32 = 0

    var isPaginated = false

    var displayContent = InlineDisplay.Content()

    private var lineLayout: LayoutIntegration.LineLayout? = nil
    var hasVisualOverflow = false
  }
}
