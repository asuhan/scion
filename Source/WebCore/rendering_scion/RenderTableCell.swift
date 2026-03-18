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

private func markCellDirtyWhenCollapsedBorderChanges(_ cell: RenderTableCellWrapper?) {
  cell?.setNeedsLayoutAndPrefWidthsRecalc()
}

// The following rules apply for resolving conflicts and figuring out which border
// to use.
// (1) Borders with the 'border-style' of 'hidden' take precedence over all other conflicting
// borders. Any border with this value suppresses all borders at this location.
// (2) Borders with a style of 'none' have the lowest priority. Only if the border properties of all
// the elements meeting at this edge are 'none' will the border be omitted (but note that 'none' is
// the default value for the border style.)
// (3) If none of the styles are 'hidden' and at least one of them is not 'none', then narrow borders
// are discarded in favor of wider ones. If several have the same 'border-width' then styles are preferred
// in this order: 'double', 'solid', 'dashed', 'dotted', 'ridge', 'outset', 'groove', and the lowest: 'inset'.
// (4) If border styles differ only in color, then a style set on a cell wins over one on a row,
// which wins over a row group, column, column group and, lastly, table. It is undefined which color
// is used when two elements of the same type disagree.
private func compareBorders(border1: CollapsedBorderValue, border2: CollapsedBorderValue) -> Int {
  // Sanity check the values passed in. The null border have lowest priority.
  if !border2.exists() {
    if !border1.exists() {
      return 0
    }
    return 1
  }
  if !border1.exists() {
    return -1
  }

  // Rule #1 above.
  if border2.style == .Hidden {
    if border1.style == .Hidden {
      return 0
    }
    return -1
  }
  if border1.style == .Hidden {
    return 1
  }

  // Rule #2 above.  A style of 'none' has lowest priority and always loses to any other border.
  if border2.style == .None {
    if border1.style == .None {
      return 0
    }
    return 1
  }
  if border1.style == .None {
    return -1
  }

  // The first part of rule #3 above. Wider borders win.
  if border1.width() != border2.width() {
    return border1.width() < border2.width() ? -1 : 1
  }

  // The borders have equal width.  Sort by border style.
  if border1.style != border2.style {
    return border1.style.rawValue < border2.style.rawValue ? -1 : 1
  }

  // The border have the same width and style.  Rely on precedence (cell over row over row group, etc.)
  if border1.precedence == border2.precedence {
    return 0
  }
  return border1.precedence.rawValue < border2.precedence.rawValue ? -1 : 1
}

private func chooseBorder(border1: CollapsedBorderValue, border2: CollapsedBorderValue)
  -> CollapsedBorderValue
{
  let border = compareBorders(border1: border1, border2: border2) < 0 ? border2 : border1
  return border.style == .Hidden ? CollapsedBorderValue() : border
}

