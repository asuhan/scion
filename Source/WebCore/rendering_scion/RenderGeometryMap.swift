/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// Stores data about how to map from one renderer to its container.
struct RenderGeometryMapStep {
  init(
    renderer: RenderObjectWrapper?, accumulatingTransform: Bool, isNonUniform: Bool,
    isFixedPosition: Bool, hasTransform: Bool
  ) {
    self.renderer = renderer
    self.accumulatingTransform = accumulatingTransform
    self.isNonUniform = isNonUniform
    self.isFixedPosition = isFixedPosition
    self.hasTransform = hasTransform
  }

  let renderer: RenderObjectWrapper?
  var offset = LayoutSizeWrapper()
  var transform: TransformationMatrix? = nil  // Includes offset if non-null.
  let accumulatingTransform: Bool
  let isNonUniform: Bool  // Mapping depends on the input point, e.g. because of CSS columns.
  let isFixedPosition: Bool
  let hasTransform: Bool
}

private func canMapBetweenRenderersViaLayers(
  _ renderer: RenderLayerModelObjectWrapper, _ ancestor: RenderLayerModelObjectWrapper
) -> Bool {
  var current: RenderElementWrapper = renderer
  while true {
    let style = current.style()
    if current.isFixedPositioned() || style.isFlippedBlocksWritingMode() {
      return false
    }

    if current.hasTransformOrPerspective() {
      return false
    }

    if current.isRenderFragmentedFlow() {
      return false
    }

    if current.isLegacyRenderSVGRoot() {
      return false
    }

    if CPtrToInt(current.p) == CPtrToInt(ancestor.p) {
      break
    }
    current = current.parent()!
  }

  return true
}

// Can be used while walking the Renderer tree to cache data about offsets and transforms.
class RenderGeometryMap {
  init(_ flags: MapCoordinatesMode = .UseTransforms) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func absoluteRect(_ rect: FloatRectWrapper) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func mapToContainer(_ rect: FloatRectWrapper, _ container: RenderLayerModelObjectWrapper?)
    -> FloatQuad
  {
    var result = FloatQuad()

    if !hasFixedPositionStep() && !hasTransformStep() && !hasNonUniformStep()
      && (container == nil
        || (!mapping.isEmpty && CPtrToInt(container!.p) == CPtrToInt(mapping[0].renderer?.p)))
    {
      result = FloatQuad(inRect: rect)
      result.move(accumulatedOffset)
    } else {
      let transformState = TransformState(
        .ApplyTransformDirection, rect.center(), FloatQuad(inRect: rect))
      mapToContainer(transformState, container)
      result = transformState.lastPlanarQuad()
    }

    return result
  }

  // Called by code walking the renderer or layer trees.
  func pushMappingsToAncestor(
    layer: RenderLayerWrapper?, ancestorLayer: RenderLayerWrapper?, respectTransforms: Bool = true
  ) {
    var layer = layer
    if ancestorLayer == nil {
      assert(mapping.isEmpty)
      pushMappingsToAncestor(layer!.renderer().view(), nil)

      let _ = SetForScope(scopedVariable: &insertionPosition, newValue: mapping.count)
      while layer!.parent() != nil {
        pushMappingsToAncestor(
          layer: layer, ancestorLayer: layer!.parent(), respectTransforms: respectTransforms)
        layer = layer!.parent()
      }
      assert(mapping[0].renderer!.isRenderView())
      return
    }

    var newFlags = mapCoordinatesFlags
    if !respectTransforms {
      newFlags.remove(.UseTransforms)
    }

    let _ = SetForScope(scopedVariable: &mapCoordinatesFlags, newValue: newFlags)

    let renderer = layer!.renderer()

    // We have to visit all the renderers to detect flipped blocks. This might defeat the gains
    // from mapping via layers.
    if canMapBetweenRenderersViaLayers(renderer, ancestorLayer!.renderer()) {
      let layerOffset = layer!.offsetFromAncestor(ancestorLayer: ancestorLayer)

      // The RenderView must be pushed first.
      if mapping.isEmpty {
        assert(ancestorLayer!.renderer().isRenderView())
        pushMappingsToAncestor(ancestorLayer!.renderer(), nil)
      }

      let _ = SetForScope(scopedVariable: &insertionPosition, newValue: mapping.count)
      push(
        renderer, layerOffset, accumulatingTransform: true, isNonUniform: false,
        isFixedPosition: false, hasTransform: false)
      return
    }
    let ancestorRenderer = ancestorLayer!.renderer()
    pushMappingsToAncestor(renderer, ancestorRenderer)
  }

