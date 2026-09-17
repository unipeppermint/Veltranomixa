# Lucky Island · Product plan

Baseline: September 16, 2026. English edition: September 17, 2026. The native strategy refinements are documented in [Strategy polish](05-strategy-polish.md).

## Direction and core experience

A single-player, offline wheel strategy game: shape your wheel, collect resources, complete challenges, and turn an island into a lively home. The alternative ambient island experience is a backup concept, not the chosen implementation. Mainland China remains part of the intended initial App Store distribution.

Designed for portrait iPhone play during short breaks, with an initial target of 3–5 minutes per run. The loop is: choose a goal → spin → collect resources → select upgrades or refit tiles → complete a challenge → keep a new landmark. There are no energy timers.

## Original lighthouse challenge

Start with 12 spins, no Wood, and no Coins. Collect at least 20 Wood before running out of spins.

| Tile | Count | Base effect |
| --- | --- | --- |
| Wood | 3 | Yields 2, 1, and 1 Wood |
| Coins | 3 | Yields 2, 1, and 3 Coins |
| Chest | 1 | Choose one of three upgrades |
| Breeze | 1 | Double the next Wood or Coins reward |

All eight tiles are equally likely: 12.5% per tile. Increasing the number of a resource's tiles increases its total probability. There are no hidden probability adjustments.

Every third spin also offers an upgrade. If a Chest and the third-spin trigger coincide, the player gets one choice, not two:

- **Better Tools:** every Wood tile yields +1 for the run; stacks.
- **Fair Breeze:** double the next Wood or Coins reward. Multiple Breezes do not stack. Other tile types do not consume it.
- **Extra Chances:** gain 2 spins.

Spend 4 Coins to boost all Wood tiles by 1. Base yield and tool boosts are added before Breeze doubles the reward. On the last spin, resolve the reward and goal first, then any upgrade opportunity, then check remaining spins. This allows Extra Chances to rescue a run.

Tile replacement was outside the original HTML prototype. The native version now provides a first free swap per new run, then charges 6 Coins per replacement; see the strategy document for complete mechanics.

## Progress and screens

Successful challenges unlock permanent landmarks, decorations, achievements, or wheel styles. Levels can be replayed. Failure never removes existing collection items. Run resources, boosts, and wheel changes reset with a new run. Current runs save automatically and can resume after interruption.

Screens: island home, map, level details, wheel game, upgrade choice, workshop, result, collection, and settings. Settings include sound, haptics, quick animation, tutorial replay, rules and odds, privacy and local saves, about, and a confirmed reset action.

## Initial content scope

One island with three regions and 15 levels; six tile types; 15 upgrades; 12 landmarks/decorations; 10 achievements; three wheel styles. These are product scope targets, not an App Store approval threshold. Challenges should vary through resource combinations and rule interactions, rather than only larger numeric goals.

## Art and feedback

A warm miniature toy island in ocean blue, cream, and coral. Use layered illustrations, readable icons, and text labels. Focus on decelerating spins, pointer motion, resource feedback, and visible construction progress. Respect Reduce Motion and provide independent sound and haptic switches. The HTML scene and emoji are only prototype representations.

## Business model and boundaries

Current implementation is free of advertising and in-app purchases. No account, social features, server, leaderboard, or cash/physical rewards. Any future paid chapter or cosmetic purchase is outside this implementation. Final name and commercial decisions still require owner confirmation.

## Release prerequisites

The chosen gameplay is a game regardless of its category label. The original release investigation identified mainland China publishing approval and related documentation as unresolved prerequisites; offline operation is not a claimed exemption. The owner currently has no game publication number or publishing partner.

Before submission: complete functional QA, verify asset rights, supply actual app screenshots, support and privacy-policy URLs, answer the age-rating questionnaire, prepare review notes, and perform device/TestFlight validation. Do not promise approval. Do not change Bundle ID, signing team, or distribution settings without authorization.

## Backup concept

An ambient interactive island where the wheel changes weather, time, music, and atmosphere, with free scene arrangement and postcards. It removes resource goals, win/loss, and capability upgrades. It remains a separate fallback and is not mixed into this game.

## References

- [Apple categories](https://developer.apple.com/app-store/categories/)
- [App information and regional requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App privacy information](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
