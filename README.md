# NOMA

<img src="NOMA/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="128" alt="NOMA coral N app icon">

A personal, local-only project and notes app for iPhone: projects contain
tick-box notes, pinned notes surface on the home screen, and notes can hold
photos and documents (including from Google Drive) — all locked behind
a 4-digit passcode, styled monochrome with coral accents. No accounts, no
sync, no third party, nobody else's eyes on it but yours.

Open `NOMA.xcodeproj` in Xcode to build the app. The `NOMA/` folder contains
its SwiftUI source and assets. NOMA was previously called CRANK.

## Requirements

The included Xcode project targets iOS 26.5 and uses Xcode 26.5. The source
uses iOS 17-era APIs; creating a separate project lets you choose an older target.

- A Mac with Xcode 15 or later (free from the Mac App Store)
- An iPhone running iOS 17 or later
- A free Apple ID (no paid developer account needed) — see signing note below
- Optionally, the Google Drive app installed on the iPhone if you want
  Drive files to show up as an attachment source (see below)

## Setup

1. Open `NOMA.xcodeproj` in Xcode.
2. Select the NOMA target and set your signing team under Signing & Capabilities.
3. Choose your connected iPhone and Run (⌘R).

The project includes camera and microphone usage descriptions. If creating a
separate project from source, include both `NSCameraUsageDescription` and
`NSMicrophoneUsageDescription` before using those features.

**Updating CRANK:** use the same signing team and keep the bundle identifier
`com.adamscourfield.crank` and Swift module name `CRANK`. Those internal names
are retained deliberately so NOMA updates the existing installation and preserves
SwiftData model identity. Do not uninstall the app or create a new data store.
The project and app display names are NOMA.

## What it does

- **Entry screen**: "NOMA" builds in letter by letter with a coral
  underline draw-in (a brief ident, like a production company bumper),
  then crossfades into a 4-digit passcode screen — dot indicators and a
  numeric keypad, matching the rest of the app's design rather than
  using the system's own passcode UI. The correct code is `2501`,
  hardcoded as a single constant at the top of `LockScreenView.swift`
  (there's no settings screen to change it from — edit that constant
  directly if you want a different one). A wrong code shakes the dots
  and clears; checked once at launch, not on every return to the
  foreground — easy to tighten later if you want that.
- **Home screen**: any pinned notes appear first, above your list of
  projects, both searchable (`Search notes and projects`). Each project
  row shows how many notes in it are still active, plus a small icon
  chip you choose when creating it. Pinned notes are capped at 4 by
  default with a "+N more pinned" expander, so a growing pinned list
  doesn't take over the home screen — search bypasses the cap and shows
  every match.
- **Projects**: the top-level container. Create as many as you like,
  each with a name and an icon picked from a small curated set (folder,
  briefcase, wrench, house, sun, and a few others); every row and header
  that shows the project reuses that same icon chip.
- **Notes are the tick-box**: every note has a checkbox. Ticking it plays
  a brief fill-and-collapse (not an instant vanish) before it archives —
  there's no separate "done" vs "archived" state to think about once
  that finishes. Each project has an Archive screen for anything you've
  ticked off, with a swipe action to restore a note if you ticked it by
  mistake. A project's note list is also searchable once it grows.
- **Pinning**: any note can be pinned, independent of its project —
  pinned, non-archived notes are what shows up on the home screen.
- Created and completed dates are recorded and shown on the note, but
  purely as information — nothing in the app treats them as a deadline.
- **Audio**: the Audio section in a note records from the microphone. Stop,
  then save or discard the recording. Saved clips can be renamed, played,
  paused, or deleted with a swipe. Going into the background or receiving
  an audio interruption stops recording and retains the draft for review.
  Leaving the editor with an unsaved draft asks whether to keep editing or
  discard it. Audio is stored locally as an existing `NoteDocument` attachment
  (`m4a`), preserving the existing SwiftData schema. Audio-only notes are kept.
