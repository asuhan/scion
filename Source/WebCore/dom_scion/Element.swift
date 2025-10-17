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

class ElementWrapper: ContainerNodeWrapper {
  func hasFontTag() -> Bool {
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

  func beforePseudoElement() -> PseudoElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func afterPseudoElement() -> PseudoElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func childShouldCreateRenderer(child: NodeWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInTopLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func clearHoverAndActiveStatusBeforeDetachingRenderer() {
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

  func clearLastRememberedLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearLastRememberedLogicalHeight() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

func isInTopLayerOrBackdrop(style: RenderStyleWrapper, element: ElementWrapper?) -> Bool {
  return (element != nil && element!.isInTopLayer()) || style.pseudoElementType() == .Backdrop
}
