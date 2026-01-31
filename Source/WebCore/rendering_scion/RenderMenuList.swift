/*
 * This file is part of the select element renderer in WebCore.
 *
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
 * Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011, 2015 Apple Inc. All rights reserved.
 *               2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

import Foundation

// TODO(asuhan): inherit from PopupMenuClient as well
final class RenderMenuListWrapper: RenderFlexibleBoxWrapper {
  private func selectElement() -> HTMLSelectElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func innerRenderer() -> RenderBlockWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInnerRenderer(innerRenderer: RenderBlockWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func createsAnonymousWrapper() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    // Clip to the intersection of the content box and the content box for the inner box
    // This will leave room for the arrows which sit in the inner box padding,
    // and if the inner box ever spills out of the outer box, that will get clipped too.
    let outerBox = LayoutRectWrapper(
      x: additionalOffset.x + borderLeft() + paddingLeft(),
      y: additionalOffset.y + borderTop() + paddingTop(),
      width: contentWidth(),
      height: contentHeight())

    let innerBox = LayoutRectWrapper(
      x: additionalOffset.x + innerBlock!.x() + innerBlock!.paddingLeft(),
      y: additionalOffset.y + innerBlock!.y() + innerBlock!.paddingTop(),
      width: innerBlock!.contentWidth(),
      height: innerBlock!.contentHeight())

    return intersection(a: outerBox, b: innerBox)
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // FIXME: Fix field-sizing: content with size containment
    // https://bugs.webkit.org/show_bug.cgi?id=269169
    if style().fieldSizing() == .Content {
      return super.computeIntrinsicLogicalWidths(
        minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
    }

    maxLogicalWidth = LayoutUnit(
      value: shouldApplySizeContainment()
        ? theme().minimumMenuListSize(style())
        : max(optionsWidth, theme().minimumMenuListSize(style())))
    maxLogicalWidth += innerBlock!.paddingStart() + innerBlock!.paddingEnd()
    if shouldApplySizeOrInlineSizeContainment(),
      let logicalWidth = explicitIntrinsicInnerLogicalWidth()
    {
      maxLogicalWidth = logicalWidth
    }
    let logicalWidth = style().logicalWidth()
    if logicalWidth.isCalculated() {
      let zero = LayoutUnit(value: UInt64(0))
      minLogicalWidth = max(zero, valueForLength(length: logicalWidth, maximumValue: zero))
    } else if !logicalWidth.isPercent() {
      minLogicalWidth = maxLogicalWidth
    }
  }

  override func computePreferredLogicalWidths() {
    if style().fieldSizing() == .Content {
      super.computePreferredLogicalWidths()
      return
    }

    minPreferredLogicalWidth = LayoutUnit(value: 0)
    maxPreferredLogicalWidth = LayoutUnit(value: 0)

    if style().logicalWidth().isFixed() && style().logicalWidth().value() > 0 {
      maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: style().logicalWidth())
      minPreferredLogicalWidth = maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &minPreferredLogicalWidth, maxLogicalWidth: &maxPreferredLogicalWidth)
    }

    super.computePreferredLogicalWidths(
      style().logicalMinWidth(), style().logicalMaxWidth(),
      style().isHorizontalWritingMode()
        ? horizontalBorderAndPaddingExtent() : verticalBorderAndPaddingExtent())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    styleDidChangeRenderBlock(diff: diff, oldStyle: oldStyle)

    if innerBlock != nil {  // RenderBlock handled updating the anonymous block's style.
      adjustInnerStyle()
    }

    let fontChanged = oldStyle == nil || oldStyle!.fontCascade() != style().fontCascade()
    if fontChanged {
      updateOptionsWidth()
      needsOptionsWidthUpdate = false
    }
  }

  override func hasLineIfEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func adjustInnerStyle() {
    let innerStyle = innerBlock!.mutableStyle()
    innerStyle.setFlexGrow(1)
    innerStyle.setFlexShrink(1)
    // min-width: 0; is needed for correct shrinking.
    innerStyle.setLogicalMinWidth(LengthWrapper(value: Int32(0), type: .Fixed))
    // Use margin:auto instead of align-items:center to get safe centering, i.e.
    // when the content overflows, treat it the same as align-items: flex-start.
    // But we only do that for the cases where html.css would otherwise use center.
    if style().alignItems().position == .Center {
      innerStyle.setMarginBefore(LengthWrapper())
      innerStyle.setMarginAfter(LengthWrapper())

      innerStyle.setAlignSelfPosition(.FlexStart)
    }

    var paddingBox = theme().popupInternalPaddingBox(style())
    if !style().isHorizontalWritingMode() {
      paddingBox = LengthBox(
        top: Int32(paddingBox.left().value()), right: Int32(paddingBox.top().value()),
        bottom: Int32(paddingBox.right().value()), left: Int32(paddingBox.bottom().value()))
    }
    innerStyle.setPaddingBox(paddingBox)

    if document().page()!.chrome().selectItemWritingDirectionIsNatural() {
      // Items in the popup will not respect the CSS text-align and direction properties,
      // so we must adjust our own style to match.
      innerStyle.setTextAlign(.Left)
      let direction: TextDirection =
        (buttonText != nil && buttonText!.text().defaultWritingDirection() == .U_RIGHT_TO_LEFT)
        ? .RTL : .LTR
      innerStyle.setDirection(direction)
    } else if optionStyle != nil  // TODO(asuhan): add iOS support
      && document().page()!.chrome().selectItemAlignmentFollowsMenuWritingDirection()
    {
      if optionStyle!.direction() != innerStyle.direction()
        || optionStyle!.unicodeBidi() != innerStyle.unicodeBidi()
      {
        innerBlock!.setNeedsLayoutAndPrefWidthsRecalc()
      }
      innerStyle.setTextAlign(style().isLeftToRightDirection() ? .Left : .Right)
      innerStyle.setDirection(optionStyle!.direction())
      innerStyle.setUnicodeBidi(v: optionStyle!.unicodeBidi())
    }

    if innerBlock?.layoutBox() == nil {
      return
    }
    if let inlineFormattingContextRoot = innerBlock as? RenderBlockFlowWrapper {
      inlineFormattingContextRoot.inlineLayout()?.rootStyleWillChange(
        root: inlineFormattingContextRoot, newStyle: innerStyle)
    }
    if let lineLayout = LayoutIntegration.LineLayout.containing(renderer: innerBlock!) {
      lineLayout.styleWillChange(renderer: innerBlock!, newStyle: innerStyle, diff: .Layout)
    }
    LayoutIntegration.LineLayout.updateStyle(innerBlock!)
    for child: RenderTextWrapper in childrenOfType(parent: innerBlock!) {
      LayoutIntegration.LineLayout.updateStyle(child)
    }
  }

  private func updateOptionsWidth() {
    var maxOptionWidth: Float32 = 0
    let listItems = selectElement().listItems()

    for listItem in listItems {
      guard let option = listItem as? HTMLOptionElementWrapper else { continue }

      var text = option.textIndentedToRespectGroupLabel()
      text = applyTextTransform(style(), text, UChar(Character(" ").asciiValue!))
      if theme().popupOptionSupportsTextIndent() {
        // Add in the option's text indent.  We can't calculate percentage values for now.
        var optionWidth: Float32 = 0
        if let optionStyle = option.computedStyleForEditability() {
          optionWidth += minimumValueForLength(length: optionStyle.textIndent(), maximumValue: 0)
        }
        if !text.isEmpty() {
          let font = style().fontCascade()
          let run = RenderBlockWrapper.constructTextRun(text, style())
          optionWidth += font.width(run: run)
        }
        maxOptionWidth = max(maxOptionWidth, optionWidth)
      } else if !text.isEmpty() {
        let font = style().fontCascade()
        let run = RenderBlockWrapper.constructTextRun(text, style())
        maxOptionWidth = max(maxOptionWidth, font.width(run: run))
      }
    }

    let width = Int32(ceilf(maxOptionWidth))
    if optionsWidth == width {
      return
    }

    optionsWidth = width
    if parent() != nil {
      setNeedsLayoutAndPrefWidthsRecalc()
    }
  }

  override func isFlexibleBoxImpl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let buttonText: RenderTextWrapper? = nil
  private let innerBlock: RenderBlockWrapper? = nil

  private var needsOptionsWidthUpdate = false
  private var optionsWidth: Int32 = 0

  private let optionStyle: RenderStyleWrapper? = nil
}
