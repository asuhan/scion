/*
 * Copyright (C) 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.  All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2018 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2020 Apple Inc. All rights reserved.
 * Copyright (C) 2021, 2023, 2024 Igalia S.L.
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

struct SVGContainerLayout {
  init(_ container: RenderLayerModelObjectWrapper) {
    self.container = container
  }

  // 'containerNeedsLayout' denotes if the container for which the
  // SVGContainerLayout object was created needs to be laid out or not.
  mutating func layoutChildren(_ containerNeedsLayout: Bool) {
    let layoutSizeChanged = layoutSizeOfNearestViewportChanged()
    let transformChanged = SVGContainerLayout.transformToRootChanged(container)

    positionedChildren.removeAll()
    for child: RenderObjectWrapper in childrenOfType(parent: container) {
      if child.isSVGLayerAwareRenderer() {
        positionedChildren.append(child as! RenderLayerModelObjectWrapper)
      }

      var needsLayout = containerNeedsLayout
      let childEverHadLayout = child.everHadLayout()

      if transformChanged {
        // If the transform changed we need to update the text metrics (note: this also happens for layoutSizeChanged=true).
        if let text = child as? RenderSVGTextWrapper {
          text.setNeedsTextMetricsUpdate()
        }
        needsLayout = true
      }

      if layoutSizeChanged {
        if child.isAnonymous() {
          assert(child is RenderSVGViewportContainerWrapper)
          needsLayout = true
        } else if let element = child.node() as? SVGElementWrapper, element.hasRelativeLengths() {
          // When containerNeedsLayout is false and the layout size changed, we have to check whether this child uses relative lengths

          // When the layout size changed and when using relative values tell the RenderSVGShape to update its shape object
          if let shape = child as? RenderSVGShapeWrapper {
            shape.setNeedsShapeUpdate()
            needsLayout = true
          } else if let svgText = child as? RenderSVGTextWrapper {
            svgText.setNeedsTextMetricsUpdate()
            svgText.setNeedsPositioningValuesUpdate()
            needsLayout = true
          } else if let resource = child as? RenderSVGResourceGradient {
            resource.invalidateGradient()
          }
          // FIXME: [LBSE] Add pattern support.
        }
      }

      if needsLayout {
        child.setNeedsLayout(markParents: .MarkOnlyThis)
      }

      if let element = child as? RenderElementWrapper {
        if element.needsLayout() {
          element.layout()
        }

        if !childEverHadLayout && element.checkForRepaintDuringLayout() {
          element.repaint()
        }
      }

      assert(!child.needsLayout())
    }
  }

  func positionChildrenRelativeToContainer() {
    if positionedChildren.isEmpty {
      return
    }

    let verifyPositionedChildRendererExpectation = { (renderer: RenderObjectWrapper) in
      #if !NDEBUG
        assert(renderer.isSVGLayerAwareRenderer())  // Pre-condition to enter m_positionedChildren
        assert(!renderer.isRenderSVGRoot())  // There is only one outermost RenderSVGRoot object
        assert(!renderer.isRenderSVGInline())  // Inlines are only allowed within a RenderSVGText tree

        if (renderer is RenderSVGModelObjectWrapper) || (renderer is RenderSVGBlockWrapper) {
          return
        }

        fatalError("Not reached")
      #endif
    }

    let computeContainerLayoutLocation = { () in
      // The nominal SVG layout location (== flooredLayoutPoint(objectBoundingBoxWithoutTransformsTopLeft), where
      // objectBoundingBoxWithoutTransforms = union of child boxes, not mapped through their tranforms) is
      // only meaningful for the children of the RenderSVGRoot. RenderSVGRoot itself is positioned according to
      // the CSS box model object, where we need to respect border & padding, encoded in the contentBoxLocation().
      // -> Position all RenderSVGRoot children relative to the contentBoxLocation() to avoid intruding border/padding area.
      if let svgRoot = container as? RenderSVGRootWrapper {
        return -svgRoot.contentBoxLocation()
      }

      // For (inner) RenderSVGViewportContainer nominalSVGLayoutLocation() returns the viewport boundaries,
      // including the effect of the 'x'/'y' attribute values. Do not subtract the location, otherwise the
      // effect of the x/y translation is removed.
      if (container is RenderSVGViewportContainerWrapper) && !container.isAnonymous() {
        return LayoutPointWrapper()
      }

      return container.nominalSVGLayoutLocation()
    }

    // Arrange layout location for all child renderers relative to the container layout location.
    let parentLayoutLocation = computeContainerLayoutLocation()
    for child in positionedChildren {
      verifyPositionedChildRendererExpectation(child)

      let desiredLayoutLocation = toLayoutPoint(
        size: child.nominalSVGLayoutLocation() - parentLayoutLocation)
      if child.currentSVGLayoutLocation() != desiredLayoutLocation {
        child.setCurrentSVGLayoutLocation(desiredLayoutLocation)
      }
    }
  }

  static func transformToRootChanged(_ ancestor: RenderObjectWrapper?) -> Bool {
    var ancestor = ancestor
    while ancestor != nil {
      if let container = ancestor as? RenderSVGTransformableContainerWrapper {
        return container.didTransformToRootUpdate
      }

      if let container = ancestor as? RenderSVGViewportContainerWrapper {
        return container.didTransformToRootUpdate
      }

      if let svgRoot = ancestor as? RenderSVGRootWrapper {
        return svgRoot.didTransformToRootUpdate
      }
      ancestor = ancestor!.parent()
    }

    return false
  }

  private func layoutSizeOfNearestViewportChanged() -> Bool {
    var ancestor: RenderElementWrapper? = container
    while ancestor != nil && !(ancestor is RenderSVGRootWrapper)
      && !(ancestor is RenderSVGViewportContainerWrapper)
    {
      ancestor = ancestor!.parent()
    }

    assert(ancestor != nil)
    if let viewportContainer = ancestor as? RenderSVGViewportContainerWrapper {
      return viewportContainer.isLayoutSizeChanged
    }

    if let svgRoot = ancestor as? RenderSVGRootWrapper {
      return svgRoot.isLayoutSizeChanged
    }

    return false
  }

  private let container: RenderLayerModelObjectWrapper
  private var positionedChildren: [RenderLayerModelObjectWrapper] = []
}
