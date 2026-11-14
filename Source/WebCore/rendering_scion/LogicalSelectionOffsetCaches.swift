/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
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

import wk_interop

class LogicalSelectionOffsetCaches {
  struct ContainingBlockInfo {
    init() {
      self.m_hasFloatsOrFragmentedFlows = false
      self.cachedLogicalLeftSelectionOffset = false
      self.cachedLogicalRightSelectionOffset = false
      self.logicalLeftSelectionOffset = LayoutUnit()
      self.logicalRightSelectionOffset = LayoutUnit()
    }

    mutating func setBlock(
      block: RenderBlockWrapper?, cache: LogicalSelectionOffsetCaches?,
      parentCacheHasFloatsOrFragmentedFlows: Bool = false
    ) {
      m_block = block
      let blockHasFloatsOrFragmentedFlows: Bool =
        m_block != nil
        ? (m_block!.containsFloats() || m_block!.enclosingFragmentedFlow() != nil) : false
      m_hasFloatsOrFragmentedFlows =
        parentCacheHasFloatsOrFragmentedFlows || m_hasFloatsOrFragmentedFlows
        || blockHasFloatsOrFragmentedFlows
      m_cache = cache
      cachedLogicalLeftSelectionOffset = false
      cachedLogicalRightSelectionOffset = false
    }

    mutating func logicalLeftSelectionOffset(rootBlock: RenderBlockWrapper, position: LayoutUnit)
      -> LayoutUnit
    {
      assert(m_cache != nil)
      if m_hasFloatsOrFragmentedFlows || !cachedLogicalLeftSelectionOffset {
        cachedLogicalLeftSelectionOffset = true
        logicalLeftSelectionOffset =
          m_block != nil
          ? m_block!.logicalLeftSelectionOffset(
            rootBlock: rootBlock, position: position, cache: m_cache!) : LayoutUnit(value: 0)
      } else {
        assert(
          logicalLeftSelectionOffset
            == (m_block != nil
              ? m_block!.logicalLeftSelectionOffset(
                rootBlock: rootBlock, position: position, cache: m_cache!) : LayoutUnit(value: 0)))
      }
      return logicalLeftSelectionOffset
    }

    mutating func logicalRightSelectionOffset(rootBlock: RenderBlockWrapper, position: LayoutUnit)
      -> LayoutUnit
    {
      assert(m_cache != nil)
      if m_hasFloatsOrFragmentedFlows || !cachedLogicalRightSelectionOffset {
        cachedLogicalRightSelectionOffset = true
        logicalRightSelectionOffset =
          m_block != nil
          ? m_block!.logicalRightSelectionOffset(
            rootBlock: rootBlock, position: position, cache: m_cache!) : LayoutUnit(value: 0)
      } else {
        assert(
          logicalRightSelectionOffset
            == (m_block != nil
              ? m_block!.logicalRightSelectionOffset(
                rootBlock: rootBlock, position: position, cache: m_cache!) : LayoutUnit(value: 0)))
      }
      return logicalRightSelectionOffset
    }

    func block() -> RenderBlockWrapper? {
      return m_block
    }

    func cache() -> LogicalSelectionOffsetCaches? {
      return m_cache
    }

    func hasFloatsOrFragmentedFlows() -> Bool {
      return m_hasFloatsOrFragmentedFlows
    }

    private var m_block: RenderBlockWrapper? = nil
    private var m_cache: LogicalSelectionOffsetCaches? = nil
    private var m_hasFloatsOrFragmentedFlows: Bool = false
    private var cachedLogicalLeftSelectionOffset: Bool = false
    private var cachedLogicalRightSelectionOffset: Bool = false
    private var logicalLeftSelectionOffset: LayoutUnit
    private var logicalRightSelectionOffset: LayoutUnit
  }

  init(rootBlock: RenderBlockWrapper) {
    self.containingBlockForFixedPosition = ContainingBlockInfo()
    self.containingBlockForAbsolutePosition = ContainingBlockInfo()
    self.containingBlockForInflowPosition = ContainingBlockInfo()
    // FIXME: We should either move this assertion to the caller (if applicable) or structure the code
    // such that we can remove this assertion.
    assert(rootBlock.isSelectionRoot())
    // LogicalSelectionOffsetCaches should not be used on an orphaned tree.
    containingBlockForFixedPosition.setBlock(
      block: RenderObjectWrapper.containingBlockForPositionType(
        positionType: .Fixed, renderer: rootBlock), cache: nil)
    containingBlockForAbsolutePosition.setBlock(
      block: RenderObjectWrapper.containingBlockForPositionType(
        positionType: .Absolute, renderer: rootBlock), cache: nil)
    containingBlockForInflowPosition.setBlock(
      block: RenderObjectWrapper.containingBlockForPositionType(
        positionType: .Static, renderer: rootBlock), cache: nil)
  }

  init(block: RenderBlockWrapper, cache: LogicalSelectionOffsetCaches) {
    self.containingBlockForFixedPosition = cache.containingBlockForFixedPosition
    self.containingBlockForAbsolutePosition = cache.containingBlockForAbsolutePosition
    self.containingBlockForInflowPosition = ContainingBlockInfo()
    if block.canContainFixedPositionObjects() {
      containingBlockForFixedPosition.setBlock(
        block: block, cache: cache,
        parentCacheHasFloatsOrFragmentedFlows: cache.containingBlockForFixedPosition
          .hasFloatsOrFragmentedFlows())
    }
    if block.canContainAbsolutelyPositionedObjects() && !block.isRenderInline()
      && !block.isAnonymousBlock()
    {
      containingBlockForAbsolutePosition.setBlock(
        block: block, cache: cache,
        parentCacheHasFloatsOrFragmentedFlows: cache.containingBlockForAbsolutePosition
          .hasFloatsOrFragmentedFlows())
    }
    containingBlockForInflowPosition.setBlock(
      block: block, cache: cache,
      parentCacheHasFloatsOrFragmentedFlows: cache.containingBlockForInflowPosition
        .hasFloatsOrFragmentedFlows())
  }

  func containingBlockInfo(block: RenderBlockWrapper) -> ContainingBlockInfo {
    let position = block.style().position()
    if position == .Fixed {
      assert(
        CPtrToInt(block.containingBlock()?.id())
          == CPtrToInt(containingBlockForFixedPosition.block()?.id()))
      return containingBlockForFixedPosition
    }
    if position == .Absolute {
      assert(
        CPtrToInt(block.containingBlock()?.id())
          == CPtrToInt(containingBlockForAbsolutePosition.block()?.id()))
      return containingBlockForAbsolutePosition
    }
    assert(
      CPtrToInt(block.containingBlock()?.id())
        == CPtrToInt(containingBlockForInflowPosition.block()?.id()))
    return containingBlockForInflowPosition
  }

  private var containingBlockForFixedPosition: ContainingBlockInfo
  private var containingBlockForAbsolutePosition: ContainingBlockInfo
  private var containingBlockForInflowPosition: ContainingBlockInfo
}
