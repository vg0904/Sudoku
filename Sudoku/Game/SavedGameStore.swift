//
//  SavedGameStore.swift
//  Sudoku
//

import Foundation

/// Guarda y recupera la partida en curso.
///
/// Usa `UserDefaults` porque la foto es pequeña (unos pocos kilobytes de JSON) y solo hay una. Para
/// algo más grande o con historial, SwiftData como los récords sería mejor.
///
/// Recibe el `UserDefaults` en el `init`, igual que `GameSettings`, para que las pruebas usen uno
/// aislado.
struct SavedGameStore {
    private let defaults: UserDefaults

    static let key = "game.saved"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// La partida guardada, o `nil` si no hay ninguna o no se puede usar.
    func load() -> SavedGame? {
        guard let data = defaults.data(forKey: Self.key),
              let saved = try? JSONDecoder().decode(SavedGame.self, from: data),
              saved.isValid
        else { return nil }

        return saved
    }

    /// Guarda la partida, o borra la que hubiera si recibe `nil` (por ejemplo, al terminarla).
    func save(_ game: SavedGame?) {
        guard let game, let data = try? JSONEncoder().encode(game) else {
            defaults.removeObject(forKey: Self.key)
            return
        }

        defaults.set(data, forKey: Self.key)
    }
}
