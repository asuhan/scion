/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
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

  class InlineBox: Box {
    override func renderer() -> RenderBoxModelObjectWrapper {
      return super.renderer() as! RenderBoxModelObjectWrapper
    }

    func hasClosedLeftAndRightEdge() -> (Bool, Bool) {
      // FIXME: Layout knows the answer to this question so we should consult it.
      if style().boxDecorationBreak() == .Clone {
        return (true, true)
      }
      let isLTR = style().isLeftToRightDirection()
      let isFirst = !previousInlineBox().bool() && !renderer().isContinuation()
      let isLast = !nextInlineBox().bool() && renderer().continuation() == nil
      return (isLTR ? isFirst : isLast, isLTR ? isLast : isFirst)
    }

    func nextInlineBox() -> InlineBoxIterator {
      return InlineBoxIterator(box: self).traverseNextInlineBox()
    }

    func previousInlineBox() -> InlineBoxIterator {
      return InlineBoxIterator(box: self).traversePreviousInlineBox()
    }

    func iterator() -> InlineBoxIterator { return InlineBoxIterator(box: self) }

    func firstLeafBox() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func endLeafBox() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    override func deepCopy() -> InlineBox { return InlineBox(m_pathVariant) }
  }

  static func firstInlineBoxFor(renderInline: RenderInlineWrapper) -> InlineBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func firstRootInlineBoxFor(_ block: RenderBlockFlowWrapper) -> InlineBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func inlineBoxFor(legacyInlineFlowBox: LegacyInlineFlowBox) -> InlineBoxIterator {
    return InlineBoxIterator(pathVariant: .legacy(BoxLegacyPath(legacyInlineFlowBox)))
  }

  static func inlineBoxFor(content: LayoutIntegration.InlineContent, box: InlineDisplay.Box)
    -> InlineBoxIterator
  {
    return inlineBoxFor(content: content, boxIndex: content.indexForBox(box: box))
  }

  static func inlineBoxFor(content: LayoutIntegration.InlineContent, boxIndex: UInt64)
    -> InlineBoxIterator
  {
    assert(content.displayContent.boxes[Int(boxIndex)].isInlineBox())
    return InlineBoxIterator(
      pathVariant: .modern(BoxModernPath(inlineContent: content, startIndex: boxIndex)))
  }

  class InlineBoxIterator: BoxIterator {
    override init() { super.init() }

    init(pathVariant: Box.PathVariant) { super.init(pathVariant, kind: .Inline) }

    init(box: Box) { super.init(box) }

    @discardableResult
    func traverseNextInlineBox() -> InlineBoxIterator {
      switch m_box.m_pathVariant {
      case .modern(let path):
        path.traverseNextInlineBox()
      case .legacy(let path):
        path.traverseNextInlineBox()
      }
      return self
    }

    @discardableResult
    func traversePreviousInlineBox() -> InlineBoxIterator {
      switch m_box.m_pathVariant {
      case .modern(let path):
        path.traversePreviousInlineBox()
      case .legacy(let path):
        path.traversePreviousInlineBox()
      }
      return self
    }

    override func get() -> InlineBox { return m_box as! InlineBox }
  }
}
