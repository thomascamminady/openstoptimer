# OpenStopTimer

`OpenStopTimer` is an open-source stopwatch and timer app for iOS and iPadOS.
It's four apps in one:

- **Simple Timer** — a zero-configuration countdown timer. Set it and go.
- **Simple Stopwatch** — start, stop, reset. Nothing else to learn.
- **Lap Stopwatch** — a fully configurable count-up stopwatch with lap splits.
- **HIIT / Interval Timer** — build, save, and run fully configurable interval
  workouts (warmup, work, rest, rounds, cooldown), in the spirit of
  [OpenHIIT](https://github.com/EmergeTools/OpenHIIT).

Everything about the two advanced modes is optional to configure: colors per
phase, beep/chime/bell sounds per event, text size, and how much of the
screen the "current" step gets vs. the "next" preview. Workouts can be
exported/imported as `.ostworkout` files (JSON) via the share sheet,
AirDrop, Files, or Mail.

No ads, no in-app purchases, no tracking. MIT licensed.

## Project structure

- `OpenStopTimerKit/` — a local Swift Package with all the UI-free logic:
  domain models, the `Date`-anchored timer engine, appearance/config,
  on-device workout storage, and import/export. Fully unit tested and
  buildable on its own (`swift test`), no simulator required.
- `OpenStopTimer/` — the SwiftUI app target: views, view models, the design
  system, and app-target-only glue (audio playback, UIKit-adjacent bits).
- `project.yml` — the [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec
  used to generate `OpenStopTimer.xcodeproj`. The generated project isn't
  committed (see `.gitignore`) to avoid pbxproj merge conflicts.
- `Scripts/generate_sounds.py` — synthesizes the bundled beep/chime/bell
  sounds (no external audio assets needed). Run via `uv run Scripts/generate_sounds.py generate`.

## Building

Requires [Xcode](https://developer.apple.com/xcode/) and
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
./Scripts/bootstrap.sh      # generates OpenStopTimer.xcodeproj
open OpenStopTimer.xcodeproj
```

Or run the package's unit tests directly, without Xcode:

```sh
cd OpenStopTimerKit && swift test
```
