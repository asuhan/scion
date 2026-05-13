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
      ellipsisC = wk_interop.Ellipsis_new(
        ellipsis.type.rawValue, ellipsis.visualRect.x(),
        ellipsis.visualRect.y(), ellipsis.visualRect.width(),
        ellipsis.visualRect.height(), ellipsis.text.p!)
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
      ellipsisC = wk_interop.Ellipsis_new(
        ellipsis.type.rawValue, ellipsis.visualRect.x(),
        ellipsis.visualRect.y(), ellipsis.visualRect.width(),
        ellipsis.visualRect.height(), ellipsis.text.p!)
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
  let container =
    containerRaw != nil
    ? Unmanaged<RenderLayerModelObjectWrapper>.fromOpaque(containerRaw!).takeUnretainedValue() : nil
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

@_cdecl("RenderViewScion_availableLogicalHeight")
func RenderViewScion_availableLogicalHeight(
  _ viewRaw: UnsafeMutableRawPointer, _ includeMarginBorderPadding: Bool
) -> Int32 {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let availableLogicalHeight = view.availableLogicalHeight(
    heightType:
      includeMarginBorderPadding ? .IncludeMarginBorderPadding : .ExcludeMarginBorderPadding)
  return availableLogicalHeight.rawValue()
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
  return view.frameView().pInterop!
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

@_cdecl("RenderViewScion_repaintViewAndCompositedLayers")
func RenderViewScion_repaintViewAndCompositedLayers(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.repaintViewAndCompositedLayers()
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

@_cdecl("RenderViewScion_incrementRendersWithOutline")
func RenderViewScion_incrementRendersWithOutline(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.incrementRendersWithOutline()
}

@_cdecl("RenderViewScion_decrementRendersWithOutline")
func RenderViewScion_decrementRendersWithOutline(_ viewRaw: UnsafeMutableRawPointer) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  view.decrementRendersWithOutline()
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
    ancestorContainerRaw != nil
    ? createRenderObjectWrapperOrNative(ancestorContainerRaw!) as! RenderLayerModelObjectWrapper?
    : nil
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

@_cdecl("RenderViewScion_mapAbsoluteToLocalPoint")
func RenderViewScion_mapAbsoluteToLocalPoint(
  _ viewRaw: UnsafeRawPointer, _ modeRaw: UInt8, _ transformStateRaw: UnsafeMutableRawPointer
) {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let transformState = TransformState(transformStateRaw)
  let mode = MapCoordinatesMode(rawValue: modeRaw)
  view.mapAbsoluteToLocalPoint(mode, transformState)
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

@_cdecl("RenderViewScion_boxesWithScrollSnapPositionsIsEmpty")
func RenderViewScion_boxesWithScrollSnapPositionsIsEmpty(_ viewRaw: UnsafeRawPointer) -> Bool {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  return view.boxesWithScrollSnapPositionsIsEmpty()
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

@_cdecl("RenderObjectScion_parent")
func RenderObjectScion_parent(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  assert(object.parent() == nil)
  return nil
}

@_cdecl("RenderObjectScion_nextSibling")
func RenderObjectScion_nextSibling(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  assert(object.nextSibling() == nil)
  return nil
}

@_cdecl("RenderObjectScion_nextInPreOrderAfterChildren")
func RenderObjectScion_nextInPreOrderAfterChildren(_ objectRaw: UnsafeRawPointer)
  -> UnsafeMutableRawPointer?
{
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  assert(object.nextInPreOrderAfterChildren() == nil)
  return nil
}

@_cdecl("RenderObjectScion_enclosingLayer")
func RenderObjectScion_enclosingLayer(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  guard let layer = object.enclosingLayer() else { return nil }
  assert(!layer.isNativeImpl())
  return layer.layerId()
}

@_cdecl("RenderObjectScion_enclosingFragmentedFlow")
func RenderObjectScion_enclosingFragmentedFlow(_ objectRaw: UnsafeRawPointer)
  -> UnsafeMutableRawPointer?
{
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  assert(object.enclosingFragmentedFlow() == nil)
  return nil
}

@_cdecl("RenderObjectScion_isPseudoElement")
func RenderObjectScion_isPseudoElement(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isPseudoElement()
}

@_cdecl("RenderObjectScion_isRenderElement")
func RenderObjectScion_isRenderElement(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderElement()
}

@_cdecl("RenderObjectScion_isRenderBoxModelObject")
func RenderObjectScion_isRenderBoxModelObject(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderBoxModelObject()
}

@_cdecl("RenderObjectScion_isRenderBlock")
func RenderObjectScion_isRenderBlock(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderBlock()
}

@_cdecl("RenderObjectScion_isRenderBlockFlow")
func RenderObjectScion_isRenderBlockFlow(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderBlockFlow()
}

@_cdecl("RenderObjectScion_isRenderInline")
func RenderObjectScion_isRenderInline(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderInline()
}

@_cdecl("RenderObjectScion_isRenderLayerModelObject")
func RenderObjectScion_isRenderLayerModelObject(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderLayerModelObject()
}

@_cdecl("RenderObjectScion_isRenderDetailsMarker")
func RenderObjectScion_isRenderDetailsMarker(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderDetailsMarker()
}

@_cdecl("RenderObjectScion_isRenderEmbeddedObject")
func RenderObjectScion_isRenderEmbeddedObject(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderEmbeddedObject()
}

@_cdecl("RenderObjectScion_isFieldset")
func RenderObjectScion_isFieldset(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isFieldset()
}

@_cdecl("RenderObjectScion_isRenderFileUploadControl")
func RenderObjectScion_isRenderFileUploadControl(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderFileUploadControl()
}

@_cdecl("RenderObjectScion_isRenderListItem")
func RenderObjectScion_isRenderListItem(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderListItem()
}

@_cdecl("RenderObjectScion_isRenderListMarker")
func RenderObjectScion_isRenderListMarker(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderListMarker()
}

@_cdecl("RenderObjectScion_isRenderMedia")
func RenderObjectScion_isRenderMedia(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderMedia()
}

@_cdecl("RenderObjectScion_isRenderIFrame")
func RenderObjectScion_isRenderIFrame(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderIFrame()
}

@_cdecl("RenderObjectScion_isRenderImage")
func RenderObjectScion_isRenderImage(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderImage()
}

@_cdecl("RenderObjectScion_isRenderReplica")
func RenderObjectScion_isRenderReplica(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderReplica()
}

@_cdecl("RenderObjectScion_isRenderTable")
func RenderObjectScion_isRenderTable(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderTable()
}

@_cdecl("RenderObjectScion_isRenderTableCell")
func RenderObjectScion_isRenderTableCell(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderTableCell()
}

@_cdecl("RenderObjectScion_isRenderVideo")
func RenderObjectScion_isRenderVideo(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderVideo()
}

@_cdecl("RenderObjectScion_isRenderViewTransitionCapture")
func RenderObjectScion_isRenderViewTransitionCapture(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderViewTransitionCapture()
}

@_cdecl("RenderObjectScion_isRenderWidget")
func RenderObjectScion_isRenderWidget(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderWidget()
}

@_cdecl("RenderObjectScion_isRenderHTMLCanvas")
func RenderObjectScion_isRenderHTMLCanvas(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderHTMLCanvas()
}

@_cdecl("RenderObjectScion_isRenderGrid")
func RenderObjectScion_isRenderGrid(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderGrid()
}

@_cdecl("RenderObjectScion_isDocumentElementRenderer")
func RenderObjectScion_isDocumentElementRenderer(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isDocumentElementRenderer()
}

@_cdecl("RenderObjectScion_isBody")
func RenderObjectScion_isBody(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isBody()
}

@_cdecl("RenderObjectScion_isHTMLMarquee")
func RenderObjectScion_isHTMLMarquee(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isHTMLMarquee()
}

@_cdecl("RenderObjectScion_childrenInline")
func RenderObjectScion_childrenInline(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.childrenInline()
}

@_cdecl("RenderObjectScion_setChildrenInline")
func RenderObjectScion_setChildrenInline(_ objectRaw: UnsafeMutableRawPointer, _ b: Bool) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setChildrenInline(b: b)
}

@_cdecl("RenderObjectScion_fragmentedFlowState")
func RenderObjectScion_fragmentedFlowState(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.fragmentedFlowState() == .InsideFlow
}

@_cdecl("RenderObjectScion_isRenderSVGModelObject")
func RenderObjectScion_isRenderSVGModelObject(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderSVGModelObject()
}

@_cdecl("RenderObjectScion_isLegacyRenderSVGRoot")
func RenderObjectScion_isLegacyRenderSVGRoot(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isLegacyRenderSVGRoot()
}

@_cdecl("RenderObjectScion_isRenderSVGRoot")
func RenderObjectScion_isRenderSVGRoot(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderSVGRoot()
}

@_cdecl("RenderObjectScion_isRenderSVGContainer")
func RenderObjectScion_isRenderSVGContainer(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderSVGContainer()
}

@_cdecl("RenderObjectScion_isLegacyRenderSVGContainer")
func RenderObjectScion_isLegacyRenderSVGContainer(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isLegacyRenderSVGContainer()
}

@_cdecl("RenderObjectScion_isRenderSVGGradientStop")
func RenderObjectScion_isRenderSVGGradientStop(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderSVGGradientStop()
}

@_cdecl("RenderObjectScion_isLegacyRenderSVGHiddenContainer")
func RenderObjectScion_isLegacyRenderSVGHiddenContainer(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isLegacyRenderSVGHiddenContainer()
}

@_cdecl("RenderObjectScion_isRenderSVGHiddenContainer")
func RenderObjectScion_isRenderSVGHiddenContainer(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderSVGHiddenContainer()
}

@_cdecl("RenderObjectScion_isLegacyRenderSVGShape")
func RenderObjectScion_isLegacyRenderSVGShape(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isLegacyRenderSVGShape()
}

@_cdecl("RenderObjectScion_isRenderSVGText")
func RenderObjectScion_isRenderSVGText(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderSVGText()
}

@_cdecl("RenderObjectScion_isRenderSVGInlineText")
func RenderObjectScion_isRenderSVGInlineText(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderSVGInlineText()
}

@_cdecl("RenderObjectScion_isLegacyRenderSVGImage")
func RenderObjectScion_isLegacyRenderSVGImage(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isLegacyRenderSVGImage()
}

@_cdecl("RenderObjectScion_isLegacyRenderSVGResourceContainer")
func RenderObjectScion_isLegacyRenderSVGResourceContainer(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isLegacyRenderSVGResourceContainer()
}

@_cdecl("RenderObjectScion_isSVGLayerAwareRenderer")
func RenderObjectScion_isSVGLayerAwareRenderer(_ objectRaw: UnsafeMutableRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isSVGLayerAwareRenderer()
}

@_cdecl("RenderObjectScion_isSVGRenderer")
func RenderObjectScion_isSVGRenderer(_ objectRaw: UnsafeMutableRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isSVGRenderer()
}

@_cdecl("RenderObjectScion_isAnonymous")
func RenderObjectScion_isAnonymous(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isAnonymous()
}

@_cdecl("RenderObjectScion_isAnonymousBlock")
func RenderObjectScion_isAnonymousBlock(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isAnonymousBlock()
}

@_cdecl("RenderObjectScion_isPositioned")
func RenderObjectScion_isPositioned(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isPositioned()
}

@_cdecl("RenderObjectScion_isInFlowPositioned")
func RenderObjectScion_isInFlowPositioned(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isInFlowPositioned()
}

@_cdecl("RenderObjectScion_isOutOfFlowPositioned")
func RenderObjectScion_isOutOfFlowPositioned(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isOutOfFlowPositioned()
}

@_cdecl("RenderObjectScion_isFixedPositioned")
func RenderObjectScion_isFixedPositioned(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isFixedPositioned()
}

@_cdecl("RenderObjectScion_isStickilyPositioned")
func RenderObjectScion_isStickilyPositioned(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isStickilyPositioned()
}

@_cdecl("RenderObjectScion_isRenderText")
func RenderObjectScion_isRenderText(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderText()
}

@_cdecl("RenderObjectScion_isRenderLineBreak")
func RenderObjectScion_isRenderLineBreak(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderLineBreak()
}

@_cdecl("RenderObjectScion_isBR")
func RenderObjectScion_isBR(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isBR()
}

@_cdecl("RenderObjectScion_isRenderBox")
func RenderObjectScion_isRenderBox(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderBox()
}

@_cdecl("RenderObjectScion_isRenderTableRow")
func RenderObjectScion_isRenderTableRow(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderTableRow()
}

@_cdecl("RenderObjectScion_isRenderView")
func RenderObjectScion_isRenderView(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderView()
}

@_cdecl("RenderObjectScion_isInline")
func RenderObjectScion_isInline(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isInline()
}

@_cdecl("RenderObjectScion_isHorizontalWritingMode")
func RenderObjectScion_isHorizontalWritingMode(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isHorizontalWritingMode()
}

@_cdecl("RenderObjectScion_hasReflection")
func RenderObjectScion_hasReflection(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.hasReflection()
}

@_cdecl("RenderObjectScion_isRenderFragmentedFlow")
func RenderObjectScion_isRenderFragmentedFlow(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderFragmentedFlow()
}

@_cdecl("RenderObjectScion_hasOutlineAutoAncestor")
func RenderObjectScion_hasOutlineAutoAncestor(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.hasOutlineAutoAncestor()
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

@_cdecl("RenderObjectScion_selfNeedsLayout")
func RenderObjectScion_selfNeedsLayout(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.selfNeedsLayout()
}

@_cdecl("RenderObjectScion_needsPositionedMovementLayout")
func RenderObjectScion_needsPositionedMovementLayout(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.needsPositionedMovementLayout()
}

@_cdecl("RenderObjectScion_posChildNeedsLayout")
func RenderObjectScion_posChildNeedsLayout(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.posChildNeedsLayout()
}

@_cdecl("RenderObjectScion_needsSimplifiedNormalFlowLayout")
func RenderObjectScion_needsSimplifiedNormalFlowLayout(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.needsSimplifiedNormalFlowLayout()
}

@_cdecl("RenderObjectScion_needsSimplifiedNormalFlowLayoutOnly")
func RenderObjectScion_needsSimplifiedNormalFlowLayoutOnly(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.needsSimplifiedNormalFlowLayoutOnly()
}

@_cdecl("RenderObjectScion_normalChildNeedsLayout")
func RenderObjectScion_normalChildNeedsLayout(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.normalChildNeedsLayout()
}

@_cdecl("RenderObjectScion_preferredLogicalWidthsDirty")
func RenderObjectScion_preferredLogicalWidthsDirty(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.preferredLogicalWidthsDirty()
}

@_cdecl("RenderObjectScion_hasNonVisibleOverflow")
func RenderObjectScion_hasNonVisibleOverflow(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.hasNonVisibleOverflow()
}

@_cdecl("RenderObjectScion_hasPotentiallyScrollableOverflow")
func RenderObjectScion_hasPotentiallyScrollableOverflow(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.hasPotentiallyScrollableOverflow()
}

@_cdecl("RenderObjectScion_hasTransformRelatedProperty")
func RenderObjectScion_hasTransformRelatedProperty(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.hasTransformRelatedProperty()
}

@_cdecl("RenderObjectScion_isTransformed")
func RenderObjectScion_isTransformed(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isTransformed()
}

@_cdecl("RenderObjectScion_hasTransformOrPerspective")
func RenderObjectScion_hasTransformOrPerspective(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.hasTransformOrPerspective()
}

@_cdecl("RenderObjectScion_capturedInViewTransition")
func RenderObjectScion_capturedInViewTransition(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.capturedInViewTransition()
}

@_cdecl("RenderObjectScion_effectiveCapturedInViewTransition")
func RenderObjectScion_effectiveCapturedInViewTransition(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.effectiveCapturedInViewTransition()
}

@_cdecl("RenderObjectScion_view")
func RenderObjectScion_view(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  let view = object.view()
  return view.getWk()
}

@_cdecl("RenderObjectScion_node")
func RenderObjectScion_node(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  guard let node = object.node() else { return nil }
  return node.p
}

@_cdecl("RenderObjectScion_document")
func RenderObjectScion_document(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.document().p
}

@_cdecl("RenderObjectScion_frame")
func RenderObjectScion_frame(_ objectRaw: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.frame().p
}

@_cdecl("RenderObjectScion_page")
func RenderObjectScion_page(_ objectRaw: UnsafeRawPointer) -> UnsafeRawPointer {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.page().p
}

@_cdecl("RenderObjectScion_settings")
func RenderObjectScion_settings(_ objectRaw: UnsafeRawPointer) -> UnsafeRawPointer {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.settings().p
}

@_cdecl("RenderObjectScion_container")
func RenderObjectScion_container(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  assert(object.container() == nil)
  return nil
}

@_cdecl("RenderObjectScion_setNeedsLayout")
func RenderObjectScion_setNeedsLayout(_ objectRaw: UnsafeMutableRawPointer, _ markParents: Bool) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setNeedsLayout(markParents: markParents ? .MarkContainingBlockChain : .MarkOnlyThis)
}

@_cdecl("RenderObjectScion_setPreferredLogicalWidthsDirty")
func RenderObjectScion_setPreferredLogicalWidthsDirty(
  _ objectRaw: UnsafeMutableRawPointer, _ shouldBeDirty: Bool, _ markParents: Bool
) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setPreferredLogicalWidthsDirty(
    shouldBeDirty: shouldBeDirty,
    markParents: markParents ? .MarkContainingBlockChain : .MarkOnlyThis)
}

@_cdecl("RenderObjectScion_invalidateBackgroundObscurationStatus")
func RenderObjectScion_invalidateBackgroundObscurationStatus(_ objectRaw: UnsafeMutableRawPointer) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.invalidateBackgroundObscurationStatus()
}

@_cdecl("RenderObjectScion_isComposited")
func RenderObjectScion_isComposited(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isComposited()
}

private func convertHitTestRequest(_ raw: HitTestRequestRaw) -> HitTestRequestWrapper {
  return HitTestRequestWrapper(
    raw.source ? .User : .Script, HitTestRequestWrapper.Type_(rawValue: raw.type))
}

private func convertHitTestLocation(_ r: HitTestLocationRaw) -> HitTestLocationWrapper {
  return HitTestLocationWrapper(
    convertLayoutPointRaw(r.point),
    convertLayoutRect(r.boundingBox),
    convertFloatPoint(r.transformedPoint),
    convertFloatQuad(r.transformedRect),
    isRectBased: r.isRectBased,
    isRectilinear: r.isRectilinear)
}

private func convertHitTestResult(_ raw: HitTestResultRaw) -> HitTestResultWrapper {
  return HitTestResultWrapper(
    convertHitTestLocation(raw.hitTestLocation),
    raw.innerNode != nil ? NodeWrapper(p: raw.innerNode!) : nil,
    raw.innerNonSharedNode != nil ? NodeWrapper(p: raw.innerNonSharedNode!) : nil,
    convertLayoutPointRaw(raw.localPoint))
}

private func convertLayoutPoint(_ p: LayoutPointWrapper) -> LayoutPointRaw {
  return LayoutPointRaw(x: p.x.rawValue(), y: p.y.rawValue())
}

private func convertFloatPoint(_ p: FloatPoint) -> FloatPointRaw {
  return FloatPointRaw(x: p.x, y: p.y)
}

private func convertFloatQuad(_ q: FloatQuad) -> FloatQuadRaw {
  return FloatQuadRaw(
    p1: convertFloatPoint(q.p1()), p2: convertFloatPoint(q.p2()), p3: convertFloatPoint(q.p3()),
    p4: convertFloatPoint(q.p4()))
}

private func convertHitTestLocation(_ r: HitTestLocationWrapper) -> HitTestLocationRaw {
  return HitTestLocationRaw(
    point: convertLayoutPoint(r.point()),
    boundingBox: convertLayoutRect(r.boundingBox()),
    transformedPoint: convertFloatPoint(r.transformedPoint()),
    transformedRect: convertFloatQuad(r.transformedRect()),
    isRectBased: r.isRectBasedTest(),
    isRectilinear: r.isRectilinear())
}

@_cdecl("RenderObjectScion_hitTest")
func RenderObjectScion_hitTest(
  _ objectRaw: UnsafeMutableRawPointer, _ requestRaw: HitTestRequestRaw,
  _ resultRaw: UnsafeMutablePointer<HitTestResultRaw>, _ locationInContainerRaw: HitTestLocationRaw,
  _ accumulatedOffsetRaw: LayoutPointRaw, _ hitTestFilterRaw: UInt8
)
  -> Bool
{
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  let request = convertHitTestRequest(requestRaw)
  var result = convertHitTestResult(resultRaw.pointee)
  let locationInContainer = convertHitTestLocation(locationInContainerRaw)
  let accumulatedOffset = convertLayoutPointRaw(accumulatedOffsetRaw)
  let hitTestFilter = HitTestFilter(rawValue: hitTestFilterRaw)!
  let testResult = object.hitTest(
    request, &result, locationInContainer, accumulatedOffset, hitTestFilter)
  resultRaw.pointee.hitTestLocation = convertHitTestLocation(result.hitTestLocation)
  resultRaw.pointee.innerNode = result.innerNode()?.p
  resultRaw.pointee.innerNonSharedNode = result.innerNonSharedNode()?.p
  resultRaw.pointee.localPoint = convertLayoutPoint(result.localPoint)
  return testResult
}

@_cdecl("RenderObjectScion_containingBlock")
func RenderObjectScion_containingBlock(_ objectRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  assert(object.containingBlock() == nil)
  return nil
}

@_cdecl("RenderObjectScion_style")
func RenderObjectScion_style(_ objectRaw: UnsafeRawPointer) -> UnsafeRawPointer {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.style().p!
}

@_cdecl("RenderObjectScion_containerForRepaint")
func RenderObjectScion_containerForRepaint(_ objectRaw: UnsafeRawPointer)
  -> RepaintContainerStatusRaw
{
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  let r = object.containerForRepaint()
  let renderer =
    (r.renderer?.isNativeImpl() ?? false)
    ? (r.renderer! as! RenderViewWrapper).getWk() : r.renderer?.id()
  return RepaintContainerStatusRaw(
    fullRepaintIsScheduled: r.fullRepaintIsScheduled, renderer: renderer)
}

func createRenderObjectWrapperOrNative(_ raw: UnsafeMutableRawPointer)
  -> RenderObjectWrapper
{
  if wk_interop.RenderObject_isRenderView(raw), let viewRaw = wk_interop.RenderView_scion(raw) {
    return Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  }
  return createRenderObjectWrapper(raw)
}

@_cdecl("RenderObjectScion_repaintUsingContainer")
func RenderObjectScion_repaintUsingContainer(
  _ objectRaw: UnsafeMutableRawPointer, _ repaintContainer: UnsafeMutableRawPointer,
  _ r: LayoutRectRaw,
  _ shouldClipToLayer: Bool
) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.repaintUsingContainer(
    createRenderObjectWrapperOrNative(repaintContainer) as! RenderLayerModelObjectWrapper?,
    convertLayoutRect(r), shouldClipToLayer)
}

