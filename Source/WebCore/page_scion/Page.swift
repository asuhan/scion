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

enum CompositingPolicy {
  case Normal
  case Conservative  // Used in low memory situations.
}

class PageWrapper {
  func mainFrame() -> FrameWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func chrome() -> ChromeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dragCaretController() -> DragCaretControllerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func focusController() -> FocusControllerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollingCoordinator() -> ScrollingCoordinatorWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func delegatesScaling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deviceScaleFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func useSystemAppearance() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func preferredFilterRenderingModes() -> FilterRenderingMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageOverlayController() -> PageOverlayControllerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isVisible() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInWindow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addRelevantRepaintedObject(object: RenderObjectWrapper, objectPaintRect: LayoutRectWrapper) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
