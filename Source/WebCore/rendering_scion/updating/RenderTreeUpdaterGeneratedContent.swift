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

private func elementIsTargetedByKeyframeEffectRequiringPseudoElement(
  element: ElementWrapper?, pseudoId: PseudoId
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func elementHasDisplayAnimationForPseudoId(element: ElementWrapper, pseudoId: PseudoId)
  -> Bool
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func updateWritingSuggestionsRenderer(
      renderer: RenderElementWrapper, minimalStyleDifference: StyleDifference
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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

    private func needsPseudoElement(style: RenderStyleWrapper?) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let updater: RenderTreeUpdater
  }
}
