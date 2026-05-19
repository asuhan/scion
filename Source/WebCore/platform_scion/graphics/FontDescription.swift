/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2007 Nicholas Shanks <webkit@nickshanks.com>
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

class FontDescriptionWrapper {
  let p: UnsafeRawPointer

  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func computedSize() -> Float32 {
    return wk_interop.FontDescription_computedSize(p)
  }

  func textRenderingMode() -> TextRenderingMode {
    return TextRenderingMode(rawValue: wk_interop.FontDescription_textRenderingMode(p))!
  }

  func orientation() -> FontOrientation {
    return FontOrientation(rawValue: wk_interop.FontDescription_orientation(p))!
  }

  func shouldAllowUserInstalledFonts() -> AllowUserInstalledFonts {
    return wk_interop.FontDescription_shouldAllowUserInstalledFonts(p) ? .Yes : .No
  }

  func setComputedSize(s: Float32) { wk_interop.FontDescription_setComputedSize(p, s) }

  func setWeight(_ weight: FontSelectionValue) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOrientation(_ orientation: FontOrientation) {
    wk_interop.FontDescription_setOrientation(p, orientation == .Vertical)
  }

  func setWidthVariant(_ widthVariant: FontWidthVariant) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
