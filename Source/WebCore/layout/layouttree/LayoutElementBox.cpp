/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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
#include "LayoutElementBox.h"

#include "RenderElement.h"
#include "RenderStyleInlines.h"
#include <wtf/TZoneMallocInlines.h>

extern "C" WEBCORE_EXPORT const void* ElementBox_firstChild(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->firstChild();
}

extern "C" WEBCORE_EXPORT const void* ElementBox_firstInFlowChild(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->firstInFlowChild();
}

extern "C" WEBCORE_EXPORT const void* ElementBox_lastChild(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->lastChild();
}

extern "C" WEBCORE_EXPORT bool ElementBox_isListMarkerImage(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->isListMarkerImage();
}

extern "C" WEBCORE_EXPORT bool ElementBox_isListMarkerOutside(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->isListMarkerOutside();
}

extern "C" WEBCORE_EXPORT bool ElementBox_isListMarkerInsideList(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->isListMarkerInsideList();
}

extern "C" WEBCORE_EXPORT void* ElementBox_rendererForIntegration(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->rendererForIntegration();
}

extern "C" WEBCORE_EXPORT bool ElementBox_hasOutOfFlowChild(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->hasOutOfFlowChild();
}

extern "C" WEBCORE_EXPORT void ElementBox_setBaselineForIntegration(const void* p, int32_t baseline_raw)
{
    const auto element_box = static_cast<const WebCore::Layout::ElementBox*>(p);
    const_cast<WebCore::Layout::ElementBox*>(element_box)->setBaselineForIntegration(WebCore::LayoutUnit::fromRawValue(baseline_raw));
}

extern "C" WEBCORE_EXPORT bool ElementBox_hasBaselineForIntegration(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->baselineForIntegration().has_value();
}

