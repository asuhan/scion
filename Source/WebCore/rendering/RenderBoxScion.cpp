/*
 * Copyright (C) 2026 Scion authors. All rights reserved.
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

#include "RenderBoxScion.h"
#include "LayoutRect.h"
#include "LayoutRectRaw.h"
#include "ScrollTypes.h"

extern "C" bool RenderBoxScion_requiresLayerWithScrollableArea(const void*);

extern "C" int32_t RenderBoxScion_width(const void*);

extern "C" LayoutPointRaw RenderBoxScion_location(const void*);

struct LayoutSizeRaw {
    int32_t width;
    int32_t height;
};

extern "C" LayoutSizeRaw RenderBoxScion_size(const void*);

extern "C" LayoutRectRaw RenderBoxScion_frameRect(const void*);

extern "C" LayoutRectRaw RenderBoxScion_layoutOverflowRect(const void*);

extern "C" LayoutRectRaw RenderBoxScion_visualOverflowRect(const void*);

extern "C" LayoutRectRaw RenderBoxScion_paddingBoxRectIncludingScrollbar(const void*);

extern "C" RepaintRectsRaw RenderBoxScion_localRectsForRepaint(const void*, bool);

extern "C" int32_t RenderBoxScion_availableLogicalWidth(const void*);

extern "C" bool RenderBoxScion_hasAutoScrollbar(const void*, uint8_t);

extern "C" bool RenderBoxScion_hasAlwaysPresentScrollbar(const void*, uint8_t);

extern "C" bool RenderBoxScion_scrollsOverflow(const void*);

extern "C" bool RenderBoxScion_isUnsplittableForPagination(const void*);

extern "C" LayoutPointRaw RenderBoxScion_topLeftLocation(const void*);

extern "C" void RenderBoxScion_styleWillChange(void*, uint8_t, const void*);

extern "C" void RenderBoxScion_willBeDestroyed(void*);

extern "C" bool RenderBoxScion_shouldTrimChildMargin(const void*, uint8_t, void*);

namespace WebCore {

bool RenderBoxScion::requiresLayerWithScrollableArea() const
{
    return RenderBoxScion_requiresLayerWithScrollableArea(m_handle);
}

LayoutUnit RenderBoxScion::width() const
{
    return LayoutUnit::fromRawValue(RenderBoxScion_width(m_handle));
}

LayoutPoint RenderBoxScion::location() const
{
    const auto point = RenderBoxScion_location(m_handle);
    return { LayoutUnit::fromRawValue(point.x), LayoutUnit::fromRawValue(point.y) };
}

LayoutSize RenderBoxScion::size() const
{
    const auto sizeRaw = RenderBoxScion_size(m_handle);
    return { LayoutUnit::fromRawValue(sizeRaw.width), LayoutUnit::fromRawValue(sizeRaw.height) };
}

namespace {

LayoutRect convertLayoutRectRaw(const LayoutRectRaw& r)
{
    return { LayoutUnit::fromRawValue(r.x), LayoutUnit::fromRawValue(r.y), LayoutUnit::fromRawValue(r.width), LayoutUnit::fromRawValue(r.height) };
}

RenderObject::RepaintRects convertRepaintRectsRaw(const RepaintRectsRaw& rects)
{
    return { convertLayoutRectRaw(rects.clippedOverflowRect), rects.outlineBoundsRect.is_valid ? convertLayoutRectRaw(rects.outlineBoundsRect.rect) : LayoutRect {} };
}

} // namespace

LayoutRect RenderBoxScion::frameRect() const
{
    return convertLayoutRectRaw(RenderBoxScion_frameRect(m_handle));
}

LayoutRect RenderBoxScion::layoutOverflowRect() const
{
    return convertLayoutRectRaw(RenderBoxScion_layoutOverflowRect(m_handle));
}

LayoutRect RenderBoxScion::visualOverflowRect() const
{
    return convertLayoutRectRaw(RenderBoxScion_visualOverflowRect(m_handle));
}

LayoutRect RenderBoxScion::paddingBoxRectIncludingScrollbar() const
{
    return convertLayoutRectRaw(RenderBoxScion_paddingBoxRectIncludingScrollbar(m_handle));
}

RenderObject::RepaintRects RenderBoxScion::localRectsForRepaint(RepaintOutlineBounds repaintOutlineBounds) const
{
    return convertRepaintRectsRaw(RenderBoxScion_localRectsForRepaint(m_handle, repaintOutlineBounds == RepaintOutlineBounds::Yes));
}

LayoutUnit RenderBoxScion::availableLogicalWidth() const
{
    return LayoutUnit::fromRawValue(RenderBoxScion_availableLogicalWidth(m_handle));
}

bool RenderBoxScion::hasAutoScrollbar(ScrollbarOrientation orientation) const
{
    return RenderBoxScion_hasAutoScrollbar(m_handle, static_cast<uint8_t>(orientation));
}

bool RenderBoxScion::hasAlwaysPresentScrollbar(ScrollbarOrientation orientation) const
{
    return RenderBoxScion_hasAlwaysPresentScrollbar(m_handle, static_cast<uint8_t>(orientation));
}

bool RenderBoxScion::scrollsOverflow() const
{
    return RenderBoxScion_scrollsOverflow(m_handle);
}

bool RenderBoxScion::isUnsplittableForPagination() const
{
    return RenderBoxScion_isUnsplittableForPagination(m_handle);
}

LayoutPoint RenderBoxScion::topLeftLocation() const
{
    const auto point = RenderBoxScion_topLeftLocation(m_handle);
    return { LayoutUnit::fromRawValue(point.x), LayoutUnit::fromRawValue(point.y) };
}

void RenderBoxScion::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    RenderBoxScion_styleWillChange(m_handle, static_cast<uint8_t>(diff), &newStyle);
}

void RenderBoxScion::willBeDestroyed()
{
    RenderBoxScion_willBeDestroyed(m_handle);
}

bool RenderBoxScion::shouldTrimChildMargin(MarginTrimType marginTrimType, const RenderBox& child) const
{
    return RenderBoxScion_shouldTrimChildMargin(m_handle, static_cast<uint8_t>(marginTrimType), const_cast<void*>(static_cast<const void*>(&child)));
}

}