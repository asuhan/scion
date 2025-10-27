/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
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

typealias UChar = UInt16
typealias LChar = UInt8

class StringWrapper {
  init(p: UnsafeRawPointer? = nil) {
    self.p = p ?? wk_interop.String_new()
  }

  // Construct a string with UTF-16 data.
  init(characters: CharSpanWrapper<UChar>) {
    self.p = wk_interop.String_new_span(characters.p)
  }

  func isNull() -> Bool {
    if self.p != nil {
      return wk_interop.String_isNull(self.p)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func length() -> UInt32 {
    if self.p != nil {
      return string_length(p: self.p!)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func span8() -> CharSpanWrapper<LChar> {
    if self.p != nil {
      return CharSpanWrapper<LChar>(p: wk_interop.String_span8(self.p))
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func span16() -> CharSpanWrapper<UChar> {
    if self.p != nil {
      return CharSpanWrapper<UChar>(p: wk_interop.String_span16(self.p))
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func is8Bit() -> Bool {
    if self.p != nil {
      return wk_interop.String_is8Bit(self.p)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func characterStartingAt(i: UInt32) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func convertTo16Bit() {
    if self.p != nil {
      return wk_interop.String_convertTo16Bit(self.p)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  subscript(index: UInt32) -> UChar {
    if self.p != nil {
      return string_subscript(p: self.p!, index: index)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func substring(position: UInt32, length: UInt32 = UInt32(Int32.max)) -> StringWrapper {
    if self.p != nil {
      return StringWrapper(p: wk_interop.String_substring(self.p!, position, length))
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var p: UnsafeRawPointer?
}

func emptyString() -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
