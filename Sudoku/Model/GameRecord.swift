//
//  GameRecord.swift
//  Sudoku
//

import Foundation
import SwiftData

/// Una partida ganada que entró en la tabla de récords.
///
/// `@Model` convierte la clase en un modelo de SwiftData: sus propiedades se guardan en disco y la
/// vista que la lea con `@Query` se actualiza sola cuando cambian.
@Model
final class GameRecord {
    var playerName: String
    /// Cuánto se tardó, en segundos.
    var time: TimeInterval
    /// La dificultad como texto (`Difficulty.rawValue`).
    ///
    /// Se guarda el texto y no el `enum` porque los filtros de `@Query` (`#Predicate`) se traducen
    /// a consultas de la base de datos, y comparar un texto es lo que mejor se traduce.
    var difficultyRaw: String
    /// Las vidas con las que se jugó, o `0` si eran ilimitadas. Mismo criterio que
    /// `GameSettings.lives`.
    var lives: Int
    var mistakes: Int
    var date: Date

    init(
        playerName: String,
        time: TimeInterval,
        difficulty: Difficulty,
        lives: Int,
        mistakes: Int,
        date: Date
    ) {
        self.playerName = playerName
        self.time = time
        self.difficultyRaw = difficulty.rawValue
        self.lives = lives
        self.mistakes = mistakes
        self.date = date
    }

    var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .medium
    }
}
