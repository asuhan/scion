target_sources(layout_scion PRIVATE
    AtomString.swift
    CharSpan.swift
    StringBuilder.swift
    StringView.swift
    TextBreakIterator.swift
    WTFString.swift
)
add_subdirectory(icu)