@_cdecl("RenderObjectScion_clippedOverflowRectForRepaint")
func RenderObjectScion_clippedOverflowRectForRepaint(
  _ objectRaw: UnsafeRawPointer, _ repaintContainerRaw: UnsafeMutableRawPointer?
) -> LayoutRectRaw {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return convertLayoutRect(
    object.clippedOverflowRectForRepaint(
      createRenderObjectWrapperOrNative(repaintContainerRaw!) as! RenderLayerModelObjectWrapper?))
}

@_cdecl("RenderObjectScion_rectsForRepaintingAfterLayout")
func RenderObjectScion_rectsForRepaintingAfterLayout(
  _ objectRaw: UnsafeRawPointer, _ repaintContainerRaw: UnsafeMutableRawPointer?,
  _ repaintOutlineBounds: Bool
) -> RepaintRectsRaw {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  let repaintContainer =
    repaintContainerRaw != nil
    ? createRenderObjectWrapperOrNative(repaintContainerRaw!) as! RenderLayerModelObjectWrapper?
    : nil
  return convertRepaintRects(
    object.rectsForRepaintingAfterLayout(repaintContainer, repaintOutlineBounds ? .Yes : .No))
}

@_cdecl("RenderObjectScion_isFloatingOrOutOfFlowPositioned")
func RenderObjectScion_isFloatingOrOutOfFlowPositioned(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isFloatingOrOutOfFlowPositioned()
}

