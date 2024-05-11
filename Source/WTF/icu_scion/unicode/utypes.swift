/// © 2016 and later: Unicode, Inc. and others.
/// License & terms of use: http://www.unicode.org/copyright.html
/*
**********************************************************************
*   Copyright (C) 1996-2016, International Business Machines
*   Corporation and others.  All Rights Reserved.
**********************************************************************
*
*  FILE NAME : UTYPES.H (formerly ptypes.h)
*
*   Date        Name        Description
*   12/11/96    helena      Creation.
*   02/27/97    aliu        Added typedefs for UClassID, int8, int16, int32,
*                           uint8, uint16, and uint32.
*   04/01/97    aliu        Added XP_CPLUSPLUS and modified to work under C as
*                            well as C++.
*                           Modified to use memcpy() for uprv_arrayCopy() fns.
*   04/14/97    aliu        Added TPlatformUtilities.
*   05/07/97    aliu        Added import/export specifiers (replacing the old
*                           broken EXT_CLASS).  Added version number for our
*                           code.  Cleaned up header.
*    6/20/97    helena      Java class name change.
*   08/11/98    stephen     UErrorCode changed from typedef to enum
*   08/12/98    erm         Changed T_ANALYTIC_PACKAGE_VERSION to 3
*   08/14/98    stephen     Added uprv_arrayCopy() for int8_t, int16_t, int32_t
*   12/09/98    jfitz       Added BUFFER_OVERFLOW_ERROR (bug 1100066)
*   04/20/99    stephen     Cleaned up & reworked for autoconf.
*                           Renamed to utypes.h.
*   05/05/99    stephen     Changed to use <inttypes.h>
*   12/07/99    helena      Moved copyright notice string from ucnv_bld.h here.
*******************************************************************************
*/

enum UErrorCode: Int32 {
  case U_ZERO_ERROR = 0
}

internal func U_FAILURE(errorCode: UErrorCode) -> Bool {
  return errorCode.rawValue > UErrorCode.U_ZERO_ERROR.rawValue
}
