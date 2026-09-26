//
//  GameClockTests.swift
//  SudokuTests
//

import Foundation
import Testing
@testable import Sudoku

@Suite("Cronómetro")
struct GameClockTests {

    /// Un instante fijo del que partir. Todas las pruebas trabajan con desplazamientos sobre él,
    /// así que no dependen de la hora real ni tienen que esperar.
    private let origin = Date(timeIntervalSince1970: 1_000_000)

    private func date(_ offset: TimeInterval) -> Date {
        origin.addingTimeInterval(offset)
    }

    @Test("Un reloj nuevo está en cero y detenido")
    func startsAtZero() {
        let clock = GameClock()

        #expect(!clock.isRunning)
        #expect(clock.elapsed(at: date(100)) == 0)
    }

    @Test("Corriendo, el tiempo avanza con la fecha consultada")
    func advancesWhileRunning() {
        var clock = GameClock()
        clock.start(at: origin)

        #expect(clock.isRunning)
        #expect(clock.elapsed(at: date(0)) == 0)
        #expect(clock.elapsed(at: date(30)) == 30)
        #expect(clock.elapsed(at: date(90)) == 90)
    }

    @Test("Al detenerse, el tiempo se congela")
    func freezesWhenStopped() {
        var clock = GameClock()
        clock.start(at: origin)
        clock.stop(at: date(45))

        #expect(!clock.isRunning)
        #expect(clock.elapsed(at: date(45)) == 45)
        // Aunque pase más tiempo, el valor no cambia.
        #expect(clock.elapsed(at: date(500)) == 45)
    }

    @Test("Los tramos se acumulan")
    func accumulatesSegments() {
        var clock = GameClock()

        clock.start(at: origin)
        clock.stop(at: date(20))

        clock.start(at: date(100))
        clock.stop(at: date(130))

        #expect(clock.elapsed(at: date(999)) == 50)
    }

    @Test("El tiempo parado no cuenta")
    func pausedTimeIsNotCounted() {
        var clock = GameClock()

        clock.start(at: origin)
        clock.stop(at: date(10))
        // Diez minutos en pausa.
        clock.start(at: date(610))

        #expect(clock.elapsed(at: date(615)) == 15)
    }

    @Test("Arrancar dos veces no reinicia el tramo")
    func startIsIdempotent() {
        var clock = GameClock()

        clock.start(at: origin)
        clock.start(at: date(50))

        #expect(clock.elapsed(at: date(60)) == 60, "El segundo start debe ignorarse")
    }

    @Test("Detener un reloj ya detenido no cambia nada")
    func stopIsIdempotent() {
        var clock = GameClock()
        clock.start(at: origin)
        clock.stop(at: date(30))
        clock.stop(at: date(400))

        #expect(clock.elapsed(at: date(400)) == 30)
    }

    @Test("Reiniciar deja el reloj en cero y detenido")
    func resetClearsEverything() {
        var clock = GameClock()
        clock.start(at: origin)
        clock.stop(at: date(30))
        clock.reset()

        #expect(!clock.isRunning)
        #expect(clock.elapsed(at: date(100)) == 0)
    }

    @Test("`restart` pone a cero y arranca de nuevo")
    func restartStartsFromZero() {
        var clock = GameClock()
        clock.start(at: origin)
        clock.stop(at: date(30))

        clock.restart(at: date(200))

        #expect(clock.isRunning)
        #expect(clock.elapsed(at: date(210)) == 10, "Los 30 segundos anteriores se descartan")
    }

    @Test("Un salto del reloj del sistema hacia atrás no da tiempos negativos")
    func toleratesBackwardsClock() {
        var clock = GameClock()
        clock.start(at: origin)

        // Consultar con una fecha anterior al arranque (cambio de hora, por ejemplo).
        #expect(clock.elapsed(at: date(-500)) == 0)

        clock.stop(at: date(-500))
        #expect(clock.elapsed(at: origin) == 0)
    }

    // MARK: - Formateo

    @Test("El formato corto es mm:ss", arguments: [
        (0.0, "0:00"),
        (9.0, "0:09"),
        (65.0, "1:05"),
        (600.0, "10:00"),
        (3599.0, "59:59"),
    ])
    func formatsMinutesAndSeconds(elapsed: TimeInterval, expected: String) {
        #expect(TimerLabel.format(elapsed) == expected)
    }

    @Test("Pasada la hora se añade el componente de horas")
    func formatsHours() {
        #expect(TimerLabel.format(3600) == "1:00:00")
        #expect(TimerLabel.format(3725) == "1:02:05")
    }
}

@Suite("Cronómetro de la partida")
@MainActor
struct SudokuGameClockTests {

    private let origin = Date(timeIntervalSince1970: 2_000_000)

    private func makeGame(emptyIndices: [Int]) -> SudokuGame {
        var generator = SeededRandomNumberGenerator(seed: 77)
        let solution = SudokuGenerator.makeFilledGrid(using: &generator)

        var board = solution
        for index in emptyIndices {
            board[index] = 0
        }

        return SudokuGame(puzzle: Puzzle(board: board, solution: solution, difficulty: .easy))
    }

    @Test("Reiniciar la partida arranca el reloj desde cero")
    func restartRestartsClock() {
        let game = makeGame(emptyIndices: [0])

        game.restart(now: origin)

        #expect(game.clock.isRunning)
        #expect(game.clock.elapsed(at: origin.addingTimeInterval(12)) == 12)
    }

    @Test("Resolver el tablero detiene el reloj")
    func solvingStopsClock() {
        let game = makeGame(emptyIndices: [0])
        game.restart(now: origin)

        game.select(0)
        game.enter(game.puzzle.solution[0], now: origin.addingTimeInterval(40))

        #expect(game.isSolved)
        #expect(!game.clock.isRunning)
        #expect(game.clock.elapsed(at: origin.addingTimeInterval(500)) == 40)
    }

    @Test("Una jugada que no resuelve no detiene el reloj")
    func wrongMoveKeepsClockRunning() {
        let game = makeGame(emptyIndices: [0, 1])
        game.restart(now: origin)

        game.select(0)
        game.enter(game.puzzle.solution[1], now: origin.addingTimeInterval(10))

        #expect(!game.isSolved)
        #expect(game.clock.isRunning)
    }
}
