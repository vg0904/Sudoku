//
//  Difficulty.swift
//  Sudoku
//

import Foundation

/// Nivel de dificultad de una partida.
///
/// La dificultad se traduce en cuántas celdas se vacían del tablero resuelto. El número es un
/// *objetivo*, no una garantía: el generador se detiene antes si quitar otra celda haría que el
/// tablero tuviera más de una solución.
nonisolated enum Difficulty: String, CaseIterable, Identifiable, Sendable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    /// Cuántas de las 81 celdas se intentan vaciar.
    var cellsToRemove: Int {
        switch self {
        case .easy: 43
        case .medium: 48
        case .hard: 53
        }
    }

}

// El nombre visible vive en `Views/Difficulty+Presentation.swift`: usa `LocalizedStringKey`, que
// respeta el idioma elegido en los ajustes. `LocalizedStringResource` no lo haría, porque se
// resuelve con el idioma de la app y no con el del entorno de la vista.
