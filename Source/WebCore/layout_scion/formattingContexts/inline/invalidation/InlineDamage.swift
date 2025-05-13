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

import wk_interop

struct InlineDamageWrapper {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  struct Reason: OptionSet {
    let rawValue: UInt32
    static let Append = Reason(rawValue: 1 << 0)
    static let Insert = Reason(rawValue: 1 << 1)
    static let Remove = Reason(rawValue: 1 << 2)
    static let ContentChange = Reason(rawValue: 1 << 3)
    static let StyleChange = Reason(rawValue: 1 << 4)
    static let Pagination = Reason(rawValue: 1 << 5)
  }

  func reasons() -> Reason {
    return damageReasons
  }

  // FIXME: Add support for damage range with multiple, different damage types.
  struct LayoutPosition {
    var lineIndex: UInt64 = 0
    var inlineItemPosition = InlineItemPosition()
    var partialContentTop = LayoutUnit()
  }
  func layoutStartPosition() -> LayoutPosition? {
    let rawPosition = wk_interop.InlineDamage_layoutStartPosition(p)
    if !rawPosition.is_valid {
      return nil
    }
    return LayoutPosition(
      lineIndex: rawPosition.line_index,
      inlineItemPosition: InlineItemPosition(
        index: rawPosition.inline_item_position.index,
        offset: rawPosition.inline_item_position.offset),
      partialContentTop: LayoutUnit.fromRawValue(value: rawPosition.partial_content_top)
    )
  }

  func trailingContentForLine(lineIndex: UInt64) -> InlineDisplay.Box? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addDetachedBox(layoutBox: BoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInlineItemListDirty() -> Bool {
    return wk_interop.InlineDamage_isInlineItemListDirty(p)
  }

  func setInlineItemListClean() {
    wk_interop.InlineDamage_setInlineItemListClean(p)
  }

  var p: UnsafeMutableRawPointer
  var damageReasons = Reason(rawValue: 0)
}
