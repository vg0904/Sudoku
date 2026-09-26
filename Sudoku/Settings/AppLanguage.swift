//
//  AppLanguage.swift
//  Sudoku
//

import Foundation

/// El idioma en el que se muestra la app.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    /// Sigue el idioma del sistema, que es lo que Apple recomienda por defecto.
    case automatic
    case spanish
    case english

    var id: String { rawValue }

    /// El `Locale` que hay que meter en el entorno, o `nil` para dejar que decida el sistema.
    var locale: Locale? {
        switch self {
        case .automatic: nil
        case .spanish: Locale(identifier: "es")
        case .english: Locale(identifier: "en")
        }
    }

    /// El locale efectivo, ya resuelto contra el del sistema.
    var effectiveLocale: Locale {
        locale ?? .autoupdatingCurrent
    }
}
