/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
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

#pragma once

#include "RenderBlockFlow.h"
#include "RenderListMarker.h"

namespace WebCore {

class HTMLOListElement;
class RenderListItemScion;

class RenderListItem final : public RenderBlockFlow {
    WTF_MAKE_TZONE_OR_ISO_ALLOCATED(RenderListItem);
    WTF_OVERRIDE_DELETE_FOR_CHECKED_PTR(RenderListItem);
public:
    RenderListItem(Element&, RenderStyle&&);
    virtual ~RenderListItem();

    void setScionHandle(void* handle);

    Element& element() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return downcast<Element>(nodeForNonAnonymous());
    }

    int value() const;
    void updateValue();

    void setNotInList(bool);
    bool notInList() const;

    WEBCORE_EXPORT StringView markerTextWithoutSuffix() const;
    StringView markerTextWithSuffix() const;

    void updateListMarkerNumbers();

    static void updateItemValuesForOrderedList(const HTMLOListElement&);
    static unsigned itemCountForOrderedList(const HTMLOListElement&);

    RenderStyle computeMarkerStyle() const;

    RenderListMarker* markerRenderer() const;
    void setMarkerRenderer(RenderListMarker&);

    bool isInReversedOrderedList() const;

private:
    // NB(asuhan): this returns a literal, we can skip the Scion check
    ASCIILiteral renderName() const final { return "RenderListItem"_s; }
    
    void paint(PaintInfo&, const LayoutPoint&) final;

    void styleDidChange(StyleDifference, const RenderStyle* oldStyle) final;
public:
    void layout() final;

private:
    void computePreferredLogicalWidths() final;

    void updateValueNow() const;
    void counterDirectivesChanged();

    SingleThreadWeakPtr<RenderListMarker> m_marker;
    mutable std::optional<int> m_value;
    bool m_notInList { false };
    std::unique_ptr<RenderListItemScion> m_scion;
};

bool isHTMLListElement(const Node&);

inline int RenderListItem::value() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (!m_value)
        updateValueNow();
    return m_value.value();
}

} // namespace WebCore

SPECIALIZE_TYPE_TRAITS_RENDER_OBJECT(RenderListItem, isRenderListItem())
