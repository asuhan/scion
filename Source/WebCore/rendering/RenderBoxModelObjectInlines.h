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
 *
 */

#pragma once

#include "RenderBoxModelObject.h"
#include "RenderStyleInlines.h"

namespace WebCore {

inline LayoutUnit RenderBoxModelObject::borderAfter() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderAfterWidth());
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingAfter() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderAfter() + paddingAfter();
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingBefore() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderBefore() + paddingBefore();
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderAndPaddingBefore() + borderAndPaddingAfter();
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingLogicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderStart() + borderEnd() + paddingStart() + paddingEnd();
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingLogicalLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? borderLeft() + paddingLeft() : borderTop() + paddingTop();
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingLogicalRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? borderRight() + paddingRight() : borderBottom() + paddingBottom();
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingStart() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderStart() + paddingStart();
}
inline LayoutUnit RenderBoxModelObject::borderAndPaddingEnd() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderEnd() + paddingEnd();
}
inline LayoutUnit RenderBoxModelObject::borderBefore() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderBeforeWidth());
}
inline LayoutUnit RenderBoxModelObject::borderBottom() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderBottomWidth());
}
inline LayoutUnit RenderBoxModelObject::borderEnd() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderEndWidth());
}
inline LayoutUnit RenderBoxModelObject::borderLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderLeftWidth());
}
inline LayoutUnit RenderBoxModelObject::borderLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderBefore() + borderAfter();
}
inline LayoutUnit RenderBoxModelObject::borderLogicalRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? borderRight() : borderBottom();
}
inline LayoutUnit RenderBoxModelObject::borderLogicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderStart() + borderEnd();
}
inline LayoutUnit RenderBoxModelObject::borderRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderRightWidth());
}
inline LayoutUnit RenderBoxModelObject::borderStart() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderStartWidth());
}
inline LayoutUnit RenderBoxModelObject::borderTop() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutUnit(style().borderTopWidth());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingAfter() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingAfter());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingBefore() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingBefore());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingBottom() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingBottom());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingEnd() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingEnd());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingLeft());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingRight());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingStart() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingStart());
}
inline LayoutUnit RenderBoxModelObject::computedCSSPaddingTop() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return resolveLengthPercentageUsingContainerLogicalWidth(style().paddingTop());
}
inline bool RenderBoxModelObject::hasInlineDirectionBordersOrPadding() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderStart() || borderEnd() || paddingStart() || paddingEnd();
}
inline bool RenderBoxModelObject::hasInlineDirectionBordersPaddingOrMargin() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return hasInlineDirectionBordersOrPadding() || marginStart() || marginEnd();
}
inline LayoutUnit RenderBoxModelObject::horizontalBorderAndPaddingExtent() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderLeft() + borderRight() + paddingLeft() + paddingRight();
}
inline LayoutUnit RenderBoxModelObject::horizontalBorderExtent() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderLeft() + borderRight();
}
inline LayoutUnit RenderBoxModelObject::marginAndBorderAndPaddingAfter() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return marginAfter() + borderAfter() + paddingAfter();
}
inline LayoutUnit RenderBoxModelObject::marginAndBorderAndPaddingBefore() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return marginBefore() + borderBefore() + paddingBefore();
}
inline LayoutUnit RenderBoxModelObject::marginAndBorderAndPaddingEnd() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return marginEnd() + borderEnd() + paddingEnd();
}
inline LayoutUnit RenderBoxModelObject::marginAndBorderAndPaddingStart() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return marginStart() + borderStart() + paddingStart();
}
inline LayoutUnit RenderBoxModelObject::paddingAfter() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingAfter();
}
inline LayoutUnit RenderBoxModelObject::paddingBefore() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingBefore();
}
inline LayoutUnit RenderBoxModelObject::paddingBottom() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingBottom();
}
inline LayoutUnit RenderBoxModelObject::paddingEnd() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingEnd();
}
inline LayoutUnit RenderBoxModelObject::paddingLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingLeft();
}
inline LayoutUnit RenderBoxModelObject::paddingLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return paddingBefore() + paddingAfter();
}
inline LayoutUnit RenderBoxModelObject::paddingLogicalLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? paddingLeft() : paddingTop();
}
inline LayoutUnit RenderBoxModelObject::paddingLogicalRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? paddingRight() : paddingBottom();
}
inline LayoutUnit RenderBoxModelObject::paddingLogicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return paddingStart() + paddingEnd();
}
inline LayoutUnit RenderBoxModelObject::paddingRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingRight();
}
inline LayoutUnit RenderBoxModelObject::paddingStart() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingStart();
}
inline LayoutUnit RenderBoxModelObject::paddingTop() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return computedCSSPaddingTop();
}
inline LayoutSize RenderBoxModelObject::relativePositionLogicalOffset() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? relativePositionOffset() : relativePositionOffset().transposedSize();
}
inline LayoutSize RenderBoxModelObject::stickyPositionLogicalOffset() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? stickyPositionOffset() : stickyPositionOffset().transposedSize();
}
inline LayoutUnit RenderBoxModelObject::verticalBorderAndPaddingExtent() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderTop() + borderBottom() + paddingTop() + paddingBottom();
}
inline LayoutUnit RenderBoxModelObject::verticalBorderExtent() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderTop() + borderBottom();
}

inline RectEdges<LayoutUnit> RenderBoxModelObject::borderWidths() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return {
        LayoutUnit(style().borderTopWidth()),
        LayoutUnit(style().borderRightWidth()),
        LayoutUnit(style().borderBottomWidth()),
        LayoutUnit(style().borderLeftWidth())
    };
}

RectEdges<LayoutUnit> RenderBoxModelObject::padding() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return {
        computedCSSPaddingTop(),
        computedCSSPaddingRight(),
        computedCSSPaddingBottom(),
        computedCSSPaddingLeft()
    };
}

inline LayoutUnit RenderBoxModelObject::resolveLengthPercentageUsingContainerLogicalWidth(const Length& value) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    LayoutUnit containerWidth;
    if (value.isPercentOrCalculated())
        containerWidth = containingBlockLogicalWidthForContent();
    return minimumValueForLength(value, containerWidth);
}

} // namespace WebCore
