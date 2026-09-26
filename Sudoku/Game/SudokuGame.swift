//
//  SudokuGame.swift
//  Sudoku
//

import Foundation

/// Cómo debe dibujarse una celda. La vista lee esto y no reimplementa nada de la lógica.
nonisolated enum CellState: Equatable, Sendable {
    /// Pista del tablero original: no se puede modificar.
    case given
    case empty
    /// Entrada correcta de quien juega.
    case filled
    /// Entrada que no coincide con la solución.
    case wrong
}

/// Un error recién cometido, para que la vista sacuda la celda.
///
/// Lleva un `id` además de la celda porque escribir dos veces el mismo número equivocado en la
/// misma celda no cambia nada más: sin el id, la vista no vería la segunda jugada y no volvería a
/// sacudir.
nonisolated struct Mistake: Equatable, Sendable {
    let id: Int
    let index: Int
}

/// El estado de una partida: el tablero, lo que se ha escrito y los errores cometidos.
///
/// Es la única fuente de verdad para las vistas. No sabe nada de SwiftUI más allá de ser
/// `@Observable`.
@Observable
@MainActor
final class SudokuGame {
    /// El tablero actual y su solución.
    private(set) var puzzle: Puzzle = .placeholder

    /// Lo que ha escrito quien juega, separado de las pistas para poder borrarlo sin perder el
    /// tablero. `0` significa celda vacía, igual que en `SudokuGrid`.
    private(set) var entries: [Int] = Array(repeating: 0, count: SudokuGrid.cellCount)

    /// Celdas cuyo valor actual no coincide con la solución.
    private(set) var wrongIndices: Set<Int> = []

    /// Total de números incorrectos escritos en esta partida.
    private(set) var mistakeCount = 0

    /// El último error, o `nil` si todavía no hay ninguno en esta partida.
    private(set) var lastMistake: Mistake?

    /// `false` si la partida se ha ayudado con el atajo de depuración: así las pruebas no llenan la
    /// tabla de récords con tiempos imposibles.
    private(set) var isEligibleForRecords = true

    /// `true` mientras la partida está en pausa: el reloj no corre y no se aceptan jugadas.
    private(set) var isPaused = false

    /// `true` mientras se construye un tablero nuevo.
    private(set) var isGenerating = false

    /// Cuánto se lleva jugando. Arranca cuando el tablero está listo y se detiene al resolverlo.
    private(set) var clock = GameClock()

    /// El grupo que se acaba de completar, o `nil` si no hay nada que celebrar.
    ///
    /// La vista la consume y llama a `endCelebration()` cuando termina la animación.
    private(set) var celebration: Celebration?

    /// Da ids crecientes a las celebraciones.
    private var celebrationCount = 0

    var selectedIndex: Int?
    var difficulty: Difficulty = .medium

    /// Cuántos errores se permiten antes de perder, o `nil` para jugar sin límite.
    ///
    /// Lo fija la configuración. Con `nil` el juego se comporta como antes de haber vidas: los
    /// errores se cuentan pero nunca se pierde.
    var maxLives: Int?

    /// Crea una partida vacía. Llama a `newGame(difficulty:)` para tener algo jugable.
    init(maxLives: Int? = nil) {
        self.maxLives = maxLives
    }

    /// Crea una partida con un tablero ya conocido, sin generar nada.
    ///
    /// Lo usan las pruebas y las previews para no pagar el coste del generador.
    init(puzzle: Puzzle, maxLives: Int? = nil) {
        self.puzzle = puzzle
        self.difficulty = puzzle.difficulty
        self.selectedIndex = puzzle.board.firstEmptyIndex()
        self.maxLives = maxLives
    }

    // MARK: - Consultas

    /// El valor visible en una celda: la pista si la hay, si no lo que se escribió.
    func value(at index: Int) -> Int {
        let given = puzzle.board[index]
        return given != 0 ? given : entries[index]
    }

    /// `true` si la celda es una pista del tablero original.
    func isGiven(_ index: Int) -> Bool {
        puzzle.board[index] != 0
    }

