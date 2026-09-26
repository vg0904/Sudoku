//
//  RecordStoreTests.swift
//  SudokuTests
//

import Foundation
import SwiftData
import Testing
@testable import Sudoku

@Suite("Récords")
@MainActor
struct RecordStoreTests {

    /// La base de datos de la prueba. Swift Testing crea una instancia de la suite por prueba, así
    /// que cada una empieza con su propia tabla vacía.
    ///
    /// `isStoredInMemoryOnly` hace que SwiftData no escriba nada en disco: las pruebas no tocan
    /// los récords reales de quien juega ni se afectan entre sí. Es el equivalente al
    /// `UserDefaults` aislado de las pruebas de ajustes.
    private let container: ModelContainer

    init() throws {
        container = try ModelContainer(
            for: GameRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeStore() throws -> RecordStore {
        RecordStore(context: container.mainContext)
    }

    private let origin = Date(timeIntervalSince1970: 5_000_000)

    /// Guarda un récord con valores de relleno para lo que la prueba no mira.
    @discardableResult
    private func save(
        _ store: RecordStore,
        time: TimeInterval,
        difficulty: Difficulty = .medium,
        name: String = "Ana",
        lives: Int? = 3,
        secondsAfterOrigin: TimeInterval = 0
    ) throws -> GameRecord {
        try store.save(
            playerName: name,
            time: time,
            difficulty: difficulty,
            lives: lives,
            mistakes: 1,
            date: origin.addingTimeInterval(secondsAfterOrigin)
        )
    }

    // MARK: - Orden y puesto

    @Test("Una tabla vacía no tiene mejor tiempo y cualquier tiempo entra primero")
    func emptyTable() throws {
        let store = try makeStore()

        #expect(store.records(for: .medium).isEmpty)
        #expect(store.bestTime(for: .medium) == nil)
        #expect(store.rank(for: 999, difficulty: .medium) == 1)
    }

    @Test("La tabla va del mejor tiempo al peor")
    func sortedByTime() throws {
        let store = try makeStore()
        try save(store, time: 300)
        try save(store, time: 120)
        try save(store, time: 200)

        #expect(store.records(for: .medium).map(\.time) == [120, 200, 300])
        #expect(store.bestTime(for: .medium) == 120)
    }

    @Test("Cada dificultad tiene su propia tabla")
    func separateTablesPerDifficulty() throws {
        let store = try makeStore()
        try save(store, time: 100, difficulty: .easy)
        try save(store, time: 500, difficulty: .hard)

        #expect(store.records(for: .easy).map(\.time) == [100])
        #expect(store.records(for: .hard).map(\.time) == [500])
        #expect(store.records(for: .medium).isEmpty)
    }

    @Test("El puesto se calcula contra los tiempos guardados")
    func rankAmongExisting() throws {
        let store = try makeStore()
        try save(store, time: 100)
        try save(store, time: 200)

        #expect(store.rank(for: 50, difficulty: .medium) == 1)
        #expect(store.rank(for: 150, difficulty: .medium) == 2)
        #expect(store.rank(for: 250, difficulty: .medium) == 3)
    }

    @Test("Con un empate conserva el puesto quien llegó antes")
    func tiesFavourTheOlderRecord() throws {
        let store = try makeStore()
        try save(store, time: 100, name: "Ana", secondsAfterOrigin: 0)

        #expect(store.rank(for: 100, difficulty: .medium) == 2)

        try save(store, time: 100, name: "Luis", secondsAfterOrigin: 60)
        #expect(store.records(for: .medium).map(\.playerName) == ["Ana", "Luis"])
    }

    // MARK: - Límite de la tabla

    @Test("Con la tabla llena, un tiempo peor que el último no entra")
    func fullTableRejectsSlowerTimes() throws {
        let store = try makeStore()
        for position in 1...RecordStore.tableSize {
            try save(store, time: Double(position) * 10)
        }

        #expect(store.rank(for: 999, difficulty: .medium) == nil)
        #expect(store.rank(for: 5, difficulty: .medium) == 1)
    }

    @Test("Guardar un récord mejor saca de la tabla al último")
    func savingTrimsTheTable() throws {
        let store = try makeStore()
        for position in 1...RecordStore.tableSize {
            try save(store, time: Double(position) * 10)
        }

        try save(store, time: 5)

        let times = store.records(for: .medium).map(\.time)
        #expect(times.count == RecordStore.tableSize)
        #expect(times.first == 5)
        #expect(!times.contains(Double(RecordStore.tableSize) * 10), "El peor ha salido")

        // Y de verdad se borró, no solo se dejó fuera de la consulta.
        let everything = try store.context.fetch(FetchDescriptor<GameRecord>())
        #expect(everything.count == RecordStore.tableSize)
    }

    @Test("Recortar una tabla no toca las demás")
    func trimmingIsPerDifficulty() throws {
        let store = try makeStore()
        try save(store, time: 1_000, difficulty: .easy)
        for position in 1...(RecordStore.tableSize + 1) {
            try save(store, time: Double(position), difficulty: .hard)
        }

        #expect(store.records(for: .easy).count == 1)
        #expect(store.records(for: .hard).count == RecordStore.tableSize)
    }

    // MARK: - Datos del récord

    @Test("Se guardan las vidas, y las ilimitadas como cero")
    func storesLives() throws {
        let store = try makeStore()
        let limited = try save(store, time: 100, lives: 2)
        let unlimited = try save(store, time: 200, lives: nil)

        #expect(limited.lives == 2)
        #expect(unlimited.lives == 0)
    }

    @Test("Un nombre vacío o solo con espacios se guarda como ???")
    func blankNameBecomesAnonymous() throws {
        let store = try makeStore()
        let record = try save(store, time: 100, name: "   ")

        #expect(record.playerName == RecordStore.anonymousName)
    }

    @Test("Los espacios de los extremos del nombre se quitan")
    func namesAreTrimmed() throws {
        let store = try makeStore()
        let record = try save(store, time: 100, name: "  Ana  ")

        #expect(record.playerName == "Ana")
    }

    // MARK: - Perfiles

    @Test("Recuerda el último nombre usado")
    func remembersLastName() throws {
        let store = try makeStore()
        #expect(store.lastPlayerName == nil)

        try save(store, time: 100, name: "Ana", secondsAfterOrigin: 0)
        try save(store, time: 200, name: "Luis", secondsAfterOrigin: 60)

        #expect(store.lastPlayerName == "Luis")
    }

    @Test("Los nombres usados salen sin repetir, del más reciente al más antiguo")
    func listsPlayerNames() throws {
        let store = try makeStore()
        try save(store, time: 100, name: "Ana", secondsAfterOrigin: 0)
        try save(store, time: 200, name: "Luis", secondsAfterOrigin: 60)
        try save(store, time: 300, name: "Ana", secondsAfterOrigin: 120)

        #expect(store.playerNames == ["Ana", "Luis"])
    }

    @Test("Se puede borrar un récord")
    func deletesRecord() throws {
        let store = try makeStore()
        let record = try save(store, time: 100)

        try store.delete(record)

        #expect(store.records(for: .medium).isEmpty)
    }
}
