# Changelog

All notable changes to Sudoku are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - Unreleased

The first public release.

### Gameplay

- Random puzzles with a unique solution at three difficulties: Easy, Medium and Hard.
- Lives: choose 1 to 5 hearts per game, or play without a limit. Each mistake costs a heart.
- Correct answers lock in place, and only wrong numbers can be erased.
- Clearing the board asks for confirmation.
- Pause with ⌘P or the toolbar button. The board is hidden while paused, and the game pauses
  automatically when you switch to another app or window.
- A start menu with the app's logo: continue the saved game, or pick a difficulty and start a new
  one. **Back to Menu** (the 🏠 toolbar button, or ⇧⌘M in the Game menu) saves the game and goes
  back to it.
- The game in progress is saved automatically, and **Continue** in the start menu picks it up
  right where you left off, with the clock running from the saved time.

### Board and number pad

- Highlight the selected row, column and box, and glow numbers that match the selected one.
- Alternating 3×3 boxes, a selection that slides between cells, numbers that drop into place and a
  shake on mistakes.
- Number pad keys fill up as you place each number and turn into a checkmark when all nine are
  placed.

### Celebrations

- Completing a row, column, box or all nine of a number plays a celebration in the style you
  choose: Wave, Flip, Jump, Shine or None, with a live preview in Settings.
- Confetti when you solve the puzzle.

### Records

- Arcade-style top 10 per difficulty. Enter your name when you set a record: the last name used is
  pre-filled and previous names are one click away.
- Each record shows the time, the lives setting, mistakes and date.
- A separate Records window (⌘L) with one table per difficulty. Select records and delete them with
  ⌫, the toolbar's trash button or a right-click; it asks for confirmation first.
- The victory card shows your best time when you don't set a new record.

### Appearance and accessibility

- Colour themes: follow the Mac's accent colour, or pick one of eight colours with light and dark
  variants that stay readable.
- VoiceOver reads every cell's number and state, with an optional setting to also announce its row
  and column.
- Every animation respects Reduce Motion, and there's an in-app "Reduce animations" setting.
- English and Spanish, switchable in Settings without restarting.

### Mac

- Toolbar with Liquid Glass, a Game menu with keyboard shortcuts, a Settings window (⌘,) and a Help
  menu that links to the documentation and the issue tracker.

[1.0.0]: https://github.com/vg0904/Sudoku/releases/tag/v1.0.0
