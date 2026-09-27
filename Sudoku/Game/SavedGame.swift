//
//  SavedGame.swift
//  Sudoku
//

import Foundation

/// Una "foto" de la partida en curso, para retomarla al volver a abrir la app.
///
/// Solo contiene datos simples (`Int`, `Bool`, `TimeInterval`) para que `Codable` la convierta en
/// JSON sin código a mano. No guarda nada visual ni temporal: ni la celebración en marcha ni la
/// animación de un error.
nonisolated struct SavedGame: Codable, Equatable, Sendable {
    /// La versión del formato. Si algún día cambia lo que se guarda, una foto con otra versión se
    /// descarta en lugar de restaurarse a medias.
    static let currentFormatVersion = 1

    var formatVersion = Self.currentFormatVersion

    /// El tablero inicial, con `0` en las celdas vacías.
    var board: [Int]
    var solution: [Int]
    var difficulty: Difficulty
    /// Lo que escribió quien juega, separado de las pistas como en `SudokuGame`.
    var entries: [Int]
    var wrongIndices: [Int]
    var mistakeCount: Int
    /// El tiempo jugado hasta el momento de guardar.
    var elapsed: TimeInterval
    var maxLives: Int?
    var selectedIndex: Int?
    var isEligibleForRecords: Bool

    /// `true` si la foto tiene sentido: el formato actual, 81 celdas por lista y valores del 0 al 9.
    ///
    /// Protege de datos dañados o de otra versión de la app. Restaurar algo incoherente dejaría una
    /// partida imposible de ganar.
    var isValid: Bool {
        let cellCount = SudokuGrid.cellCount
        let digits = 0...SudokuGrid.size
        let cellRange = 0..<cellCount

        guard formatVersion == Self.currentFormatVersion,
              board.count == cellCount,
              solution.count == cellCount,
              entries.count == cellCount,
              (board + entries).allSatisfy(digits.contains),
              solution.allSatisfy((1...SudokuGrid.size).contains),
              wrongIndices.allSatisfy(cellRange.contains),
              selectedIndex.map(cellRange.contains) ?? true,
              mistakeCount >= 0,
              elapsed >= 0
        else { return false }

        // Cada pista tiene que coincidir con la solución.
        return cellRange.allSatisfy { board[$0] == 0 || board[$0] == solution[$0] }
    }
}

extension Difficulty: Codable {}
