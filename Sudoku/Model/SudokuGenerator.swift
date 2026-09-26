//
//  SudokuGenerator.swift
//  Sudoku
//

import Foundation

/// Un tablero generado junto con su solución.
nonisolated struct Puzzle: Equatable, Sendable {
    /// El tablero con huecos que se le presenta a quien juega. Las celdas llenas son las pistas.
    let board: SudokuGrid
    /// La única solución válida de `board`.
    let solution: SudokuGrid
    let difficulty: Difficulty

    /// Un `Puzzle` vacío, para tener algo que mostrar mientras se genera el primero.
    static let placeholder = Puzzle(board: SudokuGrid(), solution: SudokuGrid(), difficulty: .medium)
}

/// Genera y resuelve tableros de Sudoku por backtracking.
///
/// Todas las funciones que dependen del azar reciben el generador aleatorio como parámetro `inout`
/// en lugar de usar el del sistema internamente. Eso es lo que permite que las pruebas inyecten una
/// semilla fija y obtengan tableros reproducibles.
nonisolated enum SudokuGenerator {

    // MARK: - Generar

    /// Construye un tablero con solución única y su solución.
    ///
    /// Primero resuelve una grilla vacía con los candidatos en orden aleatorio (lo que da un
    /// tablero completo distinto cada vez), y después va vaciando celdas mientras la solución siga
    /// siendo única.
    ///
    /// - Note: Puede vaciar menos celdas que `difficulty.cellsToRemove`. La unicidad manda: si
    ///   quitar una celda abriría una segunda solución, el valor se restaura.
    static func makePuzzle<R: RandomNumberGenerator>(
        difficulty: Difficulty,
        using generator: inout R
    ) -> Puzzle {
        let solution = makeFilledGrid(using: &generator)
        var board = solution
        var removed = 0

        for index in (0..<SudokuGrid.cellCount).shuffled(using: &generator) {
            guard removed < difficulty.cellsToRemove else { break }

            let value = board[index]
            board[index] = 0

            if countSolutions(board, limit: 2) == 1 {
                removed += 1
            } else {
                board[index] = value
            }
        }

        return Puzzle(board: board, solution: solution, difficulty: difficulty)
    }

    /// Igual que `makePuzzle(difficulty:using:)` pero con el generador aleatorio del sistema.
    static func makePuzzle(difficulty: Difficulty) -> Puzzle {
        var generator = SystemRandomNumberGenerator()
        return makePuzzle(difficulty: difficulty, using: &generator)
    }

    /// Una grilla 9×9 completa y válida, elegida al azar.
    static func makeFilledGrid<R: RandomNumberGenerator>(using generator: inout R) -> SudokuGrid {
        var grid = SudokuGrid()
        _ = fill(&grid, using: &generator)
        return grid
    }

    private static func fill<R: RandomNumberGenerator>(
        _ grid: inout SudokuGrid,
        using generator: inout R
    ) -> Bool {
        guard let index = grid.firstEmptyIndex() else { return true }

        for value in (1...SudokuGrid.size).shuffled(using: &generator) {
            guard grid.canPlace(value, at: index) else { continue }

            grid[index] = value
            if fill(&grid, using: &generator) { return true }
            grid[index] = 0
        }

        return false
    }

    // MARK: - Resolver

    /// Resuelve `grid`, o devuelve `nil` si no tiene solución.
    ///
    /// Si hay varias soluciones devuelve la primera que encuentra.
    static func solve(_ grid: SudokuGrid) -> SudokuGrid? {
        var working = grid
        return solveInPlace(&working) ? working : nil
    }

    private static func solveInPlace(_ grid: inout SudokuGrid) -> Bool {
        guard let index = grid.firstEmptyIndex() else { return true }

        for value in 1...SudokuGrid.size {
            guard grid.canPlace(value, at: index) else { continue }

            grid[index] = value
            if solveInPlace(&grid) { return true }
            grid[index] = 0
        }

        return false
    }

    /// Cuenta cuántas soluciones tiene `grid`, deteniéndose al alcanzar `limit`.
    ///
    /// El límite es lo que hace viable generar tableros: para saber si la solución es única basta
    /// con buscar dos, no todas.
    static func countSolutions(_ grid: SudokuGrid, limit: Int = 2) -> Int {
        var working = grid
        var found = 0
        countSolutionsInPlace(&working, found: &found, limit: limit)
        return found
    }

    private static func countSolutionsInPlace(
        _ grid: inout SudokuGrid,
        found: inout Int,
        limit: Int
    ) {
        guard let index = grid.firstEmptyIndex() else {
            found += 1
            return
        }

        for value in 1...SudokuGrid.size {
            guard grid.canPlace(value, at: index) else { continue }

            grid[index] = value
            countSolutionsInPlace(&grid, found: &found, limit: limit)
            grid[index] = 0

            if found >= limit { return }
        }
    }
}
