/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2001 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2024 Apple Inc. All rights reserved.
 *           (C) 2006 Alexey Proskuryakov (ap@nypop.com)
 * Copyright (C) 2007 Samuel Weinig (sam@webkit.org)
 * Copyright (C) 2010-2021 Google Inc. All rights reserved.
 * Copyright (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2012 Samsung Electronics. All rights reserved.
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

final class HTMLInputElementWrapper: HTMLTextFormControlElementWrapper {
  override func placeholderElement() -> HTMLElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autoFillButtonElement() -> HTMLElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func displayString() -> StringWrapper {
    return StringWrapper(p: wk_interop.HTMLInputElement_displayString(p), owner: true)
  }

  func icon() -> IconWrapper? {
    guard let icon = wk_interop.HTMLInputElement_icon(p) else { return nil }
    return IconWrapper(p: icon)
  }

  func multiple() -> Bool { return wk_interop.HTMLInputElement_multiple(p) }

  func isFileUpload() -> Bool { return wk_interop.HTMLInputElement_isFileUpload(p) }

  func files() -> FileListWrapper? {
    guard let files = wk_interop.HTMLInputElement_files(p) else { return nil }
    return FileListWrapper(p: files)
  }

  func canReceiveDroppedFiles() -> Bool {
    return wk_interop.HTMLInputElement_canReceiveDroppedFiles(p)
  }

  func valueWithDefault() -> StringWrapper {
    return StringWrapper(p: wk_interop.HTMLInputElement_valueWithDefault(p), owner: true)
  }

  func hasAutoFillStrongPasswordButton() -> Bool {
    return wk_interop.HTMLInputElement_hasAutoFillStrongPasswordButton(p)
  }
}
