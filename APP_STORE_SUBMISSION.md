# MemoriesAppiOS App Store Submission Prep

This document tracks the items needed to prepare MemoriesAppiOS for App Store review.

## App Store Connect Metadata

- App name: `Memories`
- Bundle ID: `com.jlrosssc.MemoriesAppiOS`
- SKU: `memoriesappios`
- Category: `Photo & Video` or `Lifestyle`
- Age rating: choose based on the family media stored on the connected server
- Support URL: `https://jlrosssc.github.io/MemoriesAppiOS/`
- Privacy Policy URL: `https://jlrosssc.github.io/MemoriesAppiOS/privacy.html`

## Suggested Description

Memories is an iPhone and iPad companion for a self-hosted Family Memories server. It lets authorized family members browse, search, view, edit, and upload family photos, videos, audio, documents, and memory details through the existing Memories server interface.

The app is designed for families who already operate a compatible Memories server. It does not include a public hosted service.

## Suggested Keywords

family memories, photos, archive, genealogy, home videos, documents, private family, media library

## Review Notes

Explain the app's dependency on a self-hosted server so App Review can test it.

```text
MemoriesAppiOS is a companion client for a self-hosted Family Memories server.

Test server:
<provide review server URL>

Test account:
Username: <provide reviewer username>
Password: <provide reviewer password>

After login, reviewers can use the toolbar menu to open Home, Add Media, Needs Details, Guide, and Admin routes. Media upload uses the server's existing upload form and iOS file/photo pickers.
```

Do not submit until a reviewer-safe test account and reachable server URL are available.

## Current App Version Summary

Use the current repository version as the submission baseline.

- SwiftUI iPhone/iPad app.
- WebKit-based client for the existing Family Memories server UI.
- Multiple saved Memories server profiles.
- Optional username and password storage for HTTP Basic/Digest authentication.
- Passwords are stored in the iOS Keychain with this-device-only accessibility.
- Navigation shortcuts for Home, Add Media, Needs Details, Guide, and Admin.
- Back, forward, reload, stop, and share actions.
- In-app handling for website JavaScript alerts, confirmations, and text prompts.
- Upload and page-load error alerts for clearer review/testing feedback.
- App icon is complete and present in the asset catalog.

## Privacy Checklist

Confirm these statements against the deployed server before answering App Store privacy questions.

- The iOS app stores saved server names, URLs, and usernames locally in app storage.
- Server connections must use HTTPS.
- Optional saved passwords are stored in the iOS Keychain.
- The WebKit view may store server cookies/session data locally if the user signs in.
- Media selected for upload is sent only to the configured Memories server.
- The app does not include third-party analytics SDKs.
- The app does not include advertising SDKs.
- The app does not sell or broker user data.
- The app may access Photos, Camera, and Microphone only when the user interacts with server upload forms.

If the server logs IP addresses, account activity, uploaded media, or profile data, disclose that in the privacy policy and App Store privacy labels.

## Required App Store Assets

- 1024x1024 app icon: already present at `MemoriesAppiOS/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- iPhone screenshots for all required display sizes selected in App Store Connect.
- iPad screenshots if listing iPad support.
- Support page URL.
- Privacy policy URL.
- Demo account credentials for App Review.

## Pre-Submission Build Checklist

- Open `MemoriesAppiOS.xcodeproj` in Xcode.
- Set the Apple Developer Team in Signing & Capabilities.
- Confirm bundle identifier is available in the Apple Developer account.
- Archive a Release build.
- Validate and upload from Xcode Organizer.
- Test on a physical iPhone with the production Memories server.
- Test login, logout, Home, Add Media, Needs Details, edit memory, media playback, and file upload.
- Test saved server creation, selection, editing, and deletion.
- Test an account/server that uses HTTP Basic or Digest authentication if that setup is expected in production.
- Confirm camera/photo/microphone prompts are accurate.
- Confirm the review server uses a valid HTTPS certificate.
- Confirm the support and privacy URLs load publicly without authentication.

## Useful Apple Resources

- App Store Connect: https://appstoreconnect.apple.com/
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App privacy details overview: https://developer.apple.com/app-store/app-privacy-details/
- Preparing apps for review: https://developer.apple.com/app-store/review/
