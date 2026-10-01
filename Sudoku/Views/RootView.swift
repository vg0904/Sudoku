//
//  RootView.swift
//  Sudoku
//

import SwiftData
import SwiftUI

/// Alterna entre el menú de inicio y el tablero.
struct RootView: View {
    @Environment(GameSettings.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// Uno por ventana: cada ventana tiene su propia pantalla y su propia partida.
    @State private var navigator: AppNavigator

    /// Lo comparten el menú (para ofrecer "Continuar") y el tablero (para guardar).
    private let savedGameStore: SavedGameStore

    /// - Parameter navigator: para las previews, con un `UserDefaults` aislado. Es opcional y se
    ///   crea dentro porque un argumento por defecto se evalúa fuera del main actor, y
    ///   `AppNavigator` vive en él.
    init(savedGameStore: SavedGameStore = SavedGameStore(), navigator: AppNavigator? = nil) {
        self.savedGameStore = savedGameStore
        _navigator = State(initialValue: navigator ?? AppNavigator())
    }

    var body: some View {
        Group {
            switch navigator.screen {
            case .menu:
                StartMenuView(savedGameStore: savedGameStore)
            case .game(let start):
                // Cada vez que se entra al tablero es una vista nueva, con su propia partida: al
                // volver al menú, la anterior ya quedó guardada.
                ContentView(start: start, savedGameStore: savedGameStore)
            }
        }
        .transition(.opacity)
        .animation(settings.reduceEffects || systemReduceMotion ? nil : .easeInOut(duration: 0.25), value: navigator.screen)
        .environment(navigator)
        // Para los comandos del menú Partida (⌘N, ⇧⌘M).
        .focusedSceneValue(\.appNavigator, navigator)
    }
}

#Preview {
    RootView(
        savedGameStore: SavedGameStore(defaults: UserDefaults(suiteName: "preview") ?? .standard),
        navigator: AppNavigator(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    )
    .environment(GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
    .modelContainer(for: GameRecord.self, inMemory: true)
}
