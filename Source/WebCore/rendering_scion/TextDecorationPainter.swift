/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2017 Apple Inc. All rights reserved.
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

struct TextDecorationPainter {
  struct Styles {}

  struct BackgroundDecorationGeometry {}

  func paintBackgroundDecorations(
    style: RenderStyleWrapper, textRun: TextRunWrapper,
    decorationGeometry: BackgroundDecorationGeometry, decorationType: TextDecorationLine,
    decorationStyle: Styles
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct ForegroundDecorationGeometry {
    let boxOrigin: FloatPoint
    let textBoxWidth: Float32
    let textDecorationThickness: Float32
    let linethroughCenter: Float32
    let wavyStrokeParameters: WavyStrokeParameters
  }

  func paintForegroundDecorations(
    foregroundDecorationGeometry: ForegroundDecorationGeometry, decorationStyle: Styles
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func textDecorationsInEffectForStyle(style: Styles) -> TextDecorationLine {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
