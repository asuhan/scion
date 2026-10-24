/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Nokia Corporation and/or its subsidiary(-ies)
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

#include "RenderBox.h"

namespace WebCore {

class RenderTable;
class RenderTableCell;

class RenderTableColScion;

class RenderTableCol final : public RenderBox {
    WTF_MAKE_TZONE_OR_ISO_ALLOCATED(RenderTableCol);
    WTF_OVERRIDE_DELETE_FOR_CHECKED_PTR(RenderTableCol);
public:
    RenderTableCol(Element&, RenderStyle&&);
    RenderTableCol(Document&, RenderStyle&&);
    virtual ~RenderTableCol();

    void setScionHandle(void* handle);

    void clearPreferredLogicalWidthsDirtyBits();

    unsigned span() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return m_span;
    }
    void setSpan(unsigned span)
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        m_span = span;
    }

    bool isTableColumnGroupWithColumnChildren() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return firstChild();
    }
    bool isTableColumn() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return style().display() == DisplayType::TableColumn;
    }
    bool isTableColumnGroup() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return style().display() == DisplayType::TableColumnGroup;
    }

    RenderTableCol* enclosingColumnGroup() const;
    RenderTableCol* enclosingColumnGroupIfAdjacentBefore() const;
    RenderTableCol* enclosingColumnGroupIfAdjacentAfter() const;

    // Returns the next column or column-group.
    RenderTableCol* nextColumn() const;

    const BorderValue& borderAdjoiningCellStartBorder() const;
    const BorderValue& borderAdjoiningCellEndBorder() const;
    const BorderValue& borderAdjoiningCellBefore(const RenderTableCell&) const;
    const BorderValue& borderAdjoiningCellAfter(const RenderTableCell&) const;

    LayoutUnit offsetLeft() const override;
    LayoutUnit offsetTop() const override;
    LayoutUnit offsetWidth() const override;
    LayoutUnit offsetHeight() const override;
    void updateFromElement() override;

private:
    // NB(asuhan): this returns a literal, we can skip the Scion check
    ASCIILiteral renderName() const override { return "RenderTableCol"_s; }
    void computePreferredLogicalWidths() override
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        ASSERT_NOT_REACHED();
    }

    void insertedIntoTree() override;
    void willBeRemovedFromTree() override;

    bool isChildAllowed(const RenderObject&, const RenderStyle&) const override;
    bool canHaveChildren() const override;
    // NB(asuhan): this returns a literal, we can skip the Scion check
    bool requiresLayer() const override { return false; }

    LayoutRect clippedOverflowRect(const RenderLayerModelObject* repaintContainer, VisibleRectContext) const override;
    RepaintRects rectsForRepaintingAfterLayout(const RenderLayerModelObject* repaintContainer, RepaintOutlineBounds) const override;

    void imageChanged(WrappedImagePtr, const IntRect* = 0) override;

    void styleDidChange(StyleDifference, const RenderStyle* oldStyle) override;
    void paint(PaintInfo&, const LayoutPoint&) override { }

    RenderTable* table() const;

    unsigned m_span { 1 };
    std::unique_ptr<RenderTableColScion> m_scion;
};

inline RenderTableCol* RenderTableCol::enclosingColumnGroupIfAdjacentBefore() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (previousSibling())
        return nullptr;
    return enclosingColumnGroup();
}

inline RenderTableCol* RenderTableCol::enclosingColumnGroupIfAdjacentAfter() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (nextSibling())
        return nullptr;
    return enclosingColumnGroup();
}

} // namespace WebCore

SPECIALIZE_TYPE_TRAITS_RENDER_OBJECT(RenderTableCol, isRenderTableCol())