    func state(at index: Int) -> CellState {
        if isGiven(index) { return .given }
        if wrongIndices.contains(index) { return .wrong }
        return entries[index] == 0 ? .empty : .filled
    }

    /// `true` si se puede escribir en la celda: está vacía o tiene un error por corregir.
    ///
    /// Una respuesta correcta queda fija, igual que una pista. Así un número tecleado por
    /// accidente no puede sobrescribirla, ni costar un error o una vida.
    func isEditable(_ index: Int) -> Bool {
        switch state(at: index) {
        case .empty, .wrong: true
        case .given, .filled: false
        }
    }

    /// `true` si la celda seleccionada tiene un error que se puede borrar.
    ///
    /// Solo se borran errores: las respuestas correctas están bloqueadas y una celda vacía no
    /// tiene nada que borrar.
    var canClearSelection: Bool {
        guard let selectedIndex else { return false }
        return state(at: selectedIndex) == .wrong
    }

    /// `true` si limpiar el tablero haría perder algo: números escritos o errores contados.
    var hasProgress: Bool {
        mistakeCount > 0 || entries.contains { $0 != 0 }
    }

    /// Corazones que quedan, o `nil` si se juega sin límite de errores.
    var livesRemaining: Int? {
        guard let maxLives else { return nil }
        return max(0, maxLives - mistakeCount)
    }

    /// `true` cuando se han agotado los corazones.
    var isDefeated: Bool {
        livesRemaining == 0
    }

    /// `true` cuando el tablero está completo y sin errores pendientes.
    var isSolved: Bool {
        // `puzzle.solution.isComplete` descarta el placeholder: sin partida real no hay victoria.
        guard puzzle.solution.isComplete, wrongIndices.isEmpty else { return false }
        return !(0..<SudokuGrid.cellCount).contains { value(at: $0) == 0 }
    }

    /// Fila, columna y caja de la celda seleccionada, para resaltarlas.
    var highlightedIndices: Set<Int> {
        guard let selectedIndex else { return [] }
        return SudokuGrid.relatedIndices(of: selectedIndex)
    }

    /// El número visible en la celda seleccionada, o `0` si está vacía o no hay selección.
    var selectedValue: Int {
        guard let selectedIndex else { return 0 }
        return value(at: selectedIndex)
    }

    /// Cuántas veces está bien colocado un número, contando las pistas.
    ///
    /// Solo cuenta aciertos: un 5 escrito donde no va no acerca a completar el 5. Si contara
    /// cualquier 5 visible, la paloma del teclado numérico mentiría.
    func placedCount(of number: Int) -> Int {
        guard (1...SudokuGrid.size).contains(number) else { return 0 }

        return (0..<SudokuGrid.cellCount).count { index in
            puzzle.solution[index] == number && value(at: index) == number
        }
    }

    /// `true` cuando las nueve apariciones de un número ya están colocadas correctamente.
    ///
    /// A partir de ese momento escribirlo otra vez solo podría ser un error, así que el juego
    /// deja de aceptarlo — tanto desde el teclado numérico como desde el teclado físico.
    func isValueComplete(_ number: Int) -> Bool {
        placedCount(of: number) == SudokuGrid.size
    }

    /// Las celdas que muestran el mismo número que la seleccionada, ella incluida.
    ///
    /// Es la ayuda visual clásica del Sudoku: al tocar un 5 se ven de golpe todos los 5 ya
    /// colocados. Da `[]` si la celda seleccionada está vacía, porque entonces no hay nada que
    /// emparejar.
    var matchingValueIndices: Set<Int> {
        let target = selectedValue
        guard target != 0 else { return [] }

        return Set((0..<SudokuGrid.cellCount).filter { value(at: $0) == target })
    }

    // MARK: - Partidas

