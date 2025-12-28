/*
 * Copyright (C) 2011 Nokia Inc.  All rights reserved.
 * Copyright (C) 2012 Google Inc. All rights reserved.
 * Copyright (C) 2013, 2017 Apple Inc. All rights reserved.
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

// These strings need to be compared according to "Extended Filtering", as in Section 3.3.2 in RFC4647.
// https://tools.ietf.org/html/rfc4647#page-10
//
// The "checkFurther" field is needed in one specific situation.
// In the quoteTable below, there are lines like:
// { "de"   , 0x201e, 0x201c, 0x201a, 0x2018 },
// { "de-ch", 0x00ab, 0x00bb, 0x2039, 0x203a },
// Let's say the binary search arbitrarily decided to test our key against the upper line "de" first.
// If the key we're testing against is "de-ch", then we should report "greater than",
// so the binary search will keep searching and eventually find the "de-ch" line.
// However, if the key we're testing against is "de-de", then we should report "equal to",
// because these are the quotes we should use for all "de" except for "de-ch".
struct QuotesForLanguage {
  let language: String
  let checkFurther: UChar
  let open1: UChar
  let close1: UChar
  let open2: UChar
  let close2: UChar
}

private func quotesForLanguage(language: AtomStringWrapper) -> QuotesForLanguage? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func stringForQuoteCharacter(character: UChar) -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func quotationMarkString() -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func apostropheString() -> StringWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class RenderQuoteWrapper: RenderInlineWrapper {
  init(document: Document, style: RenderStyleWrapper, quote: QuoteType) {
    super.init(type: .Quote, document: document, style: style)
    type = quote
    assert(isRenderQuote())
  }

  func updateRenderer(builder: RenderTreeBuilder, previousQuote: RenderQuoteWrapper?) {
    assert(document().inRenderTreeUpdate())
    var depth: Int32 = -1
    if previousQuote != nil {
      depth = previousQuote!.m_depth
      if previousQuote!.isOpen() {
        depth += 1
      }
    }

    if !isOpen() {
      depth -= 1
    } else if depth < 0 {
      depth = 0
    }

    if m_depth == depth && !needsTextUpdate {
      return
    }

    m_depth = depth
    needsTextUpdate = false
    updateTextRenderer(builder: builder)
  }

  private func isOpen() -> Bool {
    switch type {
    case .OpenQuote, .NoOpenQuote:
      return true
    case .CloseQuote, .NoCloseQuote:
      return false
    }
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeText() -> StringWrapper {
    if m_depth < 0 {
      return emptyString()
    }
    var isOpenQuote = false
    switch type {
    case .NoOpenQuote, .NoCloseQuote:
      return emptyString()
    case .OpenQuote:
      isOpenQuote = true
      fallthrough
    case .CloseQuote:
      if let quotes = style().quotes() {
        return isOpenQuote
          ? quotes.openQuote(index: UInt32(m_depth)) : quotes.closeQuote(index: UInt32(m_depth))
      }
      if let quotes = quotesForLanguage(language: style().computedLocale()) {
        return stringForQuoteCharacter(
          character: isOpenQuote
            ? (m_depth != 0 ? quotes.open2 : quotes.open1)
            : (m_depth != 0 ? quotes.close2 : quotes.close1))
      }
      // FIXME: Should the default be the quotes for "en" rather than straight quotes?
      // (According to https://html.spec.whatwg.org/multipage/rendering.html#quotes, the answer is "yes".)
      return m_depth != 0 ? apostropheString() : quotationMarkString()
    }
  }

  private func updateTextRenderer(builder: RenderTreeBuilder) {
    assert(document().inRenderTreeUpdate())
    let text = computeText()
    if m_text == text {
      return
    }
    m_text = text
    if let renderText = lastChild() as? RenderTextFragmentWrapper {
      renderText.setContentString(text: m_text)
      renderText.dirtyLegacyLineBoxes(fullLayout: false)
      return
    }
    builder.attach(
      parent: self, child: CreateRenderer.RenderTextFragment(document: document(), text: m_text))
  }

  private var type: QuoteType = .OpenQuote
  private var m_depth: Int32 = -1
  private var m_text = emptyString()

  private var needsTextUpdate = false
}
