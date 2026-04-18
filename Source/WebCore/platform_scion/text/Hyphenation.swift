/*
 * Copyright (C) 2010-2023 Apple Inc. All rights reserved.
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

internal func enoughWidthForHyphenation(availableWidth: Float32, fontSize: Float32) -> Bool {
  // If the maximum width available for the prefix before the hyphen is small, then it is very unlikely
  // that an hyphenation opportunity exists, so do not bother to look for it.
  return availableWidth > fontSize * 5 / 4
}

internal func canHyphenate(localeIdentifier: AtomStringWrapper) -> Bool {
  if localeIdentifier.p == nil {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  return wk_interop.Hyphenation_canHyphenate(localeIdentifier.p)
}

internal func lastHyphenLocation(
  string: StringWrapperView, beforeIndex: UInt64, localeIdentifier: AtomStringWrapper
) -> UInt64 {
  if localeIdentifier.p == nil {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  return wk_interop.Hyphenation_lastHyphenLocation(string.p, beforeIndex, localeIdentifier.p)
}
