/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2005, 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2005-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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

class BorderPainter {
  init(renderer: RenderElementWrapper, paintInfo: PaintInfoWrapper) {
    self.renderer = renderer
    self.paintInfo = paintInfo
  }

  func paintBorder(
    rect: LayoutRectWrapper, style: RenderStyleWrapper,
    bleedAvoidance: BackgroundBleedAvoidance = .BackgroundBleedNone,
    includeLogicalLeftEdge: Bool = true, includeLogicalRightEdge: Bool = true
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintNinePieceImage(
    rect: LayoutRectWrapper, style: RenderStyleWrapper, ninePieceImage: NinePieceImage,
    op: CompositeOperator
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func pathForBorderArea(
    rect: LayoutRectWrapper, style: RenderStyleWrapper, deviceScaleFactor: Float32,
    includeLogicalLeftEdge: Bool = true, includeLogicalRightEdge: Bool = true
  ) -> PathWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let renderer: RenderElementWrapper
  private let paintInfo: PaintInfoWrapper
}
