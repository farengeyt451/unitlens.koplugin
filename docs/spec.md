# Unit Lens - KOReader Plugin Specification

Status: Draft (initial). Spec-driven development - this document is the source of truth; code follows it.

## 1. Vision

An offline, zero-configuration reading companion for KOReader. While the user reads, the
plugin silently scans each visible page for measurement units, marks them with an
unobtrusive wavy underline, and - only when the reader taps one - reveals the equivalent
value in the _opposite_ measurement system.

Guiding principles:

- **Offline** - pure Lua, no network, no AI. Works on e-ink hardware.
- **KISS** - no redundant settings; automate every decision that can be automated.
- **Non-intrusive** - never break reading flow; conversion is opt-in per tap.
- **Extensible** - languages are pluggable via drop-in dictionary files.
- **Fast** - designed for weak e-ink CPUs; no per-page regex compilation.

## 2. Scope

### In scope (MVP)

- Languages: **Russian** and **English** (built-in), plus **user-provided** dictionaries.
- Category: **Length** first (inch, foot, yard, mile <-> mm, cm, m, km). Others
  (area, volume, mass, temperature, speed) use the same machinery and are added later.
- Systems: **Metric (SI)**, **US customary**, and **British imperial**. Units whose value
  differs by region (gallon, pint, fluid ounce, …) list every value as separate `results`
  lines; the popup shows them all (see §4.2) - no region detection needed.
- Interaction: scan -> wavy underline -> tap -> tooltip.

### Out of scope (MVP / non-goals)

- **No quantity math.** The popup shows a _per-unit rate_, e.g. `1 фут = 0.3048 м`.
  For `600 mm` the reader sees `1 mm = 0.0394 in`, not `600 mm = 23.62 in`. This is a
  deliberate KISS tradeoff: convey the _scale_ of a unit, not compute exact values.
- **No conversion math.** Values are **precomputed** in the dictionary (§4.2); the engine only
  matches a word and renders the stored line(s). There is no `converter` module, no runtime
  factors, no SI-base graph - the dict _is_ the source of truth.
- **No spelled-out number parsing.** `двенадцати` is never turned into `12`. The unit
  word alone (`футах`) triggers the underline; the number is irrelevant to the result.
- **No region (US vs imperial) detection.** For units that diverge by region, the popup
  lists every variant and the reader picks (see §4.2).
- No cloud, no AI, no persisted user highlights/annotations.

## 3. Core rules

### 3.1 Conversion direction - an authoring convention

The intended behaviour is: on tap, show the value in the **opposite** measurement system
(customary -> metric, metric -> customary). But because values are **precomputed in the dict**
(§4.2), this is a rule the **dictionary author** follows - not logic the engine runs. The
engine is **direction-agnostic**: it matches a word and renders the stored line(s).
Consequences:

- No global "what system is this book?" detection, and **no conversion math at all**.
- **Mixed-system books work for free** - each occurrence renders its own unit's lines.
- Each unit is authored **one-directional**: defining `foot` (-> metric) does **not** provide
  `metre` (-> customary); the metric side is its own dict entry. More entries, but fully
  explicit and WYSIWYG.
- Region divergence (US vs imperial gallon) needs **no** detection - the unit lists every
  value as separate `results` lines (§4.2).
- The active dictionary is the **book's language** - auto from metadata, or the reader is
  asked to pick when it can't be determined; user-overridable and remembered per book (§3.3).

### 3.2 Detection - spelled forms vs. symbols

A token is treated as a measurement by a single **structural** rule based on _where_ the
alias lives in the dictionary - not on any per-word risk labelling:

- **Spelled `forms`** (`футах`, `дюймов`, `inches`, `miles`) match **standalone**.
- **`symbols`** (`in`, `ft`, `mi`, bare `м`) match **only when a digit is adjacent**
  (`6 ft`, `5 in`) - an abbreviation is never spelled out inside prose.

This is **language-agnostic**: full unit words are detected in spelled-number sentences in
**any** language - Russian `в двенадцати футах` -> `футах`, English `walked several miles`
-> `miles`. Only symbols need a digit: `stopped in the doorway` stays clean because the
symbol `in` has no adjacent digit, while `6 in` / `6 ft` still fire.

