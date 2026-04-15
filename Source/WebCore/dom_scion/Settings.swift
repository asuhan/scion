/*
 * Copyright (C) 2017-2020 Apple Inc. All rights reserved.
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

class SettingsWrapper {
  init(_ p: UnsafeRawPointer) { self.p = p }

  func acceleratedCompositingEnabled() -> Bool {
    return wk_interop.Settings_acceleratedCompositingEnabled(p)
  }

  func acceleratedCompositingForFixedPositionEnabled() -> Bool {
    return wk_interop.Settings_acceleratedCompositingForFixedPositionEnabled(p)
  }

  func acceleratedDrawingEnabled() -> Bool {
    return wk_interop.Settings_acceleratedDrawingEnabled(p)
  }

  func alignContentOnBlocksEnabled() -> Bool {
    return wk_interop.Settings_alignContentOnBlocksEnabled(p)
  }

  func animatedImageAsyncDecodingEnabled() -> Bool {
    return wk_interop.Settings_animatedImageAsyncDecodingEnabled(p)
  }

  func asyncOverflowScrollingEnabled() -> Bool {
    return wk_interop.Settings_asyncOverflowScrollingEnabled(p)
  }

  func backgroundShouldExtendBeyondPage() -> Bool {
    return wk_interop.Settings_backgroundShouldExtendBeyondPage(p)
  }

  func caretBrowsingEnabled() -> Bool { return wk_interop.Settings_caretBrowsingEnabled(p) }

  func clientCoordinatesRelativeToLayoutViewport() -> Bool {
    return wk_interop.Settings_clientCoordinatesRelativeToLayoutViewport(p)
  }

  func css3DTransformBackfaceVisibilityInteroperabilityEnabled() -> Bool {
    return wk_interop.Settings_css3DTransformBackfaceVisibilityInteroperabilityEnabled(p)
  }

  func cssScrollAnchoringEnabled() -> Bool {
    return wk_interop.Settings_cssScrollAnchoringEnabled(p)
  }

  func cssUnprefixedBackdropFilterEnabled() -> Bool {
    return wk_interop.Settings_cssUnprefixedBackdropFilterEnabled(p)
  }

  func fixedBackgroundsPaintRelativeToDocument() -> Bool {
    return wk_interop.Settings_fixedBackgroundsPaintRelativeToDocument(p)
  }

  func forceCompositingMode() -> Bool { return wk_interop.Settings_forceCompositingMode(p) }

  func grammarAndSpellingPseudoElementsEnabled() -> Bool {
    return wk_interop.Settings_grammarAndSpellingPseudoElementsEnabled(p)
  }

  func highlightAPIEnabled() -> Bool { return wk_interop.Settings_highlightAPIEnabled(p) }

  func imageSubsamplingEnabled() -> Bool { return wk_interop.Settings_imageSubsamplingEnabled(p) }

  func incompleteImageBorderEnabled() -> Bool {
    return wk_interop.Settings_incompleteImageBorderEnabled(p)
  }

  func largeImageAsyncDecodingEnabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layerBasedSVGEngineEnabled() -> Bool {
    return wk_interop.Settings_layerBasedSVGEngineEnabled(p)
  }

  func overlappingBackingStoreProvidersEnabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollToTextFragmentEnabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollingPerformanceTestingEnabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldAllowUserInstalledFonts() -> Bool {
    return wk_interop.Settings_shouldAllowUserInstalledFonts(p)
  }

  func shouldPrintBackgrounds() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func showDebugBorders() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func showRepaintCounter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func systemLayoutDirection() -> TextDirection {
    return wk_interop.Settings_systemLayoutDirection(p) ? .RTL : .LTR
  }

  func userInterfaceDirectionPolicy() -> UserInterfaceDirectionPolicy {
    return wk_interop.Settings_userInterfaceDirectionPolicy(p) ? .System : .Content
  }

  func visualViewportEnabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let p: UnsafeRawPointer
}
