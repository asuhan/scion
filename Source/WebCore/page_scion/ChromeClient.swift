/*
 * Copyright (C) 2006-2023 Apple, Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 * Copyright (C) 2012 Samsung Electronics. All rights reserved.
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

class ChromeClient {
  func pageExtendedBackgroundColorDidChange() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Allows ports to customize the type of graphics layers created by this page.
  func graphicsLayerFactory() -> GraphicsLayerFactory? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Pass nullptr as the GraphicsLayer to detatch the root layer.
  func attachRootGraphicsLayer(frame: LocalFrameWrapper, layer: GraphicsLayer?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct CompositingTriggerFlags: OptionSet {
    let rawValue: UInt32

    static let ThreeDTransformTrigger = CompositingTriggerFlags(rawValue: 1 << 0)
    static let VideoTrigger = CompositingTriggerFlags(rawValue: 1 << 1)
    static let PluginTrigger = CompositingTriggerFlags(rawValue: 1 << 2)
    static let CanvasTrigger = CompositingTriggerFlags(rawValue: 1 << 3)
    static let AnimationTrigger = CompositingTriggerFlags(rawValue: 1 << 4)
    static let FilterTrigger = CompositingTriggerFlags(rawValue: 1 << 5)
    static let ScrollableNonMainFrameTrigger = CompositingTriggerFlags(rawValue: 1 << 6)
    static let AnimatedOpacityTrigger = CompositingTriggerFlags(rawValue: 1 << 7)
    static let AllTriggers = CompositingTriggerFlags(rawValue: 0xFFFF_FFFF)
  }

  // Returns a bitfield indicating conditions that can trigger the compositor.
  func allowedCompositingTriggers() -> CompositingTriggerFlags {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ensureScrollbarsController(
    _ page: PageWrapper, _ area: ScrollableAreaWrapper, _ update: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldUseTiledBackingForFrameView(frameView: LocalFrameViewWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
