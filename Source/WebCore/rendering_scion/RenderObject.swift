/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 *           (C) 2004 Allan Sandfeld Jensen (kde@carewolf.com)
 * Copyright (C) 2003-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 */

import wk_interop

enum RepaintRectCalculation: UInt8 {
  case Fast
  case Accurate
}

enum RepaintOutlineBounds {
  case No
  case Yes
}

enum RequiresFullRepaint {
  case No
  case Yes
}

private func objectIsRelayoutBoundary(object: RenderElementWrapper) -> Bool {
  // FIXME: In future it may be possible to broaden these conditions in order to improve performance.
  if object.isRenderView() {
    return true
  }

  if let textControl = object as? RenderTextControlWrapper {
    if !textControl.isFlexItem() && !textControl.isGridItem() {
      // Flexing type of layout systems may compute different size than what input's preferred width is which won't happen unless they run their layout as well.
      return true
    }
  }

  if object.shouldApplyLayoutContainment() && object.shouldApplySizeContainment() {
    return true
  }

  if object.isRenderOrLegacyRenderSVGRoot() {
    return true
  }

  if !object.hasNonVisibleOverflow() {
    return false
  }

  if object.document().settings().layerBasedSVGEngineEnabled() && object.isSVGLayerAwareRenderer() {
    return false
  }

  if object.style().width().isIntrinsicOrAuto() || object.style().height().isIntrinsicOrAuto()
    || object.style().height().isPercentOrCalculated()
  {
    return false
  }

  // Table parts can't be relayout roots since the table is responsible for layouting all the parts.
  if object.isTablePart() {
    return false
  }

  return true
}

private func setIsSimplifiedLayoutRootForLayerIfApplicable(renderElement: RenderElementWrapper) {
  assert(renderElement.isOutOfFlowPositioned())

  if !renderElement.normalChildNeedsLayout() {
    return
  }

  if let renderer = renderElement as? RenderLayerModelObjectWrapper, let layer = renderer.layer() {
    return layer.setIsSimplifiedLayoutRoot()
  }

  fatalError("Not reached")
}

private func nearestNonAnonymousContainingBlockIncludingSelf(renderer: RenderElementWrapper?)
  -> RenderBlockWrapper?
{
  var renderer = renderer
  while renderer != nil && (!(renderer is RenderBlockWrapper) || renderer!.isAnonymousBlock()) {
    renderer = renderer!.containingBlock()
  }
  return renderer as! RenderBlockWrapper?
}

private func canRelyOnAncestorLayerFullRepaint(
  _ rendererToRepaint: RenderObjectWrapper, _ ancestorLayer: RenderLayerWrapper
) -> Bool {
  if let renderElement = rendererToRepaint as? RenderElementWrapper,
    renderElement.hasSelfPaintingLayer()
  {
    return ancestorLayer.renderer().hasNonVisibleOverflow()
  }
  return true
}

private func fullRepaintIsScheduled(_ renderer: RenderObjectWrapper) -> Bool {
  if !renderer.view().usesCompositing() && renderer.document().ownerElement() == nil {
    return false
  }
  var ancestorLayer = renderer.enclosingLayer()
  while ancestorLayer != nil {
    if ancestorLayer!.needsFullRepaint() {
      return canRelyOnAncestorLayerFullRepaint(renderer, ancestorLayer!)
    }
    ancestorLayer = ancestorLayer!.paintOrderParent()
  }
  return false
}

class RenderObjectWrapper: CachedImageClientWrapper {
  enum `Type` {
    case BlockFlow
    case Button
    case CombineText
    case Counter
    case DeprecatedFlexibleBox
    case DetailsMarker
    case EmbeddedObject
    case FileUploadControl
    case FlexibleBox
    case Frame
    case FrameSet
    case Grid
    case HTMLCanvas
    case IFrame
    case Image
    case Inline
    case LineBreak
    case ListBox
    case ListItem
    case ListMarker
    case Media
    case MenuList
    case Meter
    case MultiColumnFlow
    case MultiColumnSet
    case MultiColumnSpannerPlaceholder
    case Progress
    case Quote
    case Replica
    case ScrollbarPart
    case SearchField
    case Slider
    case SliderContainer
    case Table
    case TableCaption
    case TableCell
    case TableCol
    case TableRow
    case TableSection
    case Text
    case TextControlInnerBlock
    case TextControlInnerContainer
    case TextControlMultiLine
    case TextControlSingleLine
    case TextFragment
    case VTTCue
    case Video
    case View
    case ViewTransitionCapture
    case SVGEllipse
    case SVGForeignObject
    case SVGGradientStop
    case SVGHiddenContainer
    case SVGImage
    case SVGInline
    case SVGInlineText
    case SVGPath
    case SVGRect
    case SVGResourceClipper
    case SVGResourceFilter
    case SVGResourceFilterPrimitive
    case SVGResourceLinearGradient
    case SVGResourceMarker
    case SVGResourceMasker
    case SVGResourcePattern
    case SVGResourceRadialGradient
    case SVGRoot
    case SVGTSpan
    case SVGText
    case SVGTextPath
    case SVGTransformableContainer
    case SVGViewportContainer
    case LegacySVGEllipse
    case LegacySVGForeignObject
    case LegacySVGHiddenContainer
    case LegacySVGImage
    case LegacySVGPath
    case LegacySVGRect
    case LegacySVGResourceClipper
    case LegacySVGResourceFilter
    case LegacySVGResourceFilterPrimitive
    case LegacySVGResourceLinearGradient
    case LegacySVGResourceMarker
    case LegacySVGResourceMasker
    case LegacySVGResourcePattern
    case LegacySVGResourceRadialGradient
    case LegacySVGRoot
    case LegacySVGTransformableContainer
    case LegacySVGViewportContainer
  }

  struct TypeFlag: OptionSet {
    let rawValue: UInt8

    static let IsAnonymous = TypeFlag(rawValue: 1 << 0)
    static let IsText = TypeFlag(rawValue: 1 << 1)
    static let IsBox = TypeFlag(rawValue: 1 << 2)
    static let IsBoxModelObject = TypeFlag(rawValue: 1 << 3)
    static let IsLayerModelObject = TypeFlag(rawValue: 1 << 4)
    static let IsRenderInline = TypeFlag(rawValue: 1 << 5)
    static let IsRenderBlock = TypeFlag(rawValue: 1 << 6)
    static let IsFlexibleBox = TypeFlag(rawValue: 1 << 7)
  }

  // Type Specific Flags

  struct BlockFlowFlag: OptionSet {
    let rawValue: UInt8

    static let IsFragmentContainer = BlockFlowFlag(rawValue: 1 << 0)
    static let IsFragmentedFlow = BlockFlowFlag(rawValue: 1 << 1)
    static let IsTextControl = BlockFlowFlag(rawValue: 1 << 2)
    static let IsSVGBlock = BlockFlowFlag(rawValue: 1 << 3)
    static let IsViewTransitionContainer = BlockFlowFlag(rawValue: 1 << 4)
  }

  struct LineBreakFlag: OptionSet {
    let rawValue: UInt8

    static let IsWBR = LineBreakFlag(rawValue: 1 << 0)
  }

  struct ReplacedFlag: OptionSet {
    let rawValue: UInt8

    static let IsImage = ReplacedFlag(rawValue: 1 << 0)
    static let IsMedia = ReplacedFlag(rawValue: 1 << 1)
    static let IsWidget = ReplacedFlag(rawValue: 1 << 2)
    static let IsViewTransitionCapture = ReplacedFlag(rawValue: 1 << 3)
    static let UsesBoundaryCaching = ReplacedFlag(rawValue: 1 << 5)
  }

  struct SVGModelObjectFlag: OptionSet {
    let rawValue: UInt8

    static let IsLegacy = SVGModelObjectFlag(rawValue: 1 << 0)
    static let IsContainer = SVGModelObjectFlag(rawValue: 1 << 1)
    static let IsHiddenContainer = SVGModelObjectFlag(rawValue: 1 << 2)
    static let IsResourceContainer = SVGModelObjectFlag(rawValue: 1 << 3)
    static let IsShape = SVGModelObjectFlag(rawValue: 1 << 4)
    static let UsesBoundaryCaching = SVGModelObjectFlag(rawValue: 1 << 5)
  }

  struct TypeSpecificFlags {
    enum Kind: UInt8 {
      case Invalid = 0
      case BlockFlow
      case LineBreak
      case Replaced
      case SVGModelObject
    }

    init() {
      self.kind = .Invalid
      self.flags = 0
    }

    init(_ flags: RenderObjectWrapper.BlockFlowFlag) {
      self.kind = .BlockFlow
      self.flags = flags.rawValue
    }

    func blockFlowFlags() -> BlockFlowFlag {
      return BlockFlowFlag(rawValue: valueForKind(.BlockFlow))
    }

    func lineBreakFlags() -> LineBreakFlag {
      return LineBreakFlag(rawValue: valueForKind(.LineBreak))
    }

    func replacedFlags() -> ReplacedFlag {
      return ReplacedFlag(rawValue: valueForKind(.Replaced))
    }

    func svgFlags() -> SVGModelObjectFlag {
      return SVGModelObjectFlag(rawValue: valueForKind(.SVGModelObject))
    }

    private func valueForKind(_ kind: Kind) -> UInt8 {
      return self.kind == kind ? flags : 0
    }

    let kind: Kind
    let flags: UInt8
  }

  init(p: UnsafeMutableRawPointer) {
    self.pInterop = p
    m_node = nil
    m_typeFlags = []
    m_type = .BlockFlow
    m_typeSpecificFlags = TypeSpecificFlags()
  }

  init(
    _ type: `Type`, _ node: NodeWrapper, _ typeFlags: TypeFlag,
    _ typeSpecificFlags: TypeSpecificFlags
  ) {
    self.pInterop = nil
    // TODO(asuhan): add fields for assertions
    m_node = node
    m_typeFlags = node.isDocumentNode() ? typeFlags.union(.IsAnonymous) : typeFlags
    m_type = type
    m_typeSpecificFlags = typeSpecificFlags
    assert(!typeFlags.contains(.IsAnonymous))
    if let renderView = node.document().renderView() {
      renderView.didCreateRenderer()
    }
    // TODO(asuhan): add leak counter
  }

  func type() -> `Type` { return m_type }

