# MathChallenge — "Cognitive Trainer"

An offline brain-training suite for Windows, written as a single-file
PowerShell + WPF application ([`MathChallenge.ps1`](MathChallenge.ps1)).
Arithmetic drills, Vedic maths tricks, Sudoku, and classic cognitive-training
exercises, with streak multipliers, levels and per-game timers.

No installer, no admin rights, no network access, no account, and nothing is
written to disk — scores live only for the current session.

## Download

Get the latest `MathChallenge.exe` (or the zip bundle) from
**[Releases](https://github.com/AfzalAshraf/MathChallenge/releases)**. Extract
anywhere and double-click the exe.

If SmartScreen warns about an unsigned executable: **More info → Run anyway**,
or verify the download against the published SHA-256 checksums:

```bat
certutil -hashfile MathChallenge.exe SHA256
```

## Run from source

```powershell
# from a repository checkout
powershell -ExecutionPolicy Bypass -File .\MathChallenge.ps1
```

or double-click [`packaging/Launch-MathChallenge.bat`](packaging/Launch-MathChallenge.bat),
or right-click `MathChallenge.ps1` → **Run with PowerShell**.

**Requirements:** Windows 10/11 x64, .NET Framework 4.7.2+ (preinstalled on
Windows 10 1803+), Windows PowerShell 5.1. The window is 1160×820 and not
resizable, so a 1200×900 screen or larger is needed.

## Games

| Category | Games |
| --- | --- |
| Brain training | Schulte 5×5, Schulte 7×7, Color Stroop, Speed Grid, N-Back (N=2) |
| Vedic maths | 11 Sandwich, Ghost Base, Sparkle Square, Last Stand, Vedic Speed (60 s) |
| Brain teasers | Water Jugs, Weight Balance, Coin Puzzle, Math Tricks (120 s each, with hints and worked solutions) |
| Sudoku | Easy (45+ clues), Medium (35 clues), Hard (25 clues) — 3 mistakes ends the board |

**Scoring:** answer streaks multiply points (×2 at 5, ×3 at 10, ×4 at 15, ×5 at
20); every 5 correct answers in a game levels you up and multiplies again.

### Keyboard shortcuts

| Key | Action |
| --- | --- |
| `Enter` | Submit an answer |
| `D1`–`D9` / `Numpad1`–`Numpad9` | Fill the selected Sudoku cell (or toggle a pencil note) |
| Arrow keys | Move the Sudoku selection |
| `N` | Toggle Sudoku notes (pencil) mode |
| `Z` | Undo the last Sudoku move |
| `Delete` / `Back` | Erase the selected Sudoku cell |
| `Escape` | Stop the game and return to the menu |

## Automated builds and releases

Three GitHub Actions workflows live in [`.github/workflows`](.github/workflows):

| Workflow | Trigger | What it does |
| --- | --- | --- |
| [`ci.yml`](.github/workflows/ci.yml) | push/PR to `main` | Parses `MathChallenge.ps1`, validates the embedded XAML is well-formed, checks the packaging inputs exist, and runs an advisory PSScriptAnalyzer pass. |
| [`release.yml`](.github/workflows/release.yml) | tag push (`v*`, `[0-9]*`, `release-*`) or manual run | Converts the script to a standalone `MathChallenge.exe` with **ps2exe**, zips it with the launcher, README and LICENSE, writes SHA-256 checksums, and attaches everything to a GitHub Release on that tag. |
| [`android.yml`](.github/workflows/android.yml) | manual only (**inactive**) | A documented Gradle → APK → Release template. See below. |

### Cutting a release

```bash
git add .
git commit -m "Release v1.1"
git push
git tag v1.1
git push origin v1.1
```

Pushing the tag starts `release.yml`. When it finishes (a few minutes on a
`windows-latest` runner), the release appears under
**[Releases](https://github.com/AfzalAshraf/MathChallenge/releases)** with
`MathChallenge.exe`, `MathChallenge-v1.1-windows.zip` and a checksums file
attached. Re-pushing the same tag replaces the assets instead of failing.

Accepted tag patterns are `v*`, `[0-9]*` and `release-*`; tag names may contain
letters, digits and `. _ + -`. A tag ending in `-alpha`, `-beta`, `-rc1`,
`-preview` or `-nightly` is published as a **pre-release**, so it does not take
the "Latest" badge away from your newest stable tag.

To test the packaging **without** creating a release, use
**Actions → Build & Publish Windows Release → Run workflow** and leave the tag
field blank: you get downloadable artifacts from the run summary and no release.

No secrets need to be configured. Publishing uses the built-in `GITHUB_TOKEN`
with `permissions: contents: write` and the `gh` CLI that is preinstalled on
GitHub-hosted runners — so there is no personal access token to create, store or
rotate, and no third-party action to trust.

### Why there is no APK

This project is a **Windows desktop app** (PowerShell + WPF). It has no
`gradlew`, no `build.gradle`, no `AndroidManifest.xml` and no Java/Kotlin
sources, so there is nothing that can be compiled into an Android APK — any
"build APK" workflow here would fail at `./gradlew assembleRelease`.

The `.exe` produced by `release.yml` is the exact analogue: the same
tag-push → build → attach-to-release pipeline, with the right artifact for this
codebase. If an Android port is ever added — native, React Native or Flutter —
[`android.yml`](.github/workflows/android.yml) is ready: uncomment its tag
trigger and it builds the APK/AAB and attaches it to the release. It detects
which kind of project it is in, and for React Native you only need to set
`GRADLE_PROJECT_DIR: android`.

## Repository layout

```
MathChallenge.ps1                      the whole application (UI + game logic)
packaging/README.txt                   end-user instructions shipped in the zip
packaging/Launch-MathChallenge.bat     double-click launcher for the .ps1
.github/workflows/ci.yml               validation on push/PR
.github/workflows/release.yml          tag -> exe + zip -> GitHub Release
.github/workflows/android.yml          inactive Android/APK template
.gitattributes                         CRLF for .bat, LF elsewhere
LICENSE                                Apache-2.0
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
