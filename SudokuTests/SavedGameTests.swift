//
//  SavedGameTests.swift
//  SudokuTests
//

import Foundation
import Testing
@testable import Sudoku

@Suite("Partida guardada")
@MainActor
struct SavedGameTests {

    private let origin = Date(timeIntervalSince1970: 7_000_000)

    /// Una partida en marcha desde `origin`, con los huecos indicados.
    private func makeRunningGame(emptyIndices: [Int] = [0, 1, 2]) -> SudokuGame {
        var generator = SeededRandomNumberGenerator(seed: 41)
        let solution = SudokuGenerator.makeFilledGrid(using: &generator)

        var board = solution
        for index in emptyIndices {
            board[index] = 0
        }

        let game = SudokuGame(
            puzzle: Puzzle(board: board, solution: solution, difficulty: .hard),
            maxLives: 3
        )
        game.restart(now: origin)
        return game
    }

    /// Un `UserDefaults` propio de cada prueba, igual que en las pruebas de ajustes.
    private func makeIsolatedStore() -> (SavedGameStore, cleanup: () -> Void) {
        let suiteName = "SudokuTests.SavedGame.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return (SavedGameStore(defaults: defaults), { UserDefaults().removePersistentDomain(forName: suiteName) })
    }

    // MARK: - Foto

    @Test("La foto recoge el estado de la partida")
    func snapshotCapturesState() throws {
        let game = makeRunningGame()
        game.select(0)
        game.enter(game.puzzle.solution[0])
        game.select(1)
        game.enter(game.puzzle.solution[2])

        let saved = try #require(game.snapshot(now: origin.addingTimeInterval(95)))

        #expect(saved.difficulty == .hard)
        #expect(saved.entries[0] == game.puzzle.solution[0])
        #expect(saved.wrongIndices == [1])
        #expect(saved.mistakeCount == 1)
        #expect(saved.elapsed == 95)
        #expect(saved.maxLives == 3)
        #expect(saved.selectedIndex == 1)
        #expect(saved.isValid)
    }

    @Test("Una partida terminada o sin tablero no deja foto")
    func finishedGamesHaveNoSnapshot() {
        let solved = makeRunningGame(emptyIndices: [0])
        solved.select(0)
        solved.enter(solved.puzzle.solution[0])

        #expect(solved.isSolved)
        #expect(solved.snapshot() == nil)
        #expect(SudokuGame().snapshot() == nil)
    }

    // MARK: - Retomar

    @Test("Retomar deja la partida exactamente como estaba")
    func restoreRoundTrip() throws {
        let original = makeRunningGame()
        original.select(0)
        original.enter(original.puzzle.solution[1])
        let saved = try #require(original.snapshot(now: origin.addingTimeInterval(60)))

        let restored = SudokuGame()
        #expect(restored.restore(saved))

        #expect(restored.puzzle == original.puzzle)
        #expect(restored.difficulty == .hard)
        #expect(restored.entries == original.entries)
        #expect(restored.wrongIndices == original.wrongIndices)
        #expect(restored.mistakeCount == 1)
        #expect(restored.livesRemaining == 2)
        #expect(restored.selectedIndex == 0)
    }

    @Test("La partida retomada empieza en pausa, con el tiempo que llevaba")
    func restoredGameStartsPaused() throws {
        let original = makeRunningGame()
        let saved = try #require(original.snapshot(now: origin.addingTimeInterval(120)))

        let restored = SudokuGame()
        restored.restore(saved)

        #expect(restored.isPaused)
        #expect(!restored.clock.isRunning)
        #expect(restored.clock.elapsed(at: .distantFuture) == 120, "En pausa el tiempo no avanza")

        // Al reanudar, el reloj sigue desde ahí.
        let later = origin.addingTimeInterval(1_000)
        restored.resume(now: later)
        #expect(restored.clock.elapsed(at: later.addingTimeInterval(5)) == 125)
    }

    @Test("Una foto dañada no se retoma y no toca la partida")
    func invalidSnapshotIsRejected() throws {
        let original = makeRunningGame()
        var saved = try #require(original.snapshot())
        saved.entries.removeLast()

        let game = SudokuGame()
        #expect(!saved.isValid)
        #expect(!game.restore(saved))
        #expect(!game.isInProgress, "Sigue sin partida")
    }

    @Test("Una pista que no coincide con la solución invalida la foto")
    func mismatchedGivenIsInvalid() throws {
        var saved = try #require(makeRunningGame().snapshot())
        // La celda 5 es una pista; se le pone un valor distinto del de la solución.
        saved.board[5] = saved.solution[5] % 9 + 1

        #expect(!saved.isValid)
    }

    // MARK: - Señal de guardado

    @Test("Cada jugada, borrado, pausa o reinicio pide guardar")
    func changesBumpSaveRevision() {
        let game = makeRunningGame()
        var revision = game.saveRevision

        func expectBump(_ description: String) {
            #expect(game.saveRevision > revision, "\(description) debería pedir guardar")
            revision = game.saveRevision
        }

        game.select(0)
        game.enter(game.puzzle.solution[1])
        expectBump("Una jugada")

        game.clearSelection()
        expectBump("Un borrado")

        game.pause()
        expectBump("Una pausa")

        game.restart()
        expectBump("Un reinicio")
    }

    // MARK: - Almacén

    @Test("Guardar y cargar devuelve la misma foto")
    func storeRoundTrip() throws {
        let (store, cleanup) = makeIsolatedStore()
        defer { cleanup() }
        let saved = try #require(makeRunningGame().snapshot())

        store.save(saved)

        #expect(store.load() == saved)
    }

    @Test("Guardar nada borra la foto anterior")
    func savingNilClears() throws {
        let (store, cleanup) = makeIsolatedStore()
        defer { cleanup() }
        store.save(try #require(makeRunningGame().snapshot()))

        store.save(nil)

        #expect(store.load() == nil)
    }

    @Test("Datos que no son una partida se ignoran")
    func corruptDataLoadsNothing() {
        let suiteName = "SudokuTests.SavedGame.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { UserDefaults().removePersistentDomain(forName: suiteName) }
        defaults.set(Data("no es json".utf8), forKey: SavedGameStore.key)

        #expect(SavedGameStore(defaults: defaults).load() == nil)
    }

    @Test("Una foto de otra versión del formato se ignora")
    func otherFormatVersionLoadsNothing() throws {
        let (store, cleanup) = makeIsolatedStore()
        defer { cleanup() }
        var saved = try #require(makeRunningGame().snapshot())
        saved.formatVersion = SavedGame.currentFormatVersion + 1

        store.save(saved)

        #expect(store.load() == nil)
    }
}
