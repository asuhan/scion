/// © 2016 and later: Unicode, Inc. and others.
/// License & terms of use: http://www.unicode.org/copyright.html
/*
******************************************************************************
*
*   Copyright (C) 1999-2013, International Business Machines
*   Corporation and others.  All Rights Reserved.
*
******************************************************************************
*   file name:  ubidi.h
*   encoding:   UTF-8
*   tab size:   8 (not used)
*   indentation:4
*
*   created on: 1999jul27
*   created by: Markus W. Scherer, updated by Matitiahu Allouche
*/

// TODO(asuhan): rework to directly use raw values instead of this enum
enum UBiDiLevel: UInt8 {
  case UBIDI_DEFAULT_LTR = 0xfe
  case UBIDI_LTR = 0
  case UBIDI_RTL = 1
  case UBIDI_MIXED = 2
  case UBIDI_NEUTRAL = 3
  case UBIDI_OPTION_STREAMING = 4
  case UBIDI_LEVEL_5 = 5
  case UBIDI_LEVEL_6 = 6
  case OPAQUE = 0xff
  case UBIDI_MAX_EXPLICIT_LEVEL = 125
}

struct UBiDiWrapper {
  init(p: UnsafeMutableRawPointer) {
    self.p = p
  }

  var p: UnsafeMutableRawPointer
}
