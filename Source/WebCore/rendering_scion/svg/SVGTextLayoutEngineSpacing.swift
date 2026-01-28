/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2023 Apple Inc. All rights reserved.
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

// Helper class used by SVGTextLayoutEngine to handle 'letter-spacing' and 'word-spacing'.
struct SVGTextLayoutEngineSpacing {
  init(_ font: FontCascadeWrapper) { self.font = font }

  mutating func calculateCSSSpacing(_ currentCharacter: UChar?) -> Float32 {
    let lastCharacter = m_lastCharacter
    m_lastCharacter = currentCharacter

    if font.letterSpacing() == 0 && font.wordSpacing() == 0 {
      return 0
    }

    var spacing = font.letterSpacing()
    if currentCharacter != nil && lastCharacter != nil && font.wordSpacing() != 0 {
      if FontCascadeWrapper.treatAsSpace(ch: UInt32(currentCharacter!))
        && !FontCascadeWrapper.treatAsSpace(ch: UInt32(lastCharacter!))
      {
        spacing += font.wordSpacing()
      }
    }

    return spacing
  }

  private let font: FontCascadeWrapper
  private var m_lastCharacter: UChar? = nil
}
