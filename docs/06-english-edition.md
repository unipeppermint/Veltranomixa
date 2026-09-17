# Lucky Island · English edition

September 17, 2026.

All active native app copy is English: navigation, levels, resources, upgrades, island rules, achievements, workshop previews, confirmations, tutorial, privacy, about, error/recovery messages, and accessibility descriptions. The display name is Lucky Island. Stable save IDs, rewards, game rules, Bundle ID, and signing settings are unchanged.

Older saved SpinRecords may contain Chinese display text. Their English fallback is computed only for display; UUIDs, indices, balances, and pending acknowledgement are unchanged, so translation cannot reroll or duplicate a reward.

Layout adjustments include a flexible game title between compact, accessible navigation buttons, word-wrapped button titles/subtitles, a full-width page title at accessibility sizes, a one-column workshop grid for large text, and vertical collection cards at accessibility sizes. The game wheel is capped at 300 points and the home illustration uses less vertical space so English copy has more room. Wheel labels retain their radial alignment with a bounded text scale.

Editable project plans, prototype HTML copy, and tests have been translated. Original visual mockups, historic screenshots, and raw historic logs retain their original content as test/design evidence. They are outside the app target. New English test captures and logs are saved under `validation/english/`.

## Verification

- Swift package: 23 rules and save tests passed, including legacy message compatibility.
- iPhone 17 Pro, iOS 26.5: all 4 UI tests passed before the final compact header/wheel adjustment; the final home was checked separately.
- iPhone SE (3rd generation), iOS 26.5: all 4 UI tests passed with the final layout, covering a complete run, recovery, radial labels, settings, collection, and accessibility-sized workshop previews.
- Final Release simulator build: succeeded with signing disabled.
- Both HTML prototypes: embedded JavaScript syntax checks passed, including the standalone iframe source.
- Native source, tests, editable documents, and HTML contain no remaining Han characters. Archived logs/images are excluded from this text scan and from the app bundle.

The small-screen pages scroll vertically where content exceeds the viewport. No wording is intentionally truncated; long titles and button subtitles wrap. English captures are in `validation/english/iphone17pro/` and `validation/english/iphone-se/`. `00-final-home.png` shows the final compact home layout; older iPhone 17 Pro game captures precede the last spacing adjustment. Raw logs are retained alongside them.
