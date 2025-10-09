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

  func type() -> `Type` {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setName(name: String) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Add child layers. If the child is already parented, it will be removed from its old parent.
  func addChild(childLayer: GraphicsLayer) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeFromParent() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMaskLayer(layer: GraphicsLayer?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsBackdropRoot(isBackdropRoot: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBackdropRoot() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  func setPosition(p: FloatPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAnchorPoint(p: FloatPoint3D) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setSize(size: FloatSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTransform(matrix: TransformationMatrix) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMasksToBounds(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setDrawsContent(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentsOpaque(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOpacity(opacity: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBlendMode(blendMode: BlendMode) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPaintingPhase(phase: GraphicsLayerPaintingPhase) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum ShouldClipToLayer {
    case DoNotClipToLayer
    case ClipToLayer
  }

  func shouldDirectlyCompositeImage(image: ImageWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  func setShowRepaintCounter(show: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAppliesPageScale(appliesScale: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Whether this layer can throw away backing store to save memory. False for layers that can be revealed by async scrolling.
  func setAllowsBackingStoreDetaching(allowDetaching: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAllowsTiling(allowsTiling: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func supportsContentsTiling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
