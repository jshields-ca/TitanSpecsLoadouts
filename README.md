# Titan Panel [Specs & Loadouts]

Titan Panel plugin for World of Warcraft that shows your current specialization and active talent loadout, and lets you quickly switch saved loadouts from Titan's right-click menu.

## Features

- Titan bar text shows: **Spec + Active Loadout**
- Right-click menu groups saved loadouts under each specialization
- Cross-spec selection: automatically switches spec, then applies chosen loadout
- Minimal workflow: no need to open the Talents window for routine swaps

## Folder Layout

- `TitanSpecsLoadouts/`
  - `TitanSpecsLoadouts.toc`
  - `TitanSpecsLoadouts.lua`
  - `Locales.lua`

## Installation (Manual)

1. Place this repository's `TitanSpecsLoadouts` folder in your WoW AddOns directory:
   - `_retail_/Interface/AddOns/TitanSpecsLoadouts`
2. Ensure dependencies are enabled:
   - `Titan Panel`
3. Launch the game and enable **Titan Panel [Specs & Loadouts]** on the AddOns screen.

## Usage

- Add the plugin on Titan Panel if not auto-shown.
- View current spec/loadout directly on the Titan bar.
- Right-click the plugin:
  - Expand a specialization
  - Select one of its saved loadouts

## Notes

- In combat, WoW may block talent/spec changes; this addon intentionally relies on native WoW restriction/error behavior.
- Requires the modern talent loadout APIs available in current retail builds.

## Development

This addon is intentionally lightweight and self-contained.

- Main logic: `TitanSpecsLoadouts/TitanSpecsLoadouts.lua`
- Metadata: `TitanSpecsLoadouts/TitanSpecsLoadouts.toc`
- Strings: `TitanSpecsLoadouts/Locales.lua`

## License

All rights reserved unless a license file is added.
