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

prefix operator *

func previousFloatingIndex(floatingType: Float, floats: PlacedFloats.List, currentIndex: UInt32)
  -> UInt32?
{
  assert(currentIndex <= floats.count)

  var currentIndexMutable = currentIndex
  while currentIndexMutable != 0 {
    currentIndexMutable -= 1
    let floating = floats[Int(currentIndexMutable)]
    if (floatingType == .Left && floating.isLeftPositioned())
      || (floatingType == .Right && !floating.isLeftPositioned())
    {
      return currentIndexMutable
    }
  }

  return nil
}

class Iterator {
  init(floats: PlacedFloats.List, verticalPosition: PositionInContextRoot?) {
    self.floats = floats
    self.current = FloatPair(floats: floats)
    if verticalPosition != nil {
      set(verticalPosition: verticalPosition!)
    }
  }

  @discardableResult
  prefix static func ++ (iterator: Iterator) -> Iterator {
    if iterator.current.isEmpty() {
      fatalError("Not reached")
    }

    // 1. Take the current floating from left and right and check which one's bottom edge is positioned higher (they could be on the same vertical position too).
    // The current floats from left and right are considered the inner-most pair for the current vertical position.
    // 2. Move away from inner-most pair by picking one of the previous floats in the list(#1)
    // Ensure that the new floating bottom edge is positioned lower than the current one -which essentially means skipping in-between floats that are positioned higher).
    // 3. Reset the vertical position and align it with the new left-right pair. These floats are now the inner-most boxes for the current vertical position.
    // As the result we have more horizontal space on the current vertical position.
    let leftBottom =
      iterator.current.left() != nil ? iterator.current.left()!.absoluteBottom() : nil
    let rightBottom =
      iterator.current.right() != nil ? iterator.current.right()!.absoluteBottom() : nil

    let updateLeft =
      (leftBottom == rightBottom)
      || (rightBottom == nil || (leftBottom != nil && leftBottom! < rightBottom!))
    let updateRight =
      (leftBottom == rightBottom)
      || (leftBottom == nil || (rightBottom != nil && leftBottom! > rightBottom!))

    if updateLeft {
      assert(iterator.current.floatPair.left != nil)
      iterator.current.verticalPosition = leftBottom!
      iterator.current.floatPair.left = iterator.findPreviousFloatingWithLowerBottom(
        floatingType: .Left, currentIndex: iterator.current.floatPair.left!)
    }

    if updateRight {
      assert(iterator.current.floatPair.right != nil)
      iterator.current.verticalPosition = rightBottom!
      iterator.current.floatPair.right = iterator.findPreviousFloatingWithLowerBottom(
        floatingType: .Right, currentIndex: iterator.current.floatPair.right!)
    }

    return iterator
  }

  private func findPreviousFloatingWithLowerBottom(floatingType: Float, currentIndex: UInt32)
    -> UInt32?
  {
    assert(currentIndex < floats.count)

    // Last floating? There's certainly no previous floating at this point.
    if currentIndex == 0 {
      return nil
    }

    let currentBottom = floats[Int(currentIndex)].absoluteRectWithMargin().bottom()

    var index: UInt32? = currentIndex
    while true {
      index = previousFloatingIndex(
        floatingType: floatingType, floats: floats, currentIndex: index!)
      if index == nil {
        return nil
      }

      if floats[Int(index!)].absoluteRectWithMargin().bottom() > currentBottom {
        return index
      }
    }

    fatalError("Not reached")
  }

  prefix static func * (iterator: Iterator) -> FloatPair { return iterator.current }

  static func == (this: Iterator, other: Iterator) -> Bool { return this.current == other.current }

  static func != (this: Iterator, other: Iterator) -> Bool { return !(this == other) }

  private func set(verticalPosition: PositionInContextRoot) {
    // Move the iterator to the initial vertical position by starting at the inner-most floating pair (last floats on left/right).
    // 1. Check if the inner-most pair covers the vertical position.
    // 2. Move outwards from the inner-most pair until the vertical position intersects.
    current.verticalPosition = verticalPosition
    // No floats at all?
    if floats.isEmpty {
      fatalError("Not reached")
    }

    current.floatPair.left = findFloatingBelow(
      floatingType: .Left, verticalPosition: verticalPosition)
    current.floatPair.right = findFloatingBelow(
      floatingType: .Right, verticalPosition: verticalPosition)

    assert(
      current.floatPair.left == nil
        || (current.floatPair.left! < floats.count
          && floats[Int(current.floatPair.left!)].isLeftPositioned())
    )
    assert(
      current.floatPair.right == nil
        || (current.floatPair.right! < floats.count
          && !floats[Int(current.floatPair.right!)].isLeftPositioned())
    )
  }

  private func findFloatingBelow(floatingType: Float, verticalPosition: PositionInContextRoot)
    -> UInt32?
  {
    assert(!floats.isEmpty)

    var index = floatingType == .Left ? current.floatPair.left : current.floatPair.right
    // Start from the end if we don't have current yet.
    index = index ?? UInt32(floats.count)
    while true {
      index = previousFloatingIndex(
        floatingType: floatingType, floats: floats, currentIndex: index!)
      if index == nil {
        return nil
      }

      // Is this floating intrusive on this position?
      let rect = floats[Int(index!)].absoluteRectWithMargin()
      if rect.top() <= verticalPosition.toLayoutUnit()
        && rect.bottom() > verticalPosition.toLayoutUnit()
      {
        return index
      }
    }
  }

