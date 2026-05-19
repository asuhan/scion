/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2005-2008, 2017 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 * Copyright (C) 2016 Apple Inc.  All rights reserved.
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

enum TransformOperationType {
  case ScaleX
  case ScaleY
  case Scale
  case TranslateX
  case TranslateY
  case Translate
  case RotateX
  case RotateY
  case Rotate
  case SkewX
  case SkewY
  case Skew
  case Matrix
  case ScaleZ
  case Scale3D
  case TranslateZ
  case Translate3D
  case RotateZ
  case Rotate3D
  case Matrix3D
  case Perspective
  case Identity
  case None
}

class TransformOperation {
  typealias `Type` = TransformOperationType

  init(_ type: `Type`) { m_type = type }

  private func type() -> `Type` { return m_type }

  func is3DOperation() -> Bool {
    let opType = type()
    return opType == .ScaleZ
      || opType == .Scale3D
      || opType == .TranslateZ
      || opType == .Translate3D
      || opType == .RotateX
      || opType == .RotateY
      || opType == .Rotate3D
      || opType == .Matrix3D
      || opType == .Perspective
  }

  func isRepresentableIn2D() -> Bool { return true }

  static func isRotateTransformOperationType(_ type: `Type`) -> Bool {
    return type == .RotateX
      || type == .RotateY
      || type == .RotateZ
      || type == .Rotate
      || type == .Rotate3D
  }

  static func isScaleTransformOperationType(_ type: `Type`) -> Bool {
    return type == .ScaleX
      || type == .ScaleY
      || type == .ScaleZ
      || type == .Scale
      || type == .Scale3D
  }

  static func isTranslateTransformOperationType(_ type: `Type`) -> Bool {
    return type == .TranslateX
      || type == .TranslateY
      || type == .TranslateZ
      || type == .Translate
      || type == .Translate3D
  }

  private let m_type: `Type`
}
