/*
 * Copyright (C) 2009-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

class StringBuilderWrapper {
  init() {
    self.p = wk_interop.StringBuilder_new()
  }

  deinit { wk_interop.StringBuilder_destroy(p) }

  func append(character: UChar) {
    wk_interop.StringBuilder_append_UChar(self.p, character)
  }

  func append(string: AtomStringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func append(string: StringWrapper) {
    wk_interop.StringBuilder_append_String(self.p, string.p)
  }

  func append(string: StringWrapperView) {
    wk_interop.StringBuilder_append_StringView(self.p, string.p)
  }

  // FIXME: Unclear why toString returns String and toStringPreserveCapacity returns const String&. Make them consistent.
  func toString(owner: Bool = true) -> StringWrapper {
    return StringWrapper(p: wk_interop.StringBuilder_toString(p), owner: owner)
  }

  func isEmpty() -> Bool {
    return wk_interop.StringBuilder_isEmpty(self.p)
  }

  func length() -> UInt32 {
    return wk_interop.StringBuilder_length(self.p)
  }

  func view() -> StringWrapperView {
    return StringWrapperView(p: wk_interop.StringBuilder_view(self.p))
  }

  var p: UnsafeMutableRawPointer
}
