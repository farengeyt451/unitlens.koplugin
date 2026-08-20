# Translating the interface (`unitlens.koplugin/l10n/`)

These files translate the plugin's **interface** - its menu, the About box and
notifications. This is separate from the **book dictionaries** (the dictionaries in
`dicts/`, which decide _which units are detected_ on the page - see
[dictionaries.md](dictionaries.md)).

- **Interface language** → `unitlens.koplugin/l10n/<code>.lua`. Global setting
- **Book dictionaries** → `unitlens.koplugin/dicts/<code>.lua`. Per-book setting

## Add or update a language

1. Copy [`en.lua`](../unitlens.koplugin/l10n/en.lua) to `l10n/<code>.lua`, where
   `<code>` is the language's [ISO 639-1] code (`de`, `fr`, `pt`, …). `en.lua` is
   the canonical, always-complete list of strings
2. Set `name` to the language's **own** endonym - this is what shows in the menu
   (e.g. `"Deutsch"`, `"Français"`, `"Português"`). Show the language in itself,
   not in English
3. Translate the **values**. Keep the **keys** exactly - they are the English
   source string and the lookup key
4. That's it. The file is auto-discovered; the language appears under
   **Tools ▸ Unit Lens ▸ Interface language** on the next launch

```lua
-- l10n/de.lua
return {
  name = "Deutsch",
  strings = {
    ["Highlight measurement units"] = "Maßeinheiten hervorheben",
    ["Underline style"]             = "Unterstreichungsstil",
    -- any key you omit falls back to the English source, so partial is fine
  },
}
```

## Notes

- Missing keys fall back to English automatically - partial translations are OK
- `Auto (system)` follows KOReader's own app language and resolves to the closest
  shipped file, or English if none matches
- Keep the `▸` arrows and punctuation in menu-path strings so they read naturally
- Keep translations plain and short so they fit e-ink menus

[ISO 639-1]: https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
