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

  private func updateTextRenderer(builder: RenderTreeBuilder) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var type: QuoteType = .OpenQuote
  private var m_depth: Int32 = -1
  private var text = emptyString()

  private var needsTextUpdate = false
}