  private var floats: PlacedFloats.List
  private var current: FloatPair
}

func begin(floats: PlacedFloats.List, initialVerticalPosition: PositionInContextRoot) -> Iterator {
  // Start with the inner-most floating pair for the initial vertical position.
  return Iterator(floats: floats, verticalPosition: initialVerticalPosition)
}

func end(floats: PlacedFloats.List) -> Iterator {
  return Iterator(floats: floats, verticalPosition: nil)
}

func areFloatsHorizontallySorted(placedFloats: PlacedFloats) -> Bool {
  // TODO(asuhan): implement this
  return true
}

// FloatingContext is responsible for adjusting the position of a box in the current formatting context
// by taking the floating boxes into account.
// Note that a FloatingContext's inline direction always matches the root's inline direction but it may
// not match the PlacedFloats's inline direction (i.e. PlacedFloats may be constructed by a parent BFC with mismatching inline direction).
class FloatingContext {
  init(
    formattingContextRoot: ElementBoxWrapper, layoutState: LayoutStateWrapper,
    placedFloats: PlacedFloats
  ) {
    self.formattingContextRoot = formattingContextRoot
    self.layoutState = layoutState
    self.placedFloats = placedFloats
  }

  func positionForFloat(
    layoutBox: BoxWrapper, boxGeometry: BoxGeometry, horizontalConstraints: HorizontalConstraints
  ) -> LayoutPointWrapper {
    assert(layoutBox.isFloatingPositioned())
    assert(areFloatsHorizontallySorted(placedFloats: placedFloats))
    let borderBoxTopLeft = BoxGeometry.borderBoxTopLeft(box: boxGeometry)

    if isEmpty() {
      return LayoutPointWrapper(
        x: alignWithContainingBlock(
          layoutBox: layoutBox, boxGeometry: boxGeometry,
          horizontalConstraints: horizontalConstraints
        ).toLayoutUnit(),
        y: borderBoxTopLeft.y
      )
    }

    // Find the top most position where the float box fits.
    assert(!isEmpty())

    let absoluteCoordinates = absoluteCoordinates(
      floatAvoider: layoutBox, borderBoxTopLeft: borderBoxTopLeft)
    var absoluteTopLeft = absoluteCoordinates.topLeft
    var verticalPositionCandidate = absoluteTopLeft.y
    // Incoming float cannot be placed higher than existing floats (margin box of the last float).
    // Take the static position (where the box would go if it wasn't floating) and adjust it with the last float.
    let lastFloatAbsoluteTop = placedFloats.last()!.absoluteRectWithMargin().top()
    let lastOrClearedFloatPosition = max(
      clearPosition(layoutBox: layoutBox) ?? lastFloatAbsoluteTop, lastFloatAbsoluteTop)
    if verticalPositionCandidate - boxGeometry.marginBefore() < lastOrClearedFloatPosition {
      verticalPositionCandidate = lastOrClearedFloatPosition + boxGeometry.marginBefore()
    }

    absoluteTopLeft.setY(y: verticalPositionCandidate)
    let margins = BoxGeometry.Edges(
      horizontal: BoxGeometry.HorizontalEdges(
        start: boxGeometry.marginStart(),
        end: boxGeometry.marginEnd()
      ),
      vertical: BoxGeometry.VerticalEdges(
        before: boxGeometry.marginBefore(),
        after: boxGeometry.marginAfter()
      )
    )
    var floatBox = FloatAvoider(
      absoluteTopLeft: absoluteTopLeft, borderBoxWidth: boxGeometry.borderBoxWidth(),
      margin: margins,
      containingBlockAbsoluteContentBox: absoluteCoordinates.containingBlockContentBox,
      isFloatingPositioned: true,
      isLeftAligned: isFloatingCandidateLeftPositionedInPlacedFloats(floatBox: layoutBox))
    findAvailablePosition(
      floatAvoider: &floatBox, floats: placedFloats.list,
      containingBlockContentBoxEdges: absoluteCoordinates.containingBlockContentBox)
    // Convert box coordinates from formatting root back to containing block.
    let containingBlockTopLeft = absoluteCoordinates.containingBlockTopLeft
    return LayoutPointWrapper(
      x: floatBox.left() + margins.horizontal.start - containingBlockTopLeft.x,
      y: floatBox.top() + margins.vertical.before - containingBlockTopLeft.y)
  }

