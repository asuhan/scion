/*
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2015-2018 Google Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov.
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
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

struct EditingTextIterator {
  func atEnd() -> Bool {
    return positionNode == nil
  }

  func text() -> StringWrapperView {
    assert(!atEnd())
    return m_text
  }

  func copyableText() -> TextIteratorCopyableText {
    assert(!atEnd())
    return m_copyableText
  }

  func appendTextToStringBuilder(builder: StringBuilderWrapper) {
    copyableText().appendToStringBuilder(builder: builder)
  }

  func rendererTextForBehavior(renderer: RenderTextWrapper) -> StringWrapper {
    return behaviors.contains(.EmitsOriginalText) ? renderer.originalText() : renderer.text()
  }

  func protectedStartContainer() -> NodeWrapper? {
    return startContainer
  }

  init(range: SimpleRange, behaviors: TextIteratorBehavior = []) {
    self.behaviors = behaviors
    self.currentNode = nil
    self.fullyClippedStack = BitStack()
    self.startContainer = nil
    self.endContainer = nil
    self.pastEndNode = nil
    self.positionNode = nil
    self.positionOffsetBaseNode = nil
    self.m_copyableText = TextIteratorCopyableText()
    self.m_text = StringWrapperView()
    self.nodeForAdditionalNewline = nil
    self.textRun = InlineIterator.TextBoxIterator()
    self.textRunLogicalOrderCache = InlineIterator.TextLogicalOrderCache()
    self.remainingTextRun = InlineIterator.TextBoxIterator()
    self.remainingTextRunLogicalOrderCache = InlineIterator.TextLogicalOrderCache()
    self.firstLetterText = nil
    self.lastTextNode = nil
    assert(
      !self.behaviors.contains(.EmitsObjectReplacementCharacters)
        || !self.behaviors.contains(.EmitsObjectReplacementCharactersForImages))
    range.start.protectedDocument().updateLayoutIgnorePendingStylesheets()
    startContainer = range.start.container
    startOffset = Int32(range.start.offset)
    endContainer = range.end.container
    endOffset = Int32(range.end.offset)
    currentNode = firstNode(point: range.start)
    if currentNode == nil {
      return
    }
    initialize()
  }

  mutating func initialize() {
    let currentNode: NodeWrapper? = protectedCurrentNode()
    if isClippedByFrameAncestor(document: currentNode!.protectedDocument(), behaviors: behaviors) {
      return
    }
    setUpFullyClippedStack(stack: &fullyClippedStack, node: currentNode!)
    offset = CPtrToInt(currentNode?.p) == CPtrToInt(startContainer?.p) ? startOffset : 0
    pastEndNode = nextInPreOrderCrossingShadowBoundaries(
      rangeEndContainer: endContainer!, rangeEndOffset: endOffset)
    positionNode = currentNode
    advance()
  }

  mutating func advance() {
    assert(!atEnd())
    // reset the run information
    positionNode = nil
    m_copyableText.reset()
    m_text = StringWrapperView()
    // handle remembered node that needed a newline after the text node's newline
    if let nodeForAdditionalNewline = exchange(&nodeForAdditionalNewline, with: nil) {
      // Emit the extra newline, and position it *inside* m_node, after m_node's
      // contents, in case it's a block, in the same way that we position the first
      // newline. The range for the emitted newline should start where the line
      // break begins.
      // FIXME: It would be cleaner if we emitted two newlines during the last
      // iteration, instead of using m_needsAnotherNewline.
      let parentNode: ContainerNodeWrapper? = nodeForAdditionalNewline.protectedParentNode()
      emitCharacter(
        character: UInt16(10 /* '\n' */), characterNode: parentNode,
        offsetBaseNode: nodeForAdditionalNewline, textStartOffset: 1, textEndOffset: 1)
      return
    }
    if !textRun.bool() && remainingTextRun.bool() {
      revertToRemainingTextRun()
    }
    // handle remembered text box
    if textRun.bool() {
      handleTextRun()
      if positionNode != nil {
        return
      }
    }
    while currentNode != nil && CPtrToInt(currentNode?.p) != CPtrToInt(pastEndNode?.p) {
      // if the range ends at offset 0 of an element, represent the
      // position, but not the content, of that element e.g. if the
      // node is a blockflow element, emit a newline that
      // precedes the element
      if CPtrToInt(currentNode?.p) == CPtrToInt(endContainer?.p) && !(endOffset != 0) {
        representNodeOffsetZero()
        currentNode = nil
        return
      }
      let renderer: RenderObjectWrapper? = currentNode!.renderer()
      if !handledNode {
        if !isRendererVisible(renderer: renderer, behaviors: behaviors) {
          handledNode = true
          handledChildren = !(hasDisplayContents(node: protectedCurrentNode()!)) && renderer == nil
        } else if currentNode is ElementWrapper && renderer!.isSkippedContentRootForRenderObject() {
          handledChildren = true
        } else {
          // handle current node according to its type
          if renderer!.isRenderText() && currentNode!.isTextNode() {
            handledNode = handleTextNode()
          } else if isRendererReplacedElement(renderer: renderer, behaviors: behaviors) {
            handledNode = handleReplacedElement()
          } else {
            handledNode = handleNonTextNode()
          }
          if positionNode != nil {
            return
          }
        }
      }
      // find a new current node to handle in depth-first manner,
      // calling exitNode() as we come back thru a parent node
      var next: NodeWrapper? =
        handledChildren ? nil : firstChild(options: behaviors, node: protectedCurrentNode()!)
      offset = 0
      if next == nil {
        var currentNode: NodeWrapper? = protectedCurrentNode()
        next = nextSibling(options: behaviors, node: currentNode!)
        if next == nil {
          let pastEnd: Bool =
            CPtrToInt(nextNode(options: behaviors, node: currentNode!)?.p)
            == CPtrToInt(pastEndNode?.p)
          var parentNode: NodeWrapper? = parentNodeOrShadowHost(
            options: behaviors, node: currentNode!)
          while next == nil && parentNode != nil {
            if (pastEnd && CPtrToInt(parentNode?.p) == CPtrToInt(endContainer?.p))
              || isDescendantOf(
                options: behaviors, node: endContainer!, possibleAncestor: parentNode!)
            {
              return
            }
            let haveRenderer: Bool = isRendererVisible(
              renderer: currentNode!.renderer(), behaviors: behaviors)
            let exitedNode: NodeWrapper? = currentNode
            self.currentNode = parentNode
            currentNode = self.currentNode
            fullyClippedStack.pop()
            parentNode = parentNodeOrShadowHost(options: behaviors, node: currentNode!)
            if haveRenderer {
              exitNode(exitedNode: exitedNode)
            }
            if positionNode != nil {
              handledNode = true
              handledChildren = true
              return
            }
            next = nextSibling(options: behaviors, node: currentNode!)
            if next != nil
              && isRendererVisible(renderer: currentNode!.renderer(), behaviors: behaviors)
            {
              exitNode(exitedNode: currentNode)
            }
          }
        }
        fullyClippedStack.pop()
      }
      // set the new current node
      self.currentNode = next
      if let currentNode = protectedCurrentNode() {
        pushFullyClippedState(stack: &fullyClippedStack, node: currentNode)
      }
      handledNode = false
      handledChildren = false
      handledFirstLetter = false
      firstLetterText = nil
      // how would this ever be?
      if positionNode != nil {
        return
      }
    }
  }

  mutating func handleTextNode() -> Bool {
    let textNode = protectedCurrentNode() as! TextWrapper
    if fullyClippedStack.top() && !behaviors.contains(.IgnoresStyleVisibility) {
      return false
    }
    let renderer = textNode.renderer()!
    lastTextNode = textNode
    let rendererText = rendererTextForBehavior(renderer: renderer)
    // handle pre-formatted text
    if !(renderer.style().collapseWhiteSpace()) {
      let runStart: Int32 = offset
      if lastTextNodeEndedWithCollapsedSpace && hasVisibleTextNode(renderer: renderer) {
        emitCharacter(
          character: UInt16(32 /* ' ' */), characterNode: textNode, offsetBaseNode: nil,
          textStartOffset: runStart, textEndOffset: runStart)
        return false
      }
      let renderTextFragment: RenderTextFragmentWrapper? = renderer as? RenderTextFragmentWrapper
      if renderTextFragment != nil && !handledFirstLetter && !(offset != 0) {
        handleTextNodeFirstLetter(renderer: renderTextFragment!)
        if firstLetterText != nil {
          let firstLetter = firstLetterText!.text()
          emitText(
            textNode: textNode, renderer: firstLetterText!, textStartOffset: offset,
            textEndOffset: Int32(UInt32(offset) + firstLetter.length()))
          firstLetterText = nil
          textRun = InlineIterator.TextBoxIterator()
          return false
        }
      }
      if renderer.style().visibility() != .Visible && !behaviors.contains(.IgnoresStyleVisibility) {
        return false
      }
      let rendererTextLength: Int32 = Int32(rendererText.length())
      let end: Int32 =
        (CPtrToInt(textNode.p) == CPtrToInt(endContainer?.p)) ? endOffset : 2_147_483_647
      let runEnd: Int32 = min(rendererTextLength, end)
      if runStart >= runEnd {
        return true
      }
      emitText(
        textNode: textNode, renderer: renderer, textStartOffset: runStart, textEndOffset: runEnd)
      return true
    }
    (textRun, textRunLogicalOrderCache) = InlineIterator.firstTextBoxInLogicalOrderFor(renderer)
    let renderTextFragment: RenderTextFragmentWrapper? = renderer as? RenderTextFragmentWrapper
    if renderTextFragment != nil && !handledFirstLetter && !(offset != 0) {
      handleTextNodeFirstLetter(renderer: renderTextFragment!)
    } else if !textRun.bool() && rendererText.length() != 0 {
      if renderer.style().visibility() != .Visible && !behaviors.contains(.IgnoresStyleVisibility) {
        return false
      }
      lastTextNodeEndedWithCollapsedSpace = true
      // entire block is collapsed space
      return true
      // entire block is collapsed space
    }
    handleTextRun()
    return true
  }

  mutating func handleTextRun() {
    let textNode = protectedCurrentNode() as! TextWrapper
    let renderer = firstLetterText != nil ? firstLetterText! : textNode.renderer()!
    if renderer.style().visibility() != .Visible && !behaviors.contains(.IgnoresStyleVisibility) {
      textRun = InlineIterator.TextBoxIterator()
      return
    }
    let (firstTextRun, _) = InlineIterator.firstTextBoxInLogicalOrderFor(renderer)
    let rendererText = rendererTextForBehavior(renderer: renderer)
    let rangeStart: UInt32 = UInt32(offset)
    var rangeEnd: UInt32? = nil
    if CPtrToInt(textNode.p) == CPtrToInt(endContainer?.p) {
      rangeEnd = UInt32(endOffset)
    }
    while textRun.bool() {
      let textRunStart: UInt32 = textRun.get().start()
      let textRunEnd: UInt32 = textRunStart + textRun.get().length()
      let runStart: UInt32 = max(textRunStart, rangeStart)
      let runEnd: UInt32 = min(textRunEnd, (rangeEnd ?? textRunEnd))
      // Check if we need to emit (previously) collapsed whitespace at the start of this run.
      let isAfterRangeEnd: Bool = rangeEnd != nil ? runStart > rangeEnd! : false
      let hasPrecedingCollapsedWhitespace: Bool =
        lastTextNodeEndedWithCollapsedSpace
        || (textRun == firstTextRun && textRunStart == runStart && runStart != 0)
      let shouldEmitWhitespace: Bool =
        !isAfterRangeEnd && hasPrecedingCollapsedWhitespace && lastCharacter != 0
        && !(renderer.style().isCollapsibleWhiteSpace(lastCharacter))
      if shouldEmitWhitespace {
        if CPtrToInt(lastTextNode?.p) == CPtrToInt(textNode.p) && runStart != 0
          && renderer.style().isCollapsibleWhiteSpace(rendererText[runStart - 1])
        {
          var spaceRunStart: UInt32 = runStart - 1
          while spaceRunStart != 0
            && renderer.style().isCollapsibleWhiteSpace(rendererText[spaceRunStart - 1])
          {
            spaceRunStart -= 1
          }
          emitCharacter(
            character: UInt16(32 /* ' ' */), characterNode: textNode, offsetBaseNode: nil,
            textStartOffset: Int32(spaceRunStart), textEndOffset: Int32(spaceRunStart + 1))
        } else {
          emitCharacter(
            character: UInt16(32 /* ' ' */), characterNode: textNode, offsetBaseNode: nil,
            textStartOffset: Int32(runStart), textEndOffset: Int32(runStart))
        }
        return
      }
      // Determine what the next text run will be, but don't advance yet
      let nextTextRun = InlineIterator.nextTextBoxInLogicalOrder(textRun, textRunLogicalOrderCache)
      if runStart < runEnd {
        let isNewlineOrTab = { (character: UInt16) -> Bool in
          return Int32(character) == Int32(10 /* '\n' */)
            || Int32(character) == Int32(9 /* '\t' */)
        }
        // Handle either a single newline or tab character (which becomes a space),
        // or a run of characters that does not include newlines or tabs.
        // This effectively translates newlines and tabs to spaces without copying the text.
        if isNewlineOrTab(rendererText[runStart]) {
          emitCharacter(
            character: UInt16(32 /* ' ' */), characterNode: textNode, offsetBaseNode: nil,
            textStartOffset: Int32(runStart), textEndOffset: Int32(runStart + 1))
          offset = Int32(runStart + 1)
        } else {
          var subrunEnd: UInt32 = runStart + 1
          while subrunEnd < runEnd {
            if isNewlineOrTab(rendererText[subrunEnd]) {
              break
            }
            subrunEnd += 1
          }
          if subrunEnd == runEnd && behaviors.contains(.BehavesAsIfNodesFollowing) {
            let lastSpaceCollapsedByNextNonTextRun: Bool =
              !nextTextRun.bool() && rendererText.length() > subrunEnd
              && Int32(rendererText[subrunEnd]) == Int32(32 /* ' ' */)
            if lastSpaceCollapsedByNextNonTextRun {
              subrunEnd += 1
            }
            // runEnd stopped before last space. Increment by one to restore the space.
          }
          offset = Int32(subrunEnd)
          emitText(
            textNode: textNode, renderer: renderer, textStartOffset: Int32(runStart),
            textEndOffset: Int32(subrunEnd))
        }
        // If we are doing a subrun that doesn't go to the end of the text box,
        // come back again to finish handling this text box; don't advance to the next one.
        if UInt32(UInt32(positionEndOffset)) < textRunEnd {
          return
        }
        // Advance and return
        let nextRunStart: UInt32 =
          nextTextRun.bool() ? nextTextRun.get().start() : rendererText.length()
        if nextRunStart > runEnd {
          lastTextNodeEndedWithCollapsedSpace = true
        }
        // collapsed space between runs or at the end
        textRun = nextTextRun
        return
      }
      // Advance and continue
      textRun = nextTextRun
    }
    if !textRun.bool() && remainingTextRun.bool() {
      revertToRemainingTextRun()
      handleTextRun()
    }
  }

  mutating func revertToRemainingTextRun() {
    assert(!textRun.bool() && remainingTextRun.bool())
    textRun = remainingTextRun
    textRunLogicalOrderCache = exchange(
      &remainingTextRunLogicalOrderCache, with: InlineIterator.TextLogicalOrderCache())
    remainingTextRun = InlineIterator.TextBoxIterator()
    firstLetterText = nil
    offset = 0
  }

  mutating func handleTextNodeFirstLetter(renderer: RenderTextFragmentWrapper) {
    if let firstLetter = renderer.firstLetter() {
      if firstLetter.style().visibility() != .Visible
        && !behaviors.contains(.IgnoresStyleVisibility)
      {
        return
      }
      if let firstLetterText = firstRenderTextInFirstLetter(firstLetter: firstLetter) {
        handledFirstLetter = true
        remainingTextRun = textRun
        remainingTextRunLogicalOrderCache = exchange(
          &textRunLogicalOrderCache, with: InlineIterator.TextLogicalOrderCache())
        (textRun, textRunLogicalOrderCache) = InlineIterator.firstTextBoxInLogicalOrderFor(
          firstLetterText)
        self.firstLetterText = firstLetterText
      }
    }
    handledFirstLetter = true
  }

  mutating func handleReplacedElement() -> Bool {
    fatalError("Not implemented")
  }

  mutating func shouldRepresentNodeOffsetZero() -> Bool {
    if behaviors.contains(.EmitsCharactersBetweenAllVisiblePositions) {
      if let renderer: RenderObjectWrapper = currentNode!.renderer(), renderer.isRenderTable() {
        return true
      }
    }
    // Leave element positioned flush with start of a paragraph
    // (e.g. do not insert tab before a table cell at the start of a paragraph)
    if Int32(lastCharacter) == Int32(10 /* '\n' */) {
      return false
    }
    // Otherwise, show the position if we have emitted any characters
    if hasEmitted {
      return true
    }
    // We've not emitted anything yet. Generally, there is no need for any positioning then.
    // The only exception is when the element is visually not in the same line as
    // the start of the range (e.g. the range starts at the end of the previous paragraph).
    // NOTE: Creating VisiblePositions and comparing them is relatively expensive, so we
    // make quicker checks to possibly avoid that. Another check that we could make is
    // is whether the inline vs block flow changed since the previous visible element.
    // I think we're already in a special enough case that that won't be needed, tho.
    // No character needed if this is the first node in the range.
    if CPtrToInt(currentNode?.p) == CPtrToInt(startContainer?.p) {
      return false
    }
    // If we are outside the start container's subtree, assume we need to emit.
    // FIXME: m_startContainer could be an inline block
    let currentNode = self.currentNode!
    if !currentNode.isDescendantOf(startContainer) {
      return true
    }
    // If we started as m_startContainer offset 0 and the current node is a descendant of
    // the start container, we already had enough context to correctly decide whether to
    // emit after a preceding block. We chose not to emit (m_hasEmitted is false),
    // so don't second guess that now.
    // NOTE: Is this really correct when m_currentNode is not a leftmost descendant? Probably
    // immaterial since we likely would have already emitted something by now.
    if startOffset == 0 {
      return false
    }
    // If this node is unrendered or invisible the VisiblePosition checks below won't have much meaning.
    // Additionally, if the range we are iterating over contains huge sections of unrendered content,
    // we would create VisiblePositions on every call to this function without this check.
    if currentNode.renderer() == nil || currentNode.renderer()!.style().visibility() != .Visible {
      return false
    }
    if let renderBlockFlow = currentNode.renderer()! as? RenderBlockFlowWrapper {
      if !renderBlockFlow.height().bool() && !(currentNode is HTMLBodyElement) {
        return false
      }
    }
    // The startPos.isNotNull() check is needed because the start could be before the body,
    // and in that case we'll get null. We don't want to put in newlines at the start in that case.
    // The currPos.isNotNull() check is needed because positions in non-HTML content
    // (like SVG) do not have visible positions, and we don't want to emit for them either.
    let startPos = VisiblePosition(
      Position(
        anchorNode: protectedStartContainer(), offset: UInt32(startOffset),
        anchorType: .PositionIsOffsetInAnchor))
    let currPos = VisiblePosition(positionBeforeNode(anchorNode: currentNode))
    return startPos.isNotNull() && currPos.isNotNull() && !inSameLine(a: startPos, b: currPos)
  }

  mutating func shouldEmitSpaceBeforeAndAfterNode(node: NodeWrapper) -> Bool {
    return node.renderer() != nil && node.renderer()!.isRenderTable()
      && (node.renderer()!.isInline()
        || behaviors.contains(.EmitsCharactersBetweenAllVisiblePositions))
  }

  mutating func representNodeOffsetZero() {
    // Emit a character to show the positioning of m_currentNode.
    // When we haven't been emitting any characters, shouldRepresentNodeOffsetZero() can
    // create VisiblePositions, which is expensive. So, we perform the inexpensive checks
    // on m_currentNode to see if it necessitates emitting a character first and will early return
    // before encountering shouldRepresentNodeOffsetZero()s worse case behavior.
    let currentNode: NodeWrapper? = protectedCurrentNode()
    if shouldEmitTabBeforeNode(node: currentNode!) {
      if shouldRepresentNodeOffsetZero() {
        let parentNode: ContainerNodeWrapper? = currentNode!.protectedParentNode()
        emitCharacter(
          character: UInt16(9 /* '\t' */), characterNode: parentNode, offsetBaseNode: currentNode,
          textStartOffset: 0, textEndOffset: 0)
      }
    } else if shouldEmitNewlineBeforeNode(node: currentNode!) {
      if shouldRepresentNodeOffsetZero() {
        let parentNode: ContainerNodeWrapper? = currentNode!.protectedParentNode()
        emitCharacter(
          character: UInt16(10 /* '\n' */), characterNode: parentNode, offsetBaseNode: currentNode,
          textStartOffset: 0, textEndOffset: 0)
      }
    } else if shouldEmitSpaceBeforeAndAfterNode(node: currentNode!) {
      if shouldRepresentNodeOffsetZero() {
        let parentNode: ContainerNodeWrapper? = currentNode!.protectedParentNode()
        emitCharacter(
          character: UInt16(32 /* ' ' */), characterNode: parentNode, offsetBaseNode: currentNode,
          textStartOffset: 0, textEndOffset: 0)
      }
    } else if shouldEmitReplacementInsteadOfNode(node: currentNode!) {
      if shouldRepresentNodeOffsetZero() {
        let parentNode: ContainerNodeWrapper? = currentNode!.protectedParentNode()
        emitCharacter(
          character: objectReplacementCharacter, characterNode: parentNode,
          offsetBaseNode: currentNode, textStartOffset: 0, textEndOffset: 0)
      }
    }
  }

  mutating func handleNonTextNode() -> Bool {
    let currentNode: NodeWrapper? = protectedCurrentNode()
    if shouldEmitNewlineForNode(
      node: currentNode, emitsOriginalText: behaviors.contains(.EmitsOriginalText))
    {
      let parentNode: ContainerNodeWrapper? = currentNode!.protectedParentNode()
      emitCharacter(
        character: UInt16(10 /* '\n' */), characterNode: parentNode, offsetBaseNode: currentNode,
        textStartOffset: 0, textEndOffset: 1)
    } else if behaviors.contains(.EmitsCharactersBetweenAllVisiblePositions)
      && currentNode!.renderer() != nil && currentNode!.renderer()!.isHR()
    {
      let parentNode: ContainerNodeWrapper? = currentNode!.protectedParentNode()
      emitCharacter(
        character: UInt16(32 /* ' ' */), characterNode: parentNode, offsetBaseNode: currentNode,
        textStartOffset: 0, textEndOffset: 1)
    } else {
      representNodeOffsetZero()
    }
    return true
  }

  mutating func exitNode(exitedNode: NodeWrapper?) {
    // prevent emitting a newline when exiting a collapsed block at beginning of the range
    // FIXME: !m_hasEmitted does not necessarily mean there was a collapsed block... it could
    // have been an hr (e.g.). Also, a collapsed block could have height (e.g. a table) and
    // therefore look like a blank line.
    if !hasEmitted {
      return
    }
    // Emit with a position *inside* m_currentNode, after m_currentNode's contents, in
    // case it is a block, because the run should start where the
    // emitted character is positioned visually.
    let baseNode: NodeWrapper? = exitedNode
    // FIXME: This shouldn't require the m_lastTextNode to be true, but we can't change that without making
    // the logic in _web_attributedStringFromRange match. We'll get that for free when we switch to use
    // TextIterator in _web_attributedStringFromRange.
    // See <rdar://problem/5428427> for an example of how this mismatch will cause problems.
    if lastTextNode != nil
      && shouldEmitNewlineAfterNode(
        node: protectedCurrentNode()!,
        emitsCharactersBetweenAllVisiblePositions: behaviors.contains(
          .EmitsCharactersBetweenAllVisiblePositions))
    {
      // use extra newline to represent margin bottom, as needed
      let addNewline: Bool = shouldEmitExtraNewlineForNode(node: protectedCurrentNode()!)
      // FIXME: We need to emit a '\n' as we leave an empty block(s) that
      // contain a VisiblePosition when doing selection preservation.
      if Int32(lastCharacter) != Int32(10 /* '\n' */) {
        // insert a newline with a position following this block's contents.
        emitCharacter(
          character: UInt16(10 /* '\n' */), characterNode: baseNode!.protectedParentNode(),
          offsetBaseNode: baseNode, textStartOffset: 1, textEndOffset: 1)
        // remember whether to later add a newline for the current node
        assert(nodeForAdditionalNewline == nil)
        if addNewline {
          nodeForAdditionalNewline = baseNode
        }
      } else if addNewline {
        emitCharacter(
          character: UInt16(10 /* '\n' */), characterNode: baseNode!.protectedParentNode(),
          offsetBaseNode: baseNode, textStartOffset: 1, textEndOffset: 1)
      }
    }
    // If nothing was emitted, see if we need to emit a space.
    if positionNode == nil && shouldEmitSpaceBeforeAndAfterNode(node: protectedCurrentNode()!) {
      let parentNode: ContainerNodeWrapper? = baseNode!.protectedParentNode()
      emitCharacter(
        character: UInt16(32 /* ' ' */), characterNode: parentNode, offsetBaseNode: baseNode,
        textStartOffset: 1, textEndOffset: 1)
    }
  }

  mutating func emitCharacter(
    character: UInt16, characterNode: NodeWrapper?, offsetBaseNode: NodeWrapper?,
    textStartOffset: Int32, textEndOffset: Int32
  ) {
    assert(characterNode != nil)
    hasEmitted = true
    // remember information with which to construct the TextIterator::range()
    positionNode = characterNode
    positionOffsetBaseNode = offsetBaseNode
    positionStartOffset = textStartOffset
    positionEndOffset = textEndOffset
    m_copyableText.set(singleCharacter: character)
    m_text = m_copyableText.text()
    lastCharacter = character
    lastTextNodeEndedWithCollapsedSpace = false
  }

  mutating func emitText(
    textNode: TextWrapper, renderer: RenderTextWrapper, textStartOffset: Int32, textEndOffset: Int32
  ) {
    var textEndOffset = textEndOffset
    assert(textStartOffset >= 0)
    assert(textEndOffset >= 0)
    assert(textStartOffset <= textEndOffset)
    let shouldIgnoreFullSizeKana: Bool =
      behaviors.contains(.IgnoresFullSizeKana)
      && renderer.style().textTransform().contains(.FullSizeKana)
    // FIXME: This probably yields the wrong offsets when text-transform: lowercase turns a single character into two characters.
    let string =
      behaviors.contains(.EmitsOriginalText) || shouldIgnoreFullSizeKana
      ? renderer.originalText()
      : (behaviors.contains(.EmitsTextsWithoutTranscoding)
        ? renderer.textWithoutConvertingBackslashToYenSymbol() : renderer.text())
    assert(
      behaviors.contains(.EmitsOriginalText) || string.length() >= UInt32(UInt32(textEndOffset)))
    textEndOffset = Int32(min(string.length(), UInt32(UInt32(textEndOffset))))
    positionNode = textNode
    positionOffsetBaseNode = nil
    positionStartOffset = textStartOffset
    positionEndOffset = textEndOffset
    lastCharacter = string[UInt32(textEndOffset - 1)]
    m_copyableText.set(
      string: string, offset: UInt32(textStartOffset),
      length: UInt32(textEndOffset - textStartOffset))
    m_text = m_copyableText.text()
    lastTextNodeEndedWithCollapsedSpace = false
    hasEmitted = true
  }

  mutating func range() -> SimpleRange {
    assert(!atEnd())
    // Use the current run information, if we have it.
    if positionOffsetBaseNode != nil {
      let index: UInt32 = positionOffsetBaseNode!.computeNodeIndex()
      positionStartOffset += Int32(index)
      positionEndOffset += Int32(index)
      positionOffsetBaseNode = nil
    }
    return SimpleRange(
      start: BoundaryPoint(container: positionNode!, offset: UInt32(UInt32(positionStartOffset))),
      end: BoundaryPoint(container: positionNode!, offset: UInt32(UInt32(positionEndOffset))))
  }

  mutating func node() -> NodeWrapper? {
    let start = range().start
    if start.container.isCharacterDataNode() {
      return start.container
    }
    return start.container.traverseToChildAt(start.offset)
  }

  func protectedCurrentNode() -> NodeWrapper? {
    return currentNode
  }

  private var behaviors: TextIteratorBehaviors
  private var currentNode: NodeWrapper? = nil
  private var offset: Int32 = 0
  private var handledNode: Bool = false
  private var handledChildren: Bool = false
  private var fullyClippedStack: BitStack
  private var startContainer: NodeWrapper? = nil
  private var startOffset: Int32 = 0
  private var endContainer: NodeWrapper? = nil
  private var endOffset: Int32 = 0
  private var pastEndNode: NodeWrapper? = nil
  private var positionNode: NodeWrapper? = nil
  private var positionOffsetBaseNode: NodeWrapper? = nil
  private var positionStartOffset: Int32 = 0
  private var positionEndOffset: Int32 = 0
  private var m_copyableText: TextIteratorCopyableText
  private var m_text: StringWrapperView
  private var nodeForAdditionalNewline: NodeWrapper? = nil
  private var textRun: InlineIterator.TextBoxIterator
  private var textRunLogicalOrderCache: InlineIterator.TextLogicalOrderCache
  private var remainingTextRun: InlineIterator.TextBoxIterator
  private var remainingTextRunLogicalOrderCache: InlineIterator.TextLogicalOrderCache
  private var firstLetterText: RenderTextWrapper? = nil
  private var lastTextNode: TextWrapper? = nil
  private var lastTextNodeEndedWithCollapsedSpace: Bool = false
  private var lastCharacter: UInt16 = 0
  private var hasEmitted: Bool = false
  private var handledFirstLetter: Bool = false
}

