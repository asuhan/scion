/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
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

/*
 * Paint the object and its children, clipped by (x|y|w|h).
 * (tx|ty) is the calculated position of the parent
 */

import wk_interop

typealias OverlapTestRequestMap = [ObjectIdentifier: IntRect]

struct PaintInfoWrapper {
  init(
    newContext: GraphicsContextWrapper, newRect: LayoutRectWrapper, newPhase: PaintPhase,
    newPaintBehavior: PaintBehavior, newSubtreePaintRoot: RenderObjectWrapper? = nil,
    newOutlineObjects: ListSet<RenderInlineWrapper, UInt>? = nil,
    overlapTestRequests: OverlapTestRequestMap? = nil,
    newPaintContainer: RenderLayerModelObjectWrapper? = nil,
    enclosingSelfPaintingLayer: RenderLayerWrapper? = nil,
    newRequireSecurityOriginAccessForWidgets: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  func context() -> GraphicsContextWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldPaintWithinRoot(renderer: RenderObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func forceTextColor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func forcedTextColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingSelfPaintingLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func eventRegionContext() -> EventRegionContext? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func accessibilityRegionContext() -> AccessibilityRegionContext? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deepCopy() -> PaintInfoWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var rect: LayoutRectWrapper {
    let raw = PaintInfo_rect(p)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  var phase: PaintPhase {
    get {
      return PaintPhase(rawValue: PaintInfo_phase(p))!
    }
    set {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  var paintBehavior: PaintBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // used to list outlines that should be painted by a block with inline children
  var outlineObjects: ListSet<RenderInlineWrapper, UInt>? {
    get {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    set {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  // the layer object that originates the current painting
  var paintContainer: RenderLayerModelObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let p: UnsafeMutableRawPointer
}
