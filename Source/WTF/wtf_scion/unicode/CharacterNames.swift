/*
 * Copyright (C) 2007-2023 Apple Inc. All rights reserved.
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

struct CharacterNames {
  struct Unicode {
    static let enDash: UChar = 0x2013
    static let firstStrongIsolate: UChar = 0x2068
    static let hyphen: UChar = 0x2010
    static let leftToRightEmbed: UChar = 0x202A
    static let leftToRightIsolate: UChar = 0x2066
    static let leftToRightOverride: UChar = 0x202D
    static let newlineCharacter: UChar = 0x000A
    static let noBreakSpace: UChar = 0x00A0
    static let objectReplacementCharacter: UChar = 0xFFFC
    static let popDirectionalFormatting: UChar = 0x202C
    static let popDirectionalIsolate: UChar = 0x2069
    static let reverseSolidus: UChar = 0x005C
    static let rightToLeftEmbed: UChar = 0x202B
    static let rightToLeftIsolate: UChar = 0x2067
    static let rightToLeftOverride: UChar = 0x202E
    static let softHyphen: UChar = 0x00AD
    static let space: UChar = 0x0020
    static let tabCharacter: UChar = 0x0009
    static let zeroWidthSpace: UChar = 0x200B
  }
}
