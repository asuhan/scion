/*
 * Copyright (C) 2006, 2007, 2009, 2012 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

// Each RenderFileUploadControl contains a RenderButton (for opening the file chooser), and
// sufficient space to draw a file icon and filename. The RenderButton has a shadow node
// associated with it to receive click/hover events.

private let afterButtonSpacing: Int32 = 4
private let buttonShadowHeight: Int32 = 2

// On Cocoa platforms the icon height matches the button height, to maximize the icon size.
private let iconLogicalHeight: Int32 = 16
private let iconLogicalWidth: Int32 = 16

private let iconFilenameSpacing: Int32 = 2

private let defaultWidthNumChars: Int32 = 34

private func nodeLogicalWidth(_ node: NodeWrapper?) -> Int32 {
  guard let renderBox = node?.renderBox() else { return 0 }
  return roundToInt(value: renderBox.logicalSize().width())
}

final class RenderFileUploadControlWrapper: RenderBlockFlowWrapper {
  init(_ input: HTMLInputElementWrapper, _ style: RenderStyleWrapper) {
    m_canReceiveDroppedFiles = input.canReceiveDroppedFiles()
    super.init(type: .FileUploadControl, element: input, style: style)
    assert(isRenderFileUploadControl())
  }

  func inputElement() -> HTMLInputElementWrapper {
    assert(isNativeImpl())
    return nodeForNonAnonymous() as! HTMLInputElementWrapper
  }

  func updateFromElement() {
    assert(isNativeImpl())
    assert(inputElement().isFileUpload())

    if let button = uploadButton() {
      let newCanReceiveDroppedFilesState = inputElement().canReceiveDroppedFiles()
      if m_canReceiveDroppedFiles != newCanReceiveDroppedFilesState {
        m_canReceiveDroppedFiles = newCanReceiveDroppedFilesState
        button.setActive(newCanReceiveDroppedFilesState)
      }
    }

    // This only supports clearing out the files, but that's OK because for
    // security reasons that's the only change the DOM is allowed to make.
    let files = inputElement().files()
    assert(files != nil)
    if let files, files.isEmpty() {
      repaint()
    }
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    assert(isNativeImpl())
    if shouldApplySizeOrInlineSizeContainment() {
      if let logicalWidth = explicitIntrinsicInnerLogicalWidth() {
        minLogicalWidth = logicalWidth
        maxLogicalWidth = logicalWidth
      }
      return
    }
    // Figure out how big the filename space needs to be for a given number of characters
    // (using "0" as the nominal character).
    let character = UChar(Character("0").asciiValue!)
    let characterAsString = StringWrapper(characters: WTF.span(character: character))
    let font = style().fontCascade()
    let minDefaultLabelWidth =
      Float32(defaultWidthNumChars)
      * font.width(
        run: RenderBlockWrapper.constructTextRun(
          characterAsString, style(), ExpansionBehaviorWrapper.allowRightOnly()))

    let label = theme().fileListDefaultLabel(multipleFilesAllowed: inputElement().multiple())
    var defaultLabelWidth = font.width(
      run: RenderBlockWrapper.constructTextRun(
        label, style(), ExpansionBehaviorWrapper.allowRightOnly()))
    if let button = uploadButton() {
      if let buttonRenderer = button.renderer() {
        defaultLabelWidth +=
          (buttonRenderer.maxPreferredLogicalWidth() + LayoutUnit(value: afterButtonSpacing))
          .toFloat()
      }
    }
    maxLogicalWidth = LayoutUnit(
      value: Int32(max(minDefaultLabelWidth, defaultLabelWidth).rounded(.up)))

    let logicalWidth = style().logicalWidth()
    if logicalWidth.isCalculated() {
      minLogicalWidth = max(
        LayoutUnit(value: 0),
        valueForLength(length: logicalWidth, maximumValue: LayoutUnit(value: 0)))
    } else if !logicalWidth.isPercent() {
      minLogicalWidth = maxLogicalWidth
    }
  }

  override func computePreferredLogicalWidths() {
    assert(isNativeImpl())
    assert(preferredLogicalWidthsDirty())

    m_minPreferredLogicalWidth = LayoutUnit(value: 0)
    m_maxPreferredLogicalWidth = LayoutUnit(value: 0)

    if style().logicalWidth().isFixed() && style().logicalWidth().value() > 0 {
      m_maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().logicalWidth())
      m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &m_minPreferredLogicalWidth, maxLogicalWidth: &m_maxPreferredLogicalWidth)
    }

    renderBoxComputePreferredLogicalWidths(
      style().logicalMinWidth(), style().logicalMaxWidth(),
      style().isHorizontalWritingMode()
        ? horizontalBorderAndPaddingExtent() : verticalBorderAndPaddingExtent())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  private func maxFilenameLogicalWidth() -> Int32 {
    assert(isNativeImpl())
    return max(
      0,
      roundToInt(value: contentLogicalWidth()) - nodeLogicalWidth(uploadButton())
        - afterButtonSpacing
        - (inputElement().icon() != nil ? iconLogicalWidth + iconFilenameSpacing : 0))
  }

  override func paintObject(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    if style().usedVisibility() != .Visible {
      return
    }

    if !paintInfo.context().paintingDisabled() {
      paintControl(&paintInfo, paintOffset)
    }

    // Paint the children.
    super.paintObject(paintInfo: &paintInfo, paintOffset: paintOffset)
  }

  private func paintControl(_ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper)
  {
    assert(isNativeImpl())
    // Push a clip.
    let stateSaver = GraphicsContextStateSaver(context: paintInfo.context(), saveAndRestore: false)
    if paintInfo.phase == .Foreground || paintInfo.phase == .ChildBlockBackgrounds {
      let clipRect = enclosingIntRect(
        rect: LayoutRectWrapper(
          x: paintOffset.x + borderLeft(), y: paintOffset.y + borderTop(),
          width: width() - borderLeft() - borderRight(),
          height: height() - borderBottom() - borderTop() + LayoutUnit(value: buttonShadowHeight)))
      if clipRect.isEmpty() {
        return
      }
      stateSaver.save()
      paintInfo.context().clip(rect: FloatRectWrapper(r: clipRect))
    }

    let isHorizontalWritingMode = style().isHorizontalWritingMode()
    let isFlippedBlocksWritingMode = style().isFlippedBlocksWritingMode()
    let logicalPaintOffset = isHorizontalWritingMode ? paintOffset : paintOffset.transposedPoint()

    if paintInfo.phase == .Foreground {
      let displayedFilename = fileTextValue()
      let font = style().fontCascade()
      let textRun = RenderBlockWrapper.constructTextRun(
        displayedFilename, style(), ExpansionBehaviorWrapper.allowRightOnly(),
        [.RespectDirection, .RespectDirectionOverride])
      // Determine where the filename should be placed
      var contentLogicalLeft = logicalPaintOffset.x + logicalLeftOffsetForContent()
      if style().isLeftToRightDirection() {
        contentLogicalLeft += textIndentOffset()
      } else {
        contentLogicalLeft -= textIndentOffset()
      }

      guard let button = uploadButton() else {
        use(stateSaver)
        return
      }

      let buttonLogicalWidth = LayoutUnit(value: nodeLogicalWidth(button))
      let buttonAndIconLogicalWidth =
        buttonLogicalWidth + LayoutUnit(value: afterButtonSpacing)
        + LayoutUnit(
          value: inputElement().icon() != nil ? iconLogicalWidth + iconFilenameSpacing : 0)
      var textLogicalLeft: LayoutUnit
      if style().isLeftToRightDirection() {
        textLogicalLeft = contentLogicalLeft + buttonAndIconLogicalWidth
      } else {
        textLogicalLeft = LayoutUnit(
          value: (contentLogicalLeft + contentLogicalWidth() - buttonAndIconLogicalWidth).toFloat()
            - font.width(run: textRun))
      }

      // We want to match the button's baseline
      // FIXME: Make this work with transforms.
      let textLogicalTop = { () -> Float32 in
        if let buttonRenderer = button.renderer().map({ $0 as! RenderButtonWrapper }) {
          if let buttonTextRenderer = buttonRenderer.textRenderer() {
            let textBox = InlineIterator.firstTextBoxFor(buttonTextRenderer)
            if textBox.bool() {
              var textVisualRect = textBox.get().visualRectIgnoringBlockDirection()
              textVisualRect.setLocation(
                location: buttonTextRenderer.localToContainerPoint(
                  localPoint: textVisualRect.location(), container: self))
              textVisualRect.moveBy(
                delta: roundPointToDevicePixels(
                  point: paintOffset, pixelSnappingFactor: document().deviceScaleFactor()))

              let metrics = textBox.get().style().fontCascade().metricsOfPrimaryFont()

              if !isHorizontalWritingMode {
                if isFlippedBlocksWritingMode {
                  return textVisualRect.x() - Float32(metrics.intAscent())
                }

                return textVisualRect.x() + Float32(metrics.intDescent())
              }

              if isFlippedBlocksWritingMode {
                return textVisualRect.y() - Float32(metrics.intDescent())
              }

              return textVisualRect.y() + Float32(metrics.intAscent())
            }
          }
        }

        return Float32(
          roundToInt(
            value:
              baselinePosition(
                baselineType: .AlphabeticBaseline, firstLine: true,
                direction: isHorizontalWritingMode ? .HorizontalLine : .VerticalLine,
                linePositionMode: .PositionOnContainingLine
              )))
      }()

      paintInfo.context().setFillColor(
        color: style().visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyColor))

      // Draw the filename
      do {
        let stateSaver = GraphicsContextStateSaver(context: paintInfo.context())

        var textOrigin = IntPoint(
          x: roundToInt(value: textLogicalLeft), y: Int32(textLogicalTop.rounded()))
        if !isHorizontalWritingMode {
          textOrigin = textOrigin.transposedPoint()
          paintInfo.context().translate(p: FloatPoint(p: textOrigin))
          paintInfo.context().rotate(piOverTwoFloat)
          paintInfo.context().translate(p: FloatPoint(p: -textOrigin))
        }

        paintInfo.context().drawBidiText(font: font, run: textRun, point: FloatPoint(p: textOrigin))
        use(stateSaver)
      }

      if let icon = inputElement().icon() {
        // Determine where the icon should be placed
        let borderAndPaddingOffsetForIcon =
          (!isHorizontalWritingMode && isFlippedBlocksWritingMode)
          ? borderAndPaddingAfter() : borderAndPaddingBefore()
        let iconLogicalTop =
          logicalPaintOffset.y + borderAndPaddingOffsetForIcon
          + (contentLogicalHeight() - LayoutUnit(value: iconLogicalHeight)) / 2
        var iconLogicalLeft: LayoutUnit
        if style().isLeftToRightDirection() {
          iconLogicalLeft =
            contentLogicalLeft + buttonLogicalWidth + LayoutUnit(value: afterButtonSpacing)
        } else {
          iconLogicalLeft =
            contentLogicalLeft + contentLogicalWidth() - buttonLogicalWidth
            - LayoutUnit(value: afterButtonSpacing) - LayoutUnit(value: iconLogicalWidth)
        }

        var iconRect = IntRect(
          x: iconLogicalLeft.toInt(), y: iconLogicalTop.toInt(), width: iconLogicalWidth,
          height: iconLogicalHeight)
        if !isHorizontalWritingMode {
          iconRect = iconRect.transposedRect()
        }

        // Draw the file icon
        icon.paint(paintInfo.context(), FloatRectWrapper(r: iconRect))
      }
    }
    use(stateSaver)
  }

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    assert(isNativeImpl())
    return VisiblePosition()
  }

  func fileTextValue() -> StringWrapper {
    assert(isNativeImpl())
    let input = inputElement()
    guard let files = input.files() else {
      return StringWrapper()
    }
    if files.length() != 0 && !input.displayString().isEmpty() {
      if files.length() == 1 {
        return StringTruncator.centerTruncate(
          input.displayString(), maxWidth: Float32(maxFilenameLogicalWidth()),
          font: style().fontCascade())
      }

      return StringTruncator.rightTruncate(
        input.displayString(), maxWidth: Float32(maxFilenameLogicalWidth()),
        font: style().fontCascade())
    }
    return theme().fileListNameForWidth(
      fileList: files, font: style().fontCascade(), width: maxFilenameLogicalWidth(),
      multipleFilesAllowed: input.multiple())
  }

  private func uploadButton() -> HTMLInputElementWrapper? {
    assert(isNativeImpl())
    assert(inputElement().shadowRoot() != nil)
    return inputElement().shadowRoot()!.firstChild() as? HTMLInputElementWrapper
  }

  private var m_canReceiveDroppedFiles: Bool
}