@_cdecl("RenderObjectScion_renderTreeBeingDestroyed")
func RenderObjectScion_renderTreeBeingDestroyed(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.renderTreeBeingDestroyed()
}

@_cdecl("RenderObjectScion_destroy")
func RenderObjectScion_destroy(_ objectRaw: UnsafeMutableRawPointer) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.destroy()
}

@_cdecl("RenderObjectScion_isRenderDeprecatedFlexibleBox")
func RenderObjectScion_isRenderDeprecatedFlexibleBox(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderDeprecatedFlexibleBox()
}

@_cdecl("RenderObjectScion_isRenderFlexibleBox")
func RenderObjectScion_isRenderFlexibleBox(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isRenderFlexibleBox()
}

@_cdecl("RenderObjectScion_isFlexibleBoxIncludingDeprecated")
func RenderObjectScion_isFlexibleBoxIncludingDeprecated(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isFlexibleBoxIncludingDeprecated()
}

@_cdecl("RenderObjectScion_isSkippedContent")
func RenderObjectScion_isSkippedContent(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isSkippedContent()
}

@_cdecl("RenderObjectScion_usedPointerEvents")
func RenderObjectScion_usedPointerEvents(_ objectRaw: UnsafeRawPointer) -> UInt8 {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.usedPointerEvents().rawValue
}

