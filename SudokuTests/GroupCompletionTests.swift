//
//  GroupCompletionTests.swift
//  SudokuTests
//

import Testing
@testable import Sudoku

@Suite("Grupos de la grilla")
struct GridGroupTests {

    @Test("Una fila son nueve índices consecutivos")
    func rowIndices() {
        #expect(SudokuGrid.rowIndices(0) == Array(0...8))
        #expect(SudokuGrid.rowIndices(4) == Array(36...44))
    }

    @Test("Una columna avanza de nueve en nueve")
    func columnIndices() {
        #expect(SudokuGrid.columnIndices(0) == [0, 9, 18, 27, 36, 45, 54, 63, 72])
        #expect(SudokuGrid.columnIndices(8) == [8, 17, 26, 35, 44, 53, 62, 71, 80])
    }

    @Test("Las cajas se numeran en orden de lectura")
    func boxNumbering() {
        #expect(SudokuGrid.box(of: 0) == 0)
        #expect(SudokuGrid.box(of: 4) == 1)
        #expect(SudokuGrid.box(of: 8) == 2)
        #expect(SudokuGrid.box(of: SudokuGrid.index(row: 4, column: 4)) == 4)
        #expect(SudokuGrid.box(of: 80) == 8)
    }

    @Test("La primera caja son las tres primeras celdas de las tres primeras filas")
    func firstBoxIndices() {
        #expect(SudokuGrid.boxIndices(0) == [0, 1, 2, 9, 10, 11, 18, 19, 20])
    }

    @Test("La caja central está donde debe")
    func centerBoxIndices() {
        #expect(SudokuGrid.boxIndices(4) == [30, 31, 32, 39, 40, 41, 48, 49, 50])
    }

    @Test("Cada celda pertenece a la caja que la lista", arguments: 0..<9)
    func boxesAreConsistent(box: Int) {
        for index in SudokuGrid.boxIndices(box) {
            #expect(SudokuGrid.box(of: index) == box)
        }
    }
}

@Suite("Celebraciones")
@MainActor
struct CelebrationTests {

    /// Una partida con los huecos indicados sobre un tablero resuelto.
    private func makeGame(gaps: [Int]) -> SudokuGame {
        var generator = SeededRandomNumberGenerator(seed: 31)
        let solution = SudokuGenerator.makeFilledGrid(using: &generator)

        var board = solution
        for index in gaps {
            board[index] = 0
        }

        return SudokuGame(puzzle: Puzzle(board: board, solution: solution, difficulty: .easy))
    }

    @Test("Una partida nueva no tiene nada que celebrar")
    func startsWithoutCelebration() {
        let game = makeGame(gaps: [0])

        #expect(game.celebration == nil)
    }

    @Test("Cerrar una fila la celebra")
    func completingRowCelebrates() throws {
        // La celda 4 está en la fila 0, columna 4 y caja 1. Se deja sola para que al rellenarla
        // se cierren los tres grupos a la vez.
        let game = makeGame(gaps: [4])

        game.select(4)
        game.enter(game.puzzle.solution[4])

        let celebration = try #require(game.celebration)
        #expect(celebration.groups.contains(.row(0)))
    }

    @Test("Una jugada que cierra fila, columna, caja y número celebra los cuatro grupos")
    func completingSeveralGroupsAtOnce() throws {
        // Con un único hueco, rellenarlo cierra además la novena aparición de su número.
        let game = makeGame(gaps: [4])
        let number = game.puzzle.solution[4]

        game.select(4)
        game.enter(number)

        let celebration = try #require(game.celebration)
        #expect(celebration.groups.count == 4)
        #expect(celebration.groups.contains(.row(0)))
        #expect(celebration.groups.contains(.column(4)))
        #expect(celebration.groups.contains(.box(1)))
        #expect(celebration.completes(number: number))
    }

    @Test("Los índices de la celebración no se repiten")
    func indicesAreDeduplicated() throws {
        let game = makeGame(gaps: [4])

        game.select(4)
        game.enter(game.puzzle.solution[4])

        let celebration = try #require(game.celebration)
        #expect(Set(celebration.indices).count == celebration.indices.count)
        // Fila (9) + columna (9) + caja (9) compartiendo celdas dan 21 únicas. El número suma 8
        // más: sus otras apariciones caen, por las reglas del Sudoku, fuera de esa fila, columna
        // y caja.
        #expect(celebration.indices.count == 29)
    }

