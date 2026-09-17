# Lucky Island · Strategy polish

September 17, 2026. Changes were made in the existing native app without additional dependencies.

## Playable improvements

- One free tile replacement per new run, available from level 1. Later swaps cost 6 Coins. Boosting Wood tiles still costs 4 Coins. An identical replacement cannot consume Coins or the free swap.
- The dedicated workshop shows the original tile, replacement resource, probability changes, next-spin yield, and Coin budget. It warns when a swap removes the last source of an unfinished target resource.
- The wheel uses radial layout: icon outside, label/value inside, all following the sector angle. The board and content rotate together. Labels show base plus tools; the workshop shows full next-spin yield. Original tile positions are numbered 1–8 clockwise from the top.
- Goal cards show the next-spin environment. Level details explain the local rule. Home and tutorial emphasize wheel strategy.
- From level 2, the growth upgrade follows the unfinished Wood, Shells, or Coins goal. A continuation option remains available; the third offer adds variety. Unaffordable Timber Trade is excluded from new offers.

## Island rules

| Levels | Rule | Decision |
| --- | --- | --- |
| 1, 2 | Free workshop | Trade resource probability against saving Coins for boosts |
| 4, 5, 7, 10 | Grove neighbors | Each adjacent Wood tile adds +1 to landed Wood; tiles 1 and 8 are adjacent |
| 6, 8, 11, 12, 14 | Tidal rhythm | Every third spin gives Shells +3; other spins give Wood +1 |
| 3, 9, 13, 15 | Island market | Odd spins give Wood +2; even spins give Coins +2 |

Each tile remains 12.5% likely. Wood and Coins resolve base + tools + island bonus, then Breeze. Shells do not consume Breeze.

## Persistence and verification

Existing v1 saves do not require reset. Optional mechanics-version and free-refit fields allow older runs to retain classic yields and replacement prices. Newly started runs use the new mechanics. Tide and market phases derive from persisted spin count, so relaunching cannot reset their cycle.

UI automation uses a DEBUG-only save subdirectory, separate from player progress. Fixed-result test images are not App Store marketing captures.

Regression coverage includes free-swap persistence, identical swaps, grove wraparound adjacency and Breeze order, tide-cycle recovery, market alternation, old-save compatibility, and upgrade offers. UI coverage includes previews, new probabilities, paid-swap constraints, resume/win, and large-text workshop confirmation.

## Balance diagnostics

A fixed-seed policy ran 1,000 games per level, 15,000 total. It uses the free swap, preserves necessary resource sources, chooses goal-relevant growth upgrades, and extends low-spin runs. Win rates were 93.0%–100%, with average spin counts of 8.525–27.172. Early levels intentionally remain forgiving. This does not establish player win rates or prove strategic depth. Results are in `validation/strategy-balance.csv`.

An earlier policy could remove the only Coins tile and stall a Coins goal. The workshop now warns about removing necessary sources, and the diagnostic policy preserves them. Players can still choose risky layouts.

## Historical verification results

- Debug and Release simulator builds passed; no signed archive.
- 22 rule/save tests passed at this stage.
- Three UI tests passed across two runs: free swap/preview/paid limit/resume/win, large-text collection/settings, and large-text workshop preview/confirmation.
- The 15,000-run simulation completed with every level achievable.
- The wheel and large-text workshop screenshots were visually inspected. Original evidence is in `validation/strategy-screenshots/`.
- Test device: iPhone 17 Pro simulator on iOS 26.5. No new device or TestFlight verification.
- No dependencies, Bundle ID, signing team, or distribution settings changed.

## Radial wheel behavior

The top pointer stays fixed while the entire board rotates. Tile i starts with content rotation i × 45 degrees. The selected board angle is −i × 45 degrees, so the winning tile becomes upright when it stops under the pointer. Restored runs use the same relation. There is no independently counter-rotating content and no orbiting pointer.

The fifth-tile half-turn and relaunch UI regression passed after an initial test setup issue with onboarding was corrected. The radial arrangement was visually inspected. The reference capture is `validation/strategy-screenshots/wheel-radial-layout.png`.

Pointer feedback follows the original keyframe rhythm: a small deflection and return every 0.12 seconds, using the initial default keyframe timing and repeat count. Quick spins and Reduce Motion skip the pointer wobble.
