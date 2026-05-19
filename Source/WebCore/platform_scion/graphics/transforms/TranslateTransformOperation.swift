/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003, 2004, 2005-2008, 2017 Apple Inc. All rights reserved.
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

final class TranslateTransformOperation: TransformOperation {
  static func create(tx: LengthWrapper, ty: LengthWrapper, type: TransformOperation.`Type`)
    -> TranslateTransformOperation
  {
    return TranslateTransformOperation(
      tx: tx, ty: ty, tz: LengthWrapper(value: Int32(0), type: .Fixed), type: type)
  }

  override final func isRepresentableIn2D() -> Bool { return m_z.isZero() }

  private init(
    tx: LengthWrapper, ty: LengthWrapper, tz: LengthWrapper, type: TransformOperation.`Type`
  ) {
    m_x = tx
    m_y = ty
    m_z = tz
    super.init(type)
    assert(TranslateTransformOperation.isTranslateTransformOperationType(type))
  }

  private let m_x: LengthWrapper
  private let m_y: LengthWrapper
  private let m_z: LengthWrapper
}
