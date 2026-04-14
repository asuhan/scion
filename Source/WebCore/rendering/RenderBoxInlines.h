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

#include "RenderBox.h"
#include "RenderBoxScion.h"
#include "RenderBoxModelObjectInlines.h"

namespace WebCore {

inline LayoutUnit RenderBox::availableHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? availableLogicalHeight(IncludeMarginBorderPadding) : availableLogicalWidth();
}
inline LayoutUnit RenderBox::availableLogicalWidth() const
{
    if (m_scion) { return m_scion->availableLogicalWidth(); }
    return contentLogicalWidth();
}
inline LayoutUnit RenderBox::availableWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? availableLogicalWidth() : availableLogicalHeight(IncludeMarginBorderPadding);
}
inline LayoutSize RenderBox::borderBoxLogicalSize() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return logicalSize();
}
inline LayoutRect RenderBox::clientBoxRect() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutRect(clientLeft(), clientTop(), clientWidth(), clientHeight());
}
inline LayoutUnit RenderBox::clientLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderLeft();
}
inline LayoutUnit RenderBox::clientLogicalBottom() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderBefore() + clientLogicalHeight();
}
inline LayoutUnit RenderBox::clientLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? clientHeight() : clientWidth();
}
inline LayoutUnit RenderBox::clientLogicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? clientWidth() : clientHeight();
}
inline LayoutUnit RenderBox::clientTop() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return borderTop();
}
inline LayoutRect RenderBox::computedCSSContentBoxRect() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return LayoutRect(borderLeft() + computedCSSPaddingLeft(), borderTop() + computedCSSPaddingTop(), paddingBoxWidth() - computedCSSPaddingLeft() - computedCSSPaddingRight()  - (style().scrollbarGutter().bothEdges ? verticalScrollbarWidth() : 0), paddingBoxHeight() - computedCSSPaddingTop() - computedCSSPaddingBottom() - (style().scrollbarGutter().bothEdges ? horizontalScrollbarHeight() : 0));
}
inline LayoutUnit RenderBox::contentHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return std::max(0_lu, paddingBoxHeight() - paddingTop() - paddingBottom() - (style().scrollbarGutter().bothEdges ? horizontalScrollbarHeight() : 0));
}
inline LayoutUnit RenderBox::contentLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? contentHeight() : contentWidth();
}
inline LayoutSize RenderBox::contentLogicalSize() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? contentSize() : contentSize().transposedSize();
}
inline LayoutUnit RenderBox::contentLogicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? contentWidth() : contentHeight();
}
inline LayoutSize RenderBox::contentSize() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return { contentWidth(), contentHeight() };
}
inline LayoutUnit RenderBox::contentWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return std::max(0_lu, paddingBoxWidth() - paddingLeft() - paddingRight() - (style().scrollbarGutter().bothEdges ? verticalScrollbarWidth() : 0));
}
inline std::optional<LayoutUnit> RenderBox::explicitIntrinsicInnerLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? explicitIntrinsicInnerHeight() : explicitIntrinsicInnerWidth();
}
inline std::optional<LayoutUnit> RenderBox::explicitIntrinsicInnerLogicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? explicitIntrinsicInnerWidth() : explicitIntrinsicInnerHeight();
}
inline bool RenderBox::hasHorizontalOverflow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return scrollWidth() != roundToInt(paddingBoxWidth());
}
inline bool RenderBox::hasScrollableOverflowX() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return scrollsOverflowX() && hasHorizontalOverflow();
}
inline bool RenderBox::hasScrollableOverflowY() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return scrollsOverflowY() && hasVerticalOverflow();
}
inline bool RenderBox::hasVerticalOverflow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return scrollHeight() != roundToInt(paddingBoxHeight());
}
inline LayoutUnit RenderBox::intrinsicLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? intrinsicSize().height() : intrinsicSize().width();
}
inline LayoutUnit RenderBox::logicalBottom() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return logicalTop() + logicalHeight();
}
inline LayoutUnit RenderBox::logicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? height() : width();
}
inline LayoutUnit RenderBox::logicalLeft() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? x() : y();
}
inline LayoutUnit RenderBox::logicalLeftLayoutOverflow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? layoutOverflowRect().x() : layoutOverflowRect().y();
}
inline LayoutUnit RenderBox::logicalLeftVisualOverflow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? visualOverflowRect().x() : visualOverflowRect().y();
}
inline LayoutUnit RenderBox::logicalRight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return logicalLeft() + logicalWidth();
}
inline LayoutUnit RenderBox::logicalRightLayoutOverflow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? layoutOverflowRect().maxX() : layoutOverflowRect().maxY();
}
inline LayoutUnit RenderBox::logicalRightVisualOverflow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? visualOverflowRect().maxX() : visualOverflowRect().maxY();
}
inline LayoutSize RenderBox::logicalSize() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? m_frameRect.size() : m_frameRect.size().transposedSize();
}
inline LayoutUnit RenderBox::logicalTop() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? y() : x();
}
inline LayoutUnit RenderBox::logicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? width() : height();
}
inline LayoutUnit RenderBox::overridingContentLogicalHeight(LayoutUnit overridingLogicalHeight) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return std::max(0_lu, overridingLogicalHeight - borderAndPaddingLogicalHeight() - scrollbarLogicalHeight() - (style().scrollbarGutter().bothEdges ? scrollbarLogicalHeight() : 0));
}
inline LayoutUnit RenderBox::overridingContentLogicalWidth(LayoutUnit overridingLogicalWidth) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return std::max(LayoutUnit(), overridingLogicalWidth - borderAndPaddingLogicalWidth() - scrollbarLogicalWidth() - (style().scrollbarGutter().bothEdges ? scrollbarLogicalWidth() : 0));
}
inline LayoutUnit RenderBox::paddingBoxHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return std::max(0_lu, height() - borderTop() - borderBottom() - horizontalScrollbarHeight());
}
inline LayoutUnit RenderBox::paddingBoxWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return std::max(0_lu, width() - borderLeft() - borderRight() - verticalScrollbarWidth());
}
inline int RenderBox::scrollbarLogicalHeight() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? horizontalScrollbarHeight() : verticalScrollbarWidth();
}
inline int RenderBox::scrollbarLogicalWidth() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? verticalScrollbarWidth() : horizontalScrollbarHeight();
}
inline void RenderBox::setLogicalLocation(LayoutPoint location)
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    setLocation(style().isHorizontalWritingMode() ? location : location.transposedPoint());
}
inline void RenderBox::setLogicalSize(LayoutSize size)
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    setSize(style().isHorizontalWritingMode() ? size : size.transposedSize());
}
inline bool RenderBox::shouldTrimChildMargin(MarginTrimType type, const RenderBox& child) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().marginTrim().contains(type) && isChildEligibleForMarginTrim(type, child);
}
inline bool RenderBox::stretchesToViewport() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return document().inQuirksMode() && style().logicalHeight().isAuto() && !isFloatingOrOutOfFlowPositioned() && (isDocumentElementRenderer() || isBody()) && !shouldComputeLogicalHeightFromAspectRatio() && !isInline();
}

