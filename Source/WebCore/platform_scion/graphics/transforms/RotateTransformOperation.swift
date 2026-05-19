/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 1999-2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2008, 2017 Apple Inc. All rights reserved.
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

final class RotateTransformOperation: TransformOperation {
  init(x: Float64, y: Float64, z: Float64, angle: Float64, type: TransformOperation.`Type`) {
    m_x = x
    m_y = y
    m_z = z
    m_angle = angle
    super.init(type)
    assert(TransformOperation.isRotateTransformOperationType(type))
  }

  override final func isRepresentableIn2D() -> Bool {
    return (m_x == 0 && m_y == 0) || m_angle == 0
  }

  private let m_x: Float64
  private let m_y: Float64
  private let m_z: Float64
  private let m_angle: Float64
}
