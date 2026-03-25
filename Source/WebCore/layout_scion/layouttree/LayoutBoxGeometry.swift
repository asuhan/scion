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
    if !isNativeImpl() {
      let raw = wk_interop.BoxGeometry_horizontalMargin(p)
      return HorizontalEdges(
        start: LayoutUnit.fromRawValue(value: raw.start),
        end: LayoutUnit.fromRawValue(value: raw.end)
      )
    }
    #if ASSERT_ENABLED
      assert(m_hasValidHorizontalMargin)
    #endif  // ASSERT_ENABLED
    return margin.horizontal
  }

  func marginBefore() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBefore(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidVerticalMargin)
    #endif  // ASSERT_ENABLED
    return margin.vertical.before
  }

  func marginStart() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginStart(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidHorizontalMargin)
    #endif  // ASSERT_ENABLED
    return margin.horizontal.start
  }

  func marginAfter() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginAfter(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidVerticalMargin)
    #endif  // ASSERT_ENABLED
    return margin.vertical.after
  }

  func marginEnd() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginEnd(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidHorizontalMargin)
    #endif  // ASSERT_ENABLED
    return margin.horizontal.end
  }

  func borderBefore() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderBefore(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidBorder)
    #endif  // ASSERT_ENABLED
    return border.vertical.before
  }

  func borderAfter() -> LayoutUnit {
    assert(isNativeImpl())
    #if ASSERT_ENABLED
      assert(m_hasValidBorder)
    #endif  // ASSERT_ENABLED
    return border.vertical.after
  }

  func borderStart() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderStart(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidBorder)
    #endif  // ASSERT_ENABLED
    return border.horizontal.start
  }

  func borderEnd() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderEnd(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidBorder)
    #endif  // ASSERT_ENABLED
    return border.horizontal.end
  }

  private func verticalBorder() -> LayoutUnit {
    assert(isNativeImpl())
    return borderBefore() + borderAfter()
  }

  private func horizontalBorder() -> LayoutUnit {
    assert(isNativeImpl())
    return borderStart() + borderEnd()
  }

  func paddingBefore() -> LayoutUnit {
    assert(isNativeImpl())
    #if ASSERT_ENABLED
      assert(m_hasValidPadding)
    #endif  // ASSERT_ENABLED
    return padding.vertical.before
  }

  func paddingAfter() -> LayoutUnit {
    assert(isNativeImpl())
    #if ASSERT_ENABLED
      assert(m_hasValidPadding)
    #endif  // ASSERT_ENABLED
    return padding.vertical.after
  }

  func paddingStart() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_paddingStart(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidPadding)
    #endif  // ASSERT_ENABLED
    return padding.horizontal.start
  }

  func paddingEnd() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_paddingEnd(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidPadding)
    #endif  // ASSERT_ENABLED
    return padding.horizontal.end
  }

  private func verticalPadding() -> LayoutUnit {
    assert(isNativeImpl())
    return paddingBefore() + paddingAfter()
  }

  private func horizontalPadding() -> LayoutUnit {
    assert(isNativeImpl())
    return paddingStart() + paddingEnd()
  }

  func borderAndPaddingBefore() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderAndPaddingBefore(p))
    }
    return borderBefore() + paddingBefore()
  }

  func borderAndPaddingAfter() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_borderAndPaddingAfter(p))
    }
    return borderAfter() + paddingAfter()
  }

  func horizontalBorderAndPadding() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_horizontalBorderAndPadding(p))
    }
    return horizontalBorder() + horizontalPadding()
  }

  func verticalBorderAndPadding() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_verticalBorderAndPadding(p))
    }
    return verticalBorder() + verticalPadding()
  }

  func contentBoxTop() -> LayoutUnit {
    assert(isNativeImpl())
    return paddingBoxTop() + paddingBefore()
  }

  func contentBoxLeft() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxLeft(p))
    }
    return paddingBoxLeft() + paddingStart()
  }

  func contentBoxRight() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxRight(p))
    }
    return contentBoxLeft() + contentBoxWidth()
  }

  func contentBoxHeight() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxHeight(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidContentBoxHeight)
    #endif  // ASSERT_ENABLED
    return m_contentBoxHeight
  }

  func contentBoxWidth() -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_contentBoxWidth(p))
    }
    #if ASSERT_ENABLED
      assert(m_hasValidContentBoxWidth)
    #endif  // ASSERT_ENABLED
    return m_contentBoxWidth
  }

  func contentBoxSize() -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: contentBoxWidth(), height: contentBoxHeight())
  }

  func paddingBoxTop() -> LayoutUnit {
    assert(isNativeImpl())
    return borderBefore()
  }

  func paddingBoxLeft() -> LayoutUnit {
    assert(isNativeImpl())
    return borderStart()
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
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: BoxGeometry_borderBoxHeight(p))
  }

  func borderBoxWidth() -> LayoutUnit {
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: BoxGeometry_borderBoxWidth(p))
  }

  func marginBoxHeight() -> LayoutUnit {
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBoxHeight(p))
  }

  func marginBoxWidth() -> LayoutUnit {
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBoxWidth(p))
  }

  func marginBorderAndPaddingAfter() -> LayoutUnit {
    return marginAfter() + borderAndPaddingAfter()
  }

  func marginBorderAndPaddingStart() -> LayoutUnit {
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBorderAndPaddingStart(p))
  }

  func marginBorderAndPaddingEnd() -> LayoutUnit {
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_marginBorderAndPaddingEnd(p))
  }

  func horizontalMarginBorderAndPadding() -> LayoutUnit {
    if isNativeImpl() {
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
    if isNativeImpl() {
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
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setLeft(p, left.rawValue())
  }

  func moveHorizontally(offset: LayoutUnit) {
    if isNativeImpl() {
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
    if !isNativeImpl() {
      wk_interop.BoxGeometry_setContentBoxHeight(p, height.rawValue())
      return
    }
    #if ASSERT_ENABLED
      setHasValidContentBoxHeight()
    #endif
    m_contentBoxHeight = height
  }

  func setContentBoxWidth(width: LayoutUnit) {
    if !isNativeImpl() {
      wk_interop.BoxGeometry_setContentBoxWidth(p, width.rawValue())
      return
    }
    #if ASSERT_ENABLED
      setHasValidContentBoxWidth()
    #endif
    m_contentBoxWidth = width
  }

  func setContentBoxSize(size: LayoutSizeWrapper) {
    if !isNativeImpl() {
      wk_interop.BoxGeometry_setContentBoxWidth(p, size.width().rawValue())
      wk_interop.BoxGeometry_setContentBoxHeight(p, size.height().rawValue())
      return
    }
    setContentBoxWidth(width: size.width())
    setContentBoxHeight(height: size.height())
  }

  func setHorizontalMargin(margin: HorizontalEdges) {
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.BoxGeometry_setHorizontalMargin(p, margin.start.rawValue(), margin.end.rawValue())
  }

  func setVerticalMargin(margin: VerticalEdges) {
    if isNativeImpl() {
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
    if !isNativeImpl() {
      wk_interop.BoxGeometry_setVerticalSpaceForScrollbar(p, scrollbarHeight.rawValue())
      return
    }
    verticalSpaceForScrollbar = scrollbarHeight
  }

  func setHorizontalSpaceForScrollbar(scrollbarWidth: LayoutUnit) {
    if !isNativeImpl() {
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
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_top(p))
  }

  private func left() -> LayoutUnit {
    if isNativeImpl() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LayoutUnit.fromRawValue(value: wk_interop.BoxGeometry_left(p))
  }

  private func topLeft() -> LayoutPointWrapper { return LayoutPointWrapper(x: left(), y: top()) }

  private func isNativeImpl() -> Bool { return p == nil }

  #if ASSERT_ENABLED
    func setHasValidContentBoxHeight() { m_hasValidContentBoxHeight = true }
    func setHasValidContentBoxWidth() { m_hasValidContentBoxWidth = true }
  #endif  // ASSERT_ENABLED

  private var m_contentBoxWidth = LayoutUnit()
  private var m_contentBoxHeight = LayoutUnit()

  private let margin = Edges()
  private var border = Edges()
  var padding = Edges()

  var verticalSpaceForScrollbar = LayoutUnit()
  var horizontalSpaceForScrollbar = LayoutUnit()

  #if ASSERT_ENABLED
    private let m_hasValidHorizontalMargin = false
    private let m_hasValidVerticalMargin = false
    private let m_hasValidBorder = false
    private let m_hasValidPadding = false
    private var m_hasValidContentBoxHeight = false
    private var m_hasValidContentBoxWidth = false
  #endif  // ASSERT_ENABLED

  var p: UnsafeMutableRawPointer? = nil
}
