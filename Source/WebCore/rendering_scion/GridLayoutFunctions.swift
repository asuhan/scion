/*
 * Copyright (C) 2017 Igalia S.L.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct GridAxis: OptionSet {
  let rawValue: UInt8

  static let GridRowAxis = GridAxis(rawValue: 1 << 0)
  static let GridColumnAxis = GridAxis(rawValue: 1 << 1)
}

struct ExtraMarginsFromSubgrids {
  func extraTotalMargin() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  static func += (lhs: inout ExtraMarginsFromSubgrids, rhs: ExtraMarginsFromSubgrids)
    -> ExtraMarginsFromSubgrids
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

class GridLayoutFunctions {
  private static func marginStartIsAuto(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> Bool {
    return direction == .ForColumns
      ? gridItem.style().marginStart().isAuto() : gridItem.style().marginBefore().isAuto()
  }

  private static func marginEndIsAuto(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> Bool {
    return direction == .ForColumns
      ? gridItem.style().marginEnd().isAuto() : gridItem.style().marginAfter().isAuto()
  }

  private static func gridItemHasMargin(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> Bool {
    // Length::IsZero returns true for 'auto' margins, which is aligned with the purpose of this function.
    if direction == .ForColumns {
      return !gridItem.style().marginStart().isZero() || !gridItem.style().marginEnd().isZero()
    }
    return !gridItem.style().marginBefore().isZero() || !gridItem.style().marginAfter().isZero()
  }

  private static func computeMarginLogicalSizeForGridItem(
    grid: RenderGridWrapper, direction: GridTrackSizingDirection, gridItem: RenderBoxWrapper
  ) -> LayoutUnit {
    let flowAwareDirection = flowAwareDirectionForGridItem(
      grid: grid, gridItem: gridItem, direction: direction)
    if !gridItemHasMargin(gridItem: gridItem, direction: flowAwareDirection) {
      return LayoutUnit(value: 0)
    }

    var marginStart = LayoutUnit()
    var marginEnd = LayoutUnit()
    if direction == .ForColumns {
      gridItem.computeInlineDirectionMargins(
        containingBlock: grid,
        containerWidth: gridItem.containingBlockLogicalWidthForContentInFragment(fragment: nil),
        availableSpaceAdjustedWithFloats: nil, childWidth: gridItem.logicalWidth(),
        marginStart: &marginStart, marginEnd: &marginEnd)
    } else {
      gridItem.computeBlockDirectionMargins(
        containingBlock: grid, marginBefore: &marginStart, marginAfter: &marginEnd)
    }
    return marginStartIsAuto(gridItem: gridItem, direction: flowAwareDirection)
      ? marginEnd
      : marginEndIsAuto(gridItem: gridItem, direction: flowAwareDirection)
        ? marginStart : marginStart + marginEnd
  }

  private static func extraMarginForSubgrid(
    parent: RenderGridWrapper, startLine: UInt32, endLine: UInt32,
    direction: GridTrackSizingDirection
  ) -> ExtraMarginsFromSubgrids {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private static func extraMarginForSubgridAncestors(
    direction: GridTrackSizingDirection, gridItem: RenderBoxWrapper
  ) -> ExtraMarginsFromSubgrids {
    var extraMargins = ExtraMarginsFromSubgrids()
    for currentAncestorSubgrid in ancestorSubgridsOfGridItem(
      gridItem: gridItem, direction: direction)
    {
      let span = currentAncestorSubgrid.gridSpanForGridItem(
        gridItem: gridItem, direction: direction)
      extraMargins += extraMarginForSubgrid(
        parent: currentAncestorSubgrid, startLine: span.startLine(), endLine: span.endLine(),
        direction: direction)
    }
    return extraMargins
  }

  static func marginLogicalSizeForGridItem(
    grid: RenderGridWrapper, direction: GridTrackSizingDirection, gridItem: RenderBoxWrapper
  ) -> LayoutUnit {
    var margin = computeMarginLogicalSizeForGridItem(
      grid: grid, direction: direction, gridItem: gridItem)

    if CPtrToInt(grid.p) != CPtrToInt(gridItem.parent()?.p) {
      let subgridDirection = flowAwareDirectionForGridItem(
        grid: grid, gridItem: gridItem.parent() as! RenderGridWrapper, direction: direction)
      margin += extraMarginForSubgridAncestors(direction: subgridDirection, gridItem: gridItem)
        .extraTotalMargin()
    }

    return margin
  }

  static func isOrthogonalGridItem(grid: RenderGridWrapper, gridItem: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func isGridItemInlineSizeDependentOnBlockConstraints(
    gridItem: RenderBoxWrapper, parentGrid: RenderGridWrapper, gridItemAlignSelf: ItemPosition
  ) -> Bool {
    assert(CPtrToInt(gridItem.parent()?.p) == CPtrToInt(parentGrid.p))

    if isOrthogonalGridItem(grid: parentGrid, gridItem: gridItem) {
      return true
    }

    let gridItemStyle = gridItem.style()
    let gridItemFlexWrap = gridItemStyle.flexWrap()
    if gridItem.isRenderFlexibleBox() && gridItem.style().isColumnFlexDirection()
      && (gridItemFlexWrap == .Wrap || gridItemFlexWrap == .Reverse)
    {
      return true
    }

    if gridItem.isRenderMultiColumnFlow() {
      return true
    }

    if isAspectRatioBlockSizeDependentGridItem(gridItem: gridItem) {
      return true
    }

    // Stretch alignment allows the grid item content to resolve against the stretched size.
    if gridItemAlignSelf != .Stretch {
      return false
    }

    for gridItemChild: RenderObjectWrapper in childrenOfType(parent: gridItem) {
      if hasAspectRatioAndInlineSizeDependsOnBlockSize(renderer: gridItemChild) {
        return true
      }
    }

    return false
  }

  private static func hasAspectRatioAndInlineSizeDependsOnBlockSize(renderer: RenderObjectWrapper)
    -> Bool
  {
    let rendererStyle = renderer.style()
    let rendererHasAspectRatio =
      renderer.hasIntrinsicAspectRatio() || rendererStyle.hasAspectRatio()

    return rendererHasAspectRatio && rendererStyle.logicalWidth().isAuto()
      && !rendererStyle.logicalHeight().isIntrinsicOrAuto()
  }

  static func isAspectRatioBlockSizeDependentGridItem(gridItem: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func flowAwareDirectionForGridItem(
    grid: RenderGridWrapper, gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> GridTrackSizingDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func flowAwareDirectionForParent(
    grid: RenderGridWrapper, parent: RenderElementWrapper, direction: GridTrackSizingDirection
  ) -> GridTrackSizingDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func overridingContainingBlockContentSizeForGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> RenderBoxWrapper
    .ContainingBlockOverrideValue?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func isSubgridReversedDirection(
    grid: RenderGridWrapper, outerDirection: GridTrackSizingDirection, subgrid: RenderGridWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func alignmentContextForBaselineAlignment(span: GridSpan, alignment: ItemPosition)
    -> UInt32
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
