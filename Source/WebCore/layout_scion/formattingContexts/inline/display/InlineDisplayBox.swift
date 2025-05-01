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
  class Box {
    init() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    class Text {
      convenience init() { self.init(start: 0, length: 0, originalContent: StringWrapper()) }

      init(
        start: UInt64, length: UInt64, originalContent: StringWrapper,
        adjustedContentToRender: StringWrapper = StringWrapper(), hasHyphen: Bool = false
      ) {
        self.originalContent = originalContent
        self.adjustedContentToRender = adjustedContentToRender
        self.start = UInt32(start)
        self.length = UInt32(length)
        self.hasHyphen = hasHyphen
      }

      func setPartiallyVisibleContentLength(truncatedLength: UInt64) {
        partiallyVisibleContentLength = UInt32(truncatedLength)
        hasPartiallyVisibleContentLength = true
      }

      func end() -> UInt64 {
        return UInt64(start + length)
      }

      var originalContent = StringWrapper()
      var adjustedContentToRender = StringWrapper()

      var start: UInt32 = 0
      var length: UInt32 = 0
      var partiallyVisibleContentLength: UInt32 = 0
      var hasPartiallyVisibleContentLength = false
      var hasHyphen = false
    }

    enum `Type`: UInt8 {
      case Text
      case WordSeparator
      case Ellipsis
      case SoftLineBreak
      case LineBreakBox
      case AtomicInlineBox
      case NonRootInlineBox
      case RootInlineBox
      case GenericInlineLevelBox
    }
    struct PositionWithinInlineLevelBox: OptionSet {
      let rawValue: UInt8
      static let First = PositionWithinInlineLevelBox(rawValue: 1 << 0)
      static let Last = PositionWithinInlineLevelBox(rawValue: 1 << 1)
    }

    init(
      lineIndex: UInt64, type: `Type`, layoutBox: BoxWrapper, bidiLevel: UBiDiLevel,
      physicalRect: FloatRectWrapper, inkOverflow: FloatRectWrapper, expansion: Expansion,
      text: Text? = nil, hasContent: Bool = true, isFullyTruncated: Bool = false,
      positionWithinInlineLevelBox: PositionWithinInlineLevelBox = PositionWithinInlineLevelBox()
    ) {
      self.layoutBox = layoutBox
      self.unflippedVisualRect = physicalRect
      self.inkOverflow = inkOverflow
      self.lineIndex = UInt32(lineIndex)
      self.horizontalExpansion = expansion.horizontalExpansion
      self.expansionBehavior = expansion.behavior
      self.bidiLevel = bidiLevel
      self.type = type
      self.hasContent = hasContent
      self.isFirstForLayoutBox = positionWithinInlineLevelBox.contains(
        PositionWithinInlineLevelBox.First)
      self.isLastForLayoutBox = positionWithinInlineLevelBox.contains(
        PositionWithinInlineLevelBox.Last)
      self.isFullyTruncated = isFullyTruncated
      if let text = text {
        self.m_text = text
      }
    }

    func isText() -> Bool { return type == .Text || isWordSeparator() }

    func isWordSeparator() -> Bool { return type == .WordSeparator }

    func isEllipsis() -> Bool { return type == .Ellipsis }

    func isSoftLineBreak() -> Bool { return type == .SoftLineBreak }

    func isTextOrSoftLineBreak() -> Bool { return isText() || isSoftLineBreak() }

    func isLineBreak() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isInlineLevelBox() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isAtomicInlineBox() -> Bool { return type == .AtomicInlineBox }

    func isInlineBox() -> Bool { return isNonRootInlineBox() || isRootInlineBox() }

    func isNonRootInlineBox() -> Bool { return type == .NonRootInlineBox }

    func isRootInlineBox() -> Bool { return type == .RootInlineBox }

    func isGenericInlineLevelBox() -> Bool { return type == .GenericInlineLevelBox }

    func isNonRootInlineLevelBox() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isVisible() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isVisibleIgnoringUsedVisibility() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func visualRectIgnoringBlockDirection() -> FloatRectWrapper { return unflippedVisualRect }

    static func visibleRectIgnoringBlockDirection(box: Box, visibleLineRect: FloatRectWrapper)
      -> FloatRectWrapper
    {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func top() -> Float32 { return visualRectIgnoringBlockDirection().y() }

    func bottom() -> Float32 { return visualRectIgnoringBlockDirection().maxY() }

    func left() -> Float32 { return visualRectIgnoringBlockDirection().x() }

    func right() -> Float32 { return visualRectIgnoringBlockDirection().maxX() }

    func width() -> Float32 { return visualRectIgnoringBlockDirection().width() }

    func height() -> Float32 { return visualRectIgnoringBlockDirection().height() }

    func moveVertically(offset: Float32) {
      unflippedVisualRect.move(delta: FloatSize(width: 0, height: offset))
      inkOverflow.move(delta: FloatSize(width: 0, height: offset))
    }

    func moveHorizontally(offset: Float32) {
      unflippedVisualRect.move(delta: FloatSize(width: offset, height: 0))
      inkOverflow.move(delta: FloatSize(width: offset, height: 0))
    }

    func expandVertically(delta: Float32) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func expandHorizontally(delta: Float32) {
      unflippedVisualRect.expand(size: FloatSize(width: delta, height: 0))
      inkOverflow.expand(size: FloatSize(width: delta, height: 0))
    }

    func adjustInkOverflow(childBorderBox: FloatRectWrapper) {
      inkOverflow.uniteEvenIfEmpty(other: childBorderBox)
    }

    func setLeft(physicalLeft: Float32) {
      let offset = physicalLeft - left()
      unflippedVisualRect.setX(x: physicalLeft)
      inkOverflow.setX(x: inkOverflow.x() + offset)
    }

    func setRight(physicalRight: Float32) {
      let offset = physicalRight - right()
      unflippedVisualRect.shiftMaxXEdgeTo(edge: physicalRight)
      inkOverflow.shiftMaxXEdgeTo(edge: inkOverflow.maxX() + offset)
    }

    func setTop(physicalTop: Float32) {
      let offset = physicalTop - top()
      unflippedVisualRect.setY(y: physicalTop)
      inkOverflow.setY(y: inkOverflow.y() + offset)
    }

    func setBottom(physicalBottom: Float32) {
      let offset = physicalBottom - bottom()
      unflippedVisualRect.shiftMaxYEdgeTo(edge: physicalBottom)
      inkOverflow.shiftMaxYEdgeTo(edge: inkOverflow.maxY() + offset)
    }

    func setRect(rect: FloatRectWrapper, inkOverflow: FloatRectWrapper) {
      self.unflippedVisualRect = rect
      self.inkOverflow = inkOverflow
    }

    func setHasContent() { hasContent = true }

    func setIsFullyTruncated() { isFullyTruncated = true }

    func text() -> Text {
      assert(isTextOrSoftLineBreak())
      return m_text
    }

    struct Expansion {
      var behavior: ExpansionBehaviorWrapper = ExpansionBehaviorWrapper.defaultBehavior()
      var horizontalExpansion: Float32 = 0
    }

    func setExpansion(expansion: Expansion) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func expansion() -> Expansion {
      return Expansion(behavior: expansionBehavior, horizontalExpansion: horizontalExpansion)
    }

    func style() -> RenderStyleWrapper {
      return lineIndex == 0 ? layoutBox.firstLineStyle() : layoutBox.style
    }

    func moveToLine(lineIndex: UInt32) { self.lineIndex = lineIndex }

    var layoutBox: BoxWrapper
    var unflippedVisualRect = FloatRectWrapper()
    var inkOverflow = FloatRectWrapper()

    var lineIndex: UInt32 = 0

    private var horizontalExpansion: Float32 = 0

    private var expansionBehavior = ExpansionBehaviorWrapper.defaultBehavior()

    var bidiLevel: UBiDiLevel = .UBIDI_DEFAULT_LTR
    var type: `Type` = .GenericInlineLevelBox
    var hasContent = false
    var isFirstForLayoutBox = false
    var isLastForLayoutBox = false
    var isFullyTruncated = false

    var m_text = Text()
  }
}
