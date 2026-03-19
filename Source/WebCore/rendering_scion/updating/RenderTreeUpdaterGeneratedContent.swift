/*
 * Copyright (C) 2017 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

private func keyframeEffectStackForElementAndPseudoId(element: ElementWrapper, pseudoId: PseudoId)
  -> KeyframeEffectStackWrapper?
{
  return element.keyframeEffectStack(
    pseudoElementIdentifier: pseudoId == .None
      ? nil : Style.PseudoElementIdentifier(pseudoId: pseudoId))
}

private func elementIsTargetedByKeyframeEffectRequiringPseudoElement(
  element: ElementWrapper?, pseudoId: PseudoId
) -> Bool {
  if let pseudoElement = element as? PseudoElementWrapper {
    return elementIsTargetedByKeyframeEffectRequiringPseudoElement(
      element: pseudoElement.hostElement(), pseudoId: pseudoId)
  }

  if element != nil,
    let stack = keyframeEffectStackForElementAndPseudoId(element: element!, pseudoId: pseudoId)
  {
    return stack.requiresPseudoElement()
  }

  return false
}

private func elementHasDisplayAnimationForPseudoId(element: ElementWrapper, pseudoId: PseudoId)
  -> Bool
{
  if let stack = keyframeEffectStackForElementAndPseudoId(element: element, pseudoId: pseudoId) {
    return stack.containsProperty(property: .CSSPropertyDisplay)
  }
  return false
}

private func createContentRenderers(
  builder: RenderTreeBuilder, pseudoRenderer: RenderElementWrapper, style: RenderStyleWrapper,
  pseudoId: PseudoId
) {
  if let contentData = style.contentData() {
    var content: ContentData? = contentData
    while content != nil {
      let child = content!.createContentRenderer(
        document: pseudoRenderer.document(), pseudoStyle: style)
      if pseudoRenderer.isChildAllowed(child, style) {
        builder.attach(parent: pseudoRenderer, child: child)
      }
      content = content!.next()
    }
  } else {
    // The only valid scenario where this method is called without the "content" property being set
    // is the case where a pseudo-element has animations set on it via the Web Animations API.
    assert(
      elementIsTargetedByKeyframeEffectRequiringPseudoElement(
        element: pseudoRenderer.element(), pseudoId: pseudoId))
  }
}

private func updateStyleForContentRenderers(
  pseudoRenderer: RenderElementWrapper, style: RenderStyleWrapper
) {
  for contentRenderer: RenderElementWrapper in descendantsOfType(root: pseudoRenderer) {
    // We only manage the style for the generated content which must be images or text.
    if !(contentRenderer is RenderImageWrapper) && !(contentRenderer is RenderQuoteWrapper) {
      continue
    }
    contentRenderer.setStyle(
      style: RenderStyleWrapper.createStyleInheritingFromPseudoStyle(pseudoStyle: style))
  }
}

extension RenderTreeUpdater {
  class GeneratedContent {
    init(updater: RenderTreeUpdater) {
      self.updater = updater
    }

    func updateBackdropRenderer(
      renderer: RenderElementWrapper, minimalStyleDifference: StyleDifference
    ) {
      // Intentionally bail out early here to avoid computing the style.
      if renderer.element() == nil || !renderer.element()!.isInTopLayer() {
        destroyBackdropIfNeeded(renderer: renderer)
        return
      }

      let style = renderer.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .Backdrop),
        parentStyle: renderer.style())
      if style == nil || style!.display() == .None {
        destroyBackdropIfNeeded(renderer: renderer)
        return
      }

      let newStyle = RenderStyleWrapper.clone(style: style!)
      if let backdropRenderer = renderer.backdropRenderer() {
        backdropRenderer.setStyle(style: newStyle, minimalStyleDifference: minimalStyleDifference)
      } else {
        let newBackdropRenderer = CreateRenderer.RenderBlockFlow(
          type: .BlockFlow, document: renderer.document(), style: newStyle)
        newBackdropRenderer.initializeStyle()
        renderer.setBackdropRenderer(renderer: newBackdropRenderer)
        updater.builder!.attach(parent: renderer.view(), child: newBackdropRenderer)
      }
    }

    private func destroyBackdropIfNeeded(renderer: RenderElementWrapper) {
      if let backdropRenderer = renderer.backdropRenderer() {
        updater.builder!.destroy(renderer: backdropRenderer)
      }
    }

    func updatePseudoElement(
      current: ElementWrapper, elementUpdate: Style.ElementUpdate, pseudoId: PseudoId
    ) {
      var pseudoElement =
        pseudoId == .Before ? current.beforePseudoElement() : current.afterPseudoElement()

      if let renderer = pseudoElement?.renderer() {
        updater.renderTreePosition().invalidateNextSibling(siblingRenderer: renderer)
      }

      let updateStyle = elementUpdate.style?.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: pseudoId))

      if !needsPseudoElement(style: updateStyle)
        && !elementIsTargetedByKeyframeEffectRequiringPseudoElement(
          element: current, pseudoId: pseudoId)
        && !elementHasDisplayAnimationForPseudoId(element: current, pseudoId: pseudoId)
      {
        if pseudoElement != nil {
          if pseudoId == .Before {
            GeneratedContent.removeBeforePseudoElement(element: current, builder: updater.builder!)
          } else {
            GeneratedContent.removeAfterPseudoElement(element: current, builder: updater.builder!)
          }
        }
        return
      }

      if updateStyle == nil {
        return
      }

      let existingStyle = pseudoElement?.renderOrDisplayContentsStyle()

      let styleChange =
        existingStyle != nil
        ? Style.determineChange(s1: updateStyle!, s2: existingStyle!) : .Renderer
      if styleChange == .None {
        return
      }

      pseudoElement = current.ensurePseudoElement(pseudoId: pseudoId)

      if updateStyle!.display() == .Contents {
        // For display:contents we create an inline wrapper that inherits its
        // style from the display:contents style.
        let contentsStyle = RenderStyleWrapper.create()
        contentsStyle.setPseudoElementType(pseudoElementType: pseudoId)
        contentsStyle.inheritFrom(inheritParent: updateStyle!)
        contentsStyle.copyContentFrom(other: updateStyle!)
        contentsStyle.copyPseudoElementsFrom(other: updateStyle!)

        let contentsUpdate = Style.ElementUpdate(
          style: contentsStyle, change: styleChange,
          recompositeLayer: elementUpdate.recompositeLayer)
        updater.updateElementRenderer(element: pseudoElement!, elementUpdate: contentsUpdate)
        let pseudoElementUpdateStyle = RenderStyleWrapper.cloneIncludingPseudoElements(
          style: updateStyle!)
        pseudoElement!.storeDisplayContentsOrNoneStyle(style: pseudoElementUpdateStyle)
      } else {
        let pseudoElementUpdateStyle = RenderStyleWrapper.cloneIncludingPseudoElements(
          style: updateStyle!)
        let pseudoElementUpdate = Style.ElementUpdate(
          style: pseudoElementUpdateStyle, change: styleChange,
          recompositeLayer: elementUpdate.recompositeLayer)
        updater.updateElementRenderer(element: pseudoElement!, elementUpdate: pseudoElementUpdate)
        if updateStyle!.display() == .None {
          let pseudoElementUpdateStyle = RenderStyleWrapper.cloneIncludingPseudoElements(
            style: updateStyle!)
          pseudoElement!.storeDisplayContentsOrNoneStyle(style: pseudoElementUpdateStyle)
        } else {
          pseudoElement!.clearDisplayContentsOrNoneStyle()
        }
      }

      let pseudoElementRenderer = pseudoElement!.containerRenderer()
      if pseudoElementRenderer == nil {
        return
      }

      if styleChange == .Renderer {
        createContentRenderers(
          builder: updater.builder!, pseudoRenderer: pseudoElementRenderer!, style: updateStyle!,
          pseudoId: pseudoId)
      } else {
        updateStyleForContentRenderers(pseudoRenderer: pseudoElementRenderer!, style: updateStyle!)
      }

      if updater.renderView().hasQuotesNeedingUpdate() {
        for child: RenderQuoteWrapper in descendantsOfType(root: pseudoElementRenderer!) {
          updateQuotesUpTo(lastQuote: child)
        }
      }
      updater.builder!.updateAfterDescendants(renderer: pseudoElementRenderer!)
    }

    func updateWritingSuggestionsRenderer(
      renderer: RenderElementWrapper, minimalStyleDifference: StyleDifference
    ) {
      if !renderer.canHaveChildren() {
        return
      }

      if renderer.element() == nil {
        return
      }

      let editor = renderer.element()!.document().editor()
      let nodeBeforeWritingSuggestions = editor.nodeBeforeWritingSuggestions()
      if nodeBeforeWritingSuggestions == nil {
        return
      }

      if CPtrToInt(renderer.element()?.p)
        != CPtrToInt(nodeBeforeWritingSuggestions!.parentElement()?.p)
      {
        return
      }

      let writingSuggestionData = editor.writingSuggestionData()
      if writingSuggestionData == nil {
        destroyWritingSuggestionsIfNeeded(renderer: renderer)
        return
      }

      let style = renderer.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(
          pseudoId: .InternalWritingSuggestions), parentStyle: renderer.style())
      if style == nil || style!.display() == .None {
        destroyWritingSuggestionsIfNeeded(renderer: renderer)
        return
      }

      let nodeBeforeWritingSuggestionsTextRenderer =
        nodeBeforeWritingSuggestions!.renderer() as? RenderTextWrapper
      if nodeBeforeWritingSuggestionsTextRenderer == nil {
        destroyWritingSuggestionsIfNeeded(renderer: renderer)
        return
      }

      let parentForWritingSuggestions = nodeBeforeWritingSuggestionsTextRenderer!.parent()
      if parentForWritingSuggestions == nil {
        destroyWritingSuggestionsIfNeeded(renderer: renderer)
        return
      }

      let textWithoutSuggestion = nodeBeforeWritingSuggestionsTextRenderer!.text()

      let (prefix_, suffix) = GeneratedContent.prefixAndSuffixForWritingSuggestion(
        textWithoutSuggestion: textWithoutSuggestion, writingSuggestionData: writingSuggestionData!)

      nodeBeforeWritingSuggestionsTextRenderer!.setText(newContent: prefix_)

      let newStyle = RenderStyleWrapper.clone(style: style!)
      newStyle.setDisplay(value: .Inline)

      if let writingSuggestionsRenderer = editor.writingSuggestionRenderer() {
        writingSuggestionsRenderer.setStyle(
          style: newStyle, minimalStyleDifference: minimalStyleDifference)

        let writingSuggestionsText = writingSuggestionsRenderer.firstChild() as? RenderTextWrapper
        if writingSuggestionsText == nil {
          fatalError("Not reached")
        }

        writingSuggestionsText!.setText(newContent: writingSuggestionData!.content)

        if !suffix.isEmpty() {
          if let suffixText = writingSuggestionsRenderer.nextSibling() as? RenderTextWrapper {
            suffixText.setText(newContent: suffix)
          } else {
            fatalError("Not reached")
          }
        }
      } else {
        let newWritingSuggestionsRenderer = CreateRenderer.RenderInline(
          type: .Inline, document: renderer.document(), style: newStyle)
        newWritingSuggestionsRenderer.initializeStyle()

        let rendererAfterWritingSuggestions = nodeBeforeWritingSuggestionsTextRenderer!
          .nextSibling()

        let writingSuggestionsText = CreateRenderer.RenderText(
          type: .Text, document: renderer.document(), text: writingSuggestionData!.content)
        updater.builder!.attach(
          parent: newWritingSuggestionsRenderer, child: writingSuggestionsText)

        editor.setWritingSuggestionRenderer(renderer: newWritingSuggestionsRenderer)
        updater.builder!.attach(
          parent: parentForWritingSuggestions!, child: newWritingSuggestionsRenderer,
          beforeChild: rendererAfterWritingSuggestions)

        if parentForWritingSuggestions == nil {
          destroyWritingSuggestionsIfNeeded(renderer: renderer)
          return
        }

        let prefixNode = nodeBeforeWritingSuggestionsTextRenderer!.textNode()
        if prefixNode == nil {
          fatalError("Not reached")
        }

        if !suffix.isEmpty() {
          let suffixRenderer = CreateRenderer.RenderText(
            type: .Text, textNode: prefixNode!, text: suffix)
          updater.builder!.attach(
            parent: parentForWritingSuggestions!, child: suffixRenderer,
            beforeChild: rendererAfterWritingSuggestions)
        }
      }
    }

    private static func prefixAndSuffixForWritingSuggestion(
      textWithoutSuggestion: StringWrapper, writingSuggestionData: WritingSuggestionDataWrapper
    )
      -> (StringWrapper, StringWrapper)
    {
      if !writingSuggestionData.supportsSuffix() {
        return (textWithoutSuggestion, emptyString())
      }

      let offset = UInt32(writingSuggestionData.offset)
      return (
        textWithoutSuggestion.substring(position: 0, length: offset),
        textWithoutSuggestion.substring(position: offset)
      )
    }

    private func destroyWritingSuggestionsIfNeeded(renderer: RenderElementWrapper) {
      if renderer.element() == nil {
        return
      }

      let editor = renderer.element()!.document().editor()

      if let writingSuggestionsRenderer = editor.writingSuggestionRenderer() {
        updater.builder!.destroy(renderer: writingSuggestionsRenderer)
      }
    }

    static func removeBeforePseudoElement(element: ElementWrapper, builder: RenderTreeBuilder) {
      if let pseudoElement = element.beforePseudoElement() {
        RenderTreeUpdater.tearDownRenderers(
          root: pseudoElement, teardownType: .Full, builder: builder)
        element.clearBeforePseudoElement()
      }
    }

    static func removeAfterPseudoElement(element: ElementWrapper, builder: RenderTreeBuilder) {
      if let pseudoElement = element.afterPseudoElement() {
        RenderTreeUpdater.tearDownRenderers(
          root: pseudoElement, teardownType: .Full, builder: builder)
        element.clearAfterPseudoElement()
      }
    }

    private func updateQuotesUpTo(lastQuote: RenderQuoteWrapper?) {
      let quoteRenderers: RenderDescendantIteratorAdapter<RenderQuoteWrapper> = descendantsOfType(
        root: updater.renderView())
      let it =
        previousUpdatedQuote != nil
        ? ++quoteRenderers.at(current: previousUpdatedQuote!) : quoteRenderers.begin()
      while it != quoteRenderers.end() {
        let quote = *it
        // Quote character depends on quote depth so we chain the updates.
        quote.updateRenderer(builder: updater.builder!, previousQuote: previousUpdatedQuote)
        previousUpdatedQuote = quote
        if CPtrToInt(quote.id()) == CPtrToInt(lastQuote?.id()) {
          return
        }
        ++it
      }
      assert(lastQuote == nil || updater.builder!.hasBrokenContinuation)
    }

    private func needsPseudoElement(style: RenderStyleWrapper?) -> Bool {
      if style == nil {
        return false
      }
      if !updater.renderTreePosition().parent.canHaveGeneratedChildren() {
        return false
      }
      if !pseudoElementRendererIsNeeded(style: style) {
        return false
      }
      return true
    }

    private let updater: RenderTreeUpdater
    private var previousUpdatedQuote: RenderQuoteWrapper? = nil
  }
}