let bitsInWord: UInt32 = UInt32(MemoryLayout<UInt32>.size * 8)

let bitInWordMask: UInt32 = bitsInWord - 1

func nextInPreOrderCrossingShadowBoundaries(rangeEndContainer: NodeWrapper, rangeEndOffset: Int32)
  -> NodeWrapper?
{
  if rangeEndOffset >= 0 && !rangeEndContainer.isCharacterDataNode() {
    if let next = rangeEndContainer.traverseToChildAt(UInt32(rangeEndOffset)) {
      return next
    }
  }
  var node: NodeWrapper? = rangeEndContainer
  while node != nil {
    if let next = node!.nextSibling() {
      return next
    }
    node = node!.parentOrShadowHostNode()
  }
  return nil
}

func fullyClipsContents(node: NodeWrapper) -> Bool {
  let renderer: RenderObjectWrapper? = node.renderer()
  if renderer == nil {
    let element: ElementWrapper? = node as? ElementWrapper
    return element != nil && !element!.hasDisplayContents()
  }
  let box: RenderBoxWrapper? = renderer! as? RenderBoxWrapper
  if box == nil || !box!.hasNonVisibleOverflow() {
    return false
  }
  // Quirk to keep copy/paste in the CodeMirror editor version used in Jenkins working.
  if node is HTMLTextAreaElementWrapper {
    return box!.size().isEmpty()
  }
  return box!.contentSize().isEmpty()
}

