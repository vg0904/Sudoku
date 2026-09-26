//
//  GameSettings.swift
//  Sudoku
//

import Foundation
import Observation

/// Los ajustes de la app, guardados en `UserDefaults`.
///
/// El `init` recibe el `UserDefaults` a usar para que las pruebas trabajen sobre una instancia
/// aislada y no toquen los ajustes reales de quien juega.
@Observable
@MainActor
final class GameSettings {

    /// Las claves con las que se guarda cada ajuste. Cambiarlas descarta lo ya guardado.
    private enum Key {
        static let language = "settings.language"
        static let lives = "settings.lives"
        static let showTimer = "settings.showTimer"
        static let highlightGroups = "settings.highlightGroups"
        static let highlightMatches = "settings.highlightMatches"
        static let reduceEffects = "settings.reduceEffects"
        static let celebrationStyle = "settings.celebrationStyle"
        static let theme = "settings.theme"
    }

    private let defaults: UserDefaults

    var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Key.language) }
    }

    /// Vidas por partida: de 1 a 5, o `0` para jugar sin límite.
    ///
    /// Se guarda como entero en lugar de un opcional porque `UserDefaults` no distingue entre
    /// "ausente" y "nil", y `0` deja clarísimo el caso de sin límite.
    var lives: Int {
        didSet { defaults.set(lives, forKey: Key.lives) }
    }

    var showTimer: Bool {
        didSet { defaults.set(showTimer, forKey: Key.showTimer) }
    }

    /// Resaltar la fila, la columna y la caja de la celda seleccionada.
    var highlightGroups: Bool {
        didSet { defaults.set(highlightGroups, forKey: Key.highlightGroups) }
    }

    /// Dar brillo a las celdas con el mismo número que la seleccionada.
    var highlightMatches: Bool {
        didSet { defaults.set(highlightMatches, forKey: Key.highlightMatches) }
    }

    /// Apaga las animaciones de la app, con independencia de Reduce Motion del sistema.
    var reduceEffects: Bool {
        didSet { defaults.set(reduceEffects, forKey: Key.reduceEffects) }
    }

    /// El color principal de la app.
    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    /// Cómo se celebra completar una fila, columna o caja.
    var celebrationStyle: CelebrationStyle {
        didSet { defaults.set(celebrationStyle.rawValue, forKey: Key.celebrationStyle) }
    }

    /// Cuántos errores se permiten, o `nil` si se juega sin límite.
    var maxLives: Int? {
        lives == 0 ? nil : lives
    }

    /// El rango que ofrece el selector de vidas.
    static let livesRange = 1...5

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // `object(forKey:)` en lugar de `bool(forKey:)`/`integer(forKey:)` para poder distinguir
        // "no guardado nunca" de "guardado como false/0", que devuelven lo mismo.
        self.language = (defaults.string(forKey: Key.language))
            .flatMap(AppLanguage.init(rawValue:)) ?? .automatic
        self.lives = defaults.object(forKey: Key.lives) as? Int ?? 3
        self.showTimer = defaults.object(forKey: Key.showTimer) as? Bool ?? true
        self.highlightGroups = defaults.object(forKey: Key.highlightGroups) as? Bool ?? true
        self.highlightMatches = defaults.object(forKey: Key.highlightMatches) as? Bool ?? true
        self.reduceEffects = defaults.object(forKey: Key.reduceEffects) as? Bool ?? false
        // Igual que el idioma: un valor guardado que ya no existe vuelve al de por defecto.
        self.celebrationStyle = (defaults.string(forKey: Key.celebrationStyle))
            .flatMap(CelebrationStyle.init(rawValue:)) ?? .wave
        self.theme = (defaults.string(forKey: Key.theme))
            .flatMap(AppTheme.init(rawValue:)) ?? .system
    }
}
