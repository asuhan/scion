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
  let blockFormattingContextRoot = ElementBoxWrapper(wrapperStyle: style)
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
  let rootLayoutBox = ElementBoxWrapper(wrapperStyle: style)
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
    defer { wk_interop.FloatRect_destroy(line_box_rect) }
    let line_box_logical_rect = wk_interop.FloatRect_new(
      line.lineBoxLogicalRect.x(), line.lineBoxLogicalRect.y(), line.lineBoxLogicalRect.width(),
      line.lineBoxLogicalRect.height())
    defer { wk_interop.FloatRect_destroy(line_box_logical_rect) }
    let scrollable_overflow = wk_interop.FloatRect_new(
      line.scrollableOverflow.x(), line.scrollableOverflow.y(), line.scrollableOverflow.width(),
      line.scrollableOverflow.height())
    defer { wk_interop.FloatRect_destroy(scrollable_overflow) }
    let content_overflow = wk_interop.FloatRect_new(
      line.contentOverflow.x(), line.contentOverflow.y(), line.contentOverflow.width(),
      line.contentOverflow.height())
    defer { wk_interop.FloatRect_destroy(content_overflow) }
    let ink_overflow = wk_interop.FloatRect_new(
      line.inkOverflow.x(), line.inkOverflow.y(), line.inkOverflow.width(),
      line.inkOverflow.height())
    defer { wk_interop.FloatRect_destroy(ink_overflow) }
    let enclosing_logical_top_and_bottom = wk_interop.EnclosingTopAndBottom_new(
      line.enclosingLogicalTopAndBottom.top, line.enclosingLogicalTopAndBottom.bottom)
    defer { wk_interop.EnclosingTopAndBottom_destroy(enclosing_logical_top_and_bottom) }
    var ellipsisC: UnsafeRawPointer? = nil
    defer { if ellipsisC != nil { wk_interop.Ellipsis_destroy(ellipsisC!) } }
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
    defer { wk_interop.FloatRect_destroy(unflipped_visual_rect) }
    let ink_overflow = wk_interop.FloatRect_new(
      box.inkOverflow.x(), box.inkOverflow.y(), box.inkOverflow.width(), box.inkOverflow.height())
    defer { wk_interop.FloatRect_destroy(ink_overflow) }
    let expansion = box.expansion()
    let expansionC = wk_interop.Expansion_new(
      expansion.behavior.left.rawValue, expansion.behavior.right.rawValue,
      expansion.horizontalExpansion)
    defer { Expansion_destroy(expansionC) }
    let text =
      box.isTextOrSoftLineBreak()
      ? wk_interop.Text_new(
        UInt64(box.text().start), UInt64(box.text().length),
        box.text().partiallyVisibleContentLength,
        box.text().hasPartiallyVisibleContentLength, box.text().m_originalContent.p,
        wk_interop.String_new_copy(box.text().adjustedContentToRender.p),
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
    defer { wk_interop.InlineDisplayBox_destroy(boxC) }
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
  let rootLayoutBox = ElementBoxWrapper(wrapperStyle: style)
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
    defer { wk_interop.FloatRect_destroy(line_box_rect) }
    let line_box_logical_rect = wk_interop.FloatRect_new(
      line.lineBoxLogicalRect.x(), line.lineBoxLogicalRect.y(), line.lineBoxLogicalRect.width(),
      line.lineBoxLogicalRect.height())
    defer { wk_interop.FloatRect_destroy(line_box_logical_rect) }
    let scrollable_overflow = wk_interop.FloatRect_new(
      line.scrollableOverflow.x(), line.scrollableOverflow.y(), line.scrollableOverflow.width(),
      line.scrollableOverflow.height())
    defer { wk_interop.FloatRect_destroy(scrollable_overflow) }
    let content_overflow = wk_interop.FloatRect_new(
      line.contentOverflow.x(), line.contentOverflow.y(), line.contentOverflow.width(),
      line.contentOverflow.height())
    defer { wk_interop.FloatRect_destroy(content_overflow) }
    let ink_overflow = wk_interop.FloatRect_new(
      line.inkOverflow.x(), line.inkOverflow.y(), line.inkOverflow.width(),
      line.inkOverflow.height())
    defer { wk_interop.FloatRect_destroy(ink_overflow) }
    let enclosing_logical_top_and_bottom = wk_interop.EnclosingTopAndBottom_new(
      line.enclosingLogicalTopAndBottom.top, line.enclosingLogicalTopAndBottom.bottom)
    defer { wk_interop.EnclosingTopAndBottom_destroy(enclosing_logical_top_and_bottom) }
    var ellipsisC: UnsafeRawPointer? = nil
    defer { if ellipsisC != nil { wk_interop.Ellipsis_destroy(ellipsisC!) } }
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
    defer { wk_interop.FloatRect_destroy(unflipped_visual_rect) }
    let ink_overflow = wk_interop.FloatRect_new(
      box.inkOverflow.x(), box.inkOverflow.y(), box.inkOverflow.width(), box.inkOverflow.height())
    defer { wk_interop.FloatRect_destroy(ink_overflow) }
    let expansion = box.expansion()
    let expansionC = wk_interop.Expansion_new(
      expansion.behavior.left.rawValue, expansion.behavior.right.rawValue,
      expansion.horizontalExpansion)
    defer { Expansion_destroy(expansionC) }
    let text =
      box.isTextOrSoftLineBreak()
      ? wk_interop.Text_new(
        UInt64(box.text().start), UInt64(box.text().length),
        box.text().partiallyVisibleContentLength,
        box.text().hasPartiallyVisibleContentLength, box.text().m_originalContent.p,
        wk_interop.String_new_copy(box.text().adjustedContentToRender.p),
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
    defer { wk_interop.InlineDisplayBox_destroy(boxC) }
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

func convertLayoutPointRaw(_ point: LayoutPointRaw) -> LayoutPointWrapper {
  return LayoutPointWrapper(
    x: LayoutUnit.fromRawValue(value: point.x),
    y: LayoutUnit.fromRawValue(value: point.y))
}

@_cdecl("LineLayoutScion_paint")
func LineLayoutScion_paint(
  handle: UInt64, paintInfoRaw: UnsafeMutableRawPointer, paintInfoRawVal: PaintInfoRaw,
  paintOffset: LayoutPointRaw,
  layerRendererRaw: UnsafeMutableRawPointer?
) {
  let paintInfo = PaintInfoWrapper(p: paintInfoRaw)
  let paintOffset = convertLayoutPointRaw(paintOffset)
  let layerRenderer = layerRendererRaw != nil ? RenderInlineWrapper(p: layerRendererRaw!) : nil
  globalLineLayout!.paint(
    paintInfo: paintInfo, paintOffset: paintOffset, layerRenderer: layerRenderer)
}

@_cdecl("RepaintRegionAccumulator_create")
func RepaintRegionAccumulator_create(_ viewRaw: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer
{
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let repaintRegionAccumulator = RenderViewWrapper.RepaintRegionAccumulator(view)
  let unmanaged = Unmanaged.passRetained(repaintRegionAccumulator)
  return unmanaged.toOpaque()
}

@_cdecl("RepaintRegionAccumulator_destroy")
func RepaintRegionAccumulator_destroy(_ repaintRegionAccumulatorRaw: UnsafeMutableRawPointer) {
  let repaintRegionAccumulator = Unmanaged<RenderViewWrapper.RepaintRegionAccumulator>.fromOpaque(
    repaintRegionAccumulatorRaw
  ).takeUnretainedValue()
  repaintRegionAccumulator.destroy()
}

@_cdecl("RenderViewScion_create")
func RenderViewScion_create(_ documentRaw: UnsafeMutableRawPointer, _ styleRaw: UnsafeRawPointer)
  -> UnsafeMutableRawPointer
{
  let document = Document(documentRaw)
  let style = RenderStyleWrapper()
  style.p = styleRaw
  style.pOwner = true
  let renderView = RenderViewWrapper(document, style)
  let unmanaged = Unmanaged.passUnretained(renderView)
  return unmanaged.toOpaque()
}

func convertLayoutRect(_ raw: LayoutRectRaw) -> LayoutRectWrapper {
  return LayoutRectWrapper(
    x: LayoutUnit.fromRawValue(value: raw.x), y: LayoutUnit.fromRawValue(value: raw.y),
    width: LayoutUnit.fromRawValue(value: raw.width),
    height: LayoutUnit.fromRawValue(value: raw.height))
}

func convertLayoutRect(_ r: LayoutRectWrapper) -> LayoutRectRaw {
  return LayoutRectRaw(
    x: r.x().rawValue(), y: r.y().rawValue(), width: r.width().rawValue(),
    height: r.height().rawValue())
}

private func convertRepaintRects(_ raw: RepaintRectsRaw) -> RenderObjectWrapper.RepaintRects {
  return RenderObjectWrapper.RepaintRects(
    rect: convertLayoutRect(raw.clippedOverflowRect),
    outlineBounds: raw.outlineBoundsRect.is_valid
      ? convertLayoutRect(raw.outlineBoundsRect.rect) : nil)
}

private func convertRepaintRects(_ rects: RenderObjectWrapper.RepaintRects) -> RepaintRectsRaw {
  let clippedOverflowRect = convertLayoutRect(rects.clippedOverflowRect)
  let emptyRect = LayoutRectRaw(x: 0, y: 0, width: 0, height: 0)
  let outlineBoundsRect = OptionalLayoutRectRaw(
    rect: rects.outlineBoundsRect != nil ? convertLayoutRect(rects.outlineBoundsRect!) : emptyRect,
    is_valid: rects.outlineBoundsRect != nil)
  return RepaintRectsRaw(
    clippedOverflowRect: clippedOverflowRect, outlineBoundsRect: outlineBoundsRect)
}

private func convertVisibleRectContext(_ raw: VisibleRectContextRaw)
  -> RenderObjectWrapper.VisibleRectContext
{
  var context = RenderObjectWrapper.VisibleRectContext(
    hasPositionFixedDescendant: raw.hasPositionFixedDescendant,
    dirtyRectIsFlipped: raw.dirtyRectIsFlipped,
    RenderObjectWrapper.VisibleRectContextOption(rawValue: raw.options))
  context.descendantNeedsEnclosingIntRect = raw.descendantNeedsEnclosingIntRect
  return context
}

@_cdecl("RenderViewScion_computeVisibleRectsInContainer")
func RenderViewScion_computeVisibleRectsInContainer(
  _ viewRaw: UnsafeRawPointer, _ rectsRaw: RepaintRectsRaw, _ containerRaw: UnsafeRawPointer?,
  _ contextRaw: VisibleRectContextRaw
) -> OptionalRepaintRectsRaw {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let rects = convertRepaintRects(rectsRaw)
  let container = Unmanaged<RenderLayerModelObjectWrapper>.fromOpaque(containerRaw!)
    .takeUnretainedValue()
  let context = convertVisibleRectContext(contextRaw)
  if let repaintRects = view.computeVisibleRectsInContainer(rects, container, context) {
    return OptionalRepaintRectsRaw(rects: convertRepaintRects(repaintRects), is_valid: true)
  }
  let emptyRect = LayoutRectRaw(x: 0, y: 0, width: 0, height: 0)
  let emptyRepaintRects = RepaintRectsRaw(
    clippedOverflowRect: emptyRect,
    outlineBoundsRect: OptionalLayoutRectRaw(rect: emptyRect, is_valid: false))
  return OptionalRepaintRectsRaw(rects: emptyRepaintRects, is_valid: false)
}

@_cdecl("RenderViewScion_selection")
func RenderViewScion_selection(_ viewRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.selection().interop()
}

@_cdecl("RenderViewScion_printing")
func RenderViewScion_printing(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.printing()
}

@_cdecl("RenderViewScion_pageOrViewLogicalHeight")
func RenderViewScion_pageOrViewLogicalHeight(_ viewRaw: UnsafeRawPointer) -> Int32 {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.pageOrViewLogicalHeight().rawValue()
}

@_cdecl("RenderViewScion_requiresLayer")
func RenderViewScion_requiresLayer(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.requiresLayer()
}

@_cdecl("RenderViewScion_isChildAllowed")
func RenderViewScion_isChildAllowed(
  _ viewRaw: UnsafeRawPointer, _ childRaw: UnsafeMutableRawPointer, _ styleRaw: UnsafeRawPointer
) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let style = RenderStyleWrapper()
  style.p = styleRaw
  return view.isChildAllowed(RenderObjectWrapper(p: childRaw), style)
}

@_cdecl("RenderViewScion_layout")
func RenderViewScion_layout(_ viewRaw: UnsafeRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.layout()
}

@_cdecl("RenderViewScion_updateLogicalWidth")
func RenderViewScion_updateLogicalWidth(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.updateLogicalWidth()
}

@_cdecl("RenderViewScion_computeLogicalHeight")
func RenderViewScion_computeLogicalHeight(
  _ viewRaw: UnsafeRawPointer, _ logicalHeightRaw: Int32, _ logicalTopRaw: Int32
) -> LogicalExtentComputedValuesRaw {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let e = view.computeLogicalHeight(
    logicalHeight: LayoutUnit.fromRawValue(value: logicalHeightRaw),
    logicalTop: LayoutUnit.fromRawValue(value: logicalTopRaw))
  return LogicalExtentComputedValuesRaw(
    extent: e.extent.rawValue(), position: e.extent.rawValue(),
    margins: ComputedMarginValuesRaw(
      before: e.margins.before.rawValue(), after: e.margins.after.rawValue(),
      start: e.margins.start.rawValue(), end: e.margins.end.rawValue()))
}

@_cdecl("RenderViewScion_viewHeight")
func RenderViewScion_viewHeight(_ viewRaw: UnsafeRawPointer) -> Int32 {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.viewHeight()
}

@_cdecl("RenderViewScion_viewWidth")
func RenderViewScion_viewWidth(_ viewRaw: UnsafeRawPointer) -> Int32 {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.viewWidth()
}

@_cdecl("RenderViewScion_viewLogicalWidth")
func RenderViewScion_viewLogicalWidth(_ viewRaw: UnsafeRawPointer) -> Int32 {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.viewLogicalWidth()
}

@_cdecl("RenderViewScion_viewLogicalHeight")
func RenderViewScion_viewLogicalHeight(_ viewRaw: UnsafeRawPointer) -> Int32 {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.viewLogicalHeight()
}

@_cdecl("RenderViewScion_frameView")
func RenderViewScion_frameView(_ viewRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.frameView().p
}

@_cdecl("RenderViewScion_initialContainingBlock")
func RenderViewScion_initialContainingBlock(_ viewRaw: UnsafeRawPointer) -> UnsafeRawPointer {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.initialContainingBlock().p!
}

@_cdecl("RenderViewScion_layoutState")
func RenderViewScion_layoutState(_ viewRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.layoutState().p!
}

@_cdecl("RenderViewScion_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly")
func RenderViewScion_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(
  _ viewRaw: UnsafeRawPointer
) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly()
}

@_cdecl("RenderViewScion_updateQuirksMode")
func RenderViewScion_updateQuirksMode(_ viewRaw: UnsafeRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.updateQuirksMode()
}

@_cdecl("RenderViewScion_needsEventRegionUpdateForNonCompositedFrame")
func RenderViewScion_needsEventRegionUpdateForNonCompositedFrame(_ viewRaw: UnsafeRawPointer)
  -> Bool
{
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.needsEventRegionUpdateForNonCompositedFrame()
}

@_cdecl("RenderViewScion_repaintRootContents")
func RenderViewScion_repaintRootContents(_ viewRaw: UnsafeRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.repaintRootContents()
}

@_cdecl("RenderViewScion_paint")
func RenderViewScion_paint(
  _ viewRaw: UnsafeMutableRawPointer, _ paintInfoRaw: UnsafeMutableRawPointer,
  _ paintOffset: LayoutPointRaw
) {
  var paintInfo = PaintInfoWrapper(p: paintInfoRaw)
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.paint(paintInfo: &paintInfo, paintOffset: convertLayoutPointRaw(paintOffset))
}

@_cdecl("RenderViewScion_rendererForRootBackground")
func RenderViewScion_rendererForRootBackground(_ viewRaw: UnsafeRawPointer)
  -> UnsafeMutableRawPointer?
{
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  guard let element = view.rendererForRootBackground() else { return nil }
  assert(!element.isNativeImpl())
  return element.id()
}

@_cdecl("RenderViewScion_printRect")
func RenderViewScion_printRect(_ viewRaw: UnsafeRawPointer) -> IntRectRaw {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let r = view.printRect()
  return IntRectRaw(
    location: IntPointRaw(x: r.location.x, y: r.location.y),
    size: IntSizeRaw(width: r.size.width, height: r.size.height))
}

@_cdecl("RenderViewScion_setIsInWindow")
func RenderViewScion_setIsInWindow(_ isInWindow: Bool, _ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.setIsInWindow(isInWindow)
}

@_cdecl("RenderViewScion_compositor")
func RenderViewScion_compositor(_ viewRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.compositor().interop()
}

@_cdecl("RenderViewScion_usesCompositing")
func RenderViewScion_usesCompositing(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.usesCompositing()
}

@_cdecl("RenderViewScion_unscaledDocumentRect")
func RenderViewScion_unscaledDocumentRect(_ viewRaw: UnsafeRawPointer) -> IntRectRaw {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let rect = view.unscaledDocumentRect()
  return IntRectRaw(
    location: IntPointRaw(x: rect.location.x, y: rect.location.y),
    size: IntSizeRaw(width: rect.size.width, height: rect.size.height))
}

@_cdecl("RenderViewScion_unextendedBackgroundRect")
func RenderViewScion_unextendedBackgroundRect(_ viewRaw: UnsafeRawPointer) -> LayoutRectRaw {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return convertLayoutRect(view.unextendedBackgroundRect())
}

@_cdecl("RenderViewScion_backgroundRect")
func RenderViewScion_backgroundRect(_ viewRaw: UnsafeRawPointer) -> LayoutRectRaw {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return convertLayoutRect(view.backgroundRect())
}

@_cdecl("RenderViewScion_documentRect")
func RenderViewScion_documentRect(_ viewRaw: UnsafeRawPointer) -> IntRectRaw {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let rect = view.documentRect()
  return IntRectRaw(
    location: IntPointRaw(x: rect.location.x, y: rect.location.y),
    size: IntSizeRaw(width: rect.size.width, height: rect.size.height))
}

@_cdecl("RenderViewScion_rootElementShouldPaintBaseBackground")
func RenderViewScion_rootElementShouldPaintBaseBackground(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.rootElementShouldPaintBaseBackground()
}

@_cdecl("RenderViewScion_shouldPaintBaseBackground")
func RenderViewScion_shouldPaintBaseBackground(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.shouldPaintBaseBackground()
}

@_cdecl("RenderViewScion_hasQuotesNeedingUpdate")
func RenderViewScion_hasQuotesNeedingUpdate(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.hasQuotesNeedingUpdate()
}

@_cdecl("RenderViewScion_hasRenderersWithOutline")
func RenderViewScion_hasRenderersWithOutline(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.hasRenderersWithOutline()
}

@_cdecl("RenderViewScion_hasSoftwareFilters")
func RenderViewScion_hasSoftwareFilters(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.hasSoftwareFilters()
}

@_cdecl("RenderViewScion_rendererCount")
func RenderViewScion_rendererCount(_ viewRaw: UnsafeRawPointer) -> UInt64 {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.rendererCount()
}

@_cdecl("RenderViewScion_didCreateRenderer")
func RenderViewScion_didCreateRenderer(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.didCreateRenderer()
}

@_cdecl("RenderViewScion_didDestroyRenderer")
func RenderViewScion_didDestroyRenderer(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.didDestroyRenderer()
}

func convertIntRect(_ r: IntRectRaw) -> IntRect {
  return IntRect(x: r.location.x, y: r.location.y, width: r.size.width, height: r.size.height)
}

@_cdecl("RenderViewScion_updateVisibleViewportRect")
func RenderViewScion_updateVisibleViewportRect(
  _ viewRaw: UnsafeRawPointer, _ visibleRectRaw: IntRectRaw
) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.updateVisibleViewportRect(convertIntRect(visibleRectRaw))
}

