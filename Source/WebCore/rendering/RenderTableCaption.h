/*
 * Copyright (C) 2011 Robert Hogan <robert@roberthogan.net>
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

#include "RenderBlockFlow.h"

namespace WebCore {

class RenderTable;

class RenderTableCaptionScion;

class RenderTableCaption final : public RenderBlockFlow {
    WTF_MAKE_TZONE_OR_ISO_ALLOCATED(RenderTableCaption);
    WTF_OVERRIDE_DELETE_FOR_CHECKED_PTR(RenderTableCaption);
public:
    RenderTableCaption(Element&, RenderStyle&&);
    virtual ~RenderTableCaption();

    void setScionHandle(void* handle);

    Element& element() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return downcast<Element>(nodeForNonAnonymous());
    }

private:
    void insertedIntoTree() override;
    void willBeRemovedFromTree() override;
    LayoutUnit containingBlockLogicalWidthForContent() const final;

    RenderTable* table() const;
    std::unique_ptr<RenderTableCaptionScion> m_scion;
};

} // namespace WebCore

SPECIALIZE_TYPE_TRAITS_RENDER_OBJECT(RenderTableCaption, isRenderTableCaption())
