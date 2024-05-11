/*
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

// This class implements the layout logic for flex formatting contexts.
// https://www.w3.org/TR/css-flexbox-1/
class FlexFormattingContext {
  struct FlexItem {
    var mainAxis: LogicalFlexItem.MainAxisGeometry
    var crossAxis: LogicalFlexItem.CrossAxisGeometry
    var logicalOrder = 0
    var layoutBox: ElementBoxWrapper
  }

  init(flexBox: ElementBoxWrapper, globalLayoutState: LayoutStateWrapper) {
    self.flexBox = flexBox
    self.globalLayoutState = globalLayoutState
    self.flexFormattingUtils = FlexFormattingUtils(flexFormattingContext: self)
    self.integrationUtils = IntegrationUtils(globalLayoutState: globalLayoutState)
  }

  func layout(constraints: ConstraintsForFlexContent) {
    let logicalFlexItems = convertFlexItemsToLogicalSpace(constraints: constraints)
    var flexLayout = FlexLayout(flexFormattingContext: self)

    let flexDirection = root().style.flexDirection()
    let flexDirectionIsInlineAxis = flexDirection == .Row || flexDirection == .RowReverse
    let logicalVerticalSpace =
      flexDirectionIsInlineAxis
      ? constraints.availableVerticalSpace : constraints.horizontal.logicalWidth
    let logicalHorizontalSpace =
      flexDirectionIsInlineAxis
      ? constraints.horizontal.logicalWidth : constraints.availableVerticalSpace

    let logicalFlexConstraints = FlexLayout.LogicalConstraints(
      mainAxis: FlexLayout.LogicalConstraints.AxisGeometry(definiteSize: logicalHorizontalSpace),
      crossAxis: FlexLayout.LogicalConstraints.AxisGeometry(definiteSize: logicalVerticalSpace)
    )

    let flexItemRects = flexLayout.layout(
      logicalConstraints: logicalFlexConstraints, flexItems: logicalFlexItems)
    setFlexItemsGeometry(
      logicalFlexItemList: logicalFlexItems, logicalRects: flexItemRects, constraints: constraints)
  }

  func root() -> ElementBoxWrapper {
    return flexBox!
  }

  func formattingUtils() -> FlexFormattingUtils {
    return flexFormattingUtils!
  }

  func geometryForFlexItem(flexItem: BoxWrapper) -> BoxGeometry {
    assert(flexItem.isFlexItem())
    return globalLayoutState!.geometryForBox(layoutBox: flexItem)
  }

  func convertFlexItemsToLogicalSpace(constraints: ConstraintsForFlexContent)
    -> FlexLayout.LogicalFlexItems
  {
    var flexItemList: [FlexItem] = []
    var flexItemsNeedReordering = false

    convertVisualToLogical(
      constraints: constraints, flexItemList: &flexItemList,
      flexItemsNeedReordering: &flexItemsNeedReordering)

    reorderFlexItemsIfApplicable(
      flexItemsNeedReordering: flexItemsNeedReordering, flexItemList: &flexItemList)

    var logicalFlexItemList = FlexLayout.LogicalFlexItems(
      repeating: LogicalFlexItem(), count: flexItemList.count)
    for index in 0..<flexItemList.count {
      let flexItem = flexItemList[index]
      logicalFlexItemList[index] = LogicalFlexItem(
        flexItem: flexItem.layoutBox, mainGeometry: flexItem.mainAxis,
        crossGeometry: flexItem.crossAxis, hasAspectRatio: false, isOrhogonal: false)
    }
    return logicalFlexItemList
  }

  func convertVisualToLogical(
    constraints: ConstraintsForFlexContent, flexItemList: inout [FlexItem],
    flexItemsNeedReordering: inout Bool
  ) {
    let direction = root().style.flexDirection()
    var previousLogicalOrder: Int? = nil

    var flexItem = root().firstInFlowChild()
    while flexItem != nil {
      let flexItemGeometry = globalLayoutState!.geometryForBox(layoutBox: flexItem!)
      let style = flexItem!.style
      var mainAxis = LogicalFlexItem.MainAxisGeometry()
      var crossAxis = LogicalFlexItem.CrossAxisGeometry()

      switch direction {
      case .Row, .RowReverse:
        if style.flexBasis().isAuto() {
          // Auto keyword retrieves the value of the main size property as the used flex-basis.
          // If that value is itself auto, then the used value is content.
          if !style.width().isAuto() {
            mainAxis.definiteFlexBasis = valueForLength(
              length: style.width(), maximumValue: constraints.horizontal.logicalWidth)
          }
        } else if !style.flexBasis().isContent() {
          mainAxis.definiteFlexBasis = valueForLength(
            length: style.flexBasis(), maximumValue: constraints.horizontal.logicalWidth)
        }
        if style.minWidth().isSpecified() {
          mainAxis.minimumSize = valueForLength(
            length: style.minWidth(), maximumValue: constraints.horizontal.logicalWidth)
        }
        if style.maxWidth().isSpecified() {
          mainAxis.maximumSize = valueForLength(
            length: style.maxWidth(), maximumValue: constraints.horizontal.logicalWidth)
        }

        mainAxis.marginStart = FlexFormattingContext.marginStart(
          flexItemGeometry: flexItemGeometry, direction: direction, style: style)
        mainAxis.marginEnd = FlexFormattingContext.marginEnd(
          flexItemGeometry: flexItemGeometry, direction: direction, style: style)
        mainAxis.borderAndPadding = flexItemGeometry.horizontalBorderAndPadding()

        if !style.marginBefore().isAuto() {
          crossAxis.marginStart = flexItemGeometry.marginBefore()
        }
        if !style.marginAfter().isAuto() {
          crossAxis.marginEnd = flexItemGeometry.marginAfter()
        }
        let height = style.height()
        crossAxis.hasSizeAuto = height.isAuto()
        if height.isFixed() {
          crossAxis.definiteSize = LayoutUnit(value: height.value())
        }
        if style.maxHeight().isSpecified() {
          crossAxis.maximumSize = valueForLength(
            length: style.maxHeight(),
            maximumValue: constraints.availableVerticalSpace ?? LayoutUnit(value: 0))
        }
        if style.minHeight().isSpecified() {
          crossAxis.minimumSize = valueForLength(
            length: style.minHeight(),
            maximumValue: constraints.availableVerticalSpace ?? LayoutUnit(value: 0))
        }
        crossAxis.borderAndPadding = flexItemGeometry.verticalBorderAndPadding()
      case .Column, .ColumnReverse:
        break
      }
      let flexItemOrder = style.order()
      flexItemsNeedReordering =
        flexItemsNeedReordering || flexItemOrder != (previousLogicalOrder ?? 0)
      previousLogicalOrder = flexItemOrder

      flexItemList.append(
        FlexItem(
          mainAxis: mainAxis, crossAxis: crossAxis, layoutBox: flexItem as! ElementBoxWrapper))

      flexItem = flexItem!.nextInFlowSibling()
    }
  }

  static func marginStart(
    flexItemGeometry: BoxGeometry, direction: FlexDirection, style: RenderStyleWrapper
  ) -> LayoutUnit? {
    if direction == .Row {
      return style.marginStart().isAuto() ? nil : flexItemGeometry.marginStart()
    }
    return style.marginEnd().isAuto() ? nil : flexItemGeometry.marginEnd()
  }

  static func marginEnd(
    flexItemGeometry: BoxGeometry, direction: FlexDirection, style: RenderStyleWrapper
  ) -> LayoutUnit? {
    if direction == .Row {
      return style.marginEnd().isAuto() ? nil : flexItemGeometry.marginEnd()
    }
    return style.marginStart().isAuto() ? nil : flexItemGeometry.marginStart()
  }

  func reorderFlexItemsIfApplicable(flexItemsNeedReordering: Bool, flexItemList: inout [FlexItem]) {
    if !flexItemsNeedReordering {
      return
    }

    // TODO(asuhan): use a guaranteed stable sort
    flexItemList.sort { $0.logicalOrder < $1.logicalOrder }
  }

  func setFlexItemsGeometry(
    logicalFlexItemList: FlexLayout.LogicalFlexItems, logicalRects: FlexLayout.LogicalFlexItemRects,
    constraints: ConstraintsForFlexContent
  ) {
    let logicalWidth = logicalRects.last!.right() - logicalRects.first!.left()
    let flexBoxStyle = root().style
    let flexDirection = flexBoxStyle.flexDirection()
    let isMainAxisParallelWithInlineAxis = FlexFormattingUtils.isMainAxisParallelWithInlineAxis(
      flexBox: root())
    let flexBoxLogicalHeightForWarpReverse =
      FlexFormattingContext.flexBoxLogicalHeightForWarpReverse(
        flexBoxStyle: flexBoxStyle,
        isMainAxisParallelWithInlineAxis: isMainAxisParallelWithInlineAxis,
        logicalRects: logicalRects, constraints: constraints)

    for (index, logicalFlexItem) in logicalFlexItemList.enumerated() {
      let flexItemGeometry = geometryForFlexItem(flexItem: logicalFlexItem.layoutBox!)
      let logicalRect = FlexFormattingContext.logicalRect(
        flexBoxLogicalHeightForWarpReverse: flexBoxLogicalHeightForWarpReverse,
        logicalRects: logicalRects, index: index, logicalFlexItem: logicalFlexItem,
        flexItemGeometry: flexItemGeometry)

      var borderBoxTopLeft = LayoutPointWrapper()
      switch flexDirection {
      case .Row:
        borderBoxTopLeft = LayoutPointWrapper(
          x: constraints.horizontal.logicalLeft + logicalRect.left(),
          y: constraints.logicalTop + logicalRect.top())
      case .RowReverse:
        borderBoxTopLeft = LayoutPointWrapper(
          x: constraints.horizontal.logicalRight() - logicalRect.right(),
          y: constraints.logicalTop + logicalRect.top())
        if logicalFlexItem.isContentBoxBased() {
          borderBoxTopLeft.move(
            s: LayoutSizeWrapper(
              width: -flexItemGeometry.horizontalBorderAndPadding(), height: LayoutUnit(value: 0)))
        }
      case .Column:
        let flippedTopLeft = FloatPoint(x: logicalRect.top().float(), y: logicalRect.left().float())
        borderBoxTopLeft = LayoutPointWrapper(
          x: constraints.horizontal.logicalLeft + LayoutUnit(value: flippedTopLeft.x),
          y: constraints.logicalTop + LayoutUnit(value: flippedTopLeft.y))
      case .ColumnReverse:
        let visualBottom =
          constraints.logicalTop + (constraints.availableVerticalSpace ?? logicalWidth)
        borderBoxTopLeft = LayoutPointWrapper(
          x: constraints.horizontal.logicalLeft + logicalRect.top(),
          y: visualBottom - logicalRect.right())
      }
      flexItemGeometry.setTopLeft(topLeft: borderBoxTopLeft)

      var contentBoxWidth =
        isMainAxisParallelWithInlineAxis ? logicalRect.width() : logicalRect.height()
      var contentBoxHeight =
        isMainAxisParallelWithInlineAxis ? logicalRect.height() : logicalRect.width()
      if !logicalFlexItem.isContentBoxBased() {
        contentBoxWidth -= flexItemGeometry.horizontalBorderAndPadding()
        contentBoxHeight -= flexItemGeometry.verticalBorderAndPadding()
      }
      flexItemGeometry.setContentBoxWidth(width: contentBoxWidth)
      flexItemGeometry.setContentBoxHeight(height: contentBoxHeight)
    }
  }

  static func flexBoxLogicalHeightForWarpReverse(
    flexBoxStyle: RenderStyleWrapper, isMainAxisParallelWithInlineAxis: Bool,
    logicalRects: FlexLayout.LogicalFlexItemRects, constraints: ConstraintsForFlexContent
  ) -> LayoutUnit? {
    if flexBoxStyle.flexWrap() != .Reverse {
      return nil
    }
    if !isMainAxisParallelWithInlineAxis {
      // We always have a valid horizontal constraint for column logical height.
      return constraints.horizontal.logicalWidth
    }

    // Let's use the bottom of the content if flex box does not have a definite height.
    return constraints.availableVerticalSpace ?? logicalRects.last!.bottom()
  }

  static func logicalRect(
    flexBoxLogicalHeightForWarpReverse: LayoutUnit?, logicalRects: FlexLayout.LogicalFlexItemRects,
    index: Int, logicalFlexItem: LogicalFlexItem, flexItemGeometry: BoxGeometry
  ) -> FlexRect {
    // Note that flex rects are inner size based.
    if let flexBoxLogicalHeightForWarpReverse = flexBoxLogicalHeightForWarpReverse {
      let rect = logicalRects[index]
      var adjustedLogicalTop = flexBoxLogicalHeightForWarpReverse - rect.bottom()
      if logicalFlexItem.isContentBoxBased() {
        adjustedLogicalTop -= flexItemGeometry.verticalBorderAndPadding()
      }
      rect.setTop(top: adjustedLogicalTop)
      return rect
    }
    return logicalRects[index]
  }

  var flexBox: ElementBoxWrapper? = nil
  var globalLayoutState: LayoutStateWrapper? = nil
  var flexFormattingUtils: FlexFormattingUtils? = nil
  var integrationUtils: IntegrationUtils? = nil
}
