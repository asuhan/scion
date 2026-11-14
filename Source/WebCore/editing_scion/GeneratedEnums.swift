typealias TextIteratorBehaviors = TextIteratorBehavior

enum AnchorType: Int32 {
  case PositionIsOffsetInAnchor
  case PositionIsBeforeAnchor
  case PositionIsAfterAnchor
  case PositionIsBeforeChildren
  case PositionIsAfterChildren
}

enum BoundarySearchContextAvailability: Int32 {
  case DontHaveMoreContext
  case MayHaveMoreContext
}

enum CaretAlignment: Int32 {
  case AlignLeft
  case AlignRight
  case AlignCenter
}

enum CaretRectMode: Int32 {
  case Normal
  case ExpandToEndOfLine
}

enum CursorMovementDirection: Int32 {
  case MoveLeft
  case MoveRight
}

enum Editability: Int32 {
  case ReadOnly
  case CanEditPlainText
  case CanEditRichly
}

enum EditableType: Int32 {
  case ContentIsEditable
  case HasEditableAXRole
}

enum EditingBehaviorType: Int32 {
  case Mac
  case Windows
  case Unix
  case iOS
}

enum EditorParagraphSeparator: Int32 {
  case div
  case p
}

struct FindOption: OptionSet {
  let rawValue: UInt32
  static let CaseInsensitive = FindOption(rawValue: 1)
  static let AtWordStarts = FindOption(rawValue: 2)
  static let TreatMedialCapitalAsWordStart = FindOption(rawValue: 4)
  static let Backwards = FindOption(rawValue: 8)
  static let WrapAround = FindOption(rawValue: 16)
  static let StartInSelection = FindOption(rawValue: 32)
  static let DoNotRevealSelection = FindOption(rawValue: 64)
  static let AtWordEnds = FindOption(rawValue: 128)
  static let DoNotTraverseFlatTree = FindOption(rawValue: 256)
  static let DoNotSetSelection = FindOption(rawValue: 512)
}

struct LayoutOptions: OptionSet {
  let rawValue: UInt32
  static let RunPostLayoutTasksSynchronously = LayoutOptions(rawValue: 1)
  static let IgnorePendingStylesheets = LayoutOptions(rawValue: 2)
  static let ContentVisibilityForceLayout = LayoutOptions(rawValue: 4)
  static let UpdateCompositingLayers = LayoutOptions(rawValue: 8)
  static let DoNotLayoutAncestorDocuments = LayoutOptions(rawValue: 16)
  static let CanDeferUpdateLayerPositions = LayoutOptions(rawValue: 32)
}

enum LegacyEditingPositionFlag: Int32 {
  case On
}

enum LineEndpointComputationMode: Int32 {
  case UseLogicalOrdering
  case UseInlineBoxOrdering
}

enum NeedsContextAtParagraphStart: Int32 {
  case No
  case Yes
}

enum PositionMoveType: Int32 {
  case CodePoint
  case Character
  case BackwardDeletion
}

enum SelectionDirection: Int32 {
  case Forward
  case Backward
  case Right
  case Left
}

enum ShouldMatchBidiLevel: Int32 {
  case MatchBidiLevel
  case IgnoreBidiLevel
}

enum ShouldUpdateStyle: Int32 {
  case Update
  case DoNotUpdate
}

enum SkipDisplayContents: Int32 {
  case No
  case Yes
}

enum TextGranularity: Int32 {
  case CharacterGranularity
  case WordGranularity
  case SentenceGranularity
  case LineGranularity
  case ParagraphGranularity
  case DocumentGranularity
  case SentenceBoundary
  case LineBoundary
  case ParagraphBoundary
  case DocumentBoundary
}

struct TextIteratorBehavior: OptionSet {
  let rawValue: UInt32
  static let EmitsCharactersBetweenAllVisiblePositions = TextIteratorBehavior(rawValue: 1)
  static let EntersTextControls = TextIteratorBehavior(rawValue: 2)
  static let EmitsTextsWithoutTranscoding = TextIteratorBehavior(rawValue: 4)
  static let IgnoresStyleVisibility = TextIteratorBehavior(rawValue: 8)
  static let EmitsObjectReplacementCharacters = TextIteratorBehavior(rawValue: 16)
  static let EmitsOriginalText = TextIteratorBehavior(rawValue: 32)
  static let EmitsImageAltText = TextIteratorBehavior(rawValue: 64)
  static let BehavesAsIfNodesFollowing = TextIteratorBehavior(rawValue: 128)
  static let ClipsToFrameAncestors = TextIteratorBehavior(rawValue: 256)
  static let TraversesFlatTree = TextIteratorBehavior(rawValue: 512)
  static let EntersImageOverlays = TextIteratorBehavior(rawValue: 1024)
  static let IgnoresUserSelectNone = TextIteratorBehavior(rawValue: 2048)
  static let EmitsObjectReplacementCharactersForImages = TextIteratorBehavior(rawValue: 4096)
  static let IgnoresFullSizeKana = TextIteratorBehavior(rawValue: 16384)
}

enum TreeType: Int32 {
  case Tree
  case ShadowIncludingTree
  case ComposedTree
}

enum UpdateLayoutResult: Int32 {
  case NoChange
  case ChangesDone
}

enum VoicedSoundMarkType: Int32 {
  case NoVoicedSoundMark
  case VoicedSoundMark
  case SemiVoicedSoundMark
}

enum WithinWordBoundary: Int32 {
  case No
  case Yes
}

enum WordSide: Int32 {
  case RightWordIfOnBoundary
  case LeftWordIfOnBoundary
}
