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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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
