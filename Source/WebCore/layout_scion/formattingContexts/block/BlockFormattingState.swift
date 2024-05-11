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

// BlockFormattingState holds the state for a particular block formatting context tree.
class BlockFormattingState: FormattingState {
  init(layoutState: LayoutStateWrapper, blockFormattingContextRoot: ElementBoxWrapper) {
    self.placedFloats = PlacedFloats(blockFormattingContextRoot: blockFormattingContextRoot)
    super.init(type: .Block, layoutState: layoutState)
  }

  // Since we layout the out-of-flow boxes at the end of the formatting context layout, it's okay to store them in the formatting state -as opposed to the containing block level.
  typealias OutOfFlowBoxList = [BoxWrapper]

  func addOutOfFlowBox(outOfFlowBox: BoxWrapper) {
    outOfFlowBoxes.append(outOfFlowBox)
  }

  func setUsedVerticalMargin(layoutBox: BoxWrapper, usedVerticalMargin: UsedVerticalMargin) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedVerticalMargin(layoutBox: BoxWrapper) -> UsedVerticalMargin {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasUsedVerticalMargin(layoutBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasClearance(layoutBox: BoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClearance(layoutBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shrinkToFit() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var placedFloats: PlacedFloats
  var outOfFlowBoxes = OutOfFlowBoxList()
}