  func positionForNonFloatingFloatAvoider(layoutBox: BoxWrapper, boxGeometry: BoxGeometry)
    -> LayoutPointWrapper
  {
    assert(layoutBox.establishesBlockFormattingContext())
    assert(!layoutBox.isFloatingPositioned())
    assert(!layoutBox.hasFloatClear())
    assert(areFloatsHorizontallySorted(placedFloats: placedFloats))

    let borderBoxTopLeft = BoxGeometry.borderBoxTopLeft(box: boxGeometry)
    if isEmpty() {
      return borderBoxTopLeft
    }

    let absoluteCoordinates = absoluteCoordinates(
      floatAvoider: layoutBox, borderBoxTopLeft: borderBoxTopLeft)
    let margins = BoxGeometry.Edges(
      horizontal: BoxGeometry.HorizontalEdges(
        start: boxGeometry.marginStart(), end: boxGeometry.marginEnd()),
      vertical: BoxGeometry.VerticalEdges(
        before: boxGeometry.marginBefore(), after: boxGeometry.marginAfter())
    )
    var floatAvoider = FloatAvoider(
      absoluteTopLeft: absoluteCoordinates.topLeft, borderBoxWidth: boxGeometry.borderBoxWidth(),
      margin: margins,
      containingBlockAbsoluteContentBox: absoluteCoordinates.containingBlockContentBox,
      isFloatingPositioned: false,
      isLeftAligned: layoutBox.style.isLeftToRightDirection())
    findPositionForFormattingContextRoot(
      floatAvoider: &floatAvoider,
      containingBlockContentBoxEdges: absoluteCoordinates.containingBlockContentBox)
    let containingBlockTopLeft = absoluteCoordinates.containingBlockTopLeft
    return LayoutPointWrapper(
      x: floatAvoider.left() - containingBlockTopLeft.x,
      y: floatAvoider.top() - containingBlockTopLeft.y)
  }

  private func clearPosition(layoutBox: BoxWrapper) -> LayoutUnit? {
    if !layoutBox.hasFloatClear() {
      return nil
    }
    // The vertical position candidate needs to clear the existing floats in this context.
    switch clearInPlacedFloats(clearBox: layoutBox) {
    case .Left:
      return leftBottom()
    case .Right:
      return rightBottom()
    case .Both:
      return bottom()
    default:
      fatalError("Not reached")
    }
  }

  private func alignWithContainingBlock(
    layoutBox: BoxWrapper, boxGeometry: BoxGeometry, horizontalConstraints: HorizontalConstraints
  ) -> Position {
    // If there is no floating to align with, push the box to the left/right edge of its containing block's content box.
    if isFloatingCandidateLeftPositionedInPlacedFloats(floatBox: layoutBox) {
      return Position(value: horizontalConstraints.logicalLeft + boxGeometry.marginStart())
    }
    return Position(
      value: horizontalConstraints.logicalRight() - boxGeometry.marginEnd()
        - boxGeometry.borderBoxWidth())
  }

  struct PositionWithClearance {
    var position = LayoutUnit()
    var clearance: LayoutUnit? = nil
  }
  func verticalPositionWithClearance(layoutBox: BoxWrapper, boxGeometry: BoxGeometry)
    -> PositionWithClearance?
  {
    assert(layoutBox.hasFloatClear())
    assert(areFloatsHorizontallySorted(placedFloats: placedFloats))

    if isEmpty() {
      return nil
    }

    let clear = clearInPlacedFloats(clearBox: layoutBox)
    if clear == .Left {
      return bottomWithClearance(
        floatBottom: leftBottom(), layoutBox: layoutBox, boxGeometry: boxGeometry)
    }

    if clear == .Right {
      return bottomWithClearance(
        floatBottom: rightBottom(), layoutBox: layoutBox, boxGeometry: boxGeometry)
    }

    if clear == .Both {
      return bottomWithClearance(
        floatBottom: bottom(), layoutBox: layoutBox, boxGeometry: boxGeometry)
    }

    fatalError("Not reached")
  }

  private func bottomWithClearance(
    floatBottom: LayoutUnit?, layoutBox: BoxWrapper, boxGeometry: BoxGeometry
  )
    -> PositionWithClearance?
  {
    if floatBottom == nil {
      return nil
    }
    // 9.5.2 Controlling flow next to floats: the 'clear' property
    // Then the amount of clearance is set to the greater of:
    //
    // 1. The amount necessary to place the border edge of the block even with the bottom outer edge of the lowest float that is to be cleared.
    // 2. The amount necessary to place the top border edge of the block at its hypothetical position.
    var logicalTopRelativeToPlacedFloatsRoot = mapTopLeftToPlacedFloatsRoot(
      layoutBox: layoutBox, borderBoxTopLeft: BoxGeometry.borderBoxTopLeft(box: boxGeometry)
    ).y
    let clearance = floatBottom! - logicalTopRelativeToPlacedFloatsRoot
    if clearance <= 0 {
      return nil
    }

    if layoutBox.isBlockLevelBox() {
      // Clearance inhibits margin collapsing in block formatting context.
      fatalError("Not implemented yet")
      // FIXME: This needs to go to BFC.
    }
    // Now adjust the box's position with the clearance.
    logicalTopRelativeToPlacedFloatsRoot += clearance
    assert(floatBottom! == logicalTopRelativeToPlacedFloatsRoot)

    // The return vertical position needs to be in the containing block's coordinate system.
    let containingBlock = FormattingContext.containingBlock(layoutBox: layoutBox)
    if CPtrToInt(containingBlock.p) == CPtrToInt(placedFloats.formattingContextRoot().p) {
      return PositionWithClearance(
        position: logicalTopRelativeToPlacedFloatsRoot, clearance: clearance)
    }

    let containingBlockTopLeft = BoxGeometry.borderBoxTopLeft(
      box: containingBlockGeometries().geometryForBox(layoutBox: containingBlock))
    let containingBlockRootRelativeTop = mapTopLeftToPlacedFloatsRoot(
      layoutBox: containingBlock, borderBoxTopLeft: containingBlockTopLeft
    ).y
    return PositionWithClearance(
      position: logicalTopRelativeToPlacedFloatsRoot - containingBlockRootRelativeTop,
      clearance: clearance)
  }

