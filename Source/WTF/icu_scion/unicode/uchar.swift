/// © 2016 and later: Unicode, Inc. and others.
/// License & terms of use: http://www.unicode.org/copyright.html
/*
**********************************************************************
*   Copyright (C) 1997-2016, International Business Machines
*   Corporation and others.  All Rights Reserved.
**********************************************************************
*
* File UCHAR.H
*
* Modification History:
*
*   Date        Name        Description
*   04/02/97    aliu        Creation.
*   03/29/99    helena      Updated for C APIs.
*   4/15/99     Madhu       Updated for C Implementation and Javadoc
*   5/20/99     Madhu       Added the function u_getVersion()
*   8/19/1999   srl         Upgraded scripts to Unicode 3.0
*   8/27/1999   schererm    UCharDirection constants: U_...
*   11/11/1999  weiv        added u_isalnum(), cleaned comments
*   01/11/2000  helena      Renamed u_getVersion to u_getUnicodeVersion().
******************************************************************************
*/

/// Data for enumerated Unicode general category types.
/// See http://www.unicode.org/Public/UNIDATA/UnicodeData.html .
/// @stable ICU 2.0
struct UCharCategory {
  /** Ps @stable ICU 2.0 */
  static let U_START_PUNCTUATION: UInt32 = 20
  /** Pe @stable ICU 2.0 */
  static let U_END_PUNCTUATION: UInt32 = 21
  /** Po @stable ICU 2.0 */
  static let U_OTHER_PUNCTUATION: UInt32 = 23
  /** Pi @stable ICU 2.0 */
  static let U_INITIAL_PUNCTUATION: UInt32 = 28
  /** Pf @stable ICU 2.0 */
  static let U_FINAL_PUNCTUATION: UInt32 = 29
}

struct UCharMasks {
  /** Mask constant for a UCharCategory. @stable ICU 2.1 */
  static func U_MASK(x: UInt32) -> UInt32 {
    return 1 << x
  }

  static let U_GC_PS_MASK = U_MASK(x: UCharCategory.U_START_PUNCTUATION)
  static let U_GC_PE_MASK = U_MASK(x: UCharCategory.U_END_PUNCTUATION)
  static let U_GC_PI_MASK = U_MASK(x: UCharCategory.U_INITIAL_PUNCTUATION)
  static let U_GC_PF_MASK = U_MASK(x: UCharCategory.U_FINAL_PUNCTUATION)
  static let U_GC_PO_MASK = U_MASK(x: UCharCategory.U_OTHER_PUNCTUATION)

  static func U_GET_GC_MASK(c: UInt32) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

/// Line Break constants.
///
/// @see UCHAR_LINE_BREAK
/// @stable ICU 2.2
enum ULineBreak: UInt32 {
  case U_LB_CLOSE_PUNCTUATION = 8 /*[CL]*/
  case U_LB_EXCLAMATION = 11 /*[EX]*/
  case U_LB_NONSTARTER = 18 /*[NS]*/
  case U_LB_BREAK_SYMBOLS = 27 /*[SY]*/
  case U_LB_CLOSE_PARENTHESIS = 36 /*[CP]*/
  /* new in Unicode 5.2/ICU 4.4 */
  case U_LB_INFIX_NUMERIC = 16 /*[IS]*/
  case U_LB_ZWSPACE = 28 /*[ZW]*/
  case U_LB_WORD_JOINER = 30 /*[WJ]*/
}

enum UProperty: UInt32 {
  /** Enumerated property Line_Break.
        Returns ULineBreak values. @stable ICU 2.2 */
  case UCHAR_LINE_BREAK = 0x1008
}
