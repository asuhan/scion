/*
 * Copyright (C) 2022 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

struct FlexBaseAndHypotheticalMainSize {
  var flexBase = LayoutUnit(value: 0)
  var hypotheticalMainSize = LayoutUnit(value: 0)
}

struct PositionAndMargins {
  func margin() -> LayoutUnit {
    return marginStart + marginEnd
  }

  var position = LayoutUnit()
  var marginStart = LayoutUnit()
  var marginEnd = LayoutUnit()
}

func outerMainSize(flexItem: LogicalFlexItem, mainSize: LayoutUnit, usedMargin: LayoutUnit? = nil)
  -> LayoutUnit
{
  var outerMainSize = usedMargin ?? flexItem.mainAxis().margin()
  if flexItem.isContentBoxBased() {
    outerMainSize += flexItem.mainAxis().borderAndPadding
  }
  outerMainSize += mainSize
  return outerMainSize
}

func outerCrossSize(flexItem: LogicalFlexItem, crossSize: LayoutUnit, usedMargin: LayoutUnit? = nil)
  -> LayoutUnit
{
  var outerCrossSize = usedMargin ?? flexItem.crossAxis().margin()
  if flexItem.isContentBoxBased() {
    outerCrossSize += flexItem.crossAxis().borderAndPadding
  }
  outerCrossSize += crossSize
  return outerCrossSize
}

// This class implements the layout logic for flex formatting contexts.
// https://www.w3.org/TR/css-flexbox-1/
struct FlexLayout {
  init(flexFormattingContext: FlexFormattingContext) {
    self.flexFormattingContext = flexFormattingContext
  }

  typealias LogicalFlexItems = [LogicalFlexItem]
  struct LogicalConstraints {
    struct AxisGeometry {
      var definiteSize: LayoutUnit? = nil
      var minimumSize: LayoutUnit? = nil
      var maximumSize: LayoutUnit? = nil

      var minimumContentSize: LayoutUnit? = nil
      var maximumContentSize: LayoutUnit? = nil
      var availableSize = LayoutUnit()  // space available to the flex container minus margin, border, and padding.
    }
    var mainAxis = AxisGeometry()
    var crossAxis = AxisGeometry()
  }
  typealias LogicalFlexItemRects = [FlexRect]
  typealias FlexBaseAndHypotheticalMainSizeList = [FlexBaseAndHypotheticalMainSize]
  typealias LineRanges = [Range<UInt64>]
  typealias SizeList = [LayoutUnit]
  typealias PositionAndMarginsList = [PositionAndMargins]
  typealias LinesCrossSizeList = [LayoutUnit]
  typealias LinesCrossPositionList = [LayoutUnit]

  mutating func layout(logicalConstraints: LogicalConstraints, flexItems: LogicalFlexItems)
    -> LogicalFlexItemRects
  {
    // This follows https://www.w3.org/TR/css-flexbox-1/#layout-algorithm
    // 9.2. (#2) Determine the available main and cross space for the flex items
    computeAvailableMainAndCrossSpace(logicalConstraints: logicalConstraints)

    var flexItemsMainSizeList = SizeList()
    var flexItemsCrossSizeList = SizeList()
    var flexLinesCrossSizeList = LinesCrossSizeList()
    var lineRanges = LineRanges()

    performContentSizing(
      logicalConstraints: logicalConstraints, flexItems: flexItems, lineRanges: &lineRanges,
      flexItemsMainSizeList: &flexItemsMainSizeList,
      flexItemsCrossSizeList: &flexItemsCrossSizeList,
      flexLinesCrossSizeList: &flexLinesCrossSizeList)

    var mainPositionAndMargins = PositionAndMarginsList()
    var crossPositionAndMargins = PositionAndMarginsList()
    var linesCrossPositionList = LinesCrossPositionList()

    performContentAlignment(
      logicalConstraints: logicalConstraints, flexItems: flexItems, lineRanges: lineRanges,
      flexItemsMainSizeList: flexItemsMainSizeList, flexItemsCrossSizeList: flexItemsCrossSizeList,
      flexLinesCrossSizeList: &flexLinesCrossSizeList,
      mainPositionAndMargins: &mainPositionAndMargins,
      crossPositionAndMargins: &crossPositionAndMargins,
      linesCrossPositionList: &linesCrossPositionList)

    return computeFlexItemRects(
      lineRanges: lineRanges, mainPositionAndMargins: mainPositionAndMargins,
      crossPositionAndMargins: crossPositionAndMargins,
      linesCrossPositionList: linesCrossPositionList,
      flexItemsMainSizeList: flexItemsMainSizeList, flexItemsCrossSizeList: flexItemsCrossSizeList)
  }

  func performContentSizing(
    logicalConstraints: LogicalConstraints, flexItems: LogicalFlexItems,
    lineRanges: inout LineRanges,
    flexItemsMainSizeList: inout SizeList,
    flexItemsCrossSizeList: inout SizeList,
    flexLinesCrossSizeList: inout LinesCrossSizeList
  ) {
    var needsMainAxisLayout = true

    while needsMainAxisLayout {
      performMainAxisSizing(
        logicalConstraints: logicalConstraints, flexItems: flexItems, lineRanges: &lineRanges,
        flexItemsMainSizeList: &flexItemsMainSizeList)

      performCrossAxisSizing(
        logicalConstraints: logicalConstraints, flexItems: flexItems, lineRanges: lineRanges,
        flexItemsMainSizeList: flexItemsMainSizeList,
        flexItemsCrossSizeList: &flexItemsCrossSizeList,
        flexLinesCrossSizeList: &flexLinesCrossSizeList, needsMainAxisLayout: &needsMainAxisLayout)
    }
  }

  func performMainAxisSizing(
    logicalConstraints: LogicalConstraints, flexItems: LogicalFlexItems,
    lineRanges: inout LineRanges, flexItemsMainSizeList: inout SizeList
  ) {
    // 9.2. (#3) Determine the flex base size and hypothetical main size of each item
    let flexBaseAndHypotheticalMainSizeList = flexBaseAndHypotheticalMainSizeForFlexItems(
      mainAxis: logicalConstraints.mainAxis, flexItems: flexItems)
    // 9.2. (#4) Determine the main size of the flex container
    let flexContainerMainSize = flexContainerMainSize(mainAxis: logicalConstraints.mainAxis)
    // 9.3. (#5) Collect flex items into flex lines
    lineRanges = computeFlexLines(
      flexItems: flexItems, flexContainerMainSize: flexContainerMainSize,
      flexBaseAndHypotheticalMainSizeList: flexBaseAndHypotheticalMainSizeList)
    // 9.3. (#6) Resolve the flexible lengths of all the flex items to find their used main size
    flexItemsMainSizeList = computeMainSizeForFlexItems(
      flexItems: flexItems, lineRanges: lineRanges, flexContainerMainSize: flexContainerMainSize,
      flexBaseAndHypotheticalMainSizeList: flexBaseAndHypotheticalMainSizeList)
  }

  func performCrossAxisSizing(
    logicalConstraints: LogicalConstraints, flexItems: LogicalFlexItems,
    lineRanges: LineRanges,
    flexItemsMainSizeList: SizeList,
    flexItemsCrossSizeList: inout SizeList,
    flexLinesCrossSizeList: inout LinesCrossSizeList,
    needsMainAxisLayout: inout Bool
  ) {
    // 9.4. (#7) Determine the hypothetical cross size of each item
    let hypotheticalCrossSizeList = hypotheticalCrossSizeForFlexItems(
      flexItems: flexItems, flexItemsMainSizeList: flexItemsMainSizeList)
    // 9.4. (#8) Calculate the cross size of each flex line
    flexLinesCrossSizeList = crossSizeForFlexLines(
      lineRanges: lineRanges, crossAxis: logicalConstraints.crossAxis, flexItems: flexItems,
      flexItemsHypotheticalCrossSizeList: hypotheticalCrossSizeList)
    // 9.4. (#9) Handle 'align-content: stretch
    stretchFlexLines(
      flexLinesCrossSizeList: &flexLinesCrossSizeList, numberOfLines: UInt64(lineRanges.count),
      crossAxis: logicalConstraints.crossAxis)
    // 9.4. (#10) Collapse visibility:collapse items
    let collapsedContentNeedsSecondLayout = collapseNonVisibleFlexItems()
    if collapsedContentNeedsSecondLayout {
      return
    }
    // 9.4. (#11) Determine the used cross size of each flex item
    flexItemsCrossSizeList = computeCrossSizeForFlexItems(
      flexItems: flexItems, lineRanges: lineRanges, flexLinesCrossSizeList: flexLinesCrossSizeList,
      flexItemsHypotheticalCrossSizeList: hypotheticalCrossSizeList)
    needsMainAxisLayout = false
  }

  func performContentAlignment(
    logicalConstraints: LogicalConstraints,
    flexItems: LogicalFlexItems,
    lineRanges: LineRanges, flexItemsMainSizeList: SizeList,
    flexItemsCrossSizeList: SizeList,
    flexLinesCrossSizeList: inout LinesCrossSizeList,
    mainPositionAndMargins: inout PositionAndMarginsList,
    crossPositionAndMargins: inout PositionAndMarginsList,
    linesCrossPositionList: inout LinesCrossPositionList
  ) {
    // 9.5. (#12) Main-Axis Alignment
    mainPositionAndMargins = handleMainAxisAlignment(
      availableMainSpace: availableMainSpace, lineRanges: lineRanges, flexItems: flexItems,
      flexItemsMainSizeList: flexItemsMainSizeList)
    // 9.6. (#13 - #16) Cross-Axis Alignment
    crossPositionAndMargins = handleCrossAxisAlignmentForFlexItems(
      flexItems: flexItems, lineRanges: lineRanges, flexItemsCrossSizeList: flexItemsCrossSizeList,
      flexLinesCrossSizeList: flexLinesCrossSizeList)
    linesCrossPositionList = handleCrossAxisAlignmentForFlexLines(
      crossAxis: logicalConstraints.crossAxis, lineRanges: lineRanges,
      flexLinesCrossSizeList: &flexLinesCrossSizeList)
  }

  mutating func computeAvailableMainAndCrossSpace(logicalConstraints: LogicalConstraints) {
    availableMainSpace = computedFinalSize(candidateSizes: logicalConstraints.mainAxis)
    availableCrossSpace = computedFinalSize(candidateSizes: logicalConstraints.crossAxis)
  }

  func computedFinalSize(candidateSizes: LogicalConstraints.AxisGeometry) -> LayoutUnit {
    // For each dimension, if that dimension of the flex container's content box is a definite size, use that;
    // if that dimension of the flex container is being sized under a min or max-content constraint, the available space in that dimension is that constraint;
    // otherwise, subtract the flex container's margin, border, and padding from the space available to the flex container in that dimension and use that value.
    if let r = candidateSizes.definiteSize {
      return r
    }
    if let r = candidateSizes.minimumContentSize {
      return r
    }
    if let r = candidateSizes.maximumContentSize {
      return r
    }
    return candidateSizes.availableSize
  }

  func computeFlexItemRects(
    lineRanges: LineRanges, mainPositionAndMargins: PositionAndMarginsList,
    crossPositionAndMargins: PositionAndMarginsList, linesCrossPositionList: LinesCrossPositionList,
    flexItemsMainSizeList: SizeList, flexItemsCrossSizeList: SizeList
  ) -> LogicalFlexItemRects {
    var flexRects = LogicalFlexItemRects()
    for (lineIndex, lineRange) in lineRanges.enumerated() {
      for flexItemIndex in Int(lineRange.lowerBound)..<Int(lineRange.upperBound) {
        let flexItemMainPosition = mainPositionAndMargins[flexItemIndex].position
        let flexItemCrossPosition =
          linesCrossPositionList[lineIndex] + crossPositionAndMargins[flexItemIndex].position
        flexRects[flexItemIndex] = FlexRect(
          rect: LayoutRectWrapper(
            x: flexItemMainPosition, y: flexItemCrossPosition,
            width: flexItemsMainSizeList[flexItemIndex],
            height: flexItemsCrossSizeList[flexItemIndex]),
          mainAxisMargins: FlexRect.Margins(
            start: mainPositionAndMargins[flexItemIndex].marginStart,
            end: mainPositionAndMargins[flexItemIndex].marginEnd),
          crossAxisMargins: FlexRect.Margins(
            start: crossPositionAndMargins[flexItemIndex].marginStart,
            end: crossPositionAndMargins[flexItemIndex].marginEnd)
        )
      }
    }
    return flexRects
  }

  func flexBaseAndHypotheticalMainSizeForFlexItems(
    mainAxis: LogicalConstraints.AxisGeometry, flexItems: LogicalFlexItems
  ) -> FlexBaseAndHypotheticalMainSizeList {
    var flexBaseAndHypotheticalMainSizeList = FlexBaseAndHypotheticalMainSizeList()
    for flexItem in flexItems {
      let flexBaseSize = computedFlexBase(flexItem: flexItem, mainAxis: mainAxis)
      // The hypothetical main size is the item's flex base size clamped according to its used min and max main sizes (and flooring the content box size at zero).
      var hypotheticalMainSize = max(
        formattingUtils().usedMinimumMainSize(flexItem: flexItem), flexBaseSize)
      if let usedMaxiumMainSize = formattingUtils().usedMaxiumMainSize(flexItem: flexItem) {
        hypotheticalMainSize = min(usedMaxiumMainSize, hypotheticalMainSize)
      }
      flexBaseAndHypotheticalMainSizeList.append(
        FlexBaseAndHypotheticalMainSize(
          flexBase: flexBaseSize, hypotheticalMainSize: hypotheticalMainSize))
    }
    return flexBaseAndHypotheticalMainSizeList
  }

  func flexContainerMainSize(mainAxis: LogicalConstraints.AxisGeometry) -> LayoutUnit {
    // 4. Determine the main size of the flex container using the rules of the formatting context in which it participates.
    //    For this computation, auto margins on flex items are treated as 0.
    // FIXME: above.
    return availableMainSpace
  }

  func computeFlexLines(
    flexItems: LogicalFlexItems, flexContainerMainSize: LayoutUnit,
    flexBaseAndHypotheticalMainSizeList: FlexBaseAndHypotheticalMainSizeList
  ) -> LineRanges {
    // Collect flex items into flex lines:
    // If the flex container is single-line, collect all the flex items into a single flex line.
    // Otherwise, starting from the first uncollected item, collect consecutive items one by one until the first time that the next collected
    // item would not fit into the flex container's inner main size.
    // If the very first uncollected item wouldn't fit, collect just it into the line.
    // For this step, the size of a flex item is its outer hypothetical main size. (Note: This can be negative.)
    if isSingleLineFlexContainer() {
      return [0..<UInt64(flexBaseAndHypotheticalMainSizeList.count)]
    }

    var lineRanges = LineRanges()
    var lastWrapIndex: UInt64 = 0
    var flexItemsMainSize = LayoutUnit()
    for flexItemIndex in 0..<UInt64(flexBaseAndHypotheticalMainSizeList.count) {
      let flexItemHypotheticalOuterMainSize = outerMainSize(
        flexItem: flexItems[Int(flexItemIndex)],
        mainSize: flexBaseAndHypotheticalMainSizeList[Int(flexItemIndex)].hypotheticalMainSize)
      let isFlexLineEmpty = flexItemIndex == lastWrapIndex
      if isFlexLineEmpty
        || flexItemsMainSize + flexItemHypotheticalOuterMainSize <= flexContainerMainSize
      {
        flexItemsMainSize += flexItemHypotheticalOuterMainSize
        continue
      }
      lineRanges.append(lastWrapIndex..<flexItemIndex)
      flexItemsMainSize = flexItemHypotheticalOuterMainSize
      lastWrapIndex = flexItemIndex
    }
    lineRanges.append(lastWrapIndex..<UInt64(flexBaseAndHypotheticalMainSizeList.count))
    return lineRanges
  }

  func computeMainSizeForFlexItems(
    flexItems: LogicalFlexItems, lineRanges: LineRanges, flexContainerMainSize: LayoutUnit,
    flexBaseAndHypotheticalMainSizeList: FlexBaseAndHypotheticalMainSizeList
  ) -> SizeList {
    var mainSizeList = SizeList()
    var isInflexibleItemList = [Bool](repeating: false, count: flexItems.count)

    for lineRange in lineRanges {
      var nonFrozenSet: Set<UInt64> = []

      // 1. Determine the used flex factor. Sum the outer hypothetical main sizes of all items on the line.
      //    If the sum is less than the flex container's inner main size, use the flex grow factor for the rest of this algorithm;
      //    otherwise, use the flex shrink factor.
      let shouldUseFlexGrowFactor = shouldUseFlexGrowFactor(
        lineRange: lineRange, flexItems: flexItems,
        flexBaseAndHypotheticalMainSizeList: flexBaseAndHypotheticalMainSizeList,
        flexContainerMainSize: flexContainerMainSize)

      // 2. Size inflexible items. Freeze, setting its target main size to its hypothetical main size.
      //    any item that has a flex factor of zero
      //    if using the flex grow factor: any item that has a flex base size greater than its hypothetical main size
      //    if using the flex shrink factor: any item that has a flex base size smaller than its hypothetical main size
      for flexItemIndex in lineRange.lowerBound..<lineRange.upperBound {
        if shouldFreeze(
          flexItems: flexItems,
          flexBaseAndHypotheticalMainSizeList: flexBaseAndHypotheticalMainSizeList,
          flexItemIndex: Int(flexItemIndex), shouldUseFlexGrowFactor: shouldUseFlexGrowFactor)
        {
          mainSizeList[Int(flexItemIndex)] =
            flexBaseAndHypotheticalMainSizeList[Int(flexItemIndex)].hypotheticalMainSize
          isInflexibleItemList[Int(flexItemIndex)] = true
          continue
        }
        nonFrozenSet.update(with: flexItemIndex)
      }

      // 3. Calculate initial free space. Sum the outer sizes of all items on the line, and subtract this from the flex container's inner main size.
      //    For frozen items, use their outer target main size; for other items, use their outer flex base size.

      var minimumViolationList: [UInt64] = []
      var maximumViolationList: [UInt64] = []
      minimumViolationList.reserveCapacity(flexItems.count)
      maximumViolationList.reserveCapacity(flexItems.count)
      // 4. Loop:
      while true {
        // a. Check for flexible items. If all the flex items on the line are frozen, free space has been distributed; exit this loop.
        if nonFrozenSet.isEmpty {
          break
        }

        // b. Calculate the remaining free space as for initial free space, above. If the sum of the unfrozen flex items' flex factors
        //    is less than one, multiply the initial free space by this sum. If the magnitude of this value is less than the magnitude of the
        //    remaining free space, use this as the remaining free space.
        var freeSpace = computedFreeSpace(
          flexItems: flexItems, lineRange: lineRange, nonFrozenSet: nonFrozenSet,
          flexBaseAndHypotheticalMainSizeList: flexBaseAndHypotheticalMainSizeList,
          mainSizeList: mainSizeList, flexContainerMainSize: flexContainerMainSize)
        adjustFreeSpaceWithFlexFactors(
          flexItems: flexItems, nonFrozenSet: nonFrozenSet, freeSpace: &freeSpace)

        // c. Distribute free space proportional to the flex factors.
        var usedTotalFactor: Float32 = 0
        for nonFrozenIndexU64 in nonFrozenSet {
          let nonFrozenIndex = Int(nonFrozenIndexU64)
          usedTotalFactor +=
            shouldUseFlexGrowFactor
            ? flexItems[nonFrozenIndex].growFactor()
            : flexItems[nonFrozenIndex].shrinkFactor()
              * flexBaseAndHypotheticalMainSizeList[nonFrozenIndex].flexBase.float()
        }

        for nonFrozenIndexU64 in nonFrozenSet {
          let nonFrozenIndex = Int(nonFrozenIndexU64)
          if usedTotalFactor == 0 || usedTotalFactor.isInfinite {
            mainSizeList[nonFrozenIndex] =
              flexBaseAndHypotheticalMainSizeList[nonFrozenIndex].flexBase
            continue
          }
          if shouldUseFlexGrowFactor {
            // If using the flex grow factor
            // Find the ratio of the item's flex grow factor to the sum of the flex grow factors of all unfrozen items on the line.
            // Set the item's target main size to its flex base size plus a fraction of the remaining free space proportional to the ratio.
            let growFactor = flexItems[nonFrozenIndex].growFactor() / usedTotalFactor
            mainSizeList[nonFrozenIndex] =
              LayoutUnit(
                value: flexBaseAndHypotheticalMainSizeList[nonFrozenIndex].flexBase + freeSpace
                  * growFactor)
            continue
          }
          // If using the flex shrink factor
          // For every unfrozen item on the line, multiply its flex shrink factor by its inner flex base size, and note this as its scaled flex shrink factor.
          // Find the ratio of the item's scaled flex shrink factor to the sum of the scaled flex shrink factors of all unfrozen items on the line.
          // Set the item's target main size to its flex base size minus a fraction of the absolute value of the remaining free space proportional to the ratio.
          // Note this may result in a negative inner main size; it will be corrected in the next step.
          let flexBaseSize = flexBaseAndHypotheticalMainSizeList[nonFrozenIndex].flexBase
          let scaledShrinkFactor = flexItems[nonFrozenIndex].shrinkFactor() * flexBaseSize
          let shrinkFactor = scaledShrinkFactor / usedTotalFactor
          mainSizeList[nonFrozenIndex] = LayoutUnit(
            value: flexBaseSize - abs(freeSpace * shrinkFactor))
        }

        // d. Fix min/max violations. Clamp each non-frozen item's target main size by its used min and max main sizes and floor
        //    its content-box size at zero. If the item's target main size was made smaller by this, it's a max violation.
        //    If the item's target main size was made larger by this, it's a min violation.
        var totalViolation = LayoutUnit()
        minimumViolationList.removeAll()
        maximumViolationList.removeAll()
        for nonFrozenIndexU64 in nonFrozenSet {
          let nonFrozenIndex = Int(nonFrozenIndexU64)
          let unclampedMainSize = mainSizeList[nonFrozenIndex]
          let flexItem = flexItems[nonFrozenIndex]
          var clampedMainSize = max(
            formattingUtils().usedMinimumMainSize(flexItem: flexItem), unclampedMainSize)
          if let usedMaxiumMainSize = formattingUtils().usedMaxiumMainSize(flexItem: flexItem) {
            clampedMainSize = min(usedMaxiumMainSize, clampedMainSize)
          }
          // FIXME: ...and floor its content-box size at zero
          totalViolation += (clampedMainSize - unclampedMainSize)
          if clampedMainSize < unclampedMainSize {
            maximumViolationList.append(nonFrozenIndexU64)
          } else if clampedMainSize > unclampedMainSize {
            minimumViolationList.append(nonFrozenIndexU64)
          }
          mainSizeList[nonFrozenIndex] = clampedMainSize
        }

        // e. Freeze over-flexed items. The total violation is the sum of the adjustments from the previous step
        //    ∑(clamped size - unclamped size). If the total violation is:
        //      Zero : Freeze all items.
        //      Positive: Freeze all the items with min violations.
        //      Negative: Freeze all the items with max violations.
        if !totalViolation.bool() {
          nonFrozenSet.removeAll()
        } else if totalViolation > 0 {
          for minimimViolationIndex in minimumViolationList {
            nonFrozenSet.remove(minimimViolationIndex)
          }
        } else {
          for maximumViolationIndex in maximumViolationList {
            nonFrozenSet.remove(maximumViolationIndex)
          }
        }
      }
    }
    return mainSizeList
  }

  func shouldUseFlexGrowFactor(
    lineRange: Range<UInt64>, flexItems: LogicalFlexItems,
    flexBaseAndHypotheticalMainSizeList: FlexBaseAndHypotheticalMainSizeList,
    flexContainerMainSize: LayoutUnit
  ) -> Bool {
    var hypotheticalOuterMainSizes = LayoutUnit()
    for flexItemIndex in lineRange.lowerBound..<lineRange.upperBound {
      let flexItemHypotheticalOuterMainSize = outerMainSize(
        flexItem: flexItems[Int(flexItemIndex)],
        mainSize: flexBaseAndHypotheticalMainSizeList[Int(flexItemIndex)].hypotheticalMainSize)
      hypotheticalOuterMainSizes += flexItemHypotheticalOuterMainSize
    }
    return hypotheticalOuterMainSizes < flexContainerMainSize
  }

  func shouldFreeze(
    flexItems: LogicalFlexItems,
    flexBaseAndHypotheticalMainSizeList: FlexBaseAndHypotheticalMainSizeList, flexItemIndex: Int,
    shouldUseFlexGrowFactor: Bool
  ) -> Bool {
    if flexItems[flexItemIndex].growFactor() == 0 && flexItems[flexItemIndex].shrinkFactor() == 0 {
      return true
    }
    let flexBaseAndHypotheticalMainSize = flexBaseAndHypotheticalMainSizeList[flexItemIndex]
    if shouldUseFlexGrowFactor
      && flexBaseAndHypotheticalMainSize.flexBase
        > flexBaseAndHypotheticalMainSize.hypotheticalMainSize
    {
      return true
    }
    if !shouldUseFlexGrowFactor
      && flexBaseAndHypotheticalMainSize.flexBase
        < flexBaseAndHypotheticalMainSize.hypotheticalMainSize
    {
      return true
    }
    return false
  }

  func computedFreeSpace(
    flexItems: LogicalFlexItems, lineRange: Range<UInt64>, nonFrozenSet: Set<UInt64>,
    flexBaseAndHypotheticalMainSizeList: FlexBaseAndHypotheticalMainSizeList,
    mainSizeList: SizeList,
    flexContainerMainSize: LayoutUnit
  ) -> LayoutUnit {
    var lineContentMainSize = LayoutUnit()
    for flexItemIndex in lineRange.lowerBound..<lineRange.upperBound {
      let flexItemOuterMainSize = outerMainSize(
        flexItem: flexItems[Int(flexItemIndex)],
        mainSize: nonFrozenSet.contains(flexItemIndex)
          ? flexBaseAndHypotheticalMainSizeList[Int(flexItemIndex)].flexBase
          : mainSizeList[Int(flexItemIndex)])
      lineContentMainSize += flexItemOuterMainSize
    }
    return flexContainerMainSize - lineContentMainSize
  }

  func adjustFreeSpaceWithFlexFactors(
    flexItems: LogicalFlexItems, nonFrozenSet: Set<UInt64>, freeSpace: inout LayoutUnit
  ) {
    var totalFlexFactor: Float32 = 0
    for nonFrozenIndexU64 in nonFrozenSet {
      let nonFrozenIndex = Int(nonFrozenIndexU64)
      totalFlexFactor +=
        flexItems[nonFrozenIndex].growFactor() + flexItems[nonFrozenIndex].shrinkFactor()
    }
    if totalFlexFactor < 1 {
      freeSpace *= totalFlexFactor
    }
  }

  func hypotheticalCrossSizeForFlexItems(
    flexItems: LogicalFlexItems, flexItemsMainSizeList: SizeList
  ) -> SizeList {
    var hypotheticalCrossSizeList = [LayoutUnit](repeating: LayoutUnit(), count: flexItems.count)
    for (flexItemIndexU64, flexItem) in flexItems.enumerated() {
      let flexItemIndex = Int(flexItemIndexU64)

      if let definiteSize = flexItems[flexItemIndex].crossAxis().definiteSize {
        hypotheticalCrossSizeList[flexItemIndex] = definiteSize
        continue
      }
      let flexItemBox = flexItem.layoutBox!
      var usedCrossSize = crossContentSizeAfterPerformingLayout(
        flexItemsMainSizeList: flexItemsMainSizeList, flexItemBox: flexItemBox,
        flexItemIndex: flexItemIndex)
      if !flexItem.isContentBoxBased() {
        usedCrossSize += flexItem.crossAxis().borderAndPadding
      }
      hypotheticalCrossSizeList[flexItemIndex] = usedCrossSize
    }
    return hypotheticalCrossSizeList
  }

  func crossContentSizeAfterPerformingLayout(
    flexItemsMainSizeList: SizeList, flexItemBox: BoxWrapper, flexItemIndex: Int
  ) -> LayoutUnit {
    formattingContext().integrationUtils!.layoutWithFormattingContextForBox(
      box: flexItemBox as! ElementBoxWrapper, widthConstraint: flexItemsMainSizeList[flexItemIndex])
    return formattingContext().geometryForFlexItem(flexItem: flexItemBox).contentBoxHeight()
  }

  func crossSizeForFlexLines(
    lineRanges: LineRanges, crossAxis: LogicalConstraints.AxisGeometry, flexItems: LogicalFlexItems,
    flexItemsHypotheticalCrossSizeList: SizeList
  ) -> LinesCrossSizeList {
    var flexLinesCrossSizeList = LinesCrossSizeList(
      repeating: LayoutUnit(), count: lineRanges.count)
    // If the flex container is single-line and has a definite cross size, the cross size of the flex line is the flex container's inner cross size.
    if isSingleLineFlexContainer() && crossAxis.definiteSize != nil {
      assert(flexLinesCrossSizeList.count == 1)
      flexLinesCrossSizeList[0] = crossAxis.definiteSize!
      return flexLinesCrossSizeList
    }

    for (lineIndex, lineRange) in lineRanges.enumerated() {
      var maximumAscent = LayoutUnit()
      var maximumDescent = LayoutUnit()
      var maximumHypotheticalOuterCrossSize = LayoutUnit()
      for flexItemIndex in lineRange {
        // Collect all the flex items whose inline-axis is parallel to the main-axis, whose align-self is baseline, and whose cross-axis margins are both non-auto.
        let flexItem = flexItems[Int(flexItemIndex)]
        if !flexItem.isOrhogonal && flexItem.style().alignSelf().position == .Baseline
          && flexItem.crossAxis().hasNonAutoMargins()
        {
          // Find the largest of the distances between each item's baseline and its hypothetical outer cross-start edge,
          // and the largest of the distances between each item's baseline and its hypothetical outer cross-end edge, and sum these two values.
          maximumAscent = max(maximumAscent, flexItem.crossAxis().ascent)
          maximumDescent = max(maximumDescent, flexItem.crossAxis().descent)
          continue
        }
        // Among all the items not collected by the previous step, find the largest outer hypothetical cross size.
        let flexItemOuterCrossSize = outerCrossSize(
          flexItem: flexItem, crossSize: flexItemsHypotheticalCrossSizeList[Int(flexItemIndex)])
        maximumHypotheticalOuterCrossSize = max(
          maximumHypotheticalOuterCrossSize, flexItemOuterCrossSize)
      }
      // The used cross-size of the flex line is the largest of the numbers found in the previous two steps and zero.
      // If the flex container is single-line, then clamp the line's cross-size to be within the container's computed min and max cross sizes.
      flexLinesCrossSizeList[lineIndex] = max(
        maximumHypotheticalOuterCrossSize, maximumAscent + maximumDescent)
      if isSingleLineFlexContainer() {
        let minimumCrossSize = crossAxis.minimumSize ?? flexLinesCrossSizeList[lineIndex]
        let maximumCrossSize = crossAxis.maximumSize ?? flexLinesCrossSizeList[lineIndex]
        flexLinesCrossSizeList[lineIndex] = min(
          maximumCrossSize, max(minimumCrossSize, flexLinesCrossSizeList[lineIndex]))
      }
    }
    return flexLinesCrossSizeList
  }

  func stretchFlexLines(
    flexLinesCrossSizeList: inout LinesCrossSizeList, numberOfLines: UInt64,
    crossAxis: LogicalConstraints.AxisGeometry
  ) {
    // Handle 'align-content: stretch'.
    // If the flex container has a definite cross size, align-content is stretch, and the sum of the flex lines' cross sizes is less than the flex container's inner cross size,
    // increase the cross size of each flex line by equal amounts such that the sum of their cross sizes exactly equals the flex container's inner cross size.
    if !linesMayStretch() || crossAxis.definiteSize == nil {
      return
    }

    let linesCrossSize = FlexLayout.linesCrossSize(flexLinesCrossSizeList: flexLinesCrossSizeList)
    if crossAxis.definiteSize! <= linesCrossSize {
      return
    }

    let extraSpace = (crossAxis.definiteSize! - linesCrossSize) / numberOfLines
    for lineIndex in 0..<flexLinesCrossSizeList.count {
      flexLinesCrossSizeList[lineIndex] += extraSpace
    }
  }

  func linesMayStretch() -> Bool {
    let alignContent = flexContainerStyle().alignContent()
    if alignContent.distribution == .Stretch {
      return true
    }
    return alignContent.distribution == .Default && alignContent.position == .Normal
  }

  static func linesCrossSize(flexLinesCrossSizeList: LinesCrossSizeList) -> LayoutUnit {
    var size = LayoutUnit()
    for flexLinesCrossSize in flexLinesCrossSizeList {
      size += flexLinesCrossSize
    }
    return size
  }

  func collapseNonVisibleFlexItems() -> Bool {
    // Collapse visibility:collapse items. If any flex items have visibility: collapse,
    // note the cross size of the line they're in as the item's strut size, and restart layout from the beginning.
    // FIXME: Not supported yet.
    return false
  }

  func computeCrossSizeForFlexItems(
    flexItems: LogicalFlexItems, lineRanges: LineRanges, flexLinesCrossSizeList: LinesCrossSizeList,
    flexItemsHypotheticalCrossSizeList: SizeList
  ) -> SizeList {
    var crossSizeList = SizeList(repeating: LayoutUnit(), count: flexItems.count)
    for (lineIndex, lineRange) in lineRanges.enumerated() {
      for flexItemIndexU64 in lineRange {
        let flexItemIndex = Int(flexItemIndexU64)
        let flexItem = flexItems[flexItemIndex]
        let crossAxis = flexItem.crossAxis()
        let flexItemAlignSelf = flexItem.style().alignSelf()
        let alignValue =
          flexItemAlignSelf.position != .Auto
          ? flexItemAlignSelf.position : flexContainerStyle().alignItems().position
        // If a flex item has align-self: stretch, its computed cross size property is auto, and neither of its cross-axis margins are auto, the used outer cross size is the used cross size of its flex line,
        // clamped according to the item's used min and max cross sizes. Otherwise, the used cross size is the item's hypothetical cross size.
        if (alignValue == .Stretch || alignValue == .Normal) && crossAxis.hasSizeAuto
          && crossAxis.hasNonAutoMargins()
        {
          crossSizeList[flexItemIndex] = stretchedInnerCrossSize(
            flexItem: flexItem,
            flexLinesCrossSizeList: flexLinesCrossSizeList,
            lineIndex: lineIndex)
          // FIXME: This requires re-layout to get percentage-sized descendants updated.
        } else {
          crossSizeList[flexItemIndex] = flexItemsHypotheticalCrossSizeList[flexItemIndex]
        }
      }
    }
    return crossSizeList
  }

  func stretchedInnerCrossSize(
    flexItem: LogicalFlexItem,
    flexLinesCrossSizeList: LinesCrossSizeList, lineIndex: Int
  ) -> LayoutUnit {
    var stretchedInnerCrossSize =
      flexLinesCrossSizeList[lineIndex] - flexItem.crossAxis().margin()
    if flexItem.isContentBoxBased() {
      stretchedInnerCrossSize -= flexItem.crossAxis().borderAndPadding
    }
    let maximum = flexItem.crossAxis().maximumSize ?? stretchedInnerCrossSize
    let minimum = flexItem.crossAxis().minimumSize ?? stretchedInnerCrossSize
    return min(maximum, max(minimum, stretchedInnerCrossSize))
  }

  func handleMainAxisAlignment(
    availableMainSpace: LayoutUnit, lineRanges: LineRanges, flexItems: LogicalFlexItems,
    flexItemsMainSizeList: SizeList
  ) -> PositionAndMarginsList {
    // Distribute any remaining free space. For each flex line:
    var mainPositionAndMargins = PositionAndMarginsList(
      repeating: PositionAndMargins(), count: flexItems.count)

    for lineRange in lineRanges {
      var lineContentOuterMainSize = LayoutUnit()

      resolveMarginAutoMainAxis(
        flexItems: flexItems, lineRange: lineRange, flexItemsMainSizeList: flexItemsMainSizeList,
        mainPositionAndMargins: &mainPositionAndMargins,
        lineContentOuterMainSize: &lineContentOuterMainSize)

      var justifyContentValue = flexContainerStyle().justifyContent().distribution
      var positionalAlignmentValue = flexContainerStyle().justifyContent().position

      setFallbackValuesIfApplicableMainAxis(
        lineRange: lineRange, lineContentOuterMainSize: lineContentOuterMainSize,
        availableMainSpace: availableMainSpace, justifyContentValue: &justifyContentValue,
        positionalAlignmentValue: &positionalAlignmentValue)

      justifyContent(
        flexItems: flexItems, justifyContentValue: justifyContentValue,
        positionalAlignmentValue: positionalAlignmentValue, availableMainSpace: availableMainSpace,
        lineContentOuterMainSize: lineContentOuterMainSize, lineRange: lineRange,
        flexItemsMainSizeList: flexItemsMainSizeList,
        mainPositionAndMargins: &mainPositionAndMargins)
    }
    return mainPositionAndMargins
  }

  func resolveMarginAutoMainAxis(
    flexItems: LogicalFlexItems, lineRange: Range<UInt64>, flexItemsMainSizeList: SizeList,
    mainPositionAndMargins: inout PositionAndMarginsList, lineContentOuterMainSize: inout LayoutUnit
  ) {
    // 1. If the remaining free space is positive and at least one main-axis margin on this line is auto, distribute the free space equally among these margins.
    //    Otherwise, set all auto margins to zero.
    var flexItemsWithMarginAuto: [UInt64] = []
    var autoMarginCount: UInt64 = 0

    for flexItemIndexU64 in lineRange {
      let flexItemIndex = Int(flexItemIndexU64)
      let flexItem = flexItems[flexItemIndex]
      let marginStart = flexItem.mainAxis().marginStart
      let marginEnd = flexItem.mainAxis().marginEnd

      if marginStart == nil || marginEnd == nil {
        flexItemsWithMarginAuto.append(flexItemIndexU64)
        if marginStart == nil {
          autoMarginCount += 1
        }
        if marginEnd == nil {
          autoMarginCount += 1
        }
      }
      mainPositionAndMargins[flexItemIndex].marginStart = marginStart ?? LayoutUnit(value: 0)
      mainPositionAndMargins[flexItemIndex].marginEnd = marginEnd ?? LayoutUnit(value: 0)
      lineContentOuterMainSize += outerMainSize(
        flexItem: flexItem, mainSize: flexItemsMainSizeList[flexItemIndex],
        usedMargin: mainPositionAndMargins[flexItemIndex].margin())
    }

    let spaceToDistrubute = availableMainSpace - lineContentOuterMainSize
    if autoMarginCount == 0 || spaceToDistrubute <= Int32(0) {
      return
    }

    lineContentOuterMainSize = availableMainSpace
    let extraMarginSpace = spaceToDistrubute / autoMarginCount

    for flexItemIndexU64 in flexItemsWithMarginAuto {
      let flexItemIndex = Int(flexItemIndexU64)
      let flexItem = flexItems[flexItemIndex]

      if flexItem.mainAxis().marginStart == nil {
        mainPositionAndMargins[flexItemIndex].marginStart = extraMarginSpace
      }
      if flexItem.mainAxis().marginEnd == nil {
        mainPositionAndMargins[flexItemIndex].marginEnd = extraMarginSpace
      }
    }
  }

  func setFallbackValuesIfApplicableMainAxis(
    lineRange: Range<UInt64>, lineContentOuterMainSize: LayoutUnit, availableMainSpace: LayoutUnit,
    justifyContentValue: inout ContentDistribution, positionalAlignmentValue: inout ContentPosition
  ) {
    let itemCount = lineRange.upperBound - lineRange.lowerBound
    let hasOverflow = lineContentOuterMainSize > availableMainSpace
    if !hasOverflow && itemCount > 1 {
      return
    }
    switch justifyContentValue {
    case .SpaceBetween:
      positionalAlignmentValue = hasOverflow ? .Start : .FlexStart
    case .SpaceEvenly, .SpaceAround:
      positionalAlignmentValue = hasOverflow ? .Start : .Center
    default:
      break
    }
    justifyContentValue = .Default
  }

  func justifyContent(
    flexItems: LogicalFlexItems, justifyContentValue: ContentDistribution,
    positionalAlignmentValue: ContentPosition,
    availableMainSpace: LayoutUnit, lineContentOuterMainSize: LayoutUnit, lineRange: Range<UInt64>,
    flexItemsMainSizeList: SizeList, mainPositionAndMargins: inout PositionAndMarginsList
  ) {
    // 2. Align the items along the main-axis per justify-content.
    let startIndex = Int(lineRange.lowerBound)
    mainPositionAndMargins[startIndex].position =
      initialOffsetMainAxis(
        justifyContentValue: justifyContentValue,
        positionalAlignmentValue: positionalAlignmentValue, availableMainSpace: availableMainSpace,
        lineContentOuterMainSize: lineContentOuterMainSize, lineRange: lineRange)
      + mainPositionAndMargins[startIndex].marginStart
    var previousFlexItemOuterEnd = flexItemOuterEnd(
      flexItemIndex: startIndex, flexItems: flexItems, flexItemsMainSizeList: flexItemsMainSizeList,
      mainPositionAndMargins: mainPositionAndMargins)
    let gap = gapBetweenItems(
      justifyContentValue: justifyContentValue, availableMainSpace: availableMainSpace,
      lineContentOuterMainSize: lineContentOuterMainSize, lineRange: lineRange)
    for index in (startIndex + 1)..<Int(lineRange.upperBound) {
      mainPositionAndMargins[index].position =
        previousFlexItemOuterEnd + gap + mainPositionAndMargins[index].marginStart
      previousFlexItemOuterEnd = flexItemOuterEnd(
        flexItemIndex: index, flexItems: flexItems, flexItemsMainSizeList: flexItemsMainSizeList,
        mainPositionAndMargins: mainPositionAndMargins)
    }
  }

  func initialOffsetMainAxis(
    justifyContentValue: ContentDistribution, positionalAlignmentValue: ContentPosition,
    availableMainSpace: LayoutUnit, lineContentOuterMainSize: LayoutUnit, lineRange: Range<UInt64>
  ) -> LayoutUnit {
    // ContentDistribution::Default handles fallback to justifyContentValue.position()
    if justifyContentValue != .Default {
      switch justifyContentValue {
      case .SpaceBetween:
        return LayoutUnit()
      case .SpaceAround:
        return (availableMainSpace - lineContentOuterMainSize)
          / (lineRange.upperBound - lineRange.lowerBound) / 2
      case .SpaceEvenly:
        return (availableMainSpace - lineContentOuterMainSize)
          / (lineRange.upperBound - lineRange.lowerBound + 1)
      default:
        fatalError("Not implemented yet")
      }
    }

    switch positionalAlignmentValue {
    // logical alignments
    case .Normal, .FlexStart:
      return LayoutUnit()
    case .FlexEnd:
      return availableMainSpace - lineContentOuterMainSize
    case .Center:
      return availableMainSpace / 2 - lineContentOuterMainSize / 2
    // non-logical alignments
    case .Left, .Start:
      if FlexFormattingUtils.isReversedToContentDirection(flexBox: flexContainer()) {
        return availableMainSpace - lineContentOuterMainSize
      }
      return LayoutUnit()
    case .Right, .End:
      if FlexFormattingUtils.isReversedToContentDirection(flexBox: flexContainer()) {
        return LayoutUnit()
      }
      return availableMainSpace - lineContentOuterMainSize
    default:
      fatalError("Not implemented yet")
    }
  }

  func gapBetweenItems(
    justifyContentValue: ContentDistribution, availableMainSpace: LayoutUnit,
    lineContentOuterMainSize: LayoutUnit, lineRange: Range<UInt64>
  ) -> LayoutUnit {
    switch justifyContentValue {
    case .Default:
      return LayoutUnit()
    case .SpaceBetween:
      return max(LayoutUnit(value: 0), availableMainSpace - lineContentOuterMainSize)
        / (lineRange.upperBound - lineRange.lowerBound - 1)
    case .SpaceAround:
      return max(LayoutUnit(value: 0), availableMainSpace - lineContentOuterMainSize)
        / (lineRange.upperBound - lineRange.lowerBound)
    case .SpaceEvenly:
      return max(LayoutUnit(value: 0), availableMainSpace - lineContentOuterMainSize)
        / (lineRange.upperBound - lineRange.lowerBound + 1)
    default:
      fatalError("Not implemented yet")
    }
  }

  func flexItemOuterEnd(
    flexItemIndex: Int, flexItems: LogicalFlexItems, flexItemsMainSizeList: SizeList,
    mainPositionAndMargins: PositionAndMarginsList
  ) -> LayoutUnit {
    let flexIteOuterMainSize = outerMainSize(
      flexItem: flexItems[flexItemIndex], mainSize: flexItemsMainSizeList[flexItemIndex],
      usedMargin: mainPositionAndMargins[flexItemIndex].margin())
    // Note that position here means border box position.
    let flexItemEnd = flexIteOuterMainSize - mainPositionAndMargins[flexItemIndex].marginStart
    return mainPositionAndMargins[flexItemIndex].position + flexItemEnd
  }

  func handleCrossAxisAlignmentForFlexItems(
    flexItems: LogicalFlexItems, lineRanges: LineRanges, flexItemsCrossSizeList: SizeList,
    flexLinesCrossSizeList: LinesCrossSizeList
  ) -> PositionAndMarginsList {
    var crossPositionAndMargins = PositionAndMarginsList(
      repeating: PositionAndMargins(), count: flexItems.count)

    for (lineIndex, lineRange) in lineRanges.enumerated() {
      resolveMarginAutoCrossAxis(
        flexItems: flexItems, lineRange: lineRange,
        flexItemsCrossSizeList: flexItemsCrossSizeList,
        flexLinesCrossSizeList: flexLinesCrossSizeList, lineIndex: lineIndex,
        crossPositionAndMargins: &crossPositionAndMargins)

      alignSelfCrossAxis(
        flexItems: flexItems, lineRange: lineRange,
        flexItemsCrossSizeList: flexItemsCrossSizeList,
        flexLinesCrossSizeList: flexLinesCrossSizeList,
        crossPositionAndMargins: &crossPositionAndMargins, lineIndex: lineIndex)
    }
    return crossPositionAndMargins
  }

  func resolveMarginAutoCrossAxis(
    flexItems: LogicalFlexItems, lineRange: Range<UInt64>, flexItemsCrossSizeList: SizeList,
    flexLinesCrossSizeList: LinesCrossSizeList, lineIndex: Int,
    crossPositionAndMargins: inout PositionAndMarginsList
  ) {
    for flexItemIndexU64 in lineRange {
      let flexItemIndex = Int(flexItemIndexU64)
      let flexItem = flexItems[flexItemIndex]
      var marginStart = flexItem.crossAxis().marginStart
      var marginEnd = flexItem.crossAxis().marginEnd

      // Resolve cross-axis auto margins. If a flex item has auto cross-axis margins:
      if marginStart == nil || marginEnd == nil {
        let flexItemOuterCrossSize = outerCrossSize(
          flexItem: flexItem, crossSize: flexItemsCrossSizeList[flexItemIndex])
        let extraCrossSpace = flexLinesCrossSizeList[lineIndex] - flexItemOuterCrossSize
        // If its outer cross size (treating those auto margins as zero) is less than the cross size of its flex line, distribute
        // the difference in those sizes equally to the auto margins.
        // Otherwise, if the block-start or inline-start margin (whichever is in the cross axis) is auto, set it to zero.
        // Set the opposite margin so that the outer cross size of the item equals the cross size of its flex line.
        if extraCrossSpace > 0 {
          if marginStart == nil && marginEnd == nil {
            marginStart = extraCrossSpace / 2
            marginEnd = extraCrossSpace / 2
          } else if marginStart == nil {
            marginStart = extraCrossSpace
          } else {
            marginEnd = extraCrossSpace
          }
        } else {
          let marginCrossSpace =
            flexLinesCrossSizeList[lineIndex] - flexItemsCrossSizeList[flexItemIndex]
          if marginStart != nil {
            marginStart = marginCrossSpace
            marginEnd = LayoutUnit(value: 0)
          } else {
            marginStart = LayoutUnit(value: 0)
            marginEnd = marginCrossSpace
          }
        }
      }
      crossPositionAndMargins[flexItemIndex].marginStart = marginStart!
      crossPositionAndMargins[flexItemIndex].marginEnd = marginEnd!
    }
  }

  func alignSelfCrossAxis(
    flexItems: LogicalFlexItems, lineRange: Range<UInt64>, flexItemsCrossSizeList: SizeList,
    flexLinesCrossSizeList: LinesCrossSizeList,
    crossPositionAndMargins: inout PositionAndMarginsList,
    lineIndex: Int
  ) {
    // Align all flex items along the cross-axis per align-self, if neither of the item's cross-axis margins are auto.
    for flexItemIndexU64 in lineRange {
      let flexItemIndex = Int(flexItemIndexU64)
      let flexItem = flexItems[flexItemIndex]
      let flexItemOuterCrossSize = outerCrossSize(
        flexItem: flexItem, crossSize: flexItemsCrossSizeList[flexItemIndex],
        usedMargin: crossPositionAndMargins[flexItemIndex].margin())
      var flexItemOuterCrossPosition = LayoutUnit()

      let flexItemAlignSelf = flexItem.style().alignSelf()
      var alignValue =
        flexItemAlignSelf.position != .Auto
        ? flexItemAlignSelf : flexContainerStyle().alignItems()
      setFallbackValuesIfApplicableCrossAxis(
        flexItemOuterCrossSize: flexItemOuterCrossSize,
        flexLinesCrossSizeList: flexLinesCrossSizeList, lineIndex: lineIndex,
        flexItemAlignSelf: flexItemAlignSelf, alignValue: &alignValue)

      switch alignValue.position {
      case .Stretch, .Normal:
        // This is taken care of at 9.4.11 see computeCrossSizeForFlexItems.
        flexItemOuterCrossPosition = LayoutUnit()
      case .Center:
        flexItemOuterCrossPosition =
          flexLinesCrossSizeList[lineIndex] / 2 - flexItemOuterCrossSize / 2
      case .Start, .FlexStart:
        flexItemOuterCrossPosition = LayoutUnit()
      case .End, .FlexEnd:
        flexItemOuterCrossPosition = flexLinesCrossSizeList[lineIndex] - flexItemOuterCrossSize
      default:
        fatalError("Not implemented yet")
      }
      crossPositionAndMargins[flexItemIndex].position =
        flexItemOuterCrossPosition + crossPositionAndMargins[flexItemIndex].marginStart
    }
  }

  func setFallbackValuesIfApplicableCrossAxis(
    flexItemOuterCrossSize: LayoutUnit, flexLinesCrossSizeList: LinesCrossSizeList, lineIndex: Int,
    flexItemAlignSelf: StyleSelfAlignmentData, alignValue: inout StyleSelfAlignmentData
  ) {
    if flexItemOuterCrossSize <= flexLinesCrossSizeList[lineIndex]
      || flexItemAlignSelf.overflow != .Safe
    {
      return
    }
    alignValue.setPosition(position: .FlexStart)
  }

  func handleCrossAxisAlignmentForFlexLines(
    crossAxis: LogicalConstraints.AxisGeometry, lineRanges: LineRanges,
    flexLinesCrossSizeList: inout LinesCrossSizeList
  ) -> LinesCrossPositionList {
    // If the cross size property is a definite size, use that, clamped by the used min and max cross sizes of the flex container.
    // Otherwise, use the sum of the flex lines' cross sizes, clamped by the used min and max cross sizes of the flex container.
    if isSingleLineFlexContainer() {
      return [LayoutUnit()]
    }

    var flexLinesCrossSize = LayoutUnit()
    for crossSize in flexLinesCrossSizeList {
      flexLinesCrossSize += crossSize
    }
    let flexContainerUsedCrossSize = crossAxis.definiteSize ?? flexLinesCrossSize
    // Align all flex lines per align-content.
    let gap = gapCrossAxis(
      flexContainerUsedCrossSize: flexContainerUsedCrossSize,
      flexLinesCrossSize: flexLinesCrossSize,
      lineRanges: lineRanges, flexLinesCrossSizeList: &flexLinesCrossSizeList)

    var linesCrossPositionList = LinesCrossPositionList(
      repeating: LayoutUnit(), count: lineRanges.count)
    linesCrossPositionList[0] = initialOffsetCrossAxis(
      flexContainerUsedCrossSize: flexContainerUsedCrossSize,
      flexLinesCrossSize: flexLinesCrossSize, lineRanges: lineRanges)
    for lineIndex in 1..<lineRanges.count {
      linesCrossPositionList[lineIndex] =
        (linesCrossPositionList[lineIndex - 1] + flexLinesCrossSizeList[lineIndex - 1]) + gap
    }
    return linesCrossPositionList
  }

  func initialOffsetCrossAxis(
    flexContainerUsedCrossSize: LayoutUnit, flexLinesCrossSize: LayoutUnit, lineRanges: LineRanges
  ) -> LayoutUnit {
    switch flexContainerStyle().alignContent().position {
    case .Start, .Normal:
      return LayoutUnit()
    case .Center:
      return flexContainerUsedCrossSize / 2 - flexLinesCrossSize / 2
    case .End:
      return flexContainerUsedCrossSize - flexLinesCrossSize
    default:
      switch flexContainerStyle().alignContent().distribution {
      case .SpaceBetween, .Stretch:
        return LayoutUnit()
      case .SpaceAround:
        let extraCrossSpace = flexContainerUsedCrossSize - flexLinesCrossSize
        if extraCrossSpace <= Int32(0) {
          return LayoutUnit()
        }
        return extraCrossSpace / lineRanges.count / 2
      default:
        fatalError("Not reached")
      }
    }
  }

  func gapCrossAxis(
    flexContainerUsedCrossSize: LayoutUnit, flexLinesCrossSize: LayoutUnit, lineRanges: LineRanges,
    flexLinesCrossSizeList: inout LinesCrossSizeList
  )
    -> LayoutUnit
  {
    let extraCrossSpace = flexContainerUsedCrossSize - flexLinesCrossSize
    if extraCrossSpace <= Int32(0) {
      return LayoutUnit()
    }
    switch flexContainerStyle().alignContent().distribution {
    case .SpaceBetween:
      return extraCrossSpace / (lineRanges.count - 1)
    case .SpaceAround:
      return extraCrossSpace / lineRanges.count
    case .Stretch, .Default:
      // Lines stretch to take up the remaining space. If the leftover free-space is negative,
      // this value is identical to flex-start. Otherwise, the free-space is split equally between all of the lines,
      // increasing their cross size.
      let extraCrossSpaceForEachLine = extraCrossSpace / flexLinesCrossSizeList.count
      for lineIndex in 0..<flexLinesCrossSizeList.count {
        flexLinesCrossSizeList[lineIndex] += extraCrossSpaceForEachLine
      }
      return LayoutUnit()
    default:
      return LayoutUnit()
    }
  }

  func isSingleLineFlexContainer() -> Bool { return flexContainer().style.flexWrap() == .NoWrap }

  // 3. Determine the flex base size and hypothetical main size of each item:
  func computedFlexBase(flexItem: LogicalFlexItem, mainAxis: LogicalConstraints.AxisGeometry)
    -> LayoutUnit
  {
    // A. If the item has a definite used flex basis, that's the flex base size.
    if let definiteFlexBase = flexItem.mainAxis().definiteFlexBasis {
      return definiteFlexBase
    }
    // B. If the flex item has...
    if flexItem.hasAspectRatio && flexItem.hasContentFlexBasis()
      && flexItem.crossAxis().definiteSize != nil
    {
      // The flex base size is calculated from its inner cross size and the flex item's intrinsic aspect ratio.
      fatalError("Not implemented yet")
    }
    // C. If the used flex basis is content or depends on its available space, and the flex container is being sized under
    //    a min-content or max-content constraint, size the item under that constraint
    let flexBasisContentOrAvailableSpaceDependent =
      flexItem.hasContentFlexBasis() || flexItem.hasAvailableSpaceDependentFlexBasis()
    let flexContainerHasMinMaxConstraints =
      mainAxis.minimumContentSize != nil || mainAxis.maximumContentSize != nil
    if flexBasisContentOrAvailableSpaceDependent && flexContainerHasMinMaxConstraints {
      // Compute flex item's main size.
      fatalError("Not implemented yet")
    }
    // D. If the used flex basis is content or depends on its available space, the available main size is infinite,
    //    and the flex item's inline axis is parallel to the main axis, lay the item out using the rules for a box in an orthogonal flow.
    //    The flex base size is the item's max-content main size.
    if flexBasisContentOrAvailableSpaceDependent && flexItem.isOrhogonal {
      // Lay the item out using the rules for a box in an orthogonal flow. The flex base size is the item's max-content main size.
      fatalError("Not implemented yet")
    }
    // E. Otherwise, size the item into the available space using its used flex basis in place of its main size, treating a value of content as max-content.
    var usedMainContentSize = maxContentForFlexItem(flexItem: flexItem)
    if !flexItem.isContentBoxBased() {
      usedMainContentSize += flexItem.mainAxis().borderAndPadding
    }
    return usedMainContentSize
  }

  func maxContentForFlexItem(flexItem: LogicalFlexItem) -> LayoutUnit {
    // 9.2.3 E Otherwise, size the item into the available space using its used flex basis in place of its main size,
    // treating a value of content as max-content. If a cross size is needed to determine the main size (e.g. when the flex item’s main size
    // is in its block axis) and the flex item’s cross size is auto and not definite, in this calculation use fit-content as the flex item’s cross size.
    // The flex base size is the item’s resulting main size.
    if flexItem.isOrhogonal && flexItem.crossAxis().definiteSize == nil {
      fatalError("Not implemented yet")
    }

    let flexItemBox = flexItem.layoutBox!
    return formattingContext().integrationUtils!.maxContentLogicalWidth(box: flexItemBox)
  }

  func flexContainer() -> ElementBoxWrapper { return flexFormattingContext.root() }

  func flexContainerStyle() -> RenderStyleWrapper {
    return flexContainer().style
  }

  func formattingContext() -> FlexFormattingContext {
    return flexFormattingContext
  }

  func formattingUtils() -> FlexFormattingUtils {
    return formattingContext().formattingUtils()
  }

  var flexFormattingContext: FlexFormattingContext

  var availableMainSpace = LayoutUnit()
  var availableCrossSpace = LayoutUnit()
}
