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
#include "ScrollTypes.h"

extern "C" bool RenderBoxScion_requiresLayerWithScrollableArea(const void*);

extern "C" int32_t RenderBoxScion_width(const void*);

extern "C" bool RenderBoxScion_hasAutoScrollbar(const void*, uint8_t);

extern "C" bool RenderBoxScion_hasAlwaysPresentScrollbar(const void*, uint8_t);

extern "C" void RenderBoxScion_styleWillChange(void*, uint8_t, const void*);

namespace WebCore {

bool RenderBoxScion::requiresLayerWithScrollableArea()
{
    return RenderBoxScion_requiresLayerWithScrollableArea(m_handle);
}

LayoutUnit RenderBoxScion::width() const
{
    return LayoutUnit::fromRawValue(RenderBoxScion_width(m_handle));
}

bool RenderBoxScion::hasAutoScrollbar(ScrollbarOrientation orientation)
{
    return RenderBoxScion_hasAutoScrollbar(m_handle, static_cast<uint8_t>(orientation));
}

bool RenderBoxScion::hasAlwaysPresentScrollbar(ScrollbarOrientation orientation)
{
    return RenderBoxScion_hasAlwaysPresentScrollbar(m_handle, static_cast<uint8_t>(orientation));
}

void RenderBoxScion::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    RenderBoxScion_styleWillChange(m_handle, static_cast<uint8_t>(diff), &newStyle);
}

}