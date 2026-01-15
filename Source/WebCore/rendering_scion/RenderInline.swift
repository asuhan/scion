/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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

private func computeMargin(_ renderer: RenderInlineWrapper?, _ margin: LengthWrapper) -> LayoutUnit
{
  if margin.isAuto() {
    return LayoutUnit(value: 0)
  }
  if margin.isFixed() {
    return LayoutUnit(value: margin.value())
  }
  if margin.isPercentOrCalculated() {
    return minimumValueForLength(
      length: margin,
      maximumValue: max(LayoutUnit(value: 0), renderer!.containingBlock()!.availableLogicalWidth()))
  }
  return LayoutUnit(value: 0)
}

class RenderInlineWrapper: RenderBoxModelObjectWrapper {
  override init(p: UnsafeMutableRawPointer?) {
    if p != nil {
      super.init(p: p!)
    } else {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  init(type: `Type`, element: ElementWrapper, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(type: `Type`, document: Document, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginLeft() -> LayoutUnit {
    return computeMargin(self, style().marginLeft())
  }

  override func marginBottom() -> LayoutUnit {
    return computeMargin(self, style().marginBottom())
  }

  override func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    return computeMargin(self, style().marginBeforeUsing(otherStyle: otherStyle ?? style()))
  }

  override func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    return computeMargin(self, style().marginAfterUsing(otherStyle: otherStyle ?? style()))
  }

  func innerPaddingBoxWidth() -> LayoutUnit {
    var firstInlineBoxPaddingBoxLeft = LayoutUnit()
    var lastInlineBoxPaddingBoxRight = LayoutUnit()

    if LayoutIntegration.LineLayout.containing(renderer: self) != nil {
      let inlineBox = InlineIterator.firstInlineBoxFor(renderInline: self)
      if inlineBox.bool() {
        if style().isLeftToRightDirection() {
          firstInlineBoxPaddingBoxLeft =
            LayoutUnit(value: inlineBox.get().logicalLeftIgnoringInlineDirection() + borderStart())
          while inlineBox.get().nextInlineBox().bool() {
            inlineBox.traverseNextInlineBox()
          }
          assert(inlineBox.bool())
          lastInlineBoxPaddingBoxRight =
            LayoutUnit(value: inlineBox.get().logicalRightIgnoringInlineDirection() - borderEnd())
        } else {
          lastInlineBoxPaddingBoxRight = LayoutUnit(
            value: inlineBox.get().logicalRightIgnoringInlineDirection() - borderStart())
          while inlineBox.get().nextInlineBox().bool() {
            inlineBox.traverseNextInlineBox()
          }
          assert(inlineBox.bool())
          firstInlineBoxPaddingBoxLeft =
            LayoutUnit(value: inlineBox.get().logicalLeftIgnoringInlineDirection() + borderEnd())
        }
        return max(
          LayoutUnit(value: UInt64(0)), lastInlineBoxPaddingBoxRight - firstInlineBoxPaddingBoxLeft)
      }
      return LayoutUnit()
    }

    guard let firstInlineBox = firstLegacyInlineBox() else { return LayoutUnit() }
    guard let lastInlineBox = lastLegacyInlineBox() else { return LayoutUnit() }

    if style().isLeftToRightDirection() {
      firstInlineBoxPaddingBoxLeft = LayoutUnit(value: firstInlineBox.logicalLeft())
      lastInlineBoxPaddingBoxRight = LayoutUnit(value: lastInlineBox.logicalRight())
    } else {
      lastInlineBoxPaddingBoxRight = LayoutUnit(value: firstInlineBox.logicalRight())
      firstInlineBoxPaddingBoxLeft = LayoutUnit(value: lastInlineBox.logicalLeft())
    }
    return max(
      LayoutUnit(value: UInt64(0)), lastInlineBoxPaddingBoxRight - firstInlineBoxPaddingBoxLeft)
  }

  func innerPaddingBoxHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func linesVisualOverflowBoundingBox() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstLegacyInlineBox() -> LegacyInlineFlowBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastLegacyInlineBox() -> LegacyInlineFlowBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintOutline(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func frameRectForStickyPositioning() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
