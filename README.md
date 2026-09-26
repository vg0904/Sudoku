# Sudoku

A native, ad-free Sudoku for the Mac, written in SwiftUI.

It started as a hands-on way to learn Swift and Apple's frameworks, so the code favours
modern, idiomatic APIs (`@Observable`, Swift Testing, Swift concurrency, SwiftData) and explains
*why* it does things the way it does.

*[Leer en español](README.es.md)*

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
- **Colour themes**: follows your Mac's accent colour by default, or pick one of eight colours tuned
  to stay readable in light and dark mode.
- **Accessibility**: VoiceOver labels throughout, and every animation respects Reduce Motion
  (plus an in-app "Reduce animations" setting).
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

## Contributing

Contributions are welcome! Please read **[CONTRIBUTING.md](CONTRIBUTING.md)** first. It covers the
conventions this project relies on (actor isolation, localisation, animations and tests).

A note on language: **code comments are written in Spanish**, while identifiers, string keys and
documentation are in English. Comments in either language are welcome in contributions.

## License

Sudoku is released under the [MIT License](LICENSE).
