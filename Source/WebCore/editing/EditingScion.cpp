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

#include "config.h"
#include "EditingScion.h"

#include "Document.h"
#include "Node.h"
#include "Position.h"
#include "RenderObject.h"
#include "SimpleRange.h"
#include "VisiblePosition.h"

namespace WebCore {

PositionRaw positionToRaw(const Position& position)
{
    return { position.anchorNode(), position.m_offset, static_cast<uint8_t>(position.m_anchorType), position.m_isLegacyEditingPosition };
}

Position positionFromRaw(const PositionRaw& raw)
{
    RefPtr node = static_cast<Node*>(raw.anchorNode);
    if (raw.isLegacyEditingPosition)
        return makeDeprecatedLegacyPosition(WTFMove(node), raw.offset);
    auto anchorType = static_cast<Position::AnchorType>(raw.anchorType);
    if (anchorType == Position::PositionIsOffsetInAnchor)
        return { WTFMove(node), raw.offset, anchorType };
    return { WTFMove(node), anchorType };
}

VisiblePositionRaw visiblePositionToRaw(const VisiblePosition& position)
{
    return { positionToRaw(position.deepEquivalent()), static_cast<uint8_t>(position.affinity()) };
}

VisiblePosition visiblePositionFromRaw(const VisiblePositionRaw& raw)
{
    return { positionFromRaw(raw.deepPosition), static_cast<Affinity>(raw.affinity) };
}

SimpleRangeRaw simpleRangeToRaw(const SimpleRange& range)
{
    return { { range.start.container.ptr(), range.start.offset }, { range.end.container.ptr(), range.end.offset } };
}

SimpleRange simpleRangeFromRaw(const SimpleRangeRaw& raw)
{
    return { { *static_cast<Node*>(raw.start.container), raw.start.offset }, { *static_cast<Node*>(raw.end.container), raw.end.offset } };
}

bool usesScionEditing(const Position& position)
{
    // Without Scion rendering no renderer is Scion; skip the walk.
    if (!Document::s_useScionRendering)
        return false;
    // As plainText() does for ranges: the renderer of the nearest rendered node decides.
    for (RefPtr node = position.anchorNode(); node; node = node->parentNode()) {
        if (auto* renderer = node->renderer())
            return renderer->isScion();
    }
    return false;
}

} // namespace WebCore