inline LayoutRect RenderBox::paddingBoxRectIncludingScrollbar() const
{
    if (m_scion) { return m_scion->paddingBoxRectIncludingScrollbar(); }
    auto borderWidths = this->borderWidths();
    return LayoutRect(borderWidths.left(), borderWidths.top(), width() - borderWidths.left() - borderWidths.right(), height() - borderWidths.top() - borderWidths.bottom());
}

inline LayoutRect RenderBox::contentBoxRect() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    auto verticalScrollbarWidth = 0_lu;
    auto horizontalScrollbarHeight = 0_lu;
    auto leftScrollbarSpace = 0_lu;
    auto topScrollbarSpace = 0_lu;

    if (hasNonVisibleOverflow()) {
        verticalScrollbarWidth = this->verticalScrollbarWidth();
        horizontalScrollbarHeight = this->horizontalScrollbarHeight();

        bool bothEdgeScrollbarGutters = style().scrollbarGutter().bothEdges;

        if ((shouldPlaceVerticalScrollbarOnLeft() || bothEdgeScrollbarGutters))
            leftScrollbarSpace = verticalScrollbarWidth;
        // FIXME: It's wrong that scrollbar-gutter: both-edges affects height: webkit.org/b/266938
        if (bothEdgeScrollbarGutters)
            topScrollbarSpace = horizontalScrollbarHeight;
    }

    auto padding = this->padding();
    auto borderWidths = this->borderWidths();
    auto location = LayoutPoint { borderWidths.left() + padding.left() + leftScrollbarSpace, borderWidths.top() + padding.top() + topScrollbarSpace };

    auto paddingBoxWidth = std::max(0_lu, width() - borderWidths.left() - borderWidths.right() - verticalScrollbarWidth);
    auto paddingBoxHeight = std::max(0_lu, height() - borderWidths.top() - borderWidths.bottom() - horizontalScrollbarHeight);

    auto width = std::max(0_lu, paddingBoxWidth - padding.left() - padding.right() - leftScrollbarSpace);
    auto height = std::max(0_lu, paddingBoxHeight - padding.top() - padding.bottom() - topScrollbarSpace);

    auto size = LayoutSize { width, height };

    return { location, size };
}

inline LayoutRect RenderBox::marginBoxRect() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    auto left = resolveLengthPercentageUsingContainerLogicalWidth(style().marginLeft());
    auto right = resolveLengthPercentageUsingContainerLogicalWidth(style().marginRight());
    auto top = resolveLengthPercentageUsingContainerLogicalWidth(style().marginTop());
    auto bottom = resolveLengthPercentageUsingContainerLogicalWidth(style().marginBottom());
    return { -left, -top, size().width() + left + right, size().height() + top + bottom };
}

inline void RenderBox::setLogicalHeight(LayoutUnit size)
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        setHeight(size);
    else
        setWidth(size);
}

inline void RenderBox::setLogicalLeft(LayoutUnit left)
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        setX(left);
    else
        setY(left);
}

inline void RenderBox::setLogicalTop(LayoutUnit top)
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        setY(top);
    else
        setX(top);
}

inline void RenderBox::setLogicalWidth(LayoutUnit size)
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (style().isHorizontalWritingMode())
        setWidth(size);
    else
        setHeight(size);
}

} // namespace WebCore
