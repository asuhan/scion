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

// TODO(asuhan): replace with native implementation
class FloatingObjectSetIterator: IteratorProtocol, Equatable {
  init(_ p: UnsafeMutableRawPointer) { self.p = p }

  deinit { wk_interop.FloatingObjectSetIterator_destroy(p) }

  func next() -> FloatingObjectWrapper? {
    if wk_interop.FloatingObjectSetIterator_atEnd(p) {
      return nil
    }
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

// TODO(asuhan): replace with native implementation
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

  func add(_ floating: FloatingObjectWrapper) {
    let unmanaged = Unmanaged.passRetained(floating)
    wk_interop.FloatingObjectSet_add(p, unmanaged.toOpaque())
  }

  func clear() { wk_interop.FloatingObjectSet_clear(p) }

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
    m_paintsFloat = true
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
    assert(isNativeImpl())
    let cloneObject = FloatingObjectWrapper(
      renderer!, type, m_frameRect, m_marginOffset, shouldPaint: m_paintsFloat,
      isDescendant: m_isDescendant, overflowClipped: m_hasAncestorWithOverflowClip)
    cloneObject.m_paginationStrut = m_paginationStrut
    cloneObject.isPlaced = isPlaced
    return cloneObject
  }

  func setIsPlaced(placed: Bool) {
    if !isNativeImpl() {
      wk_interop.FloatingObject_setIsPlaced(p!, placed)
      return
    }
    self.isPlaced = placed
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
    if !isNativeImpl() {
      wk_interop.FloatingObject_setMarginOffset(
        p!, offset.width().rawValue(), offset.height().rawValue())
      return
    }
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    m_marginOffset = offset
  }

  func frameRect() -> LayoutRectWrapper {
    assert(isPlaced)
    return m_frameRect
  }

  func setFrameRect(frameRect: LayoutRectWrapper) {
    if !isNativeImpl() {
      wk_interop.FloatingObject_setFrameRect(
        p!, m_frameRect.x().rawValue(), m_frameRect.y().rawValue(),
        m_frameRect.width().rawValue(),
        m_frameRect.height().rawValue())
      return
    }
    #if ASSERT_ENABLED
      assert(!isInPlacedTree)
    #endif
    m_frameRect = frameRect
  }

  func setPaginationStrut(strut: LayoutUnit) {
    assert(isNativeImpl())
    m_paginationStrut = strut
  }

  func shouldPaint() -> Bool {
    assert(isNativeImpl())
    if renderer == nil {
      return false
    }

    return !renderer!.hasSelfPaintingLayer() && m_paintsFloat
  }

  func paintsFloat() -> Bool {
    assert(isNativeImpl())
    return m_paintsFloat
  }

  func setPaintsFloat(paintsFloat: Bool) {
    assert(isNativeImpl())
    m_paintsFloat = paintsFloat
  }

  func hasAncestorWithOverflowClip() -> Bool {
    assert(isNativeImpl())
    return m_hasAncestorWithOverflowClip
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
    assert(isNativeImpl())
    assert(isPlaced)
    return LayoutSizeWrapper(
      width: m_frameRect.location().x + m_marginOffset.width(),
      height: m_frameRect.location().y + m_marginOffset.height())
  }

  func translationOffsetToAncestor() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    return locationOffsetOfBorderBox() - renderer!.locationOffset()
  }

  func marginOffset() -> LayoutSizeWrapper {
    assert(isNativeImpl())
    assert(isPlaced)
    return m_marginOffset
  }

  private func isNativeImpl() -> Bool { return p == nil }

  var renderer: RenderBoxWrapper? = nil
  var m_frameRect = LayoutRectWrapper()
  private var m_paginationStrut = LayoutUnit()
  private var m_marginOffset: LayoutSizeWrapper
  let type: Type_  // Type (left or right aligned)
  private var m_paintsFloat: Bool
  private var m_isDescendant = false
  var isPlaced: Bool
  private let m_hasAncestorWithOverflowClip: Bool
  #if ASSERT_ENABLED
    var isInPlacedTree = false
  #endif
  private var p: UnsafeMutableRawPointer?
}

