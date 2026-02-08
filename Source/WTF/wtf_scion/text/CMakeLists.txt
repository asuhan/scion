target_sources(layout_scion PRIVATE
    ASCIILiteral.swift
    AtomString.swift
    CharacterProperties.swift
    CharSpan.swift
    MakeString.swift
    StringBuilder.swift
    StringCommon.swift
    StringView.swift
    TextBreakIterator.swift
    WTFString.swift
)
add_subdirectory(icu)
