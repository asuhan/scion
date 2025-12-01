/*
 * Copyright (C) 2005-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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
 */

struct RenderTheme {
  // This function is to be implemented in platform-specific theme implementations to hand back the
  // appropriate platform theme.
  static func singleton() -> RenderTheme {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // These methods are called to paint the widget as a background of the RenderObject. A widget's foreground, e.g., the
  // text of a button, is always rendered by the engine itself. The boolean return value indicates
  // whether the CSS border/background should also be painted.
  @discardableResult
  func paint(
    box: RenderBoxWrapper, part: ControlPartWrapper, paintInfo: PaintInfoWrapper,
    rect: LayoutRectWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func paint(box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: LayoutRectWrapper) -> Bool {
    // If painting is disabled, but we aren't updating control tints, then just bail.
    // If we are updating control tints, just schedule a repaint if the theme supports tinting
    // for that control.
    if paintInfo.context().invalidatingControlTints() {
      if controlSupportsTints(o: box) {
        box.repaint()
      }
      return false
    }
    if paintInfo.context().paintingDisabled() {
      return false
    }

    let appearance = box.style().usedAppearance()

    if !canPaint(paintInfo: paintInfo, settings: box.settings(), appearance: appearance) {
      return false
    }

    let integralSnappedRect = snappedIntRect(rect: rect)
    let deviceScaleFactor = box.document().deviceScaleFactor()
    let devicePixelSnappedRect = snapRectToDevicePixels(
      rect: rect, pixelSnappingFactor: deviceScaleFactor)

    switch appearance {
    case .Checkbox:
      return paintCheckbox(box: box, paintInfo: paintInfo, rect: devicePixelSnappedRect)
    case .Radio:
      return paintRadio(box: box, paintInfo: paintInfo, rect: devicePixelSnappedRect)
    case .ColorWell:
      return paintColorWell(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .PushButton, .SquareButton, .DefaultButton, .Button:
      return paintButton(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .Menulist:
      return paintMenuList(
        box: box, paintInfo: paintInfo, devicePixelSnappedRect: devicePixelSnappedRect)
    case .Meter:
      return paintMeter(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .ProgressBar:
      return paintProgressBar(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .SliderHorizontal, .SliderVertical:
      return paintSliderTrack(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .SliderThumbHorizontal, .SliderThumbVertical:
      return paintSliderThumb(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .MenulistButton, .TextField, .TextArea, .Listbox:
      return true
    case .SearchField:
      return paintSearchField(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .SearchFieldCancelButton:
      return paintSearchFieldCancelButton(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .SearchFieldDecoration:
      return paintSearchFieldDecorationPart(
        box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .SearchFieldResultsDecoration:
      return paintSearchFieldResultsDecorationPart(
        box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .SearchFieldResultsButton:
      return paintSearchFieldResultsButton(
        box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .Switch:
      return true
    case .SwitchThumb:
      return paintSwitchThumb(
        renderer: box, paintInfo: paintInfo, devicePixelSnappedRect: devicePixelSnappedRect)
    case .SwitchTrack:
      return paintSwitchTrack(
        renderer: box, paintInfo: paintInfo, devicePixelSnappedRect: devicePixelSnappedRect)
    case .None, .Auto, .Base, .InnerSpinButton:
      return true  // We don't support the appearance, so let the normal background/border paint.
    }
  }

  func paintBorderOnly(box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: LayoutRectWrapper)
    -> Bool
  {
    if paintInfo.context().paintingDisabled() {
      return false
    }

    let devicePixelSnappedRect = snapRectToDevicePixels(
      rect: rect, pixelSnappingFactor: box.document().deviceScaleFactor())
    // Call the appropriate paint method based off the appearance value.
    switch box.style().usedAppearance() {
    case .TextField:
      return paintTextField(
        box: box, paintInfo: paintInfo, devicePixelSnappedRect: devicePixelSnappedRect)
    case .Listbox, .TextArea:
      return paintTextArea(
        box: box, paintInfo: paintInfo, devicePixelSnappedRect: devicePixelSnappedRect)
    case .MenulistButton, .SearchField:
      return true
    case .None,
      .Auto,
      .Base,
      .Checkbox,
      .Radio,
      .PushButton,
      .SquareButton,
      .ColorWell,
      .DefaultButton,
      .Button,
      .Menulist,
      .Meter,
      .ProgressBar,
      .SliderHorizontal,
      .SliderVertical,
      .SliderThumbHorizontal,
      .SliderThumbVertical,
      .SearchFieldCancelButton,
      .InnerSpinButton,
      .SearchFieldDecoration,
      .SearchFieldResultsDecoration,
      .SearchFieldResultsButton,
      .Switch,
      .SwitchThumb,
      .SwitchTrack:
      return false
    }
  }

  func paintDecorations(box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: LayoutRectWrapper)
  {
    if paintInfo.context().paintingDisabled() {
      return
    }

    // FIXME: Investigate whether all controls can use a device-pixel-snapped rect
    // rather than an integral-snapped rect.

    let integralSnappedRect = snappedIntRect(rect: rect)
    let devicePixelSnappedRect = snapRectToDevicePixels(
      rect: rect, pixelSnappingFactor: box.document().deviceScaleFactor())

    // Call the appropriate paint method based off the appearance value.
    switch box.style().usedAppearance() {
    case .MenulistButton:
      paintMenuListButtonDecorations(box: box, paintInfo: paintInfo, rect: devicePixelSnappedRect)
    case .TextField:
      paintTextFieldDecorations(box: box, paintInfo: paintInfo, rect: devicePixelSnappedRect)
    case .TextArea:
      paintTextAreaDecorations(box: box, paintInfo: paintInfo, rect: devicePixelSnappedRect)
    case .SquareButton:
      paintSquareButtonDecorations(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .ColorWell:
      paintColorWellDecorations(box: box, paintInfo: paintInfo, rect: devicePixelSnappedRect)
    case .Menulist:
      paintMenuListDecorations(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    case .SliderThumbHorizontal, .SearchField:
      paintSearchFieldDecorations(box: box, paintInfo: paintInfo, rect: integralSnappedRect)
    default:
      break
    }
  }

  func adjustedPaintRect(box: RenderBoxWrapper, paintRect: LayoutRectWrapper) -> LayoutRectWrapper {
    return paintRect
  }

  // A method asking if the control changes its tint when the window has focus or not.
  func controlSupportsTints(o: RenderObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Text selection colors.
  func activeSelectionBackgroundColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inactiveSelectionBackgroundColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformSelectionBackgroundColor(color: ColorWrapper, options: StyleColorOptions)
    -> ColorWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Highlighting color for search matches.
  func textSearchHighlightColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Default highlighting color for app highlights.
  func annotationHighlightColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func defaultButtonTextColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func documentMarkerLineColor(renderer: RenderTextWrapper, mode: DocumentMarkerLineStyleMode)
    -> ColorWrapper
  {
    let options = renderer.styleColorOptions()

    switch mode {
    case .Spelling:
      return spellingMarkerColor(options: options)
    case .DictationAlternatives, .TextCheckingDictationPhraseWithAlternatives:
      return dictationAlternativesMarkerColor(options: options)
    case .AutocorrectionReplacement:
      return autocorrectionReplacementMarkerColor(renderer: renderer)
    case .Grammar:
      return grammarMarkerColor(options: options)
    }
  }

  func canPaint(paintInfo: PaintInfoWrapper, settings: SettingsWrapper, appearance: StyleAppearance)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintCheckbox(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: FloatRectWrapper)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintRadio(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: FloatRectWrapper)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintButton(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintColorWell(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect) -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintColorWellDecorations(
    box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: FloatRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintTextField(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, devicePixelSnappedRect: FloatRectWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintTextFieldDecorations(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: FloatRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintTextArea(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, devicePixelSnappedRect: FloatRectWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintTextAreaDecorations(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: FloatRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMenuList(
    box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, devicePixelSnappedRect: FloatRectWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMenuListDecorations(
    box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMenuListButtonDecorations(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: FloatRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSquareButtonDecorations(
    box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMeter(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintProgressBar(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSliderTrack(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSliderThumb(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSearchField(box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSearchFieldDecorations(
    box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSearchFieldCancelButton(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: IntRect
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSearchFieldDecorationPart(
    box: RenderObjectWrapper, paintInfo: PaintInfoWrapper, rect: IntRect
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSearchFieldResultsDecorationPart(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: IntRect
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSearchFieldResultsButton(
    box: RenderBoxWrapper, paintInfo: PaintInfoWrapper, rect: IntRect
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSwitchThumb(
    renderer: RenderObjectWrapper, paintInfo: PaintInfoWrapper,
    devicePixelSnappedRect: FloatRectWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSwitchTrack(
    renderer: RenderObjectWrapper, paintInfo: PaintInfoWrapper,
    devicePixelSnappedRect: FloatRectWrapper
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autocorrectionReplacementMarkerColor(renderer: RenderTextWrapper) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func spellingMarkerColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dictationAlternativesMarkerColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func grammarMarkerColor(options: StyleColorOptions) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
