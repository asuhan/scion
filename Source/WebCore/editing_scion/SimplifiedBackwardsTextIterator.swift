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

struct SimplifiedBackwardsTextIterator {
  func atEnd() -> Bool {
    return positionNode == nil
  }

  func text() -> StringWrapperView {
    assert(!atEnd())
    return m_text
  }

  func node() -> NodeWrapper? {
    assert(!atEnd())
    return m_node
  }

  func protectedNode() -> NodeWrapper? {
    return m_node
  }

  init(range: SimpleRange) {
    self.behaviors = []
    self.m_node = nil
    self.fullyClippedStack = BitStack()
    self.startContainer = nil
    self.endContainer = nil
    self.positionNode = nil
    self.copyableText = TextIteratorCopyableText()
    self.m_text = StringWrapperView()
    self.lastTextNode = nil
    range.start.protectedDocument().updateLayoutIgnorePendingStylesheets()
    var startNode: NodeWrapper? = range.start.container
    var endNode: NodeWrapper? = range.end.container
    var startOffset: UInt32 = range.start.offset
    var endOffset: UInt32 = range.end.offset
    if !startNode!.isCharacterDataNode() {
      if startOffset < startNode!.countChildNodes() {
        startNode = startNode!.traverseToChildAt(startOffset)
        startOffset = 0
      }
    }
    if !endNode!.isCharacterDataNode() {
      if endOffset > 0 && endOffset <= endNode!.countChildNodes() {
        endNode = endNode!.traverseToChildAt(endOffset - 1)
        endOffset = endNode!.length()
      }
    }
    m_node = endNode
    setUpFullyClippedStack(stack: &fullyClippedStack, node: m_node!)
    offset = Int32(endOffset)
    handledNode = false
    handledChildren = endOffset == 0
    startContainer = startNode
    self.startOffset = Int32(startOffset)
    endContainer = endNode
    self.endOffset = Int32(endOffset)
    positionNode = endNode
    lastTextNode = nil
    lastCharacter = UInt16(10 /* '\n' */)
    havePassedStartContainer = false
    advance()
  }

  mutating func advance() {
    assert(!atEnd())
    positionNode = nil
    copyableText.reset()
    m_text = StringWrapperView()
    while m_node != nil && !havePassedStartContainer {
      // Don't handle node if we start iterating at [node, 0].
      if !handledNode
        && !((CPtrToInt(m_node?.p) == CPtrToInt(endContainer?.p) && !(endOffset != 0)))
      {
        let renderer: RenderObjectWrapper? = m_node!.renderer()
        if renderer != nil && renderer!.isRenderText() && m_node!.isTextNode() {
          if renderer!.style().visibility() == .Visible && offset > 0 {
            handledNode = handleTextNode()
          }
        } else if isRendererReplacedElement(renderer: renderer, behaviors: behaviors) {
          if renderer!.style().visibility() == .Visible && offset > 0 {
            handledNode = handleReplacedElement()
          }
        } else {
          handledNode = handleNonTextNode()
        }
        if positionNode != nil {
          return
        }
      }
      if !handledChildren && m_node!.hasChildNodes() {
        m_node = m_node!.lastChild()
        pushFullyClippedState(stack: &fullyClippedStack, node: protectedNode()!)
      } else {
        // Exit empty containers as we pass over them or containers
        // where [container, 0] is where we started iterating.
        if !handledNode && canHaveChildrenForEditing(node: protectedNode()!)
          && m_node!.parentNode() != nil
          && (m_node!.lastChild() == nil
            || (CPtrToInt(m_node?.p) == CPtrToInt(endContainer?.p) && !(endOffset != 0)))
        {
          exitNode()
          if positionNode != nil {
            handledNode = true
            handledChildren = true
            return
          }
        }
        // Exit all other containers.
        while m_node!.previousSibling() == nil {
          if !(advanceRespectingRange(next: m_node!.protectedParentOrShadowHostNode())) {
            break
          }
          fullyClippedStack.pop()
          exitNode()
          if positionNode != nil {
            handledNode = true
            handledChildren = true
            return
          }
        }
        fullyClippedStack.pop()
        if advanceRespectingRange(next: m_node!.protectedPreviousSibling()) {
          pushFullyClippedState(stack: &fullyClippedStack, node: protectedNode()!)
        } else {
          m_node = nil
        }
      }
      // For the purpose of word boundary detection,
      // we should iterate all visible text and trailing (collapsed) whitespaces.
      offset = m_node != nil ? maxOffsetIncludingCollapsedSpaces(node: protectedNode()!) : 0
      handledNode = false
      handledChildren = false
      if positionNode != nil {
        return
      }
    }
  }

