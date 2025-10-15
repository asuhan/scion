/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

private func styleForFirstLetter(firstLetterContainer: RenderElementWrapper) -> RenderStyleWrapper?
{
  let styleContainer =
    firstLetterContainer.isAnonymous()
    ? firstLetterContainer.firstNonAnonymousAncestor()! : firstLetterContainer
  let style = styleContainer.style().getCachedPseudoStyle(
    pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .FirstLetter))
  if style == nil {
    return nil
  }

  let firstLetterStyle = RenderStyleWrapper.clone(style: style!)

  // If we have an initial letter drop that is >= 1, then we need to force floating to be on.
  if firstLetterStyle.initialLetterDrop() >= 1 && !firstLetterStyle.isFloating() {
    firstLetterStyle.setFloating(v: firstLetterStyle.isLeftToRightDirection() ? .Left : .Right)
  }

  // We have to compute the correct font-size for the first-letter if it has an initial letter height set.
  let paragraph: RenderElementWrapper? =
    firstLetterContainer.isRenderBlockFlow()
    ? firstLetterContainer : firstLetterContainer.containingBlock()
  if firstLetterStyle.initialLetterHeight() >= 1
    && firstLetterStyle.metricsOfPrimaryFont().capHeight() != nil
    && paragraph!.style().metricsOfPrimaryFont().capHeight() != nil
  {
    // FIXME: For ideographic baselines, we want to go from line edge to line edge. This is equivalent to (N-1)*line-height + the font height.
    // We don't yet support ideographic baselines.
    // For an N-line first-letter and for alphabetic baselines, the cap-height of the first letter needs to equal (N-1)*line-height of paragraph lines + cap-height of the paragraph
    // Mathematically we can't rely on font-size, since font().height() doesn't necessarily match. For reliability, the best approach is simply to
    // compare the final measured cap-heights of the two fonts in order to get to the closest possible value.
    firstLetterStyle.setLineBoxContain(c: [.InitialLetter])
    let lineHeight = Int32(paragraph!.style().computedLineHeight())

    // Set the font to be one line too big and then ratchet back to get to a precise fit. We can't just set the desired font size based off font height metrics
    // because many fonts bake ascent into the font metrics. Therefore we have to look at actual measured cap height values in order to know when we have a good fit.
    let newFontDescription = firstLetterStyle.fontDescription()
    let capRatio =
      firstLetterStyle.metricsOfPrimaryFont().capHeight()! / firstLetterStyle.computedFontSize()
    let startingFontSize =
      Float32(
        (firstLetterStyle.initialLetterHeight() - 1) * lineHeight
          + Int32(paragraph!.style().metricsOfPrimaryFont().intCapHeight())) / capRatio
    newFontDescription.setSpecifiedSize(s: startingFontSize)
    newFontDescription.setComputedSize(s: startingFontSize)
    firstLetterStyle.setFontDescription(description: newFontDescription)
    firstLetterStyle.fontCascade().update(
      fontSelector: firstLetterStyle.fontCascade().fontSelector())

    let desiredCapHeight =
      (firstLetterStyle.initialLetterHeight() - 1) * lineHeight
      + Int32(paragraph!.style().metricsOfPrimaryFont().intCapHeight())
    var actualCapHeight = Int32(firstLetterStyle.metricsOfPrimaryFont().intCapHeight())
    while actualCapHeight > desiredCapHeight {
      let newFontDescription = firstLetterStyle.fontDescription()
      newFontDescription.setSpecifiedSize(s: newFontDescription.specifiedSize() - 1)
      newFontDescription.setComputedSize(s: newFontDescription.computedSize() - 1)
      firstLetterStyle.setFontDescription(description: newFontDescription)
      firstLetterStyle.fontCascade().update(
        fontSelector: firstLetterStyle.fontCascade().fontSelector())
      actualCapHeight = Int32(firstLetterStyle.metricsOfPrimaryFont().intCapHeight())
    }
  }

  firstLetterStyle.setPseudoElementType(pseudoElementType: .FirstLetter)
  // Force inline display (except for floating first-letters).
  firstLetterStyle.setDisplay(value: firstLetterStyle.isFloating() ? .Block : .Inline)
  // CSS2 says first-letter can't be positioned.
  firstLetterStyle.setPosition(v: .Static)

  return firstLetterStyle
}

