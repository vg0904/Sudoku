//
//  Celebration.swift
//  Sudoku
//

import Foundation

/// Un aviso de que una jugada acaba de completar una fila, una columna o una caja.
///
/// El modelo solo dice **qué** celebrar; el *cuándo* apagarla lo decide la vista. Así la detección
/// se puede probar sin relojes ni esperas, y SwiftUI se encarga de cancelar la animación si la
/// partida cambia a mitad.
nonisolated struct Celebration: Identifiable, Equatable, Sendable {
    /// El grupo que se ha completado.
    enum Group: Equatable, Hashable, Sendable {
        case row(Int)
        case column(Int)
        case box(Int)
        /// Las nueve apariciones de un número, repartidas por todo el tablero. También es lo que
        /// avisa al teclado numérico de que ese botón tiene que celebrar.
        case number(Int)
    }

    /// Un número que sube con cada celebración.
    ///
    /// Sirve de `id` para `.task(id:)` en la vista: dos celebraciones distintas de la misma fila
    /// tienen ids distintos, así que la animación se vuelve a disparar.
    let id: Int

    /// Los grupos completados de una sola jugada. Cerrar fila y caja a la vez da dos.
    let groups: [Group]

    /// `true` si esta celebración incluye haber completado `number`.
    func completes(number: Int) -> Bool {
        groups.contains(.number(number))
    }

    /// Las celdas a animar, **ordenadas por cercanía a la jugada**, sin repeticiones.
    ///
    /// Ese orden es lo que hace que la onda salga del punto donde se acaba de escribir en lugar de
    /// recorrer la fila siempre en el mismo sentido.
    let indices: [Int]
}
