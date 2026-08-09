# Agent Instructions

## Repository remotes and branches

- `origin` is the personal GitHub fork: `git@github.com:JoeeGrigg/findroid.git`.
- `upstream` is the original repository: `https://github.com/jarnedemeulemeester/findroid.git`.
- Keep `main` as a clean mirror of `upstream/main`. Never commit personal changes or feature work directly to `main`.
- `personal` contains development-only tooling and customizations that must not be submitted upstream.
- Upstreamable work is developed on `dev/<name>` with personal tooling available, then exported to a clean `feature/<name>` branch.
- Run branch-changing recipes only with a clean working tree.

## Personal development workflow

The `justfile` is intentionally maintained on `personal` and inherited by `dev/*` branches. Use these recipes instead of manually manipulating branches when possible.

### Synchronize with upstream

```bash
just sync-personal
```

This recipe:

1. Adds the `upstream` remote if it is missing.
2. Fetches the original repository.
3. Fast-forwards local `main` to `upstream/main`.
4. Pushes `main` to `origin`.
5. Rebases `personal` onto the updated `main`.
6. Pushes `personal` using `--force-with-lease`.

Run this before starting a new feature. Features created by `just feature` remain safe if `personal` is later rebased because the recipe records their exact personal base commit.

### Start an upstreamable feature

```bash
just feature <name>
```

Example:

```bash
just feature improve-search
```

This switches to `personal`, creates `dev/improve-search`, and records the exact personal base commit needed to produce a clean PR later. Develop and commit on the `dev/*` branch. It includes personal files such as the `justfile` for local development.

Do not open an upstream pull request from a `dev/*` branch.

### Prepare a clean pull-request branch

```bash
just prepare-pr <name>
```

Example:

```bash
just prepare-pr improve-search
```

This regenerates `feature/improve-search` from `dev/improve-search`, rebasing only the upstreamable feature commits onto `main`. Personal commits and files are excluded. It returns to `dev/improve-search` afterward so personal tooling remains available.

When more changes are made on `dev/<name>`, commit them there and run `just prepare-pr <name>` again to regenerate the clean feature branch.

### Review the proposed upstream changes

```bash
just review-pr <name>
```

This displays commits in `feature/<name>`, shows the diff summary against `main`, and runs `git diff --check`. Review the full diff when appropriate before pushing.

### Push the clean feature branch

```bash
just push-pr <name>
```

This pushes `feature/<name>` to `origin` using `--force-with-lease`, ready for a pull request to the original repository. Only `feature/*` branches should be used for upstream pull requests.

## Integration testing multiple branches

`integration-branches.txt` defines the Git refs to combine for local integration testing. It accepts one exact local or remote ref per line. Blank lines and text following `#` are ignored.

To combine all configured branches with `personal`, build the result, install it, and launch it on the connected device:

```bash
just integrate-run
```

This recipe requires a clean working tree and a connected ADB device. It fetches all remotes, creates a timestamped `integration/<timestamp>` branch from `personal`, merges every configured ref in order, and runs the normal device workflow. It leaves the integration branch checked out for debugging. Integration branches are temporary and must never be used for upstream pull requests.

If a merge conflicts, resolve or abort it on the generated integration branch. Do not resolve integration conflicts by changing the clean `feature/*` branches unless the underlying feature itself needs correction.

## Build and device workflow

To build, install, and launch the phone app on the connected ADB debugging device:

```bash
just run
```

The recipe verifies that a device is connected, runs `:app:phone:installLibreDebug`, stops the existing debug process, and launches `dev.jdtech.jellyfin.debug`.

Before considering code complete, run relevant checks. For changes shared by phone and TV, use:

```bash
./gradlew ktfmtCheck :app:phone:assembleLibreDebug :app:tv:assembleLibreDebug
```

Use `just run` afterward when the phone behavior should be validated on the connected device.

## Personal-only changes

Changes that must never go upstream should be committed directly to `personal`, not to `main` or `feature/*`. Keep unrelated personal tooling in separate commits. Never include secrets in any branch pushed to GitHub.
