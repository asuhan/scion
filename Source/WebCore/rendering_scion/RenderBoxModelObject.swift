/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2010-2018 Google Inc. All rights reserved.
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

// Modes for some of the line-related functions.
enum LinePositionMode: UInt8 {
  case PositionOnContainingLine
  case PositionOfInteriorLineBoxes
}

enum LineDirectionMode: UInt8 {
  case HorizontalLine
  case VerticalLine
}

class RenderBoxModelObjectWrapper: RenderLayerModelObjectWrapper {
  func paddingStart() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_paddingStart(p))
  }

  func paddingEnd() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_paddingEnd(p))
  }

  func borderStart() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_borderStart(p))
  }

  func marginStart(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderBoxModelObject_marginStart(p, otherStyle?.p))
  }

  func baselinePosition(
    baselineType: FontBaseline, firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  ) -> LayoutUnit {
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderBoxModelObject_baselinePosition(
        p, baselineType.rawValue, firstLine, direction.rawValue, linePositionMode.rawValue))
  }

  func inlineContinuation() -> RenderInlineWrapper? {
    if let raw = wk_interop.RenderBoxModelObject_inlineContinuation(p) {
      return RenderInlineWrapper(p: raw)
    }
    return nil
  }
}
