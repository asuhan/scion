/*
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Alexander Kellett <lypanov@kde.org>
 * Copyright (C) 2006 Oliver Hunt <ojh16@student.canterbury.ac.nz>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
 * Copyright (C) 2012-2023 Google Inc.
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

private func collectLayoutAttributes(
  _ text: RenderObjectWrapper?, _ attributes: inout [SVGTextLayoutAttributes]
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

@discardableResult
private func findPreviousAndNextAttributes(
  _ start: RenderElementWrapper, _ locateElement: RenderSVGInlineTextWrapper,
  _ stopAfterNext: inout Bool, _ previous: inout SVGTextLayoutAttributes?,
  _ next: inout SVGTextLayoutAttributes?
) -> Bool {
  // FIXME: Make this iterative.
  for child: RenderObjectWrapper in childrenOfType(parent: start) {
    if let text = child as? RenderSVGInlineTextWrapper {
      if CPtrToInt(locateElement.p) != CPtrToInt(text.p) {
        if stopAfterNext {
          next = text.layoutAttributes()
          return true
        }

        previous = text.layoutAttributes()
        continue
      }

      stopAfterNext = true
      continue
    }

    guard let childSVGInline = child as? RenderSVGInlineWrapper else { continue }

    if findPreviousAndNextAttributes(
      childSVGInline, locateElement, &stopAfterNext, &previous, &next)
    {
      return true
    }
  }

  return false
}

private func checkLayoutAttributesConsistency(
  _ text: RenderSVGTextWrapper, _ expectedLayoutAttributes: ArraySlice<SVGTextLayoutAttributes>
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func updateFontInAllDescendants(_ text: RenderSVGTextWrapper) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class RenderSVGTextWrapper: RenderSVGBlockWrapper {
  func textElement() -> SVGTextElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsPositioningValuesUpdate() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsTextMetricsUpdate() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: [LBSE] Only needed for legacy SVG engine.
  override func setNeedsTransformUpdate() { needsTransformUpdate = true }

  static func locateRenderSVGTextAncestor(start: RenderObjectWrapper) -> RenderSVGTextWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func subtreeChildWasAdded(child: RenderObjectWrapper?) {
    assert(child != nil)
    if !shouldHandleSubtreeMutations() || renderTreeBeingDestroyed() {
      return
    }

    // The positioning elements cache doesn't include the new 'child' yet. Clear the
    // cache, as the next buildLayoutAttributesForTextRenderer() call rebuilds it.
    layoutAttributesBuilder.clearTextPositioningElements()

    if !child!.isRenderSVGInlineText() && !child!.isRenderSVGInline() {
      return
    }

    // Detect changes in layout attributes and only measure those text parts that have changed!
    var newLayoutAttributes: [SVGTextLayoutAttributes] = []
    collectLayoutAttributes(self, &newLayoutAttributes)
    if newLayoutAttributes.isEmpty {
      assert(layoutAttributes.isEmpty)
      return
    }

    // Compare layoutAttributes with newLayoutAttributes to figure out which attribute got added.
    var attributes_: SVGTextLayoutAttributes? = nil
    for attributes in newLayoutAttributes {
      attributes_ = attributes
      if layoutAttributes.contains(where: { (element: SVGTextLayoutAttributes) in
        return element === attributes
      }) {
        continue
      }
      // Every time this is invoked, there's only a single new entry in the newLayoutAttributes list, compared to the old in layoutAttributes.
      var stopAfterNext = false
      var previous: SVGTextLayoutAttributes? = nil
      var next: SVGTextLayoutAttributes? = nil
      findPreviousAndNextAttributes(self, attributes.context(), &stopAfterNext, &previous, &next)

      if previous != nil {
        layoutAttributesBuilder.buildLayoutAttributesForTextRenderer(previous!.context())
      }
      layoutAttributesBuilder.buildLayoutAttributesForTextRenderer(attributes.context())
      if next != nil {
        layoutAttributesBuilder.buildLayoutAttributesForTextRenderer(next!.context())
      }
      break
    }

    #if !NDEBUG
      // Verify that layoutAttributes only differs by a maximum of one entry.
      for newAttr in newLayoutAttributes {
        assert(
          layoutAttributes.contains(where: { (element: SVGTextLayoutAttributes) in
            return element === newAttr
          }) || newAttr === attributes_)
      }
    #endif

    layoutAttributes = newLayoutAttributes
  }

  func subtreeChildWillBeRemoved(
    child: RenderObjectWrapper, affectedAttributes: inout [SVGTextLayoutAttributes]
  ) {
    if !shouldHandleSubtreeMutations() {
      return
    }

    checkLayoutAttributesConsistency(self, layoutAttributes[...])

    // The positioning elements cache depends on the size of each text renderer in the
    // subtree. If this changes, clear the cache. It's going to be rebuilt below.
    layoutAttributesBuilder.clearTextPositioningElements()
    if layoutAttributes.isEmpty || !child.isRenderSVGInlineText() {
      return
    }

    // This logic requires that the 'text' child is still inserted in the tree.
    let text = child as! RenderSVGInlineTextWrapper
    var stopAfterNext = false
    var previous: SVGTextLayoutAttributes? = nil
    var next: SVGTextLayoutAttributes? = nil
    if !renderTreeBeingDestroyed() {
      findPreviousAndNextAttributes(self, text, &stopAfterNext, &previous, &next)
    }

    if previous != nil {
      affectedAttributes.append(previous!)
    }
    if next != nil {
      affectedAttributes.append(next!)
    }

    let indexToRemove = layoutAttributes.firstIndex(where: { (element: SVGTextLayoutAttributes) in
      return element === text.layoutAttributes()
    })
    layoutAttributes.remove(at: indexToRemove!)
  }

  func subtreeChildWasRemoved(affectedAttributes: ArraySlice<SVGTextLayoutAttributes>) {
    if !shouldHandleSubtreeMutations() || renderTreeBeingDestroyed() {
      assert(affectedAttributes.isEmpty)
      return
    }

    // This is called immediately after subtreeChildWillBeDestroyed, once the RenderSVGInlineText.willBeDestroyed() method
    // passes on to the base class, which removes us from the render tree. At this point we can update the layout attributes.
    for affectedAttribute in affectedAttributes {
      layoutAttributesBuilder.buildLayoutAttributesForTextRenderer(affectedAttribute.context())
    }
  }

  override final func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visualOverflowRectEquivalent() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updatePositionAndOverflow(_ boundaries: FloatRectWrapper) {
    if document().settings().layerBasedSVGEngineEnabled() {
      clearOverflow()

      m_objectBoundingBox = boundaries

      let boundingRect = enclosingLayoutRect(rect: m_objectBoundingBox)
      setLocation(p: boundingRect.location())
      setSize(boundingRect.size())

      var overflowRect = visualOverflowRectEquivalent()
      if let textShadow = style().textShadow() {
        textShadow.adjustRectForShadow(&overflowRect)
      }

      addVisualOverflow(rect: overflowRect)
      return
    }

    let boundingRect = enclosingLayoutRect(rect: boundaries)
    setLocation(p: boundingRect.location())
    setSize(boundingRect.size())
    m_objectBoundingBox = boundingRect.FloatRect()
    assert(m_objectBoundingBox == frameRect().FloatRect())
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if document().settings().layerBasedSVGEngineEnabled() {
      let relevantPaintPhases: PaintPhase = [
        .Foreground, .ClippingMask, .Mask, .Outline, .SelfOutline,
      ]
      if !shouldPaintSVGRenderer(paintInfo, relevantPaintPhases) {
        return
      }

      if paintInfo.phase == .ClippingMask {
        paintSVGClippingMask(paintInfo: paintInfo, objectBoundingBox: objectBoundingBox())
        return
      }

      let adjustedPaintOffset = paintOffset + location()
      if paintInfo.phase == .Mask {
        paintSVGMask(paintInfo, adjustedPaintOffset)
        return
      }

      if paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline {
        super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
        return
      }

      assert(paintInfo.phase == .Foreground)
      let _ = GraphicsContextStateSaver(context: paintInfo.context())

      let coordinateSystemOriginTranslation = adjustedPaintOffset - nominalSVGLayoutLocation()
      paintInfo.context().translate(
        x: coordinateSystemOriginTranslation.width().float(),
        y: coordinateSystemOriginTranslation.height().float())

      super.paint(paintInfo: &paintInfo, paintOffset: paintOffset)
      return
    }

    if paintInfo.context().paintingDisabled() {
      return
    }

    if paintInfo.phase != .ClippingMask && paintInfo.phase != .Mask
      && paintInfo.phase != .Foreground && paintInfo.phase != .Outline
      && paintInfo.phase != .SelfOutline
    {
      return
    }

    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    var blockInfo = paintInfo.deepCopy()
    let _ = GraphicsContextStateSaver(context: blockInfo.context())
    blockInfo.applyTransform(localToParentTransform())
    super.paint(paintInfo: &blockInfo, paintOffset: LayoutPointWrapper())

    // Paint the outlines, if any
    if paintInfo.phase == .Foreground {
      blockInfo.phase = .SelfOutline
      super.paint(paintInfo: &blockInfo, paintOffset: LayoutPointWrapper())
    }
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    let isLayerBasedSVGEngineEnabled = { [self] () in
      return document().settings().layerBasedSVGEngineEnabled()
    }

    // TODO(asuhan): add stack stats
    assert(needsLayout())

    if shouldHandleSubtreeMutations() && !renderTreeBeingDestroyed() {
      checkLayoutAttributesConsistency(self, layoutAttributes[...])
    }

    let checkForRepaintOverride =
      !isLayerBasedSVGEngineEnabled() ? SVGRenderSupport.checkForSVGRepaintDuringLayout(self) : nil
    let repainter = LayoutRepainter(
      renderer: self, checkForRepaintOverride: checkForRepaintOverride)

    var updateCachedBoundariesInParents = false
    let previousReferenceBoxRect = transformReferenceBoxRect()

    // We update the transform now because updateScaledFont() needs it, but we do it a second time at the end of the layout,
    // since the transform reference box may change because of the font change.
    if !isLayerBasedSVGEngineEnabled() && needsTransformUpdate {
      localTransform = textElement().animatedLocalTransform()
      updateCachedBoundariesInParents = true
    }

    if !everHadLayout() {
      // When laying out initially, collect all layout attributes, build the character data map,
      // and propogate resulting SVGLayoutAttributes to all RenderSVGInlineText children in the subtree.
      assert(layoutAttributes.isEmpty)
      collectLayoutAttributes(self, &layoutAttributes)
      updateFontInAllDescendants(self)
      layoutAttributesBuilder.buildLayoutAttributesForForSubtree(self)

      needsReordering = true
      needsTextMetricsUpdate = false
      needsPositioningValuesUpdate = false
      updateCachedBoundariesInParents = true
    } else if needsPositioningValuesUpdate {
      // When the x/y/dx/dy/rotate lists change, recompute the layout attributes, and eventually
      // update the on-screen font objects as well in all descendants.
      if needsTextMetricsUpdate {
        updateFontInAllDescendants(self)
      }
      layoutAttributesBuilder.buildLayoutAttributesForForSubtree(self)
      needsReordering = true
      needsTextMetricsUpdate = false
      needsPositioningValuesUpdate = false
      updateCachedBoundariesInParents = true
    } else {
      var isLayoutSizeChanged = false
      if let legacyRootObject = RenderAncestorIteratorAdapter<LegacyRenderSVGRootWrapper>
        .lineageOfType(first: self).first()
      {
        isLayoutSizeChanged = legacyRootObject.isLayoutSizeChanged
      } else if let rootObject = RenderAncestorIteratorAdapter<RenderSVGRootWrapper>.lineageOfType(
        first: self
      ).first() {
        isLayoutSizeChanged = rootObject.isLayoutSizeChanged
      }

      if needsTextMetricsUpdate || isLayoutSizeChanged {
        // If the root layout size changed (eg. window size changes) or the transform to the root
        // context has changed then recompute the on-screen font size.
        updateFontInAllDescendants(self)

        assert(!needsReordering)
        assert(!needsPositioningValuesUpdate)
        needsTextMetricsUpdate = false
        updateCachedBoundariesInParents = true
      }
      layoutAttributesBuilder.rebuildMetricsForSubtree(self)
    }

    checkLayoutAttributesConsistency(self, layoutAttributes[...])

    // Reduced version of RenderBlock::layoutBlock(), which only takes care of SVG text.
    // All if branches that could cause early exit in RenderBlocks layoutBlock() method are turned into assertions.
    assert(!isInline())
    assert(!scrollsOverflow())
    assert(!hasControlClip())
    assert(multiColumnFlowForBlockFlow() == nil)
    assert(positionedObjects() == nil)
    assert(!isAnonymousBlock())
    if !isLayerBasedSVGEngineEnabled() {
      assert(!simplifiedLayout())
      assert(overflow == nil)
    }

    // FIXME: We need to find a way to only layout the child boxes, if needed.
    var layoutChanged = everHadLayout() && selfNeedsLayout()
    let oldBoundaries = objectBoundingBox()

    if firstChild() == nil {
      updatePositionAndOverflow(FloatRectWrapper())
      setChildrenInline(b: true)
    }

    assert(childrenInline())

    var repaintLogicalTop = LayoutUnit()
    var repaintLogicalBottom = LayoutUnit()
    rebuildFloatingObjectSetFromIntrudingFloats()
    layoutInlineChildren(
      relayoutChildren: true, repaintLogicalTop: &repaintLogicalTop,
      repaintLogicalBottom: &repaintLogicalBottom)

    // updatePositionAndOverflow() is called by SVGRootInlineBox, after forceLayoutInlineChildren() ran, before this point is reached.
    needsReordering = false

    if isLayerBasedSVGEngineEnabled() {
      updateLayerTransform()
      updateCachedBoundariesInParents = false  // No longer needed for LBSE.
      layoutChanged = false  // No longer needed for LBSE.
    } else {
      if needsTransformUpdate {
        if previousReferenceBoxRect != transformReferenceBoxRect() {
          localTransform = textElement().animatedLocalTransform()
        }
        needsTransformUpdate = false
      }
      if !updateCachedBoundariesInParents {
        updateCachedBoundariesInParents = oldBoundaries != objectBoundingBox()
      }
    }

    // Invalidate all resources of this client if our layout changed.
    if layoutChanged {
      SVGResourcesCache.clientLayoutChanged(self)
    }

    // If our bounds changed, notify the parents.
    if updateCachedBoundariesInParents, let parent = parent() {
      parent.invalidateCachedBoundaries()
    }

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    let needsTransformUpdate = { [self] () in
      if document().settings().layerBasedSVGEngineEnabled() {
        return false
      }
      if diff != .Layout {
        return false
      }

      let newStyle = style()
      if oldStyle == nil {
        return newStyle.affectsTransform()
      }

      return
        (oldStyle!.affectsTransform() != newStyle.affectsTransform()
        || oldStyle!.transform() != newStyle.transform()
        || oldStyle!.translate() !== newStyle.translate()
        || oldStyle!.scale() !== newStyle.scale()
        || oldStyle!.rotate() !== newStyle.rotate()
        || oldStyle!.offsetPath() !== newStyle.offsetPath())
    }

    if needsTransformUpdate() {
      setNeedsTransformUpdate()
    }

    super.styleDidChange(diff: diff, oldStyle: oldStyle)
  }

  override func localToParentTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldHandleSubtreeMutations() -> Bool {
    if beingDestroyed() || !everHadLayout() {
      assert(layoutAttributes.isEmpty)
      assert(layoutAttributesBuilder.numberOfTextPositioningElements() == 0)
      return false
    }
    return true
  }

  private var needsReordering = false
  private var needsPositioningValuesUpdate = false
  private var needsTransformUpdate = true  // FIXME: [LBSE] Only needed for legacy SVG engine.
  private var needsTextMetricsUpdate = false
  private var localTransform = AffineTransform()  // FIXME: [LBSE] Only needed for legacy SVG engine.
  private var layoutAttributesBuilder = SVGTextLayoutAttributesBuilder()
  private var layoutAttributes: [SVGTextLayoutAttributes] = []
  private var m_objectBoundingBox = FloatRectWrapper()
}
