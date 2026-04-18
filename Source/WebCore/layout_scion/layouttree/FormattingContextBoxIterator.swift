/*
 * Copyright (C) 2024 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

class FormattingContextBoxIterator: LayoutDescendantIterator<BoxWrapper> {
  init(begin: UnsafeMutableRawPointer, end: UnsafeMutableRawPointer) {
    self.begin = begin
    self.end = end
    self.current = begin
  }

  deinit {
    wk_interop.FormattingContextBoxIterator_destroy(begin)
    wk_interop.FormattingContextBoxIterator_destroy(end)
  }

  override func next() -> BoxWrapper? {
    if wk_interop.FormattingContextBoxIterator_equal(current, end) {
      return nil
    }
    let boxRaw = wk_interop.FormattingContextBoxIterator_deref(current)
    let styleRaw = wk_interop.Box_style(boxRaw)
    let style = convert_render_style(p: styleRaw!)
    current = wk_interop.FormattingContextBoxIterator_preinc(current)!
    // TODO(asuhan): decide the type correctly
    let box = BoxWrapper(wrapperStyle: style)
    box.p = boxRaw
    return box
  }

  private let begin: UnsafeMutableRawPointer
  private let end: UnsafeMutableRawPointer
  private var current: UnsafeMutableRawPointer
}

class FormattingContextBoxIteratorAdapter: Sequence {
  init(root: ElementBoxWrapper) {
    if root.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    self.p = wk_interop.FormattingContextBoxIteratorAdapter_new(root.p)
  }

  deinit { wk_interop.FormattingContextBoxIteratorAdapter_destroy(p) }

  func makeIterator() -> FormattingContextBoxIterator {
    let begin = wk_interop.FormattingContextBoxIteratorAdapter_begin(p)
    let end = wk_interop.FormattingContextBoxIteratorAdapter_end(p)
    return FormattingContextBoxIterator(begin: begin!, end: end!)
  }

  private let p: UnsafeMutableRawPointer
}

internal func formattingContextBoxes(root: ElementBoxWrapper) -> FormattingContextBoxIteratorAdapter
{
  assert(root.establishesFormattingContext())
  return FormattingContextBoxIteratorAdapter(root: root)
}
