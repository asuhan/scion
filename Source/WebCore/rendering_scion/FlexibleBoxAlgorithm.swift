/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct FlexLayoutItem {
  init(
    flexItem: RenderBoxWrapper, flexBaseContentSize: LayoutUnit,
    mainAxisBorderAndPadding: LayoutUnit, mainAxisMargin: LayoutUnit,
    minMaxSizes: (LayoutUnit, LayoutUnit), everHadLayout: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hypotheticalMainAxisMarginBoxSize() -> LayoutUnit {
    return hypotheticalMainContentSize + mainAxisBorderAndPadding + mainAxisMargin
  }

  func flexBaseMarginBoxSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flexedMarginBoxSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func style() -> RenderStyleWrapper { return renderer.style() }

  func constrainSizeByMinMax(size: LayoutUnit) -> LayoutUnit {
    let (minSize, maxSize) = minMaxSizes
    return max(minSize, min(size, maxSize))
  }

  let renderer: RenderBoxWrapper
  let flexBaseContentSize: LayoutUnit
  let mainAxisBorderAndPadding: LayoutUnit
  let mainAxisMargin: LayoutUnit
  let minMaxSizes: (LayoutUnit, LayoutUnit)
  let hypotheticalMainContentSize: LayoutUnit
  var flexedContentSize: LayoutUnit
  var frozen = false
  let everHadLayout = false
}

struct FlexLayoutAlgorithm {
  init(
    flexbox: RenderFlexibleBoxWrapper, lineBreakLength: LayoutUnit,
    allItems: ArraySlice<FlexLayoutItem>,
    gapBetweenItems: LayoutUnit
  ) {
    self.flexbox = flexbox
    self.lineBreakLength = lineBreakLength
    self.allItems = allItems
    self.gapBetweenItems = gapBetweenItems
  }

  struct NextFlexLine {
    let lineItems: [FlexLayoutItem]
    let sumFlexBaseSize: LayoutUnit
    let totalFlexGrow: Float64
    let totalFlexShrink: Float64
    let totalWeightedFlexShrink: Float64
    let sumHypotheticalMainSize: LayoutUnit
  }

  // The hypothetical main size of an item is the flex base size clamped
  // according to its min and max main size properties
  func computeNextFlexLine(nextIndex: inout UInt64) -> NextFlexLine {
    var lineItems: [FlexLayoutItem] = []
    var sumFlexBaseSize = LayoutUnit(value: UInt64(0))
    var totalFlexGrow: Float64 = 0
    var totalFlexShrink: Float64 = 0
    var totalWeightedFlexShrink: Float64 = 0
    var sumHypotheticalMainSize = LayoutUnit(value: UInt64(0))

    // Trim main axis margin for item at the start of the flex line
    if nextIndex < allItems.count && flexbox.shouldTrimMainAxisMarginStart() {
      flexbox.trimMainAxisMarginStart(allItems[Int(nextIndex)])
    }
    while nextIndex < allItems.count {
      let flexLayoutItem = allItems[Int(nextIndex)]
      let style = flexLayoutItem.style()
      assert(!flexLayoutItem.renderer.isOutOfFlowPositioned())
      if isMultiline()
        && (sumHypotheticalMainSize + flexLayoutItem.hypotheticalMainAxisMarginBoxSize()
          > lineBreakLength
          && !canFitItemWithTrimmedMarginEnd(flexLayoutItem, sumHypotheticalMainSize))
        && !lineItems.isEmpty
      {
        break
      }
      lineItems.append(flexLayoutItem)
      sumFlexBaseSize += flexLayoutItem.flexBaseMarginBoxSize() + gapBetweenItems
      totalFlexGrow += Float64(style.flexGrow())
      totalFlexShrink += Float64(style.flexShrink())
      totalWeightedFlexShrink += Float64(style.flexShrink() * flexLayoutItem.flexBaseContentSize)
      sumHypotheticalMainSize +=
        flexLayoutItem.hypotheticalMainAxisMarginBoxSize() + gapBetweenItems
      nextIndex += 1
    }

    if !lineItems.isEmpty {
      // We added a gap after every item but there shouldn't be one after the last item, so subtract it here. Note that
      // sums might be negative here due to negative margins in flex items.
      sumHypotheticalMainSize -= gapBetweenItems
      sumFlexBaseSize -= gapBetweenItems
    }

    assert(lineItems.count > 0 || nextIndex == allItems.count)
    // Trim main axis margin for item at the end of the flex line
    if lineItems.count != 0 && flexbox.shouldTrimMainAxisMarginEnd() {
      let lastItem = lineItems.last!
      removeMarginEndFromFlexSizes(lastItem, &sumFlexBaseSize, &sumHypotheticalMainSize)
      flexbox.trimMainAxisMarginEnd(lastItem)
    }
    return NextFlexLine(
      lineItems: lineItems, sumFlexBaseSize: sumFlexBaseSize, totalFlexGrow: totalFlexGrow,
      totalFlexShrink: totalFlexShrink, totalWeightedFlexShrink: totalWeightedFlexShrink,
      sumHypotheticalMainSize: sumHypotheticalMainSize)
  }

  private func isMultiline() -> Bool { return flexbox.style().flexWrap() != .NoWrap }

  private func canFitItemWithTrimmedMarginEnd(
    _ flexLayoutItem: FlexLayoutItem, _ sumHypotheticalMainSize: LayoutUnit
  ) -> Bool {
    let marginTrim = flexbox.style().marginTrim()
    if (flexbox.isHorizontalFlow() && marginTrim.contains(.InlineEnd))
      || (flexbox.isColumnFlow() && marginTrim.contains(.BlockEnd))
    {
      return sumHypotheticalMainSize + flexLayoutItem.hypotheticalMainAxisMarginBoxSize()
        - flexbox.flowAwareMarginEndForFlexItem(flexItem: flexLayoutItem.renderer)
        <= lineBreakLength
    }
    return false
  }

  private func removeMarginEndFromFlexSizes(
    _ flexLayoutItem: FlexLayoutItem, _ sumFlexBaseSize: inout LayoutUnit,
    _ sumHypotheticalMainSize: inout LayoutUnit
  ) {
    var margin = LayoutUnit()
    if flexbox.isHorizontalFlow() {
      margin = flexLayoutItem.renderer.marginEnd(otherStyle: flexbox.style())
    } else {
      margin = flexLayoutItem.renderer.marginAfter(otherStyle: flexbox.style())
    }
    sumFlexBaseSize -= margin
    sumHypotheticalMainSize -= margin
  }

  private let flexbox: RenderFlexibleBoxWrapper
  private let lineBreakLength: LayoutUnit
  private let allItems: ArraySlice<FlexLayoutItem>

  private let gapBetweenItems: LayoutUnit
}
