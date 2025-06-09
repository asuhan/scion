/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

public typealias InlineLayoutUnit = Float32
typealias InlineLayoutPoint = FloatPoint
typealias InlineLayoutSize = FloatSize
typealias InlineLayoutRect = FloatRectWrapper

struct Position: Comparable, Equatable {
  var value = LayoutUnit()

  func toLayoutUnit() -> LayoutUnit {
    return value
  }

  static func < (a: Position, b: Position) -> Bool {
    return a.value < b.value
  }
}

struct Point {
  // FIXME: Use Position<Horizontal>, Position<Vertical> to avoid top/left vs. x/y confusion.
  var x = LayoutUnit()  // left
  var y = LayoutUnit()  // top

  init(point: LayoutPointWrapper) {
    self.x = point.x
    self.y = point.y
  }

  init(x: LayoutUnit, y: LayoutUnit) {
    self.x = x
    self.y = y
  }

  mutating func move(offset: LayoutSizeWrapper) {
    x += offset.width()
    y += offset.height()
  }

  mutating func moveBy(offset: LayoutPointWrapper) {
    x += offset.x
    y += offset.y
  }

  func LayoutPoint() -> LayoutPointWrapper {
    return LayoutPointWrapper(x: x, y: y)
  }
}

typealias PointInContextRoot = Point
typealias PositionInContextRoot = Position

struct ContentWidthAndMargin {
  var contentWidth = LayoutUnit()
  var usedMargin = UsedHorizontalMargin()
}

struct ContentHeightAndMargin {
  var contentHeight = LayoutUnit()
  var nonCollapsedMargin = UsedVerticalMargin.NonCollapsedValues()
}

struct HorizontalGeometry {
  var left = LayoutUnit()
  var right = LayoutUnit()
  var contentWidthAndMargin = ContentWidthAndMargin()
}

struct VerticalGeometry {
  var top = LayoutUnit()
  var bottom = LayoutUnit()
  var contentHeightAndMargin = ContentHeightAndMargin()
}

struct OverriddenVerticalValues {
  // Consider collapsing it.
  var height: LayoutUnit? = nil
}

struct OverriddenHorizontalValues {
  var width: LayoutUnit? = nil
  var margin: UsedHorizontalMargin? = nil
}

internal func toLayoutUnit(value: InlineLayoutUnit) -> LayoutUnit {
  return LayoutUnit(value: value)
}

internal func ceiledLayoutUnit(value: InlineLayoutUnit) -> LayoutUnit {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func toLayoutPoint(point: InlineLayoutPoint) -> LayoutPointWrapper {
  return LayoutPointWrapper(size: point)
}

func toLayoutSize(size: InlineLayoutSize) -> LayoutSizeWrapper {
  return LayoutSizeWrapper(size: size)
}

func toLayoutRect(rect: InlineLayoutRect) -> LayoutRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func maxInlineLayoutUnit() -> InlineLayoutUnit {
  return Float32.greatestFiniteMagnitude
}