func ignoresContainerClip(node: NodeWrapper) -> Bool {
  let renderer: RenderObjectWrapper? = node.renderer()
  if renderer == nil || renderer!.isRenderTextOrLineBreak() {
    return false
  }
  return renderer!.style().hasOutOfFlowPosition()
}

func pushFullyClippedState(stack: inout BitStack, node: NodeWrapper) {
  // Push true if this node full clips its contents, or if a parent already has fully
  // clipped and this is not a node that ignores its container's clip.
  stack.push(
    bit: fullyClipsContents(node: node) || (stack.top() && !ignoresContainerClip(node: node)))
}

func setUpFullyClippedStack(stack: inout BitStack, node: NodeWrapper) {
  // Put the nodes in a vector so we can iterate in reverse order.
  // FIXME: This (and TextIterator in general) should use ComposedTreeIterator.
  var ancestry = [NodeWrapper]()
  var parent: ContainerNodeWrapper? = node.parentOrShadowHostNode()
  while parent != nil {
    ancestry.append(parent!)
    parent = parent!.parentOrShadowHostNode()
  }
  // Call pushFullyClippedState on each node starting with the earliest ancestor.
  let size: UInt64 = UInt64(ancestry.count)
  var i: UInt64 = 0
  while i < size {
    pushFullyClippedState(stack: &stack, node: ancestry[Int(size - i - 1)])
    i += 1
  }
  pushFullyClippedState(stack: &stack, node: node)
}

