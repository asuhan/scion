/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2021 Apple Inc. All rights reserved.
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

class StyleGeneratedImage: StyleImage {
  override final func imageSize(_ renderer: RenderElementWrapper?, _ multiplier: Float32)
    -> FloatSize
  {
    if !m_fixedSize {
      return m_containerSize
    }

    if renderer == nil {
      return FloatSize()
    }

    let fixedSize = fixedSize(renderer!)
    if multiplier == 1 {
      return fixedSize
    }

    var width = fixedSize.width * multiplier
    var height = fixedSize.height * multiplier

    // Don't let images that have a width/height >= 1 shrink below 1 device pixel when zoomed.
    let deviceScaleFactor = renderer!.document().deviceScaleFactor()
    if fixedSize.width > 0 {
      width = max(1 / deviceScaleFactor, width)
    }
    if fixedSize.height > 0 {
      height = max(1 / deviceScaleFactor, height)
    }

    return FloatSize(width: width, height: height)
  }

  override final func computeIntrinsicDimensions(
    renderer: RenderElementWrapper?, intrinsicWidth: inout LengthWrapper,
    intrinsicHeight: inout LengthWrapper, intrinsicRatio: inout FloatSize
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // All generated images must be able to compute their fixed size.
  func fixedSize(_ renderer: RenderElementWrapper) -> FloatSize { fatalError("Not reached") }

  private let m_containerSize = FloatSize()
  private let m_fixedSize = false
}
