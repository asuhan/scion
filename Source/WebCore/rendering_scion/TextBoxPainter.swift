/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

protocol BoxPath {
  func isHorizontal() -> Bool
}

class TextBoxPainter<TextBoxPath: BoxPath> {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paint() {
    if paintInfo.phase == .Selection && !haveSelection {
      return
    }

    if paintInfo.phase == .EventRegion {
      if renderer.parent()!.visibleToHitTesting(
        request: HitTestRequestWrapper(type: .IgnoreCSSPointerEventsProperty))
      {
        paintInfo.eventRegionContext()!.unite(
          roundedRect: FloatRoundedRect(rect: paintRect), renderer: renderer, style: style)
        return
      }
      return
    }

    if paintInfo.phase == .Accessibility {
      paintInfo.accessibilityRegionContext()!.takeBounds(
        renderText: renderer, paintRect: paintRect)
      return
    }

    let shouldRotate = !textBox.isHorizontal() && !isCombinedText
    if shouldRotate {
      paintInfo.context().concatCTM(transform: rotation(boxRect: paintRect, direction: .Clockwise))
    }

    if paintInfo.phase == .Foreground {
      if !isPrinting {
        paintBackground()
      }

      paintPlatformDocumentMarkers()
    }

    paintForegroundAndDecorations()

    if paintInfo.phase == .Foreground {
      if useCustomUnderlines {
        paintCompositionUnderlines()
      }

      renderer.page().addRelevantRepaintedObject(
        object: renderer, objectPaintRect: enclosingLayoutRect(rect: paintRect))
    }

    if shouldRotate {
      paintInfo.context().concatCTM(
        transform: rotation(boxRect: paintRect, direction: .Counterclockwise))
    }
  }

  func paintBackground() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintForegroundAndDecorations() {
    let shouldPaintSelectionForeground = haveSelection && !useCustomUnderlines
    let hasTextDecoration = !style.textDecorationsInEffect().isEmpty
    let hasHighlightDecoration =
      document.hasHighlight()
      && !MarkedText.collectForHighlights(
        renderer: renderer, selectableRange: selectableRange, phase: .Decoration
      ).isEmpty

    let hasDecoration =
      hasTextDecoration || hasHighlightDecoration || hasSpellingOrGrammarDecoration()

    if !contentMayNeedStyledMarkedText(
      hasDecoration: hasDecoration, shouldPaintSelectionForeground: shouldPaintSelectionForeground)
    {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasSpellingOrGrammarDecoration() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func contentMayNeedStyledMarkedText(
    hasDecoration: Bool, shouldPaintSelectionForeground: Bool
  ) -> Bool {
    if hasDecoration {
      return true
    }
    if shouldPaintSelectionForeground {
      return true
    }
    if let markers = document.markersIfExists() {
      if markers.hasMarkers() {
        return true
      }
    }
    if document.hasHighlight() {
      return true
    }
    return false
  }

  func paintCompositionUnderlines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintPlatformDocumentMarkers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let textBox: TextBoxPath
  private let renderer: RenderTextWrapper
  private let document: Document
  private let style: RenderStyleWrapper
  private let paintInfo: PaintInfoWrapper
  private let selectableRange: TextBoxSelectableRange
  private let paintRect: FloatRectWrapper
  private let isCombinedText: Bool
  private let isPrinting: Bool
  private let haveSelection: Bool
  private let useCustomUnderlines: Bool
}

class ModernTextBoxPainterWrapper: TextBoxPainter<InlineIterator.BoxModernPath> {
  init(
    inlineContent: LayoutIntegration.InlineContent, box: InlineDisplay.Box,
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