func isClippedByFrameAncestor(document: Document, behaviors: TextIteratorBehavior) -> Bool {
  if !behaviors.contains(.ClipsToFrameAncestors) {
    return false
  }
  var owner: HTMLFrameOwnerElementWrapper? = document.ownerElement()
  while owner != nil {
    var ownerClipStack = BitStack()
    setUpFullyClippedStack(stack: &ownerClipStack, node: owner!)
    if ownerClipStack.top() {
      return true
    }
    owner = owner!.document().ownerElement()
  }
  return false
}

func isRendererReplacedElement(renderer: RenderObjectWrapper?, behaviors: TextIteratorBehavior = [])
  -> Bool
{
  if renderer == nil {
    return false
  }
  let isAttachment: Bool = false
  if renderer!.isImage() || renderer!.isRenderWidget() || renderer!.isRenderMedia() || isAttachment
  {
    return true
  }
  if let element = renderer!.node() as? ElementWrapper {
    if element is HTMLFormControlElementWrapper || element is HTMLLegendElementWrapper
      || element is HTMLProgressElementWrapper || element.hasMeterTagName()
    {
      return true
    }
    if equalLettersIgnoringASCIICase(
      element.roleAttributeWithoutSynchronization(), ASCIILiteral("img"))
    {
      return true
    }
    // Links are also replaced with object replacement character in ATSPI.
    if behaviors.contains(.EmitsObjectReplacementCharacters) && element.isLink() {
      return true
    }
  }
  return false
}

