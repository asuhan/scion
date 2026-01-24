/*
 * Copyright (c) 2024 Igalia S.L.
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

class SVGVisitedRendererTracking {
  typealias VisitedSet = WeakHashSet<RenderElementWrapper>

  init(_ visitedSet: VisitedSet) { visitedRenderers = visitedSet }

  func isVisiting(_ renderer: RenderElementWrapper) -> Bool {
    return visitedRenderers.contains(value: renderer)
  }

  struct Scope: ~Copyable {
    init(_ tracking: SVGVisitedRendererTracking, _ renderer: RenderElementWrapper) {
      self.tracking = tracking
      self.renderer = renderer
      self.tracking.addUnique(renderer)
    }

    deinit {
      if renderer != nil {
        tracking.removeUnique(renderer!)
      }
    }

    private let tracking: SVGVisitedRendererTracking
    private let renderer: RenderElementWrapper?
  }

  private func addUnique(_ renderer: RenderElementWrapper) {
    let result = visitedRenderers.add(value: renderer)
    assert(result.isNewEntry)
  }

  private func removeUnique(_ renderer: RenderElementWrapper) {
    let result = visitedRenderers.remove(renderer)
    assert(result)
  }

  private let visitedRenderers: VisitedSet
}
