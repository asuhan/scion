/*
 * Copyright (C) 2008, 2009, 2013, 2015 Apple Inc. All Rights Reserved.
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

private func pseudoForScrollbarPart(_ part: ScrollbarPart) -> PseudoId {
  switch part {
  case .BackButtonStartPart, .ForwardButtonStartPart, .BackButtonEndPart, .ForwardButtonEndPart:
    return .WebKitScrollbarButton
  case .BackTrackPart, .ForwardTrackPart:
    return .WebKitScrollbarTrackPiece
  case .ThumbPart:
    return .WebKitScrollbarThumb
  case .TrackBGPart:
    return .WebKitScrollbarTrack
  case .ScrollbarBGPart:
    return .WebKitScrollbar
  default:
    fatalError("Not reached")
  }
}

final class RenderScrollbar: Scrollbar {
  private func owningRenderer() -> RenderBoxWrapper? {
    if owningFrame != nil {
      let currentRenderer = owningFrame!.ownerRenderer()
      return currentRenderer
    }
    assert(ownerElement != nil)
    if ownerElement!.renderer() != nil {
      return ownerElement!.renderer()!.enclosingBox()
    }
    return nil
  }

  private func getScrollbarPseudoStyle(_ partType: ScrollbarPart, _ pseudoId: PseudoId)
    -> RenderStyleWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleChanged() {
    updateScrollbarParts()
  }

  private func updateScrollbarParts() {
    updateScrollbarPart(.ScrollbarBGPart)
    updateScrollbarPart(.BackButtonStartPart)
    updateScrollbarPart(.ForwardButtonStartPart)
    updateScrollbarPart(.BackTrackPart)
    updateScrollbarPart(.ThumbPart)
    updateScrollbarPart(.ForwardTrackPart)
    updateScrollbarPart(.BackButtonEndPart)
    updateScrollbarPart(.ForwardButtonEndPart)
    updateScrollbarPart(.TrackBGPart)

    // See if the scrollbar's thickness changed.  If so, we need to mark our owning object as needing a layout.
    let isHorizontal = orientation() == .Horizontal
    let oldThickness = isHorizontal ? height() : width()
    var newThickness: Int32 = 0
    if let part = parts[UInt32(ScrollbarPart.ScrollbarBGPart.rawValue)] {
      part.layout()
      newThickness = (isHorizontal ? part.height() : part.width()).int()
    }

    if newThickness != oldThickness {
      setFrameRect(
        IntRect(
          location: location(),
          size: IntSize(
            width: isHorizontal ? width() : newThickness,
            height: isHorizontal ? newThickness : height())))
      if let box = owningRenderer() {
        box.setChildNeedsLayout()
      }
    }
  }

  private func updateScrollbarPart(_ partType: ScrollbarPart) {
    if partType == .NoPart {
      return
    }

    let partStyle = getScrollbarPseudoStyle(partType, pseudoForScrollbarPart(partType))
    var needRenderer = partStyle != nil && partStyle!.display() != .None

    if needRenderer && partStyle!.display() != .Block {
      // See if we are a button that should not be visible according to OS settings.
      let buttonsPlacement = theme().buttonsPlacement()
      switch partType {
      case .BackButtonStartPart:
        needRenderer =
          (buttonsPlacement == .ScrollbarButtonsSingle
            || buttonsPlacement == .ScrollbarButtonsDoubleStart
            || buttonsPlacement == .ScrollbarButtonsDoubleBoth)
      case .ForwardButtonStartPart:
        needRenderer =
          (buttonsPlacement == .ScrollbarButtonsDoubleStart
            || buttonsPlacement == .ScrollbarButtonsDoubleBoth)
      case .BackButtonEndPart:
        needRenderer =
          (buttonsPlacement == .ScrollbarButtonsDoubleEnd
            || buttonsPlacement == .ScrollbarButtonsDoubleBoth)
      case .ForwardButtonEndPart:
        needRenderer =
          (buttonsPlacement == .ScrollbarButtonsSingle
            || buttonsPlacement == .ScrollbarButtonsDoubleEnd
            || buttonsPlacement == .ScrollbarButtonsDoubleBoth)
      default:
        break
      }
    }

    if !needRenderer {
      parts.removeValue(forKey: UInt32(partType.rawValue))
      return
    }

    if let partRendererSlot = parts[UInt32(partType.rawValue)] {
      partRendererSlot.setStyle(style: partStyle!)
    } else {
      let partRendererSlot = CreateRenderer.RenderScrollbarPart(
        owningRenderer()!.document(), partStyle!, self, partType)
      partRendererSlot.initializeStyle()
      parts[UInt32(partType.rawValue)] = partRendererSlot
    }
  }

  // This Scrollbar(Widget) may outlive the DOM which created it (during tear down),
  // so we keep a reference to the Element which caused this custom scrollbar creation.
  // This will not create a reference cycle as the Widget tree is owned by our containing
  // FrameView which this Element pointer can in no way keep alive. See webkit bug 80610.
  private let ownerElement: ElementWrapper? = nil

  private let owningFrame: LocalFrameWrapper? = nil
  private var parts: [UInt32: RenderScrollbarPartWrapper] = [:]
}
