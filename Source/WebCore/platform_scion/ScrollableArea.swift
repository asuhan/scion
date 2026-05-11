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
    let style = wk_interop.ScrollableArea_scrollbarGutterStyle(pInterop!)
    return ScrollbarGutter(isAuto: style.isAuto, bothEdges: style.bothEdges)
  }

  func scrollbarWidthStyle() -> ScrollbarWidth {
    return ScrollbarWidth(rawValue: wk_interop.ScrollableArea_scrollbarWidthStyle(pInterop!))!
  }

  func inLiveResize() -> Bool { return wk_interop.ScrollableArea_inLiveResize(pInterop!) }

  // This returns information about existing scrollbars, not scrollbars that may be created in future.
  func hasOverlayScrollbars() -> Bool {
    return wk_interop.ScrollableArea_hasOverlayScrollbars(pInterop!)
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
    return ScrollbarsControllerWrapper(wk_interop.ScrollableArea_scrollbarsController(pInterop!))
  }

  func invalidateScrollbar(scrollbar: Scrollbar, rect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isScrollCornerVisible() -> Bool {
    return wk_interop.ScrollableArea_isScrollCornerVisible(pInterop!)
  }

  func scrollCornerRect() -> IntRect {
    let r = wk_interop.ScrollableArea_scrollCornerRect(pInterop!)
    return IntRect(x: r.location.x, y: r.location.y, width: r.size.width, height: r.size.height)
  }

  func invalidateScrollCorner(rect: IntRect) {
    wk_interop.ScrollableArea_invalidateScrollCorner(
      pInterop!,
      IntRectRaw(
        location: IntPointRaw(x: rect.location.x, y: rect.location.y),
        size: IntSizeRaw(width: rect.size.width, height: rect.size.height)))
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
    let p = wk_interop.ScrollableArea_scrollPosition(pInterop!)
    return ScrollPosition(x: p.x, y: p.y)
  }

  func scrollOffset() -> ScrollOffset {
    let p = wk_interop.ScrollableArea_scrollOffset(pInterop!)
    return ScrollOffset(x: p.x, y: p.y)
  }

  func currentScrollType() -> ScrollType {
    return wk_interop.ScrollableArea_currentScrollType(pInterop!) ? .Programmatic : .User
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
    let size = wk_interop.ScrollableArea_contentsSize(pInterop!)
    return IntSize(width: size.width, height: size.height)
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
    wk_interop.ScrollableArea_scrollbarWidthChanged(pInterop!, width.rawValue)
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