  mutating func handleTextNode() -> Bool {
    lastTextNode = (m_node as! TextWrapper)
    var startOffset: Int32 = 0
    var offsetInNode: Int32 = 0
    let renderer: RenderTextWrapper? = handleFirstLetter(
      startOffset: &startOffset, offsetInNode: &offsetInNode)
    if renderer == nil {
      return true
    }
    let text = renderer!.text()
    if !renderer!.hasRenderedText() && text.length() != 0 {
      return true
    }
    if startOffset + offsetInNode == offset {
      assert(!shouldHandleFirstLetter)
      return true
    }
    positionEndOffset = offset
    offset = startOffset + offsetInNode
    positionNode = m_node
    positionStartOffset = offset
    assert(positionStartOffset < positionEndOffset)
    assert(positionStartOffset - offsetInNode >= 0)
    assert(positionEndOffset - offsetInNode > 0)
    assert(positionEndOffset - offsetInNode <= Int32(Int32(text.length())))
    lastCharacter = text[UInt32(positionEndOffset - offsetInNode - 1)]
    copyableText.set(
      string: text, offset: UInt32(positionStartOffset - offsetInNode),
      length: UInt32(positionEndOffset - positionStartOffset))
    m_text = copyableText.text()
    return !shouldHandleFirstLetter
  }

  mutating func handleFirstLetter(startOffset: inout Int32, offsetInNode: inout Int32)
    -> RenderTextWrapper?
  {
    let renderer = m_node!.renderer()! as! RenderTextWrapper
    startOffset = (CPtrToInt(m_node?.p) == CPtrToInt(startContainer?.p)) ? self.startOffset : 0
    let fragment: RenderTextFragmentWrapper? = renderer as? RenderTextFragmentWrapper
    if fragment == nil {
      offsetInNode = 0
      return renderer
    }
    let offsetAfterFirstLetter: Int32 = Int32(fragment!.start())
    if startOffset >= offsetAfterFirstLetter {
      assert(!shouldHandleFirstLetter)
      offsetInNode = offsetAfterFirstLetter
      return renderer
    }
    if !shouldHandleFirstLetter && startOffset + offsetAfterFirstLetter < offset {
      shouldHandleFirstLetter = true
      offsetInNode = offsetAfterFirstLetter
      return renderer
    }
    shouldHandleFirstLetter = false
    offsetInNode = 0
    let firstLetterRenderer: RenderTextWrapper? = firstRenderTextInFirstLetter(
      firstLetter: fragment!.firstLetter())
    offset = firstLetterRenderer!.caretMaxOffset()
    offset += collapsedSpaceLength(renderer: firstLetterRenderer!, textEnd: offset)
    return firstLetterRenderer
  }

  mutating func handleReplacedElement() -> Bool {
    let index: UInt32 = m_node!.computeNodeIndex()
    // We want replaced elements to behave like punctuation for boundary
    // finding, and to simply take up space for the selection preservation
    // code in moveParagraphs, so we use a comma. Unconditionally emit
    // here because this iterator is only used for boundary finding.
    emitCharacter(
      c: UInt16(44 /* ',' */), node: m_node!.protectedParentNode(), startOffset: Int32(index),
      endOffset: Int32(index + 1))
    return true
  }

