/*
 * Copyright (C) 2026 Scion authors. All rights reserved.
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

// The Swift end of editing/EditingScion.h: C++ editing code asks these about positions in
// content the Swift port lays out.

extension VisiblePosition {
  func raw() -> VisiblePositionRaw {
    return VisiblePositionRaw(
      deepPosition: deepEquivalent().raw(), affinity: affinity() == .Downstream ? 1 : 0)
  }
}

@_cdecl("VisiblePositionScion_create")
func VisiblePositionScion_create(_ positionRaw: PositionRaw, _ affinityRaw: UInt8)
  -> VisiblePositionRaw
{
  return VisiblePosition(Position(raw: positionRaw), affinityRaw != 0 ? .Downstream : .Upstream)
    .raw()
}

extension SimpleRange {
  init(raw: SimpleRangeRaw) {
    self.init(
      start: BoundaryPoint(
        container: createNodeWrapper(raw.start.container!), offset: raw.start.offset),
      end: BoundaryPoint(container: createNodeWrapper(raw.end.container!), offset: raw.end.offset))
  }

  func raw() -> SimpleRangeRaw {
    return SimpleRangeRaw(
      start: BoundaryPointRaw(container: start.container.p, offset: start.offset),
      end: BoundaryPointRaw(container: end.container.p, offset: end.offset))
  }
}

@_cdecl("EditingScion_findPlainText")
func EditingScion_findPlainText(
  _ rangeRaw: SimpleRangeRaw, _ targetRaw: UnsafeRawPointer, _ optionsRaw: UInt16
) -> SimpleRangeRaw {
  let target = StringWrapper(p: targetRaw, owner: false)
  return findPlainText(
    range: SimpleRange(raw: rangeRaw), target: target,
    options: FindOption(rawValue: UInt32(optionsRaw))
  ).raw()
}

@_cdecl("EditingScion_characterCount")
func EditingScion_characterCount(_ rangeRaw: SimpleRangeRaw, _ behaviorsRaw: UInt32) -> UInt64 {
  return characterCount(
    range: SimpleRange(raw: rangeRaw), behaviors: TextIteratorBehavior(rawValue: behaviorsRaw))
}

@_cdecl("VisiblePositionScion_localCaretRect")
func VisiblePositionScion_localCaretRect(_ positionRaw: VisiblePositionRaw) -> LocalCaretRectRaw {
  let caret = VisiblePosition(raw: positionRaw).localCaretRect()
  return LocalCaretRectRaw(
    rect: convertLayoutRect(caret.rect), renderer: wkRenderObject(caret.renderer))
}

@_cdecl("EditingScion_localCaretRectInRendererForCaretPainting")
func EditingScion_localCaretRectInRendererForCaretPainting(_ positionRaw: VisiblePositionRaw)
  -> LocalCaretRectRaw
{
  var caretPainter: RenderBlockWrapper? = nil
  let rect = localCaretRectInRendererForCaretPainting(
    caretPosition: VisiblePosition(raw: positionRaw), caretPainter: &caretPainter)
  return LocalCaretRectRaw(rect: convertLayoutRect(rect), renderer: wkRenderObject(caretPainter))
}

@_cdecl("VisiblePositionScion_leftVisuallyDistinctCandidate")
func VisiblePositionScion_leftVisuallyDistinctCandidate(_ positionRaw: VisiblePositionRaw)
  -> PositionRaw
{
  return VisiblePosition(raw: positionRaw).leftVisuallyDistinctCandidate().raw()
}

@_cdecl("VisiblePositionScion_rightVisuallyDistinctCandidate")
func VisiblePositionScion_rightVisuallyDistinctCandidate(_ positionRaw: VisiblePositionRaw)
  -> PositionRaw
{
  return VisiblePosition(raw: positionRaw).rightVisuallyDistinctCandidate().raw()
}

@_cdecl("EditingScion_adjustEndpointsAtBidiBoundary")
func EditingScion_adjustEndpointsAtBidiBoundary(
  _ baseRaw: UnsafeMutablePointer<VisiblePositionRaw>,
  _ extentRaw: UnsafeMutablePointer<VisiblePositionRaw>
) {
  var base = VisiblePosition(raw: baseRaw.pointee)
  var extent = VisiblePosition(raw: extentRaw.pointee)
  adjustEndpointsAtBidiBoundary(visibleBase: &base, visibleExtent: &extent)
  baseRaw.pointee = base.raw()
  extentRaw.pointee = extent.raw()
}

@_cdecl("EditingScion_startOfLine")
func EditingScion_startOfLine(
  _ positionRaw: VisiblePositionRaw, _ modeRaw: UInt8,
  _ reachedBoundaryRaw: UnsafeMutablePointer<Bool>?
) -> VisiblePositionRaw {
  var reachedBoundary: Bool? = reachedBoundaryRaw != nil ? false : nil
  let result = startOfLine(
    c: VisiblePosition(raw: positionRaw),
    mode: LineEndpointComputationMode(rawValue: Int32(modeRaw))!,
    reachedBoundary: &reachedBoundary)
  reachedBoundaryRaw?.pointee = reachedBoundary ?? false
  return result.raw()
}

@_cdecl("EditingScion_endOfLine")
func EditingScion_endOfLine(
  _ positionRaw: VisiblePositionRaw, _ modeRaw: UInt8,
  _ reachedBoundaryRaw: UnsafeMutablePointer<Bool>?
) -> VisiblePositionRaw {
  var reachedBoundary: Bool? = reachedBoundaryRaw != nil ? false : nil
  let result = endOfLine(
    c: VisiblePosition(raw: positionRaw),
    mode: LineEndpointComputationMode(rawValue: Int32(modeRaw))!,
    reachedBoundary: &reachedBoundary)
  reachedBoundaryRaw?.pointee = reachedBoundary ?? false
  return result.raw()
}

@_cdecl("EditingScion_collectTextRanges")
func EditingScion_collectTextRanges(
  _ rangeRaw: SimpleRangeRaw, _ ranges: UnsafeMutableRawPointer,
  _ append: @convention(c) (UnsafeMutableRawPointer?, SimpleRangeRaw) -> Void
) {
  var iterator = EditingTextIterator(range: SimpleRange(raw: rangeRaw))
  while !iterator.atEnd() {
    append(ranges, iterator.range().raw())
    iterator.advance()
  }
}
