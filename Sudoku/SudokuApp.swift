//
//  SudokuApp.swift
//  Sudoku
//
//  Created by Victor Gabriel Guerra Garza on 22/09/26.
//

import SwiftData
import SwiftUI

@main
struct SudokuApp: App {
    /// Los ajustes son de toda la app, así que viven aquí y se inyectan en todas las escenas.
    @State private var settings = GameSettings()

    /// La base de datos de récords.
    ///
    /// Se crea **una sola vez** y la comparten la ventana del juego y la de Récords. Si cada
    /// escena creara la suya con `.modelContainer(for:)`, serían dos contenedores sobre el mismo
    /// archivo y un récord recién guardado podría no aparecer en la otra ventana.
    private let recordsContainer: ModelContainer

    init() {
        do {
            recordsContainer = try ModelContainer(for: GameRecord.self)
        } catch {
            // Sin base de datos no hay forma razonable de seguir: es el mismo criterio que usan
            // las plantillas de Xcode para SwiftData.
            fatalError("No se pudo abrir la base de datos de récords: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .appEnvironment(settings)
        }
        .modelContainer(recordsContainer)
        .commands {
            GameCommands()
            HelpCommands(locale: settings.language.effectiveLocale)
        }
        #if os(macOS)
        .defaultSize(width: 520, height: 720)
        .windowResizability(.contentMinSize)
        #endif

        #if os(macOS)
        // `Window` y no `WindowGroup`: solo tiene sentido una ventana de récords, y pedirla otra
        // vez la trae al frente en lugar de abrir una segunda.
        Window("Records", id: RecordsView.windowID) {
            RecordsView()
                .appEnvironment(settings)
        }
        .modelContainer(recordsContainer)
        .defaultSize(width: 620, height: 460)

        // Esta escena añade el elemento Ajustes al menú de la app y le da ⌘, sin más código.
        Settings {
            SettingsView()
                .appEnvironment(settings)
        }
        #endif
    }
}

private extension View {
    /// Lo que necesita cada escena de la app, en un solo sitio para que las dos no se desfasen.
    func appEnvironment(_ settings: GameSettings) -> some View {
        self
            .environment(settings)
            // Poner el locale en el entorno es lo que permite cambiar de idioma sin reiniciar:
            // `Text` con clave literal se resuelve contra este valor.
            .environment(\.locale, settings.language.effectiveLocale)
            // El color del tema para las vistas propias, y el tinte para los controles del
            // sistema (botones, interruptores, el selector de dificultad).
            .environment(\.themeColor, settings.theme.color)
            .tint(settings.theme.tint)
    }
}

/// El menú **Game** de la barra de menús.
struct GameCommands: Commands {
    /// La partida de la ventana con el foco. Es `nil` si no hay ninguna ventana activa.
    @FocusedValue(\.sudokuGame) private var game
    @FocusedBinding(\.isConfirmingClearBoard) private var isConfirmingClearBoard
    /// La navegación de la ventana con el foco: dice si se ve el menú o el tablero.
    @FocusedValue(\.appNavigator) private var navigator
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // Quita el "Nueva ventana" que `WindowGroup` pone en Archivo. Sin esto, ⌘N abriría otra
        // ventana en lugar de empezar una partida.
        CommandGroup(replacing: .newItem) {}
        // Quita "Imprimir" de Archivo: el juego no imprime nada, y así ⌘P queda para la pausa.
        CommandGroup(replacing: .printItem) {}

        CommandMenu("Game") {
            Button(game?.isPaused == true ? "Resume" : "Pause") {
                game?.togglePause()
            }
            .keyboardShortcut("p")
            .disabled(!(game?.canPause ?? false))

            Divider()

            // En el tablero genera otro con la misma dificultad; en el menú de inicio, empieza con
            // la elegida en su selector, igual que su botón Nueva partida.
            Button("New Game") {
                if let game {
                    Task { await game.newGame() }
                } else {
                    navigator?.startNewGame()
                }
            }
            .keyboardShortcut("n")
            .disabled(game == nil && navigator == nil)

            // No limpia directamente: pide a la ventana que muestre la confirmación.
            Button("Clear Board") {
                isConfirmingClearBoard = true
            }
            .keyboardShortcut("r")
            .disabled(!(game?.hasProgress ?? false))

            Divider()

            // ⌘M ya es Minimizar en todas las apps de Mac, así que se usa ⇧⌘M.
            // Como el botón 🏠: solo desde el tablero, y no mientras se genera.
            Button("Back to Menu") {
                navigator?.showMenu()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            .disabled(!(navigator?.isShowingGame ?? false) || game?.isGenerating == true)

            #if DEBUG
            Divider()

            // `verbatim` para que este texto de depuración no entre en el catálogo de traducciones.
            Button {
                game?.debugFillAllButOne()
            } label: {
                Text(verbatim: "Fill All but One Cell (Debug)")
            }
            .keyboardShortcut("f", modifiers: [.command, .option])
            .disabled(game == nil)
            #endif

            #if os(macOS)
            Divider()

            Button("Records") {
                openWindow(id: RecordsView.windowID)
            }
            .keyboardShortcut("l")

            SettingsLink {
                Text("Settings…")
            }
            #endif
        }
    }
}

/// El menú **Ayuda**.
///
/// Sin esto, macOS pone un "Ayuda de Sudoku" que solo dice que no hay ayuda disponible. Aquí lleva
/// a la documentación y a los issues del repositorio en GitHub.
struct HelpCommands: Commands {
    /// El idioma de la app, para abrir el README en español o en inglés.
    let locale: Locale

    @Environment(\.openURL) private var openURL

    private static let repository = "https://github.com/vg0904/Sudoku"

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Sudoku Help") {
                let readme = locale.language.languageCode == .spanish ? "README.es.md" : "README.md"
                open("\(Self.repository)/blob/main/\(readme)")
            }
            .keyboardShortcut("?", modifiers: .command)

            Button("Report a Problem…") {
                open("\(Self.repository)/issues/new")
            }

            Divider()

            Button("View Source Code") {
                open(Self.repository)
            }
        }
    }

    private func open(_ address: String) {
        guard let url = URL(string: address) else { return }
        openURL(url)
    }
}
