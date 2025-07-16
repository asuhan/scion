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
  func start() -> UInt32
  func end() -> UInt32
  func length() -> UInt32
  func direction() -> TextDirection
}

private func radiiForUnderline(
  underline: CompositionUnderline, markedTextStartOffset: UInt32, markedTextEndOffset: UInt32
) -> FloatRoundedRect.Radii {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class TextBoxPainter<TextBoxPath: BoxPath> {
  init(textBox: TextBoxPath, paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
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

  private func makeIterator() -> InlineIterator.TextBoxIterator {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintBackground() {
    let shouldPaintCompositionBackground = containsComposition && !useCustomUnderlines
    let hasSelectionWithNonCustomUnderline = haveSelection && !useCustomUnderlines

    if !shouldPaintBackground(
      hasSelectionWithNonCustomUnderline: hasSelectionWithNonCustomUnderline,
      shouldPaintCompositionBackground: shouldPaintCompositionBackground)
    {
      return
    }

    if shouldPaintCompositionBackground {
      paintCompositionBackground()
    }

    var markedTexts: [MarkedText] = MarkedText.collectForDocumentMarkers(
      renderer: renderer, selectableRange: selectableRange, phase: .Background)
    markedTexts.insert(
      contentsOf: MarkedText.collectForHighlights(
        renderer: renderer, selectableRange: selectableRange, phase: .Background),
      at: markedTexts.count)

    if hasSelectionWithNonCustomUnderline && !paintInfo.context().paintingDisabled() {
      let selectionMarkedText = createMarkedTextFromSelectionInBox()
      if !selectionMarkedText.isEmpty() {
        markedTexts.append(selectionMarkedText)
      }
    }

    let styledMarkedTexts = StyledMarkedText.subdivideAndResolve(
      textsToSubdivide: markedTexts, renderer: renderer, isFirstLine: isFirstLine,
      paintInfo: paintInfo)

    // Coalesce styles of adjacent marked texts to minimize the number of drawing commands.
    let coalescedStyledMarkedTexts = StyledMarkedText.coalesceAdjacentWithEqualBackground(
      markedTexts: styledMarkedTexts)

    for markedText in coalescedStyledMarkedTexts {
      paintBackground(markedText: markedText)
    }
  }

  private func shouldPaintBackground(
    hasSelectionWithNonCustomUnderline: Bool, shouldPaintCompositionBackground: Bool
  ) -> Bool {
    if hasSelectionWithNonCustomUnderline || shouldPaintCompositionBackground {
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

  private func paintForegroundAndDecorations() {
    var shouldPaintSelectionForeground = haveSelection && !useCustomUnderlines
    let hasTextDecoration = !style.textDecorationsInEffect().isEmpty
    let hasHighlightDecoration =
      document.hasHighlight()
      && !MarkedText.collectForHighlights(
        renderer: renderer, selectableRange: selectableRange, phase: .Decoration
      ).isEmpty
    let hasMismatchingContentDirection =
      renderer.containingBlock()!.style().direction() != textBox.direction()
    let hasBackwardTruncation = selectableRange.truncation != nil && hasMismatchingContentDirection

    let hasDecoration =
      hasTextDecoration || hasHighlightDecoration || hasSpellingOrGrammarDecoration()

    if !contentMayNeedStyledMarkedText(
      hasDecoration: hasDecoration, shouldPaintSelectionForeground: shouldPaintSelectionForeground)
    {
      let lineStyle = isFirstLine ? renderer.firstLineStyle() : renderer.style()
      let markedText = MarkedText(
        startOffset: startPosition(hasBackwardTruncation: hasBackwardTruncation),
        endOffset: endPosition(hasBackwardTruncation: hasBackwardTruncation),
        type: .Unmarked)
      let styledMarkedText = StyledMarkedText(
        marker: markedText,
        style: StyledMarkedText.computeStyleForUnmarkedMarkedText(
          renderer: renderer, lineStyle: lineStyle, isFirstLine: isFirstLine, paintInfo: paintInfo))
      paintCompositionForeground(markedText: styledMarkedText)
      return
    }

    var markedTexts: [MarkedText] = []
    if paintInfo.phase != .Selection {
      // The marked texts for the gaps between document markers and selection are implicitly created by subdividing the entire line.
      markedTexts.append(
        MarkedText(
          startOffset: startPosition(hasBackwardTruncation: hasBackwardTruncation),
          endOffset: endPosition(hasBackwardTruncation: hasBackwardTruncation),
          type: .Unmarked))

      if !isPrinting {
        markedTexts.insert(
          contentsOf: MarkedText.collectForDocumentMarkers(
            renderer: renderer, selectableRange: selectableRange, phase: .Foreground),
          at: markedTexts.count)
        markedTexts.insert(
          contentsOf: MarkedText.collectForHighlights(
            renderer: renderer, selectableRange: selectableRange, phase: .Foreground),
          at: markedTexts.count)

        let shouldPaintDraggedContent = !(paintInfo.paintBehavior.contains(.ExcludeSelection))
        if shouldPaintDraggedContent {
          let markedTextsForDraggedContent = MarkedText.collectForDraggedAndTransparentContent(
            type: .DraggedContent, renderer: renderer, selectableRange: selectableRange)
          if !markedTextsForDraggedContent.isEmpty {
            shouldPaintSelectionForeground = false
            markedTexts.insert(contentsOf: markedTextsForDraggedContent, at: markedTexts.count)
          }
        }
        let markedTextsForTransparentContent = MarkedText.collectForDraggedAndTransparentContent(
          type: .TransparentContent, renderer: renderer, selectableRange: selectableRange)
        if !markedTextsForTransparentContent.isEmpty {
          markedTexts.insert(contentsOf: markedTextsForTransparentContent, at: markedTexts.count)
        }
      }
    }
    // The selection marked text acts as a placeholder when computing the marked texts for the gaps...
    if shouldPaintSelectionForeground {
      assert(!isPrinting)
      let selectionMarkedText = createMarkedTextFromSelectionInBox()
      if !selectionMarkedText.isEmpty() {
        markedTexts.append(selectionMarkedText)
      }
    }

    var styledMarkedTexts = StyledMarkedText.subdivideAndResolve(
      textsToSubdivide: markedTexts, renderer: renderer, isFirstLine: isFirstLine,
      paintInfo: paintInfo)

    // ... now remove the selection marked text if we are excluding selection.
    if !isPrinting && paintInfo.paintBehavior.contains(.ExcludeSelection) {
      styledMarkedTexts.removeAll(where: {
        markedText in markedText.type == .Selection
      })
    }

    if hasDecoration && paintInfo.phase != .Selection {
      let length = selectableRange.truncation ?? paintTextRun.length()
      var selectionStart: UInt32 = 0
      var selectionEnd: UInt32 = 0
      if haveSelection {
        (selectionStart, selectionEnd) = selectionStartEnd()
      }

      var textDecorationSelectionClipOutRect = FloatRectWrapper()
      if paintInfo.paintBehavior.contains(.ExcludeSelection) && selectionStart < selectionEnd
        && selectionEnd <= length
      {
        textDecorationSelectionClipOutRect = paintRect
        var logicalWidthBeforeRange: Float32 = 0
        var logicalWidthAfterRange: Float32 = 0
        let logicalSelectionWidth = fontCascade().widthOfTextRange(
          run: paintTextRun, from: selectionStart, to: selectionEnd, fallbackFonts: nil,
          outWidthBeforeRange: &logicalWidthBeforeRange,
          outWidthAfterRange: &logicalWidthAfterRange)
        // FIXME: Do we need to handle vertical bottom to top text?
        if !textBox.isHorizontal() {
          textDecorationSelectionClipOutRect.move(dx: 0, dy: logicalWidthBeforeRange)
          textDecorationSelectionClipOutRect.setHeight(height: logicalSelectionWidth)
        } else if textBox.direction() == .RTL {
          textDecorationSelectionClipOutRect.move(dx: logicalWidthAfterRange, dy: 0)
          textDecorationSelectionClipOutRect.setWidth(width: logicalSelectionWidth)
        } else {
          textDecorationSelectionClipOutRect.move(dx: logicalWidthBeforeRange, dy: 0)
          textDecorationSelectionClipOutRect.setWidth(width: logicalSelectionWidth)
        }
      }

      // Coalesce styles of adjacent marked texts to minimize the number of drawing commands.
      let coalescedStyledMarkedTexts = StyledMarkedText.coalesceAdjacentWithEqualDecorations(
        markedTexts: styledMarkedTexts)

      for markedText in coalescedStyledMarkedTexts {
        let startOffset = markedText.startOffset
        let endOffset = markedText.endOffset
        if startOffset < endOffset {
          // Avoid measuring the text when the entire line box is selected as an optimization.
          var snappedPaintRect = snapRectToDevicePixelsWithWritingDirection(
            rect: LayoutRectWrapper(r: paintRect), deviceScaleFactor: document.deviceScaleFactor(),
            ltr: paintTextRun.ltr())
          if startOffset != 0 || endOffset != paintTextRun.length() {
            let selectionRect = LayoutRectWrapper(
              x: paintRect.x(), y: paintRect.y(), width: paintRect.width(),
              height: paintRect.height())
            fontCascade().adjustSelectionRectForText(
              canUseSimplifiedTextMeasuring: renderer.canUseSimplifiedTextMeasuring() ?? false,
              run: paintTextRun,
              selectionRect: selectionRect, from: startOffset, to: endOffset)
            snappedPaintRect = snapRectToDevicePixelsWithWritingDirection(
              rect: selectionRect, deviceScaleFactor: document.deviceScaleFactor(),
              ltr: paintTextRun.ltr())
          }
          let decorationPainter = createDecorationPainter(
            markedText: markedText, clipOutRect: textDecorationSelectionClipOutRect)
          paintBackgroundDecorations(
            decorationPainter: decorationPainter, markedText: markedText,
            textBoxPaintRect: snappedPaintRect)
          paintCompositionForeground(markedText: markedText)
          paintForegroundDecorations(
            decorationPainter: decorationPainter, markedText: markedText,
            textBoxPaintRect: snappedPaintRect)
        }
      }
    } else {
      // Coalesce styles of adjacent marked texts to minimize the number of drawing commands.
      let coalescedStyledMarkedTexts = StyledMarkedText.coalesceAdjacentWithEqualForeground(
        markedTexts: styledMarkedTexts)

      if coalescedStyledMarkedTexts.isEmpty {
        return
      }

      for markedText in coalescedStyledMarkedTexts {
        paintCompositionForeground(markedText: markedText)
      }
    }
  }

  private func startPosition(hasBackwardTruncation: Bool) -> UInt32 {
    return !hasBackwardTruncation
      ? selectableRange.clamp(offset: textBox.start())
      : textBox.length() - selectableRange.truncation!
  }

  private func endPosition(hasBackwardTruncation: Bool) -> UInt32 {
    return !hasBackwardTruncation ? selectableRange.clamp(offset: textBox.end()) : textBox.length()
  }

  private func hasSpellingOrGrammarDecoration() -> Bool {
    let markedTexts = MarkedText.collectForDocumentMarkers(
      renderer: renderer, selectableRange: selectableRange, phase: .Decoration)

    let hasSpellingError = markedTexts.contains(where: { markedText in
      markedText.type == .SpellingError
    })

    if hasSpellingError {
      if let spellingErrorStyle = renderer.spellingErrorPseudoStyle() {
        return !spellingErrorStyle.textDecorationsInEffect().isEmpty
      }
    }

    let hasGrammarError = markedTexts.contains(where: { markedText in
      markedText.type == .GrammarError
    })

    if hasGrammarError {
      if let grammarErrorStyle = renderer.grammarErrorPseudoStyle() {
        return !grammarErrorStyle.textDecorationsInEffect().isEmpty
      }
    }

    return false
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

  private func paintCompositionBackground() {
    let editor = renderer.frame().editor()

    if !editor.compositionUsesCustomHighlights() {
      let (clampedStart, clampedEnd) = selectableRange.clamp(
        startOffset: editor.compositionStart(), endOffset: editor.compositionEnd())

      paintBackground(
        startOffset: clampedStart, endOffset: clampedEnd,
        color: CompositionHighlight.defaultCompositionFillColor)
      return
    }

    for highlight in editor.customCompositionHighlights() {
      if highlight.backgroundColor == nil {
        continue
      }

      if highlight.endOffset <= textBox.start() {
        continue
      }

      if highlight.startOffset >= textBox.end() {
        break
      }

      let (clampedStart, clampedEnd) = selectableRange.clamp(
        startOffset: highlight.startOffset, endOffset: highlight.endOffset)

      paintBackground(
        startOffset: clampedStart, endOffset: clampedEnd, color: highlight.backgroundColor!,
        backgroundStyle: .Rounded)

      if highlight.endOffset > textBox.end() {
        break
      }
    }
  }

  private func paintCompositionUnderlines() {
    let underlines = renderer.frame().editor().customCompositionUnderlines()
    let underlineCount = underlines.count

    if underlineCount == 0 {
      return
    }

    var hasLiveConversion = false

    var markedTextStartOffset = underlines[0].startOffset
    var markedTextEndOffset = underlines[0].endOffset

    for underline in underlines {
      if underline.thick {
        hasLiveConversion = true
      }

      if underline.startOffset < markedTextStartOffset {
        markedTextStartOffset = underline.startOffset
      }

      if underline.endOffset > markedTextEndOffset {
        markedTextEndOffset = underline.endOffset
      }
    }

    for underline in underlines {
      if underline.endOffset <= textBox.start() {
        // Underline is completely before this run. This might be an underline that sits
        // before the first run we draw, or underlines that were within runs we skipped
        // due to truncation.
        continue
      }

      if underline.startOffset >= textBox.end() {
        break  // Underline is completely after this run, bail. A later run will paint it.
      }

      let underlineRadii = radiiForUnderline(
        underline: underline, markedTextStartOffset: markedTextStartOffset,
        markedTextEndOffset: markedTextEndOffset)

      // Underline intersects this run. Paint it.
      paintCompositionUnderline(
        underline: underline, radii: underlineRadii, hasLiveConversion: hasLiveConversion)

      if underline.endOffset > textBox.end() {
        break  // Underline also runs into the next run. Bail now, no more marker advancement.
      }
    }
  }

  private func paintCompositionForeground(markedText: StyledMarkedText) {
    let editor = renderer.frame().editor()

    if !(editor.compositionUsesCustomHighlights() && containsComposition) {
      paintForeground(markedText: markedText)
      return
    }

    // The highlight ranges must be "packed" so that there is no non-empty interval between
    // any two adjacent highlight ranges. This is needed since otherwise, `paintForeground`
    // will not be called in those would-be non-empty intervals.
    let highlights = editor.customCompositionHighlights()

    var highlightsWithForeground: [CompositionHighlight] = []
    highlightsWithForeground.append(
      CompositionHighlight(
        startOffset: textBox.start(), endOffset: highlights[0].startOffset, backgroundColor: nil,
        foregroundColor: nil))

    for (i, highlight) in highlights.enumerated() {
      highlightsWithForeground.append(highlight)
      if i != highlights.count - 1 {
        highlightsWithForeground.append(
          CompositionHighlight(
            startOffset: highlights[i].endOffset,
            endOffset: highlights[i + 1].startOffset,
            backgroundColor: nil,
            foregroundColor: nil))
      }
    }

    highlightsWithForeground.append(
      CompositionHighlight(
        startOffset: highlights.last!.endOffset,
        endOffset: textBox.end(),
        backgroundColor: nil,
        foregroundColor: nil))

    let lineStyle = isFirstLine ? renderer.firstLineStyle() : renderer.style()

    for highlight in highlightsWithForeground {
      var style = StyledMarkedText.computeStyleForUnmarkedMarkedText(
        renderer: renderer, lineStyle: lineStyle, isFirstLine: isFirstLine, paintInfo: paintInfo)

      if highlight.endOffset <= textBox.start() {
        continue
      }

      if highlight.startOffset >= textBox.end() {
        break
      }

      let (clampedStart, clampedEnd) = selectableRange.clamp(
        startOffset: highlight.startOffset, endOffset: highlight.endOffset)

      if let highlightForegroundColor = highlight.foregroundColor {
        style.textStyles.fillColor = highlightForegroundColor
      }

      paintForeground(
        markedText: StyledMarkedText(
          marker: MarkedText(startOffset: clampedStart, endOffset: clampedEnd, type: .Unmarked),
          style: style))

      if highlight.endOffset > textBox.end() {
        break
      }
    }
  }

  private func paintPlatformDocumentMarkers() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintBackground(markedText: StyledMarkedText) {
    paintBackground(
      startOffset: markedText.startOffset, endOffset: markedText.endOffset,
      color: markedText.style.backgroundColor, backgroundStyle: .Normal)
  }

  private func paintForeground(markedText: StyledMarkedText) {
    if markedText.startOffset >= markedText.endOffset {
      return
    }

    let context = paintInfo.context()
    let font = fontCascade()

    var emphasisMarkOffset: Float32 = 0
    let emphasisMark =
      emphasisMarkExistsAndIsAbove != nil ? style.textEmphasisMarkString() : nullAtom()
    if !emphasisMark.isEmpty() {
      emphasisMarkOffset =
        Float32(
          emphasisMarkExistsAndIsAbove!
            ? -font.metricsOfPrimaryFont().intAscent()
              - font.emphasisMarkDescent(mark: emphasisMark)
            : font.metricsOfPrimaryFont().intDescent() + font.emphasisMarkAscent(mark: emphasisMark)
        )
    }

    let textPainter = TextPainter(context: context, font: font, renderStyle: style)
    textPainter.setStyle(textPaintStyle: markedText.style.textStyles)
    textPainter.setIsHorizontal(isHorizontal: textBox.isHorizontal())
    if markedText.style.textShadow != nil {
      textPainter.setShadow(shadow: markedText.style.textShadow)
      if style.hasAppleColorFilter() {
        textPainter.setShadowColorFilter(colorFilter: style.appleColorFilter())
      }
    }
    textPainter.setEmphasisMark(
      mark: emphasisMark, offset: emphasisMarkOffset,
      combinedText: isCombinedText ? (renderer as! RenderCombineTextWrapper) : nil
    )
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private enum BackgroundStyle {
    case Normal
    case Rounded
  }

  private func paintBackground(
    startOffset: UInt32, endOffset: UInt32, color: ColorWrapper,
    backgroundStyle: BackgroundStyle = .Normal
  ) {
    if startOffset >= endOffset {
      return
    }

    let context = paintInfo.context()
    let _ = GraphicsContextStateSaver(context: context)
    updateGraphicsContext(context: context, paintStyle: TextPaintStyle(color: color))  // Don't draw text at all!

    // Note that if the text is truncated, we let the thing being painted in the truncation
    // draw its own highlight.
    let lineBox = makeIterator().get().lineBox()
    let selectionBottom = LineSelection.logicalBottom(lineBox: lineBox.get())
    let selectionTop = LineSelection.logicalTopAdjustedForPrecedingBlock(lineBox: lineBox.get())
    // Use same y positioning and height as for selection, so that when the selection and this subrange are on
    // the same word there are no pieces sticking out.
    let deltaY = LayoutUnit(
      value: style.isFlippedLinesWritingMode()
        ? selectionBottom - logicalRect.maxY() : logicalRect.y() - selectionTop)
    let selectionHeight = LayoutUnit(value: max(0, selectionBottom - selectionTop))
    let selectionRect = LayoutRectWrapper(
      x: LayoutUnit(value: paintRect.x()), y: LayoutUnit(value: paintRect.y() - deltaY),
      width: LayoutUnit(value: logicalRect.width()), height: selectionHeight)
    var adjustedSelectionRect = selectionRect
    fontCascade().adjustSelectionRectForText(
      canUseSimplifiedTextMeasuring: renderer.canUseSimplifiedTextMeasuring() ?? false,
      run: paintTextRun, selectionRect: adjustedSelectionRect,
      from: startOffset, to: endOffset)
    if paintTextRun.length() == endOffset - startOffset {
      // FIXME: We should reconsider re-measuring the content when non-whitespace runs are joined together (see webkit.org/b/251318).
      let visualRight = max(adjustedSelectionRect.maxX(), selectionRect.maxX())
      adjustedSelectionRect.shiftMaxXEdgeTo(edge: visualRight)
    }

    // FIXME: Support painting combined text. See <https://bugs.webkit.org/show_bug.cgi?id=180993>.
    var backgroundRect = snapRectToDevicePixels(
      rect: adjustedSelectionRect, pixelSnappingFactor: document.deviceScaleFactor())
    if backgroundStyle == .Rounded {
      backgroundRect.expand(dw: -1, dh: -1)
      backgroundRect.move(dx: 0.5, dy: 0.5)
      context.fillRoundedRect(
        rect: FloatRoundedRect(
          rect: backgroundRect, radii: FloatRoundedRect.Radii(uniformRadius: 2)),
        color: color)
      return
    }

    context.fillRect(rect: backgroundRect, color: color)
  }

  private func createDecorationPainter(markedText: StyledMarkedText, clipOutRect: FloatRectWrapper)
    -> TextDecorationPainter
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintBackgroundDecorations(
    decorationPainter: TextDecorationPainter, markedText: StyledMarkedText,
    textBoxPaintRect: FloatRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintForegroundDecorations(
    decorationPainter: TextDecorationPainter, markedText: StyledMarkedText,
    textBoxPaintRect: FloatRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintCompositionUnderline(
    underline: CompositionUnderline, radii: FloatRoundedRect.Radii, hasLiveConversion: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func selectionStartEnd() -> (UInt32, UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func createMarkedTextFromSelectionInBox() -> MarkedText {
    let (selectionStart, selectionEnd) = selectionStartEnd()
    if selectionStart < selectionEnd {
      return MarkedText(startOffset: selectionStart, endOffset: selectionEnd, type: .Selection)
    }
    return MarkedText()
  }

  private func fontCascade() -> FontCascadeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let textBox: TextBoxPath
  private let renderer: RenderTextWrapper
  private let document: Document
  private let style: RenderStyleWrapper
  private let logicalRect: FloatRectWrapper
  private let paintTextRun: TextRunWrapper
  private let paintInfo: PaintInfoWrapper
  private let selectableRange: TextBoxSelectableRange
  private let paintRect: FloatRectWrapper
  private let isFirstLine: Bool
  private let isCombinedText: Bool
  private let isPrinting: Bool
  private let haveSelection: Bool
  private let containsComposition: Bool
  private let useCustomUnderlines: Bool
  private let emphasisMarkExistsAndIsAbove: Bool?
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
