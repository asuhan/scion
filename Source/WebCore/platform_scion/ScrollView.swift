/*
 * Copyright (C) 2004-2018 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Holger Hans Peter Freyther
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

enum DelegatedScrollingMode: UInt8 {
  case NotDelegated
  case DelegatedToNativeScrollView
  case DelegatedToWebKit
}

class ScrollViewWrapper: ScrollableAreaWrapper, Widget {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  // Returns a clip rect in host window coordinates. Used to clip the blit on a scroll.
  func windowClipRect() -> IntRect {
    let rect = wk_interop.ScrollView_windowClipRect(p)
    return IntRect(
      x: rect.location.x, y: rect.location.y, width: rect.size.width, height: rect.size.height)
  }

  func positionScrollbarLayers() { wk_interop.ScrollView_positionScrollbarLayers(p) }

  // By default scrolling is handled by WebCore, but some WebKit implementations take over scrolling,
  // delegating it to a native scrolling widget or the UI process.
  func delegatedScrollingMode() -> DelegatedScrollingMode {
    return DelegatedScrollingMode(rawValue: wk_interop.ScrollView_delegatedScrollingMode(p))!
  }

  // There are at least three types of contentInset. Usually we just care about WebCoreContentInset, which is the inset
  // that is set on a Page that requires WebCore to move its layers to accomodate the inset. However, there are platform
  // concepts that are similar on both iOS and Mac when there is a platformWidget(). Sometimes we need the Mac platform value
  // for topContentInset, so when the TopContentInsetType is WebCoreOrPlatformContentInset, platformTopContentInset()
  // will be returned instead of the value set on Page.
  enum TopContentInsetType {
    case WebCoreContentInset
    case WebCoreOrPlatformContentInset
  }

  // Size available for view contents, including content inset areas. Not affected by zooming.
  func sizeForVisibleContent(scrollbarInclusion: VisibleContentRectIncludesScrollbars = .No)
    -> IntSize
  {
    let size = wk_interop.ScrollView_sizeForVisibleContent(p, scrollbarInclusion == .Yes)
    return IntSize(width: size.width, height: size.height)
  }

  // Functions for getting/setting the size webkit should use to layout the contents. By default this is the same as the visible
  // content size. Explicitly setting a layout size value will cause webkit to layout the contents using this size instead.
  func layoutSize() -> IntSize {
    let size = wk_interop.ScrollView_layoutSize(p)
    return IntSize(width: size.width, height: size.height)
  }

  func layoutWidth() -> Int32 { return wk_interop.ScrollView_layoutWidth(p) }

  func layoutHeight() -> Int32 { return wk_interop.ScrollView_layoutHeight(p) }

  func fixedLayoutSize() -> IntSize {
    let size = wk_interop.ScrollView_fixedLayoutSize(p)
    return IntSize(width: size.width, height: size.height)
  }

  func useFixedLayout() -> Bool { return wk_interop.ScrollView_useFixedLayout(p) }

  override func contentsSize() -> IntSize {
    let size = wk_interop.ScrollView_contentsSize(p)
    return IntSize(width: size.width, height: size.height)
  }

  func contentsWidth() -> Int32 { return contentsSize().width }

  func contentsHeight() -> Int32 { return contentsSize().height }

  // scrollPostion() anchors its (0,0) point at the ScrollableArea's origin. The top of the scrolling
  // layer does not represent the top of the view when there is a topContentInset. Additionally, as
  // detailed above, the origin of the scrolling layer also does not necessarily correspond with the
  // top of the document anyway, since there could also be header. documentScrollPositionRelativeToViewOrigin()
  // will return a version of the current scroll offset which tracks the top of the Document
  // relative to the very top of the view.
  func documentScrollPositionRelativeToViewOrigin() -> ScrollPosition {
    let position = wk_interop.ScrollView_documentScrollPositionRelativeToViewOrigin(p)
    return ScrollPosition(x: position.x, y: position.y)
  }

  func windowToContents(windowRect: IntRect) -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The purpose of this function is to answer whether or not the scroll view is currently visible. Animations and painting updates can be suspended if
  // we know that we are either not in a window right now or if that window is not visible.
  func isOffscreen() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func managesScrollbars() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateScrollbarSteps() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func platformWidget() -> PlatformWidget {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func width() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func height() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> IntSize {
    let intSizeRaw = wk_interop.ScrollView_size(p)
    return IntSize(width: intSizeRaw.width, height: intSizeRaw.height)
  }

  func location() -> IntPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFrameRect(_ rect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameRect() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paint(
    _ context: GraphicsContextWrapper, _ rect: IntRect,
    _ securityOriginPaintPolicy: SecurityOriginPaintPolicy = .AnyOrigin,
    _ regionContext: RegionContext? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func show() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hide() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func repaintContentRectangle(_ rect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var p: UnsafeMutableRawPointer
}
