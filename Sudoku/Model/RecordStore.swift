//
//  RecordStore.swift
//  Sudoku
//

import Foundation
import SwiftData

/// Las reglas de la tabla de récords, encima de un `ModelContext` de SwiftData.
///
/// Hay una tabla por dificultad, con los `tableSize` mejores tiempos. Las vistas leen la tabla
/// directamente con `@Query`; esto es para lo que necesita reglas: saber si un tiempo entra,
/// guardarlo y recortar lo que sobre.
///
/// Recibe el contexto en lugar de crearlo para que las pruebas usen una base de datos en memoria.
struct RecordStore {
    let context: ModelContext

    /// Cuántos récords guarda cada dificultad, como la tabla de una máquina arcade.
    static let tableSize = 10

    /// El nombre que se usa si se guarda un récord sin escribir ninguno: tres interrogaciones,
    /// como en las recreativas.
    static let anonymousName = "???"

    // MARK: - Consultas

    /// La tabla de una dificultad, del mejor tiempo al peor.
    ///
    /// Con tiempos empatados va primero el más antiguo: quien lo consiguió antes conserva el
    /// puesto, como en los arcades.
    func records(for difficulty: Difficulty) -> [GameRecord] {
        let raw = difficulty.rawValue
        var descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.difficultyRaw == raw },
            sortBy: [SortDescriptor(\.time), SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = Self.tableSize

        return (try? context.fetch(descriptor)) ?? []
    }

    /// El mejor tiempo guardado en una dificultad, o `nil` si todavía no hay ninguno.
    func bestTime(for difficulty: Difficulty) -> TimeInterval? {
        records(for: difficulty).first?.time
    }

    /// En qué puesto (desde 1) entraría `time`, o `nil` si no llega a la tabla.
    ///
    /// Un empate cuenta como peor que el récord que ya existe, por la misma regla que el orden.
    func rank(for time: TimeInterval, difficulty: Difficulty) -> Int? {
        let table = records(for: difficulty)
        let rank = table.count { $0.time <= time } + 1

        return rank <= Self.tableSize ? rank : nil
    }

    /// El nombre del récord más reciente, para dejarlo escrito la próxima vez.
    var lastPlayerName: String? {
        var descriptor = FetchDescriptor<GameRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1

        return (try? context.fetch(descriptor))?.first?.playerName
    }

    /// Los nombres que se han usado, del más reciente al más antiguo y sin repetir.
    ///
    /// Son los "perfiles": no hay que crearlos aparte, existen en cuanto alguien guarda un récord.
    var playerNames: [String] {
        let descriptor = FetchDescriptor<GameRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let names = ((try? context.fetch(descriptor)) ?? []).map(\.playerName)

        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }
    }

    // MARK: - Cambios

    /// Guarda un récord y recorta la tabla de su dificultad a `tableSize`.
    ///
    /// - Parameters:
    ///   - lives: las vidas de la partida, o `nil` si eran ilimitadas.
    @discardableResult
    func save(
        playerName: String,
        time: TimeInterval,
        difficulty: Difficulty,
        lives: Int?,
        mistakes: Int,
        date: Date = .now
    ) throws -> GameRecord {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = GameRecord(
            playerName: trimmed.isEmpty ? Self.anonymousName : trimmed,
            time: time,
            difficulty: difficulty,
            lives: lives ?? 0,
            mistakes: mistakes,
            date: date
        )
        context.insert(record)
        try trim(difficulty)
        try context.save()

        return record
    }

    /// Borra un récord concreto.
    func delete(_ record: GameRecord) throws {
        context.delete(record)
        try context.save()
    }

    /// Quita lo que quede por debajo del puesto `tableSize` en una dificultad.
    ///
    /// Se descartan los primeros en Swift en lugar de pedir `fetchOffset` a la consulta: sin un
    /// `fetchLimit`, SwiftData ignora el desplazamiento y devuelve la tabla entera, que acababa
    /// borrada completa. La tabla nunca pasa de `tableSize + 1` filas, así que no cuesta nada.
    private func trim(_ difficulty: Difficulty) throws {
        let raw = difficulty.rawValue
        let descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.difficultyRaw == raw },
            sortBy: [SortDescriptor(\.time), SortDescriptor(\.date)]
        )

        for leftover in try context.fetch(descriptor).dropFirst(Self.tableSize) {
            context.delete(leftover)
        }
    }
}
