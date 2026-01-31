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

import wk_interop

struct UCharCategory {
  /** Mn @stable ICU 2.0 */
  static let U_NON_SPACING_MARK: UInt32 = 6
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

  static let U_GC_MN_MASK = U_MASK(x: UCharCategory.U_NON_SPACING_MARK)
  static let U_GC_PS_MASK = U_MASK(x: UCharCategory.U_START_PUNCTUATION)
  static let U_GC_PE_MASK = U_MASK(x: UCharCategory.U_END_PUNCTUATION)
  static let U_GC_PI_MASK = U_MASK(x: UCharCategory.U_INITIAL_PUNCTUATION)
  static let U_GC_PF_MASK = U_MASK(x: UCharCategory.U_FINAL_PUNCTUATION)
  static let U_GC_PO_MASK = U_MASK(x: UCharCategory.U_OTHER_PUNCTUATION)

  static func U_GET_GC_MASK(c: Int32) -> UInt32 {
    return U_MASK(x: UInt32(wk_interop.u_charType_scion(c)))
  }
}

/// This specifies the language directional property of a character set.
/// @stable ICU 2.0
enum UCharDirection: UInt8 {
  /** L @stable ICU 2.0 */
  case U_LEFT_TO_RIGHT = 0
  /** R @stable ICU 2.0 */
  case U_RIGHT_TO_LEFT = 1
  /** EN @stable ICU 2.0 */
  case U_EUROPEAN_NUMBER = 2
  /** ES @stable ICU 2.0 */
  case U_EUROPEAN_NUMBER_SEPARATOR = 3
  /** ET @stable ICU 2.0 */
  case U_EUROPEAN_NUMBER_TERMINATOR = 4
  /** AN @stable ICU 2.0 */
  case U_ARABIC_NUMBER = 5
  /** CS @stable ICU 2.0 */
  case U_COMMON_NUMBER_SEPARATOR = 6
  /** B @stable ICU 2.0 */
  case U_BLOCK_SEPARATOR = 7
  /** S @stable ICU 2.0 */
  case U_SEGMENT_SEPARATOR = 8
  /** WS @stable ICU 2.0 */
  case U_WHITE_SPACE_NEUTRAL = 9
  /** ON @stable ICU 2.0 */
  case U_OTHER_NEUTRAL = 10
  /** LRE @stable ICU 2.0 */
  case U_LEFT_TO_RIGHT_EMBEDDING = 11
  /** LRO @stable ICU 2.0 */
  case U_LEFT_TO_RIGHT_OVERRIDE = 12
  /** AL @stable ICU 2.0 */
  case U_RIGHT_TO_LEFT_ARABIC = 13
  /** RLE @stable ICU 2.0 */
  case U_RIGHT_TO_LEFT_EMBEDDING = 14
  /** RLO @stable ICU 2.0 */
  case U_RIGHT_TO_LEFT_OVERRIDE = 15
  /** PDF @stable ICU 2.0 */
  case U_POP_DIRECTIONAL_FORMAT = 16
  /** NSM @stable ICU 2.0 */
  case U_DIR_NON_SPACING_MARK = 17
  /** BN @stable ICU 2.0 */
  case U_BOUNDARY_NEUTRAL = 18
  /** FSI @stable ICU 52 */
  case U_FIRST_STRONG_ISOLATE = 19
  /** LRI @stable ICU 52 */
  case U_LEFT_TO_RIGHT_ISOLATE = 20
  /** RLI @stable ICU 52 */
  case U_RIGHT_TO_LEFT_ISOLATE = 21
  /** PDI @stable ICU 52 */
  case U_POP_DIRECTIONAL_ISOLATE = 22
}

/// East Asian Width constants.
///
/// @see UCHAR_EAST_ASIAN_WIDTH
/// @see u_getIntPropertyValue
/// @stable ICU 2.2
enum UEastAsianWidth: UInt8 {
  /*
     * Note: UEastAsianWidth constants are parsed by preparseucd.py.
     * It matches lines like
     *     U_EA_<Unicode East_Asian_Width value name>
     */

  case U_EA_NEUTRAL /*[N]*/
  case U_EA_AMBIGUOUS /*[A]*/
  case U_EA_HALFWIDTH /*[H]*/
  case U_EA_FULLWIDTH /*[F]*/
  case U_EA_NARROW /*[Na]*/
  case U_EA_WIDE /*[W]*/
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
  /** Binary property Default_Ignorable_Code_Point (new in Unicode 3.2).
      Ignorable in most processing.
      <2060..206F, FFF0..FFFB, E0000..E0FFF>+Other_Default_Ignorable_Code_Point+(Cf+Cc+Cs-White_Space) @stable ICU 2.1 */
  case UCHAR_DEFAULT_IGNORABLE_CODE_POINT = 5
  /** Enumerated property East_Asian_Width.
      See http://www.unicode.org/reports/tr11/
      Returns UEastAsianWidth values. @stable ICU 2.2 */
  case UCHAR_EAST_ASIAN_WIDTH = 0x1004
  /** Enumerated property Line_Break.
      Returns ULineBreak values. @stable ICU 2.2 */
  case UCHAR_LINE_BREAK = 0x1008
}
