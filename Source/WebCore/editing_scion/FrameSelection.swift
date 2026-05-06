/*
 * Copyright (C) 2004-2020 Apple Inc. All rights reserved.
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

class CaretBaseWrapper {}

final class DragCaretControllerWrapper: CaretBaseWrapper {
  init(_ p: UnsafeRawPointer) { self.p = p }

  func caretRenderer() -> RenderBlockWrapper? {
    if wk_interop.DragCaretController_caretRenderer(p) == nil {
      return nil
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintDragCaret(
    frame: LocalFrameWrapper, p: GraphicsContextWrapper, paintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isContentEditable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let p: UnsafeRawPointer
}

final class FrameSelectionWrapper: CaretBaseWrapper, CaretAnimationClient {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  func selection() -> VisibleSelectionWrapper {
    return VisibleSelectionWrapper(wk_interop.FrameSelection_selection(p))
  }

  enum RevealSelectionAfterUpdate {
    case NotForced
    case Forced
  }

  func setNeedsSelectionUpdate(revealMode: RevealSelectionAfterUpdate = .NotForced) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return the renderer that is responsible for painting the caret (in the selection start node).
  func caretRendererWithoutUpdatingLayout() -> RenderBlockWrapper? {
    guard let raw = wk_interop.FrameSelection_caretRendererWithoutUpdatingLayout(p) else {
      return nil
    }
    return createRenderObjectWrapperOrNative(raw) as! RenderBlockWrapper?
  }

  func isCaret() -> Bool { return wk_interop.FrameSelection_isCaret(p) }

  func paintCaret(context: GraphicsContextWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFocusedAndActive() -> Bool { return wk_interop.FrameSelection_isFocusedAndActive(p) }

  func shouldShowBlockCursor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let p: UnsafeMutableRawPointer
}
