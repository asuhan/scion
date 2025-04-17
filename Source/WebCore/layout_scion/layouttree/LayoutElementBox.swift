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

class ElementBoxWrapper: BoxWrapper {
  // FIXME: This is currently needed for style updates.
  func firstChild() -> BoxWrapper? {
    if p == nil {
      return nil
    }
    let unwrapped = wk_interop.ElementBox_firstChild(p)
    if unwrapped == nil {
      return nil
    }
    // TODO(asuhan): decide the type correctly
    let child =
      wk_interop.Box_isInlineTextBox(unwrapped)
      ? convert_inline_text_box(p: unwrapped!) : ElementBoxWrapper()
    child.p = unwrapped
    let styleUnwrapped = wk_interop.Box_style(unwrapped)
    child.style = convert_render_style(p: styleUnwrapped!)
    return child
  }

  func firstInFlowChild() -> BoxWrapper? {
    if p == nil {
      return nil
    }
    let unwrapped = wk_interop.ElementBox_firstInFlowChild(p)
    if unwrapped == nil {
      return nil
    }
    // TODO(asuhan): decide the type correctly
    let child = convert_inline_text_box(p: unwrapped!)
    child.p = unwrapped
    return child
  }

  func firstInFlowOrFloatingChild() -> BoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastChild() -> BoxWrapper? {
    if p == nil {
      return nil
    }
    let unwrapped = wk_interop.ElementBox_lastChild(p)
    if unwrapped == nil {
      return nil
    }
    // TODO(asuhan): decide the type correctly
    let styleUnwrapped = wk_interop.Box_style(unwrapped)!
    let style = convert_render_style(p: styleUnwrapped)
    let child =
      wk_interop.Box_isInlineTextBox(unwrapped)
      ? convert_inline_text_box(p: unwrapped!) : ElementBoxWrapper(style: style)
    child.p = unwrapped
    return child
  }

  func lastInFlowChild() -> BoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasChild() -> Bool {
    return firstChild() != nil
  }

  func hasInFlowChild() -> Bool {
    return firstInFlowChild() != nil
  }

  func hasInFlowOrFloatingChild() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutOfFlowChild() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.ElementBox_hasOutOfFlowChild(p)
  }

  func setBaselineForIntegration(baseline: LayoutUnit) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.ElementBox_setBaselineForIntegration(p!, baseline.rawValue())
  }

  func baselineForIntegration() -> LayoutUnit? {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    if !wk_interop.ElementBox_hasBaselineForIntegration(p) {
      return nil
    }
    return LayoutUnit.fromRawValue(value: wk_interop.ElementBox_baselineForIntegration(p))
  }

  func hasIntrinsicWidth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIntrinsicHeight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIntrinsicRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intrinsicWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intrinsicHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intrinsicRatio() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isListMarkerImage() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.ElementBox_isListMarkerImage(p)
  }

  func isListMarkerOutside() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.ElementBox_isListMarkerOutside(p)
  }

  func isListMarkerInsideList() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.ElementBox_isListMarkerInsideList(p)
  }

  override func rendererForIntegration() -> RenderElementWrapper? {
    let unwrapped = wk_interop.ElementBox_rendererForIntegration(p)
    if unwrapped == nil {
      return nil
    }
    if wk_interop.RenderObject_isRenderListMarker(unwrapped!) {
      return RenderListMarkerWrapper(p: unwrapped!)
    }
    if wk_interop.RenderObject_isRenderBlockFlow(unwrapped!) {
      return RenderBlockFlowWrapper(p: unwrapped!)
    }
    if wk_interop.RenderObject_isRenderFlexibleBox(unwrapped!) {
      return RenderFlexibleBoxWrapper(p: unwrapped!)
    }
    if wk_interop.RenderObject_isRenderBlock(unwrapped!) {
      return RenderBlockWrapper(p: unwrapped!)
    }
    if wk_interop.RenderObject_isRenderBox(unwrapped!) {
      return RenderBoxWrapper(p: unwrapped!)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
