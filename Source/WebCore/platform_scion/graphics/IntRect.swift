/*
 * Copyright (C) 2003, 2006, 2009 Apple Inc. All rights reserved.
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

struct IntRect {
  init() {
    location = IntPoint()
    size = IntSize()
  }

  init(location: IntPoint, size: IntSize) {
    self.location = location
    self.size = size
  }

  func x() -> Int32 { return location.x }
  func y() -> Int32 { return location.y }
  func maxX() -> Int32 { return x() + width() }
  func maxY() -> Int32 { return y() + height() }
  func width() -> Int32 { return size.width }
  func height() -> Int32 { return size.height }

  func isEmpty() -> Bool { return size.isEmpty() }

  mutating func moveBy(offset: IntPoint) {
    location.move(dx: offset.x, dy: offset.y)
  }

  var location: IntPoint
  let size: IntSize
}

func intersection(a: IntRect, b: IntRect) -> IntRect {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
