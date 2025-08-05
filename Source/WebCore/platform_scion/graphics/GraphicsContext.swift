/*
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
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

class GraphicsContextWrapper {
  func paintingDisabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidatingImagesWithAsyncDecodes() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func detectingContentfulPaint() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFillColor(color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStrokeColor(color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeThickness() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStrokeThickness(thickness: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeStyle() -> StrokeStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setDropShadow(dropShadow: GraphicsDropShadow) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearDropShadow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func compositeOperation() -> CompositeOperator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCompositeOperation(operation: CompositeOperator, blendMode: BlendMode = .Normal) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAlpha(alpha: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textDrawingMode() -> TextDrawingModeFlags {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTextDrawingMode(textDrawingMode: TextDrawingModeFlags) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShouldAntialias(shouldAntialias: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setDrawLuminanceMask(drawLuminanceMask: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func save(purpose: GraphicsContextState.Purpose = .SaveRestore) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func restore(purpose: GraphicsContextState.Purpose = .SaveRestore) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustLineToPixelBoundaries(
    p1: FloatPoint, p2: FloatPoint, strokeWidth: Float32, penStyle: StrokeStyle
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokePath(path: PathWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillRect(rect: FloatRectWrapper, color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillRect(
    rect: FloatRectWrapper, color: ColorWrapper, op: CompositeOperator,
    blendMode: BlendMode = .Normal
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillRoundedRect(rect: FloatRoundedRect, color: ColorWrapper, blendMode: BlendMode = .Normal)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearRect(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLineCap(lineCap: LineCap) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLineJoin(lineJoin: LineJoin) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMiterLimit(miter: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func drawTiledImage(
    image: ImageWrapper, destination: FloatRectWrapper, source: FloatPoint, tileSize: FloatSize,
    spacing: FloatSize, options: ImagePaintingOptionsWrapper = ImagePaintingOptionsWrapper()
  ) -> ImageDrawResult {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clip(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipOut(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipPath(path: PathWrapper, clipRule: WindRule = .EvenOdd) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func drawText(
    font: FontCascadeWrapper, run: TextRunWrapper, point: FloatPoint,
    from: UInt32 = 0, to: UInt32? = nil
  ) -> FloatSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func drawEmphasisMarks(
    font: FontCascadeWrapper, run: TextRunWrapper, mark: AtomStringWrapper, point: FloatPoint,
    from: UInt32 = 0, to: UInt32? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeUnderlineBoundsForText(rect: FloatRectWrapper, printing: Bool) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func drawLineForText(
    rect: FloatRectWrapper, printing: Bool, doubleUnderlines: Bool = false,
    style: StrokeStyle = .SolidStroke
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func drawLinesForText(
    point: FloatPoint, thickness: Float32, widths: DashArray, printing: Bool,
    doubleUnderlines: Bool, strokeStyle: StrokeStyle
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func drawDotsForDocumentMarker(rect: FloatRectWrapper, style: DocumentMarkerLineStyle) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // DisplayList
  func drawDisplayListItems(
    items: [DisplayList.ItemWrapper], resourceHeap: DisplayList.ResourceHeapWrapper,
    controlFactory: ControlFactoryWrapper, destination: FloatPoint
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func beginTransparencyLayer(opacity: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endTransparencyLayer() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func concatCTM(transform: AffineTransform) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum IncludeDeviceScale {
    case DefinitelyIncludeDeviceScale
    case PossiblyIncludeDeviceScale
  }

  func getCTM(includeScale: IncludeDeviceScale = .PossiblyIncludeDeviceScale) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentfulPaintDetected() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentfulPaintDetected() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
