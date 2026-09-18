# Lucky Island · Follow-up audit

September 18, 2026. Review of the current clean working tree after the hosted policy link and settings simplification. No business logic or release configuration was modified by this audit.

The previous three requested repairs remain implemented. Privacy Policy opens the supplied HTTPS URL, Save Information contains only storage/help copy, and the redundant settings footer is absent. The public policy URL is present in the Release executable. Quarantine cleanup and special-tile descriptions remain covered by the rule tests.

## Repair follow-up

The owner authorized all three follow-up repairs. The original findings below are retained as historical evidence.

- Blocked save loading now produces a Reset unavailable explanation before any destructive confirmation. The protection against overwriting incompatible saves remains intact.
- The result statistic now says workshop changes, matching the existing counter. Game rules, achievement thresholds and save schema are unchanged.
- Informational/error alerts are queued while another modal is present and delivered after dismissal, without dismissing the user's current dialog. Messages are no longer discarded by the previous early-return guard.
- Three targeted UI regressions inject load, reset and write failures and verify user-visible feedback. Fault injection is compiled only in Debug and enabled only within the isolated UI-test save session.

Repair validation: all 3 targeted failure-path UI tests passed on iPhone SE / iOS 26.5; all 26 rule/persistence tests passed; the Release arm64 build succeeded with signing disabled. The Release executable contains none of the fault-injection marker strings. Logs are under `validation/error-feedback-fixes/`. The prior full happy-path UI run is recorded separately below.

## Findings

### P2 · Reset silently does nothing when save loading is blocked

Location: `Veltranomixa/ViewController.swift:363`, with the triggering state set at line 28.

If loading fails, for example because the stored version is newer than supported, the controller sets `loadBlocked`. Settings still presents the destructive reset confirmation. Confirming it then returns from `guard !self.loadBlocked` without resetting or explaining why. The user sees a functioning destructive action that has no effect and no feedback.

The isolated model reproduction confirms that a version-2 save triggers the load error. The UI no-op follows directly from the controller guard; an injected-error UI session was not performed. This does not affect normal valid-save resets, and preserving newer saves is intentional. Disable/explain the unavailable action or display an explicit recovery message; do not silently discard the protection against overwriting future saves.

### P3 · Result counter wording includes upgrades that it does not count

Location: `Veltranomixa/ViewController.swift:243`; `GameEngine.choose` and `GameEngine.craft` in the domain model.

The result labels `r.crafts` as “upgrades and swaps”. Only workshop boosts/replacements increment this value. Choosing Better Tools from the three upgrade cards raises `boost` but leaves `crafts` at zero, confirmed by a deterministic reproduction. A run can therefore contain several chosen upgrades while displaying zero upgrades and swaps.

Recommended low-impact correction: label the value “workshop changes”, matching its existing meaning and the Island Crafter achievement. If the product instead wants all upgrade choices counted, introduce a separate compatible statistic rather than changing the achievement semantics implicitly.

### P2 risk to verify · Error alerts can be dropped during another alert

Location: `Veltranomixa/ViewController.swift:370`, called from the alert action handlers at lines 119, 363 and 367.

`info()` returns whenever a modal is already presented. Start-challenge, reset and tutorial actions synchronously perform disk work and may call `info()` from their failure handlers while the original alert is still being dismissed. Under that timing, the failure message is discarded. Normal successful flows do not exercise this path.

This is a source-identified presentation risk, not a reproduced device failure. A follow-up should inject a write/reset error during an alert action and ensure the error is presented after dismissal (or queued safely), rather than silently lost. Do not present a second modal on top of a dismissing alert.

## Validation

- Current Release build for generic iOS/arm64: succeeded with signing disabled.
- Current rules/persistence suite: 26 tests passed, zero failures.
- Deterministic isolated checks confirm the upgrade-counter mismatch and future-version load rejection. The scenario code and output are included under `validation/recheck-2026-09-18/`; they operate only on temporary data.
- Release bundle includes the app and SnapKit privacy manifests. The fixed-random/UI-test environment keys and visible test banner were not found in its executable.
- No Han characters, TODO or FIXME markers were found in native Swift source.
- Full iPhone SE UI regression: 5 tests passed, zero failures on iOS 26.5. It covers gameplay/recovery, large-text collection/settings/workshop, Save Information and exposed wheel accessibility labels.

These checks do not establish physical-device VoiceOver, audio/haptics, lower supported iOS versions, exhaustive failure recovery or signed distribution readiness.

## Release status outside these findings

The project still has no configured development team. App Store Connect, distribution signing, TestFlight, the support URL and worldwide regional paperwork were not inspected or changed. Refer to the earlier release-readiness audit for those unresolved inputs; this audit does not reclassify them as completed.

The installed display name remains Lucky Island and the version is 1.0 (1). Lucky Island: Slot Builder was suggested in conversation; no store-name change was requested or applied, and App Store Connect name availability was not verified. The store name and device display name can be managed separately.
