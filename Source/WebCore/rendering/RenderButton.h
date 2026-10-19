/*
 * Copyright (C) 2005-2022 Apple Inc.
 * Copyright (C) 2022 Google Inc. All rights reserved.
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

#include "RenderFlexibleBox.h"
#include "RenderTextFragment.h"
#include <memory>

namespace WebCore {

class HTMLFormControlElement;
class RenderButtonScion;
class RenderTextFragment;

// RenderButtons are just like normal flexboxes except that they will generate an anonymous block child.
// For inputs, they will also generate an anonymous RenderText and keep its style and content up
// to date as the button changes.
class RenderButton final : public RenderFlexibleBox {
    WTF_MAKE_TZONE_OR_ISO_ALLOCATED(RenderButton);
    WTF_OVERRIDE_DELETE_FOR_CHECKED_PTR(RenderButton);
public:
    RenderButton(HTMLFormControlElement&, RenderStyle&&);
    virtual ~RenderButton();

    void setScionHandle(void* handle);

    HTMLFormControlElement& formControlElement() const;

    bool canBeSelectionLeaf() const override;

    // NB(asuhan): this returns a literal, we can skip the Scion check
    bool createsAnonymousWrapper() const override { return true; }

    void updateFromElement() override;

    bool canHaveGeneratedChildren() const override;
    bool hasControlClip() const override;
    LayoutRect controlClipRect(const LayoutPoint&) const override;

    void updateAnonymousChildStyle(RenderStyle&) const override;

    void setText(const String&);
    String text() const;

#if PLATFORM(IOS_FAMILY)
    void layout() override;
#endif

    RenderTextFragment* textRenderer() const
    {
        if (m_scion) { ASSERT_NOT_REACHED(); }
        return m_buttonText.get();
    }

    RenderBlock* innerRenderer() const;
    void setInnerRenderer(RenderBlock&);

    LayoutUnit baselinePosition(FontBaseline, bool firstLine, LineDirectionMode, LinePositionMode = PositionOnContainingLine) const override;

private:
    void element() const = delete;

    // NB(asuhan): these return literals, we can skip the Scion check
    ASCIILiteral renderName() const override { return "RenderButton"_s; }

    bool hasLineIfEmpty() const override;

    bool isFlexibleBoxImpl() const override { return true; }

    SingleThreadWeakPtr<RenderTextFragment> m_buttonText;
    SingleThreadWeakPtr<RenderBlock> m_inner;
    std::unique_ptr<RenderButtonScion> m_scion;
};

} // namespace WebCore

SPECIALIZE_TYPE_TRAITS_RENDER_OBJECT(RenderButton, isRenderButton())
