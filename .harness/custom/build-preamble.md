# Project build guidance — BUILDER prompt preamble

## Test destination — ALWAYS the dedicated simulator, NEVER the shared model

This Mac may host more than one autonomous iOS loop at a time. Targeting a simulator by its generic
model name (`platform=iOS Simulator,name=iPhone 17 Pro`) resolves to the **same booted device** across
every loop, so two loops stamp on each other — the running app flip-flops and `xcodebuild test`
intermittently fails to launch the XCUITest runner (`…uitests.xctrunner`). It reads as "flaky UI tests"
and burns whole iterations before anyone traces it to device contention.

**Whenever you run `xcodebuild test` — or any build / launch / screenshot / UI-driving command that
boots a simulator — target the DEDICATED device `Enough-Sim`, never the generic model:**

```
-destination 'platform=iOS Simulator,name=Enough-Sim'
```

`Enough-Sim` is iOS 26.5, UDID `9481593E-90BC-4051-9F45-01CAE6D17C61` — the same device the loop's own
gate (`LOCAL_DOD` in `.harness/config/harness.env`) and `./build_run.sh` use. Prefer running
`./build_run.sh` for a build + launch + screenshot; it already defaults to this device.

**This overrides any command text quoted elsewhere.** If a task's spec (`## Do` / `## Done when`), its
`verify` commands, `CLAUDE.md`, or `README.md` still shows `name=iPhone 17 Pro`, **substitute the
`Enough-Sim` destination above when you actually run it.** The generic name in those places is either the
CI-canonical command (correct for CI, see below) or historical spec prose — not an instruction to boot the
shared device locally.

**Any NEW script or tool a task has you create** that boots or targets a simulator MUST default to
`Enough-Sim` (by name, or resolve it to its UDID via `xcrun simctl`), never the shared `iPhone 17 Pro`.
Minting a new script that defaults to the generic model creates a permanent new collision surface.

If `Enough-Sim` is missing, recreate it (then it resolves by name again):
```
xcrun simctl create "Enough-Sim" com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-5
```

**CI is deliberately exempt** — GitHub Actions runs one loop per isolated, ephemeral runner, so there is
no shared machine and no cross-loop collision; `.github/workflows/*` correctly targets `name=iPhone 17 Pro`
and must stay that way. This rule is LOCAL-only.