  func top() -> LayoutUnit? {
    var top: LayoutUnit? = nil
    for floatItem in placedFloats.list {
      top =
        top == nil
        ? floatItem.absoluteRectWithMargin().top()
        : min(top!, floatItem.absoluteRectWithMargin().top())
    }
    return top
  }

  func leftBottom() -> LayoutUnit? {
    return bottom(type: .Left)
  }

  func rightBottom() -> LayoutUnit? {
    return bottom(type: .Right)
  }

  func bottom() -> LayoutUnit? {
    return bottom(type: .Both)
  }

  func isEmpty() -> Bool {
    return placedFloats.list.isEmpty
  }

  struct Constraints {
    var left: PointInContextRoot? = nil
    var right: PointInContextRoot? = nil
  }
  enum MayBeAboveLastFloat: UInt8 {
    case No
    case Yes
  }
  func constraints(
    candidateTop: LayoutUnit, candidateBottom: LayoutUnit, mayBeAboveLastFloat: MayBeAboveLastFloat
  ) -> Constraints {
    if isEmpty() {
      return Constraints()
    }
    // 1. Convert vertical position if this floating context is inherited.
    // 2. Find the inner left/right floats at candidateTop/candidateBottom. Note when MayBeAboveLastFloat is 'no', we can just stop at the inner most (last) float (block vs. inline case).
    // 3. Convert left/right positions back to formattingContextRoot's coordinate system.
    let coordinateMappingIsRequired =
      CPtrToInt(placedFloats.formattingContextRoot().p) != CPtrToInt(root().p)
    var adjustedCandidateTop = candidateTop
    var adjustingDelta = LayoutSizeWrapper()
    if coordinateMappingIsRequired {
      let adjustedCandidatePosition = mapPointFromFormattingContextRootToPlacedFloatsRoot(
        position: Point(x: LayoutUnit(value: 0), y: candidateTop))
      adjustedCandidateTop = adjustedCandidatePosition.y
      adjustingDelta = LayoutSizeWrapper(
        width: adjustedCandidatePosition.x, height: adjustedCandidateTop - candidateTop)
    }
    let adjustedCandidateBottom = adjustedCandidateTop + (candidateBottom - candidateTop)
    let candidateHeight = adjustedCandidateBottom - adjustedCandidateTop

    var constraints = Constraints()
    if mayBeAboveLastFloat == .No {
      for floatItem in placedFloats.list.reversed() {
        if (constraints.left != nil && floatItem.isLeftPositioned())
          || (constraints.right != nil && !floatItem.isLeftPositioned())
        {
          continue
        }

        let edgeAndBottom = computeFloatEdgeAndBottom(
          floatItem: floatItem, candidateHeight: candidateHeight,
          adjustedCandidateTop: adjustedCandidateTop,
          adjustedCandidateBottom: adjustedCandidateBottom)
        if edgeAndBottom == nil {
          continue
        }

        let (edge, bottom) = edgeAndBottom!

        if floatItem.isLeftPositioned() {
          constraints.left = PointInContextRoot(x: edge, y: bottom)
        } else {
          constraints.right = PointInContextRoot(x: edge, y: bottom)
        }

        if (constraints.left != nil && constraints.right != nil)
          || (constraints.left != nil && !placedFloats.hasRightPositioned())
          || (constraints.right != nil && !placedFloats.hasLeftPositioned())
        {
          break
        }
      }
    } else {
      for floatItem in placedFloats.list.reversed() {
        let edgeAndBottom = computeFloatEdgeAndBottom(
          floatItem: floatItem, candidateHeight: candidateHeight,
          adjustedCandidateTop: adjustedCandidateTop,
          adjustedCandidateBottom: adjustedCandidateBottom)
        if edgeAndBottom == nil {
          continue
        }

        let (edge, bottom) = edgeAndBottom!

        if floatItem.isLeftPositioned() {
          if constraints.left == nil || constraints.left!.x < edge {
            constraints.left = PointInContextRoot(x: edge, y: bottom)
          }
        } else {
          if constraints.right == nil || constraints.right!.x > edge {
            constraints.right = PointInContextRoot(x: edge, y: bottom)
          }
        }
        // FIXME: Bail out when floats are way above.
      }
    }

    if coordinateMappingIsRequired {
      if let left_point = constraints.left {
        left_point.move(offset: -adjustingDelta)
      }

      if let right_point = constraints.right {
        right_point.move(offset: -adjustingDelta)
      }
    }

    if placedFloats.isLeftToRightDirection != root().style.isLeftToRightDirection() {
      // FIXME: Move it under coordinateMappingIsRequired when the integration codepath starts initiating the floating state with the
      // correct containing block (i.e. when the float comes from the parent BFC).

      // Flip to logical in inline direction.
      var logicalConstraints = Constraints()
      let borderBoxWidth = containingBlockGeometries().geometryForBox(layoutBox: root())
        .borderBoxWidth()
      if let left_point = constraints.left {
        logicalConstraints.right = PointInContextRoot(
          x: borderBoxWidth - left_point.x, y: left_point.y)
      }
      if let right_point = constraints.right {
        logicalConstraints.left = PointInContextRoot(
          x: borderBoxWidth - right_point.x, y: right_point.y)
      }
      return logicalConstraints
    }
    return constraints
  }

