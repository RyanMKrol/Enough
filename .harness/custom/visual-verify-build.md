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
- **Screenshot at DEFAULT text size unless your task is specifically about Dynamic Type.** The
  simulator's Dynamic Type is a PERSISTENT setting, so an accessibility-sizing task (T069) can leave
  it cranked up and make every later task's screenshot look wrongly oversized/"blocky". Before
  judging a normal screenshot, ensure the size is the iOS default: `xcrun simctl ui booted
  content_size large` (note the UNDERSCORE — `content-size` with a hyphen just prints simctl usage
  and does nothing on Xcode 26). Only an explicit accessibility task should set an `accessibility-*`
  size, and it MUST reset to `large` when it finishes.
- Judge against `.harness/docs/designs/design-spec.md`: correct accent (Japan red `#e24947` by
  default), canvas `#f2f2f7`, exact copy strings, and layout matching the section for your
  screen. Truncated text, missing sections, default-blue SwiftUI tint, or a blank screen =
  NOT verified.

### Navigating to your screen (xcui/AXe — only if installed)

If `command -v axe` succeeds (installed by task T070; skip this whole section otherwise), you
can DRIVE the simulator to the screen you changed instead of judging only the launch screen.
The UI carries stable accessibility identifiers once task T065 has landed (`tab-learn`,
`tab-reviews`, `tab-progress`, `tab-browse`, `screen-home`, `home-continue-card`,
`grade-good`, `session-close`, … — full list in `Sources/App/AccessibilityIDs.swift`).

```bash
XCUI=$(ls ~/.claude/plugins/cache/axiom-marketplace/axiom/*/bin/xcui 2>/dev/null | tail -1)
UDID=<the booted sim build_run.sh used — pass it to every call; two sims may be booted>
axe tap --id tab-reviews --udid "$UDID"                       # navigate by identifier
"$XCUI" wait --for-element screen-reviews --timeout 10s --udid "$UDID"
xcrun simctl io "$UDID" screenshot screenshots/latest.png      # re-screenshot on that screen
"$XCUI" assert --id streak-pill --label "6" --udid "$UDID"     # semantic assert (exit 1 = fail)
axe describe-ui --udid "$UDID"                                 # dump the accessibility tree
```

Flags go AFTER the subcommand. Prefer one `xcui assert` on the element your task changed —
it checks label text the screenshot can't. Blank screenshot? Capture the console first:
`xclog launch com.ryankrol.enough --timeout 30s --max-lines 200 --device "$UDID"`
(note: xclog terminates and relaunches the app).