@_cdecl("RenderViewScion_resumePausedImageAnimationsIfNeeded")
func RenderViewScion_resumePausedImageAnimationsIfNeeded(
  _ viewRaw: UnsafeRawPointer, _ visibleRectRaw: IntRectRaw
) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.resumePausedImageAnimationsIfNeeded(convertIntRect(visibleRectRaw))
}

@_cdecl("RenderViewScion_takeStyleChangeLayerTreeMutationRoot")
func RenderViewScion_takeStyleChangeLayerTreeMutationRoot(_ viewRaw: UnsafeRawPointer)
  -> UnsafeMutableRawPointer?
{
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  guard let root = view.takeStyleChangeLayerTreeMutationRoot() else { return nil }
  assert(!root.isNativeImpl())
  return root.layerId()
}

@_cdecl("RenderViewScion_viewTransitionRoot")
func RenderViewScion_viewTransitionRoot(_ viewRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  guard let root = view.viewTransitionRoot() else { return nil }
  assert(!root.isNativeImpl())
  return root.id()
}

@_cdecl("RenderViewScion_styleDidChange")
func RenderViewScion_styleDidChange(
  _ viewRaw: UnsafeMutableRawPointer, _ diffRaw: UInt8, _ oldStyleRaw: UnsafeRawPointer?
) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let oldStyle = oldStyleRaw != nil ? convert_render_style(p: oldStyleRaw!) : nil
  view.styleDidChange(diff: StyleDifference(rawValue: diffRaw)!, oldStyle: oldStyle)
}