// CSS 2.1 http://www.w3.org/TR/CSS21/selector.html#first-letter
// "Punctuation (i.e, characters defined in Unicode [UNICODE] in the "open" (Ps), "close" (Pe),
// "initial" (Pi). "final" (Pf) and "other" (Po) punctuation classes), that precedes or follows the first letter should be included"
private func isPunctuationForFirstLetter(c: UInt32) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func shouldSkipForFirstLetter(c: UInt32) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func supportsFirstLetter(block: RenderBlockWrapper) -> Bool {
  if block is RenderButtonWrapper {
    return true
  }
  if !(block is RenderBlockFlowWrapper) {
    return false
  }
  if block is RenderSVGTextWrapper {
    return false
  }
  return block.canHaveGeneratedChildren()
}

extension RenderTreeBuilder {
  class FirstLetter {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func updateAfterDescendants(block: RenderBlockWrapper) {
      if !block.style().hasPseudoStyle(pseudo: .FirstLetter) {
        return
      }
      if !supportsFirstLetter(block: block) {
        return
      }

      // FIXME: This should be refactored, firstLetterContainer is not needed.
      let renderObjects = block.getFirstLetter()
      let firstLetterRenderer = renderObjects.firstLetter
      let firstLetterContainer = renderObjects.firstLetterContainer

      if firstLetterRenderer == nil {
        return
      }

      // Other containers are handled when updating their renderers.
      if CPtrToInt(block.p) == CPtrToInt(firstLetterContainer?.p) {
        return
      }

      // If the child already has style, then it has already been created, so we just want
      // to update it.
      if firstLetterRenderer!.parent()!.style().pseudoElementType() == .FirstLetter {
        updateStyle(firstLetterBlock: block, currentChild: firstLetterRenderer!)
        return
      }

      if let renderText = firstLetterRenderer as? RenderTextWrapper {
        createRenderers(currentTextChild: renderText)
      }
    }

    private func updateStyle(
      firstLetterBlock: RenderBlockWrapper, currentChild: RenderObjectWrapper
    ) {
      let firstLetter = currentChild.parent()
      if firstLetter == nil || firstLetter!.parent() == nil {
        return
      }

      let firstLetterContainer = firstLetter!.parent()!

      let pseudoStyle = styleForFirstLetter(firstLetterContainer: firstLetterContainer)
      if pseudoStyle == nil {
        fatalError("Not reached")
      }

      assert(firstLetter!.isFloating() || firstLetter!.isInline())

      if Style.determineChange(s1: firstLetter!.style(), s2: pseudoStyle!) == .Renderer {
        // The first-letter renderer needs to be replaced. Create a new renderer of the right type.
        var newFirstLetter: RenderBoxModelObjectWrapper? = nil
        if pseudoStyle!.display() == .Inline {
          newFirstLetter = CreateRenderer.RenderInline(
            type: .Inline, document: firstLetterBlock.document(), style: pseudoStyle!)
        } else {
          newFirstLetter = CreateRenderer.RenderBlockFlow(
            type: .BlockFlow, document: firstLetterBlock.document(), style: pseudoStyle!)
        }
        newFirstLetter!.initializeStyle()
        newFirstLetter!.setIsFirstLetter()

        // Move the first letter into the new renderer.
        while let child = firstLetter!.firstChild() {
          if let textChild = child as? RenderTextWrapper {
            textChild.removeAndDestroyLegacyTextBoxes()
          }
          let toMove = builder.detach(parent: firstLetter!, child: child, willBeDestroyed: .No)
          builder.attach(parent: newFirstLetter!, child: toMove)
        }

        if let remainingText = (firstLetter as! RenderBoxModelObjectWrapper)
          .firstLetterRemainingText()
        {
          assert(
            remainingText.isAnonymous()
              || CPtrToInt(remainingText.textNode()!.renderer()?.p) == CPtrToInt(remainingText.p))
          // Replace the old renderer with the new one.
          remainingText.setFirstLetter(firstLetter: newFirstLetter!)
          newFirstLetter!.setFirstLetterRemainingText(remainingText: remainingText)
        }
        let nextSibling = firstLetter!.nextSibling()
        builder.destroy(renderer: firstLetter!)
        builder.attach(
          parent: firstLetterContainer, child: newFirstLetter, beforeChild: nextSibling)
        return
      }

      firstLetter!.setStyle(style: pseudoStyle!)
    }

