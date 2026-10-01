//
//  AppNavigator.swift
//  Sudoku
//

import Foundation
import Observation

/// Cómo empieza la partida que se abre desde el menú.
nonisolated enum GameStart: Equatable, Sendable {
    /// Retoma la partida guardada.
    case resume(SavedGame)
    /// Genera un tablero nuevo con esta dificultad.
    case new(Difficulty)
}

/// Qué pantalla muestra la ventana: el menú de inicio o el tablero.
///
/// Es una clase `@Observable` y no un par de closures porque los comandos de la barra de menús
/// llegan a ella con `FocusedValues`, y SwiftUI no sabe comparar closures: daría el valor por
/// cambiado en cada actualización y volvería a evaluar los menús sin motivo. Una clase se compara
/// por identidad, así que mientras sea la misma ventana el valor es estable.
@Observable
@MainActor
final class AppNavigator {
    enum Screen: Equatable {
        case menu
        case game(GameStart)
    }

    private enum Key {
        static let menuDifficulty = "menu.difficulty"
    }

    private let defaults: UserDefaults

    private(set) var screen = Screen.menu

    /// La dificultad del selector del menú. Se recuerda entre sesiones para no tener que elegirla
    /// cada vez.
    var menuDifficulty: Difficulty {
        didSet { defaults.set(menuDifficulty.rawValue, forKey: Key.menuDifficulty) }
    }

    /// Recibe el `UserDefaults`, como `GameSettings`, para que las pruebas usen uno aislado.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        menuDifficulty = defaults.string(forKey: Key.menuDifficulty).flatMap(Difficulty.init) ?? .medium
    }

    var isShowingGame: Bool {
        if case .game = screen { true } else { false }
    }

    /// Abre el tablero. Lo usan los botones del menú.
    func start(_ start: GameStart) {
        screen = .game(start)
    }

    /// Empieza una partida con la dificultad del selector: el botón Nueva partida del menú y ⌘N.
    func startNewGame() {
        start(.new(menuDifficulty))
    }

    /// Vuelve al menú. Guardar la partida no es cosa de este modelo: lo hace el tablero al
    /// desaparecer, que cubre también cerrar la ventana.
    func showMenu() {
        screen = .menu
    }
}
