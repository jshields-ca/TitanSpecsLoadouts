# Contributing

Thanks for your interest in contributing to Titan Panel [Specs & Loadouts]!

This is a small personal addon, but contributions are welcome — whether that's bug reports, feature suggestions, or code.

## Reporting Bugs

Open a [GitHub Issue](https://github.com/jshields-ca/TitanSpecsLoadouts/issues) and include:

- Your class and spec(s) involved
- WoW version and Titan Panel version
- What you did, what you expected, what happened instead
- Any error messages from the in-game Lua error frame or BugGrabber

## Suggesting Features

Open a GitHub Issue with the `enhancement` label. Keep in mind the addon is intentionally focused — suggestions that fit the "quick spec/loadout switching from the Titan bar" purpose are most likely to be picked up.

## Pull Requests

1. Fork the repo and create a branch from `main`.
2. Keep changes focused — one fix or feature per PR.
3. Test in-game before submitting. At minimum: same-spec switching, cross-spec switching, and `/reload` behavior.
4. Update `CHANGELOG.md` with a brief description of your change under an `Unreleased` section.
5. Open the PR with a clear description of what it does and why.

## Code Style

- Lua, following the existing file structure.
- Local functions only — no globals except the required Titan Panel API registrations.
- Prefer defensive API calls (nil-check before calling any WoW API that may not exist across versions).
- Comments for any non-obvious WoW API behavior or event timing assumptions.

## License

By contributing, you agree your changes will be released under the same license as this project.
