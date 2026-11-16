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

#pragma once

#include "LayoutRectRaw.h"
#include <cstdint>

// Positions cross to the Swift editing code by value. The node pointer is borrowed: it is only
// valid for the duration of the call, and the receiving side takes its own reference.
struct PositionRaw {
    void* anchorNode;
    uint32_t offset;
    uint8_t anchorType;
    bool isLegacyEditingPosition;
};

struct VisiblePositionRaw {
    struct PositionRaw deepPosition;
    uint8_t affinity;
};

struct LocalCaretRectRaw {
    struct LayoutRectRaw rect;
    void* renderer;
};

struct BoundaryPointRaw {
    void* container;
    uint32_t offset;
};

struct SimpleRangeRaw {
    struct BoundaryPointRaw start;
    struct BoundaryPointRaw end;
};

namespace WebCore {

class Position;
class VisiblePosition;
struct SimpleRange;

PositionRaw positionToRaw(const Position&);
Position positionFromRaw(const PositionRaw&);
VisiblePositionRaw visiblePositionToRaw(const VisiblePosition&);
SimpleRangeRaw simpleRangeToRaw(const SimpleRange&);
SimpleRange simpleRangeFromRaw(const SimpleRangeRaw&);

// Whether the position is laid out by the Swift port, so that editing queries about it go to
// the Swift editing code.
bool usesScionEditing(const Position&);

} // namespace WebCore
