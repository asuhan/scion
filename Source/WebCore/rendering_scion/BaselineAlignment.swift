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
  // It stores an item (if not already present) and update the max_ascent associated to this
  // baseline-sharing group.
  func update(_ child: RenderBoxWrapper, _ ascent: LayoutUnit) {
    if m_items.add(value: child).isNewEntry {
      maxAscent = Swift.max(maxAscent, ascent)
    }
  }

  init(blockFlow: FlowDirection, childPreference: ItemPosition) {
    maxAscent = LayoutUnit(value: 0)
    m_items = WeakHashSet<RenderBoxWrapper>()
    m_blockFlow = blockFlow
    m_preference = childPreference
  }

  func computeSize() -> Int32 { return Int32(m_items.computeSize()) }

  func next() -> RenderBoxWrapper? { return m_items.next() }

  // Determines whether a baseline-sharing group is compatible with an item, based on its 'block-flow' and
  // 'baseline-preference'
  func isCompatible(_ childBlockFlow: FlowDirection, _ childPreference: ItemPosition)
    -> Bool
  {
    assert(isBaselinePosition(position: childPreference))
    assert(computeSize() > 0)
    return
      ((m_blockFlow == childBlockFlow || isOrthogonalBlockFlow(childBlockFlow))
      && m_preference == childPreference)
      || (isOppositeBlockFlow(childBlockFlow) && m_preference != childPreference)
  }

  // Determines whether the baseline-sharing group's associated block-flow is opposite (LR vs RL) to particular
  // item's writing-mode.
  private func isOppositeBlockFlow(_ blockFlow: FlowDirection) -> Bool {
    switch blockFlow {
    case .TopToBottom:
      return false
    case .LeftToRight:
      return m_blockFlow == .RightToLeft
    case .RightToLeft:
      return m_blockFlow == .LeftToRight
    default:
      fatalError("Not reached")
    }
  }

  // Determines whether the baseline-sharing group's associated block-flow is orthogonal (vertical vs horizontal)
  // to particular item's writing-mode.
  private func isOrthogonalBlockFlow(_ blockFlow: FlowDirection) -> Bool {
    switch blockFlow {
    case .TopToBottom:
      return m_blockFlow != .TopToBottom
    case .LeftToRight, .RightToLeft:
      return m_blockFlow == .TopToBottom
    default:
      fatalError("Not reached")
    }
  }

  private let m_blockFlow: FlowDirection
  private let m_preference: ItemPosition
  var maxAscent: LayoutUnit
  private let m_items: WeakHashSet<RenderBoxWrapper>
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
    assert(isBaselinePosition(position: preference))
    updateSharedGroup(child: child, preference: preference, ascent: ascent)
  }

  func sharedGroup(child: RenderBoxWrapper, preference: ItemPosition) -> BaselineGroup {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Updates the baseline-sharing group compatible with the item.
  // We pass the item's baseline-preference to avoid dependencies with the LayoutGrid class, which is the one
  // managing the alignment behavior of the Grid Items.
  mutating func updateSharedGroup(
    child: RenderBoxWrapper, preference: ItemPosition, ascent: LayoutUnit
  ) {
    assert(isBaselinePosition(position: preference))
    let group = findCompatibleSharedGroup(child, preference)
    group.update(child, ascent)
  }

  // Returns the baseline-sharing group compatible with an item.
  // We pass the item's baseline-preference to avoid dependencies with the LayoutGrid class, which is the one
  // managing the alignment behavior of the Grid Items.
  // FIXME: Properly implement baseline-group compatibility.
  // See https://github.com/w3c/csswg-drafts/issues/721
  private mutating func findCompatibleSharedGroup(
    _ child: RenderBoxWrapper, _ preference: ItemPosition
  )
    -> BaselineGroup
  {
    let blockFlowDirection = child.style().blockFlowDirection()
    for group in sharedGroups {
      if group.isCompatible(blockFlowDirection, preference) {
        return group
      }
    }
    sharedGroups.insert(
      BaselineGroup(blockFlow: blockFlowDirection, childPreference: preference), at: 0)
    return sharedGroups[0]
  }

  var sharedGroups: [BaselineGroup] = []
}

enum AllowedBaseLine {
  case FirstLine
  case LastLine
  case BothLines
}

func isBaselinePosition(position: ItemPosition) -> Bool {
  return position == .Baseline || position == .LastBaseline
}

func isFirstBaselinePosition(position: ItemPosition) -> Bool {
  return position == .Baseline
}