- **Photos**: attach from your library (`PhotosPicker`, no extra
  permission prompt) or take one directly in the app with the camera
  button. Thumbnails get a rounded corner, a hairline border, and a soft
  shadow so they read as deliberate, not slapped-on; tap one to view it
  full-screen.
- **Documents**: tap "Add Document" to open the system file browser, which
  lists iCloud Drive, On My iPhone, and — if you have the Google Drive app
  installed — your Drive files too, since Drive registers itself as a
  Files provider. Whatever you pick is copied into the note (same as
  photos), so the note stays self-contained even if the original file
  later moves. Tap a document to preview it with QuickLook.
- Empty notes (no title, body, photos, or documents) are discarded
  automatically when you leave the editor.
- **Design**: monochrome throughout (system backgrounds/text, which
  already adapt to light/dark), with a single coral accent for anything
  interactive or "on" — pins, ticked notes, buttons, the passcode dots.

## What it deliberately doesn't do

- No iCloud sync — everything lives only on this one phone.
- No sharing, collaboration, or export — single-user by design.
- No live connection to Google Drive — picking a Drive file copies it in
  once; the note won't reflect later edits made to the original in Drive.
- No renaming a project after creation, and no reordering projects —
  straightforward to add if you find you want it.
- No syncing NOMA between devices (e.g. an iPhone and a Mac build) —
  that would mean either CloudKit (which needs a paid Apple Developer
  account) or building a real local-network sync protocol ourselves;
  deliberately out of scope for a personal, single-device app.

## File layout

```
NOMA/
  NOMAApp.swift                 — app entry point, passcode gate, SwiftData container
  Theme/
    Color+NOMA.swift             — the one accent color token (Color.coral)
  Audio/
    NoteAudioController.swift                 — microphone, playback, and interruption handling
  Models/
    Project.swift                  — top-level container; name, icon, holds notes
    Note.swift                      — the tick-box note: title, body, pin, archive state, dates
    NoteImage.swift                  — one attached photo, belongs to a Note
    NoteDocument.swift                 — one attached document, belongs to a Note
  Views/
    LockScreenView.swift            — ident reveal + 4-digit passcode entry screen
    HomeView.swift                   — pinned notes (capped) + searchable project list
    ProjectRowView.swift              — one row on the home screen
    ProjectIconView.swift              — the coral icon chip, and the curated icon set
    NewProjectView.swift                — name + icon picker sheet for creating a project
    PinnedNoteRow.swift                   — one pinned-note row on the home screen
    ProjectDetailView.swift                — active notes inside a project, searchable
    ArchiveView.swift                       — completed notes for a project
    NoteRowView.swift                        — one row inside a project (tick box + thumbnail)
    NoteDetailView.swift                      — the note editor
    NoteAudioSection.swift                    — inline recorder and saved audio playback
    DocumentRowView.swift                      — one attached-document row
    DocumentPreviewView.swift                   — QuickLook wrapper for documents
    CameraCaptureView.swift                      — UIImagePickerController wrapper for the camera
    ImageViewerView.swift                         — full-screen photo viewer
  Resources/
    Assets.xcassets/                             — the one asset catalog; drag this whole folder in, not its children individually
      AccentColor.colorset/                       — the coral accent, light + dark variants
      AppIcon.appiconset/                           — the home-screen icon (coral, a rounded N monogram)
```

## Updating an existing installation

Use the original Xcode project with its existing bundle identifier and signing
team. Install over the current app; do not uninstall it. Keep the model container
configuration and storage location unchanged. Back up `Library/Application Support`
from the app's data container, including the database, WAL, and hidden external
attachment directory, before updating. The audio feature adds no stored model
properties or entities and requires no schema migration.

`Tests/StoreCompatibilityCheck.swift` can be compiled with the four model files
using the macOS Swift toolchain. Pass a **disposable copy** of `default.store`,
plus an optional playable audio fixture, to check that existing data opens and
audio attachment save/read/rename/archive/delete operations preserve its contents.

## Branding

`Branding/noma-icon.svg` is the editable vector master. Regenerate the opaque
1024px app icon with:

```sh
xcrun swift Branding/render-icon.swift NOMA/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
```
