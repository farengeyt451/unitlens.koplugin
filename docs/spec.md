# Unit Converter — KOReader Plugin Specification

Status: Draft (initial). Spec-driven development — this document is the source of truth; code follows it.

## 1. Vision

An offline, zero-configuration reading companion for KOReader. While the user reads, the
plugin silently scans each visible page for measurement units, marks them with an
unobtrusive wavy underline, and — only when the reader taps one — reveals the equivalent
value in the *opposite* measurement system.

Guiding principles:

- **Offline** — pure Lua, no network, no AI. Works on e-ink hardware.
- **KISS** — no redundant settings; automate every decision that can be automated.
- **Non-intrusive** — never break reading flow; conversion is opt-in per tap.
- **Extensible** — languages are pluggable via drop-in dictionary files.
- **Fast** — designed for weak e-ink CPUs; no per-page regex compilation.

## 2. Scope

### In scope (MVP)

- Languages: **Russian** and **English** (built-in), plus **user-provided** dictionaries.
- Category: **Length** first (inch, foot, yard, mile <-> mm, cm, m, km). Others
  (area, volume, mass, temperature, speed) use the same machinery and are added later.
- Systems: **Metric (SI)**, **US customary**, and **British imperial**. Units whose value
  differs by region (gallon, pint, fluid ounce, …) carry all variants; the popup lists them
  all (see §4.2) — no region detection needed.
- Interaction: scan -> wavy underline -> tap -> tooltip.

### Out of scope (MVP / non-goals)

- **No quantity math.** The popup shows a *per-unit rate*, e.g. `1 фут = 0.3048 м`.
  For `600 mm` the reader sees `1 mm = 0.0394 in`, not `600 mm = 23.62 in`. This is a
  deliberate KISS tradeoff: convey the *scale* of a unit, not compute exact values.
- **No spelled-out number parsing.** `двенадцати` is never turned into `12`. The unit
  word alone (`футах`) triggers the underline; the number is irrelevant to the result.
- **No region (US vs imperial) detection.** For units that diverge by region, the popup
  lists every variant and the reader picks (see §4.2).
- No cloud, no AI, no persisted user highlights/annotations.

## 3. Core rules

### 3.1 Conversion direction — always the opposite system

Each unit belongs to a measurement **system** — `metric`, or `customary` (the US / British
imperial family). On tap we convert **to the other side**: customary -> metric, metric ->
customary. Consequences:

- No global "what system is this book?" detection is needed.
- **Mixed-system books work for free** — each occurrence is handled by its own unit.
- The active dictionary is the **book's language** — auto from metadata, or the reader is
  asked to pick when it can't be determined; user-overridable and remembered per book
  (see §3.3).
- Units whose value differs by region (US vs imperial — gallon, pint, …) need **no** region
  detection: the popup **lists every variant** (§4.2), symmetrically in both directions.

### 3.2 Detection — spelled forms vs. symbols

A token is treated as a measurement by a single **structural** rule based on *where* the
alias lives in the dictionary — not on any per-word risk labelling:

- **Spelled `forms`** (`футах`, `дюймов`, `inches`, `miles`) match **standalone**.
- **`symbols`** (`in`, `ft`, `mi`, bare `м`) match **only when a digit is adjacent**
  (`6 ft`, `5 in`) — an abbreviation is never spelled out inside prose.

This is **language-agnostic**: full unit words are detected in spelled-number sentences in
**any** language — Russian `в двенадцати футах` -> `футах`, English `walked several miles`
-> `miles`. Only symbols need a digit: `stopped in the doorway` stays clean because the
symbol `in` has no adjacent digit, while `6 in` / `6 ft` still fire.

Everything else about false positives is governed by **inclusion, not gating** (§4.1): a word
only underlines if its unit is in the dictionary at all. High-collision-but-common units
(`feet`, `foot`) are kept and accept the occasional false underline on `his feet`; common
words that are only *rarely* a unit (`are`, `род`) are simply **left out** of the dictionary.

### 3.3 Language selection — one active dictionary per book

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
*or* Latin `es` is active, never both), keeps tooltips in the book's language, and minimizes
scan work.