@_cdecl("RenderObjectScion_setNormalChildNeedsLayoutBit")
func RenderObjectScion_setNormalChildNeedsLayoutBit(_ objectRaw: UnsafeMutableRawPointer, _ b: Bool)
{
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setNormalChildNeedsLayoutBit(b: b)
}

@_cdecl("RenderObjectScion_setPosChildNeedsLayoutBit")
func RenderObjectScion_setPosChildNeedsLayoutBit(_ objectRaw: UnsafeMutableRawPointer, _ b: Bool) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setPosChildNeedsLayoutBit(b: b)
}

@_cdecl("RenderObjectScion_setNeedsSimplifiedNormalFlowLayoutBit")
func RenderObjectScion_setNeedsSimplifiedNormalFlowLayoutBit(
  _ objectRaw: UnsafeMutableRawPointer, _ b: Bool
) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setNeedsSimplifiedNormalFlowLayoutBit(b: b)
}

@_cdecl("RenderObjectScion_isSetNeedsLayoutForbidden")
func RenderObjectScion_isSetNeedsLayoutForbidden(_ objectRaw: UnsafeRawPointer) -> Bool {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  return object.isSetNeedsLayoutForbidden()
}

@_cdecl("RenderObjectScion_setNeedsLayoutIsForbidden")
func RenderObjectScion_setNeedsLayoutIsForbidden(_ objectRaw: UnsafeRawPointer, _ flag: Bool) {
  let object = Unmanaged<RenderObjectWrapper>.fromOpaque(objectRaw).takeUnretainedValue()
  object.setNeedsLayoutIsForbidden(flag)
}

