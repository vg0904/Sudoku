//
//  Difficulty+Presentation.swift
//  Sudoku
//

import SwiftUI

extension Difficulty {
    /// El nombre que se muestra en el selector.
    ///
    /// Es `LocalizedStringKey` y no `LocalizedStringResource` a propósito: el primero se resuelve
    /// con el `locale` del entorno de la vista, así que respeta el idioma elegido en los ajustes.
    /// El segundo usa el idioma de la app y se quedaría en el anterior al cambiarlo en vivo.
    var displayName: LocalizedStringKey {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}
