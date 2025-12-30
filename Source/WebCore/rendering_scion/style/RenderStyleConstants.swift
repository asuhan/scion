/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
 * Copyright (C) 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
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

enum PrintColorAdjust: UInt8 {
  case Economy
  case Exact
}

// The difference between two styles.  The following values are used:
// - StyleDifference::Equal - The two styles are identical
// - StyleDifference::RecompositeLayer - The layer needs its position and transform updated, but no repaint
// - StyleDifference::Repaint - The object just needs to be repainted.
// - StyleDifference::RepaintIfText - The object needs to be repainted if it contains text.
// - StyleDifference::RepaintLayer - The layer and its descendant layers needs to be repainted.
// - StyleDifference::LayoutPositionedMovementOnly - Only the position of this positioned object has been updated
// - StyleDifference::SimplifiedLayout - Only overflow needs to be recomputed
// - StyleDifference::SimplifiedLayoutAndPositionedMovement - Both positioned movement and simplified layout updates are required.
// - StyleDifference::Layout - A full layout is required.
enum StyleDifference: UInt8 {
  case Equal
  case RecompositeLayer
  case Repaint
  case RepaintIfText
  case RepaintLayer
  case LayoutPositionedMovementOnly
  case SimplifiedLayout
  case SimplifiedLayoutAndPositionedMovement
  case Layout
  case NewStyle
}

func < (_ a: StyleDifference, _ b: StyleDifference) -> Bool { return a.rawValue < b.rawValue }
func <= (_ a: StyleDifference, _ b: StyleDifference) -> Bool { return a.rawValue <= b.rawValue }
func > (_ a: StyleDifference, _ b: StyleDifference) -> Bool { return a.rawValue > b.rawValue }
func >= (_ a: StyleDifference, _ b: StyleDifference) -> Bool { return a.rawValue >= b.rawValue }

func max(_ a: StyleDifference, _ b: StyleDifference) -> StyleDifference {
  return StyleDifference(rawValue: max(a.rawValue, b.rawValue))!
}

// When some style properties change, different amounts of work have to be done depending on
// context (e.g. whether the property is changing on an element which has a compositing layer).
// A simple StyleDifference does not provide enough information so we return a bit mask of
// StyleDifferenceContextSensitiveProperties from RenderStyle::diff() too.
struct StyleDifferenceContextSensitiveProperty: OptionSet {
  let rawValue: UInt8
  static let Transform = StyleDifferenceContextSensitiveProperty(rawValue: 1 << 0)
  static let Opacity = StyleDifferenceContextSensitiveProperty(rawValue: 1 << 1)
  static let Filter = StyleDifferenceContextSensitiveProperty(rawValue: 1 << 2)
  static let ClipRect = StyleDifferenceContextSensitiveProperty(rawValue: 1 << 3)
  static let ClipPath = StyleDifferenceContextSensitiveProperty(rawValue: 1 << 4)
  static let WillChange = StyleDifferenceContextSensitiveProperty(rawValue: 1 << 5)
}

// Static pseudo styles. Dynamic ones are produced on the fly.
enum PseudoId: UInt32 {
  // The order must be None, public IDs, and then internal IDs.
  case None

  // Public:
  case FirstLine
  case FirstLetter
  case GrammarError
  case Highlight
  case Marker
  case Before
  case After
  case Selection
  case Backdrop
  case WebKitScrollbar
  case SpellingError
  case TargetText
  case ViewTransition
  case ViewTransitionGroup
  case ViewTransitionImagePair
  case ViewTransitionOld
  case ViewTransitionNew

  // Internal:
  case WebKitScrollbarThumb
  case WebKitScrollbarButton
  case WebKitScrollbarTrack
  case WebKitScrollbarTrackPiece
  case WebKitScrollbarCorner
  case WebKitResizer
  case InternalWritingSuggestions

  case AfterLastInternalPseudoId
}

func parentPseudoElement(pseudoId: PseudoId) -> PseudoId? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

enum ColumnSpan: UInt8 {
  case None
  case All
}

enum BorderCollapse: UInt8 {
  case Separate
  case Collapse
}

// These have been defined in the order of their precedence for border-collapsing. Do
// not change this order! This order also must match the order in CSSValueKeywords.in.
enum BorderStyle: UInt8 {
  case None
  case Hidden
  case Inset
  case Groove
  case Outset
  case Ridge
  case Dotted
  case Dashed
  case Solid
  case Double
}