func firstNode(point: BoundaryPoint) -> NodeWrapper? {
  if point.container.isCharacterDataNode() {
    return point.container
  }
  if let child = point.container.traverseToChildAt(point.offset) {
    return child
  }
  if !(point.offset != 0) {
    return point.container
  }
  return nextSkippingChildren(point.container)
}

func findIteratorOptions(options: FindOption = []) -> TextIteratorBehaviors {
  var iteratorOptions: TextIteratorBehaviors = [
    .EntersTextControls, .ClipsToFrameAncestors, .EntersImageOverlays,
  ]
  if !options.contains(.DoNotTraverseFlatTree) {
    iteratorOptions.insert([.TraversesFlatTree])
  }
  return iteratorOptions
}

func characterRange(start: BoundaryPoint, range: SimpleRange, behaviors: TextIteratorBehavior = [])
  -> CharacterRange
{
  return CharacterRange(
    location: characterCount(
      range: SimpleRange(start: start, end: range.start), behaviors: behaviors),
    length: characterCount(range: range, behaviors: behaviors))
}

func firstChild(options: TextIteratorBehavior, node: NodeWrapper) -> NodeWrapper? {
  if options.contains(.TraversesFlatTree) {
    return firstChildInComposedTreeIgnoringUserAgentShadow(node)
  }
  return node.firstChild()
}

func characterRange(scope: SimpleRange, range: SimpleRange, behaviors: TextIteratorBehavior = [])
  -> CharacterRange
{
  return characterRange(start: scope.start, range: range, behaviors: behaviors)
}

func nextSibling(options: TextIteratorBehavior, node: NodeWrapper) -> NodeWrapper? {
  if options.contains(.TraversesFlatTree) {
    return nextSiblingInComposedTreeIgnoringUserAgentShadow(node)
  }
  return node.nextSibling()
}

func resolveCharacterLocation(
  scope: SimpleRange, location: UInt64, behaviors: TextIteratorBehavior = []
) -> BoundaryPoint {
  return resolveCharacterRange(
    scope: scope, range: CharacterRange(location: location, length: 0), behaviors: behaviors
  ).start
}

func nextNode(options: TextIteratorBehavior, node: NodeWrapper) -> NodeWrapper? {
  if options.contains(.TraversesFlatTree) {
    return nextInComposedTreeIgnoringUserAgentShadow(node)
  }
  return next(node)
}

func isDescendantOf(options: TextIteratorBehavior, node: NodeWrapper, possibleAncestor: NodeWrapper)
  -> Bool
{
  if options.contains(.TraversesFlatTree) {
    return node.isDescendantOrShadowDescendantOf(possibleAncestor)
  }
  return node.isDescendantOf(possibleAncestor)
}

func parentNodeOrShadowHost(options: TextIteratorBehavior, node: NodeWrapper) -> NodeWrapper? {
  if options.contains(.TraversesFlatTree) {
    return node.parentInComposedTree()
  }
  return node.parentOrShadowHostNode()
}

func hasDisplayContents(node: NodeWrapper) -> Bool {
  let element: ElementWrapper? = node as? ElementWrapper
  return element != nil && element!.hasDisplayContents()
}

