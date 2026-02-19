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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func hasClosedLeftAndRightEdge() -> (Bool, Bool) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func nextInlineBox() -> InlineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func previousInlineBox() -> InlineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func iterator() -> InlineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func firstLeafBox() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func endLeafBox() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  static func firstInlineBoxFor(renderInline: RenderInlineWrapper) -> InlineBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func firstRootInlineBoxFor(_ block: RenderBlockFlowWrapper) -> InlineBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
      pathVariant: InlineIterator.BoxModernPath(inlineContent: content, startIndex: boxIndex))
  }

  class InlineBoxIterator: BoxIterator<InlineBox> {
    override init() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    init(pathVariant: BoxPath) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    init(box: InlineIterator.Box) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    @discardableResult
    func traverseNextInlineBox() -> InlineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    @discardableResult
    func traversePreviousInlineBox() -> InlineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }
}
