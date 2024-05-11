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

struct HorizontalConstraints {
  func logicalRight() -> LayoutUnit {
    return logicalLeft + logicalWidth
  }

  var logicalLeft = LayoutUnit()
  var logicalWidth = LayoutUnit()
}

struct VerticalConstraints {
  var logicalTop = LayoutUnit()
  var logicalHeight = LayoutUnit()
}

class ConstraintsForInFlowContent {
  convenience init(horizontal: HorizontalConstraints, logicalTop: LayoutUnit) {
    self.init(
      horizontal: horizontal, logicalTop: logicalTop, baseTypeFlags: BaseTypeFlag.GenericContent)
  }

  init(horizontal: HorizontalConstraints, logicalTop: LayoutUnit, baseTypeFlags: BaseTypeFlag) {
    self.baseTypeFlags = UInt32(baseTypeFlags.rawValue)
    self.horizontal = horizontal
    self.logicalTop = logicalTop
  }

  struct BaseTypeFlag: OptionSet {
    let rawValue: UInt8
    static let GenericContent = BaseTypeFlag(rawValue: 1 << 0)
    static let InlineContent = BaseTypeFlag(rawValue: 1 << 1)
    static let TableContent = BaseTypeFlag(rawValue: 1 << 2)
    static let FlexContent = BaseTypeFlag(rawValue: 1 << 3)
  }

  private var baseTypeFlags: UInt32
  var horizontal = HorizontalConstraints()
  var logicalTop = LayoutUnit()
}

struct ConstraintsForOutOfFlowContent {
  var horizontal = HorizontalConstraints()
  var vertical = VerticalConstraints()
  // Borders and padding are resolved against the containing block's content box as if the box was an in-flow box.
  var borderAndPaddingConstraints = LayoutUnit()
}

enum IntrinsicWidthMode {
  case Minimum
  case Maximum
}

struct IntrinsicWidthConstraints {
  mutating func expand(horizontalValue: LayoutUnit) {
    minimum += horizontalValue
    maximum += horizontalValue
  }

  var minimum = LayoutUnit()
  var maximum = LayoutUnit()
}
