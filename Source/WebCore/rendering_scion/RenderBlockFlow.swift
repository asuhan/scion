/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
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

import wk_interop

class RenderBlockFlowWrapper: RenderBlockWrapper {
  convenience init(
    type: `Type`, document: Document, style: RenderStyleWrapper, flags: BlockFlowFlag = []
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func collapsedMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintColumnRules(paintInfo: PaintInfoWrapper, point: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStaticInlinePositionForChild(
    child: RenderBoxWrapper, blockOffset: LayoutUnit, inlinePosition: LayoutUnit
  ) {
    wk_interop.RenderBlockFlow_setStaticInlinePositionForChild(
      p, child.p, blockOffset.rawValue(), inlinePosition.rawValue())
  }

  func setBreakAtLineToAvoidWidow(lineToBreak: Int) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func multiColumnFlowForBlockFlow() -> RenderMultiColumnFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearDidBreakAtLineToAvoidWidow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMultiColumnFlow(fragmentedFlow: RenderMultiColumnFlowWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearMultiColumnFlow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willCreateColumns(desiredColumnCount: UInt32? = nil) -> Bool {
    // The following types are not supposed to create multicol context.
    if isRenderFileUploadControl() || isRenderTextControl() || isRenderListBox() {
      return false
    }
    if isRenderSVGBlock() {
      return false
    }
    if style().display() == .RubyBlock || style().display() == .RubyAnnotation {
      return false
    }

    if firstChild() == nil {
      return false
    }

    if style().pseudoElementType() != .None {
      return false
    }

    // If overflow-y is set to paged-x or paged-y on the body or html element, we'll handle the paginating in the RenderView instead.
    if (style().overflowY() == .PagedX || style().overflowY() == .PagedY)
      && !(isDocumentElementRenderer() || isBody())
    {
      return true
    }

    if !style().specifiesColumns() {
      return false
    }

    // column-axis with opposite writing direction initiates MultiColumnFlow.
    if !style().hasInlineColumnAxis() {
      return true
    }

    // Non-auto column-width always initiates MultiColumnFlow.
    if !style().hasAutoColumnWidth() {
      return true
    }

    if desiredColumnCount != nil {
      return desiredColumnCount! > 1
    }

    // column-count > 1 always initiates MultiColumnFlow.
    if !style().hasAutoColumnCount() {
      return style().columnCount() > 1
    }

    fatalError("Not reached")
  }

  func requiresColumns(desiredColumnCount: Int32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func deleteLines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeFloatingObjects() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markAllDescendantsWithFloatsForLayout(
    floatToRemove: RenderBoxWrapper? = nil, inLayout: Bool = true
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markSiblingsWithFloatsForLayout(floatToRemove: RenderBoxWrapper? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func floatingObjectSet() -> FloatingObjectSet? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func insertFloatingObjectForIFC(floatBox: RenderBoxWrapper) -> FloatingObjectWrapper {
    return FloatingObjectWrapper(
      p: wk_interop.RenderBlockFlow_insertFloatingObjectForIFC(p, floatBox.p))
  }

  override func setChildrenInline(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum InvalidationReason {
    case StyleChange
    case InsertionOrRemoval  // renderer gets constructed/goes away
    case ContentChange  // existing renderer gets changed (text content only atm)
  }

  func invalidateLineLayoutPath(invalidationReason: InvalidationReason) {
    switch lineLayoutPath() {
    case .UndeterminedPath:
      return
    case .SvgTextPath:
      setLineLayoutPath(path: .UndeterminedPath)
      return
    case .InlinePath:
      // FIXME: Implement partial invalidation.
      if inlineLayout() != nil {
        previousInlineLayoutContentBoxLogicalHeight = inlineLayout()!.contentBoxLogicalHeight()
        if invalidationReason != .InsertionOrRemoval {
          // Repaint and set needs layout, including out of flow boxes.
          // Since we eagerly remove the display content here, repaints issued between this invalidation (triggered by style change/content mutation) and the subsequent layout would produce empty rects.
          repaint()
          let walker = InlineWalker(root: self)
          while !walker.atEnd() {
            let renderer = walker.current()!
            if !renderer.everHadLayout() {
              walker.advance()
              continue
            }
            if !renderer.isInFlow()
              && inlineLayout()!.contains(renderer: renderer as! RenderElementWrapper)
            {
              renderer.repaint()
            }
            renderer.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
            walker.advance()
          }
        }
      }
      lineLayout = .None
      if invalidationReason == .InsertionOrRemoval {
        setLineLayoutPath(path: .UndeterminedPath)
      }
      if selfNeedsLayout() || normalChildNeedsLayout() {
        return
      }
      // FIXME: We should just kick off a subtree layout here (if needed at all) see webkit.org/b/172947.
      setNeedsLayout()
      return
    }
  }

  enum LineLayoutPath {
    case UndeterminedPath
    case InlinePath
    case SvgTextPath
  }

  func lineLayoutPath() -> LineLayoutPath {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLineLayoutPath(path: LineLayoutPath) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgTextLayout() -> LegacyLineLayout? {
    switch lineLayout {
    case .Legacy(let layout):
      return layout
    default:
      return nil
    }
  }

  func inlineLayout() -> LayoutIntegration.LineLayout? {
    switch lineLayout {
    case .Integration(let layout):
      return layout
    default:
      return nil
    }
  }

  // Update minimum page height required to avoid fragmentation where it shouldn't occur (inside
  // unbreakable content, between orphans and widows, etc.). This will be used as a hint to the
  // column balancer to help set a good minimum column height.
  func updateMinimumPageHeight(offset: LayoutUnit, minHeight: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addFloatsToNewParent(toBlockFlow: RenderBlockFlowWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endPaddingWidthForCaret() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBlockFlow_endPaddingWidthForCaret(p))
  }

  func lowestInitialLetterLogicalBottom() -> LayoutUnit? {
    let raw = wk_interop.RenderBlockFlow_lowestInitialLetterLogicalBottom(p)
    if !raw.is_valid {
      return nil
    }
    return LayoutUnit.fromRawValue(value: raw.value)
  }

  struct LinePaginationAdjustment {
    var strut = LayoutUnit(value: 0)
    var isFirstAfterPageBreak = false
  }

  override func paintInlineChildren(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(childrenInline())

    if let inlineLayout = inlineLayout() {
      inlineLayout.paint(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    if let svgTextLayout = svgTextLayout() {
      svgTextLayout.lineBoxes.paint(
        renderer: self, paintInfo: paintInfo, paintOffset: paintOffset)
    }
  }

  override func paintFloats(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, preservePhase: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasInlineLayout() -> Bool {
    switch lineLayout {
    case .Integration:
      return true
    default:
      return false
    }
  }

  func computeLineAdjustmentForPagination(
    lineBox: InlineIterator.LineBoxIterator, delta: LayoutUnit, floatMinimumBottom: LayoutUnit
  ) -> LinePaginationAdjustment {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: This is temporary until after we remove the forced "line layout codepath" invalidation.
  private var previousInlineLayoutContentBoxLogicalHeight: LayoutUnit?

  enum LineLayout {
    case None
    case Integration(LayoutIntegration.LineLayout)
    case Legacy(LegacyLineLayout)
  }

  var lineLayout: LineLayout = .None
}
