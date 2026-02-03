/*
 * Copyright (C) 2014 Igalia S.L.
 * Copyright (C) 2015-2017 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER “AS IS” AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

private func rendererAfterOffset(_ renderer: RenderObjectWrapper, _ offset: UInt32)
  -> RenderObjectWrapper?
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

struct RenderRange {
  init() {
    self.init(start: nil, end: nil, startOffset: 0, endOffset: 0)
  }

  init(
    start: RenderObjectWrapper?, end: RenderObjectWrapper?, startOffset: UInt32, endOffset: UInt32
  ) {
    self.start = start
    self.end = end
    self.startOffset = startOffset
    self.endOffset = endOffset
  }

  let start: RenderObjectWrapper?
  let end: RenderObjectWrapper?
  let startOffset: UInt32
  let endOffset: UInt32
}

struct RenderRangeIterator {
  init(_ start: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func next() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

class RenderHighlight {
  func setRenderRange(_ renderRange: RenderRange) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setRenderRange(highlightRange: HighlightRangeWrapper) -> Bool {  // Returns true if successful.
    if highlightRange.startPosition.isNull() || highlightRange.endPosition.isNull() {
      return false
    }

    let startPosition = highlightRange.startPosition
    let endPosition = highlightRange.endPosition

    if startPosition.containerNode() == nil || endPosition.containerNode() == nil {
      return false
    }

    let startRenderer = startPosition.containerNode()!.renderer()
    let endRenderer = endPosition.containerNode()!.renderer()

    if startRenderer == nil || endRenderer == nil {
      return false
    }

    let startOffset = UInt32(startPosition.computeOffsetInContainerNode())
    let endOffset = UInt32(endPosition.computeOffsetInContainerNode())

    setRenderRange(
      RenderRange(
        start: startRenderer, end: endRenderer, startOffset: startOffset, endOffset: endOffset))
    return true
  }

  func start() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func end() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func startOffset() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endOffset() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func highlightStateForRenderer(_ renderer: RenderObjectWrapper)
    -> RenderObjectWrapper.HighlightState
  {
    if isSelection {
      return renderer.selectionState()
    }

    if CPtrToInt(renderer.p) == CPtrToInt(renderRange.start?.p) {
      if renderRange.start != nil && renderRange.end != nil
        && CPtrToInt(renderRange.start!.p) == CPtrToInt(renderRange.end!.p)
      {
        return .Both
      }
      if renderRange.start != nil {
        return .Start
      }
    }
    if CPtrToInt(renderer.p) == CPtrToInt(renderRange.end?.p) {
      return .End
    }

    let highlightEnd = rendererAfterOffset(renderRange.end!, renderRange.endOffset)

    let highlightIterator = RenderRangeIterator(renderRange.start)
    var currentRenderer = renderRange.start
    while currentRenderer != nil && CPtrToInt(currentRenderer!.p) != CPtrToInt(highlightEnd?.p) {
      if CPtrToInt(currentRenderer!.p) == CPtrToInt(renderRange.start?.p) {
        currentRenderer = highlightIterator.next()
        continue
      }
      if !currentRenderer!.canBeSelectionLeaf() {
        currentRenderer = highlightIterator.next()
        continue
      }
      if CPtrToInt(renderer.p) == CPtrToInt(currentRenderer?.p) {
        return .Inside
      }
      currentRenderer = highlightIterator.next()
    }
    return .None
  }

  func highlightStateForTextBox(renderer: RenderTextWrapper, textBoxRange: TextBoxSelectableRange)
    -> RenderObjectWrapper.HighlightState
  {
    let state = highlightStateForRenderer(renderer)

    if state == .None || state == .Inside {
      return state
    }

    let startOffset = startOffset()
    let endOffset = endOffset()

    // The position after a hard line break is considered to be past its end.
    assert(textBoxRange.start + textBoxRange.length >= (textBoxRange.isLineBreak ? 1 : 0))
    let lastSelectable =
      textBoxRange.start + textBoxRange.length - (textBoxRange.isLineBreak ? 1 : 0)

    let containsStart =
      state != .End && startOffset >= textBoxRange.start
      && startOffset < textBoxRange.start + textBoxRange.length
    let containsEnd =
      state != .Start && endOffset > textBoxRange.start && endOffset <= lastSelectable
    if containsStart && containsEnd {
      return .Both
    }
    if containsStart {
      return .Start
    }
    if containsEnd {
      return .End
    }
    if (state == .End || startOffset < textBoxRange.start)
      && (state == .Start || endOffset > lastSelectable)
    {
      return .Inside
    }

    return .None
  }

  func rangeForTextBox(renderer: RenderTextWrapper, textBoxRange: TextBoxSelectableRange) -> (
    UInt32, UInt32
  ) {
    let state = highlightStateForTextBox(renderer: renderer, textBoxRange: textBoxRange)

    switch state {
    case .Inside:
      return textBoxRange.clamp(startOffset: 0, endOffset: UInt32.max)
    case .Start:
      return textBoxRange.clamp(startOffset: startOffset(), endOffset: UInt32.max)
    case .End:
      return textBoxRange.clamp(startOffset: 0, endOffset: endOffset())
    case .Both:
      return textBoxRange.clamp(startOffset: startOffset(), endOffset: endOffset())
    case .None:
      return (0, 0)
    }
  }

  private let renderRange = RenderRange()
  private let isSelection = false
}
