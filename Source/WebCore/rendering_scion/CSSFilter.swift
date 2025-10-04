/*
 * Copyright (C) 2011-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

private func createBlurEffect(blurOperation: BlurFilterOperationWrapper) -> FilterEffectWrapper {
  let stdDeviation = floatValueForLength(
    length: blurOperation.stdDeviation(), maximumValue: LayoutUnit(value: 0))
  return FEGaussianBlurWrapper.create(x: stdDeviation, y: stdDeviation, edgeMode: .None)
}

private func createBrightnessEffect(
  componentTransferOperation: BasicComponentTransferFilterOperationWrapper
) -> FilterEffectWrapper {
  var transferFunction = ComponentTransferFunction()
  transferFunction.type = .FECOMPONENTTRANSFER_TYPE_LINEAR
  transferFunction.slope = narrowPrecisionToFloat(componentTransferOperation.amount())
  transferFunction.intercept = 0

  let nullFunction = ComponentTransferFunction()
  return FEComponentTransferWrapper.create(
    redFunction: transferFunction, greenFunction: transferFunction, blueFunction: transferFunction,
    alphaFunction: nullFunction)
}

private func createContrastEffect(
  componentTransferOperation: BasicComponentTransferFilterOperationWrapper
) -> FilterEffectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createDropShadowEffect(dropShadowOperation: DropShadowFilterOperationWrapper)
  -> FilterEffectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createGrayScaleEffect(colorMatrixOperation: BasicColorMatrixFilterOperationWrapper)
  -> FilterEffectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createHueRotateEffect(colorMatrixOperation: BasicColorMatrixFilterOperationWrapper)
  -> FilterEffectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createInvertEffect(
  componentTransferOperation: BasicComponentTransferFilterOperationWrapper
) -> FilterEffectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createOpacityEffect(
  componentTransferOperation: BasicComponentTransferFilterOperationWrapper
) -> FilterEffectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createSaturateEffect(colorMatrixOperation: BasicColorMatrixFilterOperationWrapper)
  -> FilterEffectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createSepiaEffect(colorMatrixOperation: BasicColorMatrixFilterOperationWrapper)
  -> FilterEffectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func createReferenceFilter(
  filter: CSSFilter, filterOperation: ReferenceFilterOperationWrapper,
  renderer: RenderElementWrapper, preferredFilterRenderingModes: FilterRenderingMode,
  targetBoundingBox: FloatRectWrapper, destinationContext: GraphicsContextWrapper
) -> SVGFilterWrapper? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func referenceFilterElement(
  filterOperation: ReferenceFilterOperationWrapper, renderer: RenderElementWrapper
) -> SVGFilterElementWrapper? {
  let filterElement = ReferencedSVGResources.referencedFilterElement(
    treeScope: renderer.treeScopeForSVGReferences(), referenceFilter: filterOperation)

  if filterElement == nil {
    print(
      "building reference filter: failed to find filter renderer, adding pending resource \(filterOperation.fragment())"
    )
    // Although we did not find the referenced filter, it might exist later in the document.
    // FIXME: This skips anonymous RenderObjects. <https://webkit.org/b/131085>
    // FIXME: Unclear if this does anything.
    return nil
  }

  return filterElement
}

private func isIdentityReferenceFilter(
  filterOperation: ReferenceFilterOperationWrapper, renderer: RenderElementWrapper
) -> Bool {
  if let filterElement = referenceFilterElement(
    filterOperation: filterOperation, renderer: renderer)
  {
    return SVGFilterWrapper.isIdentity(filterElement: filterElement)
  }

  return false
}

private func calculateReferenceFilterOutsets(
  filterOperation: ReferenceFilterOperationWrapper, renderer: RenderElementWrapper,
  targetBoundingBox: FloatRectWrapper
)
  -> IntOutsets
{
  if let filterElement = referenceFilterElement(
    filterOperation: filterOperation, renderer: renderer)
  {
    return SVGFilterWrapper.calculateOutsets(
      filterElement: filterElement, targetBoundingBox: targetBoundingBox)
  }

  return IntOutsets()
}

final class CSSFilter: FilterWrapper, CustomStringConvertible {
  static func create(
    renderer: RenderElementWrapper, operations: FilterOperations,
    preferredFilterRenderingModes: FilterRenderingMode, filterScale: FloatSize,
    targetBoundingBox: FloatRectWrapper, destinationContext: GraphicsContextWrapper
  ) -> CSSFilter? {
    let hasFilterThatMovesPixels = operations.hasFilterThatMovesPixels()
    let hasFilterThatShouldBeRestrictedBySecurityOrigin =
      operations.hasFilterThatShouldBeRestrictedBySecurityOrigin()

    let filter = CSSFilter(
      filterScale: filterScale, hasFilterThatMovesPixels: hasFilterThatMovesPixels,
      hasFilterThatShouldBeRestrictedBySecurityOrigin:
        hasFilterThatShouldBeRestrictedBySecurityOrigin)

    if !filter.buildFilterFunctions(
      renderer: renderer, operations: operations,
      preferredFilterRenderingModes: preferredFilterRenderingModes,
      targetBoundingBox: targetBoundingBox, destinationContext: destinationContext)
    {
      print("CSSFilter::create: failed to build filters \(operations)")
      return nil
    }

    print("CSSFilter::create built filter \(filter) for \(operations)")

    filter.setFilterRenderingModes(preferredFilterRenderingModes: preferredFilterRenderingModes)
    return filter
  }

  func setFilterRegion(filterRegion: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func isIdentity(renderer: RenderElementWrapper, operations: FilterOperations) -> Bool {
    if operations.hasFilterThatShouldBeRestrictedBySecurityOrigin() {
      return false
    }

    for operation in operations {
      if let referenceOperation = operation as? ReferenceFilterOperationWrapper {
        if !isIdentityReferenceFilter(filterOperation: referenceOperation, renderer: renderer) {
          return false
        }
        continue
      }

      if !operation.isIdentity() {
        return false
      }
    }

    return true
  }

  static func calculateOutsets(
    renderer: RenderElementWrapper, operations: FilterOperations,
    targetBoundingBox: FloatRectWrapper
  ) -> IntOutsets {
    var outsets = IntOutsets()

    for operation in operations {
      if let referenceOperation = operation as? ReferenceFilterOperationWrapper {
        outsets += calculateReferenceFilterOutsets(
          filterOperation: referenceOperation, renderer: renderer,
          targetBoundingBox: targetBoundingBox)
        continue
      }

      outsets += operation.outsets()
    }

    return outsets
  }

  private init(
    filterScale: FloatSize, hasFilterThatMovesPixels: Bool,
    hasFilterThatShouldBeRestrictedBySecurityOrigin: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func buildFilterFunctions(
    renderer: RenderElementWrapper, operations: FilterOperations,
    preferredFilterRenderingModes: FilterRenderingMode, targetBoundingBox: FloatRectWrapper,
    destinationContext: GraphicsContextWrapper
  ) -> Bool {
    var function: FilterFunctionWrapper? = nil

    for operation in operations {
      switch operation.type() {
      case .AppleInvertLightness:
        fatalError("Not reached")  // AppleInvertLightness is only used in -apple-color-filter.
      case .Blur:
        function = createBlurEffect(blurOperation: operation as! BlurFilterOperationWrapper)
      case .Brightness:
        function = createBrightnessEffect(
          componentTransferOperation: operation as! BasicComponentTransferFilterOperationWrapper)
      case .Contrast:
        function = createContrastEffect(
          componentTransferOperation: operation as! BasicComponentTransferFilterOperationWrapper)
      case .DropShadow:
        function = createDropShadowEffect(
          dropShadowOperation: operation as! DropShadowFilterOperationWrapper)
      case .Grayscale:
        function = createGrayScaleEffect(
          colorMatrixOperation: operation as! BasicColorMatrixFilterOperationWrapper)
      case .HueRotate:
        function = createHueRotateEffect(
          colorMatrixOperation: operation as! BasicColorMatrixFilterOperationWrapper)
      case .Invert:
        function = createInvertEffect(
          componentTransferOperation: operation as! BasicComponentTransferFilterOperationWrapper)
      case .Opacity:
        function = createOpacityEffect(
          componentTransferOperation: operation as! BasicComponentTransferFilterOperationWrapper)
      case .Saturate:
        function = createSaturateEffect(
          colorMatrixOperation: operation as! BasicColorMatrixFilterOperationWrapper)
      case .Sepia:
        function = createSepiaEffect(
          colorMatrixOperation: operation as! BasicColorMatrixFilterOperationWrapper)
      case .Reference:
        function = createReferenceFilter(
          filter: self, filterOperation: operation as! ReferenceFilterOperationWrapper,
          renderer: renderer, preferredFilterRenderingModes: preferredFilterRenderingModes,
          targetBoundingBox: targetBoundingBox,
          destinationContext: destinationContext)
      default:
        break
      }

      if function == nil {
        continue
      }

      if functions.isEmpty {
        functions.append(SourceGraphicWrapper.create())
      }

      functions.append(function!)
    }

    // If we didn't make any effects, tell our caller we are not valid.
    if functions.isEmpty {
      return false
    }

    // TODO(asuhan): shrink functions to size
    return true
  }

  public var description: String {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let hasFilterThatMovesPixels = false

  private var functions: [FilterFunctionWrapper] = []
}
