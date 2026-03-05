# Titan Panel [Specs & Loadouts] v0.1.1

Bug-fix release. No new features.

## What's fixed

### Cross-spec loadout switching now works reliably

When switching to a loadout under a different spec, WoW applies its own default loadout for the new spec first, then holds a global talent-change lock for ~1 second while the spec change settles. The previous retry logic (5 × 0.5 s) could expire before that lock lifted, leaving the addon stuck on "Loading..." indefinitely and applying the wrong loadout.

v0.1.1 replaces the fixed-count retry with a **time-based retry window** (up to 35 seconds) with fast early polling (every 0.25 s) that catches the lock lifting in ~0.5 s under normal conditions, and falls back to slower polling (1 s, then 3 s) to handle the ~30 s spec-switch cooldown in rapid-switching scenarios.

## Requirements

- WoW Retail (tested on 11.x / 12.x — War Within / Midnight)
- [Titan Panel](https://www.curseforge.com/wow/addons/titan-panel)

## Links

- CurseForge: *(pending)*
- Author: [scootr.ca](https://scootr.ca) · [BlueSky](https://bsky.app/profile/scootr.ca)
