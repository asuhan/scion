/*
 * Copyright (C) 2019-2021 Apple Inc. All rights reserved.
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

extension InlineIterator {

  class Box {
    enum PathVariant {
      case modern(BoxModernPath)
      case legacy(BoxLegacyPath)
    }

    init(_ path: PathVariant) { m_pathVariant = path }

    func isText() -> Bool {
      switch m_pathVariant {
      case .modern(let path):
        return path.isText()
      case .legacy(let path):
        return path.isText()
      }
    }

    func isRootInlineBox() -> Bool {
      switch m_pathVariant {
      case .modern(let path):
        return path.isRootInlineBox()
      case .legacy(let path):
        return path.isRootInlineBox()
      }
    }

    func isLineBreak() -> Bool {
      switch m_pathVariant {
      case .modern(let path):
        return path.isLineBreak()
      case .legacy(let path):
        return path.isLineBreak()
      }
    }

    func visualRect() -> FloatRectWrapper {
      var rect = visualRectIgnoringBlockDirection()
      formattingContextRoot().flipForWritingMode(rect: &rect)
      return rect
    }

    func visualRectIgnoringBlockDirection() -> FloatRectWrapper {
      switch m_pathVariant {
      case .modern(let path):
        return path.visualRectIgnoringBlockDirection()
      case .legacy(let path):
        return path.visualRectIgnoringBlockDirection()
      }
    }

    // Visual in inline direction, logical for writing mode.
    private func logicalRectIgnoringInlineDirection() -> FloatRectWrapper {
      let rect = visualRectIgnoringBlockDirection()
      return isHorizontal() ? rect : rect.transposedRect()
    }

    func logicalTop() -> Float32 { return logicalRectIgnoringInlineDirection().y() }

    func logicalBottom() -> Float32 { return logicalRectIgnoringInlineDirection().maxY() }

    func logicalWidth() -> Float32 { return logicalRectIgnoringInlineDirection().width() }

    // Return visual left/right coords in inline direction (they are still considered logical values as there's no flip for writing mode).
    func logicalLeftIgnoringInlineDirection() -> Float32 {
      return logicalRectIgnoringInlineDirection().x()
    }

    func logicalRightIgnoringInlineDirection() -> Float32 {
      return logicalRectIgnoringInlineDirection().maxX()
    }

    func isHorizontal() -> Bool {
      switch m_pathVariant {
      case .modern(let path):
        return path.isHorizontal()
      case .legacy(let path):
        return path.isHorizontal()
      }
    }

    func minimumCaretOffset() -> UInt32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func maximumCaretOffset() -> UInt32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func leftmostCaretOffset() -> UInt32 {
      return isLeftToRightDirection() ? minimumCaretOffset() : maximumCaretOffset()
    }

    func rightmostCaretOffset() -> UInt32 {
      return isLeftToRightDirection() ? maximumCaretOffset() : minimumCaretOffset()
    }

    func bidiLevel() -> UInt8 {
      switch m_pathVariant {
      case .modern(let path):
        return path.bidiLevel()
      case .legacy(let path):
        return path.bidiLevel()
      }
    }

    func direction() -> TextDirection { return bidiLevel() % 2 != 0 ? .RTL : .LTR }

    func isLeftToRightDirection() -> Bool { return direction() == .LTR }

    func renderer() -> RenderObjectWrapper {
      switch m_pathVariant {
      case .modern(let path):
        return path.renderer()
      case .legacy(let path):
        return path.renderer()
      }
    }

    private func formattingContextRoot() -> RenderBlockFlowWrapper {
      switch m_pathVariant {
      case .modern(let path):
        return path.formattingContextRoot()
      case .legacy(let path):
        return path.formattingContextRoot()
      }
    }

    func style() -> RenderStyleWrapper {
      switch m_pathVariant {
      case .modern(let path):
        return path.style()
      case .legacy(let path):
        return path.style()
      }
    }

    // FIXME: Remove. For intermediate porting steps only.
    func legacyInlineBox() -> LegacyInlineBox? {
      switch m_pathVariant {
      case .modern:
        return nil
      case .legacy(let path):
        return path.legacyInlineBox()
      }
    }

    func nextOnLine() -> LeafBoxIterator { return LeafBoxIterator(self).traverseNextOnLine() }

    func previousOnLine() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func nextOnLineIgnoringLineBreak() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func previousOnLineIgnoringLineBreak() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func parentInlineBox() -> InlineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func lineBox() -> LineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func modernPath() -> BoxModernPath {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    let m_pathVariant: PathVariant
  }

  class BoxIterator<Box>: Equatable, IteratorProtocol {
    init() { m_box = InlineIterator.Box(.legacy(BoxLegacyPath(nil))) }

    init(_ pathVariant: InlineIterator.Box.PathVariant) { m_box = InlineIterator.Box(pathVariant) }

    init(_ run: InlineIterator.Box) { m_box = run }

    func bool() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    static func == (self: BoxIterator, other: BoxIterator) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func next() -> Box? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func get() -> Box {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let m_box: InlineIterator.Box
  }

  class LeafBoxIterator: BoxIterator<Box> {
    @discardableResult
    func traverseNextOnLine() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    @discardableResult
    func traverseNextOnLineIgnoringLineBreak() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    @discardableResult
    func traversePreviousOnLineIgnoringLineBreak() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  class BoxRange<BoxType: Box>: Sequence {
    init(_ begin: BoxIterator<BoxType>) {
      self.begin = begin
    }

    func makeIterator() -> BoxIterator<BoxType> {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let begin: BoxIterator<BoxType>
  }

  static func boxFor(_ renderer: RenderLineBreakWrapper) -> LeafBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func boxFor(_ renderer: RenderBoxWrapper) -> LeafBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

}
