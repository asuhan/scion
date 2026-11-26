/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

extension InlineIterator {
  struct TextLogicalOrderCacheData {
    var boxes: [TextBox] = []
    var index: UInt64 = 0
  }

  // Upstream's std::unique_ptr<TextLogicalOrderCacheData>, null when data is nil.
  class TextLogicalOrderCache {
    var data: TextLogicalOrderCacheData? = nil
  }

  private static func makeTextLogicalOrderCacheIfNeeded(_ text: RenderTextWrapper)
    -> TextLogicalOrderCacheData?
  {
    if !text.needsVisualReordering() {
      return nil
    }

    var cache = TextLogicalOrderCacheData()
    for textBox in textBoxesFor(text) {
      cache.boxes.append(textBox)
    }

    if cache.boxes.isEmpty {
      return nil
    }

    cache.boxes.sort(by: { a, b in a.start() < b.start() })

    return cache
  }

  private static func updateTextLogicalOrderCacheIfNeeded(
    _ textBox: TextBoxIterator, _ cache: TextLogicalOrderCache
  ) {
    if cache.data == nil {
      cache.data = makeTextLogicalOrderCacheIfNeeded(textBox.get().renderer())
      if cache.data == nil {
        return
      }
    }

    let data = cache.data!
    if data.index < UInt64(data.boxes.count)
      && TextBoxIterator(data.boxes[Int(data.index)]) == textBox
    {
      return
    }

    guard let index = data.boxes.firstIndex(where: { TextBoxIterator($0) == textBox }) else {
      cache.data = nil
      updateTextLogicalOrderCacheIfNeeded(textBox, cache)
      return
    }
    cache.data!.index = UInt64(index)
  }

  struct LineLogicalOrderCacheData {
    var lineBox: LineBoxIterator
    var boxes: [LeafBoxIterator]
    var index: Int = 0
  }

  class LineLogicalOrderCache {
    var data: LineLogicalOrderCacheData? = nil
  }

  static func firstTextBoxInLogicalOrderFor(_ text: RenderTextWrapper) -> (
    TextBoxIterator, TextLogicalOrderCache
  ) {
    let cache = TextLogicalOrderCache()
    if let data = makeTextLogicalOrderCacheIfNeeded(text) {
      cache.data = data
      return (TextBoxIterator(data.boxes.first!), cache)
    }

    return (firstTextBoxFor(text), cache)
  }

  static func nextTextBoxInLogicalOrder(
    _ textBox: TextBoxIterator, _ cache: TextLogicalOrderCache
  ) -> TextBoxIterator {
    updateTextLogicalOrderCacheIfNeeded(textBox, cache)

    if cache.data == nil {
      return textBox.get().nextTextBox()
    }

    cache.data!.index += 1

    if cache.data!.index < UInt64(cache.data!.boxes.count) {
      return TextBoxIterator(cache.data!.boxes[Int(cache.data!.index)])
    }

    return TextBoxIterator()
  }

  // Iterators are mutable references here: the cache keeps copies and hands out copies, so
  // callers advancing a returned iterator leave the cached boxes alone.
  static func leafBoxesInLogicalOrder(
    _ lineBox: LineBoxIterator, _ reverseFunction: (inout [LeafBoxIterator], Range<Int>) -> Void
  ) -> [LeafBoxIterator] {
    var boxes: [LeafBoxIterator] = []

    var minLevel: UInt8 = 128
    var maxLevel: UInt8 = 0

    let box = lineBox.get().firstLeafBox()
    while box.bool() {
      minLevel = min(minLevel, box.get().bidiLevel())
      maxLevel = max(maxLevel, box.get().bidiLevel())
      boxes.append(LeafBoxIterator(box.get()))
      box.traverseNextOnLine()
    }

    if lineBox.get().formattingContextRoot().style().rtlOrdering() == .Visual {
      return boxes
    }

    // Reverse of reordering of the line (L2 according to Bidi spec):
    // L2. From the highest level found in the text to the lowest odd level on each line,
    // reverse any contiguous sequence of characters that are at that level or higher.

    // Reversing the reordering of the line is only done up to the lowest odd level.
    if minLevel % 2 == 0 {
      minLevel += 1
    }

    let end = boxes.count
    while minLevel <= maxLevel {
      var box = 0
      while box < end {
        while box < end && boxes[box].get().bidiLevel() < minLevel {
          box += 1
        }

        let first = box
        while box < end && boxes[box].get().bidiLevel() >= minLevel {
          box += 1
        }

        let last = box
        reverseFunction(&boxes, first..<last)
      }
      minLevel += 1
    }

    return boxes
  }

