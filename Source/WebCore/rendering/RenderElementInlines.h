/**
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
 */

#pragma once

#include "RenderElement.h"
#include "RenderObjectInlines.h"

namespace WebCore {

inline Overflow RenderElement::effectiveOverflowBlockDirection() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? effectiveOverflowY() : effectiveOverflowX();
}
inline Overflow RenderElement::effectiveOverflowInlineDirection() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().isHorizontalWritingMode() ? effectiveOverflowX() : effectiveOverflowY();
}
inline bool RenderElement::hasBackground() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().hasBackground();
}
inline bool RenderElement::hasClip() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return isOutOfFlowPositioned() && style().hasClip();
}
inline bool RenderElement::hasHiddenBackface() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().backfaceVisibility() == BackfaceVisibility::Hidden;
}
inline bool RenderElement::hasOutline() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().hasOutline() || hasOutlineAnnotation();
}
inline bool RenderElement::hasShapeOutside() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return style().shapeOutside();
}
inline FloatRect RenderElement::transformReferenceBoxRect() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return transformReferenceBoxRect(style());
}
inline FloatRect RenderElement::transformReferenceBoxRect(const RenderStyle& style) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return referenceBoxRect(transformBoxToCSSBoxType(style.transformBox()));
}

inline bool RenderElement::canContainFixedPositionObjects() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return isRenderView()
        || (canEstablishContainingBlockWithTransform() && hasTransformRelatedProperty())
        || (hasBackdropFilter() && !isDocumentElementRenderer())
        || (isRenderBlock() && style().willChange() && style().willChange()->createsContainingBlockForOutOfFlowPositioned(isDocumentElementRenderer()))
        || isRenderOrLegacyRenderSVGForeignObject()
        || shouldApplyLayoutOrPaintContainment();
}

inline bool RenderElement::createsGroupForStyle(const RenderStyle& style)
{
    return style.hasOpacity() || style.hasMask() || style.clipPath() || style.hasFilter() || style.hasBackdropFilter() || style.hasBlendMode();
}

inline bool RenderElement::shouldApplyAnyContainment() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return shouldApplyLayoutOrPaintContainment() || shouldApplySizeOrStyleContainment(style().containsSizeOrInlineSize() || style().containsStyle());
}

inline bool RenderElement::shouldApplyInlineSizeContainment() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return WebCore::isSkippedContentRoot(style(), element()) || shouldApplySizeOrStyleContainment(style().containsInlineSize());
}

inline bool RenderElement::shouldApplyLayoutContainment() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return shouldApplyLayoutOrPaintContainment(style().containsLayout() || style().contentVisibility() != ContentVisibility::Visible);
}

inline bool RenderElement::shouldApplyLayoutOrPaintContainment(bool containsAccordingToStyle) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return containsAccordingToStyle && (!isInline() || isAtomicInlineLevelBox()) && style().display() != DisplayType::RubyAnnotation && (!isTablePart() || isRenderBlockFlow());
}

inline bool RenderElement::shouldApplySizeContainment() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return WebCore::isSkippedContentRoot(style(), element()) || shouldApplySizeOrStyleContainment(style().containsSize());
}

inline bool RenderElement::shouldApplySizeOrInlineSizeContainment() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return WebCore::isSkippedContentRoot(style(), element()) || shouldApplySizeOrStyleContainment(style().containsSizeOrInlineSize());
}

// FIXME: try to avoid duplication with isSkippedContentRoot.
inline bool RenderElement::shouldApplySizeOrStyleContainment(bool containsAccordingToStyle) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return containsAccordingToStyle && (!isInline() || isAtomicInlineLevelBox()) && style().display() != DisplayType::RubyAnnotation && (!isTablePart() || isRenderTableCaption()) && !isRenderTable();
}

inline bool RenderElement::shouldApplyStyleContainment() const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    return shouldApplySizeOrStyleContainment(style().containsStyle() || style().contentVisibility() != ContentVisibility::Visible);
}

inline bool RenderElement::visibleToHitTesting(const std::optional<HitTestRequest>& request) const
{
    if (m_scion) { ASSERT_NOT_REACHED(); }
    auto visibility = !request || request->userTriggered() ? style().usedVisibility() : style().visibility();
    return visibility == Visibility::Visible
        && !isSkippedContent()
        && ((request && request->ignoreCSSPointerEventsProperty()) || usedPointerEvents() != PointerEvents::None);
}

inline int adjustForAbsoluteZoom(int value, const RenderElement& renderer)
{
    return adjustForAbsoluteZoom(value, renderer.style());
}

inline LayoutSize adjustLayoutSizeForAbsoluteZoom(LayoutSize size, const RenderElement& renderer)
{
    return adjustLayoutSizeForAbsoluteZoom(size, renderer.style());
}

inline LayoutUnit adjustLayoutUnitForAbsoluteZoom(LayoutUnit value, const RenderElement& renderer)
{
    return adjustLayoutUnitForAbsoluteZoom(value, renderer.style());
}

} // namespace WebCore
