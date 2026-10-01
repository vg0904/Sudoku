# Architecture

This document explains how Sudoku is put together and why. It's meant to help you find your way
around before making a change. For coding conventions, see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Overview

The app is split into layers that depend only on the layers below them:

```
┌──────────────────────────────────────────────────────────┐
│ SudokuApp        scenes, menu commands, shared services │
├──────────────────────────────────────────────────────────┤
│ Views/ Settings/ SwiftUI: read state, call methods       │
├──────────────────────────────────────────────────────────┤
│ Game/            SudokuGame: the live game, rules, events│
├──────────────────────────────────────────────────────────┤
│ Model/           pure logic: grid, generator, records    │
└──────────────────────────────────────────────────────────┘
```

- **`Model/` knows nothing about SwiftUI.** It's plain value types plus the SwiftData records.
- **`Game/SudokuGame` is the single source of truth** for a game in progress. It's `@Observable`,
  so views update automatically when it changes, but it doesn't import SwiftUI.
- **Views don't implement rules.** They ask the game questions (`state(at:)`, `isEditable(_:)`,
  `canPause`…) and call its methods (`enter(_:)`, `pause()`…).

Keeping the rules below the views is what makes them testable without any UI: more than 200 tests
cover the logic.

## Model

| Type | Role |
|---|---|
| `SudokuGrid` | 81 cells stored as `Int`s (`0` = empty), with index maths (row, column, box) and conflict checks. |
| `SudokuGenerator` | Builds a random solved grid, then removes cells while the puzzle keeps **exactly one solution** (`countSolutions(_:limit:)`). |
| `Puzzle` | A generated puzzle: the starting `board`, its `solution` and its `Difficulty`. |
| `Difficulty` | Easy, medium or hard, expressed as how many cells to try to remove. |
| `GameRecord` | A SwiftData `@Model`: one entry in the records table. |
| `RecordStore` | The records rules on top of a `ModelContext`: top 10 per difficulty, ranking, trimming, known player names. |

The generator takes a `RandomNumberGenerator`, so tests pass a seeded one and get the same puzzle
every run. Generating is expensive (it solves the grid many times), so `SudokuGame.newGame` runs it
in `Task.detached` to keep the window responsive.

## Game state

`SudokuGame` holds everything about the game in progress:

- the `puzzle`, the player's `entries` (kept separate from the givens so they can be cleared), the
  wrong cells and the mistake count;
- `maxLives` and the derived `livesRemaining`, `isDefeated` and `isSolved`;
- the selection, the `GameClock`, and whether the game `isPaused`.

Some rules worth knowing:

- **Correct answers lock.** `isEditable(_:)` is `true` only for empty and wrong cells, so a correct
  number can be neither overwritten nor erased.
- **Pausing blocks every move** and stops the clock. `canPause` is `false` while generating and
  once the game is over.
- **`GameClock` is a plain value type with no timer.** It stores when the current run started and
  the time accumulated so far; every method takes `now` as a parameter, which is what lets tests
  use fixed dates. `TimerLabel` redraws once a second with a `TimelineView`, so only that label
  refreshes, not the 81 cells.

### Saving and resuming

A game in progress survives quitting the app:

- `snapshot(now:)` turns the game into a `SavedGame`, a plain `Codable` value. It returns `nil`
  when there's nothing worth resuming (no puzzle yet, generating, or finished).
- `saveRevision` goes up on every change worth saving (a move, an erase, a pause, a new game).
  `ContentView` watches that single value and writes the snapshot through `SavedGameStore`, so the
  model never knows where or how it's stored. On quit (⌘Q), the game is paused and saved once
  more so the seconds since the last move aren't lost.
- The start menu reads the snapshot to offer **Continue**. Choosing it hands the snapshot to
  `ContentView` as `GameStart.resume`. `restore(_:)` always brings the game back **paused**, the
  safe default for the model, and `ContentView` resumes it straight away: the player just chose
  Continue, so asking them to press Resume as well would be one step too many. A snapshot that
  fails `isValid` (damaged data, or a different `formatVersion`) isn't offered at all.
- Leaving the board (back to the menu, or closing the window) pauses and saves the game, the
  same as quitting.

### Events: the model says *what*, the view says *how*

Animations are triggered by small events the game publishes:

- **`celebration: Celebration?`** when a move completes a row, column, box or all nine of a number.
  It carries an incrementing `id`, the completed `groups`, and the cells to animate already sorted
  by distance from the move, which is what makes the wave start where you played.
- **`lastMistake: Mistake?`** when a wrong number is entered, with its own `id`, so repeating the
  same mistake shakes the cell again.

