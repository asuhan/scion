/*
 * Copyright (C) 2023 Apple Inc.
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

// These classes are used to implement the Baseline Alignment logic, as described in the CSS Box Alignment
// specification.
// https://drafts.csswg.org/css-align/#baseline-terms
//
// A baseline-sharing group is composed of boxes that participate in baseline alignment together. This is
// possible only if they:
//
//   * Share an alignment context along an axis perpendicular to their baseline alignment axis.
//   * Have compatible baseline alignment preferences (i.e., the baselines that want to align are on the same
//     side of the alignment context).
//
// Once the BaselineGroup is instantiated, defined by a 'block flow direction' and a 'baseline-preference'
// (first/last baseline), it's ready to collect the items that will participate in the Baseline Alignment logic.
//
class BaselineGroup: Sequence, IteratorProtocol {
  init(blockFlow: FlowDirection, childPreference: ItemPosition) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func next() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let maxAscent: LayoutUnit
}

//
// BaselineAlignmentState provides an API to interact with baseline sharing groups in various
// ways such as adding items to appropriate ones and querying the baseline sharing group for
// an item. A BaselineAlignmentState should be created by a formatting context to use for each
// of its baseline alignment contexts.
//
// https://drafts.csswg.org/css-align-3/#baseline-sharing-group
// A Baseline alignment-context may handle several baseline-sharing groups. In order to create an instance, we
// need to pass the required data to define the first baseline-sharing group; a BaselineAlignmentState must have at
// least one baseline-sharing group.
//
// By adding new items to a BaselineAlignmentState, the baseline-sharing groups it handles are automatically updated,
// if there is one that is compatible with such item. Otherwise, a new baseline-sharing group is created,
// compatible with the new item.
struct BaselineAlignmentState {
  init(child: RenderBoxWrapper, preference: ItemPosition, ascent: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Updates the baseline-sharing group compatible with the item.
  // We pass the item's baseline-preference to avoid dependencies with the LayoutGrid class, which is the one
  // managing the alignment behavior of the Grid Items.
  func updateSharedGroup(child: RenderBoxWrapper, preference: ItemPosition, ascent: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let sharedGroups: [BaselineGroup]
}
