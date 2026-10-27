/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
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


#include "config.h"
#include "StyleImage.h"

#include "RenderElement.h"

extern "C" WEBCORE_EXPORT void StyleImage_addClient(void* p, void* renderer_raw)
{
    static_cast<WebCore::StyleImage*>(p)->addClient(*static_cast<WebCore::RenderElement*>(renderer_raw));
}

extern "C" WEBCORE_EXPORT void StyleImage_removeClient(void* p, void* renderer_raw)
{
    static_cast<WebCore::StyleImage*>(p)->removeClient(*static_cast<WebCore::RenderElement*>(renderer_raw));
}

extern "C" WEBCORE_EXPORT bool StyleImage_hasClient(const void* p, void* renderer_raw)
{
    return static_cast<const WebCore::StyleImage*>(p)->hasClient(*static_cast<WebCore::RenderElement*>(renderer_raw));
}

extern "C" WEBCORE_EXPORT bool StyleImage_isLoaded(const void* p, const void* renderer_raw)
{
    return static_cast<const WebCore::StyleImage*>(p)->isLoaded(static_cast<const WebCore::RenderElement*>(renderer_raw));
}

extern "C" WEBCORE_EXPORT bool StyleImage_errorOccurred(const void* p)
{
    return static_cast<const WebCore::StyleImage*>(p)->errorOccurred();
}

extern "C" WEBCORE_EXPORT bool StyleImage_usesDataProtocol(const void* p)
{
    return static_cast<const WebCore::StyleImage*>(p)->usesDataProtocol();
}

extern "C" WEBCORE_EXPORT bool StyleImage_hasImage(const void* p)
{
    return static_cast<const WebCore::StyleImage*>(p)->hasImage();
}

extern "C" WEBCORE_EXPORT void StyleImage_imageSize(const void* p, const void* renderer_raw, float multiplier, float* width, float* height)
{
    auto size = static_cast<const WebCore::StyleImage*>(p)->imageSize(static_cast<const WebCore::RenderElement*>(renderer_raw), multiplier);
    *width = size.width();
    *height = size.height();
}

extern "C" WEBCORE_EXPORT float StyleImage_imageScaleFactor(const void* p)
{
    return static_cast<const WebCore::StyleImage*>(p)->imageScaleFactor();
}

extern "C" WEBCORE_EXPORT bool StyleImage_imageHasNaturalDimensions(const void* p)
{
    return static_cast<const WebCore::StyleImage*>(p)->imageHasNaturalDimensions();
}

extern "C" WEBCORE_EXPORT bool StyleImage_canRender(const void* p, const void* renderer_raw, float multiplier)
{
    return static_cast<const WebCore::StyleImage*>(p)->canRender(static_cast<const WebCore::RenderElement*>(renderer_raw), multiplier);
}

extern "C" WEBCORE_EXPORT void StyleImage_setContainerContextForRenderer(void* p, const void* renderer_raw, float width, float height, float containerZoom)
{
    static_cast<WebCore::StyleImage*>(p)->setContainerContextForRenderer(*static_cast<const WebCore::RenderElement*>(renderer_raw), { width, height }, containerZoom);
}

extern "C" WEBCORE_EXPORT bool StyleImage_isGeneratedImage(const void* p)
{
    return static_cast<const WebCore::StyleImage*>(p)->isGeneratedImage();
}

extern "C" WEBCORE_EXPORT bool StyleImage_hasCachedImage(const void* p)
{
    return static_cast<const WebCore::StyleImage*>(p)->hasCachedImage();
}
