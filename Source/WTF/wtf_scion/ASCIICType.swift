/*
 * Copyright (C) 2007-2021 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

func isASCIILower(character: UChar) -> Bool {
  return character >= Character("a").asciiValue! && character <= Character("z").asciiValue!
}

func toASCIILowerUnchecked(character: UChar) -> UChar {
  // This function can be used for comparing any input character
  // to a lowercase English character. The isASCIIAlphaCaselessEqual
  // below should be used for regular comparison of ASCII alpha
  // characters, but switch statements in CSS tokenizer instead make
  // direct use of this function.
  return character | 0x20
}

func isASCIIAlpha(character: UChar) -> Bool {
  return isASCIILower(character: toASCIILowerUnchecked(character: character))
}

func isASCIIDigit(character: UChar) -> Bool {
  return character >= Character("0").asciiValue! && character <= Character("9").asciiValue!
}

func isASCIIAlphanumeric(character: UChar) -> Bool {
  return isASCIIDigit(character: character) || isASCIIAlpha(character: character)
}
