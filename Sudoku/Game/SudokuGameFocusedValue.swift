//
//  SudokuGameFocusedValue.swift
//  Sudoku
//

import SwiftUI

extension FocusedValues {
    /// La partida de la ventana que tiene el foco.
    ///
    /// Los comandos del menú viven fuera de la jerarquía de vistas, así que necesitan esta vía para
    /// llegar al `SudokuGame`. Se usa `FocusedValues` en lugar de un estado global porque en Mac
    /// puede haber varias ventanas abiertas y cada una tiene su propia partida.
    @Entry var sudokuGame: SudokuGame?

    /// Si la ventana con el foco está pidiendo confirmación para limpiar el tablero.
    ///
    /// El menú no puede mostrar diálogos, así que en lugar de limpiar directamente activa este
    /// enlace, y la ventana muestra la misma confirmación que su propio botón.
    @Entry var isConfirmingClearBoard: Binding<Bool>?
}
