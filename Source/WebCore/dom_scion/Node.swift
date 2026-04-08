/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2020 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

class NodeWrapper {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  func parentElement() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSibling() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nodeHasChildNodes() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSVGElement() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPseudoElement() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBeforePseudoElement() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAfterPseudoElement() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isDocumentNode() -> Bool {
    return wk_interop.Node_isDocumentNode(p)
  }

  func hasCustomStyleResolveCallbacks() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsSVGRendererUpdate() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsSVGRendererUpdate(flag: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // If this node is in a shadow tree, returns its shadow host. Otherwise, returns null.
  func shadowHost() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containingShadowRoot() -> ShadowRootWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasEverPaintedImages() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasEverPaintedImages(hasEverPaintedImages: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parentElementInComposedTree() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parentOrShadowHostElement() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the enclosing event parent Element (or self) that, when clicked, would trigger a navigation.
  func enclosingLinkEventParentOrSelf() -> ElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRootEditableElement() -> Bool {
    return wk_interop.Node_isRootEditableElement(p)
  }

  func isEditingText() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum UserSelectAllTreatment {
    case NotEditable
    case Editable
  }

  func hasEditableStyle(_ treatment: UserSelectAllTreatment = .NotEditable) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeNodeIndex() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the document associated with this node. A document node returns itself.
  func document() -> Document {
    return Document(wk_interop.Node_document(p))
  }

  func countChildNodes() -> UInt32 { return 0 }

  func isDescendantOf(_ other: NodeWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // -----------------------------------------------------------------------------
  // Integration with rendering tree

  // As renderer() includes a branch you should avoid calling it repeatedly in hot code paths.
  func renderer() -> RenderObjectWrapper? {
    guard let raw = wk_interop.Node_renderer(p) else { return nil }
    assert(!wk_interop.RenderObject_isRenderView(raw))
    return createRenderObjectWrapper(raw)
  }

  func setRenderer(renderer: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Use these two methods with caution.
  func renderBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedStyle() -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTextPathTagName() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasUseTagName() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let p: UnsafeMutableRawPointer
}
