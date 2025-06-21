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

  func hasTextBoxTrimStart() -> Bool {
    return wk_interop.RenderLayoutState_hasTextBoxTrimStart(p)
  }

  private var p: UnsafeRawPointer
}
