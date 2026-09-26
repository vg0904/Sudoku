//
//  SudokuGrid.swift
//  Sudoku
//

import Foundation

/// Una grilla de Sudoku de 9×9.
///
/// Es un tipo de valor sin ninguna dependencia de SwiftUI, así que se puede usar (y probar) fuera
/// del main actor. El generador lo usa de forma intensiva en su backtracking.
nonisolated struct SudokuGrid: Equatable, Sendable {
    /// Celdas por lado del tablero.
    static let size = 9
    /// Celdas por lado de cada caja interna.
    static let boxSize = 3
    static let cellCount = size * size

    /// Las 81 celdas en un arreglo plano, ordenadas fila por fila.
    ///
    /// Se usa `0` para representar una celda vacía en lugar de `Int?` a propósito: verificar que un
    /// tablero tenga solución única obliga a resolverlo miles de veces, y a ese volumen el
    /// desempaquetado de opcionales se vuelve medible en builds de Debug (`-Onone`).
    private(set) var cells: [Int]

    /// Crea una grilla completamente vacía.
    init() {
        cells = Array(repeating: 0, count: Self.cellCount)
    }

    init(cells: [Int]) {
        precondition(cells.count == Self.cellCount, "Una grilla de Sudoku necesita exactamente \(Self.cellCount) celdas")
        self.cells = cells
    }

    // MARK: - Acceso a celdas

    subscript(index: Int) -> Int {
        get { cells[index] }
        set { cells[index] = newValue }
    }

    subscript(row: Int, column: Int) -> Int {
        get { cells[Self.index(row: row, column: column)] }
        set { cells[Self.index(row: row, column: column)] = newValue }
    }

    static func index(row: Int, column: Int) -> Int {
        row * size + column
    }

    static func row(of index: Int) -> Int {
        index / size
    }

    static func column(of index: Int) -> Int {
        index % size
    }

    // MARK: - Reglas del juego

    /// Indica si `value` se puede escribir en `index` sin repetirse en su fila, columna o caja.
    ///
    /// La propia celda se ignora en la comparación, así que preguntar por el valor que ya tiene
    /// devuelve `true`.
    func canPlace(_ value: Int, at index: Int) -> Bool {
        let row = Self.row(of: index)
        let column = Self.column(of: index)

        // Fila y columna se recorren en el mismo bucle.
        for offset in 0..<Self.size {
            let inRow = Self.index(row: row, column: offset)
            if inRow != index, cells[inRow] == value { return false }

            let inColumn = Self.index(row: offset, column: column)
            if inColumn != index, cells[inColumn] == value { return false }
        }

        let firstBoxRow = row - row % Self.boxSize
        let firstBoxColumn = column - column % Self.boxSize
        for boxRow in firstBoxRow..<(firstBoxRow + Self.boxSize) {
            for boxColumn in firstBoxColumn..<(firstBoxColumn + Self.boxSize) {
                let inBox = Self.index(row: boxRow, column: boxColumn)
                if inBox != index, cells[inBox] == value { return false }
            }
        }

        return true
    }

    /// `true` si ninguna celda llena repite un valor en su fila, columna o caja.
    ///
    /// Una grilla vacía cumple esta condición; sirve para comprobar consistencia, no si está
    /// terminada.
    var hasNoConflicts: Bool {
        for index in 0..<Self.cellCount where cells[index] != 0 {
            if !canPlace(cells[index], at: index) { return false }
        }
        return true
    }

    /// Índice de la primera celda vacía en orden de lectura, o `nil` si no queda ninguna.
    func firstEmptyIndex() -> Int? {
        cells.firstIndex(of: 0)
    }

    /// `true` si todas las celdas tienen un valor.
    var isComplete: Bool {
        !cells.contains(0)
    }

    var emptyCellCount: Int {
        cells.count { $0 == 0 }
    }

    // MARK: - Grupos

    /// Los nueve índices de una fila, de izquierda a derecha.
    static func rowIndices(_ row: Int) -> [Int] {
        (0..<size).map { index(row: row, column: $0) }
    }

    /// Los nueve índices de una columna, de arriba abajo.
    static func columnIndices(_ column: Int) -> [Int] {
        (0..<size).map { index(row: $0, column: column) }
    }

    /// El número de caja 3×3 (0…8) que contiene un índice, contando de izquierda a derecha y de
    /// arriba abajo.
    static func box(of index: Int) -> Int {
        (row(of: index) / boxSize) * boxSize + (column(of: index) / boxSize)
    }

    /// Los nueve índices de una caja 3×3, en orden de lectura.
    static func boxIndices(_ box: Int) -> [Int] {
        let firstRow = (box / boxSize) * boxSize
        let firstColumn = (box % boxSize) * boxSize

        return (firstRow..<(firstRow + boxSize)).flatMap { row in
            (firstColumn..<(firstColumn + boxSize)).map { column in
                index(row: row, column: column)
            }
        }
    }

    // MARK: - Vecindades

    /// Los índices de fila, columna y caja que comparten grupo con `index`, sin incluirlo.
    ///
    /// Lo consume la vista para resaltar el contexto de la celda seleccionada.
    static func relatedIndices(of index: Int) -> Set<Int> {
        let row = self.row(of: index)
        let column = self.column(of: index)
        var related = Set<Int>()

        for offset in 0..<size {
            related.insert(self.index(row: row, column: offset))
            related.insert(self.index(row: offset, column: column))
        }

        let firstBoxRow = row - row % boxSize
        let firstBoxColumn = column - column % boxSize
        for boxRow in firstBoxRow..<(firstBoxRow + boxSize) {
            for boxColumn in firstBoxColumn..<(firstBoxColumn + boxSize) {
                related.insert(self.index(row: boxRow, column: boxColumn))
            }
        }

        related.remove(index)
        return related
    }
}
