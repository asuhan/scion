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

#pragma once

#include <wtf/CheckedRef.h>

#include "FloatSize.h"
#include "LayoutPoint.h"
#include "LocalFrameView.h"
#include "RenderStyle.h"
#include "VisiblePosition.h"

namespace WebCore {

class RenderLayer;
class RenderLayerCompositor;
class RenderFragmentContainer;

class RenderViewScion final : public CanMakeCheckedPtr<RenderViewScion> {
public:
    const RenderStyle& style() const;

    RenderStyle& mutableStyle();

    const RenderStyle* parentStyle() const;

    void setStyle(RenderStyle&&, StyleDifference minimalStyleDifference = StyleDifference::Equal);

    RenderObject* firstChild();

    bool needsLayout() const;

    Document& document() const;

    RenderLayer* layer() const;

    VisiblePosition positionForPoint(const LayoutPoint&, HitTestSource, const RenderFragmentContainer*);

    RenderSelection& selection();

    LocalFrameView& frameView() const;

    void updateQuirksMode();

    void repaintViewAndCompositedLayers();

    void setIsInWindow(bool);

    RenderLayerCompositor& compositor();

    bool usesCompositing() const;

    IntRect documentRect() const;

    FloatSize sizeForCSSLargeViewportUnits() const;

    uint64_t rendererCount() const;
};

}