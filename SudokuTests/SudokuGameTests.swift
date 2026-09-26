//
//  SudokuGameTests.swift
//  SudokuTests
//

import Testing
@testable import Sudoku

@Suite("Partida")
@MainActor
struct SudokuGameTests {

    /// Construye una partida con un tablero conocido y solo unas pocas celdas vacías.
    ///
    /// No se usa `makePuzzle` a propósito: vaciar celdas verificando unicidad es lento y aquí no
    /// aporta nada. Basta con una solución válida y unos huecos elegidos a mano.
    private func makeGame(emptyIndices: [Int] = [0, 1, 2]) -> SudokuGame {
        var generator = SeededRandomNumberGenerator(seed: 99)
        let solution = SudokuGenerator.makeFilledGrid(using: &generator)

        var board = solution
        for index in emptyIndices {
            board[index] = 0
        }

        return SudokuGame(puzzle: Puzzle(board: board, solution: solution, difficulty: .easy))
    }

    // MARK: - Estado inicial

    @Test("Una partida recién creada no está resuelta")
    func emptyGameIsNotSolved() {
        let game = SudokuGame()

        #expect(!game.isSolved)
        #expect(game.mistakeCount == 0)
    }

    @Test("La primera celda vacía queda seleccionada")
    func selectsFirstEmptyCell() {
        let game = makeGame(emptyIndices: [40, 41])

        #expect(game.selectedIndex == 40)
    }

    @Test("Las pistas se distinguen de las celdas vacías")
    func distinguishesGivens() {
        let game = makeGame(emptyIndices: [0])

        #expect(game.state(at: 0) == .empty)
        #expect(!game.isGiven(0))
        #expect(game.state(at: 1) == .given)
        #expect(game.isGiven(1))
    }

    // MARK: - Errores

    // Nota para estos tests: el valor equivocado se toma siempre de *otro* hueco del tablero.
    // Con un solo hueco no serviría ningún número, porque todos los demás estarían completos y
    // el juego los rechaza — ver `completeValueRejectsFurtherInput`.

    @Test("Un valor equivocado cuenta como error y marca la celda")
    func wrongValueCountsMistake() {
        let game = makeGame(emptyIndices: [0, 1])
        // El número que va en la celda 1 es incorrecto en la celda 0, y como aún le falta una
        // colocación el juego lo acepta.
        let wrong = game.puzzle.solution[1]

        game.select(0)
        game.enter(wrong)

        #expect(game.mistakeCount == 1)
        #expect(game.state(at: 0) == .wrong)
        // El número se queda visible para poder corregirlo.
        #expect(game.value(at: 0) == wrong)
    }

    @Test("Dos errores en la misma celda cuentan dos veces")
    func repeatedMistakesCountSeparately() {
        // Tres huecos en la misma fila dan dos números equivocados distintos y disponibles.
        let game = makeGame(emptyIndices: [0, 1, 2])
        let firstWrong = game.puzzle.solution[1]
        let secondWrong = game.puzzle.solution[2]

        #expect(firstWrong != secondWrong)

        game.select(0)
        game.enter(firstWrong)
        game.enter(secondWrong)

        #expect(game.mistakeCount == 2)
    }

    @Test("Corregir una celda la saca de la lista de errores pero no baja el contador")
    func correctingKeepsMistakeCount() {
        let game = makeGame(emptyIndices: [0, 1])
        let correct = game.puzzle.solution[0]
        let wrong = game.puzzle.solution[1]

        game.select(0)
        game.enter(wrong)
        game.enter(correct)

        #expect(game.state(at: 0) == .filled)
        #expect(game.wrongIndices.isEmpty)
        #expect(game.mistakeCount == 1, "El error ya ocurrió; corregirlo no lo borra del historial")
    }

