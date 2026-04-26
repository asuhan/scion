/**
 * Copyright (C) 2023 Apple Inc. All rights reserved.
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
 */

#pragma once

#include "Document.h"
#include "RenderObject.h"
#include "RenderStyleInlines.h"

namespace WebCore {

inline bool RenderObject::isAtomicInlineLevelBox() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isDisplayInlineType() && !(style().display() == DisplayType::Inline && !isReplacedOrInlineBlock());
}
inline bool RenderObject::isBlockLevelBox() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isDisplayBlockLevel();
}
inline bool RenderObject::preservesNewline() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return !isRenderSVGInlineText() && style().preserveNewline();
}

} // namespace WebCore
