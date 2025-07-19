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
  func box() -> InlineDisplay.Box
}

private func computedTextDecorationThickness(
  styleToUse: RenderStyleWrapper, deviceScaleFactor: Float32
) -> Float32 {
  return ceilToDevicePixel(
    value: styleToUse.textDecorationThickness().resolve(
      fontSize: styleToUse.computedFontSize(), metrics: styleToUse.metricsOfPrimaryFont()),
    pixelSnappingFactor: deviceScaleFactor)
}

private func computedAutoTextDecorationThickness(
  styleToUse: RenderStyleWrapper, deviceScaleFactor: Float32
) -> Float32 {
  return ceilToDevicePixel(
    value: TextDecorationThickness.createWithAuto().resolve(
      fontSize: styleToUse.computedFontSize(), metrics: styleToUse.metricsOfPrimaryFont()),
    pixelSnappingFactor: deviceScaleFactor)
}

private func computedLinethroughCenter(
  styleToUse: RenderStyleWrapper, textDecorationThickness: Float32,
  autoTextDecorationThickness: Float32
) -> Float32 {
  let center = 2 * styleToUse.metricsOfPrimaryFont().ascent() / 3 + autoTextDecorationThickness / 2
  return center - textDecorationThickness / 2
}

private func computedTextDecorationType(
  style: RenderStyleWrapper, textDecorationStyles: TextDecorationPainter.Styles
)
  -> TextDecorationLine
{
  var textDecorations = style.textDecorationsInEffect()
  textDecorations = textDecorations.union(
    TextDecorationPainter.textDecorationsInEffectForStyle(style: textDecorationStyles))
  return textDecorations
}

