//
//  CelebrationStyle.swift
//  Sudoku
//

import Foundation

/// Cómo se anima una fila, columna o caja al completarse.
///
/// Solo cambia el *cómo*: qué grupo se celebra y en qué orden recorre sus celdas lo sigue
/// decidiendo `SudokuGame`, igual para todos los estilos.
nonisolated enum CelebrationStyle: String, CaseIterable, Identifiable, Sendable {
    /// Las celdas crecen y se tiñen en cadena desde la jugada. Es el estilo original.
    case wave
    /// Cada número gira como una carta.
    case flip
    /// Cada número salta hacia quien mira, sin salir de su recuadro, y aterriza.
    case jump
    /// Una franja de luz cruza cada celda.
    case shine
    /// Sin celebración.
    case off

    var id: String { rawValue }
}
