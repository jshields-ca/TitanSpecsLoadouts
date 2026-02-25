# Titan Panel [Specs & Loadouts]

A Titan Panel plugin for World of Warcraft that shows your current specialization and active talent loadout on the Titan bar, and lets you quickly switch saved loadouts from the right-click menu — including automatic cross-spec switching.

Created by **scootR** — [scootr.ca](https://scootr.ca) · [BlueSky](https://bsky.app/profile/scootr.ca) · [GitHub](https://github.com/jshields-ca/TitanSpecsLoadouts)

CurseForge - [CurseForge](https://www.curseforge.com/wow/addons/titan-panel-specs-loadouts)

---

## Features

- **Titan bar display** — current spec (blue) and active loadout name (yellow) at a glance
- **Right-click menu** — loadouts grouped under each class specialization
- **Cross-spec switching** — pick a loadout under any spec; addon switches spec first, then applies the loadout
- **Same-spec loadout switching** — switch between loadouts within your current spec instantly
- **`[Current]` marker** — active loadout is highlighted in the right-click menu
- **Dynamic spec icon** — Titan bar icon updates to match your current specialization
- **Left-click** — opens the Talents & Loadouts UI
- **Tooltip** — shows current spec, loadout, and left/right click hints
- Compatible with WoW Retail (The War Within / Dragonflight)

## Requirements

- **World of Warcraft Retail**
- **Titan Panel** (required dependency)

## Installation (Manual)

1. Place the `TitanSpecsLoadouts` folder in your WoW AddOns directory:
   `_retail_/Interface/AddOns/TitanSpecsLoadouts`
2. Ensure **Titan Panel** is installed and enabled.
3. Launch the game and enable **Titan Panel [Specs & Loadouts]** on the AddOns screen.
4. Right-click the Titan bar and add the plugin if it doesn't appear automatically.

## Usage

- **Bar display** — view current spec and loadout name at a glance.
- **Left-click** — opens the Talents & Loadouts UI.
- **Right-click** — opens the spec/loadout menu. Expand a specialization to see its saved loadouts, then click to switch.

## File Layout

```
TitanSpecsLoadouts/
  TitanSpecsLoadouts.toc   -- Addon metadata and load order
  TitanSpecsLoadouts.lua   -- Core logic
  Locales.lua              -- UI strings
```

## Notes

- In combat, WoW blocks spec and talent changes natively. The addon surfaces Blizzard's own error in that case.
- Cross-spec switching involves a brief delay while the game processes the spec change — this is expected behavior.
- Uses modern Retail talent loadout APIs (`C_ClassTalents`, `C_SpecializationInfo`).

## License

All rights reserved unless a license file is added.

## Author

Created by **scootR**
- Website: [scootr.ca](https://scootr.ca)
- BlueSky: [bsky.app/profile/scootr.ca](https://bsky.app/profile/scootr.ca)
- GitHub: [github.com/jshields-ca/TitanSpecsLoadouts](https://github.com/jshields-ca/TitanSpecsLoadouts)
