/**
 * Copyright (C) 2024 Apple Inc. All rights reserved.
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

func use(_ x: TextBoxTrimmer) {}

private func textBoxTrim(_ textBoxTrimRoot: RenderBlockFlowWrapper) -> TextBoxTrim {
  if let multiColumnFlow = textBoxTrimRoot as? RenderMultiColumnFlowWrapper {
    return multiColumnFlow.multiColumnBlockFlow()!.style().textBoxTrim()
  }
  return textBoxTrimRoot.style().textBoxTrim()
}

class TextBoxTrimmer {
  init(blockContainer: RenderBlockFlowWrapper) {
    m_blockContainer = blockContainer
    if m_blockContainer.view().frameView().layoutContext().layoutState() != nil {
      adjustTextBoxTrimStatusBeforeLayout(nil)
    }
  }

  init(blockContainer: RenderBlockFlowWrapper, lastFormattedLineRoot: RenderBlockFlowWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  deinit {
    if m_blockContainer.view().frameView().layoutContext().layoutState() != nil {
      adjustTextBoxTrimStatusAfterLayout()
    }
  }

  static func lastInlineFormattingContextRootForTrimEnd(blockContainer: RenderBlockFlowWrapper)
    -> RenderBlockFlowWrapper?
  {
    let textBoxTrimValue = textBoxTrim(blockContainer)
    let hasTextBoxTrimEnd = textBoxTrimValue == .TrimEnd || textBoxTrimValue == .TrimBoth
    if !hasTextBoxTrimEnd {
      return nil
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func adjustTextBoxTrimStatusBeforeLayout(_ lastFormattedLineRoot: RenderBlockFlowWrapper?)
  {
    let textBoxTrimValue = textBoxTrim(m_blockContainer)
    if textBoxTrimValue == .None {
      return handlePropagatedTextBoxTrimBeforeLayout()
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func handlePropagatedTextBoxTrimBeforeLayout() {
    let layoutState = m_blockContainer.view().frameView().layoutContext().layoutState()!
    // This is when the block container does not have text-box-trim set.
    // 1. trimming does not get propagated into formatting contexts e.g inside inline-block.
    // 2. border and padding (start) prevent trim start.
    if m_blockContainer.createsNewFormattingContext() {
      m_previousTextBoxTrimStatus = layoutState.textBoxTrim()
      m_shouldRestoreTextBoxTrimStatus = true
      // Run layout on this subtree with no text-box-trim.
      layoutState.setTextBoxTrim(nil)
      return
    }

    if layoutState.hasTextBoxTrimStart() && m_blockContainer.borderAndPaddingStart().bool() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private func adjustTextBoxTrimStatusAfterLayout() {
    let layoutState = m_blockContainer.view().frameView().layoutContext().layoutState()!
    if m_shouldRestoreTextBoxTrimStatus {
      return layoutState.setTextBoxTrim(m_previousTextBoxTrimStatus)
    }

    if layoutState.hasTextBoxTrimStart() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private let m_blockContainer: RenderBlockFlowWrapper
  private var m_previousTextBoxTrimStatus: RenderLayoutStateWrapper.TextBoxTrim? = nil
  private var m_shouldRestoreTextBoxTrimStatus = false
}