@_cdecl("RenderSelectionScion_create")
func RenderSelectionScion_create(_ viewRaw: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
  let view = Unmanaged<RenderViewWrapper>.fromOpaque(viewRaw).takeUnretainedValue()
  let renderSelection = RenderSelection(view)
  let unmanaged = Unmanaged.passRetained(renderSelection)
  return unmanaged.toOpaque()
}

@_cdecl("RenderElementScion_style")
func RenderElementScion_style(_ elementRaw: UnsafeRawPointer) -> UnsafeRawPointer {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.elementStyle().p!
}

@_cdecl("RenderElementScion_mutableStyle")
func RenderElementScion_mutableStyle(_ elementRaw: UnsafeMutableRawPointer) -> UnsafeRawPointer {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.mutableStyle().p!
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

@_cdecl("RenderElementScion_element")
func RenderElementScion_element(_ elementRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let renderElement = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return renderElement.element()?.p
}

@_cdecl("RenderElementScion_firstChild")
func RenderElementScion_firstChild(_ elementRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  guard let firstChild = element.firstChild() else { return nil }
  assert(!firstChild.isNativeImpl())
  return firstChild.id()
}

@_cdecl("RenderElementScion_lastChild")
func RenderElementScion_lastChild(_ elementRaw: UnsafeRawPointer) -> UnsafeMutableRawPointer? {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  guard let lastChild = element.lastChild() else { return nil }
  assert(!lastChild.isNativeImpl())
  return lastChild.id()
}

@_cdecl("RenderElementScion_canContainFixedPositionObjects")
func RenderElementScion_canContainFixedPositionObjects(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.canContainFixedPositionObjects()
}

@_cdecl("RenderElementScion_canContainAbsolutelyPositionedObjects")
func RenderElementScion_canContainAbsolutelyPositionedObjects(_ elementRaw: UnsafeRawPointer)
  -> Bool
{
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.canContainAbsolutelyPositionedObjects()
}

@_cdecl("RenderElementScion_shouldApplyPaintContainment")
func RenderElementScion_shouldApplyPaintContainment(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.shouldApplyPaintContainment()
}

@_cdecl("RenderElementScion_didAttachChild")
func RenderElementScion_didAttachChild(
  _ elementRaw: UnsafeMutableRawPointer, _ child: UnsafeMutableRawPointer
) {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  element.didAttachChild(child: createRenderObjectWrapper(child))
}

@_cdecl("RenderElementScion_setChildNeedsLayout")
func RenderElementScion_setChildNeedsLayout(
  _ elementRaw: UnsafeMutableRawPointer, _ markParents: Bool
) {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  element.setChildNeedsLayout(markParents: markParents ? .MarkContainingBlockChain : .MarkOnlyThis)
}

@_cdecl("RenderElementScion_shouldApplyLayoutOrPaintContainment")
func RenderElementScion_shouldApplyLayoutOrPaintContainment(_ elementRaw: UnsafeRawPointer) -> Bool
{
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.shouldApplyLayoutOrPaintContainment()
}

@_cdecl("RenderElementScion_repaintAfterLayoutIfNeeded")
func RenderElementScion_repaintAfterLayoutIfNeeded(
  _ elementRaw: UnsafeMutableRawPointer, _ repaintContainerRaw: UnsafeMutableRawPointer,
  _ repaintContainerIsScionView: Bool,
  _ requiresFullRepaint: Bool, _ oldRectsRaw: RepaintRectsRaw, _ newRectsRaw: RepaintRectsRaw
) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  let repaintContainer =
    repaintContainerIsScionView
    ? Unmanaged<RenderViewWrapper>.fromOpaque(repaintContainerRaw).takeUnretainedValue()
    : createRenderObjectWrapper(repaintContainerRaw) as! RenderLayerModelObjectWrapper?
  let oldRects = convertRepaintRects(oldRectsRaw)
  let newRects = convertRepaintRects(newRectsRaw)
  return element.repaintAfterLayoutIfNeeded(
    repaintContainer, requiresFullRepaint ? .Yes : .No, oldRects: oldRects, newRects: newRects)
}

