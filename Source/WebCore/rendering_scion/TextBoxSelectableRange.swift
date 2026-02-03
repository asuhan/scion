/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

private func clamp(value: UInt32, low: UInt32, high: UInt32) -> UInt32 {
  return min(max(value, low), high)
}

struct TextBoxSelectableRange {
  let start: UInt32
  let length: UInt32
  let additionalLengthAtEnd: UInt32 = 0
  let isLineBreak = false
  // FIXME: Consider holding onto the truncation position instead. See webkit.org/b/164999
  let truncation: UInt32? = nil

  func clamp(offset: UInt32) -> UInt32 {
    var clampedOffset = layout_scion.clamp(value: offset, low: start, high: start + length) - start

    // FIXME: For some reason we allow the caret move to (invisible) fully truncated text. The zero test is to keep that behavior.
    if let truncation = truncation {
      return min(clampedOffset, truncation)
    }

    if clampedOffset == length {
      clampedOffset += additionalLengthAtEnd
    }

    return clampedOffset
  }

  func clamp(startOffset: UInt32, endOffset: UInt32) -> (UInt32, UInt32) {
    return (clamp(offset: startOffset), clamp(offset: endOffset))
  }
}
