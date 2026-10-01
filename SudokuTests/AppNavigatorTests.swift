//
//  AppNavigatorTests.swift
//  SudokuTests
//

import Foundation
import Testing
@testable import Sudoku

@Suite("Navegación entre el menú y el tablero")
@MainActor
struct AppNavigatorTests {

    /// Un `UserDefaults` propio de cada prueba, para no tocar la dificultad que recuerda la app real.
    private func makeIsolatedDefaults() -> (UserDefaults, cleanup: () -> Void) {
        let suiteName = "SudokuTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        return (defaults, { UserDefaults().removePersistentDomain(forName: suiteName) })
    }

    @Test("La app abre en el menú, con Medio como dificultad por defecto")
    func startsOnMenu() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let navigator = AppNavigator(defaults: defaults)

        #expect(navigator.screen == .menu)
        #expect(!navigator.isShowingGame)
        #expect(navigator.menuDifficulty == .medium)
    }

    @Test("Nueva partida abre el tablero con la dificultad del selector")
    func startNewGameUsesMenuDifficulty() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let navigator = AppNavigator(defaults: defaults)
        navigator.menuDifficulty = .hard
        navigator.startNewGame()

        #expect(navigator.screen == .game(.new(.hard)))
        #expect(navigator.isShowingGame)
    }

    @Test("Volver al menú sale del tablero")
    func showMenuLeavesGame() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let navigator = AppNavigator(defaults: defaults)
        navigator.startNewGame()
        navigator.showMenu()

        #expect(navigator.screen == .menu)
        #expect(!navigator.isShowingGame)
    }

    @Test("La dificultad elegida se recuerda en una instancia nueva")
    func menuDifficultyPersists() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        AppNavigator(defaults: defaults).menuDifficulty = .easy

        #expect(AppNavigator(defaults: defaults).menuDifficulty == .easy)
    }

    @Test("Una dificultad guardada que ya no existe vuelve a Medio")
    func unknownDifficultyFallsBack() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        defaults.set("legendary", forKey: "menu.difficulty")

        #expect(AppNavigator(defaults: defaults).menuDifficulty == .medium)
    }
}
