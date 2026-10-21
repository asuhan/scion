/*
 * Copyright (C) 2014 Igalia S.L.
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

#include "config.h"
#include "Icon.h"

#include "FloatRect.h"
#include "GraphicsContext.h"

#if !PLATFORM(IOS_FAMILY) && !PLATFORM(MAC) && !PLATFORM(WIN)

namespace WebCore {

Icon::~Icon() = default;

void Icon::paint(GraphicsContext&, const FloatRect&)
{
}

RefPtr<Icon> Icon::createIconForFiles(const Vector<String>&)
{
    return nullptr;
}

} // namespace WebCore

#endif // !PLATFORM(GTK) && !PLATFORM(IOS_FAMILY) && !PLATFORM(MAC) && !PLATFORM(WIN)

struct FloatRectRaw {
    float x;
    float y;
    float width;
    float height;
};

extern "C" WEBCORE_EXPORT void Icon_paint(void* p, void* contextRaw, FloatRectRaw rectRaw)
{
    static_cast<WebCore::Icon*>(p)->paint(*static_cast<WebCore::GraphicsContext*>(contextRaw), { rectRaw.x, rectRaw.y, rectRaw.width, rectRaw.height });
}
