# Unit Lens - a KOReader plugin

Unit Lens quietly underlines the measurement units on the page you're reading and,
on a tap, shows their equivalent in the other measurement system - **offline**, with
no conversion math at runtime.

It reads like a lens laid over the text: units are recognised and their precomputed
equivalents revealed, without pulling you out of the book.

## Features

- **Offline & private.** No network, no AI. All data ships in the plugin.
- **Dictionary-driven.** Every conversion is a precomputed string in a per-language
  dictionary - the engine matches words and renders those strings, nothing more.
- **Two match paths.** Spelled words (`двенадцати футах`, `several miles`) match
  standalone; short symbols (`600 mm`, `6 ft`) only match next to a number, to avoid
  false positives.
- **Broad coverage.** Length, mass, volume, area and temperature across metric (SI),
  US customary, British imperial, and old-Russian measures (верста, пуд, …).
- **Reader-native UI.** A configurable underline (wavy/solid/dotted/dashed/double)
  and a compact tap tooltip that follows your book's font.
- **Per-book language, translatable interface.** Book language auto-detects from
  metadata (with a manual override remembered per book); the menu itself ships in
  English, Russian and Spanish.
- **User-extensible.** Drop a new `dicts/<code>.lua` in and it's discovered
  automatically - no code changes.

## Install

Copy the plugin folder into your KOReader `plugins/` directory:

```
<KOReader>/plugins/unitlens.koplugin/
```

Restart KOReader. Open a book, then find **Tools ▸ Unit Lens** at the top of the
Tools tab.

For a local development setup, this repo includes a `docker-compose.yml` that runs
the KOReader emulator with the plugin mounted:

```bash
docker compose up -d koreader
```

## Usage

- Open a book - supported units on the visible page are underlined.
- **Tap** an underlined unit to see the conversion popup.
- Tune everything under **Tools ▸ Unit Lens**: enable/disable, book language,
  interface language, underline style/thickness/intensity, tooltip timeout, size and
  detail (detailed vs. simple).

## How to extend

Both are plain Lua tables - no build step, auto-discovered on the next launch:

- **Add a book language** (which units are detected): see
  [docs/dictionaries.md](docs/dictionaries.md). Start from
  [`unitlens.koplugin/dicts/_template.lua`](unitlens.koplugin/dicts/_template.lua).
- **Translate the interface** (menu, About, notifications): see
  [docs/interface-languages.md](docs/interface-languages.md).

Contributions of new dictionaries and translations are welcome as small,
single-file pull requests.

## How it works (in brief)

On each page change (debounced), the plugin walks the visible page into word tokens,
runs a pure matcher against the active dictionary, and draws an underline over each
hit; a tap resolves the tooltip. Results are cached per page by a rendering-hash
signature. The full design is in [docs/spec.md](docs/spec.md); the canonical unit
data (forms, symbols, values) is in [docs/units.md](docs/units.md).

## Development

The pure core (dictionaries, matcher, formatter, text utils) is testable off-device:

```bash
cd unitlens.koplugin
lua5.1 spec/run.lua        # luajit / lua5.4 also work
```

The off-device tests need `luautf8` for Unicode case-folding
(`luarocks install --local luautf8`). Sample FB2 books that exercise the matcher
(imperial / metric / mixed, in Russian and English) live in [`books/`](books/).

## Documentation

- [docs/spec.md](docs/spec.md) - architecture and design.
- [docs/units.md](docs/units.md) - canonical unit reference (all categories).
- [docs/dictionaries.md](docs/dictionaries.md) - add a book language.
- [docs/interface-languages.md](docs/interface-languages.md) - translate the interface.

## Credits

Created by Alexander Kislov. Built on the KOReader / crengine document APIs.

## License

[MIT](LICENSE) © 2026 Alexander Kislov.
