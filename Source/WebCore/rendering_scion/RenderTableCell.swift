/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2009 Apple Inc. All rights reserved.
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

private struct CollapsedBorder {
  var borderValue = CollapsedBorderValue()
  var side: BoxSide = .Top
  var shouldPaint = false
  var x1 = LayoutUnit()
  var y1 = LayoutUnit()
  var x2 = LayoutUnit()
  var y2 = LayoutUnit()
  var style: BorderStyle = .None
}

private struct CollapsedBorders {
  mutating func addBorder(
    borderValue: CollapsedBorderValue, borderSide: BoxSide, shouldPaint: Bool, x1: LayoutUnit,
    y1: LayoutUnit, x2: LayoutUnit, y2: LayoutUnit, borderStyle: BorderStyle
  ) {
    if borderValue.exists() && shouldPaint {
      var border = CollapsedBorder()
      border.borderValue = borderValue
      border.side = borderSide
      border.shouldPaint = shouldPaint
      border.x1 = x1
      border.x2 = x2
      border.y1 = y1
      border.y2 = y2
      border.style = borderStyle
      borders.append(border)
    }
  }

  mutating func nextBorder() -> CollapsedBorder? {
    for (i, border) in borders.enumerated() {
      if border.borderValue.exists() && border.shouldPaint {
        borders[i].shouldPaint = false
        return borders[i]
      }
    }

    return nil
  }

  private var borders: [CollapsedBorder] = []
}

