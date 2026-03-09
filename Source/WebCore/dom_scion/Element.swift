/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Peter Kelly (pmk@post.com)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
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

class ElementWrapper: ContainerNodeWrapper {
  func hasNowrapAttr() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAltAttr() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasViewBoxAttr() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFontTag() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSvgClipRuleAttrWithoutSynchronization() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createElementRenderer(style: RenderStyleWrapper, insertionPosition: RenderTreePosition)
    -> RenderElementWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rendererIsNeeded(style: RenderStyleWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shadowRootFromElement() -> ShadowRootWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedStyleForEditability() -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ensurePseudoElement(pseudoId: PseudoId) -> PseudoElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func beforePseudoElement() -> PseudoElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func afterPseudoElement() -> PseudoElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFormControlElement() -> Bool { return wk_interop.Element_isFormControlElement(p) }

  // Used for disabled form elements; if true, prevents mouse events from being dispatched
  // to event listeners, and prevents DOMActivate events from being sent at all.
  func isDisabledFormControl() -> Bool { return wk_interop.Element_isDisabledFormControl(p) }

  func childShouldCreateRenderer(child: NodeWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func keyframeEffectStack(pseudoElementIdentifier: Style.PseudoElementIdentifier?)
    -> KeyframeEffectStackWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInTopLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func savedLayerScrollPosition() -> ScrollPosition {
    let raw = wk_interop.Element_savedLayerScrollPosition(p)
    return ScrollPosition(x: raw.x, y: raw.y)
  }

  func setSavedLayerScrollPosition(_ position: ScrollPosition) {
    wk_interop.Element_setSavedLayerScrollPosition(p, IntPointRaw(x: position.x, y: position.y))
  }

  func willAttachRenderers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func didAttachRenderers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willDetachRenderers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func didDetachRenderers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func renderOrDisplayContentsStyle() -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearBeforePseudoElement() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearAfterPseudoElement() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearHoverAndActiveStatusBeforeDetachingRenderer() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func styleResolver() -> Style.Resolver {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasDisplayContents() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func storeDisplayContentsOrNoneStyle(style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearDisplayContentsOrNoneStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastRememberedLogicalWidth() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastRememberedLogicalHeight() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearLastRememberedLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearLastRememberedLogicalHeight() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRelevantToUser() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

func isInTopLayerOrBackdrop(style: RenderStyleWrapper, element: ElementWrapper?) -> Bool {
  return (element != nil && element!.isInTopLayer()) || style.pseudoElementType() == .Backdrop
}