private func radiiForUnderline(
  underline: CompositionUnderline, markedTextStartOffset: UInt32, markedTextEndOffset: UInt32
) -> FloatRoundedRect.Radii {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func mirrorRTLSegment(
  logicalWidth: Float32, direction: TextDirection, start: inout Float32, width: Float32
) {
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
    if let debugShadow = debugTextShadow() {
      textPainter.setShadow(shadow: debugShadow)
    }

    let isTransparentMarkedText =
      markedText.type == .DraggedContent || markedText.type == .TransparentContent
    let _ = GraphicsContextStateSaver(
      context: context,
      saveAndRestore: markedText.style.textStyles.strokeWidth > 0 || isTransparentMarkedText)
    if isTransparentMarkedText {
      context.setAlpha(alpha: markedText.style.alpha)
    }
    updateGraphicsContext(context: context, paintStyle: markedText.style.textStyles)

    if let boxPath = textBox as? InlineIterator.BoxLegacyPath {
      textPainter.setGlyphDisplayListIfNeeded(
        run: boxPath.legacyInlineBox()! as! LegacyInlineTextBox, paintInfo: paintInfo,
        textRun: paintTextRun)
    } else {
      textPainter.setGlyphDisplayListIfNeeded(
        run: (textBox as! InlineIterator.BoxModernPath).box(), paintInfo: paintInfo,
        textRun: paintTextRun)
    }

    // TextPainter wants the box rectangle and text origin of the entire line box.
    textPainter.paintRange(
      textRun: paintTextRun, boxRect: paintRect,
      textOrigin: textOriginFromPaintRect(paintRect: paintRect),
      start: markedText.startOffset,
      end: markedText.endOffset)
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
    if isCombinedText {
      paintInfo.context().concatCTM(transform: rotation(boxRect: paintRect, direction: .Clockwise))
    }

    let textRun = paintTextRun.subRun(
      startOffset: markedText.startOffset, length: markedText.endOffset - markedText.startOffset)

    let textBox = makeIterator()
    var decoratingBoxList = DecoratingBoxList()
    collectDecoratingBoxesForTextBox(
      decoratingBoxList: &decoratingBoxList, textBox: textBox,
      textBoxLocation: textBoxPaintRect.location(),
      overrideDecorationStyle: markedText.style.textDecorationStyles)

    for decoratingBox in decoratingBoxList.reversed() {
      let computedTextDecorationType = computedTextDecorationType(
        style: decoratingBox.style, textDecorationStyles: decoratingBox.textDecorationStyles)

      decorationPainter.paintBackgroundDecorations(
        style: style, textRun: textRun,
        decorationGeometry: computedBackgroundDecorationGeometry(
          decoratingBox: decoratingBox, computedTextDecorationType: computedTextDecorationType,
          textBoxPaintRect: textBoxPaintRect),
        decorationType: computedTextDecorationType,
        decorationStyle: decoratingBox.textDecorationStyles)
    }

    if isCombinedText {
      paintInfo.context().concatCTM(
        transform: rotation(boxRect: paintRect, direction: .Counterclockwise))
    }
  }

  private func computedBackgroundDecorationGeometry(
    decoratingBox: DecoratingBox, computedTextDecorationType: TextDecorationLine,
    textBoxPaintRect: FloatRectWrapper
  )
    -> TextDecorationPainter.BackgroundDecorationGeometry
  {
    let textDecorationThickness = computedTextDecorationThickness(
      styleToUse: decoratingBox.style, deviceScaleFactor: document.deviceScaleFactor())
    let autoTextDecorationThickness = computedAutoTextDecorationThickness(
      styleToUse: decoratingBox.style, deviceScaleFactor: document.deviceScaleFactor())

    return TextDecorationPainter.BackgroundDecorationGeometry(
      textOrigin: textOriginFromPaintRect(paintRect: textBoxPaintRect),
      boxOrigin: roundPointToDevicePixels(
        point: LayoutPointWrapper(size: decoratingBox.location),
        pixelSnappingFactor: document.deviceScaleFactor(),
        directionalRoundingToRight: paintTextRun.ltr()),
      textBoxWidth: textBoxPaintRect.width(),
      textDecorationThickness: textDecorationThickness,
      underlineOffset: TextBoxPainter.underlineOffset(
        decoratingBox: decoratingBox, computedTextDecorationType: computedTextDecorationType),
      overlineOffset: TextBoxPainter.overlineOffset(
        decoratingBox: decoratingBox, computedTextDecorationType: computedTextDecorationType),
      linethroughCenter: computedLinethroughCenter(
        styleToUse: decoratingBox.style, textDecorationThickness: textDecorationThickness,
        autoTextDecorationThickness: autoTextDecorationThickness),
      clippingOffset: Float32(decoratingBox.style.metricsOfPrimaryFont().intAscent()) + 2,
      wavyStrokeParameters: wavyStrokeParameters(fontSize: decoratingBox.style.computedFontSize())
    )
  }

  private static func underlineOffset(
    decoratingBox: DecoratingBox, computedTextDecorationType: TextDecorationLine
  ) -> Float32 {
    if !computedTextDecorationType.contains(.Underline) {
      return 0
    }
    let baseOffset = underlineOffsetForTextBoxPainting(
      inlineBox: decoratingBox.inlineBox.get(), style: decoratingBox.style)
    let wavyOffset =
      decoratingBox.textDecorationStyles.underline.decorationStyle == .Wavy
      ? wavyOffsetFromDecoration() : 0
    return baseOffset + wavyOffset
  }

  private static func overlineOffset(
    decoratingBox: DecoratingBox, computedTextDecorationType: TextDecorationLine
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintForegroundDecorations(
    decorationPainter: TextDecorationPainter, markedText: StyledMarkedText,
    textBoxPaintRect: FloatRectWrapper
  ) {
    let styleToUse = isFirstLine ? renderer.firstLineStyle() : renderer.style()
    let computedTextDecorationType = styleToUse.textDecorationsInEffect().union(
      TextDecorationPainter.textDecorationsInEffectForStyle(
        style: markedText.style.textDecorationStyles))

    if !computedTextDecorationType.contains(.LineThrough) {
      return
    }

    if isCombinedText {
      paintInfo.context().concatCTM(transform: rotation(boxRect: paintRect, direction: .Clockwise))
    }

    let deviceScaleFactor = document.deviceScaleFactor()
    let textDecorationThickness = computedTextDecorationThickness(
      styleToUse: styleToUse, deviceScaleFactor: deviceScaleFactor)
    let linethroughCenter = computedLinethroughCenter(
      styleToUse: styleToUse, textDecorationThickness: textDecorationThickness,
      autoTextDecorationThickness: computedAutoTextDecorationThickness(
        styleToUse: styleToUse, deviceScaleFactor: deviceScaleFactor))
    decorationPainter.paintForegroundDecorations(
      foregroundDecorationGeometry: TextDecorationPainter.ForegroundDecorationGeometry(
        boxOrigin: textBoxPaintRect.location(), textBoxWidth: textBoxPaintRect.width(),
        textDecorationThickness: textDecorationThickness,
        linethroughCenter: linethroughCenter,
        wavyStrokeParameters: wavyStrokeParameters(fontSize: styleToUse.computedFontSize())),
      decorationStyle: markedText.style.textDecorationStyles)

    if isCombinedText {
      paintInfo.context().concatCTM(
        transform: rotation(boxRect: paintRect, direction: .Counterclockwise))
    }
  }

  private func paintCompositionUnderline(
    underline: CompositionUnderline, radii: FloatRoundedRect.Radii, hasLiveConversion: Bool
  ) {
    var start: Float32 = 0  // start of line to draw, relative to tx
    var width = logicalRect.width()  // how much line to draw
    var useWholeWidth = true
    var paintStart = textBox.start()
    var paintEnd = textBox.end()
    if paintStart <= underline.startOffset {
      paintStart = underline.startOffset
      useWholeWidth = false
      start = renderer.width(
        from: textBox.start(), len: paintStart - textBox.start(), xPos: textPosition(),
        firstLine: isFirstLine)
    }
    if paintEnd != underline.endOffset {
      paintEnd = min(paintEnd, underline.endOffset)
      useWholeWidth = false
    }
    if let selectableRangeTruncation = selectableRange.truncation {
      paintEnd = min(paintEnd, textBox.start() + selectableRangeTruncation)
      useWholeWidth = false
    }
    if !useWholeWidth {
      width = renderer.width(
        from: paintStart, len: paintEnd - paintStart, xPos: textPosition() + start,
        firstLine: isFirstLine)
      mirrorRTLSegment(
        logicalWidth: logicalRect.width(), direction: textBox.direction(), start: &start,
        width: width)
    }

    fillCompositionUnderline(
      startIn: start, widthIn: width, underline: underline, _radii: radii,
      _hasLiveConversion: hasLiveConversion)
  }

  private func fillCompositionUnderline(
    startIn: Float32, widthIn: Float32, underline: CompositionUnderline,
    _radii: FloatRoundedRect.Radii,
    _hasLiveConversion: Bool
  ) {
    // Thick marked text underlines are 2px thick as long as there is room for the 2px line under the baseline.
    // All other marked text underlines are 1px thick.
    // If there's not enough space the underline will touch or overlap characters.
    var lineThickness: Float32 = 1
    let baseline = Float32(style.metricsOfPrimaryFont().intAscent())
    if underline.thick && logicalRect.height() - baseline >= 2 {
      lineThickness = 2
    }

    var start = startIn
    var width = widthIn

    // We need to have some space between underlines of subsequent clauses, because some input methods do not use different underline styles for those.
    // We make each line shorter, which has a harmless side effect of shortening the first and last clauses, too.
    start += 1
    width -= 2

    let style = renderer.style()
    let underlineColor =
      underline.compositionUnderlineColor == .TextColor
      ? style.visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyWebkitTextFillColor)
      : style.colorByApplyingColorFilter(color: underline.color)

    let context = paintInfo.context()
    context.setStrokeColor(color: underlineColor)
    context.setStrokeThickness(thickness: lineThickness)
    context.drawLineForText(
      rect: FloatRectWrapper(
        x: paintRect.x() + start, y: paintRect.y() + logicalRect.height() - lineThickness,
        width: width,
        height: lineThickness), printing: isPrinting)
  }

  private func textPosition() -> Float32 {
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

  private func textOriginFromPaintRect(paintRect: FloatRectWrapper) -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct DecoratingBox {
    let inlineBox: InlineIterator.InlineBoxIterator
    let style: RenderStyleWrapper
    let textDecorationStyles: TextDecorationPainter.Styles
    let location: FloatPoint
  }

  typealias DecoratingBoxList = [DecoratingBox]

  func collectDecoratingBoxesForTextBox(
    decoratingBoxList: inout DecoratingBoxList, textBox: InlineIterator.TextBoxIterator,
    textBoxLocation: FloatPoint, overrideDecorationStyle: TextDecorationPainter.Styles
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func debugTextShadow() -> ShadowData? {
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
