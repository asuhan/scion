/*
 * Copyright (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2004-2017 Apple Inc. All rights reserved.
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
#include "ContentData.h"

#include "Document.h"
#include "RenderCounter.h"
#include "RenderImage.h"
#include "RenderImageResource.h"
#include "RenderImageResourceStyleImage.h"
#include "RenderObjectsScion.h"
#include "RenderQuote.h"
#include "RenderStyle.h"
#include "RenderTextFragment.h"
#include "StyleInheritedData.h"
#include <wtf/TZoneMallocInlines.h>

namespace WebCore {

WTF_MAKE_TZONE_ALLOCATED_IMPL(ContentData);
WTF_MAKE_TZONE_ALLOCATED_IMPL(ImageContentData);
WTF_MAKE_TZONE_ALLOCATED_IMPL(TextContentData);
WTF_MAKE_TZONE_ALLOCATED_IMPL(CounterContentData);
WTF_MAKE_TZONE_ALLOCATED_IMPL(QuoteContentData);

std::unique_ptr<ContentData> ContentData::clone() const
{
    auto result = cloneInternal();
    auto* lastNewData = result.get();
    for (auto* contentData = next(); contentData; contentData = contentData->next()) {
        lastNewData->setNext(contentData->cloneInternal());
        lastNewData = lastNewData->next();
    }
    return result;
}

RenderPtr<RenderObject> ImageContentData::createContentRenderer(Document& document, const RenderStyle& pseudoStyle) const
{
    auto image = createRenderer<RenderImage>(RenderObject::Type::Image, document, RenderStyle::createStyleInheritingFromPseudoStyle(pseudoStyle), const_cast<StyleImage*>(m_image.ptr()));
    image->initializeStyle();
    image->setAltText(altText());
    return image;
}

RenderPtr<RenderObject> TextContentData::createContentRenderer(Document& document, const RenderStyle&) const
{
    auto fragment = createRenderer<RenderTextFragment>(document, m_text);
    if (Document::s_useScionRendering >= 10)
        fragment->setScionHandle(RenderTextFragmentScion_createFromContentString(&document, &m_text));
    fragment->setAltText(altText());
    return fragment;
}

RenderPtr<RenderObject> CounterContentData::createContentRenderer(Document& document, const RenderStyle&) const
{
    if (Document::s_useScionRendering >= 21) {
        auto counter = createRenderer<RenderCounter>(document, *m_counter);
        counter->setScionHandle(RenderCounterScion_create(&document));
        return counter;
    }
    return createRenderer<RenderCounter>(document, *m_counter);
}

RenderPtr<RenderObject> QuoteContentData::createContentRenderer(Document& document, const RenderStyle& pseudoStyle) const
{
    auto style = RenderStyle::createStyleInheritingFromPseudoStyle(pseudoStyle);
    if (Document::s_useScionRendering >= 20) {
        auto clonedStyle = RenderStyle::clonePtr(style);
        auto quote = createRenderer<RenderQuote>(document, WTFMove(style), m_quote);
        quote->setScionHandle(RenderQuoteScion_create(&document, clonedStyle.release(), static_cast<uint8_t>(m_quote)));
        quote->initializeStyle();
        return quote;
    }
    auto quote = createRenderer<RenderQuote>(document, WTFMove(style), m_quote);
    quote->initializeStyle();
    return quote;
}

} // namespace WebCore
