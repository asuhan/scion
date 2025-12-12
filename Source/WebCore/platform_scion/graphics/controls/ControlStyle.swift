/*
 * Copyright (C) 2022-2023 Apple Inc. All Rights Reserved.
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

struct ControlStyle {
  struct State: OptionSet {
    let rawValue: UInt32

    static let Hovered = State(rawValue: 1 << 0)
    static let Pressed = State(rawValue: 1 << 1)
    static let Focused = State(rawValue: 1 << 2)
    static let Enabled = State(rawValue: 1 << 3)
    static let Checked = State(rawValue: 1 << 4)
    static let Default = State(rawValue: 1 << 5)
    static let WindowActive = State(rawValue: 1 << 6)
    static let Indeterminate = State(rawValue: 1 << 7)
    static let SpinUp = State(rawValue: 1 << 8)  // Sub-state for HoverState and PressedState.
    static let Presenting = State(rawValue: 1 << 9)
    static let FormSemanticContext = State(rawValue: 1 << 10)
    static let DarkAppearance = State(rawValue: 1 << 11)
    static let RightToLeft = State(rawValue: 1 << 12)
    static let LargeControls = State(rawValue: 1 << 13)
    static let ReadOnly = State(rawValue: 1 << 14)
    static let ListButton = State(rawValue: 1 << 15)
    static let ListButtonPressed = State(rawValue: 1 << 16)
    static let VerticalWritingMode = State(rawValue: 1 << 17)
  }
}
