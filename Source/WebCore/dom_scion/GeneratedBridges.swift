import wk_interop

extension Document {
  func createEditingTextNode(_ arg0: StringWrapper) -> TextWrapper {
    fatalError("Not implemented")
  }

  func createTextNode(_ arg0: StringWrapper) -> TextWrapper {
    fatalError("Not implemented")
  }

  @discardableResult
  func inDesignMode() -> Bool {
    return wk_interop.Document_inDesignMode(p)
  }

  @discardableResult
  func updateLayoutIgnorePendingStylesheets() -> UpdateLayoutResult {
    return UpdateLayoutResult(
      rawValue: wk_interop.Document_updateLayoutIgnorePendingStylesheets(p))!
  }
}

extension ElementWrapper {
  @discardableResult
  func classAttributeWithoutSynchronization() -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.Element_classAttributeWithoutSynchronization(p)!, true)
  }

  @discardableResult
  func hasEquivalentAttributes(_ arg0: ElementWrapper) -> Bool {
    return wk_interop.Element_hasEquivalentAttributes(p, arg0.p)
  }

  func hasTagName(_ arg0: QualifiedName) -> Bool {
    fatalError("Not implemented")
  }

  @discardableResult
  func localName() -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.Element_localName(p)!, true)
  }

  @discardableResult
  func roleAttributeWithoutSynchronization() -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.Element_roleAttributeWithoutSynchronization(p)!, true)
  }

  func setAttributeWithoutSynchronization(_ arg0: QualifiedName, _ arg1: AtomStringWrapper) {
    fatalError("Not implemented")
  }

  func tagQName() -> QualifiedName {
    fatalError("Not implemented")
  }

  @discardableResult
  func typeAttributeWithoutSynchronization() -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.Element_typeAttributeWithoutSynchronization(p)!, true)
  }
}

extension HTMLImageElementWrapper {
  func cachedImage() -> CachedImageWrapper? {
    fatalError("Not implemented")
  }
}

extension NodeWrapper {
  @discardableResult
  func canContainRangeEndPoint() -> Bool {
    return wk_interop.Node_canContainRangeEndPoint(p)
  }

  @discardableResult
  func computeEditability(_ arg0: UserSelectAllTreatment, _ arg1: ShouldUpdateStyle) -> Editability
  {
    return Editability(
      rawValue: wk_interop.Node_computeEditability(
        p,
        Int32(
          [UserSelectAllTreatment.NotEditable, UserSelectAllTreatment.Editable].firstIndex(
            of: arg0)!), Int32(arg1.rawValue)))!
  }

  @discardableResult
  func contains(_ arg0: NodeWrapper?) -> Bool {
    return wk_interop.Node_contains(p, arg0?.p)
  }

  @discardableResult
  func containsIncludingShadowDOM(_ arg0: NodeWrapper?) -> Bool {
    return wk_interop.Node_containsIncludingShadowDOM(p, arg0?.p)
  }

  @discardableResult
  func firstChild() -> NodeWrapper? {
    guard let raw = wk_interop.Node_firstChild(p) else { return nil }
    return createNodeWrapper(raw)
  }

  @discardableResult
  func hasBlockquoteTagName() -> Bool {
    return wk_interop.Node_hasBlockquoteTagName(p)
  }

  @discardableResult
  func hasBrTagName() -> Bool {
    return wk_interop.Node_hasBrTagName(p)
  }

  @discardableResult
  func hasChildNodes() -> Bool {
    return wk_interop.Node_hasChildNodes(p)
  }

  @discardableResult
  func hasDdTagName() -> Bool {
    return wk_interop.Node_hasDdTagName(p)
  }

  @discardableResult
  func hasDivTagName() -> Bool {
    return wk_interop.Node_hasDivTagName(p)
  }

  @discardableResult
  func hasDlTagName() -> Bool {
    return wk_interop.Node_hasDlTagName(p)
  }

  @discardableResult
  func hasDtTagName() -> Bool {
    return wk_interop.Node_hasDtTagName(p)
  }

  @discardableResult
  func hasH1TagName() -> Bool {
    return wk_interop.Node_hasH1TagName(p)
  }

  @discardableResult
  func hasH2TagName() -> Bool {
    return wk_interop.Node_hasH2TagName(p)
  }

  @discardableResult
  func hasH3TagName() -> Bool {
    return wk_interop.Node_hasH3TagName(p)
  }

  @discardableResult
  func hasH4TagName() -> Bool {
    return wk_interop.Node_hasH4TagName(p)
  }

  @discardableResult
  func hasH5TagName() -> Bool {
    return wk_interop.Node_hasH5TagName(p)
  }

  @discardableResult
  func hasH6TagName() -> Bool {
    return wk_interop.Node_hasH6TagName(p)
  }

  @discardableResult
  func hasHtmlTagName() -> Bool {
    return wk_interop.Node_hasHtmlTagName(p)
  }

  @discardableResult
  func hasLiTagName() -> Bool {
    return wk_interop.Node_hasLiTagName(p)
  }

  @discardableResult
  func hasListingTagName() -> Bool {
    return wk_interop.Node_hasListingTagName(p)
  }

  @discardableResult
  func hasMeterTagName() -> Bool {
    return wk_interop.Node_hasMeterTagName(p)
  }