@_cdecl("RenderElementScion_isTransparent")
func RenderElementScion_isTransparent(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.isTransparent()
}

@_cdecl("RenderElementScion_opacity")
func RenderElementScion_opacity(_ elementRaw: UnsafeRawPointer) -> Float32 {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.opacity()
}

@_cdecl("RenderElementScion_hasMask")
func RenderElementScion_hasMask(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasMask()
}

@_cdecl("RenderElementScion_hasClipOrNonVisibleOverflow")
func RenderElementScion_hasClipOrNonVisibleOverflow(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasClipOrNonVisibleOverflow()
}

@_cdecl("RenderElementScion_hasClipPath")
func RenderElementScion_hasClipPath(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasClipPath()
}

@_cdecl("RenderElementScion_isViewTransitionRoot")
func RenderElementScion_isViewTransitionRoot(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.isViewTransitionRoot()
}

@_cdecl("RenderElementScion_requiresRenderingConsolidationForViewTransition")
func RenderElementScion_requiresRenderingConsolidationForViewTransition(
  _ elementRaw: UnsafeRawPointer
) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.requiresRenderingConsolidationForViewTransition()
}

@_cdecl("RenderElementScion_hasFilter")
func RenderElementScion_hasFilter(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasFilter()
}

@_cdecl("RenderElementScion_hasBackdropFilter")
func RenderElementScion_hasBackdropFilter(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasBackdropFilter()
}

