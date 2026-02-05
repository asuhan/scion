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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintText(
    _ style: RenderStyleWrapper, _ selectionStyle: RenderStyleWrapper, _ fragment: SVGTextFragment,
    _ hasSelection: Bool, _ paintSelectedTextOnly: Bool
  ) {
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
