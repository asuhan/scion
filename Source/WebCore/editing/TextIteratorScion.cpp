/*
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2015-2018 Google Inc. All rights reserved.
 * Copyright (C) 2005 Alexey Proskuryakov.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "TextIteratorScion.h"

#include "ComposedTreeIterator.h"
#include "Document.h"
#include "Editing.h"
#include "ElementInlines.h"
#include "ElementRareData.h"
#include "FontCascade.h"
#include "HTMLAttachmentElement.h"
#include "HTMLBodyElement.h"
#include "HTMLElement.h"
#include "HTMLFrameOwnerElement.h"
#include "HTMLImageElement.h"
#include "HTMLInputElement.h"
#include "HTMLLegendElement.h"
#include "HTMLMeterElement.h"
#include "HTMLNames.h"
#include "HTMLParagraphElement.h"
#include "HTMLProgressElement.h"
#include "HTMLSlotElement.h"
#include "HTMLTextAreaElement.h"
#include "HTMLTextFormControlElement.h"
#include "ImageOverlay.h"
#include "LocalFrame.h"
#include "NodeTraversal.h"
#include "Range.h"
#include "RenderBoxInlines.h"
#include "RenderImage.h"
#include "RenderIterator.h"
#include "RenderTableCell.h"
#include "RenderTableRow.h"
#include "RenderTextControl.h"
#include "RenderTextFragment.h"
#include "ShadowRoot.h"
#include "TextBoundaries.h"
#include "TextControlInnerElements.h"
#include "TextPlaceholderElement.h"
#include "VisiblePosition.h"
#include "VisibleUnits.h"
#include <unicode/unorm2.h>
#include <wtf/Function.h>
#include <wtf/TZoneMallocInlines.h>
#include <wtf/text/CString.h>
#include <wtf/text/MakeString.h>
#include <wtf/text/StringBuilder.h>
#include <wtf/text/TextBreakIterator.h>
#include <wtf/unicode/CharacterNames.h>
#include <wtf/unicode/icu/ICUHelpers.h>

#if !UCONFIG_NO_COLLATION
#include <unicode/usearch.h>
#include <wtf/text/TextBreakIteratorInternalICU.h>
#endif

extern "C" uint32_t TextBox_start(const void*);

extern "C" uint32_t TextBox_length(const void*);

extern "C" void* TextBox_nextTextBox(const void*);

extern "C" void* TextBoxIterator_create();

extern "C" bool TextBoxIterator_bool(const void*);

extern "C" void* TextBoxIterator_get(const void*);

extern "C" bool TextBoxIterator_eq(const void*, const void*);

extern "C" void* InlineIterator_firstTextBoxInLogicalOrderFor(const void*);

namespace WebCore {

unsigned TextBoxScion::start() const
{
    return TextBox_start(m_handle);
}

unsigned TextBoxScion::length() const
{
    return TextBox_length(m_handle);
}

TextBoxIteratorScion TextBoxScion::nextTextBox() const
{
    return TextBoxIteratorScion(TextBox_nextTextBox(m_handle));
}

TextBoxIteratorScion::TextBoxIteratorScion()
{
    m_handle = TextBoxIterator_create();
}

TextBoxIteratorScion::operator bool() const
{
    return TextBoxIterator_bool(m_handle);
}

const TextBoxScion* TextBoxIteratorScion::operator->() const
{
    return static_cast<const TextBoxScion*>(TextBoxIterator_get(m_handle));
}

bool TextBoxIteratorScion::operator==(const TextBoxIteratorScion& rhs) const
{
    return TextBoxIterator_eq(m_handle, rhs.m_handle);
}

namespace InlineIterator {

std::pair<TextBoxIteratorScion, TextLogicalOrderCacheScion> firstTextBoxInLogicalOrderForScion(const RenderText& text)
{
    assert(text.scion());
    auto handle = InlineIterator_firstTextBoxInLogicalOrderFor(text.scion());
    return { { handle }, {} };
}

TextBoxIteratorScion nextTextBoxInLogicalOrderScion(const TextBoxIteratorScion& textBox, TextLogicalOrderCacheScion&)
{
    // TODO(asuhan): call update text logical order cache if the text needs visual reordering.
    return textBox->nextTextBox();
}

}

TextIteratorScion::TextIteratorScion(const SimpleRange& range, TextIteratorBehaviors behaviors)
    : m_behaviors(behaviors)
{
    ASSERT(!m_behaviors.contains(TextIteratorBehavior::EmitsObjectReplacementCharacters) || !m_behaviors.contains(TextIteratorBehavior::EmitsObjectReplacementCharactersForImages));

    range.start.protectedDocument()->updateLayoutIgnorePendingStylesheets();

    m_startContainer = range.start.container.ptr();
    m_startOffset = range.start.offset;
    m_endContainer = range.end.container.ptr();
    m_endOffset = range.end.offset;

    m_currentNode = firstNode(range.start);
    if (!m_currentNode)
        return;

    init();
}

void TextIteratorScion::init()
{
    auto currentNode = protectedCurrentNode();
    if (isClippedByFrameAncestor(currentNode->protectedDocument(), m_behaviors))
        return;

    setUpFullyClippedStack(m_fullyClippedStack, *currentNode);

    m_offset = currentNode == m_startContainer.get() ? m_startOffset : 0;

    m_pastEndNode = nextInPreOrderCrossingShadowBoundaries(*m_endContainer, m_endOffset);

    m_positionNode = currentNode.get();

    advance();
}

TextIteratorScion::~TextIteratorScion() = default;

void TextIteratorScion::advance()
{
    ASSERT(!atEnd());

    // reset the run information
    m_positionNode = nullptr;
    m_copyableText.reset();
    m_text = StringView();

    // handle remembered node that needed a newline after the text node's newline
    if (RefPtr nodeForAdditionalNewline = std::exchange(m_nodeForAdditionalNewline, nullptr).get()) {
        // Emit the extra newline, and position it *inside* m_node, after m_node's
        // contents, in case it's a block, in the same way that we position the first
        // newline. The range for the emitted newline should start where the line
        // break begins.
        // FIXME: It would be cleaner if we emitted two newlines during the last
        // iteration, instead of using m_needsAnotherNewline.
        auto parentNode = nodeForAdditionalNewline->protectedParentNode();
        emitCharacter('\n', WTFMove(parentNode), WTFMove(nodeForAdditionalNewline), 1, 1);
        return;
    }

    if (!m_textRun && m_remainingTextRun)
        revertToRemainingTextRun();

    // handle remembered text box
    if (m_textRun) {
        handleTextRun();
        if (m_positionNode)
            return;
    }

    while (m_currentNode && m_currentNode != m_pastEndNode) {
        // if the range ends at offset 0 of an element, represent the
        // position, but not the content, of that element e.g. if the
        // node is a blockflow element, emit a newline that
        // precedes the element
        if (m_currentNode == m_endContainer && !m_endOffset) {
            representNodeOffsetZero();
            m_currentNode = nullptr;
            return;
        }

        CheckedPtr renderer = m_currentNode->renderer();
        if (!m_handledNode) {
            if (!isRendererVisible(renderer.get(), m_behaviors)) {
                m_handledNode = true;
                m_handledChildren = !hasDisplayContents(*protectedCurrentNode()) && !renderer;
            } else if (is<Element>(m_currentNode.get()) && renderer->isSkippedContentRoot()) {
                m_handledChildren = true;
            } else {
                // handle current node according to its type
                if (renderer->isRenderText() && m_currentNode->isTextNode())
                    m_handledNode = handleTextNode();
                else if (isRendererReplacedElement(renderer.get(), m_behaviors))
                    m_handledNode = handleReplacedElement();
                else
                    m_handledNode = handleNonTextNode();
                if (m_positionNode)
                    return;
            }
        }

        // find a new current node to handle in depth-first manner,
        // calling exitNode() as we come back thru a parent node

        RefPtr next = m_handledChildren ? nullptr : firstChild(m_behaviors, *protectedCurrentNode());
        m_offset = 0;
        if (!next) {
            auto currentNode = protectedCurrentNode();
            next = nextSibling(m_behaviors, *currentNode);
            if (!next) {
                bool pastEnd = nextNode(m_behaviors, *currentNode) == m_pastEndNode;
                RefPtr parentNode = parentNodeOrShadowHost(m_behaviors, *currentNode);
                while (!next && parentNode) {
                    if ((pastEnd && parentNode == m_endContainer.get()) || isDescendantOf(m_behaviors, *m_endContainer, *parentNode))
                        return;
                    bool haveRenderer = isRendererVisible(currentNode->renderer(), m_behaviors);
                    RefPtr exitedNode = WTFMove(currentNode);
                    m_currentNode = WTFMove(parentNode);
                    currentNode = m_currentNode;
                    m_fullyClippedStack.pop();
                    parentNode = parentNodeOrShadowHost(m_behaviors, *currentNode);
                    if (haveRenderer)
                        exitNode(exitedNode.get());
                    if (m_positionNode) {
                        m_handledNode = true;
                        m_handledChildren = true;
                        return;
                    }
                    next = nextSibling(m_behaviors, *currentNode);
                    if (next && isRendererVisible(currentNode->renderer(), m_behaviors))
                        exitNode(currentNode.get());
                }
            }
            m_fullyClippedStack.pop();
        }

        // set the new current node
        m_currentNode = WTFMove(next);
        if (auto currentNode = protectedCurrentNode())
            pushFullyClippedState(m_fullyClippedStack, *currentNode);
        m_handledNode = false;
        m_handledChildren = false;
        m_handledFirstLetter = false;
        m_firstLetterText = nullptr;

        // how would this ever be?
        if (m_positionNode)
            return;
    }
}

bool TextIteratorScion::handleTextNode()
{
    Ref textNode = downcast<Text>(protectedCurrentNode().releaseNonNull());

    if (m_fullyClippedStack.top() && !m_behaviors.contains(TextIteratorBehavior::IgnoresStyleVisibility))
        return false;

    CheckedRef renderer = *textNode->renderer();
    m_lastTextNode = textNode.ptr();
    auto rendererText = rendererTextForBehavior(renderer.get());

    // handle pre-formatted text
    if (!renderer->style().collapseWhiteSpace()) {
        int runStart = m_offset;
        if (m_lastTextNodeEndedWithCollapsedSpace && hasVisibleTextNode(renderer)) {
            emitCharacter(' ', WTFMove(textNode), nullptr, runStart, runStart);
            return false;
        }
        if (CheckedPtr renderTextFragment = dynamicDowncast<RenderTextFragment>(renderer.get()); renderTextFragment && !m_handledFirstLetter && !m_offset) {
            handleTextNodeFirstLetter(*renderTextFragment);
            if (m_firstLetterText) {
                String firstLetter = m_firstLetterText->text();
                emitText(textNode, *m_firstLetterText, m_offset, m_offset + firstLetter.length());
                m_firstLetterText = nullptr;
                m_textRun = {};
                return false;
            }
        }
        if (renderer->style().visibility() != Visibility::Visible && !m_behaviors.contains(TextIteratorBehavior::IgnoresStyleVisibility))
            return false;
        int rendererTextLength = rendererText.length();
        int end = (textNode.ptr() == m_endContainer) ? m_endOffset : INT_MAX;
        int runEnd = std::min(rendererTextLength, end);

        if (runStart >= runEnd)
            return true;

        emitText(textNode, renderer, runStart, runEnd);
        return true;
    }

    std::tie(m_textRun, m_textRunLogicalOrderCache) = InlineIterator::firstTextBoxInLogicalOrderForScion(renderer.get());

    if (CheckedPtr renderTextFragment = dynamicDowncast<RenderTextFragment>(renderer.get()); renderTextFragment && !m_handledFirstLetter && !m_offset)
        handleTextNodeFirstLetter(*renderTextFragment);
    else if (!m_textRun && rendererText.length()) {
        if (renderer->style().visibility() != Visibility::Visible && !m_behaviors.contains(TextIteratorBehavior::IgnoresStyleVisibility))
            return false;
        m_lastTextNodeEndedWithCollapsedSpace = true; // entire block is collapsed space
        return true;
    }

    handleTextRun();
    return true;
}

void TextIteratorScion::handleTextRun()
{
    Ref textNode = downcast<Text>(protectedCurrentNode().releaseNonNull());

    CheckedRef renderer = m_firstLetterText ? *m_firstLetterText : *textNode->renderer();
    if (renderer->style().visibility() != Visibility::Visible && !m_behaviors.contains(TextIteratorBehavior::IgnoresStyleVisibility)) {
        m_textRun = {};
        return;
    }

    auto [firstTextRun, orderCache] = InlineIterator::firstTextBoxInLogicalOrderForScion(renderer);

    auto rendererText = rendererTextForBehavior(renderer.get());
    unsigned rangeStart = m_offset;
    auto rangeEnd = std::optional<unsigned> {};
    if (textNode.ptr() == m_endContainer)
        rangeEnd = m_endOffset;

    while (m_textRun) {
        auto textRunStart = m_textRun->start();
        auto textRunEnd = textRunStart + m_textRun->length();

        auto runStart = std::max(textRunStart, rangeStart);
        auto runEnd = std::min(textRunEnd, rangeEnd.value_or(textRunEnd));

        // Check if we need to emit (previously) collapsed whitespace at the start of this run.
        auto isAfterRangeEnd = rangeEnd ? runStart > *rangeEnd : false;
        auto hasPrecedingCollapsedWhitespace = m_lastTextNodeEndedWithCollapsedSpace || (m_textRun == firstTextRun && textRunStart == runStart && runStart);
        auto shouldEmitWhitespace = !isAfterRangeEnd && hasPrecedingCollapsedWhitespace && m_lastCharacter && !renderer->style().isCollapsibleWhiteSpace(m_lastCharacter);
        if (shouldEmitWhitespace) {
            if (m_lastTextNode == textNode.ptr() && runStart && renderer->style().isCollapsibleWhiteSpace(rendererText[runStart - 1])) {
                unsigned spaceRunStart = runStart - 1;
                while (spaceRunStart && renderer->style().isCollapsibleWhiteSpace(rendererText[spaceRunStart - 1]))
                    --spaceRunStart;
                emitCharacter(' ', WTFMove(textNode), nullptr, spaceRunStart, spaceRunStart + 1);
            } else
                emitCharacter(' ', WTFMove(textNode), nullptr, runStart, runStart);
            return;
        }

        // Determine what the next text run will be, but don't advance yet
        auto nextTextRun = InlineIterator::nextTextBoxInLogicalOrderScion(m_textRun, m_textRunLogicalOrderCache);
        if (runStart < runEnd) {
            auto isNewlineOrTab = [&](UChar character) {
                return character == '\n' || character == '\t';
            };
            // Handle either a single newline or tab character (which becomes a space),
            // or a run of characters that does not include newlines or tabs.
            // This effectively translates newlines and tabs to spaces without copying the text.
            if (isNewlineOrTab(rendererText[runStart])) {
                emitCharacter(' ', textNode.copyRef(), nullptr, runStart, runStart + 1);
                m_offset = runStart + 1;
            } else {
                auto subrunEnd = runStart + 1;
                for (; subrunEnd < runEnd; ++subrunEnd) {
                    if (isNewlineOrTab(rendererText[subrunEnd]))
                        break;
                }
                if (subrunEnd == runEnd && m_behaviors.contains(TextIteratorBehavior::BehavesAsIfNodesFollowing)) {
                    bool lastSpaceCollapsedByNextNonTextRun = !nextTextRun && rendererText.length() > subrunEnd && rendererText[subrunEnd] == ' ';
                    if (lastSpaceCollapsedByNextNonTextRun)
                        ++subrunEnd; // runEnd stopped before last space. Increment by one to restore the space.
                }
                m_offset = subrunEnd;
                emitText(textNode, renderer, runStart, subrunEnd);
            }

            // If we are doing a subrun that doesn't go to the end of the text box,
            // come back again to finish handling this text box; don't advance to the next one.
            if (static_cast<unsigned>(m_positionEndOffset) < textRunEnd)
                return;

            // Advance and return
            unsigned nextRunStart = nextTextRun ? nextTextRun->start() : rendererText.length();
            if (nextRunStart > runEnd)
                m_lastTextNodeEndedWithCollapsedSpace = true; // collapsed space between runs or at the end
            m_textRun = nextTextRun;
            return;
        }
        // Advance and continue
        m_textRun = nextTextRun;
    }
    if (!m_textRun && m_remainingTextRun) {
        revertToRemainingTextRun();
        handleTextRun();
    }
}

void TextIteratorScion::revertToRemainingTextRun()
{
    ASSERT(!m_textRun && m_remainingTextRun);

    m_textRun = m_remainingTextRun;
    m_textRunLogicalOrderCache = std::exchange(m_remainingTextRunLogicalOrderCache, {});
    m_remainingTextRun = {};
    m_firstLetterText = {};
    m_offset = 0;
}

void TextIteratorScion::handleTextNodeFirstLetter(RenderTextFragment& renderer)
{
    if (CheckedPtr firstLetter = renderer.firstLetter()) {
        if (firstLetter->style().visibility() != Visibility::Visible && !m_behaviors.contains(TextIteratorBehavior::IgnoresStyleVisibility))
            return;
        if (CheckedPtr firstLetterText = firstRenderTextInFirstLetter(firstLetter.get())) {
            m_handledFirstLetter = true;
            m_remainingTextRun = m_textRun;
            m_remainingTextRunLogicalOrderCache = std::exchange(m_textRunLogicalOrderCache, {});
            std::tie(m_textRun, m_textRunLogicalOrderCache) = InlineIterator::firstTextBoxInLogicalOrderForScion(*firstLetterText);
            m_firstLetterText = firstLetterText.get();
        }
    }
    m_handledFirstLetter = true;
}

bool TextIteratorScion::handleReplacedElement()
{
    if (m_fullyClippedStack.top())
        return false;

    CheckedRef renderer = *m_currentNode->renderer();
    if (renderer->style().visibility() != Visibility::Visible && !m_behaviors.contains(TextIteratorBehavior::IgnoresStyleVisibility))
        return false;

    if (m_lastTextNodeEndedWithCollapsedSpace) {
        emitCharacter(' ', m_lastTextNode->protectedParentNode(), m_lastTextNode.copyRef(), 1, 1);
        return false;
    }

    if (CheckedPtr renderTextControl = dynamicDowncast<RenderTextControl>(renderer.get()); renderTextControl && m_behaviors.contains(TextIteratorBehavior::EntersTextControls)) {
        if (auto innerTextElement = renderTextControl->textFormControlElement().innerTextElement()) {
            m_currentNode = innerTextElement->containingShadowRoot();
            pushFullyClippedState(m_fullyClippedStack, *protectedCurrentNode());
            m_offset = 0;
            return false;
        }
    }

    RefPtr currentElement = dynamicDowncast<HTMLElement>(m_currentNode.get());
    if (m_behaviors.contains(TextIteratorBehavior::EntersImageOverlays) && currentElement && ImageOverlay::hasOverlay(*currentElement)) {
        if (RefPtr shadowRoot = m_currentNode->shadowRoot()) {
            m_currentNode = WTFMove(shadowRoot);
            pushFullyClippedState(m_fullyClippedStack, *protectedCurrentNode());
            m_offset = 0;
            return false;
        }
        ASSERT_NOT_REACHED();
    }

    m_hasEmitted = true;

    auto shouldEmitObjectReplacementCharacter = [&] {
        if (m_behaviors.contains(TextIteratorBehavior::EmitsObjectReplacementCharacters))
            return true;

        if (m_behaviors.contains(TextIteratorBehavior::EmitsObjectReplacementCharactersForImages) && is<HTMLImageElement>(m_currentNode.get()))
            return true;

#if ENABLE(ATTACHMENT_ELEMENT)
        if (m_behaviors.contains(TextIteratorBehavior::EmitsObjectReplacementCharactersForAttachments) && is<HTMLAttachmentElement>(m_currentNode.get()))
            return true;
#endif

        return false;
    }();

    if (shouldEmitObjectReplacementCharacter) {
        emitCharacter(objectReplacementCharacter, m_currentNode->protectedParentNode(), protectedCurrentNode(), 0, 1);
        // Don't process subtrees for embedded objects. If the text there is required,
        // it must be explicitly asked by specifying a range falling inside its boundaries.
        m_handledChildren = true;
        return true;
    }

    if (m_behaviors.contains(TextIteratorBehavior::EmitsCharactersBetweenAllVisiblePositions)) {
        // We want replaced elements to behave like punctuation for boundary
        // finding, and to simply take up space for the selection preservation
        // code in moveParagraphs, so we use a comma.
        emitCharacter(',', m_currentNode->protectedParentNode(), protectedCurrentNode(), 0, 1);
        return true;
    }

    m_positionNode = m_currentNode->parentNode();
    m_positionOffsetBaseNode = m_currentNode;
    m_positionStartOffset = 0;
    m_positionEndOffset = 1;

    if (CheckedPtr renderImage = dynamicDowncast<RenderImage>(renderer.get()); renderImage && m_behaviors.contains(TextIteratorBehavior::EmitsImageAltText)) {
        auto altText = renderImage->altText();
        if (unsigned length = altText.length()) {
            m_lastCharacter = altText[length - 1];
            m_copyableText.set(WTFMove(altText));
            m_text = m_copyableText.text();
            return true;
        }
    }

    m_copyableText.reset();
    m_text = StringView();
    m_lastCharacter = 0;
    return true;
}

// Whether or not we should emit a character as we enter m_currentNode (if it's a container) or as we hit it (if it's atomic).
bool TextIteratorScion::shouldRepresentNodeOffsetZero()
{
    if (m_behaviors.contains(TextIteratorBehavior::EmitsCharactersBetweenAllVisiblePositions)) {
        if (CheckedPtr renderer = m_currentNode->renderer(); renderer && renderer->isRenderTable())
            return true;
    }

    // Leave element positioned flush with start of a paragraph
    // (e.g. do not insert tab before a table cell at the start of a paragraph)
    if (m_lastCharacter == '\n')
        return false;

    // Otherwise, show the position if we have emitted any characters
    if (m_hasEmitted)
        return true;

    // We've not emitted anything yet. Generally, there is no need for any positioning then.
    // The only exception is when the element is visually not in the same line as
    // the start of the range (e.g. the range starts at the end of the previous paragraph).
    // NOTE: Creating VisiblePositions and comparing them is relatively expensive, so we
    // make quicker checks to possibly avoid that. Another check that we could make is
    // is whether the inline vs block flow changed since the previous visible element.
    // I think we're already in a special enough case that that won't be needed, tho.

    // No character needed if this is the first node in the range.
    if (m_currentNode == m_startContainer)
        return false;

    // If we are outside the start container's subtree, assume we need to emit.
    // FIXME: m_startContainer could be an inline block
    Ref currentNode = *m_currentNode;
    if (!currentNode->isDescendantOf(m_startContainer.get()))
        return true;

    // If we started as m_startContainer offset 0 and the current node is a descendant of
    // the start container, we already had enough context to correctly decide whether to
    // emit after a preceding block. We chose not to emit (m_hasEmitted is false),
    // so don't second guess that now.
    // NOTE: Is this really correct when m_currentNode is not a leftmost descendant? Probably
    // immaterial since we likely would have already emitted something by now.
    if (m_startOffset == 0)
        return false;

    // If this node is unrendered or invisible the VisiblePosition checks below won't have much meaning.
    // Additionally, if the range we are iterating over contains huge sections of unrendered content,
    // we would create VisiblePositions on every call to this function without this check.
    if (!currentNode->renderer() || currentNode->renderer()->style().visibility() != Visibility::Visible)
        return false;

    if (CheckedPtr renderBlockFlow = dynamicDowncast<RenderBlockFlow>(*currentNode->renderer())) {
        if (!renderBlockFlow->height() && !is<HTMLBodyElement>(currentNode))
            return false;
    }

    // The startPos.isNotNull() check is needed because the start could be before the body,
    // and in that case we'll get null. We don't want to put in newlines at the start in that case.
    // The currPos.isNotNull() check is needed because positions in non-HTML content
    // (like SVG) do not have visible positions, and we don't want to emit for them either.
    VisiblePosition startPos = VisiblePosition(Position(protectedStartContainer(), m_startOffset, Position::PositionIsOffsetInAnchor));
    VisiblePosition currPos = VisiblePosition(positionBeforeNode(currentNode.ptr()));
    return startPos.isNotNull() && currPos.isNotNull() && !inSameLine(startPos, currPos);
}

bool TextIteratorScion::shouldEmitSpaceBeforeAndAfterNode(Node& node)
{
    return node.renderer() && node.renderer()->isRenderTable() && (node.renderer()->isInline() || m_behaviors.contains(TextIteratorBehavior::EmitsCharactersBetweenAllVisiblePositions));
}

void TextIteratorScion::representNodeOffsetZero()
{
    // Emit a character to show the positioning of m_currentNode.

    // When we haven't been emitting any characters, shouldRepresentNodeOffsetZero() can
    // create VisiblePositions, which is expensive. So, we perform the inexpensive checks
    // on m_currentNode to see if it necessitates emitting a character first and will early return
    // before encountering shouldRepresentNodeOffsetZero()s worse case behavior.
    auto currentNode = protectedCurrentNode();
    if (shouldEmitTabBeforeNode(*currentNode)) {
        if (shouldRepresentNodeOffsetZero()) {
            auto parentNode = currentNode->protectedParentNode();
            emitCharacter('\t', WTFMove(parentNode), WTFMove(currentNode), 0, 0);
        }
    } else if (shouldEmitNewlineBeforeNode(*currentNode)) {
        if (shouldRepresentNodeOffsetZero()) {
            auto parentNode = currentNode->protectedParentNode();
            emitCharacter('\n', WTFMove(parentNode), WTFMove(currentNode), 0, 0);
        }
    } else if (shouldEmitSpaceBeforeAndAfterNode(*currentNode)) {
        if (shouldRepresentNodeOffsetZero()) {
            auto parentNode = currentNode->protectedParentNode();
            emitCharacter(' ', WTFMove(parentNode), WTFMove(currentNode), 0, 0);
        }
    } else if (shouldEmitReplacementInsteadOfNode(*currentNode)) {
        if (shouldRepresentNodeOffsetZero()) {
            auto parentNode = currentNode->protectedParentNode();
            emitCharacter(objectReplacementCharacter, WTFMove(parentNode), WTFMove(currentNode), 0, 0);
        }
    }
}

bool TextIteratorScion::handleNonTextNode()
{
    auto currentNode = protectedCurrentNode();
    if (shouldEmitNewlineForNode(currentNode.get(), m_behaviors.contains(TextIteratorBehavior::EmitsOriginalText))) {
        auto parentNode = currentNode->protectedParentNode();
        emitCharacter('\n', WTFMove(parentNode), WTFMove(currentNode), 0, 1);
    } else if (m_behaviors.contains(TextIteratorBehavior::EmitsCharactersBetweenAllVisiblePositions) && currentNode->renderer() && currentNode->renderer()->isHR()) {
        auto parentNode = currentNode->protectedParentNode();
        emitCharacter(' ', WTFMove(parentNode), WTFMove(currentNode), 0, 1);
    } else
        representNodeOffsetZero();

    return true;
}

void TextIteratorScion::exitNode(Node* exitedNode)
{
    // prevent emitting a newline when exiting a collapsed block at beginning of the range
    // FIXME: !m_hasEmitted does not necessarily mean there was a collapsed block... it could
    // have been an hr (e.g.). Also, a collapsed block could have height (e.g. a table) and
    // therefore look like a blank line.
    if (!m_hasEmitted)
        return;

    // Emit with a position *inside* m_currentNode, after m_currentNode's contents, in
    // case it is a block, because the run should start where the
    // emitted character is positioned visually.
    RefPtr baseNode = exitedNode;
    // FIXME: This shouldn't require the m_lastTextNode to be true, but we can't change that without making
    // the logic in _web_attributedStringFromRange match. We'll get that for free when we switch to use
    // TextIteratorScion in _web_attributedStringFromRange.
    // See <rdar://problem/5428427> for an example of how this mismatch will cause problems.
    if (m_lastTextNode && shouldEmitNewlineAfterNode(*protectedCurrentNode(), m_behaviors.contains(TextIteratorBehavior::EmitsCharactersBetweenAllVisiblePositions))) {
        // use extra newline to represent margin bottom, as needed
        bool addNewline = shouldEmitExtraNewlineForNode(*protectedCurrentNode());

        // FIXME: We need to emit a '\n' as we leave an empty block(s) that
        // contain a VisiblePosition when doing selection preservation.
        if (m_lastCharacter != '\n') {
            // insert a newline with a position following this block's contents.
            emitCharacter('\n', baseNode->protectedParentNode(), baseNode.copyRef(), 1, 1);
            // remember whether to later add a newline for the current node
            ASSERT(!m_nodeForAdditionalNewline);
            if (addNewline)
                m_nodeForAdditionalNewline = baseNode.get();
        } else if (addNewline)
            // insert a newline with a position following this block's contents.
            emitCharacter('\n', baseNode->protectedParentNode(), baseNode.copyRef(), 1, 1);
    }

    // If nothing was emitted, see if we need to emit a space.
    if (!m_positionNode && shouldEmitSpaceBeforeAndAfterNode(*protectedCurrentNode())) {
        auto parentNode = baseNode->protectedParentNode();
        emitCharacter(' ', WTFMove(parentNode), WTFMove(baseNode), 1, 1);
    }
}

void TextIteratorScion::emitCharacter(UChar character, RefPtr<Node>&& characterNode, RefPtr<Node>&& offsetBaseNode, int textStartOffset, int textEndOffset)
{
    ASSERT(characterNode);
    m_hasEmitted = true;

    // remember information with which to construct the TextIteratorScion::range()
    m_positionNode = WTFMove(characterNode);
    m_positionOffsetBaseNode = WTFMove(offsetBaseNode);
    m_positionStartOffset = textStartOffset;
    m_positionEndOffset = textEndOffset;

    m_copyableText.set(character);
    m_text = m_copyableText.text();
    m_lastCharacter = character;
    m_lastTextNodeEndedWithCollapsedSpace = false;
}

void TextIteratorScion::emitText(Text& textNode, RenderText& renderer, int textStartOffset, int textEndOffset)
{
    ASSERT(textStartOffset >= 0);
    ASSERT(textEndOffset >= 0);
    ASSERT(textStartOffset <= textEndOffset);

    bool shouldIgnoreFullSizeKana = m_behaviors.contains(TextIteratorBehavior::IgnoresFullSizeKana) && renderer.style().textTransform().contains(TextTransform::FullSizeKana);

    // FIXME: This probably yields the wrong offsets when text-transform: lowercase turns a single character into two characters.
    String string = m_behaviors.contains(TextIteratorBehavior::EmitsOriginalText) || shouldIgnoreFullSizeKana ? renderer.originalText()
                                                                                                              : (m_behaviors.contains(TextIteratorBehavior::EmitsTextsWithoutTranscoding) ? renderer.textWithoutConvertingBackslashToYenSymbol() : renderer.text());

    ASSERT(m_behaviors.contains(TextIteratorBehavior::EmitsOriginalText) || string.length() >= static_cast<unsigned>(textEndOffset));

    textEndOffset = std::min(string.length(), static_cast<unsigned>(textEndOffset));

    m_positionNode = &textNode;
    m_positionOffsetBaseNode = nullptr;
    m_positionStartOffset = textStartOffset;
    m_positionEndOffset = textEndOffset;

    m_lastCharacter = string[textEndOffset - 1];
    m_copyableText.set(WTFMove(string), textStartOffset, textEndOffset - textStartOffset);
    m_text = m_copyableText.text();

    m_lastTextNodeEndedWithCollapsedSpace = false;
    m_hasEmitted = true;
}

SimpleRange TextIteratorScion::range() const
{
    ASSERT(!atEnd());
    // Use the current run information, if we have it.
    if (m_positionOffsetBaseNode) {
        unsigned index = m_positionOffsetBaseNode->computeNodeIndex();
        m_positionStartOffset += index;
        m_positionEndOffset += index;
        m_positionOffsetBaseNode = nullptr;
    }
    return { { *m_positionNode, static_cast<unsigned>(m_positionStartOffset) }, { *m_positionNode, static_cast<unsigned>(m_positionEndOffset) } };
}

Node* TextIteratorScion::node() const
{
    auto start = this->range().start;
    if (start.container->isCharacterDataNode())
        return start.container.ptr();
    return start.container->traverseToChildAt(start.offset);
}

RefPtr<Node> TextIteratorScion::protectedCurrentNode() const
{
    return m_currentNode;
}

#if ENABLE(TREE_DEBUGGING)
void TextIteratorScion::showTreeForThis() const
{
    if (m_currentNode)
        m_currentNode->showTreeForThis();
    fprintf(stderr, "offset: %d\n", m_offset);
}
#endif

}