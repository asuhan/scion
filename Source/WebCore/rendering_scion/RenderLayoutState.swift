/*
 * Copyright (C) 2007, 2013 Apple Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

class RenderLayoutStateWrapper {
  struct TextBoxTrim {
    let trimFirstFormattedLine: Bool
    let propagatedTextBoxEdge: TextEdge
  }

  struct LineClamp {
    let maximumLines: UInt64
    let shouldDiscardOverflow: Bool
  }

  struct LegacyLineClamp {
    let maximumLineCount: UInt64
    let currentLineCount: UInt64
  }

  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func isPaginated() -> Bool {
    return wk_interop.RenderLayoutState_isPaginated(p)
  }

  // The page logical offset is the object's offset from the top of the page in the page progression
  // direction (so an x-offset in vertical text and a y-offset for horizontal text).
  func pageLogicalOffset(child: RenderBoxWrapper, childLogicalOffset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lineGrid() -> RenderBlockFlowWrapper? {
    if let raw = wk_interop.RenderLayoutState_lineGrid(p) {
      return RenderBlockFlowWrapper(p: raw)
    }
    return nil
  }

  func layoutOffset() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageOffset() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func renderer() -> RenderElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lineClamp() -> LineClamp? {
    let raw = wk_interop.RenderLayoutState_lineClamp(p)
    if !raw.isValid {
      return nil
    }
    return LineClamp(
      maximumLines: raw.maximumLines, shouldDiscardOverflow: raw.shouldDiscardOverflow)
  }

  func legacyLineClamp() -> LegacyLineClamp? {
    let raw = wk_interop.RenderLayoutState_legacyLineClamp(p)
    if !raw.isValid {
      return nil
    }
    return LegacyLineClamp(
      maximumLineCount: raw.maximumLineCount, currentLineCount: raw.currentLineCount)
  }

  func textBoxTrim() -> TextBoxTrim? {
    let raw = wk_interop.RenderLayoutState_textBoxTrim(p)
    if !raw.isValid {
      return nil
    }
    let propagatedTextBoxEdge = TextEdge(
      over: TextEdgeType(rawValue: raw.propagatedTextBoxEdge.over)!,
      under: TextEdgeType(rawValue: raw.propagatedTextBoxEdge.under)!
    )
    return TextBoxTrim(
      trimFirstFormattedLine: raw.trimFirstFormattedLine,
      propagatedTextBoxEdge: propagatedTextBoxEdge)
  }

  func hasTextBoxTrimStart() -> Bool {
    return wk_interop.RenderLayoutState_hasTextBoxTrimStart(p)
  }

  func hasTextBoxTrimEnd(candidate: RenderBlockFlowWrapper) -> Bool {
    return wk_interop.RenderLayoutState_hasTextBoxTrimEnd(p, candidate.p)
  }

  private var p: UnsafeRawPointer
}

// Stack-based class to assist with LayoutState push/pop
struct LayoutStateMaintainer: ~Copyable {
  init(
    root: RenderBoxWrapper, offset: LayoutSizeWrapper, disablePaintOffsetCache: Bool,
    pageHeight: LayoutUnit = LayoutUnit(value: UInt64(0)), pageHeightChanged: Bool = false
  ) {
    context = root.view().frameView().layoutContext()
    paintOffsetCacheIsDisabled = disablePaintOffsetCache
    didPushLayoutState = context.pushLayoutState(
      renderer: root, offset: offset, pageHeight: pageHeight, pageHeightChanged: pageHeightChanged)
    if didPushLayoutState && paintOffsetCacheIsDisabled {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  deinit {
    if !didPushLayoutState {
      return
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let context: LocalFrameViewLayoutContextWrapper
  private var paintOffsetCacheIsDisabled = false
  private var didPushLayoutState = false
}
