/*
 * Copyright (C) 2012-2023 Apple Inc.  All rights reserved.
 * Copyright (C) 2014 Google Inc.  All rights reserved.
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
 * PROFITS; OR BUSINESS IN..0TERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class RenderMultiColumnFlowWrapper: RenderFragmentedFlowWrapper {
  init(document: Document, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func multiColumnBlockFlow() -> RenderBlockFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func nextColumnSetOrSpannerSiblingOf(child: RenderBoxWrapper?) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func previousColumnSetOrSpannerSiblingOf(child: RenderBoxWrapper?) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func findColumnSpannerPlaceholder(spanner: RenderBoxWrapper?)
    -> RenderMultiColumnSpannerPlaceholderWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The point is physical, and the result is a physical location within the fragment.
  func physicalTranslationFromFlowToFragment(physicalPoint: LayoutPointWrapper)
    -> RenderFragmentContainerWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  typealias SpannerMap = [UInt: RenderMultiColumnSpannerPlaceholderWrapper]

  var spannerMap: SpannerMap {
    get {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    set {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }
}
