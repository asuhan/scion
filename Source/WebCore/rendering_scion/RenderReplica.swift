/*
 * Copyright (C) 2008 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

final class RenderReplicaWrapper: RenderBoxWrapper {
  init(document: Document, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func requiresLayer() -> Bool {
    assert(isNativeImpl())
    return true
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    setFrameRect(rect: parentBox()!.borderBoxRect())
    updateLayerTransform()
    clearNeedsLayout()
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.phase != .Foreground && paintInfo.phase != .Mask {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    if paintInfo.phase == .Foreground {
      // Turn around and paint the parent layer. Use temporary clipRects, so that the layer doesn't end up caching clip rects
      // computing using the wrong rootLayer
      let rootPaintingLayer =
        layer()!.transform != nil ? layer()!.parent() : layer()!.enclosingTransformedAncestor()
      let paintingInfo = RenderLayerWrapper.LayerPaintingInfo(
        inRootLayer: rootPaintingLayer, inDirtyRect: paintInfo.rect, inPaintBehavior: .Normal,
        inSubpixelOffset: LayoutSizeWrapper(), inSubtreePaintRoot: nil)
      let flags: RenderLayerWrapper.PaintLayerFlag = [
        .HaveTransparency, .AppliedTransform, .TemporaryClipRects, .PaintingReflection,
      ]
      layer()!.parent()!.paintLayer(
        context: paintInfo.context(), paintingInfo: paintingInfo, paintFlags: flags)
    } else if paintInfo.phase == .Mask {
      paintMask(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
    }
  }

  override func canHaveChildren() -> Bool {
    assert(isNativeImpl())
    return false
  }

  override func computePreferredLogicalWidths() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
