//
//  StartMenuView.swift
//  Sudoku
//

import SwiftUI

/// La pantalla con la que se abre la app: el logo y lo que se puede hacer.
struct StartMenuView: View {
    @Environment(GameSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.openWindow) private var openWindow
    @Environment(AppNavigator.self) private var navigator

    /// De dónde se lee la partida guardada, para ofrecer "Continuar".
    let savedGameStore: SavedGameStore

    /// Se lee al aparecer y no una sola vez en el `init`: al volver del tablero, la partida
    /// guardada puede haber cambiado o desaparecido (si se terminó).
    @State private var savedGame: SavedGame?
    /// Activa la animación de entrada.
    @State private var hasAppeared = false

    private var reduceMotion: Bool {
        settings.reduceEffects || systemReduceMotion
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    // Una sombra suave lo despega del fondo. Hace falta sobre todo en modo claro,
                    // donde el icono blanco se confundía con la ventana. Sigue la silueta del PNG
                    // porque tiene transparencia alrededor de las esquinas redondeadas.
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                    // El título de debajo ya dice lo mismo; el logo es decorativo.
                    .accessibilityHidden(true)
                    // Con Reduce Motion solo aparece, sin crecer.
                    .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.85)

                // El nombre de la app no se traduce, así que no entra en el catálogo.
                Text(verbatim: "Sudoku")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
            }
            .opacity(hasAppeared ? 1 : 0)

            // Estilos normales del sistema, no Liquid Glass: estos botones son el contenido de la
            // pantalla y no flotan sobre nada, y la HIG pide no usar vidrio en la capa de contenido.
            // El vidrio aparece solo en la barra de la ventana, que es su sitio.
            VStack(spacing: 14) {
                continueButton
                newGameSection
            }
            .frame(maxWidth: 280)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared || reduceMotion ? 0 : 12)

            Spacer()
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        // El mismo mínimo que el tablero, para que la ventana no cambie de tamaño al pasar de uno
        // a otro.
        .frame(minWidth: 460, minHeight: 640)
        // Récords y Ajustes van en la barra, en el mismo sitio que durante la partida. El sistema
        // les da Liquid Glass automáticamente.
        .toolbar {
            // Sin nada en el centro, macOS pegaría los botones al inicio de la barra, junto a los
            // de la ventana. El espaciador los empuja al final, donde están en la partida.
            ToolbarSpacer(.flexible)

            ToolbarItemGroup(placement: .primaryAction) {
                Button("Records", systemImage: "trophy") {
                    openWindow(id: RecordsView.windowID)
                }
                .help("Records")

                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Settings")
            }
        }
        // Como en el tablero: sin título, la barra queda limpia. VoiceOver y el menú Ventana lo
        // siguen mostrando.
        .toolbar(removing: .title)
        #endif
        .onAppear {
            savedGame = savedGameStore.load()

            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(duration: 0.6)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Secciones

    /// Va primero y destacado: si hay una partida a medias, lo más probable es querer seguirla.
    ///
    /// Sin partida guardada sigue ahí, pero desactivado y en gris. Así el menú no cambia de forma
    /// según el caso, y se ve que "Continuar" existe aunque ahora no haya nada que continuar.
    @ViewBuilder
    private var continueButton: some View {
        // Desactivado con el estilo destacado se vería azul claro: parecería un segundo botón
        // principal. Con el normal, el sistema lo pinta gris y Nueva partida queda como el único
        // destacado, que es lo que pide la HIG.
        if savedGame == nil {
            continueButtonBase
                .buttonStyle(.bordered)
                .disabled(true)
        } else {
            continueButtonBase
                .buttonStyle(.borderedProminent)
                // ↩ es de este botón solo si hay algo que continuar; si no, se lo lleva Nueva
                // partida.
                .keyboardShortcut(.defaultAction)
        }
    }

    private var continueButtonBase: some View {
        Button {
            guard let savedGame else { return }
            navigator.start(.resume(savedGame))
        } label: {
            VStack(spacing: 2) {
                Text("Continue")
                    .font(.headline)
                Group {
                    if let savedGame {
                        HStack(spacing: 4) {
                            Text(savedGame.difficulty.displayName)
                            Text(verbatim: "·")
                            Text(TimerLabel.format(savedGame.elapsed))
                                .monospacedDigit()
                        }
                    } else {
                        Text("No game in progress")
                    }
                }
                .font(.subheadline)
                .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.extraLarge)
    }

    private var newGameSection: some View {
        // `@Bindable` convierte la propiedad del modelo en un `Binding` para el selector.
        @Bindable var navigator = navigator

        return VStack(spacing: 10) {
            Picker("Difficulty", selection: $navigator.menuDifficulty) {
                ForEach(Difficulty.allCases) { difficulty in
                    Text(difficulty.displayName).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Sin partida guardada, empezar una es la acción principal y se lleva ↩.
            if savedGame == nil {
                newGameButton
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            } else {
                newGameButton
                    .buttonStyle(.bordered)
            }
        }
    }

    private var newGameButton: some View {
        // Lo mismo que ⌘N en el menú Partida.
        Button(action: navigator.startNewGame) {
            Text("New Game")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .controlSize(.extraLarge)
    }
}

#Preview("Sin partida guardada") {
    StartMenuView(savedGameStore: previewStore(withSavedGame: false))
        .environment(GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
        .environment(AppNavigator(defaults: UserDefaults(suiteName: "preview") ?? .standard))
}

#Preview("Con partida guardada") {
    StartMenuView(savedGameStore: previewStore(withSavedGame: true))
        .environment(GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
        .environment(AppNavigator(defaults: UserDefaults(suiteName: "preview") ?? .standard))
}

/// Un almacén aislado para las previews, vacío o con una partida difícil a medias.
private func previewStore(withSavedGame: Bool) -> SavedGameStore {
    let suite = withSavedGame ? "preview.menu.saved" : "preview.menu.empty"
    let store = SavedGameStore(defaults: UserDefaults(suiteName: suite) ?? .standard)

    guard withSavedGame else {
        store.save(nil)
        return store
    }

    // Generar un tablero de verdad tarda demasiado en Debug para una preview. Esta fórmula da una
    // solución válida al instante; el menú solo mira la dificultad y el tiempo.
    let solution = (0..<SudokuGrid.cellCount).map { index in
        let row = index / 9, column = index % 9
        return (row * 3 + row / 3 + column) % 9 + 1
    }
    store.save(SavedGame(
        board: Array(repeating: 0, count: SudokuGrid.cellCount),
        solution: solution,
        difficulty: .hard,
        entries: Array(repeating: 0, count: SudokuGrid.cellCount),
        wrongIndices: [],
        mistakeCount: 0,
        elapsed: 204,
        maxLives: 3,
        selectedIndex: nil,
        isEligibleForRecords: true
    ))
    return store
}
