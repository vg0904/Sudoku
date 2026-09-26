# Contributing to Sudoku

Thanks for your interest in improving Sudoku! This guide explains how to propose changes and, just
as importantly, the conventions the code relies on. Several of them exist because of bugs that
compile without warnings, so please read the [Conventions](#conventions) section before opening a
pull request.

## Ways to contribute

- **Report a bug** or **suggest a feature** by opening an issue. For bugs, include your macOS
  version, the steps to reproduce, what you expected and what happened.
- **Fix a bug or build a feature.** For anything larger than a small fix, please open an issue
  first so we can agree on the approach before you invest time in it.
- **Translate.** The app is in English and Spanish; new languages are welcome (see
  [Localisation](#localisation)).

## Development setup

Follow [Getting started](README.md#getting-started) in the README. In short: open
`Sudoku.xcodeproj` in Xcode 27+, choose your own team under **Signing & Capabilities**, and run.
**Don't commit your signing or bundle identifier changes.**

The project doesn't have a shared scheme yet; Xcode creates one automatically.

### Debug-only shortcut

In Debug builds the **Game** menu has **Fill All but One Cell (Debug)** (⌥⌘F). It fills the board
correctly except one cell, so you can test winning (the victory card, confetti) without solving a
whole puzzle. Games that use it **don't count for records**. It's compiled out of Release builds.

## Pull request workflow

1. Fork the repository and create a branch from `main` (`fix/…`, `feature/…`).
2. Make your change, with tests for any logic you add or modify.
3. Make sure **the project builds without warnings** and **all tests pass** (⌘U).
4. If you added user-facing text, add its Spanish translation (see below).
5. Open a pull request describing *what* changed and *why*. Screenshots or a short screen recording
   help a lot for visual changes.

### Checklist

- [ ] Builds with no new warnings (check Xcode's Issue navigator, not only the build result).
- [ ] All tests pass, and new logic has tests.
- [ ] New visible text uses English keys and has a Spanish translation.
- [ ] Animations degrade with Reduce Motion (and the in-app "Reduce animations" setting).
- [ ] Colours come from the theme (`themeColor`), not `Color.accentColor`.
- [ ] No signing, team or bundle identifier changes.

## Code style

- Swift with 4-space indentation, `PascalCase` types and `camelCase` members.
- SwiftUI state is `@State private var`; the game and settings models are `@Observable`.
- **Prefer Swift concurrency** (`async`/`await`, `.task`) over Combine; the project doesn't use
  Combine.
- Keep game logic out of views. Views read the model and call its methods; rules live in `Model/`
  and `Game/`, where they can be tested.
- Comment the *why*, especially for anything non-obvious. Existing comments are in Spanish; new
  comments in English or Spanish are both fine.

## Conventions

These are the rules that most often trip people up in this codebase.

### Actor isolation: everything is `@MainActor` by default

The target builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so **any type without an
annotation is isolated to the main actor.**

- Pure model types (`SudokuGrid`, `SudokuGenerator`, `CelebrationFrame`, `ConfettiPiece`…) are
  marked `nonisolated`. Do the same for new value types that hold logic.
- Heavy work (like generating a puzzle) runs in `Task.detached` so the window doesn't freeze.
- **A method added in an extension doesn't inherit `nonisolated` from the type.** It takes the
  project default (`MainActor`). Mark it `nonisolated` explicitly if it's called from a
  non-isolated context.
- **The `content` closures of `keyframeAnimator` are `@Sendable` and don't run on the main actor.**
  Inside them you may read `let` properties, but not call view methods or read `@Environment`
  properties. Copy what you need into a local constant first (see `CelebrationEffects.swift`).
- Some of these warnings only show up in Xcode's live diagnostics, not in every command-line build.
  Check the Issue navigator before opening a pull request.

### Localisation

Text lives in `Sudoku/Localizable.xcstrings` (English is the base language, plus Spanish).

- **Keys are written in English**: `Text("New Game")`, never `Text("Nueva partida")`.
- **`Text(someString)` does not localise.** Only string literals (`LocalizedStringKey`) do. If a
  helper returns text, return `Text` or `LocalizedStringKey`, not `String`.
- Display names use `LocalizedStringKey`, not `LocalizedStringResource`: the former follows the
  language chosen in Settings (injected with `.environment(\.locale, …)`), the latter always uses
  the system language.
- **Plurals use explicit variations** (`plural.one` / `plural.other`) in the String Catalog.
  Automatic grammar agreement (`^[…](inflect: true)`) was tried and doesn't resolve here.
- Edit translations with Xcode's String Catalog editor. Debug-only text uses `Text(verbatim:)` so it
  doesn't enter the catalog.

### Colours and themes

- **Never use `Color.accentColor` directly** in views. Use `@Environment(\.themeColor)`, which
  follows the theme chosen in Settings. System controls pick up the theme through `.tint(_:)`.
- Fixed theme colours live in `Assets.xcassets/Theme`, with light and dark variants. Standard
  system colours like `.orange` or `.yellow` fall below a 3:1 contrast ratio on white.
  `AppThemeTests` checks every theme; keep it passing if you change or add one.
- **On macOS, `Color.accentColor` renders grey inside a disabled control.** If a decorative part of a
  control must stay coloured while the control is disabled, draw it with
  `.environment(\.isEnabled, true)` (see `NumberPadButtonStyle`).
- The board is content, so **it doesn't use Liquid Glass**, following Apple's guidance to keep
  Liquid Glass for the functional layer (toolbars, navigation). The toolbar gets it automatically.

### Animations

- **The model publishes *what* happened; the view decides *how* and *for how long*.** For example,
  `SudokuGame.celebration` and `SudokuGame.lastMistake` are small events with an incrementing `id`.
  The id matters: without it, two identical events in a row wouldn't retrigger the animation.
  Never put timers or `Task.sleep` for visual effects inside the model.
- **Every animation must degrade.** Check both `accessibilityReduceMotion` and
  `settings.reduceEffects`; with either one on, nothing moves or scales and only colour changes
  remain.
- Celebration styles are a **pure function**, `CelebrationFrame(style:progress:allowsMotion:)`, of
  a 0→1 progress value. Adding a style means a new `case` in `CelebrationStyle`, a branch there
  and tests in `CelebrationStyleTests`.
- **Keyframes carry velocity from one keyframe to the next**, and the resulting behaviour isn't
  always intuitive: a very short `LinearKeyframe` before a `SpringKeyframe` once pushed a scale
  below zero and mirrored the number. Set `startVelocity` explicitly, and measure your curve with
  `KeyframeTimeline(…).value(time:)` before shipping it.
- Put animation effects **on plain views, not inside a `Button`'s label or `ButtonStyle`**, where
  they didn't play reliably (see `NumberPadKey`).

### Persistence

- **Settings** are stored in `UserDefaults` through `GameSettings`. It takes the `UserDefaults`
  instance in its initialiser so tests can use an isolated suite. Read values with
  `object(forKey:)` so "never saved" can be told apart from `false` or `0`.
- **Records** use SwiftData (`GameRecord` + `RecordStore`). There is a single `ModelContainer`,
  created in `SudokuApp` and shared by every scene.
- **In SwiftData, `fetchOffset` is ignored unless you also set `fetchLimit`.** This once deleted
  the whole records table. `RecordStore` drops rows in Swift instead.
- When a SwiftData query "returns nothing", temporarily replace `try?` with `do`/`catch` and print
  the error; `try?` hides it.

### Tests

- Tests use **Swift Testing** (`@Test`, `#expect`, `#require`), one file per area in `SudokuTests/`.
- Make logic testable by **injecting what varies**: the current time (`now:` parameters), the
  random number generator (`SeededRandomNumberGenerator` in the tests), `UserDefaults`, and the
  SwiftData context (use `ModelConfiguration(isStoredInMemoryOnly: true)`).
- Test names (`@Test("…")`) describe the expected behaviour in a full sentence. Existing ones are in
  Spanish; English is fine for new ones.

### Platforms

The target also lists iOS and visionOS, but **only macOS is currently supported and tested**. Keep
Mac-only APIs (`Settings`, `Window`, `SettingsLink`, `onDeleteCommand`…) inside `#if os(macOS)` so
the other platforms keep compiling. Contributions that bring the game to iPad or Vision Pro are
welcome; please open an issue to discuss the design first.

## License

By contributing, you agree that your contributions will be licensed under the project's
[MIT License](LICENSE).