enum BorderPrecedence: UInt8 {
  case Off
  case Table
  case ColumnGroup
  case Column
  case RowGroup
  case Row
  case Cell
}

enum OutlineIsAuto: UInt8 {
  case Off
  case On
}

enum PositionType: UInt8 {
  case Static = 0
  case Relative = 1
  case Absolute = 2
  case Sticky = 3
  // This value is required to pack our bits efficiently in RenderObject.
  case Fixed = 6
}

enum Float: UInt8 {
  case None
  case Left
  case Right
  case InlineStart
  case InlineEnd
}

struct UsedFloat: OptionSet {
  let rawValue: UInt32
  static let None = UsedFloat(rawValue: 1 << 0)
  static let Left = UsedFloat(rawValue: 1 << 1)
  static let Right = UsedFloat(rawValue: 1 << 2)
}

// Box decoration attributes. Not inherited.

enum BoxDecorationBreak: UInt8 {
  case Slice
  case Clone
}

// Box attributes. Not inherited.

enum BoxSizing: UInt8 {
  case ContentBox
  case BorderBox
}

// Random visual rendering model attributes. Not inherited.

enum Overflow: UInt8 {
  case Visible
  case Hidden
  case Clip
  case Scroll
  case Auto
  case PagedX
  case PagedY
}

enum VerticalAlign: UInt8 {
  case Baseline
  case Middle
  case Sub
  case Super
  case TextTop
  case TextBottom
  case Top
  case Bottom
  case BaselineMiddle
  case Length
}

enum Clear: UInt8 {
  case None
  case Left
  case Right
  case InlineStart
  case InlineEnd
  case Both
}

enum UsedClear: UInt8 {
  case None
  case Left
  case Right
  case Both
}

enum FillAttachment: UInt8 {
  case ScrollBackground
  case LocalBackground
  case FixedBackground
}

enum FillBox: UInt8 {
  case BorderBox
  case PaddingBox
  case ContentBox
  case BorderArea
  case Text
  case NoClip
}

enum FillRepeat: UInt8 {
  case Repeat
  case NoRepeat
  case Round
  case Space
}

// CSS3 Background Values
enum FillSizeType: UInt8 {
  case Contain
  case Cover
  case Size
  case None
}

// CSS3 <position>
enum Edge: UInt8 {
  case Top
  case Right
  case Bottom
  case Left
}

// CSS3 Mask Mode

enum MaskMode: UInt8 {
  case Alpha
  case Luminance
  case MatchSource
}

// CSS3 Marquee Properties

enum MarqueeBehavior: UInt8 {
  case None
  case Scroll
  case Slide
  case Alternate
}

enum MarqueeDirection: UInt8 {
  case Auto
  case Left
  case Right
  case Up
  case Down
  case Forward
  case Backward
}

// Deprecated Flexible Box Properties

enum BoxAlignment: UInt8 {
  case Stretch
  case Start
  case Center
  case End
  case Baseline
}

enum BoxOrient: UInt8 {
  case Horizontal
  case Vertical
}

// CSS3 Flexbox Properties

enum FlexDirection: UInt8 {
  case Row
  case RowReverse
  case Column
  case ColumnReverse
}

enum FlexWrap: UInt8 {
  case NoWrap
  case Wrap
  case Reverse
}

enum ItemPosition: UInt8 {
  case Legacy
  case Auto
  case Normal
  case Stretch
  case Baseline
  case LastBaseline
  case Center
  case Start
  case End
  case SelfStart
  case SelfEnd
  case FlexStart
  case FlexEnd
  case Left
  case Right
}

enum OverflowAlignment: UInt8 {
  case Default
  case Unsafe
  case Safe
}

enum ItemPositionType {
  case NonLegacy
  case Legacy
}

enum ContentPosition: UInt8 {
  case Normal
  case Baseline
  case LastBaseline
  case Center
  case Start
  case End
  case FlexStart
  case FlexEnd
  case Left
  case Right
}

enum ContentDistribution: UInt8 {
  case Default
  case SpaceBetween
  case SpaceAround
  case SpaceEvenly
  case Stretch
}

// CSS3 User Select Values

enum UserSelect: UInt8 {
  case None
  case Text
  case All
}

enum AspectRatioType: UInt8 {
  case Auto
  case Ratio
  case AutoAndRatio
  case AutoZero
}

