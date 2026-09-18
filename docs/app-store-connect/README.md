# App Store Connect submission copy

Prepared September 18, 2026, for the current Lucky Island 1.0 implementation. These files are proposed submission copy, not an uploaded or approved listing.

- `metadata.en.json`: proposed name, subtitle, promotional text, keywords, identifiers and owner-dependent fields. Null values must be supplied by the owner, not pasted into App Store Connect.
- `description.en.txt`: player-facing description, 1,245 characters including trailing newline.
- `review-notes.en.txt`: reviewer instructions, 1,760 UTF-8 bytes including trailing newline.
- `support-page.en.txt`: support-page content to host publicly; this is not a deployed support URL.

Name: 26/30 characters. Subtitle: 30/30. Promotional text: 143/170. Keywords: 94/100 ASCII bytes. Both long text fields are below their respective limits. Availability of the proposed name has not been checked in the owner's App Store Connect account. The on-device display name is still Lucky Island.

Required owner inputs: real review contact name and international-format phone number; a monitored review email; a working public support URL; copyright ownership confirmation; price confirmation; an authorized signing team and processed build; regional licensing/declarations for worldwide distribution. Existing app records must retain their SKU and Bundle ID. Build 1 is only usable if not already consumed in App Store Connect.

Use English (U.S.) metadata for the current English-only UI. Recommended category is Games, with Strategy and Casual subcategories. Recommended initial price is Free and release control is Manual; both are owner choices. No IAPs, subscriptions, Game Center, App Clips or custom product pages need to be created for this version. A standard Apple EULA can be retained. First-version What's New is not required.

Prepare 1–10 accurate screenshots per required set; a 6.9-inch set at 1320 × 2868 is an accepted portrait option. Use actual production UI with no test-mode banners. Do not use existing 1206 × 2622 captures as a substitute for the required large-iPhone set. Current build targets iPhone only. Video previews are optional.

Age-rating suggestions are based on source behavior: no messaging, UGC, advertising in the native game, unrestricted in-app browsing, age verification, parental-control feature, mature content, violence, medical content, cash wagering or purchasable random items. The wheel consumes turns but does not accept a wager of Coins; None for simulated gambling is a source-based recommendation, not an Apple classification decision. Confirm against the actual questionnaire examples and final binary. Do not infer exemption just from no real money, or a rating solely from the word Slot. Let the questionnaire calculate the rating; do not claim Made for Kids.

The native source supports a proposed Data Not Collected privacy answer: gameplay remains on-device and no tracking/analytics SDK is integrated. Before publishing, verify actual operator/partner practices including any non-exempt support, analytics or website processing. Optional disclosure is conditional; do not assume all support data is exempt. The external hosted policy has its own website behavior and is opened in the system browser.

No custom cryptography was identified. Follow the no non-exempt encryption/system-only path appropriate to the actual export questions and final dependencies. Do not fabricate encryption approval codes. ITSAppUsesNonExemptEncryption is not currently set in the project.

Do not publish unverified accessibility feature claims. A few UI label/layout tests do not establish full VoiceOver or Larger Text conformance. Signed/TestFlight, real-device and older-iOS validation remain separate release work.

Worldwide availability requires regional review: mainland China game approval and applicable ICP information, Vietnam game licensing, EU DSA trader/non-trader declaration and any triggered regional ratings. These must be supplied by the owner; do not silently narrow territories.

After uploading the signed archive, choose the processed build, complete privacy/age/export/contact information, save version metadata, add the version for review and submit the review submission. No account changes, upload or submission have been performed here.

Official references:
- [Version metadata and review information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- [App information and regional requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/)
- [Screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Age-rating setup](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)
- [Age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
- [Privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/determine-and-upload-app-encryption-documentation/)
- [EU DSA](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)
- [Accessibility labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/)
