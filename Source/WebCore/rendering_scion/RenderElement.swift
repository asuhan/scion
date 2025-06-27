/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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
 */

import wk_interop

class RenderElementWrapper: RenderObjectWrapper {
  func element() -> ElementWrapper? {
    if let elementRaw = wk_interop.RenderElement_element(p) {
      return ElementWrapper(p: elementRaw)
    }
    return nil
  }

  func firstChild() -> RenderObjectWrapper? {
    if let childRaw = wk_interop.RenderElement_firstChild(p) {
      return RenderObjectWrapper(p: childRaw)
    }
    return nil
  }

  override func layoutBox() -> ElementBoxWrapper? {
    return super.layoutBox() as? ElementBoxWrapper
  }

  // Obtains the selection colors that should be used when painting a selection.
  func selectionBackgroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionForegroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setChildNeedsLayout(markParents: MarkingBehavior = .MarkContainingBlockChain) {
    wk_interop.RenderElement_setChildNeedsLayout(p, markParents.rawValue)
  }

  /* This function performs a layout only if one is needed. */
  func layoutIfNeeded() {
    wk_interop.RenderElement_layoutIfNeeded(p)
  }

  func visibleToHitTesting(request: HitTestRequestWrapper? = nil) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSelfPaintingLayer() -> Bool {
    return wk_interop.RenderElement_hasSelfPaintingLayer(p)
  }

  func checkForRepaintDuringLayout() -> Bool {
    return wk_interop.RenderElement_checkForRepaintDuringLayout(p)
  }

  func isContinuation() -> Bool {
    return wk_interop.RenderElement_isContinuation(p)
  }

  func isWritingModeRoot() -> Bool {
    return wk_interop.RenderElement_isWritingModeRoot(p)
  }
}
