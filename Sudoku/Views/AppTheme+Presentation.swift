//
//  AppTheme+Presentation.swift
//  Sudoku
//

import SwiftUI

extension AppTheme {
    /// El nombre que se muestra en los ajustes.
    var displayName: LocalizedStringKey {
        switch self {
        case .system: "System"
        case .blue: "Blue"
        case .purple: "Purple"
        case .pink: "Pink"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .graphite: "Graphite"
        }
    }

    /// El color del tema.
    ///
    /// Los temas fijos vienen del catálogo de assets (`Assets.xcassets/Theme`) y no de `.orange`,
    /// `.green`, etc. Cada uno tiene una variante clara y otra oscura: los colores estándar del
    /// sistema como texto sobre blanco no llegan al contraste mínimo de 3:1 para texto grande (el
    /// naranja se queda en ~2:1), y los números escritos van en este color.
    var color: Color {
        switch self {
        case .system: .accentColor
        case .blue: Color("ThemeBlue")
        case .purple: Color("ThemePurple")
        case .pink: Color("ThemePink")
        case .red: Color("ThemeRed")
        case .orange: Color("ThemeOrange")
        case .yellow: Color("ThemeYellow")
        case .green: Color("ThemeGreen")
        case .graphite: Color("ThemeGraphite")
        }
    }

    /// Lo que se pasa a `.tint(_:)` en la raíz.
    ///
    /// Con el tema del sistema es `nil`: así los controles no reciben ningún tinte propio y
    /// siguen al sistema exactamente como antes de existir los temas.
    var tint: Color? {
        self == .system ? nil : color
    }
}

extension EnvironmentValues {
    /// El color del tema elegido.
    ///
    /// Las vistas lo usan en lugar de `Color.accentColor`, que siempre es el del sistema y no se
    /// entera del tema. Se inyecta en la raíz de cada escena.
    @Entry var themeColor: Color = .accentColor
}
