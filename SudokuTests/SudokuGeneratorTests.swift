//
//  SudokuGeneratorTests.swift
//  SudokuTests
//

import Testing
@testable import Sudoku

@Suite("Generador")
struct SudokuGeneratorTests {

    @Test("Una grilla llena es completa y sin conflictos")
    func filledGridIsValid() {
        var generator = SeededRandomNumberGenerator(seed: 1)
        let grid = SudokuGenerator.makeFilledGrid(using: &generator)

        #expect(grid.isComplete)
        #expect(grid.hasNoConflicts)
    }

    @Test("Dos semillas distintas dan grillas distintas")
    func differentSeedsDifferentGrids() {
        var first = SeededRandomNumberGenerator(seed: 1)
        var second = SeededRandomNumberGenerator(seed: 2)

        #expect(
            SudokuGenerator.makeFilledGrid(using: &first)
                != SudokuGenerator.makeFilledGrid(using: &second)
        )
    }

    @Test("La misma semilla da el mismo tablero")
    func generationIsDeterministic() {
        var first = SeededRandomNumberGenerator(seed: 42)
        var second = SeededRandomNumberGenerator(seed: 42)

        let a = SudokuGenerator.makePuzzle(difficulty: .easy, using: &first)
        let b = SudokuGenerator.makePuzzle(difficulty: .easy, using: &second)

        #expect(a == b)
    }

    @Test("Un tablero generado tiene exactamente una solución", arguments: Difficulty.allCases)
    func puzzleHasUniqueSolution(difficulty: Difficulty) {
        var generator = SeededRandomNumberGenerator(seed: 7)
        let puzzle = SudokuGenerator.makePuzzle(difficulty: difficulty, using: &generator)

        #expect(puzzle.solution.isComplete)
        #expect(puzzle.solution.hasNoConflicts)
        #expect(puzzle.board.hasNoConflicts)
        #expect(SudokuGenerator.countSolutions(puzzle.board, limit: 2) == 1)
    }

    @Test("Resolver el tablero reproduce la solución guardada", arguments: Difficulty.allCases)
    func solvingReproducesSolution(difficulty: Difficulty) throws {
        var generator = SeededRandomNumberGenerator(seed: 13)
        let puzzle = SudokuGenerator.makePuzzle(difficulty: difficulty, using: &generator)

        let solved = try #require(SudokuGenerator.solve(puzzle.board))
        #expect(solved == puzzle.solution)
    }

    @Test("Las pistas del tablero coinciden con la solución", arguments: Difficulty.allCases)
    func givenCellsMatchSolution(difficulty: Difficulty) {
        var generator = SeededRandomNumberGenerator(seed: 21)
        let puzzle = SudokuGenerator.makePuzzle(difficulty: difficulty, using: &generator)

        for index in 0..<SudokuGrid.cellCount where puzzle.board[index] != 0 {
            #expect(puzzle.board[index] == puzzle.solution[index])
        }
    }

    @Test("Se vacían celdas sin pasarse del objetivo", arguments: Difficulty.allCases)
    func removesReasonableNumberOfCells(difficulty: Difficulty) {
        var generator = SeededRandomNumberGenerator(seed: 4)
        let puzzle = SudokuGenerator.makePuzzle(difficulty: difficulty, using: &generator)
        let empty = puzzle.board.emptyCellCount

        // Se comprueba un rango, no una igualdad: la unicidad de la solución manda, así que el
        // generador puede quedarse corto respecto a `cellsToRemove`. Nunca puede pasarse.
        #expect(empty <= difficulty.cellsToRemove)
        #expect(empty >= 30, "Vació solo \(empty) celdas; el tablero saldría demasiado fácil")
    }

    @Test("Un tablero más difícil no deja más pistas que uno fácil")
    func harderPuzzlesHaveFewerGivens() {
        var easyGenerator = SeededRandomNumberGenerator(seed: 5)
        var hardGenerator = SeededRandomNumberGenerator(seed: 5)

        let easy = SudokuGenerator.makePuzzle(difficulty: .easy, using: &easyGenerator)
        let hard = SudokuGenerator.makePuzzle(difficulty: .hard, using: &hardGenerator)

        #expect(hard.board.emptyCellCount >= easy.board.emptyCellCount)
    }

    @Test("Contar soluciones se detiene en el límite")
    func solutionCountingRespectsLimit() {
        // Una grilla vacía tiene miles de millones de soluciones; el límite es lo que evita
        // enumerarlas.
        #expect(SudokuGenerator.countSolutions(SudokuGrid(), limit: 2) == 2)
        #expect(SudokuGenerator.countSolutions(SudokuGrid(), limit: 5) == 5)
    }

    @Test("Una grilla resuelta cuenta como una sola solución")
    func completedGridHasOneSolution() {
        var generator = SeededRandomNumberGenerator(seed: 3)
        let grid = SudokuGenerator.makeFilledGrid(using: &generator)

        #expect(SudokuGenerator.countSolutions(grid, limit: 2) == 1)
    }

    @Test("Un tablero imposible no tiene solución")
    func unsolvableGridHasNoSolution() {
        var grid = SudokuGrid()

        // Se construye una grilla que no viola ninguna regla pero que aun así no se puede
        // completar: la fila 0 ya tiene el 1 al 8, así que (0,0) solo podría ser 9 — y el 9 está
        // ocupado en su columna. La celda se queda sin candidatos.
        for column in 1..<SudokuGrid.size {
            grid[0, column] = column
        }
        grid[1, 0] = 9

        #expect(grid.hasNoConflicts, "La grilla debe ser consistente para que el test valga")
        #expect(SudokuGenerator.solve(grid) == nil)
        #expect(SudokuGenerator.countSolutions(grid) == 0)
    }
}
