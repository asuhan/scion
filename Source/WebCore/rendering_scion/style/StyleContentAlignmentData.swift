/*
 * Copyright (C) 2015 Igalia S.L. All rights reserved.
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

class StyleContentAlignmentData {
  func isNormal() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isStartward(leftRightAxisDirection: TextDirection? = nil, isFlexReverse: Bool = false)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // leftRightAxisDirection is only needed for justify-content (invalid for align-content).
  // Pass std::nullopt if neither the inline axis nor the physical left-right axis matches the justify-content axis (e.g. in flexbox).
  func isCentered() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var position: ContentPosition = .Normal
  var distribution: ContentDistribution = .Default
  let overflow: OverflowAlignment = .Default
}
