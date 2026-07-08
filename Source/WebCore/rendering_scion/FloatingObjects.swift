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

typealias FloatingObjectSet = ListHashSet<FloatingObjectWrapper>

class FloatingObjectWrapper: Hashable {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
    type = .FloatLeft
    m_hasAncestorWithOverflowClip = false
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
  }

  static func == (lhs: FloatingObjectWrapper, rhs: FloatingObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hash(into hasher: inout Hasher) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    return frameRect.x()
  }

  func maxX() -> LayoutUnit {
    assert(isPlaced)
    return frameRect.maxX()
  }

  func y() -> LayoutUnit {
    assert(isPlaced)
    return frameRect.y()
  }

  func maxY() -> LayoutUnit {
    assert(isPlaced)
    return frameRect.maxY()
  }

  func width() -> LayoutUnit { return frameRect.width() }

  func height() -> LayoutUnit { return frameRect.height() }

  func setX(x: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    frameRect.setX(x: x)
  }

  func setY(y: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    frameRect.setY(y: y)
  }

  func setWidth(width: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    frameRect.setWidth(width: width)
  }

  func setHeight(height: LayoutUnit) {
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    frameRect.setHeight(height: height)
  }

  func setMarginOffset(offset: LayoutSizeWrapper) {
    wk_interop.FloatingObject_setMarginOffset(
      p!, offset.width().rawValue(), offset.height().rawValue())
  }

  func setFrameRect(frameRect: LayoutRectWrapper) {
    wk_interop.FloatingObject_setFrameRect(
      p!, frameRect.x().rawValue(), frameRect.y().rawValue(),
      frameRect.width().rawValue(),
      frameRect.height().rawValue())
  }

  func setPaginationStrut(strut: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldPaint() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func isNativeImpl() -> Bool { return p == nil }

  var renderer: RenderBoxWrapper? = nil
  var frameRect = LayoutRectWrapper()
  let type: Type_  // Type (left or right aligned)
  private var m_isDescendant = false
  let isPlaced = false
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
