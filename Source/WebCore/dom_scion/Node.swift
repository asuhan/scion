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
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func hasCustomStyleResolveCallbacks() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsSVGRendererUpdate() -> Bool {
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

  func isRootEditableElement() -> Bool {
    return wk_interop.Node_isRootEditableElement(p)
  }

  // -----------------------------------------------------------------------------
  // Integration with rendering tree

  // As renderer() includes a branch you should avoid calling it repeatedly in hot code paths.
  func renderer() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  let p: UnsafeRawPointer
}
