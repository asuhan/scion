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

func use(_ x: LineClampUpdater) {}

class LineClampUpdater {
  init(blockContainer: RenderBlockFlowWrapper) {
    m_blockContainer = blockContainer
    guard let layoutState = m_blockContainer.view().frameView().layoutContext().layoutState() else {
      return
    }

    m_previousLineClamp = layoutState.lineClamp()
    if blockContainer.isFieldset() {
      layoutState.setLineClamp(nil)

      m_skippedLegacyLineClampToRestore = layoutState.legacyLineClamp()
      layoutState.setLegacyLineClamp(legacyLineClamp: nil)
      return
    }

    let maximumLinesForBlockContainer = m_blockContainer.style().maxLines()
    if maximumLinesForBlockContainer != 0 {
      // New, top level line clamp.
      layoutState.setLineClamp(
        RenderLayoutStateWrapper.LineClamp(
          maximumLines: maximumLinesForBlockContainer,
          shouldDiscardOverflow: m_blockContainer.style().overflowContinue() == .Discard))
      return
    }

    if m_previousLineClamp != nil {
      // Propagated line clamp.
      if blockContainer.establishesIndependentFormattingContext() {
        // Contents of descendants that establish independent formatting contexts are skipped over while counting line boxes.
        layoutState.setLineClamp(nil)
        return
      }
      let effectiveShouldDiscard =
        m_previousLineClamp!.shouldDiscardOverflow
        || m_blockContainer.style().overflowContinue() == .Discard
      layoutState.setLineClamp(
        RenderLayoutStateWrapper.LineClamp(
          maximumLines: m_previousLineClamp!.maximumLines,
          shouldDiscardOverflow: effectiveShouldDiscard))
      return
    }
  }

  deinit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_blockContainer: RenderBlockFlowWrapper
  private var m_previousLineClamp: RenderLayoutStateWrapper.LineClamp?
  private var m_skippedLegacyLineClampToRestore: RenderLayoutStateWrapper.LegacyLineClamp?
}
