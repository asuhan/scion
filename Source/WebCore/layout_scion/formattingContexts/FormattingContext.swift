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

class FormattingContext {
  init(formattingContextRoot: ElementBoxWrapper, layoutState: LayoutStateWrapper) {
    self.root = formattingContextRoot
    self.layoutState = layoutState
  }

  func layoutInFlowContent(constraints: ConstraintsForInFlowContent) {}

  func computedIntrinsicWidthConstraints() -> IntrinsicWidthConstraints {
    return IntrinsicWidthConstraints()
  }

  func usedContentHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum EscapeReason {
    case TableQuirkNeedsGeometryFromEstablishedFormattingContext
    case OutOfFlowBoxNeedsInFlowGeometry
    case FloatBoxIsAlwaysRelativeToFloatStateRoot
    case FindFixedHeightAncestorQuirk
    case DocumentBoxStretchesToViewportQuirk
    case BodyStretchesToViewportQuirk
    case TableNeedsAccessToTableWrapper
  }

  func geometryForBox(layoutBox: BoxWrapper, escapeReason: EscapeReason? = nil) -> BoxGeometry {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func initialContainingBlock(layoutBox: BoxWrapper) -> InitialContainingBlock {
    if layoutBox.isInitialContainingBlock() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    var ancestor = layoutBox.parent()
    while !ancestor.isInitialContainingBlock() {
      ancestor = ancestor.parent()
    }
    return ancestor as! InitialContainingBlock
  }

  static func containingBlock(layoutBox: BoxWrapper) -> ElementBoxWrapper {
    // If we ever end up here with the ICB, we must be doing something not-so-great.
    assert(layoutBox as? InitialContainingBlock == nil)
    // The containing block in which the root element lives is a rectangle called the initial containing block.
    // For other elements, if the element's position is 'relative' or 'static', the containing block is formed by the
    // content edge of the nearest block container ancestor box or which establishes a formatting context.
    // If the element has 'position: fixed', the containing block is established by the viewport
    // If the element has 'position: absolute', the containing block is established by the nearest ancestor with a
    // 'position' of 'absolute', 'relative' or 'fixed'.
    if !layoutBox.isPositioned() || layoutBox.isInFlowPositioned() {
      var ancestor = layoutBox.parent()
      while ancestor as? InitialContainingBlock == nil {
        if ancestor.isContainingBlockForInFlow() {
          return ancestor
        }
        ancestor = ancestor.parent()
      }
      return ancestor
    }

    if layoutBox.isFixedPositioned() {
      var ancestor = layoutBox.parent()
      while ancestor as? InitialContainingBlock == nil {
        if ancestor.isContainingBlockForFixedPosition() {
          return ancestor
        }
        ancestor = ancestor.parent()
      }
      return ancestor
    }

    if layoutBox.isOutOfFlowPositioned() {
      var ancestor = layoutBox.parent()
      while ancestor as? InitialContainingBlock == nil {
        if ancestor.isContainingBlockForOutOfFlowPosition() {
          return ancestor
        }
        ancestor = ancestor.parent()
      }
      return ancestor
    }

    fatalError("Not reached")
  }

  var root: ElementBoxWrapper
  var layoutState: LayoutStateWrapper
}