    @Test("Un valor correcto no cuenta error")
    func correctValueIsNotAMistake() {
        let game = makeGame(emptyIndices: [0])

        game.select(0)
        game.enter(game.puzzle.solution[0])

        #expect(game.mistakeCount == 0)
        #expect(game.state(at: 0) == .filled)
    }

    @Test("Un error queda publicado con su celda")
    func mistakeIsPublished() {
        let game = makeGame(emptyIndices: [0, 1])
        #expect(game.lastMistake == nil)

        game.select(0)
        game.enter(game.puzzle.solution[1])

        #expect(game.lastMistake?.index == 0)
    }

    @Test("Repetir el mismo error da un evento distinto")
    func repeatedMistakeHasNewID() {
        // Sin id nuevo, la vista no volvería a sacudir la celda.
        let game = makeGame(emptyIndices: [0, 1])
        let wrong = game.puzzle.solution[1]

        game.select(0)
        game.enter(wrong)
        let first = game.lastMistake

        game.enter(wrong)

        #expect(game.lastMistake != first)
        #expect(game.lastMistake?.index == 0)
    }

    @Test("Un acierto no publica ningún error")
    func correctValueDoesNotPublishMistake() {
        let game = makeGame(emptyIndices: [0])

        game.select(0)
        game.enter(game.puzzle.solution[0])

        #expect(game.lastMistake == nil)
    }

    @Test("Reiniciar descarta el último error")
    func restartClearsLastMistake() {
        let game = makeGame(emptyIndices: [0, 1])

        game.select(0)
        game.enter(game.puzzle.solution[1])
        game.restart()

        #expect(game.lastMistake == nil)
    }

    // MARK: - Reglas de entrada

    @Test("No se puede escribir sobre una pista")
    func cannotOverwriteGiven() {
        let game = makeGame(emptyIndices: [0])
        let original = game.value(at: 1)

        game.select(1)
        game.enter(original == 1 ? 2 : 1)

        #expect(game.value(at: 1) == original)
        #expect(game.mistakeCount == 0)
    }

    @Test("Los valores fuera de 1...9 se ignoran", arguments: [0, 10, -1])
    func ignoresOutOfRangeValues(value: Int) {
        let game = makeGame(emptyIndices: [0])

        game.select(0)
        game.enter(value)

        #expect(game.value(at: 0) == 0)
        #expect(game.mistakeCount == 0)
    }

    @Test("Borrar vacía la celda sin tocar el contador")
    func clearingLeavesMistakeCount() {
        let game = makeGame(emptyIndices: [0, 1])

        game.select(0)
        game.enter(game.puzzle.solution[1])
        game.clearSelection()

        #expect(game.value(at: 0) == 0)
        #expect(game.state(at: 0) == .empty)
        #expect(game.mistakeCount == 1)
    }

    // MARK: - Respuestas bloqueadas

    @Test("Una respuesta correcta no se puede borrar")
    func correctEntryCannotBeCleared() {
        let game = makeGame(emptyIndices: [0, 1])
        let correct = game.puzzle.solution[0]

        game.select(0)
        game.enter(correct)
        #expect(!game.canClearSelection)

        game.clearSelection()

        #expect(game.value(at: 0) == correct)
        #expect(game.state(at: 0) == .filled)
    }

    @Test("Escribir sobre una respuesta correcta no la cambia ni cuenta error")
    func correctEntryCannotBeOverwritten() {
        let game = makeGame(emptyIndices: [0, 1])
        let correct = game.puzzle.solution[0]

        game.select(0)
        game.enter(correct)
        // El número de la otra celda vacía todavía se acepta en general, así que si la celda 0
        // no estuviera bloqueada, esto sería un error.
        game.enter(game.puzzle.solution[1])

        #expect(game.value(at: 0) == correct)
        #expect(game.mistakeCount == 0)
    }