private func emptyBorder() -> CollapsedBorderValue {
  return CollapsedBorderValue(border: BorderValue(), color: ColorWrapper(), precedence: .Cell)
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
      CPtrToInt(tableSection.id()) == CPtrToInt(table.topSection()?.id())
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

  func setCol(column: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func col() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextCell() -> RenderTableCellWrapper? {
    assert(isNativeImpl())
    return super.nextSibling() as! RenderTableCellWrapper?
  }

  func previousCell() -> RenderTableCellWrapper? {
    assert(isNativeImpl())
    return super.previousSibling() as! RenderTableCellWrapper?
  }

  func row() -> RenderTableRowWrapper? {
    assert(isNativeImpl())
    return parent() as! RenderTableRowWrapper?
  }

  func section() -> RenderTableSectionWrapper? {
    assert(isNativeImpl())
    guard let row = self.row() else { return nil }
    return row.parent() as! RenderTableSectionWrapper?
  }

  func table() -> RenderTableWrapper? {
    assert(isNativeImpl())
    guard let section = self.section() else { return nil }
    return section.parent() as! RenderTableWrapper?
  }

  func rowIndex() -> UInt32 {
    assert(isNativeImpl())
    // This function shouldn't be called on a detached cell.
    return row()!.rowIndex()
  }

  func styleOrColLogicalWidth() -> LengthWrapper {
    let styleWidth = style().logicalWidth()
    if !styleWidth.isAuto() {
      return styleWidth
    }
    if let firstColumn = table()!.colElement(col: col()) {
      return logicalWidthFromColumns(firstColumn, styleWidth)
    }
    return styleWidth
  }

  func logicalHeightForRowSizing() -> LayoutUnit {
    assert(isNativeImpl())
    // FIXME: This function does too much work, and is very hot during table layout!
    let adjustedLogicalHeight =
      logicalHeight() - (intrinsicPaddingBefore() + intrinsicPaddingAfter())
    if !style().logicalHeight().isSpecified() {
      return adjustedLogicalHeight
    }
    var styleLogicalHeight = valueForLength(length: style().logicalHeight(), maximumValue: 0)
    // In strict mode, box-sizing: content-box do the right thing and actually add in the border and padding.
    // Call computedCSSPadding* directly to avoid including implicitPadding.
    if !document().inQuirksMode() && style().boxSizing() != .BorderBox {
      styleLogicalHeight +=
        computedCSSPaddingBefore() + computedCSSPaddingAfter() + borderBefore() + borderAfter()
    }
    return max(styleLogicalHeight, adjustedLogicalHeight)
  }

  func setCellLogicalWidth(_ tableLayoutLogicalWidth: LayoutUnit) {
    if tableLayoutLogicalWidth == logicalWidth() {
      return
    }

    setNeedsLayout(markParents: .MarkOnlyThis)
    row()!.setChildNeedsLayout(markParents: .MarkOnlyThis)

    setLogicalWidth(size: tableLayoutLogicalWidth)
    setCellWidthChanged(b: true)
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
    if CPtrToInt(backgroundObject.id()) != CPtrToInt(id()) {
      adjustedPaintOffset.moveBy(offset: location())
    }

    // Background images attached to the row or row group must span the row
    // or row group. Draw them at the backgroundObject's dimensions, but
    // clipped to this cell.
    // FIXME: This should also apply to columns and column groups.
    let paintBackgroundObject =
      CPtrToInt(backgroundObject.id()) != CPtrToInt(id()) && bgLayer.hasImage()
      && !(backgroundObject is RenderTableColWrapper)
    // We have to clip here because the background would paint
    // on top of the borders otherwise. This only matters for cells and rows.
    let shouldClip =
      paintBackgroundObject
      || (backgroundObject.hasLayer()
        && (CPtrToInt(backgroundObject.id()) == CPtrToInt(id())
          || CPtrToInt(backgroundObject.id()) == CPtrToInt(parent()?.id()))
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
    if CPtrToInt(backgroundObject.id()) != CPtrToInt(id()) {
      painter.setOverrideClip(overrideClip: .BorderBox)
      painter.setOverrideOrigin(overrideOrigin: .BorderBox)
    }
    painter.paintFillLayers(
      color: color, fillLayer: bgLayer, rect: fillRect, bleedAvoidance: .BackgroundBleedNone,
      op: compositeOp, backgroundObject: backgroundObject)
  }

  func cellBaselinePosition() -> LayoutUnit {
    // <http://www.w3.org/TR/2007/CR-CSS21-20070719/tables.html#height-layout>: The baseline of a cell is the baseline of
    // the first in-flow line box in the cell, or the first in-flow table-row in the cell, whichever comes first. If there
    // is no such line box or table-row, the baseline is the bottom of content edge of the cell box.
    return firstLineBaseline() ?? borderAndPaddingBefore() + contentLogicalHeight()
  }

  func isBaselineAligned() -> Bool {
    assert(isNativeImpl())
    let alignContent = style().alignContent()
    if !alignContent.isNormal() {
      return alignContent.position == .Baseline
    }
    let va = style().verticalAlign()
    return va == .Baseline || va == .TextBottom || va == .TextTop || va == .Super || va == .Sub
      || va == .Length
  }

  func computeIntrinsicPadding(rowHeight: LayoutUnit) {
    let oldIntrinsicPaddingBefore = intrinsicPaddingBefore()
    let oldIntrinsicPaddingAfter = intrinsicPaddingAfter()
    let logicalHeightWithoutIntrinsicPadding =
      logicalHeight() - oldIntrinsicPaddingBefore - oldIntrinsicPaddingAfter

    var intrinsicPaddingBefore = oldIntrinsicPaddingBefore
    var alignment = style().verticalAlign()
    let alignContent = style().alignContent()
    if !alignContent.isNormal() {
      // align-content overrides vertical-align
      if alignContent.position == .Baseline {
        alignment = .Baseline
      } else if alignContent.isCentered() {
        alignment = .Middle
      } else if alignContent.isStartward() {
        alignment = .Top
      } else if alignContent.isEndward() {
        alignment = .Bottom
      }
    }
    switch alignment {
    case .Sub, .Super, .TextTop, .TextBottom, .Length, .Baseline:
      let baseline = cellBaselinePosition()
      let needsIntrinsicPadding = baseline > borderAndPaddingBefore() || !logicalHeight().bool()
      if needsIntrinsicPadding {
        intrinsicPaddingBefore =
          section()!.rowBaseline(row: rowIndex()) - (baseline - oldIntrinsicPaddingBefore)
      }
    case .Top:
      break
    case .Middle:
      intrinsicPaddingBefore = (rowHeight - logicalHeightWithoutIntrinsicPadding) / 2
    case .Bottom:
      intrinsicPaddingBefore = rowHeight - logicalHeightWithoutIntrinsicPadding
    case .BaselineMiddle:
      break
    }

    let intrinsicPaddingAfter =
      rowHeight - logicalHeightWithoutIntrinsicPadding - intrinsicPaddingBefore
    setIntrinsicPaddingBefore(p: intrinsicPaddingBefore)
    setIntrinsicPaddingAfter(p: intrinsicPaddingAfter)

    // FIXME: Changing an intrinsic padding shouldn't trigger a relayout as it only shifts the cell inside the row but
    // doesn't change the logical height.
    if intrinsicPaddingBefore != oldIntrinsicPaddingBefore
      || intrinsicPaddingAfter != oldIntrinsicPaddingAfter
    {
      setNeedsLayout(markParents: .MarkOnlyThis)
    }
  }

  func clearIntrinsicPadding() {
    assert(isNativeImpl())
    setIntrinsicPadding(LayoutUnit(value: 0), LayoutUnit(value: 0))
  }

  func intrinsicPaddingBefore() -> LayoutUnit {
    assert(isNativeImpl())
    return m_intrinsicPaddingBefore
  }

  func intrinsicPaddingAfter() -> LayoutUnit {
    assert(isNativeImpl())
    return m_intrinsicPaddingAfter
  }

  // FIXME: For now we just assume the cell has the same block flow direction as the table. It's likely we'll
  // create an extra anonymous RenderBlock to handle mixing directionality anyway, in which case we can lock
  // the block flow directionality of the cells to the table's directionality.
  override func paddingBefore() -> LayoutUnit {
    assert(isNativeImpl())
    return computedCSSPaddingBefore() + intrinsicPaddingBefore()
  }

  override func paddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalHeightFromRowHeight(rowHeight: LayoutUnit) {
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

  func isFirstOrLastCellInRow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    // If the table grid is dirty, we cannot get reliable information about adjoining cells,
    // so we ignore outside borders. This should not be a problem because it means that
    // the table is going to recalculate the grid, relayout and repaint its current rect, which
    // includes any outside borders of this cell.
    if !table()!.collapseBorders() || table()!.needsSectionRecalc {
      return super.localRectsForRepaint(repaintOutlineBounds)
    }

    let rtl = !styleForCellFlow().isLeftToRightDirection()
    let outlineSize = LayoutUnit(value: style().outlineSize())
    var left = max(borderHalfLeft(outer: true), outlineSize)
    var right = max(borderHalfRight(outer: true), outlineSize)
    var top = max(borderHalfTop(outer: true), outlineSize)
    var bottom = max(borderHalfBottom(outer: true), outlineSize)
    if (left.bool() && !rtl) || (right.bool() && rtl) {
      if let before = table()!.cellBefore(cell: self) {
        top = max(top, before.borderHalfTop(outer: true))
        bottom = max(bottom, before.borderHalfBottom(outer: true))
      }
    }
    if (left.bool() && rtl) || (right.bool() && !rtl) {
      if let after = table()!.cellAfter(cell: self) {
        top = max(top, after.borderHalfTop(outer: true))
        bottom = max(bottom, after.borderHalfBottom(outer: true))
      }
    }
    if top.bool() {
      if let above = table()!.cellAbove(cell: self) {
        left = max(left, above.borderHalfLeft(outer: true))
        right = max(right, above.borderHalfRight(outer: true))
      }
    }
    if bottom.bool() {
      if let below = table()!.cellBelow(cell: self) {
        left = max(left, below.borderHalfLeft(outer: true))
        right = max(right, below.borderHalfRight(outer: true))
      }
    }

    let location = LayoutPointWrapper(
      x: max(left, -visualOverflowRect().x()), y: max(top, -visualOverflowRect().y()))
    var overflowRect = LayoutRectWrapper(
      x: -location.x, y: -location.y,
      width: location.x + max(width() + right, visualOverflowRect().maxX()),
      height: location.y + max(height() + bottom, visualOverflowRect().maxY()))

    // FIXME: layoutDelta needs to be applied in parts before/after transforms and
    // repaint containers. https://bugs.webkit.org/show_bug.cgi?id=23308
    overflowRect.move(size: view().frameView().layoutContext().layoutDelta())

    var rects = RepaintRects(rect: overflowRect)
    if repaintOutlineBounds == .Yes {
      rects.outlineBoundsRect = localOutlineBoundsRepaintRect()
    }

    return rects
  }

  func invalidateHasEmptyCollapsedBorders() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setHasEmptyCollapsedBorder(side: CollapsedBorderSide, empty: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(style().display() == .TableCell)
    assert(row()?.rowIndexWasSet() ?? true)

    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    setHasVisibleBoxDecorations(true)  // FIXME: Optimize this to only set to true if necessary.

    if parent() != nil && section() != nil && oldStyle != nil
      && style().height() != oldStyle!.height()
    {
      section()!.rowLogicalHeightChanged(rowIndex())
    }

    // Our intrinsic padding pushes us down to align with the baseline of other cells on the row. If our vertical-align
    // has changed then so will the padding needed to align with other cells - clear it so we can recalculate it from scratch.
    if oldStyle != nil
      && (style().verticalAlign() != oldStyle!.verticalAlign()
        || style().alignContent() != oldStyle!.alignContent())
    {
      clearIntrinsicPadding()
    }

    // If border was changed, notify table.
    if let table = table(), oldStyle != nil && !oldStyle!.borderIsEquivalentForPainting(style()) {
      table.invalidateCollapsedBorders(cellWithStyleChange: self)
      if table.collapseBorders() && diff == .Layout {
        markCellDirtyWhenCollapsedBorderChanges(table.cellBelow(cell: self))
        markCellDirtyWhenCollapsedBorderChanges(table.cellAbove(cell: self))
        markCellDirtyWhenCollapsedBorderChanges(table.cellBefore(cell: self))
        markCellDirtyWhenCollapsedBorderChanges(table.cellAfter(cell: self))
      }
    }
  }

  override func computePreferredLogicalWidths() {
    // The child cells rely on the grids up in the sections to do their computePreferredLogicalWidths work.  Normally the sections are set up early, as table
    // cells are added, but relayout can cause the cells to be freed, leaving stale pointers in the sections'
    // grids.  We must refresh those grids before the child cells try to use them.
    table()!.recalcSectionsIfNeeded()

    super.computePreferredLogicalWidths()
    if element() == nil || !style().autoWrap() || !element()!.hasNowrapAttr() {
      return
    }

    let w = styleOrColLogicalWidth()
    if w.isFixed() {
      // Nowrap is set, but we didn't actually use it because of the
      // fixed width set on the cell. Even so, it is a WinIE/Moz trait
      // to make the minwidth of the cell into the fixed width. They do this
      // even in strict mode, so do not make this a quirk. Affected the top
      // of hiptop.com.
      m_minPreferredLogicalWidth = max(LayoutUnit(value: w.value()), m_minPreferredLogicalWidth)
    }
  }

  override func frameRectForStickyPositioning() -> LayoutRectWrapper {
    // RenderTableCell has the RenderTableRow as the container, but is positioned relatively
    // to the RenderTableSection. The sticky positioning algorithm assumes that elements are
    // positioned relatively to their container, so we correct for that here.
    assert(parentBox() != nil)
    var returnValue = frameRect()
    returnValue.move(size: -parentBox()!.locationOffset())
    return returnValue
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

  override func offsetFromContainer(
    _ container: RenderElementWrapper, _ point: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    assert(CPtrToInt(container.id()) == CPtrToInt(self.container()?.id()))

    var offset = super.offsetFromContainer(container, point, &offsetDependsOnPoint)
    if let containerOfRow = container.container(), parent() != nil {
      var unused: Bool? = nil
      offset -= parentBox()!.offsetFromContainer(containerOfRow, point, &unused)
    }

    return offset
  }

  override func computeVisibleRectsInContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    if CPtrToInt(container?.id()) == CPtrToInt(id()) {
      return rects
    }

    var adjustedRects = rects
    if (!view().frameView().layoutContext().isPaintOffsetCacheEnabled() || container != nil
      || context.options.contains(.UseEdgeInclusiveIntersection)) && parent() != nil
    {
      adjustedRects.moveBy(-parentBox()!.location())  // Rows are in the same coordinate space, so don't add their offset in.
    }

    return super.computeVisibleRectsInContainer(adjustedRects, container, context)
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
    assert(isNativeImpl())
    m_intrinsicPaddingBefore = p
  }

  private func setIntrinsicPaddingAfter(p: LayoutUnit) {
    assert(isNativeImpl())
    m_intrinsicPaddingAfter = p
  }

  private func setIntrinsicPadding(_ before: LayoutUnit, _ after: LayoutUnit) {
    assert(isNativeImpl())
    setIntrinsicPaddingBefore(p: before)
    setIntrinsicPaddingAfter(p: after)
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
    if table() == nil || section() == nil {
      return emptyBorder()
    }

    if hasEmptyCollapsedBeforeBorder {
      return emptyBorder()
    }

    if table()!.collapsedBordersAreValid() {
      return section()!.cachedCollapsedBorder(cell: self, side: .CBSBefore)
    }

    let result = computeCollapsedBeforeBorder(includeColor: includeColor)
    setHasEmptyCollapsedBorder(side: .CBSBefore, empty: !result.width().bool())
    if includeColor == .IncludeBorderColor && !hasEmptyCollapsedBeforeBorder {
      section()!.setCachedCollapsedBorder(cell: self, side: .CBSBefore, border: result)
    }
    return result
  }

  private func collapsedAfterBorder(includeColor: IncludeBorderColorOrNot = .IncludeBorderColor)
    -> CollapsedBorderValue
  {
    if table() == nil || section() == nil {
      return emptyBorder()
    }

    if hasEmptyCollapsedAfterBorder {
      return emptyBorder()
    }

    if table()!.collapsedBordersAreValid() {
      return section()!.cachedCollapsedBorder(cell: self, side: .CBSAfter)
    }

    let result = computeCollapsedAfterBorder(includeColor: includeColor)
    setHasEmptyCollapsedBorder(side: .CBSAfter, empty: !result.width().bool())
    if includeColor == .IncludeBorderColor && !hasEmptyCollapsedAfterBorder {
      section()!.setCachedCollapsedBorder(cell: self, side: .CBSAfter, border: result)
    }
    return result
  }

  private func cachedCollapsedLeftBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection()
        ? section()!.cachedCollapsedBorder(cell: self, side: .CBSStart)
        : section()!.cachedCollapsedBorder(cell: self, side: .CBSEnd)
    }
    return styleForCellFlow.isFlippedBlocksWritingMode()
      ? section()!.cachedCollapsedBorder(cell: self, side: .CBSAfter)
      : section()!.cachedCollapsedBorder(cell: self, side: .CBSBefore)
  }

  private func cachedCollapsedRightBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isLeftToRightDirection()
        ? section()!.cachedCollapsedBorder(cell: self, side: .CBSEnd)
        : section()!.cachedCollapsedBorder(cell: self, side: .CBSStart)
    }
    return styleForCellFlow.isFlippedBlocksWritingMode()
      ? section()!.cachedCollapsedBorder(cell: self, side: .CBSBefore)
      : section()!.cachedCollapsedBorder(cell: self, side: .CBSAfter)
  }

  private func cachedCollapsedTopBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isFlippedBlocksWritingMode()
        ? section()!.cachedCollapsedBorder(cell: self, side: .CBSAfter)
        : section()!.cachedCollapsedBorder(cell: self, side: .CBSBefore)
    }
    return styleForCellFlow.isLeftToRightDirection()
      ? section()!.cachedCollapsedBorder(cell: self, side: .CBSStart)
      : section()!.cachedCollapsedBorder(cell: self, side: .CBSEnd)
  }

  private func cachedCollapsedBottomBorder(styleForCellFlow: RenderStyleWrapper)
    -> CollapsedBorderValue
  {
    if styleForCellFlow.isHorizontalWritingMode() {
      return styleForCellFlow.isFlippedBlocksWritingMode()
        ? section()!.cachedCollapsedBorder(cell: self, side: .CBSBefore)
        : section()!.cachedCollapsedBorder(cell: self, side: .CBSAfter)
    }
    return styleForCellFlow.isLeftToRightDirection()
      ? section()!.cachedCollapsedBorder(cell: self, side: .CBSEnd)
      : section()!.cachedCollapsedBorder(cell: self, side: .CBSStart)
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

  private func computeCollapsedBeforeBorder(
    includeColor: IncludeBorderColorOrNot = .IncludeBorderColor
  ) -> CollapsedBorderValue {
    // For before border, we need to check, in order of precedence:
    // (1) Our before border.
    let beforeColorProperty: CSSPropertyID =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderBlockStartColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    let afterColorProperty =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderBlockEndColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    var result = CollapsedBorderValue(
      border: style().borderBefore(styleForFlow: styleForCellFlow()),
      color: includeColor == .IncludeBorderColor
        ? style().visitedDependentColorWithColorFilter(colorProperty: beforeColorProperty)
        : ColorWrapper(),
      precedence: .Cell)

    let table = table()
    if table == nil {
      return result
    }
    let prevCell = table!.cellAbove(cell: self)
    if prevCell != nil {
      // (2) A before cell's after border.
      result = chooseBorder(
        border1: CollapsedBorderValue(
          border: prevCell!.style().borderAfter(),
          color: includeColor == .IncludeBorderColor
            ? prevCell!.style().visitedDependentColorWithColorFilter(
              colorProperty: afterColorProperty) : ColorWrapper(), precedence: .Cell),
        border2: result)
      if !result.exists() {
        return result
      }
    }

    // (3) Our row's before border.
    result = chooseBorder(
      border1: result,
      border2: CollapsedBorderValue(
        border: parent()!.style().borderBefore(styleForFlow: styleForCellFlow()),
        color: includeColor == .IncludeBorderColor
          ? parent()!.style().visitedDependentColorWithColorFilter(
            colorProperty: beforeColorProperty)
          : ColorWrapper(), precedence: .Row))
    if !result.exists() {
      return result
    }

    // (4) The previous row's after border.
    if prevCell != nil {
      var prevRow: RenderObjectWrapper? = nil
      if CPtrToInt(prevCell!.section()?.id()) == CPtrToInt(section()?.id()) {
        prevRow = parent()!.previousSibling()
      } else {
        prevRow = prevCell!.section()!.lastRow()
      }

      if prevRow != nil {
        result = chooseBorder(
          border1: CollapsedBorderValue(
            border: prevRow!.style().borderAfter(),
            color: includeColor == .IncludeBorderColor
              ? prevRow!.style().visitedDependentColorWithColorFilter(
                colorProperty: afterColorProperty) : ColorWrapper(), precedence: .Row),
          border2: result)
        if !result.exists() {
          return result
        }
      }
    }

    // Now check row groups.
    var currSection = section()
    if rowIndex() == 0 {
      // (5) Our row group's before border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: currSection!.style().borderBefore(styleForFlow: styleForCellFlow()),
          color: includeColor == .IncludeBorderColor
            ? currSection!.style().visitedDependentColorWithColorFilter(
              colorProperty: beforeColorProperty)
            : ColorWrapper(), precedence: .RowGroup))
      if !result.exists() {
        return result
      }

      // (6) Previous row group's after border.
      currSection = table!.sectionAbove(section: currSection, skipEmptySections: .SkipEmptySections)
      if currSection != nil {
        result = chooseBorder(
          border1: CollapsedBorderValue(
            border: currSection!.style().borderAfter(),
            color: includeColor == .IncludeBorderColor
              ? currSection!.style().visitedDependentColorWithColorFilter(
                colorProperty: afterColorProperty)
              : ColorWrapper(), precedence: .RowGroup), border2: result)
        if !result.exists() {
          return result
        }
      }
    }

    if currSection != nil {
      return result
    }

    // (8) Our column and column group's before borders.
    if let colElt = table!.colElement(col: col()) {
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: colElt.style().borderBefore(styleForFlow: styleForCellFlow()),
          color: includeColor == .IncludeBorderColor
            ? colElt.style().visitedDependentColorWithColorFilter(
              colorProperty: beforeColorProperty)
            : ColorWrapper(), precedence: .Column))
      if !result.exists() {
        return result
      }
      if let enclosingColumnGroup = colElt.enclosingColumnGroup() {
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: enclosingColumnGroup.style().borderBefore(styleForFlow: styleForCellFlow()),
            color: includeColor == .IncludeBorderColor
              ? enclosingColumnGroup.style().visitedDependentColorWithColorFilter(
                colorProperty: beforeColorProperty) : ColorWrapper(), precedence: .ColumnGroup))
        if !result.exists() {
          return result
        }
      }
    }

    // (9) The table's before border.
    return chooseBorder(
      border1: result,
      border2: CollapsedBorderValue(
        border: table!.style().borderBefore(),
        color: includeColor == .IncludeBorderColor
          ? table!.style().visitedDependentColorWithColorFilter(colorProperty: beforeColorProperty)
          : ColorWrapper(), precedence: .Table))
  }

  private func computeCollapsedAfterBorder(
    includeColor: IncludeBorderColorOrNot = .IncludeBorderColor
  ) -> CollapsedBorderValue {
    // For after border, we need to check, in order of precedence:
    // (1) Our after border.
    let beforeColorProperty: CSSPropertyID =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderBlockStartColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    let afterColorProperty: CSSPropertyID =
      includeColor == .IncludeBorderColor
      ? CSSProperty.resolveDirectionAwareProperty(
        id: .CSSPropertyBorderBlockEndColor, direction: styleForCellFlow().direction(),
        writingMode: styleForCellFlow().writingMode()) : .CSSPropertyInvalid
    var result = CollapsedBorderValue(
      border: style().borderAfter(),
      color: includeColor == .IncludeBorderColor
        ? style().visitedDependentColorWithColorFilter(colorProperty: afterColorProperty)
        : ColorWrapper(),
      precedence: .Cell)

    let table = table()
    if table == nil {
      return result
    }
    let nextCell = table!.cellBelow(cell: self)
    if nextCell != nil {
      // (2) An after cell's before border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: nextCell!.style().borderBefore(styleForFlow: styleForCellFlow()),
          color: includeColor == .IncludeBorderColor
            ? nextCell!.style().visitedDependentColorWithColorFilter(
              colorProperty: beforeColorProperty) : ColorWrapper(), precedence: .Cell))
      if !result.exists() { return result }
    }

    // (3) Our row's after border. (FIXME: Deal with rowspan!)
    result = chooseBorder(
      border1: result,
      border2: CollapsedBorderValue(
        border: parent()!.style().borderAfter(),
        color: includeColor == .IncludeBorderColor
          ? parent()!.style().visitedDependentColorWithColorFilter(
            colorProperty: afterColorProperty) : ColorWrapper(), precedence: .Row))
    if !result.exists() { return result }

    // (4) The next row's before border.
    if nextCell != nil {
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: nextCell!.parent()!.style().borderBefore(styleForFlow: styleForCellFlow()),
          color: includeColor == .IncludeBorderColor
            ? nextCell!.parent()!.style().visitedDependentColorWithColorFilter(
              colorProperty: beforeColorProperty) : ColorWrapper(), precedence: .Row))
      if !result.exists() { return result }
    }

    // Now check row groups.
    var currSection = section()
    if rowIndex() + rowSpan() >= currSection!.numRows() {
      // (5) Our row group's after border.
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: currSection!.style().borderAfter(styleForFlow: styleForCellFlow()),
          color: includeColor == .IncludeBorderColor
            ? currSection!.style().visitedDependentColorWithColorFilter(
              colorProperty: afterColorProperty) : ColorWrapper(), precedence: .RowGroup))
      if !result.exists() { return result }

      // (6) Following row group's before border.
      currSection = table!.sectionBelow(section: currSection, skipEmptySections: .SkipEmptySections)
      if currSection != nil {
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: currSection!.style().borderBefore(styleForFlow: styleForCellFlow()),
            color: includeColor == .IncludeBorderColor
              ? currSection!.style().visitedDependentColorWithColorFilter(
                colorProperty: beforeColorProperty)
              : ColorWrapper(), precedence: .RowGroup))
        if !result.exists() { return result }
      }
    }

    if currSection == nil {
      return result
    }

    // (8) Our column and column group's after borders.
    if let colElt = table!.colElement(col: col()) {
      result = chooseBorder(
        border1: result,
        border2: CollapsedBorderValue(
          border: colElt.style().borderAfter(styleForFlow: styleForCellFlow()),
          color: includeColor == .IncludeBorderColor
            ? colElt.style().visitedDependentColorWithColorFilter(colorProperty: afterColorProperty)
            : ColorWrapper(), precedence: .Column))
      if !result.exists() { return result }
      if let enclosingColumnGroup = colElt.enclosingColumnGroup() {
        result = chooseBorder(
          border1: result,
          border2: CollapsedBorderValue(
            border: enclosingColumnGroup.style().borderAfter(styleForFlow: styleForCellFlow()),
            color: includeColor == .IncludeBorderColor
              ? enclosingColumnGroup.style().visitedDependentColorWithColorFilter(
                colorProperty: afterColorProperty) : ColorWrapper(), precedence: .ColumnGroup))
        if !result.exists() { return result }
      }
    }

    // (9) The table's after border.
    return chooseBorder(
      border1: result,
      border2: CollapsedBorderValue(
        border: table!.style().borderAfter(styleForFlow: styleForCellFlow()),
        color: includeColor == .IncludeBorderColor
          ? table!.style().visitedDependentColorWithColorFilter(colorProperty: afterColorProperty)
          : ColorWrapper(), precedence: .Table))
  }

  private func logicalWidthFromColumns(
    _ firstColForThisCell: RenderTableColWrapper, _ widthFromStyle: LengthWrapper
  ) -> LengthWrapper {
    assert(CPtrToInt(firstColForThisCell.id()) == CPtrToInt(table()!.colElement(col: col())?.id()))
    var tableCol: RenderTableColWrapper? = firstColForThisCell

    let colSpanCount = colSpan()
    var colWidthSum = LayoutUnit()
    for _ in 1...colSpanCount {
      let colWidth = tableCol!.style().logicalWidth()

      // Percentage value should be returned only for colSpan == 1.
      // Otherwise we return original width for the cell.
      if !colWidth.isFixed() {
        if colSpanCount > 1 {
          return widthFromStyle
        }
        return colWidth
      }

      colWidthSum += colWidth.value()
      tableCol = tableCol!.nextColumn()
      // If no next <col> tag found for the span we just return what we have for now.
      if tableCol == nil {
        break
      }
    }

    // Column widths specified on <col> apply to the border box of the cell, see bug 8126.
    // FIXME: Why is border/padding ignored in the negative width case?
    if colWidthSum > 0 {
      return LengthWrapper(
        value: max(LayoutUnit(value: 0), colWidthSum - borderAndPaddingLogicalWidth()), type: .Fixed
      )
    }
    return LengthWrapper(value: colWidthSum, type: .Fixed)
  }

  override func hasLineIfEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let hasEmptyCollapsedBeforeBorder = false
  private let hasEmptyCollapsedAfterBorder = false
  private let hasEmptyCollapsedStartBorder = false
  private let hasEmptyCollapsedEndBorder = false
  private var m_intrinsicPaddingBefore = LayoutUnit(value: 0)
  private var m_intrinsicPaddingAfter = LayoutUnit(value: 0)
}