  private static func makeLineLogicalOrderCache(_ lineBox: LineBoxIterator)
    -> LineLogicalOrderCacheData
  {
    return LineLogicalOrderCacheData(
      lineBox: LineBoxIterator(lineBox.get()),
      boxes: leafBoxesInLogicalOrder(lineBox, { boxes, range in boxes[range].reverse() }))
  }

  private static func updateLineLogicalOrderCacheIfNeeded(
    _ box: LeafBoxIterator, _ cache: LineLogicalOrderCache
  ) {
    let lineBox = box.get().lineBox()
    if cache.data == nil || cache.data!.lineBox != lineBox {
      cache.data = makeLineLogicalOrderCache(lineBox)
    }

    if cache.data!.index < cache.data!.boxes.count && cache.data!.boxes[cache.data!.index] == box {
      return
    }

    let index = cache.data!.boxes.firstIndex(where: { $0 == box })
    assert(index != nil)
    cache.data!.index = index ?? cache.data!.boxes.count
  }

  static func firstLeafOnLineInLogicalOrder(
    _ lineBox: LineBoxIterator, _ cache: LineLogicalOrderCache
  ) -> LeafBoxIterator {
    cache.data = makeLineLogicalOrderCache(lineBox)

    guard let first = cache.data!.boxes.first else {
      return LeafBoxIterator()
    }

    cache.data!.index = 0
    return LeafBoxIterator(first.get())
  }

  static func lastLeafOnLineInLogicalOrder(
    _ lineBox: LineBoxIterator, _ cache: LineLogicalOrderCache
  ) -> LeafBoxIterator {
    cache.data = makeLineLogicalOrderCache(lineBox)

    guard let last = cache.data!.boxes.last else {
      return LeafBoxIterator()
    }

    cache.data!.index = cache.data!.boxes.count - 1
    return LeafBoxIterator(last.get())
  }

  static func nextLeafOnLineInLogicalOrder(_ box: LeafBoxIterator, _ cache: LineLogicalOrderCache)
    -> LeafBoxIterator
  {
    updateLineLogicalOrderCacheIfNeeded(box, cache)

    cache.data!.index += 1

    if cache.data!.index < cache.data!.boxes.count {
      return LeafBoxIterator(cache.data!.boxes[cache.data!.index].get())
    }

    return LeafBoxIterator()
  }

  static func previousLeafOnLineInLogicalOrder(
    _ box: LeafBoxIterator, _ cache: LineLogicalOrderCache
  ) -> LeafBoxIterator {
    updateLineLogicalOrderCacheIfNeeded(box, cache)

    if cache.data!.index == 0 {
      return LeafBoxIterator()
    }

    cache.data!.index -= 1

    return LeafBoxIterator(cache.data!.boxes[cache.data!.index].get())
  }

  static func firstLeafOnLineInLogicalOrderWithNode(
    _ lineBox: LineBoxIterator, _ cache: LineLogicalOrderCache
  ) -> LeafBoxIterator {
    var box = firstLeafOnLineInLogicalOrder(lineBox, cache)
    while box.bool() && box.get().renderer().node() == nil {
      box = nextLeafOnLineInLogicalOrder(box, cache)
    }
    return box
  }

  static func lastLeafOnLineInLogicalOrderWithNode(
    _ lineBox: LineBoxIterator, _ cache: LineLogicalOrderCache
  ) -> LeafBoxIterator {
    var box = lastLeafOnLineInLogicalOrder(lineBox, cache)
    while box.bool() && box.get().renderer().node() == nil {
      box = previousLeafOnLineInLogicalOrder(box, cache)
    }
    return box
  }
}
