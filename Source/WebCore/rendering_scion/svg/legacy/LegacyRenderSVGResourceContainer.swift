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

// TODO(asuhan): inherit from LegacyRenderSVGResource
class LegacyRenderSVGResourceContainer: LegacyRenderSVGHiddenContainer {
  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): move to LegacyRenderSVGResource
  func applyResource(
    _ renderer: RenderElementWrapper, _ style: RenderStyleWrapper,
    _ context: GraphicsContextWrapper, _ resourceMode: RenderSVGResourceMode
  ) -> LegacyRenderSVGResource.ApplyResult {
    fatalError("Not reached")
  }

  // TODO(asuhan): move to LegacyRenderSVGResource
  func postApplyResource(
    _ renderer: RenderElementWrapper, _ context: GraphicsContextWrapper,
    _ resourceMode: RenderSVGResourceMode, _ path: PathWrapper?, _ shape: RenderElementWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): move to LegacyRenderSVGResource
  func removeAllClientsFromCache(markForInvalidation: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addClientRenderLayer(client: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeClientRenderLayer(client: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
