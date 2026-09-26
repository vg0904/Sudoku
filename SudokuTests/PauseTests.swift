//
//  PauseTests.swift
//  SudokuTests
//

import Foundation
import Testing
@testable import Sudoku

@Suite("Pausa")
@MainActor
struct PauseTests {

    private let origin = Date(timeIntervalSince1970: 6_000_000)

    /// Una partida en marcha desde `origin`, con los huecos indicados.
    private func makeRunningGame(emptyIndices: [Int] = [0, 1]) -> SudokuGame {
        var generator = SeededRandomNumberGenerator(seed: 21)
        let solution = SudokuGenerator.makeFilledGrid(using: &generator)

        var board = solution
        for index in emptyIndices {
            board[index] = 0
        }

        let game = SudokuGame(puzzle: Puzzle(board: board, solution: solution, difficulty: .easy))
        game.restart(now: origin)
        return game
    }

    private func time(_ seconds: TimeInterval) -> Date {
        origin.addingTimeInterval(seconds)
    }

    // MARK: - Reloj

    @Test("Pausar detiene el reloj")
    func pauseStopsClock() {
        let game = makeRunningGame()

        game.pause(now: time(30))

        #expect(game.isPaused)
        #expect(!game.clock.isRunning)
        #expect(game.clock.elapsed(at: time(500)) == 30, "El tiempo en pausa no cuenta")
    }

    @Test("Reanudar sigue desde donde se quedó")
    func resumeContinuesClock() {
        let game = makeRunningGame()

        game.pause(now: time(30))
        game.resume(now: time(300))

        #expect(!game.isPaused)
        #expect(game.clock.isRunning)
        // 30 s antes de la pausa + 10 s después de reanudar; los 270 s en pausa no cuentan.
        #expect(game.clock.elapsed(at: time(310)) == 40)
    }

    @Test("Alternar pausa y reanuda")
    func togglePauses() {
        let game = makeRunningGame()

        game.togglePause(now: time(5))
        #expect(game.isPaused)

        game.togglePause(now: time(6))
        #expect(!game.isPaused)
    }

    @Test("Pausar dos veces no pierde tiempo")
    func pauseIsIdempotent() {
        let game = makeRunningGame()

        game.pause(now: time(30))
        game.pause(now: time(90))

        #expect(game.clock.elapsed(at: time(500)) == 30)
    }

    // MARK: - Jugadas bloqueadas

    @Test("En pausa no se pueden escribir números")
    func pausedGameIgnoresInput() {
        let game = makeRunningGame()
        game.select(0)
        game.pause(now: time(10))

        game.enter(game.puzzle.solution[0])

        #expect(game.value(at: 0) == 0)
    }

    @Test("En pausa no se puede mover la selección ni borrar")
    func pausedGameIgnoresNavigationAndClearing() {
        let game = makeRunningGame()
        game.select(0)
        game.enter(game.puzzle.solution[1])
        #expect(game.state(at: 0) == .wrong)

        game.pause(now: time(10))
        game.moveSelection(rowDelta: 0, columnDelta: 1)
        game.select(1)
        game.clearSelection()

        #expect(game.selectedIndex == 0)
        #expect(game.state(at: 0) == .wrong, "El error sigue ahí")
    }

    @Test("Al reanudar se vuelve a poder jugar")
    func resumedGameAcceptsInput() {
        let game = makeRunningGame()
        game.select(0)
        game.pause(now: time(10))
        game.resume(now: time(20))

        game.enter(game.puzzle.solution[0])

        #expect(game.state(at: 0) == .filled)
    }

    // MARK: - Cuándo se puede pausar

    @Test("Una partida terminada no se puede pausar")
    func solvedGameCannotPause() {
        let game = makeRunningGame(emptyIndices: [0])
        game.select(0)
        game.enter(game.puzzle.solution[0], now: time(40))
        #expect(game.isSolved)

        game.pause(now: time(50))

        #expect(!game.canPause)
        #expect(!game.isPaused)
    }

    @Test("Sin tablero todavía no se puede pausar")
    func emptyGameCannotPause() {
        let game = SudokuGame()

        game.pause()

        #expect(!game.canPause)
        #expect(!game.isPaused)
    }

    @Test("Reiniciar el tablero quita la pausa")
    func restartClearsPause() {
        let game = makeRunningGame()
        game.pause(now: time(10))

        game.restart(now: time(20))

        #expect(!game.isPaused)
        #expect(game.clock.isRunning)
    }
}
