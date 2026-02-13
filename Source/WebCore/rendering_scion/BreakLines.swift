/*
 * Copyright (C) 2005-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2011 Google Inc. All rights reserved.
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

struct BreakLines {
  enum NoBreakSpaceBehavior: UInt8 {
    case Normal
    case Break
  }
  enum WordBreakBehavior {
    case Normal
    case BreakAll
    case KeepAll
    case AutoPhrase
  }
  enum LineBreakRules {
    case Normal  // Fast path available when using default line-breaking rules within ASCII.
    case Special  // Uses ICU to handle special line-breaking rules.
  }

  static func nextBreakablePosition(
    rules: LineBreakRules, words: WordBreakBehavior, spaces: NoBreakSpaceBehavior,
    lineBreakIteratorFactory: CachedLineBreakIteratorFactoryWrapper, startPosition: UInt64
  ) -> UInt32 {
    let stringView = lineBreakIteratorFactory.stringView()

    if stringView.is8Bit() {
      return UInt32(
        words == .KeepAll
          ? nextBreakableSpace(
            nonBreakingSpaceBehavior: spaces, string: stringView.span8(),
            startPosition: startPosition)
          : nextBreakablePosition(
            shortcutRules: rules, words: words, nonBreakingSpaceBehavior: spaces,
            lineBreakIteratorFactory: lineBreakIteratorFactory, string: stringView.span8(),
            startPositionIn: startPosition))
    }
    return UInt32(
      words == .KeepAll
        ? nextBreakableSpace(
          nonBreakingSpaceBehavior: spaces, string: stringView.span16(),
          startPosition: startPosition)
        : nextBreakablePosition(
          shortcutRules: rules, words: words, nonBreakingSpaceBehavior: spaces,
          lineBreakIteratorFactory: lineBreakIteratorFactory, string: stringView.span16(),
          startPositionIn: startPosition))
  }

  static func nextBreakablePosition<CharacterType>(
    shortcutRules: LineBreakRules, words: WordBreakBehavior,
    nonBreakingSpaceBehavior: NoBreakSpaceBehavior,
    lineBreakIteratorFactory: CachedLineBreakIteratorFactoryWrapper,
    string: CharSpanWrapper<CharacterType>, startPositionIn: UInt64
  ) -> UInt64 where CharacterType: BinaryInteger {
    var startPosition = startPositionIn
    // Don't break if positioned at start of primary context and there is no prior context.
    let priorContextLength = lineBreakIteratorFactory.priorContext().length()
    if startPosition == 0 && priorContextLength == 0 {
      if string.size() <= 1 {
        return string.size()
      }
      startPosition += 1
    }

    var beforeBefore = CharacterInfo(
      character:
        startPosition > 1
        ? string[startPosition - 2]
        : lineBreakIteratorFactory.priorContext().secondToLastCharacter())
    var before = CharacterInfo(
      character:
        startPosition > 0
        ? string[startPosition - 1]
        : lineBreakIteratorFactory.priorContext().lastCharacter())
    var after = CharacterInfo<UChar>()

    var nextBreak: UInt64? = nil
    var i = startPosition
    while i < string.size() {
      after.set(character: string[i])

      // Breakable spaces.
      if BreakLines.isBreakableSpace(
        nonBreakingSpaceBehavior: nonBreakingSpaceBehavior, character: after.id)
      {
        return i
      }

      // ASCII rapid lookup.
      if shortcutRules == .Normal {  // Not valid for 'loose' line-breaking.
        // Don't allow line breaking between '-' and a digit if the '-' may mean a minus sign in the context,
        // while allow breaking in 'ABCD-1234' and '1234-5678' which may be in long URLs.
        if before.id == UChar(Character("-").asciiValue!) && isASCIIDigit(character: after.id) {
          if isASCIIAlphanumeric(character: beforeBefore.id) {
            return i
          }
          beforeBefore = before
          before = after
          i += 1
          continue
        }

        // If both characters are ASCII, use a lookup table for enhanced speed
        // and for compatibility with other browsers (see comments on lineBreakTable for details).
        if before.id <= LineBreakTable.lastCharacter && after.id <= LineBreakTable.lastCharacter {
          if before.id >= LineBreakTable.firstCharacter && after.id >= LineBreakTable.firstCharacter
          {
            if LineBreakTable.unsafeLookup(before: before.id, after: after.id) {
              return i
            }
          }  // Else at least one is an ASCII control character; don't break.
          beforeBefore = before
          before = after
          i += 1
          continue
        }
      }

      // Non-ASCII rapid lookup.
      if words != .AutoPhrase {
        if before.type == .kIndeterminate {
          before.type = classify(
            nonBreakingSpaceBehavior: nonBreakingSpaceBehavior, character: before.id)
        }
        after.type = classify(
          nonBreakingSpaceBehavior: nonBreakingSpaceBehavior, character: after.id)
        // Short-circuit the commonest cases: letter + letter.
        let pair = before.type.rawValue | after.type.rawValue
        // AL+AL SP+AL SP+QU AL+QU QU+QU QU+AL (after's SP is already filtered out).
        if (pair & ~(BreakClass.kSP.rawValue | BreakClass.kAL.rawValue | BreakClass.kQU.rawValue))
          == 0
        {
          if words == .BreakAll {
            if pair == BreakClass.kAL.rawValue {
              return i
            }
          }
          beforeBefore = before
          before = after
          i += 1
          continue
        }
        if (pair | BreakClass.kAL.rawValue) == (BreakClass.kID.rawValue | BreakClass.kAL.rawValue) {
          if words == .KeepAll {
            beforeBefore = before
            before = after
            i += 1
            continue
          }
          return i
        }
        // Handle special cases.
        if ((pair & (BreakClass.kGL.rawValue | BreakClass.kQU.rawValue)) != 0)
          && ((pair & BreakClass.kWeird.rawValue) == 0)  // Keep nbsp high in our list.
        {
          beforeBefore = before
          before = after
          i += 1
          continue
        }
        if after.type == .kCM {
          after.type = before.type
          beforeBefore = before
          before = after
          i += 1
          continue
        }
        if shortcutRules == .Normal {
          if (pair & BreakClass.kWeird.rawValue) == 0 {
            // Handle some common and obvious punctuation behaviors.
            if (pair & (BreakClass.kCL.rawValue | BreakClass.kCP.rawValue | BreakClass.kOP.rawValue))
              != 0
            {
              if after.type == BreakClass.kCL || after.type == BreakClass.kCP
                || before.type == BreakClass.kOP
              {
                beforeBefore = before
                before = after
                i += 1
                continue
              }
              if (pair & BreakClass.kID.rawValue) != 0 {
                return i
              }
            }
          }
        }
      }

      // ICU lookup (slow).
      if nextBreak == nil || nextBreak! < i {
        let breakIterator = lineBreakIteratorFactory.get()
        if let nextBreakU32 = breakIterator.following(location: UInt32(i) &- 1) {
          nextBreak = UInt64(nextBreakU32)
        } else {
          nextBreak = nil
        }
      }
      // Fast forward while our behavior matches ICU.
      if nextBreak != nil && i < nextBreak! {
        let max = min(nextBreak!, string.size() - 1)
        while i < max {
          let lookahead = string[i + 1]
          if (lookahead <= LineBreakTable.lastCharacter && !isASCIIAlpha(character: lookahead))
            || (nonBreakingSpaceBehavior == .Break
              && lookahead == CharacterNames.Unicode.noBreakSpace)
          {
            break
          }
          beforeBefore = before
          before = after
          i += 1
        }
      }
      if i == nextBreak
        && !isBreakableSpace(
          nonBreakingSpaceBehavior: nonBreakingSpaceBehavior, character: before.id)
      {
        return i
      }

      beforeBefore = before
      before = after
      i += 1
    }

    return string.size()
  }

  static func isBreakable(
    _ lineBreakIteratorFactory: CachedLineBreakIteratorFactoryWrapper, _ startPosition: UInt32,
    _ nextBreakable: UInt32?, breakNBSP: Bool, canUseShortcut: Bool, keepAllWords: Bool,
    breakAnywhere: Bool
  ) -> Bool {
    if nextBreakable != nil && nextBreakable! >= startPosition {
      return startPosition == nextBreakable!
    }

    if breakAnywhere {
      return startPosition == BreakLines.nextCharacter(lineBreakIteratorFactory, startPosition)
    }

    if keepAllWords {
      if breakNBSP {
        return startPosition
          == nextBreakablePosition(
            rules: .Special, words: .KeepAll, spaces: .Break,
            lineBreakIteratorFactory: lineBreakIteratorFactory, startPosition: UInt64(startPosition)
          )
      }
      return startPosition
        == nextBreakablePosition(
          rules: .Special, words: .KeepAll, spaces: .Normal,
          lineBreakIteratorFactory: lineBreakIteratorFactory, startPosition: UInt64(startPosition))
    }

    if canUseShortcut {
      if breakNBSP {
        return startPosition
          == nextBreakablePosition(
            rules: .Normal, words: .Normal, spaces: .Break,
            lineBreakIteratorFactory: lineBreakIteratorFactory, startPosition: UInt64(startPosition)
          )
      }
      return startPosition
        == nextBreakablePosition(
          rules: .Normal, words: .Normal, spaces: .Normal,
          lineBreakIteratorFactory: lineBreakIteratorFactory, startPosition: UInt64(startPosition))
    }

    if breakNBSP {
      return startPosition
        == nextBreakablePosition(
          rules: .Special, words: .Normal, spaces: .Break,
          lineBreakIteratorFactory: lineBreakIteratorFactory, startPosition: UInt64(startPosition))
    }

    return startPosition
      == nextBreakablePosition(
        rules: .Special, words: .Normal, spaces: .Normal,
        lineBreakIteratorFactory: lineBreakIteratorFactory, startPosition: UInt64(startPosition))
  }

  static func nextBreakableSpace<CharacterType>(
    nonBreakingSpaceBehavior: NoBreakSpaceBehavior, string: CharSpanWrapper<CharacterType>,
    startPosition: UInt64
  ) -> UInt64 {
    // FIXME: Use ICU instead.
    for i in startPosition..<string.size() {
      if isBreakableSpace(nonBreakingSpaceBehavior: nonBreakingSpaceBehavior, character: string[i])
      {
        return i
      }
      // FIXME: This should either be in isBreakableSpace (though previous attempts broke the world) or should use ICU instead.
      if string[i] == CharacterNames.Unicode.zeroWidthSpace {
        return i
      }
      if string[i] == CharacterNames.Unicode.ideographicSpace {
        return i + 1
      }
    }
    return string.size()
  }

  private static func nextCharacter(
    _ lineBreakIteratorFactory: CachedLineBreakIteratorFactoryWrapper, _ startPosition: UInt32
  ) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func classify(nonBreakingSpaceBehavior: NoBreakSpaceBehavior, character: UChar)
    -> BreakClass
  {
    return BreakClass(
      rawValue: wk_interop.BreakLines_classify(character, nonBreakingSpaceBehavior.rawValue))!
  }

  static func isBreakableSpace(nonBreakingSpaceBehavior: NoBreakSpaceBehavior, character: UChar)
    -> Bool
  {
    switch character {
    case UChar(Character(" ").asciiValue!), UChar(Character("\n").asciiValue!),
      UChar(Character("\t").asciiValue!):
      return true
    case CharacterNames.Unicode.noBreakSpace:
      return nonBreakingSpaceBehavior == .Break
    default:
      return false
    }
  }

  // Data types.
  enum BreakClass: UInt16 {
    // See UAX14 and LineBreak.txt
    // https://www.unicode.org/Public/UCD/latest/ucd/LineBreak.txt
    case kIndeterminate = 0
    case kAL = 1
    case kID = 2
    case kCM = 4
    case kOP = 8
    case kCP = 16
    case kCL = 32
    case kGL = 64
    case kQU = 128
    case kSP = 256
    // case kNU = 1
    case kWeird = 32768
    // Currently we map
    //     1. HL to AL
    //     2. H2 and H3 to ID
    // We also don't distinguish AL and NU.
    // If we pull more logic into isBreakable, these may need to be distinguished.
  }

  struct CharacterInfo<CharacterType> where CharacterType: BinaryInteger {
    var id: CharacterType
    var type: BreakClass = .kIndeterminate

    init(character: CharacterType = 0) {
      self.id = character
      self.type = .kIndeterminate
    }

    mutating func set(character: CharacterType) {
      self.id = character
      self.type = .kIndeterminate
    }
  }

  struct LineBreakTable {
    static var firstCharacter = UChar(Character("!").asciiValue!)
    static var lastCharacter: UChar = 0xFF

    // Must range check before calling.
    static func unsafeLookup(before: UChar, after: UChar) -> Bool {
      return wk_interop.LineBreakTable_unsafeLookup(before, after)
    }
  }

  private static var lineBreakTable = LineBreakTable()
}
