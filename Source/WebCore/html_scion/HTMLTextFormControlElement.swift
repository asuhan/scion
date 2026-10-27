/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2018 Apple Inc. All rights reserved.
 * Copyright (C) 2009, 2010, 2011 Google Inc. All rights reserved.
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

class HTMLTextFormControlElementWrapper: HTMLFormControlElementWrapper {
  func placeholderElement() -> HTMLElementWrapper? {
    guard let raw = wk_interop.HTMLTextFormControlElement_placeholderElement(p) else { return nil }
    return createHTMLElementWrapper(raw)
  }

  func updatePlaceholderVisibility() {
    wk_interop.HTMLTextFormControlElement_updatePlaceholderVisibility(p)
  }

  func innerTextElement() -> TextControlInnerTextElementWrapper? {
    guard let raw = wk_interop.HTMLTextFormControlElement_innerTextElement(p) else { return nil }
    return (createElementWrapper(raw) as! TextControlInnerTextElementWrapper)
  }

  func createInnerTextStyle(_ style: RenderStyleWrapper) -> RenderStyleWrapper {
    let innerTextStyle = convert_render_style(
      p: wk_interop.HTMLTextFormControlElement_createInnerTextStyle(p, style.p!))
    innerTextStyle.pOwner = true
    return innerTextStyle
  }

  func isInnerTextElementEditable() -> Bool {
    return wk_interop.HTMLTextFormControlElement_isInnerTextElementEditable(p)
  }
}