struct FloatingObjectInterval {
  let low: Int32
  let high: Int32
  let obj: UnsafeMutableRawPointer
}

// TODO(asuhan): replace with native implementation using red-black trees.
class FloatingObjectTreeWrapper {
  init() { p = wk_interop.FloatingObjectTree_create() }

  deinit { wk_interop.FloatingObjectTree_destroy(p) }

  func add(_ interval: FloatingObjectInterval) {
    wk_interop.FloatingObjectTree_add(p, interval.low, interval.high, interval.obj)
  }

  func allOverlapsWithAdapter(_ adapter: ComputeFloatOffsetForFloatLayoutAdapter) {
    let unmanaged = Unmanaged.passUnretained(adapter)
    wk_interop.FloatingObjectTree_allOverlapsWithAdapter(p, unmanaged.toOpaque())
  }

  func allOverlapsWithAdapter(_ adapter: FindNextFloatLogicalBottomAdapter) {
    let unmanaged = Unmanaged.passUnretained(adapter)
    wk_interop.FloatingObjectTree_allOverlapsWithFindNextFloatLogicalBottomAdapter(
      p, unmanaged.toOpaque())
  }

  private let p: UnsafeMutableRawPointer
}

private func rangesIntersect(
  floatTop: LayoutUnit, floatBottom: LayoutUnit, objectTop: LayoutUnit, objectBottom: LayoutUnit
) -> Bool {
  if objectTop >= floatBottom || objectBottom < floatTop {
    return false
  }

  // The top of the object overlaps the float
  if objectTop >= floatTop {
    return true
  }

  // The object encloses the float
  if objectTop < floatTop && objectBottom > floatBottom {
    return true
  }

  // The bottom of the object overlaps the float
  if objectBottom > objectTop && objectBottom > floatTop && objectBottom <= floatBottom {
    return true
  }

  return false
}

class ComputeFloatOffsetAdapter {
  init(
    _ type: FloatingObjectWrapper.Type_, _ renderer: RenderBlockFlowWrapper, lineTop: LayoutUnit,
    lineBottom: LayoutUnit, offset: LayoutUnit
  ) {
    m_renderer = renderer
    m_lineTop = lineTop
    m_lineBottom = lineBottom
    m_offset = offset
    m_outermostFloat = nil
    m_type = type
  }

  func lowValue() -> LayoutUnit { return m_lineTop }

  func highValue() -> LayoutUnit { return m_lineBottom }

  func collectIfNeeded(_ interval: FloatingObjectInterval) {
    let floatingObject = Unmanaged<FloatingObjectWrapper>.fromOpaque(interval.obj)
      .takeUnretainedValue()
    if floatingObject.type != m_type || !floatingObject.height().bool()
      || !rangesIntersect(
        floatTop: LayoutUnit(value: interval.low), floatBottom: LayoutUnit(value: interval.high),
        objectTop: m_lineTop,
        objectBottom: m_lineBottom)
    {
      return
    }

    // All the objects returned from the tree should be already placed.
    assert(floatingObject.isPlaced)
    // FIXME: Remove floor(). See <https://webkit.org/b/125831>.
    assert(
      rangesIntersect(
        floatTop: LayoutUnit(
          value: m_renderer.logicalTopForFloat(floatingObject: floatingObject).floor()),
        floatBottom: LayoutUnit(
          value: m_renderer.logicalBottomForFloat(floatingObject: floatingObject).floor()),
        objectTop: m_lineTop,
        objectBottom: m_lineBottom))

    let floatIsNewExtreme = updateOffsetIfNeeded(floatingObject)
    if floatIsNewExtreme {
      m_outermostFloat = floatingObject
    }
  }

  func offset() -> LayoutUnit { return m_offset }

  func updateOffsetIfNeeded(_ floatingObject: FloatingObjectWrapper) -> Bool {
    fatalError("Not reached")
  }

  let m_renderer: RenderBlockFlowWrapper
  let m_lineTop: LayoutUnit
  private let m_lineBottom: LayoutUnit
  var m_offset: LayoutUnit
  var m_outermostFloat: FloatingObjectWrapper?
  let m_type: FloatingObjectWrapper.Type_
}

