/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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

struct ComputedVerticalMargin {
  var before: LayoutUnit? = nil
  var after: LayoutUnit? = nil
}

struct UsedVerticalMargin {
  struct NonCollapsedValues {
    var before = LayoutUnit()
    var after = LayoutUnit()
  }
  var nonCollapsedValues = NonCollapsedValues()

  struct CollapsedValues {
    var before: LayoutUnit? = nil
    var after: LayoutUnit? = nil
    var isCollapsedThrough = false
  }
  var collapsedValues = CollapsedValues()

  // FIXME: This structure might need to change to indicate that the cached value is not necessarily the same as the box's computed margin value.
  // This only matters in case of collapse through margins when they collapse into another sibling box.
  // <div style="margin: 1px"></div><div style="margin: 10px"></div> <- the second div's before/after marings collapse through and the same time they collapse into
  // the first div. When the parent computes its before margin, it should see the second div's collapsed through margin as the value to collapse width (adjoining margin value).
  // So while the first div's before margin is not 10px, the cached value is 10px so that when we compute the parent's margin we just need to check the first
  // inflow child's cached margin values.
  struct PositiveAndNegativePair {
    struct Values {
      func isNonZero() -> Bool {
        return (positive ?? LayoutUnit(value: 0)).bool()
          || (negative ?? LayoutUnit(value: 0)).bool()
      }

      var positive: LayoutUnit? = nil
      var negative: LayoutUnit? = nil
      var isQuirk = false
    }
    var before = Values()
    var after = Values()
  }
  var positiveAndNegativeValues = PositiveAndNegativePair()
}

func marginBefore(usedVerticalMargin: UsedVerticalMargin) -> LayoutUnit {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func marginAfter(usedVerticalMargin: UsedVerticalMargin) -> LayoutUnit {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

struct ComputedHorizontalMargin {
  var start: LayoutUnit? = nil
  var end: LayoutUnit? = nil
}

struct UsedHorizontalMargin {
  init(start: LayoutUnit, end: LayoutUnit) {
    self.start = start
    self.end = end
  }

  init() {}

  var start = LayoutUnit()
  var end = LayoutUnit()
}

struct PrecomputedMarginBefore {
  func usedValue() -> LayoutUnit {
    return collapsedValue ?? nonCollapsedValue
  }

  var nonCollapsedValue = LayoutUnit()
  var collapsedValue: LayoutUnit? = nil
  var positiveAndNegativeMarginBefore = UsedVerticalMargin.PositiveAndNegativePair.Values()
}
