/*
 * Copyright (C) 2004, 2006, 2007, 2009 Apple Inc. All rights reserved.
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

final class RenderHTMLCanvasWrapper: RenderReplacedWrapper {
  func canvasElement() -> HTMLCanvasElementWrapper {
    return nodeForNonAnonymous() as! HTMLCanvasElementWrapper
  }

  private func canvasSizeChanged() {
    let canvasSize = canvasElement().size()
    let zoomedSize = LayoutSizeWrapper(
      width: Float32(canvasSize.width) * style().usedZoom(),
      height: Float32(canvasSize.height) * style().usedZoom())

    if zoomedSize == intrinsicSize() {
      return
    }

    setIntrinsicSize(zoomedSize)

    if parent() == nil {
      return
    }
    setNeedsLayoutIfNeededAfterIntrinsicSizeChange()
  }

  override func requiresLayer() -> Bool {
    if super.requiresLayer() {
      return true
    }

    return canvasCompositingStrategy(renderer: self) != .CanvasPaintedToEnclosingLayer
  }

  override final func paintReplaced(
    _ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    let context = paintInfo.context()

    var contentBoxRect = contentBoxRect()

    if context.detectingContentfulPaint() {
      if !context.contentfulPaintDetected() && canvasElement().renderingContext() != nil {
        context.setContentfulPaintDetected()
      }
      return
    }

    contentBoxRect.moveBy(offset: paintOffset)
    var replacedContentRect = replacedContentRect()
    replacedContentRect.moveBy(offset: paintOffset)

    // Not allowed to overflow the content box.
    let clip = !contentBoxRect.contains(other: replacedContentRect)
    let unused = GraphicsContextStateSaver(context: paintInfo.context(), saveAndRestore: clip)
    use(unused)
    if clip {
      paintInfo.context().clip(rect: FloatRectWrapper(r: snappedIntRect(rect: contentBoxRect)))
    }

    if paintInfo.phase == .Foreground {
      page().addRelevantRepaintedObject(
        object: self, objectPaintRect: intersection(a: replacedContentRect, b: contentBoxRect))
    }

    let _ = InterpolationQualityMaintainer(
      context, ImageQualityController.interpolationQualityFromStyle(style()))

    canvasElement().setIsSnapshotting(paintInfo.paintBehavior.contains(.Snapshotting))
    canvasElement().paint(context, replacedContentRect)
    canvasElement().setIsSnapshotting(false)
  }

  override func intrinsicSizeChanged() { canvasSizeChanged() }
}
