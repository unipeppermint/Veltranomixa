# Lucky Island · Prototype guide

Original prototype: September 16, 2026. Editable prototype copy translated to English on September 17, 2026.

## Files

- [Original visual reference](prototypes/lucky-island-visual-v1.png): three-screen art-direction reference, with the original embedded lettering preserved.
- [Interactive prototype](prototypes/lucky-island-interactive-v1.html): standalone HTML interaction example.
- [Source fragment](prototypes/lucky-island-source-v1.html): editable source.

The visual reference shows island home, wheel gameplay, and a three-choice upgrade panel. Its warm toy-island appearance is the art direction; its illustrated numbers and text are not authoritative game rules. The example 12/20 Wood, 6 Coins, and 5 remaining spins show a run in progress, not the initial state.

The reference was generated with the built-in ImageGen tool. It is not used as an interactive screen or bundled game asset. Production imagery has separate island, building, and item assets.

## Prototype flow

Start challenge → spin → choose upgrades → spend Coins on Wood boosts → win or lose → return to the island and collection. Quick spins are available for review.

The HTML demonstrates random rewards, eight-tile animation, three upgrades, Coin-funded Wood boosts, rules, continuing a run, a lighthouse unlock, retry, and basic settings. It keeps state in memory only.

## Native implementation differences

| Prototype | Native application |
| --- | --- |
| One lighthouse level | 15 levels across three regions |
| CSS scenery and emoji | Layered illustrations and consistent resource artwork |
| Memory-only progress | Versioned local save and interruption recovery |
| Quick animation only | Sound, haptics, quick animation, and accessibility support |
| Wood boost only | Full tile replacement workshop and yield/odds preview |
| Example collection entries | Collection driven by completed challenges |
| No audio/haptics | Native feedback services |

The HTML is not a shipping iOS app, not a WebView substitute, and not proof of final balance or review readiness.

## Review points

The island should emphasize visible progress and the next goal. Gameplay should expose targets, resources, and remaining spins immediately. Upgrades should present understandable tradeoffs. Animation and feedback should be comfortable, and the native art should retain the warm miniature feel.

## Historical verification limits

The original source JavaScript passed syntax and structural checks. A previous browser attempt using a local file URL was blocked by policy, so the original prototype was not claimed to have passed browser end-to-end testing. The standalone file includes a preview runtime with inline core behavior and needs no backend. Fonts and emoji vary by platform. Native simulator validation is documented separately.
