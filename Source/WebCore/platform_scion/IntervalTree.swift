/*
 * Copyright (C) 2025 Scion authors. All rights reserved.
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

// The adapter interface PODIntervalTree::allOverlapsWithAdapter expects.
protocol AdapterType {
  associatedtype Key
  associatedtype Value

  func lowValue() -> Key
  func highValue() -> Key
  func collectIfNeeded(low: Key, high: Key, data: Value)
}

// Same results as the upstream red-black PODIntervalTree: overlapping intervals are visited in
// increasing order of their low end. The tree takes its key ordering at construction, instead of a
// Comparable requirement, since generic types carrying a conformance requirement get null
// metadata in this build.
class IntervalTree<Key, Value> {
  init(less: @escaping (Key, Key) -> Bool) {
    self.less = less
  }

  func clear() {
    intervals.removeAll()
  }

  func add(low: Key, high: Key, _ data: Value) {
    // Keep the intervals sorted by their low end; equal ones stay in insertion order.
    var index = intervals.count
    while index > 0 && less(low, intervals[index - 1].low) {
      index -= 1
    }
    intervals.insert(Interval(low: low, high: high, data: data), at: index)
  }

  func allOverlapsWithAdapter<Adapter: AdapterType>(adapter: Adapter)
  where Adapter.Key == Key, Adapter.Value == Value {
    let low = adapter.lowValue()
    let high = adapter.highValue()
    for interval in intervals {
      // PODInterval::overlaps.
      if !(less(interval.high, low) || less(high, interval.low)) {
        adapter.collectIfNeeded(low: interval.low, high: interval.high, data: interval.data)
      }
    }
  }

  private struct Interval {
    let low: Key
    let high: Key
    let data: Value
  }

  private let less: (Key, Key) -> Bool
  private var intervals: [Interval] = []
}
