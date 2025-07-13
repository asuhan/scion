/*
 * Copyright (C) 2017-2021 Apple Inc. All rights reserved.
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

class MarkedText {
  // Sorted by paint order
  enum `Type` {
    case Unmarked
    case GrammarError
    case Correction
    case SpellingError
    case TextMatch
    case DictationAlternatives
    case Highlight
    case FragmentHighlight
    case Selection
    case DraggedContent
    case TransparentContent
  }

  enum PaintPhase {
    case Background
    case Foreground
    case Decoration
  }

  init(
    startOffset: UInt32, endOffset: UInt32, type: `Type`, marker: RenderedDocumentMarker? = nil,
    highlightName: AtomStringWrapper = AtomStringWrapper(), priority: Int32 = 0
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init() {}

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func collectForDocumentMarkers(
    renderer: RenderTextWrapper, selectableRange: TextBoxSelectableRange, phase: PaintPhase
  ) -> [MarkedText] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func collectForHighlights(
    renderer: RenderTextWrapper, selectableRange: TextBoxSelectableRange, phase: PaintPhase
  ) -> [MarkedText] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func collectForDraggedAndTransparentContent(
    type: DocumentMarker.`Type`, renderer: RenderTextWrapper,
    selectableRange: TextBoxSelectableRange
  ) -> [MarkedText] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let startOffset: UInt32 = 0
  let endOffset: UInt32 = 0
  let type: `Type` = .Unmarked
}
