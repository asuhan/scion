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

  func clearDidBreakAtLineToAvoidWidow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func insertFloatingObjectForIFC(floatBox: RenderBoxWrapper) -> FloatingObjectWrapper {
    return FloatingObjectWrapper(
      p: wk_interop.RenderBlockFlow_insertFloatingObjectForIFC(p, floatBox.p))
  }

  func inlineLayout() -> LayoutIntegration.LineLayout? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Update minimum page height required to avoid fragmentation where it shouldn't occur (inside
  // unbreakable content, between orphans and widows, etc.). This will be used as a hint to the
  // column balancer to help set a good minimum column height.
  func updateMinimumPageHeight(offset: LayoutUnit, minHeight: LayoutUnit) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintFloats(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, preservePhase: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeLineAdjustmentForPagination(
    lineBox: InlineIterator.LineBoxIterator, delta: LayoutUnit, floatMinimumBottom: LayoutUnit
  ) -> LinePaginationAdjustment {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum LineLayout {
    case None
    case Integration(LayoutIntegration.LineLayout)
    case Legacy(LegacyLineLayout)
  }

  let lineLayout: LineLayout = .None
}
