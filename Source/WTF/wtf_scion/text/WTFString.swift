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

class StringWrapper: Hashable {
  init(p: UnsafeRawPointer, owner: Bool) {
    self.p = p
    self.owner = owner
  }

  init() {
    p = wk_interop.String_new()
    owner = true
  }

  // Construct a string with UTF-16 data.
  init(characters: CharSpanWrapper<UChar>) {
    p = wk_interop.String_new_span(characters.p)
    owner = true
  }

  // Construct a string from a constant string literal.
  init(_ characters: ASCIILiteral) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  deinit {
    if owner {
      wk_interop.StringWrapper_destroy(p)
    }
  }

  func isNull() -> Bool {
    return wk_interop.String_isNull(self.p)
  }

  func isEmpty() -> Bool { return wk_interop.String_isEmpty(self.p) }

  func length() -> UInt32 {
    return string_length(p: self.p)
  }

  func span8() -> CharSpanWrapper<LChar> {
    return CharSpanWrapper<LChar>(p: wk_interop.String_span8(self.p))
  }

  func span16() -> CharSpanWrapper<UChar> {
    return CharSpanWrapper<UChar>(p: wk_interop.String_span16(self.p))
  }

  func is8Bit() -> Bool {
    return wk_interop.String_is8Bit(self.p)
  }

  func find(literal: String) -> UInt64? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func left(length: UInt32) -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func characterStartingAt(i: UInt32) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func convertToLowercaseWithLocale(_ localeIdentifier: AtomStringWrapper) -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func convertToUppercaseWithLocale(_ localeIdentifier: AtomStringWrapper) -> StringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func convertTo16Bit() {
    return wk_interop.String_convertTo16Bit(self.p)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(wk_interop.String_hash(self.p))
  }

  subscript(index: UInt32) -> UChar {
    return string_subscript(p: self.p, index: index)
  }

  func substring(position: UInt32, length: UInt32 = UInt32(Int32.max)) -> StringWrapper {
    return StringWrapper(p: wk_interop.String_substring(self.p, position, length), owner: true)
  }

  // Determines the writing direction using the Unicode Bidi Algorithm rules P2 and P3.
  func defaultWritingDirection() -> UCharDirection? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containsOnly(_ isSpecialCharacter: (UChar) -> Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (this: StringWrapper, other: StringWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var p: UnsafeRawPointer
  private let owner: Bool
}

func emptyString() -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
