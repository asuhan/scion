/*
 * Copyright (C) 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.  All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2018 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

// Update a bounding box taking into account the validity of the other bounding box.
private func updateObjectBoundingBox(
  _ objectBoundingBox: inout FloatRectWrapper, _ objectBoundingBoxValid: inout Bool,
  _ other: RenderObjectWrapper, _ otherBoundingBox: FloatRectWrapper
) {
  let otherContainer = other as? LegacyRenderSVGContainer
  let otherValid = otherContainer == nil || otherContainer!.isObjectBoundingBoxValid()
  if !otherValid {
    return
  }

  if !objectBoundingBoxValid {
    objectBoundingBox = otherBoundingBox
    objectBoundingBoxValid = true
    return
  }

  objectBoundingBox.uniteEvenIfEmpty(other: otherBoundingBox)
}

private func invalidateResourcesOfChildren(_ renderer: RenderElementWrapper) {
  assert(!renderer.needsLayout())
  if let resources = SVGResourcesCache.cachedResourcesForRenderer(renderer) {
    resources.removeClientFromCache(renderer, false)
  }

  for child: RenderElementWrapper in childrenOfType(parent: renderer) {
    invalidateResourcesOfChildren(child)
  }
}

private func layoutSizeOfNearestViewportChanged(_ renderer: RenderElementWrapper) -> Bool {
  var start: RenderElementWrapper? = renderer
  while start != nil {
    if let svgRoot = start as? LegacyRenderSVGRootWrapper {
      return svgRoot.isLayoutSizeChanged
    }
    if let container = start as? LegacyRenderSVGViewportContainer {
      return container.isLayoutSizeChanged
    }
    start = start!.parent()
  }
  fatalError("Not reached")
}

// SVGRendererSupport is a helper class sharing code between all SVG renderers.
class SVGRenderSupport {
  private static func layoutDifferentRootIfNeeded(_ renderer: RenderElementWrapper) {
    if let resources = SVGResourcesCache.cachedResourcesForRenderer(renderer) {
      resources.layoutDifferentRootIfNeeded(renderer)
    }
  }

  // Shares child layouting code between LegacyRenderSVGRoot/RenderSVG(Hidden)Container
  static func layoutChildren(_ start: RenderElementWrapper, _ selfNeedsLayout: Bool) {
    let layoutSizeChanged = layoutSizeOfNearestViewportChanged(start)
    let transformChanged = transformToRootChanged(start)
    let elementsThatDidNotReceiveLayout = WeakHashSet<RenderElementWrapper>()

    for child: RenderObjectWrapper in childrenOfType(parent: start) {
      var needsLayout = selfNeedsLayout
      let childEverHadLayout = child.everHadLayout()

      if transformChanged {
        // If the transform changed we need to update the text metrics (note: this also happens for layoutSizeChanged=true).
        if let text = child as? RenderSVGTextWrapper {
          text.setNeedsTextMetricsUpdate()
        }
        needsLayout = true
      }

      if layoutSizeChanged {
        // When selfNeedsLayout is false and the layout size changed, we have to check whether this child uses relative lengths
        if let element = child.node() as? SVGElementWrapper, element.hasRelativeLengths() {
          // When the layout size changed and when using relative values tell the LegacyRenderSVGShape to update its shape object
          if let shape = child as? LegacyRenderSVGShapeWrapper {
            shape.needsShapeUpdate = true
          } else if let svgText = child as? RenderSVGTextWrapper {
            svgText.setNeedsTextMetricsUpdate()
            svgText.setNeedsPositioningValuesUpdate()
          }
          child.setNeedsTransformUpdate()
          needsLayout = true
        }
      }

      if needsLayout {
        child.setNeedsLayout(markParents: .MarkOnlyThis)
      }

      if child.needsLayout() {
        let childElement = child as! RenderElementWrapper
        layoutDifferentRootIfNeeded(childElement)
        childElement.layout()
        // Renderers are responsible for repainting themselves when changing, except
        // for the initial paint to avoid potential double-painting caused by non-sensical "old" bounds.
        // We could handle this in the individual objects, but for now it's easier to have
        // parent containers call repaint().  (RenderBlock::layout* has similar logic.)
        if !childEverHadLayout {
          child.repaint()
        }
      } else if layoutSizeChanged, let childElement = child as? RenderElementWrapper {
        elementsThatDidNotReceiveLayout.add(value: childElement)
      }

      assert(!child.needsLayout())
    }

    if !layoutSizeChanged {
      assert(elementsThatDidNotReceiveLayout.isEmptyIgnoringNullReferences())
      return
    }

    // If the layout size changed, invalidate all resources of all children that didn't go through the layout() code path.
    for element in elementsThatDidNotReceiveLayout {
      invalidateResourcesOfChildren(element)
    }
  }

  // Helper function determining wheter overflow is hidden
  static func isOverflowHidden(_ renderer: RenderElementWrapper) -> Bool {
    // LegacyRenderSVGRoot should never query for overflow state - it should always clip itself to the initial viewport size.
    assert(!renderer.isDocumentElementRenderer())

    return isNonVisibleOverflow(renderer.style().overflowX())
  }

  // Calculates the repaintRect in combination with filter, clipper and masker in local coordinates.
  static func intersectRepaintRectWithResources(
    _ renderer: RenderElementWrapper, _ repaintRect: inout FloatRectWrapper,
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) {
    guard let resources = SVGResourcesCache.cachedResourcesForRenderer(renderer) else { return }

    if let filter = resources.filter() {
      repaintRect = filter.resourceBoundingBox(renderer, repaintRectCalculation)
    }

    if let clipper = resources.clipper() {
      repaintRect.intersect(other: clipper.resourceBoundingBox(renderer, repaintRectCalculation))
    }

    if let masker = resources.masker() {
      repaintRect.intersect(other: masker.resourceBoundingBox(renderer, repaintRectCalculation))
    }
  }

  // Determines whether a container needs to be laid out because it's filtered and a child is being laid out.
  static func filtersForceContainerLayout(_ renderer: RenderElementWrapper) -> Bool {
    // If any of this container's children need to be laid out, and a filter is applied
    // to the container, we need to repaint the entire container.
    if !renderer.normalChildNeedsLayout() {
      return false
    }

    let resources = SVGResourcesCache.cachedResourcesForRenderer(renderer)
    if resources?.filter() == nil {
      return false
    }

    return true
  }

  struct ContainerBoundingBoxes {
    let object: FloatRectWrapper
    let objectIsValid: Bool
    let repaint: FloatRectWrapper
  }

  static func computeContainerBoundingBoxes(
    _ container: RenderElementWrapper, _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> ContainerBoundingBoxes {
    var objectBoundingBox = FloatRectWrapper()
    var objectBoundingBoxValid = false
    var repaintBoundingBox = FloatRectWrapper()
    for current: RenderObjectWrapper in childrenOfType(parent: container) {
      if current.isLegacyRenderSVGHiddenContainer() {
        continue
      }

      // Don't include elements in the union that do not render.
      if let shape = current as? LegacyRenderSVGShapeWrapper, shape.isRenderingDisabled() {
        continue
      }

      let transform = current.localToParentTransform()
      if transform.isIdentity() {
        updateObjectBoundingBox(
          &objectBoundingBox, &objectBoundingBoxValid, current, current.objectBoundingBox())
        repaintBoundingBox.unite(
          other: current.repaintRectInLocalCoordinates(repaintRectCalculation))
      } else {
        updateObjectBoundingBox(
          &objectBoundingBox, &objectBoundingBoxValid, current,
          transform.mapRect(rect: current.objectBoundingBox()))
        repaintBoundingBox.unite(
          other: transform.mapRect(
            rect: current.repaintRectInLocalCoordinates(repaintRectCalculation)))
      }
    }
    return ContainerBoundingBoxes(
      object: objectBoundingBox, objectIsValid: objectBoundingBoxValid, repaint: repaintBoundingBox)
  }

  static func paintInfoIntersectsRepaintRect(
    _ localRepaintRect: FloatRectWrapper, _ localTransform: AffineTransform,
    _ paintInfo: PaintInfoWrapper
  ) -> Bool {
    if localTransform.isIdentity() {
      return localRepaintRect.intersects(other: paintInfo.rect.FloatRect())
    }

    return localTransform.mapRect(rect: localRepaintRect).intersects(
      other: paintInfo.rect.FloatRect())
  }

  // Important functions used by nearly all SVG renderers centralizing coordinate transformations / repaint rect calculations
  static func clippedOverflowRectForRepaint(
    _ renderer: RenderElementWrapper, _ repaintContainer: RenderLayerModelObjectWrapper?,
    _ context: RenderObjectWrapper.VisibleRectContext
  ) -> LayoutRectWrapper {
    // Return early for any cases where we don't actually paint
    if renderer.isInsideEntirelyHiddenLayer() {
      return LayoutRectWrapper()
    }

    // Pass our local paint rect to computeFloatVisibleRectInContainer() which will
    // map to parent coords and recurse up the parent chain.
    return enclosingLayoutRect(
      rect: renderer.computeFloatRectForRepaint(
        renderer.repaintRectInLocalCoordinates(context.repaintRectCalculation()), repaintContainer))
  }

  static func computeFloatVisibleRectInContainer(
    _ renderer: RenderElementWrapper, _ rect: FloatRectWrapper,
    _ container: RenderLayerModelObjectWrapper?, _ context: RenderObjectWrapper.VisibleRectContext
  ) -> FloatRectWrapper? {
    // Ensure our parent is an SVG object.
    let parent = renderer.parent()!
    if !(parent.element() is SVGElementWrapper) {
      return FloatRectWrapper()
    }

    var adjustedRect = rect
    adjustedRect.inflate(d: renderer.style().outlineWidth())

    // Translate to coords in our parent renderer, and then call computeFloatVisibleRectInContainer() on our parent.
    adjustedRect = renderer.localToParentTransform().mapRect(rect: adjustedRect)

    return parent.computeFloatVisibleRectInContainer(adjustedRect, container, context)
  }

  private static func localToParentTransform(
    _ renderer: RenderElementWrapper, _ transform: inout AffineTransform
  ) -> RenderElementWrapper {
    let parent = renderer.parent()!

    // At the SVG/HTML boundary (aka LegacyRenderSVGRoot), we apply the localToBorderBoxTransform
    // to map an element from SVG viewport coordinates to CSS box coordinates.
    if let svgRoot = parent as? LegacyRenderSVGRootWrapper {
      transform = svgRoot.localToBorderBoxTransform * renderer.localToParentTransform()
    } else {
      transform = renderer.localToParentTransform()
    }

    return parent
  }

  static func mapLocalToContainer(
    _ renderer: RenderElementWrapper, _ ancestorContainer: RenderLayerModelObjectWrapper?,
    _ transformState: TransformState, _ wasFixed: inout Bool?
  ) {
    var transform = AffineTransform()
    let parent = localToParentTransform(renderer, &transform)

    transformState.applyTransform(transform)

    let mode: MapCoordinatesMode = [.UseTransforms]
    parent.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixed)
  }

  static func pushMappingToContainer(
    _ renderer: RenderElementWrapper, _ ancestorToStopAt: RenderLayerModelObjectWrapper?,
    _ geometryMap: RenderGeometryMap
  ) -> RenderElementWrapper? {
    assert(CPtrToInt(ancestorToStopAt?.p) != CPtrToInt(renderer.p))

    var transform = AffineTransform()
    let parent = localToParentTransform(renderer, &transform)

    geometryMap.push(renderer, TransformationMatrix(transform))
    return parent
  }

  static func checkForSVGRepaintDuringLayout(_ renderer: RenderElementWrapper)
    -> LayoutRepainter.CheckForRepaint
  {
    if !renderer.checkForRepaintDuringLayout() {
      return .No
    }
    // When a parent container is transformed in SVG, all children will be painted automatically
    // so we are able to skip redundant repaint checks.
    if let parent = renderer.parent() as? LegacyRenderSVGContainer,
      parent.isRepaintSuspendedForChildren() || parent.didTransformToRootUpdate()
    {
      return .No
    }
    return .Yes
  }

  static func calculateApproximateStrokeBoundingBox(_ renderer: RenderElementWrapper)
    -> FloatRectWrapper
  {
    let calculateApproximateScalingStrokeBoundingBox = {
      (renderer: RenderSVGShapeProto, fillBoundingBox: FloatRectWrapper) -> FloatRectWrapper in
      // Implementation of
      // https://drafts.fxtf.org/css-masking/#compute-stroke-bounding-box
      // except that we ignore whether the stroke is none.

      assert(renderer.style().svgStyle().hasStroke())

      var strokeBoundingBox = fillBoundingBox
      let strokeWidth = renderer.strokeWidth()
      if strokeWidth <= 0 {
        return strokeBoundingBox
      }

      var delta = strokeWidth / 2
      switch renderer.shapeType {
      case .Empty:
        // Spec: "A negative value is illegal. A value of zero disables rendering of the element."
        return strokeBoundingBox
      case .Ellipse, .Circle:
        break
      case .Rectangle, .RoundedRectangle:
        break
      case .Path, .Line:
        let style = renderer.style()
        if renderer.shapeType == .Path && style.joinStyle() == .Miter {
          let miter = style.strokeMiterLimit()
          if Float64(miter) < sqrtOfTwoDouble && style.capStyle() == .Square {
            delta = Float32(Float64(delta) * sqrtOfTwoDouble)
          } else {
            delta *= max(miter, 1)
          }
        } else if style.capStyle() == .Square {
          delta = Float32(Float64(delta) * sqrtOfTwoDouble)
        }
      }

      strokeBoundingBox.inflate(d: delta)
      return strokeBoundingBox
    }

    let calculateApproximateNonScalingStrokeBoundingBox = {
      (renderer: RenderSVGShapeProto, fillBoundingBox: FloatRectWrapper) -> FloatRectWrapper in
      assert(renderer.hasPath())
      assert(renderer.style().svgStyle().hasStroke())
      assert(renderer.hasNonScalingStroke())

      var strokeBoundingBox = fillBoundingBox
      let nonScalingTransform = renderer.nonScalingStrokeTransform()
      if let inverse = nonScalingTransform.inverse() {
        let usePath = renderer.nonScalingStrokePath(renderer.path(), nonScalingTransform)
        var strokeBoundingRect = calculateApproximateScalingStrokeBoundingBox(
          renderer, usePath.fastBoundingRect())
        strokeBoundingRect = inverse.mapRect(rect: strokeBoundingRect)
        strokeBoundingBox.unite(other: strokeBoundingRect)
      }
      return strokeBoundingBox
    }

    let calculate = { (renderer: RenderSVGShapeProto) -> FloatRectWrapper in
      if !renderer.style().svgStyle().hasStroke() {
        return renderer.objectBoundingBox()
      }
      if renderer.hasNonScalingStroke() {
        return calculateApproximateNonScalingStrokeBoundingBox(
          renderer, renderer.objectBoundingBox())
      }
      return calculateApproximateScalingStrokeBoundingBox(renderer, renderer.objectBoundingBox())
    }

    if let shape = renderer as? LegacyRenderSVGShapeWrapper {
      return shape.adjustStrokeBoundingBoxForMarkersAndZeroLengthLinecaps(.Fast, calculate(shape))
    }

    let shape = renderer as! RenderSVGShapeWrapper
    return shape.adjustStrokeBoundingBoxForZeroLengthLinecaps(calculate(shape))
  }

  // Determines if any ancestor's transform has changed.
  private static func transformToRootChanged(_ ancestor: RenderElementWrapper?) -> Bool {
    var ancestor = ancestor
    while ancestor != nil && !ancestor!.isRenderOrLegacyRenderSVGRoot() {
      if let container = ancestor as? LegacyRenderSVGTransformableContainer {
        return container.didTransformToRootUpdate()
      }
      if let container = ancestor as? LegacyRenderSVGViewportContainer {
        return container.didTransformToRootUpdate()
      }
      ancestor = ancestor!.parent()
    }

    return false
  }

  static func styleChanged(renderer: RenderElementWrapper, oldStyle: RenderStyleWrapper?) {
    if renderer.element() != nil && renderer.element()!.isSVGElement()
      && (oldStyle == nil || renderer.style().hasBlendMode() != oldStyle!.hasBlendMode())
    {
      SVGRenderSupport.updateMaskedAncestorShouldIsolateBlending(renderer)
    }
  }

  private static func isolatesBlending(_ style: RenderStyleWrapper) -> Bool {
    return style.hasPositionedMask() || style.hasFilter() || style.hasBlendMode()
      || style.opacity() < 1
  }

  private static func updateMaskedAncestorShouldIsolateBlending(_ renderer: RenderElementWrapper) {
    let element = renderer.element()!
    assert(element.isSVGElement())
    for ancestor: SVGGraphicsElementWrapper in ancestorsOfType(descendant: element) {
      let style = ancestor.computedStyle()
      if style == nil || !isolatesBlending(style!) {
        continue
      }
      if style!.hasPositionedMask() {
        ancestor.setShouldIsolateBlending(renderer.style().hasBlendMode())
      }
      return
    }
  }

  static func findTreeRootObject(start: RenderElementWrapper) -> LegacyRenderSVGRootWrapper? {
    return RenderAncestorIteratorAdapter<LegacyRenderSVGRootWrapper>.lineageOfType(first: start)
      .first()
  }
}
