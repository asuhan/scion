/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
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

private let cInterpolationCutoff: Double = 800.0 * 800.0

class ImageQualityController {
  init(_ renderView: RenderViewWrapper) {
    m_renderView = renderView
    // TODO(asuhan): initialize timer
  }

  static func interpolationQualityFromStyle(_ style: RenderStyleWrapper) -> InterpolationQuality? {
    switch style.imageRendering() {
    case .OptimizeSpeed:
      return .Low
    case .CrispEdges, .Pixelated:
      return .DoNotInterpolate
    case .OptimizeQuality:
      return .Default  // FIXME: CSS 3 Images says that optimizeQuality should behave like 'auto', but that prevents authors from overriding this low quality rendering behavior.
    case .Auto:
      return nil
    }
  }

  func chooseInterpolationQuality(
    _ context: GraphicsContextWrapper, _ object: RenderBoxModelObjectWrapper, _ image: ImageWrapper,
    _ layer: FillLayerWrapper, _ size: LayoutSizeWrapper
  ) -> InterpolationQuality {
    // If the image is not a bitmap image, then none of this is relevant and we just paint at high quality.
    if !(image.isBitmapImage() || image.isPDFDocumentImage()) || context.paintingDisabled() {
      return .Default
    }

    if let styleInterpolation = ImageQualityController.interpolationQualityFromStyle(object.style())
    {
      return styleInterpolation
    }

    // Make sure to use the unzoomed image size, since if a full page zoom is in effect, the image
    // is actually being scaled.
    let imageSize = IntSize(width: Int32(image.width()), height: Int32(image.height()))

    // Look ourselves up in the hashtables.
    let innerMap = m_objectLayerSizeMap.find(object)
    let oldSize = innerMap?.sizes[layerKey(layer)]

    // If the containing FrameView is being resized, paint at low quality until resizing is finished.
    if object.document().frame() != nil {
      let frameViewIsCurrentlyInLiveResize =
        object.document().frame()!.view()?.inLiveResize() ?? false
      if frameViewIsCurrentlyInLiveResize {
        set(object, innerMap, layer, size)
        restartTimer()
        m_liveResizeOptimizationIsActive = true
        return .Low
      }
      if m_liveResizeOptimizationIsActive {
        return .Default
      }
    }

    let contextIsScaled = { (context: GraphicsContextWrapper) -> Bool in
      return !context.getCTM().isIdentityOrTranslationOrFlipped()
    }

    if size == LayoutSizeWrapper(size: imageSize) && !contextIsScaled(context) {
      // There is no scale in effect. If we had a scale in effect before, we can just remove this object from the list.
      removeLayer(object, innerMap, layer)
      return .Default
    }

    // There is no need to hash scaled images that always use low quality mode when the page demands it. This is the iChat case.
    if m_renderView.page().inLowQualityImageInterpolationMode() {
      let totalPixels = Double(image.width()) * Double(image.height())
      if totalPixels > cInterpolationCutoff {
        return .Low
      }
    }

    let saveEntryIfNewOrSizeChanged = { () in
      if oldSize == nil || oldSize! != size {
        self.set(object, innerMap, layer, size)
      }
    }

    // If an animated resize is active, paint in low quality and kick the timer ahead.
    if m_animatedResizeIsActive {
      saveEntryIfNewOrSizeChanged()
      restartTimer()
      return .Low
    }

    // If this is the first time resizing this image, or its size is the
    // same as the last resize, draw at high res, but record the paint
    // size and set the timer.
    if oldSize == nil || oldSize! == size {
      saveEntryIfNewOrSizeChanged()
      restartTimer()
      return .Default
    }

    // If the timer is no longer active, draw at high quality and don't set the timer.
    if !timerIsActive() {
      removeLayer(object, innerMap, layer)
      return .Default
    }

    // This object has been resized to two different sizes while the timer
    // is active, so draw at low quality, set the flag for animated resizes and
    // the object to the list for high quality redraw.
    saveEntryIfNewOrSizeChanged()
    m_animatedResizeIsActive = true
    restartTimer()
    return .Low
  }

  func rendererWillBeDestroyed(_ renderer: RenderBoxModelObjectWrapper) { removeObject(renderer) }

  // Upstream's HashMap<const void*, LayoutSize>, keyed by the fill layer's address since its
  // wrappers are not unique. A class, so that it is shared like upstream's LayerSizeMap pointer.
  private final class LayerSizeMap {
    var sizes: [UInt: LayoutSizeWrapper] = [:]
  }

  // Upstream's HashMap<SingleThreadWeakRef<RenderBoxModelObject>, LayerSizeMap>.
  private typealias ObjectLayerSizeMap = WeakHashMap<RenderBoxModelObjectWrapper, LayerSizeMap>

  private func layerKey(_ layer: FillLayerWrapper) -> UInt { return CPtrToInt(layer.p) }

  private func removeLayer(
    _ object: RenderBoxModelObjectWrapper, _ innerMap: LayerSizeMap?, _ layer: FillLayerWrapper
  ) {
    guard let innerMap else { return }
    innerMap.sizes.removeValue(forKey: layerKey(layer))
    if innerMap.sizes.isEmpty {
      removeObject(object)
    }
  }

  private func set(
    _ object: RenderBoxModelObjectWrapper, _ innerMap: LayerSizeMap?, _ layer: FillLayerWrapper,
    _ size: LayoutSizeWrapper
  ) {
    if let innerMap {
      innerMap.sizes[layerKey(layer)] = size
    } else {
      let newInnerMap = LayerSizeMap()
      newInnerMap.sizes[layerKey(layer)] = size
      m_objectLayerSizeMap.set(object, newInnerMap)
    }
  }

  private func restartTimer() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func timerIsActive() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func removeObject(_ object: RenderBoxModelObjectWrapper) {
    m_objectLayerSizeMap.remove(object)
    if m_objectLayerSizeMap.isEmpty() {
      m_animatedResizeIsActive = false
      // TODO(asuhan): stop timer
    }
  }

  private let m_renderView: RenderViewWrapper
  private let m_objectLayerSizeMap = ObjectLayerSizeMap()
  private var m_animatedResizeIsActive = false
  private var m_liveResizeOptimizationIsActive = false
}