  @discardableResult
  func hasOlTagName() -> Bool {
    return wk_interop.Node_hasOlTagName(p)
  }

  @discardableResult
  func hasPTagName() -> Bool {
    return wk_interop.Node_hasPTagName(p)
  }

  @discardableResult
  func hasPictureTagName() -> Bool {
    return wk_interop.Node_hasPictureTagName(p)
  }

  @discardableResult
  func hasPreTagName() -> Bool {
    return wk_interop.Node_hasPreTagName(p)
  }

  @discardableResult
  func hasProgressTagName() -> Bool {
    return wk_interop.Node_hasProgressTagName(p)
  }

  @discardableResult
  func hasRichlyEditableStyle() -> Bool {
    return wk_interop.Node_hasRichlyEditableStyle(p)
  }

  @discardableResult
  func hasTdTagName() -> Bool {
    return wk_interop.Node_hasTdTagName(p)
  }

  @discardableResult
  func hasThTagName() -> Bool {
    return wk_interop.Node_hasThTagName(p)
  }

  @discardableResult
  func hasTrTagName() -> Bool {
    return wk_interop.Node_hasTrTagName(p)
  }

  @discardableResult
  func hasUlTagName() -> Bool {
    return wk_interop.Node_hasUlTagName(p)
  }

  @discardableResult
  func hasXmpTagName() -> Bool {
    return wk_interop.Node_hasXmpTagName(p)
  }

  @discardableResult
  func isCharacterDataNode() -> Bool {
    return wk_interop.Node_isCharacterDataNode(p)
  }

  @discardableResult
  func isConnected() -> Bool {
    return wk_interop.Node_isConnected(p)
  }

  @discardableResult
  func isDescendantOrShadowDescendantOf(_ arg0: NodeWrapper?) -> Bool {
    return wk_interop.Node_isDescendantOrShadowDescendantOf(p, arg0?.p)
  }

  @discardableResult
  func isInShadowTree() -> Bool {
    return wk_interop.Node_isInShadowTree(p)
  }

  @discardableResult
  func isShadowRoot() -> Bool {
    return wk_interop.Node_isShadowRoot(p)
  }

  @discardableResult
  func isTextNode() -> Bool {
    return wk_interop.Node_isTextNode(p)
  }

  @discardableResult
  func lastChild() -> NodeWrapper? {
    guard let raw = wk_interop.Node_lastChild(p) else { return nil }
    return createNodeWrapper(raw)
  }

  @discardableResult
  func lastDescendant() -> NodeWrapper? {
    guard let raw = wk_interop.Node_lastDescendant(p) else { return nil }
    return createNodeWrapper(raw)
  }

  @discardableResult
  func nextSibling() -> NodeWrapper? {
    guard let raw = wk_interop.Node_nextSibling(p) else { return nil }
    return createNodeWrapper(raw)
  }

  @discardableResult
  func nonShadowBoundaryParentNode() -> ContainerNodeWrapper? {
    guard let raw = wk_interop.Node_nonShadowBoundaryParentNode(p) else { return nil }
    return ContainerNodeWrapper(p: raw)
  }

  @discardableResult
  func parentInComposedTree() -> ContainerNodeWrapper? {
    guard let raw = wk_interop.Node_parentInComposedTree(p) else { return nil }
    return ContainerNodeWrapper(p: raw)
  }

  @discardableResult
  func parentNode() -> ContainerNodeWrapper? {
    guard let raw = wk_interop.Node_parentNode(p) else { return nil }
    return ContainerNodeWrapper(p: raw)
  }

  @discardableResult
  func parentOrShadowHostNode() -> ContainerNodeWrapper? {
    guard let raw = wk_interop.Node_parentOrShadowHostNode(p) else { return nil }
    return ContainerNodeWrapper(p: raw)
  }

  @discardableResult
  func previousSibling() -> NodeWrapper? {
    guard let raw = wk_interop.Node_previousSibling(p) else { return nil }
    return createNodeWrapper(raw)
  }

  @discardableResult
  func protectedDocument() -> Document {
    return Document(wk_interop.Node_protectedDocument(p)!)
  }

  @discardableResult
  func protectedParentNode() -> ContainerNodeWrapper? {
    guard let raw = wk_interop.Node_protectedParentNode(p) else { return nil }
    return ContainerNodeWrapper(p: raw)
  }

  @discardableResult
  func protectedParentOrShadowHostNode() -> ContainerNodeWrapper? {
    guard let raw = wk_interop.Node_protectedParentOrShadowHostNode(p) else { return nil }
    return ContainerNodeWrapper(p: raw)
  }

  @discardableResult
  func protectedPreviousSibling() -> NodeWrapper? {
    guard let raw = wk_interop.Node_protectedPreviousSibling(p) else { return nil }
    return createNodeWrapper(raw)
  }

  @discardableResult
  func rootEditableElement() -> ElementWrapper? {
    guard let raw = wk_interop.Node_rootEditableElement(p) else { return nil }
    return createElementWrapper(raw)
  }

  @discardableResult
  func traverseToChildAt(_ arg0: UInt32) -> NodeWrapper? {
    guard let raw = wk_interop.Node_traverseToChildAt(p, arg0) else { return nil }
    return createNodeWrapper(raw)
  }

  func treeScope() -> TreeScopeWrapper {
    fatalError("Not implemented")
  }
}
