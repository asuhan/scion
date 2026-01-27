/*
 * Copyright (C) 2019-2021 Apple Inc. All rights reserved.
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

  class Box {
    func isText() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isRootInlineBox() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func visualRect() -> FloatRectWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func visualRectIgnoringBlockDirection() -> FloatRectWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func logicalTop() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func logicalBottom() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func logicalWidth() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    // Return visual left/right coords in inline direction (they are still considered logical values as there's no flip for writing mode).
    func logicalLeftIgnoringInlineDirection() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func logicalRightIgnoringInlineDirection() -> Float32 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func isHorizontal() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func renderer() -> RenderObjectWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func style() -> RenderStyleWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    // FIXME: Remove. For intermediate porting steps only.
    func legacyInlineBox() -> LegacyInlineBox? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func previousOnLine() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func parentInlineBox() -> InlineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func lineBox() -> LineBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func modernPath() -> BoxModernPath {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  class BoxIterator: Equatable {
    func bool() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    static func == (self: BoxIterator, other: BoxIterator) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func get() -> Box {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  class LeafBoxIterator: BoxIterator {
    @discardableResult
    func traverseNextOnLine() -> LeafBoxIterator {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

}
