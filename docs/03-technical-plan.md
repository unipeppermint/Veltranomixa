# Lucky Island · Technical plan

Original baseline: September 16, 2026. English documentation: September 17, 2026. Current implementation and results are in [Implementation and validation](04-implementation-and-validation.md).

## Stack and existing project

Swift + UIKit with programmatic screens and Auto Layout through CocoaPods-managed SnapKit **5.7.1**. SnapKit 6.0 removed CocoaPods support, so do not silently upgrade to 6.x or switch package managers. Prefer system frameworks for all other needs.

| Area | Technology |
| --- | --- |
| Screens and navigation | UIKit |
| View constraints | SnapKit |
| Wheel | Core Graphics / CAShapeLayer / Core Animation |
| Island | Layered images and native views/layers |
| Audio | AVFoundation |
| Haptics | UIKit feedback generators |
| Persistence | Codable JSON in Application Support |
| Verification | XCTest and XCUITest |

Continue in the existing `Veltranomixa` target. The initial project was a UIKit template containing AppDelegate, SceneDelegate, ViewController, Main.storyboard, and LaunchScreen.storyboard. It uses Swift 5 mode, an effective target deployment version of iOS 16.0, and portrait iPhone support. Project-level deployment defaults differ; inspect effective target settings when building. Preserve Bundle ID, signing team, versions, and distribution settings.

## Dependency workflow

```ruby
source 'https://cdn.cocoapods.org/'
platform :ios, '16.0'
use_frameworks! :linkage => :static
target 'Veltranomixa' do
  pod 'SnapKit', '5.7.1'
end
```

Run `pod install` and open `Veltranomixa.xcworkspace`. Commit Podfile and Podfile.lock. CocoaPods is pinned to 1.17.0 through Gemfile/Gemfile.lock. Use `pod install`, not an unplanned `pod update`, for restoration. Keep the MIT notice and verify SnapKit's privacy resource bundle in built products.

The actual Podfile also declares the CocoaPods resources script's temporary output in a post-integrate hook so Xcode script sandboxing can stay enabled.

## Layout and rendering

Use safe areas and SnapKit for screen geometry. Create constraints once; update constants or remake only when the relationship changes. Keep the wheel square, scalable, and within the scrollable content width. Allow content to grow vertically for smaller screens and large text. Recompute custom layer paths from final bounds in `layoutSubviews`; SnapKit does not constrain CALayer directly.

SceneDelegate owns the programmatic root controller. Remove storyboard entry references to avoid duplicate roots, but retain the original storyboard files and launch screen. The app must never embed the HTML prototype as its interface.

## Separation of responsibilities

- `Domain/GameEngine.swift`: stable-ID configuration, models, deterministic state transitions, injectable random source, and validation; no UIKit/SnapKit.
- `Data/SaveRepository.swift`: serialized reads/writes, atomic files, backup recovery, and compatibility protection.
- `ViewController.swift`: native display and input, committing a candidate before publishing it.
- `Views/`: shared styling, layered island, wheel artwork/animation, sound, and haptics.
- `Resources/` and `Assets.xcassets/`: images, sound, privacy manifest, and attribution.

Configurations include Level, Segment, Upgrade, RunState, SpinRecord, and SaveEnvelope. Display names must not be used as persistence identifiers. Production randomness uniformly chooses one of eight indices; tests inject fixed or seeded sources.

## Recoverable spin transaction

Logical run phases are ready, upgrade, won, and lost. A pending SpinRecord bridges committed rules and visual reveal; the UI prevents input during animation and saving.

1. Validate that a spin is legal.
2. Draw one tile and calculate resources, remaining spins, and next phase.
3. Create a unique UUID, then save the updated run and pending result in one snapshot.
4. Publish state and animate only after the write succeeds. On failure, retain the old state.
5. Animation reveals a fixed result; it does not award resources again.
6. After the reveal, clear the pending record using its UUID. If interrupted, restore the record and reveal it without rerolling or re-awarding.

Upgrades, workshop changes, and wins use the same commit-before-publish approach. Save on every action rather than relying only on background callbacks. Serialize writes to prevent an older file write from overtaking a newer one.

Wheel stopping angles use the selected tile center plus complete turns and a decelerating timing curve. Set the model layer before the explicit animation to avoid snap-back. The fixed pointer, sector centers, and radial content share the same angle convention. Test-only scripted results must be clearly marked and excluded from Release.

## Saves and compatibility

Application Support holds versioned JSON containing progress, current run, preferences, and pending result. Write atomically and retain the last valid snapshot as a backup. Validate bounds and IDs when reading. Attempt backup recovery with an explanation when the primary is invalid. Preserve damaged files before starting over if neither copy is valid. Never overwrite a future-version save with an older app.

The current format is v1. Optional strategy-mechanics fields preserve old runs with classic rules. A language change must preserve UUIDs, tile indices, balances, and phases; old stored display text may use an English fallback without changing rewards.

There is no account or cloud sync. App updates retain saves; deleting the app may erase them. Reset requires an explicit in-app confirmation and clears both primary and backup.

## Performance and accessibility

Use cached illustrations, avoid rebuilding paths every frame, and limit unnecessary animations. Pause sounds in the background. Respect sound/haptic switches, silent mode, and Reduce Motion. Resource icons must have text equivalents and controls must expose meaningful accessibility labels. Keep interactions at least 44 points high. Final smoothness, memory, thermals, and battery behavior require physical-device measurement; simulator results cannot establish those claims.

## Verification checklist

- Rules: all tile outcomes, tool stacking, addition before multiplication, Breeze consumption/non-stacking, insufficient funds, final-spin rescue, and win priority.
- Transactions: interruptions before/after saving and revealing, UUID acknowledgement, and no double award.
- Persistence: malformed data, future versions, legacy fields, backup recovery, write failures, and reset behavior.
- UI: full runs, repeated taps, return/resume, workshop preview, collection, settings, large text, and small screens.
- Project: dependency installation, workspace Debug/Release builds, simulator tests; signing/archive, device, and TestFlight checks at the appropriate stage.

## Privacy and release

No ads, analytics, account, backend, or purchases are implemented. Privacy manifests must describe actual usage. Support and privacy-policy URLs, age-rating responses, rights review, screenshots, and review notes remain release deliverables. Mainland China publishing prerequisites are independent of technical completion. Do not infer that an offline game or an entertainment category is automatically exempt.

## References

- [SnapKit releases](https://github.com/SnapKit/SnapKit/releases)
- [SnapKit 5.7.1 Podspec](https://github.com/CocoaPods/Specs/blob/master/Specs/1/f/6/SnapKit/5.7.1/SnapKit.podspec.json)
- [UIKit](https://developer.apple.com/documentation/uikit)
- [Core Animation](https://developer.apple.com/documentation/quartzcore)
- [Codable](https://developer.apple.com/documentation/foundation/encoding-and-decoding-custom-types)
- [Privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