func isRendererVisible(renderer: RenderObjectWrapper?, behaviors: TextIteratorBehavior) -> Bool {
  return renderer != nil
    && !((renderer!.style().usedUserSelect() == .None && behaviors.contains(.IgnoresUserSelectNone)))
}

func hasVisibleTextNode(renderer: RenderTextWrapper) -> Bool {
  if renderer.style().visibility() == .Visible {
    return true
  }
  if let renderTextFragment = renderer as? RenderTextFragmentWrapper {
    if let firstLetter = renderTextFragment.firstLetter() {
      if firstLetter.style().visibility() == .Visible {
        return true
      }
    }
  }
  return false
}

func firstRenderTextInFirstLetter(firstLetter: RenderBoxModelObjectWrapper?) -> RenderTextWrapper? {
  if firstLetter == nil {
    return nil
  }
  // FIXME: Should this check descendent objects?
  return childrenOfType(parent: firstLetter!).first()
  // FIXME: Should this check descendent objects?
}

func shouldEmitTabBeforeNode(node: NodeWrapper) -> Bool {
  let cell: RenderTableCellWrapper? = node.renderer() as? RenderTableCellWrapper
  // Table cells are delimited by tabs.
  if cell == nil {
    return false
  }
  // Want a tab before every cell other than the first one.
  let table: RenderTableWrapper? = cell!.table()
  return table != nil
    && (table!.cellBefore(cell: cell!) != nil || table!.cellAbove(cell: cell!) != nil)
}

func shouldEmitNewlineForNode(node: NodeWrapper?, emitsOriginalText: Bool) -> Bool {
  let renderer: RenderObjectWrapper? = node!.renderer()
  if !((renderer != nil ? renderer!.isBRForRenderObject() : node!.hasBrTagName())) {
    return false
  }
  return emitsOriginalText
    || !((node!.isInShadowTree() && node!.shadowHost()! is HTMLInputElementWrapper))
}

func hasHeaderTag(element: HTMLElementWrapper) -> Bool {
  return element.hasH1TagName() || element.hasH2TagName() || element.hasH3TagName()
    || element.hasH4TagName() || element.hasH5TagName() || element.hasH6TagName()
}

func shouldEmitReplacementInsteadOfNode(node: NodeWrapper) -> Bool {
  // Placeholders should eventually disappear, so treating them as a line break doesn't make sense
  // as when they are removed the text after it is combined with the text before it.
  return node is TextPlaceholderElementWrapper
  // Placeholders should eventually disappear, so treating them as a line break doesn't make sense
  // as when they are removed the text after it is combined with the text before it.
}

func shouldEmitNewlinesBeforeAndAfterNode(node: NodeWrapper) -> Bool {
  // Block flow (versus inline flow) is represented by having
  // a newline both before and after the element.
  let renderer: RenderObjectWrapper? = node.renderer()
  if renderer == nil {
    if hasDisplayContents(node: node) {
      return false
    }
    let element: HTMLElementWrapper? = node as? HTMLElementWrapper
    return element != nil
      && (hasHeaderTag(element: element!) || element!.hasBlockquoteTagName()
        || element!.hasDdTagName() || element!.hasDivTagName() || element!.hasDlTagName()
        || element!.hasDtTagName() || element!.hasHRTagName() || element!.hasLiTagName()
        || element!.hasListingTagName() || element!.hasOlTagName() || element!.hasPTagName()
        || element!.hasPreTagName() || element!.hasTrTagName() || element!.hasUlTagName())
  }
  // Need to make an exception for table cells, because they are blocks, but we
  // want them tab-delimited rather than having newlines before and after.
  if isTableCell(node: node) {
    return false
  }
  // Need to make an exception for table row elements, because they are neither
  // "inline" or "RenderBlock", but we want newlines for them.
  if let tableRow = renderer! as? RenderTableRowWrapper {
    let table: RenderTableWrapper? = tableRow.table()
    if table != nil && !table!.isInline() {
      return true
    }
  }
  if shouldEmitReplacementInsteadOfNode(node: node) {
    return false
  }
  return !renderer!.isInline() && renderer! is RenderBlockWrapper
    && !renderer!.isFloatingOrOutOfFlowPositioned() && !renderer!.isBody()
}

func shouldEmitNewlineAfterNode(
  node: NodeWrapper, emitsCharactersBetweenAllVisiblePositions: Bool = false
) -> Bool {
  // FIXME: It should be better but slower to create a VisiblePosition here.
  if !shouldEmitNewlinesBeforeAndAfterNode(node: node) {
    return false
  }
  // Don't emit a new line at the end of the document unless we're matching the behavior of VisiblePosition.
  if emitsCharactersBetweenAllVisiblePositions {
    return true
  }
  var subsequentNode: NodeWrapper? = node
  while true {
    subsequentNode = nextSkippingChildren(subsequentNode!)
    if subsequentNode == nil {
      break
    }
    if subsequentNode!.renderer() != nil {
      return true
    }
  }
  return false
}

func shouldEmitNewlineBeforeNode(node: NodeWrapper) -> Bool {
  return shouldEmitNewlinesBeforeAndAfterNode(node: node)
}

func shouldEmitExtraNewlineForNode(node: NodeWrapper) -> Bool {
  // When there is a significant collapsed bottom margin, emit an extra
  // newline for a more realistic result. We end up getting the right
  // result even without margin collapsing. For example: <div><p>text</p></div>
  // will work right even if both the <div> and the <p> have bottom margins.
  let renderBox: RenderBoxWrapper? = node.renderer() as? RenderBoxWrapper
  if renderBox == nil || !renderBox!.height().bool() {
    return false
  }
  // NOTE: We only do this for a select set of nodes, and WinIE appears not to do this at all.
  let element: HTMLElementWrapper? = node as? HTMLElementWrapper
  if element == nil
    || (!hasHeaderTag(element: element!) && !(element! is HTMLParagraphElementWrapper))
  {
    return false
  }
  let bottomMargin = renderBox!.collapsedMarginAfter()
  let fontSize: Float32 = renderBox!.style().fontDescription().computedSize()
  return bottomMargin * Int32(2) >= fontSize
}

func collapsedSpaceLength(renderer: RenderTextWrapper, textEnd: Int32) -> Int32 {
  let text = renderer.text()
  let length: UInt32 = text.length()
  var i: UInt32 = UInt32(textEnd)
  while i < length {
    if !(renderer.style().isCollapsibleWhiteSpace(text[i])) {
      return Int32(i - UInt32(textEnd))
    }
    i += 1
  }
  return Int32(length - UInt32(textEnd))
}

func maxOffsetIncludingCollapsedSpaces(node: NodeWrapper) -> Int32 {
  var offset: Int32 = caretMaxOffset(node: node)
  if let renderText = node.renderer() as? RenderTextWrapper {
    offset += collapsedSpaceLength(renderer: renderText, textEnd: offset)
  }
  return offset
}

