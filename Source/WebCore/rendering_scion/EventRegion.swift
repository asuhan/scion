/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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

private func toFloatSizeRaw(_ size: FloatSize) -> FloatSizeRaw {
  return FloatSizeRaw(width: size.width, height: size.height)
}

func convertFloatRoundedRect(_ roundedRect: FloatRoundedRect) -> FloatRoundedRectRaw {
  let rect = FloatRectRaw(
    x: roundedRect.rect.x(), y: roundedRect.rect.y(), width: roundedRect.rect.width(),
    height: roundedRect.rect.height())
  let radii = FloatRadiiRaw(
    topLeft: toFloatSizeRaw(roundedRect.radii.topLeft),
    topRight: toFloatSizeRaw(roundedRect.radii.topRight),
    bottomLeft: toFloatSizeRaw(roundedRect.radii.bottomLeft),
    bottomRight: toFloatSizeRaw(roundedRect.radii.bottomRight))
  return FloatRoundedRectRaw(rect: rect, radii: radii)
}

final class EventRegionContext: RegionContext {
  override init(_ p: UnsafeMutableRawPointer) { super.init(p) }

  func unite(
    roundedRect: FloatRoundedRect, renderer: RenderObjectWrapper, style: RenderStyleWrapper,
    overrideUserModifyIsEditable: Bool = false
  ) {
    assert(!isNativeImpl())
    let roundedRectRaw = convertFloatRoundedRect(roundedRect)
    let rendererRaw = renderer.getWk()
    wk_interop.EventRegionContext_unite(
      p!, roundedRectRaw, rendererRaw, style.p!, overrideUserModifyIsEditable)
  }

  func contains(rect: IntRect) -> Bool {
    assert(!isNativeImpl())
    return wk_interop.EventRegionContext_contains(
      p!,
      IntRectRaw(
        location: IntPointRaw(x: rect.location.x, y: rect.location.y),
        size: IntSizeRaw(width: rect.size.width, height: rect.size.height)))
  }
}
