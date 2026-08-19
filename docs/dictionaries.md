# Adding a Book dictionary (`unitlens.koplugin/dicts/`)

A **book dictionary** decides **which units are detected** in the book text and
**what the popup shows**. This is separate from the plugin's **interface** language
(the menu/About strings - see [interface-languages.md](interface-languages.md)).

- **Book language** → `unitlens.koplugin/dicts/<code>.lua`. Per-book setting.
- **Interface language** → `unitlens.koplugin/l10n/<code>.lua`. Global setting.

There is **no runtime math**. Every conversion is a string you precompute here
(from [units.md](units.md)) and store on the unit. The engine only matches words and
renders your strings, so a dictionary can support _any_ language.

## Add or update a language

1. Copy [`_template.lua`](../unitlens.koplugin/dicts/_template.lua) to
   `dicts/<code>.lua`, where `<code>` is the language's [ISO 639-1] code
   (`de`, `fr`, `uk`, …). It must match the file name.
2. Set `lang` to the same `<code>`, and `name` to the language's **own** endonym
   (e.g. `"Deutsch"`, `"Українська"`) - this is what shows in the menu.
3. Translate the `strings` block and fill in `units` (see below).
4. That's it. Files are **auto-discovered**; the language appears under
   **Tools ▸ Unit Lens ▸ Book language** on the next launch. (Files starting with
   `_` or `.` are ignored, which is why the template is skipped.)

## A unit, field by field

```lua
foot = {                                   -- table key: internal id, keep it stable
  name = "foot",                           -- printed after "1 " in the popup
  system = "customary",                    -- optional -> strings.systems[...]
  category = "length",                     -- optional -> strings.categories[...]
  forms = { "foot", "feet" },              -- spelled words, matched ANYWHERE
  symbols = { "ft", "′" },                 -- abbreviations, matched ONLY next to a digit
  results = { { value = "0.3048", unit = "m" } },
},
```

- **`forms`** - spelled-out words, matched **standalone** (no digit needed). List
  every inflected form your language uses (cases, plurals): `фут, фута, футах, …`.
  Matching is case-folded via full Unicode, so don't add case variants.
- **`symbols`** - abbreviations, matched **only when adjacent to a number**
  (`6 ft`, `40 m`). Case-sensitive on purpose (`m` ≠ `M`, `in` ≠ `IN`).
- **`results`** - a list of answer lines. Each is either
  - `{ value = "1.609", unit = "km", label = "statute" }` → `1 <name> = 1.609 km - statute`
    (`label` optional), or
  - `{ text = "°F = °C × 9/5 + 32" }` → printed **verbatim** (for temperature and
    anything the `1 name = …` template doesn't fit).
- **`system` / `category`** - keys into the `strings` block for the popup header.
  Omit either to drop that header line (used for words that span systems, e.g. a
  pound that is both avoirdupois and troy).

### The popup

```
System: <strings.systems[system]>          (skipped if system is unset/unknown)
Category: <strings.categories[category]>    (skipped likewise)

1 <name> = <value> <unit> - <label>         (one line per result; or the raw text)
```

## False positives - inclusion is the filter

There is no NLP and no context analysis: if a word is in `forms`, it lights up
wherever it appears. So the dictionary itself is the filter.

- Put **short/common** abbreviations and any word that collides with ordinary
  prose into **`symbols`** (digit-gated), never `forms`. A spelled unit that is
  also a common word (e.g. Russian «бар», or English "in") should be digit-gated
  or left out entirely.
- **Drop** units that are common as words but rare as units (English "are").
- Keep genuinely unit-only spelled words (`kilometre`, `фунт`, `Fahrenheit`) in
  `forms` - they are unambiguous.
- One word, several systems? Don't invent multi-word matches (the matcher is
  single-token). Fold them into several labelled `results` and let the reader
  choose (see `mile`, `pound` in the template).

## Notes

- Values are **strings**: use your language's decimal mark (`0.3048` vs `0,3048`)
  and copy figures from [units.md](units.md), the canonical data.
- There is **no validator** - dictionaries are checked by hand before shipping, so
  proof-read your forms and values.
- Match the built-ins for structure and coverage:
  [`en.lua`](../unitlens.koplugin/dicts/en.lua),
  [`ru.lua`](../unitlens.koplugin/dicts/ru.lua).
- Full contract and rationale: [spec.md](spec.md) §4.

[ISO 639-1]: https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