  private func containsFloatBoxRect(
    floatBoxRect: Rect, candidateHeight: LayoutUnit, adjustedCandidateTop: LayoutUnit,
    adjustedCandidateBottom: LayoutUnit
  ) -> Bool {
    if floatBoxRect.isEmpty() {
      return false
    }
    if !candidateHeight.bool() {
      return floatBoxRect.top() <= adjustedCandidateTop
        && floatBoxRect.bottom() > adjustedCandidateTop
    }
    return floatBoxRect.top() < adjustedCandidateBottom
      && floatBoxRect.bottom() > adjustedCandidateTop
  }

  private func computeFloatEdgeAndBottom(
    floatItem: PlacedFloats.Item, candidateHeight: LayoutUnit, adjustedCandidateTop: LayoutUnit,
    adjustedCandidateBottom: LayoutUnit
  ) -> (LayoutUnit, LayoutUnit)? {
    let marginRect = floatItem.absoluteRectWithMargin()
    if !containsFloatBoxRect(
      floatBoxRect: marginRect, candidateHeight: candidateHeight,
      adjustedCandidateTop: adjustedCandidateTop, adjustedCandidateBottom: adjustedCandidateBottom)
    {
      return nil
    }

    if let shape = floatItem.shape() {
      // Shapes are relative to the border box.
      let borderRect = floatItem.absoluteBorderBoxRect()
      let positionInShape = adjustedCandidateTop - borderRect.top()

      if !shape.lineOverlapsShapeMarginBounds(lineTop: positionInShape, lineHeight: candidateHeight)
      {
        return nil
      }

      // PolygonShape gets confused when passing in 0px height interval at vertices.
      let segment = shape.getExcludedInterval(
        logicalTop: positionInShape, logicalHeight: max(candidateHeight, LayoutUnit(value: 1)))
      if !segment.isValid {
        return nil
      }

      // Bottom is used to decide the next line top if nothing fits. With shape we'll just sample one pixel down.
      // FIXME: This is potentially slow.
      let bottom = adjustedCandidateTop + LayoutUnit(value: 1)

      if floatItem.isLeftPositioned() {
        let shapeRight = borderRect.left() + LayoutUnit(value: segment.logicalRight)
        // Shape can't extend beyond the margin box.
        return (min(shapeRight, marginRect.right()), bottom)
      }
      let shapeLeft = borderRect.left() + LayoutUnit(value: segment.logicalLeft)
      return (max(shapeLeft, marginRect.left()), bottom)
    }

    let edge = floatItem.isLeftPositioned() ? marginRect.right() : marginRect.left()
    return (edge, marginRect.bottom())
  }

  func makeFloatItem(floatBox: BoxWrapper, boxGeometry: BoxGeometry, line: UInt64? = nil)
    -> PlacedFloats.Item
  {
    let borderBoxTopLeft = BoxGeometry.borderBoxTopLeft(box: boxGeometry)
    let absoluteBoxGeometry = boxGeometry
    absoluteBoxGeometry.setTopLeft(
      topLeft:
        mapTopLeftToPlacedFloatsRoot(layoutBox: floatBox, borderBoxTopLeft: borderBoxTopLeft))
    let position: PlacedFloats.Item.Position =
      isFloatingCandidateLeftPositionedInPlacedFloats(floatBox: floatBox) ? .Left : .Right
    return PlacedFloats.Item(
      layoutBox: floatBox, position: position, absoluteBoxGeometry: absoluteBoxGeometry,
      localTopLeft: borderBoxTopLeft, line: line
    )
  }

  func isLogicalLeftPositioned(floatBox: BoxWrapper) -> Bool {
    assert(floatBox.isFloatingPositioned())
    // Note that this returns true relative to the root of this FloatingContext and not to the PlacedFloats
    // PlacedFloats's root may be an ancestor block container with mismatching inline direction.
    let floatingBoxIsInLeftToRightDirection = root().style.isLeftToRightDirection()
    let floatingValue = floatBox.style.floating()
    return floatingValue == .InlineStart
      || (floatingBoxIsInLeftToRightDirection && floatingValue == .Left)
      || (!floatingBoxIsInLeftToRightDirection && floatingValue == .Right)
  }

  private func bottom(type: Clear) -> LayoutUnit? {
    // TODO: Currently this is only called once for each formatting context root with floats per layout.
    // Cache the value if we end up calling it more frequently (and update it at append/remove).
    var bottom: LayoutUnit? = nil
    for floatItem in placedFloats.list {
      if (type == .Left && !floatItem.isLeftPositioned())
        || (type == .Right && floatItem.isLeftPositioned())
      {
        continue
      }
      bottom =
        bottom == nil
        ? floatItem.absoluteRectWithMargin().bottom()
        : max(bottom!, floatItem.absoluteRectWithMargin().bottom())
    }
    return bottom
  }

