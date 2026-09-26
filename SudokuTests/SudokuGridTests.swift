//
//  SudokuGridTests.swift
//  SudokuTests
//

import Testing
@testable import Sudoku

@Suite("Grilla")
struct SudokuGridTests {

    @Test("Una grilla nueva está vacía")
    func emptyGrid() {
        let grid = SudokuGrid()

        #expect(grid.emptyCellCount == SudokuGrid.cellCount)
        #expect(grid.firstEmptyIndex() == 0)
        #expect(!grid.isComplete)
        // Una grilla vacía no tiene conflictos: no hay nada que pueda repetirse.
        #expect(grid.hasNoConflicts)
    }

    @Test("Índices, filas y columnas se corresponden")
    func indexMath() {
        #expect(SudokuGrid.index(row: 0, column: 0) == 0)
        #expect(SudokuGrid.index(row: 8, column: 8) == 80)
        #expect(SudokuGrid.index(row: 4, column: 3) == 39)

        #expect(SudokuGrid.row(of: 39) == 4)
        #expect(SudokuGrid.column(of: 39) == 3)
    }

    @Test("Un valor repetido en la fila no se puede colocar")
    func rejectsRowDuplicate() {
        var grid = SudokuGrid()
        grid[0, 0] = 5

        #expect(!grid.canPlace(5, at: SudokuGrid.index(row: 0, column: 7)))
        #expect(grid.canPlace(6, at: SudokuGrid.index(row: 0, column: 7)))
    }

    @Test("Un valor repetido en la columna no se puede colocar")
    func rejectsColumnDuplicate() {
        var grid = SudokuGrid()
        grid[0, 2] = 7

        #expect(!grid.canPlace(7, at: SudokuGrid.index(row: 5, column: 2)))
        #expect(grid.canPlace(7, at: SudokuGrid.index(row: 5, column: 3)))
    }

    @Test("Un valor repetido en la caja 3×3 no se puede colocar")
    func rejectsBoxDuplicate() {
        var grid = SudokuGrid()
        grid[3, 3] = 9

        // Misma caja central, pero distinta fila y distinta columna.
        #expect(!grid.canPlace(9, at: SudokuGrid.index(row: 5, column: 5)))
    }

    @Test("Una celda no entra en conflicto consigo misma")
    func ignoresOwnCell() {
        var grid = SudokuGrid()
        grid[2, 2] = 4

        #expect(grid.canPlace(4, at: SudokuGrid.index(row: 2, column: 2)))
    }

    @Test("Las celdas relacionadas son las 20 vecinas, sin incluirse a sí misma")
    func relatedIndices() {
        let index = SudokuGrid.index(row: 4, column: 4)
        let related = SudokuGrid.relatedIndices(of: index)

        // 8 de la fila + 8 de la columna + 4 de la caja que no comparten fila ni columna.
        #expect(related.count == 20)
        #expect(!related.contains(index))
        #expect(related.contains(SudokuGrid.index(row: 4, column: 0)))
        #expect(related.contains(SudokuGrid.index(row: 0, column: 4)))
        #expect(related.contains(SudokuGrid.index(row: 3, column: 3)))
        #expect(!related.contains(SudokuGrid.index(row: 0, column: 0)))
    }
}
