//
//  ContentView.swift
//  Sudoku
//
//  Created by Victor Gabriel Guerra Garza on 22/09/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(GameSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    /// En macOS, `false` en cuanto la ventana deja de estar al frente: al cambiar de app, al
    /// minimizarla o al pasar a otra ventana (Ajustes, Récords). En otras plataformas siempre es
    /// `true`.
    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.themeColor) private var themeColor

    @State private var game = SudokuGame()
    @FocusState private var isBoardFocused: Bool
    /// Lo activan el botón de la barra y el comando ⌘R; el diálogo es el mismo para los dos.
    @State private var isConfirmingClearBoard = false

    // MARK: Récords

    /// Una partida ganada que entra en la tabla, a la espera de que se guarde.
    ///
    /// Los datos se toman **en el momento de ganar**: cuando se guarda (quizá al empezar la
    /// siguiente partida), el reloj y los errores del juego ya se habrán reiniciado.
    private struct PendingRecord {
        let time: TimeInterval
        let difficulty: Difficulty
        let lives: Int?
        let mistakes: Int
    }

    @State private var pendingRecord: PendingRecord?
    @State private var recordInfo = VictoryRecordInfo()
    @State private var playerName = ""

    /// La dificultad con la que se abre la ventana de récords. La comparte con `RecordsView`.
    @AppStorage(RecordsView.difficultyKey) private var recordsDifficultyRaw = Difficulty.medium.rawValue

    private var recordStore: RecordStore {
        RecordStore(context: modelContext)
    }

    // MARK: Partida guardada

    /// Dónde se guarda la partida en curso. Se inyecta para que las previews usen uno aislado y no
    /// pisen la partida guardada de verdad.
    private let savedGameStore: SavedGameStore

    init(savedGameStore: SavedGameStore = SavedGameStore()) {
        self.savedGameStore = savedGameStore
    }

    /// Los caracteres que Mac puede enviar al pulsar ⌫ o ⌦.
    private static let deleteCharacters = CharacterSet(charactersIn: "\u{8}\u{7F}\u{F728}")

    var body: some View {
        VStack(spacing: 18) {
            header

            BoardView(game: game, settings: settings)
                // En pausa el tablero se oculta del todo, no solo se tapa: si se viera, se podría
                // pensar la siguiente jugada con el reloj parado. Por lo mismo, VoiceOver tampoco
                // lo lee.
                .opacity(game.isPaused ? 0 : 1)
                .accessibilityHidden(game.isPaused)
                .overlay { if game.isGenerating { generatingOverlay } }
                .overlay { if game.isPaused { pausedOverlay } }
                .animation(.easeInOut(duration: 0.2), value: game.isPaused)

            NumberPadView(game: game, settings: settings) { isBoardFocused = true }
        }
        .padding(20)
        .frame(minWidth: 460, minHeight: 640)
        .toolbar { toolbarContent }
        #if os(macOS)
        // Sin el título caben todos los botones sin que ninguno acabe escondido en el menú
        // desplegable. El nombre de la ventana se sigue viendo en el menú Ventana y lo sigue
        // leyendo VoiceOver: es un cambio solo visual.
        .toolbar(removing: .title)
        #endif
        .confirmationDialog("Clear the board?", isPresented: $isConfirmingClearBoard) {
            Button("Clear Board", role: .destructive) {
                game.restart()
                isBoardFocused = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your numbers and mistakes will be erased. The board stays the same.")
        }
        // El contenedor entero es el que recibe el teclado, así que los clics en los botones no
        // sacan el foco del juego.
        .focusable()
        .focusEffectDisabled()
        .focused($isBoardFocused)
        .onKeyPress(characters: .decimalDigits, phases: .down) { press in
            guard let digit = press.characters.first?.wholeNumberValue,
                  (1...SudokuGrid.size).contains(digit)
            else { return .ignored }

            game.enter(digit)
            return .handled
        }
        .onKeyPress(.upArrow) { game.moveSelection(rowDelta: -1, columnDelta: 0); return .handled }
        .onKeyPress(.downArrow) { game.moveSelection(rowDelta: 1, columnDelta: 0); return .handled }
        .onKeyPress(.leftArrow) { game.moveSelection(rowDelta: 0, columnDelta: -1); return .handled }
        .onKeyPress(.rightArrow) { game.moveSelection(rowDelta: 0, columnDelta: 1); return .handled }
        // La tecla ⌫ de Mac no llega como `KeyEquivalent.delete`: esa constante es el backspace
        // (U+0008), mientras que el sistema manda `NSDeleteCharacter` (U+007F). Se aceptan los dos
        // códigos, más ⌦ (U+F728), para que borrar funcione con cualquiera.
        .onKeyPress(characters: Self.deleteCharacters, phases: .down) { _ in
            game.clearSelection()
            return .handled
        }
        #if os(macOS)
        // La ruta oficial de macOS para el comando Borrar, que cubre ⌫ y ⌦ además del menú
        // Edición. Es el respaldo por si el mapeo de caracteres cambia.
        .onDeleteCommand { game.clearSelection() }
        #endif
        // Deja que los comandos del menú (⌘N, ⌘R) alcancen esta partida.
        .focusedSceneValue(\.sudokuGame, game)
        .focusedSceneValue(\.isConfirmingClearBoard, $isConfirmingClearBoard)
        .overlay { outcomeOverlay }
        // El confeti va por encima de la tarjeta de victoria y llega hasta el borde de la
        // ventana, pasando por detrás de la barra de herramientas.
        .overlay {
            // Sin movimiento no hay confeti: es solo movimiento. La tarjeta de victoria ya
            // comunica que se ganó.
            if game.isSolved && !settings.reduceEffects && !systemReduceMotion {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .animation(.spring(duration: 0.35), value: game.isSolved)
        .animation(.spring(duration: 0.35), value: game.isDefeated)
        // Al ganar se prepara el récord; al dejar de estar resuelta (otra partida, cambiar de
        // dificultad, ⌘N…) se guarda si quedó pendiente. Vigilar este cambio cubre todos los
        // caminos a la vez, en lugar de acordarse de guardar en cada botón.
        // Pausa automática al dejar la ventana. No se reanuda sola al volver: la pausa tapa el
        // tablero, y quien juega decide cuándo seguir.
        .onChange(of: appearsActive) { _, isActive in
            if !isActive {
                game.pause()
            }
        }
        .onChange(of: game.isSolved) { _, isSolved in
            if isSolved {
                prepareRecord()
            } else {
                savePendingRecord()
                pendingRecord = nil
            }
        }
        .task {
            // Si hay una partida a medias, se retoma (en pausa). Si no, se empieza una nueva.
            if let saved = savedGameStore.load(), game.restore(saved) {
                isBoardFocused = true
                return
            }

            game.maxLives = settings.maxLives
            await game.newGame(difficulty: game.difficulty)
            isBoardFocused = true
        }
        .onChange(of: game.difficulty) { _, newDifficulty in
            // Solo cuando cambia la dificultad del selector. Al retomar una partida guardada,
            // `difficulty` también cambia, pero ya coincide con la del tablero y no hay que generar
            // otro.
            guard newDifficulty != game.puzzle.difficulty else { return }
            Task { await game.newGame(difficulty: newDifficulty) }
        }
        // Guarda tras cada jugada, borrado, pausa o partida nueva. Si la partida acaba de
        // terminar, `snapshot()` es `nil` y la foto guardada se borra.
        .onChange(of: game.saveRevision) {
            savedGameStore.save(game.snapshot())
        }
        #if os(macOS)
        // Al salir con ⌘Q la ventana no llega a perder el foco, así que no se pausa sola: se pausa
        // y se guarda aquí para no perder los segundos jugados desde la última jugada.
        .task {
            for await _ in NotificationCenter.default.notifications(named: NSApplication.willTerminateNotification) {
                game.pause()
                savedGameStore.save(game.snapshot())
            }
        }
        #endif
        // Cambiar las vidas obliga a empezar de nuevo, y es el único ajuste que lo hace: los demás
        // se aplican en vivo porque no alteran el estado del tablero. La confirmación ya se pidió
        // en la ventana de ajustes.
        .onChange(of: settings.maxLives) { _, newMaxLives in
            game.maxLives = newMaxLives
            Task { await game.newGame() }
        }
        // El modelo solo dice qué celebrar; cuánto dura se decide aquí. Si la partida cambia a
        // mitad, SwiftUI cancela esta espera sola.
        .task(id: game.celebration?.id) {
            guard let celebration = game.celebration else { return }

            // Lo que tarda la onda en cruzar el grupo, más la animación de la última celda. Cada
            // estilo dura distinto, así que lo calcula el propio estilo.
            let total = settings.celebrationStyle.totalDuration(cellCount: celebration.indices.count)
            try? await Task.sleep(for: .seconds(total))

            game.endCelebration()
        }
    }

    // MARK: - Secciones

    /// Los controles de la partida viven en la barra de la ventana, como en cualquier app de Mac.
    /// Así el contenido queda solo para jugar y el tablero gana espacio.
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // En macOS, `.principal` centra el elemento en la barra.
        ToolbarItem(placement: .principal) {
            Picker("Difficulty", selection: $game.difficulty) {
                ForEach(Difficulty.allCases) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .disabled(game.isGenerating)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            Button(
                game.isPaused ? "Resume" : "Pause",
                systemImage: game.isPaused ? "play.fill" : "pause.fill",
                action: togglePause
            )
            .help(game.isPaused ? "Resume the game" : "Pause the game and hide the board")
            .disabled(!game.canPause)

            Button("Clear Board", systemImage: "arrow.counterclockwise") {
                isConfirmingClearBoard = true
            }
            .help("Clears your numbers and the counter, keeping the same board")
            .disabled(game.isGenerating || !game.hasProgress)

            Button("New Game", systemImage: "plus") {
                Task { await game.newGame() }
            }
            .help("Start a new board")
            .disabled(game.isGenerating)
        }

        #if os(macOS)
        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItemGroup(placement: .primaryAction) {
            Button("Records", systemImage: "trophy", action: showRecords)
                .help("Records")

            // `SettingsLink` abre la misma ventana que ⌘, sin tener que presentar nada a mano.
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .help("Settings")
        }
        #endif
    }

    private var header: some View {
        HStack {
            if settings.showTimer {
                TimerLabel(clock: game.clock, isPaused: game.isPaused)
            }

            Spacer()

            livesIndicator
        }
    }

    /// Corazones cuando hay un límite de errores; si no, el contador de siempre.
    @ViewBuilder
    private var livesIndicator: some View {
        if let livesRemaining = game.livesRemaining, let maxLives = game.maxLives {
            HeartsView(
                livesRemaining: livesRemaining,
                maxLives: maxLives,
                mistakeCount: game.mistakeCount,
                reduceEffects: settings.reduceEffects
            )
        } else {
            Label("\(game.mistakeCount)", systemImage: "xmark.circle")
                .font(.title3.monospacedDigit())
                .foregroundStyle(game.mistakeCount > 0 ? .red : .secondary)
                .help("Mistakes made")
        }
    }

    // MARK: - Superposiciones

    /// Lo que ocupa el sitio del tablero mientras la partida está en pausa.
    private var pausedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(themeColor)

            Text("Paused")
                .font(.title.bold())

            Text("The board is hidden and the clock is stopped.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Resume", action: togglePause)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
        .transition(.opacity)
    }

    private var generatingOverlay: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            ProgressView("Generating board…")
        }
        .clipShape(.rect(cornerRadius: 10))
    }

    @ViewBuilder
    private var outcomeOverlay: some View {
        if game.isSolved {
            VictoryOverlay(
                elapsed: game.clock.elapsed(at: .now),
                mistakeCount: game.mistakeCount,
                record: recordInfo,
                playerName: $playerName,
                onSaveRecord: savePendingRecord,
                onShowRecords: showRecords
            ) {
                Task { await game.newGame() }
            }
        } else if game.isDefeated {
            DefeatOverlay(elapsed: game.clock.elapsed(at: .now)) {
                game.restart()
                isBoardFocused = true
            } onNewGame: {
                Task { await game.newGame() }
            }
        }
    }

    // MARK: - Récords

    /// Mira si la partida recién ganada entra en la tabla y prepara la tarjeta de victoria.
    private func prepareRecord() {
        let store = recordStore
        let time = game.clock.elapsed(at: .now)
        let rank = game.isEligibleForRecords
            ? store.rank(for: time, difficulty: game.difficulty)
            : nil

        recordInfo = VictoryRecordInfo(
            rank: rank,
            previousBest: store.bestTime(for: game.difficulty),
            knownNames: store.playerNames
        )
        // Como en las recreativas, ya viene escrito el nombre del último récord.
        playerName = store.lastPlayerName ?? ""

        pendingRecord = rank == nil ? nil : PendingRecord(
            time: time,
            difficulty: game.difficulty,
            lives: game.maxLives,
            mistakes: game.mistakeCount
        )
    }

    /// Guarda el récord pendiente, si lo hay y no se guardó ya.
    private func savePendingRecord() {
        guard let pendingRecord, !recordInfo.isSaved else { return }

        do {
            try recordStore.save(
                playerName: playerName,
                time: pendingRecord.time,
                difficulty: pendingRecord.difficulty,
                lives: pendingRecord.lives,
                mistakes: pendingRecord.mistakes
            )
            recordInfo.isSaved = true
            // Muestra el nombre tal como quedó guardado (sin espacios, o "???").
            playerName = recordStore.lastPlayerName ?? playerName
        } catch {
            // Si la base de datos falla, la partida sigue sin récord: no merece interrumpir.
            // La tarjeta no dirá "guardado", así que no engaña.
        }
    }

    /// Pausa o reanuda. Al reanudar, el foco vuelve al tablero para seguir con el teclado.
    private func togglePause() {
        game.togglePause()
        if !game.isPaused {
            isBoardFocused = true
        }
    }

    /// Abre la ventana de récords en la dificultad de la partida actual.
    private func showRecords() {
        recordsDifficultyRaw = game.difficulty.rawValue
        openWindow(id: RecordsView.windowID)
    }
}

#Preview {
    ContentView(savedGameStore: SavedGameStore(defaults: UserDefaults(suiteName: "preview") ?? .standard))
        .environment(GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
        // En memoria: los récords de la preview no se mezclan con los de verdad.
        .modelContainer(for: GameRecord.self, inMemory: true)
}