  private func isFloatingCandidateLeftPositionedInPlacedFloats(floatBox: BoxWrapper) -> Bool {
    assert(floatBox.isFloatingPositioned())
    // A floating candidate is logically left positioned when:
    // - "float: left" in left-to-right floating state
    // - "float: inline-start" inline left-to-right floating state
    // If the floating state is right-to-left (meaning that the PlacedFloats is constructed by a BFC root with "direction: rtl")
    // visually left positioned floats are logically right (Note that FloatingContext's direction may not be the same as the PlacedFloats's direction
    // when dealing with inherited PlacedFloatss across nested IFCs).
    let floatingContextIsLeftToRight = root().style.isLeftToRightDirection()
    let placedFloatsIsLeftToRight = placedFloats.isLeftToRightDirection
    if floatingContextIsLeftToRight == placedFloatsIsLeftToRight {
      return isLogicalLeftPositioned(floatBox: floatBox)
    }

    var floatingValue = floatBox.style.floating()
    if floatingValue == .InlineStart {
      floatingValue = floatingContextIsLeftToRight ? .Left : .Right
    } else if floatingValue == .InlineEnd {
      floatingValue = floatingContextIsLeftToRight ? .Right : .Left
    }
    return (placedFloatsIsLeftToRight && floatingValue == .Left)
      || (!placedFloatsIsLeftToRight && floatingValue == .Right)
  }

  private func clearInPlacedFloats(clearBox: BoxWrapper) -> Clear {
    // See isFloatingCandidateLeftPositionedInPlacedFloats for details.
    assert(clearBox.hasFloatClear())
    let clearBoxIsInLeftToRightDirection = root().style.isLeftToRightDirection()
    var clearValue = clearBox.style.clear()
    if clearValue == .Both {
      return clearValue
    }

    if clearValue == .InlineStart {
      clearValue = clearBoxIsInLeftToRightDirection ? .Left : .Right
    } else if clearValue == .InlineEnd {
      clearValue = clearBoxIsInLeftToRightDirection ? .Right : .Left
    }

    let floatsAreInLeftToRightDirection = placedFloats.isLeftToRightDirection
    return (floatsAreInLeftToRightDirection && clearValue == .Left)
      || (!floatsAreInLeftToRightDirection && clearValue == .Right) ? .Left : .Right
  }

  private func root() -> ElementBoxWrapper {
    return formattingContextRoot
  }

  // FIXME: Turn this into an actual geometry cache.
  private func containingBlockGeometries() -> LayoutStateWrapper {
    return layoutState
  }

  private func findPositionForFormattingContextRoot(
    floatAvoider: inout FloatAvoider, containingBlockContentBoxEdges: BoxGeometry.HorizontalEdges
  ) {
    // A non-floating formatting root's initial vertical position is its static position.
    // It means that such boxes can end up vertically placed in-between existing floats (which is
    // never the case for floats, since they cannot be placed above existing floats).
    //  ____  ____
    // |    || F1 |
    // | L1 | ----
    // |    |  ________
    //  ----  |   R1   |
    //         --------
    // Document order: 1. float: left (L1) 2. float: right (R1) 3. formatting root (F1)
    //
    // 1. Probe for available placement at initial position (note it runs a backward probing algorithm at a specific vertical position)
    // 2. Check if there's any intersecting float below (forward search)
    // 3. Align the box with the intersected float and probe for placement again (#1).
    let floats = placedFloats.list
    while true {
      let innerMostLeftAndRight = findAvailablePosition(
        floatAvoider: &floatAvoider, floats: floats,
        containingBlockContentBoxEdges: containingBlockContentBoxEdges)
      if innerMostLeftAndRight.isEmpty() {
        return
      }

      let startIndex = max(innerMostLeftAndRight.left ?? 0, innerMostLeftAndRight.right ?? 0) + 1
      let intersectedFloatBox = overlappingFloatBox(
        startFloatIndex: startIndex, floatAvoider: floatAvoider, floats: floats)
      if let intersectedFloatBox = intersectedFloatBox {
        floatAvoider.setVerticalPosition(
          verticalPosition: intersectedFloatBox.absoluteRectWithMargin().top())
      } else {
        return
      }
    }
  }

  private func overlappingFloatBox(
    startFloatIndex: UInt32, floatAvoider: FloatAvoider, floats: [PlacedFloats.Item]
  ) -> PlacedFloats
    .Item?
  {
    for i in Int(startFloatIndex)..<floats.count {
      let floatBox = floats[i]
      let intersects = floatBoxIntersectsAvoider(floatBox: floatBox, floatAvoider: floatAvoider)
      if intersects {
        return floatBox
      }
    }
    return nil
  }

  private func floatBoxIntersectsAvoider(floatBox: PlacedFloats.Item, floatAvoider: FloatAvoider)
    -> Bool
  {
    let floatingRect = floatBox.absoluteRectWithMargin()
    if floatAvoider.left() >= floatingRect.right() || floatAvoider.right() <= floatingRect.left() {
      return false
    }
    return floatAvoider.top() >= floatingRect.top() && floatAvoider.top() < floatingRect.bottom()
  }

  struct AbsoluteCoordinateValuesForFloatAvoider {
    var topLeft = LayoutPointWrapper()
    var containingBlockTopLeft = LayoutPointWrapper()
    var containingBlockContentBox = BoxGeometry.HorizontalEdges()
  }

