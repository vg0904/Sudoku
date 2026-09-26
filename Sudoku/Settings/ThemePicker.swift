//
//  ThemePicker.swift
//  Sudoku
//

import SwiftUI

/// Una fila de círculos de color para elegir el tema, como el selector de color de acento de
/// Ajustes del Sistema.
struct ThemePicker: View {
    @Binding var selection: AppTheme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    selection = theme
                } label: {
                    swatch(for: theme)
                }
                .buttonStyle(.plain)
                .help(Text(theme.displayName))
                // Para VoiceOver cada círculo es un botón con nombre y dice cuál está elegido; si
                // no, solo oiría "botón" nueve veces.
                .accessibilityLabel(Text(theme.displayName))
                .accessibilityAddTraits(selection == theme ? .isSelected : [])
            }
        }
    }

    private func swatch(for theme: AppTheme) -> some View {
        Circle()
            .fill(fill(for: theme))
            .frame(width: 20, height: 20)
            .overlay {
                // Igual que en macOS: el elegido lleva un punto blanco en el centro. No depende
                // solo del color, así que también se distingue sin ver colores.
                if selection == theme {
                    Circle()
                        .fill(.white)
                        .frame(width: 7, height: 7)
                        .shadow(radius: 0.5)
                }
            }
            .overlay {
                Circle().strokeBorder(.black.opacity(0.15))
            }
            .contentShape(.circle)
    }

    /// "Sistema" se pinta con todos los colores, como el "Multicolor" de macOS: no es un color
    /// concreto, sino el que haya elegido cada quien.
    private func fill(for theme: AppTheme) -> AnyShapeStyle {
        guard theme == .system else { return AnyShapeStyle(theme.color) }

        let rainbow = AppTheme.allCases
            .filter { $0 != .system && $0 != .graphite }
            .map(\.color)
        return AnyShapeStyle(AngularGradient(colors: rainbow + [rainbow[0]], center: .center))
    }
}

#Preview {
    @Previewable @State var theme = AppTheme.system
    ThemePicker(selection: $theme)
        .padding()
}
