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

extension InlineDisplay {
  class Line {
    init(
      lineBoxLogicalRect: FloatRectWrapper, lineBoxRect: FloatRectWrapper,
      contentOverflow: FloatRectWrapper, enclosingLogicalTopAndBottom: EnclosingTopAndBottom,
      alignmentBaseline: Float32, baselineType: FontBaseline, contentLogicalLeft: Float32,
      contentLogicalLeftIgnoringInlineDirection: Float32, contentLogicalWidth: Float32,
      isLeftToRightDirection: Bool, isHorizontal: Bool, isTruncatedInBlockDirection: Bool
    ) {
      self.lineBoxRect = lineBoxRect
      self.lineBoxLogicalRect = lineBoxLogicalRect
      self.contentOverflow = contentOverflow
      self.enclosingLogicalTopAndBottom = enclosingLogicalTopAndBottom
      self.alignmentBaseline = alignmentBaseline
      self.contentLogicalLeft = contentLogicalLeft
      self.contentLogicalLeftIgnoringInlineDirection = contentLogicalLeftIgnoringInlineDirection
      self.contentLogicalWidth = contentLogicalWidth
      self.baselineType = baselineType
      self.isLeftToRightDirection = isLeftToRightDirection
      self.isHorizontal = isHorizontal
      self.isFullyTruncatedInBlockDirection = isTruncatedInBlockDirection
    }

    struct EnclosingTopAndBottom {
      // This values encloses the root inline box and any other inline level box's border box.
      var top: Float32 = 0
      var bottom: Float32 = 0
    }

    func left() -> Float32 {
      return lineBoxRect.x()
    }

    func right() -> Float32 {
      return lineBoxRect.maxX()
    }

    func top() -> Float32 {
      return lineBoxRect.y()
    }

    func bottom() -> Float32 {
      return lineBoxRect.maxY()
    }

    func topLeft() -> FloatPoint {
      return lineBoxRect.location()
    }

    func lineBoxTop() -> Float32 {
      return lineBoxRect.y()
    }

    func lineBoxLeft() -> Float32 {
      return lineBoxRect.x()
    }

    func lineBoxRight() -> Float32 {
      return lineBoxRect.maxX()
    }

    func lineBoxWidth() -> Float32 {
      return lineBoxRect.width()
    }

    func visibleRectIgnoringBlockDirection() -> FloatRectWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func baseline() -> Float32 {
      return alignmentBaseline
    }

    func firstBoxIndex() -> UInt64 { return m_firstBoxIndex }

    func lastBoxIndex() -> UInt64 { return firstBoxIndex() + boxCount() - 1 }

    func boxCount() -> UInt64 { return m_boxCount }

    func moveInBlockDirection(offset: Float32, isHorizontalWritingMode: Bool) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    struct Ellipsis {
      enum `Type`: UInt8 {
        case Inline
        case Block
      }
      var type: `Type` = .Inline
      // This is visual rect ignoring block direction.
      var visualRect = FloatRectWrapper()
      var text = AtomStringWrapper()
    }

    func setEllipsis(ellipsis: Ellipsis) {
      self.ellipsis = ellipsis
    }

    func hasEllipsis() -> Bool {
      return ellipsisVisualRect != nil
    }

    func setHasContentAfterEllipsisBox() {
      hasContentAfterEllipsisBox = true
    }

    func setIsFirstAfterPageBreak() {
      isFirstAfterPageBreak = true
    }

    // FIXME: Move these to a side structure.
    private var m_firstBoxIndex: UInt64 = 0
    private var m_boxCount: UInt64 = 0

    // This is line box geometry (see https://www.w3.org/TR/css-inline-3/#line-box).
    var lineBoxRect: FloatRectWrapper
    var lineBoxLogicalRect: FloatRectWrapper
    var scrollableOverflow = FloatRectWrapper()
    // FIXME: Merge this with scrollable overflow (see InlineContentBuilder::updateLineOverflow).
    var contentOverflow: FloatRectWrapper
    // FIXME: This should be transitioned to spec aligned overflow value.
    var inkOverflow = FloatRectWrapper()
    // Enclosing top and bottom includes all inline level boxes (border box) vertically.
    // While the line box usually enclose them as well, its vertical geometry is based on
    // the layout bounds of the inline level boxes which may be different when line-height is present.
    var enclosingLogicalTopAndBottom: EnclosingTopAndBottom
    var alignmentBaseline: Float32 = 0
    // Content is mostly in flush with the line box edge except for cases like text-align.
    var contentLogicalLeft: Float32 = 0
    var contentLogicalLeftIgnoringInlineDirection: Float32 = 0
    var contentLogicalWidth: Float32 = 0
    var baselineType: FontBaseline = .AlphabeticBaseline
    var isLeftToRightDirection = true
    var isHorizontal = false
    var isFirstAfterPageBreak = false
    var isFullyTruncatedInBlockDirection = false
    var hasContentAfterEllipsisBox = false
    // This is visual rect ignoring block direction.
    var ellipsisVisualRect: FloatRectWrapper?
    var ellipsis: Ellipsis? = nil
  }
}
