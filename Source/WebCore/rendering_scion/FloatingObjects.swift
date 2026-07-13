/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2019 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

import wk_interop

class FloatingObjectSetIterator: IteratorProtocol, Equatable {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  deinit { wk_interop.FloatingObjectSetIterator_destroy(p) }

  func next() -> FloatingObjectWrapper? {
    let value = *self
    ++self
    return value
  }

  static prefix func * (it: FloatingObjectSetIterator) -> FloatingObjectWrapper {
    let raw = wk_interop.FloatingObjectSetIterator_deref(it.p)!
    return Unmanaged<FloatingObjectWrapper>.fromOpaque(raw).takeUnretainedValue()
  }

  @discardableResult
  static prefix func ++ (it: FloatingObjectSetIterator) -> FloatingObjectSetIterator {
    wk_interop.FloatingObjectSetIterator_inc(it.p)
    return it
  }

  @discardableResult
  static prefix func -- (it: FloatingObjectSetIterator) -> FloatingObjectSetIterator {
    wk_interop.FloatingObjectSetIterator_dec(it.p)
    return it
  }

  // Comparison.
  static func == (this: FloatingObjectSetIterator, other: FloatingObjectSetIterator) -> Bool {
    return wk_interop.FloatingObjectSetIterator_eq(this.p, other.p)
  }

  private let p: UnsafeMutableRawPointer
}

class FloatingObjectSet: Sequence {
  init() { p = wk_interop.FloatingObjectSet_create() }

  deinit { wk_interop.FloatingObjectSet_destroy(p) }

  func size() -> UInt32 { return wk_interop.FloatingObjectSet_size(p) }

  func isEmpty() -> Bool { return wk_interop.FloatingObjectSet_isEmpty(p) }

  func begin() -> FloatingObjectSetIterator {
    return FloatingObjectSetIterator(wk_interop.FloatingObjectSet_begin(p))
  }

  func end() -> FloatingObjectSetIterator {
    return FloatingObjectSetIterator(wk_interop.FloatingObjectSet_end(p))
  }

  func last() -> FloatingObjectWrapper {
    let raw = wk_interop.FloatingObjectSet_last(p)!
    return Unmanaged<FloatingObjectWrapper>.fromOpaque(raw).takeUnretainedValue()
  }

  func find(_ value: RenderBoxWrapper) -> FloatingObjectSetIterator {
    return FloatingObjectSetIterator(wk_interop.FloatingObjectSet_find(p, value.id()))
  }

  func contains(_ floating: FloatingObjectWrapper) -> Bool {
    let unmanaged = Unmanaged.passUnretained(floating)
    return wk_interop.FloatingObjectSet_contains(p, unmanaged.toOpaque())
  }

  func contains(_ box: RenderBoxWrapper) -> Bool {
    return wk_interop.FloatingObjectSet_containsBox(p, box.id())
  }

  func makeIterator() -> FloatingObjectSetIterator { return begin() }

  private let p: UnsafeMutableRawPointer
}

