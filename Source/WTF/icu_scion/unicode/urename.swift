/// © 2016 and later: Unicode, Inc. and others.
/// License & terms of use: http://www.unicode.org/copyright.html
/*
*******************************************************************************
*   Copyright (C) 2002-2016, International Business Machines
*   Corporation and others.  All Rights Reserved.
*******************************************************************************
*
*   file name:  urename.h
*   encoding:   UTF-8
*   tab size:   8 (not used)
*   indentation:4
*
*   Created by: Perl script tools/genren.pl written by Vladimir Weinstein
*
*  Contains data for renaming ICU exports.
*  Gets included by umachine.h
*
*  THIS FILE IS MACHINE-GENERATED, DON'T PLAY WITH IT IF YOU DON'T KNOW WHAT
*  YOU ARE DOING, OTHERWISE VERY BAD THINGS WILL HAPPEN!
*/

func u_getIntPropertyValue(character: UChar, property: UProperty) -> UInt32 {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func ubidi_close(ubidi: UBiDiWrapper) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func ubidi_getLogicalRun(
  pBiDi: UBiDiWrapper, logicalPosition: Int32, pLogicalLimit: inout Int32, pLevel: UBiDiLevel
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func ubidi_open() -> UBiDiWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func ubidi_reorderVisual(runLevels: [UBiDiLevel], visualOrderList: [Int32]) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func ubidi_setPara(
  pBiDi: UBiDiWrapper, text: StringWrapperView.UpconvertedCharactersWithSize, length: UInt32,
  paraLevel: UBiDiLevel, embeddingLevels: [UBiDiLevel]
) -> UErrorCode {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
