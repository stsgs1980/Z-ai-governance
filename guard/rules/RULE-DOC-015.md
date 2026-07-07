---
id: RULE-DOC-015
title: No Unicode graphics (UNICODE_POLICY compliance)
version: 1.0
level: [W]
status: ACTIVE
source: Z-ai-guard v3.0.0 (RULE-DOC-015)
owning-standard: STD-META-001 v2.0
last-updated: 2026-06-17
related:
  - STD-DOC-002
---

# RULE-DOC-015: No Unicode graphics (UNICODE_POLICY compliance)

All AHG output must comply with No-Unicode Policy v2.1.
No emoji, no Unicode pictograms, no decorative symbols.

**Allowed:**

- ASCII: a-z, A-Z, 0-9, standard punctuation
- Cyrillic: a-ya, A-Ya
- Status markers: [OK], [ERR], [WARN], [INFO], [FAIL] -- plain text only
- Diagrams: ASCII only: -> <- => <= | + - v ^ >
- Section dividers in comments: // -- or # -- (not Unicode dashes)

**Prohibited:**

- Emoji (any pictograms: emotions, objects, UI-symbols)
- Unicode box drawing (U+2500 and similar)
- Em dash (U+2014), en dash (U+2013) -- use -- instead
- Any Unicode decorative symbols

**Application levels:**

- Production code: [C] Critical (blocks)
- CLI output, scripts: [W] Warning
- AI-agent chat responses: [W] Warning
- Documentation (.md): regulated by MARKDOWN_STANDARD v2.1
