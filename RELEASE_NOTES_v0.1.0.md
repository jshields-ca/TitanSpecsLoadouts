# Titan Panel [Specs & Loadouts] v0.1.0

Initial release.

Adds a Titan Panel plugin that shows your current specialization and active talent loadout on the Titan bar, with a right-click menu to switch loadouts — including automatic cross-spec switching.

## Features

- Titan bar display: spec name (blue) + loadout name (yellow)
- Right-click menu grouped by spec, listing all saved loadouts per spec
- **Cross-spec switching** — pick a loadout under a different spec; the addon swaps your spec first, then applies the loadout
- **Same-spec switching** — instantly switch between loadouts within your current spec
- `[Current]` marker on the active loadout in the menu
- Dynamic spec icon on the Titan bar
- Left-click opens the Talents & Loadouts UI
- Tooltip with spec, loadout, and click hints

## Requirements

- WoW Retail (tested on 11.x / 12.x — Dragonflight / War Within / Midnight)
- [Titan Panel](https://www.curseforge.com/wow/addons/titan-panel)

## Installation

Place the `TitanSpecsLoadouts` folder into `_retail_/Interface/AddOns/` and enable it in your addon list.

## Notes

- In-combat spec and talent changes are blocked by Blizzard natively.
- Cross-spec switching involves a brief delay while WoW processes the spec change before the loadout is applied — this is expected.

## Links

- CurseForge: *(pending)*
- Author: [scootr.ca](https://scootr.ca) · [BlueSky](https://bsky.app/profile/scootr.ca)