Everything else about false positives is governed by **inclusion, not gating** (§4.1): a word
only underlines if its unit is in the dictionary at all. High-collision-but-common units
(`feet`, `foot`) are kept and accept the occasional false underline on `his feet`; common
words that are only _rarely_ a unit (`are`, `род`) are simply **left out** of the dictionary.

### 3.3 Language selection - one active dictionary per book

We scan with **one** dictionary: the book's language. It is resolved in order (first match
wins):

1. **Per-book choice:** if the reader already selected a language for this book, use it
   (stored in the document sidecar, so it persists across opens).
2. **Metadata:** else read the book's language metadata and map its **primary subtag**
   (`ru`, `en-GB` -> `en`) to a loaded dictionary.
3. **Ask:** if metadata is missing or has no matching dictionary, the plugin stays **idle**
   for this book and shows a one-time, dismissible notice inviting the reader to pick a
   language from the menu. The pick is then remembered per book (step 1).

We deliberately do **not** guess from script: Latin does not imply English (it could be
Spanish, German, French, …), so a wrong guess would silently mis-scan. Asking once is safer
than guessing. The language menu is always available to change the choice.

Why one dict instead of all: it removes cross-language collisions entirely (Latin `en`
_or_ Latin `es` is active, never both), keeps tooltips in the book's language, and minimizes
scan work.

