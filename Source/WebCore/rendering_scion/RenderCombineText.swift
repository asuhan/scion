/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

final class RenderCombineTextWrapper: RenderTextWrapper {
  func combineTextIfNeeded() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeTextOrigin(boxRect: FloatRectWrapper) -> FloatPoint? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isCombined() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func combinedTextWidth(_ font: FontCascadeWrapper) -> Float32 { return font.size() }

  func originalFont() -> FontCascadeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textCombineFont() -> FontCascadeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // FIXME: This is pretty hackish.
    // Only cache a new font style if our old one actually changed. We do this to avoid
    // clobbering width variants and shrink-to-fit changes, since we won't recombine when
    // the font doesn't change.
    if oldStyle == nil || oldStyle!.fontCascade() != style().fontCascade() {
      combineFontStyle = RenderStyleWrapper.clone(style: style())
    }

    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if m_isCombined && selfNeedsLayout() {
      // Layouts cause the text to be recombined; therefore, only only un-combine when the style diff causes a layout.
      super.setRenderedText(originalText())  // This RenderCombineText has been combined once. Restore the original text for the next combineText().
      m_isCombined = false
    }

    needsFontUpdate = true
    combineTextIfNeeded()
  }

  override func setRenderedText(_ text: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var combineFontStyle: RenderStyleWrapper? = nil
  private var m_isCombined = false
  private var needsFontUpdate = false
}
