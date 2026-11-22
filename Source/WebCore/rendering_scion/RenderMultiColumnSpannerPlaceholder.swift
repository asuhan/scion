/*
 * Copyright (c) 2014, Opera Software ASA. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Opera Software ASA nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

final class RenderMultiColumnSpannerPlaceholderWrapper: RenderBoxWrapper {
  init(
    fragmentedFlow: RenderMultiColumnFlowWrapper, spanner: RenderBoxWrapper,
    style: RenderStyleWrapper
  ) {
    m_spanner = spanner
    m_fragmentedFlow = fragmentedFlow
    super.init(.MultiColumnSpannerPlaceholder, fragmentedFlow.document(), style, .IsBoxModelObject)
    assert(isRenderMultiColumnSpannerPlaceholder())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  static func createAnonymous(
    fragmentedFlow: RenderMultiColumnFlowWrapper, spanner: RenderBoxWrapper,
    parentStyle: RenderStyleWrapper
  ) -> RenderMultiColumnSpannerPlaceholderWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func spanner() -> RenderBoxWrapper? {
    if !isNativeImpl() {
      guard let spanner = wk_interop.RenderMultiColumnSpannerPlaceholder_spanner(id()) else {
        return nil
      }
      return createRenderObjectWrapperOrNative(spanner) as! RenderBoxWrapper?
    }
    return m_spanner
  }

  func fragmentedFlow() -> RenderMultiColumnFlowWrapper? {
    assert(isNativeImpl())
    return m_fragmentedFlow
  }

  override func canHaveChildren() -> Bool {
    assert(isNativeImpl())
    return false
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
  }

  func setWk(_ wk: UnsafeMutableRawPointer) { self.wk = wk }

  override func getWk() -> UnsafeMutableRawPointer { return wk! }

  private var m_spanner: RenderBoxWrapper? = nil
  private var m_fragmentedFlow: RenderMultiColumnFlowWrapper? = nil
  private var wk: UnsafeMutableRawPointer? = nil
}
