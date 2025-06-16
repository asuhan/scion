/*
 * Copyright (C) 2023 Apple Inc. All rights reserved.
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

import wk_interop

func usedValueOrZero(length: LengthWrapper, availableWidth: LayoutUnit?) -> LayoutUnit {
  if length.isFixed() {
    return LayoutUnit(value: length.value())
  }

  if length.isAuto() || availableWidth == nil {
    return LayoutUnit(value: 0)
  }

  return minimumValueForLength(length: length, maximumValue: availableWidth!)
}

private func adjustBorderForTableAndFieldset(
  renderer: RenderBoxModelObjectWrapper, borderLeft: inout LayoutUnit,
  borderRight: inout LayoutUnit, borderTop: inout LayoutUnit, borderBottom: inout LayoutUnit
) {
  if renderer as? RenderTableWrapper != nil {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  if renderer as? RenderTableCellWrapper != nil {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  if renderer.isFieldset() {
    let adjustment = (renderer as! RenderBlockWrapper).intrinsicBorderForFieldset()
    // Note that this adjustment is coming from _inside_ the fieldset so its own flow direction is what is relevant here.
    let style = renderer.style()
    switch style.blockFlowDirection() {
    case .TopToBottom:
      borderTop += adjustment
    case .BottomToTop:
      borderBottom += adjustment
    case .LeftToRight:
      borderLeft += adjustment
    case .RightToLeft:
      borderRight += adjustment
    }
  }
}

func intrinsicPaddingForTableCell(renderer: RenderBoxWrapper) -> BoxGeometry.VerticalEdges {
  if renderer is RenderTableCellWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  return BoxGeometry.VerticalEdges()
}

func contentLogicalWidthForRenderer(renderer: RenderBoxWrapper) -> LayoutUnit {
  return renderer.parent()!.style().isHorizontalWritingMode()
    ? renderer.contentWidth() : renderer.contentHeight()
}

func contentLogicalHeightForRenderer(renderer: RenderBoxWrapper) -> LayoutUnit {
  return renderer.parent()!.style().isHorizontalWritingMode()
    ? renderer.contentHeight() : renderer.contentWidth()
}

func scrollbarLogicalSize(renderer: RenderBoxWrapper) -> LayoutSizeWrapper {
  // Scrollbars eat into the padding box area. They never stretch the border box but they may shrink the padding box.
  // In legacy render tree, RenderBox::contentWidth/contentHeight values are adjusted to accommodate the scrollbar width/height.
  // e.g. <div style="width: 10px; overflow: scroll;">content</div>, RenderBox::contentWidth() won't be returning the value of 10px but instead 0px (10px - 15px).
  let horizontalSpaceReservedForScrollbar = max(
    LayoutUnit(value: 0),
    renderer.paddingBoxRectIncludingScrollbar().width() - renderer.paddingBoxWidth())
  let verticalSpaceReservedForScrollbar = max(
    LayoutUnit(value: 0),
    renderer.paddingBoxRectIncludingScrollbar().height() - renderer.paddingBoxHeight())
  return LayoutSizeWrapper(
    width: horizontalSpaceReservedForScrollbar, height: verticalSpaceReservedForScrollbar)
}

func setIntegrationBaseline(renderBox: RenderBoxWrapper, blockFlowDirection: FlowDirection) {
  if !hasNonSyntheticBaseline(renderBox: renderBox) {
    return
  }

  let baseline = renderBox.baselinePosition(
    baselineType: .AlphabeticBaseline, firstLine: false,
    direction: blockFlowDirection == .TopToBottom || blockFlowDirection == .BottomToTop
      ? .HorizontalLine : .VerticalLine, linePositionMode: .PositionOnContainingLine)
  renderBox.layoutBox()!.setBaselineForIntegration(baseline: baseline)
}

func hasNonSyntheticBaseline(renderBox: RenderBoxWrapper) -> Bool {
  if let renderListMarker = renderBox as? RenderListMarkerWrapper {
    return !renderListMarker.isImage()
  }

  if (renderBox is RenderReplacedWrapper && renderBox.style().display() == .Inline)
    || renderBox is RenderListBoxWrapper
    || renderBox is RenderSliderWrapper
    || renderBox is RenderTextControlMultiLineWrapper
    || renderBox is RenderTableWrapper
    || renderBox is RenderGridWrapper
    || renderBox is RenderFlexibleBoxWrapper
    || renderBox is RenderDeprecatedFlexibleBoxWrapper
    || renderBox is RenderMathMLBlockWrapper
    || renderBox is RenderButtonWrapper
  {
    // These are special RenderBlock renderers that override the default baseline position behavior of the inline block box.
    return true
  }
  if let blockFlow = renderBox as? RenderBlockFlowWrapper {
    return wk_interop.RenderBlockFlow_hasNonSyntheticBaseline(blockFlow.p)
  }
  return false
}

extension LayoutIntegration {
  struct BoxGeometryUpdater {
    init(layoutState: LayoutStateWrapper, rootLayoutBox: ElementBoxWrapper) {
      self.layoutState = layoutState
      self.rootLayoutBox = rootLayoutBox
    }

    func setFormattingContextRootGeometry(availableWidth: LayoutUnit) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func setFormattingContextContentGeometry(
      availableLogicalWidth: LayoutUnit?, intrinsicWidthMode: IntrinsicWidthMode?
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    mutating func updateBoxGeometryAfterIntegrationLayout(
      layoutBox: ElementBoxWrapper, availableWidth: LayoutUnit
    ) {
      let renderBox = layoutBox.rendererForIntegration() as! RenderBoxWrapper
      var boxGeometry = layoutState.ensureGeometryForBox(layoutBox: layoutBox)
      boxGeometry.setContentBoxSize(size: renderBox.contentLogicalSize())
      boxGeometry.setSpaceForScrollbar(scrollbarSize: scrollbarLogicalSize(renderer: renderBox))

      // FIXME: These should eventually be all absorbed by LFC layout.
      setIntegrationBaseline(renderBox: renderBox, blockFlowDirection: blockFlowDirection())

      if let renderListMarker = renderBox as? RenderListMarkerWrapper {
        let style = layoutBox.parent().style
        boxGeometry.setHorizontalMargin(
          margin: horizontalLogicalMargin(
            renderer: renderListMarker, availableWidth: nil,
            isLeftToRightInlineDirection: style.isLeftToRightDirection()))
        if !renderListMarker.isInside() {
          setListMarkerOffsetForMarkerOutside(listMarker: renderListMarker)
        }
      }

      if renderBox is RenderTableWrapper {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }

      if BoxGeometryUpdater.needsFullGeometryUpdate(layoutBox: layoutBox, renderBox: renderBox) {
        updateLayoutBoxDimensions(renderBox: renderBox, availableWidth: availableWidth)
      }

      if let shapeOutsideInfo = renderBox.shapeOutsideInfo() {
        layoutBox.setShape(shape: shapeOutsideInfo.computedShape())
      }
    }

    private static func needsFullGeometryUpdate(
      layoutBox: ElementBoxWrapper, renderBox: RenderBoxWrapper
    ) -> Bool {
      if renderBox.isFieldset() {
        // Fieldsets with legends have intrinsic padding values.
        return true
      }
      if renderBox.isWritingModeRoot() {
        // Currently we've got one BoxGeometry for a layout box, but it represents geometry when
        // it is a root but also when it is an inline level box (e.g. floats, inline-blocks).
        return true
      }
      if !layoutBox.isInitialContainingBlock() && layoutBox.establishesFormattingContext()
        && layoutBox.style.isLeftToRightDirection()
          != layoutBox.parent().style.isLeftToRightDirection()
      {
        return true
      }
      return false
    }

    func formattingContextConstraints(availableWidth: LayoutUnit) -> ConstraintsForInlineContent {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func takeNestedListMarkerOffsets() -> [UInt: LayoutUnit] {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func updateLayoutBoxDimensions(
      renderBox: RenderBoxWrapper, availableWidth: LayoutUnit?,
      intrinsicWidthMode: IntrinsicWidthMode? = nil
    ) {
      let layoutBox = renderBox.layoutBox()!
      var boxGeometry = layoutState.ensureGeometryForBox(layoutBox: layoutBox)
      let isLeftToRightInlineDirection = renderBox.parent()!.style().isLeftToRightDirection()

      let inlineMargin = horizontalLogicalMargin(
        renderer: renderBox, availableWidth: availableWidth,
        isLeftToRightInlineDirection: isLeftToRightInlineDirection)
      let border = logicalBorder(
        renderer: renderBox, isLeftToRightInlineDirection: isLeftToRightInlineDirection,
        isIntrinsicWidthMode: intrinsicWidthMode != nil)
      var padding = logicalPadding(
        renderer: renderBox, availableWidth: availableWidth,
        isLeftToRightInlineDirection: isLeftToRightInlineDirection)
      if intrinsicWidthMode == nil {
        padding.vertical += intrinsicPaddingForTableCell(renderer: renderBox)
      }

      let scrollbarSize = scrollbarLogicalSize(renderer: renderBox)

      if intrinsicWidthMode != nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }

      boxGeometry.setSpaceForScrollbar(scrollbarSize: scrollbarSize)

      boxGeometry.setContentBoxWidth(width: contentLogicalWidthForRenderer(renderer: renderBox))
      boxGeometry.setContentBoxHeight(height: contentLogicalHeightForRenderer(renderer: renderBox))

      boxGeometry.setVerticalMargin(
        margin: verticalLogicalMargin(renderer: renderBox, availableWidth: availableWidth))
      boxGeometry.setHorizontalMargin(margin: inlineMargin)
      boxGeometry.setBorder(border: border)
      boxGeometry.setPadding(padding: padding)
    }

    private mutating func setListMarkerOffsetForMarkerOutside(listMarker: RenderListMarkerWrapper) {
      let layoutBox = listMarker.layoutBox()!
      assert(layoutBox.isListMarkerOutside())
      var ancestor = listMarker.containingBlock()

      let offsetFromParentListItem = BoxGeometryUpdater.offsetFromParentListItem(
        ancestor: &ancestor)

      let offsetFromAssociatedListItem = BoxGeometryUpdater.offsetFromAssociatedListItem(
        listMarker: listMarker, ancestor: &ancestor,
        offsetFromParentListItem: offsetFromParentListItem)

      if offsetFromAssociatedListItem.bool() {
        let listMarkerGeometry = layoutState.ensureGeometryForBox(layoutBox: layoutBox)
        // Make sure that the line content does not get pulled in to logical left direction due to
        // the large negative margin (i.e. this ensures that logical left of the list content stays at the line start)
        listMarkerGeometry.setHorizontalMargin(
          margin: BoxGeometry.HorizontalEdges(
            start: listMarkerGeometry.marginStart() + offsetFromParentListItem,
            end: listMarkerGeometry.marginEnd() - offsetFromParentListItem))
        let nestedOffset = offsetFromAssociatedListItem - offsetFromParentListItem
        if nestedOffset.bool() {
          nestedListMarkerOffsets.updateValue(
            nestedOffset, forKey: CPtrToInt(layoutBox.p))
        }
      }
    }

    private static func offsetFromParentListItem(ancestor: inout RenderBlockWrapper?) -> LayoutUnit
    {
      var hasAccountedForBorderAndPadding = false
      var offset = LayoutUnit()
      while ancestor != nil {
        if !hasAccountedForBorderAndPadding {
          offset -= (ancestor!.borderStart() + ancestor!.paddingStart())
        }
        if ancestor is RenderListItemWrapper {
          break
        }
        offset -= ancestor!.marginStart()
        if ancestor!.isFlexItem() {
          offset -= ancestor!.logicalLeft()
          hasAccountedForBorderAndPadding = true
        } else {
          hasAccountedForBorderAndPadding = false
        }
        ancestor = ancestor!.containingBlock()
      }
      return offset
    }

    private static func offsetFromAssociatedListItem(
      listMarker: RenderListMarkerWrapper, ancestor: inout RenderBlockWrapper?,
      offsetFromParentListItem: LayoutUnit
    ) -> LayoutUnit {
      let associatedListItem = listMarker.listItem()
      if CPtrToInt(ancestor?.p) == CPtrToInt(associatedListItem?.p) || ancestor == nil {
        // FIXME: Handle column spanner case when ancestor is null_ptr here.
        return offsetFromParentListItem
      }
      var offset = offsetFromParentListItem
      ancestor = ancestor!.containingBlock()
      while ancestor != nil {
        offset -= (ancestor!.borderStart() + ancestor!.paddingStart())
        if CPtrToInt(ancestor?.p) == CPtrToInt(associatedListItem?.p) {
          break
        }
        ancestor = ancestor!.containingBlock()
      }
      return offset
    }

    private func horizontalLogicalMargin(
      renderer: RenderBoxModelObjectWrapper, availableWidth: LayoutUnit?,
      isLeftToRightInlineDirection: Bool, retainMarginStart: Bool = true,
      retainMarginEnd: Bool = true
    ) -> BoxGeometry.HorizontalEdges {
      let style = renderer.style()

      if isHorizontalWritingMode() {
        let logicalLeftValue =
          retainMarginStart
          ? usedValueOrZero(
            length: isLeftToRightInlineDirection ? style.marginLeft() : style.marginRight(),
            availableWidth: availableWidth) : LayoutUnit(value: 0)
        let logicalRightValue =
          retainMarginEnd
          ? usedValueOrZero(
            length: isLeftToRightInlineDirection ? style.marginRight() : style.marginLeft(),
            availableWidth: availableWidth) : LayoutUnit(value: 0)
        return BoxGeometry.HorizontalEdges(start: logicalLeftValue, end: logicalRightValue)
      }

      let logicalLeftValue =
        retainMarginStart
        ? usedValueOrZero(
          length: isLeftToRightInlineDirection ? style.marginTop() : style.marginBottom(),
          availableWidth: availableWidth)
        : LayoutUnit(value: 0)
      let logicalRightValue =
        retainMarginEnd
        ? usedValueOrZero(
          length: isLeftToRightInlineDirection ? style.marginBottom() : style.marginTop(),
          availableWidth: availableWidth)
        : LayoutUnit(value: 0)

      return BoxGeometry.HorizontalEdges(start: logicalLeftValue, end: logicalRightValue)
    }

    private func verticalLogicalMargin(
      renderer: RenderBoxModelObjectWrapper, availableWidth: LayoutUnit?
    ) -> BoxGeometry.VerticalEdges {
      let style = renderer.style()
      switch blockFlowDirection() {
      case .TopToBottom, .BottomToTop:
        return BoxGeometry.VerticalEdges(
          before: usedValueOrZero(length: style.marginTop(), availableWidth: availableWidth),
          after: usedValueOrZero(length: style.marginBottom(), availableWidth: availableWidth))
      case .LeftToRight, .RightToLeft:
        return BoxGeometry.VerticalEdges(
          before: usedValueOrZero(length: style.marginRight(), availableWidth: availableWidth),
          after: usedValueOrZero(length: style.marginLeft(), availableWidth: availableWidth))
      }
    }

    private func logicalBorder(
      renderer: RenderBoxModelObjectWrapper, isLeftToRightInlineDirection: Bool,
      isIntrinsicWidthMode: Bool = false, retainBorderStart: Bool = true,
      retainBorderEnd: Bool = true
    ) -> BoxGeometry.Edges {
      let style = renderer.style()

      var borderLeft = LayoutUnit(value: style.borderLeftWidth())
      var borderRight = LayoutUnit(value: style.borderRightWidth())
      var borderTop = LayoutUnit(value: style.borderTopWidth())
      var borderBottom = LayoutUnit(value: style.borderBottomWidth())

      if !isIntrinsicWidthMode {
        adjustBorderForTableAndFieldset(
          renderer: renderer, borderLeft: &borderLeft, borderRight: &borderRight,
          borderTop: &borderTop, borderBottom: &borderBottom)
      }

      if blockFlowDirection() == .TopToBottom || blockFlowDirection() == .BottomToTop {
        let borderLogicalLeft =
          retainBorderStart
          ? isLeftToRightInlineDirection ? borderLeft : borderRight : LayoutUnit(value: 0)
        let borderLogicalRight =
          retainBorderEnd
          ? isLeftToRightInlineDirection ? borderRight : borderLeft : LayoutUnit(value: 0)
        return BoxGeometry.Edges(
          horizontal: BoxGeometry.HorizontalEdges(
            start: borderLogicalLeft, end: borderLogicalRight),
          vertical: BoxGeometry.VerticalEdges(before: borderTop, after: borderBottom))
      }

      let borderLogicalLeft =
        retainBorderStart
        ? isLeftToRightInlineDirection ? borderTop : borderBottom : LayoutUnit(value: 0)
      let borderLogicalRight =
        retainBorderEnd
        ? isLeftToRightInlineDirection ? borderBottom : borderTop : LayoutUnit(value: 0)
      return BoxGeometry.Edges(
        horizontal: BoxGeometry.HorizontalEdges(
          start: borderLogicalLeft, end: borderLogicalRight),
        vertical: BoxGeometry.VerticalEdges(before: borderRight, after: borderLeft))
    }

    private func logicalPadding(
      renderer: RenderBoxModelObjectWrapper, availableWidth: LayoutUnit?,
      isLeftToRightInlineDirection: Bool, retainPaddingStart: Bool = true,
      retainPaddingEnd: Bool = true
    ) -> BoxGeometry.Edges {
      let style = renderer.style()

      let paddingLeft = usedValueOrZero(length: style.paddingLeft(), availableWidth: availableWidth)
      let paddingRight = usedValueOrZero(
        length: style.paddingRight(), availableWidth: availableWidth)
      let paddingTop = usedValueOrZero(length: style.paddingTop(), availableWidth: availableWidth)
      let paddingBottom = usedValueOrZero(
        length: style.paddingBottom(), availableWidth: availableWidth)

      if blockFlowDirection() == .TopToBottom || blockFlowDirection() == .BottomToTop {
        let paddingLogicalLeft =
          retainPaddingStart
          ? isLeftToRightInlineDirection ? paddingLeft : paddingRight : LayoutUnit(value: 0)
        let paddingLogicalRight =
          retainPaddingEnd
          ? isLeftToRightInlineDirection ? paddingRight : paddingLeft : LayoutUnit(value: 0)
        return BoxGeometry.Edges(
          horizontal: BoxGeometry.HorizontalEdges(
            start: paddingLogicalLeft, end: paddingLogicalRight),
          vertical: BoxGeometry.VerticalEdges(before: paddingTop, after: paddingBottom))
      }

      let paddingLogicalLeft =
        retainPaddingStart
        ? isLeftToRightInlineDirection ? paddingTop : paddingBottom : LayoutUnit(value: 0)
      let paddingLogicalRight =
        retainPaddingEnd
        ? isLeftToRightInlineDirection ? paddingBottom : paddingTop : LayoutUnit(value: 0)
      return BoxGeometry.Edges(
        horizontal: BoxGeometry.HorizontalEdges(
          start: paddingLogicalLeft, end: paddingLogicalRight),
        vertical: BoxGeometry.VerticalEdges(before: paddingRight, after: paddingLeft))
    }

    private func blockFlowDirection() -> FlowDirection {
      return rootRenderer().style().blockFlowDirection()
    }

    private func isHorizontalWritingMode() -> Bool {
      return rootRenderer().style().isHorizontalWritingMode()
    }

    private func rootRenderer() -> RenderBlockWrapper {
      return rootLayoutBox.rendererForIntegration()! as! RenderBlockWrapper
    }

    private var layoutState: LayoutStateWrapper
    private var rootLayoutBox: ElementBoxWrapper
    private var nestedListMarkerOffsets: [UInt: LayoutUnit] = [:]
  }
}