@_cdecl("RenderViewScion_mapLocalToContainer")
func RenderViewScion_mapLocalToContainer(
  _ viewRaw: UnsafeRawPointer, _ ancestorContainerRaw: UnsafeMutableRawPointer?,
  _ transformStateRaw: UnsafeMutableRawPointer, _ modeRaw: UInt8,
  _ wasFixed: UnsafeMutablePointer<Bool>?
) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let ancestorContainer =
    ancestorContainerRaw != nil ? RenderLayerModelObjectWrapper(p: ancestorContainerRaw!) : nil
  let transformState = TransformState(transformStateRaw)
  let mode = MapCoordinatesMode(rawValue: modeRaw)
  var wasFixedCopy: Bool? = wasFixed?.pointee
  view.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixedCopy)
}

@_cdecl("RenderViewScion_pushMappingToContainer")
func RenderViewScion_pushMappingToContainer(
  _ viewRaw: UnsafeRawPointer, _ ancestorToStopAtRaw: UnsafeRawPointer?,
  _ geometryMapRaw: UnsafeMutableRawPointer
) -> UnsafeRawPointer? {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let ancestorToStopAt =
    ancestorToStopAtRaw != nil
    ? Unmanaged<RenderLayerModelObjectWrapper>.fromOpaque(ancestorToStopAtRaw!)
      .takeUnretainedValue()
    : nil
  let renderObjectRaw = view.pushMappingToContainer(
    ancestorToStopAt, RenderGeometryMap(geometryMapRaw))
  assert(renderObjectRaw == nil)
  return nil
}

