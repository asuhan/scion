/*
 * Copyright (C) 2010 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

enum PluginLayerHostingStrategy {
  case None
  case PlatformLayer
  case GraphicsLayer
}

// FIXME: Move these virtual functions all into the Widget class and get rid of this class.
class PluginViewBase: Widget {
  func layerHostingStrategy() -> PluginLayerHostingStrategy { return .None }

  func platformLayer() -> PlatformLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func graphicsLayer() -> GraphicsLayer? {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func location() -> IntPoint {
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

  func show() {}

  func hide() {}

  func setFrameRect(_ rect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameRect() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
