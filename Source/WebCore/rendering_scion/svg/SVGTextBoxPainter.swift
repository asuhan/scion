/*
 * Copyright (c) 2024 Apple Inc. All rights reserved.
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

private func textShouldBePainted(_ textRenderer: RenderSVGInlineTextWrapper) -> Bool {
  return textRenderer.scaledFont().size() >= 0.5
}

private func positionOffsetForDecoration(
  _ decoration: TextDecorationLine, _ fontMetrics: FontMetricsWrapper, _ thickness: Float32
) -> Float32 {
  // FIXME: For SVG Fonts we need to use the attributes defined in the <font-face> if specified.
  // Compatible with Batik/Opera.
  let ascent = fontMetrics.ascent()
  if decoration == .Underline {
    return ascent + thickness * 1.5
  }
  if decoration == .Overline {
    return thickness
  }
  if decoration == .LineThrough {
    return ascent * 5 / 8
  }

  fatalError("Not reached")
}

private func thicknessForDecoration(_ font: FontCascadeWrapper) -> Float32 {
  // FIXME: For SVG Fonts we need to use the attributes defined in the <font-face> if specified.
  // Compatible with Batik/Opera
  return font.size() / 20
}

class SVGTextBoxPainter<TextBoxPath: BoxPath>: TextBoxPainter<TextBoxPath> {
  override func paint() {
    assert(paintInfo.shouldPaintWithinRoot(renderer: renderer()))
    assert(paintInfo.phase == .Foreground || paintInfo.phase == .Selection)

    if renderer().style().usedVisibility() != .Visible {
      return
    }

    // Note: We're explicitly not supporting composition & custom underlines and custom highlighters - unlike LegacyInlineTextBox.
    // If we ever need that for SVG, it's very easy to refactor and reuse the code.

    let parentRenderer = parentRenderer()

    let paintSelectedTextOnly = paintInfo.phase == .Selection
    let shouldPaintSelectionHighlight = !(paintInfo.paintBehavior.contains(.SkipSelectionHighlight))
    let hasSelection = !parentRenderer.document().printing() && haveSelection
    if !hasSelection && paintSelectedTextOnly {
      return
    }

    if !textShouldBePainted(renderer()) {
      return
    }

    let style = parentRenderer.style()

    let svgStyle = style.svgStyle()

    var hasFill = svgStyle.hasFill()
    var hasVisibleStroke = style.hasVisibleStroke()

    var selectionStyle: RenderStyleWrapper? = style
    if hasSelection && shouldPaintSelectionHighlight {
      selectionStyle = parentRenderer.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .Selection))
      if selectionStyle != nil {
        if !hasFill {
          hasFill = selectionStyle!.svgStyle().hasFill()
        }
        if !hasVisibleStroke {
          hasVisibleStroke = selectionStyle!.hasVisibleStroke()
        }
      } else {
        selectionStyle = style
      }
    }

    if renderer().view().frameView().paintBehavior().contains(.RenderingSVGClipOrMask) {
      hasFill = true
      hasVisibleStroke = false
    }

    var fragmentTransform = AffineTransform()
    for fragment in textBoxIterator().get().textFragments() {
      assert(legacyPaintingResource == nil)

      let _ = GraphicsContextStateSaver(context: paintInfo.context())
      fragment.buildFragmentTransform(&fragmentTransform)
      if !fragmentTransform.isIdentity() {
        paintInfo.context().concatCTM(transform: fragmentTransform)
      }

      // Spec: All text decorations except line-through should be drawn before the text is filled and stroked; thus, the text is rendered on top of these decorations.
      let decorations = style.textDecorationsInEffect()
      if decorations.contains(.Underline) {
        paintDecoration(.Underline, fragment)
      }
      if decorations.contains(.Overline) {
        paintDecoration(.Overline, fragment)
      }

      for type in RenderStyleWrapper.paintTypesForPaintOrder(order: style.paintOrder()) {
        switch type {
        case .Fill:
          if !hasFill {
            continue
          }
          paintingResourceMode = [.ApplyToFill, .ApplyToText]
          assert(selectionStyle != nil)
          paintText(style, selectionStyle!, fragment, hasSelection, paintSelectedTextOnly)
        case .Stroke:
          if !hasVisibleStroke {
            continue
          }
          paintingResourceMode = [.ApplyToStroke, .ApplyToText]
          assert(selectionStyle != nil)
          paintText(style, selectionStyle!, fragment, hasSelection, paintSelectedTextOnly)
        case .Markers:
          continue
        }
      }

      // Spec: Line-through should be drawn after the text is filled and stroked; thus, the line-through is rendered on top of the text.
      if decorations.contains(.LineThrough) {
        paintDecoration(.LineThrough, fragment)
      }

      paintingResourceMode = []
    }

    // Finally, paint the outline if any.
    if renderer().style().hasOutline(), let renderInline = parentRenderer as? RenderInlineWrapper {
      renderInline.paintOutline(paintInfo: paintInfo, paintOffset: paintOffset)
    }

    assert(legacyPaintingResource == nil)
  }

  private func textBoxIterator() -> InlineIterator.SVGTextBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func renderer() -> RenderSVGInlineTextWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func parentRenderer() -> RenderBoxModelObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintDecoration(_ decoration: TextDecorationLine, _ fragment: SVGTextFragment) {
    if renderer().style().textDecorationsInEffect().isEmpty {
      return
    }

    // Find out which render style defined the text-decoration, as its fill/stroke properties have to be used for drawing instead of ours.

    let decorationRenderer = { () in
      var parentBox = textBoxIterator().get().parentInlineBox()

      // Lookup first render object in parent hierarchy which has text-decoration set.
      var renderer: RenderBoxModelObjectWrapper? = nil
      while parentBox.bool() {
        renderer = parentBox.get().renderer()

        if !renderer!.style().textDecorationLine().isEmpty {
          break
        }

        parentBox = parentBox.get().parentInlineBox()
      }

      return renderer
    }()

    assert(decorationRenderer != nil)

    let decorationStyle = decorationRenderer!.style()

    if decorationStyle.usedVisibility() == .Hidden {
      return
    }

    let svgDecorationStyle = decorationStyle.svgStyle()

    for type in RenderStyleWrapper.paintTypesForPaintOrder(order: renderer().style().paintOrder()) {
      switch type {
      case .Fill:
        if svgDecorationStyle.hasFill() {
          paintingResourceMode = [.ApplyToFill]
          paintDecorationWithStyle(decoration, fragment, decorationRenderer!)
        }
      case .Stroke:
        if decorationStyle.hasVisibleStroke() {
          paintingResourceMode = [.ApplyToStroke]
          paintDecorationWithStyle(decoration, fragment, decorationRenderer!)
        }
      case .Markers:
        break
      }
    }
  }

  private func paintDecorationWithStyle(
    _ decoration: TextDecorationLine, _ fragment: SVGTextFragment,
    _ decorationRenderer: RenderBoxModelObjectWrapper
  ) {
    assert(legacyPaintingResource == nil)
    assert(!paintingResourceMode.isEmpty)

    let context = paintInfo.context()
    let decorationStyle = decorationRenderer.style()

    let (_, scalingFactor, scaledFont) = RenderSVGInlineTextWrapper.computeNewScaledFontForStyle(
      decorationRenderer, decorationStyle)
    assert(scalingFactor != 0)

    // The initial y value refers to overline position.
    let thickness = thicknessForDecoration(scaledFont)

    if fragment.width <= 0 && thickness <= 0 {
      return
    }

    var decorationOrigin = FloatPoint(x: fragment.x, y: fragment.y)
    var width = fragment.width
    let scaledFontMetrics = scaledFont.metricsOfPrimaryFont()

    let _ = GraphicsContextStateSaver(context: context)
    if scalingFactor != 1 {
      width *= scalingFactor
      decorationOrigin.scale(scalingFactor)
      context.scale(1 / scalingFactor)
    }

    decorationOrigin.move(
      dx: 0,
      dy: -scaledFontMetrics.ascent()
        + positionOffsetForDecoration(decoration, scaledFontMetrics, thickness))

    let path = PathWrapper()
    path.addRect(
      rect: FloatRectWrapper(
        location: decorationOrigin, size: FloatSize(width: width, height: thickness)))

    if decorationRenderer.document().settings().layerBasedSVGEngineEnabled() {
      var paintServerHandling = SVGPaintServerHandling(context)
      if acquirePaintingResource(
        &paintServerHandling, scalingFactor, decorationRenderer, decorationStyle)
      {
        if paintingResourceMode.contains(.ApplyToFill) {
          context.fillPath(path: path)
        } else if paintingResourceMode.contains(.ApplyToStroke) {
          context.strokePath(path: path)
        }

        releasePaintingResource(&paintServerHandling)
      }
      return
    }

    var usedContext = context
    if acquireLegacyPaintingResource(
      &usedContext, scalingFactor, decorationRenderer, decorationStyle)
    {
      releaseLegacyPaintingResource(&usedContext, path)
    }
  }

  private func paintTextWithShadows(
    _ style: RenderStyleWrapper, _ textRun: TextRunWrapper, _ fragment: SVGTextFragment,
    startPosition: UInt32, endPosition: UInt32
  ) {
    let context = paintInfo.context()

    let scalingFactor = renderer().scalingFactor()
    assert(scalingFactor != 0)

    let scaledFont = renderer().scaledFont()
    var shadow = style.textShadow()

    var textOrigin = FloatPoint(x: fragment.x, y: fragment.y)
    var textSize = FloatSize(width: fragment.width, height: fragment.height)

    if scalingFactor != 1 {
      textOrigin.scale(scalingFactor)
      textSize.scale(scalingFactor)
    }

    let shadowRect = FloatRectWrapper(
      location: FloatPoint(
        x: textOrigin.x, y: textOrigin.y - scaledFont.metricsOfPrimaryFont().ascent()),
      size: textSize
    )

    var usedContext = context
    var paintServerHandling = SVGPaintServerHandling(context)

    let prepareGraphicsContext = { [self] () -> Bool in
      if renderer().document().settings().layerBasedSVGEngineEnabled() {
        return acquirePaintingResource(&paintServerHandling, scalingFactor, parentRenderer(), style)
      }
      return acquireLegacyPaintingResource(&usedContext, scalingFactor, parentRenderer(), style)
    }

    let restoreGraphicsContext = { [self] () in
      if renderer().document().settings().layerBasedSVGEngineEnabled() {
        releasePaintingResource(&paintServerHandling)
        return
      }
      releaseLegacyPaintingResource(&usedContext, nil)
    }

    repeat {
      if !prepareGraphicsContext() {
        break
      }

      do {
        // Optimized code path to support gradient/pattern fill/stroke on text without using temporary ImageBuffers / masking.
        var gradient: GradientWrapper? = nil
        var pattern: PatternWrapper? = nil
        if renderer().document().settings().layerBasedSVGEngineEnabled() {
          let textRootBlock = RenderSVGTextWrapper.locateRenderSVGTextAncestor(start: renderer())!

          var gradientSpaceTransform = AffineTransform()
          if paintingResourceMode.contains(.ApplyToFill) {
            gradient = usedContext.fillGradient()
            gradientSpaceTransform = usedContext.fillGradientSpaceTransform()
            pattern = usedContext.fillPattern()
          } else {
            gradient = usedContext.strokeGradient()
            gradientSpaceTransform = usedContext.strokeGradientSpaceTransform()
            pattern = usedContext.strokePattern()
          }

          assert(gradient == nil || pattern == nil)
          if gradient != nil || pattern != nil {
            if gradient != nil {
              usedContext.fillRect(
                textRootBlock.repaintRectInLocalCoordinates(), gradient!, gradientSpaceTransform)
            } else {
              // FIXME: should be fillRect(const FloatRect&, Pattern&) on GraphicsContext.
              let _ = GraphicsContextStateSaver(context: usedContext)
              if usedContext.strokePattern() != nil {
                usedContext.setFillPattern(pattern: usedContext.strokePattern()!)
              }
              usedContext.fillRect(textRootBlock.repaintRectInLocalCoordinates())
            }
            usedContext.setCompositeOperation(operation: .DestinationIn)
            usedContext.beginTransparencyLayer(opacity: 1)
          }
        }

        let shadowApplier = ShadowApplier(
          style: style, context: usedContext, shadow: shadow, colorFilter: nil, textRect: shadowRect
        )

        if !shadowApplier.didSaveContext {
          usedContext.save()
        }

        usedContext.scale(1 / scalingFactor)
        scaledFont.drawText(
          usedContext, textRun, textOrigin + shadowApplier.extraOffset, from: startPosition,
          to: endPosition
        )

        if !shadowApplier.didSaveContext {
          usedContext.restore()
        }

        if gradient != nil || pattern != nil {
          usedContext.endTransparencyLayer()
        }
      }

      restoreGraphicsContext()

      if shadow == nil {
        break
      }

      shadow = shadow!.next
    } while shadow != nil
  }

  private func paintText(
    _ style: RenderStyleWrapper, _ selectionStyle: RenderStyleWrapper, _ fragment: SVGTextFragment,
    _ hasSelection: Bool, _ paintSelectedTextOnly: Bool
  ) {
    var hasSelection = hasSelection
    var startPosition: UInt32 = 0
    var endPosition: UInt32 = 0
    if hasSelection {
      (startPosition, endPosition) = selectionStartEnd()
      hasSelection = mapStartEndPositionsIntoFragmentCoordinates(
        fragment, startPosition: &startPosition, endPosition: &endPosition)
    }

    // Fast path if there is no selection, just draw the whole chunk part using the regular style
    let textRun = constructTextRun(style, fragment)
    if !hasSelection || startPosition >= endPosition {
      paintTextWithShadows(style, textRun, fragment, startPosition: 0, endPosition: fragment.length)
      return
    }

    // Eventually draw text using regular style until the start position of the selection
    if startPosition > 0 && !paintSelectedTextOnly {
      paintTextWithShadows(style, textRun, fragment, startPosition: 0, endPosition: startPosition)
    }

    // Draw text using selection style from the start to the end position of the selection
    do {
      let _ = SVGResourcesCache.SetStyleForScope(parentRenderer(), style, newStyle: selectionStyle)
      paintTextWithShadows(
        selectionStyle, textRun, fragment, startPosition: startPosition, endPosition: endPosition)
    }

    // Eventually draw text using regular style from the end position of the selection to the end of the current chunk part
    if endPosition < fragment.length && !paintSelectedTextOnly {
      paintTextWithShadows(
        style, textRun, fragment, startPosition: endPosition, endPosition: fragment.length)
    }
  }

  private func acquirePaintingResource(
    _ paintServerHandling: inout SVGPaintServerHandling, _ scalingFactor: Float32,
    _ renderer: RenderBoxModelObjectWrapper, _ style: RenderStyleWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func releasePaintingResource(_ paintServerHandling: inout SVGPaintServerHandling) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func acquireLegacyPaintingResource(
    _ context: inout GraphicsContextWrapper, _ scalingFactor: Float32,
    _ renderer: RenderBoxModelObjectWrapper, _ style: RenderStyleWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func releaseLegacyPaintingResource(
    _ context: inout GraphicsContextWrapper, _ path: PathWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func mapStartEndPositionsIntoFragmentCoordinates(
    _ fragment: SVGTextFragment, startPosition: inout UInt32, endPosition: inout UInt32
  ) -> Bool {
    let startFragment = fragment.characterOffset - textBox.start()
    let endFragment = startFragment + fragment.length

    // Find intersection between the intervals: [startFragment..endFragment) and [startPosition..endPosition)
    startPosition = max(startFragment, startPosition)
    endPosition = min(endFragment, endPosition)

    if startPosition >= endPosition {
      return false
    }

    startPosition -= startFragment
    endPosition -= startFragment

    return true
  }

  private func constructTextRun(_ style: RenderStyleWrapper, _ fragment: SVGTextFragment)
    -> TextRunWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var paintingResourceMode: RenderSVGResourceMode = []
  private let legacyPaintingResource: LegacyRenderSVGResource? = nil
}

class LegacySVGTextBoxPainter: SVGTextBoxPainter<InlineIterator.BoxLegacyPath> {
  init(
    _ textBox: SVGInlineTextBox, _ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
