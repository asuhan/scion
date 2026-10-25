/**
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
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
 */

#pragma once

#include "RenderStyleInlines.h"
#include "RenderTable.h"

namespace WebCore {

inline RectEdges<LayoutUnit> RenderTable::borderWidths() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return {
        borderTop(),
        borderRight(),
        borderBottom(),
        borderLeft()
    };
}

inline LayoutUnit RenderTable::bordersPaddingAndSpacingInRowDirection() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    // 'border-spacing' only applies to separate borders (see 17.6.1 The separated borders model).
    return borderStart() + borderEnd() + (collapseBorders() ? 0_lu : (paddingStart() + paddingEnd() + borderSpacingInRowDirection()));
}

inline LayoutUnit RenderTable::outerBorderBottom() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        return style().isFlippedBlocksWritingMode() ? outerBorderBefore() : outerBorderAfter();
    return style().isLeftToRightDirection() ? outerBorderEnd() : outerBorderStart();
}

inline LayoutUnit RenderTable::outerBorderLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        return style().isLeftToRightDirection() ? outerBorderStart() : outerBorderEnd();
    return style().isFlippedBlocksWritingMode() ? outerBorderAfter() : outerBorderBefore();
}

inline LayoutUnit RenderTable::outerBorderRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        return style().isLeftToRightDirection() ? outerBorderEnd() : outerBorderStart();
    return style().isFlippedBlocksWritingMode() ? outerBorderBefore() : outerBorderAfter();
}

inline LayoutUnit RenderTable::outerBorderTop() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        return style().isFlippedBlocksWritingMode() ? outerBorderAfter() : outerBorderBefore();
    return style().isLeftToRightDirection() ? outerBorderStart() : outerBorderEnd();
}

} // namespace WebCore