  func layoutBox() -> BoxWrapper? {
    assert(!isNativeImpl())
    let unwrapped = wk_interop.RenderObject_layoutBox(id())
    if unwrapped == nil {
      return nil
    }
    let styleUnwrapped = wk_interop.Box_style(unwrapped)!
    let style = convert_render_style(p: styleUnwrapped)
    if wk_interop.Box_isInlineTextBox(unwrapped) {
      let box = convert_inline_text_box(p: unwrapped!)
      box.p = UnsafeRawPointer(unwrapped!)
      return box
    }
    if wk_interop.Box_isInitialContainingBlock(unwrapped) {
      let box = InitialContainingBlock(wrapperStyle: style)
      box.p = UnsafeRawPointer(unwrapped!)
      return box
    }
    if wk_interop.Box_isElementBox(unwrapped) {
      let box = ElementBoxWrapper(wrapperStyle: style)
      box.p = UnsafeRawPointer(unwrapped!)
      return box
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func theme() -> RenderTheme {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parent() -> RenderElementWrapper? {
    if !isNativeImpl() {
      let unwrapped = wk_interop.RenderObject_parent(id())
      if unwrapped == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
      return RenderElementWrapper(p: unwrapped!)
    }
    return m_parent
  }

  func checkedParent() -> RenderElementWrapper? {
    return parent()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func isDescendantOf(ancestor: RenderObjectWrapper?) -> Bool {
    var renderer: RenderObjectWrapper? = self
    while renderer != nil {
      if CPtrToInt(renderer!.id()) == CPtrToInt(ancestor?.id()) {
        return true
      }
      renderer = renderer!.m_parent
    }
    return false
  }

  func previousSibling() -> RenderObjectWrapper? {
    assert(isNativeImpl())
    return m_previous
  }

  func nextSibling() -> RenderObjectWrapper? {
    assert(isNativeImpl())
    return m_next
  }

  // Use RenderElement versions instead.
  func firstChildSlow() -> RenderObjectWrapper? {
    assert(isNativeImpl())
    return nil
  }

  func lastChildSlow() -> RenderObjectWrapper? {
    assert(isNativeImpl())
    return nil
  }

  func nextInPreOrder() -> RenderObjectWrapper? {
    if let o = firstChildSlow() {
      return o
    }

    return nextInPreOrderAfterChildren()
  }

  func nextInPreOrder(stayWithin: RenderObjectWrapper?) -> RenderObjectWrapper? {
    if let o = firstChildSlow() {
      return o
    }

    return nextInPreOrderAfterChildren(stayWithin)
  }

  func nextInPreOrderAfterChildren() -> RenderObjectWrapper? {
    if let o = nextSibling() {
      return o
    }
    var o = parent()
    while o != nil && o!.nextSibling() == nil {
      o = o!.parent()
    }
    return o?.nextSibling()
  }

  func nextInPreOrderAfterChildren(_ stayWithin: RenderObjectWrapper?) -> RenderObjectWrapper? {
    if CPtrToInt(id()) == CPtrToInt(stayWithin?.id()) {
      return nil
    }

    var current: RenderObjectWrapper? = self
    var next: RenderObjectWrapper? = nil
    while true {
      next = current!.nextSibling()
      if next != nil {
        break
      }
      current = current!.parent()
      if current == nil || CPtrToInt(current!.id()) == CPtrToInt(stayWithin?.id()) {
        return nil
      }
    }
    return next
  }

  func previousInPreOrder() -> RenderObjectWrapper? {
    if var o = previousSibling() {
      while let last = o.lastChildSlow() {
        o = last
      }
      return o
    }

    return parent()
  }

  func childAt(_ index: UInt32) -> RenderObjectWrapper? {
    var child = firstChildSlow()
    for _ in 0..<index {
      if child == nil {
        break
      }
      child = child!.nextSibling()
    }
    return child
  }

  func lastLeafChild() -> RenderObjectWrapper? {
    var r = lastChildSlow()
    while r != nil {
      if let n = r!.lastChildSlow() {
        r = n
      } else {
        break
      }
    }
    return r
  }

  func firstNonAnonymousAncestor() -> RenderElementWrapper? {
    var ancestor = parent()
    while ancestor != nil && ancestor!.isAnonymous() {
      ancestor = ancestor!.parent()
    }
    return ancestor
  }

  func enclosingLayer() -> RenderLayerWrapper? {
    for renderer in RenderAncestorIteratorAdapter<RenderLayerModelObjectWrapper>.lineageOfType(
      first: self)
    {
      if renderer.hasLayer() {
        return renderer.layer()
      }
    }
    return nil
  }

  func enclosingBox() -> RenderBoxWrapper {
    assert(isNativeImpl())
    return RenderAncestorIteratorAdapter<RenderBoxWrapper>.lineageOfType(first: self).first()!
  }

  func enclosingBoxModelObject() -> RenderBoxModelObjectWrapper {
    assert(isNativeImpl())
    return RenderAncestorIteratorAdapter<RenderBoxModelObjectWrapper>.lineageOfType(first: self)
      .first()!
  }

  func enclosingScrollableContainer() -> RenderBoxWrapper? {
    // Walk up the container chain to find the scrollable container that contains
    // this RenderObject. The important thing here is that `container()` respects
    // the containing block chain for positioned elements. This is important because
    // scrollable overflow does not establish a new containing block for children.
    var candidate = container()
    while candidate != nil {
      // Currently the RenderView can look like it has scrollable overflow, but we never
      // want to return this as our container. Instead we should use the root element.
      if candidate!.isRenderView() {
        break
      }
      if candidate!.hasPotentiallyScrollableOverflow() {
        return (candidate as! RenderBoxWrapper)
      }
      candidate = candidate!.container()
    }

    // If we reach the root, then the root element is the scrolling container.
    return document().documentElement()?.renderBox()
  }

  func styleColorOptions() -> StyleColorOptions {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return our enclosing flow thread if we are contained inside one. Follows the containing block chain.
  func enclosingFragmentedFlow() -> RenderFragmentedFlowWrapper? {
    assert(isNativeImpl())
    if fragmentedFlowState() == .NotInsideFlow {
      return nil
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func useDarkAppearance() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // RenderObject tree manipulation
  //////////////////////////////////////////
  func canHaveChildren() -> Bool { fatalError("Not reached") }

  // We only create "generated" child renderers like one for first-letter if:
  // - the firstLetterBlock can have children in the DOM and
  // - the block doesn't have any special assumption on its text children.
  // This correctly prevents form controls from having such renderers.
  func canHaveGeneratedChildren() -> Bool {
    return canHaveChildren()
  }

  func createsAnonymousWrapper() -> Bool { return false }
  //////////////////////////////////////////

  func isPseudoElement() -> Bool {
    assert(isNativeImpl())
    return node()?.isPseudoElement() ?? false
  }

  func isRenderElement() -> Bool { return !isRenderText() }

  func isRenderReplaced() -> Bool {
    assert(isNativeImpl())
    return m_typeSpecificFlags.kind == .Replaced
  }

  func isRenderBoxModelObject() -> Bool { return m_typeFlags.contains(.IsBoxModelObject) }

  func isRenderBlock() -> Bool { return m_typeFlags.contains(.IsRenderBlock) }

  func isRenderBlockFlow() -> Bool { return m_typeSpecificFlags.kind == .BlockFlow }

  func isRenderInline() -> Bool {
    assert(isNativeImpl())
    return m_typeFlags.contains(.IsRenderInline)
  }

  func isRenderLayerModelObject() -> Bool { return m_typeFlags.contains(.IsLayerModelObject) }

  func isAtomicInlineLevelBox() -> Bool {
    return style().isDisplayInlineType()
      && !(style().display() == .Inline && !isReplacedOrInlineBlock())
  }

  func isRenderQuote() -> Bool {
    assert(isNativeImpl())
    return type() == .Quote
  }

  func isRenderEmbeddedObject() -> Bool {
    assert(isNativeImpl())
    return type() == .EmbeddedObject
  }

  func isFieldset() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderObject_isFieldset(id())
    }
    if node() == nil {
      return false
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderFileUploadControl() -> Bool {
    assert(isNativeImpl())
    return type() == .FileUploadControl
  }

  func isRenderFrame() -> Bool {
    assert(isNativeImpl())
    return type() == .Frame
  }

  func isRenderFrameSet() -> Bool {
    assert(isNativeImpl())
    return type() == .FrameSet
  }

  func isImage() -> Bool {
    assert(!isNativeImpl())
    return wk_interop.RenderObject_isImage(id())
  }

  func isInlineBlockOrInlineTable() -> Bool { return false }

  func isRenderListBox() -> Bool {
    assert(isNativeImpl())
    return type() == .ListBox
  }

  func isRenderListMarker() -> Bool {
    assert(isNativeImpl())
    return type() == .ListMarker
  }

  func isRenderMedia() -> Bool {
    return isRenderReplaced() && m_typeSpecificFlags.replacedFlags().contains(.IsMedia)
  }

  func isRenderMenuList() -> Bool {
    assert(isNativeImpl())
    return type() == .MenuList
  }

  func isRenderButton() -> Bool {
    assert(isNativeImpl())
    return type() == .Button
  }

  func isRenderIFrame() -> Bool {
    assert(isNativeImpl())
    return type() == .IFrame
  }

  func isRenderFragmentContainer() -> Bool {
    assert(isNativeImpl())
    return isRenderBlockFlow()
      && m_typeSpecificFlags.blockFlowFlags().contains(.IsFragmentContainer)
  }

  func isRenderViewTransitionContainer() -> Bool {
    assert(isNativeImpl())
    return isRenderBlockFlow()
      && m_typeSpecificFlags.blockFlowFlags().contains(.IsViewTransitionContainer)
  }

  func isRenderReplica() -> Bool {
    assert(isNativeImpl())
    return type() == .Replica
  }

  func isRenderTable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTableCell() -> Bool {
    assert(isNativeImpl())
    return type() == .TableCell
  }

  func isRenderTableCol() -> Bool {
    assert(isNativeImpl())
    return type() == .TableCol
  }

  func isRenderTableCaption() -> Bool {
    assert(isNativeImpl())
    return type() == .TableCaption
  }

  func isRenderTableSection() -> Bool {
    assert(isNativeImpl())
    return type() == .TableSection
  }

  func isRenderTextControl() -> Bool {
    assert(isNativeImpl())
    return isRenderBlockFlow() && m_typeSpecificFlags.blockFlowFlags().contains(.IsTextControl)
  }

  func isRenderVideo() -> Bool {
    assert(isNativeImpl())
    return type() == .Video
  }

  func isRenderViewTransitionCapture() -> Bool {
    return isRenderReplaced()
      && m_typeSpecificFlags.replacedFlags().contains(.IsViewTransitionCapture)
  }

  func isRenderHTMLCanvas() -> Bool {
    assert(isNativeImpl())
    return type() == .HTMLCanvas
  }

  func isRenderGrid() -> Bool {
    assert(isNativeImpl())
    return type() == .Grid
  }

  func isRenderMultiColumnSet() -> Bool {
    assert(isNativeImpl())
    return type() == .MultiColumnSet
  }

  func isRenderMultiColumnFlow() -> Bool {
    assert(isNativeImpl())
    return type() == .MultiColumnFlow
  }

  func isDocumentElementRenderer() -> Bool {
    return CPtrToInt(document().documentElement()?.p) == CPtrToInt(m_node?.p)
  }

  func isBody() -> Bool {
    if node() == nil {
      return false
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLegend() -> Bool {
    if node() == nil {
      return false
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isHTMLMarquee() -> Bool {
    if node() == nil {
      return false
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTablePart() -> Bool {
    assert(isNativeImpl())
    return isRenderTableCell() || isRenderTableCol() || isRenderTableCaption() || isRenderTableRow()
      || isRenderTableSection()
  }

  func isViewTransitionPseudo() -> Bool {
    assert(isNativeImpl())
    return isRenderViewTransitionCapture() || isRenderViewTransitionContainer()
  }

  func isBeforeContent() -> Bool {
    assert(isNativeImpl())
    // Text nodes don't have their own styles, so ignore the style on a text node.
    if isRenderText() {
      return false
    }
    if style().pseudoElementType() != .Before {
      return false
    }
    return true
  }

  func isAfterContent() -> Bool {
    assert(isNativeImpl())
    // Text nodes don't have their own styles, so ignore the style on a text node.
    if isRenderText() {
      return false
    }
    if style().pseudoElementType() != .After {
      return false
    }
    return true
  }

  func isBeforeOrAfterContent() -> Bool {
    assert(isNativeImpl())
    return isBeforeContent() || isAfterContent()
  }

  func isAfterContent(obj: RenderObjectWrapper?) -> Bool {
    assert(isNativeImpl())
    return obj?.isAfterContent() ?? false
  }

  func beingDestroyed() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.BeingDestroyed)
  }

  func everHadLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.EverHadLayout)
  }

  func wasSkippedDuringLastLayoutDueToContentVisibility() -> Bool? {
    assert(isNativeImpl())
    return everHadLayout()
      ? m_stateBitfields.hasFlag(.WasSkippedDuringLastLayoutDueToContentVisibility) : nil
  }

  static func searchParentChainForScrollAnchoringController(_ renderer: RenderObjectWrapper)
    -> ScrollAnchoringControllerWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func childrenInline() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.ChildrenInline)
  }

  func setChildrenInline(b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.ChildrenInline, b)
  }

  enum FragmentedFlowState {
    case NotInsideFlow
    case InsideFlow
  }

  private enum SkipDescendentFragmentedFlow {
    case No
    case Yes
  }

  private func setFragmentedFlowStateIncludingDescendants(
    state: FragmentedFlowState, skipDescendentFragmentedFlow: SkipDescendentFragmentedFlow = .Yes
  ) {
    setFragmentedFlowState(state)

    guard let renderElement = self as? RenderElementWrapper else { return }

    for child: RenderObjectWrapper in childrenOfType(parent: renderElement) {
      // If the child is a fragmentation context it already updated the descendants flag accordingly.
      if child.isRenderFragmentedFlow() && skipDescendentFragmentedFlow == .Yes {
        continue
      }
      if child.isOutOfFlowPositioned() {
        // Fragmented status propagation stops at out-of-flow boundary.
        let isInsideMulticolumnFlow = { () in
          guard let containingBlock = child.containingBlock() else {
            fatalError("Not reached")
          }
          return containingBlock.fragmentedFlowState() == .InsideFlow
        }
        if !isInsideMulticolumnFlow() {
          continue
        }
      }
      assert(skipDescendentFragmentedFlow == .No || state != child.fragmentedFlowState())
      child.setFragmentedFlowStateIncludingDescendants(
        state: state, skipDescendentFragmentedFlow: skipDescendentFragmentedFlow)
    }
  }

  func fragmentedFlowState() -> FragmentedFlowState {
    assert(isNativeImpl())
    return m_stateBitfields.fragmentedFlowState()
  }

  func setFragmentedFlowState(_ state: FragmentedFlowState) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGModelObject() -> Bool {
    assert(isNativeImpl())
    return m_typeSpecificFlags.kind == .SVGModelObject
      && !m_typeSpecificFlags.svgFlags().contains(.IsLegacy)
  }

  func isRenderSVGBlock() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLegacyRenderSVGRoot() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGRoot() -> Bool {
    assert(isNativeImpl())
    return type() == .SVGRoot
  }

  func isRenderSVGViewportContainer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGText() -> Bool {
    assert(isNativeImpl())
    return type() == .SVGText
  }

  func isRenderSVGTextPath() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGInline() -> Bool {
    assert(isNativeImpl())
    return type() == .SVGInline || type() == .SVGTSpan || type() == .SVGTextPath
  }

  func isRenderSVGInlineText() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGForeignObject() -> Bool {
    assert(isNativeImpl())
    return type() == .SVGForeignObject
  }

  func isLegacyRenderSVGHiddenContainer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGHiddenContainer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGResourceMarker() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderOrLegacyRenderSVGRoot() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderOrLegacyRenderSVGShape() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSVGLayerAwareRenderer() -> Bool {
    return isRenderSVGRoot() || isRenderSVGModelObject() || isRenderSVGText() || isRenderSVGInline()
      || isRenderSVGForeignObject()
  }

  // FIXME: Those belong into a SVG specific base-class for all renderers (see above)
  // Unfortunately we don't have such a class yet, because it's not possible for all renderers
  // to inherit from RenderSVGObject -> RenderObject (some need RenderBlock inheritance for instance)
  func invalidateCachedBoundaries() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsTransformUpdate() {}

  // Per SVG 1.1 objectBoundingBox ignores clipping, masking, filter effects, opacity and stroke-width.
  // This is used for all computation of objectBoundingBox relative units and by SVGLocatable::getBBox().
  // NOTE: Markers are not specifically ignored here by SVG 1.1 spec, but we ignore them
  // since stroke-width is ignored (and marker size can depend on stroke-width).
  // objectBoundingBox is returned local coordinates.
  // The name objectBoundingBox is taken from the SVG 1.1 spec.
  func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the smallest rectangle enclosing all of the painted content
  // respecting clipping, masking, filters, opacity, stroke-width and markers
  // This returns approximate rectangle for SVG renderers when RepaintRectCalculation.Fast is specified.
  func repaintRectInLocalCoordinates(_ repaintRectCalculation: RepaintRectCalculation = .Fast)
    -> FloatRectWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This only returns the transform="" value from the element
  // most callsites want localToParentTransform() instead.
  func localTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the full transform mapping from local coordinates to local coords for the parent SVG renderer
  // This includes any viewport transforms and x/y offsets as well as the transform="" value off the element.
  func localToParentTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIntrinsicAspectRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAnonymous() -> Bool {
    assert(isNativeImpl())
    return m_typeFlags.contains(.IsAnonymous)
  }

  func isAnonymousBlock() -> Bool {
    // This function must be kept in sync with anonymous block creation conditions in RenderBlock::createAnonymousBlock().
    // FIXME: That seems difficult. Can we come up with a simpler way to make behavior correct?
    // FIXME: Does this relatively long function benefit from being inlined?
    return isAnonymous()
      && (style().display() == .Block || style().display() == .Box)
      && style().pseudoElementType() == .None
      && isRenderBlock()
      && !isRenderListMarker()
      && !isRenderFragmentedFlow()
      && !isRenderMultiColumnSet()
      && !isRenderView()
  }

  func isAnonymousForPercentageResolution() -> Bool {
    assert(isNativeImpl())
    return isAnonymous() && !isViewTransitionPseudo()
  }

  func isBlockBox() -> Bool {
    // A block-level box that is also a block container.
    return isBlockLevelBox() && isBlockContainer()
  }

  func isBlockLevelBox() -> Bool {
    assert(isNativeImpl())
    return style().isDisplayBlockLevel()
  }

  func isBlockContainer() -> Bool {
    let display = style().display()
    return
      (display == .Block
      || display == .InlineBlock
      || display == .FlowRoot
      || display == .ListItem
      || display == .TableCell
      || display == .TableCaption) && !isRenderReplaced()
  }

  func isFloating() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.Floating)
  }

  func isPositioned() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.isPositioned()
  }

  func isInFlowPositioned() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.isRelativelyPositioned() || m_stateBitfields.isStickilyPositioned()
  }

  func isOutOfFlowPositioned() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.isOutOfFlowPositioned()  // absolute or fixed positioning
  }

  func isFixedPositioned() -> Bool {
    return isOutOfFlowPositioned() && style().position() == .Fixed
  }

  func isAbsolutelyPositioned() -> Bool {
    return isOutOfFlowPositioned() && style().position() == .Absolute
  }

  func isRelativelyPositioned() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.isRelativelyPositioned()
  }

