/*
 * Copyright (c) 2024 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

private func rootLayoutBox(box: ElementBoxWrapper) -> ElementBoxWrapper {
  var ancestor = box.parent()
  while !ancestor.isInitialContainingBlock() {
    if ancestor.establishesFormattingContext() {
      break
    }
    ancestor = ancestor.parent()
  }
  return ancestor
}

extension LayoutIntegration {
  static func layoutWithFormattingContextForBox(
    box: ElementBoxWrapper, widthConstraint: LayoutUnit?, layoutState: LayoutStateWrapper
  ) {
    let renderer = box.rendererForIntegration() as! RenderBoxWrapper

    if let widthConstraint = widthConstraint {
      renderer.setOverridingLogicalWidthLength(
        height: LengthWrapper(value: widthConstraint, type: .Fixed))
      renderer.setNeedsLayout(markParents: .MarkOnlyThis)
    }

    renderer.layoutIfNeeded()

    if widthConstraint != nil {
      renderer.clearOverridingLogicalWidthLength()
    }

    var updater = BoxGeometryUpdater(
      layoutState: layoutState, rootLayoutBox: rootLayoutBox(box: box))
    updater.updateBoxGeometryAfterIntegrationLayout(
      layoutBox: box,
      availableWidth: widthConstraint ?? renderer.containingBlock()!.availableLogicalWidth())
  }
}
