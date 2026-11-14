/*
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2015-2018 Google Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov.
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
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

// SearchBuffer stays in C++, in editing/TextIterator.cpp; this owns one.
final class SearchBuffer {
  init(target: StringWrapper, _ arg1: FindOption) {
    p = wk_interop.SearchBuffer_create(target.p, UInt32(arg1.rawValue))
  }

  func append(_ arg0: StringWrapperView) -> UInt64 {
    return wk_interop.SearchBuffer_append(p, arg0.p)
  }

  func needsMoreContext() -> Bool {
    return wk_interop.SearchBuffer_needsMoreContext(p)
  }

  func prependContext(_ arg0: StringWrapperView) {
    wk_interop.SearchBuffer_prependContext(p, arg0.p)
  }

  func reachedBreak() {
    wk_interop.SearchBuffer_reachedBreak(p)
  }

  func search(startOffset: inout UInt64) -> UInt64 {
    return wk_interop.SearchBuffer_search(p, &startOffset)
  }

  func atBreak() -> Bool {
    return wk_interop.SearchBuffer_atBreak(p)
  }

  deinit {
    wk_interop.SearchBuffer_destroy(p)
  }

  let p: UnsafeMutableRawPointer
}