private func chooseBorder(border1: CollapsedBorderValue, border2: CollapsedBorderValue)
  -> CollapsedBorderValue
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func emptyBorder() -> CollapsedBorderValue {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func addBorderStyle(
  borderValues: inout RenderTableWrapper.CollapsedBorderValues, borderValue: CollapsedBorderValue
) {
  if !borderValue.exists() {
    return
  }
  for thisBorderValue in borderValues {
    if thisBorderValue.isSameIgnoringColor(o: borderValue) {
      return
    }
  }
  borderValues.append(borderValue)
}

private func backgroundRectForRow(tableRow: RenderBoxWrapper, table: RenderTableWrapper)
  -> LayoutRectWrapper
{
  let rect = tableRow.frameRect()
  if !table.collapseBorders() {
    // Row frameRects include unwanted hSpacing on both inline ends.
    let hSpacing = table.hBorderSpacing()
    let vSpacing = LayoutUnit(value: UInt64(0))
    if table.style().isHorizontalWritingMode() {
      rect.contract(
        box: LayoutBoxExtent(top: vSpacing, right: hSpacing, bottom: vSpacing, left: hSpacing))
    } else {
      rect.contract(
        box: LayoutBoxExtent(top: hSpacing, right: vSpacing, bottom: hSpacing, left: vSpacing))
    }
  }
  return rect
}

private func backgroundRectForSection(
  tableSection: RenderTableSectionWrapper, table: RenderTableWrapper
) -> LayoutRectWrapper {
  let rect = LayoutRectWrapper(location: LayoutPointWrapper(), size: tableSection.size())
  if !table.collapseBorders() {
    let hSpacing = table.hBorderSpacing()
    let vSpacing = table.vBorderSpacing()
    // All sections' size()s include unwanted vSpacing at the block-end
    // position. The first section's size() includes additional unwanted
    // vSpacing at the block-start position. All sections' size()s include
    // unwanted hSpacing on both inline ends.
    let beforeBlockSpacing =
      CPtrToInt(tableSection.p) == CPtrToInt(table.topSection()?.p)
      ? vSpacing : LayoutUnit(value: UInt64(0))
    if table.style().isHorizontalWritingMode() {
      rect.contract(
        box: LayoutBoxExtent(
          top: beforeBlockSpacing, right: hSpacing, bottom: vSpacing, left: hSpacing))
    } else if table.style().isFlippedBlocksWritingMode() {
      rect.contract(
        box: LayoutBoxExtent(
          top: hSpacing, right: beforeBlockSpacing, bottom: hSpacing, left: vSpacing))
    } else {
      rect.contract(
        box: LayoutBoxExtent(
          top: hSpacing, right: vSpacing, bottom: hSpacing, left: beforeBlockSpacing))
    }
  }
  return rect
}

private enum IncludeBorderColorOrNot {
  case DoNotIncludeBorderColor
  case IncludeBorderColor
}

final class RenderTableCellWrapper: RenderBlockFlowWrapper {
  func colSpan() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowSpan() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func col() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextCell() -> RenderTableCellWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func previousCell() -> RenderTableCellWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func row() -> RenderTableRowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func section() -> RenderTableSectionWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func table() -> RenderTableWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowIndex() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func styleOrColLogicalWidth() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderLeft() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfLeft(outer: false) : super.borderLeft()
    }
    return super.borderLeft()
  }

  override func borderRight() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfRight(outer: false) : super.borderRight()
    }
    return super.borderRight()
  }

  override func borderTop() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfTop(outer: false) : super.borderTop()
    }
    return super.borderTop()
  }

  override func borderBottom() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfBottom(outer: false) : super.borderBottom()
    }
    return super.borderBottom()
  }

  // FIXME: https://bugs.webkit.org/show_bug.cgi?id=46191, make the collapsed border drawing
  // work with different block flow values instead of being hard-coded to top-to-bottom.
  override func borderStart() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfStart(outer: false) : super.borderStart()
    }
    return super.borderStart()
  }

  override func borderEnd() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfEnd(outer: false) : super.borderEnd()
    }
    return super.borderEnd()
  }

  override func borderBefore() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfBefore(outer: false) : super.borderBefore()
    }
    return super.borderBefore()
  }

  override func borderAfter() -> LayoutUnit {
    if let table = table() {
      return table.collapseBorders() ? borderHalfAfter(outer: false) : super.borderAfter()
    }
    return super.borderAfter()
  }

  func collectBorderValues(borderValues: inout RenderTableWrapper.CollapsedBorderValues) {
    addBorderStyle(borderValues: &borderValues, borderValue: collapsedStartBorder())
    addBorderStyle(borderValues: &borderValues, borderValue: collapsedEndBorder())
    addBorderStyle(borderValues: &borderValues, borderValue: collapsedBeforeBorder())
    addBorderStyle(borderValues: &borderValues, borderValue: collapsedAfterBorder())
  }

  static func sortBorderValues(borderValues: inout RenderTableWrapper.CollapsedBorderValues) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats

    let oldCellBaseline = cellBaselinePosition()
    layoutBlock(relayoutChildren: cellWidthChanged())

    // If we have replaced content, the intrinsic height of our content may have changed since the last time we laid out. If that's the case the intrinsic padding we used
    // for layout (the padding required to push the contents of the cell down to the row's baseline) is included in our new height and baseline and makes both
    // of them wrong. So if our content's intrinsic height has changed push the new content up into the intrinsic padding and relayout so that the rest of
    // table and row layout can use the correct baseline and height for this cell.
    if isBaselineAligned() && section()!.rowBaseline(row: rowIndex()).bool()
      && cellBaselinePosition() > section()!.rowBaseline(row: rowIndex())
    {
      let zero = LayoutUnit(value: 0)
      let newIntrinsicPaddingBefore = max(
        zero, intrinsicPaddingBefore() - max(zero, cellBaselinePosition() - oldCellBaseline))
      setIntrinsicPaddingBefore(p: newIntrinsicPaddingBefore)
      setNeedsLayout(markParents: .MarkOnlyThis)
      layoutBlock(relayoutChildren: cellWidthChanged())
    }
    invalidateHasEmptyCollapsedBorders()

    // FIXME: This value isn't the intrinsic content logical height, but we need
    // to update the value as its used by flexbox layout. crbug.com/367324
    cacheIntrinsicContentLogicalHeightForFlexItem(height: contentLogicalHeight())

    setCellWidthChanged(b: false)
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(paintInfo.phase != .CollapsedTableBorders)
    super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
  }

  func paintCollapsedBorders(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(paintInfo.phase == .CollapsedTableBorders)

    if !paintInfo.shouldPaintWithinRoot(renderer: self) || style().usedVisibility() != .Visible {
      return
    }

    let localRepaintRect = paintInfo.rect
    let paintRect = LayoutRectWrapper(location: paintOffset + location(), size: frameRect().size())
    if paintRect.y() - table()!.outerBorderTop() >= localRepaintRect.maxY() {
      return
    }

    if paintRect.maxY() + table()!.outerBorderBottom() <= localRepaintRect.y() {
      return
    }

    let graphicsContext = paintInfo.context()
    if table()!.currentBorderValue() == nil || graphicsContext.paintingDisabled() {
      return
    }

    let styleForCellFlow = styleForCellFlow()
    let leftVal = cachedCollapsedLeftBorder(styleForCellFlow: styleForCellFlow)
    let rightVal = cachedCollapsedRightBorder(styleForCellFlow: styleForCellFlow)
    let topVal = cachedCollapsedTopBorder(styleForCellFlow: styleForCellFlow)
    let bottomVal = cachedCollapsedBottomBorder(styleForCellFlow: styleForCellFlow)

    // Adjust our x/y/width/height so that we paint the collapsed borders at the correct location.
    let topWidth = topVal.width()
    let bottomWidth = bottomVal.width()
    let leftWidth = leftVal.width()
    let rightWidth = rightVal.width()

    let deviceScaleFactor = document().deviceScaleFactor()
    let leftHalfCollapsedBorder = CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: leftWidth.float(), deviceScaleFactor: deviceScaleFactor, roundUp: false)
    let topHalfCollapsedBorder = CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: topWidth.float(), deviceScaleFactor: deviceScaleFactor, roundUp: false)
    let righHalftCollapsedBorder = CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: rightWidth.float(), deviceScaleFactor: deviceScaleFactor, roundUp: true)
    let bottomHalfCollapsedBorder = CollapsedBorderValue.adjustedCollapsedBorderWidth(
      borderWidth: bottomWidth.float(), deviceScaleFactor: deviceScaleFactor, roundUp: true)

    let borderRect = LayoutRectWrapper(
      x: paintRect.x() - leftHalfCollapsedBorder,
      y: paintRect.y() - topHalfCollapsedBorder,
      width: paintRect.width() + leftHalfCollapsedBorder + righHalftCollapsedBorder,
      height: paintRect.height() + topHalfCollapsedBorder + bottomHalfCollapsedBorder)

    let topStyle = collapsedBorderStyle(style: topVal.style)
    let bottomStyle = collapsedBorderStyle(style: bottomVal.style)
    let leftStyle = collapsedBorderStyle(style: leftVal.style)
    let rightStyle = collapsedBorderStyle(style: rightVal.style)

    let hidden = BorderStyle.Hidden.rawValue
    let renderTop =
      topStyle.rawValue > hidden && !topVal.isTransparent()
      && floorToDevicePixel(value: topWidth, pixelSnappingFactor: deviceScaleFactor) != 0
    let renderBottom =
      bottomStyle.rawValue > hidden && !bottomVal.isTransparent()
      && floorToDevicePixel(value: bottomWidth, pixelSnappingFactor: deviceScaleFactor) != 0
    let renderLeft =
      leftStyle.rawValue > hidden && !leftVal.isTransparent()
      && floorToDevicePixel(value: leftWidth, pixelSnappingFactor: deviceScaleFactor) != 0
    let renderRight =
      rightStyle.rawValue > hidden && !rightVal.isTransparent()
      && floorToDevicePixel(value: rightWidth, pixelSnappingFactor: deviceScaleFactor) != 0

    // We never paint diagonals at the joins.  We simply let the border with the highest
    // precedence paint on top of borders with lower precedence.
    var borders = CollapsedBorders()
    borders.addBorder(
      borderValue: topVal, borderSide: .Top, shouldPaint: renderTop, x1: borderRect.x(),
      y1: borderRect.y(),
      x2: borderRect.maxX(),
      y2: borderRect.y() + topWidth, borderStyle: topStyle)
    borders.addBorder(
      borderValue: bottomVal, borderSide: .Bottom, shouldPaint: renderBottom, x1: borderRect.x(),
      y1: borderRect.maxY() - bottomWidth,
      x2: borderRect.maxX(), y2: borderRect.maxY(), borderStyle: bottomStyle)
    borders.addBorder(
      borderValue: leftVal, borderSide: .Left, shouldPaint: renderLeft, x1: borderRect.x(),
      y1: borderRect.y(),
      x2: borderRect.x() + leftWidth,
      y2: borderRect.maxY(), borderStyle: leftStyle)
    borders.addBorder(
      borderValue: rightVal, borderSide: .Right, shouldPaint: renderRight,
      x1: borderRect.maxX() - rightWidth,
      y1: borderRect.y(),
      x2: borderRect.maxX(), y2: borderRect.maxY(), borderStyle: rightStyle)

    let antialias = BorderPainter.shouldAntialiasLines(context: graphicsContext)

    var border = borders.nextBorder()
    while border != nil {
      if border!.borderValue.isSameIgnoringColor(o: table()!.currentBorderValue()!) {
        BorderPainter.drawLineForBoxSide(
          graphicsContext: graphicsContext, document: document(),
          rect: LayoutRectWrapper(
            topLeft: LayoutPointWrapper(x: border!.x1, y: border!.y1),
            bottomRight: LayoutPointWrapper(x: border!.x2, y: border!.y2)
          ).FloatRect(),
          side: border!.side,
          color: border!.borderValue.color, borderStyle: border!.style, adjacentWidth1: 0,
          adjacentWidth2: 0, antialias: antialias)
      }
      border = borders.nextBorder()
    }
  }

  func paintBackgroundsBehindCell(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
    backgroundObject: RenderBoxWrapper, backgroundPaintOffset: LayoutPointWrapper
  ) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    if style().usedVisibility() != .Visible {
      return
    }

    let tableElt = table()
    if !tableElt!.collapseBorders() && style().emptyCells() == .Hide && firstChild() == nil {
      return
    }

    let style = backgroundObject.style()
    let bgLayer = style.backgroundLayers()

    var color = style.visitedDependentColor(colorProperty: .CSSPropertyBackgroundColor)
    if !bgLayer.hasImage() && !color.isVisible() {
      return
    }

    color = style.colorByApplyingColorFilter(color: color)

    var adjustedPaintOffset = paintOffset
    if CPtrToInt(backgroundObject.p) != CPtrToInt(p) {
      adjustedPaintOffset.moveBy(offset: location())
    }

    // Background images attached to the row or row group must span the row
    // or row group. Draw them at the backgroundObject's dimensions, but
    // clipped to this cell.
    // FIXME: This should also apply to columns and column groups.
    let paintBackgroundObject =
      CPtrToInt(backgroundObject.p) != CPtrToInt(p) && bgLayer.hasImage()
      && !(backgroundObject is RenderTableColWrapper)
    // We have to clip here because the background would paint
    // on top of the borders otherwise. This only matters for cells and rows.
    let shouldClip =
      paintBackgroundObject
      || (backgroundObject.hasLayer()
        && (CPtrToInt(backgroundObject.p) == CPtrToInt(p)
          || CPtrToInt(backgroundObject.p) == CPtrToInt(parent()?.p))
        && tableElt!.collapseBorders())
    let _ = GraphicsContextStateSaver(context: paintInfo.context(), saveAndRestore: shouldClip)
    if paintBackgroundObject {
      paintInfo.context().clip(
        rect: LayoutRectWrapper(location: adjustedPaintOffset, size: size()).FloatRect())
    } else if shouldClip {
      let clipRect = LayoutRectWrapper(
        x: adjustedPaintOffset.x + borderLeft(), y: adjustedPaintOffset.y + borderTop(),
        width: width() - borderLeft() - borderRight(),
        height: height() - borderTop() - borderBottom())
      paintInfo.context().clip(rect: clipRect.FloatRect())
    }
    var fillRect = LayoutRectWrapper()
    if paintBackgroundObject {
      if let tableSectionRenderer = backgroundObject as? RenderTableSectionWrapper {
        fillRect = backgroundRectForSection(tableSection: tableSectionRenderer, table: tableElt!)
      } else {
        fillRect = backgroundRectForRow(tableRow: backgroundObject, table: tableElt!)
      }
      fillRect.moveBy(offset: backgroundPaintOffset)
    } else {
      fillRect = LayoutRectWrapper(location: adjustedPaintOffset, size: size())
    }
    let compositeOp = document().compositeOperatorForBackgroundColor(color: color, renderer: self)
    let painter = BackgroundPainter(renderer: self, paintInfo: paintInfo)
    if CPtrToInt(backgroundObject.p) != CPtrToInt(p) {
      painter.setOverrideClip(overrideClip: .BorderBox)
      painter.setOverrideOrigin(overrideOrigin: .BorderBox)
    }
    painter.paintFillLayers(
      color: color, fillLayer: bgLayer, rect: fillRect, bleedAvoidance: .BackgroundBleedNone,
      op: compositeOp, backgroundObject: backgroundObject)
  }

  private func cellBaselinePosition() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isBaselineAligned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func intrinsicPaddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: For now we just assume the cell has the same block flow direction as the table. It's likely we'll
  // create an extra anonymous RenderBlock to handle mixing directionality anyway, in which case we can lock
  // the block flow directionality of the cells to the table's directionality.
  override func paddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cellWidthChanged() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setCellWidthChanged(b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func createAnonymousWithParentRenderer(parent: RenderTableRowWrapper)
    -> RenderTableCellWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createAnonymousBoxWithSameTypeAs(renderer: RenderBoxWrapper) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This function is used to unify which table part's style we use for computing direction and
  // writing mode. Writing modes are not allowed on internal table boxes.
  // This means we can safely use the same style in all cases to simplify our code.
  func styleForCellFlow() -> RenderStyleWrapper { return table()!.style() }

  func borderAdjoiningTableStart() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderAdjoiningTableEnd() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderAdjoiningCellBefore(cell: RenderTableCellWrapper) -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderAdjoiningCellAfter(cell: RenderTableCellWrapper) -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateHasEmptyCollapsedBorders() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setHasEmptyCollapsedBorder(side: CollapsedBorderSide, empty: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func frameRectForStickyPositioning() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintBoxDecorations(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    let table = table()
    if !table!.collapseBorders() && style().emptyCells() == .Hide && firstChild() == nil {
      return
    }

    var paintRect = LayoutRectWrapper(location: paintOffset, size: frameRect().size())
    adjustBorderBoxRectForPainting(paintRect: &paintRect)

    let backgroundPainter = BackgroundPainter(renderer: self, paintInfo: paintInfo)
    backgroundPainter.paintBoxShadow(paintRect: paintRect, style: style(), shadowStyle: .Normal)

    // Paint our cell background.
    paintBackgroundsBehindCell(
      paintInfo: paintInfo, paintOffset: paintOffset, backgroundObject: self,
      backgroundPaintOffset: paintOffset)

    backgroundPainter.paintBoxShadow(paintRect: paintRect, style: style(), shadowStyle: .Inset)

    if !style().hasBorder() || table!.collapseBorders() {
      return
    }

    let borderPainter = BorderPainter(renderer: self, paintInfo: paintInfo)
    borderPainter.paintBorder(rect: paintRect, style: style())
  }

  override func paintMask(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if style().usedVisibility() != .Visible || paintInfo.phase != .Mask {
      return
    }

    let tableElt = table()!
    if !tableElt.collapseBorders() && style().emptyCells() == .Hide && firstChild() == nil {
      return
    }

    var paintRect = LayoutRectWrapper(location: paintOffset, size: frameRect().size())
    adjustBorderBoxRectForPainting(paintRect: &paintRect)

    paintMaskImages(paintInfo: paintInfo, paintRect: paintRect)
  }

  private func borderHalfLeft(outer: Bool) -> LayoutUnit {
    let styleForCellFlow = styleForCellFlow()
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection()
        ? borderHalfStart(outer: outer) : borderHalfEnd(outer: outer)
    }
    return styleForCellFlow.isFlippedBlocksWritingMode()
      ? borderHalfAfter(outer: outer) : borderHalfBefore(outer: outer)
  }

  private func borderHalfRight(outer: Bool) -> LayoutUnit {
    let styleForCellFlow = styleForCellFlow()
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection()
        ? borderHalfEnd(outer: outer) : borderHalfStart(outer: outer)
    }
    return styleForCellFlow.isFlippedBlocksWritingMode()
      ? borderHalfBefore(outer: outer) : borderHalfAfter(outer: outer)
  }

  private func borderHalfTop(outer: Bool) -> LayoutUnit {
    let styleForCellFlow = styleForCellFlow()
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isFlippedBlocksWritingMode()
        ? borderHalfAfter(outer: outer) : borderHalfBefore(outer: outer)
    }
    return styleForCellFlow.isLeftToRightDirection()
      ? borderHalfStart(outer: outer) : borderHalfEnd(outer: outer)
  }

  private func borderHalfBottom(outer: Bool) -> LayoutUnit {
    let styleForCellFlow = styleForCellFlow()
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isFlippedBlocksWritingMode()
        ? borderHalfBefore(outer: outer) : borderHalfAfter(outer: outer)
    }
    return styleForCellFlow.isLeftToRightDirection()
      ? borderHalfEnd(outer: outer) : borderHalfStart(outer: outer)
  }

  private func borderHalfStart(outer: Bool) -> LayoutUnit {
    let border = collapsedStartBorder(includeColor: .DoNotIncludeBorderColor)
    if border.exists() {
      return CollapsedBorderValue.adjustedCollapsedBorderWidth(
        borderWidth: border.width().float(), deviceScaleFactor: document().deviceScaleFactor(),
        roundUp: styleForCellFlow().isLeftToRightDirection() != outer)
    }
    return LayoutUnit(value: 0)
  }

  private func borderHalfEnd(outer: Bool) -> LayoutUnit {
    let border = collapsedEndBorder(includeColor: .DoNotIncludeBorderColor)
    if border.exists() {
      return CollapsedBorderValue.adjustedCollapsedBorderWidth(
        borderWidth: border.width().float(), deviceScaleFactor: document().deviceScaleFactor(),
        roundUp: styleForCellFlow().isLeftToRightDirection() == outer)
    }
    return LayoutUnit(value: 0)
  }

  private func borderHalfBefore(outer: Bool) -> LayoutUnit {
    let border = collapsedBeforeBorder(includeColor: .DoNotIncludeBorderColor)
    if border.exists() {
      return CollapsedBorderValue.adjustedCollapsedBorderWidth(
        borderWidth: border.width().float(), deviceScaleFactor: document().deviceScaleFactor(),
        roundUp: styleForCellFlow().isFlippedBlocksWritingMode() == outer)
    }
    return LayoutUnit(value: 0)
  }

  private func borderHalfAfter(outer: Bool) -> LayoutUnit {
    let border = collapsedAfterBorder(includeColor: .DoNotIncludeBorderColor)
    if border.exists() {
      return CollapsedBorderValue.adjustedCollapsedBorderWidth(
        borderWidth: border.width().float(), deviceScaleFactor: document().deviceScaleFactor(),
        roundUp: styleForCellFlow().isFlippedBlocksWritingMode() != outer)
    }
    return LayoutUnit(value: 0)
  }

  private func setIntrinsicPaddingBefore(p: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasStartBorderAdjoiningTable() -> Bool {
    return col() == 0
  }

  private func hasEndBorderAdjoiningTable() -> Bool {
    return table()!.colToEffCol(column: col() + colSpan() - 1) == table()!.numEffCols() - 1
  }

  private func collapsedStartBorder(includeColor: IncludeBorderColorOrNot = .IncludeBorderColor)
    -> CollapsedBorderValue
  {
    if table() == nil || section() == nil {
      return emptyBorder()
    }

    if hasEmptyCollapsedStartBorder {
      return emptyBorder()
    }

    if table()!.collapsedBordersAreValid() {
      return section()!.cachedCollapsedBorder(cell: self, side: .CBSStart)
    }

    let result = computeCollapsedStartBorder(includeColor: includeColor)
    setHasEmptyCollapsedBorder(side: .CBSStart, empty: !result.width().bool())
    if includeColor == .IncludeBorderColor && !hasEmptyCollapsedStartBorder {
      section()!.setCachedCollapsedBorder(cell: self, side: .CBSStart, border: result)
    }
    return result
  }

  private func collapsedEndBorder(includeColor: IncludeBorderColorOrNot = .IncludeBorderColor)
    -> CollapsedBorderValue
  {
    if table() == nil || section() == nil {
      return emptyBorder()
    }

    if hasEmptyCollapsedEndBorder {
      return emptyBorder()
    }

    if table()!.collapsedBordersAreValid() {
      return section()!.cachedCollapsedBorder(cell: self, side: .CBSEnd)
    }

    let result = computeCollapsedEndBorder(includeColor: includeColor)
    setHasEmptyCollapsedBorder(side: .CBSEnd, empty: !result.width().bool())
    if includeColor == .IncludeBorderColor && !hasEmptyCollapsedEndBorder {
      section()!.setCachedCollapsedBorder(cell: self, side: .CBSEnd, border: result)
    }
    return result
  }

  private func collapsedBeforeBorder(includeColor: IncludeBorderColorOrNot = .IncludeBorderColor)
    -> CollapsedBorderValue
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func collapsedAfterBorder(includeColor: IncludeBorderColorOrNot = .IncludeBorderColor)
    -> CollapsedBorderValue
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cachedCollapsedLeftBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cachedCollapsedRightBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cachedCollapsedTopBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func cachedCollapsedBottomBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeCollapsedStartBorder(
    includeColor: IncludeBorderColorOrNot = .IncludeBorderColor
  ) -> CollapsedBorderValue {
    // For the start border, we need to check, in order of precedence:
    // (1) Our start border.
    let startColorProperty: CSSPropertyID =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderInlineStartColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    let endColorProperty: CSSPropertyID =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderInlineEndColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    var result = CollapsedBorderValue(
      border: style().borderStart(styleForFlow: styleForCellFlow()),
      color: includeColor == .IncludeBorderColor
        ? style().visitedDependentColorWithColorFilter(colorProperty: startColorProperty)
        : ColorWrapper(),
      precedence: .Cell)

    let table = table()
    if table == nil {
      return result
    }
    // (2) The end border of the preceding cell.
    let cellBefore = table!.cellBefore(cell: self)
    if cellBefore != nil {
      let cellBeforeAdjoiningBorder = CollapsedBorderValue(
        border: cellBefore!.borderAdjoiningCellAfter(cell: self),
        color: includeColor == .IncludeBorderColor
          ? cellBefore!.style().visitedDependentColorWithColorFilter(
            colorProperty: endColorProperty) : ColorWrapper(), precedence: .Cell)
      // |result| should be the 2nd argument as |cellBefore| should win in case of equality per CSS 2.1 (Border conflict resolution, point 4).
      result = chooseBorder(border1: cellBeforeAdjoiningBorder, border2: result)
      if !result.exists() {
        return result
      }
    }

    let startBorderAdjoinsTable = hasStartBorderAdjoiningTable()
    if startBorderAdjoinsTable {
      // (3) Our row's start border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: row()!.borderAdjoiningStartCell(cell: self),
          color: includeColor == .IncludeBorderColor
            ? parent()!.style().visitedDependentColorWithColorFilter(
              colorProperty: startColorProperty)
            : ColorWrapper(), precedence: .Row))
      if !result.exists() {
        return result
      }

      // (4) Our row group's start border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: section()!.borderAdjoiningStartCell(cell: self),
          color: includeColor == .IncludeBorderColor
            ? section()!.style().visitedDependentColorWithColorFilter(
              colorProperty: startColorProperty) : ColorWrapper(), precedence: .RowGroup))
      if !result.exists() {
        return result
      }
    }

    // (5) Our column and column group's start borders.
    var startColEdge = false
    var endColEdge = false
    if let colElt = table!.colElement(col: col(), startEdge: &startColEdge, endEdge: &endColEdge) {
      if colElt.isTableColumnGroup() && startColEdge {
        // The |colElt| is a column group and is also the first colgroup (in case of spanned colgroups).
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellStartBorder(),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(
                colorProperty: startColorProperty) : ColorWrapper(), precedence: .ColumnGroup))
        if !result.exists() {
          return result
        }
      } else if !colElt.isTableColumnGroup() {
        // We first consider the |colElt| and irrespective of whether it is a spanned col or not, we apply
        // its start border. This is as per HTML5 which states that: "For the purposes of the CSS table model,
        // the col element is expected to be treated as if it was present as many times as its span attribute specifies".
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellStartBorder(),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(
                colorProperty: startColorProperty) : ColorWrapper(), precedence: .Column))
        if !result.exists() {
          return result
        }
        // Next, apply the start border of the enclosing colgroup but only if it is adjacent to the cell's edge.
        if let enclosingColumnGroup = colElt.enclosingColumnGroupIfAdjacentBefore() {
          result = chooseBorder(
            border1: result,
            border2: CollapsedBorderValue(
              border: enclosingColumnGroup.borderAdjoiningCellStartBorder(),
              color: includeColor == .IncludeBorderColor
                ? enclosingColumnGroup.style().visitedDependentColorWithColorFilter(
                  colorProperty: startColorProperty) : ColorWrapper(), precedence: .ColumnGroup))
          if !result.exists() {
            return result
          }
        }
      }
    }

    // (6) The end border of the preceding column.
    if cellBefore != nil,
      let colElt = table!.colElement(
        col: col() - 1, startEdge: &startColEdge, endEdge: &endColEdge)
    {
      if colElt.isTableColumnGroup() && endColEdge {
        // The element is a colgroup and is also the last colgroup (in case of spanned colgroups).
        result = chooseBorder(
          border1: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellAfter(cell: self),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(
                colorProperty: endColorProperty)
              : ColorWrapper(), precedence: .ColumnGroup), border2: result)
        if !result.exists() {
          return result
        }
      } else if colElt.isTableColumn() {
        // Resolve the collapsing border against the col's border ignoring any 'span' as per HTML5.
        result = chooseBorder(
          border1: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellAfter(cell: self),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(
                colorProperty: endColorProperty)
              : ColorWrapper(), precedence: .Column), border2: result)
        if !result.exists() {
          return result
        }
        // Next, if the previous col has a parent colgroup then its end border should be applied
        // but only if it is adjacent to the cell's edge.
        if let enclosingColumnGroup = colElt.enclosingColumnGroupIfAdjacentAfter() {
          result = chooseBorder(
            border1: CollapsedBorderValue(
              border: enclosingColumnGroup.borderAdjoiningCellEndBorder(),
              color: includeColor == .IncludeBorderColor
                ? enclosingColumnGroup.style().visitedDependentColorWithColorFilter(
                  colorProperty: endColorProperty) : ColorWrapper(), precedence: .ColumnGroup),
            border2: result)
          if !result.exists() {
            return result
          }
        }
      }
    }

    if startBorderAdjoinsTable {
      // (7) The table's start border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: table!.style().borderStart(),
          color: includeColor == .IncludeBorderColor
            ? table!.style().visitedDependentColorWithColorFilter(colorProperty: startColorProperty)
            : ColorWrapper(), precedence: .Table))
      if !result.exists() {
        return result
      }
    }

    return result
  }

  private func computeCollapsedEndBorder(
    includeColor: IncludeBorderColorOrNot = .IncludeBorderColor
  ) -> CollapsedBorderValue {
    // For end border, we need to check, in order of precedence:
    // (1) Our end border.
    let startColorProperty: CSSPropertyID =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderInlineStartColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    let endColorProperty: CSSPropertyID =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderInlineEndColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    var result = CollapsedBorderValue(
      border: style().borderEnd(styleForFlow: styleForCellFlow()),
      color: includeColor == .IncludeBorderColor
        ? style().visitedDependentColorWithColorFilter(colorProperty: endColorProperty)
        : ColorWrapper(), precedence: .Cell)

    let table = table()
    if table == nil {
      return result
    }
    // Note: We have to use the effective column information instead of whether we have a cell after as a table doesn't
    // have to be regular (any row can have less cells than the total cell count).
    let isEndColumn = table!.colToEffCol(column: col() + colSpan() - 1) == table!.numEffCols() - 1
    // (2) The start border of the following cell.
    if !isEndColumn, let cellAfter = table!.cellAfter(cell: self) {
      let cellAfterAdjoiningBorder = CollapsedBorderValue(
        border: cellAfter.borderAdjoiningCellBefore(cell: self),
        color: includeColor == .IncludeBorderColor
          ? cellAfter.style().visitedDependentColorWithColorFilter(
            colorProperty: startColorProperty) : ColorWrapper(), precedence: .Cell)
      result = chooseBorder(border1: result, border2: cellAfterAdjoiningBorder)
      if !result.exists() {
        return result
      }
    }

    let endBorderAdjoinsTable = hasEndBorderAdjoiningTable()
    if endBorderAdjoinsTable {
      // (3) Our row's end border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: row()!.borderAdjoiningEndCell(cell: self),
          color: includeColor == .IncludeBorderColor
            ? parent()!.style().visitedDependentColorWithColorFilter(
              colorProperty: endColorProperty) : ColorWrapper(), precedence: .Row))
      if !result.exists() {
        return result
      }

      // (4) Our row group's end border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: section()!.borderAdjoiningEndCell(cell: self),
          color: includeColor == .IncludeBorderColor
            ? section()!.style().visitedDependentColorWithColorFilter(
              colorProperty: endColorProperty)
            : ColorWrapper(), precedence: .RowGroup))
      if !result.exists() {
        return result
      }
    }

    // (5) Our column and column group's end borders.
    var startColEdge = false
    var endColEdge = false
    if let colElt = table!.colElement(
      col: col() + colSpan() - 1, startEdge: &startColEdge, endEdge: &endColEdge)
    {
      if colElt.isTableColumnGroup() && endColEdge {
        // The element is a colgroup and is also the last colgroup (in case of spanned colgroups).
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellEndBorder(),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(colorProperty: endColorProperty)
              : ColorWrapper(), precedence: .ColumnGroup))
        if !result.exists() {
          return result
        }
      } else if !colElt.isTableColumnGroup() {
        // First apply the end border of the column irrespective of whether it is spanned or not. This is as per
        // HTML5 which states that: "For the purposes of the CSS table model, the col element is expected to be
        // treated as if it was present as many times as its span attribute specifies".
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellEndBorder(),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(
                colorProperty: endColorProperty)
              : ColorWrapper(), precedence: .Column))
        if !result.exists() {
          return result
        }
        // Next, if it has a parent colgroup then we apply its end border but only if it is adjacent to the cell.
        if let enclosingColumnGroup = colElt.enclosingColumnGroupIfAdjacentAfter() {
          result = chooseBorder(
            border1: result,
            border2: CollapsedBorderValue(
              border: enclosingColumnGroup.borderAdjoiningCellEndBorder(),
              color: includeColor == .IncludeBorderColor
                ? enclosingColumnGroup.style().visitedDependentColorWithColorFilter(
                  colorProperty: endColorProperty) : ColorWrapper(), precedence: .ColumnGroup))
          if !result.exists() {
            return result
          }
        }
      }
    }

    // (6) The start border of the next column.
    if !isEndColumn,
      let colElt = table!.colElement(
        col: col() + colSpan(), startEdge: &startColEdge, endEdge: &endColEdge)
    {
      if colElt.isTableColumnGroup() && startColEdge {
        // This case is a colgroup without any col, we only compute it if it is adjacent to the cell's edge.
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellBefore(cell: self),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(
                colorProperty: startColorProperty) : ColorWrapper(), precedence: .ColumnGroup))
        if !result.exists() {
          return result
        }
      } else if colElt.isTableColumn() {
        // Resolve the collapsing border against the col's border ignoring any 'span' as per HTML5.
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: colElt.borderAdjoiningCellBefore(cell: self),
            color: includeColor == .IncludeBorderColor
              ? colElt.style().visitedDependentColorWithColorFilter(
                colorProperty: startColorProperty) : ColorWrapper(), precedence: .Column))
        if !result.exists() {
          return result
        }
        // If we have a parent colgroup, resolve the border only if it is adjacent to the cell.
        if let enclosingColumnGroup = colElt.enclosingColumnGroupIfAdjacentBefore() {
          result = chooseBorder(
            border1: result,
            border2: CollapsedBorderValue(
              border: enclosingColumnGroup.borderAdjoiningCellStartBorder(),
              color: includeColor == .IncludeBorderColor
                ? enclosingColumnGroup.style().visitedDependentColorWithColorFilter(
                  colorProperty: startColorProperty) : ColorWrapper(), precedence: .ColumnGroup))
          if !result.exists() {
            return result
          }
        }
      }
    }

    if endBorderAdjoinsTable {
      // (7) The table's end border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: table!.style().borderEnd(),
          color: includeColor == .IncludeBorderColor
            ? table!.style().visitedDependentColorWithColorFilter(colorProperty: endColorProperty)
            : ColorWrapper(), precedence: .Table))
      if !result.exists() {
        return result
      }
    }

    return result
  }

  override func hasLineIfEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let hasEmptyCollapsedStartBorder = false
  private let hasEmptyCollapsedEndBorder = false
}