    @Test("Solo se pueden editar las celdas vacías y los errores")
    func editableStates() {
        let game = makeGame(emptyIndices: [0, 1, 2])

        game.select(0)
        game.enter(game.puzzle.solution[0])
        game.select(1)
        game.enter(game.puzzle.solution[2])

        #expect(!game.isEditable(0), "Respuesta correcta")
        #expect(game.isEditable(1), "Error")
        #expect(game.isEditable(2), "Vacía")
        #expect(!game.isEditable(3), "Pista")
    }

    @Test("Solo un error se puede borrar")
    func onlyWrongCellsCanBeCleared() {
        let game = makeGame(emptyIndices: [0, 1])

        game.select(0)
        #expect(!game.canClearSelection, "Vacía")

        game.enter(game.puzzle.solution[1])
        #expect(game.canClearSelection, "Error")

        game.select(2)
        #expect(!game.canClearSelection, "Pista")

        game.selectedIndex = nil
        #expect(!game.canClearSelection, "Sin selección")
    }

    @Test("Hay progreso en cuanto se escribe algo o se comete un error")
    func tracksProgress() {
        let game = makeGame(emptyIndices: [0, 1])
        #expect(!game.hasProgress)

        game.select(0)
        game.enter(game.puzzle.solution[1])
        game.clearSelection()
        // El tablero vuelve a estar vacío, pero el error sigue contado.
        #expect(game.hasProgress)

        game.restart()
        #expect(!game.hasProgress)

        game.select(0)
        game.enter(game.puzzle.solution[0])
        #expect(game.hasProgress)
    }

    // MARK: - Navegación

    @Test("La selección se mueve por el tablero")
    func movesSelection() {
        let game = makeGame(emptyIndices: [40])

        game.select(SudokuGrid.index(row: 4, column: 4))
        game.moveSelection(rowDelta: 1, columnDelta: 0)

        #expect(game.selectedIndex == SudokuGrid.index(row: 5, column: 4))
    }

    @Test("La selección no se sale de los bordes")
    func clampsSelectionAtEdges() {
        let game = makeGame()

        game.select(0)
        game.moveSelection(rowDelta: -1, columnDelta: -1)
        #expect(game.selectedIndex == 0)

        game.select(SudokuGrid.cellCount - 1)
        game.moveSelection(rowDelta: 1, columnDelta: 1)
        #expect(game.selectedIndex == SudokuGrid.cellCount - 1)
    }

    @Test("Se resaltan las 20 celdas relacionadas con la selección")
    func highlightsRelatedCells() {
        let game = makeGame()

        game.select(SudokuGrid.index(row: 4, column: 4))

        #expect(game.highlightedIndices.count == 20)
    }

    // MARK: - Coincidencias de número

    @Test("Seleccionar una pista resalta las nueve celdas con ese número")
    func highlightsMatchingGivens() {
        // Sin celdas vacías el tablero está completo, así que cada número aparece 9 veces.
        let game = makeGame(emptyIndices: [])

        game.select(0)
        let target = game.value(at: 0)

        #expect(game.selectedValue == target)
        #expect(game.matchingValueIndices.count == 9)
        #expect(game.matchingValueIndices.contains(0), "La celda seleccionada también cuenta")

        for index in game.matchingValueIndices {
            #expect(game.value(at: index) == target)
        }
    }

    @Test("Un número que escribo yo también cuenta como coincidencia")
    func highlightsOwnCorrectEntry() {
        let game = makeGame(emptyIndices: [0])
        let correct = game.puzzle.solution[0]

        game.select(0)
        game.enter(correct)

        // Otra celda cualquiera con el mismo número, para comprobar que se agrupan.
        let otherWithSameValue = (1..<SudokuGrid.cellCount).first { game.value(at: $0) == correct }
        let matching = game.matchingValueIndices

        #expect(matching.contains(0))
        if let otherWithSameValue {
            #expect(matching.contains(otherWithSameValue))
        }
    }

