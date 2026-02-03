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
  let renderer: RenderObjectWrapper?
  let offset: LayoutSizeWrapper
  let transform: TransformationMatrix?  // Includes offset if non-null.
  let accumulatingTransform: Bool
  let isFixedPosition: Bool
  let hasTransform: Bool
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func popMappingsToAncestor(ancestorLayer: RenderLayerWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func hasNonUniformStep() -> Bool { return nonUniformStepsCount != 0 }

  private func hasTransformStep() -> Bool { return transformedStepsCount != 0 }

  private func hasFixedPositionStep() -> Bool { return fixedStepsCount != 0 }

  typealias RenderGeometryMapSteps = [RenderGeometryMapStep]  // TODO(asuhan): use inline storage of 32

  private let nonUniformStepsCount: Int32
  private let transformedStepsCount: Int32
  private let fixedStepsCount: Int32
  private let mapping: RenderGeometryMapSteps
  private let accumulatedOffset: LayoutSizeWrapper
  private let mapCoordinatesFlags: MapCoordinatesMode
}
