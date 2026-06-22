/*
 * Copyright (C) 2003-2017 Apple Inc. All rights reserved.
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

class LegacyRootInlineBox: LegacyInlineFlowBox {
  init(_ block: RenderBlockFlowWrapper) {
    super.init(block)
    setIsHorizontal(block.isHorizontalWritingMode())
  }

  func blockFlow() -> RenderBlockFlowWrapper { return renderer() as! RenderBlockFlowWrapper }

  func nextRootBox() -> LegacyRootInlineBox? { return m_nextLineBox as! LegacyRootInlineBox? }

  func prevRootBox() -> LegacyRootInlineBox? { return m_prevLineBox as! LegacyRootInlineBox? }

  override func adjustPosition(_ dx: Float32, _ dy: Float32) {
    super.adjustPosition(dx, dy)
    let blockDirectionDelta = LayoutUnit(value: isHorizontal() ? dy : dx)  // The block direction delta is a LayoutUnit.
    lineTop += blockDirectionDelta
    lineBottom += blockDirectionDelta
    lineBoxTop += blockDirectionDelta
    lineBoxBottom += blockDirectionDelta
  }

  func selectionTop() -> LayoutUnit {
    let selectionTop = lineTop

    if renderer().style().isFlippedLinesWritingMode() {
      return selectionTop
    }

    var prevBottom = LayoutUnit()
    if let previousBox = prevRootBox() {
      prevBottom = previousBox.selectionBottom()
    } else {
      prevBottom = selectionTop
    }

    return prevBottom
  }

  func selectionBottom() -> LayoutUnit {
    let selectionBottom = lineBottom

    if !renderer().style().isFlippedLinesWritingMode() || nextRootBox() == nil {
      return selectionBottom
    }

    return nextRootBox()!.selectionTop()
  }

  func setLineTopBottomPositions(
    top: LayoutUnit, bottom: LayoutUnit, lineBoxTop: LayoutUnit, lineBoxBottom: LayoutUnit
  ) {
    self.lineTop = top
    self.lineBottom = bottom
    self.lineBoxTop = lineBoxTop
    self.lineBoxBottom = lineBoxBottom
  }

  override final func selectionState() -> RenderObjectWrapper.HighlightState {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baselineType() -> FontBaseline { return m_baselineType }

  func logicalTopVisualOverflow() -> LayoutUnit {
    return super.logicalTopVisualOverflow(lineTop: lineTop)
  }

  func logicalBottomVisualOverflow() -> LayoutUnit {
    return super.logicalBottomVisualOverflow(lineBottom: lineBottom)
  }

  override final func isRootInlineBox() -> Bool { return true }

  var lineTop = LayoutUnit()
  var lineBottom = LayoutUnit()

  var lineBoxTop = LayoutUnit()
  var lineBoxBottom = LayoutUnit()
}
