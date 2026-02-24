# Changelog

All notable changes to Titan Panel [Specs & Loadouts] are documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning where practical.

## [Unreleased]

### Status
- Pre-release development build.
- Not yet published as a stable release.

### Added
- Addon scaffold and metadata for Titan Panel integration.
- Titan bar text showing current specialization and active loadout.
- Right-click menu grouped by specialization with saved loadouts.
- Cross-spec loadout switching flow (switch specialization, then apply chosen loadout).
- Project docs: README, CurseForge description/summary, and changelog template.

### Changed
- Project naming aligned to Titan Panel [Specs & Loadouts] across folder, TOC, and plugin identifiers.

### Known Limitations
- In-combat talent/spec restrictions rely on Blizzard native behavior.
- Additional in-game validation is still required for all classes and edge conditions.

### Testing / Debugging Plan
- Validate same-spec loadout switching.
- Validate cross-spec switching + loadout application ordering.
- Validate no-saved-loadout menu behavior for each specialization.
- Validate combat lock behavior and post-combat recovery.
- Validate reload/login event refresh behavior.

---

## Next Release Draft

Target version: `0.1.0`

Release gate:
- Functional tests complete in-game
- Debug pass complete
- No blocker bugs open
