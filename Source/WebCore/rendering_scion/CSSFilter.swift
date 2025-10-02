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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class CSSFilter: FilterWrapper {
  static func create(
    renderer: RenderElementWrapper, operations: FilterOperations,
    preferredFilterRenderingModes: FilterRenderingMode, filterScale: FloatSize,
    targetBoundingBox: FloatRectWrapper, destinationContext: GraphicsContextWrapper
  ) -> CSSFilter {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  let hasFilterThatMovesPixels = false
}
