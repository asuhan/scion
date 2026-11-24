/*
 * Copyright (C) 2006, 2007 Apple Inc.  All rights reserved.
 * Copyright (C) 2009 Dominik Röttsches <dominik.roettsches@access-company.com>
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

// The word boundary helpers of platform/text/TextBoundaries.h stay in C++, on ICU.

func requiresContextForWordBoundary(_ character: UInt32) -> Bool {
  return wk_interop.TextBoundaries_requiresContextForWordBoundary(character)
}

func endOfFirstWordBoundaryContext(_ text: StringWrapperView) -> UInt32 {
  return wk_interop.TextBoundaries_endOfFirstWordBoundaryContext(text.p)
}

func startOfLastWordBoundaryContext(_ text: StringWrapperView) -> UInt32 {
  return wk_interop.TextBoundaries_startOfLastWordBoundaryContext(text.p)
}

func findWordBoundary(
  _ text: StringWrapperView, _ position: Int32, _ start: inout Int32?, _ end: inout Int32?
) {
  var startValue: Int32 = 0
  var endValue: Int32 = 0
  wk_interop.TextBoundaries_findWordBoundary(text.p, position, &startValue, &endValue)
  start = startValue
  end = endValue
}

func findEndWordBoundary(_ text: StringWrapperView, _ position: Int32, _ end: inout Int32?) {
  var endValue: Int32 = 0
  wk_interop.TextBoundaries_findEndWordBoundary(text.p, position, &endValue)
  end = endValue
}
