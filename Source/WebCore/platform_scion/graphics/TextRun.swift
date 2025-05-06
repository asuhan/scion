/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2022 Apple Inc. All rights reserved.
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

import wk_interop

class TextRunWrapper {
  init(
    stringView: StringWrapperView, xpos: Float32 = 0, expansion: Float32 = 0,
    expansionBehavior: ExpansionBehaviorWrapper = ExpansionBehaviorWrapper.defaultBehavior(),
    direction: TextDirection = .LTR,
    directionalOverride: Bool = false,
    characterScanForCodePath: Bool = true
  ) {
    // TODO(asuhan): Extend to support expansionBehavior and characterScanForCodePath.
    if stringView.p == nil {
      return
    }
    self.p = text_run_from_string_view(
      p: stringView.p!, xpos: xpos, expansion: expansion, direction: direction == .RTL,
      directionalOverride: directionalOverride)
  }

  func span8() -> CharSpanWrapper<LChar> {
    assert(self.p != nil)
    return CharSpanWrapper<LChar>(p: wk_interop.TextRun_span8(self.p))
  }

  func span16() -> CharSpanWrapper<UChar> {
    assert(self.p != nil)
    return CharSpanWrapper<UChar>(p: wk_interop.TextRun_span16(self.p))
  }

  func length() -> UInt32 {
    assert(self.p != nil)
    return wk_interop.TextRun_length(self.p!)
  }

  func is8Bit() -> Bool {
    assert(self.p != nil)
    return wk_interop.TextRun_is8Bit(self.p!)
  }

  func setTabSize(allow: Bool, size: TabSizeWrapper) {
    if self.p != nil {
      text_run_set_tab_size(textRunPtr: self.p!, allow: allow, tabSize: size)
      return
    }
    self.m_allow = allow
    self.m_size = size
  }

  func rtl() -> Bool {
    assert(self.p != nil)
    return wk_interop.TextRun_rtl(self.p!)
  }

  func setTextSpacingState(spacingStatePtr: UnsafeRawPointer?) {
    assert(self.p != nil)
    text_run_set_text_spacing_state(textRunPtr: self.p!, spacingStatePtr: spacingStatePtr)
  }

  func text() -> StringWrapperView {
    assert(self.p != nil)
    return StringWrapperView(p: TextRun_text(self.p!))
  }

  var m_allow: Bool = false
  var m_size: TabSizeWrapper = TabSizeWrapper(numOrLength: 0, isSpaces: .LengthValueType)
  var p: UnsafeMutableRawPointer?
}
