/*
 * Copyright (c) 2014, Opera Software ASA. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Opera Software ASA nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "RenderMultiColumnSpannerPlaceholder.h"

#include "RenderBoxInlines.h"
#include "RenderBoxModelObjectInlines.h"
#include "RenderMultiColumnFlow.h"
#include "RenderObjectsScion.h"
#include <wtf/TZoneMallocInlines.h>

namespace WebCore {

WTF_MAKE_TZONE_OR_ISO_ALLOCATED_IMPL(RenderMultiColumnSpannerPlaceholder);

RenderPtr<RenderMultiColumnSpannerPlaceholder> RenderMultiColumnSpannerPlaceholder::createAnonymous(RenderMultiColumnFlow& fragmentedFlow, RenderBox& spanner, const RenderStyle& parentStyle)
{
    auto newStyle = RenderStyle::createAnonymousStyleWithDisplay(parentStyle, DisplayType::Block);
    newStyle.setClear(Clear::Both); // We don't want floats in the row preceding the spanner to continue on the other side.
    RenderPtr<RenderMultiColumnSpannerPlaceholder> placeholder;
    if (Document::s_useScionRendering >= 18) {
        auto clonedStyle = RenderStyle::clonePtr(newStyle);
        placeholder = createRenderer<RenderMultiColumnSpannerPlaceholder>(fragmentedFlow, spanner, WTFMove(newStyle));
        placeholder->setScionHandle(RenderMultiColumnSpannerPlaceholderScion_create(&fragmentedFlow, &spanner, clonedStyle.release()));
    } else
        placeholder = createRenderer<RenderMultiColumnSpannerPlaceholder>(fragmentedFlow, spanner, WTFMove(newStyle));
    placeholder->initializeStyle();
    return placeholder;
}

RenderMultiColumnSpannerPlaceholder::RenderMultiColumnSpannerPlaceholder(RenderMultiColumnFlow& fragmentedFlow, RenderBox& spanner, RenderStyle&& style)
    : RenderBox(Type::MultiColumnSpannerPlaceholder, fragmentedFlow.document(), WTFMove(style), TypeFlag::IsBoxModelObject)
    , m_spanner(spanner)
    , m_fragmentedFlow(fragmentedFlow)
{
    ASSERT(isRenderMultiColumnSpannerPlaceholder());
}

RenderMultiColumnSpannerPlaceholder::~RenderMultiColumnSpannerPlaceholder() = default;

void RenderMultiColumnSpannerPlaceholder::setScionHandle(void* handle)
{
    RenderObject::setScionHandle(handle);
    RenderElement::setScionHandle(handle);
    RenderLayerModelObject::setScionHandle(handle);
    RenderBoxModelObject::setScionHandle(handle);
    RenderBox::setScionHandle(handle);
    m_scion = std::make_unique<RenderMultiColumnSpannerPlaceholderScion>(handle);
    m_scion->setWk(this);
}

ASCIILiteral RenderMultiColumnSpannerPlaceholder::renderName() const
{
    // NB(asuhan): this returns a literal, we can skip the Scion check
    return "RenderMultiColumnSpannerPlaceholder"_s;
}

} // namespace WebCore

extern "C" WEBCORE_EXPORT void* RenderMultiColumnSpannerPlaceholder_spanner(const void* p)
{
    return static_cast<const WebCore::RenderMultiColumnSpannerPlaceholder*>(p)->spanner();
}
