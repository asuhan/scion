/*
 * Copyright (C) 1997 Martin Jones (mjones@kde.org)
 *           (C) 1997 Torben Weis (weis@kde.org)
 *           (C) 1998 Waldo Bastian (bastian@kde.org)
 *           (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2009 Apple Inc. All rights reserved.
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

#include "RenderTableSection.h"

namespace WebCore {

static const unsigned unsetRowIndex = 0x7FFFFFFF;
static const unsigned maxRowIndex = 0x7FFFFFFE; // 2,147,483,646

class RenderTableRowScion;

class RenderTableRow final : public RenderBox {
    WTF_MAKE_TZONE_OR_ISO_ALLOCATED(RenderTableRow);
    WTF_OVERRIDE_DELETE_FOR_CHECKED_PTR(RenderTableRow);
public:
    RenderTableRow(Element&, RenderStyle&&);
    RenderTableRow(Document&, RenderStyle&&);
    virtual ~RenderTableRow();

    void setScionHandle(void* handle);

    RenderTableRow* nextRow() const;
    RenderTableRow* previousRow() const;

    RenderTableCell* firstCell() const;
    RenderTableCell* lastCell() const;

    RenderTable* table() const;

    void paintOutlineForRowIfNeeded(PaintInfo&, const LayoutPoint&);

    static RenderPtr<RenderTableRow> createAnonymousWithParentRenderer(const RenderTableSection&);
    RenderPtr<RenderBox> createAnonymousBoxWithSameTypeAs(const RenderBox&) const override;

    void setRowIndex(unsigned);
    bool rowIndexWasSet() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return m_rowIndex != unsetRowIndex;
    }
    unsigned rowIndex() const;

    inline const BorderValue& borderAdjoiningTableStart() const;
    inline const BorderValue& borderAdjoiningTableEnd() const;
    const BorderValue& borderAdjoiningStartCell(const RenderTableCell&) const;
    const BorderValue& borderAdjoiningEndCell(const RenderTableCell&) const;

    bool nodeAtPoint(const HitTestRequest&, HitTestResult&, const HitTestLocation& locationInContainer, const LayoutPoint& accumulatedOffset, HitTestAction) override;

    RenderTableSection* section() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return downcast<RenderTableSection>(parent());
    }

    void didInsertTableCell(RenderTableCell& child, RenderObject* beforeChild);

private:
    static RenderPtr<RenderTableRow> createTableRowWithStyle(Document&, const RenderStyle&);

    // NB(asuhan): this returns one of two literals, picked by predicates that route to Scion
    // themselves, we can skip the Scion check
    ASCIILiteral renderName() const override { return (isAnonymous() || isPseudoElement()) ? "RenderTableRow (anonymous)"_s : "RenderTableRow"_s; }
    // NB(asuhan): this returns a literal, we can skip the Scion check
    bool canHaveChildren() const override { return true; }
    void willBeRemovedFromTree() override;
    void layout() override;

    LayoutRect clippedOverflowRect(const RenderLayerModelObject* repaintContainer, VisibleRectContext) const override;
    RepaintRects rectsForRepaintingAfterLayout(const RenderLayerModelObject* repaintContainer, RepaintOutlineBounds) const override;

    bool requiresLayer() const final;
    void paint(PaintInfo&, const LayoutPoint&) override;
    void imageChanged(WrappedImagePtr, const IntRect* = 0) override;
    void styleDidChange(StyleDifference, const RenderStyle* oldStyle) override;

    void firstChild() const = delete;
    void lastChild() const = delete;
    void nextSibling() const = delete;
    void previousSibling() const = delete;

    unsigned m_rowIndex : 31;
    std::unique_ptr<RenderTableRowScion> m_scion;
};

inline void RenderTableRow::setRowIndex(unsigned rowIndex)
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    if (UNLIKELY(rowIndex > maxRowIndex))
        CRASH();
    m_rowIndex = rowIndex;
}

inline unsigned RenderTableRow::rowIndex() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    ASSERT(rowIndexWasSet());
    return m_rowIndex;
}

inline RenderTable* RenderTableRow::table() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    RenderTableSection* section = this->section();
    if (!section)
        return nullptr;
    return downcast<RenderTable>(section->parent());
}

inline RenderTableRow* RenderTableRow::nextRow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return downcast<RenderTableRow>(RenderBox::nextSibling());
}

inline RenderTableRow* RenderTableRow::previousRow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return downcast<RenderTableRow>(RenderBox::previousSibling());
}

inline RenderTableRow* RenderTableSection::firstRow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return downcast<RenderTableRow>(RenderBox::firstChild());
}

inline RenderTableRow* RenderTableSection::lastRow() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return downcast<RenderTableRow>(RenderBox::lastChild());
}

} // namespace WebCore

SPECIALIZE_TYPE_TRAITS_RENDER_OBJECT(RenderTableRow, isRenderTableRow())