@_cdecl("RenderViewScion_requiresColumns")
func RenderViewScion_requiresColumns(_ viewRaw: UnsafeRawPointer, _ desiredColumnCount: Int32)
  -> Bool
{
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.requiresColumns(desiredColumnCount: desiredColumnCount)
}

@_cdecl("RenderViewScion_computeColumnCountAndWidth")
func RenderViewScion_computeColumnCountAndWidth(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.computeColumnCountAndWidth()
}

@_cdecl("RenderViewScion_updateInitialContainingBlockSize")
func RenderViewScion_updateInitialContainingBlockSize(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.updateInitialContainingBlockSize()
}

@_cdecl("RenderViewScion_shouldUsePrintingLayout")
func RenderViewScion_shouldUsePrintingLayout(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.shouldUsePrintingLayout()
}

@_cdecl("RenderViewScion_containerQueryBoxesIsEmpty")
func RenderViewScion_containerQueryBoxesIsEmpty(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.containerQueryBoxesIsEmpty()
}

@_cdecl("RenderViewScion_setWk")
func RenderViewScion_setWk(_ wk: UnsafeMutableRawPointer, _ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.setWk(wk)
}

@_cdecl("RenderLayerModelObjectNative_layer")
func RenderLayerModelObjectNative_layer(_ layerModelObjectRaw: UnsafeMutableRawPointer)
  -> UnsafeMutableRawPointer?
{
  let layerModelObject = Unmanaged<RenderLayerModelObjectWrapper>.fromOpaque(layerModelObjectRaw)
    .takeUnretainedValue()
  assert(layerModelObject.isNativeImpl())
  guard let layer = layerModelObject.layer() else { return nil }
  assert(!layer.isNativeImpl())
  return layer.layerId()
}

