/*
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
 * Portions Copyright (c) 2011 Motorola Mobility, Inc.  All rights reserved.
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

struct VisiblePosition {
  init() {}

  func isNull() -> Bool {
    return deepPosition.isNull()
  }

  func isNotNull() -> Bool {
    return deepPosition.isNotNull()
  }

  func isOrphan() -> Bool {
    return deepPosition.isOrphan()
  }

  func deepEquivalent() -> Position {
    return deepPosition
  }

  func affinity() -> Affinity {
    return m_affinity
  }

  mutating func setAffinity(affinity: Affinity) {
    m_affinity = affinity
  }

  func characterBefore() -> UInt32 {
    return previous().characterAfter()
  }

  func rootEditableElement() -> ElementWrapper? {
    return deepPosition.isNotNull() ? deepPosition.deprecatedNode()!.rootEditableElement() : nil
  }

  init(_ position: Position, _ affinity: Affinity = VisiblePosition.defaultAffinity) {
    self.deepPosition = VisiblePosition.canonicalPosition(passedPosition: position)
    if affinity == .Upstream && !isNull() {
      var upstreamCopy = self
      upstreamCopy.m_affinity = .Upstream
      if !inSameLine(a: self, b: upstreamCopy) {
        m_affinity = .Upstream
      }
    }
  }

  func next(
    rule: EditingBoundaryCrossingRule = .CanCrossEditingBoundary, reachedBoundary: inout Bool?
  ) -> VisiblePosition {
    if reachedBoundary != nil {
      reachedBoundary! = false
    }
    // FIXME: Support CanSkipEditingBoundary
    assert(rule == .CanCrossEditingBoundary || rule == .CannotCrossEditingBoundary)
    let next = VisiblePosition(nextVisuallyDistinctCandidate(position: deepPosition), m_affinity)
    if rule == .CanCrossEditingBoundary {
      return next
    }
    return honorEditingBoundaryAtOrAfter(otherPosition: next, reachedBoundary: &reachedBoundary)
  }

  func next(rule: EditingBoundaryCrossingRule = .CanCrossEditingBoundary) -> VisiblePosition {
    var ignored: Bool? = nil
    return next(rule: rule, reachedBoundary: &ignored)
  }

  func previous(
    rule: EditingBoundaryCrossingRule = .CanCrossEditingBoundary, reachedBoundary: inout Bool?
  ) -> VisiblePosition {
    if reachedBoundary != nil {
      reachedBoundary! = false
    }
    // FIXME: Support CanSkipEditingBoundary
    assert(rule == .CanCrossEditingBoundary || rule == .CannotCrossEditingBoundary)
    // find first previous DOM position that is visible
    let pos = previousVisuallyDistinctCandidate(position: deepPosition)
    // return null visible position if there is no previous visible position
    if pos.atStartOfTree() {
      if reachedBoundary != nil {
        reachedBoundary! = true
      }
      return VisiblePosition()
    }
    let prev = VisiblePosition(pos)
    assert(prev != self)
    // We should always be able to make the affinity downstream, because going previous from an
    // upstream position can never yield another upstream position unless line wrap length is 0.
    if prev.isNotNull() && m_affinity == .Upstream {
      var upstreamCopy = prev
      upstreamCopy.setAffinity(affinity: .Upstream)
      assert(inSameLine(a: upstreamCopy, b: prev))
    }
    if rule == .CanCrossEditingBoundary {
      return prev
    }
    return honorEditingBoundaryAtOrBefore(position: prev, reachedBoundary: &reachedBoundary)
  }

  func previous(rule: EditingBoundaryCrossingRule = .CanCrossEditingBoundary) -> VisiblePosition {
    var ignored: Bool? = nil
    return previous(rule: rule, reachedBoundary: &ignored)
  }

  func leftVisuallyDistinctCandidate() -> Position {
    var p = deepPosition
    if p.isNull() {
      return Position()
    }
    let downstreamStart = p.downstream()
    let primaryDirection = p.primaryDirection()
    var orderCache = InlineIterator.LineLogicalOrderCache()
    while true {
      let decomposed = p.inlineBoxAndOffset(
        affinity: m_affinity, primaryDirection: primaryDirection)
      var box = decomposed.box
      var offset = decomposed.offset
      if !box.bool() {
        return primaryDirection == .LTR
          ? previousVisuallyDistinctCandidate(position: deepPosition)
          : nextVisuallyDistinctCandidate(position: deepPosition)
      }
      var renderer: RenderObjectWrapper? = box.get().renderer()
      while true {
        if (renderer!.isReplacedOrInlineBlock() || renderer!.isBRForRenderObject())
          && offset == box.get().rightmostCaretOffset()
        {
          return box.get().isLeftToRightDirection()
            ? previousVisuallyDistinctCandidate(position: deepPosition)
            : nextVisuallyDistinctCandidate(position: deepPosition)
        }
        if renderer!.node() == nil {
          box.traversePreviousOnLine()
          if !box.bool() {
            return primaryDirection == .LTR
              ? previousVisuallyDistinctCandidate(position: deepPosition)
              : nextVisuallyDistinctCandidate(position: deepPosition)
          }
          renderer = box.get().renderer()
          offset = box.get().rightmostCaretOffset()
          continue
        }
        // Note that this may underflow the (unsigned) offset. This is fine and handled below.
        offset = UInt32(
          box.get().isLeftToRightDirection()
            ? renderer!.previousOffset(Int32(offset)) : renderer!.nextOffset(Int32(offset)))
        let caretMinOffset: UInt32 = box.get().minimumCaretOffset()
        let caretMaxOffset: UInt32 = box.get().maximumCaretOffset()
        if offset > caretMinOffset && offset < caretMaxOffset {
          break
        }
        if offset != box.get().leftmostCaretOffset() {
          // Overshot to the left.
          let previousBox = box.get().previousOnLineIgnoringLineBreak()
          if !previousBox.bool() {
            let positionOnLeft =
              primaryDirection == .LTR
              ? previousVisuallyDistinctCandidate(position: deepPosition)
              : nextVisuallyDistinctCandidate(position: deepPosition)
            let boxOnLeft = positionOnLeft.inlineBoxAndOffset(
              affinity: m_affinity, primaryDirection: primaryDirection
            ).box
            if boxOnLeft.bool() && boxOnLeft.get().lineBox() == box.get().lineBox() {
              return Position()
            }
            return positionOnLeft
          }
          // Reposition at the other logical position corresponding to our edge's visual position and go for another round.
          box = previousBox
          renderer = box.get().renderer()
          offset = previousBox.get().rightmostCaretOffset()
          continue
        }
        var level: UInt8 = box.get().bidiLevel()
        var previousBox = box.get().previousOnLine()
        if box.get().direction() == primaryDirection {
          if !previousBox.bool() {
            let logicalStart =
              primaryDirection == .LTR
              ? firstLeafOnLineInLogicalOrderWithNode(box.get().lineBox(), &orderCache)
              : InlineIterator.lastLeafOnLineInLogicalOrderWithNode(box.get().lineBox(), orderCache)
            if logicalStart.bool() {
              box = logicalStart
              renderer = box.get().renderer()
              offset =
                primaryDirection == .LTR
                ? box.get().minimumCaretOffset() : box.get().maximumCaretOffset()
            }
            break
          }
          if Int32(previousBox.get().bidiLevel()) >= Int32(level) {
            break
          }
          level = previousBox.get().bidiLevel()
          let nextBox = box
          repeat {
            nextBox.traverseNextOnLine()
          } while nextBox.bool() && Int32(nextBox.get().bidiLevel()) > Int32(level)
          if nextBox.bool() && Int32(nextBox.get().bidiLevel()) == Int32(level) {
            break
          }
          box = previousBox
          renderer = box.get().renderer()
          offset = box.get().rightmostCaretOffset()
          if box.get().direction() == primaryDirection {
            break
          }
          continue
        }
        while previousBox.bool() && previousBox.get().renderer().node() == nil {
          previousBox.traversePreviousOnLine()
        }
        if previousBox.bool() {
          box = previousBox
          renderer = box.get().renderer()
          offset = box.get().rightmostCaretOffset()
          if Int32(box.get().bidiLevel()) > Int32(level) {
            repeat {
              previousBox = previousBox.traversePreviousOnLine()
            } while previousBox.bool() && Int32(previousBox.get().bidiLevel()) > Int32(level)
            if !previousBox.bool() || Int32(previousBox.get().bidiLevel()) < Int32(level) {
              continue
            }
          }
        } else {
          // Trailing edge of a secondary box. Set to the leading edge of the entire box.
          while true {
            while true {
              let nextBox = box.get().nextOnLine()
              if !nextBox.bool() {
                break
              }
              if Int32(nextBox.get().bidiLevel()) < Int32(level) {
                break
              }
              box = nextBox
            }
            if Int32(box.get().bidiLevel()) == Int32(level) {
              break
            }
            level = box.get().bidiLevel()
            while true {
              let previousBox = box.get().previousOnLine()
              if !previousBox.bool() {
                break
              }
              if Int32(previousBox.get().bidiLevel()) < Int32(level) {
                break
              }
              box = previousBox
            }
            if Int32(box.get().bidiLevel()) == Int32(level) {
              break
            }
            level = box.get().bidiLevel()
          }
          renderer = box.get().renderer()
          offset =
            primaryDirection == .LTR
            ? box.get().minimumCaretOffset() : box.get().maximumCaretOffset()
        }
        break
      }
      p = makeDeprecatedLegacyPosition(renderer!.protectedNode(), offset)
      if (p.isCandidate() && p.downstream() != downstreamStart) || p.atStartOfTree()
        || p.atEndOfTree()
      {
        return p
      }
      assert(p != deepPosition)
    }
  }

  func left(stayInEditableContent: Bool = false, reachedBoundary: inout Bool?) -> VisiblePosition {
    if reachedBoundary != nil {
      reachedBoundary! = false
    }
    let pos = leftVisuallyDistinctCandidate()
    // FIXME: Why can't we move left from the last position in a tree?
    if pos.atStartOfTree() || pos.atEndOfTree() {
      if reachedBoundary != nil {
        reachedBoundary! = true
      }
      return VisiblePosition()
    }
    let left = VisiblePosition(pos)
    assert(left != self)
    if !stayInEditableContent {
      return left
    }
    return directionOfEnclosingBlock(position: left.deepEquivalent()) == .LTR
      ? honorEditingBoundaryAtOrBefore(position: left, reachedBoundary: &reachedBoundary)
      : honorEditingBoundaryAtOrAfter(otherPosition: left, reachedBoundary: &reachedBoundary)
  }

  func left(stayInEditableContent: Bool = false) -> VisiblePosition {
    var ignored: Bool? = nil
    return left(stayInEditableContent: stayInEditableContent, reachedBoundary: &ignored)
  }

  func rightVisuallyDistinctCandidate() -> Position {
    var p = deepPosition
    if p.isNull() {
      return Position()
    }
    let downstreamStart = p.downstream()
    let primaryDirection = p.primaryDirection()
    var orderCache = InlineIterator.LineLogicalOrderCache()
    while true {
      let decomposed = p.inlineBoxAndOffset(
        affinity: m_affinity, primaryDirection: primaryDirection)
      var box = decomposed.box
      var offset = decomposed.offset
      if !box.bool() {
        return primaryDirection == .LTR
          ? nextVisuallyDistinctCandidate(position: deepPosition)
          : previousVisuallyDistinctCandidate(position: deepPosition)
      }
      var renderer: RenderObjectWrapper? = box.get().renderer()
      while true {
        if (renderer!.isReplacedOrInlineBlock() || renderer!.isBRForRenderObject())
          && offset == box.get().leftmostCaretOffset()
        {
          return box.get().isLeftToRightDirection()
            ? nextVisuallyDistinctCandidate(position: deepPosition)
            : previousVisuallyDistinctCandidate(position: deepPosition)
        }
        if renderer!.node() == nil {
          box.traverseNextOnLine()
          if !box.bool() {
            return primaryDirection == .LTR
              ? nextVisuallyDistinctCandidate(position: deepPosition)
              : previousVisuallyDistinctCandidate(position: deepPosition)
          }
          renderer = box.get().renderer()
          offset = box.get().leftmostCaretOffset()
          continue
        }
        // Note that this may underflow the (unsigned) offset. This is fine and handled below.
        offset = UInt32(
          box.get().isLeftToRightDirection()
            ? renderer!.nextOffset(Int32(offset)) : renderer!.previousOffset(Int32(offset)))
        let caretMinOffset: UInt32 = box.get().minimumCaretOffset()
        let caretMaxOffset: UInt32 = box.get().maximumCaretOffset()
        if offset > caretMinOffset && offset < caretMaxOffset {
          break
        }
        if offset != box.get().rightmostCaretOffset() {
          // Overshot to the right.
          let nextBox = box.get().nextOnLineIgnoringLineBreak()
          if !nextBox.bool() {
            let positionOnRight =
              primaryDirection == .LTR
              ? nextVisuallyDistinctCandidate(position: deepPosition)
              : previousVisuallyDistinctCandidate(position: deepPosition)
            let boxOnRight = positionOnRight.inlineBoxAndOffset(
              affinity: m_affinity, primaryDirection: primaryDirection
            ).box
            if boxOnRight.bool() && boxOnRight.get().lineBox() == box.get().lineBox() {
              return Position()
            }
            return positionOnRight
          }
          // Reposition at the other logical position corresponding to our edge's visual position and go for another round.
          box = nextBox
          renderer = box.get().renderer()
          offset = nextBox.get().leftmostCaretOffset()
          continue
        }
        var level: UInt8 = box.get().bidiLevel()
        let nextBox = box.get().nextOnLine()
        if box.get().direction() == primaryDirection {
          if !nextBox.bool() {
            let logicalEnd =
              primaryDirection == .LTR
              ? InlineIterator.lastLeafOnLineInLogicalOrderWithNode(box.get().lineBox(), orderCache)
              : firstLeafOnLineInLogicalOrderWithNode(box.get().lineBox(), &orderCache)
            if logicalEnd.bool() {
              box = logicalEnd
              renderer = box.get().renderer()
              offset =
                primaryDirection == .LTR
                ? box.get().maximumCaretOffset() : box.get().minimumCaretOffset()
            }
            break
          }
          if Int32(nextBox.get().bidiLevel()) >= Int32(level) {
            break
          }
          level = nextBox.get().bidiLevel()
          let previousBox = box
          repeat {
            previousBox.traversePreviousOnLine()
          } while previousBox.bool() && Int32(previousBox.get().bidiLevel()) > Int32(level)
          if previousBox.bool() && Int32(previousBox.get().bidiLevel()) == Int32(level) {
            break
          }
          // For example, abc 123 ^ CBA or 123 ^ CBA abc
          box = nextBox
          renderer = box.get().renderer()
          offset = box.get().leftmostCaretOffset()
          if box.get().direction() == primaryDirection {
            break
          }
          continue
        }
        while nextBox.bool() && nextBox.get().renderer().node() == nil {
          nextBox.traverseNextOnLine()
        }
        if nextBox.bool() {
          box = nextBox
          renderer = box.get().renderer()
          offset = box.get().leftmostCaretOffset()
          if Int32(box.get().bidiLevel()) > Int32(level) {
            repeat {
              nextBox.traverseNextOnLine()
            } while nextBox.bool() && Int32(nextBox.get().bidiLevel()) > Int32(level)
            if !nextBox.bool() || Int32(nextBox.get().bidiLevel()) < Int32(level) {
              continue
            }
          }
        } else {
          // Trailing edge of a secondary box. Set to the leading edge of the entire box.
          while true {
            while true {
              let previousBox = box.get().previousOnLine()
              if !previousBox.bool() {
                break
              }
              if Int32(previousBox.get().bidiLevel()) < Int32(level) {
                break
              }
              box = previousBox
            }
            if Int32(box.get().bidiLevel()) == Int32(level) {
              break
            }
            level = box.get().bidiLevel()
            while true {
              let nextBox = box.get().nextOnLine()
              if !nextBox.bool() {
                break
              }
              if Int32(nextBox.get().bidiLevel()) < Int32(level) {
                break
              }
              box = nextBox
            }
            if Int32(box.get().bidiLevel()) == Int32(level) {
              break
            }
            level = box.get().bidiLevel()
          }
          renderer = box.get().renderer()
          offset =
            primaryDirection == .LTR
            ? box.get().maximumCaretOffset() : box.get().minimumCaretOffset()
        }
        break
      }
      p = makeDeprecatedLegacyPosition(renderer!.protectedNode(), offset)
      if (p.isCandidate() && p.downstream() != downstreamStart) || p.atStartOfTree()
        || p.atEndOfTree()
      {
        return p
      }
      assert(p != deepPosition)
    }
  }

  func right(stayInEditableContent: Bool = false, reachedBoundary: inout Bool?) -> VisiblePosition {
    if reachedBoundary != nil {
      reachedBoundary! = false
    }
    let pos = rightVisuallyDistinctCandidate()
    // FIXME: Why can't we move left from the last position in a tree?
    if pos.atStartOfTree() || pos.atEndOfTree() {
      if reachedBoundary != nil {
        reachedBoundary! = true
      }
      return VisiblePosition()
    }
    let right = VisiblePosition(pos)
    assert(right != self)
    if !stayInEditableContent {
      return right
    }
    return directionOfEnclosingBlock(position: right.deepEquivalent()) == .LTR
      ? honorEditingBoundaryAtOrAfter(otherPosition: right, reachedBoundary: &reachedBoundary)
      : honorEditingBoundaryAtOrBefore(position: right, reachedBoundary: &reachedBoundary)
  }

  func right(stayInEditableContent: Bool = false) -> VisiblePosition {
    var ignored: Bool? = nil
    return right(stayInEditableContent: stayInEditableContent, reachedBoundary: &ignored)
  }

  func honorEditingBoundaryAtOrBefore(position: VisiblePosition, reachedBoundary: inout Bool?)
    -> VisiblePosition
  {
    if reachedBoundary != nil {
      reachedBoundary! = false
    }
    if position.isNull() {
      return position
    }
    let highestRoot: ContainerNodeWrapper? = highestEditableRoot(position: deepEquivalent())
    // Return empty position if pos is not somewhere inside the editable region containing this position
    if highestRoot != nil
      && !(position.deepEquivalent().protectedDeprecatedNode()!.isDescendantOf(highestRoot!))
    {
      if reachedBoundary != nil {
        reachedBoundary! = true
      }
      return VisiblePosition()
    }
    // Return position itself if the two are from the very same editable region, or both are non-editable
    // FIXME: In the non-editable case, just because the new position is non-editable doesn't mean movement
    // to it is allowed.  VisibleSelection::adjustForEditableContent has this problem too.
    if CPtrToInt(highestEditableRoot(position: position.deepEquivalent())?.p)
      == CPtrToInt(highestRoot?.p)
    {
      if reachedBoundary != nil {
        reachedBoundary! = self == position
      }
      return position
    }
    // Return empty position if this position is non-editable, but pos is editable
    // FIXME: Move to the previous non-editable region.
    if highestRoot == nil {
      if reachedBoundary != nil {
        reachedBoundary! = true
      }
      return VisiblePosition()
    }
    // Return the last position before pos that is in the same editable region as this position
    return VisiblePosition(
      lastEditablePositionBeforePositionInRoot(
        position: position.deepEquivalent(), highestRoot: highestRoot))
    // Return the last position before pos that is in the same editable region as this position
  }

  func honorEditingBoundaryAtOrBefore(position: VisiblePosition) -> VisiblePosition {
    var ignored: Bool? = nil
    return honorEditingBoundaryAtOrBefore(position: position, reachedBoundary: &ignored)
  }

  func honorEditingBoundaryAtOrAfter(otherPosition: VisiblePosition, reachedBoundary: inout Bool?)
    -> VisiblePosition
  {
    if reachedBoundary != nil {
      reachedBoundary! = false
    }
    if otherPosition.isNull() {
      return otherPosition
    }
    let highestRoot: ContainerNodeWrapper? = highestEditableRoot(position: deepEquivalent())
    // Return empty position if otherPosition is not somewhere inside the editable region containing this position
    if highestRoot != nil
      && !(otherPosition.deepEquivalent().protectedDeprecatedNode()!.isDescendantOf(highestRoot!))
    {
      if reachedBoundary != nil {
        reachedBoundary! = true
      }
      return VisiblePosition()
    }
    // Return otherPosition itself if the two are from the very same editable region, or both are non-editable
    // FIXME: In the non-editable case, just because the new position is non-editable doesn't mean movement
    // to it is allowed.  VisibleSelection::adjustForEditableContent has this problem too.
    if CPtrToInt(highestEditableRoot(position: otherPosition.deepEquivalent())?.p)
      == CPtrToInt(highestRoot?.p)
    {
      if reachedBoundary != nil {
        reachedBoundary! = self == otherPosition
      }
      return otherPosition
    }
    // Return empty position if this position is non-editable, but otherPosition is editable
    // FIXME: Move to the next non-editable region.
    if highestRoot == nil {
      if reachedBoundary != nil {
        reachedBoundary! = true
      }
      return VisiblePosition()
    }
    // Return the next position after pos that is in the same editable region as this position
    return VisiblePosition(
      firstEditablePositionAfterPositionInRoot(
        position: otherPosition.deepEquivalent(), highestRoot: highestRoot))
    // Return the next position after pos that is in the same editable region as this position
  }

  func honorEditingBoundaryAtOrAfter(otherPosition: VisiblePosition) -> VisiblePosition {
    var ignored: Bool? = nil
    return honorEditingBoundaryAtOrAfter(otherPosition: otherPosition, reachedBoundary: &ignored)
  }

  static func canonicalPosition(passedPosition: Position) -> Position {
    // The updateLayout call below can do so much that even the position passed
    // in to us might get changed as a side effect. Specifically, there are code
    // paths that pass selection endpoints, and updateLayout can change the selection.
    let position = passedPosition
    // FIXME (9535):  Canonicalizing to the leftmost candidate means that if we're at a line wrap, we will
    // ask renderers to paint downstream carets for other renderers.
    // To fix this, we need to either a) add code to all paintCarets to pass the responsibility off to
    // the appropriate renderer for VisiblePosition's like these, or b) canonicalize to the rightmost candidate
    // unless the affinity is upstream.
    if position.isNull() {
      return Position()
    }
    assert(position.document() != nil)
    position.document()!.updateLayoutIgnorePendingStylesheets()
    let node: NodeWrapper? = position.containerNode()
    var candidate = position.upstream()
    if candidate.isCandidate() {
      return candidate
    }
    candidate = position.downstream()
    if candidate.isCandidate() {
      return candidate
    }
    // When neither upstream or downstream gets us to a candidate (upstream/downstream won't leave
    // blocks or enter new ones), we search forward and backward until we find one.
    let next = canonicalizeCandidate(candidate: nextCandidate(position: position))
    let prev = canonicalizeCandidate(candidate: previousCandidate(position: position))
    let nextNode: NodeWrapper? = next.protectedDeprecatedNode()
    let prevNode: NodeWrapper? = prev.protectedDeprecatedNode()
    // The new position must be in the same editable element. Enforce that first.
    // Unless the descent is from a non-editable html element to an editable body.
    if node is HTMLHtmlElement && !node!.hasEditableStyle() {
      let body: HTMLElementWrapper? = node!.document().bodyOrFrameset()
      if body != nil && body!.hasEditableStyle() {
        return next.isNotNull() ? next : prev
      }
    }
    let editingRoot: ElementWrapper? = editableRootForPosition(position: position)
    // If the html element is editable, descending into its body will look like a descent
    // from non-editable to editable content since rootEditableElement() always stops at the body.
    if (editingRoot != nil && editingRoot!.hasHtmlTagName())
      || (node != nil && (node!.isDocumentNode() || node!.isShadowRoot()))
    {
      return next.isNotNull() ? next : prev
    }
    let prevIsInSameEditableElement: Bool =
      prevNode != nil
      && CPtrToInt(editableRootForPosition(position: prev)?.p) == CPtrToInt(editingRoot?.p)
    let nextIsInSameEditableElement: Bool =
      nextNode != nil
      && CPtrToInt(editableRootForPosition(position: next)?.p) == CPtrToInt(editingRoot?.p)
    if prevIsInSameEditableElement && !nextIsInSameEditableElement {
      return prev
    }
    if nextIsInSameEditableElement && !prevIsInSameEditableElement {
      return next
    }
    if !nextIsInSameEditableElement && !prevIsInSameEditableElement {
      return Position()
    }
    // The new position should be in the same block flow element. Favor that.
    let originalBlock: ElementWrapper? = deprecatedEnclosingBlockFlowElement(node: node)
    let nextIsOutsideOriginalBlock: Bool =
      !nextNode!.isDescendantOf(originalBlock)
      && CPtrToInt(nextNode?.p) != CPtrToInt(originalBlock?.p)
    let prevIsOutsideOriginalBlock: Bool =
      !prevNode!.isDescendantOf(originalBlock)
      && CPtrToInt(prevNode?.p) != CPtrToInt(originalBlock?.p)
    if nextIsOutsideOriginalBlock && !prevIsOutsideOriginalBlock {
      return prev
    }
    return next
  }

  func characterAfter() -> UInt32 {
    fatalError("Not implemented")
  }

  func inlineBoxAndOffset() -> InlineBoxAndOffset {
    return deepPosition.inlineBoxAndOffset(affinity: m_affinity)
  }

  func inlineBoxAndOffset(primaryDirection: TextDirection) -> InlineBoxAndOffset {
    return deepPosition.inlineBoxAndOffset(affinity: m_affinity, primaryDirection: primaryDirection)
  }

  func localCaretRect() -> LocalCaretRect {
    let node: NodeWrapper? = deepPosition.anchorNode()
    if node == nil {
      return LocalCaretRect(rect: LayoutRectWrapper())
    }
    let boxAndOffset = inlineBoxAndOffset()
    let renderer: RenderObjectWrapper? =
      boxAndOffset.box.bool() ? boxAndOffset.box.get().renderer() : node!.renderer()
    if renderer == nil {
      return LocalCaretRect(rect: LayoutRectWrapper())
    }
    return LocalCaretRect(
      rect: computeLocalCaretRect(renderer: renderer!, boxAndOffset: boxAndOffset),
      renderer: renderer)
  }

  func absoluteCaretBounds(insideFixed: inout Bool?) -> IntRect {
    var renderer: RenderBlockWrapper? = nil
    let localRect = localCaretRectInRendererForCaretPainting(
      caretPosition: self, caretPainter: &renderer)
    return absoluteBoundsForLocalCaretRect(
      rendererForCaretPainting: renderer, rect: localRect, insideFixed: &insideFixed)
  }

  func absoluteCaretBounds() -> IntRect {
    var ignored: Bool? = nil
    return absoluteCaretBounds(insideFixed: &ignored)
  }

  func absoluteSelectionBoundsForLine() -> FloatRectWrapper {
    let box = inlineBoxAndOffset().box
    if !box.bool() {
      return FloatRectWrapper()
    }
    let line = box.get().lineBox()
    var ignored: Bool? = nil
    return line.get().formattingContextRoot().localToAbsoluteQuad(
      FloatQuad(inRect: LineSelection.physicalRect(lineBox: line.get())), [.UseTransforms], &ignored
    ).boundingBox()
  }

  func lineDirectionPointForBlockDirectionNavigation() -> Int32 {
    let localRect = localCaretRect()
    if localRect.rect.isEmpty() || localRect.renderer == nil {
      return 0
    }
    // This ignores transforms on purpose, for now. Vertical navigation is done
    // without consulting transforms, so that 'up' in transformed text is 'up'
    // relative to the text, not absolute 'up'.
    let renderer: RenderObjectWrapper? = localRect.renderer
    let caretPoint = renderer!.localToAbsolute(localPoint: localRect.rect.location().FloatPoint())
    var containingBlock: RenderObjectWrapper? = renderer!.containingBlock()
    if containingBlock == nil {
      containingBlock = renderer
    }
    // Just use ourselves to determine the writing mode if we have no containing block.
    return Int32(containingBlock!.isHorizontalWritingMode() ? caretPoint.x : caretPoint.y)
    // Just use ourselves to determine the writing mode if we have no containing block.
  }

  func equals(other: VisiblePosition) -> Bool {
    return m_affinity == other.m_affinity && deepPosition.equals(other: other.deepPosition)
  }

  static func == (a: VisiblePosition, b: VisiblePosition) -> Bool {
    // FIXME: Is it correct and helpful for this to be ignoring differences in affinity?
    return a.deepEquivalent() == b.deepEquivalent()
    // FIXME: Is it correct and helpful for this to be ignoring differences in affinity?
  }

  static func < (a: VisiblePosition, b: VisiblePosition) -> Bool {
    return is_lt(documentOrder(a: a, b: b))
  }

  static func > (a: VisiblePosition, b: VisiblePosition) -> Bool {
    return is_gt(documentOrder(a: a, b: b))
  }

  static func <= (a: VisiblePosition, b: VisiblePosition) -> Bool {
    return is_lteq(documentOrder(a: a, b: b))
  }

  static func >= (a: VisiblePosition, b: VisiblePosition) -> Bool {
    return is_gteq(documentOrder(a: a, b: b))
  }

  static let defaultAffinity: Affinity = .Downstream
  private var deepPosition: Position = Position()
  private var m_affinity: Affinity = VisiblePosition.defaultAffinity
}

// A visible position from C++ is already canonical, so it is not canonicalized again; see
// editing/EditingScion.h. The stored properties are private, as in C++.
extension VisiblePosition {
  init(raw: VisiblePositionRaw) {
    self.deepPosition = Position(raw: raw.deepPosition)
    self.m_affinity = raw.affinity != 0 ? .Downstream : .Upstream
  }
}

extension VisiblePosition: Equatable {}

func canonicalizeCandidate(candidate: Position) -> Position {
  if candidate.isNull() {
    return Position()
  }
  assert(candidate.isCandidate())
  let upstream = candidate.upstream()
  if upstream.isCandidate() {
    return upstream
  }
  return candidate
}

func enclosingBlockFlowElement(visiblePosition: VisiblePosition) -> ElementWrapper? {
  if visiblePosition.isNull() {
    return nil
  }
  return deprecatedEnclosingBlockFlowElement(
    node: visiblePosition.deepEquivalent().protectedDeprecatedNode())
}

func isFirstVisiblePositionInNode(visiblePosition: VisiblePosition, node: NodeWrapper?) -> Bool {
  if visiblePosition.isNull() {
    return false
  }
  if !(visiblePosition.deepEquivalent().protectedContainerNode()!.isDescendantOf(node)) {
    return false
  }
  let previous = visiblePosition.previous()
  return previous.isNull()
    || !(previous.deepEquivalent().protectedDeprecatedNode()!.isDescendantOf(node))
}

func isLastVisiblePositionInNode(visiblePosition: VisiblePosition, node: NodeWrapper?) -> Bool {
  if visiblePosition.isNull() {
    return false
  }
  if !(visiblePosition.deepEquivalent().protectedContainerNode()!.isDescendantOf(node)) {
    return false
  }
  let next = visiblePosition.next()
  return next.isNull() || !(next.deepEquivalent().protectedDeprecatedNode()!.isDescendantOf(node))
}

func areVisiblePositionsInSameTreeScope(a: VisiblePosition, b: VisiblePosition) -> Bool {
  return connectedInSameTreeScope(
    a.deepEquivalent().protectedAnchorNode(), b.deepEquivalent().protectedAnchorNode())
}

func makeBoundaryPoint(position: VisiblePosition) -> BoundaryPoint? {
  return makeBoundaryPoint(position: position.deepEquivalent())
}

func commonInclusiveAncestor(a: VisiblePosition, b: VisiblePosition) -> NodeWrapper? {
  return commonInclusiveAncestor(a: a.deepEquivalent(), b: b.deepEquivalent())
}

func makeSimpleRange(range: VisiblePositionRange) -> SimpleRange? {
  fatalError("Not implemented")
}

func makeVisiblePositionRange(range: SimpleRange?) -> VisiblePositionRange {
  if range == nil {
    return VisiblePositionRange(start: VisiblePosition(), end: VisiblePosition())
  }
  return VisiblePositionRange(
    start: VisiblePosition(makeContainerOffsetPosition(point: range!.start)),
    end: VisiblePosition(makeContainerOffsetPosition(point: range!.end)))
}

func documentOrder(a: VisiblePosition, b: VisiblePosition) -> PartialOrdering {
  fatalError("Not implemented")
}

func intersects(a: VisiblePositionRange, b: VisiblePositionRange) -> Bool {
  return a.start <= b.end && b.start <= a.end
}

func contains(range: VisiblePositionRange, point: VisiblePosition) -> Bool {
  return point >= range.start && point <= range.end
}

func intersection(a: VisiblePositionRange, b: VisiblePositionRange) -> VisiblePositionRange {
  fatalError("Not implemented")
}

func commonInclusiveAncestor(range: VisiblePositionRange) -> NodeWrapper? {
  return commonInclusiveAncestor(a: range.start, b: range.end)
}

func midpoint(range: VisiblePositionRange) -> VisiblePosition {
  fatalError("Not implemented")
}
