/*
 * Copyright (C) 2006 Oliver Hunt <ojh16@student.canterbury.ac.nz>
 * Copyright (C) 2006-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2011 Torch Mobile (Beijing) CO. Ltd. All rights reserved.
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

final class SVGRootInlineBox: LegacyRootInlineBox {
  init(_ renderSVGText: RenderSVGTextWrapper) {
    super.init(renderSVGText)
  }

  override final func virtualLogicalHeight() -> Float32 { return logicalHeight }

  private func setLogicalHeight(_ height: Float32) { logicalHeight = height }

  func computePerCharacterLayoutInformation() {
    let textRoot = blockFlow() as! RenderSVGTextWrapper

    let layoutAttributes = textRoot.layoutAttributes
    if layoutAttributes.a.isEmpty {
      return
    }

    if textRoot.needsReordering {
      reorderValueListsToLogicalOrder(layoutAttributes)
    }

    // Perform SVG text layout phase two (see SVGTextLayoutEngine for details).
    var characterLayout = SVGTextLayoutEngine(layoutAttributes)
    layoutCharactersInTextBoxes(self, &characterLayout)

    // Perform SVG text layout phase three (see SVGTextChunkBuilder for details).
    let fragmentMap = characterLayout.finishLayout()

    // Perform SVG text layout phase four
    // Position & resize all SVGInlineText/FlowBoxes in the inline box tree, resize the root box as well as the RenderSVGText parent block.
    let childRect = layoutChildBoxes(self, fragmentMap)
    layoutRootBox(childRect)
  }

  override func paint(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, lineTop: LayoutUnit,
    lineBottom: LayoutUnit
  ) {
    assert(paintInfo.phase == .Foreground || paintInfo.phase == .Selection)
    assert(!paintInfo.context().paintingDisabled())

    if renderer().document().settings().layerBasedSVGEngineEnabled() {
      var overflowRect = visualOverflowRect(lineTop: lineTop, lineBottom: lineBottom)
      flipForWritingMode(rect: &overflowRect)
      overflowRect.moveBy(offset: paintOffset)

      if !paintInfo.rect.intersects(other: overflowRect) {
        return
      }
    }

    let isPrinting = renderSVGText().document().printing()
    let hasSelection = !isPrinting && selectionState() != .None
    let shouldPaintSelectionHighlight = !(paintInfo.paintBehavior.contains(.SkipSelectionHighlight))

    let childPaintInfo = paintInfo.deepCopy()
    childPaintInfo.updateSubtreePaintRootForChildren(renderer: renderer())

    if hasSelection && shouldPaintSelectionHighlight {
      var child = firstChild()
      while child != nil {
        if let textBox = child as? SVGInlineTextBox {
          textBox.paintSelectionBackground(childPaintInfo)
        } else if let flowBox = child as? SVGInlineFlowBox {
          flowBox.paintSelectionBackground(childPaintInfo)
        }
        child = child!.nextOnLine()
      }
    }

    if renderer().document().settings().layerBasedSVGEngineEnabled() {
      var child = firstChild()
      while child != nil {
        if child!.renderer.isRenderText() || !child!.boxModelObject()!.hasSelfPaintingLayer() {
          child!.paint(
            paintInfo: childPaintInfo, paintOffset: paintOffset, lineTop: lineTop,
            lineBottom: lineBottom)
        }
        child = child!.nextOnLine()
      }

      return
    }

    let renderingContext = SVGRenderingContext(renderSVGText(), paintInfo, .SaveGraphicsContext)
    if renderingContext.isRenderingPrepared() {
      var child = firstChild()
      while child != nil {
        if child!.renderer.isRenderText() || !child!.boxModelObject()!.hasSelfPaintingLayer() {
          child!.paint(
            paintInfo: childPaintInfo, paintOffset: paintOffset, lineTop: LayoutUnit(value: 0),
            lineBottom: LayoutUnit(value: 0))
        }
        child = child!.nextOnLine()
      }
    }
  }

  func closestLeafChildForPosition(_ point: LayoutPointWrapper) -> LegacyInlineBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func renderSVGText() -> RenderSVGTextWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func reorderValueListsToLogicalOrder(
    _ attributes: RenderSVGTextWrapper.LayoutAttributesRef
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func layoutCharactersInTextBoxes(
    _ start: LegacyInlineFlowBox, _ characterLayout: inout SVGTextLayoutEngine
  ) {
    var child = start.firstChild()
    while child != nil {
      if let legacyTextBox = child as? SVGInlineTextBox {
        assert(legacyTextBox.renderer() is RenderSVGInlineTextWrapper)
        characterLayout.layoutInlineTextBox(InlineIterator.svgTextBoxFor(legacyTextBox))
      } else {
        // Skip generated content.
        guard let node = child!.rendererObject().node() else { continue }

        let flowBox = child! as! SVGInlineFlowBox
        let isTextPath = node.hasTextPathTagName()  // TODO(asuhan): use hasTagName
        if isTextPath {
          // Build text chunks for all <textPath> children, using the line layout algorithm.
          // This is needeed as text-anchor is just an additional startOffset for text paths.
          var lineLayout = SVGTextLayoutEngine(characterLayout.layoutAttributes)
          layoutCharactersInTextBoxes(flowBox, &lineLayout)

          characterLayout.beginTextPathLayout(
            child!.rendererObject() as! RenderSVGTextPath, &lineLayout)
        }

        layoutCharactersInTextBoxes(flowBox, &characterLayout)

        if isTextPath {
          characterLayout.endTextPathLayout()
        }
      }
      child = child!.nextOnLine()
    }
  }

  @discardableResult
  private func layoutChildBoxes(_ start: LegacyInlineFlowBox, _ fragmentMap: SVGTextFragmentMap)
    -> FloatRectWrapper
  {
    var childRect = FloatRectWrapper()

    var child = start.firstChild()
    while child != nil {
      var boxRect = FloatRectWrapper()
      if let textBox = child as? SVGInlineTextBox {
        assert(textBox.renderer() is RenderSVGInlineTextWrapper)

        let svgTextBox = InlineIterator.svgTextBoxFor(textBox)
        let fragmentKey = (svgTextBox.get().renderer(), svgTextBox.get().start())
        if fragmentMap.contains(fragmentKey) {
          let textFragments = fragmentMap.get(fragmentKey)
          textBox.setTextFragments(textFragments.a)
        }

        boxRect = textBox.calculateBoundaries()
        textBox.setX(boxRect.x())
        textBox.setY(boxRect.y())
        textBox.setLogicalWidth(boxRect.width())
        textBox.setLogicalHeight(boxRect.height())
      } else {
        // Skip generated content.
        if child!.rendererObject().node() == nil {
          continue
        }

        let flowBox = child! as! SVGInlineFlowBox
        layoutChildBoxes(flowBox, fragmentMap)

        boxRect = flowBox.calculateBoundaries()
        flowBox.setX(boxRect.x())
        flowBox.setY(boxRect.y())
        flowBox.setLogicalWidth(boxRect.width())
        flowBox.setLogicalHeight(boxRect.height())
      }
      childRect.unite(other: boxRect)
      child = child!.nextOnLine()
    }

    return childRect
  }

  private func layoutRootBox(_ childRect: FloatRectWrapper) {
    let parentBlock = renderSVGText()

    // Finally, assign the root block position, now that all content is laid out.
    parentBlock.updatePositionAndOverflow(childRect)

    // Position all children relative to the parent block.
    var child = firstChild()
    while child != nil {
      // Skip generated content.
      if child!.rendererObject().node() == nil {
        continue
      }
      child!.adjustPosition(-childRect.x(), -childRect.y())
      child = child!.nextOnLine()
    }

    // Position ourselves.
    setX(0)
    setY(0)
    setLogicalWidth(childRect.width())
    setLogicalHeight(childRect.height())

    let boundingRect = enclosingLayoutRect(rect: childRect)
    setLineTopBottomPositions(
      top: LayoutUnit(value: 0), bottom: boundingRect.height(), lineBoxTop: LayoutUnit(value: 0),
      lineBoxBottom: boundingRect.height())
  }

  private var logicalHeight: Float32 = 0
}
