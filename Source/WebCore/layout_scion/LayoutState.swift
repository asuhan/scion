/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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

func CPtrToInt(_ p: UnsafeRawPointer?) -> UInt {
  return UInt(bitPattern: p)
}

struct LayoutStateWrapper {
  init(p: UnsafeMutableRawPointer?) {
    self.p = p
  }

  mutating func inlineContentCache(formattingContextRoot: ElementBoxWrapper) -> InlineContentCache {
    assert(formattingContextRoot.establishesInlineFormattingContext())
    let key = CPtrToInt(formattingContextRoot.p)
    if let cache = inlineContentCaches[key] {
      return cache
    }
    let cache = InlineContentCache()
    inlineContentCaches[key] = cache
    return cache
  }

  func formattingStateForFormattingContext(formattingContextRoot: ElementBoxWrapper)
    -> FormattingState
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFormattingState(formattingContextRoot: ElementBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func geometryForBox(layoutBox: BoxWrapper) -> BoxGeometry {
    if p == nil || layoutBox.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    var boxGeometry = BoxGeometry()
    boxGeometry.p = wk_interop.LayoutState_geometryForBox(p, layoutBox.p)
    return boxGeometry
  }

  func ensureGeometryForBox(layoutBox: BoxWrapper) -> BoxGeometry {
    if p == nil || layoutBox.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    var boxGeometry = BoxGeometry()
    boxGeometry.p = wk_interop.LayoutState_ensureGeometryForBox(p, layoutBox.p)
    return boxGeometry
  }

  func hasBoxGeometry(layoutBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inQuirksMode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inStandardsMode() -> Bool {
    if self.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.LayoutState_inStandardsMode(self.p)
  }

  func securityOrigin() -> SecurityOriginWrapper {
    if self.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return SecurityOriginWrapper(p: wk_interop.LayoutState_securityOrigin(self.p))
  }

  func layoutWithFormattingContextForBox(box: ElementBoxWrapper, widthConstraint: LayoutUnit?) {
    // TODO(asuhan): call by pointer
    LayoutIntegration.layoutWithFormattingContextForBox(
      box: box, widthConstraint: widthConstraint, layoutState: self)
  }

  private var inlineContentCaches: [UInt: InlineContentCache] = [:]
  var p: UnsafeMutableRawPointer?
}
