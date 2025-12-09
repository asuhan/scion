/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2013, 2014 Igalia S.L.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// This class wraps the <track-breadth> which can be either a <percentage>, <length>, min-content, max-content
// or <flex>. This class avoids spreading the knowledge of <flex> throughout the rendering directory by adding
// an new unit to Length.h.
struct GridLength {
  init(length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLength() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFlex() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func length() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPercentage() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isContentSized() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
