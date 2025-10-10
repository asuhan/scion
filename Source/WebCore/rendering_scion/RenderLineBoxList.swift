/*
 * Copyright (C) 2008-2009 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class RenderLineBoxList {
  func firstLegacyLineBox() -> LegacyInlineFlowBox? { return firstLineBox }

  func lastLegacyLineBox() -> LegacyInlineFlowBox? { return lastLineBox }

  func paint(
    renderer: RenderBoxModelObjectWrapper, paintInfo: PaintInfoWrapper,
    paintOffset: LayoutPointWrapper
  ) {
    assert(renderer.isRenderBlock() || (renderer.isRenderInline() && renderer.hasLayer()))  // The only way an inline could paint like this is if it has a layer.

    // If we have no lines then we have no work to do.
    if firstLegacyLineBox() == nil {
      return
    }

    // FIXME: Paint-time pagination is obsolete and is now only used by embedded WebViews inside AppKit
    // NSViews.  Do not add any more code for this.
    let v = renderer.view()
    let usePrintRect = !v.printRect().isEmpty()
    if !anyLineIntersectsRect(
      renderer: renderer, rect: paintInfo.rect, offset: paintOffset, usePrintRect: usePrintRect)
    {
      return
    }

    var info = paintInfo
    let outlineObjects = WeakListSet<RenderInlineWrapper, UInt>()
    info.outlineObjects = outlineObjects

    // See if our root lines intersect with the dirty rect.  If so, then we paint
    // them.  Note that boxes can easily overlap, so we can't make any assumptions
    // based off positions of our first line box or our last line box.
    var curr = firstLegacyLineBox()
    while curr != nil {
      if usePrintRect {
        // FIXME: This is the deprecated pagination model that is still needed
        // for embedded views inside AppKit.  AppKit is incapable of paginating vertical
        // text pages, so we don't have to deal with vertical lines at all here.
        let rootBox = curr!.root()
        var topForPaginationCheck = curr!.logicalTopVisualOverflow(lineTop: rootBox.lineTop)
        var bottomForPaginationCheck = curr!.logicalLeftVisualOverflow()
        if curr!.parent() == nil {
          // We're a root box.  Use lineTop and lineBottom as well here.
          topForPaginationCheck = min(topForPaginationCheck, rootBox.lineTop)
          bottomForPaginationCheck = max(bottomForPaginationCheck, rootBox.lineBottom)
        }
        if bottomForPaginationCheck - topForPaginationCheck <= v.printRect().height() {
          if paintOffset.y + bottomForPaginationCheck > Int(v.printRect().maxY()) {
            if let nextRootBox = rootBox.nextRootBox() {
              bottomForPaginationCheck = min(
                bottomForPaginationCheck, nextRootBox.logicalTopVisualOverflow(),
                nextRootBox.lineTop)
            }
          }
          if paintOffset.y + bottomForPaginationCheck > Int(v.printRect().maxY()) {
            if paintOffset.y + topForPaginationCheck < v.truncatedAt() {
              v.setBestTruncatedAt(
                y: (paintOffset.y + topForPaginationCheck).int(), forRenderer: renderer)
            }
            // If we were able to truncate, don't paint.
            if paintOffset.y + topForPaginationCheck >= v.truncatedAt() {
              break
            }
          }
        }
      }

      if lineIntersectsDirtyRect(
        renderer: renderer, box: curr, paintInfo: info, offset: paintOffset)
      {
        let rootBox = curr!.root()
        curr!.paint(
          paintInfo: info, paintOffset: paintOffset, lineTop: rootBox.lineTop,
          lineBottom: rootBox.lineBottom)
      }

      curr = curr!.nextLineBox()
    }

    if info.phase == .Outline || info.phase == .SelfOutline || info.phase == .ChildOutlines {
      for flow in info.outlineObjects! {
        flow.paintOutline(paintInfo: info, paintOffset: paintOffset)
      }
      info.outlineObjects!.clear()
    }
  }

  private func anyLineIntersectsRect(
    renderer: RenderBoxModelObjectWrapper, rect: LayoutRectWrapper, offset: LayoutPointWrapper,
    usePrintRect: Bool = false
  ) -> Bool {
    // We can check the first box and last box and avoid painting/hit testing if we don't
    // intersect.  This is a quick short-circuit that we can take to avoid walking any lines.
    // FIXME: This check is flawed in the following extremely obscure way:
    // if some line in the middle has a huge overflow, it might actually extend below the last line.
    let firstRootBox = firstLegacyLineBox()!.root()
    let lastRootBox = lastLegacyLineBox()!.root()
    var firstLineTop = firstLegacyLineBox()!.logicalTopVisualOverflow(
      lineTop: firstRootBox.lineTop)
    if usePrintRect && firstLegacyLineBox()!.parent() == nil {
      firstLineTop = min(firstLineTop, firstRootBox.lineTop)
    }
    var lastLineBottom = lastLegacyLineBox()!.logicalBottomVisualOverflow(
      lineBottom: lastRootBox.lineBottom)
    if usePrintRect && lastLegacyLineBox()!.parent() == nil {
      lastLineBottom = max(lastLineBottom, lastRootBox.lineBottom)
    }
    return rangeIntersectsRect(
      renderer: renderer, logicalTop: firstLineTop, logicalBottom: lastLineBottom, rect: rect,
      offset: offset)
  }

  private func lineIntersectsDirtyRect(
    renderer: RenderBoxModelObjectWrapper, box: LegacyInlineFlowBox?, paintInfo: PaintInfoWrapper,
    offset: LayoutPointWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: This should take a RenderBoxModelObject&.
  private func rangeIntersectsRect(
    renderer: RenderBoxModelObjectWrapper, logicalTop: LayoutUnit, logicalBottom: LayoutUnit,
    rect: LayoutRectWrapper, offset: LayoutPointWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // For block flows, each box represents the root inline box for a line in the paragraph.
  // For inline flows, each box represents a portion of that inline.
  private let firstLineBox: LegacyInlineFlowBox? = nil
  private let lastLineBox: LegacyInlineFlowBox? = nil
}
