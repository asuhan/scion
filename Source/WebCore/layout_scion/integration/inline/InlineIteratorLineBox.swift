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

class InlineIterator {
  struct LineBox {
    enum PathVariant {
      case modern(LineBoxIteratorModernPath)
      case legacy(LineBoxIteratorLegacyPath)
    }

    init(path: PathVariant) { m_pathVariant = path }

    func logicalTop() -> Float32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.logicalTop()
      case .legacy(let path):
        return path.logicalTop()
      }
    }

    func logicalBottom() -> Float32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.logicalBottom()
      case .legacy(let path):
        return path.logicalBottom()
      }
    }

    func logicalHeight() -> Float32 { return logicalBottom() - logicalTop() }

    func contentLogicalTop() -> Float32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.contentLogicalTop()
      case .legacy(let path):
        return path.contentLogicalTop()
      }
    }

    func contentLogicalBottom() -> Float32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.contentLogicalBottom()
      case .legacy(let path):
        return path.contentLogicalBottom()
      }
    }

    func contentLogicalLeft() -> Float32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.contentLogicalLeft()
      case .legacy(let path):
        return path.contentLogicalLeft()
      }
    }

    func contentLogicalHeight() -> Float32 { return contentLogicalBottom() - contentLogicalTop() }

    func inkOverflowLogicalTop() -> Float32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.inkOverflowLogicalTop()
      case .legacy(let path):
        return path.inkOverflowLogicalTop()
      }
    }

    func inkOverflowLogicalBottom() -> Float32 {
      switch m_pathVariant {
      case .modern(let path):
        return path.inkOverflowLogicalBottom()
      case .legacy(let path):
        return path.inkOverflowLogicalBottom()
      }
    }

    func style() -> RenderStyleWrapper {
      return isFirst() ? formattingContextRoot().firstLineStyle() : formattingContextRoot().style()
    }

    enum AdjustedForSelection {
      case No
      case Yes
    }

    func ellipsisVisualRect(adjustedForSelection: AdjustedForSelection = .No) -> FloatRectWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func ellipsisText() -> TextRunWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func ellipsisSelectionState() -> RenderObjectWrapper.HighlightState {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func formattingContextRoot() -> RenderBlockFlowWrapper {
      switch m_pathVariant {
      case .modern(let path):
        return path.formattingContextRoot()
      case .legacy(let path):
        return path.formattingContextRoot()
      }
    }

    func containingFragment() -> RenderFragmentContainerWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isFirst() -> Bool { return !previous().bool() }

    func isFirstAfterPageBreak() -> Bool {
      switch m_pathVariant {
      case .modern(let path):
        return path.isFirstAfterPageBreak()
      case .legacy(let path):
        return path.isFirstAfterPageBreak()
      }
    }

    func firstLeafBox() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func next() -> LineBoxIterator {
      return LineBoxIterator(self).traverseNext()
    }

    func previous() -> LineBoxIterator {
      return LineBoxIterator(self).traversePrevious()
    }

    func lineIndex() -> UInt64 {
      switch m_pathVariant {
      case .modern(let path):
        return path.lineIndex()
      case .legacy(let path):
        return path.lineIndex()
      }
    }

    let m_pathVariant: PathVariant
  }

  class LineBoxIterator: IteratorProtocol {
    init() { m_lineBox = LineBox(path: .legacy(LineBoxIteratorLegacyPath(nil))) }

    init(_ lineBox: LineBox) { m_lineBox = lineBox }

    @discardableResult
    func traverseNext() -> LineBoxIterator {
      switch m_lineBox.m_pathVariant {
      case .modern(let path):
        path.traverseNext()
      case .legacy(let path):
        path.traverseNext()
      }
      return self
    }

    func traversePrevious() -> LineBoxIterator {
      switch m_lineBox.m_pathVariant {
      case .modern(let path):
        path.traversePrevious()
      case .legacy(let path):
        path.traversePrevious()
      }
      return self
    }

    func next() -> LineBox? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func bool() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func get() -> LineBox {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let m_lineBox: LineBox
  }

  static func firstLineBoxFor(flow: RenderBlockFlowWrapper) -> LineBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func lastLineBoxFor(flow: RenderBlockFlowWrapper) -> LineBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func lineBoxFor(inlineContent: LayoutIntegration.InlineContent, lineIndex: UInt64)
    -> LineBoxIterator
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func closestBoxForHorizontalPosition(
    _ lineBox: LineBox, _ horizontalPosition: Float32, _ editableOnly: Bool = false
  ) -> LeafBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func previousLineBoxContentBottomOrBorderAndPadding(_ lineBox: LineBox) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func contentStartInBlockDirection(_ lineBox: LineBox) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