class FloatingObjectWrapper {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
    type = .FloatLeft
    m_hasAncestorWithOverflowClip = false
    m_marginOffset = LayoutSizeWrapper()
    m_paintsFloat = false
    isPlaced = false
  }

  static func create(_ renderer: RenderBoxWrapper) -> FloatingObjectWrapper {
    let object = FloatingObjectWrapper(renderer)
    object.setIsDescendant(true)
    return object
  }

  init(_ renderer: RenderBoxWrapper) {
    self.renderer = renderer
    let type = RenderStyleWrapper.usedFloat(renderer: renderer)
    assert(type != .None)
    self.type = type == .Left ? .FloatLeft : .FloatRight
    if let containingBlock = renderer.containingBlock() {
      m_hasAncestorWithOverflowClip =
        containingBlock.effectiveOverflowX() == .Clip
        || containingBlock.effectiveOverflowY() == .Clip
    } else {
      m_hasAncestorWithOverflowClip = false
    }
    m_marginOffset = LayoutSizeWrapper()
    m_paintsFloat = false
    isPlaced = false
  }

  init(
    _ renderer: RenderBoxWrapper, _ type: Type_, _ frameRect: LayoutRectWrapper,
    _ marginOffset: LayoutSizeWrapper, shouldPaint: Bool, isDescendant: Bool, overflowClipped: Bool
  ) {
    self.renderer = renderer
    self.m_frameRect = frameRect
    self.m_marginOffset = marginOffset
    self.type = type
    self.m_paintsFloat = shouldPaint
    self.m_isDescendant = isDescendant
    self.isPlaced = true
    self.m_hasAncestorWithOverflowClip = overflowClipped
  }

  // Note that Type uses bits so you can use FloatLeftRight as a mask to query for both left and right.
  struct Type_: OptionSet {
    let rawValue: UInt8

    static let FloatLeft = Type_(rawValue: 1 << 0)
    static let FloatRight = Type_(rawValue: 1 << 1)
    static let FloatLeftRight: Type_ = [.FloatLeft, .FloatRight]
  }

  func copyToNewContainer(
    offset: LayoutSizeWrapper, shouldPaint: Bool = false, isDescendant: Bool = false,
    overflowClipped: Bool = false
  ) -> FloatingObjectWrapper {
    return FloatingObjectWrapper(
      renderer!, type,
      LayoutRectWrapper(location: frameRect().location() - offset, size: frameRect().size()),
      marginOffset(), shouldPaint: shouldPaint, isDescendant: isDescendant,
      overflowClipped: overflowClipped)
  }

  func cloneForNewParent() -> FloatingObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsPlaced(placed: Bool) {
    wk_interop.FloatingObject_setIsPlaced(p!, placed)
  }

  func x() -> LayoutUnit {
    assert(isPlaced)
    return m_frameRect.x()
  }

  func maxX() -> LayoutUnit {
    assert(isPlaced)
    return m_frameRect.maxX()
  }

  func y() -> LayoutUnit {
    assert(isPlaced)
    return m_frameRect.y()
  }

  func maxY() -> LayoutUnit {
    assert(isPlaced)
    return m_frameRect.maxY()
  }

  func width() -> LayoutUnit { return m_frameRect.width() }

  func height() -> LayoutUnit { return m_frameRect.height() }

  func setX(x: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    m_frameRect.setX(x: x)
  }

  func setY(y: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    m_frameRect.setY(y: y)
  }

  func setWidth(width: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    m_frameRect.setWidth(width: width)
  }

  func setHeight(height: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    m_frameRect.setHeight(height: height)
  }

  func setMarginOffset(offset: LayoutSizeWrapper) {
    wk_interop.FloatingObject_setMarginOffset(
      p!, offset.width().rawValue(), offset.height().rawValue())
  }

  func frameRect() -> LayoutRectWrapper {
    assert(isPlaced)
    return m_frameRect
  }

  func setFrameRect(frameRect: LayoutRectWrapper) {
    wk_interop.FloatingObject_setFrameRect(
      p!, m_frameRect.x().rawValue(), m_frameRect.y().rawValue(),
      m_frameRect.width().rawValue(),
      m_frameRect.height().rawValue())
  }

  func setPaginationStrut(strut: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldPaint() -> Bool {
    assert(isNativeImpl())
    if renderer == nil {
      return false
    }

    return !renderer!.hasSelfPaintingLayer() && m_paintsFloat
  }

  func paintsFloat() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPaintsFloat(paintsFloat: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAncestorWithOverflowClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isDescendant() -> Bool {
    assert(isNativeImpl())
    return m_isDescendant
  }

  private func setIsDescendant(_ isDescendant: Bool) {
    assert(isNativeImpl())
    m_isDescendant = isDescendant
  }

  func locationOffsetOfBorderBox() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func translationOffsetToAncestor() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalRightOffsetForPositioningFloat(
    fixedOffset: LayoutUnit, logicalTop: LayoutUnit, heightRemaining: inout LayoutUnit
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginOffset() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    assert(isPlaced)
    return m_marginOffset
  }

  private func isNativeImpl() -> Bool { return p == nil }

  var renderer: RenderBoxWrapper? = nil
  var m_frameRect = LayoutRectWrapper()
  private let m_marginOffset: LayoutSizeWrapper
  let type: Type_  // Type (left or right aligned)
  private let m_paintsFloat: Bool
  private var m_isDescendant = false
  let isPlaced: Bool
  private let m_hasAncestorWithOverflowClip: Bool
  #if ASSERT_ENABLED
    var isInPlacedTree = false
  #endif
  private var p: UnsafeMutableRawPointer?
}

// FIXME: This is really the same thing as FloatingObjectSet.
// Change clients to use that set directly, and replace the moveAllToFloatInfoMap function with a takeSet function.
class FloatingObjects {
  init(_ renderer: RenderBlockFlowWrapper) {
    m_horizontalWritingMode = renderer.isHorizontalWritingMode()
    m_renderer = renderer
  }

  func clear() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func add(floatingObject: FloatingObjectWrapper) -> FloatingObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addPlacedObject(_ floatingObject: FloatingObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHorizontalWritingMode(b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasLeftObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasRightObjects() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func set() -> FloatingObjectSet { return m_set }

  func logicalLeftOffsetForPositioningFloat(
    fixedOffset: LayoutUnit, logicalTop: LayoutUnit, heightRemaining: inout LayoutUnit
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalRightOffsetForPositioningFloat(
    fixedOffset: LayoutUnit, logicalTop: LayoutUnit, heightRemaining: inout LayoutUnit
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shiftFloatsBy(blockShift: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_set = FloatingObjectSet()
  private let m_horizontalWritingMode: Bool
  private let m_renderer: RenderBlockFlowWrapper
}
