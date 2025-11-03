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

final class RenderTableCellWrapper: RenderBlockFlowWrapper {
  func colSpan() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowSpan() -> UInt32 {
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

  override func borderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func borderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
}
