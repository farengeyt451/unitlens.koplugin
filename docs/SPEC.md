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
- Interaction: scan -> wavy underline -> tap -> tooltip.

### Out of scope (MVP / non-goals)

- **No quantity math.** The popup shows a *per-unit rate*, e.g. `1 фут = 0.3048 м`.
  For `600 mm` the reader sees `1 mm = 0.0394 in`, not `600 mm = 23.62 in`. This is a
  deliberate KISS tradeoff: convey the *scale* of a unit, not compute exact values.
- **No spelled-out number parsing.** `двенадцати` is never turned into `12`. The unit
  word alone (`футах`) triggers the underline; the number is irrelevant to the result.
- No cloud, no AI, no persisted user highlights/annotations.

## 3. Core rules

### 3.1 Conversion direction — always the opposite system

Every unit in a dictionary carries its own `system` (`imperial` or `metric`). On tap we
convert **to the other system**. Consequences:

- No global "what system is this book?" detection is needed.
- **Mixed imperial/metric books work for free** — each occurrence is handled by its own unit.
- To pick which dictionary to scan with, the **script** of the text is the signal:
  Cyrillic -> Russian, Latin -> English (or simply scan with both; the matched unit
  self-identifies).

### 3.2 Detection — hybrid signal (avoiding false positives)

A token is treated as a measurement using a per-alias rule:

- **Unambiguous** unit words (`футах`, `дюймов`, `inches`, `miles`) match **standalone**.
- **Ambiguous / short** aliases (`in`, `ft`, `mi`, `stop`, `pie`) match **only when a digit
  is adjacent** (`6 ft`, `5 in`).

This makes Russian spelled-number sentences light up (`в двенадцати футах` -> `футах`
underlined) while keeping ordinary English text clean (`stopped in the doorway` -> nothing).
English pays no cost because it uses digits anyway (`6 ft`).

## 4. Dictionary format

Users author plain word data; the plugin compiles a fast lookup at load time. **No regex**
(Lua patterns have no alternation) and **no per-page pattern building**.

Authoring shape (`dicts/ru.lua`, or a user file `xx_YY.lua`):

```lua
return {
  lang = "ru",
  -- Declension endings declared once and reused across units:
  endings = { "", "а", "ов", "ам", "ах", "ом", "е" },
  units = {
    foot = { system = "imperial", to = { unit = "м",  factor = 0.3048 }, stem = "фут"  },
    inch = { system = "imperial", to = { unit = "см", factor = 2.54  },  stem = "дюйм" },
    mile = { system = "imperial", to = { unit = "км", factor = 1.609344 },
             stem = "мил", endings = { "я", "и", "ь", "ями" } },  -- per-unit override
    -- metric side (converted the opposite way, to imperial):
    metre = { system = "metric", to = { unit = "ft", factor = 3.28084 }, stem = "метр" },
    -- ambiguous/short aliases require an adjacent digit:
    -- (declared via `ambiguous = { "мил" }` or a length heuristic — see 4.1)
  },
}
```

At **load time** the loader expands `stem × endings` into a flat set:

```
forms["фут"]   = foot   forms["фута"] = foot   forms["футов"] = foot
forms["футах"] = foot   forms["футом"] = foot  ...
```

At **scan time**: split page into word tokens, case-fold (Unicode-aware), and do an
**O(1) set lookup** per token. Exact-token membership means `футбол` (a different token)
never matches — no greedy prefix issues.

### 4.1 Ambiguity

Each unit may declare `ambiguous = { ...aliases }` for forms that require an adjacent digit.
A sensible default heuristic (short aliases and known stopwords) may be applied so authors
rarely need to set this by hand.

### 4.2 User dictionaries

- Built-in `ru`/`en` are the default (the plugin works with **zero configuration**).
- A user drops `xx_YY.lua` into the plugin's dict directory to **extend or override**
  built-ins. Same format. A commented template ships with the plugin.

The canonical unit data (all categories, forms, factors) lives in
[docs/units.md](units.md) and drives the built-in dictionaries.

## 5. Architecture

Pure modules have **no KOReader dependencies** and are unit-testable off-device with `luajit`:

| Module | Kind | Responsibility |
|---|---|---|
| `converter.lua` | pure | Conversion factors + formatting -> `1 <unit> = <n> <target>`. |
| `dict.lua` | pure | Load/expand dictionaries -> `forms[token]=unitdef`, `ambiguous[token]`. |
| `matcher.lua` | pure | Apply the hybrid rule over a token array -> match indices. |
| `scanner.lua` | KOReader | Walk visible page into `{text, start_xp, end_xp}` tokens; run matcher. |
| `render.lua` | KOReader | Wrap `view.paintTo` (underline); resolve XPointers -> boxes; wrap `ui.highlight.onTap` (tap/tooltip). |
| `main.lua` | KOReader | Wiring: page-change events, menu toggle, cache, mounts. |

### 5.1 Data flow

```
page change
  -> scanner: walk visible words into XPointer tokens {text, start_xp, end_xp}
  -> matcher (pure): forms-set lookup + hybrid digit gate
  -> resolve matches to screen boxes via doc:getScreenBoxesFromPositions(start_xp, end_xp)
     (cached by rendering-hash signature)
  -> render: wrapped view.paintTo draws the wavy underline at each box
  -> on tap: wrapped ui.highlight.onTap hit-tests the point against boxes
  -> tooltip: converter -> "1 фут = 0.3048 м"
```

### 5.2 KOReader integration notes

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
5. **Extensibility & polish:** user dict directory + template; menu toggle; cache tuning.

## 8. Reference

- Unit data (all categories, forms, factors): [docs/units.md](units.md).
- Interaction/rendering approach studied from the `xray.koplugin` offline unit converter
  (paintTo overlay, `getScreenBoxesFromPositions`, `highlight.onTap`, rendering-hash cache).
