/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000-2001 Dirk Mueller (mueller@kde.org)
 *           (C) 2006 Alexey Proskuryakov (ap@nypop.com)
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2010-2017 Google Inc. All rights reserved.
 * Copyright (C) 2011 Motorola Mobility, Inc.  All rights reserved.
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

enum AllowStyleInvalidation {
  case No
  case Yes
}

final class HTMLOptionElementWrapper: HTMLElementWrapper {
  func selected(_ allowStyleInvalidation: AllowStyleInvalidation = .Yes) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textIndentedToRespectGroupLabel() -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