**Language menu** (modeled on xray's): a submenu with `Auto` plus one radio entry per loaded
dictionary — `Auto / Russian / English` by default. It is built **dynamically**: at start
the plugin scans the dict directory, loads each dictionary, and reads its self-declared
`lang` (BCP-47 primary subtag) and `name` (endonym, e.g. "Русский", "Español") for the label.
Dropping in `es.lua` therefore makes **Español** appear automatically — no code change.

Language identity: dictionaries are keyed by their **primary language subtag** (`ru`, `en`,
`es`), normalized (lowercase, `_`/`-` collapsed). This is unambiguous for word matching.
Region variants (`en-US` vs `en-GB`) affect only a few conversion factors (US vs imperial
gallon/pint), not word matching — deferred as a later refinement.

## 4. Dictionary format

Users author plain word data; the plugin compiles a fast lookup at load time. **No regex**
(Lua patterns have no alternation) and **no per-page pattern building**.

### Why not a single shared `endings` list

An earlier idea — one `endings = { "", "а", "ов", ... }` list reused for every unit — is
**rejected**, because it is simultaneously:

- **Incomplete:** Russian nouns take different endings by gender/declension class, so no
  single list fits all units. For `фут` alone a naive list misses `футу`, `футами`, `футы`.
- **Unsafe (over-generation):** blindly appending endings to a short stem can *manufacture
  an unrelated real word* — `мил` + `а` -> `мила` ("dear"), a false positive we'd create
  ourselves.

(Note: `футе` is **not** a false positive — it is the valid prepositional singular,
"о футе". The real gaps were `футу` / `футами` / `футы`.)

### Authoring shape (`dicts/ru.lua`, or a user file `xx_YY.lua`)

Every dictionary self-declares its identity (used to build the language menu and for
auto-selection) and lists the **explicit inflected forms** of each unit:

```lua
return {
  lang = "ru",          -- BCP-47 primary subtag; menu + auto-selection key
  name = "Русский",     -- endonym shown in the language menu
  units = {
    foot = {
      system = "customary", to = { unit = "м" }, factor = 0.3048,
      forms = { "фут", "фута", "футу", "футом", "футе",
                "футы", "футов", "футам", "футами", "футах" },
      symbols = { "ft" },            -- short -> requires an adjacent digit (§4.1)
    },
    inch = {
      system = "customary", to = { unit = "см" }, factor = 2.54,
      forms = { "дюйм", "дюйма", "дюйму", "дюймом", "дюйме",
                "дюймы", "дюймов", "дюймам", "дюймами", "дюймах" },
      symbols = { "in" },
    },
    metre = {   -- metric side, converted the opposite way (to customary)
      system = "metric", to = { unit = "ft" }, factor = 3.28084,
      forms = { "метр", "метра", "метру", "метром", "метре",
                "метры", "метров", "метрам", "метрами", "метрах" },
      symbols = { "м" },             -- bare "м" is ambiguous -> needs a digit
    },
  },
}
```

Explicit `forms` are the **source of truth** — transparent, and free of both the
incompleteness and over-generation problems above. At **load time** they compile to a flat,
de-duplicated set:

```
forms["фут"]=foot  forms["фута"]=foot  forms["футу"]=foot  forms["футами"]=foot  ...
```

At **scan time**: split page into word tokens, case-fold (Unicode-aware), and do an
**O(1) set lookup** per token. Exact-token membership means `футбол` (a different token)
never matches — no greedy prefix issues.

> Authoring aid: hand-listing ~10 forms per Russian noun is error-prone (it is easy to omit
> e.g. `футами`). An **offline** generator based on declension paradigms may be used to
> *produce* these lists, which are then vetted and committed. The runtime only ever reads
> the explicit `forms`. The canonical data in [docs/units.md](units.md) seeds and
> cross-checks them.

### 4.1 False positives — inclusion, not gating

Some unit words are **homographs** of ordinary words, so matching them can produce false
positives. With no NLP / context analysis available offline, we **cannot** tell `his feet`
from `twelve feet`. Rather than per-form risk flags or manual overrides, the model is
deliberately blunt: **the decision to include a unit *is* the filter.**

A unit goes into a dictionary only if it clears **both** bars:

- **Common enough as a unit** — worth converting.
- **Not hopeless as a word** — the collision cost is tolerable.

The two axes collapse into one yes/no, made once by the dict author:

| word | common as a unit? | collision | verdict |
|---|---|---|---|
| `feet` / `foot` | yes (core) | high | **include** — accept the false positives |
| `are` (area) | no (rare unit) | extreme | **omit** — losing it costs nothing |
| `род` (rod) | no (rare unit) | extreme | **omit** |

There is **no** `risk`, `ambiguous`, or override field — a unit is either in the dict
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

> **Contributor guideline.** List a unit only if it is frequent enough *as a unit* to justify
> the occasional false underline. Skip words that are common in prose but rarely mean the unit
> (`are`, `род`). This judgment lives in the author's head, not in the data — which keeps the
> dictionaries as simple as possible.

### 4.2 Unit value: `factor` or `variants`

A unit resolves to its SI base via **either** a single `factor` (value is region-invariant)
**or** an ordered `variants` list (value differs by region — the US-vs-imperial split):

```lua
foot = {                                  -- invariant: US == imperial
  category = "length", system = "customary",
  forms = { "foot", "feet" }, symbols = { "ft" },
  to = { unit = "m" }, factor = 0.3048,   -- single line: "1 foot = 0.3048 m"
},
gallon = {                                -- divergent: value depends on region
  category = "volume", system = "customary",
  forms = { "gallon", "gallons" }, symbols = { "gal" },
  to = { unit = "L" },                    -- SI target unit shown in the popup
  variants = {                            -- ordered -> deterministic popup order
    { label = "U.S. liquid", factor = 3.785411784 },
    { label = "U.S. dry",    factor = 4.40488377  },
    { label = "imperial",    factor = 4.54609     },
  },
},
```

We do **not** detect the book's region. For a `variants` unit the popup **lists every
variant** and the reader picks the relevant one:

```
1 gallon =
  3.785 L — U.S. liquid
  4.405 L — U.S. dry
  4.546 L — imperial
```

This is symmetric — tapping a metric unit lists all customary equivalents likewise
(`1 л = 0.264 US liq / 0.227 US dry / 0.220 imp gal`). Labels live in the dictionary, so a
Russian `галлон` entry carries Russian labels — no code branching. Invariant units (a plain
`factor`) render a single line.

Milestone note: length-first needs only the `factor` path; `variants` is first exercised at
the volume milestone, with no rework to the schema.

### 4.3 User dictionaries

- Built-in `ru`/`en` are the default (the plugin works with **zero configuration**).
- A user drops `xx_YY.lua` into the plugin's dict directory to **extend or override**
  built-ins. Same format. A commented template ships with the plugin.

The canonical unit data (all categories, forms, factors) lives in
[docs/units.md](units.md) and drives the built-in dictionaries.

## 5. Architecture

Pure modules have **no KOReader dependencies** and are unit-testable off-device with `luajit`:

| Module | Kind | Responsibility |
|---|---|---|
| `converter.lua` | pure | Conversion factors + formatting -> `1 <unit> = <n> <target>`; one labeled line per variant for divergent units. |
| `dict.lua` | pure | Load dictionaries; expand `forms` -> standalone `forms[token]=unitdef` and `symbols` -> digit-gated `symbols[token]=unitdef`; expose each dict's `lang`/`name`. |
| `matcher.lua` | pure | Apply the forms-standalone / symbols-need-digit rule over a token array -> match indices. |
| `langselect.lua` | KOReader | Resolve the active language (per-book choice -> metadata -> ask); build the language menu; persist the choice in the document sidecar; prompt when undetectable. |
| `scanner.lua` | KOReader | Walk visible page into `{text, start_xp, end_xp}` tokens; run matcher against the active dict. |
| `render.lua` | KOReader | Wrap `view.paintTo` (underline); resolve XPointers -> boxes; wrap `ui.highlight.onTap` (tap/tooltip). |
| `main.lua` | KOReader | Wiring: page-change events, menus, cache, mounts. |

### 5.1 Data flow

```
page change
  -> scanner: walk visible words into XPointer tokens {text, start_xp, end_xp}
  -> matcher (pure): forms-set lookup (standalone) + symbols digit gate
  -> resolve matches to screen boxes via doc:getScreenBoxesFromPositions(start_xp, end_xp)
     (cached by rendering-hash signature)
  -> render: wrapped view.paintTo draws the wavy underline at each box
  -> on tap: wrapped ui.highlight.onTap hit-tests the point against boxes
  -> tooltip: converter -> "1 фут = 0.3048 м"
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

### 5.3 UTF-8 pitfalls (must handle)

Lua's `%a` and `string.lower` are ASCII-only. Therefore:

- Tokenize on whitespace/punctuation (Cyrillic bytes are non-ASCII and survive).
- Case-fold with KOReader's Unicode helper, not `string.lower`.
- Truncate strings on UTF-8 character boundaries, never raw bytes.

## 6. Caching

- Scan/box results are cached in memory, keyed by a **signature** that includes
  `doc:getDocumentRenderingHash()` + current position + screen width/height.
- Changing font, margins, page, or screen size changes the hash -> cache auto-invalidates.
  This sidesteps the fact that EPUB page numbers are **not stable** across reflow.
- Cache is dropped on document close. No time-based or page-count-based cleaning needed.

## 7. Milestones

1. **Pure core (off-device, spec-driven):** `converter.lua`, `dict.lua` + `dicts/{ru,en}.lua`,
   `matcher.lua`; tests over sample RU/EN sentences.
2. **Live scan (device, log only):** hook page-change; walk page to XPointer tokens; run
   matcher; log matches.
3. **Underline rendering:** `paintTo` overlay; XPointers -> boxes (cached); draw wavy line.
4. **Tap -> tooltip:** wrap `onTap`; hit-test; show rate string.
5. **Language selection:** `langselect.lua` — auto from metadata (ask when undetectable), dynamic
   language menu, per-book override remembered in the sidecar.
6. **Extensibility & polish:** user dict directory + template; menu toggle; cache tuning.

## 8. Reference

- Unit data (all categories, forms, factors): [docs/units.md](units.md).
- Interaction/rendering approach studied from the `xray.koplugin` offline unit converter
  (paintTo overlay, `getScreenBoxesFromPositions`, `highlight.onTap`, rendering-hash cache).
