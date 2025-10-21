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

extension RenderTreeBuilder {
  class BlockFlow {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func attach(
      parent: RenderBlockFlowWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      if let multicolumnFlow = parent.multiColumnFlowForBlockFlow() {
        let legendAvoidsMulticolumn = parent.isFieldset() && child!.isLegend()
        if legendAvoidsMulticolumn {
          return builder.blockBuilder!.attach(parent: parent, child: child!, beforeChild: nil)
        }

        let legendBeforeChildIsIncorrect =
          parent.isFieldset() && beforeChild != nil && beforeChild!.isLegend()
        if legendBeforeChildIsIncorrect {
          return builder.blockBuilder!.attach(
            parent: multicolumnFlow, child: child!, beforeChild: nil)
        }

        // When the before child is set to be the first child of the RenderBlockFlow, we need to readjust it to be the first
        // child of the multicol conainter.
        return builder.attach(
          parent: multicolumnFlow, child: child!,
          beforeChild: CPtrToInt(beforeChild!.p) == CPtrToInt(multicolumnFlow.p)
            ? multicolumnFlow.firstChild() : beforeChild)
      }

      var beforeChildOrPlaceholder = beforeChild
      if let containingFragmentedFlow = parent.enclosingFragmentedFlow() {
        beforeChildOrPlaceholder = builder.multiColumnBuilder!.resolveMovedChild(
          enclosingFragmentedFlow: containingFragmentedFlow, beforeChild: beforeChild)
      }
      builder.blockBuilder!.attach(
        parent: parent, child: child!, beforeChild: beforeChildOrPlaceholder)
    }

    func moveAllChildrenIncludingFloats(
      from: RenderBlockFlowWrapper, to: RenderBlockWrapper,
      normalizeAfterInsertion: RenderTreeBuilder.NormalizeAfterInsertion
    ) {
      builder.moveAllChildren(from: from, to: to, normalizeAfterInsertion: normalizeAfterInsertion)
      from.addFloatsToNewParent(toBlockFlow: to as! RenderBlockFlowWrapper)
    }

    private let builder: RenderTreeBuilder
  }
}