extern "C" WEBCORE_EXPORT int32_t ElementBox_baselineForIntegration(const void* p)
{
    return static_cast<const WebCore::Layout::ElementBox*>(p)->baselineForIntegration()->rawValue();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isRenderListBox(const void* p) {
    return static_cast<const WebCore::RenderObject*>(p)->isRenderListBox();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isRenderListItem(const void* p) {
    return static_cast<const WebCore::RenderObject*>(p)->isRenderListItem();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isRenderListMarker(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->isRenderListMarker();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isRenderBlockFlow(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->isRenderBlockFlow();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isRenderFlexibleBox(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->isRenderFlexibleBox();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isRenderBlock(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->isRenderBlock();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isRenderBox(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->isRenderBox();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isImage(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->isImage();
}

extern "C" WEBCORE_EXPORT bool RenderObject_isFieldset(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->isFieldset();
}

extern "C" WEBCORE_EXPORT void RenderObject_setNeedsLayout(void* object_raw_ptr, uint8_t marking_behavior)
{
    auto* object = static_cast<WebCore::RenderObject*>(object_raw_ptr);
    object->setNeedsLayout(static_cast<WebCore::MarkingBehavior>(marking_behavior));
}

extern "C" WEBCORE_EXPORT void* RenderObject_containingBlock(const void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->containingBlock();
}

extern "C" WEBCORE_EXPORT const void* RenderObject_style(const void* p)
{
    return &static_cast<const WebCore::RenderObject*>(p)->style();
}

extern "C" WEBCORE_EXPORT void* RenderObject_layoutBox(void* p)
{
    return static_cast<WebCore::RenderObject*>(p)->layoutBox();
}

extern "C" WEBCORE_EXPORT void* RenderObject_parent(void* p)
{
    return static_cast<const WebCore::RenderObject*>(p)->parent();
}

extern "C" WEBCORE_EXPORT void RenderElement_layoutIfNeeded(void* p)
{
    static_cast<WebCore::RenderElement*>(p)->layoutIfNeeded();
}

extern "C" WEBCORE_EXPORT bool RenderElement_isWritingModeRoot(const void* p)
{
    return static_cast<const WebCore::RenderElement*>(p)->isWritingModeRoot();
}

namespace WebCore {
namespace Layout {

WTF_MAKE_TZONE_OR_ISO_ALLOCATED_IMPL(ElementBox);

ElementBox::ElementBox(ElementAttributes&& attributes, RenderStyle&& style, std::unique_ptr<RenderStyle>&& firstLineStyle, OptionSet<BaseTypeFlag> baseTypeFlags)
    : Box(WTFMove(attributes), WTFMove(style), WTFMove(firstLineStyle), baseTypeFlags | ElementBoxFlag)
{
}

ElementBox::ElementBox(ElementAttributes&& attributes, OptionSet<ListMarkerAttribute> listMarkerAttributes, RenderStyle&& style, std::unique_ptr<RenderStyle>&& firstLineStyle)
    : Box(WTFMove(attributes), WTFMove(style), WTFMove(firstLineStyle), ElementBoxFlag)
    , m_replacedData(makeUnique<ReplacedData>())
{
    ASSERT(isListMarkerBox());
    m_replacedData->listMarkerAttributes = listMarkerAttributes;
}

ElementBox::ElementBox(ElementAttributes&& attributes, ReplacedAttributes&& replacedAttributes, RenderStyle&& style, std::unique_ptr<RenderStyle>&& firstLineStyle)
    : Box(WTFMove(attributes), WTFMove(style), WTFMove(firstLineStyle), ElementBoxFlag)
    , m_replacedData(makeUnique<ReplacedData>())
{
    m_replacedData->intrinsicSize = replacedAttributes.intrinsicSize;
    m_replacedData->intrinsicRatio = replacedAttributes.intrinsicRatio;
    m_replacedData->cachedImage = replacedAttributes.cachedImage;
}

ElementBox::~ElementBox()
{
    destroyChildren();
}

const Box* ElementBox::firstInFlowChild() const
{
    if (auto* firstChild = this->firstChild()) {
        if (firstChild->isInFlow())
            return firstChild;
        return firstChild->nextInFlowSibling();
    }
    return nullptr;
}

const Box* ElementBox::firstInFlowOrFloatingChild() const
{
    if (auto* firstChild = this->firstChild()) {
        if (firstChild->isInFlow() || firstChild->isFloatingPositioned())
            return firstChild;
        return firstChild->nextInFlowOrFloatingSibling();
    }
    return nullptr;
}

const Box* ElementBox::lastInFlowChild() const
{
    if (auto* lastChild = this->lastChild()) {
        if (lastChild->isInFlow())
            return lastChild;
        return lastChild->previousInFlowSibling();
    }
    return nullptr;
}

const Box* ElementBox::lastInFlowOrFloatingChild() const
{
    if (auto* lastChild = this->lastChild()) {
        if (lastChild->isInFlow() || lastChild->isFloatingPositioned())
            return lastChild;
        return lastChild->previousInFlowOrFloatingSibling();
    }
    return nullptr;
}

bool ElementBox::hasOutOfFlowChild() const
{
    for (auto* child = this->firstChild(); child; child = child->nextSibling()) {
        if (child->isOutOfFlowPositioned())
            return true;
    }
    return false;
}

void ElementBox::appendChild(UniqueRef<Box> childRef)
{
    insertChild(WTFMove(childRef), m_lastChild.get());
}

void ElementBox::insertChild(UniqueRef<Box> childRef, Box* beforeChild)
{
    auto childBox = childRef.moveToUniquePtr();
    ASSERT(!childBox->m_parent);
    ASSERT(!childBox->m_previousSibling);
    ASSERT(!childBox->m_nextSibling);

    childBox->m_parent = this;

    if (!m_firstChild || (beforeChild && !beforeChild->m_nextSibling)) {
        // Append as first and/or last.
        childBox->m_previousSibling = m_lastChild;
        auto& nextOrFirst = m_lastChild ? m_lastChild->m_nextSibling : m_firstChild;
        ASSERT(!nextOrFirst);

        m_lastChild = childBox.get();
        nextOrFirst = WTFMove(childBox);
        return;
    }

    if (!beforeChild) {
        // Insert as first.
        ASSERT(m_firstChild && m_lastChild);
        m_firstChild->m_previousSibling = childBox.get();
        childBox->m_nextSibling = WTFMove(m_firstChild);
        m_firstChild = WTFMove(childBox);
        return;
    }

    ASSERT(&beforeChild->parent() == this);
    auto* nextSibling = beforeChild->m_nextSibling.get();
    ASSERT(nextSibling);
    childBox->m_previousSibling = beforeChild;
    childBox->m_nextSibling = WTFMove(beforeChild->m_nextSibling);
    nextSibling->m_previousSibling = childBox.get();
    beforeChild->m_nextSibling = WTFMove(childBox);
}

void ElementBox::destroyChildren()
{
    m_lastChild = nullptr;

    auto childToDestroy = std::exchange(m_firstChild, nullptr);
    while (childToDestroy) {
        childToDestroy->m_parent = nullptr;
        childToDestroy->m_previousSibling = nullptr;
        if (childToDestroy->m_nextSibling)
            childToDestroy->m_nextSibling->m_previousSibling = nullptr;
        childToDestroy = std::exchange(childToDestroy->m_nextSibling, nullptr);
    }
}

bool ElementBox::hasIntrinsicWidth() const
{
    return (m_replacedData && m_replacedData->intrinsicSize) || style().logicalWidth().isIntrinsic();
}

bool ElementBox::hasIntrinsicHeight() const
{
    return (m_replacedData && m_replacedData->intrinsicSize) || style().logicalHeight().isIntrinsic();
}

bool ElementBox::hasIntrinsicRatio() const
{
    if (!hasAspectRatio())
        return false;
    return m_replacedData && (m_replacedData->intrinsicSize || m_replacedData->intrinsicRatio);
}

LayoutUnit ElementBox::intrinsicWidth() const
{
    ASSERT(hasIntrinsicWidth());
    if (m_replacedData && m_replacedData->intrinsicSize)
        return m_replacedData->intrinsicSize->width();
    return LayoutUnit { style().logicalWidth().value() };
}

LayoutUnit ElementBox::intrinsicHeight() const
{
    ASSERT(hasIntrinsicHeight());
    if (m_replacedData && m_replacedData->intrinsicSize)
        return m_replacedData->intrinsicSize->height();
    return LayoutUnit { style().logicalHeight().value() };
}

LayoutUnit ElementBox::intrinsicRatio() const
{
    ASSERT(hasIntrinsicRatio() || (hasIntrinsicWidth() && hasIntrinsicHeight()));
    if (m_replacedData) {
        if (m_replacedData->intrinsicRatio)
            return *m_replacedData->intrinsicRatio;
        if (m_replacedData->intrinsicSize->height())
            return m_replacedData->intrinsicSize->width() / m_replacedData->intrinsicSize->height();
    }
    return 1;
}

bool ElementBox::hasAspectRatio() const
{
    return isImage();
}

RenderElement* ElementBox::rendererForIntegration() const
{
    return downcast<RenderElement>(Box::rendererForIntegration());
}

}
}
