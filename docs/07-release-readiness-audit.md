# Lucky Island · Pre-submission audit

September 17, 2026. Intended distribution: worldwide, confirmed by the owner during this audit.

The implemented game loop is complete enough for release preparation, but the project is **not yet ready for an unconditional worldwide submission**. The principal gates are a public privacy policy and support endpoint, a signed distribution build, and regional publishing requirements. Three smaller code/content issues are also confirmed below. This audit does not assert that App Store Connect fields are empty: no authenticated account inspection was performed.

The initial audit changed no app source, Bundle ID, signing team, or distribution settings. The subsequent authorized P2 repairs are recorded below.

## Follow-up: requested P2 repairs completed

The owner subsequently authorized the three recommended code/content fixes. The original findings below are retained as the audit record; all three are now addressed:

- Privacy copy distinguishes local app storage from user-managed iCloud/computer device backups, and explains the scope of reset. Device backup behavior is preserved.
- Reset removes regular quarantine files matching the app's `damaged-<UUID>.json` format before replacing both saves. Unrelated files are kept; enumeration/deletion errors propagate to the existing failure alert instead of reporting a successful reset.
- The wheel's accessibility description explains Chest, Breeze and Supply effects explicitly. Resource descriptions continue to include next-spin bonuses.

Validation: 26 rule/persistence tests passed, including quarantine cleanup, clean backup recovery, unrelated-file preservation, special-tile descriptions and resource-description/award agreement. A targeted iPhone SE UI test passed at the largest accessibility text size, checking the privacy alert's text and dismiss button plus the wheel's exposed accessibility label. The final arm64 Release archive succeeded with signing disabled. Evidence is in `validation/release-fixes/`. Physical-device VoiceOver speech has not been tested. The public policy URL, signing and regional release gates remain open.

## Follow-up: hosted privacy policy connected

