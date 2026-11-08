/*
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

import wk_interop

// The cache itself stays in C++: its key is a tuple of a string, a context and an origin, and
// Swift dictionaries are unreliable with complex keys.
struct TextBreakingPositionCache {
  static let minimumRequiredTextLengthForContentBreakCache = 5
  static let minimumRequiredContentBreaks = 3

  static func singleton() -> TextBreakingPositionCache {
    return TextBreakingPositionCache()
  }

  // C++ derives the TextBreakingPositionContext of the key from the style.
  typealias Key = (StringWrapper, RenderStyleWrapper, SecurityOriginWrapper)
  typealias List = [UInt64]

  func set(key: Key, breakingPositionList: List) {
    breakingPositionList.withUnsafeBufferPointer {
      wk_interop.TextBreakingPositionCache_set(
        key.0.p, key.1.p!, key.2.p, $0.baseAddress, UInt64($0.count))
    }
  }

  func get(key: Key) -> [UInt64]? {
    var positions: UnsafePointer<UInt64>? = nil
    var count: UInt64 = 0
    if !wk_interop.TextBreakingPositionCache_get(key.0.p, key.1.p!, key.2.p, &positions, &count) {
      return nil
    }
    return Array(UnsafeBufferPointer(start: positions, count: Int(count)))
  }
}
