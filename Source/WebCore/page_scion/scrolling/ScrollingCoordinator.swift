/*
 * Copyright (C) 2011, 2015 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

class ScrollingCoordinatorWrapper {
  // Return whether this scrolling coordinator handles scrolling for the given frame view.
  func coordinatesScrollingForFrameView(frameView: LocalFrameViewWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return whether this scrolling coordinator handles scrolling for the given overflow scroll layer.
  func coordinatesScrollingForOverflowLayer(layer: RenderLayerWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Should be called whenever the set of fixed objects changes.
  func frameViewFixedObjectsDidChange(frameView: LocalFrameViewWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Should be called whenever the root layer for the given frame view changes.
  func frameViewRootLayerDidChange(frameView: LocalFrameViewWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameViewWillBeDetached(frameView: LocalFrameViewWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Node will be unparented, but not destroyed. It's the client's responsibility to either re-parent or destroy this node.
  func unparentNode(nodeID: ScrollingNodeIDWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Node will be destroyed, and its children left unparented.
  func unparentChildrenAndDestroyNode(nodeID: ScrollingNodeIDWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSubscrollers(_ rootFrameID: FrameIdentifierWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollableAreaScrollbarLayerDidChange(
    scrollableArea: ScrollableAreaWrapper, orientation: ScrollbarOrientation
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
