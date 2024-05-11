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

struct InlineInvalidation {
  init(
    inlineDamage: InlineDamageWrapper, inlineItemList: InlineItemList,
    displayContent: InlineDisplay.Content
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rootStyleWillChange(formattingContextRoot: ElementBoxWrapper, newStyle: RenderStyleWrapper)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func styleWillChange(layoutBox: BoxWrapper, newStyle: RenderStyleWrapper, diff: StyleDifference)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textInserted(newOrDamagedInlineTextBox: InlineTextBoxWrapper, offset: UInt64? = nil) -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textWillBeRemoved(damagedInlineTextBox: InlineTextBoxWrapper, offset: UInt64? = nil) -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inlineLevelBoxInserted(layoutBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inlineLevelBoxWillBeRemoved(layoutBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inlineLevelBoxContentWillChange(layoutBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func restartForPagination(lineIndex: UInt64, pageTopAdjustment: LayoutUnit) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func mayOnlyNeedPartialLayout(inlineDamage: InlineDamageWrapper?) -> Bool {
    if let inlineDamage = inlineDamage {
      return inlineDamage.layoutStartPosition() != nil
    }
    return false
  }

  static func resetInlineDamage(inlineDamage: InlineDamageWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
