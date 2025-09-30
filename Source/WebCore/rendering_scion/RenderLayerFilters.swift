/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2013-2023 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

final class RenderLayerFilters: CachedSVGDocumentClientWrapper {
  func clearFilter() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFilterThatMovesPixels() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFilterThatShouldBeRestrictedBySecurityOrigin() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSourceImage() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func isIdentity(renderer: RenderElementWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func calculateOutsets(renderer: RenderElementWrapper, targetBoundingBox: FloatRectWrapper)
    -> IntOutsets
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func beginFilterEffect(
    renderer: RenderElementWrapper, context: GraphicsContextWrapper,
    filterBoxRect: LayoutRectWrapper, dirtyRect: LayoutRectWrapper,
    layerRepaintRect: LayoutRectWrapper, clipRect: LayoutRectWrapper
  ) -> GraphicsContextWrapper? {
    var expandedDirtyRect = dirtyRect
    var targetBoundingBox = intersection(a: filterBoxRect, b: dirtyRect)

    let outsets = RenderLayerFilters.calculateOutsets(
      renderer: renderer, targetBoundingBox: targetBoundingBox.FloatRect())
    if !outsets.isZero() {
      let flippedOutsets = LayoutBoxExtent(
        top: LayoutUnit(value: outsets.bottom), right: LayoutUnit(value: outsets.left),
        bottom: LayoutUnit(value: outsets.top), left: LayoutUnit(value: outsets.right))
      expandedDirtyRect.expand(box: flippedOutsets)
    }

    if renderer is RenderSVGShapeWrapper {
      targetBoundingBox = enclosingLayoutRect(rect: renderer.objectBoundingBox())
    } else {
      // Calculate targetBoundingBox since it will be used if the filter is created.
      targetBoundingBox = intersection(a: filterBoxRect, b: expandedDirtyRect)
    }

    if targetBoundingBox.isEmpty() {
      return nil
    }

    if filter == nil || self.targetBoundingBox != targetBoundingBox {
      self.targetBoundingBox = targetBoundingBox
      // FIXME: This rebuilds the entire effects chain even if the filter style didn't change.
      filter = CSSFilter.create(
        renderer: renderer, operations: renderer.style().filter(),
        preferredFilterRenderingModes: preferredFilterRenderingModes, filterScale: filterScale,
        targetBoundingBox: self.targetBoundingBox.FloatRect(), destinationContext: context)
    }

    if filter == nil {
      return nil
    }

    var filterRegion = targetBoundingBox

    if filter!.hasFilterThatMovesPixels {
      // For CSSFilter, filterRegion = targetBoundingBox + filter->outsets()
      filterRegion.expand(box: toLayoutBoxExtent(extent: outsets))
    } else if let shape = renderer as? RenderSVGShapeWrapper {
      filterRegion = shape.currentSVGLayoutRect()
    }

    if filterRegion.isEmpty() {
      return nil
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyFilterEffect(destinationContext: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var targetBoundingBox = LayoutRectWrapper()
  let dirtySourceRect = LayoutRectWrapper()
  let repaintRect = LayoutRectWrapper()

  var preferredFilterRenderingModes: FilterRenderingMode = [.Software]
  var filterScale = FloatSize(width: 1.0, height: 1.0)

  private var filter: CSSFilter? = nil
  private var targetSwitcher: GraphicsContextSwitcher? = nil
}
