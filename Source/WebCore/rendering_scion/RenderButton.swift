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

final class RenderButtonWrapper: RenderFlexibleBoxWrapper {
  override func createsAnonymousWrapper() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func hasControlClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateAnonymousChildStyle(_ childStyle: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func innerRenderer() -> RenderBlockWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInnerRenderer(innerRenderer: RenderBlockWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func hasLineIfEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isFlexibleBoxImpl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