  mutating func handleNonTextNode() -> Bool {
    let currentNode: NodeWrapper? = protectedNode()
    if shouldEmitTabBeforeNode(node: currentNode!) {
      let index: UInt32 = currentNode!.computeNodeIndex()
      emitCharacter(
        c: UInt16(9 /* '\t' */), node: currentNode!.protectedParentNode(),
        startOffset: Int32(index + 1), endOffset: Int32(index + 1))
    } else if shouldEmitNewlineForNode(
      node: currentNode, emitsOriginalText: behaviors.contains(.EmitsOriginalText))
      || shouldEmitNewlineAfterNode(node: m_node!)
    {
      if Int32(lastCharacter) != Int32(10 /* '\n' */) {
        // Corresponds to the same check in TextIterator::exitNode.
        let index: UInt32 = currentNode!.computeNodeIndex()
        // The start of this emitted range is wrong. Ensuring correctness would require
        // VisiblePositions and so would be slow. previousBoundary expects this.
        emitCharacter(
          c: UInt16(10 /* '\n' */), node: currentNode!.protectedParentNode(),
          startOffset: Int32(index + 1), endOffset: Int32(index + 1))
      }
    }
    return true
  }

  mutating func exitNode() {
    let node: NodeWrapper? = protectedNode()
    if shouldEmitTabBeforeNode(node: node!) {
      emitCharacter(c: UInt16(9 /* '\t' */), node: node, startOffset: 0, endOffset: 0)
    } else if shouldEmitNewlineForNode(
      node: node, emitsOriginalText: behaviors.contains(.EmitsOriginalText))
      || shouldEmitNewlineBeforeNode(node: m_node!)
    {
      // The start of this emitted range is wrong. Ensuring correctness would require
      // VisiblePositions and so would be slow. previousBoundary expects this.
      emitCharacter(c: UInt16(10 /* '\n' */), node: node, startOffset: 0, endOffset: 0)
    }
  }

  mutating func emitCharacter(c: UInt16, node: NodeWrapper?, startOffset: Int32, endOffset: Int32) {
    assert(node != nil)
    positionNode = node
    positionStartOffset = startOffset
    positionEndOffset = endOffset
    copyableText.set(singleCharacter: c)
    m_text = copyableText.text()
    lastCharacter = c
  }

  mutating func advanceRespectingRange(next: NodeWrapper?) -> Bool {
    if next == nil {
      return false
    }
    havePassedStartContainer =
      (CPtrToInt(m_node?.p) == CPtrToInt(startContainer?.p)) || havePassedStartContainer
    if havePassedStartContainer {
      return false
    }
    m_node = next
    return true
  }

  func range() -> SimpleRange {
    assert(!atEnd())
    let positionNode = self.positionNode!
    return SimpleRange(
      start: BoundaryPoint(container: positionNode, offset: UInt32(UInt32(positionStartOffset))),
      end: BoundaryPoint(container: positionNode, offset: UInt32(UInt32(positionEndOffset))))
  }

  private var behaviors: TextIteratorBehaviors
  private var m_node: NodeWrapper? = nil
  private var offset: Int32 = 0
  private var handledNode: Bool = false
  private var handledChildren: Bool = false
  private var fullyClippedStack: BitStack
  private var startContainer: NodeWrapper? = nil
  private var startOffset: Int32 = 0
  private var endContainer: NodeWrapper? = nil
  private var endOffset: Int32 = 0
  private var positionNode: NodeWrapper? = nil
  private var positionStartOffset: Int32 = 0
  private var positionEndOffset: Int32 = 0
  private var copyableText: TextIteratorCopyableText
  private var m_text: StringWrapperView
  private var lastTextNode: TextWrapper? = nil
  private var lastCharacter: UInt16 = 0
  private var havePassedStartContainer: Bool = false
  private var shouldHandleFirstLetter: Bool = false
}
