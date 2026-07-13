# MemoriesAppiOS

MemoriesAppiOS is an iPhone and iPad companion app for the Family Memories server app.

The current server exposes its viewing, editing, upload, login, and admin workflows as authenticated web routes rather than a dedicated JSON API. This iOS app therefore provides a native SwiftUI shell around the server UI using `WKWebView`, with iOS-friendly server settings and shortcuts for common Memories routes.

## Features

- Save and normalize the Memories server HTTPS URL.
- Browse the Memories home/search page.
- Open common server routes from a native menu:
  - Home
  - Add Media
  - Needs Details
  - Guide
  - Admin
- Use the server's existing login session and forms.
- View photos, videos, audio, and documents through the server media routes.
- Add or replace media using the server's existing upload forms.
- Edit memory details through the server's existing edit forms.
- Share the current page URL from iOS.

## Server Setup

The app does not ship with a default server. On first launch, enter the HTTPS URL for the Family Memories server you operate.

## Support and Privacy

- Support: https://jlrosssc.github.io/MemoriesAppiOS/
- Privacy policy: https://jlrosssc.github.io/MemoriesAppiOS/privacy.html
- GitHub privacy policy copy: [PRIVACY.md](PRIVACY.md)

## Project

- Open `MemoriesAppiOS.xcodeproj` in Xcode.
- Build the `MemoriesAppiOS` target.
- Bundle identifier: `com.jlrosssc.MemoriesAppiOS`.
- Minimum iOS version: 17.0.

## Server Notes

This app is designed to work with the existing `family-memories` FastAPI server routes:

- `/`
- `/login`
- `/media/new`
- `/needs-details`
- `/guide`
- `/admin`
- `/memories/{id}`
- `/memories/{id}/edit`
- `/media/{path}`

Future versions can add a fully native list/detail/editor once the server exposes JSON endpoints for memories, people, authentication, and multipart media uploads.