    /// Genera un tablero nuevo con la dificultad indicada.
    ///
    /// El parámetro `now` existe para que las pruebas controlen el cronómetro; en la app se deja
    /// con su valor por defecto.
    func newGame(difficulty: Difficulty, now: Date = .now) async {
        self.difficulty = difficulty
        isGenerating = true
        clock.reset()

        // Vaciar celdas verificando unicidad obliga a resolver el tablero miles de veces. En Debug
        // (`-Onone`) eso tarda lo suficiente para congelar la ventana, así que `Task.detached` lo
        // saca del main actor. Hace falta ser explícito: este proyecto compila con
        // SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor.
        let generated = await Task.detached(priority: .userInitiated) {
            SudokuGenerator.makePuzzle(difficulty: difficulty)
        }.value

        puzzle = generated
        selectedIndex = generated.board.firstEmptyIndex()
        isGenerating = false

        // El reloj arranca aquí y no antes: el tiempo de generación no es tiempo de juego.
        resetProgress(now: now)
    }

    /// Genera un tablero nuevo conservando la dificultad actual.
    func newGame() async {
        await newGame(difficulty: difficulty)
    }

    /// Borra todo lo escrito y el contador de errores, **conservando el mismo tablero**.
    func restart(now: Date = .now) {
        resetProgress(now: now)
        selectedIndex = puzzle.board.firstEmptyIndex()
    }

    private func resetProgress(now: Date) {
        entries = Array(repeating: 0, count: SudokuGrid.cellCount)
        wrongIndices = []
        mistakeCount = 0
        lastMistake = nil
        isEligibleForRecords = true
        isPaused = false
        celebration = nil
        clock.restart(at: now)
    }

    // MARK: - Pausa

    /// `true` si hay una partida en marcha que se pueda pausar.
    ///
    /// No se pausa mientras se genera el tablero (el reloj aún no corre) ni con la partida
    /// terminada (el reloj ya se detuvo).
    var canPause: Bool {
        puzzle.solution.isComplete && !isGenerating && !isSolved && !isDefeated
    }

    /// Detiene el reloj y bloquea las jugadas. No hace nada si no se puede pausar o ya lo está.
    func pause(now: Date = .now) {
        guard canPause, !isPaused else { return }
        isPaused = true
        clock.stop(at: now)
    }

    /// Vuelve a poner en marcha el reloj desde donde se quedó.
    func resume(now: Date = .now) {
        guard isPaused else { return }
        isPaused = false
        clock.start(at: now)
    }

    func togglePause(now: Date = .now) {
        isPaused ? resume(now: now) : pause(now: now)
    }

    // MARK: - Jugadas

    func select(_ index: Int) {
        guard !isPaused, (0..<SudokuGrid.cellCount).contains(index) else { return }
        selectedIndex = index
    }

    /// Escribe un número en la celda seleccionada.
    ///
    /// Un valor que no coincide con la solución cuenta como error y **se queda visible en rojo**
    /// para poder corregirlo. Cada intento erróneo cuenta, incluso repetido en la misma celda.
    func enter(_ value: Int, now: Date = .now) {
        guard !isPaused,
              (1...SudokuGrid.size).contains(value),
              let index = selectedIndex,
              isEditable(index),
              !isSolved,
              !isDefeated,
              // Un número ya completo no se acepta desde ninguna vía, para que el teclado y el
              // botón con la paloma se comporten igual.
              !isValueComplete(value)
        else { return }

        entries[index] = value

        if value == puzzle.solution[index] {
            wrongIndices.remove(index)
            detectCompletedGroups(at: index)
        } else {
            mistakeCount += 1
            wrongIndices.insert(index)
            // El contador sirve de id: sube con cada error y nunca se repite dentro de la partida.
            lastMistake = Mistake(id: mistakeCount, index: index)
        }

        // El reloj se detiene tanto al ganar como al perder: en ambos casos la partida terminó.
        if isSolved || isDefeated {
            clock.stop(at: now)
        }
    }

    /// Cierra la celebración en curso. La llama la vista cuando acaba la animación.
    func endCelebration() {
        celebration = nil
    }

    // MARK: - Grupos completados