    @Test("Completar un número lo celebra aunque no cierre ningún otro grupo")
    func completingNumberCelebrates() throws {
        // Dos huecos con el mismo número, en filas, columnas y cajas distintas. Al rellenar el
        // primero no se completa nada; al rellenar el segundo se completa el número, pero su fila,
        // columna y caja siguen con otro hueco cada una.
        var generator = SeededRandomNumberGenerator(seed: 31)
        let solution = SudokuGenerator.makeFilledGrid(using: &generator)
        let number = solution[0]
        let sameNumber = (1..<SudokuGrid.cellCount).filter { solution[$0] == number }
        let target = try #require(sameNumber.first { SudokuGrid.box(of: $0) != 0 })
        // Otro hueco en la fila, la columna y la caja de `target`, para que no se cierren.
        let neighbours = [
            SudokuGrid.rowIndices(SudokuGrid.row(of: target)).first { $0 != target && solution[$0] != number },
            SudokuGrid.columnIndices(SudokuGrid.column(of: target)).first { $0 != target && solution[$0] != number },
            SudokuGrid.boxIndices(SudokuGrid.box(of: target)).first { $0 != target && solution[$0] != number },
        ].compactMap { $0 }

        let game = makeGame(gaps: [0, target] + neighbours)

        game.select(0)
        game.enter(number)
        #expect(game.celebration.map { !$0.completes(number: number) } ?? true)

        game.select(target)
        game.enter(number)

        let celebration = try #require(game.celebration)
        #expect(celebration.groups == [.number(number)])
        #expect(Set(celebration.indices) == Set(sameNumber + [0]))
        #expect(celebration.indices.first == target, "La onda sale de la jugada")
    }

    @Test("Un número que no se completa no se celebra")
    func incompleteNumberDoesNotCelebrate() {
        // Dos huecos con números distintos: rellenar uno deja el otro número incompleto.
        let game = makeGame(gaps: [0, 1])

        game.select(0)
        game.enter(game.puzzle.solution[0])

        let completed = game.celebration?.completes(number: game.puzzle.solution[1]) ?? false
        #expect(!completed)
    }

    @Test("La onda empieza en la celda jugada")
    func waveStartsAtPlayedCell() throws {
        let game = makeGame(gaps: [4])

        game.select(4)
        game.enter(game.puzzle.solution[4])

        let celebration = try #require(game.celebration)
        #expect(celebration.indices.first == 4)
    }

    @Test("Solo se completa el grupo, no todo el tablero")
    func celebratesWithoutSolving() throws {
        // Dos huecos: uno en la fila 0 y otro lejos, para que el tablero no quede resuelto.
        let farCell = SudokuGrid.index(row: 5, column: 7)
        let game = makeGame(gaps: [4, farCell])

        game.select(4)
        game.enter(game.puzzle.solution[4])

        #expect(!game.isSolved)
        #expect(game.celebration != nil, "Cerrar un grupo se celebra aunque quede tablero")
    }

    @Test("Una jugada equivocada no celebra nada")
    func wrongMoveDoesNotCelebrate() {
        let game = makeGame(gaps: [0, 1])

        game.select(0)
        game.enter(game.puzzle.solution[1])

        #expect(game.state(at: 0) == .wrong)
        #expect(game.celebration == nil)
    }

    @Test("Una fila con un error dentro no se celebra al llenarse")
    func rowWithMistakeIsNotCelebrated() {
        // Dos huecos en la fila 0: se llena uno mal y el otro bien. La fila queda completa de
        // números pero con un error, así que no hay celebración.
        let game = makeGame(gaps: [0, 1])

        game.select(0)
        game.enter(game.puzzle.solution[1])
        #expect(game.celebration == nil)

        game.select(1)
        game.enter(game.puzzle.solution[1])

        // La celda 1 sí es correcta, pero su fila y su caja siguen teniendo el error de la celda 0.
        if let celebration = game.celebration {
            #expect(!celebration.groups.contains(.row(0)), "La fila 0 tiene un error")
            #expect(!celebration.groups.contains(.box(0)), "La caja 0 tiene un error")
        }
    }

    @Test("Celebraciones sucesivas tienen ids distintos")
    func celebrationIDsIncrease() throws {
        let firstCell = SudokuGrid.index(row: 0, column: 4)
        let secondCell = SudokuGrid.index(row: 5, column: 7)
        let game = makeGame(gaps: [firstCell, secondCell])

        game.select(firstCell)
        game.enter(game.puzzle.solution[firstCell])
        let first = try #require(game.celebration)

        game.select(secondCell)
        game.enter(game.puzzle.solution[secondCell])
        let second = try #require(game.celebration)

        #expect(second.id > first.id, "Sin id nuevo la vista no repetiría la animación")
    }

    @Test("`endCelebration` la limpia")
    func endCelebrationClears() {
        let game = makeGame(gaps: [4])

        game.select(4)
        game.enter(game.puzzle.solution[4])
        #expect(game.celebration != nil)

        game.endCelebration()

        #expect(game.celebration == nil)
    }

    @Test("Reiniciar la partida descarta la celebración pendiente")
    func restartClearsCelebration() {
        let game = makeGame(gaps: [4])

        game.select(4)
        game.enter(game.puzzle.solution[4])
        #expect(game.celebration != nil)

        game.restart()

        #expect(game.celebration == nil)
    }
}
