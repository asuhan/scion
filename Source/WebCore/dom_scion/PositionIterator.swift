/*
 * Copyright (C) 2007, 2008 Apple Inc. All rights reserved.
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

import wk_interop

struct PositionIterator {
  init(pos: Position) {
    self.anchorNode = pos.anchorNode()
    self.nodeAfterPositionInAnchor = anchorNode!.traverseToChildAt(
      UInt32(pos.deprecatedEditingOffset()))
    self.offsetInAnchor = nodeAfterPositionInAnchor != nil ? 0 : pos.deprecatedEditingOffset()
  }

  func node() -> NodeWrapper? {
    return anchorNode
  }

  func protectedNode() -> NodeWrapper? {
    return anchorNode
  }

  func offsetInLeafNode() -> Int32 {
    return offsetInAnchor
  }

  func toPosition() -> Position {
    let anchorNode: NodeWrapper? = protectedNode()
    if nodeAfterPositionInAnchor != nil {
      assert(CPtrToInt(nodeAfterPositionInAnchor!.parentNode()?.p) == CPtrToInt(anchorNode?.p))
      // FIXME: This check is inadaquete because any ancestor could be ignored by editing
      if positionBeforeOrAfterNodeIsCandidate(node: anchorNode!) {
        return positionBeforeNode(anchorNode: anchorNode)
      }
      return positionInParentBeforeNode(node: nodeAfterPositionInAnchor)
    }
    if positionBeforeOrAfterNodeIsCandidate(node: anchorNode!) {
      return atStartOfNode()
        ? positionBeforeNode(anchorNode: anchorNode) : positionAfterNode(anchorNode: anchorNode)
    }
    if anchorNode!.hasChildNodes() {
      return lastPositionInOrAfterNode(anchorNode)
    }
    return makeDeprecatedLegacyPosition(anchorNode, UInt32(offsetInAnchor))
  }

  mutating func increment() {
    if anchorNode == nil {
      return
    }
    if nodeAfterPositionInAnchor != nil {
      anchorNode = nodeAfterPositionInAnchor
      nodeAfterPositionInAnchor = anchorNode!.firstChild()
      offsetInAnchor = 0
      return
    }
    let anchorNode: NodeWrapper? = protectedNode()
    if anchorNode!.renderer() != nil && !anchorNode!.hasChildNodes()
      && offsetInAnchor < lastOffsetForEditing(node: anchorNode!)
    {
      offsetInAnchor = Position.uncheckedNextOffset(n: anchorNode, current: UInt32(offsetInAnchor))
    } else {
      nodeAfterPositionInAnchor = anchorNode
      self.anchorNode = nodeAfterPositionInAnchor!.parentNode()
      nodeAfterPositionInAnchor = nodeAfterPositionInAnchor!.nextSibling()
      offsetInAnchor = 0
    }
  }

  mutating func decrement() {
    if anchorNode == nil {
      return
    }
    if nodeAfterPositionInAnchor != nil {
      anchorNode = nodeAfterPositionInAnchor!.previousSibling()
      if let anchorNode = protectedNode() {
        nodeAfterPositionInAnchor = nil
        offsetInAnchor = anchorNode.hasChildNodes() ? 0 : lastOffsetForEditing(node: anchorNode)
      } else {
        nodeAfterPositionInAnchor = nodeAfterPositionInAnchor!.parentNode()
        self.anchorNode = nodeAfterPositionInAnchor!.parentNode()
        offsetInAnchor = 0
      }
      return
    }
    if self.anchorNode!.hasChildNodes() {
      self.anchorNode = self.anchorNode!.lastChild()
      offsetInAnchor =
        self.anchorNode!.hasChildNodes() ? 0 : lastOffsetForEditing(node: self.anchorNode!)
    } else {
      if offsetInAnchor != 0 && self.anchorNode!.renderer() != nil {
        offsetInAnchor = Position.uncheckedPreviousOffset(
          n: self.anchorNode, current: UInt32(offsetInAnchor))
      } else {
        nodeAfterPositionInAnchor = self.anchorNode
        self.anchorNode = self.anchorNode!.parentNode()
      }
    }
  }

  func atStart() -> Bool {
    if anchorNode == nil {
      return true
    }
    if anchorNode!.parentNode() != nil {
      return false
    }
    return (!anchorNode!.hasChildNodes() && !(offsetInAnchor != 0))
      || (nodeAfterPositionInAnchor != nil && nodeAfterPositionInAnchor!.previousSibling() == nil)
  }

  func atEnd() -> Bool {
    let anchorNode: NodeWrapper? = protectedNode()
    if anchorNode == nil {
      return true
    }
    if nodeAfterPositionInAnchor != nil {
      return false
    }
    return anchorNode!.parentNode() == nil
      && (anchorNode!.hasChildNodes() || offsetInAnchor >= lastOffsetForEditing(node: anchorNode!))
  }

  func atStartOfNode() -> Bool {
    if anchorNode == nil {
      return true
    }
    if nodeAfterPositionInAnchor == nil {
      return !anchorNode!.hasChildNodes() && !(offsetInAnchor != 0)
    }
    return nodeAfterPositionInAnchor!.previousSibling() == nil
  }

  func atEndOfNode() -> Bool {
    let anchorNode: NodeWrapper? = protectedNode()
    if anchorNode == nil {
      return true
    }
    if nodeAfterPositionInAnchor != nil {
      return false
    }
    return anchorNode!.hasChildNodes() || offsetInAnchor >= lastOffsetForEditing(node: anchorNode!)
  }

  func isCandidate() -> Bool {
    let anchorNode: NodeWrapper? = protectedNode()
    if anchorNode == nil {
      return false
    }
    let renderer: RenderObjectWrapper? = anchorNode!.renderer()
    if renderer == nil {
      return false
    }
    if renderer!.style().visibility() != .Visible {
      return false
    }
    if renderer!.isBRForRenderObject() {
      return self.toPosition().isCandidate()
    }
    if let renderText = renderer! as? RenderTextWrapper {
      return !Position.nodeIsUserSelectNone(node: anchorNode)
        && renderText.containsCaretOffset(UInt32(offsetInAnchor))
    }
    if positionBeforeOrAfterNodeIsCandidate(node: anchorNode!) {
      return (atStartOfNode() || atEndOfNode())
        && !(Position.nodeIsUserSelectNone(node: anchorNode!.parentNode()))
    }
    if anchorNode! is HTMLHtmlElement {
      return false
    }
    if let block = renderer! as? RenderBlockWrapper {
      if block is RenderBlockFlowWrapper || block is RenderGridWrapper
        || block is RenderFlexibleBoxWrapper
      {
        if block.logicalHeight().bool() || anchorNode! is HTMLBodyElement
          || anchorNode!.isRootEditableElement()
        {
          if !Position.hasRenderedNonAnonymousDescendantsWithHeight(renderer: block) {
            return atStartOfNode() && !Position.nodeIsUserSelectNone(node: anchorNode)
          }
          return anchorNode!.hasEditableStyle() && !Position.nodeIsUserSelectNone(node: anchorNode)
            && self.toPosition().atEditingBoundary()
        }
        return false
      }
    }
    return anchorNode!.hasEditableStyle() && !Position.nodeIsUserSelectNone(node: anchorNode)
      && self.toPosition().atEditingBoundary()
  }

  private var anchorNode: NodeWrapper? = nil
  private var nodeAfterPositionInAnchor: NodeWrapper? = nil
  private var offsetInAnchor: Int32 = 0
}