    @Test("Una celda vacía no resalta nada")
    func emptyCellHighlightsNoMatches() {
        let game = makeGame(emptyIndices: [0])

        game.select(0)

        #expect(game.selectedValue == 0)
        #expect(game.matchingValueIndices.isEmpty)
    }

    @Test("Sin selección no hay coincidencias")
    func noSelectionHighlightsNoMatches() {
        let game = makeGame()
        game.selectedIndex = nil

        #expect(game.selectedValue == 0)
        #expect(game.matchingValueIndices.isEmpty)
    }

    @Test("Borrar la celda seleccionada apaga las coincidencias")
    func clearingRemovesMatches() {
        // Se borra un error, porque es lo único que se puede borrar.
        let game = makeGame(emptyIndices: [0, 1])

        game.select(0)
        game.enter(game.puzzle.solution[1])
        #expect(!game.matchingValueIndices.isEmpty)

        game.clearSelection()

        #expect(game.matchingValueIndices.isEmpty)
    }

    // MARK: - Números completos

    @Test("En un tablero resuelto todos los números están completos")
    func allValuesCompleteOnFullBoard() {
        let game = makeGame(emptyIndices: [])

        for number in 1...SudokuGrid.size {
            #expect(game.placedCount(of: number) == 9)
            #expect(game.isValueComplete(number))
        }
    }

    @Test("Un hueco deja incompleto solo el número que le corresponde")
    func oneGapLeavesOneValueIncomplete() {
        let game = makeGame(emptyIndices: [])
        let missing = game.puzzle.solution[0]
        let gapped = makeGame(emptyIndices: [0])

        #expect(gapped.placedCount(of: missing) == 8)
        #expect(!gapped.isValueComplete(missing))

        // Los demás números siguen completos.
        for number in (1...SudokuGrid.size) where number != missing {
            #expect(gapped.isValueComplete(number))
        }
    }

    @Test("Completar el hueco completa el número")
    func fillingGapCompletesValue() {
        let game = makeGame(emptyIndices: [0])
        let missing = game.puzzle.solution[0]

        #expect(!game.isValueComplete(missing))

        game.select(0)
        game.enter(missing)

        #expect(game.isValueComplete(missing))
        #expect(game.placedCount(of: missing) == 9)
    }

    @Test("Un número mal colocado no cuenta para completar")
    func wrongPlacementDoesNotCount() {
        // Se vacían dos celdas con números distintos para poder escribir uno donde va el otro.
        let game = makeGame(emptyIndices: [0, 1])
        let valueAtZero = game.puzzle.solution[0]
        let valueAtOne = game.puzzle.solution[1]

        // Las celdas 0 y 1 están en la misma fila, así que sus valores son distintos.
        #expect(valueAtZero != valueAtOne)

        // Escribe en la celda 1 el número que iba en la 0: visible, pero mal puesto.
        game.select(1)
        game.enter(valueAtZero)

        #expect(game.state(at: 1) == .wrong)
        #expect(game.placedCount(of: valueAtZero) == 8, "El mal colocado no debe contar")
        #expect(!game.isValueComplete(valueAtZero))
    }

    @Test("Un número completo ya no se puede escribir")
    func completeValueRejectsFurtherInput() {
        let game = makeGame(emptyIndices: [0, 1])
        let valueAtZero = game.puzzle.solution[0]

        // Completa el número de la celda 0.
        game.select(0)
        game.enter(valueAtZero)
        #expect(game.isValueComplete(valueAtZero))

        // Intentar ponerlo en la otra celda vacía no hace nada, ni siquiera cuenta error.
        game.select(1)
        game.enter(valueAtZero)

        #expect(game.value(at: 1) == 0)
        #expect(game.mistakeCount == 0)
    }

    @Test("Un número completo sigue completo porque sus celdas no se pueden borrar")
    func completedValueStaysComplete() {
        let game = makeGame(emptyIndices: [0])
        let missing = game.puzzle.solution[0]

        game.select(0)
        game.enter(missing)
        #expect(game.isValueComplete(missing))

        game.clearSelection()

        #expect(game.isValueComplete(missing))
        #expect(game.placedCount(of: missing) == 9)
    }