**Language menu** (modeled on xray's): a submenu with `Auto` plus one radio entry per loaded
dictionary - `Auto / Russian / English` by default. It is built **dynamically**: at start
the plugin scans the dict directory, loads each dictionary, and reads its self-declared
`lang` (BCP-47 primary subtag) and `name` (endonym, e.g. "Русский", "Español") for the label.
Dropping in `es.lua` therefore makes **Español** appear automatically - no code change.

Language identity: dictionaries are keyed by their **primary language subtag** (`ru`, `en`,
`es`), normalized (lowercase, `_`/`-` collapsed). This is unambiguous for word matching.
Region variants (`en-US` vs `en-GB`) affect only a few unit **values** (US vs imperial
gallon/pint) - listed as separate `results` lines (§4.2), not word matching.

## 4. Dictionary format

Users author plain word data; the plugin compiles a fast lookup at load time. **No regex**
(Lua patterns have no alternation) and **no per-page pattern building**.

### Why not a single shared `endings` list

An earlier idea - one `endings = { "", "а", "ов", ... }` list reused for every unit - is
**rejected**, because it is simultaneously:

- **Incomplete:** Russian nouns take different endings by gender/declension class, so no
  single list fits all units. For `фут` alone a naive list misses `футу`, `футами`, `футы`.
- **Unsafe (over-generation):** blindly appending endings to a short stem can _manufacture
  an unrelated real word_ - `мил` + `а` -> `мила` ("dear"), a false positive we'd create
  ourselves.

(Note: `футе` is **not** a false positive - it is the valid prepositional singular,
"о футе". The real gaps were `футу` / `футами` / `футы`.)

### Authoring shape (`dicts/ru.lua`, or a user file `xx_YY.lua`)

Every dictionary self-declares its identity (used to build the language menu and for
auto-selection), carries a `strings` block for localized popup text (§4.3), and lists each
unit's **explicit inflected forms** plus its **precomputed `results`** (§4.2):

```lua
return {
  lang = "ru",              -- BCP-47 primary subtag; menu + auto-selection key
  name = "Русский",         -- endonym shown in the language menu

  -- Localized popup text for THIS language (§4.3). Optional; missing keys skip a line.
  strings = {
    system_label   = "Система",
    category_label = "Категория",
    systems    = { metric = "Метрическая", customary = "Американская/Британская" },
    categories = { length = "Длина", volume = "Объём" },
  },

  units = {
    metre = {
      name    = "метр",                 -- source display in the popup line
      system  = "metric",               -- key -> strings.systems  (optional metadata)
      category = "length",              -- key -> strings.categories (optional metadata)
      forms   = { "метр", "метра", "метру", "метром", "метре",
                  "метры", "метров", "метрам", "метрами", "метрах" },
      symbols = { "м" },                -- digit-gated: bare "м" needs a number (§4.1)
      results = {                       -- precomputed lines (§4.2)
        { value = "3,28084", unit = "фута" },   -- -> "1 метр = 3,28084 фута"
      },
    },
    arshin = {                          -- user-addable historical unit
      name    = "аршин",
      category = "length",              -- (no `system` -> that header line is skipped)
      forms   = { "аршин", "аршина", "аршину", "аршином", "аршине",
                  "аршины", "аршинам", "аршинами", "аршинах" },
      -- no `symbols` -> only spelled forms match; nothing is digit-gated
      results = {
        { value = "71,12",  unit = "см" },
        { value = "0,7112", unit = "м"  },
      },
    },
  },
}
```

Fields:

| field                | role                                                                       | required |
| -------------------- | -------------------------------------------------------------------------- | -------- |
| `forms`              | spelled inflected forms; **standalone** matches (§3.2)                     | yes      |
| `symbols`            | abbreviations; **digit-gated** matches (§3.2, §4.1)                        | no       |
| `name`               | source display in the popup line (author's spelling - `metre`/`meter`/`m`) | yes      |
| `results`            | ordered list of precomputed lines (§4.2)                                   | yes      |
| `system`, `category` | **keys** into the dict's `strings` for the popup header (§4.3)             | no       |

Explicit `forms` are the **source of truth** - transparent, and free of both the
incompleteness and over-generation problems above. At **load time** they compile to a flat,
de-duplicated set:

```
forms["фут"]=foot  forms["фута"]=foot  forms["футу"]=foot  forms["футами"]=foot  ...
```

At **scan time**: split page into word tokens, case-fold (Unicode-aware), and do an
**O(1) set lookup** per token. Exact-token membership means `футбол` (a different token)
never matches - no greedy prefix issues.

> Authoring aid: hand-listing ~10 forms per Russian noun is error-prone (it is easy to omit
> e.g. `футами`). An **offline** generator based on declension paradigms may be used to
> _produce_ these lists, which are then vetted and committed. The runtime only ever reads
> the explicit `forms`. The canonical data in [docs/units.md](units.md) seeds and
> cross-checks them.

### 4.1 False positives - inclusion, not gating

Some unit words are **homographs** of ordinary words, so matching them can produce false
positives. With no NLP / context analysis available offline, we **cannot** tell `his feet`
from `twelve feet`. Rather than per-form risk flags or manual overrides, the model is
deliberately blunt: **the decision to include a unit _is_ the filter.**

A unit goes into a dictionary only if it clears **both** bars:

- **Common enough as a unit** - worth converting.
- **Not hopeless as a word** - the collision cost is tolerable.

The two axes collapse into one yes/no, made once by the dict author:

| word            | common as a unit? | collision | verdict                                  |
| --------------- | ----------------- | --------- | ---------------------------------------- |
| `feet` / `foot` | yes (core)        | high      | **include** - accept the false positives |
| `are` (area)    | no (rare unit)    | extreme   | **omit** - losing it costs nothing       |
| `род` (rod)     | no (rare unit)    | extreme   | **omit**                                 |

There is **no** `risk`, `ambiguous`, or override field - a unit is either in the dict
(standalone-matchable via its `forms`) or it is not. The only automatic gate is the
**symbols rule** from §3.2: entries in `symbols` need an adjacent digit; entries in `forms`
match standalone.

```lua
metre = {
  forms   = { "метр", "метра", "метрах" },  -- standalone
  symbols = { "м" },                          -- needs an adjacent digit
}
-- "в метрах" -> matches;  "5 м" -> matches;  bare "м" in prose -> ignored
```

> **Contributor guideline.** List a unit only if it is frequent enough _as a unit_ to justify
> the occasional false underline. Skip words that are common in prose but rarely mean the unit
> (`are`, `род`). This judgment lives in the author's head, not in the data - which keeps the
> dictionaries as simple as possible.

### 4.2 Results - precomputed conversion lines

Because the plugin never parses the quantity (§2), the converted value is known at authoring
time. So each unit **stores the answer directly** - no conversion math, no SI-base factor, no
`converter` module. `results` is an ordered list; each entry renders exactly one popup line:

```lua
{ value = "<string>", unit = "<label>", label = "<optional note>" }
```

- `value` is a **string**, shown verbatim - the author controls precision _and_ the decimal
  mark (ru `"0,3048"`, en `"0.3048"`). No float formatting, no locale code in the engine.
- `unit` is the target label printed after the value (`"m"`, `"см"`, `"фута"`).
- `label` (optional) disambiguates one line among several - the region-variant case.

One entry -> one line; several entries -> several lines. This **single shape** covers both a
plain conversion and the US-vs-imperial split - there is no separate "variants" concept:

```lua
foot = {                                  -- one result -> one line
  name = "foot", system = "customary", category = "length",
  forms = { "foot", "feet" }, symbols = { "ft", "′", "'" },
  results = { { value = "0.3048", unit = "m" } },
}
gallon = {                                -- several results -> several lines
  name = "gallon", system = "customary", category = "volume",
  forms = { "gallon", "gallons" }, symbols = { "gal" },
  results = {
    { value = "3.785", unit = "L", label = "US liquid" },
    { value = "4.405", unit = "L", label = "US dry"   },
    { value = "4.546", unit = "L", label = "imperial" },
  },
}
```

**Render template** per line: `1 {name} = {value} {unit}`, appending ` - {label}` only when a
`label` is present. So `gallon` renders three labelled lines; `foot` renders one.

Direction is an **authoring convention** (§3.1): the author picks the target, so defining
`foot` does not auto-provide `metre` - the metric side is its own entry.

### 4.3 Display strings - the `strings` block

The active dict is also the **translation source** for the popup header. A dict-level
`strings` block localizes the two field labels and maps the `system`/`category` **keys** to
visible text:

```lua
strings = {
  system_label   = "Система",
  category_label = "Категория",
  systems    = { metric = "Метрическая", customary = "Американская/Британская" },
  categories = { length = "Длина", volume = "Объём" },
}
```

The full popup for a matched unit is the header (from `strings`) followed by its `results`:

```
Система: Метрическая
Категория: Длина

1 фут = 0,3048 метра
```

Rules:

- **Keys vs. text stay separated.** A unit stores stable keys (`system = "metric"`); the
  visible string comes from `strings.systems[key]` / `strings.categories[key]` in the active
  dict. A user adding `system = "history"` just adds `history = "Историческая"` to `strings`.
- **Graceful skip.** If a unit omits `system`/`category`, or `strings` has no entry for the
  key, that header line is simply **not shown** - so a minimal user unit with no metadata
  still renders just its result line(s). `strings` itself is optional.
- **Extensible.** The same block may later carry other UI text (the "language not detected"
  notice, menu labels); for now it holds only `system`/`category`.

### 4.4 User dictionaries

- Built-in `ru`/`en` are the default (the plugin works with **zero configuration**).
- A user drops `xx_YY.lua` into the plugin's dict directory to **extend or override**
  built-ins. Same format. A commented template ships with the plugin.
- Values are **hand-authored and manually verified** before shipping - there is no runtime
  validator (a deliberate KISS choice). [docs/units.md](units.md) is the canonical reference
  the built-in dicts are checked against.

The canonical unit data (all categories, forms, values) lives in
[docs/units.md](units.md) and drives the built-in dictionaries.

## 5. Architecture

The engine is deliberately small: a **matcher + renderer over dumb dicts**. The **pure core**
has no KOReader dependencies and is unit-testable off-device with `luajit`; the **integration
layer** touches KOReader APIs.

```
   DATA                 PURE CORE  (luajit-testable)              KOREADER INTEGRATION
 ┌──────────┐         ┌──────────────────────────────┐         ┌───────────────────────┐
 │ dicts/   │  load   │ ul_dict.lua                  │  active │ ul_langselect.lua     │
 │  en.lua  │────────▶│  load + flatten:             │◀────────│  pick active dict per │
 │  ru.lua  │         │  forms[] · symbols[] ·        │  lang   │  book (meta/menu/ask) │
 │  xx_YY   │         │  units[] · strings           │         └───────────┬───────────┘
 └──────────┘         └───────────────┬──────────────┘                     │
                       compiled dict  │                                     │
                                      ▼                                     │
                      ┌──────────────────────────────┐        page tokens  │
                      │ ul_matcher.lua               │◀───────────────┐     │
                      │  forms standalone /           │                │     │
                      │  symbols need a digit         │──── matches ──▶│     │
                      └───────────────┬──────────────┘   (unit+span)  │     │
                                      ▼                                │     │
                      ┌──────────────────────────────┐                │     │
                      │ ul_format.lua                │                │     │
                      │  unit + strings -> popup text │                │     │
                      └───────────────┬──────────────┘                │     │
                            popup text│                                │     │
 ┌─────────────────────────────────────────────────────────────┐     │     │
 │ INTEGRATION            │                        │            │     │     │
 │  ul_scanner.lua ─tokens┘   ul_render.lua ◀─text─┘            │     │     │
 │  page -> XPointer          underline overlay +               │─────┘     │
 │  word tokens               tap -> tooltip                    │           │
 └───────────────────────────────┬─────────────────────────────┘           │
                                  │ events · cache · menu · lifecycle       │
                      ┌───────────┴──────────────────────────────────────────┘
                      │ main.lua  (KOReader wiring)
                      └──────────────────────────────────────────────────────
```

| Module              | Kind     | Responsibility                                                                                                                                                                                            |
| ------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ul_dict.lua`       | pure     | Load dictionaries; flatten `forms` -> standalone `forms[token]=unitdef` and `symbols` -> digit-gated `symbols[token]=unitdef`; expose each dict's `units`, `strings`, `lang`, `name`.                     |
| `ul_matcher.lua`    | pure     | Apply the forms-standalone / symbols-need-digit rule over a token array -> matches (unit + token span).                                                                                                   |
| `ul_format.lua`     | pure     | Build popup text from a matched unit + the dict's `strings`: header (`system`/`category`, with graceful skip) + one line per `results` entry. Replaces the old converter - pure string assembly, no math. |
| `ul_langselect.lua` | KOReader | Resolve the active **book** language (per-book choice -> metadata -> ask); build its menu items; persist the choice in the document sidecar; prompt when undetectable.                                    |
| `ul_i18n.lua`       | KOReader | Resolve/activate the **interface** language (global, "auto" follows the app); `t()` lookup with English fallback; auto-discover `l10n/*.lua`; build its menu items.                                       |
| `ul_settings.lua`   | KOReader | Read/write global settings (`G_reader_settings`) with defaults: enable, underline style/thickness/intensity, tooltip timeout, interface language.                                                         |
| `ul_menu.lua`       | KOReader | Build the **Unit Lens ▸** submenu (enable toggle, Language, style/thickness/intensity, tooltip timeout, About) from plugin state.                                                                         |
| `ul_scanner.lua`    | KOReader | Walk visible page into `{text, start_xp, end_xp}` tokens; run matcher against the active dict.                                                                                                            |
| `ul_render.lua`     | KOReader | Wrap `view.paintTo` (underline, style/thickness/intensity from settings); resolve XPointers -> boxes; wrap `ui.highlight.onTap`; show the `ul_format.lua` tooltip (timeout from settings).                |
| `main.lua`          | KOReader | Wiring: page-change events, menu, settings, cache, lifecycle.                                                                                                                                             |

> **Module naming.** Every plugin module is prefixed `ul_` (Unit Lens). KOReader loads
> all plugins into a **shared `package.loaded`**, and it already owns generic names such as
> `util` (`frontend/util.lua`), so a bare `require("util")` would return KOReader's module,
> not ours. Unique prefixes avoid this collision. The two exceptions are fixed by KOReader:
> the entry point must be `main.lua`, and dictionaries live under `dicts/` (loaded as
> `require("dicts.<lang>")`).

### 5.1 Data flow

```
page change
  -> scanner: walk visible words into XPointer tokens {text, start_xp, end_xp}
  -> matcher (pure): forms-set lookup (standalone) + symbols digit gate -> matches
  -> resolve matches to screen boxes via doc:getScreenBoxesFromPositions(start_xp, end_xp)
     (cached by rendering-hash signature)
  -> render: wrapped view.paintTo draws the wavy underline at each box
  -> on tap: wrapped ui.highlight.onTap hit-tests the point against boxes
  -> ul_format.lua: unit + dict.strings -> "Система: … / Категория: … / 1 фут = 0,3048 м"
  -> tooltip shows the assembled text
```

### 5.2 KOReader integration notes

- **Language menu & memory:** a submenu of radio entries (`checked_func` + `callback`),
  built by scanning the dict directory; the per-book choice is stored in the document
  sidecar (`DocSettings`) and re-applied on open.
- **Book language metadata:** read via `doc:getProps()` (e.g. `.language`); normalize its
  primary subtag to match a dict `lang`.
- **Underline overlay:** wrap `self.ui.view.paintTo`; after the page is drawn, paint
  underlines onto the blitbuffer. No annotations are created or persisted.
- **Screen positions:** `doc:getScreenBoxesFromPositions(start_xp, end_xp, true)` -> `{x,y,w,h}`.
- **Tap:** wrap `self.ui.highlight.onTap`; on hit return handled, else defer to the original.
- **Word walking:** crengine word-navigation (`getPrevVisibleWordStart` /
  `getTextFromXPointers`) yields an exact XPointer per token.

### 5.4 Settings & menu

All plugin UI lives under a single **Unit Lens ▸** entry at the top of KOReader's Tools tab
(like X-Ray), built as a standard nested menu (`sub_item_table`) - no bespoke dialog. To get the
top slot we insert our id at the front of the shared `reader_menu_order.tools` singleton on init
(`sorting_hint = "tools"` alone only appends us as an orphan after "More tools"). Layout:

```
Unit Lens ▸
  ☑ Highlight measurement units            enable/disable
  Book language ▸       ◉ Auto (from book) · English · Русский · … (one per dict)
  Interface language ▸  ◉ Auto (system) · English · Русский · Español · … (one per l10n file)
  Underline style ▸ ◉ Wavy · Solid · Dotted · Dashed · Double · None
  Underline thickness ▸  1px · ◉ 2px · 3px
  Underline intensity ▸  Light · ◉ Medium · Dark
  Tooltip timeout ▸      2s · ◉ 4s · 8s · Never
  About                                    version + credits
```

**Two languages, kept distinct.** _Book language_ (`ul_langselect`) picks which
`dicts/` dictionary scans the page - it is per-book and drives detection and the
tooltip's wording (from the dict's `strings`). _Interface language_ (`ul_i18n`)
translates the plugin's own menu, About and notifications - it is global and
defaults to `auto` (follow KOReader's app language, English fallback).

**Interface translations** live in `l10n/<code>.lua` as
`{ name = <endonym>, strings = { [english] = translated } }`; keys are the English
source string and missing keys fall back to English. Files are auto-discovered by
scanning `l10n/`, so a new language is a one-file PR with no code changes
(`en.lua` is the canonical, complete key list - see `l10n/README.md`).

| Setting             | Key (`unitlens_`)         | Values                               | Default  | Scope        |
| ------------------- | ------------------------- | ------------------------------------ | -------- | ------------ |
| Enabled             | `enabled`                 | bool                                 | `true`   | global       |
| Underline style     | `underline_style`         | wavy/solid/dotted/dashed/double/none | `wavy`   | global       |
| Underline thickness | `underline_thickness`     | 1/2/3 (px)                           | `2`      | global       |
| Underline intensity | `underline_intensity`     | light/medium/dark (grey)             | `medium` | global       |
| Tooltip timeout     | `tooltip_timeout`         | 2/4/8/0 (0 = never, seconds)         | `4`      | global       |
| Tooltip text size   | `tooltip_text_size`       | auto/smallest(−4)/smaller(−2)/bigger(+2)/biggest(+4) | `auto`   | global       |
| Tooltip content     | `tooltip_detail`          | detailed (header + conversion) / simple (conversion only) | `detailed` | global |
| Interface language  | `ui_lang`                 | `auto` or an l10n code               | `auto`   | global       |
| Book language       | `unitlens_lang` (sidecar) | `auto` or a dict code                | `auto`   | **per-book** |

Appearance settings persist globally via `G_reader_settings`; the language choice is
per-book in the document sidecar (`DocSettings`). `ul_render` reads the appearance values
at paint/tooltip time, so changes apply on the next repaint without a rescan; changing the
language, the enable toggle, or *Tooltip content* (the popup text is baked into the match
records at scan time) triggers a rescan.

**Tooltip typography** follows the reader instead of a hardcoded value: the size is the
book's active body font size (`document.configurable.font_size`, global `cre_font_size`
fallback), optionally nudged by *Tooltip text size*, and clamped for sanity. The face is
KOReader's `cfont` content-font alias — `Font:getFace` resolves aliases/filenames, not
crengine font-family names, so the book's actual family can't be reused reliably. Note
`Font:getFace` scales the size by screen DPI internally, so a **raw** point size is passed.

### 5.3 UTF-8 pitfalls (must handle)

Lua's `%a` and `string.lower` are ASCII-only. Therefore:

- Tokenize on whitespace/punctuation (Cyrillic bytes are non-ASCII and survive).
- **Case-fold via a full-Unicode library, never a hand-rolled case table.** On device
  `ul_util.casefold` delegates to KOReader's bundled **`ffi/utf8proc`** (`Utf8Proc.lowercase`);
  off-device the pure-core tests use **`luautf8`** (`luarocks install --local luautf8`,
  module `lua-utf8`). No silent ASCII fallback - `ul_util.lua` errors if neither is present, so
  we never half-match non-Latin text. This is what lets a user drop in _any_ language dict.
- Truncate strings on UTF-8 character boundaries, never raw bytes.

## 6. Caching

- Scan/box results are cached in memory, keyed by a **signature** that includes
  `doc:getDocumentRenderingHash()` + current position + screen width/height.
- Changing font, margins, page, or screen size changes the hash -> cache auto-invalidates.
  This sidesteps the fact that EPUB page numbers are **not stable** across reflow.
- Cache is dropped on document close. No time-based or page-count-based cleaning needed.

## 7. Milestones

1. **Pure core (off-device, spec-driven):** `ul_dict.lua` + `dicts/{ru,en}.lua`, `ul_matcher.lua`,
   `ul_format.lua`; tests over sample RU/EN sentences and expected popup text.
2. **Live scan (device, log only):** hook page-change; walk page to XPointer tokens; run
   matcher; log matches.
3. **Underline rendering:** `paintTo` overlay; XPointers -> boxes (cached); draw wavy line.
4. **Tap -> tooltip:** wrap `onTap`; hit-test; show the `ul_format.lua` text.
5. **Language selection & settings menu:** `ul_langselect.lua` - book language auto from metadata
   (ask when undetectable), dynamic menu, per-book override in the sidecar. `ul_i18n.lua` + `l10n/` —
   interface translations (global, auto-follows the app; contributor-friendly one-file PRs).
   `ul_menu.lua` + `ul_settings.lua` - a dedicated **Unit Lens ▸** submenu at the top of Tools with
   the enable toggle, Book language, Interface language, underline style/thickness/intensity, tooltip
   timeout, and About (version + credits). See §5.4.
6. **Extensibility & polish:** user dict directory + template; digit-gated `600 мм` splitter; cache tuning.

## 8. Reference

- Unit data (all categories, forms, values): [docs/units.md](units.md).
- Interaction/rendering approach studied from the `xray.koplugin` offline unit converter
  (paintTo overlay, `getScreenBoxesFromPositions`, `highlight.onTap`, rendering-hash cache).
