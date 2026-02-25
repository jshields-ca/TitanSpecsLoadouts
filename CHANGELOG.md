# Changelog

All notable changes to Titan Panel [Specs & Loadouts] are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project uses [Semantic Versioning](https://semver.org/).

---

## [0.1.0] - 2026-02-24

Initial release.

### Added
- Titan bar display showing **current specialization** (blue) and **active talent loadout** (yellow).
- Right-click menu grouped by all class specializations with saved loadouts listed under each.
- Left-click opens the Talents & Loadouts UI.
- Cross-spec loadout switching: automatically switches specialization, then applies the chosen loadout.
- Same-spec loadout switching without spec change.
- Dynamic Titan bar icon updates to match current specialization.
- `[Current]` green prefix marker on the active loadout in the right-click menu.
- Tooltip showing current spec and loadout name with left/right click hints.
- Titan Panel `ShowIcon` and `ShowLabelText` control variables.
- Compatible with WoW Retail 11.x / 12.x (Dragonflight / War Within era APIs).
- Fallback API wrappers for `C_SpecializationInfo` and legacy `GetSpecialization*` functions.

### Fixed (during development)
- `C_Traits.GetConfigInfo()` returns spec names, not loadout names; corrected to use `C_ClassTalents.GetConfigInfo()`.
- `GetLastSelectedSavedConfigID()` is read-only and does not update after `LoadConfig()` fires; replaced tracking with addon-owned `addonTrackedConfigID` state variable.
- `addonTrackedConfigID` is seeded from `GetLastSelectedSavedConfigID()` on `PLAYER_TALENT_UPDATE` (the first reliable moment after login/reload), then maintained by the addon for all subsequent switches.
- Cross-spec switch applied WoW's default loadout instead of the chosen one: `PLAYER_SPECIALIZATION_CHANGED` handler no longer calls `tryFinalizePending()`; WoW auto-loads its default for the new spec after that event fires, so finalization is deferred to `PLAYER_TALENT_UPDATE` once talent state is settled.
- `seedTrackedConfigFromAPI()` would overwrite `addonTrackedConfigID` with WoW's auto-loaded default while a cross-spec switch was still pending (first `LoadConfig` call returned `Error`); fixed by returning early when `pending.targetConfigID` is set.
- `PLAYER_SPECIALIZATION_CHANGED` and `ACTIVE_TALENT_GROUP_CHANGED` both fire for same-spec loadout switches as well as real spec changes; both handlers now track `lastKnownSpecID` and only clear `addonTrackedConfigID` when the spec actually changes.
- Both handlers also guard against the spec API returning `nil` mid-event (which could falsely trigger a clear).
- Stale `pending` from a cross-spec switch could be re-applied after the user immediately picked a same-spec loadout; `activateLoadout` now calls `clearPending()` before `loadConfigID()` when switching within the current spec.
- Same-spec loadout switching now functions correctly regardless of `LoadConfig()` result code (`LoadInProgress` vs `NoChangesNecessary`).
- Titan bar display updates immediately after a loadout switch rather than waiting for the next event cycle.
- Menu width is stable on first open (no layout jump).
- Redundant re-load of an already-active loadout skipped correctly.

### Known Limitations
- In-combat talent and spec changes are blocked by Blizzard natively; the addon surfaces the game's own error messages.
- Cross-spec switching requires the game to process the spec change event before the loadout is applied; brief delay is expected and handled via event-driven pending state.
