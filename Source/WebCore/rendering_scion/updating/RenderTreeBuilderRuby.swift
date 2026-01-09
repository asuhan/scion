/*
 * Copyright (C) 2017 Apple Inc. All rights reserved.
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

func createAnonymousStyleForRuby(parentStyle: RenderStyleWrapper, display: DisplayType)
  -> RenderStyleWrapper
{
  assert(display == .Ruby || display == .RubyBase)

  let style = RenderStyleWrapper.createAnonymousStyleWithDisplay(
    parentStyle: parentStyle, display: display)
  style.setUnicodeBidi(v: .Isolate)
  if display == .RubyBase {
    style.setTextWrapMode(v: .NoWrap)
  }
  return style
}

private func createAnonymousRendererForRuby(parent: RenderElementWrapper, display: DisplayType)
  -> RenderElementWrapper
{
  let style = createAnonymousStyleForRuby(parentStyle: parent.style(), display: display)
  let ruby = CreateRenderer.RenderInline(type: .Inline, document: parent.document(), style: style)
  ruby.initializeStyle()
  return ruby
}

extension RenderTreeBuilder {
  class Ruby {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func findOrCreateParentForStyleBasedRubyChild(
      parent: RenderElementWrapper, child: RenderObjectWrapper,
      beforeChild: inout RenderObjectWrapper?
    ) -> RenderElementWrapper {
      if !child.isRenderText() && child.style().display() == .Ruby
        && parent.style().display() == .RubyBlock
      {
        return parent
      }

      if parent.style().display() == .RubyBlock {
        // See if we have an anonymous ruby box already.
        // FIXME: It should be the immediate child but continuations can break this assumption.
        var first = parent.firstChild()
        while first != nil {
          if !first!.isAnonymous() {
            // <ruby blockified><ruby> is valid and still requires construction of an anonymous inline ruby box.
            assert(first!.style().display() == .Ruby)
            break
          }
          if first!.style().display() == .Ruby {
            return first as! RenderElementWrapper
          }
          first = first!.firstChildSlow()
        }
      }

      if parent.style().display() != .Ruby {
        let rubyContainer = createAnonymousRendererForRuby(parent: parent, display: .Ruby)
        builder.attach(parent: parent, child: rubyContainer, beforeChild: beforeChild)
        beforeChild = nil
        return rubyContainer
      }

      if !child.isRenderText()
        && (child.style().display() == .RubyBase || child.style().display() == .RubyAnnotation)
      {
        return parent
      }

      if beforeChild != nil && beforeChild!.parent()!.style().display() == .RubyBase {
        return beforeChild!.parent()!
      }

      let previous = beforeChild != nil ? beforeChild!.previousSibling() : parent.lastChild()
      if previous != nil && previous!.style().display() == .RubyBase {
        beforeChild = nil
        return previous as! RenderElementWrapper
      }

      let rubyBase = createAnonymousRendererForRuby(parent: parent, display: .RubyBase)
      rubyBase.initializeStyle()
      builder.inlineBuilder!.attach(
        parent: parent as! RenderInlineWrapper, child: rubyBase, beforeChild: beforeChild)
      beforeChild = nil
      return rubyBase
    }

    func attachForStyleBasedRuby(
      parent: RenderElementWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      if parent.style().display() == .RubyBlock {
        assert(child!.style().display() == .Ruby)
        builder.attachToRenderElementInternal(
          parent: parent, child: child, beforeChild: beforeChild)
        return
      }
      assert(parent.style().display() == .Ruby)
      assert(child!.style().display() == .RubyBase || child!.style().display() == .RubyAnnotation)

      var beforeChild = beforeChild
      while beforeChild != nil && beforeChild!.parent() != nil
        && CPtrToInt(beforeChild!.parent()!.p) != CPtrToInt(parent.p)
      {
        beforeChild = beforeChild!.parent()
      }

      if child!.style().display() == .RubyAnnotation {
        // Create an empty anonymous base if it is missing.
        let previous = beforeChild != nil ? beforeChild!.previousSibling() : parent.lastChild()
        if previous == nil || previous!.style().display() != .RubyBase {
          let rubyBase = createAnonymousRendererForRuby(parent: parent, display: .RubyBase)
          builder.attachToRenderElementInternal(
            parent: parent, child: rubyBase, beforeChild: beforeChild)
        }
      }
      builder.attachToRenderElementInternal(parent: parent, child: child, beforeChild: beforeChild)
    }

    private let builder: RenderTreeBuilder
  }
}