@_cdecl("RenderLayerModelObjectScion_shouldPlaceVerticalScrollbarOnLeft")
func RenderLayerModelObjectScion_shouldPlaceVerticalScrollbarOnLeft(
  _ layerModelObjectRaw: UnsafeMutableRawPointer
) -> Bool {
  let layerModelObject = Unmanaged<RenderLayerModelObjectWrapper>.fromOpaque(layerModelObjectRaw)
    .takeUnretainedValue()
  return layerModelObject.shouldPlaceVerticalScrollbarOnLeftForLayerModelObject()
}

@_cdecl("RenderObjectScion_enclosingLayer")
func RenderObjectScion_enclosingLayer(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  guard let layer = object.enclosingLayer() else { return nil }
  assert(!layer.isNativeImpl())
  return layer.layerId()
}

@_cdecl("RenderObjectScion_setChildrenInline")
func RenderObjectScion_setChildrenInline(_ objectRaw: UnsafeMutableRawPointer, _ b: Bool) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setChildrenInline(b: b)
}

@_cdecl("RenderObjectScion_hasLayer")
func RenderObjectScion_hasLayer(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.hasLayer()
}

@_cdecl("RenderObjectScion_needsLayout")
func RenderObjectScion_needsLayout(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.needsLayout()
}

@_cdecl("RenderObjectScion_setNormalChildNeedsLayoutBit")
func RenderObjectScion_setNormalChildNeedsLayoutBit(_ objectRaw: UnsafeMutableRawPointer, _ b: Bool)
{
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setNormalChildNeedsLayoutBit(b: b)
}

