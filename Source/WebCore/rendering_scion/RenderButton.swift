/*
 * Copyright (C) 2005-2022 Apple Inc.
 * Copyright (C) 2022 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

import wk_interop

private func synthesizedBaselineFromContentBox(box: RenderBoxWrapper, direction: LineDirectionMode)
  -> LayoutUnit
{
  return direction == .HorizontalLine
    ? box.borderTop() + box.paddingTop() + box.contentHeight()
    : box.borderRight() + box.paddingRight() + box.contentWidth()
}

final class RenderButtonWrapper: RenderFlexibleBoxWrapper {
  init(_ element: HTMLFormControlElementWrapper, _ style: RenderStyleWrapper) {
    super.init(type: .Button, element: element, style: style)
    assert(isRenderButton())
  }

  func formControlElement() -> HTMLFormControlElementWrapper {
    assert(isNativeImpl())
    return nodeForNonAnonymous() as! HTMLFormControlElementWrapper
  }

  override func canBeSelectionLeaf() -> Bool {
    assert(isNativeImpl())
    return formControlElement().hasEditableStyle()
  }

  override func createsAnonymousWrapper() -> Bool { return true }

  // Only clip overflow on input elements, to match other browsers.
  override func hasControlClip() -> Bool {
    assert(isNativeImpl())
    return formControlElement() is HTMLInputElementWrapper
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    assert(isNativeImpl())
    // Clip to the padding box to at least give content the extra padding space.
    return LayoutRectWrapper(
      x: additionalOffset.x + borderLeft(), y: additionalOffset.y + borderTop(),
      width: width() - borderLeft() - borderRight(), height: height() - borderTop() - borderBottom()
    )
  }

  override func updateAnonymousChildStyle(_ childStyle: RenderStyleWrapper) {
    assert(isNativeImpl())
    childStyle.setFlexGrow(1)

    // min-inline-size: 0; is needed for correct shrinking.
    // Use margin-block:auto instead of align-items:center to get safe centering, i.e.
    // when the content overflows, treat it the same as align-items: flex-start.
    if isHorizontalWritingMode() {
      childStyle.setMinWidth(LengthWrapper(value: Int32(0), type: .Fixed))
      childStyle.setMarginTop(LengthWrapper())
      childStyle.setMarginBottom(LengthWrapper())
    } else {
      childStyle.setMinHeight(LengthWrapper(value: Int32(0), type: .Fixed))
      childStyle.setMarginLeft(LengthWrapper())
      childStyle.setMarginRight(LengthWrapper())
    }
    childStyle.setFlexDirection(style().flexDirection())
    childStyle.setJustifyContent(style().justifyContent())
    childStyle.setFlexWrap(style().flexWrap())
    childStyle.setAlignItems(style().alignItems())
    childStyle.setAlignContent(style().alignContent())
  }

  func updateFromElement() {
    assert(isNativeImpl())
    // If we're an input element, we may need to change our button text.
    if let input = formControlElement() as? HTMLInputElementWrapper {
      let value = input.valueWithDefault()
      setText(value)
    }
  }

  func setText(_ str: StringWrapper) {
    assert(isNativeImpl())
    if m_buttonText == nil && str.isEmpty() {
      return
    }

    if m_buttonText == nil {
      let newButtonText = wk_interop.RenderTextFragment_createFromContentString(
        document().p, str.p)!
      m_buttonText =
        (createRenderObjectWrapperOrNative(newButtonText) as! RenderTextFragmentWrapper)
      // FIXME: This mutation should go through the normal RenderTreeBuilder path.
      wk_interop.RenderTreeBuilder_attach(getWk(), newButtonText)
      return
    }

    if !str.isEmpty() {
      m_buttonText!.setText(newContent: str)
      return
    }
    wk_interop.RenderTreeBuilder_destroy(m_buttonText!.getWk())
  }

  func textRenderer() -> RenderTextFragmentWrapper? {
    assert(isNativeImpl())
    return m_buttonText
  }

  func innerRenderer() -> RenderBlockWrapper? {
    assert(isNativeImpl())
    return m_inner
  }

  func setInnerRenderer(innerRenderer: RenderBlockWrapper) {
    assert(isNativeImpl())
    assert(m_inner == nil)
    m_inner = innerRenderer
    updateAnonymousChildStyle(m_inner!.mutableStyle())

    if m_inner != nil && m_inner!.layoutBox() != nil {
      if let inlineFormattingContextRoot = m_inner as? RenderBlockFlowWrapper {
        inlineFormattingContextRoot.inlineLayout()?.rootStyleWillChange(
          root: inlineFormattingContextRoot, newStyle: inlineFormattingContextRoot.style())
      }
      if let lineLayout = LayoutIntegration.LineLayout.containing(renderer: m_inner!) {
        lineLayout.styleWillChange(renderer: m_inner!, newStyle: m_inner!.style(), diff: .Layout)
      }
      LayoutIntegration.LineLayout.updateStyle(m_inner!)
      for child: RenderTextWrapper in childrenOfType(parent: m_inner!) {
        LayoutIntegration.LineLayout.updateStyle(child)
      }
    }
  }

  override final func baselinePosition(
    baselineType: FontBaseline, firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  ) -> LayoutUnit {
    if !isNativeImpl() {
      return LayoutUnit.fromRawValue(
        value: wk_interop.RenderBoxModelObject_baselinePosition(
          id(), baselineType.rawValue, firstLine, direction.rawValue, linePositionMode.rawValue))
    }
    if shouldApplyLayoutContainment() {
      return super.baselinePosition(
        baselineType: baselineType, firstLine: firstLine, direction: direction,
        linePositionMode: linePositionMode)
    }
    // We cannot rely on RenderFlexibleBox::baselinePosition() because of flexboxes have some special behavior
    // regarding baselines that shouldn't apply to buttons.
    let baseline =
      firstLineBaseline() ?? synthesizedBaselineFromContentBox(box: self, direction: direction)
    let marginAscent = direction == .HorizontalLine ? marginTop() : marginRight()
    return baseline + marginAscent
  }

  override func hasLineIfEmpty() -> Bool {
    assert(isNativeImpl())
    return formControlElement() is HTMLInputElementWrapper
  }

  override func isFlexibleBoxImpl() -> Bool {
    assert(isNativeImpl())
    return true
  }

  private weak var m_buttonText: RenderTextFragmentWrapper? = nil
  private weak var m_inner: RenderBlockWrapper? = nil
}