  func isStickilyPositioned() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.isStickilyPositioned()
  }

  func shouldUsePositionedClipping() -> Bool {
    assert(isNativeImpl())
    return isAbsolutelyPositioned() || isRenderSVGForeignObject()
  }

  func isRenderText() -> Bool {
    assert(isNativeImpl())
    return m_typeFlags.contains(.IsText)
  }

  private func isRenderLineBreak() -> Bool {
    assert(isNativeImpl())
    return type() == .LineBreak
  }

  func isBR() -> Bool {
    return isRenderLineBreak() && !hasWBRLineBreakFlag()
  }

  private func isWBR() -> Bool {
    return isRenderLineBreak() && hasWBRLineBreakFlag()
  }

  func isLineBreakOpportunity() -> Bool {
    return isRenderLineBreak() && isWBR()
  }

  func isRenderBox() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderObject_isRenderBox(id())
    }
    return m_typeFlags.contains(.IsBox)
  }

  func isRenderTableRow() -> Bool {
    assert(isNativeImpl())
    return type() == .TableRow
  }

  func isRenderView() -> Bool { return type() == .View }

  func isInline() -> Bool {
    assert(isNativeImpl())
    return !m_stateBitfields.hasFlag(.IsBlock)
  }

  func isReplacedOrInlineBlock() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.IsReplacedOrInlineBlock)
  }

  func isHorizontalWritingMode() -> Bool {
    if isNativeImpl() { return !m_stateBitfields.hasFlag(.VerticalWritingMode) }
    return wk_interop.RenderObject_isHorizontalWritingMode(id())
  }

  func hasReflection() -> Bool { return hasRareData() && rareData().hasReflection }

  func isRenderFragmentedFlow() -> Bool {
    assert(isNativeImpl())
    return isRenderBlockFlow() && m_typeSpecificFlags.blockFlowFlags().contains(.IsFragmentedFlow)
  }

  func hasOutlineAutoAncestor() -> Bool {
    assert(isNativeImpl())
    return hasRareData() && rareData().hasOutlineAutoAncestor
  }

  func paintContainmentApplies() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.PaintContainmentApplies)
  }

  func hasSVGTransform() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.HasSVGTransform)
  }

  func isExcludedFromNormalLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.IsExcludedFromNormalLayout)
  }

  func setIsExcludedFromNormalLayout(excluded: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.IsExcludedFromNormalLayout, excluded)
  }

  func isExcludedAndPlacedInBorder() -> Bool { return isExcludedFromNormalLayout() && isLegend() }

  func hasLayer() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.HasLayer)
  }

  enum BoxDecorationState {
    case None
    case InvalidObscurationStatus
    case IsKnownToBeObscured
    case MayBeVisible
  }

  func hasVisibleBoxDecorations() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.boxDecorationState != .None
  }

  func backgroundIsKnownToBeObscured(paintOffset: LayoutPointWrapper) -> Bool {
    if m_stateBitfields.boxDecorationState == .InvalidObscurationStatus {
      let boxDecorationState: BoxDecorationState =
        computeBackgroundIsKnownToBeObscured(paintOffset) ? .IsKnownToBeObscured : .MayBeVisible
      m_stateBitfields.boxDecorationState = boxDecorationState
    }
    return m_stateBitfields.boxDecorationState == .IsKnownToBeObscured
  }

  func needsLayout() -> Bool {
    return selfNeedsLayout()
      || normalChildNeedsLayout()
      || posChildNeedsLayout()
      || needsSimplifiedNormalFlowLayout()
      || needsPositionedMovementLayout()
  }

  func selfNeedsLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.NeedsLayout)
  }

  func needsPositionedMovementLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.NeedsPositionedMovementLayout)
  }

  func needsPositionedMovementLayoutOnly() -> Bool {
    return needsPositionedMovementLayout()
      && !selfNeedsLayout()
      && !normalChildNeedsLayout()
      && !posChildNeedsLayout()
      && !needsSimplifiedNormalFlowLayout()
  }

  func posChildNeedsLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.PosChildNeedsLayout)
  }

  func needsSimplifiedNormalFlowLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.NeedsSimplifiedNormalFlowLayout)
  }

  func needsSimplifiedNormalFlowLayoutOnly() -> Bool {
    return needsSimplifiedNormalFlowLayout() && !selfNeedsLayout() && !normalChildNeedsLayout()
      && !posChildNeedsLayout() && !needsPositionedMovementLayout()
  }

  func normalChildNeedsLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.NormalChildNeedsLayout)
  }

  func outOfFlowChildNeedsStaticPositionLayout() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.OutOfFlowChildNeedsStaticPositionLayout)
  }

  func preferredLogicalWidthsDirty() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.PreferredLogicalWidthsDirty)
  }

  func isSelectionBorder() -> Bool {
    let st = selectionState()
    return st == .Start
      || st == .End
      || st == .Both
      || CPtrToInt(view().selection().start()?.id()) == CPtrToInt(id())
      || CPtrToInt(view().selection().end()?.id()) == CPtrToInt(id())
  }

  func hasNonVisibleOverflow() -> Bool {
    if !isNativeImpl() {
      return wk_interop.RenderObject_hasNonVisibleOverflow(id())
    }
    return m_stateBitfields.hasFlag(.HasNonVisibleOverflow)
  }

  func hasPotentiallyScrollableOverflow() -> Bool {
    assert(isNativeImpl())
    // We only need to test one overflow dimension since 'visible' and 'clip' always get accompanied
    // with 'clip' or 'visible' in the other dimension (see Style::Adjuster::adjust).
    return hasNonVisibleOverflow() && style().overflowX() != .Clip
      && style().overflowX() != .Visible
  }

  func hasTransformRelatedProperty() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.HasTransformRelatedProperty)  // Transform, perspective or transform-style: preserve-3d.
  }

  func isTransformed() -> Bool {
    return hasTransformRelatedProperty() && (style().affectsTransform() || hasSVGTransform())
  }

  func hasTransformOrPerspective() -> Bool {
    return hasTransformRelatedProperty() && (isTransformed() || style().hasPerspective())
  }

  func capturedInViewTransition() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.CapturedInViewTransition)
  }

  func setCapturedInViewTransition(_ captured: Bool) {
    if capturedInViewTransition() == captured {
      return
    }

    var layerToInvalidate: RenderLayerWrapper? = nil
    if isDocumentElementRenderer() {
      layerToInvalidate = view().layer()
    } else if hasLayer() {
      layerToInvalidate = (self as! RenderLayerModelObjectWrapper).layer()
    }

    layerToInvalidate?.setNeedsPostLayoutCompositingUpdate()

    // Invalidate transform applied by `RenderLayerBacking::updateTransform`.
    layerToInvalidate?.setNeedsCompositingGeometryUpdate()
  }

  // When the document element is captured, the captured contents uses the RenderView
  // instead. Returns the capture state with this adjustment applied.
  func effectiveCapturedInViewTransition() -> Bool {
    if isDocumentElementRenderer() {
      return false
    }
    if isRenderView() {
      return document().activeViewTransitionCapturedDocumentElement()
    }
    return capturedInViewTransition()
  }

  func preservesNewline() -> Bool {
    return !isRenderSVGInlineText() && style().preserveNewline()
  }

  func view() -> RenderViewWrapper {
    if !isNativeImpl() {
      return RenderViewWrapper(p: wk_interop.RenderObject_view(id()))
    }
    return document().renderView()!
  }

  func checkedView() -> RenderViewWrapper {
    return view()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  // Returns true if this renderer is rooted.
  func isRooted() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func node() -> NodeWrapper? {
    assert(isNativeImpl())
    if isAnonymous() {
      return nil
    }
    return m_node
  }

  func protectedNode() -> NodeWrapper? { return node() }

  func nonPseudoNode() -> NodeWrapper? {
    assert(isNativeImpl())
    return isPseudoElement() ? nil : node()
  }

  func document() -> Document {
    assert(isNativeImpl())
    return m_node!.document()
  }

  func protectedDocument() -> Document {
    return document()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func treeScopeForSVGReferences() -> TreeScopeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frame() -> LocalFrameWrapper { return document().frame()! }

  func protectedFrame() -> LocalFrameWrapper { return frame() }  // TODO(asuhan): just remove this wrapper, not needed in Swift

  func page() -> PageWrapper {
    // The render tree will always be torn down before Frame is disconnected from Page,
    // so it's safe to assume Frame::page() is non-null as long as there are live RenderObjects.
    return frame().page()!
  }

  func settings() -> SettingsWrapper { return page().settings() }

  // Returns the object containing this one. Can be different from parent for positioned elements.
  // If repaintContainer and repaintContainerSkipped are not null, on return *repaintContainerSkipped
  // is true if the renderer returned is an ancestor of repaintContainer.
  func container() -> RenderElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func container(_ repaintContainer: RenderLayerModelObjectWrapper?) -> (
    RenderElementWrapper?, Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPreferredLogicalWidthsDirty(
    shouldBeDirty: Bool, markParents: MarkingBehavior = .MarkContainingBlockChain
  ) {
    assert(isNativeImpl())
    let alreadyDirty = preferredLogicalWidthsDirty()
    m_stateBitfields.setFlag(.PreferredLogicalWidthsDirty, shouldBeDirty)
    if shouldBeDirty && !alreadyDirty && markParents == .MarkContainingBlockChain
      && (isRenderText() || !style().hasOutOfFlowPosition())
    {
      invalidateContainerPreferredLogicalWidths()
    }
  }

  func invalidateContainerPreferredLogicalWidths() {
    // In order to avoid pathological behavior when inlines are deeply nested, we do include them
    // in the chain that we mark dirty (even though they're kind of irrelevant).
    var ancestor = isRenderTableCell() ? containingBlock() : container()
    while ancestor != nil && !ancestor!.preferredLogicalWidthsDirty() {
      // Don't invalidate the outermost object of an unrooted subtree. That object will be
      // invalidated when the subtree is added to the document.
      let container =
        ancestor!.isRenderTableCell() ? ancestor!.containingBlock() : ancestor!.container()
      if container == nil && !ancestor!.isRenderView() {
        break
      }

      ancestor!.m_stateBitfields.setFlag(.PreferredLogicalWidthsDirty, true)
      if ancestor!.style().hasOutOfFlowPosition() {
        // A positioned object has no effect on the min/max width of its containing block ever.
        // We can optimize this case and not go up any further.
        break
      }
      ancestor = container
    }
  }

  func setHasOutlineAutoAncestor(hasOutlineAutoAncestor: Bool = true) {
    assert(isNativeImpl())
    if hasOutlineAutoAncestor || hasRareData() {
      ensureRareData().hasOutlineAutoAncestor = hasOutlineAutoAncestor
    }
  }

  func setPaintContainmentApplies(_ value: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.PaintContainmentApplies, value)
  }

  func setHasSVGTransform(_ value: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.HasSVGTransform, value)
  }

  func isComposited() -> Bool {
    assert(isNativeImpl())
    return hasLayer() && (self as! RenderLayerModelObjectWrapper).layer()!.isComposited()
  }

  func hitTest(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestFilter: HitTestFilter = .HitTestAll
  ) -> Bool {
    var inside = false
    if hitTestFilter != .HitTestSelf {
      // First test the foreground layer (lines and inlines).
      inside = nodeAtPoint(
        request, &result, locationInContainer, accumulatedOffset, .HitTestForeground)

      // Test floats next.
      if !inside {
        inside = nodeAtPoint(
          request, &result, locationInContainer, accumulatedOffset, .HitTestFloat)
      }

      // Finally test to see if the mouse is in the background (within a child block's background).
      if !inside {
        inside = nodeAtPoint(
          request, &result, locationInContainer, accumulatedOffset, .HitTestChildBlockBackgrounds)
      }
    }

    // See if the mouse is inside us but not any of our descendants
    if hitTestFilter != .HitTestDescendants && !inside {
      inside = nodeAtPoint(
        request, &result, locationInContainer, accumulatedOffset, .HitTestBlockBackground)
    }

    return inside
  }

  func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ action: HitTestAction
  ) -> Bool {
    return false
  }

  // Convert a local quad into the coordinate system of container, taking transforms into account.
  func localToContainerQuad(
    localQuad: FloatQuad, container: RenderLayerModelObjectWrapper?,
    mode: MapCoordinatesMode = [.UseTransforms]
  ) -> FloatQuad {
    var wasFixed: Bool? = nil
    return localToContainerQuad(
      localQuad: localQuad, container: container, mode: mode, wasFixed: &wasFixed)
  }

  private func localToContainerQuad(
    localQuad: FloatQuad, container: RenderLayerModelObjectWrapper?, mode: MapCoordinatesMode,
    wasFixed: inout Bool?
  ) -> FloatQuad {
    // Track the point at the center of the quad's bounding box. As mapLocalToContainer() calls offsetFromContainer(),
    // it will use that point as the reference point to decide which column's transform to apply in multiple-column blocks.
    let transformState = TransformState(
      .ApplyTransformDirection, localQuad.boundingBox().center(), localQuad)
    mapLocalToContainer(container, transformState, mode.union(.ApplyContainerFlip), &wasFixed)
    transformState.flatten()

    return transformState.lastPlanarQuad()
  }

  func localToContainerPoint(
    localPoint: FloatPoint, container: RenderLayerModelObjectWrapper?, wasFixed: inout Bool?,
    mode: MapCoordinatesMode = .UseTransforms
  ) -> FloatPoint {
    let transformState = TransformState(.ApplyTransformDirection, localPoint)
    mapLocalToContainer(container, transformState, mode.union(.ApplyContainerFlip), &wasFixed)
    transformState.flatten()

    return transformState.lastPlanarPoint()
  }

  func localToContainerPoint(localPoint: FloatPoint, container: RenderLayerModelObjectWrapper?)
    -> FloatPoint
  {
    var wasFixed: Bool? = nil
    return localToContainerPoint(localPoint: localPoint, container: container, wasFixed: &wasFixed)
  }

  // Return the offset from the container() renderer (excluding transforms). In multi-column layout,
  // different offsets apply at different points, so return the offset that applies to the given point.
  func offsetFromContainer(
    _ container: RenderElementWrapper, _ physicalPoint: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    assert(CPtrToInt(container.id()) == CPtrToInt(self.container()?.id()))

    var offset = LayoutSizeWrapper()
    if let box = container as? RenderBoxWrapper {
      offset -= toLayoutSize(point: LayoutPointWrapper(point: box.scrollPosition()))
    }

    if offsetDependsOnPoint != nil {
      offsetDependsOnPoint = container is RenderFragmentedFlowWrapper
    }

    return offset
  }

  // Return the offset from an object up the container() chain. Asserts that none of the intermediate objects have transforms.
  func offsetFromAncestorContainer(_ container: RenderElementWrapper) -> LayoutSizeWrapper {
    var offset = LayoutSizeWrapper()
    var referencePoint = LayoutPointWrapper()
    var currentContainer = self
    repeat {
      let nextContainer = currentContainer.container()!
      assert(!currentContainer.isTransformed())
      var unused: Bool? = nil
      let currentOffset = currentContainer.offsetFromContainer(
        nextContainer, referencePoint, &unused)
      offset += currentOffset
      referencePoint.move(s: currentOffset)
      currentContainer = nextContainer
    } while CPtrToInt(currentContainer.id()) != CPtrToInt(container.id())

    return offset
  }

  func minPreferredLogicalWidth() -> LayoutUnit {
    assert(!isNativeImpl())
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderObject_minPreferredLogicalWidth(id()))
  }

  func maxPreferredLogicalWidth() -> LayoutUnit {
    assert(!isNativeImpl())
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderObject_maxPreferredLogicalWidth(id()))
  }

  func markContainingBlocksForLayout(layoutRoot: RenderElementWrapper? = nil)
    -> RenderElementWrapper?
  {
    assert(!isSetNeedsLayoutForbidden())
    if self is RenderViewWrapper {
      return self as! RenderElementWrapper?
    }

    var ancestor = container()

    var simplifiedNormalFlowLayout =
      needsSimplifiedNormalFlowLayout() && !selfNeedsLayout() && !normalChildNeedsLayout()
    var hasOutOfFlowPosition = isOutOfFlowPositioned()

    while ancestor != nil {
      // TODO(asuhan): SetLayoutNeededForbiddenScope

      // Don't mark the outermost object of an unrooted subtree. That object will be
      // marked when the subtree is added to the document.
      var container = ancestor!.container()
      if container == nil && !ancestor!.isRenderView() {
        // Internal render tree shuffle.
        return nil
      }

      if hasOutOfFlowPosition {
        let willSkipRelativelyPositionedInlines =
          !ancestor!.isRenderBlock() || ancestor!.isAnonymousBlock()
        // Skip relatively positioned inlines and anonymous blocks to get to the enclosing RenderBlock.
        while ancestor != nil && (!ancestor!.isRenderBlock() || ancestor!.isAnonymousBlock()) {
          ancestor = ancestor!.container()
        }
        if ancestor == nil || ancestor!.posChildNeedsLayout() {
          return nil
        }
        if willSkipRelativelyPositionedInlines {
          container = ancestor!.container()
        }
        ancestor!.setPosChildNeedsLayoutBit(b: true)
        simplifiedNormalFlowLayout = true
      } else if simplifiedNormalFlowLayout {
        if ancestor!.needsSimplifiedNormalFlowLayout() {
          return nil
        }
        ancestor!.setNeedsSimplifiedNormalFlowLayoutBit(b: true)
      } else {
        if ancestor!.normalChildNeedsLayout() {
          return nil
        }
        ancestor!.setNormalChildNeedsLayoutBit(b: true)
      }
      assert(!ancestor!.isSetNeedsLayoutForbidden())

      if layoutRoot != nil {
        // Having a valid layout root also mean we should not stop at layout boundaries.
        if CPtrToInt(ancestor!.id()) == CPtrToInt(layoutRoot!.id()) {
          return layoutRoot
        }
      } else if objectIsRelayoutBoundary(object: ancestor!) {
        return ancestor
      }

      hasOutOfFlowPosition = ancestor!.isOutOfFlowPositioned()
      if hasOutOfFlowPosition {
        setIsSimplifiedLayoutRootForLayerIfApplicable(renderElement: ancestor!)
      }
      ancestor = container
    }
    return nil
  }

  func setNeedsLayout(markParents: MarkingBehavior = .MarkContainingBlockChain) {
    assert(!isNativeImpl())
    wk_interop.RenderObject_setNeedsLayout(id(), markParents.rawValue)
  }

  enum HadSkippedLayout {
    case No
    case Yes
  }

  func clearNeedsLayout(hadSkippedLayout: HadSkippedLayout = .No) {
    // FIXME: Consider not setting the "ever had layout" bit to true when "hadSkippedLayout"
    setEverHadLayout()
    setHadSkippedLayout(hadSkippedLayout == .Yes)

    if let renderElement = self as? RenderElementWrapper {
      renderElement.setLayoutIdentifier(
        renderElement.view().frameView().layoutContext().layoutIdentifier())
    }
    m_stateBitfields.clearFlag(.NeedsLayout)
    setPosChildNeedsLayoutBit(b: false)
    setNeedsSimplifiedNormalFlowLayoutBit(b: false)
    setNormalChildNeedsLayoutBit(b: false)
    setOutOfFlowChildNeedsStaticPositionLayoutBit(b: false)
    setNeedsPositionedMovementLayoutBit(b: false)
    #if ASSERT_ENABLED
      checkBlockPositionedObjectsNeedLayout()
    #endif
  }

  func setNeedsLayoutAndPrefWidthsRecalc() {
    setNeedsLayout()
    setPreferredLogicalWidthsDirty(shouldBeDirty: true)
  }

  func setPositionState(_ position: PositionType) {
    assert(isNativeImpl())
    assert((position != .Absolute && position != .Fixed) || isRenderBox())
    m_stateBitfields.setPositionedState(position)
  }

  func clearPositionedState() {
    assert(isNativeImpl())
    m_stateBitfields.clearPositionedState()
  }

  func setFloating(_ b: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.Floating, b)
  }

  func setInline(_ b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.IsBlock, !b)
  }

  func setHasVisibleBoxDecorations(_ b: Bool = true) {
    assert(isNativeImpl())
    if !b {
      m_stateBitfields.setBoxDecorationState(.None)
      return
    }
    if hasVisibleBoxDecorations() {
      return
    }
    m_stateBitfields.setBoxDecorationState(.InvalidObscurationStatus)
  }

  func invalidateBackgroundObscurationStatus() {
    if !hasVisibleBoxDecorations() {
      return
    }
    m_stateBitfields.setBoxDecorationState(.InvalidObscurationStatus)
  }

  func computeBackgroundIsKnownToBeObscured(_ paintOffset: LayoutPointWrapper) -> Bool {
    return false
  }

  func setReplacedOrInlineBlock(_ b: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.IsReplacedOrInlineBlock, b)
  }

  func setHorizontalWritingMode(_ b: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.VerticalWritingMode, !b)
  }

  func setHasNonVisibleOverflow(_ b: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.HasNonVisibleOverflow, b)
  }

  func setHasLayer(_ b: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.HasLayer, b)
  }

  func setHasTransformRelatedProperty(_ b: Bool = true) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.HasTransformRelatedProperty, b)
  }

  func setHasReflection(_ hasReflection: Bool = true) {
    if hasReflection || hasRareData() {
      ensureRareData().hasReflection = hasReflection
    }
  }

  func hitTest(
    request: HitTestRequestWrapper, result: HitTestResultWrapper,
    locationInContainer: HitTestLocationWrapper, accumulatedOffset: LayoutPointWrapper,
    hitTestFilter: HitTestFilter = .HitTestAll
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func protectedNodeForHitTest() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateHitTestResult(result: HitTestResultWrapper, point: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    assert(isNativeImpl())
    return createVisiblePosition(caretMinOffset(), .Downstream)
  }

  func createVisiblePosition(_ offset: Int32, _ affinity: Affinity) -> VisiblePosition {
    // If this is a non-anonymous renderer in an editable area, then it's simple.
    if let node = nonPseudoNode() {
      if !node.hasEditableStyle() {
        // If it can be found, we prefer a visually equivalent position that is editable.
        let position = makeDeprecatedLegacyPosition(node, UInt32(offset))
        var candidate = position.downstream(.CanCrossEditingBoundary)
        if candidate.deprecatedNode()!.hasEditableStyle() {
          return VisiblePosition(candidate, affinity)
        }
        candidate = position.upstream(.CanCrossEditingBoundary)
        if candidate.deprecatedNode()!.hasEditableStyle() {
          return VisiblePosition(candidate, affinity)
        }
      }
      // FIXME: Eliminate legacy editing positions
      return VisiblePosition(makeDeprecatedLegacyPosition(node, UInt32(offset)), affinity)
    }

    // We don't want to cross the boundary between editable and non-editable
    // regions of the document, but that is either impossible or at least
    // extremely unlikely in any normal case because we stop as soon as we
    // find a single non-anonymous renderer.

    // Find a nearby non-anonymous renderer.
    var child: RenderObjectWrapper? = self
    while true {
      let parent = child!.parent()
      if parent == nil {
        break
      }
      // Find non-anonymous content after.
      var renderer = child
      while true {
        renderer = renderer!.nextInPreOrder(stayWithin: parent)
        if renderer == nil {
          break
        }
        if let node = renderer!.nonPseudoNode() {
          return VisiblePosition(firstPositionInOrBeforeNode(node))
        }
      }

      // Find non-anonymous content before.
      renderer = child
      while true {
        renderer = renderer!.previousInPreOrder()
        if renderer == nil || CPtrToInt(renderer!.id()) == CPtrToInt(parent!.id()) {
          break
        }
        if let node = renderer!.nonPseudoNode() {
          return VisiblePosition(lastPositionInOrAfterNode(node))
        }
      }

      // Use the parent itself unless it too is anonymous.
      if let element = parent!.nonPseudoElement() {
        return VisiblePosition(firstPositionInOrBeforeNode(element))
      }

      // Repeat at the next level up.
      child = parent
    }

    // Everything was anonymous. Give up.
    return VisiblePosition()
  }

  func createVisiblePosition(_ position: Position) -> VisiblePosition {
    if position.isNotNull() {
      return VisiblePosition(position)
    }

    assert(node() == nil)
    return createVisiblePosition(0, .Downstream)
  }

  func containingBlock() -> RenderBlockWrapper? {
    assert(!isNativeImpl())
    if let unwrapped = wk_interop.RenderObject_containingBlock(id()) {
      // TODO(asuhan): decide the type correctly
      if wk_interop.RenderObject_isRenderListItem(unwrapped) {
        return RenderListItemWrapper(p: unwrapped)
      }
      return RenderBlockWrapper(p: unwrapped)
    }
    return nil
  }

  static func containingBlockForPositionType(
    positionType: PositionType, renderer: RenderObjectWrapper
  )
    -> RenderBlockWrapper?
  {
    if positionType == .Static || positionType == .Relative || positionType == .Sticky {
      var ancestor = renderer.parent()
      while ancestor != nil
        && ((ancestor!.isInline() && !ancestor!.isReplacedOrInlineBlock())
          || !ancestor!.isRenderBlock())
      {
        ancestor = ancestor!.parent()
      }
      return ancestor as! RenderBlockWrapper?
    }

    if positionType == .Absolute {
      if renderer is RenderInlineWrapper && renderer.style().position() == .Relative {
        // A relatively positioned RenderInline forwards its absolute positioned descendants to
        // its nearest non-anonymous containing block (to avoid having positioned objects list in RenderInlines).
        return nearestNonAnonymousContainingBlockIncludingSelf(renderer: renderer.parent())
      }
      var ancestor = renderer.parent()
      while ancestor != nil && !ancestor!.canContainAbsolutelyPositionedObjects() {
        ancestor = ancestor!.parent()
      }
      // Make sure we only return non-anonymous RenderBlock as containing block.
      return nearestNonAnonymousContainingBlockIncludingSelf(renderer: ancestor)
    }

    if positionType == .Fixed {
      var ancestor = renderer.parent()
      while ancestor != nil && !ancestor!.canContainFixedPositionObjects() {
        if isInTopLayerOrBackdrop(style: ancestor!.style(), element: ancestor!.element()) {
          return renderer.view()
        }
        ancestor = ancestor!.parent()
      }
      return nearestNonAnonymousContainingBlockIncludingSelf(renderer: ancestor)
    }

    fatalError("Not reached")
  }

  // Convert the given local point to absolute coordinates. If OptionSet<MapCoordinatesMode> includes UseTransforms, take transforms into account.
  func localToAbsolute(
    localPoint: FloatPoint = FloatPoint(), mode: MapCoordinatesMode = MapCoordinatesMode()
  ) -> FloatPoint {
    var unused: Bool? = nil
    return localToAbsolute(localPoint, mode, &unused)
  }

  private func localToAbsolute(
    _ localPoint: FloatPoint, _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) -> FloatPoint {
    assert(isNativeImpl())
    let transformState = TransformState(.ApplyTransformDirection, localPoint)
    mapLocalToContainer(nil, transformState, mode.union(.ApplyContainerFlip), &wasFixed)
    transformState.flatten()

    return transformState.lastPlanarPoint()
  }

  func style() -> RenderStyleWrapper {
    if !isNativeImpl() {
      return convert_render_style(p: wk_interop.RenderObject_style(id()))
    }
    if isRenderText() {
      return m_parent!.style()
    }
    return (self as! RenderElementWrapper).elementStyle()
  }

  func firstLineStyle() -> RenderStyleWrapper {
    if isRenderText() {
      return m_parent!.firstLineStyle()
    }
    return (self as! RenderElementWrapper).firstLineStyle()
  }

  // Anonymous blocks that are part of of a continuation chain will return their inline continuation's outline style instead.
  // This is typically only relevant when repainting.
  func outlineStyleForRepaint() -> RenderStyleWrapper {
    assert(isNativeImpl())
    return style()
  }

  // Return the RenderLayerModelObject in the container chain which is responsible for painting this object, or nullptr
  // if painting is root-relative. This is the container that should be passed to the 'forRepaint' functions.
  struct RepaintContainerStatus {
    let fullRepaintIsScheduled: Bool  // Either the repaint container or a layer in-between has already been scheduled for full repaint.
    let renderer: RenderLayerModelObjectWrapper?
  }

  func containerForRepaint() -> RepaintContainerStatus {
    var repaintContainer: RenderLayerModelObjectWrapper? = nil
    var fullRepaintAlreadyScheduled = false

    if view().usesCompositing(), let parentLayer = enclosingLayer() {
      let compLayerStatus = parentLayer.enclosingCompositingLayerForRepaint()
      if compLayerStatus.layer != nil {
        repaintContainer = compLayerStatus.layer!.renderer()
        fullRepaintAlreadyScheduled =
          compLayerStatus.fullRepaintAlreadyScheduled
          && canRelyOnAncestorLayerFullRepaint(self, compLayerStatus.layer!)
      }
    }
    if view().hasSoftwareFilters(), let parentLayer = enclosingLayer(),
      let enclosingFilterLayer = parentLayer.enclosingFilterLayer()
    {
      fullRepaintAlreadyScheduled =
        parentLayer.needsFullRepaint() && canRelyOnAncestorLayerFullRepaint(self, parentLayer)
      return RepaintContainerStatus(
        fullRepaintIsScheduled: fullRepaintAlreadyScheduled,
        renderer: enclosingFilterLayer.renderer())
    }

    // If we have a flow thread, then we need to do individual repaints within the RenderFragmentContainers instead.
    // Return the flow thread as a repaint container in order to create a chokepoint that allows us to change
    // repainting to do individual region repaints.
    if let parentRenderFragmentedFlow = enclosingFragmentedFlow() {
      // If we have already found a repaint container then we will repaint into that container only if it is part of the same
      // flow thread. Otherwise we will need to catch the repaint call and send it to the flow thread.
      let repaintContainerFragmentedFlow = repaintContainer?.enclosingFragmentedFlow()
      if repaintContainerFragmentedFlow == nil
        || CPtrToInt(repaintContainerFragmentedFlow!.id())
          != CPtrToInt(parentRenderFragmentedFlow.id())
      {
        repaintContainer = parentRenderFragmentedFlow
      }
    }
    return RepaintContainerStatus(
      fullRepaintIsScheduled: fullRepaintAlreadyScheduled, renderer: repaintContainer)
  }

  // Actually do the repaint of rect r for this object which has been computed in the coordinate space
  // of repaintContainer. If repaintContainer is nullptr, repaint via the view.
  func repaintUsingContainer(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ r: LayoutRectWrapper,
    _ shouldClipToLayer: Bool = true
  ) {
    if r.isEmpty() {
      return
    }

    var repaintContainer = repaintContainer
    if repaintContainer == nil {
      repaintContainer = view()
    }

    if let fragmentedFlow = repaintContainer as? RenderFragmentedFlowWrapper {
      fragmentedFlow.repaintRectangleInFragments(r)
      return
    }

    propagateRepaintToParentWithOutlineAutoIfNeeded(repaintContainer!, r)

    if repaintContainer!.hasFilter() && repaintContainer!.layer() != nil
      && repaintContainer!.layer()!.requiresFullLayerImageForFilters()
    {
      repaintContainer!.checkedLayer()!.setFilterBackendNeedsRepaintingInRect(r)
      return
    }

    if repaintContainer!.isRenderView() {
      let view = view()
      assert(CPtrToInt(repaintContainer!.id()) == CPtrToInt(view.id()))
      let viewHasCompositedLayer = view.isComposited()
      if !viewHasCompositedLayer || view.layer()!.backing!.paintsIntoWindow() {
        var rect = r
        if viewHasCompositedLayer && view.layer()!.transform != nil {
          rect = LayoutRectWrapper(
            r: view.layer()!.transform!.mapRect(
              snapRectToDevicePixels(
                rect: rect, pixelSnappingFactor: document().deviceScaleFactor())))
        }
        view.repaintViewRectangle(rect)
        return
      }
    }

    if view().usesCompositing() {
      assert(repaintContainer!.isComposited())
      repaintContainer!.checkedLayer()!.setBackingNeedsRepaintInRect(
        r: r, shouldClip: shouldClipToLayer ? .ClipToLayer : .DoNotClipToLayer)
    }
  }

  // Repaint the entire object.  Called when, e.g., the color of a border changes, or when a border
  // style changes.
  enum ForceRepaint {
    case No
    case Yes
  }

  func repaint(forceRepaint: ForceRepaint = .No) {
    assert(
      isDescendantOf(ancestor: view()) || self is RenderScrollbarPartWrapper
        || self is RenderReplicaWrapper)

    if view().printing() {
      return
    }
    issueRepaint(nil, .No, forceRepaint)
  }

  // Repaint a specific subrectangle within a given object. The rect |r| is in the object's coordinate space.
  func repaintRectangle(repaintRect: LayoutRectWrapper, shouldClipToLayer: Bool = true) {
    assert(isDescendantOf(ancestor: view()) || self is RenderScrollbarPartWrapper)
    return repaintRectangle(repaintRect, shouldClipToLayer ? .Yes : .No, .No)
  }

  enum ClipRepaintToLayer {
    case No
    case Yes
  }

  private func repaintRectangle(
    _ repaintRect: LayoutRectWrapper, _ shouldClipToLayer: ClipRepaintToLayer,
    _ forceRepaint: ForceRepaint, _ additionalRepaintOutsets: LayoutBoxExtent? = nil
  ) {
    assert(
      isDescendantOf(ancestor: view()) || self is RenderScrollbarPartWrapper
        || self is RenderReplicaWrapper)

    if view().printing() {
      return
    }
    // FIXME: layoutDelta needs to be applied in parts before/after transforms and
    // repaint containers. https://bugs.webkit.org/show_bug.cgi?id=23308
    var dirtyRect = repaintRect
    dirtyRect.move(size: view().frameView().layoutContext().layoutDelta())
    issueRepaint(dirtyRect, shouldClipToLayer, forceRepaint, additionalRepaintOutsets)
  }

  struct VisibleRectContextOption: OptionSet {
    let rawValue: UInt8

    static let UseEdgeInclusiveIntersection = VisibleRectContextOption(rawValue: 1 << 0)
    static let ApplyCompositedClips = VisibleRectContextOption(rawValue: 1 << 1)
    static let ApplyCompositedContainerScrolls = VisibleRectContextOption(rawValue: 1 << 2)
    static let ApplyContainerClip = VisibleRectContextOption(rawValue: 1 << 3)
    static let CalculateAccurateRepaintRect = VisibleRectContextOption(rawValue: 1 << 4)
  }

  struct VisibleRectContext {
    init(
      hasPositionFixedDescendant: Bool = false, dirtyRectIsFlipped: Bool = false,
      _ options: VisibleRectContextOption = []
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func repaintRectCalculation() -> RepaintRectCalculation {
      return options.contains(.CalculateAccurateRepaintRect) ? .Accurate : .Fast
    }

    var hasPositionFixedDescendant: Bool
    var dirtyRectIsFlipped: Bool
    var descendantNeedsEnclosingIntRect: Bool
    var options: VisibleRectContextOption
  }

  struct RepaintRects: Equatable {
    var clippedOverflowRect: LayoutRectWrapper  // Some rect (normally the visual overflow rect) mapped up to the repaint container, respecting clipping.
    var outlineBoundsRect: LayoutRectWrapper?  // A rect repsenting the extent of outlines and shadows, mapped to the repaint container, but not clipped.

    init(rect: LayoutRectWrapper = LayoutRectWrapper(), outlineBounds: LayoutRectWrapper? = nil) {
      clippedOverflowRect = rect
      outlineBoundsRect = outlineBounds
    }

    mutating func move(_ size: LayoutSizeWrapper) {
      clippedOverflowRect.move(size: size)
      outlineBoundsRect?.move(size: size)
    }

    mutating func moveBy(_ size: LayoutPointWrapper) {
      clippedOverflowRect.moveBy(offset: size)
      outlineBoundsRect?.moveBy(offset: size)
    }

    mutating func expand(_ size: LayoutSizeWrapper) {
      clippedOverflowRect.expand(size: size)
      outlineBoundsRect?.expand(size: size)
    }

    mutating func encloseToIntRects() {
      clippedOverflowRect = LayoutRectWrapper(rect: enclosingIntRect(rect: clippedOverflowRect))
      if outlineBoundsRect != nil {
        outlineBoundsRect = LayoutRectWrapper(rect: enclosingIntRect(rect: outlineBoundsRect!))
      }
    }

    mutating func unite(_ other: RepaintRects) {
      clippedOverflowRect.unite(other: other.clippedOverflowRect)
      if outlineBoundsRect != nil && other.outlineBoundsRect != nil {
        outlineBoundsRect!.unite(other: other.outlineBoundsRect!)
      }
    }

    mutating func flipForWritingMode(
      _ containerSize: LayoutSizeWrapper, _ isHorizontalWritingMode: Bool
    ) {
      if isHorizontalWritingMode {
        clippedOverflowRect.setY(y: containerSize.height() - clippedOverflowRect.maxY())
        if outlineBoundsRect != nil {
          outlineBoundsRect!.setY(y: containerSize.height() - outlineBoundsRect!.maxY())
        }
      } else {
        clippedOverflowRect.setX(x: containerSize.width() - clippedOverflowRect.maxX())
        if outlineBoundsRect != nil {
          outlineBoundsRect!.setX(x: containerSize.width() - outlineBoundsRect!.maxX())
        }
      }
    }

    // Returns true if intersecting (clippedOverflowRect remains non-empty).
    mutating func intersect(_ clipRect: LayoutRectWrapper) -> Bool {
      // Note the we only intersect clippedOverflowRect.
      clippedOverflowRect.intersect(other: clipRect)
      return !clippedOverflowRect.isEmpty()
    }

    // Returns true if intersecting (clippedOverflowRect remains non-empty).
    func edgeInclusiveIntersect(_ clipRect: LayoutRectWrapper) -> Bool {
      // Note the we only intersect clippedOverflowRect.
      return clippedOverflowRect.edgeInclusiveIntersect(clipRect)
    }

    mutating func transform(_ matrix: TransformationMatrix) {
      clippedOverflowRect = matrix.mapRect(clippedOverflowRect)
      if outlineBoundsRect != nil {
        outlineBoundsRect = matrix.mapRect(outlineBoundsRect!)
      }
    }

    mutating func transform(_ matrix: TransformationMatrix, _ deviceScaleFactor: Float32) {
      let identicalRects = outlineBoundsRect != nil && outlineBoundsRect! == clippedOverflowRect
      clippedOverflowRect = LayoutRectWrapper(
        r: encloseRectToDevicePixels(
          rect: matrix.mapRect(clippedOverflowRect), pixelSnappingFactor: deviceScaleFactor))
      if identicalRects {
        outlineBoundsRect = clippedOverflowRect
      } else if outlineBoundsRect != nil {
        outlineBoundsRect = LayoutRectWrapper(
          r: encloseRectToDevicePixels(
            rect: matrix.mapRect(outlineBoundsRect!), pixelSnappingFactor: deviceScaleFactor))
      }
    }
  }

  // Returns the rect that should be repainted whenever this object changes. The rect is in the view's
  // coordinate space. This method deals with outlines and overflow.
  func absoluteClippedOverflowRectForRepaint() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return clippedOverflowRect(nil, RenderObjectWrapper.visibleRectContextForRepaint)
  }

  func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    let repaintRects = localRectsForRepaint(.No)
    if repaintRects.clippedOverflowRect.isEmpty() {
      return LayoutRectWrapper()
    }

    return computeRects(repaintRects, repaintContainer, context).clippedOverflowRect
  }

  func clippedOverflowRectForRepaint(_ repaintContainer: RenderLayerModelObjectWrapper?)
    -> LayoutRectWrapper
  {
    return clippedOverflowRect(repaintContainer, RenderObjectWrapper.visibleRectContextForRepaint)
  }

  func rectWithOutlineForRepaint(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ outlineWidth: LayoutUnit
  ) -> LayoutRectWrapper {
    var r = clippedOverflowRectForRepaint(repaintContainer)
    r.inflate(d: outlineWidth)
    return r
  }

  func outlineBoundsForRepaint(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap? = nil
  )
    -> LayoutRectWrapper
  {
    return LayoutRectWrapper()
  }

  // Given a rect in the object's coordinate space, compute a rect  in the coordinate space
  // of repaintContainer suitable for the given VisibleRectContext.
  func computeRects(
    _ rects: RepaintRects, _ repaintContainer: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects {
    return computeVisibleRectsInContainer(rects, repaintContainer, context)!
  }

  func computeRectForRepaint(
    rect: LayoutRectWrapper, repaintContainer: RenderLayerModelObjectWrapper?
  ) -> LayoutRectWrapper {
    let repaintRects = RepaintRects(rect: rect)
    return computeRects(
      repaintRects, repaintContainer, RenderObjectWrapper.visibleRectContextForRepaint
    ).clippedOverflowRect
  }

  func computeFloatRectForRepaint(
    _ rect: FloatRectWrapper, _ repaintContainer: RenderLayerModelObjectWrapper?
  ) -> FloatRectWrapper {
    return computeFloatVisibleRectInContainer(
      rect, repaintContainer, RenderObjectWrapper.visibleRectContextForRepaint)!
  }

  func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    let localRects = localRectsForRepaint(repaintOutlineBounds)
    if localRects.clippedOverflowRect.isEmpty() {
      return RepaintRects()
    }

    var result = computeRects(
      localRects, repaintContainer, RenderObjectWrapper.visibleRectContextForRepaint)
    if result.outlineBoundsRect != nil {
      result.outlineBoundsRect = LayoutRectWrapper(
        r: snapRectToDevicePixels(
          rect: result.outlineBoundsRect!, pixelSnappingFactor: document().deviceScaleFactor()))
    }

    return result
  }

  // Given a rect in the object's coordinate space, compute the location in container space where this rect is visible,
  // when clipping and scrolling as specified by the context. When using edge-inclusive intersection, return std::nullopt
  // rather than an empty rect if the rect is completely clipped out in container space.
  func computeVisibleRectsInContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    if CPtrToInt(container?.id()) == CPtrToInt(id()) {
      return rects
    }

    guard let parent = parent() else { return rects }

    var adjustedRects = rects
    if parent.hasNonVisibleOverflow() {
      let isEmpty = !(parent as! RenderLayerModelObjectWrapper).applyCachedClipAndScrollPosition(
        &adjustedRects, container, context)
      if isEmpty {
        if context.options.contains(.UseEdgeInclusiveIntersection) {
          return nil
        }
        return adjustedRects
      }
    }
    return parent.computeVisibleRectsInContainer(adjustedRects, container, context)
  }

  func computeFloatVisibleRectInContainer(
    _ rect: FloatRectWrapper, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> FloatRectWrapper? {
    fatalError("Not reached")
  }

  func isFloatingOrOutOfFlowPositioned() -> Bool {
    return isFloating() || isOutOfFlowPositioned()
  }

  func isInFlow() -> Bool { return !isFloatingOrOutOfFlowPositioned() }

  enum HighlightState: UInt8 {
    case None  // The object is not selected.
    case Start  // The object either contains the start of a selection run or is the start of a run
    case Inside  // The object is fully encompassed by a selection run
    case End  // The object either contains the end of a selection run or is the end of a run
    case Both  // The object contains an entire run or is the sole selected object in that run
  }

  // The current selection state for an object.  For blocks, the state refers to the state of the leaf
  // descendants (as described above in the HighlightState enum declaration).
  func selectionState() -> HighlightState {
    assert(isNativeImpl())
    return m_stateBitfields.selectionState()
  }

  func canBeSelectionLeaf() -> Bool { return false }

  // When performing a global document tear-down, or when going into the back/forward cache, the renderer of the document is cleared.
  func renderTreeBeingDestroyed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Virtual function helpers for the deprecated Flexible Box Layout (display: -webkit-box).
  func isRenderDeprecatedFlexibleBox() -> Bool {
    assert(isNativeImpl())
    return m_type == .DeprecatedFlexibleBox
  }

  // Virtual function helper for the new FlexibleBox Layout (display: -webkit-flex).
  func isRenderFlexibleBox() -> Bool {
    assert(isNativeImpl())
    return m_typeFlags.contains(.IsFlexibleBox)
  }

  func isFlexibleBoxIncludingDeprecated() -> Bool {
    return isRenderFlexibleBox() || isRenderDeprecatedFlexibleBox()
  }

  func caretMinOffset() -> Int32 { return 0 }

  func caretMaxOffset() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Map points and quads through elements, potentially via 3d transforms. You should never need to call these directly; use
  // localToAbsolute/absoluteToLocal methods instead.
  func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    if CPtrToInt(ancestorContainer?.id()) == CPtrToInt(id()) {
      return
    }

    guard let parent = parent() else { return }

    // FIXME: this should call offsetFromContainer to share code, but I'm not sure it's ever called.
    let centerPoint = LayoutPointWrapper(size: transformState.mappedPoint())
    var mode = mode
    if let parentAsBox = parent as? RenderBoxWrapper {
      if mode.contains(.ApplyContainerFlip) {
        if parentAsBox.style().isFlippedBlocksWritingMode() {
          transformState.move(
            parentAsBox.flipForWritingMode(
              position: LayoutPointWrapper(size: transformState.mappedPoint()))
              - centerPoint)
        }
        mode.remove(.ApplyContainerFlip)
      }
      transformState.move(
        -toLayoutSize(point: LayoutPointWrapper(point: parentAsBox.scrollPosition())))
    }

    parent.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixed)
  }

  func mapAbsoluteToLocalPoint(_ mode: MapCoordinatesMode, _ transformState: inout TransformState) {
    if let parent = parent() {
      parent.mapAbsoluteToLocalPoint(mode, &transformState)
      if let box = parent as? RenderBoxWrapper {
        transformState.move(toLayoutSize(point: LayoutPointWrapper(point: box.scrollPosition())))
      }
    }
  }

  // Pushes state onto RenderGeometryMap about how to map coordinates from this renderer to its container, or ancestorToStopAt (whichever is encountered first).
  // Returns the renderer which was mapped to (container or ancestorToStopAt).
  func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    assert(CPtrToInt(ancestorToStopAt?.id()) != CPtrToInt(id()))

    let container = parent()
    if container == nil {
      return nil
    }

    // FIXME: this should call offsetFromContainer to share code, but I'm not sure it's ever called.
    var offset = LayoutSizeWrapper()
    if let box = container as? RenderBoxWrapper {
      offset = -toLayoutSize(point: LayoutPointWrapper(point: box.scrollPosition()))
    }

    geometryMap.push(self, offset, accumulatingTransform: false)

    return container
  }

  func shouldUseTransformFromContainer(_ containerObject: RenderObjectWrapper?) -> Bool {
    if isTransformed() {
      return true
    }
    if containerObject?.style().hasPerspective() ?? false {
      return CPtrToInt(containerObject!.id()) == CPtrToInt(parent()?.id())
    }
    return false
  }

  // FIXME: Now that it's no longer passed a container maybe this should be renamed?
  func getTransformFromContainer(_ offsetInContainer: LayoutSizeWrapper) -> TransformationMatrix {
    var transform = TransformationMatrix()
    transform.makeIdentity()
    transform.translate(
      tx: offsetInContainer.width().double(), ty: offsetInContainer.height().double())
    var layer: RenderLayerWrapper? = nil
    if hasLayer() {
      layer = (self as! RenderLayerModelObjectWrapper).layer()
      if layer?.transform != nil {
        transform.multiply(mat: layer!.currentTransform())
      }
    }

    if let perspectiveObject = parent(),
      perspectiveObject.hasLayer() && perspectiveObject.style().hasPerspective()
    {
      // Perpsective on the container affects us, so we have to factor it in here.
      assert(perspectiveObject.hasLayer())
      let perspectiveOrigin = (perspectiveObject as! RenderLayerModelObjectWrapper).layer()!
        .perspectiveOrigin()

      let perspectiveMatrix = TransformationMatrix()
      perspectiveMatrix.applyPerspective(Float64(perspectiveObject.style().usedPerspective()))

      transform.translateRight3d(
        tx: Float64(-perspectiveOrigin.x), ty: Float64(-perspectiveOrigin.y), tz: 0)
      transform = perspectiveMatrix * transform
      transform.translateRight3d(
        tx: Float64(perspectiveOrigin.x), ty: Float64(perspectiveOrigin.y), tz: 0)
    }
    return transform
  }

  func pushOntoTransformState(
    _ transformState: TransformState, _ mode: MapCoordinatesMode,
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ container: RenderElementWrapper?,
    _ offsetInContainer: LayoutSizeWrapper, _ containerSkipped: Bool
  ) {
    let preserve3D = mode.contains(.UseTransforms) && participatesInPreserve3D()
    if mode.contains(.UseTransforms) && shouldUseTransformFromContainer(container) {
      let matrix = getTransformFromContainer(offsetInContainer)
      transformState.applyTransform(matrix, preserve3D ? .AccumulateTransform : .FlattenTransform)
    } else {
      transformState.move(
        offsetInContainer.width(), offsetInContainer.height(),
        preserve3D ? .AccumulateTransform : .FlattenTransform)
    }

    if containerSkipped {
      // There can't be a transform between repaintContainer and container, because transforms create containers, so it should be safe
      // to just subtract the delta between the repaintContainer and container.
      let containerOffset = repaintContainer!.offsetFromAncestorContainer(container!)
      transformState.move(
        -containerOffset.width(), -containerOffset.height(),
        preserve3D ? .AccumulateTransform : .FlattenTransform)
    }
  }

  func pushOntoGeometryMap(
    _ geometryMap: RenderGeometryMap, _ repaintContainer: RenderLayerModelObjectWrapper?,
    _ container: RenderElementWrapper?, _ containerSkipped: Bool
  ) {
    let isFixedPos = isFixedPositioned()
    var adjustmentForSkippedAncestor = LayoutSizeWrapper()
    if containerSkipped {
      // There can't be a transform between repaintContainer and container, because transforms create containers, so it should be safe
      // to just subtract the delta between the ancestor and container.
      adjustmentForSkippedAncestor = -repaintContainer!.offsetFromAncestorContainer(container!)
    }

    var offsetDependsOnPoint: Bool? = false
    var containerOffset = offsetFromContainer(
      container!, LayoutPointWrapper(), &offsetDependsOnPoint)

    let preserve3D = participatesInPreserve3D()
    if shouldUseTransformFromContainer(container)
      && geometryMap.mapCoordinatesFlags.contains(.UseTransforms)
    {
      let t = getTransformFromContainer(containerOffset)
      t.translateRight(
        tx: adjustmentForSkippedAncestor.width().double(),
        ty: adjustmentForSkippedAncestor.height().double())

      geometryMap.push(
        self, t, accumulatingTransform: preserve3D, isNonUniform: offsetDependsOnPoint!,
        isFixedPosition: isFixedPos, hasTransform: isTransformed())
    } else {
      containerOffset += adjustmentForSkippedAncestor
      geometryMap.push(
        self, containerOffset, accumulatingTransform: preserve3D,
        isNonUniform: offsetDependsOnPoint!, isFixedPosition: isFixedPos,
        hasTransform: isTransformed())
    }
  }

  func participatesInPreserve3D() -> Bool {
    return hasLayer()
      && (self as! RenderLayerModelObjectWrapper).layer()!.participatesInPreserve3D()
  }

  func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: Renderers should not need to be notified about internal reparenting (webkit.org/b/224143).
  func insertedIntoTree() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willBeRemovedFromTree() {
    // FIXME: We should ASSERT(isRooted()) but we have some out-of-order removals which would need to be fixed first.
    // Update cached boundaries in SVG renderers, if a child is removed.
    checkedParent()!.invalidateCachedBoundaries()
  }

  func resetFragmentedFlowStateOnRemoval() {
    assert(!renderTreeBeingDestroyed())

    if fragmentedFlowState() == .NotInsideFlow {
      return
    }

    if let renderElement = self as? RenderElementWrapper {
      renderElement.removeFromRenderFragmentedFlow()
      return
    }

    // A RenderFragmentedFlow is always considered to be inside itself, so it never has to change its state in response to parent changes.
    if isRenderFragmentedFlow() {
      return
    }

    setFragmentedFlowStateIncludingDescendants(state: .NotInsideFlow)
  }

  func initializeFragmentedFlowStateOnInsertion() {
    assert(parent() != nil)

    // A RenderFragmentedFlow is always considered to be inside itself, so it never has to change its state in response to parent changes.
    if isRenderFragmentedFlow() {
      return
    }

    let computedState = RenderObjectWrapper.computedFragmentedFlowState(self)
    if fragmentedFlowState() == computedState {
      return
    }

    setFragmentedFlowStateIncludingDescendants(
      state: computedState, skipDescendentFragmentedFlow: .No)
  }

  func addPDFURLRect(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSkippedContent() -> Bool {
    assert(isNativeImpl())
    return parent()?.style().hasSkippedContent() ?? false
  }

  func isSkippedContentForLayout() -> Bool {
    return isSkippedContent() && !view().frameView().layoutContext().needsSkippedContentLayout()
  }

  //////////////////////////////////////////
  // Helper functions. Dangerous to use!
  func setPreviousSibling(previous: RenderObjectWrapper?) {
    assert(isNativeImpl())
    m_previous = previous
  }

  func setNextSibling(next: RenderObjectWrapper?) {
    assert(isNativeImpl())
    m_next = next
  }

  func setParent(parent: RenderElementWrapper?) {
    assert(isNativeImpl())
    m_parent = parent
  }
  //////////////////////////////////////////

  func nodeForNonAnonymous() -> NodeWrapper {
    assert(isNativeImpl())
    assert(!isAnonymous())
    return m_node!
  }

  func scheduleLayout(layoutRoot: RenderElementWrapper?) {
    if let renderView = layoutRoot as? RenderViewWrapper {
      return renderView.protectedFrameView().checkedLayoutContext().scheduleLayout()
    }

    if layoutRoot?.isRooted() ?? false {
      layoutRoot!.view().protectedFrameView().checkedLayoutContext().scheduleSubtreeLayout(
        layoutRoot!)
    }
  }

  func setNeedsPositionedMovementLayoutBit(b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.NeedsPositionedMovementLayout, b)
  }

  func setNormalChildNeedsLayoutBit(b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.NormalChildNeedsLayout, b)
  }

  func setPosChildNeedsLayoutBit(b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.PosChildNeedsLayout, b)
  }

  func setNeedsSimplifiedNormalFlowLayoutBit(b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.NeedsSimplifiedNormalFlowLayout, b)
  }

  func setOutOfFlowChildNeedsStaticPositionLayoutBit(b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.OutOfFlowChildNeedsStaticPositionLayout, b)
  }

  static func computedFragmentedFlowState(_ renderer: RenderObjectWrapper)
    -> FragmentedFlowState
  {
    if renderer.parent() == nil {
      return renderer.fragmentedFlowState()
    }

    if renderer is RenderMultiColumnFlowWrapper {
      // Multicolumn flows do not inherit the flow state.
      return .InsideFlow
    }

    var inheritedFlowState: FragmentedFlowState = .NotInsideFlow
    if renderer is RenderTextWrapper {
      inheritedFlowState = renderer.parent()!.fragmentedFlowState()
    } else if renderer is RenderSVGBlockWrapper || renderer is RenderSVGInlineWrapper
      || renderer is LegacyRenderSVGModelObject
    {
      // containingBlock() skips svg boundary (SVG root is a RenderReplaced).
      if let svgRoot = SVGRenderSupport.findTreeRootObject(start: renderer as! RenderElementWrapper)
      {
        inheritedFlowState = svgRoot.fragmentedFlowState()
      }
    } else if let container = renderer.container() {
      inheritedFlowState = container.fragmentedFlowState()
    } else {
      // Splitting lines or doing continuation, so just keep the current state.
      inheritedFlowState = renderer.fragmentedFlowState()
    }
    return inheritedFlowState
  }

  static let visibleRectContextForRepaint = VisibleRectContext(
    hasPositionFixedDescendant: false, dirtyRectIsFlipped: false,
    [.ApplyContainerClip, .ApplyCompositedContainerScrolls])

  func isSetNeedsLayoutForbidden() -> Bool {
    assert(isNativeImpl())
    #if ASSERT_ENABLED
      return m_setNeedsLayoutForbidden
    #else
      return false
    #endif  // ASSERT_ENABLED
  }

  func issueRepaint(
    _ partialRepaintRect: LayoutRectWrapper? = nil, _ clipRepaintToLayer: ClipRepaintToLayer = .No,
    _ forceRepaint: ForceRepaint = .No, _ additionalRepaintOutsets: LayoutBoxExtent? = nil
  ) {
    var repaintContainer = containerForRepaint()
    if repaintContainer.renderer == nil {
      repaintContainer = RepaintContainerStatus(
        fullRepaintIsScheduled: fullRepaintIsScheduled(self), renderer: view())
    }

    if repaintContainer.fullRepaintIsScheduled && forceRepaint == .No {
      return
    }

    var repaintRect = LayoutRectWrapper()
    if partialRepaintRect != nil {
      repaintRect = computeRectForRepaint(
        rect: partialRepaintRect!, repaintContainer: repaintContainer.renderer)
      if additionalRepaintOutsets != nil {
        repaintRect.expand(box: additionalRepaintOutsets!)
      }
    } else {
      repaintRect = clippedOverflowRectForRepaint(repaintContainer.renderer)
    }

    repaintUsingContainer(repaintContainer.renderer, repaintRect, clipRepaintToLayer == .Yes)
  }

  private func hasWBRLineBreakFlag() -> Bool {
    assert(isNativeImpl())
    return m_typeSpecificFlags.lineBreakFlags().contains(.IsWBR)
  }

  func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    fatalError("Not reached")
  }

  func setLayerNeedsFullRepaint() {
    assert(hasLayer())
    (self as! RenderLayerModelObjectWrapper).checkedLayer()!.repaintStatus = .NeedsFullRepaint
  }

  func setLayerNeedsFullRepaintForPositionedMovementLayout() {
    assert(hasLayer())
    (self as! RenderLayerModelObjectWrapper).checkedLayer()!.repaintStatus =
      .NeedsFullRepaintForPositionedMovementLayout
  }

  private func propagateRepaintToParentWithOutlineAutoIfNeeded(
    _ repaintContainer: RenderLayerModelObjectWrapper, _ repaintRect: LayoutRectWrapper
  ) {
    if !hasOutlineAutoAncestor() {
      return
    }

    // FIXME: We should really propagate only when the child renderer sticks out.
    var repaintRectNeedsConverting = false
    // Issue repaint on the renderer with outline: auto.
    var renderer: RenderObjectWrapper? = self
    while renderer != nil {
      let originalRenderer = renderer
      if let previousMultiColumnSet = renderer!.previousSibling() as? RenderMultiColumnSetWrapper,
        !renderer!.isLegend()
      {
        let enclosingMultiColumnFlow = previousMultiColumnSet.multiColumnFlowForBlockFlow()!
        let renderMultiColumnPlaceholder = enclosingMultiColumnFlow.findColumnSpannerPlaceholder(
          spanner: renderer as! RenderBoxWrapper?)!
        renderer = renderMultiColumnPlaceholder
      }

      let rendererHasOutlineAutoAncestor =
        renderer!.hasOutlineAutoAncestor() || originalRenderer!.hasOutlineAutoAncestor()
      assert(
        rendererHasOutlineAutoAncestor
          || originalRenderer!.outlineStyleForRepaint().outlineStyleIsAuto() == .On
          || (renderer is RenderBoxModelObjectWrapper
            && (renderer as! RenderBoxModelObjectWrapper).isContinuation())
      )
      if CPtrToInt(originalRenderer?.id()) == CPtrToInt(repaintContainer.id())
        && rendererHasOutlineAutoAncestor
      {
        repaintRectNeedsConverting = true
      }
      if rendererHasOutlineAutoAncestor {
        renderer = renderer!.parent()
        continue
      }
      // Issue repaint on the correct repaint container.
      var adjustedRepaintRect = repaintRect
      adjustedRepaintRect.inflate(d: originalRenderer!.outlineStyleForRepaint().outlineSize())
      if !repaintRectNeedsConverting {
        repaintContainer.repaintRectangle(repaintRect: adjustedRepaintRect)
      } else if let rendererWithOutline = originalRenderer as? RenderLayerModelObjectWrapper {
        adjustedRepaintRect = LayoutRectWrapper(
          r: repaintContainer.localToContainerQuad(
            localQuad: FloatQuad(inRect: adjustedRepaintRect.FloatRect()),
            container: rendererWithOutline
          ).boundingBox())
        rendererWithOutline.repaintRectangle(repaintRect: adjustedRepaintRect)
      }
      return
    }
    fatalError("Not reached")
  }

  func setEverHadLayout() {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.EverHadLayout)
  }

  func setHadSkippedLayout(_ b: Bool) {
    assert(isNativeImpl())
    m_stateBitfields.setFlag(.WasSkippedDuringLastLayoutDueToContentVisibility, b)
  }

  func hasRareData() -> Bool {
    assert(isNativeImpl())
    return m_stateBitfields.hasFlag(.HasRareData)
  }

  #if ASSERT_ENABLED
    private func checkBlockPositionedObjectsNeedLayout() {
      assert(!needsLayout())

      (self as? RenderBlockWrapper)?.checkPositionedObjectsNeedLayout()
    }
  #endif

  private struct StateFlag: OptionSet {
    let rawValue: UInt32

    static let IsBlock = StateFlag(rawValue: 1 << 0)
    static let IsReplacedOrInlineBlock = StateFlag(rawValue: 1 << 1)
    static let BeingDestroyed = StateFlag(rawValue: 1 << 2)
    static let NeedsLayout = StateFlag(rawValue: 1 << 3)
    static let NeedsPositionedMovementLayout = StateFlag(rawValue: 1 << 4)
    static let NormalChildNeedsLayout = StateFlag(rawValue: 1 << 5)
    static let PosChildNeedsLayout = StateFlag(rawValue: 1 << 6)
    static let NeedsSimplifiedNormalFlowLayout = StateFlag(rawValue: 1 << 7)
    static let OutOfFlowChildNeedsStaticPositionLayout = StateFlag(rawValue: 1 << 8)
    static let EverHadLayout = StateFlag(rawValue: 1 << 9)
    static let IsExcludedFromNormalLayout = StateFlag(rawValue: 1 << 10)
    static let Floating = StateFlag(rawValue: 1 << 11)
    static let VerticalWritingMode = StateFlag(rawValue: 1 << 12)
    static let PreferredLogicalWidthsDirty = StateFlag(rawValue: 1 << 13)
    static let HasRareData = StateFlag(rawValue: 1 << 14)
    static let HasLayer = StateFlag(rawValue: 1 << 15)
    static let HasNonVisibleOverflow = StateFlag(rawValue: 1 << 16)
    static let HasTransformRelatedProperty = StateFlag(rawValue: 1 << 17)
    static let ChildrenInline = StateFlag(rawValue: 1 << 18)
    static let PaintContainmentApplies = StateFlag(rawValue: 1 << 19)
    static let HasSVGTransform = StateFlag(rawValue: 1 << 20)
    static let WasSkippedDuringLastLayoutDueToContentVisibility = StateFlag(rawValue: 1 << 21)
    static let CapturedInViewTransition = StateFlag(rawValue: 1 << 22)
  }

  private struct StateBitfields {
    enum PositionedState: UInt8 {
      case IsStaticallyPositioned = 0
      case IsRelativelyPositioned = 1
      case IsOutOfFlowPositioned = 2
      case IsStickilyPositioned = 3
    }

    func hasFlag(_ flag: StateFlag) -> Bool { return flags.contains(flag) }

    mutating func setFlag(_ flag: StateFlag, _ value: Bool = true) {
      if value {
        flags.formUnion(flag)
      } else {
        flags.subtract(flag)
      }
    }

    mutating func clearFlag(_ flag: StateFlag) { setFlag(flag, false) }

    func isOutOfFlowPositioned() -> Bool { return m_positionedState == .IsOutOfFlowPositioned }
    func isRelativelyPositioned() -> Bool { return m_positionedState == .IsRelativelyPositioned }
    func isStickilyPositioned() -> Bool { return m_positionedState == .IsStickilyPositioned }
    func isPositioned() -> Bool { return m_positionedState != .IsStaticallyPositioned }

    mutating func setPositionedState(_ positionState: PositionType) {
      // This mask maps .Fixed and .Absolute to IsOutOfFlowPositioned, saving one bit.
      m_positionedState = PositionedState(rawValue: positionState.rawValue & 0x3)!
    }

    mutating func clearPositionedState() {
      m_positionedState = PositionedState(rawValue: PositionType.Static.rawValue)!
    }

    func selectionState() -> HighlightState { return m_selectionState }

    func fragmentedFlowState() -> FragmentedFlowState { return m_fragmentedFlowState }

    mutating func setBoxDecorationState(_ boxDecorationState: BoxDecorationState) {
      self.boxDecorationState = boxDecorationState
    }

    private var flags: StateFlag = []
    private var m_positionedState: PositionedState = .IsStaticallyPositioned
    private let m_selectionState: HighlightState = .None
    private let m_fragmentedFlowState: FragmentedFlowState = .NotInsideFlow
    var boxDecorationState: BoxDecorationState = .None
  }

  static func createFromRawPointer(p: UnsafeMutableRawPointer) -> RenderObjectWrapper {
    if wk_interop.RenderObject_isRenderListBox(p) {
      return RenderListBoxWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderListItem(p) {
      return RenderListItemWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderBlockFlow(p) {
      return RenderBlockFlowWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderFlexibleBox(p) {
      return RenderFlexibleBoxWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderBlock(p) {
      return RenderBlockWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderListMarker(p) {
      return RenderListMarkerWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderBox(p) {
      return RenderBoxWrapper(p: p)
    }
    if wk_interop.RenderObject_isRenderText(p) {
      return RenderTextWrapper(p: p)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isNativeImpl() -> Bool { return pInterop == nil }

  // TODO(asuhan): return unsigned integer once interop isn't needed anymore.
  func id() -> UnsafeMutableRawPointer {
    return pInterop ?? UnsafeMutableRawPointer(
      bitPattern: UInt(bitPattern: ObjectIdentifier(self)))!
  }

  private let pInterop: UnsafeMutableRawPointer?

  #if ASSERT_ENABLED
    private var m_setNeedsLayoutForbidden = false
  #endif  // ASSERT_ENABLED

  private var m_stateBitfields = StateBitfields()

  private let m_node: NodeWrapper?

  private var m_parent: RenderElementWrapper? = nil
  private var m_previous: RenderObjectWrapper? = nil
  private let m_typeFlags: TypeFlag
  private let m_type: `Type`
  private var m_next: RenderObjectWrapper? = nil  // TODO(asuhan): use weak reference
  private let m_typeSpecificFlags: TypeSpecificFlags

  // FIXME: This should be RenderElementRareData.
  class RenderObjectRareData {
    var hasReflection = false
    var hasOutlineAutoAncestor = false
    let trimmedMargins: MarginTrimType = []

    // From RenderElement
    var referencedSVGResources: ReferencedSVGResources? = nil
    let backdropRenderer = WeakNullableRef<RenderBlockFlowWrapper>(nil)

    // From RenderBox
    let controlPart: ControlPartWrapper? = nil
  }

  private func rareData() -> RenderObjectRareData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ensureRareData() -> RenderObjectRareData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
