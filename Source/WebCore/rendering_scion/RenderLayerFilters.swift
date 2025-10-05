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
  init(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  func updateReferenceFilterClients(operations: FilterOperations) {
    removeReferenceFilterClients()

    for operation in operations {
      let referenceOperation = operation as? ReferenceFilterOperationWrapper
      if referenceOperation == nil {
        continue
      }

      let documentReference = referenceOperation!.cachedSVGDocumentReference()
      if let cachedSVGDocument = documentReference != nil ? documentReference!.document() : nil {
        // Reference is external; wait for notifyFinished().
        cachedSVGDocument.addClient(client: self)
        externalSVGReferences.append(
          CachedResourceHandleWrapper<CachedSVGDocumentWrapper>(res: cachedSVGDocument))
      } else {
        // Reference is internal; add layer as a client so we can trigger filter repaint on SVG attribute change.
        let filterElement = layer.renderer().document().getElementById(
          elementId: referenceOperation!.fragment())
        if filterElement == nil {
          continue
        }
        let renderer = filterElement!.renderer() as? LegacyRenderSVGResourceFilter
        if renderer == nil {
          continue
        }
        renderer!.addClientRenderLayer(client: layer)
        internalSVGReferences.append(filterElement!)
      }
    }
  }

  func removeReferenceFilterClients() {
    for resourceHandle in externalSVGReferences {
      resourceHandle.get()!.removeClient(client: self)
    }

    externalSVGReferences.removeAll()

    for filterElement in internalSVGReferences {
      if let renderer = filterElement.renderer() {
        (renderer as! LegacyRenderSVGResourceContainer).removeClientRenderLayer(client: layer)
      }
    }

    internalSVGReferences.removeAll()
  }

  static func isIdentity(renderer: RenderElementWrapper) -> Bool {
    let operations = renderer.style().filter()
    return CSSFilter.isIdentity(renderer: renderer, operations: operations)
  }

  static func calculateOutsets(renderer: RenderElementWrapper, targetBoundingBox: FloatRectWrapper)
    -> IntOutsets
  {
    let operations = renderer.style().filter()

    if !operations.hasFilterThatMovesPixels() {
      return IntOutsets()
    }

    return CSSFilter.calculateOutsets(
      renderer: renderer, operations: operations, targetBoundingBox: targetBoundingBox)
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

    // For CSSFilter, sourceImageRect = filterRegion.
    var hasUpdatedBackingStore = false
    if self.filterRegion != filterRegion.FloatRect() {
      self.filterRegion = filterRegion.FloatRect()
      hasUpdatedBackingStore = true
    }

    filter!.setFilterRegion(filterRegion: self.filterRegion)

    if !filter!.hasFilterThatMovesPixels {
      repaintRect = dirtyRect
    } else if hasUpdatedBackingStore || !hasSourceImage() {
      repaintRect = filterRegion
    } else {
      repaintRect = dirtyRect
      repaintRect.unite(other: layerRepaintRect)
      repaintRect.intersect(other: filterRegion)
    }

    resetDirtySourceRect()

    if targetSwitcher == nil || hasUpdatedBackingStore {
      var sourceImageRect = FloatRectWrapper()
      if renderer is RenderSVGShapeWrapper {
        sourceImageRect = renderer.strokeBoundingBox()
      } else {
        sourceImageRect = targetBoundingBox.FloatRect()
      }
      targetSwitcher = GraphicsContextSwitcher.create(
        destinationContext: context, sourceImageRect: sourceImageRect,
        colorSpace: DestinationColorSpace.SRGB(), filter: filter)
    }

    if targetSwitcher == nil {
      return nil
    }

    targetSwitcher!.beginClipAndDrawSourceImage(
      destinationContext: context, repaintRect: repaintRect.FloatRect(),
      clipRect: clipRect.FloatRect())

    return targetSwitcher!.drawingContext(destinationContext: context)
  }

  func applyFilterEffect(destinationContext: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func resetDirtySourceRect() { dirtySourceRect = LayoutRectWrapper() }

  let layer: RenderLayerWrapper
  var internalSVGReferences: [ElementWrapper] = []
  var externalSVGReferences: [CachedResourceHandleWrapper<CachedSVGDocumentWrapper>] = []

  var targetBoundingBox = LayoutRectWrapper()
  var dirtySourceRect = LayoutRectWrapper()
  var repaintRect = LayoutRectWrapper()

  var preferredFilterRenderingModes: FilterRenderingMode = [.Software]
  var filterScale = FloatSize(width: 1.0, height: 1.0)
  var filterRegion = FloatRectWrapper()

  private var filter: CSSFilter? = nil
  private var targetSwitcher: GraphicsContextSwitcher? = nil
}
