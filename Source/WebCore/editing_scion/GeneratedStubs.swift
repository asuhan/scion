import wk_interop

enum PartialOrdering {
  case less, equivalent, greater, unordered
}

func is_eq(_ ordering: PartialOrdering) -> Bool { return ordering == .equivalent }
func is_neq(_ ordering: PartialOrdering) -> Bool { return ordering != .equivalent }
func is_lt(_ ordering: PartialOrdering) -> Bool { return ordering == .less }
func is_gt(_ ordering: PartialOrdering) -> Bool { return ordering == .greater }
func is_lteq(_ ordering: PartialOrdering) -> Bool {
  return ordering == .less || ordering == .equivalent
}
func is_gteq(_ ordering: PartialOrdering) -> Bool {
  return ordering == .greater || ordering == .equivalent
}

// dom/BoundaryPoint.h

func makeBoundaryPointAfterNodeContents(_ arg0: NodeWrapper) -> BoundaryPoint {
  fatalError("Not implemented")
}

func makeBoundaryPointBeforeNodeContents(_ arg0: NodeWrapper) -> BoundaryPoint {
  fatalError("Not implemented")
}

// dom/ComposedTreeIterator.h

func firstChildInComposedTreeIgnoringUserAgentShadow(_ node: NodeWrapper) -> NodeWrapper? {
  guard
    let raw = wk_interop.ComposedTreeIterator_firstChildInComposedTreeIgnoringUserAgentShadow(
      node.p)
  else { return nil }
  return createNodeWrapper(raw)
}

func nextInComposedTreeIgnoringUserAgentShadow(_ node: NodeWrapper) -> NodeWrapper? {
  guard let raw = wk_interop.ComposedTreeIterator_nextInComposedTreeIgnoringUserAgentShadow(node.p)
  else { return nil }
  return createNodeWrapper(raw)
}

func nextSiblingInComposedTreeIgnoringUserAgentShadow(_ node: NodeWrapper) -> NodeWrapper? {
  guard
    let raw = wk_interop.ComposedTreeIterator_nextSiblingInComposedTreeIgnoringUserAgentShadow(
      node.p)
  else { return nil }
  return createNodeWrapper(raw)
}

// dom/ImageOverlay.h

func hasOverlay(_ arg0: HTMLElementWrapper) -> Bool {
  return wk_interop.ImageOverlay_hasOverlay(arg0.p)
}

// dom/Node.h

func connectedInSameTreeScope(_ arg0: NodeWrapper?, _ arg1: NodeWrapper?) -> Bool {
  return wk_interop.Node_connectedInSameTreeScope(arg0?.p, arg1?.p)
}

// dom/NodeTraversal.h

func next(_ arg0: NodeWrapper) -> NodeWrapper? {
  guard let raw = wk_interop.NodeTraversal_next(arg0.p) else { return nil }
  return createNodeWrapper(raw)
}

func next(_ arg0: NodeWrapper, _ stayWithin: NodeWrapper?) -> NodeWrapper? {
  guard let raw = wk_interop.NodeTraversal_next_2(arg0.p, stayWithin?.p) else { return nil }
  return createNodeWrapper(raw)
}

func nextSkippingChildren(_ arg0: NodeWrapper) -> NodeWrapper? {
  guard let raw = wk_interop.NodeTraversal_nextSkippingChildren(arg0.p) else { return nil }
  return createNodeWrapper(raw)
}

func nextSkippingChildren(_ arg0: NodeWrapper, _ stayWithin: NodeWrapper?) -> NodeWrapper? {
  guard let raw = wk_interop.NodeTraversal_nextSkippingChildren_2(arg0.p, stayWithin?.p) else {
    return nil
  }
  return createNodeWrapper(raw)
}

func previousPostOrder(_ arg0: NodeWrapper, _ stayWithin: NodeWrapper? = nil) -> NodeWrapper? {
  guard let raw = wk_interop.NodeTraversal_previousPostOrder(arg0.p, stayWithin?.p) else {
    return nil
  }
  return createNodeWrapper(raw)
}

// editing/HTMLInterchange.h

let AppleTabSpanClass: ASCIILiteral = ASCIILiteral("Apple-tab-span")

// layout/integration/inline/InlineIteratorLineBox.h

func closestBoxForHorizontalPosition(
  _ arg0: InlineIterator.LineBox, _ horizontalPosition: Float32, _ editableOnly: Bool = false
) -> InlineIterator.LeafBoxIterator {
  fatalError("Not implemented")
}

func contentStartInBlockDirection(_ arg0: InlineIterator.LineBox) -> Float32 {
  fatalError("Not implemented")
}

// platform/text/TextBoundaries.h

func endOfFirstWordBoundaryContext(_ arg0: StringWrapperView) -> UInt32 {
  fatalError("Not implemented")
}

func findEndWordBoundary(_ arg0: StringWrapperView, _ position: Int32, _ end: inout Int32?) {
  fatalError("Not implemented")
}

