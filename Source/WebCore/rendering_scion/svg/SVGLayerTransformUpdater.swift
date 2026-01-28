/*
 * Copyright (C) 2020, 2021, 2022 Igalia S.L.
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

struct SVGLayerTransformUpdater {
  init(_ renderer: RenderLayerModelObjectWrapper) {
    self.renderer = renderer
    if !renderer.hasLayer() {
      transformReferenceBox = FloatRectWrapper()
      layerTransform = nil
      return
    }

    transformReferenceBox = self.renderer.transformReferenceBoxRect()
    layerTransform = self.renderer.layerTransform()

    self.renderer.updateLayerTransform()
  }

  func layerTransformChanged() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let renderer: RenderLayerModelObjectWrapper
  private let transformReferenceBox: FloatRectWrapper
  private let layerTransform: TransformationMatrix?
}
