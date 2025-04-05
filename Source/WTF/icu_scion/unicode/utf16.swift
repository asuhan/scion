/// © 2016 and later: Unicode, Inc. and others.
/// License & terms of use: http://www.unicode.org/copyright.html
/*
*******************************************************************************
*
*   Copyright (C) 1999-2012, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
*******************************************************************************
*   file name:  utf16.h
*   encoding:   UTF-8
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 1999sep09
*   created by: Markus W. Scherer
*/

import wk_interop

func U16_NEXT(s: CharSpanWrapper<UChar>, i: inout UInt64, length: UInt32) -> UInt32 {
  let raw = wk_interop.U16_NEXT_scion(s.p, i, length)
  i = raw.position
  return raw.character
}

internal func U16_FWD_1(s: StringWrapper, i: inout UInt32, length: UInt32) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func U16_SET_CP_START(s: StringWrapper, start: UInt32, i: UInt32) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
