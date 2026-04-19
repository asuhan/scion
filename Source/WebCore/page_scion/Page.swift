/*
 * Copyright (C) 2006-2020 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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
 */

import wk_interop

enum CompositingPolicy {
  case Normal
  case Conservative  // Used in low memory situations.
}

class PageWrapper {
  init(_ p: UnsafeRawPointer) { self.p = p }

  func mainFrame() -> FrameWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func chrome() -> ChromeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dragCaretController() -> DragCaretControllerWrapper {
    return DragCaretControllerWrapper(wk_interop.Page_dragCaretController(p))
  }

  func focusController() -> FocusControllerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollingCoordinator() -> ScrollingCoordinatorWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func settings() -> SettingsWrapper { return SettingsWrapper(wk_interop.Page_settings(p)) }

  func pageScaleFactor() -> Float32 { return wk_interop.Page_pageScaleFactor(p) }

  func delegatesScaling() -> Bool { return wk_interop.Page_delegatesScaling(p) }

  func deviceScaleFactor() -> Float32 { return wk_interop.Page_deviceScaleFactor(p) }

  func useSystemAppearance() -> Bool { return wk_interop.Page_useSystemAppearance(p) }

  func preferredFilterRenderingModes() -> FilterRenderingMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageOverlayController() -> PageOverlayControllerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isVisible() -> Bool { return wk_interop.Page_isVisible(p) }

  func isInWindow() -> Bool { return wk_interop.Page_isInWindow(p) }

  func addRelevantRepaintedObject(object: RenderObjectWrapper, objectPaintRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addRelevantUnpaintedObject(object: RenderObjectWrapper, objectPaintRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func compositingPolicyOverride() -> CompositingPolicy? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastRenderingUpdateTimestamp() -> MonotonicTime {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasEverSetVisibilityAdjustment() -> Bool {
    return wk_interop.Page_hasEverSetVisibilityAdjustment(p)
  }

  private let p: UnsafeRawPointer
}
