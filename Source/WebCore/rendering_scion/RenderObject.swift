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

  // Type Specific Flags

  struct BlockFlowFlag: OptionSet {
    let rawValue: UInt8

    static let IsFragmentContainer = BlockFlowFlag(rawValue: 1 << 0)
    static let IsFragmentedFlow = BlockFlowFlag(rawValue: 1 << 1)
    static let IsTextControl = BlockFlowFlag(rawValue: 1 << 2)
    static let IsSVGBlock = BlockFlowFlag(rawValue: 1 << 3)
    static let IsViewTransitionContainer = BlockFlowFlag(rawValue: 1 << 4)
  }

  init(p: UnsafeMutableRawPointer) {
    self.p = p
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
      let box = InitialContainingBlock(style: style)
      box.p = UnsafeRawPointer(unwrapped!)
      return box
    }
    if wk_interop.Box_isElementBox(unwrapped) {
      let box = ElementBoxWrapper(style: style)
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

  func isDescendantOf(ancestor: RenderObjectWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func firstNonAnonymousAncestor() -> RenderElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func enclosingBoxModelObject() -> RenderBoxModelObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return our enclosing flow thread if we are contained inside one. Follows the containing block chain.
  func enclosingFragmentedFlow() -> RenderFragmentedFlowWrapper? {
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
  //////////////////////////////////////////

  func isRenderReplaced() -> Bool {
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

  func isRenderEmbeddedObject() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFieldset() -> Bool {
    return wk_interop.RenderObject_isFieldset(p)
  }

  func isRenderFrameSet() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isImage() -> Bool {
    return wk_interop.RenderObject_isImage(p)
  }

  func isRenderButton() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderIFrame() -> Bool {
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

  func isDocumentElementRenderer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBody() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isHTMLMarquee() -> Bool {
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

  func fragmentedFlowState() -> FragmentedFlowState {
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

  func isRenderOrLegacyRenderSVGRoot() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSVGLayerAwareRenderer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  func isAnonymous() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isAnonymousBlock() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func isStickilyPositioned() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldUsePositionedClipping() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderText() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBR() -> Bool {
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

  func isExcludedFromNormalLayout() -> Bool {
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

  func normalChildNeedsLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSelectionBorder() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  // When the document element is captured, the captured contents uses the RenderView
  // instead. Returns the capture state with this adjustment applied.
  func effectiveCapturedInViewTransition() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func view() -> RenderViewWrapper {
    return RenderViewWrapper(p: wk_interop.RenderObject_view(p))
  }

  func node() -> NodeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func document() -> Document {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func treeScopeForSVGReferences() -> TreeScopeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frame() -> LocalFrameWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  func isComposited() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Convert a local quad into the coordinate system of container, taking transforms into account.
  func localToContainerQuad(
    localQuad: FloatQuad, container: RenderLayerModelObjectWrapper?,
    mode: MapCoordinatesMode = [.UseTransforms]
  ) -> FloatQuad {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func minPreferredLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderObject_minPreferredLogicalWidth(p))
  }

  func maxPreferredLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderObject_maxPreferredLogicalWidth(p))
  }

  func setNeedsLayout(markParents: MarkingBehavior = .MarkContainingBlockChain) {
    wk_interop.RenderObject_setNeedsLayout(p, markParents.rawValue)
  }

  func setNeedsLayoutAndPrefWidthsRecalc() {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    let fullRepaintIsScheduled = false  // Either the repaint container or a layer in-between has already been scheduled for full repaint.
    let renderer: RenderLayerModelObjectWrapper? = nil
  }

  func containerForRepaint() -> RepaintContainerStatus {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Repaint the entire object.  Called when, e.g., the color of a border changes, or when a border
  // style changes.
  enum ForceRepaint {
    case No
    case Yes
  }

  func repaint(forceRepaint: ForceRepaint = .No) {
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

  // When performing a global document tear-down, or when going into the back/forward cache, the renderer of the document is cleared.
  func renderTreeBeingDestroyed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Virtual function helper for the new FlexibleBox Layout (display: -webkit-flex).
  func isRenderFlexibleBox() -> Bool {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func initializeFragmentedFlowStateOnInsertion() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSkippedContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  //////////////////////////////////////////
  // Helper functions. Dangerous to use!
  func setParent(parent: RenderElementWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
  //////////////////////////////////////////

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
}