final class ComputeFloatOffsetForFloatLayoutAdapter: ComputeFloatOffsetAdapter {
  override init(
    _ type: FloatingObjectWrapper.Type_, _ renderer: RenderBlockFlowWrapper, lineTop: LayoutUnit,
    lineBottom: LayoutUnit, offset: LayoutUnit
  ) {
    super.init(type, renderer, lineTop: lineTop, lineBottom: lineBottom, offset: offset)
  }

  func heightRemaining() -> LayoutUnit {
    return m_outermostFloat != nil
      ? m_renderer.logicalBottomForFloat(floatingObject: m_outermostFloat!) - m_lineTop
      : LayoutUnit(value: UInt64(1))
  }

  override func updateOffsetIfNeeded(_ floatingObject: FloatingObjectWrapper) -> Bool {
    m_type == .FloatLeft
      ? updateOffsetIfNeededLeft(floatingObject) : updateOffsetIfNeededRight(floatingObject)
  }

  private func updateOffsetIfNeededLeft(_ floatingObject: FloatingObjectWrapper) -> Bool {
    let logicalRight = m_renderer.logicalRightForFloat(floatingObject)
    if logicalRight > m_offset {
      m_offset = logicalRight
      return true
    }
    return false
  }

  private func updateOffsetIfNeededRight(_ floatingObject: FloatingObjectWrapper) -> Bool {
    let logicalLeft = m_renderer.logicalLeftForFloat(floatingObject)
    if logicalLeft < m_offset {
      m_offset = logicalLeft
      return true
    }
    return false
  }
}

final class FindNextFloatLogicalBottomAdapter {
  init(_ renderer: RenderBlockFlowWrapper, _ belowLogicalHeight: LayoutUnit) {
    m_renderer = renderer
    m_belowLogicalHeight = belowLogicalHeight
  }

  func lowValue() -> LayoutUnit { return m_belowLogicalHeight }

  func highValue() -> LayoutUnit { return LayoutUnit.max() }

  func collectIfNeeded(_ interval: FloatingObjectInterval) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextLogicalBottom() -> LayoutUnit { return m_nextLogicalBottom ?? LayoutUnit(value: 0) }

  private let m_renderer: RenderBlockFlowWrapper
  private let m_belowLogicalHeight: LayoutUnit
  private let m_nextLogicalBottom: LayoutUnit? = nil
}

// FIXME: This is really the same thing as FloatingObjectSet.
// Change clients to use that set directly, and replace the moveAllToFloatInfoMap function with a takeSet function.
class FloatingObjects {
  init(_ renderer: RenderBlockFlowWrapper) {
    m_horizontalWritingMode = renderer.isHorizontalWritingMode()
    m_renderer = renderer
  }

  func clear() {
    m_set.clear()
    m_placedFloatsTree = nil
    m_leftObjectsCount = 0
    m_rightObjectsCount = 0
  }

  @discardableResult
  func add(floatingObject: FloatingObjectWrapper) -> FloatingObjectWrapper? {
    increaseObjectsCount(floatingObject.type)
    if floatingObject.isPlaced {
      addPlacedObject(floatingObject)
    }
    m_set.add(floatingObject)
    return floatingObject
  }

  func addPlacedObject(_ floatingObject: FloatingObjectWrapper) {
    #if ASSERT_ENABLED
      assert(!floatingObject.isInPlacedTree)
    #endif

    floatingObject.setIsPlaced(placed: true)
    if m_placedFloatsTree != nil {
      m_placedFloatsTree!.add(intervalForFloatingObject(floatingObject))
      #if ASSERT_ENABLED
        floatingObject.isInPlacedTree = true
      #endif
    }
  }

  func setHorizontalWritingMode(b: Bool = true) { m_horizontalWritingMode = b }

  func hasLeftObjects() -> Bool { return m_leftObjectsCount > 0 }

  func hasRightObjects() -> Bool { return m_rightObjectsCount > 0 }

  func set() -> FloatingObjectSet { return m_set }

