/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
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

func rotation(boxRect: FloatRectWrapper, direction: RotationDirection) -> AffineTransform {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

struct TextPainter {
  init(context: GraphicsContextWrapper, font: FontCascadeWrapper, renderStyle: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStyle(textPaintStyle: TextPaintStyle) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShadow(shadow: ShadowData?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setShadowColorFilter(colorFilter: FilterOperations) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsHorizontal(isHorizontal: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setEmphasisMark(
    mark: AtomStringWrapper, offset: Float32, combinedText: RenderCombineTextWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
