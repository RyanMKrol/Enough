## Project-specific visual verification (Enough)

- Capture via `./build_run.sh` — it generates, builds, installs, launches on an iPhone
  simulator, and writes `screenshots/latest.png`. Look at that file.
- A fresh install shows the ONBOARDING WELCOME screen. To verify main-app screens with a
  populated mid-trip state (streak 6, 3 owned Japan decks, 12 reviews due), relaunch with the
  demo seed once task T042 has landed:
  `xcrun simctl terminate booted com.ryankrol.enough || true`
  `xcrun simctl launch booted com.ryankrol.enough -demo-state`
  then re-screenshot: `xcrun simctl io booted screenshot screenshots/latest.png`.
- To reach a specific tab/screen for a screenshot, you may also launch with `-debug-menu`
  (opens the debug sheet) — but prefer judging the actual screen your task changed.
- Judge against `.harness/docs/designs/design-spec.md`: correct accent (Japan red `#e24947` by
  default), canvas `#f2f2f7`, exact copy strings, and layout matching the section for your
  screen. Truncated text, missing sections, default-blue SwiftUI tint, or a blank screen =
  NOT verified.