@_cdecl("RenderSelectionScion_create")
func RenderSelectionScion_create(_ viewRaw: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let renderSelection = RenderSelection(view)
  let unmanaged = Unmanaged.passRetained(renderSelection)
  return unmanaged.toOpaque()
}

@_cdecl("RenderElementScion_setStyle")
func RenderElementScion_setStyle(
  _ elementRaw: UnsafeMutableRawPointer, _ styleRaw: UnsafeRawPointer,
  _ minimalStyleDifferenceRaw: UInt8
) {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  let style = convert_render_style(p: styleRaw)
  style.p = styleRaw
  let minimalStyleDifferenceRaw = StyleDifference(rawValue: minimalStyleDifferenceRaw)!
  element.setStyle(style: style, minimalStyleDifference: minimalStyleDifferenceRaw)
}

@_cdecl("RenderElementScion_hasClipPath")
func RenderElementScion_hasClipPath(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasClipPath()
}

@_cdecl("RenderElementScion_hasFilter")
func RenderElementScion_hasFilter(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasFilter()
}

func createRenderObjectWrapper(_ p: UnsafeMutableRawPointer) -> RenderObjectWrapper {
  if wk_interop.RenderObject_isRenderBlockFlow(p) {
    return RenderBlockFlowWrapper(p: p)
  }
  if wk_interop.RenderObject_isRenderBlock(p) {
    return RenderBlockWrapper(p: p)
  }
  if wk_interop.RenderObject_isRenderBox(p) {
    return RenderBoxWrapper(p: p)
  }
  if wk_interop.RenderObject_isRenderElement(p) {
    return RenderElementWrapper(p: p)
  }
  return RenderObjectWrapper(p: p)
}

@_cdecl("RenderElementScion_attachRendererInternal")
func RenderElementScion_attachRendererInternal(
  _ elementRaw: UnsafeMutableRawPointer, _ childRaw: UnsafeMutableRawPointer,
  _ beforeChildRaw: UnsafeMutableRawPointer?
) {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  let child = createRenderObjectWrapper(childRaw)
  let beforeChild = beforeChildRaw != nil ? RenderObjectWrapper(p: beforeChildRaw!) : nil
  element.attachRendererInternal(child: child, beforeChild: beforeChild)
}

