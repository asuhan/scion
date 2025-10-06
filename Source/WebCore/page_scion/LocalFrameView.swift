/*
   Copyright (C) 1997 Martin Jones (mjones@kde.org)
             (C) 1998 Waldo Bastian (bastian@kde.org)
             (C) 1998, 1999 Torben Weis (weis@kde.org)
             (C) 1999 Lars Knoll (knoll@kde.org)
             (C) 1999 Antti Koivisto (koivisto@kde.org)
   Copyright (C) 2004-2019 Apple Inc. All rights reserved.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

import wk_interop

class LocalFrameViewWrapper: FrameViewWrapper {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func layoutContext() -> LocalFrameViewLayoutContextWrapper {
    return LocalFrameViewLayoutContextWrapper(p: wk_interop.LocalFrameView_layoutContext(p))
  }

  // Called when changes to the GraphicsLayer hierarchy have to be synchronized with
  // content rendered via the normal painting path.
  func setNeedsOneShotDrawingSynchronization() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baseBackgroundColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasExtendedBackgroundRectForPainting() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func extendedBackgroundRectForPainting() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContentIsOpaque(contentIsOpaque: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameScaleFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Functions for querying the current scrolled position, negating the effects of overhang
  // and adjusting for page scale.
  func scrollPositionForFixedPosition() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintBehavior() -> PaintBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFlippedBlockRenderers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerAccessPrevented() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var p: UnsafeRawPointer
}
