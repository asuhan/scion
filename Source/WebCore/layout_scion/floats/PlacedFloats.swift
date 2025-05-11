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

// PlacedFloats holds the floating boxes for BFC/IFC using the BFC's writing mode.
// PlacedFloats may be inherited by IFCs with mismataching writing mode. In such cases floats
// are added to PlacledFloats as if they had matching inline direction (i.e. all boxes within PlacedFloats share the same writing mode)
class PlacedFloats {
  init(blockFormattingContextRoot: ElementBoxWrapper) {
    // TODO(asuhan): implement this
    self.blockFormattingContextRoot = blockFormattingContextRoot
    self.isLeftToRightDirection = blockFormattingContextRoot.style.isLeftToRightDirection()
    // assert(blockFormattingContextRoot.establishesBlockFormattingContext())
  }

  func formattingContextRoot() -> ElementBoxWrapper {
    return blockFormattingContextRoot
  }

  struct Item {
    // FIXME: This c'tor is only used by the render tree integation codepath.
    enum Position: UInt8 {
      case Left
      case Right
    }

    init(
      position: Position, absoluteBoxGeometry: BoxGeometry, localTopLeft: LayoutPointWrapper,
      shape: ShapeWrapper?
    ) {
      self.position = position
      self.absoluteBoxGeometry = absoluteBoxGeometry
      self.localTopLeft = localTopLeft
      self.m_shape = shape
    }

    init(
      layoutBox: BoxWrapper, position: Position, absoluteBoxGeometry: BoxGeometry,
      localTopLeft: LayoutPointWrapper, line: UInt64?
    ) {
      self.m_layoutBox = layoutBox
      self.position = position
      self.absoluteBoxGeometry = absoluteBoxGeometry
      self.localTopLeft = localTopLeft
      self.m_shape = layoutBox.shape()
      self.placedByLine = line
    }

    func isLeftPositioned() -> Bool {
      return position == .Left
    }

    func boxGeometry() -> BoxGeometry {
      let boxGeometry = absoluteBoxGeometry
      boxGeometry.setTopLeft(topLeft: localTopLeft)
      return boxGeometry
    }

    func absoluteRectWithMargin() -> Rect {
      return BoxGeometry.marginBoxRect(box: absoluteBoxGeometry)
    }

    func absoluteBorderBoxRect() -> Rect {
      return BoxGeometry.borderBoxRect(box: absoluteBoxGeometry)
    }

    func horizontalMargin() -> BoxGeometry.HorizontalEdges {
      return absoluteBoxGeometry.horizontalMargin()
    }

    func absoluteBottom() -> PositionInContextRoot {
      return PositionInContextRoot(value: absoluteRectWithMargin().bottom())
    }

    func shape() -> ShapeWrapper? { return m_shape }

    func layoutBox() -> BoxWrapper? { return m_layoutBox }

    var m_layoutBox: BoxWrapper? = nil
    private var position: Position
    private var absoluteBoxGeometry: BoxGeometry
    private var localTopLeft: LayoutPointWrapper
    private var m_shape: ShapeWrapper?
    var placedByLine: UInt64?
  }
  typealias List = [Item]

  func last() -> Item? { return list.isEmpty ? nil : list.last }

  func append(newFloatItem: Item) {
    // TODO(asuhan): implement this
    let isLeftPositioned = newFloatItem.isLeftPositioned()
    positionTypes = positionTypes.union(isLeftPositioned ? .Left : .Right)

    if list.isEmpty {
      return list.append(newFloatItem)
    }

    // TODO(asuhan): add missing assertion

    // When adding a new float item to the list, we have to ensure that it is definitely the left(right)-most item.
    // Normally it is, but negative horizontal margins can push the float box beyond another float box.
    // Float items in m_list list should stay in horizontal position order (left/right edge) on the same vertical position.
    let horizontalMargin = newFloatItem.horizontalMargin()
    let hasNegativeHorizontalMargin =
      (isLeftPositioned && horizontalMargin.start < 0)
      || (!isLeftPositioned && horizontalMargin.end < 0)
    if !hasNegativeHorizontalMargin {
      return list.append(newFloatItem)
    }

    for (i, floatItem) in list.enumerated().reversed() {
      if isLeftPositioned != floatItem.isLeftPositioned() {
        continue
      }

      if isHorizontallyOrdered(
        isLeftPositioned: isLeftPositioned, newFloatItem: newFloatItem, floatItem: floatItem)
      {
        return list.insert(newFloatItem, at: i + 1)
      }
    }
    list.insert(newFloatItem, at: 0)
  }

  func isHorizontallyOrdered(isLeftPositioned: Bool, newFloatItem: Item, floatItem: Item) -> Bool {
    if newFloatItem.absoluteRectWithMargin().top() > floatItem.absoluteRectWithMargin().top() {
      // There's no more floats on this vertical position.
      return true
    }
    return
      (isLeftPositioned
      && newFloatItem.absoluteRectWithMargin().right() >= floatItem.absoluteRectWithMargin().right())
      || (!isLeftPositioned
        && newFloatItem.absoluteRectWithMargin().left() <= floatItem.absoluteRectWithMargin().left())
  }

  func remove(floatBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clear() {
    list.removeAll()
    positionTypes = PositionType()
  }

  func isEmpty() -> Bool {
    return list.isEmpty
  }

  func hasLeftPositioned() -> Bool {
    return positionTypes.contains(.Left)
  }

  func hasRightPositioned() -> Bool {
    return positionTypes.contains(.Right)
  }

  // FIXME: This should always be placedFloats's root().style().isLeftToRightDirection() if we used the actual containing block of the intrusive
  // floats to initiate the floating state in the integration codepath (i.e. when the float comes from the parent BFC).
  func setIsLeftToRightDirection(isLeftToRightDirection: Bool) {
    self.isLeftToRightDirection = isLeftToRightDirection
  }

  var blockFormattingContextRoot: ElementBoxWrapper
  var list = List()
  struct PositionType: OptionSet {
    let rawValue: UInt8
    static let Left = PositionType(rawValue: 1 << 0)
    static let Right = PositionType(rawValue: 1 << 1)
  }
  var positionTypes = PositionType()
  var isLeftToRightDirection = false
}