@_cdecl("RenderBoxModelObjectScion_continuation")
func RenderBoxModelObjectScion_continuation(_ boxModelObjectRaw: UnsafeRawPointer)
  -> UnsafeMutableRawPointer?
{
  let boxModelObject = Unmanaged<RenderBoxModelObjectWrapper>.fromOpaque(boxModelObjectRaw)
    .takeUnretainedValue()
  guard let continuation = boxModelObject.continuation() else { return nil }
  assert(!continuation.isNativeImpl())
  return continuation.id()
}

@_cdecl("RenderBoxScion_requiresLayerWithScrollableArea")
func RenderBoxScion_requiresLayerWithScrollableArea(_ boxRaw: UnsafeRawPointer) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.requiresLayerWithScrollableArea()
}

@_cdecl("RenderBoxScion_width")
func RenderBoxScion_width(_ boxRaw: UnsafeRawPointer) -> Int32 {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.width().rawValue()
}

@_cdecl("RenderBoxScion_location")
func RenderBoxScion_location(_ boxRaw: UnsafeRawPointer) -> LayoutPointRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let point = box.location()
  return LayoutPointRaw(x: point.x.rawValue(), y: point.y.rawValue())
}

@_cdecl("RenderBoxScion_size")
func RenderBoxScion_size(_ boxRaw: UnsafeRawPointer) -> LayoutSizeRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let layoutSize = box.size()
  return LayoutSizeRaw(width: layoutSize.width().rawValue(), height: layoutSize.height().rawValue())
}

@_cdecl("RenderBoxScion_frameRect")
func RenderBoxScion_frameRect(_ boxRaw: UnsafeRawPointer) -> LayoutRectRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return convertLayoutRect(box.frameRect())
}

@_cdecl("RenderBoxScion_layoutOverflowRect")
func RenderBoxScion_layoutOverflowRect(_ boxRaw: UnsafeRawPointer) -> LayoutRectRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return convertLayoutRect(box.layoutOverflowRect())
}

@_cdecl("RenderBoxScion_visualOverflowRect")
func RenderBoxScion_visualOverflowRect(_ boxRaw: UnsafeRawPointer) -> LayoutRectRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return convertLayoutRect(box.visualOverflowRect())
}

@_cdecl("RenderBoxScion_paddingBoxRectIncludingScrollbar")
func RenderBoxScion_paddingBoxRectIncludingScrollbar(_ boxRaw: UnsafeRawPointer) -> LayoutRectRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return convertLayoutRect(box.paddingBoxRectIncludingScrollbar())
}

@_cdecl("RenderBoxScion_localRectsForRepaint")
func RenderBoxScion_localRectsForRepaint(_ boxRaw: UnsafeRawPointer, _ repaintOutlineBounds: Bool)
  -> RepaintRectsRaw
{
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return convertRepaintRects(box.localRectsForRepaint(repaintOutlineBounds ? .Yes : .No))
}

@_cdecl("RenderBoxScion_availableLogicalWidth")
func RenderBoxScion_availableLogicalWidth(_ boxRaw: UnsafeRawPointer) -> Int32 {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.availableLogicalWidth().rawValue()
}

@_cdecl("RenderBoxScion_hasAutoScrollbar")
func RenderBoxScion_hasAutoScrollbar(_ boxRaw: UnsafeRawPointer, _ orientation: UInt8)
  -> Bool
{
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.hasAutoScrollbar(ScrollbarOrientation(rawValue: orientation)!)
}

@_cdecl("RenderBoxScion_hasAlwaysPresentScrollbar")
func RenderBoxScion_hasAlwaysPresentScrollbar(_ boxRaw: UnsafeRawPointer, _ orientation: UInt8)
  -> Bool
{
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.hasAlwaysPresentScrollbar(ScrollbarOrientation(rawValue: orientation)!)
}

@_cdecl("RenderBoxScion_scrollsOverflow")
func RenderBoxScion_scrollsOverflow(_ boxRaw: UnsafeRawPointer) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.scrollsOverflow()
}

@_cdecl("RenderBoxScion_isUnsplittableForPagination")
func RenderBoxScion_isUnsplittableForPagination(_ boxRaw: UnsafeRawPointer) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.isUnsplittableForPagination()
}

@_cdecl("RenderBoxScion_topLeftLocation")
func RenderBoxScion_topLeftLocation(_ boxRaw: UnsafeRawPointer) -> LayoutPointRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let point = box.topLeftLocation()
  return LayoutPointRaw(x: point.x.rawValue(), y: point.y.rawValue())
}

@_cdecl("RenderBoxScion_styleWillChange")
func RenderBoxScion_styleWillChange(
  _ boxRaw: UnsafeRawPointer, _ diffRaw: UInt8, _ newStyleRaw: UnsafeRawPointer
) {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let diff = StyleDifference(rawValue: diffRaw)!
  let newStyle = convert_render_style(p: newStyleRaw)
  box.styleWillChange(diff: diff, newStyle: newStyle)
}

@_cdecl("RenderBoxScion_willBeDestroyed")
func RenderBoxScion_willBeDestroyed(_ boxRaw: UnsafeMutableRawPointer) {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  box.willBeDestroyed()
}