enum WordBreak: UInt8 {
  case Normal
  case BreakAll
  case KeepAll
  case BreakWord
  case AutoPhrase
}

enum OverflowWrap: UInt8 {
  case Normal
  case BreakWord
  case Anywhere
}

enum NBSPMode: UInt8 {
  case Normal
  case Space
}

enum LineBreak: UInt8 {
  case Auto
  case Loose
  case Normal
  case Strict
  case AfterWhiteSpace
  case Anywhere
}

enum Resize: UInt8 {
  case None
  case Both
  case Horizontal
  case Vertical
  case Block
  case Inline
}

enum QuoteType: UInt8 {
  case OpenQuote
  case CloseQuote
  case NoOpenQuote
  case NoCloseQuote
}

enum WhiteSpace {
  case Normal
  case Pre
  case PreWrap
  case PreLine
  case NoWrap
  case BreakSpaces
}

enum WhiteSpaceCollapse: UInt8 {
  case Collapse
  case Preserve
  case PreserveBreaks
  case BreakSpaces
}

enum ReflectionDirection: UInt8 {
  case Below
  case Above
  case Left
  case Right
}

// The order of this enum must match the order of the text align values in CSSValueKeywords.in.
enum TextAlignMode: UInt8 {
  case Left
  case Right
  case Center
  case Justify
  case WebKitLeft
  case WebKitRight
  case WebKitCenter
  case Start
  case End
}

struct TextDecorationLine: OptionSet {
  let rawValue: UInt8
  static let Underline = TextDecorationLine(rawValue: 1 << 0)
  static let Overline = TextDecorationLine(rawValue: 1 << 1)
  static let LineThrough = TextDecorationLine(rawValue: 1 << 2)
  static let Blink = TextDecorationLine(rawValue: 1 << 3)
}

enum TextDecorationStyle: UInt8 {
  case Solid
  case Double
  case Dotted
  case Dashed
  case Wavy
}

enum TextAlignLast: UInt8 {
  case Auto
  case Start
  case End
  case Left
  case Right
  case Center
  case Justify
}

enum TextDecorationSkipInk: UInt8 {
  case None
  case Auto
  case All
}

struct MarginTrimType: OptionSet {
  let rawValue: UInt8
  static let BlockStart = MarginTrimType(rawValue: 1 << 0)
  static let BlockEnd = MarginTrimType(rawValue: 1 << 1)
  static let InlineStart = MarginTrimType(rawValue: 1 << 2)
  static let InlineEnd = MarginTrimType(rawValue: 1 << 3)
}

enum TextEdgeType: UInt8 {
  // Note that TextEdgeType is shared between text-box-edge and line-fit-edge,
  // where text-box-edge's default value is auto, and line-fit-edge has leading.
  case Auto
  case Leading
  case Text
  case CapHeight
  case ExHeight
  case Alphabetic
  case CJKIdeographic
  case CJKIdeographicInk
}

enum BreakBetween: UInt8 {
  case Auto
  case Avoid
  case AvoidColumn
  case AvoidPage
  case Column
  case Page
  case LeftPage
  case RightPage
  case RectoPage
  case VersoPage
}

func alwaysPageBreak(between: BreakBetween) -> Bool {
  return between.rawValue >= BreakBetween.Page.rawValue
}

enum BreakInside: UInt8 {
  case Auto
  case Avoid
  case AvoidColumn
  case AvoidPage
}

struct HangingPunctuation: OptionSet {
  let rawValue: UInt8
  static let First = HangingPunctuation(rawValue: 1 << 0)
  static let Last = HangingPunctuation(rawValue: 1 << 1)
  static let AllowEnd = HangingPunctuation(rawValue: 1 << 2)
  static let ForceEnd = HangingPunctuation(rawValue: 1 << 3)
}

enum EmptyCell: UInt8 {
  case Show
  case Hide
}

enum CaptionSide: UInt8 {
  case Top
  case Bottom
}

enum Visibility: UInt8 {
  case Visible
  case Hidden
  case Collapse
}

enum DisplayType: UInt8 {
  case Inline
  case Block
  case ListItem
  case InlineBlock
  case Table
  case InlineTable
  case TableRowGroup
  case TableHeaderGroup
  case TableFooterGroup
  case TableRow
  case TableColumnGroup
  case TableColumn
  case TableCell
  case TableCaption
  case Box
  case InlineBox
  case Flex
  case InlineFlex
  case Contents
  case Grid
  case InlineGrid
  case FlowRoot
  case Ruby
  case RubyBlock
  case RubyBase
  case RubyAnnotation
  case None
}

