/*
 * Copyright (C) 2018-2023 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

private final class GlyphDisplayListCacheEntry {
  static func create(
    _ displayList: DisplayList.DisplayListWrapper, _ textRun: TextRunWrapper,
    _ font: FontCascadeWrapper, _ context: GraphicsContextWrapper
  ) -> GlyphDisplayListCacheEntry {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func displayList() -> DisplayList.DisplayListWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func key() -> GlyphDisplayListCacheKey {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

struct GlyphDisplayListCacheKey: Hashable {
  init(_ textRun: TextRunWrapper, _ font: FontCascadeWrapper, _ context: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

class GlyphDisplayListCache {
  func get<LayoutRun: DisplayTextBox>(
    run: LayoutRun, font: FontCascadeWrapper, context: GraphicsContextWrapper,
    textRun: TextRunWrapper, paintInfo: PaintInfoWrapper
  )
    -> DisplayList.DisplayListWrapper?
  { return getDisplayList(run, font, context, textRun, paintInfo) }

  private static func canShareDisplayList(_ displayList: DisplayList.DisplayListWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func getDisplayList<LayoutRun: DisplayTextBox>(
    _ run: LayoutRun, _ font: FontCascadeWrapper, _ context: GraphicsContextWrapper,
    _ textRun: TextRunWrapper, _ paintInfo: PaintInfoWrapper
  ) -> DisplayList.DisplayListWrapper? {
    // TODO(asuhan): implement memory pressure handling

    if font.isLoadingCustomFonts() || font.fonts() == nil {
      return nil
    }

    if let result = getIfExists(run) { return result }

    // TODO(asuhan): implement maximum cache size cap

    if let entry = m_entries[GlyphDisplayListCacheKey(textRun, font, context)] {
      let result = entry.displayList()
      run.setIsInGlyphDisplayListCache()
      m_entriesForLayoutRun[ObjectIdentifier(run)] = entry
      return result
    }

    guard let displayList = font.displayListForTextRun(context, textRun) else { return nil }

    let entry = GlyphDisplayListCacheEntry.create(displayList, textRun, font, context)
    let result = entry.displayList()
    if GlyphDisplayListCache.canShareDisplayList(result) {
      m_entries[entry.key()] = entry
    }
    run.setIsInGlyphDisplayListCache()
    m_entriesForLayoutRun[ObjectIdentifier(run)] = entry
    return result
  }

  private func getIfExists<LayoutRun: DisplayTextBox>(_ run: LayoutRun) -> DisplayList
    .DisplayListWrapper?
  {
    if !run.isInGlyphDisplayListCache {
      return nil
    }
    return m_entriesForLayoutRun[ObjectIdentifier(run)]?.displayList()
  }

  private var m_entriesForLayoutRun: [ObjectIdentifier: GlyphDisplayListCacheEntry] = [:]
  // TODO(asuhan): use more compact data structure for m_entries
  private var m_entries: [GlyphDisplayListCacheKey: GlyphDisplayListCacheEntry] = [:]

  static var singleton = GlyphDisplayListCache()
}
