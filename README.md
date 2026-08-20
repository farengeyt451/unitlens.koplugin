<div align="center">

<img src="assets/icon.png" alt="Unit Lens icon" width="128" height="128">

# Unit Lens - a KOReader plugin

<a href="https://github.com/farengeyt451/unitconverter.koplugin/actions/workflows/test.yml"><img src="https://github.com/farengeyt451/unitconverter.koplugin/actions/workflows/test.yml/badge.svg" alt="CI"></a>
<a href="https://github.com/koreader/koreader/releases/tag/v2026.07.1"><img src="https://img.shields.io/badge/KOReader-2026.07.1-blue" alt="KOReader 2026.07.1"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License: MIT"></a>

</div>

Unit Lens provides a reference for units of measurement, allowing you to see the equivalent unit in another measurement system.
Works - **offline**, with no conversion math at runtime.

## Features

- **Offline:** No network, no AI. All data ships in the plugin
- **Dictionary-driven:** Every conversion is a precomputed string in a per-language
  dictionary
- **Configurable UI:** configurable underline, font and tooltip
- **Per-book language, translatable interface:** Book language auto-detects from
  metadata (with a manual override remembered per book); the menu itself ships in
  Russian, English and Spanish
- **User-extensible.** Drop a new `dicts/<code>.lua` in and it's discovered
  automatically - no code changes

## Install

1. Go to [releases page](https://github.com/farengeyt451/unitlens.koplugin/releases)

2. Download latest release unitlens.koplugin-x.x.x.zip

3. Unzip and copy the plugin folder into your KOReader `plugins/` directory:

   ```
   <KOReader>/plugins/unitlens.koplugin/
   ```

4. Restart KOReader. Open a book, then find **Tools ▸ Unit Lens** at the top of the
   Tools tab.

## Usage

- Open a book - supported units on the visible page are underlined
- **Tap** an underlined unit to see the conversion popup
- Tune everything under **Tools ▸ Unit Lens**: enable/disable, book language,
  interface language, underline style/thickness/intensity, tooltip timeout, size and
  detail (detailed vs. simple)

## How to extend

Both are plain Lua tables - no build step, auto-discovered on the next launch:

- **Add your custom dict:** see [docs/dictionaries.md](docs/dictionaries.md).
  Start from [`unitlens.koplugin/dicts/_template.lua`](unitlens.koplugin/dicts/_template.lua)
- **Translate the interface:** see
  [docs/interface-languages.md](docs/interface-languages.md)

Contributions of new dictionaries and translations are welcome as small,
single-file pull requests.

## How it works (in brief)

On each page change (debounced), the plugin walks the visible page into word tokens,
runs a pure matcher against the active dictionary, and draws an underline over each
hit; a tap resolves the tooltip. Results are cached per page by a rendering-hash
signature

## Development

For a local development setup, this repo includes a `docker-compose.yml` that runs
the KOReader emulator with the plugin mounted:

```bash
docker compose up -d koreader
```

The pure core (dictionaries, matcher, formatter, text utils) is testable off-device:

```bash
cd unitlens.koplugin
lua5.1 spec/run.lua        # luajit / lua5.4 also work
```

The off-device tests need `luautf8` for Unicode case-folding
(`luarocks install --local luautf8`).

Sample FB2 books that exercise the matcher (imperial / metric / mixed, in Russian and English) live in [`books/`](books/)

## Documentation

- [docs/spec.md](docs/spec.md) - architecture and design
- [docs/dictionaries.md](docs/dictionaries.md) - add custom dict (with your language)
- [docs/interface-languages.md](docs/interface-languages.md) - translate the interface
- [CHANGELOG.md](CHANGELOG.md) - notable changes per release

## Credits

Created by Alexander Kislov. Built on the KOReader / crengine document APIs.

## License

[MIT](LICENSE) © 2026 Alexander Kislov.