enum PointerEvents: UInt8 {
  case None
  case Auto
  case Stroke
  case Fill
  case Painted
  case Visible
  case VisibleStroke
  case VisibleFill
  case VisiblePainted
  case BoundingBox
  case All
}

enum TransformStyle3D: UInt8 {
  case Flat
  case Preserve3D
}

enum BackfaceVisibility: UInt8 {
  case Visible
  case Hidden
}

enum TransformBox: UInt8 {
  case StrokeBox
  case ContentBox
  case BorderBox
  case FillBox
  case ViewBox
}

enum Hyphens: UInt8 {
  case None
  case Manual
  case Auto
}

enum TextEmphasisMark: UInt8 {
  case None
  case Auto
  case Dot
  case Circle
  case DoubleCircle
  case Triangle
  case Sesame
  case Custom
}

struct TextEmphasisPosition: OptionSet {
  let rawValue: UInt8
  static let Over = TextEmphasisPosition(rawValue: 1 << 0)
  static let Under = TextEmphasisPosition(rawValue: 1 << 1)
  static let Left = TextEmphasisPosition(rawValue: 1 << 2)
  static let Right = TextEmphasisPosition(rawValue: 1 << 3)
}

enum TextOrientation: UInt8 {
  case Mixed
  case Upright
  case Sideways
}

enum TextOverflow: UInt8 {
  case Clip
  case Ellipsis
}

enum TextWrapMode {
  case Wrap
  case NoWrap
}

enum TextWrapStyle: UInt8 {
  case Auto
  case Balance
  case Pretty
  case Stable
}

enum ImageRendering: UInt8 {
  case Auto
  case OptimizeSpeed
  case OptimizeQuality
  case CrispEdges
  case Pixelated
}

enum Order: UInt8 {
  case Logical = 0
  case Visual = 1
}

enum ColumnProgression: UInt8 {
  case Normal
  case Reverse
}

enum LineSnap: UInt8 {
  case None
  case Baseline
  case Contain
}

enum LineAlign: UInt8 {
  case None
  case Edges
}

enum RubyPosition: UInt8 {
  case Over
  case Under
  case InterCharacter
  case LegacyInterCharacter
}

enum RubyAlign: UInt8 {
  case Start
  case Center
  case SpaceBetween
  case SpaceAround
}

enum RubyOverhang: UInt8 {
  case Auto
  case None
}

enum MasonryAutoFlowPlacementAlgorithm {
  case Pack
  case Next
}

enum MasonryAutoFlowPlacementOrder {
  case DefiniteFirst
  case Ordered
}

enum AutoRepeatType {
  case None
  case Fill
  case Fit
}

enum TextIndentLine: UInt8 {
  case FirstLine
  case EachLine
}

enum TextIndentType: UInt8 {
  case Normal
  case Hanging
}

enum Isolation {
  case Auto
  case Isolate
}

// Fill, Stroke, ViewBox are just used for SVG.
enum CSSBoxType: UInt8 {
  case BoxMissing
  case MarginBox
  case BorderBox
  case PaddingBox
  case ContentBox
  case FillBox
  case StrokeBox
  case ViewBox
}

// These are all minimized combinations of paint-order.
enum PaintOrder: UInt8 {
  case Normal
  case Fill
  case FillMarkers
  case Stroke
  case StrokeMarkers
  case Markers
  case MarkersStroke
}

enum PaintType: UInt8 {
  case Fill
  case Stroke
  case Markers
}

struct EventListenerRegionType: OptionSet {
  let rawValue: UInt8
  static let Wheel = EventListenerRegionType(rawValue: 1 << 0)
  static let NonPassiveWheel = EventListenerRegionType(rawValue: 1 << 1)
  static let MouseClick = EventListenerRegionType(rawValue: 1 << 2)
}

enum ContainIntrinsicSizeType: UInt8 {
  case None
  case Length
  case AutoAndLength
  case AutoAndNone
}

enum ContentVisibility: UInt8 {
  case Visible
  case Auto
  case Hidden
}

enum FieldSizing: UInt8 {
  case Fixed
  case Content
}

let defaultMiterLimit: Float32 = 4