  func popMappingsToAncestor(ancestorLayer: RenderLayerWrapper?) {
    popMappingsToAncestor(ancestorLayer?.renderer())
  }

  private func pushMappingsToAncestor(
    _ renderer: RenderObjectWrapper?, _ ancestorRenderer: RenderLayerModelObjectWrapper?
  ) {
    // We need to push mappings in reverse order here, so do insertions rather than appends.
    let _ = SetForScope(scopedVariable: &insertionPosition, newValue: mapping.count)
    var renderer = renderer
    repeat {
      renderer = renderer!.pushMappingToContainer(ancestorRenderer, self)
    } while renderer != nil && CPtrToInt(renderer!.p) != CPtrToInt(ancestorRenderer?.p)

    assert(mapping.isEmpty || mapping[0].renderer!.isRenderView())
  }

  private func popMappingsToAncestor(_ ancestorRenderer: RenderLayerModelObjectWrapper?) {
    assert(!mapping.isEmpty)

    while !mapping.isEmpty && CPtrToInt(mapping.last!.renderer?.p) != CPtrToInt(ancestorRenderer?.p)
    {
      stepRemoved(mapping.last!)
      mapping.removeLast()
    }
  }

  // The following methods should only be called by renderers inside a call to pushMappingsToAncestor().

  // Push geometry info between this renderer and some ancestor. The ancestor must be its container() or some
  // stacking context between the renderer and its container.
  private func push(
    _ renderer: RenderObjectWrapper, _ offsetFromContainer: LayoutSizeWrapper,
    accumulatingTransform: Bool = false, isNonUniform: Bool = false, isFixedPosition: Bool = false,
    hasTransform: Bool = false
  ) {
    assert(insertionPosition != RenderGeometryMap.notFound)

    mapping.insert(
      RenderGeometryMapStep(
        renderer: renderer, accumulatingTransform: accumulatingTransform,
        isNonUniform: isNonUniform,
        isFixedPosition: isFixedPosition, hasTransform: hasTransform), at: insertionPosition)

    mapping[insertionPosition].offset = offsetFromContainer

    stepInserted(mapping[insertionPosition])
  }

  func push(
    _ renderer: RenderObjectWrapper, _ t: TransformationMatrix, accumulatingTransform: Bool = false,
    isNonUniform: Bool = false, isFixedPosition: Bool = false, hasTransform: Bool = false
  ) {
    assert(insertionPosition != RenderGeometryMap.notFound)

    mapping.insert(
      RenderGeometryMapStep(
        renderer: renderer, accumulatingTransform: accumulatingTransform,
        isNonUniform: isNonUniform,
        isFixedPosition: isFixedPosition, hasTransform: hasTransform), at: insertionPosition)

    if !t.isIntegerTranslation() {
      mapping[insertionPosition].transform = t.deepCopy()
    } else {
      mapping[insertionPosition].offset = LayoutSizeWrapper(width: t.e(), height: t.f())
    }

    stepInserted(mapping[insertionPosition])
  }

