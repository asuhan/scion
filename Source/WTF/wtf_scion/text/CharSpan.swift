/*
 * Copyright (C) 2014-2019 Apple Inc. All rights reserved.
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

import wk_interop

class CharSpanWrapper<CharacterType> {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  deinit {
    switch MemoryLayout<CharacterType>.size {
    case 1:
      wk_interop.CharSpanWrapper8_destroy(p)
    case 2:
      wk_interop.CharSpanWrapper16_destroy(p)
    default:
      fatalError("Not reached")
    }
  }

  func size() -> UInt64 {
    switch MemoryLayout<CharacterType>.size {
    case 1:
      return wk_interop.span8_size(p)
    case 2:
      return wk_interop.span16_size(p)
    default:
      fatalError("Not reached")
    }
  }

  subscript(index: UInt64) -> UChar {
    switch MemoryLayout<CharacterType>.size {
    case 1:
      return wk_interop.span8_subscript(p, index)
    case 2:
      return wk_interop.span16_subscript(p, index)
    default:
      fatalError("Not reached")
    }
  }

  func subspan(_ offset: UInt32, _ count: UInt32) -> CharSpanWrapper<CharacterType> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func data() -> UnsafePointer<CharacterType> {
    switch MemoryLayout<CharacterType>.size {
    case 1:
      return wk_interop.span8_data(p).assumingMemoryBound(to: CharacterType.self)
    case 2:
      return wk_interop.span16_data(p).assumingMemoryBound(to: CharacterType.self)
    default:
      fatalError("Not reached")
    }
  }

  var p: UnsafeRawPointer
}
