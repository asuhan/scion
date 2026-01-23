/*
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
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

struct SVGTextMetrics {
  enum MetricsType {
    case SkippedSpaceMetrics
  }

  init() {
    self.init(0, 0, 0)
  }

  init(_ metricsType: MetricsType) {
    self.init(1, 0, 0)
  }

  init(_ length: UInt32, _ scaledWidth: Float32, _ scaledHeight: Float32) {
    self.width = scaledWidth
    self.height = scaledHeight
    self.length = length
  }

  private let width: Float32
  private let height: Float32
  private let length: UInt32
}
