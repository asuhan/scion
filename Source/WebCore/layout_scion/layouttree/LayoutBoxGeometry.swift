/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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

class BoxGeometry {
  static func borderBoxTop(box: BoxGeometry) -> LayoutUnit { return box.top() }

  static func borderBoxLeft(box: BoxGeometry) -> LayoutUnit { return box.left() }

  static func borderBoxTopLeft(box: BoxGeometry) -> LayoutPointWrapper { return box.topLeft() }

  static func borderBoxRect(box: BoxGeometry) -> Rect {
    return Rect(
      top: box.top(), left: box.left(), width: box.borderBoxWidth(), height: box.borderBoxHeight())
  }

  static func marginBoxRect(box: BoxGeometry) -> Rect {
    return Rect(
      top: box.top() - box.marginBefore(), left: box.left() - box.marginStart(),
      width: box.marginBoxWidth(),
      height: box.marginBoxHeight())
  }

  struct VerticalEdges {
    var before = LayoutUnit()
    var after = LayoutUnit()

    @discardableResult
    static func += (this: inout VerticalEdges, other: VerticalEdges) -> VerticalEdges {
      this.before += other.before
      this.after += other.after
      return this
    }
  }

  struct HorizontalEdges {
    var start = LayoutUnit()
    var end = LayoutUnit()
  }

  struct Edges {
    var horizontal = HorizontalEdges()
    var vertical = VerticalEdges()
  }

  func horizontalMargin() -> HorizontalEdges {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let raw = wk_interop.BoxGeometry_horizontalMargin(p)
    return HorizontalEdges(
      start: LayoutUnit.fromRawValue(value: raw.start), end: LayoutUnit.fromRawValue(value: raw.end)
    )
  }

  func marginBefore() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBefore(p))
  }

  func marginStart() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginStart(p))
  }

  func marginAfter() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginAfter(p))
  }

  func marginEnd() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginEnd(p))
  }

  func borderBefore() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderBefore(p))
  }

  func borderAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderStart() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderStart(p))
  }

  func borderEnd() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderEnd(p))
  }

  func paddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingStart() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_paddingStart(p))
  }

  func paddingEnd() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_paddingEnd(p))
  }

  func borderAndPaddingBefore() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderAndPaddingBefore(p))
  }

  func borderAndPaddingAfter() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderAndPaddingAfter(p))
  }

  func horizontalBorderAndPadding() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_horizontalBorderAndPadding(p))
  }

  func verticalBorderAndPadding() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_verticalBorderAndPadding(p))
  }

  func contentBoxTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentBoxLeft() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxLeft(p))
  }

  func contentBoxRight() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxRight(p))
  }

  func contentBoxHeight() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxHeight(p))
  }

  func contentBoxWidth() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxWidth(p))
  }

  func contentBoxSize() -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: contentBoxWidth(), height: contentBoxHeight())
  }

  func paddingBoxTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingBoxLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingBoxHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingBoxWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginBorderAndPaddingBefore() -> LayoutUnit {
    return marginBefore() + borderAndPaddingBefore()
  }

  func borderBoxHeight() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: BoxGeometry_borderBoxHeight(p))
  }

  func borderBoxWidth() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: BoxGeometry_borderBoxWidth(p))
  }

  func marginBoxHeight() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBoxHeight(p))
  }

  func marginBoxWidth() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBoxWidth(p))
  }

  func marginBorderAndPaddingAfter() -> LayoutUnit {
    return marginAfter() + borderAndPaddingAfter()
  }

  func marginBorderAndPaddingStart() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBorderAndPaddingStart(p))
  }

  func marginBorderAndPaddingEnd() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBorderAndPaddingEnd(p))
  }

  func horizontalMarginBorderAndPadding() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(
      value: wk_interop.BoxGeometry_horizontalMarginBorderAndPadding(p))
  }

  func borderBox() -> Rect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasPrecomputedMarginBefore() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTopLeft(topLeft: LayoutPointWrapper) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setTopLeft(p, topLeft.x.rawValue(), topLeft.y.rawValue())
  }

  func setTop(top: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLeft(left: LayoutUnit) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setLeft(p, left.rawValue())
  }

  func moveHorizontally(offset: LayoutUnit) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_moveHorizontally(p, offset.rawValue())
  }

  func move(size: LayoutSizeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentBoxHeight(height: LayoutUnit) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setContentBoxHeight(p, height.rawValue())
  }

  func setContentBoxWidth(width: LayoutUnit) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setContentBoxWidth(p, width.rawValue())
  }

  func setContentBoxSize(size: LayoutSizeWrapper) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setContentBoxWidth(p, size.width().rawValue())
    wk_interop.BoxGeometry_setContentBoxHeight(p, size.height().rawValue())
  }

  func setHorizontalMargin(margin: HorizontalEdges) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setHorizontalMargin(p, margin.start.rawValue(), margin.end.rawValue())
  }

  func setVerticalMargin(margin: VerticalEdges) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setVerticalMargin(p, margin.before.rawValue(), margin.after.rawValue())
  }

  func setHorizontalBorder(horizontalBorder: HorizontalEdges) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBorder(border: Edges) {
    self.border = border
  }

  func setHorizontalPadding(horizontalPadding: HorizontalEdges) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPadding(padding: Edges) {
    self.padding = padding
  }

  func setVerticalSpaceForScrollbar(scrollbarHeight: LayoutUnit) {
    if p != nil {
      wk_interop.BoxGeometry_setVerticalSpaceForScrollbar(p, scrollbarHeight.rawValue())
      return
    }
    verticalSpaceForScrollbar = scrollbarHeight
  }

  func setHorizontalSpaceForScrollbar(scrollbarWidth: LayoutUnit) {
    if p != nil {
      wk_interop.BoxGeometry_setHorizontalSpaceForScrollbar(p, scrollbarWidth.rawValue())
      return
    }
    horizontalSpaceForScrollbar = scrollbarWidth
  }

  func setSpaceForScrollbar(scrollbarSize: LayoutSizeWrapper) {
    setVerticalSpaceForScrollbar(scrollbarHeight: scrollbarSize.height())
    setHorizontalSpaceForScrollbar(scrollbarWidth: scrollbarSize.width())
  }

  func reset() {
    setTopLeft(topLeft: LayoutPointWrapper(x: LayoutUnit(), y: LayoutUnit()))

    setHorizontalMargin(margin: HorizontalEdges())
    setVerticalMargin(margin: VerticalEdges())
    setBorder(border: Edges())
    setPadding(padding: Edges())

    setContentBoxSize(size: LayoutSizeWrapper())

    setVerticalSpaceForScrollbar(scrollbarHeight: LayoutUnit())
    setHorizontalSpaceForScrollbar(scrollbarWidth: LayoutUnit())
  }

  private func top() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_top(p))
  }

  private func left() -> LayoutUnit {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_left(p))
  }

  private func topLeft() -> LayoutPointWrapper { return LayoutPointWrapper(x: left(), y: top()) }

  private var border = Edges()
  var padding = Edges()

  var verticalSpaceForScrollbar = LayoutUnit()
  var horizontalSpaceForScrollbar = LayoutUnit()
  var p: UnsafeMutableRawPointer? = nil
}
