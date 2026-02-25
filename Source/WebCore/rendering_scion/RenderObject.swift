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

    let kind: Kind
    let flags: UInt8
  }

  init(p: UnsafeMutableRawPointer) {
    self.p = p
    m_node = nil
    m_typeFlags = []
    m_type = .BlockFlow
    m_typeSpecificFlags = TypeSpecificFlags()
  }

  init(
    _ type: `Type`, _ node: NodeWrapper, _ typeFlags: TypeFlag,
    _ typeSpecificFlags: TypeSpecificFlags
  ) {
    self.p = UnsafeMutableRawPointer(bitPattern: 0xdead_beef)!
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

  func layoutBox() -> BoxWrapper? {
    let unwrapped = wk_interop.RenderObject_layoutBox(p)
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
    let unwrapped = wk_interop.RenderObject_parent(p)
    if unwrapped == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return RenderElementWrapper(p: unwrapped!)
  }

  func checkedParent() -> RenderElementWrapper? {
    return parent()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func isDescendantOf(ancestor: RenderObjectWrapper?) -> Bool {
    var renderer: RenderObjectWrapper? = self
    while renderer != nil {
      if CPtrToInt(renderer!.p) == CPtrToInt(ancestor?.p) {
        return true
      }
      renderer = renderer!.m_parent
    }
    return false
  }

  func previousSibling() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSibling() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Use RenderElement versions instead.
  func firstChildSlow() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastChildSlow() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    if CPtrToInt(p) == CPtrToInt(stayWithin?.p) {
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
      if current == nil || CPtrToInt(current!.p) == CPtrToInt(stayWithin?.p) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingBoxModelObject() -> RenderBoxModelObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func useDarkAppearance() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // RenderObject tree manipulation
  //////////////////////////////////////////
  func canHaveChildren() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canHaveGeneratedChildren() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createsAnonymousWrapper() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  //////////////////////////////////////////

  func isRenderElement() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderReplaced() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderBoxModelObject() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderBlock() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderBlockFlow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderInline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderLayerModelObject() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderQuote() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderEmbeddedObject() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFieldset() -> Bool {
    return wk_interop.RenderObject_isFieldset(p)
  }

  func isRenderFileUploadControl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderFrameSet() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isImage() -> Bool {
    return wk_interop.RenderObject_isImage(p)
  }

  func isInlineBlockOrInlineTable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderListBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderListMarker() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderMenuList() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderButton() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderIFrame() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderFragmentContainer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTableCell() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTableCol() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTableCaption() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTableSection() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTextControl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderVideo() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderViewTransitionCapture() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderHTMLCanvas() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderGrid() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderMultiColumnSet() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderMultiColumnFlow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isDocumentElementRenderer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBody() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLegend() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isHTMLMarquee() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTablePart() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isViewTransitionPseudo() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBeforeContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAfterContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBeforeOrAfterContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAfterContent(obj: RenderObjectWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func beingDestroyed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func everHadLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func wasSkippedDuringLastLayoutDueToContentVisibility() -> Bool? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func searchParentChainForScrollAnchoringController(_ renderer: RenderObjectWrapper)
    -> ScrollAnchoringControllerWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func childrenInline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setChildrenInline(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFragmentedFlowState(_ state: FragmentedFlowState) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGViewportContainer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGText() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGTextPath() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGInline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGInlineText() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderSVGForeignObject() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBlockBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInFlowPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isOutOfFlowPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFixedPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAbsolutelyPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRelativelyPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isStickilyPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldUsePositionedClipping() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderText() -> Bool { return m_typeFlags.contains(.IsText) }

  func isBR() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLineBreakOpportunity() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderTableRow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderView() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isReplacedOrInlineBlock() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isHorizontalWritingMode() -> Bool {
    return wk_interop.RenderObject_isHorizontalWritingMode(p)
  }

  func hasReflection() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderFragmentedFlow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutlineAutoAncestor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintContainmentApplies() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isExcludedFromNormalLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsExcludedFromNormalLayout(excluded: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isExcludedAndPlacedInBorder() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisibleBoxDecorations() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backgroundIsKnownToBeObscured(paintOffset: LayoutPointWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsLayout() -> Bool {
    return selfNeedsLayout()
      || normalChildNeedsLayout()
      || posChildNeedsLayout()
      || needsSimplifiedNormalFlowLayout()
      || needsPositionedMovementLayout()
  }

  func selfNeedsLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsPositionedMovementLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsPositionedMovementLayoutOnly() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func posChildNeedsLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsSimplifiedNormalFlowLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsSimplifiedNormalFlowLayoutOnly() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func normalChildNeedsLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outOfFlowChildNeedsStaticPositionLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func preferredLogicalWidthsDirty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSelectionBorder() -> Bool {
    let st = selectionState()
    return st == .Start
      || st == .End
      || st == .Both
      || CPtrToInt(view().selection().start()?.p) == CPtrToInt(p)
      || CPtrToInt(view().selection().end()?.p) == CPtrToInt(p)
  }

  func hasNonVisibleOverflow() -> Bool {
    return wk_interop.RenderObject_hasNonVisibleOverflow(p)
  }

  func hasPotentiallyScrollableOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTransformRelatedProperty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTransformed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTransformOrPerspective() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func capturedInViewTransition() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCapturedInViewTransition(_ captured: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func view() -> RenderViewWrapper {
    return RenderViewWrapper(p: wk_interop.RenderObject_view(p))
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func protectedNode() -> NodeWrapper? { return node() }

  func nonPseudoNode() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func document() -> Document {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func protectedDocument() -> Document {
    return document()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func treeScopeForSVGReferences() -> TreeScopeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frame() -> LocalFrameWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func protectedFrame() -> LocalFrameWrapper { return frame() }  // TODO(asuhan): just remove this wrapper, not needed in Swift

  func page() -> PageWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func settings() -> SettingsWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasOutlineAutoAncestor(hasOutlineAutoAncestor: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPaintContainmentApplies(_ value: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasSVGTransform(_ value: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isComposited() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    assert(CPtrToInt(container.p) == CPtrToInt(self.container()?.p))

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
    } while CPtrToInt(currentContainer.p) != CPtrToInt(container.p)

    return offset
  }

  func minPreferredLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderObject_minPreferredLogicalWidth(p))
  }

  func maxPreferredLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderObject_maxPreferredLogicalWidth(p))
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
        if CPtrToInt(ancestor!.p) == CPtrToInt(layoutRoot!.p) {
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
    wk_interop.RenderObject_setNeedsLayout(p, markParents.rawValue)
  }

  enum HadSkippedLayout {
    case No
    case Yes
  }

  func clearNeedsLayout(hadSkippedLayout: HadSkippedLayout = .No) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsLayoutAndPrefWidthsRecalc() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPositionState(_ position: PositionType) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearPositionedState() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFloating(_ b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInline(_ b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasVisibleBoxDecorations(_ b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateBackgroundObscurationStatus() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeBackgroundIsKnownToBeObscured(_ paintOffset: LayoutPointWrapper) -> Bool {
    return false
  }

  func setReplacedOrInlineBlock(_ b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHorizontalWritingMode(_ b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasNonVisibleOverflow(_ b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasTransformRelatedProperty(_ b: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHasReflection(_ hasReflection: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
        if renderer == nil || CPtrToInt(renderer!.p) == CPtrToInt(parent!.p) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containingBlock() -> RenderBlockWrapper? {
    if let unwrapped = wk_interop.RenderObject_containingBlock(p) {
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
    localPoint: FloatPoint = FloatPoint(), mode: MapCoordinatesMode = MapCoordinatesMode(),
    wasFixed: Bool? = nil
  ) -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func style() -> RenderStyleWrapper {
    return convert_render_style(p: wk_interop.RenderObject_style(p))
  }

  func firstLineStyle() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Anonymous blocks that are part of of a continuation chain will return their inline continuation's outline style instead.
  // This is typically only relevant when repainting.
  func outlineStyleForRepaint() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
        || CPtrToInt(repaintContainerFragmentedFlow!.p) != CPtrToInt(parentRenderFragmentedFlow.p)
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
      assert(CPtrToInt(repaintContainer!.p) == CPtrToInt(view.p))
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    if CPtrToInt(container?.p) == CPtrToInt(p) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFloatingOrOutOfFlowPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInFlow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func canBeSelectionLeaf() -> Bool { return false }

  // When performing a global document tear-down, or when going into the back/forward cache, the renderer of the document is cleared.
  func renderTreeBeingDestroyed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Virtual function helpers for the deprecated Flexible Box Layout (display: -webkit-box).
  func isRenderDeprecatedFlexibleBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Virtual function helper for the new FlexibleBox Layout (display: -webkit-flex).
  func isRenderFlexibleBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFlexibleBoxIncludingDeprecated() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func caretMinOffset() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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
    if CPtrToInt(ancestorContainer?.p) == CPtrToInt(p) {
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
    assert(CPtrToInt(ancestorToStopAt?.p) != CPtrToInt(p))

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
      return CPtrToInt(containerObject!.p) == CPtrToInt(parent()?.p)
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSkippedContentForLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  //////////////////////////////////////////
  // Helper functions. Dangerous to use!
  func setPreviousSibling(previous: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNextSibling(next: RenderObjectWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setParent(parent: RenderElementWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  //////////////////////////////////////////

  func nodeForNonAnonymous() -> NodeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNormalChildNeedsLayoutBit(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPosChildNeedsLayoutBit(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsSimplifiedNormalFlowLayoutBit(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOutOfFlowChildNeedsStaticPositionLayoutBit(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLayerNeedsFullRepaint() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLayerNeedsFullRepaintForPositionedMovementLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
      if CPtrToInt(originalRenderer?.p) == CPtrToInt(repaintContainer.p)
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  var p: UnsafeMutableRawPointer

  private let m_node: NodeWrapper?

  private let m_parent: RenderElementWrapper? = nil
  private let m_typeFlags: TypeFlag
  private let m_type: `Type`
  private let m_typeSpecificFlags: TypeSpecificFlags
}
