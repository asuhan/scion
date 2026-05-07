/*
 * Copyright (C) 2009-2023 Apple Inc. All rights reserved.
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

class GraphicsLayer {
  enum `Type`: UInt8 {
    case Normal
    case Structural  // Supports position and transform only, and doesn't flatten (i.e. behaves like preserves3D is true). Uses CATransformLayer on Cocoa platforms.
    case PageTiledBacking
    case TiledBacking
    case ScrollContainer
    case ScrolledContents
    case Shape
  }

  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  // Unparent, clear the client, and clear the RefPtr.
  static func unparentAndClear(layer: GraphicsLayer?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Clear the client, and clear the RefPtr, but leave parented.
  static func clear(layer: GraphicsLayer?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func create(
    factory: GraphicsLayerFactory?, client: GraphicsLayerClientWrapper,
    layerType: GraphicsLayer.`Type` = .Normal
  ) -> GraphicsLayer {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func type() -> `Type` { return `Type`(rawValue: wk_interop.GraphicsLayer_type(p))! }

  func setName(name: String) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parent() -> GraphicsLayer? {
    guard let parentRaw = wk_interop.GraphicsLayer_parent(p) else { return nil }
    return GraphicsLayer(parentRaw)
  }

  func children() -> ArraySlice<GraphicsLayer> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true if the child list changed.
  @discardableResult
  func setChildren(newChildren: [GraphicsLayer]) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Add child layers. If the child is already parented, it will be removed from its old parent.
  func addChild(childLayer: GraphicsLayer) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeAllChildren() { wk_interop.GraphicsLayer_removeAllChildren(p) }

  func removeFromParent() { wk_interop.GraphicsLayer_removeFromParent(p) }

  func setMaskLayer(layer: GraphicsLayer?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsBackdropRoot(isBackdropRoot: Bool) {
    wk_interop.GraphicsLayer_setIsBackdropRoot(p, isBackdropRoot)
  }

  func isBackdropRoot() -> Bool { return wk_interop.GraphicsLayer_isBackdropRoot(p) }

  // The given layer will replicate this layer and its children; the replica renders behind this layer.
  func setReplicatedByLayer(layer: GraphicsLayer?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The layer that replicates this layer (if any).
  func replicaLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setReplicatedLayerPosition(_ point: FloatPoint) {
    wk_interop.GraphicsLayer_setReplicatedLayerPosition(p, FloatPointRaw(x: point.x, y: point.y))
  }

  enum ShouldSetNeedsDisplay {
    case DontSetNeedsDisplay
    case SetNeedsDisplay
  }

  // Offset is origin of the renderer minus origin of the graphics layer.
  func offsetFromRenderer() -> FloatSize {
    let offset = wk_interop.GraphicsLayer_offsetFromRenderer(p)
    return FloatSize(width: offset.width, height: offset.height)
  }

  func setOffsetFromRenderer(
    _ offset: FloatSize, _ shouldSetNeedsDisplay: ShouldSetNeedsDisplay = .SetNeedsDisplay
  ) {
    wk_interop.GraphicsLayer_setOffsetFromRenderer(
      p, FloatSizeRaw(width: offset.width, height: offset.height),
      shouldSetNeedsDisplay == .SetNeedsDisplay)
  }

  // Scroll offset of the content layer inside its scrolling parent layer.
  func scrollOffset() -> ScrollOffset {
    let offset = wk_interop.GraphicsLayer_scrollOffset(p)
    return ScrollOffset(x: offset.x, y: offset.y)
  }

  func setScrollOffset(
    _ offset: ScrollOffset, _ shouldSetNeedsDisplay: ShouldSetNeedsDisplay = .SetNeedsDisplay
  ) {
    wk_interop.GraphicsLayer_setScrollOffset(
      p, IntPointRaw(x: offset.x, y: offset.y), shouldSetNeedsDisplay == .SetNeedsDisplay)
  }

  // The position of the layer (the location of its top-left corner in its parent)
  func position() -> FloatPoint {
    let pos = wk_interop.GraphicsLayer_position(p)
    return FloatPoint(x: pos.x, y: pos.y)
  }

  func setPosition(p: FloatPoint) {
    wk_interop.GraphicsLayer_setPosition(self.p, FloatPointRaw(x: p.x, y: p.y))
  }

  func setAnchorPoint(p: FloatPoint3D) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The size of the layer.
  func size() -> FloatSize {
    let s = wk_interop.GraphicsLayer_size(p)
    return FloatSize(width: s.width, height: s.height)
  }

  func setSize(size: FloatSize) {
    wk_interop.GraphicsLayer_setSize(p, FloatSizeRaw(width: size.width, height: size.height))
  }

  func setBoundsOrigin(_ origin: FloatPoint) {
    wk_interop.GraphicsLayer_setBoundsOrigin(self.p, FloatPointRaw(x: origin.x, y: origin.y))
  }

  // For platforms that move underlying platform layers on a different thread for scrolling; just update the GraphicsLayer state.
  func syncBoundsOrigin(_ origin: FloatPoint) {
    wk_interop.GraphicsLayer_syncBoundsOrigin(self.p, FloatPointRaw(x: origin.x, y: origin.y))
  }

  func setTransform(matrix: TransformationMatrix) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setChildrenTransform(_ matrix: TransformationMatrix) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPreserves3D(_ b: Bool) { wk_interop.GraphicsLayer_setPreserves3D(p, b) }

  func setMasksToBounds(b: Bool) { wk_interop.GraphicsLayer_setMasksToBounds(p, b) }

  func drawsContent() -> Bool { return wk_interop.GraphicsLayer_drawsContent(p) }

  func setDrawsContent(b: Bool) { wk_interop.GraphicsLayer_setDrawsContent(p, b) }

  func setContentsVisible(_ b: Bool) { wk_interop.GraphicsLayer_setContentsVisible(p, b) }

  func setUserInteractionEnabled(_ b: Bool) {
    wk_interop.GraphicsLayer_setUserInteractionEnabled(p, b)
  }

  func setBackgroundColor(_ color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentsOpaque(b: Bool) { wk_interop.GraphicsLayer_setContentsOpaque(p, b) }

  func setBackfaceVisibility(_ b: Bool) { wk_interop.GraphicsLayer_setBackfaceVisibility(p, b) }

  func setOpacity(opacity: Float32) { wk_interop.GraphicsLayer_setOpacity(p, opacity) }

  func setBackdropFiltersRect(_ backdropFiltersRect: FloatRoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBlendMode(blendMode: BlendMode) {
    wk_interop.GraphicsLayer_setBlendMode(p, blendMode.rawValue)
  }

  func setPaintingPhase(phase: GraphicsLayerPaintingPhase) {
    wk_interop.GraphicsLayer_setPaintingPhase(p, phase.rawValue)
  }

  enum ShouldClipToLayer {
    case DoNotClipToLayer
    case ClipToLayer
  }

  func setNeedsDisplay() { wk_interop.GraphicsLayer_setNeedsDisplay(p) }

  // mark the given rect (in layer coords) as needing dispay. Never goes deep.
  func setNeedsDisplayInRect(
    _ initialRect: FloatRectWrapper, _ shouldClip: ShouldClipToLayer = .ClipToLayer
  ) {
    wk_interop.GraphicsLayer_setNeedsDisplayInRect(
      p, toFloatRectRaw(initialRect), shouldClip == .ClipToLayer)
  }

  func setContentsNeedsDisplay() { wk_interop.GraphicsLayer_setContentsNeedsDisplay(p) }

  func markDamageRectsUnreliable() { wk_interop.GraphicsLayer_markDamageRectsUnreliable(p) }

  // The tile phase is relative to the GraphicsLayer bounds.
  func setContentsTilePhase(_ p: FloatSize) {
    wk_interop.GraphicsLayer_setContentsTilePhase(
      self.p, FloatSizeRaw(width: p.width, height: p.height))
  }

  func setContentsTileSize(_ s: FloatSize) {
    wk_interop.GraphicsLayer_setContentsTileSize(
      self.p, FloatSizeRaw(width: s.width, height: s.height))
  }

  func setContentsRect(_ r: FloatRectWrapper) {
    wk_interop.GraphicsLayer_setContentsRect(p, toFloatRectRaw(r))
  }

  func setContentsClippingRect(_ roundedRect: FloatRoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentsRectClipsDescendants(_ b: Bool) {
    wk_interop.GraphicsLayer_setContentsRectClipsDescendants(p, b)
  }

  func setShapeLayerPath(_ path: PathWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShapeLayerWindRule(_ windRule: WindRule) {
    wk_interop.GraphicsLayer_setShapeLayerWindRule(p, windRule == .EvenOdd)
  }

  // Layer contents
  func setContentsToImage(_ image: ImageWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldDirectlyCompositeImage(image: ImageWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum ContentsLayerPurpose {
    case None
    case Image
    case Media
    case Canvas
    case BackgroundColor
    case Plugin
    case Model
    case HostedModel
    case Host
  }

  // Pass an invalid color to remove the contents layer.
  func setContentsToSolidColor(_ color: ColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentsToPlatformLayer(_ platformLayer: PlatformLayer?, _ purpose: ContentsLayerPurpose)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentsToPlatformLayerHost(_ identifier: LayerHostingContextIdentifierWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usesContentsLayer() -> Bool { return wk_interop.GraphicsLayer_usesContentsLayer(p) }

  enum ScalingFilter {
    case Linear
    case Nearest
    case Trilinear
  }

  func setContentsMinificationFilter(filter: ScalingFilter) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentsMagnificationFilter(filter: ScalingFilter) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShowDebugBorder(show: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShowRepaintCounter(show: Bool) { wk_interop.GraphicsLayer_setShowRepaintCounter(p, show) }

  func pixelAlignmentOffset() -> FloatSize {
    let s = wk_interop.GraphicsLayer_pixelAlignmentOffset(p)
    return FloatSize(width: s.width, height: s.height)
  }

  func setAppliesPageScale(appliesScale: Bool = true) {
    wk_interop.GraphicsLayer_setAppliesPageScale(p, appliesScale)
  }

  func setAppliesDeviceScale(_ appliesScale: Bool = true) {
    wk_interop.GraphicsLayer_setAppliesDeviceScale(p, appliesScale)
  }

  func appliesDeviceScale() -> Bool { return wk_interop.GraphicsLayer_appliesDeviceScale(p) }

  // Whether this layer can throw away backing store to save memory. False for layers that can be revealed by async scrolling.
  func setAllowsBackingStoreDetaching(allowDetaching: Bool) {
    wk_interop.GraphicsLayer_setAllowsBackingStoreDetaching(p, allowDetaching)
  }

  func setAllowsTiling(allowsTiling: Bool) {
    wk_interop.GraphicsLayer_setAllowsTiling(p, allowsTiling)
  }

  func setShouldUpdateRootRelativeScaleFactor(value: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func tiledBacking() -> TiledBackingWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTileCoverage(coverage: TiledBackingWrapper.TileCoverage) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func supportsLayerType(type: `Type`) -> Bool {
    return wk_interop.GraphicsLayer_supportsLayerType(type.rawValue)
  }

  static func supportsContentsTiling() -> Bool {
    return wk_interop.GraphicsLayer_supportsContentsTiling()
  }

  func setShouldPaintUsingCompositeCopy(_ copy: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAnimationExtent(_ animationExtent: FloatRectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let p: UnsafeMutableRawPointer
}
