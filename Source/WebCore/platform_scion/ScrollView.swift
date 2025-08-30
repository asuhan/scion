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

class ScrollViewWrapper: ScrollableAreaWrapper, Widget {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fixedLayoutSize() -> IntSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func useFixedLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // scrollPostion() anchors its (0,0) point at the ScrollableArea's origin. The top of the scrolling
  // layer does not represent the top of the view when there is a topContentInset. Additionally, as
  // detailed above, the origin of the scrolling layer also does not necessarily correspond with the
  // top of the document anyway, since there could also be header. documentScrollPositionRelativeToViewOrigin()
  // will return a version of the current scroll offset which tracks the top of the Document
  // relative to the very top of the view.
  func documentScrollPositionRelativeToViewOrigin() -> ScrollPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> IntSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
