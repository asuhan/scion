/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

struct RenderedPosition {
  func isNull() -> Bool {
    return renderer == nil
  }

  func lineBox() -> InlineIterator.LineBoxIterator {
    return box.bool() ? box.get().lineBox() : InlineIterator.LineBoxIterator()
  }

  mutating func atLeftBoundaryOfBidiRun() -> Bool {
    return atLeftBoundaryOfBidiRun(shouldMatchBidiLevel: .IgnoreBidiLevel, bidiLevelOfRun: 0)
  }

  mutating func atRightBoundaryOfBidiRun() -> Bool {
    return atRightBoundaryOfBidiRun(shouldMatchBidiLevel: .IgnoreBidiLevel, bidiLevelOfRun: 0)
  }

  mutating func atLeftBoundaryOfBidiRun(bidiLevelOfRun: UInt8) -> Bool {
    return atLeftBoundaryOfBidiRun(
      shouldMatchBidiLevel: .MatchBidiLevel, bidiLevelOfRun: bidiLevelOfRun)
  }

  mutating func atRightBoundaryOfBidiRun(bidiLevelOfRun: UInt8) -> Bool {
    return atRightBoundaryOfBidiRun(
      shouldMatchBidiLevel: .MatchBidiLevel, bidiLevelOfRun: bidiLevelOfRun)
  }

  // TRANSLATE-REVIEW: operator operator== has no rule

  func atLeftmostOffsetInBox() -> Bool {
    return box.bool() && offset == box.get().leftmostCaretOffset()
  }

  func atRightmostOffsetInBox() -> Bool {
    return box.bool() && offset == box.get().rightmostCaretOffset()
  }

  init() {
    self.renderer = nil
    self.box = InlineIterator.LeafBoxIterator()
    self.m_previousLeafOnLine = nil
    self.m_nextLeafOnLine = nil
  }

  init(renderer: RenderObjectWrapper?, box: InlineIterator.LeafBoxIterator, offset: UInt32) {
    self.renderer = renderer
    self.box = box
    self.offset = offset
    self.m_previousLeafOnLine = nil
    self.m_nextLeafOnLine = nil
  }

  init(position: VisiblePosition) {
    self.init(position: position.deepEquivalent(), affinity: position.affinity())
  }

  init(position: Position, affinity: Affinity) {
    self.renderer = nil
    self.box = InlineIterator.LeafBoxIterator()
    self.m_previousLeafOnLine = nil
    self.m_nextLeafOnLine = nil
    if position.isNull() {
      return
    }
    let boxAndOffset = position.inlineBoxAndOffset(affinity: affinity)
    box = boxAndOffset.box
    offset = boxAndOffset.offset
    if box.bool() {
      renderer = box.get().renderer()
    } else {
      renderer = rendererFromPosition(position: position)
    }
  }

  mutating func previousLeafOnLine() -> InlineIterator.LeafBoxIterator {
    if m_previousLeafOnLine == nil {
      m_previousLeafOnLine = box.get().previousOnLineIgnoringLineBreak()
    }
    return m_previousLeafOnLine!
  }

  mutating func nextLeafOnLine() -> InlineIterator.LeafBoxIterator {
    if m_nextLeafOnLine == nil {
      m_nextLeafOnLine = box.get().nextOnLineIgnoringLineBreak()
    }
    return m_nextLeafOnLine!
  }

  mutating func isEquivalent(other: RenderedPosition) -> Bool {
    return
      (CPtrToInt(renderer?.id()) == CPtrToInt(other.renderer?.id()) && box == other.box
      && offset == other.offset)
      || (atLeftmostOffsetInBox() && other.atRightmostOffsetInBox()
        && previousLeafOnLine() == other.box)
      || (atRightmostOffsetInBox() && other.atLeftmostOffsetInBox()
        && nextLeafOnLine() == other.box)
  }

  mutating func bidiLevelOnLeft() -> UInt8 {
    let box = atLeftmostOffsetInBox() ? previousLeafOnLine() : self.box
    return UInt8(box.bool() ? Int32(box.get().bidiLevel()) : 0)
  }

  mutating func bidiLevelOnRight() -> UInt8 {
    let box = atRightmostOffsetInBox() ? nextLeafOnLine() : self.box
    return UInt8(box.bool() ? Int32(box.get().bidiLevel()) : 0)
  }

  mutating func leftBoundaryOfBidiRun(bidiLevelOfRun: UInt8) -> RenderedPosition {
    if !box.bool() || Int32(bidiLevelOfRun) > Int32(box.get().bidiLevel()) {
      return RenderedPosition()
    }
    var box = self.box
    repeat {
      let prev = box.get().previousOnLineIgnoringLineBreak()
      if !prev.bool() || Int32(prev.get().bidiLevel()) < Int32(bidiLevelOfRun) {
        return RenderedPosition(
          renderer: box.get().renderer(), box: box, offset: box.get().leftmostCaretOffset())
      }
      box = prev
    } while box.bool()
    assertionFailure()
    return RenderedPosition()
  }

  mutating func rightBoundaryOfBidiRun(bidiLevelOfRun: UInt8) -> RenderedPosition {
    if !box.bool() || Int32(bidiLevelOfRun) > Int32(box.get().bidiLevel()) {
      return RenderedPosition()
    }
    var box = self.box
    repeat {
      let next = box.get().nextOnLineIgnoringLineBreak()
      if !next.bool() || Int32(next.get().bidiLevel()) < Int32(bidiLevelOfRun) {
        return RenderedPosition(
          renderer: box.get().renderer(), box: box, offset: box.get().rightmostCaretOffset())
      }
      box = next
    } while box.bool()
    assertionFailure()
    return RenderedPosition()
  }

