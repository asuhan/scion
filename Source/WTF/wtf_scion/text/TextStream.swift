/*
 * Copyright (C) 2004, 2008 Apple Inc. All rights reserved.
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

precedencegroup TextStreamShiftPrecedence {
  associativity: left
  higherThan: DefaultPrecedence
}

infix operator <<< : TextStreamShiftPrecedence

class TextStream {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  @discardableResult
  static func <<< (_ ts: TextStream, _ s: String) -> TextStream {
    let bytes = s.utf8CString
    bytes.withUnsafeBufferPointer { ptr in
      wk_interop.TextStream_writeChars(ts.p, ptr.baseAddress!)
    }
    return ts
  }

  @discardableResult
  static func <<< (_ ts: TextStream, _ i: Int32) -> TextStream {
    wk_interop.TextStream_writeInt(ts.p, i)
    return ts
  }

  @discardableResult
  static func <<< (_ ts: TextStream, _ string: StringWrapper) -> TextStream {
    wk_interop.TextStream_writeString(ts.p, string.p)
    return ts
  }

  @discardableResult
  static func <<< (_ ts: TextStream, _ string: StringWrapperView) -> TextStream {
    wk_interop.TextStream_writeStringView(ts.p, string.p)
    return ts
  }

  @discardableResult
  func indent() -> TextStream {
    wk_interop.TextStream_indent(p)
    return self
  }

  private let p: UnsafeMutableRawPointer
}
