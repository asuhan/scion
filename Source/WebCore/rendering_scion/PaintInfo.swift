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

typealias OverlapTestRequestMap = HashMap<OverlapTestRequestClient, IntRect>

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
    self.n = native(
      rect: newRect, phase: newPhase, paintBehavior: newPaintBehavior,
      subtreePaintRoot: newSubtreePaintRoot, outlineObjects: newOutlineObjects,
      overlapTestRequests: overlapTestRequests, paintContainer: newPaintContainer,
      requireSecurityOriginAccessForWidgets: newRequireSecurityOriginAccessForWidgets,
      enclosingSelfPaintingLayer: enclosingSelfPaintingLayer,
      context: newContext)
  }

  init(from: PaintInfoRaw) {
    if from.outline_objects != nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    self.n = native(
      rect: LayoutRectWrapper(
        x: LayoutUnit.fromRawValue(value: from.rect.x),
        y: LayoutUnit.fromRawValue(value: from.rect.y),
        width: LayoutUnit.fromRawValue(value: from.rect.width),
        height: LayoutUnit.fromRawValue(value: from.rect.height)),
      phase: PaintPhase(rawValue: from.phase),
      paintBehavior: PaintBehavior(rawValue: from.paint_behavior),
      subtreePaintRoot: from.subtree_paint_root != nil
        ? RenderObjectWrapper(p: from.subtree_paint_root!) : nil,
      outlineObjects: nil,
      overlapTestRequests: nil,
      paintContainer: nil,
      requireSecurityOriginAccessForWidgets: from.require_security_origin_access_for_widgets,
      enclosingSelfPaintingLayer: nil,
      context: GraphicsContextWrapper())
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  private init(n: native) {
    self.n = n
  }

  func context() -> GraphicsContextWrapper {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.context
  }

  func setContext(_ context: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateSubtreePaintRootForChildren(renderer: RenderObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldPaintWithinRoot(renderer: RenderObjectWrapper) -> Bool {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    if let subtreePaintRoot = n!.subtreePaintRoot {
      // TODO(asuhan): use ObjectIdentifier for comparison once gone native
      return CPtrToInt(subtreePaintRoot.p) == CPtrToInt(renderer.p)
    }
    return true
  }

  func forceTextColor() -> Bool { return forceBlackText() || forceWhiteText() }

  func forceBlackText() -> Bool {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.paintBehavior.contains(.ForceBlackText)
  }

  func forceWhiteText() -> Bool {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.paintBehavior.contains(.ForceWhiteText)
  }

  func forcedTextColor() -> ColorWrapper {
    return forceBlackText() ? ColorWrapper.black : ColorWrapper.white
  }

  func skipRootBackground() -> Bool {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.paintBehavior.contains(.SkipRootBackground)
  }

  func paintRootBackgroundOnly() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingSelfPaintingLayer() -> RenderLayerWrapper? {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.enclosingSelfPaintingLayer
  }

  func applyTransform(_ localToAncestorTransform: AffineTransform) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func eventRegionContext() -> EventRegionContext? {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.regionContext as? EventRegionContext
  }

  func accessibilityRegionContext() -> AccessibilityRegionContext? {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.regionContext as? AccessibilityRegionContext
  }

  func deepCopy() -> PaintInfoWrapper {
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return PaintInfoWrapper(n: n!)
  }

  var rect: LayoutRectWrapper {
    if let p = p {
      let raw = PaintInfo_rect(p)
      return LayoutRectWrapper(
        x: LayoutUnit.fromRawValue(value: raw.x),
        y: LayoutUnit.fromRawValue(value: raw.y),
        width: LayoutUnit.fromRawValue(value: raw.width),
        height: LayoutUnit.fromRawValue(value: raw.height))
    }
    return n!.rect
  }

  var phase: PaintPhase {
    get {
      if let p = p {
        return PaintPhase(rawValue: PaintInfo_phase(p))
      }
      return n!.phase
    }
    set {
      if n != nil {
        n!.phase = newValue
        return
      }
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  var paintBehavior: PaintBehavior {
    get {
      if n == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      return n!.paintBehavior
    }
    set {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  // used to list outlines that should be painted by a block with inline children
  var outlineObjects: ListSet<RenderInlineWrapper, UInt>? {
    get {
      if n == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      return n!.outlineObjects
    }
    set {
      if n == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      n!.outlineObjects = newValue
    }
  }

  var overlapTestRequests: OverlapTestRequestMap? {
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
    if n == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return n!.paintContainer
  }

  // For PaintPhase::EventRegion and PaintPhase::Accessibility.
  var regionContext: RegionContext? {
    get {
      if n == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      return n!.regionContext
    }
    set {
      if n == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      n!.regionContext = newValue
    }
  }

  var requireSecurityOriginAccessForWidgets: Bool {
    get {
      if n == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      return n!.requireSecurityOriginAccessForWidgets
    }
    set {
      if n == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      n!.requireSecurityOriginAccessForWidgets = newValue
    }
  }

  private struct native {
    let rect: LayoutRectWrapper
    var phase: PaintPhase
    let paintBehavior: PaintBehavior
    let subtreePaintRoot: RenderObjectWrapper?  // used to draw just one element and its visual children
    var outlineObjects: WeakListSet<RenderInlineWrapper, UInt>?  // used to list outlines that should be painted by a block with inline children
    let overlapTestRequests: OverlapTestRequestMap?
    let paintContainer: RenderLayerModelObjectWrapper?  // the layer object that originates the current painting
    var requireSecurityOriginAccessForWidgets: Bool
    let enclosingSelfPaintingLayer: RenderLayerWrapper?
    var regionContext: RegionContext? = nil  // For PaintPhase::EventRegion and PaintPhase::Accessibility.
    let context: GraphicsContextWrapper
  }

  private var p: UnsafeMutableRawPointer? = nil
  private var n: native? = nil
}