The owner supplied the [public privacy policy](https://doc-hosting.flycricket.io/lucky-island-privacy-policy/0844502f-3dcc-4b6b-b833-8b7e5930bd9c/privacy). It returned HTTP 200 and the body matches the current local-save, system-backup and reset behavior. Settings now includes a Privacy Policy button that opens the system browser; the offline summary remains available. Failed browser launches show an error. The hosting page has Flycricket branding and an advertising area, separate from the native game. The in-app policy-link finding below is resolved; the App Store Connect policy field has not been inspected or updated.

## Confirmed submission gates

| Priority | Finding | Evidence and required resolution |
| --- | --- | --- |
| P1 | No in-app privacy-policy link | `ViewController.swift:342` opens a short local alert. It contains no policy URL or link to a full policy. Provide a real, publicly accessible policy and an in-app entry; enter the same policy in App Store Connect. Policy content should explain local saves, deletion and system backups. |
| P1 | Distribution signing has not been completed | Effective Release build settings contain no `DEVELOPMENT_TEAM`. The new archive was deliberately unsigned (`CODE_SIGNING_ALLOWED=NO`) and has no provisioning profile. It proves arm64 compilation and packaging, not upload readiness. Select the owner's existing team, verify the existing Bundle ID registration, create a signed archive, run Organizer validation and TestFlight. Do not invent a team or change the Bundle ID. |
| P1, regional | Worldwide availability has unresolved publishing prerequisites | The existing product plan records no mainland China game approval number or publishing partner. Current Apple guidance also identifies game licensing for Vietnam. These documents were not supplied or verified. Complete the applicable regional requirements before making the game available there; any change to the worldwide scope requires the owner's decision. |
| External verification | Public support, store metadata and account declarations | No support/policy URL was supplied in this session. Support must point to working contact information. Verify age rating, privacy answers, screenshots, review contact, pricing, agreements, EU trader status and territory-specific fields in the actual App Store Connect record. Their completion cannot be inferred from source code. |

Apple requires a privacy-policy link both in the app and its metadata; a local privacy summary is not the complete requirement. See [App Review Guidelines 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy). Apple separately describes a support website with usable contact information in [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/).

For mainland China, Apple's current reference identifies game approval numbers and applicable ICP requirements; it also identifies Vietnam game licensing. These are regional release gates to verify, not a conclusion that changing category or operating offline creates an exemption. See [App information: regional availability](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/). EU distribution also requires the appropriate trader-status declaration and, where applicable, verified business contact details: [EU DSA requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/).

## Confirmed code and content issues

### P2 · Local-only privacy wording overlooks device backups

Location: `Veltranomixa/ViewController.swift:342`, with save directory selection at line 22.

The alert says progress/settings are saved only on the device. Saves live in Application Support, and no backup exclusion is set. They may therefore be included in user-controlled iCloud or computer device backups. The app has no own cloud-sync service, but that is different from excluding all system backups.

Recommended correction: describe local storage and no developer-operated sync, while acknowledging system backups under the user's device settings. Keep useful progress backup behavior unless the product owner explicitly chooses otherwise. [Apple file-system guidance](https://developer.apple.com/documentation/foundation/using-the-file-system-effectively).

### P2 · Reset leaves quarantined save data behind

Location: `Veltranomixa/Data/SaveRepository.swift:40`.

When both saves are invalid, `load()` preserves them as `damaged-<UUID>.json`. `reset()` only writes new primary and backup files; it never removes those quarantined copies. Reproduction with two deliberately invalid temporary saves left **2 damaged files after a successful reset**. These files are not loaded as progress automatically, so this is incomplete data cleanup rather than normal progress being resurrected.

Recommended correction: on confirmed reset, clean up the app-owned quarantine files too, report cleanup failures accurately, and add a regression case covering load-corruption-reset. Evidence and the temporary-data reproduction are in `validation/release-audit/scenarios.log` and `scenarios.swift`.

### P2 · VoiceOver misdescribes special wheel tiles

Location: `Veltranomixa/Views/WheelView.swift:37`.

Every tile is described using the numerical resource-yield helper. That reports zero for a Chest and Breeze, and a bare one for Supply. Their real effects are an upgrade choice, a future doubling effect, and one extra spin plus one Wood. The current accessibility description therefore omits essential gameplay effects.

Recommended correction: use explicit effect descriptions for Chest/Breeze/Supply and reserve numerical next-spin yields for resource tiles. Verify the final phrasing with VoiceOver on a device. This finding is based on the generated accessibility string and rule implementation; no physical-device VoiceOver session was performed.

## Validation completed

| Check | Result | Scope |
| --- | --- | --- |
| Release arm64 Archive | Passed | Xcode 26.6 / iPhoneOS 26.5 SDK, generic iOS destination, signing disabled |
| Rule and persistence XCTest | 23 passed, 0 failures | Re-run during this audit |
| All-level scenario sweep | 1,500 runs, 0 unresolved runs at the loop cap | 100 seeded runs per level; validates state and performs JSON encode/decode during transitions |
| Corruption/reset reproduction | Issue confirmed | Two quarantined files survive reset |
| Previous English UI evidence | 4 tests passed on each of iPhone 17 Pro and SE | Reused existing logs; not rerun during this audit. The SE run covers the final compact layout; the earlier Pro game run predates that adjustment |
| Archive bundle inspection | Passed inspected checks | Main and SnapKit privacy manifests, sounds, attribution and compiled image assets are packaged |
| Release debug-content scan | No tested markers found | No `ISLAND_UI_FIXED`, `ISLAND_UI_TEST`, or `UI TEST MODE` strings in the archived executable |
| Icon source | 1024 × 1024 RGB, no alpha channel | Universal iOS app icon is referenced by the compiled Info.plist |

The scenario sweep is a deterministic rule diagnostic, not full UI playthrough of every level or evidence of player retention/balance. Automated win rates must not be used as player-facing marketing claims. No new crash or invalid state was observed within these checks.

The archive has Bundle ID `com.ccvl.Veltranomixa`, display name `Lucky Island`, version/build `1.0 (1)`, deployment target iOS 16.0, portrait iPhone device family, and no Mac/visionOS compatibility opt-in. The built SDK meets Apple's current minimum Xcode 26 / iOS 26 SDK requirement. See [SDK minimum requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).

App and SnapKit privacy manifests declare no tracking, collected data or required-reason APIs. The inspected source contains no network, account, advertising, analytics or purchase implementation. No missing required-reason API declaration was identified in the current code. This does not replace App Store Connect privacy responses or the signed upload validator. The only build warning was skipped AppIntents metadata extraction because the app has no AppIntents dependency.

## Store presentation and remaining QA

- The game has a working loop across 15 levels, three island rules beyond the basic workshop rule, collection, achievements, wheel styles, settings and recoverable saves. No placeholder screens, unavailable purchase buttons or production demo banner were identified. The SnapKit notice is still bundled and the old license menu is absent.
- Current screenshots in the test archive include fixed-result test banners, historic Chinese UI, and some earlier layouts. Do not submit those as store screenshots. Prepare captures from the final release behavior showing actual play. The clean final home capture is useful evidence, but it is not a complete store screenshot set.
- The original launch screen is a plain system background. This is polish work, not an identified submission blocker.
- iOS 16 is the advertised minimum, but this machine only has the iOS 26.5 simulator runtime. Older supported versions, a physical iPhone, device audio/silent switch/haptics, interruption handling under real device conditions, sustained memory/performance and signed TestFlight distribution remain unverified.
- Run full gameplay at least once on a signed build, including late levels and alternate upgrades. Current end-to-end UI tests chiefly exercise the first level; the late-level sweep exercises model logic only.
- `ITSAppUsesNonExemptEncryption` is unset. Complete the export-compliance questions; omission alone is not evidence of a rejectable binary. Source review found no custom cryptography. Do not make legal declarations on the owner's behalf.
- Confirm version/build uniqueness against App Store Connect. Local `1.0 (1)` cannot establish whether that build number was already uploaded. Confirm naming and rights to the supplied/generated visual assets for commercial release.
- Finish the age-rating questionnaire based on actual mechanics. There is no real-money staking, cash-out, purchasable random item or player competition in this implementation. A wheel alone does not establish simulated gambling; conversely, absence of real money does not by itself rule out that descriptor. Review whether the design constitutes betting/wagering and explain the mechanics accurately. [Apple age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/).

## Recommended order

1. Supply the real policy/support endpoints and complete the in-app policy entry; correct backup wording, reset cleanup and special-tile accessibility descriptions.
2. Resolve worldwide regional publishing requirements and account declarations with the app owner/publisher.
3. Configure the authorized signing team, create a signed archive, run Organizer validation and TestFlight, and complete real-device/older-OS QA.
4. Prepare final production screenshots, accurate store metadata, privacy/age/export answers, and concise review notes. Confirm territory availability and submit only after these gates are closed.

## Evidence reproduction

Run from the repository root:

```sh
swift test --scratch-path /tmp/lucky-english-rules
swiftc Veltranomixa/Domain/GameEngine.swift Veltranomixa/Data/SaveRepository.swift \
  docs/validation/release-audit/scenarios.swift -o /tmp/lucky-release-audit
/tmp/lucky-release-audit
xcodebuild -workspace Veltranomixa.xcworkspace -scheme Veltranomixa \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /tmp/LuckyIslandAudit.xcarchive -derivedDataPath /tmp/LuckyIslandAudit \
  CODE_SIGNING_ALLOWED=NO archive
```

The unsigned archive is retained locally at `/tmp/LuckyIslandAudit.xcarchive`. Logs are under `validation/release-audit/`. No build was uploaded and no App Store Connect record was changed.
