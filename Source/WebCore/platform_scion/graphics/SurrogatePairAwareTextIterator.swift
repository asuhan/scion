/*
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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

struct SurrogatePairAwareTextIterator {
  // The passed in UChar pointer starts at 'currentIndex'. The iterator operates on the range [currentIndex, lastIndex].
  // 'endIndex' denotes the maximum length of the UChar array, which might exceed 'lastIndex'.
  init(characters: CharSpanWrapper<UChar>, currentIndex: UInt32, lastIndex: UInt32) {
    self.characters = characters
    self.currentIndex = currentIndex
    self.originalIndex = currentIndex
    self.lastIndex = lastIndex
    self.endIndex = UInt32(characters.size()) + currentIndex
  }

  func consume(character: inout UInt32, clusterLength: inout UInt32) -> Bool {
    if currentIndex >= lastIndex {
      return false
    }

    let relativeIndex = currentIndex - originalIndex
    var clusterLengthOut: UInt64 = 0
    character = U16_NEXT(
      s: characters.subspan(startOffset: UInt64(relativeIndex)), i: &clusterLengthOut,
      length: endIndex - currentIndex)
    clusterLength = UInt32(clusterLengthOut)
    return true
  }

  mutating func advance(advanceLength: UInt32) {
    currentIndex += advanceLength
  }

  private let characters: CharSpanWrapper<UChar>
  private var currentIndex: UInt32
  private let originalIndex: UInt32
  private let lastIndex: UInt32
  private let endIndex: UInt32
}
