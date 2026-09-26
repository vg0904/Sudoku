//
//  SudokuLivesTests.swift
//  SudokuTests
//

import Foundation
import Testing
@testable import Sudoku

@Suite("Vidas")
@MainActor
struct SudokuLivesTests {

    private let origin = Date(timeIntervalSince1970: 3_000_000)

    /// Una partida con varios huecos en la fila 0 y un límite de vidas.
    ///
    /// Hacen falta varios huecos para poder equivocarse: el valor equivocado se toma de otro hueco,
    /// porque los números ya completos se rechazan.
    private func makeGame(maxLives: Int?, gaps: [Int] = [0, 1, 2, 3]) -> SudokuGame {
        var generator = SeededRandomNumberGenerator(seed: 55)
        let solution = SudokuGenerator.makeFilledGrid(using: &generator)

        var board = solution
        for index in gaps {
            board[index] = 0
        }

        return SudokuGame(
            puzzle: Puzzle(board: board, solution: solution, difficulty: .medium),
            maxLives: maxLives
        )
    }

    /// Comete un error en `index` usando el valor que corresponde a `borrowFrom`.
    private func makeMistake(in game: SudokuGame, at index: Int, borrowFrom: Int) {
        game.select(index)
        game.enter(game.puzzle.solution[borrowFrom])
    }

    // MARK: - Conteo

    @Test("Una partida nueva empieza con todas las vidas")
    func startsWithAllLives() {
        let game = makeGame(maxLives: 3)

        #expect(game.livesRemaining == 3)
        #expect(!game.isDefeated)
    }

    @Test("Cada error quita una vida")
    func mistakeCostsALife() {
        let game = makeGame(maxLives: 3)

        makeMistake(in: game, at: 0, borrowFrom: 1)
        #expect(game.livesRemaining == 2)

        makeMistake(in: game, at: 0, borrowFrom: 2)
        #expect(game.livesRemaining == 1)
        #expect(!game.isDefeated)
    }

    @Test("Al gastar la última vida hay derrota")
    func runningOutOfLivesDefeats() {
        let game = makeGame(maxLives: 3)

        makeMistake(in: game, at: 0, borrowFrom: 1)
        makeMistake(in: game, at: 0, borrowFrom: 2)
        makeMistake(in: game, at: 0, borrowFrom: 3)

        #expect(game.livesRemaining == 0)
        #expect(game.isDefeated)
    }

    @Test("Con una sola vida el primer error basta")
    func singleLifeIsImmediate() {
        let game = makeGame(maxLives: 1)

        makeMistake(in: game, at: 0, borrowFrom: 1)

        #expect(game.isDefeated)
    }

    @Test("Corregir la celda no devuelve la vida")
    func correctingDoesNotRestoreLife() {
        let game = makeGame(maxLives: 3)

        makeMistake(in: game, at: 0, borrowFrom: 1)
        game.enter(game.puzzle.solution[0])

        #expect(game.state(at: 0) == .filled)
        #expect(game.livesRemaining == 2, "El error ya se pagó")
    }

    // MARK: - Vidas desactivadas

    @Test("Sin límite de vidas nunca hay derrota")
    func unlimitedLivesNeverDefeat() {
        let game = makeGame(maxLives: nil)

        for borrowFrom in [1, 2, 3] {
            makeMistake(in: game, at: 0, borrowFrom: borrowFrom)
        }

        #expect(game.livesRemaining == nil)
        #expect(!game.isDefeated)
        #expect(game.mistakeCount == 3, "Los errores se siguen contando")
    }

    @Test("Una partida sin vidas configuradas se comporta como antes")
    func defaultGameHasNoLives() {
        let game = SudokuGame()

        #expect(game.maxLives == nil)
        #expect(game.livesRemaining == nil)
        #expect(!game.isDefeated)
    }

    // MARK: - Efectos de la derrota

    @Test("En derrota no se aceptan más jugadas")
    func defeatBlocksInput() {
        let game = makeGame(maxLives: 1)
        makeMistake(in: game, at: 0, borrowFrom: 1)
        #expect(game.isDefeated)

        let mistakesAtDefeat = game.mistakeCount

        game.select(1)
        game.enter(game.puzzle.solution[1])

        #expect(game.value(at: 1) == 0, "El tablero queda congelado")
        #expect(game.mistakeCount == mistakesAtDefeat)
    }

    @Test("La derrota detiene el reloj")
    func defeatStopsClock() {
        let game = makeGame(maxLives: 1)
        game.restart(now: origin)

        game.select(0)
        game.enter(game.puzzle.solution[1], now: origin.addingTimeInterval(25))

        #expect(game.isDefeated)
        #expect(!game.clock.isRunning)
        #expect(game.clock.elapsed(at: origin.addingTimeInterval(900)) == 25)
    }

    @Test("Reintentar el mismo tablero devuelve las vidas y reinicia el reloj")
    func retryRestoresLivesAndClock() {
        let game = makeGame(maxLives: 3)
        let boardBefore = game.puzzle.board

        makeMistake(in: game, at: 0, borrowFrom: 1)
        makeMistake(in: game, at: 0, borrowFrom: 2)
        makeMistake(in: game, at: 0, borrowFrom: 3)
        #expect(game.isDefeated)

        game.restart(now: origin)

        #expect(game.livesRemaining == 3)
        #expect(!game.isDefeated)
        #expect(game.puzzle.board == boardBefore, "Es el mismo tablero")
        #expect(game.clock.isRunning)
        #expect(game.clock.elapsed(at: origin) == 0)
    }

    @Test("Tras reintentar se vuelve a poder jugar")
    func retryAllowsInputAgain() {
        let game = makeGame(maxLives: 1)
        makeMistake(in: game, at: 0, borrowFrom: 1)

        game.restart()
        game.select(0)
        game.enter(game.puzzle.solution[0])

        #expect(game.value(at: 0) == game.puzzle.solution[0])
    }

    @Test("Ganar con vidas de sobra no cuenta como derrota")
    func winningIsNotDefeat() {
        let game = makeGame(maxLives: 3, gaps: [0])

        game.select(0)
        game.enter(game.puzzle.solution[0])

        #expect(game.isSolved)
        #expect(!game.isDefeated)
        #expect(game.livesRemaining == 3)
    }
}