  func logicalLeftOffsetForPositioningFloat(
    fixedOffset: LayoutUnit, logicalTop: LayoutUnit, heightRemaining: inout LayoutUnit
  ) -> LayoutUnit {
    let adapter = ComputeFloatOffsetForFloatLayoutAdapter(
      .FloatLeft, m_renderer, lineTop: logicalTop, lineBottom: logicalTop, offset: fixedOffset)
    if let placedFloatsTree = self.placedFloatsTree() {
      placedFloatsTree.allOverlapsWithAdapter(adapter)
    }

    heightRemaining = adapter.heightRemaining()

    return adapter.offset()
  }

  func logicalRightOffsetForPositioningFloat(
    fixedOffset: LayoutUnit, logicalTop: LayoutUnit, heightRemaining: inout LayoutUnit
  ) -> LayoutUnit {
    let adapter = ComputeFloatOffsetForFloatLayoutAdapter(
      .FloatRight, m_renderer, lineTop: logicalTop, lineBottom: logicalTop, offset: fixedOffset)
    if let placedFloatsTree = self.placedFloatsTree() {
      placedFloatsTree.allOverlapsWithAdapter(adapter)
    }

    heightRemaining = adapter.heightRemaining()

    return min(fixedOffset, adapter.offset())
  }

  func findNextFloatLogicalBottomBelowForBlock(_ logicalHeight: LayoutUnit) -> LayoutUnit {
    let adapter = FindNextFloatLogicalBottomAdapter(m_renderer, logicalHeight)
    if let placedFloatsTree = placedFloatsTree() {
      placedFloatsTree.allOverlapsWithAdapter(adapter)
    }

    return adapter.nextLogicalBottom()
  }

  func shiftFloatsBy(blockShift: LayoutUnit) {
    let shiftX = m_horizontalWritingMode ? LayoutUnit(value: UInt64(0)) : -blockShift
    let shiftY = m_horizontalWritingMode ? blockShift : LayoutUnit(value: UInt64(0))

    for floater in m_set {
      floater.m_frameRect.move(dx: shiftX, dy: shiftY)
      floater.renderer!.move(dx: shiftX, dy: shiftY)
    }
  }

  private func computePlacedFloatsTree() {
    assert(m_placedFloatsTree == nil)
    if m_set.isEmpty() {
      return
    }

    m_placedFloatsTree = FloatingObjectTreeWrapper()
    for floatingObject in m_set {
      if floatingObject.isPlaced {
        m_placedFloatsTree!.add(intervalForFloatingObject(floatingObject))
      }
    }
  }

  private func placedFloatsTree() -> FloatingObjectTreeWrapper? {
    if m_placedFloatsTree == nil {
      computePlacedFloatsTree()
    }
    return m_placedFloatsTree
  }

  private func increaseObjectsCount(_ type: FloatingObjectWrapper.Type_) {
    if type == .FloatLeft {
      m_leftObjectsCount += 1
    } else {
      m_rightObjectsCount += 1
    }
  }

  private func intervalForFloatingObject(_ floatingObject: FloatingObjectWrapper)
    -> FloatingObjectInterval
  {
    let unmanaged = Unmanaged.passUnretained(floatingObject)
    // FIXME: The endpoints of the floating object interval shouldn't need to be
    // floored. See <https://webkit.org/b/125831> for more details.
    if m_horizontalWritingMode {
      return FloatingObjectInterval(
        low: floatingObject.frameRect().y().floor(),
        high: floatingObject.frameRect().maxY().floor(), obj: unmanaged.toOpaque())
    }
    return FloatingObjectInterval(
      low: floatingObject.frameRect().x().floor(), high: floatingObject.frameRect().maxX().floor(),
      obj: unmanaged.toOpaque())
  }

  private let m_set = FloatingObjectSet()
  private var m_placedFloatsTree: FloatingObjectTreeWrapper? = nil
  private var m_leftObjectsCount: UInt32 = 0
  private var m_rightObjectsCount: UInt32 = 0
  private var m_horizontalWritingMode: Bool
  private let m_renderer: RenderBlockFlowWrapper
}