  mutating func atLeftBoundaryOfBidiRun(
    shouldMatchBidiLevel: ShouldMatchBidiLevel, bidiLevelOfRun: UInt8
  ) -> Bool {
    if !box.bool() {
      return false
    }
    if atLeftmostOffsetInBox() {
      if shouldMatchBidiLevel == .IgnoreBidiLevel {
        return !previousLeafOnLine().bool()
          || Int32(previousLeafOnLine().get().bidiLevel()) < Int32(box.get().bidiLevel())
      }
      return Int32(box.get().bidiLevel()) >= Int32(bidiLevelOfRun)
        && (!previousLeafOnLine().bool()
          || Int32(previousLeafOnLine().get().bidiLevel()) < Int32(bidiLevelOfRun))
    }
    if atRightmostOffsetInBox() {
      if shouldMatchBidiLevel == .IgnoreBidiLevel {
        return nextLeafOnLine().bool()
          && Int32(box.get().bidiLevel()) < Int32(nextLeafOnLine().get().bidiLevel())
      }
      return nextLeafOnLine().bool() && Int32(box.get().bidiLevel()) < Int32(bidiLevelOfRun)
        && Int32(nextLeafOnLine().get().bidiLevel()) >= Int32(bidiLevelOfRun)
    }
    return false
  }

  mutating func atRightBoundaryOfBidiRun(
    shouldMatchBidiLevel: ShouldMatchBidiLevel, bidiLevelOfRun: UInt8
  ) -> Bool {
    if !box.bool() {
      return false
    }
    if atRightmostOffsetInBox() {
      if shouldMatchBidiLevel == .IgnoreBidiLevel {
        return !nextLeafOnLine().bool()
          || Int32(nextLeafOnLine().get().bidiLevel()) < Int32(box.get().bidiLevel())
      }
      return Int32(box.get().bidiLevel()) >= Int32(bidiLevelOfRun)
        && (!nextLeafOnLine().bool()
          || Int32(nextLeafOnLine().get().bidiLevel()) < Int32(bidiLevelOfRun))
    }
    if atLeftmostOffsetInBox() {
      if shouldMatchBidiLevel == .IgnoreBidiLevel {
        return previousLeafOnLine().bool()
          && Int32(box.get().bidiLevel()) < Int32(previousLeafOnLine().get().bidiLevel())
      }
      return previousLeafOnLine().bool() && Int32(box.get().bidiLevel()) < Int32(bidiLevelOfRun)
        && Int32(previousLeafOnLine().get().bidiLevel()) >= Int32(bidiLevelOfRun)
    }
    return false
  }

  mutating func positionAtLeftBoundaryOfBiDiRun() -> Position {
    assert(atLeftBoundaryOfBidiRun())
    if atLeftmostOffsetInBox() {
      return makeDeprecatedLegacyPosition(renderer!.protectedNode(), offset)
    }
    return makeDeprecatedLegacyPosition(
      nextLeafOnLine().get().renderer().protectedNode(),
      nextLeafOnLine().get().leftmostCaretOffset())
  }

  mutating func positionAtRightBoundaryOfBiDiRun() -> Position {
    assert(atRightBoundaryOfBidiRun())
    if atRightmostOffsetInBox() {
      return makeDeprecatedLegacyPosition(renderer!.protectedNode(), offset)
    }
    return makeDeprecatedLegacyPosition(
      previousLeafOnLine().get().renderer().protectedNode(),
      previousLeafOnLine().get().rightmostCaretOffset())
  }

  func absoluteRect(caretRectMode: CaretRectMode = .Normal) -> IntRect {
    if isNull() {
      return IntRect()
    }
    let localRect = snappedIntRect(
      rect: computeLocalCaretRect(
        renderer: renderer!, boxAndOffset: InlineBoxAndOffset(box: box, offset: offset),
        caretRectMode: caretRectMode))
    var ignored: Bool? = nil
    return localRect == IntRect()
      ? IntRect()
      : renderer!.localToAbsoluteQuad(
        FloatQuad(inRect: FloatRectWrapper(r: localRect)), [.UseTransforms], &ignored
      ).enclosingBoundingBox()
  }

  private var renderer: RenderObjectWrapper? = nil
  private var box: InlineIterator.LeafBoxIterator
  private var offset: UInt32 = 0
  private var m_previousLeafOnLine: InlineIterator.LeafBoxIterator? = nil
  private var m_nextLeafOnLine: InlineIterator.LeafBoxIterator? = nil
}

private func rendererFromPosition(position: Position) -> RenderObjectWrapper? {
  assert(position.isNotNull())
  var rendererNode: NodeWrapper? = nil
  switch position.anchorType() {
  case .PositionIsOffsetInAnchor:
    rendererNode = position.computeNodeAfterPosition()
    if rendererNode == nil || rendererNode!.renderer() == nil {
      rendererNode = position.anchorNode()!.lastChild()
    }
    break
  case .PositionIsBeforeAnchor, .PositionIsAfterAnchor:
    break
  case .PositionIsBeforeChildren:
    rendererNode = position.anchorNode()!.firstChild()
    break
  case .PositionIsAfterChildren:
    rendererNode = position.anchorNode()!.lastChild()
    break
  }
  if rendererNode == nil || rendererNode!.renderer() == nil {
    rendererNode = position.anchorNode()
  }
  return rendererNode!.renderer()
}

func renderObjectContainsPosition(target: RenderObjectWrapper?, position: Position) -> Bool {
  var renderer: RenderObjectWrapper? = rendererFromPosition(position: position)
  while renderer != nil && renderer!.node() != nil {
    if CPtrToInt(renderer?.id()) == CPtrToInt(target?.id()) {
      return true
    }
    renderer = renderer!.parent()
  }
  return false
}
