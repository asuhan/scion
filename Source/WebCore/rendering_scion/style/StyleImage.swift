/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

import wk_interop

class StyleImage: Equatable {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  static func == (_ a: StyleImage, _ b: StyleImage) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Loading.
  func isPending() -> Bool {
    fatalError("Not reached")
  }

  func isLoaded(renderer: RenderElementWrapper) -> Bool {
    return wk_interop.StyleImage_isLoaded(p, wkRenderObject(renderer))
  }

  func errorOccurred() -> Bool {
    return wk_interop.StyleImage_errorOccurred(p)
  }

  func usesDataProtocol() -> Bool {
    return wk_interop.StyleImage_usesDataProtocol(p)
  }

  func hasImage() -> Bool {
    return wk_interop.StyleImage_hasImage(p)
  }

  func addClient(_ renderer: RenderElementWrapper) {
    wk_interop.StyleImage_addClient(p, wkRenderObject(renderer)!)
  }

  func removeClient(_ renderer: RenderElementWrapper) {
    wk_interop.StyleImage_removeClient(p, wkRenderObject(renderer)!)
  }

  func hasClient(_ renderer: RenderElementWrapper) -> Bool {
    return wk_interop.StyleImage_hasClient(p, wkRenderObject(renderer)!)
  }

  // Size / scale.
  func imageSize(_ renderer: RenderElementWrapper?, _ multiplier: Float32) -> FloatSize {
    var width: Float32 = 0
    var height: Float32 = 0
    wk_interop.StyleImage_imageSize(p, wkRenderObject(renderer), multiplier, &width, &height)
    return FloatSize(width: width, height: height)
  }

  func usesImageContainerSize() -> Bool { fatalError("Not reached") }

  func computeIntrinsicDimensions(
    renderer: RenderElementWrapper?, intrinsicWidth: inout LengthWrapper,
    intrinsicHeight: inout LengthWrapper, intrinsicRatio: inout FloatSize
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func imageScaleFactor() -> Float32 {
    return wk_interop.StyleImage_imageScaleFactor(p)
  }

  func imageHasNaturalDimensions() -> Bool {
    return wk_interop.StyleImage_imageHasNaturalDimensions(p)
  }

  // Image.
  func image(renderer: RenderElementWrapper?, size: FloatSize, isForFirstLine: Bool = false)
    -> ImageWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cachedImage() -> CachedImageWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Rendering.
  func canRender(renderer: RenderElementWrapper, multiplier: Float32) -> Bool {
    return wk_interop.StyleImage_canRender(p, wkRenderObject(renderer), multiplier)
  }

  func setContainerContextForRenderer(
    renderer: RenderElementWrapper, containerSize: FloatSize, containerZoom: Float32
  ) {
    wk_interop.StyleImage_setContainerContextForRenderer(
      p, wkRenderObject(renderer), containerSize.width, containerSize.height, containerZoom)
  }

  func isGeneratedImage() -> Bool {
    return wk_interop.StyleImage_isGeneratedImage(p)
  }

  func hasCachedImage() -> Bool {
    return wk_interop.StyleImage_hasCachedImage(p)
  }

  private let p: UnsafeMutableRawPointer
}