func foldQuoteMarkAndReplaceNoBreakSpace(c: UInt16) -> UInt16 {
  switch Int32(c) {
  case Int32(hebrewPunctuationGershayim), Int32(leftDoubleQuotationMark),
    Int32(leftLowDoubleQuotationMark), Int32(rightDoubleQuotationMark),
    Int32(leftPointingDoubleAngleQuotationMark), Int32(rightPointingDoubleAngleQuotationMark),
    Int32(doubleHighReversed9QuotationMark), Int32(doubleLowReversed9QuotationMark),
    Int32(reversedDoublePrimeQuotationMark), Int32(doublePrimeQuotationMark),
    Int32(lowDoublePrimeQuotationMark), Int32(fullwidthQuotationMark):
    return UInt16(34 /* '"' */)
  case Int32(hebrewPunctuationGeresh), Int32(leftSingleQuotationMark),
    Int32(leftLowSingleQuotationMark), Int32(rightSingleQuotationMark),
    Int32(singleLow9QuotationMark), Int32(singleLeftPointingAngleQuotationMark),
    Int32(singleRightPointingAngleQuotationMark), Int32(leftCornerBracket),
    Int32(rightCornerBracket), Int32(leftWhiteCornerBracket), Int32(rightWhiteCornerBracket),
    Int32(presentationFormForVerticalLeftCornerBracket),
    Int32(presentationFormForVerticalRightCornerBracket),
    Int32(presentationFormForVerticalLeftWhiteCornerBracket),
    Int32(presentationFormForVerticalRightWhiteCornerBracket), Int32(fullwidthApostrophe),
    Int32(halfwidthLeftCornerBracket), Int32(halfwidthRightCornerBracket):
    return UInt16(39 /* '\'' */)
  case Int32(noBreakSpace):
    return UInt16(32 /* ' ' */)
  default:
    return c
  }
}

func foldQuoteMarks(stringToFold: StringWrapper) -> StringWrapper {
  var result = makeStringByReplacingAll(
    stringToFold, target: hebrewPunctuationGeresh, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: hebrewPunctuationGershayim, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: leftDoubleQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: leftLowDoubleQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: leftSingleQuotationMark, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: leftLowSingleQuotationMark, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: rightDoubleQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: singleLow9QuotationMark, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: singleLeftPointingAngleQuotationMark, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: singleRightPointingAngleQuotationMark, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: leftCornerBracket, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: rightCornerBracket, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: leftWhiteCornerBracket, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: rightWhiteCornerBracket, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: presentationFormForVerticalLeftCornerBracket,
    replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: presentationFormForVerticalRightCornerBracket,
    replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: presentationFormForVerticalLeftWhiteCornerBracket,
    replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: presentationFormForVerticalRightWhiteCornerBracket,
    replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: fullwidthApostrophe, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: halfwidthLeftCornerBracket, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: halfwidthRightCornerBracket, replacement: UInt16(39 /* '\'' */))
  result = makeStringByReplacingAll(
    result, target: leftPointingDoubleAngleQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: rightPointingDoubleAngleQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: doubleHighReversed9QuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: doubleLowReversed9QuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: reversedDoublePrimeQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: doublePrimeQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: lowDoublePrimeQuotationMark, replacement: UInt16(34 /* '"' */))
  result = makeStringByReplacingAll(
    result, target: fullwidthQuotationMark, replacement: UInt16(34 /* '"' */))
  return makeStringByReplacingAll(
    result, target: rightSingleQuotationMark, replacement: UInt16(39 /* '\'' */))
}

let minimumSearchBufferSize: UInt64 = 8192

var searcherInUse: Bool = false

func createSearcher() -> UnsafeMutableRawPointer? {
  fatalError("Not implemented")
}

func searcher() -> UnsafeMutableRawPointer? {
  return searcherInSearcher
}

func lockSearcher() {
  assert(!searcherInUse)
  searcherInUse = true
}

func unlockSearcher() {
  assert(searcherInUse)
  searcherInUse = false
}

func isKanaLetter(character: UInt16) -> Bool {
  // Hiragana letters.
  if Int32(character) >= 12353 && Int32(character) <= 12438 {
    return true
  }
  // Katakana letters.
  if Int32(character) >= 12449 && Int32(character) <= 12538 {
    return true
  }
  if Int32(character) >= 12784 && Int32(character) <= 12799 {
    return true
  }
  // Halfwidth katakana letters.
  if Int32(character) >= 65382 && Int32(character) <= 65437 && Int32(character) != 65392 {
    return true
  }
  return false
}

func isSmallKanaLetter(character: UInt16) -> Bool {
  assert(isKanaLetter(character: character))
  switch Int32(character) {
  case 12353, 12355, 12357, 12359, 12361, 12387, 12419, 12421, 12423, 12430, 12437, 12438, 12449,
    12451, 12453, 12455, 12457, 12483, 12515, 12517, 12519, 12526, 12533, 12534, 12784, 12785,
    12786, 12787, 12788, 12789, 12790, 12791, 12792, 12793, 12794, 12795, 12796, 12797, 12798,
    12799, 65383, 65384, 65385, 65386, 65387, 65388, 65389, 65390, 65391:
    return true
  default:
    break
  }
  return false
}

func composedVoicedSoundMark(character: UInt16) -> VoicedSoundMarkType {
  assert(isKanaLetter(character: character))
  switch Int32(character) {
  case 12364, 12366, 12368, 12370, 12372, 12374, 12376, 12378, 12380, 12382, 12384, 12386, 12389,
    12391, 12393, 12400, 12403, 12406, 12409, 12412, 12436, 12460, 12462, 12464, 12466, 12468,
    12470, 12472, 12474, 12476, 12478, 12480, 12482, 12485, 12487, 12489, 12496, 12499, 12502,
    12505, 12508, 12532, 12535, 12536, 12537, 12538:
    return .VoicedSoundMark
  case 12401, 12404, 12407, 12410, 12413, 12497, 12500, 12503, 12506, 12509:
    return .SemiVoicedSoundMark
  default:
    break
  }
  return .NoVoicedSoundMark
}

func isCombiningVoicedSoundMark(character: UInt16) -> Bool {
  switch Int32(character) {
  case 12441, 12442:
    return true
  default:
    break
  }
  return false
}

func containsKanaLetters(pattern: StringWrapper) -> Bool {
  fatalError("Not implemented")
}

func normalizeCharacters(characters: UInt16?, length: UInt32, buffer: inout [UInt16]) {
  fatalError("Not implemented")
}

func isNonLatin1Separator(character: UInt32) -> Bool {
  fatalError("Not implemented")
}

func isSeparator(character: UInt32) -> Bool {
  if isLatin1(character) {
    return latin1SeparatorTableInIsSeparator[Int(character)]
  }
  return isNonLatin1Separator(character: character)
}

func characterCount(range: SimpleRange, behaviors: TextIteratorBehavior = []) -> UInt64 {
  fatalError("Not implemented")
}

func isInsideReplacedElement(iterator: inout EditingTextIterator, behaviors: TextIteratorBehavior)
  -> Bool
{
  assert(!iterator.atEnd())
  assert(iterator.text().length() == 1)
  let node: NodeWrapper? = iterator.node()
  return node != nil && isRendererReplacedElement(renderer: node!.renderer(), behaviors: behaviors)
}

func clampedAdd(a: UInt64, b: UInt64) -> UInt64 {
  let sum: UInt64 = a + b
  return sum >= a ? sum : UInt64.max
}

