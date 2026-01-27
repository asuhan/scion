/*
 * Copyright (C) 2004, 2005, 2006, 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006 Rob Buis <buis@kde.org>
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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

enum SVGLengthType {
  case Unknown
  case Number
  case Percentage
  case Ems
  case Exs
  case Pixels
  case Centimeters
  case Millimeters
  case Inches
  case Points
  case Picas
}

enum SVGLengthMode {
  case Width
  case Height
  case Other
}

struct SVGLengthValue {
  init(_ lengthMode: SVGLengthMode = .Other, _ valueAsString: StringWrapper = StringWrapper()) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func value(_ context: SVGLengthContext) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func valueAsPercentage() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let valueInSpecifiedUnits: Float32 = 0
  let lengthType: SVGLengthType = .Number
}
