//
//  SettingsView.swift
//  Sudoku
//

import SwiftUI

/// La ventana de ajustes, que macOS abre con ⌘, y desde el menú de la app.
struct SettingsView: View {
    @Environment(GameSettings.self) private var settings

    /// El número de vidas que espera confirmación.
    ///
    /// El selector no cambia hasta que se confirma, así que cancelar no tiene que revertir nada:
    /// el valor simplemente nunca se movió.
    @State private var pendingLives: Int?

    /// Para que la vista previa de la celebración respete Reduce Motion igual que el tablero.
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// Las pestañas de la ventana. No se llama `Section` para no tapar el `Section` de SwiftUI
    /// que usan los formularios de abajo.
    enum Pane: Hashable {
        case general, game
    }

    @State private var selectedPane: Pane

    /// - Parameter initialPane: la pestaña con la que se abre. Solo las previews la cambian,
    ///   para poder ver cualquier pestaña sin hacer clic.
    init(initialPane: Pane = .general) {
        _selectedPane = State(initialValue: initialPane)
    }

    var body: some View {
        TabView(selection: $selectedPane) {
            Tab("General", systemImage: "gearshape", value: .general) {
                generalTab
                    // Cada pestaña tiene su altura: macOS redimensiona la ventana con una animación
                    // al cambiar, como en las apps del sistema, en lugar de dejar huecos vacíos.
                    .frame(width: 440, height: 340)
            }

            Tab("Game", systemImage: "square.grid.3x3", value: .game) {
                gameTab
                    .frame(width: 440, height: 600)
            }
        }
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section {
                Picker("Language", selection: languageBinding) {
                    Text("Automatic").tag(AppLanguage.automatic)
                    Text("Spanish").tag(AppLanguage.spanish)
                    Text("English").tag(AppLanguage.english)
                }
            } footer: {
                Text("Automatic follows your Mac's language.")
            }

            Section {
                LabeledContent("Color") {
                    ThemePicker(selection: themeBinding)
                }
            } footer: {
                Text("System uses the accent color from System Settings > Appearance.")
            }

            Section {
                Toggle("Show timer while playing", isOn: showTimerBinding)
            } footer: {
                Text("The time is always shown when you finish, even if the clock is hidden.")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Juego

    private var gameTab: some View {
        Form {
            Section {
                Picker("Lives", selection: livesBinding) {
                    ForEach(GameSettings.livesRange, id: \.self) { count in
                        // El plural se resuelve con una variación explícita en el catálogo, no con
                        // inflexión automática: así el resultado es determinista y comprobable.
                        Text("\(count) lives").tag(count)
                    }
                    Divider()
                    Text("Unlimited").tag(0)
                }
            } footer: {
                Text("Changing this restarts the current game.")
            }

            Section("Visual aids") {
                Toggle("Highlight row, column and box", isOn: highlightGroupsBinding)
                Toggle("Glow matching numbers", isOn: highlightMatchesBinding)
            }

            Section {
                Picker("Celebration", selection: celebrationStyleBinding) {
                    ForEach(CelebrationStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                if settings.celebrationStyle != .off {
                    CelebrationPreview(
                        style: settings.celebrationStyle,
                        allowsMotion: !settings.reduceEffects && !systemReduceMotion
                    )
                }
            } footer: {
                Text("Plays when you complete a row, column or box, or place all nine of a number.")
            }

            Section {
                Toggle("Reduce animations", isOn: reduceEffectsBinding)
                Toggle("Include row and column in VoiceOver", isOn: announcesCellPositionBinding)
            } header: {
                Text("Accessibility")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Animations are also reduced automatically when Reduce Motion is on in System Settings.")
                    Text("VoiceOver always reads each cell's number and state. This adds its position.")
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "Restart the game?",
            isPresented: isConfirmingLives,
            presenting: pendingLives
        ) { lives in
            Button("Restart") {
                settings.lives = lives
                pendingLives = nil
            }
            Button("Cancel", role: .cancel) {
                pendingLives = nil
            }
        } message: { _ in
            Text("Changing the number of lives starts a new game and your progress will be lost.")
        }
    }

    // MARK: - Enlaces

    /// Las vidas son el único ajuste que altera la partida, así que es el único que confirma.
    private var livesBinding: Binding<Int> {
        Binding {
            settings.lives
        } set: { proposed in
            guard proposed != settings.lives else { return }
            pendingLives = proposed
        }
    }

    private var isConfirmingLives: Binding<Bool> {
        Binding {
            pendingLives != nil
        } set: { isPresented in
            if !isPresented { pendingLives = nil }
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding { settings.language } set: { settings.language = $0 }
    }

    private var showTimerBinding: Binding<Bool> {
        Binding { settings.showTimer } set: { settings.showTimer = $0 }
    }

    private var highlightGroupsBinding: Binding<Bool> {
        Binding { settings.highlightGroups } set: { settings.highlightGroups = $0 }
    }

    private var highlightMatchesBinding: Binding<Bool> {
        Binding { settings.highlightMatches } set: { settings.highlightMatches = $0 }
    }

    private var themeBinding: Binding<AppTheme> {
        Binding { settings.theme } set: { settings.theme = $0 }
    }

    private var celebrationStyleBinding: Binding<CelebrationStyle> {
        Binding { settings.celebrationStyle } set: { settings.celebrationStyle = $0 }
    }

    private var announcesCellPositionBinding: Binding<Bool> {
        Binding { settings.announcesCellPosition } set: { settings.announcesCellPosition = $0 }
    }

    private var reduceEffectsBinding: Binding<Bool> {
        Binding { settings.reduceEffects } set: { settings.reduceEffects = $0 }
    }
}

#Preview("Ajustes") {
    SettingsView()
        .environment(GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
}

#Preview("Juego") {
    SettingsView(initialPane: .game)
        .environment(GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard))
}
