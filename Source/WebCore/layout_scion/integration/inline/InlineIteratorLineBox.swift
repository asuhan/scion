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
    init(path: LineBoxIteratorModernPath) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func logicalTop() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func logicalBottom() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func logicalHeight() -> Float32 { return logicalBottom() - logicalTop() }

    func contentLogicalTop() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func contentLogicalBottom() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func contentLogicalLeft() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func contentLogicalHeight() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func inkOverflowLogicalTop() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func inkOverflowLogicalBottom() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func style() -> RenderStyleWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isFirst() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func firstLeafBox() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func previous() -> LineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func lineIndex() -> UInt64 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  class LineBoxIterator: IteratorProtocol {
    @discardableResult
    func traverseNext() -> LineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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

  static func previousLineBoxContentBottomOrBorderAndPadding(_ lineBox: LineBox) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
