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

class InlineContentCache {
  class InlineItems {
    func content() -> InlineItemList { return inlineItemList }

    func clearContent() {
      inlineItemList.removeAll()
    }

    struct ContentAttributes {
      var requiresVisualReordering = false
      // Note that <span>this is text</span> returns true as inline boxes are not considered 'content' here.
      var hasTextAndLineBreakOnlyContent = false
      var inlineBoxCount: UInt64 = 0
    }

    func set(inlineItemList: InlineItemList, contentAttributes: ContentAttributes) {
      self.inlineItemList = inlineItemList
      self.contentAttributes = contentAttributes
    }

    func shrinkToFit() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func replace(
      insertionPosition: UInt64, inlineItemList: InlineItemList,
      contentAttributes: ContentAttributes
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isEmpty() -> Bool {
      return content().count == 0
    }

    func requiresVisualReordering() -> Bool {
      return contentAttributes.requiresVisualReordering
    }

    func hasTextAndLineBreakOnlyContent() -> Bool {
      return contentAttributes.hasTextAndLineBreakOnlyContent
    }

    func hasInlineBoxes() -> Bool {
      return inlineBoxCount() != 0
    }

    func inlineBoxCount() -> UInt64 {
      return contentAttributes.inlineBoxCount
    }

    var contentAttributes = ContentAttributes()
    var inlineItemList = InlineItemList()
  }

  func clearMaximumIntrinsicWidthLineContent() {
    maximumIntrinsicWidthLineContent = nil
  }

  func resetMinimumMaximumContentSizes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var inlineItems = InlineItems()
  var maximumIntrinsicWidthLineContent: LineLayoutResult? = nil
  var minimumContentSize: InlineLayoutUnit? = nil
  var maximumContentSize: InlineLayoutUnit? = nil
}
