/*
 * Copyright (C) 2017-2021 Apple Inc. All rights reserved.
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

class MarkedText {
  // Sorted by paint order
  enum `Type`: UInt8 {
    case Unmarked
    case GrammarError
    case Correction
    case SpellingError
    case TextMatch
    case DictationAlternatives
    case Highlight
    case FragmentHighlight
    case Selection
    case DraggedContent
    case TransparentContent
  }

  enum PaintPhase {
    case Background
    case Foreground
    case Decoration
  }

  enum OverlapStrategy {
    case None
    case Frontmost
  }

  init(
    startOffset: UInt32, endOffset: UInt32, type: `Type`, marker: RenderedDocumentMarker? = nil,
    highlightName: AtomStringWrapper = AtomStringWrapper(), priority: Int32 = 0
  ) {
    self.startOffset = startOffset
    self.endOffset = endOffset
    self.type = type
    self.marker = marker
    self.highlightName = highlightName
    self.priority = priority
  }

  init() {}

  func isEmpty() -> Bool { return endOffset <= startOffset }

  static func subdivide(markedTexts: [MarkedText], overlapStrategy: OverlapStrategy) -> [MarkedText]
  {
    if markedTexts.isEmpty {
      return []
    }

    struct Offset {
      enum Kind {
        case Begin
        case End
      }
      let kind: Kind
      let value: UInt32  // Copy of markedText.startOffset/endOffset to avoid the need to branch based on kind.
      let markedText: MarkedText
    }

    // 1. Build table of all offsets.
    var offsets: [Offset] = []
    assert(markedTexts.count < UInt32.max / 2)
    let numberOfMarkedTexts = markedTexts.count
    let numberOfOffsets = 2 * numberOfMarkedTexts
    offsets.reserveCapacity(numberOfOffsets)
    for markedText in markedTexts {
      offsets.append(Offset(kind: .Begin, value: markedText.startOffset, markedText: markedText))
      offsets.append(Offset(kind: .End, value: markedText.endOffset, markedText: markedText))
    }

    // 2. Sort offsets such that begin offsets are in paint order and end offsets are in reverse paint order.
    offsets.sort(by: {
      a, b in
      a.value < b.value
        || (a.value == b.value && a.kind == b.kind && a.kind == .Begin
          && a.markedText.type.rawValue < b.markedText.type.rawValue)
        || (a.value == b.value && a.kind == b.kind && a.kind == .End
          && a.markedText.type.rawValue > b.markedText.type.rawValue)
    })

    // 3. Compute intersection.
    var result: [MarkedText] = []
    result.reserveCapacity(numberOfMarkedTexts)
    var processedMarkedTexts: Set<ObjectIdentifier> = []
    var offsetSoFar = offsets[0].value
    for i in 1..<numberOfOffsets {
      if offsets[i].value > offsets[i - 1].value {
        if overlapStrategy == .Frontmost {
          var frontmost: UInt32? = nil
          for j in 0..<UInt32(i) {
            if !processedMarkedTexts.contains(ObjectIdentifier(offsets[Int(j)].markedText))
              && (frontmost == nil
                || offsets[Int(j)].markedText.type.rawValue
                  > offsets[Int(frontmost!)].markedText.type.rawValue)
            {
              frontmost = j
            }
          }
          if frontmost != nil {
            result.append(
              MarkedText(
                startOffset: offsetSoFar, endOffset: offsets[i].value,
                type: offsets[Int(frontmost!)].markedText.type,
                marker: offsets[Int(frontmost!)].markedText.marker,
                highlightName: offsets[Int(frontmost!)].markedText.highlightName)
            )
          }
        } else {
          // The appended marked texts may not be in paint order. We will fix this up at the end of this function.
          for j in 0..<i {
            if !processedMarkedTexts.contains(ObjectIdentifier(offsets[j].markedText)) {
              result.append(
                MarkedText(
                  startOffset: offsetSoFar, endOffset: offsets[i].value,
                  type: offsets[j].markedText.type,
                  marker: offsets[j].markedText.marker,
                  highlightName: offsets[j].markedText.highlightName,
                  priority: offsets[j].markedText.priority))
            }
          }
        }
        offsetSoFar = offsets[i].value
      }
      if offsets[i].kind == .End {
        processedMarkedTexts.insert(ObjectIdentifier(offsets[i].markedText))
      }
    }
    // Fix up; sort the marked texts so that they are in paint order.
    if overlapStrategy == .None {
      result.sort(by: {
        a, b in
        return a.startOffset < b.startOffset
          || (a.startOffset == b.startOffset && a.type.rawValue < b.type.rawValue)
      })
    }
    return result
  }

  static func collectForDocumentMarkers(
    renderer: RenderTextWrapper, selectableRange: TextBoxSelectableRange, phase: PaintPhase
  ) -> [MarkedText] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func collectForHighlights(
    renderer: RenderTextWrapper, selectableRange: TextBoxSelectableRange, phase: PaintPhase
  ) -> [MarkedText] {
    var markedTexts: [MarkedText] = []
    let renderHighlight = RenderHighlight()
    if renderer.document().settings().highlightAPIEnabled() {
      let parentRenderer = renderer.parent()!
      let parentStyle = parentRenderer.style()
      if let highlightRegistry = renderer.document().highlightRegistryIfExists() {
        for highlightName in highlightRegistry.highlightNames() {
          if let renderStyle = parentRenderer.getUncachedPseudoStyle(
            pseudoElementRequest: Style.PseudoElementRequest(
              pseudoId: .Highlight, nameArgument: highlightName),
            parentStyle: parentStyle)
          {
            if renderStyle.textDecorationsInEffect().isEmpty && phase == .Decoration {
              continue
            }
          } else {
            continue
          }
          for highlightRange in highlightRegistry.get(name: highlightName).highlightRanges() {
            if !renderHighlight.setRenderRange(highlightRange: highlightRange) {
              continue
            }
            if let staticRange = highlightRange.range() as? StaticRangeWrapper {
              if !staticRange.computeValidity() || staticRange.collapsed() {
                continue
              }
            } else {
              continue
            }
            // FIXME: Potentially move this check elsewhere, to where we collect this range information.
            let hasRenderer = MarkedText.hasRenderer()
            if !hasRenderer {
              continue
            }

            let (highlightStart, highlightEnd) = renderHighlight.rangeForTextBox(
              renderer: renderer, textBoxRange: selectableRange)

            if highlightStart < highlightEnd {
              let currentPriority = highlightRegistry.get(name: highlightName).priority()
              // If we can just append it to the end, do that instead.
              if markedTexts.isEmpty || markedTexts.last!.priority <= currentPriority {
                markedTexts.append(
                  MarkedText(
                    startOffset: highlightStart, endOffset: highlightEnd,
                    type: .Highlight,
                    marker: nil,
                    highlightName: highlightName, priority: currentPriority)
                )
              } else {
                // Gets the first place such that markedTexts[insertIndex] > currentPriority.
                let insertIndex = markedTexts.partitioningIndex(where: { markedText in
                  markedText.priority > currentPriority
                })

                markedTexts.insert(
                  MarkedText(
                    startOffset: highlightStart, endOffset: highlightEnd,
                    type: .Highlight,
                    marker: nil,
                    highlightName: highlightName, priority: currentPriority), at: insertIndex)
              }
            }
          }
        }
      }
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private static func hasRenderer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func collectForDraggedAndTransparentContent(
    type: DocumentMarker.`Type`, renderer: RenderTextWrapper,
    selectableRange: TextBoxSelectableRange
  ) -> [MarkedText] {
    let markerType = markerTypeForDocumentMarker(type: type)
    if markerType == .Unmarked {
      fatalError("Not reached")
    }
    let contentRanges = renderer.contentRangesBetweenOffsetsForType(
      type: type, startOffset: selectableRange.start,
      endOffset: selectableRange.start + selectableRange.length)

    return contentRanges.map { first, second in
      MarkedText(
        startOffset: selectableRange.clamp(offset: first),
        endOffset: selectableRange.clamp(offset: second), type: markerType)
    }
  }

  private static func markerTypeForDocumentMarker(type: DocumentMarker.`Type`) -> MarkedText.`Type`
  {
    switch type {
    case .DraggedContent:
      return .DraggedContent
    case .TransparentContent:
      return .TransparentContent
    default:
      return .Unmarked
    }
  }

  var startOffset: UInt32 = 0
  var endOffset: UInt32 = 0
  var type: `Type` = .Unmarked
  var marker: RenderedDocumentMarker? = nil
  var highlightName = AtomStringWrapper()
  var priority: Int32 = 0
}