func resolveCharacterRange(
  scope: SimpleRange, range: CharacterRange, behaviors: TextIteratorBehavior = []
) -> SimpleRange {
  var resultRange = SimpleRange(
    start: range.location != 0 ? scope.end : scope.start,
    end: (range.location != 0 || range.length != 0) ? scope.end : scope.start)
  let rangeEnd: UInt64 = clampedAdd(a: range.location, b: range.length)
  var location: UInt64 = 0
  var it = EditingTextIterator(range: scope, behaviors: behaviors)
  while !it.atEnd() {
    let length: UInt32 = it.text().length()
    var textRunRange = it.range()
    let found = { (targetLocation: UInt64) -> Bool in
      return targetLocation >= location && targetLocation - location <= UInt64(length)
    }
    let foundStart: Bool = found(range.location)
    let foundEnd: Bool = found(rangeEnd)
    if foundEnd {
      // FIXME: This is a workaround for the fact that the end of a run is often at the wrong position for emitted '\n's or if the renderer of the current node is a replaced element.
      // FIXME: consider controlling this with TextIteratorBehavior instead of doing it unconditionally to help us eventually phase it out everywhere.
      if length == 1
        && (Int32(it.text()[0]) == Int32(10 /* '\n' */)
          || isInsideReplacedElement(iterator: &it, behaviors: behaviors))
      {
        it.advance()
        if !it.atEnd() {
          textRunRange.end = it.range().start
        } else {
          if let end = makeBoundaryPoint(
            position: VisiblePosition(makeDeprecatedLegacyPosition(point: textRunRange.start))
              .next().deepEquivalent())
          {
            textRunRange.end = end
          }
        }
      }
    }
    let boundary = { (targetLocation: UInt64) -> BoundaryPoint in
      if textRunRange.start.container is TextWrapper {
        assert(
          targetLocation - location
            <= UInt64((textRunRange.start.container as! TextWrapper).length()))
        let offset: UInt32 = UInt32(UInt64(textRunRange.start.offset) + targetLocation - location)
        return BoundaryPoint(container: textRunRange.start.container, offset: offset)
      }
      return targetLocation == location ? textRunRange.start : textRunRange.end
    }
    if foundStart {
      resultRange.start = boundary(range.location)
    }
    if foundEnd {
      resultRange.end = boundary(rangeEnd)
      break
    }
    location += UInt64(length)
    it.advance()
  }
  return resultRange
}

func hasAnyPlainText(range: SimpleRange, behaviors: TextIteratorBehavior = []) -> Bool {
  var iterator = EditingTextIterator(range: range, behaviors: behaviors)
  while !iterator.atEnd() {
    if !(iterator.text().isEmpty()) {
      return true
    }
    iterator.advance()
  }
  return false
}

func plainText(
  range: SimpleRange, defaultBehavior: TextIteratorBehavior = [], isDisplayString: Bool = false
) -> StringWrapper {
  fatalError("Not implemented")
}

func plainTextReplacingNoBreakSpace(
  range: SimpleRange, defaultBehaviors: TextIteratorBehavior = [], isDisplayString: Bool = false
) -> StringWrapper {
  return makeStringByReplacingAll(
    plainText(range: range, defaultBehavior: defaultBehaviors, isDisplayString: isDisplayString),
    target: noBreakSpace, replacement: UInt16(32 /* ' ' */))
}

func forEachMatch(
  range: SimpleRange, target: StringWrapper, options: FindOption, match: (CharacterRange) -> Bool
) {
  let buffer = SearchBuffer(target: target, options)
  if buffer.needsMoreContext() {
    let beforeStartRange = SimpleRange(
      start: makeBoundaryPointBeforeNodeContents(createNodeWrapper(range.start.document().p)),
      end: range.start)
    var backwardsIterator = SimplifiedBackwardsTextIterator(range: beforeStartRange)
    while !backwardsIterator.atEnd() {
      buffer.prependContext(backwardsIterator.text())
      if !buffer.needsMoreContext() {
        break
      }
      backwardsIterator.advance()
    }
  }
  var findIterator = CharacterIterator(
    range: range, behaviors: findIteratorOptions(options: options))
  while !findIterator.atEnd() {
    findIterator.advance(count: Int32(buffer.append(findIterator.text())))
    while 1 != 0 {
      var matchStartOffset: UInt64 = 0
      let newMatchLength: UInt64 = buffer.search(startOffset: &matchStartOffset)
      if !(newMatchLength != 0) {
        if findIterator.atBreak() && !buffer.atBreak() {
          buffer.reachedBreak()
          continue
        }
        break
      }
      let lastCharacterInBufferOffset: UInt64 = UInt64(findIterator.characterOffset())
      assert(lastCharacterInBufferOffset >= matchStartOffset)
      if match(
        CharacterRange(
          location: lastCharacterInBufferOffset - matchStartOffset, length: newMatchLength))
      {
        return
      }
    }
  }
}

func rangeForMatch(range: SimpleRange, options: FindOption, match: CharacterRange) -> SimpleRange {
  let noMatchResult = { () -> SimpleRange in
    let boundary = options.contains(.Backwards) ? range.start : range.end
    return SimpleRange(start: boundary, end: boundary)
  }
  if !(match.length != 0) {
    return noMatchResult()
  }
  var it = CharacterIterator(range: range, behaviors: findIteratorOptions(options: options))
  it.advance(count: Int32(match.location))
  if it.atEnd() {
    return noMatchResult()
  }
  let start = it.range().start
  it.advance(count: Int32(match.length - 1))
  if it.atEnd() {
    return noMatchResult()
  }
  return SimpleRange(start: start, end: it.range().end)
}

func findClosestPlainText(
  range: SimpleRange, target: StringWrapper, options: FindOption, targetOffset: UInt64
) -> SimpleRange {
  var closestMatch = CharacterRange()
  var closestMatchDistance: UInt64 = UInt64.max
  forEachMatch(
    range: range, target: target, options: options,
    match: ({ (match: CharacterRange) -> Bool in
      let distance = { (a: UInt64, b: UInt64) -> UInt64 in
        return UInt64(abs(Int64(Int64(a - b))))
      }
      let matchDistance: UInt64 = min(
        distance(match.location, targetOffset),
        distance(match.location + match.length, targetOffset))
      if matchDistance > closestMatchDistance {
        return false
      }
      if matchDistance == closestMatchDistance && !options.contains(.Backwards) {
        return false
      }
      closestMatch = match
      if !(matchDistance != 0) && !options.contains(.Backwards) {
        return true
      }
      closestMatchDistance = matchDistance
      return false
    }))
  return rangeForMatch(range: range, options: options, match: closestMatch)
}

func findPlainText(range: SimpleRange, target: StringWrapper, options: FindOption) -> SimpleRange {
  // When searching forward stop since we want the first match.
  // When searching backward keep going since we want the last match.
  let stopAfterFindingMatch: Bool = !options.contains(.Backwards)
  var lastMatchFound = CharacterRange()
  forEachMatch(
    range: range, target: target, options: options,
    match: ({ (match: CharacterRange) -> Bool in
      lastMatchFound = match
      return stopAfterFindingMatch
    }))
  return rangeForMatch(range: range, options: options, match: lastMatchFound)
}

func containsPlainText(document: StringWrapper, target: StringWrapper, options: FindOption) -> Bool
{
  let buffer = SearchBuffer(target: target, options)
  var remainingText = StringWrapperView(s: document)
  while !remainingText.isEmpty() {
    let charactersAppended: UInt64 = buffer.append(StringWrapperView(s: document))
    remainingText = remainingText.substring(start: UInt32(charactersAppended))
    if remainingText.isEmpty() {
      buffer.reachedBreak()
    }
    var matchStartOffset: UInt64 = 0
    if buffer.search(startOffset: &matchStartOffset) != 0 {
      return true
    }
  }
  return false
}

// A function-local static in searcher().
private var searcherInSearcher: UnsafeMutableRawPointer? = createSearcher()

// A function-local static in isSeparator().
private let latin1SeparatorTableInIsSeparator: [Bool] = [
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0,
  1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 1 != 0, 1 != 0,
  1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0,
  1 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0,
  1 != 0, 1 != 0, 0 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0,
  1 != 0, 0 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 0 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0, 1 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 1 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0, 1 != 0, 0 != 0, 0 != 0, 0 != 0, 0 != 0,
  0 != 0, 0 != 0, 0 != 0, 0 != 0,
]