    @Test("Un número fuera de rango nunca está completo", arguments: [0, 10, -1])
    func outOfRangeValuesAreNeverComplete(number: Int) {
        let game = makeGame(emptyIndices: [])

        #expect(game.placedCount(of: number) == 0)
        #expect(!game.isValueComplete(number))
    }

    // MARK: - Reinicio y victoria

    @Test("Borrar todo limpia el progreso y conserva el tablero")
    func restartKeepsBoard() {
        let game = makeGame(emptyIndices: [0, 1, 2])
        let boardBefore = game.puzzle.board
        let correct = game.puzzle.solution[0]

        game.select(0)
        game.enter(correct == 1 ? 2 : 1)
        game.restart()

        #expect(game.mistakeCount == 0)
        #expect(game.wrongIndices.isEmpty)
        #expect(game.value(at: 0) == 0)
        #expect(game.puzzle.board == boardBefore)
    }

    @Test("Completar el tablero correctamente lo marca como resuelto")
    func fillingCorrectlySolvesGame() {
        let emptyIndices = [0, 1, 2, 30, 31, 55]
        let game = makeGame(emptyIndices: emptyIndices)

        #expect(!game.isSolved)

        for index in emptyIndices {
            game.select(index)
            game.enter(game.puzzle.solution[index])
        }

        #expect(game.isSolved)
        #expect(game.mistakeCount == 0)
    }

    #if DEBUG
    @Test("El atajo de depuración deja el tablero a una jugada de ganar")
    func debugFillLeavesOneMove() {
        let game = makeGame(emptyIndices: [0, 1, 2, 30])

        // Un error previo también se corrige.
        game.select(0)
        game.enter(game.puzzle.solution[1])

        game.debugFillAllButOne()

        #expect(!game.isSolved)
        #expect(game.wrongIndices.isEmpty)
        #expect(game.selectedIndex == 30, "Selecciona la única celda que falta")

        game.enter(game.puzzle.solution[30])

        #expect(game.isSolved)
    }

    @Test("Una partida con el atajo de depuración no cuenta para los récords")
    func debugFillIsNotEligibleForRecords() {
        let game = makeGame(emptyIndices: [0, 1])
        #expect(game.isEligibleForRecords)

        game.debugFillAllButOne()
        #expect(!game.isEligibleForRecords)

        // Reiniciar el mismo tablero sin ayuda vuelve a contar.
        game.restart()
        #expect(game.isEligibleForRecords)
    }
    #endif

    @Test("Un tablero lleno con un error no cuenta como resuelto")
    func fullBoardWithMistakeIsNotSolved() {
        let game = makeGame(emptyIndices: [0, 1])

        // Se llena la celda 1 con el número de la celda 0: queda mal puesto, pero al no contar
        // como acierto ese número sigue disponible para colocarlo bien después.
        game.select(1)
        game.enter(game.puzzle.solution[0])
        #expect(game.state(at: 1) == .wrong)

        game.select(0)
        game.enter(game.puzzle.solution[0])

        // Las 81 celdas tienen número, pero una está equivocada.
        #expect(game.state(at: 0) == .filled)
        #expect(game.state(at: 1) == .wrong)
        #expect(!game.isSolved)
    }

    @Test("Una vez resuelto ya no se aceptan entradas")
    func solvedGameIgnoresInput() {
        let emptyIndices = [0]
        let game = makeGame(emptyIndices: emptyIndices)

        game.select(0)
        game.enter(game.puzzle.solution[0])
        #expect(game.isSolved)

        game.enter(game.puzzle.solution[0] == 1 ? 2 : 1)

        #expect(game.mistakeCount == 0)
        #expect(game.isSolved)
    }
}
