/**
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Simon Hausmann <hausmann@kde.org>
 *           (C) 2000 Stefan Schimanski (1Stein@gmx.de)
 * Copyright (C) 2004, 2005, 2006, 2008, 2013 Apple Inc.
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

private let borderStartEdgeColor = SRGBA<UInt8>(red: 170, green: 170, blue: 170)
private let borderEndEdgeColor = ColorWrapper.black
private let borderFillColor = SRGBA<UInt8>(red: 208, green: 208, blue: 208)

enum FrameEdge: UInt8 {
  case LeftFrameEdge = 0
  case RightFrameEdge = 1
  case TopFrameEdge = 2
  case BottomFrameEdge = 3
}

struct FrameEdgeInfo {
  init(preventResize: Bool = false, allowBorder: Bool = true) {
    self.preventResize = [Bool](repeating: preventResize, count: 4)
    self.allowBorder = [Bool](repeating: allowBorder, count: 4)
  }

  func preventResize(_ edge: FrameEdge) -> Bool { return preventResize[Int(edge.rawValue)] }
  func allowBorder(_ edge: FrameEdge) -> Bool { return allowBorder[Int(edge.rawValue)] }

  mutating func setPreventResize(_ edge: FrameEdge, _ preventResize: Bool) {
    self.preventResize[Int(edge.rawValue)] = preventResize
  }

  mutating func setAllowBorder(_ edge: FrameEdge, _ allowBorder: Bool) {
    self.allowBorder[Int(edge.rawValue)] = allowBorder
  }

  private var preventResize: [Bool]
  private var allowBorder: [Bool]
}

private func resetFrameRendererAndDescendants(
  _ frameSetChild: RenderBoxWrapper?, _ parentFrameSet: RenderFrameSetWrapper
) {
  if frameSetChild == nil {
    return
  }

  var descendant: RenderBoxWrapper? = frameSetChild
  while descendant != nil {
    descendant!.setWidth(width: 0)
    descendant!.setHeight(height: 0)
    descendant!.clearNeedsLayout()
    descendant = RenderObjectTraversal.next(descendant!, parentFrameSet) as! RenderBoxWrapper?
  }
}

final class RenderFrameSetWrapper: RenderBoxWrapper {
  func frameSetElement() -> HTMLFrameSetElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func edgeInfo() -> FrameEdgeInfo {
    var result = FrameEdgeInfo(preventResize: frameSetElement().noResize(), allowBorder: true)

    let rows = Int(frameSetElement().totalRows())
    let cols = Int(frameSetElement().totalCols())
    if rows != 0 && cols != 0 {
      result.setPreventResize(.LeftFrameEdge, m_cols.preventResize[0])
      result.setAllowBorder(.LeftFrameEdge, m_cols.allowBorder[0])
      result.setPreventResize(.RightFrameEdge, m_cols.preventResize[cols])
      result.setAllowBorder(.RightFrameEdge, m_cols.allowBorder[cols])
      result.setPreventResize(.TopFrameEdge, m_rows.preventResize[0])
      result.setAllowBorder(.TopFrameEdge, m_rows.allowBorder[0])
      result.setPreventResize(.BottomFrameEdge, m_rows.preventResize[rows])
      result.setAllowBorder(.BottomFrameEdge, m_rows.allowBorder[rows])
    }

    return result
  }

  private static let noSplit: Int32 = -1

  private struct GridAxis: ~Copyable {
    init() {
      splitBeingResized = noSplit
    }

    mutating func resize(_ size: Int32) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    let sizes: [Int32] = []
    var deltas: [Int32] = []
    var preventResize: [Bool] = []
    var allowBorder: [Bool] = []
    let splitBeingResized: Int32
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    let doFullRepaint = selfNeedsLayout() && checkForRepaintDuringLayout()
    var oldBounds = LayoutRectWrapper()
    var repaintContainer: RenderLayerModelObjectWrapper? = nil
    if doFullRepaint {
      repaintContainer = containerForRepaint().renderer
      oldBounds = clippedOverflowRectForRepaint(repaintContainer)
    }

    if !parent()!.isRenderFrameSet() && !document().printing() {
      setWidth(width: view().viewWidth())
      setHeight(height: view().viewHeight())
    }

    let cols = frameSetElement().totalCols()
    let rows = frameSetElement().totalRows()

    if m_rows.sizes.count != rows || m_cols.sizes.count != cols {
      m_rows.resize(rows)
      m_cols.resize(cols)
    }

    let borderThickness = LayoutUnit(value: frameSetElement().border())
    layOutAxis(
      &m_rows, frameSetElement().rowLengths(), (height() - (rows - 1) * borderThickness).int())
    layOutAxis(
      &m_cols, frameSetElement().colLengths(), (width() - (cols - 1) * borderThickness).int())

    positionFrames()

    super.layout()

    computeEdgeInfo()

    updateLayerTransform()

    if doFullRepaint {
      repaintUsingContainer(
        repaintContainer, LayoutRectWrapper(rect: snappedIntRect(rect: oldBounds)))
      let newBounds = clippedOverflowRectForRepaint(repaintContainer)
      if newBounds != oldBounds {
        repaintUsingContainer(
          repaintContainer, LayoutRectWrapper(rect: snappedIntRect(rect: newBounds)))
      }
    }

    clearNeedsLayout()
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.phase != .Foreground {
      return
    }

    var child = firstChild()
    if child == nil {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    let rows = m_rows.sizes.count
    let cols = m_cols.sizes.count
    let borderThickness = LayoutUnit(value: frameSetElement().border())

    var yPos = LayoutUnit()
    for r in 0..<rows {
      var xPos = LayoutUnit()
      for c in 0..<cols {
        (child as! RenderElementWrapper).paint(
          paintInfo: &paintInfo, paintOffset: adjustedPaintOffset)
        xPos += m_cols.sizes[c]
        if borderThickness.bool() && m_cols.allowBorder[c + 1] {
          paintColumnBorder(
            paintInfo,
            snappedIntRect(
              rect: LayoutRectWrapper(
                x: adjustedPaintOffset.x + xPos, y: adjustedPaintOffset.y + yPos,
                width: borderThickness,
                height: height())))
          xPos += borderThickness
        }
        child = child!.nextSibling()
        if child == nil {
          return
        }
      }
      yPos += m_rows.sizes[r]
      if borderThickness.bool() && m_rows.allowBorder[r + 1] {
        paintRowBorder(
          paintInfo,
          snappedIntRect(
            rect: LayoutRectWrapper(
              x: adjustedPaintOffset.x, y: adjustedPaintOffset.y + yPos, width: width(),
              height: borderThickness)))
        yPos += borderThickness
      }
    }
  }

  private func layOutAxis(
    _ axis: inout GridAxis, _ grid: ArraySlice<LengthWrapper>, _ availableLen: Int32
  ) {
    let availableLen = max(availableLen, 0)

    var gridLayout = axis.sizes[...]

    if grid.isEmpty {
      gridLayout[0] = availableLen
      return
    }

    let gridLen = axis.sizes.count
    assert(gridLen != 0)

    var totalRelative: Int32 = 0
    var totalFixed: Int32 = 0
    var totalPercent: Int32 = 0
    var countRelative = 0
    var countFixed: Int32 = 0
    var countPercent: Int32 = 0

    // First we need to investigate how many columns of each type we have and
    // how much space these columns are going to require.
    for i in 0..<gridLen {
      // Count the total length of all of the fixed columns/rows -> totalFixed
      // Count the number of columns/rows which are fixed -> countFixed
      if grid[i].isFixed() {
        gridLayout[i] = max(grid[i].intValue(), 0)
        totalFixed += gridLayout[i]
        countFixed += 1
      }

      // Count the total percentage of all of the percentage columns/rows -> totalPercent
      // Count the number of columns/rows which are percentages -> countPercent
      if grid[i].isPercentOrCalculated() {
        gridLayout[i] = max(
          intValueForLength(length: grid[i], maximumValue: LayoutUnit(value: availableLen)), 0)
        totalPercent += gridLayout[i]
        countPercent += 1
      }

      // Count the total relative of all the relative columns/rows -> totalRelative
      // Count the number of columns/rows which are relative -> countRelative
      if grid[i].isRelative() {
        totalRelative += max(grid[i].intValue(), 1)
        countRelative += 1
      }
    }

    var remainingLen = availableLen

    // Fixed columns/rows are our first priority. If there is not enough space to fit all fixed
    // columns/rows we need to proportionally adjust their size.
    if totalFixed > remainingLen {
      let remainingFixed = remainingLen

      for i in 0..<gridLen {
        if grid[i].isFixed() {
          gridLayout[i] = (gridLayout[i] * remainingFixed) / totalFixed
          remainingLen -= gridLayout[i]
        }
      }
    } else {
      remainingLen -= totalFixed
    }

    // Percentage columns/rows are our second priority. Divide the remaining space proportionally
    // over all percentage columns/rows. IMPORTANT: the size of each column/row is not relative
    // to 100%, but to the total percentage. For example, if there are three columns, each of 75%,
    // and the available space is 300px, each column will become 100px in width.
    if totalPercent > remainingLen {
      let remainingPercent = remainingLen

      for i in 0..<gridLen {
        if grid[i].isPercentOrCalculated() {
          gridLayout[i] = (gridLayout[i] * remainingPercent) / totalPercent
          remainingLen -= gridLayout[i]
        }
      }
    } else {
      remainingLen -= totalPercent
    }

    // Relative columns/rows are our last priority. Divide the remaining space proportionally
    // over all relative columns/rows. IMPORTANT: the relative value of 0* is treated as 1*.
    if countRelative != 0 {
      var lastRelative = 0
      let remainingRelative = remainingLen

      for i in 0..<gridLen {
        if grid[i].isRelative() {
          gridLayout[i] = (max(grid[i].intValue(), 1) * remainingRelative) / totalRelative
          remainingLen -= gridLayout[i]
          lastRelative = i
        }
      }

      // If we could not evenly distribute the available space of all of the relative
      // columns/rows, the remainder will be added to the last column/row.
      // For example: if we have a space of 100px and three columns (*,*,*), the remainder will
      // be 1px and will be added to the last column: 33px, 33px, 34px.
      if remainingLen != 0 {
        gridLayout[lastRelative] += remainingLen
        remainingLen = 0
      }
    }

    // If we still have some left over space we need to divide it over the already existing
    // columns/rows
    if remainingLen != 0 {
      // Our first priority is to spread if over the percentage columns. The remaining
      // space is spread evenly, for example: if we have a space of 100px, the columns
      // definition of 25%,25% used to result in two columns of 25px. After this the
      // columns will each be 50px in width.
      if countPercent != 0 && totalPercent != 0 {
        let remainingPercent = remainingLen
        var changePercent: Int32 = 0

        for i in 0..<gridLen {
          if grid[i].isPercentOrCalculated() {
            changePercent = (remainingPercent * gridLayout[i]) / totalPercent
            gridLayout[i] += changePercent
            remainingLen -= changePercent
          }
        }
      } else if totalFixed != 0 {
        // Our last priority is to spread the remaining space over the fixed columns.
        // For example if we have 100px of space and two column of each 40px, both
        // columns will become exactly 50px.
        let remainingFixed = remainingLen
        var changeFixed: Int32 = 0

        for i in 0..<gridLen {
          if grid[i].isFixed() {
            changeFixed = (remainingFixed * gridLayout[i]) / totalFixed
            gridLayout[i] += changeFixed
            remainingLen -= changeFixed
          }
        }
      }
    }

    // If we still have some left over space we probably ended up with a remainder of
    // a division. We cannot spread it evenly anymore. If we have any percentage
    // columns/rows simply spread the remainder equally over all available percentage columns,
    // regardless of their size.
    if remainingLen != 0 && countPercent != 0 {
      let remainingPercent = remainingLen
      var changePercent: Int32 = 0

      for i in 0..<gridLen {
        if grid[i].isPercentOrCalculated() {
          changePercent = remainingPercent / countPercent
          gridLayout[i] += changePercent
          remainingLen -= changePercent
        }
      }
    } else if remainingLen != 0 && countFixed != 0 {
      // If we don't have any percentage columns/rows we only have
      // fixed columns. Spread the remainder equally over all fixed
      // columns/rows.
      let remainingFixed = remainingLen
      var changeFixed: Int32 = 0

      for i in 0..<gridLen {
        if grid[i].isFixed() {
          changeFixed = remainingFixed / countFixed
          gridLayout[i] += changeFixed
          remainingLen -= changeFixed
        }
      }
    }

    // Still some left over. Add it to the last column, because it is impossible
    // spread it evenly or equally.
    if remainingLen != 0 {
      gridLayout[gridLen - 1] += remainingLen
    }

    // now we have the final layout, distribute the delta over it
    var worked = true
    let gridDelta = axis.deltas[...]
    for i in 0..<gridLen {
      if gridLayout[i] != 0 && gridLayout[i] + gridDelta[i] <= 0 {
        worked = false
      }
      gridLayout[i] += gridDelta[i]
    }
    // if the deltas broke something, undo them
    if !worked {
      for i in 0..<gridLen {
        gridLayout[i] -= gridDelta[i]
      }
      for i in 0..<axis.deltas.count {
        axis.deltas[i] = 0
      }
    }
  }

  private func computeEdgeInfo() {
    for i in 0..<m_rows.preventResize.count {
      m_rows.preventResize[i] = frameSetElement().noResize()
    }
    for i in 0..<m_rows.allowBorder.count {
      m_rows.allowBorder[i] = false
    }
    for i in 0..<m_cols.preventResize.count {
      m_cols.preventResize[i] = frameSetElement().noResize()
    }
    for i in 0..<m_cols.allowBorder.count {
      m_cols.allowBorder[i] = false
    }

    var child = firstChild()

    let rows = m_rows.sizes.count
    let cols = m_cols.sizes.count
    for r in 0..<rows {
      for c in 0..<cols {
        var edgeInfo = FrameEdgeInfo()
        if let frameSet = child as? RenderFrameSetWrapper {
          edgeInfo = frameSet.edgeInfo()
        } else {
          edgeInfo = (child as! RenderFrameWrapper).edgeInfo()
        }
        fillFromEdgeInfo(edgeInfo, r, c)
        child = child!.nextSibling()
        if child == nil {
          return
        }
      }
    }
  }

  private func fillFromEdgeInfo(_ edgeInfo: FrameEdgeInfo, _ r: Int, _ c: Int) {
    if edgeInfo.allowBorder(.LeftFrameEdge) {
      m_cols.allowBorder[c] = true
    }
    if edgeInfo.allowBorder(.RightFrameEdge) {
      m_cols.allowBorder[c + 1] = true
    }
    if edgeInfo.preventResize(.LeftFrameEdge) {
      m_cols.preventResize[c] = true
    }
    if edgeInfo.preventResize(.RightFrameEdge) {
      m_cols.preventResize[c + 1] = true
    }

    if edgeInfo.allowBorder(.TopFrameEdge) {
      m_rows.allowBorder[r] = true
    }
    if edgeInfo.allowBorder(.BottomFrameEdge) {
      m_rows.allowBorder[r + 1] = true
    }
    if edgeInfo.preventResize(.TopFrameEdge) {
      m_rows.preventResize[r] = true
    }
    if edgeInfo.preventResize(.BottomFrameEdge) {
      m_rows.preventResize[r + 1] = true
    }
  }

  func positionFrames() {
    var child = firstChildBox()
    if child == nil {
      return
    }

    let rows = Int(frameSetElement().totalRows())
    let cols = Int(frameSetElement().totalCols())

    var yPos: Int32 = 0
    let borderThickness = frameSetElement().border()
    for r in 0..<rows {
      var xPos: Int32 = 0
      let height = m_rows.sizes[r]
      for c in 0..<cols {
        child!.setLocation(p: LayoutPointWrapper(point: IntPoint(x: xPos, y: yPos)))
        let width = m_cols.sizes[c]

        // has to be resized and itself resize its contents
        child!.setWidth(width: width)
        child!.setHeight(height: height)
        #if WTF_PLATFORM_IOS_FAMILY
          // FIXME: Is this iOS-specific?
          child!.setNeedsLayout(markParents: .MarkOnlyThis)
        #else
          child!.setNeedsLayout()
        #endif
        child!.layout()

        xPos += width + borderThickness

        child = child!.nextSiblingBox()
        if child == nil {
          return
        }
      }
      yPos += height + borderThickness
    }

    resetFrameRendererAndDescendants(child, self)
  }

  private func paintRowBorder(_ paintInfo: PaintInfoWrapper, _ borderRect: IntRect) {
    if !paintInfo.rect.intersects(other: LayoutRectWrapper(rect: borderRect)) {
      return
    }

    // FIXME: We should do something clever when borders from distinct framesets meet at a join.

    // Fill first.
    let context = paintInfo.context()
    context.fillRect(
      rect: FloatRectWrapper(r: borderRect),
      color: frameSetElement().hasBorderColor()
        ? style().visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyBorderLeftColor)
        : ColorWrapper(borderFillColor))

    // Now stroke the edges but only if we have enough room to paint both edges with a little
    // bit of the fill color showing through.
    if borderRect.height() >= 3 {
      context.fillRect(
        rect: FloatRectWrapper(
          r: IntRect(location: borderRect.location, size: IntSize(width: width().int(), height: 1))),
        color: ColorWrapper(borderStartEdgeColor))
      context.fillRect(
        rect: FloatRectWrapper(
          r: IntRect(
            location: IntPoint(x: borderRect.x(), y: borderRect.maxY() - 1),
            size: IntSize(width: width().int(), height: 1))),
        color: borderEndEdgeColor)
    }
  }

  private func paintColumnBorder(_ paintInfo: PaintInfoWrapper, _ borderRect: IntRect) {
    if !paintInfo.rect.intersects(other: LayoutRectWrapper(rect: borderRect)) {
      return
    }

    // FIXME: We should do something clever when borders from distinct framesets meet at a join.

    // Fill first.
    let context = paintInfo.context()
    context.fillRect(
      rect: FloatRectWrapper(r: borderRect),
      color: frameSetElement().hasBorderColor()
        ? style().visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyBorderLeftColor)
        : ColorWrapper(borderFillColor))

    // Now stroke the edges but only if we have enough room to paint both edges with a little
    // bit of the fill color showing through.
    if borderRect.width() >= 3 {
      context.fillRect(
        rect: FloatRectWrapper(
          r: IntRect(location: borderRect.location, size: IntSize(width: 1, height: height().int()))
        ),
        color: ColorWrapper(borderStartEdgeColor))
      context.fillRect(
        rect: FloatRectWrapper(
          r: IntRect(
            location: IntPoint(x: borderRect.maxX() - 1, y: borderRect.y()),
            size: IntSize(width: 1, height: height().int()))),
        color: borderEndEdgeColor)
    }
  }

  private var m_rows = GridAxis()
  private var m_cols = GridAxis()
}
