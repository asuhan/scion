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

// TODO(asuhan): use an inline capacity of 8
typealias ChildFrameRects = [LayoutRectWrapper]

private func appendChildFrameRects(
  _ box: RenderDeprecatedFlexibleBoxWrapper?, _ childFrameRects: inout ChildFrameRects
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func repaintChildrenDuringLayoutIfMoved(
  _ box: RenderDeprecatedFlexibleBoxWrapper?, _ oldChildRects: ChildFrameRects
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())

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

      setHeight(height: 0)

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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func layoutVerticalBox(_ relayoutChildren: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isStretchingChildren() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func avoidsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

    maxPreferredLogicalWidth = LayoutUnit(value: 0)
    minPreferredLogicalWidth = maxPreferredLogicalWidth
    if style().width().isFixed() && style().width().value() > 0 {
      maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().width())
      minPreferredLogicalWidth = maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &minPreferredLogicalWidth, maxLogicalWidth: &maxPreferredLogicalWidth)
    }

    super.computePreferredLogicalWidths(
      minWidth: style().minWidth(), maxWidth: style().maxWidth(),
      borderAndPadding: borderAndPaddingLogicalWidth())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  private func hasMultipleLines() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isVertical() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isHorizontal() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func clearLineClamp() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var stretchingChildren = false
}
