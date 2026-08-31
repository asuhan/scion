/*
 * Copyright (C) 2004-2020 Apple Inc. All rights reserved.
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
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#pragma once

#include "CharacterRange.h"
#include "FindOptions.h"
#include "InlineIteratorLogicalOrderTraversal.h"
#include "InlineIteratorTextBox.h"
#include "SimpleRange.h"
#include "TextIterator.h"
#include "TextIteratorBehavior.h"
#include <wtf/TZoneMalloc.h>
#include <wtf/Vector.h>

namespace WebCore {

class TextBoxIteratorScion {
public:
    TextBoxIteratorScion();

    TextBoxIteratorScion(void* handle)
        : m_handle(handle)
    {
    }

    explicit operator bool() const;

    bool operator==(const TextBoxIteratorScion&) const;

    unsigned start() const;

    unsigned end() const;

    unsigned length() const;

    bool isOnSameLineAs(const TextBoxIteratorScion&) const;

    TextBoxIteratorScion nextTextBox() const;

private:
    void* m_handle;
};

class TextLogicalOrderCacheScion {};

class TextIteratorScion {
    WTF_MAKE_TZONE_ALLOCATED_EXPORT(TextIteratorScion, WEBCORE_EXPORT);

public:
    WEBCORE_EXPORT explicit TextIteratorScion(const SimpleRange&, TextIteratorBehaviors = {});
    WEBCORE_EXPORT ~TextIteratorScion();

    bool atEnd() const { return !m_positionNode; }
    WEBCORE_EXPORT void advance();

    StringView text() const
    {
        ASSERT(!atEnd());
        return m_text;
    }
    WEBCORE_EXPORT SimpleRange range() const;
    WEBCORE_EXPORT Node* node() const;
    RefPtr<Node> protectedCurrentNode() const;

    const TextIteratorCopyableText& copyableText() const
    {
        ASSERT(!atEnd());
        return m_copyableText;
    }
    void appendTextToStringBuilder(StringBuilder& builder) const { copyableText().appendToStringBuilder(builder); }

#if ENABLE(TREE_DEBUGGING)
    void showTreeForThis() const;
#endif
    String rendererTextForBehavior(RenderText& renderer) const { return m_behaviors.contains(TextIteratorBehavior::EmitsOriginalText) ? renderer.originalText() : renderer.text(); }

private:
    void init();
    void exitNode(Node*);
    bool shouldRepresentNodeOffsetZero();
    bool shouldEmitSpaceBeforeAndAfterNode(Node&);
    void representNodeOffsetZero();
    bool handleTextNode();
    bool handleReplacedElement();
    bool handleNonTextNode();
    void handleTextRun();
    void handleTextNodeFirstLetter(RenderTextFragment&);
    void emitCharacter(UChar, RefPtr<Node>&& characterNode, RefPtr<Node>&& offsetBaseNode, int textStartOffset, int textEndOffset);
    void emitText(Text& textNode, RenderText&, int textStartOffset, int textEndOffset);
    void revertToRemainingTextRun();

    Node* baseNodeForEmittingNewLine() const;

    RefPtr<Node> protectedStartContainer() const { return m_startContainer; }

    const TextIteratorBehaviors m_behaviors;

    // Current position, not necessarily of the text being returned, but position as we walk through the DOM tree.
    RefPtr<Node> m_currentNode;
    int m_offset { 0 };
    bool m_handledNode { false };
    bool m_handledChildren { false };
    BitStack m_fullyClippedStack;

    // The range.
    RefPtr<Node> m_startContainer;
    int m_startOffset { 0 };
    RefPtr<Node> m_endContainer;
    int m_endOffset { 0 };
    RefPtr<Node> m_pastEndNode;

    // The current text and its position, in the form to be returned from the iterator.
    RefPtr<Node> m_positionNode;
    mutable RefPtr<Node> m_positionOffsetBaseNode;
    mutable int m_positionStartOffset { 0 };
    mutable int m_positionEndOffset { 0 };
    TextIteratorCopyableText m_copyableText;
    StringView m_text;

    // Used when there is still some pending text from the current node; when these are false and null, we go back to normal iterating.
    RefPtr<Node> m_nodeForAdditionalNewline;
    TextBoxIteratorScion m_textRun;
    TextLogicalOrderCacheScion m_textRunLogicalOrderCache;

    // Used when iterating over :first-letter text to save pointer to remaining text box.
    TextBoxIteratorScion m_remainingTextRun;
    TextLogicalOrderCacheScion m_remainingTextRunLogicalOrderCache;

    // Used to point to RenderText object for :first-letter.
    SingleThreadWeakPtr<RenderText> m_firstLetterText;

    // Used to do the whitespace collapsing logic.
    RefPtr<Text> m_lastTextNode;
    bool m_lastTextNodeEndedWithCollapsedSpace { false };
    UChar m_lastCharacter { 0 };

    // Used when deciding whether to emit a "positioning" (e.g. newline) before any other content
    bool m_hasEmitted { false };

    // Used when deciding text fragment created by :first-letter should be looked into.
    bool m_handledFirstLetter { false };
};

namespace InlineIterator {

std::pair<TextBoxIteratorScion, TextLogicalOrderCacheScion> firstTextBoxInLogicalOrderForScion(const RenderText&);
TextBoxIteratorScion nextTextBoxInLogicalOrderScion(const TextBoxIteratorScion&, TextLogicalOrderCacheScion&);

} // namespace InlineIterator

} // namespace WebCore
