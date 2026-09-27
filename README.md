# Sudoku

A native, ad-free Sudoku for the Mac, written in SwiftUI.

It started as a hands-on way to learn Swift and Apple's frameworks, so the code favours
modern, idiomatic APIs (`@Observable`, Swift Testing, Swift concurrency, SwiftData) and explains
*why* it does things the way it does.

*[Leer en español](README.es.md)*

## Just want to play?

You don't need to know anything about programming. You only need a Mac with **macOS 27 or
later**.

### 1. Download it

1. Go to the [latest release](https://github.com/vg0904/Sudoku/releases/latest).
2. Under **Assets**, click **Sudoku.zip**. It goes to your **Downloads** folder.
3. Open **Downloads** and double-click **Sudoku.zip**. A **Sudoku** app appears next to it.
4. Drag **Sudoku** into your **Applications** folder.

### 2. Open it the first time

Because Sudoku is a free project and isn't registered with Apple ([here's why](#about-this-project)),
the first time you open it your Mac shows a warning saying it can't check the app. That's
expected. You only have to allow it **once**:

1. Double-click **Sudoku** in Applications. When the warning appears, close it with **Done** (not
   **Move to Trash**).
2. Open **System Settings** (the grey gear icon in the Dock, or  → System Settings).
3. Click **Privacy & Security** in the sidebar.
4. Scroll down to the **Security** section. You'll see a message about Sudoku: click
   **Open Anyway**, then enter your Mac's password or use Touch ID.
5. Click **Open**.

That's it. From now on, Sudoku opens like any other app.

### 3. Play

- **Click a cell**, then **type a number** on your keyboard or click one on the number pad at the
  bottom. You can also move around with the arrow keys.
- Each row, each column and each 3×3 box must contain every number from 1 to 9, exactly once.
- A wrong number turns red and costs a heart ♥. Select it and press **Delete** (⌫) to erase it.
- The number pad shows how many of each number you've placed; a ✓ means all nine are done.
- Pick the difficulty at the top of the window, and press ⌘P to pause. Your game is saved when you
  quit, so you can carry on later.
- Colours, lives, celebrations and more are in **Sudoku → Settings** (⌘,).

### Something went wrong?

- **There's no "Open Anyway" button:** open Sudoku once first (step 1), then check System Settings
  again. The button only appears after you've tried to open the app.
- **The warning says the app is damaged:** that sometimes happens with downloaded apps. Open the
  **Terminal** app, paste the line below and press Return, then open Sudoku again:

  ```sh
  xattr -dr com.apple.quarantine /Applications/Sudoku.app
  ```

- **Still stuck, or found a bug?** In Sudoku, choose **Help → Report a Problem…**, or
  [open an issue](https://github.com/vg0904/Sudoku/issues/new) here on GitHub.

If you'd rather not open an app that isn't registered with Apple, anyone with Xcode can
[build it from the source code](#getting-started) instead.

## Features

- **Random puzzles with a unique solution** at three difficulty levels, generated off the main
  thread so the window never freezes.
- **Lives** (1–5 or unlimited): each mistake costs a heart. Correct answers lock in place, and only
  wrong numbers can be erased, so a stray keystroke never costs you.
- **Visual aids**: highlight the selected row, column and box; glow matching numbers; alternating
  3×3 boxes; a selection that slides between cells.
- **Progress on the number pad**: each key fills up as you place that number, then celebrates and
  turns into a checkmark when all nine are placed.
- **Celebrations** when you complete a row, column, box or number, in a style you pick (Wave, Flip,
  Jump, Shine or None), with a live preview in Settings. Confetti when you win.
- **Arcade-style records**: a top 10 per difficulty stored with SwiftData. Enter your name when
  you set a record; the last name is remembered and previous names are one click away. Each record
  shows the time, lives used, mistakes and date.
- **Fair timing**: pause with ⌘P (the board is hidden while paused) and the game pauses
  automatically when you switch apps.
- **Your game is saved**: quit whenever you like, and pick up where you left off the next time you
  open the app.
- **Colour themes**: follows your Mac's accent colour by default, or pick one of eight colours tuned
  to stay readable in light and dark mode.
- **Accessibility**: VoiceOver reads every cell's number and state, and can also announce its row
  and column. Every animation respects Reduce Motion, plus an in-app "Reduce animations" setting.
- **Localised** in English and Spanish, switchable in Settings without restarting.
- **Mac-native**: toolbar with Liquid Glass, menu commands with keyboard shortcuts, a Settings window
  and a separate Records window.

### Keyboard shortcuts

| Shortcut | Action |
|---|---|
| 1–9 | Enter a number in the selected cell |
| Arrow keys | Move the selection |
| ⌫ / ⌦ | Erase a wrong number |
| ⌘N | New game |
| ⌘R | Clear the board (asks for confirmation) |
| ⌘P | Pause / resume |
| ⌘L | Open the Records window |
| ⌘, | Settings |

## Requirements

- macOS 27 or later
- Xcode 27 or later

The project has no third-party dependencies.

## Getting started

1. Clone the repository:

   ```sh
   git clone https://github.com/vg0904/Sudoku.git
   ```

2. Open `Sudoku.xcodeproj` in Xcode.
3. **Set up signing.** The project is configured with the maintainer's development team. In the
   project editor, select the **Sudoku** target → **Signing & Capabilities**, and choose your own
   team (a free personal team works). If Xcode complains that the bundle identifier is taken,
   change it to something unique, such as `com.yourname.Sudoku`.

   Please don't commit these signing changes in pull requests.
4. Press **⌘R** to build and run.

## Running the tests

The logic is covered by more than 200 tests written with [Swift Testing](https://developer.apple.com/documentation/testing).

- In Xcode: **⌘U**, or open the Test navigator (**⌘6**).
- From the command line:

  ```sh
  xcodebuild test -project Sudoku.xcodeproj -scheme Sudoku -destination 'platform=macOS'
  ```

Tests never touch your real data: settings use an isolated `UserDefaults` suite and records use an
in-memory SwiftData store.

## Project structure

```
Sudoku/
├── Model/      Pure game logic: the grid, the puzzle generator, difficulty, records.
├── Game/       The live game state (`SudokuGame`), the clock and celebration events.
├── Settings/   User settings (persisted in UserDefaults) and the Settings window.
├── Views/      SwiftUI views: board, cells, number pad, overlays, confetti, records.
└── SudokuApp.swift   Scenes (game window, Records, Settings) and menu commands.
SudokuTests/    Swift Testing suites, one file per area.
```

For how the pieces fit together — and the non-obvious decisions behind them — see
**[ARCHITECTURE.md](docs/ARCHITECTURE.md)**.

## About this project

I'm a student, and Sudoku is a hobby project. I built it to learn Swift and Apple's frameworks
properly, by making something I actually wanted to use: a clean Sudoku for my Mac, with no ads and
no tracking. I'm sharing it so others can play it, read the code, learn from it, and help make it
better.

I don't make any money from it, and I don't intend to. That's also why the app isn't notarized:
notarization requires a paid Apple Developer Program membership (99 USD a year), which doesn't make
sense for a free project made for learning. The full source code is here, so you can always check
exactly what the app does, or build it yourself.

## Contributing

Contributions are welcome! Please read **[CONTRIBUTING.md](CONTRIBUTING.md)** first. It covers the
conventions this project relies on (actor isolation, localisation, animations and tests).

A note on language: **code comments are written in Spanish**, while identifiers, string keys and
documentation are in English. Comments in either language are welcome in contributions.

## What's new

See the [CHANGELOG](CHANGELOG.md) for what changed in each version.

## License

Sudoku is released under the [MIT License](LICENSE).
