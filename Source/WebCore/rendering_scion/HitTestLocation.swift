/*
 * Copyright (C) 2006 Apple Inc.
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
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

struct HitTestLocationWrapper {
  // Make a copy the HitTestLocation in a new region by applying given offset to internal point and area.
  init(_ other: HitTestLocationWrapper, _ offset: LayoutSizeWrapper) {
    m_point = other.m_point
    m_boundingBox = other.m_boundingBox
    m_transformedPoint = other.m_transformedPoint
    m_transformedRect = other.m_transformedRect
    m_isRectBased = other.m_isRectBased
    m_isRectilinear = other.m_isRectilinear
    move(offset)
  }

  func point() -> LayoutPointWrapper { return m_point }

  func roundedPoint() -> IntPoint { return roundedIntPoint(point: m_point) }

  func boundingBox() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intersects(rect: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private mutating func move(_ offset: LayoutSizeWrapper) {
    m_point.move(s: offset)
    m_transformedPoint.move(offset.FloatSize())
    m_transformedRect.move(offset)
    m_boundingBox = LayoutRectWrapper(rect: enclosingIntRect(rect: m_transformedRect.boundingBox()))
  }

  // These are the cached forms of the more accurate point and rect below.
  private var m_point: LayoutPointWrapper
  private var m_boundingBox: LayoutRectWrapper

  private var m_transformedPoint: FloatPoint
  private let m_transformedRect: FloatQuad

  private let m_isRectBased: Bool
  private let m_isRectilinear: Bool
}
