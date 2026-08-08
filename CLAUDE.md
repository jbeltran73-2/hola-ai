# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Whisper-AI is a macOS voice dictation application that captures audio, sends it to OpenAI Whisper API for transcription, post-processes with GPT for formatting, and inserts text into any active application.

## Tech Stack

- **Language**: Swift 6.0+
- **Platform**: macOS 13.0+ (Ventura)
- **UI Framework**: SwiftUI + AppKit (for menu bar)
- **Audio**: AVFoundation
- **Networking**: URLSession with async/await
- **Build System**: Swift Package Manager

## Build Commands

```bash
swift build              # Build the project
swift run WhisperAI      # Run the application
swift test               # Run tests
swift build -c release   # Build release version
```

## Project Structure

```
Sources/WhisperAI/
├── App/               # Application lifecycle (WhisperAIApp.swift entry point)
├── UI/                # SwiftUI views
├── Services/          # Business logic
│   ├── AudioCapture/  # Microphone handling (AVFoundation)
│   ├── Transcription/ # Whisper API integration
│   └── TextInsertion/ # Accessibility APIs for text insertion
├── Models/            # Data models
├── Utilities/         # Helpers
└── Resources/         # Assets
```

## Architecture

The app follows a service-based architecture:
1. **AudioCapture** captures microphone input and produces audio suitable for speech recognition
2. **Transcription** sends audio to OpenAI Whisper API and receives text
3. **TextInsertion** uses macOS Accessibility APIs to insert text into the focused field of any app

The app runs as a menu bar application (LSUIElement) with no dock icon.

## Coding Conventions

- Prefer `async/await` over completion handlers
- Use `@MainActor` for UI-related code
- One primary type per file
- Extensions in separate files: `TypeName+Extension.swift`
- Import order: Foundation, Apple frameworks, third-party
- Define custom error types per module
- Log errors with context using `os.log`

## macOS Gotchas

- Menu bar apps need `LSUIElement = true` in Info.plist
- Accessibility requires user permission + entitlements
- Global hotkeys need special handling (no standard API)
- Audio capture requires microphone permission

## API Integration Notes

- Whisper API accepts audio files (not streams for basic tier)
- Maximum audio length: 25MB or ~25 minutes
- Response time varies: plan for 1-3 seconds

## Environment Setup

Swift 6.x with Command Line Tools only has known compatibility issues. If `swift build` fails with "SDK not supported by compiler":

```bash
# Option 1: Reinstall Command Line Tools
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install

# Option 2: Install full Xcode (recommended for macOS app development)
```

## Apple Developer Account

- **Developer ID**: Juan Beltran (K4Y5K8699H)
- **Certificate**: Developer ID Application: Juan Beltran (K4Y5K8699H)
- **Never store app-specific passwords, certificates, or Apple ID credentials in this file**

### GitHub Actions Secrets (repo: jbeltran73-2/hola-ai)

Store these only in GitHub → Settings → Secrets and variables → Actions:

| Secret | Description |
|--------|-------------|
| `CERTIFICATE_P12` | Developer ID Application certificate (base64) |
| `CERTIFICATE_PASSWORD` | Certificate export password |
| `APPLE_TEAM_ID` | Team ID (K4Y5K8699H) |
| `APPLE_PASSWORD` | App-specific password for notarization |
| `APPLE_ID` | Apple ID email for notarization |

Local notarization uses a Keychain profile (`NOTARY_PROFILE`), not a password in git.

## Ralph Agent Integration

This project uses Ralph for autonomous development. Key files:
- `prd.json` - User stories with `passes` status
- `progress.txt` - Development log and learnings
- `AGENTS.md` - Patterns and gotchas for agents

When working on user stories, update `prd.json` to mark `passes: true` when complete, and append learnings to `progress.txt`.
