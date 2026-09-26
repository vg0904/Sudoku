//
//  AppThemeTests.swift
//  SudokuTests
//

import SwiftUI
import Testing
@testable import Sudoku

@Suite("Temas de color")
@MainActor
struct AppThemeTests {

    /// La luminancia relativa de WCAG, a partir de las componentes lineales del color.
    private func luminance(_ color: Color, scheme: ColorScheme) -> Double {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        let resolved = color.resolve(in: environment)

        return 0.2126 * Double(resolved.linearRed)
            + 0.7152 * Double(resolved.linearGreen)
            + 0.0722 * Double(resolved.linearBlue)
    }

    /// El contraste de WCAG entre dos colores: de 1:1 (iguales) a 21:1 (negro sobre blanco).
    private func contrast(_ color: Color, against background: Color, scheme: ColorScheme) -> Double {
        let a = luminance(color, scheme: scheme)
        let b = luminance(background, scheme: scheme)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Los números escritos van en el color del tema. Son texto grande, así que WCAG pide al menos
    /// 3:1. Los colores estándar del sistema no llegan (el amarillo sobre blanco da 1.5:1), y por
    /// eso los temas tienen sus propias variantes en el catálogo.
    @Test(
        "Cada tema se lee como texto grande en modo claro y oscuro",
        arguments: AppTheme.allCases.filter { $0 != .system }
    )
    func themeColorsHaveEnoughContrast(theme: AppTheme) {
        let onLight = contrast(theme.color, against: .white, scheme: .light)
        let onDark = contrast(
            theme.color,
            against: Color(red: 0.12, green: 0.12, blue: 0.12),
            scheme: .dark
        )

        #expect(onLight >= 3, "Sobre blanco: \(onLight):1")
        #expect(onDark >= 3, "Sobre oscuro: \(onDark):1")
    }

    @Test(
        "Los temas fijos cambian de tono entre claro y oscuro",
        arguments: AppTheme.allCases.filter { $0 != .system }
    )
    func themeColorsAdaptToAppearance(theme: AppTheme) {
        // Si el color no se encontrara en el catálogo, las dos variantes saldrían iguales.
        #expect(luminance(theme.color, scheme: .light) != luminance(theme.color, scheme: .dark))
    }

    @Test("El tema del sistema no impone ningún tinte")
    func systemThemeHasNoTint() {
        #expect(AppTheme.system.tint == nil)
        #expect(AppTheme.orange.tint != nil)
    }
}
