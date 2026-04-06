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

import wk_interop

func CPtrToInt(_ p: UnsafeRawPointer?) -> UInt {
  return UInt(bitPattern: p)
}

class LayoutStateWrapper {
  // Primary layout state has a direct geometry cache in layout boxes.
  enum `Type` {
    case Primary
    case Secondary
  }

  typealias FormattingContextLayoutFunction = (ElementBoxWrapper, LayoutUnit?, LayoutStateWrapper)
    -> Void
  typealias FormattingContextLogicalWidthFunction = (
    ElementBoxWrapper, LayoutIntegration.LogicalWidthType
  ) -> LayoutUnit

  init(
    _ document: Document, _ rootContainer: ElementBoxWrapper, _ type: `Type`,
    _ formattingContextLayoutFunction: @escaping FormattingContextLayoutFunction,
    _ formattingContextLogicalWidthFunction: @escaping FormattingContextLogicalWidthFunction
  ) {
    m_type = type
    m_rootContainer = rootContainer
    m_securityOrigin = document.securityOrigin()
    m_formattingContextLayoutFunction = formattingContextLayoutFunction
    m_formattingContextLogicalWidthFunction = formattingContextLogicalWidthFunction
    // It makes absolutely no sense to construct a dedicated layout state for a non-formatting context root (layout would be a no-op).
    assert(root().establishesFormattingContext())

    updateQuirksMode(document)
  }

  init(p: UnsafeMutableRawPointer?) {
    self.p = p
    m_type = .Primary
    m_rootContainer = nil
    m_securityOrigin = nil
    m_formattingContextLayoutFunction = nil
    m_formattingContextLogicalWidthFunction = nil
  }

  deinit {
    if interopOwner {
      wk_interop.LayoutState_destroy(p)
    }
  }

  func updateQuirksMode(_ document: Document) {
    let quirksMode = { () -> QuirksMode in
      if document.inLimitedQuirksMode() {
        return .Limited
      }
      if document.inQuirksMode() {
        return .Yes
      }
      return .No
    }
    setQuirksMode(quirksMode())
  }

  func inlineContentCache(formattingContextRoot: ElementBoxWrapper) -> InlineContentCache {
    assert(formattingContextRoot.establishesInlineFormattingContext())
    let key = CPtrToInt(formattingContextRoot.p)
    if let cache = inlineContentCaches[key] {
      return cache
    }
    let cache = InlineContentCache()
    inlineContentCaches[key] = cache
    return cache
  }

  func ensureBlockFormattingStateWrapper(formattingContextRoot: ElementBoxWrapper)
    -> BlockFormattingState
  {
    return BlockFormattingState(
      p: wk_interop.LayoutState_ensureBlockFormattingState(p, formattingContextRoot.p))
  }

  func ensureBlockFormattingState(formattingContextRoot: ElementBoxWrapper) -> BlockFormattingState
  {
    assert(formattingContextRoot.establishesBlockFormattingContext())
    let key = CPtrToInt(formattingContextRoot.p)
    if let state = blockFormattingStates[key] {
      return state
    }
    let state = BlockFormattingState(
      layoutState: self, blockFormattingContextRoot: formattingContextRoot)
    blockFormattingStates[key] = state
    return state
  }

  func formattingStateForFormattingContext(formattingContextRoot: ElementBoxWrapper)
    -> FormattingState
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFormattingState(formattingContextRoot: ElementBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func geometryForBox(layoutBox: BoxWrapper) -> BoxGeometry {
    if p == nil || layoutBox.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let boxGeometry = BoxGeometry()
    boxGeometry.p = wk_interop.LayoutState_geometryForBox(p, layoutBox.p)
    return boxGeometry
  }

  func ensureGeometryForBox(layoutBox: BoxWrapper) -> BoxGeometry {
    assert((p == nil) == (layoutBox.p == nil))
    if !isNativeImpl() {
      let boxGeometry = BoxGeometry()
      boxGeometry.p = wk_interop.LayoutState_ensureGeometryForBox(p, layoutBox.p)
      return boxGeometry
    }
    if m_type == .Primary, let boxGeometry = layoutBox.m_cachedGeometryForPrimaryLayoutState {
      #if ASSERT_ENABLED
        assert(layoutBox.m_primaryLayoutState === self)
      #endif
      return boxGeometry
    }
    return ensureGeometryForBoxSlow(layoutBox)
  }

  func hasBoxGeometry(layoutBox: BoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private enum QuirksMode {
    case No
    case Limited
    case Yes
  }

  func inQuirksMode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inStandardsMode() -> Bool {
    if self.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.LayoutState_inStandardsMode(self.p)
  }

  func securityOrigin() -> SecurityOriginWrapper {
    if self.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return SecurityOriginWrapper(p: wk_interop.LayoutState_securityOrigin(self.p))
  }

  func root() -> ElementBoxWrapper {
    assert(self.p == nil)
    return m_rootContainer!
  }

  func layoutWithFormattingContextForBox(box: ElementBoxWrapper, widthConstraint: LayoutUnit?) {
    // TODO(asuhan): call by pointer
    LayoutIntegration.layoutWithFormattingContextForBox(
      box: box, widthConstraint: widthConstraint, layoutState: self)
  }

  private func setQuirksMode(_ quirksMode: QuirksMode) { m_quirksMode = quirksMode }
  private func ensureGeometryForBoxSlow(_ layoutBox: BoxWrapper) -> BoxGeometry {
    assert(isNativeImpl())
    if m_type == .Primary {
      #if ASSERT_ENABLED
        assert(layoutBox.m_cachedGeometryForPrimaryLayoutState == nil)
        assert(layoutBox.m_primaryLayoutState == nil)
        layoutBox.m_primaryLayoutState = self
      #endif
      layoutBox.m_cachedGeometryForPrimaryLayoutState = BoxGeometry()
      return layoutBox.m_cachedGeometryForPrimaryLayoutState!
    }

    if let boxGeometry = m_layoutBoxToBoxGeometry[ObjectIdentifier(layoutBox)] {
      return boxGeometry
    }
    let boxGeometry = BoxGeometry()
    m_layoutBoxToBoxGeometry.updateValue(boxGeometry, forKey: ObjectIdentifier(layoutBox))
    return boxGeometry
  }

  private func isNativeImpl() -> Bool { return p == nil }

  private let m_type: `Type`

  private var inlineContentCaches: [UInt: InlineContentCache] = [:]

  private var blockFormattingStates: [UInt: BlockFormattingState] = [:]
  var p: UnsafeMutableRawPointer?
  var interopOwner = false

  private var m_layoutBoxToBoxGeometry: [ObjectIdentifier: BoxGeometry] = [:]
  private var m_quirksMode: QuirksMode = .No

  // TODO(asuhan): make these fields non-optional
  private let m_rootContainer: ElementBoxWrapper?
  private let m_securityOrigin: SecurityOriginWrapper?

  private let m_formattingContextLayoutFunction: FormattingContextLayoutFunction?
  private let m_formattingContextLogicalWidthFunction: FormattingContextLogicalWidthFunction?
}