  private func mapToContainer(
    _ transformState: TransformState, _ container: RenderLayerModelObjectWrapper?
  ) {
    // If the mapping includes something like columns, we have to go via renderers.
    if hasNonUniformStep() {
      var dummy: Bool? = nil
      mapping.last!.renderer!.mapLocalToContainer(
        container, transformState, mapCoordinatesFlags.union(.ApplyContainerFlip), &dummy)
      transformState.flatten()
      return
    }

    var inFixed = false
    #if ASSERT_ENABLED
      var foundContainer =
        container == nil
        || (!mapping.isEmpty && CPtrToInt(mapping[0].renderer?.p) == CPtrToInt(container!.p))
    #endif

    for (i, currentStep) in mapping.enumerated().reversed() {
      // If container is the RenderView (step 0) we want to apply its scroll offset.
      if i > 0 && CPtrToInt(currentStep.renderer?.p) == CPtrToInt(container?.p) {
        #if ASSERT_ENABLED
          foundContainer = true
        #endif
        break
      }

      // If this box has a transform, it acts as a fixed position container
      // for fixed descendants, which prevents the propagation of 'fixed'
      // unless the layer itself is also fixed position.
      if i != 0 && currentStep.hasTransform && !currentStep.isFixedPosition {
        inFixed = false
      } else if currentStep.isFixedPosition {
        inFixed = true
      }

      if i == 0 {
        // The root gets special treatment for fixed position
        if inFixed {
          transformState.move(currentStep.offset.width(), currentStep.offset.height())
        }

        // A null container indicates mapping through the RenderView, so including its transform (the page scale).
        if container == nil && currentStep.transform != nil {
          transformState.applyTransform(currentStep.transform!)
        }
      } else {
        let accumulate: TransformState.TransformAccumulation =
          currentStep.accumulatingTransform ? .AccumulateTransform : .FlattenTransform
        if currentStep.transform != nil {
          transformState.applyTransform(currentStep.transform!, accumulate)
        } else {
          transformState.move(currentStep.offset.width(), currentStep.offset.height(), accumulate)
        }
      }
    }

    #if ASSERT_ENABLED
      assert(foundContainer)
    #endif
    transformState.flatten()
  }

  private func stepInserted(_ step: RenderGeometryMapStep) {
    // RenderView's offset, is only applied when we have fixed-positions.
    if !step.renderer!.isRenderView() {
      accumulatedOffset += step.offset
      #if ASSERT_ENABLED
        accumulatedOffsetMightBeSaturated =
          accumulatedOffset.mightBeSaturated() || accumulatedOffsetMightBeSaturated
      #endif
    }

    if step.isNonUniform {
      nonUniformStepsCount += 1
    }

    if step.transform != nil {
      transformedStepsCount += 1
    }

    if step.isFixedPosition {
      fixedStepsCount += 1
    }
  }

  private func stepRemoved(_ step: RenderGeometryMapStep) {
    // RenderView's offset, is only applied when we have fixed-positions.
    if !step.renderer!.isRenderView() {
      accumulatedOffset -= step.offset
      #if ASSERT_ENABLED
        accumulatedOffsetMightBeSaturated =
          accumulatedOffset.mightBeSaturated() || accumulatedOffsetMightBeSaturated
      #endif
    }

    if step.isNonUniform {
      assert(nonUniformStepsCount != 0)
      nonUniformStepsCount -= 1
    }

    if step.transform != nil {
      assert(transformedStepsCount != 0)
      transformedStepsCount -= 1
    }

    if step.isFixedPosition {
      assert(fixedStepsCount != 0)
      fixedStepsCount -= 1
    }
  }

  private func hasNonUniformStep() -> Bool { return nonUniformStepsCount != 0 }

  private func hasTransformStep() -> Bool { return transformedStepsCount != 0 }

  private func hasFixedPositionStep() -> Bool { return fixedStepsCount != 0 }

  typealias RenderGeometryMapSteps = [RenderGeometryMapStep]  // TODO(asuhan): use inline storage of 32

  private static let notFound = -1
  private var insertionPosition: Int = notFound
  private var nonUniformStepsCount: Int32
  private var transformedStepsCount: Int32
  private var fixedStepsCount: Int32
  private var mapping: RenderGeometryMapSteps
  private var accumulatedOffset: LayoutSizeWrapper
  private var mapCoordinatesFlags: MapCoordinatesMode
  #if ASSERT_ENABLED
    private var accumulatedOffsetMightBeSaturated: Bool
  #endif
}