  private func absoluteCoordinates(floatAvoider: BoxWrapper, borderBoxTopLeft: LayoutPointWrapper)
    -> AbsoluteCoordinateValuesForFloatAvoider
  {
    let containingBlock = FormattingContext.containingBlock(layoutBox: floatAvoider)
    let containingBlockGeometry = containingBlockGeometries().geometryForBox(
      layoutBox: containingBlock)
    let absoluteTopLeft = mapTopLeftToPlacedFloatsRoot(
      layoutBox: floatAvoider, borderBoxTopLeft: borderBoxTopLeft)

    if CPtrToInt(containingBlock.p) == CPtrToInt(placedFloats.formattingContextRoot().p) {
      return AbsoluteCoordinateValuesForFloatAvoider(
        topLeft: absoluteTopLeft,
        containingBlockTopLeft: LayoutPointWrapper(),
        containingBlockContentBox: BoxGeometry.HorizontalEdges(
          start: containingBlockGeometry.contentBoxLeft(),
          end: containingBlockGeometry.contentBoxRight())
      )
    }

    let containingBlockAbsoluteTopLeft = mapTopLeftToPlacedFloatsRoot(
      layoutBox: containingBlock,
      borderBoxTopLeft: BoxGeometry.borderBoxTopLeft(box: containingBlockGeometry))
    return AbsoluteCoordinateValuesForFloatAvoider(
      topLeft: absoluteTopLeft,
      containingBlockTopLeft: containingBlockAbsoluteTopLeft,
      containingBlockContentBox: BoxGeometry.HorizontalEdges(
        start: containingBlockAbsoluteTopLeft.x + containingBlockGeometry.contentBoxLeft(),
        end: containingBlockAbsoluteTopLeft.x + containingBlockGeometry.contentBoxRight())
    )
  }

  private func mapTopLeftToPlacedFloatsRoot(
    layoutBox: BoxWrapper, borderBoxTopLeft: LayoutPointWrapper
  )
    -> LayoutPointWrapper
  {
    assert(layoutBox.isFloatingPositioned() || layoutBox.isInFlow())
    let placedFloatsRoot = placedFloats.formattingContextRoot()
    var borderBoxTopLeftCopy = borderBoxTopLeft
    for containingBlock in containingBlockChain(layoutBox: layoutBox, stayWithin: placedFloatsRoot)
    {
      borderBoxTopLeftCopy.moveBy(
        offset: BoxGeometry.borderBoxTopLeft(
          box: containingBlockGeometries().geometryForBox(layoutBox: containingBlock)))
    }
    return borderBoxTopLeftCopy
  }

  private func mapPointFromFormattingContextRootToPlacedFloatsRoot(position: Point) -> Point {
    let from = root()
    let to = placedFloats.formattingContextRoot()
    if from === to {
      return position
    }
    var mappedPosition = position
    var containingBlock = from
    while containingBlock !== to {
      mappedPosition.moveBy(
        offset: BoxGeometry.borderBoxTopLeft(
          box: containingBlockGeometries().geometryForBox(layoutBox: containingBlock)))
      containingBlock = FormattingContext.containingBlock(layoutBox: containingBlock)
    }
    return mappedPosition
  }

  var formattingContextRoot: ElementBoxWrapper
  var layoutState: LayoutStateWrapper
  var placedFloats: PlacedFloats
}

struct FloatPair {
  struct LeftRightIndex {
    func isEmpty() -> Bool {
      return left == nil && right == nil
    }

    var left: UInt32?
    var right: UInt32?
  }

  func isEmpty() -> Bool { return floatPair.isEmpty() }

  func left() -> PlacedFloats.Item? {
    if let leftIdx = floatPair.left {
      let float = floats[Int(leftIdx)]
      assert(float.isLeftPositioned())
      return float
    }
    return nil
  }

  func right() -> PlacedFloats.Item? {
    if let rightIdx = floatPair.right {
      let float = floats[Int(rightIdx)]
      assert(!float.isLeftPositioned())
      return float
    }
    return nil
  }

  func intersects(floatAvoider: FloatAvoider) -> Bool {
    assert(!floatPair.isEmpty())
    return FloatPair.intersectsItem(floating: left(), floatAvoider: floatAvoider)
      || FloatPair.intersectsItem(floating: right(), floatAvoider: floatAvoider)
  }

  private static func intersectsItem(floating: PlacedFloats.Item?, floatAvoider: FloatAvoider)
    -> Bool
  {
    if let floating = floating {
      let floatingRect = floating.absoluteRectWithMargin()
      if floatAvoider.left() >= floatingRect.right() || floatAvoider.right() <= floatingRect.left()
      {
        return false
      }
      return floatAvoider.top() >= floatingRect.top() && floatAvoider.top() < floatingRect.bottom()
    }
    return false
  }

  func intersects(containingBlockContentBoxEdges: BoxGeometry.HorizontalEdges) -> Bool {
    assert(!floatPair.isEmpty())

    let leftRightEdge = horizontalConstraints()
    if let leftEdge = leftRightEdge.left {
      if leftEdge.toLayoutUnit() > containingBlockContentBoxEdges.start {
        return true
      }
    }

    if let rightEdge = leftRightEdge.right {
      if rightEdge.toLayoutUnit() < containingBlockContentBoxEdges.end {
        return true
      }
    }

    return false
  }

