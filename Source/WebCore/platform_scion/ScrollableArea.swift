/*
 * Copyright (c) 2010-2023 Google Inc. All rights reserved.
 * Copyright (C) 2008-2024 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

class ScrollableAreaWrapper {
  init(_ p: UnsafeMutableRawPointer?) {
    self.pInterop = p
  }

  func horizontalScrollbarMode() -> ScrollbarMode {
    return ScrollbarMode(rawValue: wk_interop.ScrollableArea_horizontalScrollbarMode(pInterop!))!
  }

  func verticalScrollbarMode() -> ScrollbarMode {
    return ScrollbarMode(rawValue: wk_interop.ScrollableArea_verticalScrollbarMode(pInterop!))!
  }

  func scrollbarGutterStyle() -> ScrollbarGutter {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollbarWidthStyle() -> ScrollbarWidth {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inLiveResize() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This returns information about existing scrollbars, not scrollbars that may be created in future.
  func hasOverlayScrollbars() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollingNodeID() -> ScrollingNodeIDWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollAnimator() -> ScrollAnimatorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollbarsController() -> ScrollbarsControllerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateScrollbar(scrollbar: Scrollbar, rect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isScrollCornerVisible() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollCornerRect() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateScrollCorner(rect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func horizontalScrollbar() -> Scrollbar? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func verticalScrollbar() -> Scrollbar? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollPosition() -> ScrollPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollOffset() -> ScrollOffset {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentScrollType() -> ScrollType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum VisibleContentRectIncludesScrollbars {
    case No
    case Yes
  }

  func visibleContentRect() -> IntRect {
    // TODO(asuhan): add iOS support
    let r = wk_interop.ScrollableArea_visibleContentRect(pInterop!)
    return IntRect(x: r.location.x, y: r.location.y, width: r.size.width, height: r.size.height)
  }

  func contentsSize() -> IntSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func useDarkAppearance() -> Bool { return wk_interop.ScrollableArea_useDarkAppearance(pInterop!) }

  func layerForHorizontalScrollbar() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerForVerticalScrollbar() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldPlaceVerticalScrollbarOnLeft() -> Bool {
    fatalError("Not reached")
  }

  func scrollbarWidthChanged(_ width: ScrollbarWidth) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setScrollOrigin(_ origin: IntPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateScrollCornerRect(rect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerForScrollCorner() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isNativeImpl() -> Bool { return pInterop == nil }

  // This reflects animated scrolls triggered by CSS OM View "smooth" scrolls.
  let scrollAnimationStatus: ScrollAnimationStatus = .NotAnimating

  let pInterop: UnsafeMutableRawPointer?
}
