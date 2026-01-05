/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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

struct CompositedClipData {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let clippingLayer: RenderLayerWrapper? = nil  // For scroller entries, the scrolling layer. For other entries, the most-descendant layer that has a clip.
  let isOverflowScroll = false
}

// This class encapsulates the set of layers and their scrolling tree nodes representing clipping in the layer's containing block ancestry,
// but not in its paint order ancestry.
class LayerAncestorClippingStack {
  func hasAnyScrollingLayers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func detachFromScrollingCoordinator(scrollingCoordinator: ScrollingCoordinatorWrapper) {
    for var entry in stack {
      if entry.overflowScrollProxyNodeID.bool() {
        scrollingCoordinator.unparentChildrenAndDestroyNode(nodeID: entry.overflowScrollProxyNodeID)
        entry.overflowScrollProxyNodeID = ScrollingNodeIDWrapper()
      }
    }
  }

  func firstLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastLayer() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct ClippingStackEntry {
    let clipData: CompositedClipData
    var overflowScrollProxyNodeID = ScrollingNodeIDWrapper()  // The node for repositioning the scrolling proxy layer.
    let clippingLayer: GraphicsLayer? = nil
  }

  let stack: [ClippingStackEntry] = []
}