func findNextWordFromIndex(_ arg0: StringWrapperView, _ position: Int32, _ forward: Bool) -> Int32 {
  fatalError("Not implemented")
}

func findWordBoundary(
  _ arg0: StringWrapperView, _ position: Int32, _ start: inout Int32?, _ end: inout Int32?
) {
  fatalError("Not implemented")
}

func requiresContextForWordBoundary(_ character: UInt32) -> Bool {
  fatalError("Not implemented")
}

func startOfLastWordBoundaryContext(_ arg0: StringWrapperView) -> UInt32 {
  fatalError("Not implemented")
}

// unicode/ubrk.h

func ubrk_first(_ bi: UnsafeMutableRawPointer?) -> Int32 {
  fatalError("Not implemented")
}

func ubrk_following(_ bi: UnsafeMutableRawPointer?, _ offset: Int32) -> Int32 {
  fatalError("Not implemented")
}

func ubrk_isBoundary(_ bi: UnsafeMutableRawPointer?, _ offset: Int32) -> Bool {
  fatalError("Not implemented")
}

func ubrk_next(_ bi: UnsafeMutableRawPointer?) -> Int32 {
  fatalError("Not implemented")
}

func ubrk_preceding(_ bi: UnsafeMutableRawPointer?, _ offset: Int32) -> Int32 {
  fatalError("Not implemented")
}

// unicode/unorm2.h

func unorm2_getNFCInstance(_ pErrorCode: UErrorCode?) -> UnsafeMutableRawPointer? {
  fatalError("Not implemented")
}

// unicode/usearch.h

func usearch_open(
  _ pattern: UInt16?, _ patternlength: Int32, _ text: UInt16?, _ textlength: Int32,
  _ locale: CChar?, _ breakiter: UnsafeMutableRawPointer?, _ status: UErrorCode?
) -> UnsafeMutableRawPointer? {
  fatalError("Not implemented")
}

// unicode/utypes.h

func U_SUCCESS(_ code: UErrorCode) -> Bool {
  fatalError("Not implemented")
}

// wtf/text/StringCommon.h

func isLatin1(_ arg0: UInt32) -> Bool {
  fatalError("Not implemented")
}

// wtf/text/StringImpl.h

func deprecatedIsSpaceOrNewline(_ arg0: UInt16) -> Bool {
  fatalError("Not implemented")
}

// wtf/text/TextBreakIterator.h

func isWordTextBreak(_ arg0: UnsafeMutableRawPointer?) -> Bool {
  fatalError("Not implemented")
}

func sentenceBreakIterator(_ arg0: StringWrapperView) -> UnsafeMutableRawPointer? {
  fatalError("Not implemented")
}

// wtf/text/TextBreakIteratorInternalICU.h

func currentSearchLocaleID() -> CChar? {
  fatalError("Not implemented")
}

// wtf/unicode/CharacterNames.h

let doubleHighReversed9QuotationMark: UInt16 = 8223

let doubleLowReversed9QuotationMark: UInt16 = 11842

let doublePrimeQuotationMark: UInt16 = 12318

let fullwidthApostrophe: UInt16 = 65287

let fullwidthQuotationMark: UInt16 = 65282

let halfwidthLeftCornerBracket: UInt16 = 65378

let halfwidthRightCornerBracket: UInt16 = 65379

let hebrewPunctuationGeresh: UInt16 = 1523

let hebrewPunctuationGershayim: UInt16 = 1524

let leftCornerBracket: UInt16 = 12300

let leftDoubleQuotationMark: UInt16 = 8220

let leftLowDoubleQuotationMark: UInt16 = 8222

let leftLowSingleQuotationMark: UInt16 = 8218

let leftPointingDoubleAngleQuotationMark: UInt16 = 171

let leftSingleQuotationMark: UInt16 = 8216

let leftWhiteCornerBracket: UInt16 = 12302

let lowDoublePrimeQuotationMark: UInt16 = 12319

let newlineCharacter: UInt16 = 10

let noBreakSpace: UInt16 = 160

let objectReplacementCharacter: UInt16 = 65532

let presentationFormForVerticalLeftCornerBracket: UInt16 = 65089

let presentationFormForVerticalLeftWhiteCornerBracket: UInt16 = 65091

let presentationFormForVerticalRightCornerBracket: UInt16 = 65090

let presentationFormForVerticalRightWhiteCornerBracket: UInt16 = 65092

let reversedDoublePrimeQuotationMark: UInt16 = 12317

let rightCornerBracket: UInt16 = 12301

let rightDoubleQuotationMark: UInt16 = 8221

let rightPointingDoubleAngleQuotationMark: UInt16 = 187

let rightSingleQuotationMark: UInt16 = 8217

let rightWhiteCornerBracket: UInt16 = 12303

let singleLeftPointingAngleQuotationMark: UInt16 = 8249

let singleLow9QuotationMark: UInt16 = 8219

let singleRightPointingAngleQuotationMark: UInt16 = 8250
