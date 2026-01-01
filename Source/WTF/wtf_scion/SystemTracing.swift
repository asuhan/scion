/*
 * Copyright (C) 2016 Apple Inc. All rights reserved.
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

// Trace point codes can be up to 14 bits (0-16383).
// When adding or changing these codes, update Tools/Tracing/SystemTracePoints.plist to match.
enum TracePointCode {
  case CompositingUpdateStart
  case CompositingUpdateEnd
}

private func tracePoint(
  _ code: TracePointCode, _ data1: UInt64 = 0, _ data2: UInt64 = 0, _ data3: UInt64 = 0,
  _ data4: UInt64 = 0
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

struct TraceScope: ~Copyable {
  init(
    _ entryCode: TracePointCode, _ exitCode: TracePointCode, _ data1: UInt64 = 0,
    _ data2: UInt64 = 0, _ data3: UInt64 = 0, _ data4: UInt64 = 0
  ) {
    self.exitCode = exitCode
    tracePoint(entryCode, data1, data2, data3, data4)
  }

  deinit {
    tracePoint(self.exitCode)
  }

  private let exitCode: TracePointCode
}
