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

private let defaultWidthNumChars: Int32 = 34

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

  override func paintObject(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    assert(isNativeImpl())
    return VisiblePosition()
  }

  private func uploadButton() -> HTMLInputElementWrapper? {
    assert(isNativeImpl())
    assert(inputElement().shadowRoot() != nil)
    guard let firstChild = inputElement().shadowRoot()!.firstChild(), firstChild.hasInputTagName()
    else {
      return nil
    }
    return HTMLInputElementWrapper(p: firstChild.p)
  }

  private var m_canReceiveDroppedFiles: Bool
}
