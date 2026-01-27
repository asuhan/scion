/*
 * Copyright (C) Research In Motion Limited 2010-2011. All rights reserved.
 * Copyright (C) 2024 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
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
 */

struct SVGCharacterData {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var x: Float32
  var y: Float32
  let dx: Float32
  let dy: Float32
  let rotate: Float32
}

typealias SVGCharacterDataMap = [UInt32: SVGCharacterData]

class SVGTextMetricsArrayRef {
  init(_ a: [SVGTextMetrics]) { self.a = a }

  var a: [SVGTextMetrics]
}

class SVGTextLayoutAttributes {
  static func isEmptyValue(_ value: Float32) -> Bool { return value.isNaN }

  func clear() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func context() -> RenderSVGInlineTextWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func characterDataMap() -> SVGTextLayoutAttributesBuilder.SVGCharacterDataMapRef {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textMetricsValues() -> SVGTextMetricsArrayRef {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