    private func createRenderers(currentTextChild: RenderTextWrapper) {
      let textContentParent = currentTextChild.parent()
      var firstLetterContainer: RenderElementWrapper? = nil
      if let wrapperInlineForDisplayContents = currentTextChild.inlineWrapperForDisplayContents() {
        firstLetterContainer = wrapperInlineForDisplayContents.parent()
      } else {
        firstLetterContainer = textContentParent
      }
      if firstLetterContainer == nil {
        return
      }

      let pseudoStyle = styleForFirstLetter(firstLetterContainer: firstLetterContainer!)
      if pseudoStyle == nil {
        return
      }

      var newFirstLetter: RenderBoxModelObjectWrapper? = nil
      if pseudoStyle!.display() == .Inline {
        newFirstLetter = CreateRenderer.RenderInline(
          type: .Inline, document: currentTextChild.document(), style: pseudoStyle!)
      } else {
        newFirstLetter = CreateRenderer.RenderBlockFlow(
          type: .BlockFlow, document: currentTextChild.document(), style: pseudoStyle!)
      }
      newFirstLetter!.initializeStyle()
      newFirstLetter!.setIsFirstLetter()

      // The original string is going to be either a generated content string or a DOM node's
      // string. We want the original string before it got transformed in case first-letter has
      // no text-transform or a different text-transform applied to it.
      let oldText = currentTextChild.originalText()
      assert(!oldText.isNull())

      if !oldText.isEmpty() {
        var length: UInt32 = 0

        // Account for leading spaces and punctuation.
        while length < oldText.length()
          && shouldSkipForFirstLetter(c: oldText.characterStartingAt(i: length))
        {
          length += numCodeUnitsInGraphemeClusters(
            string: StringWrapperView(s: oldText).substring(start: length), numGraphemeClusters: 1)
        }

        // Account for first grapheme cluster.
        length += numCodeUnitsInGraphemeClusters(
          string: StringWrapperView(s: oldText).substring(start: length), numGraphemeClusters: 1)

        // Keep looking for whitespace and allowed punctuation, but avoid
        // accumulating just whitespace into the :first-letter.
        var numCodeUnits: UInt32 = 0
        var scanLength = length
        while scanLength < oldText.length() {
          let c = oldText.characterStartingAt(i: scanLength)

          if !shouldSkipForFirstLetter(c: c) {
            break
          }

          numCodeUnits = numCodeUnitsInGraphemeClusters(
            string: StringWrapperView(s: oldText).substring(start: scanLength),
            numGraphemeClusters: 1)

          if isPunctuationForFirstLetter(c: c) {
            length = scanLength + numCodeUnits
          }

          scanLength += numCodeUnits
        }

        let textNode = currentTextChild.textNode()
        let beforeChild = currentTextChild.nextSibling()
        let inlineWrapperForDisplayContents = currentTextChild.inlineWrapperForDisplayContents()
        builder.destroy(renderer: currentTextChild)

        // Construct a text fragment for the text after the first letter.
        // This text fragment might be empty.
        var newRemainingText: RenderTextFragmentWrapper? = nil
        if textNode != nil {
          newRemainingText = CreateRenderer.RenderTextFragment(
            textNode: textNode!, text: oldText, startOffset: Int32(length),
            length: Int32(oldText.length() - length))
          textNode!.setRenderer(renderer: newRemainingText)
        } else {
          newRemainingText = CreateRenderer.RenderTextFragment(
            document: builder.view.document(), text: oldText, startOffset: Int32(length),
            length: Int32(oldText.length() - length))
        }

        let remainingText = newRemainingText!
        remainingText.setInlineWrapperForDisplayContents(wrapper: inlineWrapperForDisplayContents)
        builder.attach(
          parent: textContentParent!, child: newRemainingText, beforeChild: beforeChild)

        // FIXME: Make attach the final step so that we don't need to keep firstLetter around.
        let firstLetter = newFirstLetter!
        remainingText.setFirstLetter(firstLetter: firstLetter)
        firstLetter.setFirstLetterRemainingText(remainingText: remainingText)
        builder.attach(
          parent: firstLetterContainer!, child: newFirstLetter, beforeChild: remainingText)

        // Construct text fragment for the first letter.
        let letter = CreateRenderer.RenderTextFragment(
          document: builder.view.document(), text: oldText, startOffset: 0, length: Int32(length))
        builder.attach(parent: firstLetter, child: letter)
      }
    }

    private let builder: RenderTreeBuilder
  }
}
