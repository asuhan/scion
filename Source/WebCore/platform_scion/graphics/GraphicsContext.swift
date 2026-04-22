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

import wk_interop

class GraphicsContextWrapper {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  init() {
    // TODO(asuhan): implement this
    self.p = nil
  }

  func paintingDisabled() -> Bool { return wk_interop.GraphicsContext_paintingDisabled(p!) }

  func performingPaintInvalidation() -> Bool {
    return wk_interop.GraphicsContext_performingPaintInvalidation(p!)
  }

  func invalidatingControlTints() -> Bool {
    return wk_interop.GraphicsContext_invalidatingControlTints(p!)
  }

  func invalidatingImagesWithAsyncDecodes() -> Bool {
    return wk_interop.GraphicsContext_invalidatingImagesWithAsyncDecodes(p!)
  }

  func detectingContentfulPaint() -> Bool {
    return wk_interop.GraphicsContext_detectingContentfulPaint(p!)
  }

  func fillColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillGradient() -> GradientWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillGradientSpaceTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillPattern() -> PatternWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFillColor(color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFillPattern(pattern: PatternWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFillRule(fillRule: WindRule) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeGradient() -> GradientWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeGradientSpaceTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokePattern() -> PatternWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStrokeColor(color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeThickness() -> Float32 { return wk_interop.GraphicsContext_strokeThickness(p!) }

  func setStrokeThickness(thickness: Float32) {
    wk_interop.GraphicsContext_setStrokeThickness(p!, thickness)
  }

  func strokeStyle() -> StrokeStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStrokeStyle(style: StrokeStyle) {
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
    return CompositeOperator(rawValue: wk_interop.GraphicsContext_compositeOperation(p!))!
  }

  func setCompositeOperation(operation: CompositeOperator, blendMode: BlendMode = .Normal) {
    wk_interop.GraphicsContext_setCompositeOperation(p!, operation.rawValue, blendMode.rawValue)
  }

  func alpha() -> Float32 {
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

  func imageInterpolationQuality() -> InterpolationQuality {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setImageInterpolationQuality(_ imageInterpolationQuality: InterpolationQuality) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldAntialias() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShouldAntialias(shouldAntialias: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Normally CG enables subpixel-quantization because it improves the performance of aligning glyphs.
  // In some cases we have to disable to to ensure a high-quality output of the glyphs.
  func shouldSubpixelQuantizeFonts() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShouldSubpixelQuantizeFonts(shouldSubpixelQuantizeFonts: Bool) {
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

  // These draw methods will do both stroking and filling.
  // FIXME: ...except drawRect(), which fills properly but always strokes
  // using a 1-pixel stroke inset from the rect borders (of the correct
  // stroke color).
  func drawRect(rect: FloatRectWrapper, borderThickness: Float32 = 1) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This is only used to draw borders, so we should not draw shadows.
  func drawLine(point1: FloatPoint, point2: FloatPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillPath(path: PathWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokePath(path: PathWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillEllipse(_ ellipse: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeEllipse(_ ellipse: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum RequiresClipToRect {
    case No
    case Yes
  }

  func fillRect(_ rect: FloatRectWrapper, _ requiresClipToRect: RequiresClipToRect = .Yes) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fillRect(rect: FloatRectWrapper, color: ColorWrapper) {
    let srgba = color.toSRGBA()
    wk_interop.GraphicsContext_fillRect(
      p!, FloatRectRaw(x: rect.x(), y: rect.y(), width: rect.width(), height: rect.height()),
      SRGBARaw(red: srgba.red, green: srgba.green, blue: srgba.blue, alpha: srgba.alpha))
  }

  func fillRect(
    _ rect: FloatRectWrapper, _ gradient: GradientWrapper,
    _ gradientSpaceTransform: AffineTransform, _ requiresClipToRect: RequiresClipToRect = .Yes
  ) {
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

  func fillRectWithRoundedHole(
    rect: FloatRectWrapper, roundedHoleRect: FloatRoundedRect, color: ColorWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearRect(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeRect(_ rect: FloatRectWrapper, _ lineWidth: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLineCap(lineCap: LineCap) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLineDash(dashArray: DashArray, dashOffset: Float32) {
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

  func createScaledImageBuffer(
    _ rect: FloatRectWrapper, _ scale: FloatSize = FloatSize(width: 1, height: 1),
    _ colorSpace: DestinationColorSpace = DestinationColorSpace.SRGB(),
    _ renderingMode: RenderingMode? = nil, _ renderingMethod: RenderingMethod? = nil
  ) -> ImageBufferWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createAlignedImageBuffer(
    _ size: FloatSize, _ colorSpace: DestinationColorSpace = DestinationColorSpace.SRGB(),
    _ renderingMethod: RenderingMethod? = nil
  ) -> ImageBufferWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func drawImage(
    _ image: ImageWrapper, _ destination: FloatRectWrapper,
    _ imagePaintingOptions: ImagePaintingOptionsWrapper = ImagePaintingOptionsWrapper(
      ImageOrientation(orientation: .FromImage))
  ) -> ImageDrawResult {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func drawImage(
    _ image: ImageWrapper, _ destination: FloatRectWrapper, _ source: FloatRectWrapper,
    _ imagePaintingOptions: ImagePaintingOptionsWrapper = ImagePaintingOptionsWrapper(
      ImageOrientation(orientation: .FromImage))
  ) -> ImageDrawResult {
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

  func drawImageBuffer(
    _ image: ImageBufferWrapper, _ destination: FloatRectWrapper,
    _ imagePaintingOptions: ImagePaintingOptionsWrapper = ImagePaintingOptionsWrapper()
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func drawControlPart(
    part: ControlPartWrapper, borderRect: FloatRoundedRect, deviceScaleFactor: Float32,
    style: ControlStyle
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clip(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipRoundedRect(rect: FloatRoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipOut(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipOutRoundedRect(rect: FloatRoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipPath(path: PathWrapper, clipRule: WindRule = .EvenOdd) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipToImageBuffer(_ imageBuffer: ImageBufferWrapper, _ destRect: FloatRectWrapper) {
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

  func drawBidiText(
    font: FontCascadeWrapper, run: TextRunWrapper, point: FloatPoint,
    customFontNotReadyAction: FontCascadeWrapper.CustomFontNotReadyAction =
      .DoNotPaintIfFontNotReady
  ) {
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

  // Focus Rings

  func drawFocusRing(_ path: PathWrapper, _ outlineWidth: Float32, _ color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Transforms

  func scale(_ s: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rotate(_ angleInRadians: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func translate(size: FloatSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func translate(p: FloatPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func translate(x: Float32, y: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func concatCTM(transform: AffineTransform) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCTM(transform: AffineTransform) {
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

  private let p: UnsafeMutableRawPointer?
}
