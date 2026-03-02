/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005, 2006, 2007, 2008, 2014 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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

struct FillSize {
  let type: FillSizeType
  let size: LengthSize
}

struct FillRepeatXY {
  let x: FillRepeat = .Repeat
  let y: FillRepeat = .Repeat
}

class FillLayerWrapper {
  init(_ p: UnsafeRawPointer) { self.p = p }

  func image() -> StyleImage? {
    assert(!isNativeImpl())
    let raw = wk_interop.FillLayer_image(self.p)
    if raw == nil {
      return nil
    }
    return StyleImage(raw!)
  }

  var xPosition: LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var yPosition: LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var backgroundXOrigin: Edge {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var backgroundYOrigin: Edge {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var attachment: FillAttachment {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var clip: FillBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var origin: FillBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var `repeat`: FillRepeatXY {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var blendMode: BlendMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var sizeLength: LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var sizeType: FillSizeType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> FillSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var maskMode: MaskMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // https://drafts.fxtf.org/css-masking/#the-mask-composite
  // If there is no further mask layer, the compositing operator must be ignored.
  func compositeForPainting() -> CompositeOperator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func next() -> FillLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func imagesAreLoaded(renderer: RenderElementWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasImage() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOpaqueImage(renderer: RenderElementWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasRepeatXY() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipOccludesNextLayers(firstLayer: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isNativeImpl() -> Bool { return false }

  private let p: UnsafeRawPointer
}
