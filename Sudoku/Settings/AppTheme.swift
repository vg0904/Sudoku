//
//  AppTheme.swift
//  Sudoku
//

import Foundation

/// El color principal de la app: selección, números escritos, celebraciones y botones.
nonisolated enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    /// Sigue el color de acento elegido en Ajustes del Sistema. Es lo que Apple recomienda por
    /// defecto, y el azul que se ve normalmente es el acento por defecto de macOS.
    case system
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case graphite

    var id: String { rawValue }
}