  func containsFloatFromFormattingContext() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func verticalConstraint() -> PositionInContextRoot { return verticalPosition }

  struct HorizontalConstraints {
    var left: PositionInContextRoot?
    var right: PositionInContextRoot?
  }

  func horizontalConstraints() -> HorizontalConstraints {
    var leftEdge: PositionInContextRoot? = nil
    var rightEdge: PositionInContextRoot? = nil

    if let left = left() {
      leftEdge = PositionInContextRoot(value: left.absoluteRectWithMargin().right())
    }

    if let right = right() {
      rightEdge = PositionInContextRoot(value: right.absoluteRectWithMargin().left())
    }

    return HorizontalConstraints(left: leftEdge, right: rightEdge)
  }

  func bottom() -> PositionInContextRoot {
    let left = left()
    let right = right()
    assert(left != nil || right != nil)
    var leftBottom: PositionInContextRoot? = nil
    if let left = left {
      leftBottom = PositionInContextRoot(value: left.absoluteRectWithMargin().bottom())
    }
    var rightBottom: PositionInContextRoot? = nil
    if let right = right {
      rightBottom = PositionInContextRoot(value: right.absoluteRectWithMargin().bottom())
    }

    if let leftBottom = leftBottom {
      if let rightBottom = rightBottom {
        return PositionInContextRoot(
          value: max(leftBottom.toLayoutUnit(), rightBottom.toLayoutUnit()))
      }

      return leftBottom
    }

    return rightBottom!
  }

  prefix static func * (this: FloatPair) -> LeftRightIndex { return this.floatPair }

  static func == (this: FloatPair, other: FloatPair) -> Bool {
    return this.floatPair.left == other.floatPair.left
      && this.floatPair.right == other.floatPair.right
  }

  var floats: PlacedFloats.List
  var floatPair = LeftRightIndex()
  var verticalPosition = PositionInContextRoot()
}

@discardableResult
func findAvailablePosition(
  floatAvoider: inout FloatAvoider, floats: PlacedFloats.List,
  containingBlockContentBoxEdges: BoxGeometry.HorizontalEdges
) -> FloatPair.LeftRightIndex {
  var bottomMost: PositionInContextRoot? = nil
  var innerMostLeftAndRight: FloatPair.LeftRightIndex? = nil
  let end = end(floats: floats)
  let iterator = begin(
    floats: floats, initialVerticalPosition: PositionInContextRoot(value: floatAvoider.top()))
  while iterator != end {
    let leftRightFloatPair = *iterator
    assert(!leftRightFloatPair.isEmpty())
    innerMostLeftAndRight = innerMostLeftAndRight ?? *leftRightFloatPair

    // Move the box horizontally so that it either
    // 1. aligns with the current floating pair (always constrained by containing block e.g. when current float on this position is outside of containing block i.e. not intrusive).
    // 2. or with the containing block's content box if there's no float to align with at this vertical position.
    let leftRightEdge = leftRightFloatPair.horizontalConstraints()

    // Ensure that the float avoider
    // 1. avoids floats on both sides (with the exception of non-intrusive floats from other FCs)
    // 2. does not overflow its containing block if the horizontal position is constrained by other floats
    // (i.e. a float avoider may overflow its containing block just fine unless this overflow is the result of getting it pushed by other floats on this vertical position -out of available space)
    // 3. Move to the next floating pair if this vertical position is over-constrained.
    if let horizontalConstraint = floatAvoider.isLeftAligned
      ? leftRightEdge.left : leftRightEdge.right
    {
      floatAvoider.setHorizontalPosition(horizontalPosition: horizontalConstraint.toLayoutUnit())
    } else {
      floatAvoider.resetHorizontalPosition()
    }
    floatAvoider.setVerticalPosition(
      verticalPosition: leftRightFloatPair.verticalConstraint().toLayoutUnit())

    if !leftRightFloatPair.intersects(floatAvoider: floatAvoider)
      && !floatAvoider.overflowsContainingBlock()
    {
      return innerMostLeftAndRight!
    }

    // Is this float pair is outside of our containing block's content box? In some cases we _may_ overlap them.
    if !leftRightFloatPair.intersects(
      containingBlockContentBoxEdges: containingBlockContentBoxEdges)
      && !leftRightFloatPair.containsFloatFromFormattingContext()
    {
      // Surprisingly floats do overlap each other on the non-floating side (e.g. float: left may overlap a float: right)
      // when they are not considered intrusive (i.e. they are outside of our containing block's content box) and coming from outside of the formatting context.
      return innerMostLeftAndRight!
    }

    bottomMost = leftRightFloatPair.bottom()
    // Move to the next floating pair.
    ++iterator
  }

  // The candidate box is already below of all the floats.
  if bottomMost == nil {
    return FloatPair.LeftRightIndex()
  }

  // Passed all the floats and still does not fit? Push it below the last float.
  floatAvoider.setVerticalPosition(verticalPosition: bottomMost!.toLayoutUnit())
  floatAvoider.resetHorizontalPosition()
  assert(innerMostLeftAndRight != nil)
  return innerMostLeftAndRight!
}
