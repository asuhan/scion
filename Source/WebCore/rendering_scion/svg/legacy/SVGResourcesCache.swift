/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

private func resourcesCacheFromRenderer(_ renderer: RenderElementWrapper) -> SVGResourcesCache {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func rendererCanHaveResources(_ renderer: RenderObjectWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class SVGResourcesCache {
  static func cachedResourcesForRenderer(_ renderer: RenderElementWrapper) -> SVGResources? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Called from all SVG renderers addChild() methods.
  static func clientWasAddedToTree(renderer: RenderObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Called from all SVG renderers addChild() methods.
  static func clientWillBeRemovedFromTree(renderer: RenderObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Called from all SVG renderers layout() methods.
  static func clientLayoutChanged(_ renderer: RenderElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Called from all SVG renderers styleDidChange() methods.
  static func clientStyleChanged(
    _ renderer: RenderElementWrapper, _ diff: StyleDifference, oldStyle: RenderStyleWrapper?,
    newStyle: RenderStyleWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct SetStyleForScope: ~Copyable {
    init(
      _ renderer: RenderElementWrapper, _ scopedStyle: RenderStyleWrapper,
      newStyle: RenderStyleWrapper
    ) {
      self.renderer = renderer
      self.scopedStyle = scopedStyle
      self.needsNewStyle = scopedStyle != newStyle && rendererCanHaveResources(renderer)
      setStyle(newStyle)
    }

    deinit {
      setStyle(scopedStyle)
    }

    private func setStyle(_ style: RenderStyleWrapper) {
      if !needsNewStyle {
        return
      }

      // FIXME: Check if a similar mechanism is needed for LBSE + text rendering.
      if renderer.document().settings().layerBasedSVGEngineEnabled() {
        return
      }

      let cache = resourcesCacheFromRenderer(renderer)
      cache.removeResourcesFromRenderer(renderer)
      cache.addResourcesFromRenderer(renderer, style)
    }

    private let renderer: RenderElementWrapper
    private let scopedStyle: RenderStyleWrapper
    private let needsNewStyle: Bool
  }

  private func addResourcesFromRenderer(
    _ renderer: RenderElementWrapper, _ style: RenderStyleWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func removeResourcesFromRenderer(_ renderer: RenderElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