@_cdecl("RenderBoxScion_shouldTrimChildMargin")
func RenderBoxScion_shouldTrimChildMargin(
  _ boxRaw: UnsafeRawPointer, _ typeRaw: UInt8, _ childRaw: UnsafeMutableRawPointer
) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let type = MarginTrimType(rawValue: typeRaw)
  let child = createRenderObjectWrapper(childRaw) as! RenderBoxWrapper
  return box.shouldTrimChildMarginForBox(type: type, child: child)
}

@_cdecl("RenderBlockFlowScion_willBeDestroyed")
func RenderBlockFlowScion_willBeDestroyed(_ blockFlowRaw: UnsafeMutableRawPointer) {
  let box = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockFlowRaw).takeUnretainedValue()
  box.willBeDestroyed()
}

@_cdecl("RenderBlockFlowScion_multiColumnFlow")
func RenderBlockFlowScion_multiColumnFlow(_ blockFlowRaw: UnsafeRawPointer)
  -> UnsafeMutableRawPointer?
{
  let blockFlow = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockFlowRaw).takeUnretainedValue()
  assert(blockFlow.multiColumnFlowForBlockFlow() == nil)
  return nil
}

@_cdecl("RenderBlockFlowScion_containsFloats")
func RenderBlockFlowScion_containsFloats(_ blockFlowRaw: UnsafeRawPointer) -> Bool {
  let blockFlow = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockFlowRaw).takeUnretainedValue()
  return blockFlow.containsFloats()
}

@_cdecl("RenderBlockFlowScion_deleteLines")
func RenderBlockFlowScion_deleteLines(_ blockFlowRaw: UnsafeMutableRawPointer) {
  let blockFlow = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockFlowRaw).takeUnretainedValue()
  blockFlow.deleteLines()
}

@_cdecl("RenderBlockFlowScion_setChildrenInline")
func RenderBlockFlowScion_setChildrenInline(_ blockFlowRaw: UnsafeMutableRawPointer, _ value: Bool)
{
  let blockFlow = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockFlowRaw).takeUnretainedValue()
  blockFlow.setChildrenInline(b: value)
}

@_cdecl("RenderBlockFlowScion_inlineLayout")
func RenderBlockFlowScion_inlineLayout(_ blockFlowRaw: UnsafeMutableRawPointer)
  -> UnsafeMutableRawPointer?
{
  let blockFlow = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockFlowRaw).takeUnretainedValue()
  assert(blockFlow.inlineLayout() == nil)
  return nil
}

@_cdecl("RenderBlockFlowScion_styleWillChange")
func RenderBlockFlowScion_styleWillChange(
  _ blockFlowRaw: UnsafeRawPointer, _ diffRaw: UInt8, _ newStyleRaw: UnsafeRawPointer
) {
  let blockFlow = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockFlowRaw).takeUnretainedValue()
  let diff = StyleDifference(rawValue: diffRaw)!
  let newStyle = convert_render_style(p: newStyleRaw)
  blockFlow.styleWillChange(diff: diff, newStyle: newStyle)
}

@_cdecl("RenderBlockScion_setMarginBeforeForChild")
func RenderBlockScion_setMarginBeforeForChild(
  _ blockRaw: UnsafeRawPointer, _ childRaw: UnsafeMutableRawPointer, _ valueRaw: Int32
) {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  block.setMarginBeforeForChild(
    child: createRenderObjectWrapper(childRaw) as! RenderBoxWrapper,
    value: LayoutUnit.fromRawValue(value: valueRaw))
}

@_cdecl("RenderBlockScion_setMarginAfterForChild")
func RenderBlockScion_setMarginAfterForChild(
  _ blockRaw: UnsafeRawPointer, _ childRaw: UnsafeMutableRawPointer, _ valueRaw: Int32
) {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  block.setMarginAfterForChild(
    child: createRenderObjectWrapper(childRaw) as! RenderBoxWrapper,
    value: LayoutUnit.fromRawValue(value: valueRaw))
}

@_cdecl("RenderBlockScion_canHaveChildren")
func RenderBlockScion_canHaveChildren(_ blockRaw: UnsafeRawPointer) -> Bool {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.canHaveChildren()
}

@_cdecl("RenderBlockScion_debugDescription")
func RenderBlockScion_debugDescription(_ blockRaw: UnsafeRawPointer) -> UnsafeRawPointer {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.debugDescription().p
}

@_cdecl("RenderBlockScion_isInlineBlockOrInlineTable")
func RenderBlockScion_isInlineBlockOrInlineTable(_ blockRaw: UnsafeRawPointer) -> Bool {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.isInlineBlockOrInlineTable()
}

@_cdecl("RenderBlockScion_outlineStyleForRepaint")
func RenderBlockScion_outlineStyleForRepaint(_ blockRaw: UnsafeRawPointer) -> UnsafeRawPointer {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.outlineStyleForRepaint().p!
}
