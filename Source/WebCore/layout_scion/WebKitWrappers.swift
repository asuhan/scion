/*
 * Copyright (C) 2025 Apple Inc. All rights reserved.
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

internal func convert_constraints(constraintsCPtr: UnsafeRawPointer) -> ConstraintsForInlineContent
{
  let logicalLeft = LayoutUnit.fromRawValue(
    value: wk_interop.ConstraintsForInlineContent_horizontal_logicalLeft(
      constraintsCPtr))
  let logicalWidth = LayoutUnit.fromRawValue(
    value: wk_interop.ConstraintsForInlineContent_horizontal_logicalWidth(
      constraintsCPtr))
  let logicalTop = LayoutUnit.fromRawValue(
    value: wk_interop.ConstraintsForInlineContent_logicalTop(constraintsCPtr))
  let visualLeft = LayoutUnit.fromRawValue(
    value: wk_interop.ConstraintsForInlineContent_visualLeft(constraintsCPtr))
  let baseTypeFlags = ConstraintsForInFlowContent.BaseTypeFlag(
    rawValue: wk_interop.ConstraintsForInlineContent_baseTypeFlags(constraintsCPtr))
  let horizontal = HorizontalConstraints(logicalLeft: logicalLeft, logicalWidth: logicalWidth)
  let genericContraints = ConstraintsForInFlowContent(
    horizontal: horizontal,
    logicalTop: logicalTop)
  return ConstraintsForInlineContent(
    genericContraints: genericContraints, visualLeft: visualLeft, baseTypeFlags: baseTypeFlags)
}

func convert_box_geometry_horizontal_edges(raw: wk_interop.BoxGeometryHorizontalEdgesRaw)
  -> BoxGeometry.HorizontalEdges
{
  return BoxGeometry.HorizontalEdges(
    start: LayoutUnit.fromRawValue(value: raw.start),
    end: LayoutUnit.fromRawValue(value: raw.end))
}

func convert_box_geometry_vertical_edges(raw: wk_interop.BoxGeometryVerticalEdgesRaw)
  -> BoxGeometry.VerticalEdges
{
  return BoxGeometry.VerticalEdges(
    before: LayoutUnit.fromRawValue(value: raw.before),
    after: LayoutUnit.fromRawValue(value: raw.after))
}

func convert_box_geometry_edges(raw: wk_interop.BoxGeometryEdgesRaw) -> BoxGeometry.Edges {
  return BoxGeometry.Edges(
    horizontal: convert_box_geometry_horizontal_edges(raw: raw.horizontal),
    vertical: convert_box_geometry_vertical_edges(raw: raw.vertical))
}

func convert_box_geometry(raw: wk_interop.BoxGeometryRaw) -> BoxGeometry {
  let box = BoxGeometry()
  box.p = raw.orig_ptr
  box.padding = convert_box_geometry_edges(raw: raw.padding)
  box.verticalSpaceForScrollbar = LayoutUnit.fromRawValue(value: raw.vertical_space_for_scrollbar)
  box.horizontalSpaceForScrollbar = LayoutUnit.fromRawValue(
    value: raw.horizontal_space_for_scrollbar)
  return box
}

func convert_placed_floats_item(raw: wk_interop.PlacedFloatsItemRaw) -> PlacedFloats.Item {
  var layoutBox: BoxWrapper? = nil
  if let p = raw.layout_box {
    layoutBox = BoxWrapper()
    layoutBox!.p = p
  }
  var shape: ShapeWrapper? = nil
  if let layoutBox = layoutBox {
    shape = layoutBox.shape()
  }
  var item = PlacedFloats.Item(
    position: PlacedFloats.Item.Position(rawValue: raw.position)!,
    absoluteBoxGeometry: convert_box_geometry(raw: raw.absolute_box_geometry),
    localTopLeft: LayoutPointWrapper(),
    shape: shape)
  item.placedByLine = raw.placed_by_line_is_valid ? raw.placed_by_line : nil
  item.m_layoutBox = layoutBox
  return item
}

func convert_placed_floats(raw: PlacedFloatsRaw) -> PlacedFloats {
  let root_raw_ptr = raw.block_formatting_context_root
  let style = convert_render_style(p: Box_style(root_raw_ptr))
  let blockFormattingContextRoot = ElementBoxWrapper(style: style)
  blockFormattingContextRoot.p = root_raw_ptr
  let placedFloats = PlacedFloats(blockFormattingContextRoot: blockFormattingContextRoot)
  for i in 0..<raw.inline_items_count {
    placedFloats.list.append(convert_placed_floats_item(raw: raw.inline_items[Int(i)]))
  }
  return placedFloats
}

func convert_line_clamp_raw(raw: LineClampRaw) -> BlockLayoutState.LineClamp? {
  if !raw.isValid {
    return nil
  }
  return BlockLayoutState.LineClamp(
    maximumLines: raw.maximumLines,
    shouldDiscardOverflow: raw.shouldDiscardOverflow, isLegacy: raw.isLegacy)
}

@_cdecl("InlineFormattingContext_layout")
public func InlineFormattingContext_layout(
  inlineFormattingContextCPtr: UnsafeMutableRawPointer,
  constraintsCPtr: UnsafeRawPointer,
  lineDamageCPtr: UnsafeMutableRawPointer?,
  nestedListedMarkersCArr: UnsafePointer<UnsafeRawPointer?>?,
  nestedListMarkerOffsetsCArr: UnsafeRawPointer?,
  nestedListMarkersCount: UInt64,
  placedFloatsRaw: PlacedFloatsRaw,
  lineClampRaw: LineClampRaw,
  layoutResultCPtr: UnsafeMutableRawPointer
) {
  let rootLayoutBoxC = InlineFormattingContext_root(inlineFormattingContextCPtr)
  let style = convert_render_style(p: Box_style(rootLayoutBoxC))
  let rootLayoutBox = ElementBoxWrapper(style: style)
  rootLayoutBox.p = rootLayoutBoxC
  let layoutStateC = InlineFormattingContext_globalLayoutState(inlineFormattingContextCPtr)
  let layoutState = LayoutStateWrapper(p: layoutStateC)
  let parentBlockLayoutState = BlockLayoutState(
    placedFloats: convert_placed_floats(raw: placedFloatsRaw),
    lineClamp: convert_line_clamp_raw(raw: lineClampRaw))
  let inlineFormattingContext = InlineFormattingContext(
    rootBlockContainer: rootLayoutBox, globalLayoutState: layoutState,
    parentBlockLayoutState: parentBlockLayoutState)
  var nestedListMarkerOffsets: [UInt: LayoutUnit] = [:]
  for idx in 0..<nestedListMarkersCount {
    let key = CPtrToInt(CPtrArrElement(nestedListedMarkersCArr, idx))
    let rawOffset = I32ArrElement(nestedListMarkerOffsetsCArr, idx)
    nestedListMarkerOffsets.updateValue(LayoutUnit.fromRawValue(value: rawOffset), forKey: key)
  }
  inlineFormattingContext.layoutState().setNestedListMarkerOffsets(
    nestedListMarkerOffsets: nestedListMarkerOffsets)
  var lineDamage: InlineDamageWrapper? =
    lineDamageCPtr != nil ? InlineDamageWrapper(p: lineDamageCPtr!) : nil
  let constraints = convert_constraints(constraintsCPtr: constraintsCPtr)
  let inlineLayoutResult = inlineFormattingContext.layout(
    constraints: constraints, lineDamage: &lineDamage)
  for line in inlineLayoutResult.displayContent.lines {
    let line_box_rect = wk_interop.FloatRect_new(
      line.lineBoxRect.x(), line.lineBoxRect.y(), line.lineBoxRect.width(),
      line.lineBoxRect.height())
    let line_box_logical_rect = wk_interop.FloatRect_new(
      line.lineBoxLogicalRect.x(), line.lineBoxLogicalRect.y(), line.lineBoxLogicalRect.width(),
      line.lineBoxLogicalRect.height())
    let scrollable_overflow = wk_interop.FloatRect_new(
      line.scrollableOverflow.x(), line.scrollableOverflow.y(), line.scrollableOverflow.width(),
      line.scrollableOverflow.height())
    let content_overflow = wk_interop.FloatRect_new(
      line.contentOverflow.x(), line.contentOverflow.y(), line.contentOverflow.width(),
      line.contentOverflow.height())
    let ink_overflow = wk_interop.FloatRect_new(
      line.inkOverflow.x(), line.inkOverflow.y(), line.inkOverflow.width(),
      line.inkOverflow.height())
    let enclosing_logical_top_and_bottom = wk_interop.EnclosingTopAndBottom_new(
      line.enclosingLogicalTopAndBottom.top, line.enclosingLogicalTopAndBottom.bottom)
    var ellipsisC: UnsafeRawPointer? = nil
    if let ellipsis = line.ellipsis {
      if ellipsis.text.p == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      ellipsisC = wk_interop.Ellipsis_new(
        ellipsis.type.rawValue, ellipsis.visualRect.x(),
        ellipsis.visualRect.y(), ellipsis.visualRect.width(),
        ellipsis.visualRect.height(), ellipsis.text.p)
    }
    let lineC = wk_interop.InlineDisplayLine_new(
      0,  // first_box_index
      0,  // box_count
      line_box_rect,
      line_box_logical_rect,
      scrollable_overflow,
      content_overflow,
      ink_overflow,
      enclosing_logical_top_and_bottom,
      line.alignmentBaseline,
      line.contentLogicalLeft,
      line.contentLogicalLeftIgnoringInlineDirection,
      line.contentLogicalWidth,
      line.baselineType.rawValue,
      line.isLeftToRightDirection,
      line.isHorizontal,
      line.isFirstAfterPageBreak,
      line.isFullyTruncatedInBlockDirection,
      line.hasContentAfterEllipsisBox,
      ellipsisC
    )
    wk_interop.InlineLayoutResult_displayContent_addLine(layoutResultCPtr, lineC)
  }
  for box in inlineLayoutResult.displayContent.boxes {
    let unflipped_visual_rect = wk_interop.FloatRect_new(
      box.unflippedVisualRect.x(), box.unflippedVisualRect.y(), box.unflippedVisualRect.width(),
      box.unflippedVisualRect.height())
    let ink_overflow = wk_interop.FloatRect_new(
      box.inkOverflow.x(), box.inkOverflow.y(), box.inkOverflow.width(), box.inkOverflow.height())
    let expansion = box.expansion()
    let expansionC = wk_interop.Expansion_new(
      expansion.behavior.left.rawValue, expansion.behavior.right.rawValue,
      expansion.horizontalExpansion)
    let text =
      box.isTextOrSoftLineBreak()
      ? wk_interop.Text_new(
        UInt64(box.text().start), UInt64(box.text().length),
        box.text().partiallyVisibleContentLength,
        box.text().hasPartiallyVisibleContentLength, box.text().m_originalContent.p,
        box.text().adjustedContentToRender.p != nil
          ? wk_interop.String_new_copy(box.text().adjustedContentToRender.p) : nil,
        box.text().hasHyphen) : nil
    var positionWithinInlineLevelBox = InlineDisplay.Box.PositionWithinInlineLevelBox()
    if box.isFirstForLayoutBox {
      positionWithinInlineLevelBox = positionWithinInlineLevelBox.union(
        InlineDisplay.Box.PositionWithinInlineLevelBox.First)
    }
    if box.isLastForLayoutBox {
      positionWithinInlineLevelBox = positionWithinInlineLevelBox.union(
        InlineDisplay.Box.PositionWithinInlineLevelBox.Last)
    }
    let boxC = wk_interop.InlineDisplayBox_new(
      box.layoutBox.p,
      unflipped_visual_rect,
      ink_overflow,
      UInt64(box.lineIndex),
      expansionC,
      box.bidiLevel.rawValue,
      box.type.rawValue,
      box.hasContent,
      positionWithinInlineLevelBox.rawValue,
      box.isFullyTruncated,
      text
    )
    wk_interop.InlineLayoutResult_displayContent_addBox(layoutResultCPtr, boxC)
  }
  wk_interop.InlineLayoutResult_setRange(layoutResultCPtr, inlineLayoutResult.range.rawValue)
  wk_interop.InlineFormattingContext_setClearGapAfterLastLine(
    inlineFormattingContextCPtr,
    inlineFormattingContext.layoutState().clearGapAfterLastLine)
}

@_cdecl("LineLayout_layout")
public func LineLayout_layout(
  inlineFormattingContextCPtr: UnsafeMutableRawPointer,
  constraintsCPtr: UnsafeRawPointer,
  lineDamageCPtr: UnsafeMutableRawPointer?,
  nestedListedMarkersCArr: UnsafePointer<UnsafeRawPointer?>?,
  nestedListMarkerOffsetsCArr: UnsafeRawPointer?,
  nestedListMarkersCount: UInt64,
  placedFloatsRaw: PlacedFloatsRaw,
  lineClampRaw: LineClampRaw,
  layoutResultCPtr: UnsafeMutableRawPointer,
  lineLayoutRootFlowCPtr: UnsafeMutableRawPointer,
  isPartialLayout: Bool,
  intrusiveInitialLetterLogicalBottomRaw: OptionalIntRaw
) -> LayoutRectRaw {
  let lineLayout = LayoutIntegration.LineLayout(
    flow: RenderBlockFlowWrapper(p: lineLayoutRootFlowCPtr))
  lineLayout.blockFormattingState.placedFloats = convert_placed_floats(raw: placedFloatsRaw)
  let rootLayoutBoxC = InlineFormattingContext_root(inlineFormattingContextCPtr)
  let style = convert_render_style(p: Box_style(rootLayoutBoxC))
  let rootLayoutBox = ElementBoxWrapper(style: style)
  rootLayoutBox.p = rootLayoutBoxC
  let layoutStateC = InlineFormattingContext_globalLayoutState(inlineFormattingContextCPtr)
  let layoutState = LayoutStateWrapper(p: layoutStateC)
  let parentBlockLayoutState = BlockLayoutState(
    placedFloats: convert_placed_floats(raw: placedFloatsRaw),
    lineClamp: convert_line_clamp_raw(raw: lineClampRaw),
    textBoxTrim: BlockLayoutState.TextBoxTrim(),  // TODO(asuhan): pass this correctly
    textBoxEdge: TextEdge(),  // TODO(asuhan): pass this correctly
    intrusiveInitialLetterLogicalBottom: intrusiveInitialLetterLogicalBottomRaw.is_valid
      ? LayoutUnit.fromRawValue(value: intrusiveInitialLetterLogicalBottomRaw.value)
      : nil)
  let inlineFormattingContext = InlineFormattingContext(
    rootBlockContainer: rootLayoutBox, globalLayoutState: layoutState,
    parentBlockLayoutState: parentBlockLayoutState)
  var nestedListMarkerOffsets: [UInt: LayoutUnit] = [:]
  for idx in 0..<nestedListMarkersCount {
    let key = CPtrToInt(CPtrArrElement(nestedListedMarkersCArr, idx))
    let rawOffset = I32ArrElement(nestedListMarkerOffsetsCArr, idx)
    nestedListMarkerOffsets.updateValue(LayoutUnit.fromRawValue(value: rawOffset), forKey: key)
  }
  inlineFormattingContext.layoutState().setNestedListMarkerOffsets(
    nestedListMarkerOffsets: nestedListMarkerOffsets)
  var lineDamage: InlineDamageWrapper? =
    lineDamageCPtr != nil ? InlineDamageWrapper(p: lineDamageCPtr!) : nil
  let constraints = convert_constraints(constraintsCPtr: constraintsCPtr)
  lineLayout.inlineContentConstraints = constraints
  let layoutResult = inlineFormattingContext.layout(
    constraints: constraints, lineDamage: &lineDamage)
  let repaintRect = LayoutRectWrapper(
    r: lineLayout.constructContent(
      inlineLayoutState: inlineFormattingContext.layoutState(), layoutResult: layoutResult))

  let adjustments = lineLayout.adjustContentForPagination(
    blockLayoutState: parentBlockLayoutState, isPartialLayout: isPartialLayout)

  lineLayout.updateRenderTreePositions(
    lineAdjustments: adjustments, inlineLayoutState: inlineFormattingContext.layoutState())

  for line in layoutResult.displayContent.lines {
    let line_box_rect = wk_interop.FloatRect_new(
      line.lineBoxRect.x(), line.lineBoxRect.y(), line.lineBoxRect.width(),
      line.lineBoxRect.height())
    let line_box_logical_rect = wk_interop.FloatRect_new(
      line.lineBoxLogicalRect.x(), line.lineBoxLogicalRect.y(), line.lineBoxLogicalRect.width(),
      line.lineBoxLogicalRect.height())
    let scrollable_overflow = wk_interop.FloatRect_new(
      line.scrollableOverflow.x(), line.scrollableOverflow.y(), line.scrollableOverflow.width(),
      line.scrollableOverflow.height())
    let content_overflow = wk_interop.FloatRect_new(
      line.contentOverflow.x(), line.contentOverflow.y(), line.contentOverflow.width(),
      line.contentOverflow.height())
    let ink_overflow = wk_interop.FloatRect_new(
      line.inkOverflow.x(), line.inkOverflow.y(), line.inkOverflow.width(),
      line.inkOverflow.height())
    let enclosing_logical_top_and_bottom = wk_interop.EnclosingTopAndBottom_new(
      line.enclosingLogicalTopAndBottom.top, line.enclosingLogicalTopAndBottom.bottom)
    var ellipsisC: UnsafeRawPointer? = nil
    if let ellipsis = line.ellipsis {
      if ellipsis.text.p == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      ellipsisC = wk_interop.Ellipsis_new(
        ellipsis.type.rawValue, ellipsis.visualRect.x(),
        ellipsis.visualRect.y(), ellipsis.visualRect.width(),
        ellipsis.visualRect.height(), ellipsis.text.p)
    }
    let lineC = wk_interop.InlineDisplayLine_new(
      0,  // first_box_index
      0,  // box_count
      line_box_rect,
      line_box_logical_rect,
      scrollable_overflow,
      content_overflow,
      ink_overflow,
      enclosing_logical_top_and_bottom,
      line.alignmentBaseline,
      line.contentLogicalLeft,
      line.contentLogicalLeftIgnoringInlineDirection,
      line.contentLogicalWidth,
      line.baselineType.rawValue,
      line.isLeftToRightDirection,
      line.isHorizontal,
      line.isFirstAfterPageBreak,
      line.isFullyTruncatedInBlockDirection,
      line.hasContentAfterEllipsisBox,
      ellipsisC
    )
    wk_interop.InlineLayoutResult_displayContent_addLine(layoutResultCPtr, lineC)
  }
  for box in layoutResult.displayContent.boxes {
    let unflipped_visual_rect = wk_interop.FloatRect_new(
      box.unflippedVisualRect.x(), box.unflippedVisualRect.y(), box.unflippedVisualRect.width(),
      box.unflippedVisualRect.height())
    let ink_overflow = wk_interop.FloatRect_new(
      box.inkOverflow.x(), box.inkOverflow.y(), box.inkOverflow.width(), box.inkOverflow.height())
    let expansion = box.expansion()
    let expansionC = wk_interop.Expansion_new(
      expansion.behavior.left.rawValue, expansion.behavior.right.rawValue,
      expansion.horizontalExpansion)
    let text =
      box.isTextOrSoftLineBreak()
      ? wk_interop.Text_new(
        UInt64(box.text().start), UInt64(box.text().length),
        box.text().partiallyVisibleContentLength,
        box.text().hasPartiallyVisibleContentLength, box.text().m_originalContent.p,
        box.text().adjustedContentToRender.p != nil
          ? wk_interop.String_new_copy(box.text().adjustedContentToRender.p) : nil,
        box.text().hasHyphen) : nil
    var positionWithinInlineLevelBox = InlineDisplay.Box.PositionWithinInlineLevelBox()
    if box.isFirstForLayoutBox {
      positionWithinInlineLevelBox = positionWithinInlineLevelBox.union(
        InlineDisplay.Box.PositionWithinInlineLevelBox.First)
    }
    if box.isLastForLayoutBox {
      positionWithinInlineLevelBox = positionWithinInlineLevelBox.union(
        InlineDisplay.Box.PositionWithinInlineLevelBox.Last)
    }
    let boxC = wk_interop.InlineDisplayBox_new(
      box.layoutBox.p,
      unflipped_visual_rect,
      ink_overflow,
      UInt64(box.lineIndex),
      expansionC,
      box.bidiLevel.rawValue,
      box.type.rawValue,
      box.hasContent,
      positionWithinInlineLevelBox.rawValue,
      box.isFullyTruncated,
      text
    )
    wk_interop.InlineLayoutResult_displayContent_addBox(layoutResultCPtr, boxC)
  }
  wk_interop.InlineLayoutResult_setRange(layoutResultCPtr, layoutResult.range.rawValue)
  wk_interop.InlineFormattingContext_setClearGapAfterLastLine(
    inlineFormattingContextCPtr,
    inlineFormattingContext.layoutState().clearGapAfterLastLine)
  return LayoutRectRaw(
    x: repaintRect.x().rawValue(), y: repaintRect.y().rawValue(),
    width: repaintRect.width().rawValue(),
    height: repaintRect.height().rawValue())
}

// TODO(asuhan): support multiple LineLayout instances
var globalLineLayout: LayoutIntegration.LineLayout? = nil

@_cdecl("LineLayoutScion_create")
func LineLayoutScion_create(flow: UnsafeMutableRawPointer) -> UInt64 {
  globalLineLayout = LayoutIntegration.LineLayout(flow: RenderBlockFlowWrapper(p: flow))
  return 0
}

@_cdecl("LineLayoutScion_updateFormattingContexGeometries")
func LineLayoutScion_updateFormattingContexGeometries(
  handle: UInt64, rawAvailableLogicalWidth: Int32
) {
  globalLineLayout!.updateFormattingContexGeometries(
    availableLogicalWidth: LayoutUnit.fromRawValue(value: rawAvailableLogicalWidth))
}

@_cdecl("LineLayoutScion_collectOverflow")
func LineLayoutScion_collectOverflow(handle: UInt64) {
  globalLineLayout!.collectOverflow()
}

@_cdecl("LineLayoutScion_layout")
func LineLayoutScion_layout(handle: UInt64) -> OptionalLayoutRectRaw {
  if let layoutResultRect = globalLineLayout!.layout() {
    return OptionalLayoutRectRaw(
      rect: LayoutRectRaw(
        x: layoutResultRect.x().rawValue(), y: layoutResultRect.y().rawValue(),
        width: layoutResultRect.width().rawValue(), height: layoutResultRect.height().rawValue()),
      is_valid: true)
  }
  return OptionalLayoutRectRaw(
    rect: LayoutRectRaw(x: 0, y: 0, width: 0, height: 0), is_valid: false)
}

@_cdecl("LineLayoutScion_contentBoxLogicalHeightRaw")
func LineLayoutScion_contentBoxLogicalHeightRaw(handle: UInt64) -> Int32 {
  let height = globalLineLayout!.contentBoxLogicalHeight()
  return height.rawValue()
}

@_cdecl("LineLayoutScion_lineCount")
func LineLayoutScion_lineCount(handle: UInt64) -> UInt64 {
  return globalLineLayout!.lineCount()
}

@_cdecl("LineLayoutScion_hasDetachedContent")
func LineLayoutScion_hasDetachedContent(handle: UInt64) -> Bool {
  return globalLineLayout!.hasDetachedContent()
}

@_cdecl("LineLayoutScion_paint")
func LineLayoutScion_paint(
  handle: UInt64, paintInfoRaw: UnsafeMutableRawPointer, paintOffset: LayoutPointRaw,
  layerRendererRaw: UnsafeMutableRawPointer?
) {
  let paintInfo = PaintInfoWrapper(p: paintInfoRaw)
  let paintOffset = LayoutPointWrapper(
    x: LayoutUnit.fromRawValue(value: paintOffset.x),
    y: LayoutUnit.fromRawValue(value: paintOffset.y))
  let layerRenderer = layerRendererRaw != nil ? RenderInlineWrapper(p: layerRendererRaw!) : nil
  globalLineLayout!.paint(
    paintInfo: paintInfo, paintOffset: paintOffset, layerRenderer: layerRenderer)
}
