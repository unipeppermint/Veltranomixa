# Lucky Island · Implementation and validation

The app is implemented in the original **Veltranomixa** target. It is not a replacement project. See [Strategy polish](05-strategy-polish.md) for subsequent gameplay changes and [English edition](06-english-edition.md) for the language/layout update.

## Build and run

Open `Veltranomixa.xcworkspace` and select the `Veltranomixa` scheme. Dependency versions are CocoaPods 1.17.0 and SnapKit 5.7.1, recorded in Gemfile.lock and Podfile.lock.

```sh
bundle install
bundle exec pod install
xcodebuild -workspace Veltranomixa.xcworkspace -scheme Veltranomixa \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/LuckyIslandBuild CODE_SIGNING_ALLOWED=NO build
swift test --scratch-path /tmp/lucky-rule-tests
```

On this machine, Homebrew CocoaPods uses an isolated GEM_HOME; direct `pod install` also succeeded. Gemfile.lock was resolved from its installed dependencies. Other machines can restore through Bundler normally.

The Podfile post-integrate hook declares a temporary output for the CocoaPods resource-copy script. Xcode script sandboxing remains enabled. The existing Bundle ID `com.ccvl.Veltranomixa`, signing configuration, and version values remain unchanged. SceneDelegate now creates the root controller programmatically; the original storyboards and launch screen remain in the project.

## Implemented features

- Native UIKit/SnapKit island, map, level details, wheel gameplay, upgrades, workshop, results, collection, and settings. No WebView.
- Three regions, 15 levels, six tile types, 15 upgrades, 12 landmarks, 10 achievements, and three wheel styles.
- Lighthouse baseline: 12 spins, 20 Wood, eight equal-probability tiles, and the original three upgrade choices. Wins take priority; Extra Chances can rescue the last spin.
- Native workshop: first swap free per new run, then 6 Coins. Replacements have base yield 2. A separate 4-Coin purchase boosts all Wood tiles by 1. Each tile always retains 12.5% odds.
- Shells appear from level 6; Supply from level 11. Shells preserve Breeze. Supply refunds a spin and adds 1 Wood.
- Bonus challenge: finish with at least 3 spins left. Targets vary across Wood, Coins, Shells, and combinations.
- Breeze style is initially available. Coral unlocks after level 13, Starlight after level 14, and the final island achievement after level 15.
- Core Animation spin deceleration, pointer feedback, resource flight, generated layered artwork, collection art, resource icons, app icon, synthesized sounds, and native haptics.
- Sound, haptic, quick-spin, tutorial replay, rules/odds, privacy/local save, about, and confirmed reset controls. Reduce Motion is respected.
- Local JSON v1 saves and backup. Each candidate is atomically written before being displayed. Pending spins contain a UUID, tile index, and message; rewards commit before animation. Acknowledgement only clears the pending marker.
- Backup fallback, damaged-file preservation, and rejection of future save versions. Optional mechanics fields keep old runs on their original rules.

## Source map

| Path | Responsibility |
| --- | --- |
| `Domain/GameEngine.swift` | Configuration, models, rules, randomness, validation |
| `Data/SaveRepository.swift` | Serialized atomic persistence and recovery |
| `ViewController.swift` | Screens, inputs, and persistence-backed updates |
| `Views/` | Wheel, island, shared UI, audio, haptics, decorative wheel |
| `Assets.xcassets/` | Island, building/item atlases, app icon |
| `Tests/` | Independent macOS rule/save XCTest suite |
| `UITests/` | Simulator user flows and accessibility layouts |

## Assets and attribution

Images were generated with the built-in ImageGen tool and saved inside the asset catalog. A 4×3 building atlas supplies individual collectible sprites, overlaid on a building-free island background according to actual completion. A 3×2 atlas supplies resource icons. The reference mockup and HTML emoji scenery are not shipping screens.

`spin.wav` and `success.wav` are original synthesized short sounds. The original SnapKit MIT notice remains bundled. Both the app privacy manifest and SnapKit privacy resource bundle were verified in simulator products. No account, ad, analytics, purchase, or network SDK was introduced.

## Historical validation: September 16

- Xcode 26.6, iOS 26.5 SDK, CocoaPods 1.17.0.
- Workspace Debug and Release simulator builds passed. No signed archive was produced.
- 16 rule/persistence tests passed, covering base outcomes, operation order, Breeze, last-spin behavior, trigger deduplication, workshop funds, UUID acknowledgement, pending recovery, corrupted saves, future versions, and write errors.
- A random UI run passed: terminate after a spin, relaunch, resume, upgrade, finish, and visit collection/settings.
- Deterministic win and large-text UI tests passed. Screenshot inspection found clipped navigation at the largest accessibility size; the navigation sizing was corrected and the targeted test passed again.
- A 15,000-run fixed-seed diagnostic reported 89.3%–99.7% win rates and 12.959–35.871 average spins across levels. This was an automated policy, not a player win-rate claim. See `validation/balance.csv`.
- Builds emitted an AppIntents metadata extraction notice because the app does not depend on that framework.

Test-only fixed randomness requires `ISLAND_UI_FIXED_WOOD=1` and is compiled only under `#if DEBUG`, with an explicit screen banner. UI tests now use a separate save directory. Test-mode captures must not be used as App Store marketing screenshots. Historical logs/captures retain the exact copy rendered by those builds; current-language evidence is stored separately.

## Product presentation cleanup: September 17

Settings no longer exposes an open-source-license row, development-version banner, release TODO, artwork-generation tools, or layout-framework details. About Lucky Island shows a product introduction and the actual bundle version. The dependency copyright notice is still packaged. Release TODOs live in documentation rather than player screens.

## Remaining external validation and release inputs

- Physical-device audio, silent switch, haptics, VoiceOver reading, older supported OS versions, sustained performance/thermals/memory, and TestFlight remain unverified.
- The owner must provide a real support endpoint and public privacy-policy URL, and confirm final branding/commercial choices. Current implementation has no ads or purchases.
- Mainland China publishing prerequisites remain unresolved. Development and simulator QA do not authorize or guarantee release. No publishing action has been performed.
- Balance, pacing, and strategic depth still require human playtesting. Automated policies only help identify dead ends and numeric anomalies.