@_cdecl("RenderElementScion_hasBlendMode")
func RenderElementScion_hasBlendMode(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasBlendMode()
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

@_cdecl("RenderElementScion_detachRendererInternal")
func RenderElementScion_detachRendererInternal(
  _ elementRaw: UnsafeMutableRawPointer, _ rendererRaw: UnsafeMutableRawPointer
)
  -> UnsafeMutableRawPointer?
{
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  let renderer = createRenderObjectWrapper(rendererRaw)
  return element.detachRendererInternal(renderer: renderer)?.id()
}

@_cdecl("RenderElementScion_hasCachedSVGResource")
func RenderElementScion_hasCachedSVGResource(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.hasCachedSVGResource()
}

@_cdecl("RenderElementScion_renderBlockHasRareData")
func RenderElementScion_renderBlockHasRareData(_ elementRaw: UnsafeRawPointer) -> Bool {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  return element.renderBlockHasRareData
}

@_cdecl("RenderElementScion_setFirstChild")
func RenderElementScion_setFirstChild(
  _ elementRaw: UnsafeMutableRawPointer, _ firstChildRaw: UnsafeMutableRawPointer?
) {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  element.setFirstChild(firstChildRaw != nil ? createRenderObjectWrapper(firstChildRaw!) : nil)
}

@_cdecl("RenderElementScion_setLastChild")
func RenderElementScion_setLastChild(
  _ elementRaw: UnsafeMutableRawPointer, _ lastChildRaw: UnsafeMutableRawPointer?
) {
  let element = Unmanaged<RenderElementWrapper>.fromOpaque(elementRaw).takeUnretainedValue()
  element.setLastChild(lastChildRaw != nil ? createRenderObjectWrapper(lastChildRaw!) : nil)
}

@_cdecl("RenderBoxModelObjectScion_borderLogicalLeft")
func RenderBoxModelObjectScion_borderLogicalLeft(_ boxModelObjectRaw: UnsafeRawPointer) -> Int32 {
  let boxModelObject = Unmanaged<RenderBoxModelObjectWrapper>.fromOpaque(boxModelObjectRaw)
    .takeUnretainedValue()
  return boxModelObject.borderLogicalLeft().rawValue()
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

@_cdecl("RenderBoxScion_logicalHeight")
func RenderBoxScion_logicalHeight(_ boxRaw: UnsafeRawPointer) -> Int32 {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.logicalHeight().rawValue()
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

@_cdecl("RenderBoxScion_clientLogicalWidth")
func RenderBoxScion_clientLogicalWidth(_ boxRaw: UnsafeRawPointer) -> Int32 {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.clientLogicalWidth().rawValue()
}

@_cdecl("RenderBoxScion_clientLogicalHeight")
func RenderBoxScion_clientLogicalHeight(_ boxRaw: UnsafeRawPointer) -> Int32 {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.clientLogicalHeight().rawValue()
}

private func convertFloatPoint(_ p: FloatPointRaw) -> FloatPoint {
  return FloatPoint(x: p.x, y: p.y)
}

private func convertFloatQuad(_ q: FloatQuadRaw) -> FloatQuad {
  return FloatQuad(
    convertFloatPoint(q.p1), convertFloatPoint(q.p2), convertFloatPoint(q.p3),
    convertFloatPoint(q.p4))
}

@_cdecl("RenderBoxScion_hitTestClipPath")
func RenderBoxScion_hitTestClipPath(
  _ boxRaw: UnsafeRawPointer, _ hitTestLocationRaw: HitTestLocationRaw,
  _ accumulatedOffsetRaw: LayoutPointRaw
) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let hitTestLocation = convertHitTestLocation(hitTestLocationRaw)
  let accumulatedOffset = convertLayoutPointRaw(accumulatedOffsetRaw)
  return box.hitTestClipPath(hitTestLocation, accumulatedOffset)
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

@_cdecl("RenderBoxScion_canBeScrolledAndHasScrollableArea")
func RenderBoxScion_canBeScrolledAndHasScrollableArea(_ boxRaw: UnsafeRawPointer) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.canBeScrolledAndHasScrollableArea()
}

@_cdecl("RenderBoxScion_canAutoscroll")
func RenderBoxScion_canAutoscroll(_ boxRaw: UnsafeRawPointer) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.canAutoscroll()
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

@_cdecl("RenderBoxScion_flipForWritingModeForChild")
func RenderBoxScion_flipForWritingModeForChild(
  _ boxRaw: UnsafeRawPointer, _ childRaw: UnsafeMutableRawPointer, _ point: LayoutPointRaw
) -> LayoutPointRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let child = createRenderObjectWrapperOrNative(childRaw) as! RenderBoxWrapper
  return convertLayoutPoint(
    box.flipForWritingModeForChild(child: child, point: convertLayoutPointRaw(point)))
}

@_cdecl("RenderBoxScion_topLeftLocation")
func RenderBoxScion_topLeftLocation(_ boxRaw: UnsafeRawPointer) -> LayoutPointRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let point = box.topLeftLocation()
  return LayoutPointRaw(x: point.x.rawValue(), y: point.y.rawValue())
}

