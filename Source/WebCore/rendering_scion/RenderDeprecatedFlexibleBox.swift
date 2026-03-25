/*
 * This file is part of the render object implementation for KHTML.
 *
 * Copyright (C) 2003 Apple Inc.
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

struct FlexBoxIterator {
  init(_ parent: RenderDeprecatedFlexibleBoxWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func first() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func next() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private func marginWidthForChild(_ child: RenderBoxWrapper) -> LayoutUnit {
  // A margin basically has three types: fixed, percentage, and auto (variable).
  // Auto and percentage margins simply become 0 when computing min/max width.
  // Fixed margins can be added in as is.
  let marginLeft = child.style().marginLeft()
  let marginRight = child.style().marginRight()
  var margin = LayoutUnit()
  if marginLeft.isFixed() {
    margin += marginLeft.value()
  }
  if marginRight.isFixed() {
    margin += marginRight.value()
  }
  return margin
}

private func childDoesNotAffectWidthOrFlexing(_ child: RenderObjectWrapper) -> Bool {
  // Positioned children don't affect the min/max width.
  return child.isOutOfFlowPositioned()
}

private func widthForChild(_ child: RenderBoxWrapper) -> LayoutUnit {
  return child.overridingLogicalWidth() ?? child.logicalWidth()
}

private func heightForChild(_ child: RenderBoxWrapper) -> LayoutUnit {
  return child.overridingLogicalHeight() ?? child.logicalHeight()
}

private func contentWidthForChild(_ child: RenderBoxWrapper) -> LayoutUnit {
  return max(LayoutUnit(value: 0), widthForChild(child) - child.borderAndPaddingLogicalWidth())
}

private func contentHeightForChild(_ child: RenderBoxWrapper) -> LayoutUnit {
  return max(LayoutUnit(value: 0), heightForChild(child) - child.borderAndPaddingLogicalHeight())
}

// TODO(asuhan): use an inline capacity of 8
typealias ChildFrameRects = [LayoutRectWrapper]
typealias ChildLayoutDeltas = [LayoutSizeWrapper]

private func appendChildFrameRects(
  _ box: RenderDeprecatedFlexibleBoxWrapper?, _ childFrameRects: inout ChildFrameRects
) {
  var iterator = FlexBoxIterator(box)
  var child = iterator.first()
  while child != nil {
    if !child!.isOutOfFlowPositioned() {
      childFrameRects.append(child!.frameRect())
    }
    child = iterator.next()
  }
}

private func appendChildLayoutDeltas(
  _ box: RenderDeprecatedFlexibleBoxWrapper?, _ childLayoutDeltas: inout ChildLayoutDeltas
) {
  var iterator = FlexBoxIterator(box)
  var child = iterator.first()
  while child != nil {
    if !child!.isOutOfFlowPositioned() {
      childLayoutDeltas.append(LayoutSizeWrapper())
    }
    child = iterator.next()
  }
}

private func repaintChildrenDuringLayoutIfMoved(
  _ box: RenderDeprecatedFlexibleBoxWrapper?, _ oldChildRects: ChildFrameRects
) {
  var childIndex = 0
  var iterator = FlexBoxIterator(box)
  var child = iterator.first()
  while child != nil {
    if child!.isOutOfFlowPositioned() {
      child = iterator.next()
      continue
    }

    // If the child moved, we have to repaint it as well as any floating/positioned
    // descendants. An exception is if we need a layout. In this case, we know we're going to
    // repaint ourselves (and the child) anyway.
    if !box!.selfNeedsLayout() && child!.checkForRepaintDuringLayout() {
      child!.repaintDuringLayoutIfMoved(oldRect: oldChildRects[childIndex])
    }

    childIndex += 1
    child = iterator.next()
  }
  assert(childIndex == oldChildRects.count)
}

private struct FlexChildrenInfo {
  let highestFlexGroup: UInt32
  let lowestFlexGroup: UInt32
  let haveFlex: Bool
}

// The first walk over our kids is to find out if we have any flexible children.
private func gatherFlexChildrenInfo(_ iterator: inout FlexBoxIterator, _ relayoutChildren: Bool)
  -> FlexChildrenInfo
{
  var highestFlexGroup: UInt32 = 0
  var lowestFlexGroup: UInt32 = 0
  var haveFlex = false
  var child = iterator.first()
  while child != nil {
    // Check to see if this child flexes.
    if !childDoesNotAffectWidthOrFlexing(child!) && child!.style().boxFlex() > 0 {
      // We always have to lay out flexible objects again, since the flex distribution
      // may have changed, and we need to reallocate space.
      child!.clearOverridingContentSize()
      if !relayoutChildren {
        child!.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }
      haveFlex = true
      let flexGroup = child!.style().boxFlexGroup()
      if lowestFlexGroup == 0 {
        lowestFlexGroup = flexGroup
      }
      if flexGroup < lowestFlexGroup {
        lowestFlexGroup = flexGroup
      }
      if flexGroup > highestFlexGroup {
        highestFlexGroup = flexGroup
      }
    }
    child = iterator.next()
  }
  return FlexChildrenInfo(
    highestFlexGroup: highestFlexGroup, lowestFlexGroup: lowestFlexGroup, haveFlex: haveFlex)
}

private func layoutChildIfNeededApplyingDelta(
  _ child: RenderBoxWrapper, _ layoutDelta: LayoutSizeWrapper
) {
  if !child.needsLayout() {
    return
  }

  child.view().frameView().layoutContext().addLayoutDelta(delta: layoutDelta)
  child.layoutIfNeeded()
  child.view().frameView().layoutContext().addLayoutDelta(delta: -layoutDelta)
}

private func lineCountFor(_ blockFlow: RenderBlockFlowWrapper) -> UInt64 {
  if blockFlow.childrenInline() {
    return UInt64(blockFlow.lineCount())
  }

  var count: UInt64 = 0
  for child: RenderBlockFlowWrapper in childrenOfType(parent: blockFlow) {
    if blockFlow.isFloatingOrOutOfFlowPositioned() || !blockFlow.style().height().isAuto() {
      continue
    }
    count += lineCountFor(child)
  }
  return count
}

final class RenderDeprecatedFlexibleBoxWrapper: RenderBlockWrapper {
  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    let shouldClearLineClamp = { [self] () in
      let oldStyle = hasInitializedStyle ? style() : nil
      if oldStyle == nil || oldStyle!.lineClamp().isNone() {
        return false
      }
      if newStyle.lineClamp().isNone() {
        return true
      }
      return newStyle.boxOrient() == .Horizontal
    }
    if shouldClearLineClamp() {
      clearLineClamp()
    }
    super.styleWillChange(diff: diff, newStyle: newStyle)
  }

  override func layoutBlock(
    relayoutChildren: Bool, pageLogicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) {
    assert(needsLayout())

    if !relayoutChildren && simplifiedLayout() {
      return
    }

    var relayoutChildren = relayoutChildren
    let repainter = LayoutRepainter(renderer: self)
    do {
      let unused = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())
      use(unused)

      resetLogicalHeightBeforeLayoutIfNeeded()
      preparePaginationBeforeBlockLayout(relayoutChildren: &relayoutChildren)

      let previousSize = size()

      updateLogicalWidth()
      updateLogicalHeight()

      if previousSize != size()
        || (parent()!.isRenderDeprecatedFlexibleBox()
          && parent()!.style().boxOrient() == .Horizontal
          && parent()!.style().boxAlign() == .Stretch)
      {
        relayoutChildren = true
      }

      setHeight(height: Int32(0))

      stretchingChildren = false

      let oldLayoutDelta = view().frameView().layoutContext().layoutDelta()

      // Fieldsets need to find their legend and position it inside the border of the object.
      // The legend then gets skipped during normal layout. The same is true for ruby text.
      // It doesn't get included in the normal layout process but is instead skipped.
      layoutExcludedChildren(relayoutChildren: relayoutChildren)

      var oldChildRects = ChildFrameRects()
      appendChildFrameRects(self, &oldChildRects)

      if isHorizontal() {
        layoutHorizontalBox(relayoutChildren)
      } else {
        layoutVerticalBox(relayoutChildren)
      }

      repaintChildrenDuringLayoutIfMoved(self, oldChildRects)
      assert(view().frameView().layoutContext().layoutDeltaMatches(delta: oldLayoutDelta))

      let oldClientAfterEdge = clientLogicalBottom()
      updateLogicalHeight()

      if previousSize.height() != height() {
        relayoutChildren = true
      }

      layoutPositionedObjects(relayoutChildren: relayoutChildren || isDocumentElementRenderer())

      updateDescendantTransformsAfterLayout()

      computeOverflow(oldClientAfterEdge: oldClientAfterEdge)
    }

    updateLayerTransform()

    if let layoutState = view().frameView().layoutContext().layoutState(),
      layoutState.pageLogicalHeight().bool()
    {
      setPageLogicalOffset(
        logicalOffset: layoutState.pageLogicalOffset(child: self, childLogicalOffset: logicalTop()))
    }

    // Update our scrollbars if we're overflow:auto/scroll/hidden now that we know if
    // we overflow or not.
    updateScrollInfoAfterLayout()

    // Repaint with our new bounds if they are different from our old bounds.
    repainter.repaintAfterLayout()

    clearNeedsLayout()
  }

  private func layoutHorizontalBox(_ relayoutChildren: Bool) {
    let toAdd = borderBottom() + paddingBottom() + horizontalScrollbarHeight()
    let yPos = borderTop() + paddingTop()
    var xPos = borderLeft() + paddingLeft()
    var heightSpecified = false
    var oldHeight = LayoutUnit()

    var remainingSpace = LayoutUnit()

    var iterator = FlexBoxIterator(self)
    let flexChildrenInfo = gatherFlexChildrenInfo(&iterator, relayoutChildren)
    let highestFlexGroup = flexChildrenInfo.highestFlexGroup
    let lowestFlexGroup = flexChildrenInfo.lowestFlexGroup
    var haveFlex = flexChildrenInfo.haveFlex
    var flexingChildren = false

    beginUpdateScrollInfoAfterLayoutTransaction()

    var childLayoutDeltas = ChildLayoutDeltas()
    appendChildLayoutDeltas(self, &childLayoutDeltas)
    var relayoutChildren = relayoutChildren

    // We do 2 passes.  The first pass is simply to lay everyone out at
    // their preferred widths. The subsequent passes handle flexing the children.
    // The first pass skips flexible objects completely.
    repeat {
      // Reset our height.
      setHeight(height: yPos)

      xPos = borderLeft() + paddingLeft()

      var childIndex = 0

      // Our first pass is done without flexing.  We simply lay the children
      // out within the box.  We have to do a layout first in order to determine
      // our box's intrinsic height.
      var maxAscent = LayoutUnit()
      var maxDescent = LayoutUnit()
      var child_ = iterator.first()
      while child_ != nil {
        if relayoutChildren {
          child_!.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }

        if child_!.isOutOfFlowPositioned() {
          child_ = iterator.next()
          continue
        }

        let childLayoutDelta = childLayoutDeltas[childIndex]
        childIndex += 1

        // Compute the child's vertical margins.
        child_!.computeAndSetBlockDirectionMargins(containingBlock: self)

        child_!.markForPaginationRelayoutIfNeeded()

        // Apply the child's current layout delta.
        layoutChildIfNeededApplyingDelta(child_!, childLayoutDelta)

        // Update our height and overflow height.
        if style().boxAlign() == .Baseline {
          let ascent =
            (child_!.firstLineBaseline() ?? (child_!.height() + child_!.marginBottom()))
            + child_!.marginTop()
          let descent = (child_!.height() + child_!.verticalMarginExtent()) - ascent

          // Update our maximum ascent.
          maxAscent = max(maxAscent, ascent)

          // Update our maximum descent.
          maxDescent = max(maxDescent, descent)

          // Now update our height.
          setHeight(height: max(yPos + maxAscent + maxDescent, height()))
        } else {
          setHeight(height: max(height(), yPos + child_!.height() + child_!.verticalMarginExtent()))
        }

        child_ = iterator.next()
      }
      assert(childIndex == childLayoutDeltas.count)

      if iterator.first() == nil && hasLineIfEmpty() {
        setHeight(
          height: height()
            + lineHeight(
              firstLine: true,
              direction: style().isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
              linePositionMode: .PositionOfInteriorLineBoxes))
      }

      setHeight(height: height() + toAdd)

      oldHeight = height()
      updateLogicalHeight()

      relayoutChildren = false
      if oldHeight != height() {
        heightSpecified = true
      }

      // Now that our height is actually known, we can place our boxes.
      childIndex = 0
      stretchingChildren = (style().boxAlign() == .Stretch)
      var child = iterator.first()
      while child != nil {
        if child!.isOutOfFlowPositioned() {
          child!.containingBlock()!.insertPositionedObject(positioned: child!)
          let childLayer = child!.layer()!
          childLayer.setStaticInlinePosition(position: xPos)  // FIXME: Not right for regions.
          if childLayer.staticBlockPosition() != yPos {
            childLayer.setStaticBlockPosition(position: yPos)
            if child!.style().hasStaticBlockPosition(horizontal: style().isHorizontalWritingMode())
            {
              child!.setChildNeedsLayout(markParents: .MarkOnlyThis)
            }
          }
          child = iterator.next()
          continue
        }

        var childLayoutDelta = childLayoutDeltas[childIndex]
        childIndex += 1

        // We need to see if this child's height has changed, since we make block elements
        // fill the height of a containing box by default.
        // Now do a layout.
        let oldChildHeight = child!.height()
        child!.updateLogicalHeight()
        if oldChildHeight != child!.height() {
          child!.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }

        child!.markForPaginationRelayoutIfNeeded()

        layoutChildIfNeededApplyingDelta(child!, childLayoutDelta)

        // We can place the child now, using our value of box-align.
        xPos += child!.marginLeft()
        var childY = yPos
        switch style().boxAlign() {
        case .Center:
          childY +=
            child!.marginTop()
            + max(
              LayoutUnit(value: 0),
              (contentHeight() - (child!.height() + child!.verticalMarginExtent())) / 2)
        case .Baseline:
          let ascent =
            (child!.firstLineBaseline() ?? (child!.height() + child!.marginBottom()))
            + child!.marginTop()
          childY += child!.marginTop() + (maxAscent - ascent)
        case .End:
          childY += contentHeight() - child!.marginBottom() - child!.height()
        default:  // .Start
          childY += child!.marginTop()
        }

        placeChild(child!, LayoutPointWrapper(x: xPos, y: childY), &childLayoutDelta)

        xPos += child!.width() + child!.marginRight()

        child = iterator.next()
      }
      assert(childIndex == childLayoutDeltas.count)

      remainingSpace = borderLeft() + paddingLeft() + contentWidth() - xPos

      stretchingChildren = false
      if flexingChildren {
        haveFlex = false  // We're done.
      } else if haveFlex {
        // We have some flexible objects.  See if we need to grow/shrink them at all.
        if !remainingSpace.bool() {
          break
        }

        // Allocate the remaining space among the flexible objects.  If we are trying to
        // grow, then we go from the lowest flex group to the highest flex group.  For shrinking,
        // we go from the highest flex group to the lowest group.
        let expanding = remainingSpace > 0
        let start = expanding ? lowestFlexGroup : highestFlexGroup
        let end = expanding ? highestFlexGroup : lowestFlexGroup
        for i in start...end {
          if !remainingSpace.bool() {
            break
          }
          // Always start off by assuming the group can get all the remaining space.
          var groupRemainingSpace = remainingSpace
          repeat {
            // Flexing consists of multiple passes, since we have to change ratios every time an object hits its max/min-width
            // For a given pass, we always start off by computing the totalFlex of all objects that can grow/shrink at all, and
            // computing the allowed growth before an object hits its min/max width (and thus
            // forces a totalFlex recomputation).
            let groupRemainingSpaceAtBeginning = groupRemainingSpace
            var totalFlex: Float32 = 0
            do {
              var child = iterator.first()
              while child != nil {
                if allowedChildFlex(child!, expanding, i).bool() {
                  totalFlex += child!.style().boxFlex()
                }
                child = iterator.next()
              }
            }
            var spaceAvailableThisPass = groupRemainingSpace
            do {
              var child = iterator.first()
              while child != nil {
                let allowedFlex = allowedChildFlex(child!, expanding, i)
                if allowedFlex.bool() {
                  let projectedFlex =
                    (allowedFlex == LayoutUnit.max())
                    ? allowedFlex
                    : LayoutUnit(value: allowedFlex * (totalFlex / child!.style().boxFlex()))
                  spaceAvailableThisPass =
                    expanding
                    ? min(spaceAvailableThisPass, projectedFlex)
                    : max(spaceAvailableThisPass, projectedFlex)
                }
                child = iterator.next()
              }
            }

            // The flex groups may not have any flexible objects this time around.
            if !spaceAvailableThisPass.bool() || totalFlex == 0 {
              // If we just couldn't grow/shrink any more, then it's time to transition to the next flex group.
              groupRemainingSpace = LayoutUnit(value: 0)
              continue
            }

            // Now distribute the space to objects.
            var child = iterator.first()
            while child != nil && spaceAvailableThisPass.bool() && totalFlex != 0 {
              if allowedChildFlex(child!, expanding, i).bool() {
                let spaceAdd = LayoutUnit(
                  value: spaceAvailableThisPass * (child!.style().boxFlex() / totalFlex))
                if spaceAdd.bool() {
                  child!.setOverridingLogicalWidth(width: widthForChild(child!) + spaceAdd)
                  flexingChildren = true
                  relayoutChildren = true
                }

                spaceAvailableThisPass -= spaceAdd
                remainingSpace -= spaceAdd
                groupRemainingSpace -= spaceAdd

                totalFlex -= child!.style().boxFlex()
              }
              child = iterator.next()
            }
            if groupRemainingSpace == groupRemainingSpaceAtBeginning {
              // This is not advancing, avoid getting stuck by distributing the remaining pixels.
              let spaceAdd = LayoutUnit(value: groupRemainingSpace > 0 ? 1 : -1)
              var child = iterator.first()
              while child != nil && groupRemainingSpace.bool() {
                if allowedChildFlex(child!, expanding, i).bool() {
                  child!.setOverridingLogicalWidth(width: widthForChild(child!) + spaceAdd)
                  flexingChildren = true
                  relayoutChildren = true
                  remainingSpace -= spaceAdd
                  groupRemainingSpace -= spaceAdd
                }
                child = iterator.next()
              }
            }
          } while groupRemainingSpace.abs() >= Int32(1)
        }

        // We didn't find any children that could grow.
        if haveFlex && !flexingChildren {
          haveFlex = false
        }
      }
    } while haveFlex

    endAndCommitUpdateScrollInfoAfterLayoutTransaction()

    if remainingSpace > 0
      && ((style().isLeftToRightDirection() && style().boxPack() != .Start)
        || (!style().isLeftToRightDirection() && style().boxPack() != .End))
    {
      // Children must be repositioned.
      var offset = LayoutUnit()
      if style().boxPack() == .Justify {
        // Determine the total number of children.
        var totalChildren: Int = 0
        var child = iterator.first()
        while child != nil {
          if childDoesNotAffectWidthOrFlexing(child!) {
            child = iterator.next()
            continue
          }
          totalChildren += 1
          child = iterator.next()
        }

        // Iterate over the children and space them out according to the
        // justification level.
        if totalChildren > 1 {
          totalChildren -= 1
          var firstChild = true
          var child = iterator.first()
          while child != nil {
            if childDoesNotAffectWidthOrFlexing(child!) {
              child = iterator.next()
              continue
            }

            if firstChild {
              firstChild = false
              child = iterator.next()
              continue
            }

            offset += remainingSpace / totalChildren
            remainingSpace -= (remainingSpace / totalChildren)
            totalChildren -= 1

            placeChild(
              child!,
              child!.location()
                + LayoutSizeWrapper(width: offset, height: LayoutUnit(value: UInt64(0))))

            child = iterator.next()
          }
        }
      } else {
        if style().boxPack() == .Center {
          offset += remainingSpace / 2
        } else {  // .End for LTR, .Start for RTL
          offset += remainingSpace
        }
        var child = iterator.first()
        while child != nil {
          if childDoesNotAffectWidthOrFlexing(child!) {
            child = iterator.next()
            continue
          }

          placeChild(
            child!,
            child!.location()
              + LayoutSizeWrapper(width: offset, height: LayoutUnit(value: UInt64(0))))
          child = iterator.next()
        }
      }
    }

    // So that the computeLogicalHeight in layoutBlock() knows to relayout positioned objects because of
    // a height change, we revert our height back to the intrinsic height before returning.
    if heightSpecified {
      setHeight(height: oldHeight)
    }
  }

  private func layoutVerticalBox(_ relayoutChildren: Bool) {
    var yPos = borderTop() + paddingTop()
    let toAdd = borderBottom() + paddingBottom() + horizontalScrollbarHeight()
    var heightSpecified = false
    var oldHeight = LayoutUnit()

    var remainingSpace = LayoutUnit()

    var iterator = FlexBoxIterator(self)
    let flexChildrenInfo = gatherFlexChildrenInfo(&iterator, relayoutChildren)
    let highestFlexGroup = flexChildrenInfo.highestFlexGroup
    let lowestFlexGroup = flexChildrenInfo.lowestFlexGroup
    var haveFlex = flexChildrenInfo.haveFlex
    var flexingChildren = false

    // We confine the line clamp ugliness to vertical flexible boxes (thus keeping it out of
    // mainstream block layout); this is not really part of the XUL box model.
    let haveLineClamp = !style().lineClamp().isNone()
    let clampedContent =
      haveLineClamp ? applyLineClamp(&iterator, relayoutChildren) : ClampedContent()

    beginUpdateScrollInfoAfterLayoutTransaction()

    var relayoutChildren = relayoutChildren

    // We do 2 passes.  The first pass is simply to lay everyone out at
    // their preferred widths.  The second pass handles flexing the children.
    // Our first pass is done without flexing.  We simply lay the children
    // out within the box.
    repeat {
      setHeight(height: borderTop() + paddingTop())
      let minHeight = height() + toAdd

      var child = iterator.first()
      while child != nil {
        // Make sure we relayout children if we need it.
        if !haveLineClamp && relayoutChildren {
          child!.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }

        if child!.isOutOfFlowPositioned() {
          child!.containingBlock()!.insertPositionedObject(positioned: child!)
          let childLayer = child!.layer()!
          childLayer.setStaticInlinePosition(position: borderAndPaddingStart())  // FIXME: Not right for regions.
          if childLayer.staticBlockPosition() != height() {
            childLayer.setStaticBlockPosition(position: height())
            if child!.style().hasStaticBlockPosition(horizontal: style().isHorizontalWritingMode())
            {
              child!.setChildNeedsLayout(markParents: .MarkOnlyThis)
            }
          }
          child = iterator.next()
          continue
        }

        // Compute the child's vertical margins.
        child!.computeAndSetBlockDirectionMargins(containingBlock: self)

        // Add in the child's marginTop to our height.
        setHeight(height: height() + child!.marginTop())

        if !haveLineClamp {
          child!.markForPaginationRelayoutIfNeeded()
        }

        // Now do a layout.
        child!.layoutIfNeeded()

        // We can place the child now, using our value of box-align.
        var childX = borderLeft() + paddingLeft()
        switch style().boxAlign() {
        case .Center, .Baseline:  // Baseline just maps to center for vertical boxes
          childX +=
            child!.marginLeft()
            + max(
              LayoutUnit(value: 0),
              (contentWidth() - (child!.width() + child!.horizontalMarginExtent())) / 2)
        case .End:
          if !style().isLeftToRightDirection() {
            childX += child!.marginLeft()
          } else {
            childX += contentWidth() - child!.marginRight() - child!.width()
          }
        default:  // .Start/.Stretch
          if style().isLeftToRightDirection() {
            childX += child!.marginLeft()
          } else {
            childX += contentWidth() - child!.marginRight() - child!.width()
          }
        }

        // Place the child.
        placeChild(child!, LayoutPointWrapper(x: childX, y: height()))
        setHeight(height: height() + child!.height() + child!.marginBottom())
        child = iterator.next()
      }

      yPos = height()

      if iterator.first() == nil && hasLineIfEmpty() {
        setHeight(
          height: height()
            + lineHeight(
              firstLine: true,
              direction: style().isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
              linePositionMode: .PositionOfInteriorLineBoxes))
      }

      setHeight(height: height() + toAdd)

      // Negative margins can cause our height to shrink below our minimal height (border/padding).
      // If this happens, ensure that the computed height is increased to the minimal height.
      if height() < minHeight {
        setHeight(height: minHeight)
      }

      // Now we have to calc our height, so we know how much space we have remaining.
      oldHeight = height()
      updateLogicalHeight()
      if oldHeight != height() {
        heightSpecified = true
      }

      remainingSpace = borderTop() + paddingTop() + contentHeight() - yPos

      if flexingChildren {
        haveFlex = false  // We're done.
      } else if haveFlex {
        // We have some flexible objects.  See if we need to grow/shrink them at all.
        if !remainingSpace.bool() {
          break
        }

        // Allocate the remaining space among the flexible objects.  If we are trying to
        // grow, then we go from the lowest flex group to the highest flex group.  For shrinking,
        // we go from the highest flex group to the lowest group.
        let expanding = remainingSpace > 0
        let start = expanding ? lowestFlexGroup : highestFlexGroup
        let end = expanding ? highestFlexGroup : lowestFlexGroup
        for i in start...end {
          if !remainingSpace.bool() {
            break
          }
          // Always start off by assuming the group can get all the remaining space.
          var groupRemainingSpace = remainingSpace
          repeat {
            // Flexing consists of multiple passes, since we have to change ratios every time an object hits its max/min-width
            // For a given pass, we always start off by computing the totalFlex of all objects that can grow/shrink at all, and
            // computing the allowed growth before an object hits its min/max width (and thus
            // forces a totalFlex recomputation).
            let groupRemainingSpaceAtBeginning = groupRemainingSpace
            var totalFlex: Float32 = 0
            do {
              var child = iterator.first()
              while child != nil {
                if allowedChildFlex(child!, expanding, i).bool() {
                  totalFlex += child!.style().boxFlex()
                }
                child = iterator.next()
              }
            }
            var spaceAvailableThisPass = groupRemainingSpace
            do {
              var child = iterator.first()
              while child != nil {
                let allowedFlex = allowedChildFlex(child!, expanding, i)
                if allowedFlex.bool() {
                  let projectedFlex =
                    (allowedFlex == LayoutUnit.max())
                    ? allowedFlex
                    : LayoutUnit(value: allowedFlex * (totalFlex / child!.style().boxFlex()))
                  spaceAvailableThisPass =
                    expanding
                    ? min(spaceAvailableThisPass, projectedFlex)
                    : max(spaceAvailableThisPass, projectedFlex)
                }
                child = iterator.next()
              }
            }

            // The flex groups may not have any flexible objects this time around.
            if !spaceAvailableThisPass.bool() || totalFlex == 0 {
              // If we just couldn't grow/shrink any more, then it's time to transition to the next flex group.
              groupRemainingSpace = LayoutUnit(value: 0)
              continue
            }

            // Now distribute the space to objects.
            var child = iterator.first()
            while child != nil && spaceAvailableThisPass.bool() && totalFlex != 0 {
              if allowedChildFlex(child!, expanding, i).bool() {
                let spaceAdd = LayoutUnit(
                  value: spaceAvailableThisPass * (child!.style().boxFlex() / totalFlex))
                if spaceAdd.bool() {
                  child!.setOverridingLogicalHeight(height: heightForChild(child!) + spaceAdd)
                  flexingChildren = true
                  relayoutChildren = true
                }

                spaceAvailableThisPass -= spaceAdd
                remainingSpace -= spaceAdd
                groupRemainingSpace -= spaceAdd

                totalFlex -= child!.style().boxFlex()
              }
              child = iterator.next()
            }
            if groupRemainingSpace == groupRemainingSpaceAtBeginning {
              // This is not advancing, avoid getting stuck by distributing the remaining pixels.
              let spaceAdd = LayoutUnit(value: groupRemainingSpace > 0 ? 1 : -1)
              var child = iterator.first()
              while child != nil && groupRemainingSpace.bool() {
                if allowedChildFlex(child!, expanding, i).bool() {
                  child!.setOverridingLogicalHeight(height: heightForChild(child!) + spaceAdd)
                  flexingChildren = true
                  relayoutChildren = true
                  remainingSpace -= spaceAdd
                  groupRemainingSpace -= spaceAdd
                }
                child = iterator.next()
              }
            }
          } while groupRemainingSpace.abs() >= Int32(1)
        }

        // We didn't find any children that could grow.
        if haveFlex && !flexingChildren {
          haveFlex = false
        }
      }
    } while haveFlex

    endAndCommitUpdateScrollInfoAfterLayoutTransaction()

    if style().boxPack() != .Start && remainingSpace > 0 {
      // Children must be repositioned.
      var offset = LayoutUnit()
      if style().boxPack() == .Justify {
        // Determine the total number of children.
        var totalChildren: Int = 0
        var child = iterator.first()
        while child != nil {
          if childDoesNotAffectWidthOrFlexing(child!) {
            child = iterator.next()
            continue
          }
          totalChildren += 1
          child = iterator.next()
        }

        // Iterate over the children and space them out according to the
        // justification level.
        if totalChildren > 1 {
          totalChildren -= 1
          var firstChild = true
          var child = iterator.first()
          while child != nil {
            if childDoesNotAffectWidthOrFlexing(child!) {
              child = iterator.next()
              continue
            }

            if firstChild {
              firstChild = false
              child = iterator.next()
              continue
            }

            offset += remainingSpace / totalChildren
            remainingSpace -= (remainingSpace / totalChildren)
            totalChildren -= 1

            placeChild(
              child!,
              child!.location()
                + LayoutSizeWrapper(width: LayoutUnit(value: UInt64(0)), height: offset))

            child = iterator.next()
          }
        }
      } else {
        if style().boxPack() == .Center {
          offset += remainingSpace / 2
        } else {  // .End
          offset += remainingSpace
        }
        var child = iterator.first()
        while child != nil {
          if childDoesNotAffectWidthOrFlexing(child!) {
            child = iterator.next()
            continue
          }

          placeChild(
            child!,
            child!.location()
              + LayoutSizeWrapper(width: LayoutUnit(value: UInt64(0)), height: offset))
          child = iterator.next()
        }
      }
    }

    // So that the computeLogicalHeight in layoutBlock() knows to relayout positioned objects because of
    // a height change, we revert our height back to the intrinsic height before returning.
    if heightSpecified {
      setHeight(height: oldHeight)
    } else if haveLineClamp && clampedContent.renderer != nil {
      let contentOffset = { [self] () in
        let clampedRenderer = clampedContent.renderer!
        var contentLogicalTop =
          clampedRenderer.logicalTop() + clampedRenderer.contentBoxLocation().y
        var ancestor = clampedRenderer.containingBlock()
        while ancestor != nil {
          if CPtrToInt(ancestor!.id()) == CPtrToInt(id()) {
            return contentLogicalTop
          }
          contentLogicalTop += ancestor!.logicalTop()
          ancestor = ancestor!.containingBlock()
        }
        fatalError("Not reached")
      }
      setHeight(
        height: contentOffset() + clampedContent.contentHeight + borderBottom() + paddingBottom())
    }
  }

  func isStretchingChildren() -> Bool {
    assert(isNativeImpl())
    return stretchingChildren
  }

  override func avoidsFloats() -> Bool {
    assert(isNativeImpl())
    return true
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    if shouldApplySizeOrInlineSizeContainment() {
      if let width = explicitIntrinsicInnerLogicalWidth() {
        minLogicalWidth = width
        maxLogicalWidth = width
      }
      addScrollbarWidth(minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
      return
    }

    if hasMultipleLines() || isVertical() {
      var child = firstChildBox()
      while child != nil {
        if childDoesNotAffectWidthOrFlexing(child!) {
          child = child!.nextSiblingBox()
          continue
        }

        let margin = marginWidthForChild(child!)
        var width = child!.minPreferredLogicalWidth() + margin
        minLogicalWidth = max(width, minLogicalWidth)

        width = child!.maxPreferredLogicalWidth() + margin
        maxLogicalWidth = max(width, maxLogicalWidth)
        child = child!.nextSiblingBox()
      }
    } else {
      var child = firstChildBox()
      while child != nil {
        if childDoesNotAffectWidthOrFlexing(child!) {
          child = child!.nextSiblingBox()
          continue
        }

        let margin = marginWidthForChild(child!)
        minLogicalWidth += child!.minPreferredLogicalWidth() + margin
        maxLogicalWidth += child!.maxPreferredLogicalWidth() + margin
        child = child!.nextSiblingBox()
      }
    }

    maxLogicalWidth = max(minLogicalWidth, maxLogicalWidth)
    addScrollbarWidth(minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
  }

  private func addScrollbarWidth(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    let scrollbarWidth = intrinsicScrollbarLogicalWidthIncludingGutter()
    maxLogicalWidth += scrollbarWidth
    minLogicalWidth += scrollbarWidth
  }

  override func computePreferredLogicalWidths() {
    assert(preferredLogicalWidthsDirty())

    m_maxPreferredLogicalWidth = LayoutUnit(value: 0)
    m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
    if style().width().isFixed() && style().width().value() > 0 {
      m_maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().width())
      m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &m_minPreferredLogicalWidth, maxLogicalWidth: &m_maxPreferredLogicalWidth)
    }

    super.computePreferredLogicalWidths(
      minWidth: style().minWidth(), maxWidth: style().maxWidth(),
      borderAndPadding: borderAndPaddingLogicalWidth())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  private func allowedChildFlex(_ child: RenderBoxWrapper, _ expanding: Bool, _ group: UInt32)
    -> LayoutUnit
  {
    if childDoesNotAffectWidthOrFlexing(child) || child.style().boxFlex() == 0
      || child.style().boxFlexGroup() != group
    {
      return LayoutUnit(value: 0)
    }

    if expanding {
      if isHorizontal() {
        // FIXME: For now just handle fixed values.
        var maxWidth = LayoutUnit.max()
        let width = contentWidthForChild(child)
        if !child.style().maxWidth().isUndefined() && child.style().maxWidth().isFixed() {
          maxWidth = LayoutUnit(value: child.style().maxWidth().value())
        } else if child.style().maxWidth().type() == .Intrinsic {
          maxWidth = child.maxPreferredLogicalWidth()
        } else if child.style().maxWidth().isMinIntrinsic() {
          maxWidth = child.minPreferredLogicalWidth()
        }
        if maxWidth == LayoutUnit.max() {
          return maxWidth
        }
        return max(LayoutUnit(value: 0), maxWidth - width)
      } else {
        // FIXME: For now just handle fixed values.
        var maxHeight = LayoutUnit.max()
        let height = contentHeightForChild(child)
        if !child.style().maxHeight().isUndefined() && child.style().maxHeight().isFixed() {
          maxHeight = LayoutUnit(value: child.style().maxHeight().value())
        }
        if maxHeight == LayoutUnit.max() {
          return maxHeight
        }
        return max(LayoutUnit(value: 0), maxHeight - height)
      }
    }

    // FIXME: For now just handle fixed values.
    if isHorizontal() {
      var minWidth = child.minPreferredLogicalWidth()
      let width = contentWidthForChild(child)
      if child.style().minWidth().isFixed() {
        minWidth = LayoutUnit(value: child.style().minWidth().value())
      } else if child.style().minWidth().type() == .Intrinsic {
        minWidth = child.maxPreferredLogicalWidth()
      } else if child.style().minWidth().isMinIntrinsic() {
        minWidth = child.minPreferredLogicalWidth()
      } else if child.style().minWidth().isAuto() {
        minWidth = LayoutUnit(value: 0)
      }

      let allowedShrinkage = min(LayoutUnit(value: 0), minWidth - width)
      return allowedShrinkage
    } else {
      let minHeight = child.style().minHeight()
      if minHeight.isFixed() || minHeight.isAuto() {
        let minHeight = LayoutUnit(value: child.style().minHeight().value())
        let height = contentHeightForChild(child)
        let allowedShrinkage = min(LayoutUnit(value: 0), minHeight - height)
        return allowedShrinkage
      }
    }

    return LayoutUnit(value: 0)
  }

  private func placeChild(
    _ child: RenderBoxWrapper, _ location: LayoutPointWrapper,
    _ childLayoutDelta: inout LayoutSizeWrapper
  ) {
    // Place the child and track the layout delta so we can apply it if we do another layout.
    childLayoutDelta += LayoutSizeWrapper(
      width: child.x() - location.x, height: child.y() - location.y)
    child.setLocation(p: location)
  }

  private func placeChild(_ child: RenderBoxWrapper, _ location: LayoutPointWrapper) {
    child.setLocation(p: location)
  }

  private func hasMultipleLines() -> Bool { return style().boxLines() == .Multiple }

  private func isVertical() -> Bool {
    assert(isNativeImpl())
    return style().boxOrient() == .Vertical
  }

  private func isHorizontal() -> Bool {
    assert(isNativeImpl())
    return style().boxOrient() == .Horizontal
  }

  private func clearLineClamp() {
    var iterator = FlexBoxIterator(self)
    var child = iterator.first()
    while child != nil {
      if childDoesNotAffectWidthOrFlexing(child!) {
        child = iterator.next()
        continue
      }

      child!.clearOverridingContentSize()
      if (child!.isReplacedOrInlineBlock()
        && (child!.style().width().isPercentOrCalculated()
          || child!.style().height().isPercentOrCalculated()))
        || (child!.style().height().isAuto() && child is RenderBlockFlowWrapper)
      {
        child!.setChildNeedsLayout()
        (child as? RenderBlockFlowWrapper)?.markPositionedObjectsForLayout()
      }
      child = iterator.next()
    }
  }

  private struct ClampedContent {
    init(_ contentHeight: LayoutUnit, _ renderer: RenderBlockFlowWrapper?) {
      self.contentHeight = contentHeight
      self.renderer = renderer
    }

    init() { self.init(LayoutUnit(), nil) }

    let contentHeight: LayoutUnit
    let renderer: RenderBlockFlowWrapper?
  }
  private func applyLineClamp(_ iterator: inout FlexBoxIterator, _ relayoutChildren: Bool)
    -> ClampedContent
  {
    var child = iterator.first()
    while child != nil {
      if childDoesNotAffectWidthOrFlexing(child!) {
        child = iterator.next()
        continue
      }

      child!.clearOverridingContentSize()
      if relayoutChildren
        || (child!.isReplacedOrInlineBlock()
          && (child!.style().width().isPercentOrCalculated()
            || child!.style().height().isPercentOrCalculated()))
        || (child!.style().height().isAuto() && child is RenderBlockFlowWrapper)
      {
        child!.setChildNeedsLayout(markParents: .MarkOnlyThis)

        // Dirty all the positioned objects.
        (child as? RenderBlockFlowWrapper)?.markPositionedObjectsForLayout()
      }
      child = iterator.next()
    }

    let layoutState = view().frameView().layoutContext().layoutState()!
    let ancestorLineClamp = layoutState.legacyLineClamp()
    defer {
      layoutState.setLegacyLineClamp(legacyLineClamp: ancestorLineClamp)
    }

    let lineCountForLineClamp = { [self] (iterator: inout FlexBoxIterator) in
      let lineClamp = style().lineClamp()
      if !lineClamp.isPercentage() {
        return UInt64(lineClamp.value)
      }

      var numberOfLines: UInt64 = 0
      var child = iterator.first()
      while child != nil {
        if childDoesNotAffectWidthOrFlexing(child!) {
          child = iterator.next()
          continue
        }

        child!.layoutIfNeeded()
        if let blockFlow = child as? RenderBlockFlowWrapper {
          numberOfLines += lineCountFor(blockFlow)
        }
        // FIXME: This should be turned into a partial damange.
        child!.setChildNeedsLayout(markParents: .MarkOnlyThis)
        child = iterator.next()
      }
      return UInt64(max(1, Float32((numberOfLines + 1) * UInt64(lineClamp.value)) / 100))
    }

    layoutState.setLegacyLineClamp(
      legacyLineClamp: RenderLayoutStateWrapper.LegacyLineClamp(
        maximumLineCount: lineCountForLineClamp(&iterator), currentLineCount: 0,
        clampedContentLogicalHeight: nil, clampedRenderer: nil))
    do {
      var child = iterator.first()
      while child != nil {
        if child!.isOutOfFlowPositioned() {
          child = iterator.next()
          continue
        }

        child!.markForPaginationRelayoutIfNeeded()
        child!.layoutIfNeeded()
        child = iterator.next()
      }
    }

    let lineClamp = layoutState.legacyLineClamp()!
    if lineClamp.clampedContentLogicalHeight == nil {
      // We've managed to run line clamping but it came back with no clamped content (i.e. there are fewer lines than the line-clamp limit).
      return ClampedContent()
    }

    return ClampedContent(lineClamp.clampedContentLogicalHeight!, lineClamp.clampedRenderer)
  }

  private var stretchingChildren = false
}
