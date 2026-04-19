/*
 * Copyright (C) 2006 Lars Knoll <lars@trolltech.com>
 * Copyright (C) 2007-2023 Apple Inc. All rights reserved.
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

extension WTF {
  class TextBreakIteratorWrapper {
    struct LineMode {
      typealias Behavior = TextBreakIteratorICU.LineMode.Behavior
      var behavior: Behavior = .Default
    }

    enum ContentAnalysis: UInt8 {
      case Linguistic
      case Mechanical
    }
  }
}

// RAII for TextBreakIterator and TextBreakIteratorCache.
struct CachedTextBreakIteratorWrapper {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  func following(location: UInt32) -> UInt32? {
    let followingRaw = wk_interop.CachedTextBreakIterator_following(p, location)
    if followingRaw < 0 {
      return nil
    }
    return UInt32(followingRaw)
  }

  private var p: UnsafeRawPointer
}

struct CachedLineBreakIteratorFactoryWrapper: ~Copyable {
  class PriorContextWrapper {
    init(p: UnsafeMutableRawPointer) {
      self.p = p
    }

    func lastCharacter() -> UChar {
      return wk_interop.PriorContext_lastCharacter(p)
    }

    func secondToLastCharacter() -> UChar {
      return wk_interop.PriorContext_secondToLastCharacter(p)
    }

    func set(newPriorContext: [UChar]) {
      if newPriorContext.count != 2 {
        // TODO(asuhan): implement this
        fatalError("Unexpected newPriorContext size: \(newPriorContext.count)")
      }
      wk_interop.PriorContext_set(p, newPriorContext[0], newPriorContext[1])
    }

    func length() -> UInt32 {
      return wk_interop.PriorContext_length(p)
    }

    private var p: UnsafeMutableRawPointer
  }

  deinit { wk_interop.CachedLineBreakIteratorFactory_destroy(p) }

  init(
    stringView: StringWrapperView, locale: AtomStringWrapper = AtomStringWrapper(),
    mode: WTF.TextBreakIteratorWrapper.LineMode.Behavior = .Default,
    contentAnalysis: WTF.TextBreakIteratorWrapper.ContentAnalysis = .Mechanical
  ) {
    self.p = wk_interop.CachedLineBreakIteratorFactory_new(
      stringView.p, locale.p, mode.rawValue, contentAnalysis.rawValue)
  }

  func stringView() -> StringWrapperView {
    return StringWrapperView(p: wk_interop.CachedLineBreakIteratorFactory_stringView(p))
  }

  func mode() -> WTF.TextBreakIteratorWrapper.LineMode.Behavior {
    return WTF.TextBreakIteratorWrapper.LineMode.Behavior(
      rawValue: wk_interop.CachedLineBreakIteratorFactory_mode(p))!
  }

  func get() -> CachedTextBreakIteratorWrapper {
    return CachedTextBreakIteratorWrapper(p: wk_interop.CachedLineBreakIteratorFactory_get(p))
  }

  func priorContext() -> PriorContextWrapper {
    return PriorContextWrapper(p: CachedLineBreakIteratorFactory_priorContext(p))
  }

  private var p: UnsafeMutableRawPointer
}

// Returns the number of code units that create the specified number of
// grapheme clusters. If there are fewer clusters in the string than specified,
// the length of the string is returned.
func numCodeUnitsInGraphemeClusters(string: StringWrapperView, numGraphemeClusters: UInt32)
  -> UInt32
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
