/*
 * Copyright (C) 2025 Scion authors. All rights reserved.
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

#include "RenderViewScion.h"
#include "Document.h"
#include "RenderFragmentContainer.h"
#include "RenderLayer.h"
#include "RenderSelection.h"
#include "RenderViewScion.h"
#include <wtf/Assertions.h>

namespace WebCore {

RenderViewScion::~RenderViewScion()
{
    ASSERT_NOT_REACHED();
}

const RenderStyle& RenderViewScion::style() const
{
    ASSERT_NOT_REACHED();
    return RenderStyle::defaultStyle();
}

RenderStyle& RenderViewScion::mutableStyle()
{
    ASSERT_NOT_REACHED();
    return RenderStyle::defaultStyle();
}

const RenderStyle* RenderViewScion::parentStyle() const
{
    ASSERT_NOT_REACHED();
    return nullptr;
}

void RenderViewScion::setStyle(RenderStyle&&, StyleDifference)
{
    ASSERT_NOT_REACHED();
}

RenderObject* RenderViewScion::firstChild()
{
    ASSERT_NOT_REACHED();
    return nullptr;
}

bool RenderViewScion::needsLayout() const
{
    ASSERT_NOT_REACHED();
    return false;
}

Document& RenderViewScion::document() const
{
    static Document* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

LocalFrame& RenderViewScion::frame() const
{
    static LocalFrame* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

RenderLayer* RenderViewScion::layer() const
{
    ASSERT_NOT_REACHED();
    return nullptr;
}

VisiblePosition RenderViewScion::positionForPoint(const LayoutPoint&, HitTestSource, const RenderFragmentContainer*)
{
    ASSERT_NOT_REACHED();
    return {};
}

void RenderViewScion::repaint(RenderObject::ForceRepaint) const
{
    ASSERT_NOT_REACHED();
}

RenderMultiColumnFlow* RenderViewScion::multiColumnFlow() const
{
    ASSERT_NOT_REACHED();
    return nullptr;
}

void RenderViewScion::updateColumnProgressionFromStyle(const RenderStyle&)
{
    ASSERT_NOT_REACHED();
}

RenderSelection& RenderViewScion::selection()
{
    static RenderSelection* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

LocalFrameView& RenderViewScion::frameView() const
{
    static LocalFrameView* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

void RenderViewScion::updateQuirksMode()
{
    ASSERT_NOT_REACHED();
}

void RenderViewScion::repaintRootContents()
{
    ASSERT_NOT_REACHED();
}

void RenderViewScion::repaintViewAndCompositedLayers()
{
    ASSERT_NOT_REACHED();
}

void RenderViewScion::setIsInWindow(bool)
{
    ASSERT_NOT_REACHED();
}

RenderLayerCompositor& RenderViewScion::compositor()
{
    static RenderLayerCompositor* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

bool RenderViewScion::usesCompositing() const
{
    ASSERT_NOT_REACHED();
    return false;
}

IntRect RenderViewScion::documentRect() const
{
    ASSERT_NOT_REACHED();
    return {};
}

FloatSize RenderViewScion::sizeForCSSLargeViewportUnits() const
{
    ASSERT_NOT_REACHED();
    return {};
}

uint64_t RenderViewScion::rendererCount() const
{
    ASSERT_NOT_REACHED();
    return 0;
}

void RenderViewScion::didCreateRenderer()
{
    ASSERT_NOT_REACHED();
}

const SingleThreadWeakHashSet<const RenderBox>& RenderViewScion::containerQueryBoxes() const
{
    static SingleThreadWeakHashSet<const RenderBox> unused;
    ASSERT_NOT_REACHED();
    return unused;
}

}