    /// Publica una celebración si la jugada en `index` acaba de cerrar su fila, columna o caja, o
    /// de colocar la novena aparición de su número.
    private func detectCompletedGroups(at index: Int) {
        let row = SudokuGrid.row(of: index)
        let column = SudokuGrid.column(of: index)
        let box = SudokuGrid.box(of: index)

        var groups: [Celebration.Group] = []
        var candidates: [Int] = []

        let rowIndices = SudokuGrid.rowIndices(row)
        if isGroupComplete(rowIndices) {
            groups.append(.row(row))
            candidates += rowIndices
        }

        let columnIndices = SudokuGrid.columnIndices(column)
        if isGroupComplete(columnIndices) {
            groups.append(.column(column))
            candidates += columnIndices
        }

        let boxIndices = SudokuGrid.boxIndices(box)
        if isGroupComplete(boxIndices) {
            groups.append(.box(box))
            candidates += boxIndices
        }

        // Siempre es una novedad: la celda era editable, así que antes de esta jugada el número
        // tenía como mucho ocho colocadas.
        let number = puzzle.solution[index]
        if isValueComplete(number) {
            groups.append(.number(number))
            candidates += (0..<SudokuGrid.cellCount).filter { puzzle.solution[$0] == number }
        }

        guard !groups.isEmpty else { return }

        celebrationCount += 1
        celebration = Celebration(
            id: celebrationCount,
            groups: groups,
            indices: waveOrder(of: candidates, from: index)
        )
    }

    /// `true` si las nueve celdas del grupo tienen ya su valor correcto.
    ///
    /// Comparar contra la solución resuelve las dos condiciones de una vez: una celda vacía vale
    /// `0` y nunca coincide, y una equivocada tampoco. Por eso un grupo con un error **no** se
    /// celebra.
    private func isGroupComplete(_ indices: [Int]) -> Bool {
        indices.allSatisfy { value(at: $0) == puzzle.solution[$0] }
    }

    /// Quita repetidos y ordena por distancia a la celda jugada, para que la onda salga de ahí.
    ///
    /// Cerrar una fila y una caja a la vez comparte tres celdas; sin deduplicar se animarían dos
    /// veces.
    private func waveOrder(of indices: [Int], from origin: Int) -> [Int] {
        let originRow = SudokuGrid.row(of: origin)
        let originColumn = SudokuGrid.column(of: origin)

        func distance(to index: Int) -> Int {
            abs(SudokuGrid.row(of: index) - originRow)
                + abs(SudokuGrid.column(of: index) - originColumn)
        }

        var seen = Set<Int>()
        let unique = indices.filter { seen.insert($0).inserted }

        return unique.sorted { distance(to: $0) < distance(to: $1) }
    }

    #if DEBUG
    /// Solo en depuración: rellena bien todas las celdas editables menos una y la selecciona.
    ///
    /// Sirve para probar lo que pasa al ganar (la tarjeta, el confeti) sin resolver un tablero
    /// entero. No pasa por `enter`, así que no cuenta errores ni dispara celebraciones de grupo.
    /// Dentro de `#if DEBUG` no llega a la versión que se distribuye.
    func debugFillAllButOne() {
        let editable = (0..<SudokuGrid.cellCount).filter(isEditable)
        guard let last = editable.last else { return }

        isEligibleForRecords = false
        for index in editable.dropLast() {
            entries[index] = puzzle.solution[index]
            wrongIndices.remove(index)
        }
        selectedIndex = last
    }
    #endif

    /// Borra el error de la celda seleccionada. Sobre cualquier otra celda no hace nada.
    func clearSelection() {
        guard !isPaused, canClearSelection, let index = selectedIndex else { return }
        entries[index] = 0
        wrongIndices.remove(index)
    }

    /// Mueve la selección por el tablero, sin salirse de los bordes.
    func moveSelection(rowDelta: Int, columnDelta: Int) {
        guard !isPaused else { return }
        guard let current = selectedIndex else {
            selectedIndex = 0
            return
        }

        let last = SudokuGrid.size - 1
        let row = min(max(SudokuGrid.row(of: current) + rowDelta, 0), last)
        let column = min(max(SudokuGrid.column(of: current) + columnDelta, 0), last)
        selectedIndex = SudokuGrid.index(row: row, column: column)
    }
}
