# Cadence

A personal iOS command center for tracking content-creator stats and ideas across Instagram and TikTok. Built as a daily-use app for my own DJI Osmo Action footage workflow, and as a sandbox for the modern Apple stack.

No third-party APIs — stats are entered manually or pulled from screenshots via on-device OCR, so there's no Meta/TikTok app-review dependency.

## Features

- **Stats tab** — Per-platform follower / post / engagement snapshots, headline count with delta-since-last, line chart over time (Swift Charts), and a deletable history list.
- **Log from screenshot** — Pick an Instagram or TikTok profile screenshot; Vision OCR parses followers, following, posts, and likes into a pre-filled log sheet.
- **Insights tab** — Growth rate, best-stretch detection, weekday performance, and posts-vs-follower-change correlation, computed from logged snapshots.
- **Ideas board** — Kanban-style content pipeline: `idea → filming → editing → posted`, per-platform tagging, freeform notes.
- **Home-screen widget** — Small/medium widget showing latest follower count and delta per platform. App writes summaries to a shared App Group; widget reads.
- **Daily reminders** — Local notification at a configurable time to nudge a stat log. No server.
- **Settings** — Reminder toggle + time picker.

## Stack

| Layer        | Used                                           |
|--------------|------------------------------------------------|
| UI           | SwiftUI                                        |
| Persistence  | SwiftData (`StatSnapshot`, `Idea` models)      |
| Charts       | Swift Charts                                   |
| OCR          | Vision (`VNRecognizeTextRequest`)              |
| Reminders    | UserNotifications                              |
| Widget       | WidgetKit + App Groups (shared `UserDefaults`) |

Targets iOS 17+ (SwiftData, Swift Charts, `ContentUnavailableView`).

## Project layout

```
Cadence/
├── Cadence/                     App target
│   ├── CadenceApp.swift         App entry, ModelContainer setup
│   ├── ContentView.swift        TabView root
│   ├── Models.swift             SwiftData models + enums
│   ├── StatsView.swift          Stats tab + log sheet
│   ├── ImportFromScreenshotSheet.swift
│   ├── OCRService.swift         Vision-based parser
│   ├── InsightsView.swift       Computed insights cards
│   ├── IdeasView.swift          Content board
│   ├── SettingsView.swift
│   ├── ReminderService.swift    UserNotifications wrapper
│   └── WidgetData.swift         App-Group writer
├── CadenceWidget/               Widget extension
│   ├── CadenceWidget.swift      Timeline + views
│   └── CadenceWidgetBundle.swift
├── CadenceTests/
└── CadenceUITests/
```

## Build

Open `Cadence.xcodeproj` in Xcode 15+ and run on an iOS 17+ simulator or device. The app and widget share the App Group `group.com.dawoudmahmud.cadence` — change the identifier in both targets' entitlements if you fork.

## Status

Personal-use app, not on the App Store. Active areas: tightening OCR heuristics for varied screenshot layouts and iterating on which insight cards are actually useful day to day.