The game never waits or sleeps. The view decides how long an animation lasts and calls
`endCelebration()` when it's done (see `ContentView`'s `.task(id:)`). That keeps detection testable
without real time, and SwiftUI cancels a pending animation on its own if a new game starts.

## Views

`RootView` switches between the start menu (`StartMenuView`) and the board, following
`AppNavigator`, an `@Observable` model with the current screen and the menu's difficulty. Each
visit to the board creates a new `ContentView`, and with it a new `SudokuGame`: `GameStart` says
whether it resumes the saved game or generates a new one at the chosen difficulty. The board saves
in `onDisappear`, so leaving by any route (the 🏠 button, ⇧⌘M or closing the window) saves the same
way.

The Game menu reaches the navigator through `FocusedValues`. It's a class rather than a closure on
purpose: SwiftUI can't compare closures, so a closure in `FocusedValues` (or the environment) counts
as changed on every update, while a class compares by identity.

`ContentView` puts the board's window together: the toolbar, the header (timer and hearts), the board, the
number pad and the overlays (generating, paused, victory, defeat, confetti). It also handles the
keyboard, automatic pausing and the records flow.

| View | Notes |
|---|---|
| `BoardView` | Draws the 9×9 grid. Lines are one `Path` overlay, not per-cell borders. The selection is **one view that moves**, which is why it slides. |
| `CellView` | Draws one cell. Receives everything already resolved; reads only `themeColor` from the environment. |
| `NumberPadView` / `NumberPadKey` | Keys fill up with each number's progress. `NumberPadButtonStyle` draws the fill. |
| `HeartsView` | Lives, with a `PhaseAnimator` shake when one is lost. |
| `GameOutcomeOverlay` | The victory card (including record entry) and the defeat card. |
| `ConfettiView` | `TimelineView` + `Canvas` drawing ~140 pieces in one layer; pauses itself when done. |
| `RecordsView` | The Records window: a `Table` per difficulty, read with `@Query`. |

### The celebration pipeline

```
SudokuGame.celebration ──► BoardView / NumberPadView
                              │  one CellPulse per cell: (celebration id, delay in the wave)
                              ▼
                  CelebrationMotion / CelebrationBackdrop     (CelebrationEffects.swift)
                              │  keyframeAnimator animates a progress 0 → 1 after the delay
                              ▼
            CelebrationFrame(style:progress:allowsMotion:)    (pure function)
                              │  scale, rotation, elevation, tint, shine
                              ▼
                        applied to the cell or the key
```

Because the effect is a pure function of the progress, every style can be tested without playing
an animation, and cells and number-pad keys share exactly the same code. The same pieces power the
live preview in Settings (`CelebrationPreview`).

## Settings and theming

- **`GameSettings`** (`@Observable`) persists every setting in `UserDefaults`: language, lives,
  timer, visual aids, reduce animations, celebration style and theme.
- `SudokuApp.appEnvironment(_:)` injects into **every scene** the settings, the chosen `locale`
  (which is how the language changes without restarting), the theme colour
  (`\.themeColor`) and the tint for system controls.
- `AppTheme.system` uses the Mac's accent colour; the fixed themes come from
  `Assets.xcassets/Theme`, with light and dark variants picked for contrast.

## Scenes and commands

`SudokuApp` declares three scenes:

- a `WindowGroup` with the game;
- a `Window` for Records (a single window: asking for it again brings it to the front);
- `Settings`, which macOS opens with ⌘,.

**One `ModelContainer`** is created in `SudokuApp.init` and attached to both the game and the
Records scenes, so a record saved in one window shows up immediately in the other through `@Query`.

The **Game** menu (`GameCommands`) lives outside the view hierarchy, so it reaches the game of the
focused window through **focused values** (`\.sudokuGame`, `\.isConfirmingClearBoard`). That keeps
it correct with several windows open, each with its own game.

## Records flow

1. When `game.isSolved` becomes `true`, `ContentView` asks `RecordStore` for the rank of the time
   in that difficulty and captures the time, lives and mistakes **at that moment**.
2. If the time makes the top 10, the victory card shows the rank and a name field pre-filled with
   the last name used.
3. The record is saved when the player presses Save, **or** automatically when `isSolved` goes back
   to `false` (a new game, ⌘N, a difficulty change…). Watching that single transition covers every
   path.
4. Games helped by the debug shortcut have `isEligibleForRecords == false` and are never ranked.

## Testing

Each area has its own Swift Testing suite in `SudokuTests/`. Logic is made testable by injecting
whatever varies: the time (`now:`), randomness (`SeededRandomNumberGenerator`), `UserDefaults`
(isolated suites) and SwiftData (in-memory containers). Pure functions such as `CelebrationFrame`
and `ConfettiPiece.snapshot(at:)` are tested by sampling them over time instead of running
animations.
