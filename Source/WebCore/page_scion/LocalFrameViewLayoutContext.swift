/*
 * Copyright (C) 2017 Apple Inc. All rights reserved.
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

struct UpdateScrollInfoAfterLayoutTransaction {
  let nestedCount: Int32 = 0
  let blocks = WeakHashSet<RenderBlockWrapper>()
}

class LocalFrameViewLayoutContextWrapper {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func isInLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func subtreeLayoutRoot() -> RenderElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutState() -> RenderLayoutStateWrapper? {
    if let raw = wk_interop.LocalFrameViewLayoutContext_layoutState(p) {
      return RenderLayoutStateWrapper(p: raw)
    }
    return nil
  }

  // layoutDelta is used transiently during layout to store how far an object has moved from its
  // last layout location, in order to repaint correctly.
  // If we're doing a full repaint m_layoutState will be 0, but in that case layoutDelta doesn't matter.
  func layoutDelta() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addLayoutDelta(delta: LayoutSizeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutDeltaMatches(delta: LayoutSizeWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateScrollInfoAfterLayoutTransactionIfExists() -> UpdateScrollInfoAfterLayoutTransaction? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // These functions may only be accessed by LayoutStateMaintainer.
  // Subtree push/pop
  func pushLayoutState(
    renderer: RenderBoxWrapper, offset: LayoutSizeWrapper,
    pageHeight: LayoutUnit = LayoutUnit(value: UInt64(0)), pageHeightChanged: Bool = false
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Suspends the LayoutState optimization. Used under transforms that cannot be represented by
  // LayoutState (common in SVG) and when manipulating the render tree during layout in ways
  // that can trigger repaint of a non-child (e.g. when a list item moves its list marker around).
  // Note that even when disabled, LayoutState is still used to store layoutDelta.
  // These functions may only be accessed by LayoutStateMaintainer or LayoutStateDisabler.
  func disablePaintOffsetCache() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enablePaintOffsetCache() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var p: UnsafeRawPointer
}