@_cdecl("RenderBoxScion_hasRenderOverflow")
func RenderBoxScion_hasRenderOverflow(_ boxRaw: UnsafeRawPointer) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.hasRenderOverflow()
}

@_cdecl("RenderBoxScion_hasVisualOverflow")
func RenderBoxScion_hasVisualOverflow(_ boxRaw: UnsafeRawPointer) -> Bool {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  return box.hasVisualOverflow()
}

@_cdecl("RenderBoxScion_scrollPosition")
func RenderBoxScion_scrollPosition(_ boxRaw: UnsafeRawPointer) -> IntPointRaw {
  let box = Unmanaged<RenderBoxWrapper>.fromOpaque(boxRaw).takeUnretainedValue()
  let position = box.scrollPosition()
  return IntPointRaw(x: position.x, y: position.y)
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

@_cdecl("RenderBlockScion_insertPositionedObject")
func RenderBlockScion_insertPositionedObject(
  _ blockRaw: UnsafeMutableRawPointer, _ positionedRaw: UnsafeMutableRawPointer
) {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  let positioned = createRenderObjectWrapperOrNative(positionedRaw) as! RenderBoxWrapper
  block.insertPositionedObject(positioned: positioned)
}

@_cdecl("RenderBlockScion_addPercentHeightDescendant")
func RenderBlockScion_addPercentHeightDescendant(
  _ blockRaw: UnsafeMutableRawPointer, _ descendantRaw: UnsafeMutableRawPointer
) {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  let descendant = createRenderObjectWrapperOrNative(descendantRaw) as! RenderBoxWrapper
  block.addPercentHeightDescendant(descendant: descendant)
}

@_cdecl("RenderBlockScion_borderTop")
func RenderBlockScion_borderTop(_ blockRaw: UnsafeRawPointer) -> Int32 {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.borderTop().rawValue()
}

@_cdecl("RenderBlockScion_borderBottom")
func RenderBlockScion_borderBottom(_ blockRaw: UnsafeRawPointer) -> Int32 {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.borderBottom().rawValue()
}

@_cdecl("RenderBlockScion_borderLeft")
func RenderBlockScion_borderLeft(_ blockRaw: UnsafeRawPointer) -> Int32 {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.borderLeft().rawValue()
}

@_cdecl("RenderBlockScion_borderRight")
func RenderBlockScion_borderRight(_ blockRaw: UnsafeRawPointer) -> Int32 {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.borderRight().rawValue()
}

@_cdecl("RenderBlockScion_borderBefore")
func RenderBlockScion_borderBefore(_ blockRaw: UnsafeRawPointer) -> Int32 {
  let block = Unmanaged<RenderBlockFlowWrapper>.fromOpaque(blockRaw).takeUnretainedValue()
  return block.borderBefore().rawValue()
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
