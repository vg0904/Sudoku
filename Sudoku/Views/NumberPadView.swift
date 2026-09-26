//
//  NumberPadView.swift
//  Sudoku
//

import SwiftUI

/// El teclado numérico de la parte inferior.
///
/// Cada botón se va **rellenando desde abajo** según cuántas veces está bien colocado su número,
/// pistas incluidas: es el progreso de quien juega de un vistazo. Al colocar la novena aparición,
/// el botón celebra con el mismo estilo que el tablero y después cambia la cifra por una palomita
/// y se desactiva: a partir de ahí escribirlo solo podría ser un error.
struct NumberPadView: View {
    let game: SudokuGame
    let settings: GameSettings
    /// Se ejecuta tras cada acción para devolver el foco al tablero, y que el teclado siga
    /// funcionando después de un clic.
    let onAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private var allowsMotion: Bool {
        !settings.reduceEffects && !systemReduceMotion
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...SudokuGrid.size, id: \.self) { number in
                numberButton(number)
            }

            Button {
                game.clearSelection()
                onAction()
            } label: {
                Image(systemName: "delete.left")
                    .frame(maxWidth: .infinity, minHeight: NumberPadKey.height)
            }
            .buttonStyle(NumberPadButtonStyle())
            .help("Erase the wrong number")
            // Solo los errores se borran, así que el botón se apaga en cualquier otra celda.
            .disabled(!game.canClearSelection)
        }
        .disabled(game.isGenerating || game.isSolved || game.isDefeated || game.isPaused)
    }

    private func numberButton(_ number: Int) -> some View {
        let placed = game.placedCount(of: number)
        let isComplete = placed == SudokuGrid.size
        let isCelebrating = game.celebration?.completes(number: number) ?? false
        // La palomita espera a que acabe la celebración: primero se ve el número celebrar y
        // después se sustituye. Con "Ninguna" la celebración dura casi nada y aparece enseguida.
        let showsCheckmark = isComplete && !isCelebrating

        return NumberPadKey(
            number: number,
            progress: Double(placed) / Double(SudokuGrid.size),
            showsCheckmark: showsCheckmark,
            pulse: celebrationPulse(for: number),
            celebrationStyle: settings.celebrationStyle,
            allowsMotion: allowsMotion
        ) {
            game.enter(number)
            onAction()
        }
        // Mientras celebra no se desactiva: si no, el estilo de "desactivado" apagaría la
        // animación. Pulsarlo en ese momento no hace nada, porque el juego ya rechaza el número.
        .disabled(showsCheckmark)
        .help(isComplete ? "All \(number)s are placed" : "Enter \(number)")
        // Sin esto, VoiceOver solo diría el número; así sabe también cuánto le falta.
        .accessibilityValue(Text("\(placed) of \(SudokuGrid.size)"))
    }

    /// El aviso de celebración para el botón de `number`, o `nil` si no le toca.
    ///
    /// Arranca sin retardo: el botón celebra en cuanto se completa el número, mientras la onda
    /// recorre el tablero.
    private func celebrationPulse(for number: Int) -> CellPulse? {
        guard settings.celebrationStyle != .off,
              let celebration = game.celebration,
              celebration.completes(number: number)
        else { return nil }

        return CellPulse(celebrationID: celebration.id, delay: 0)
    }
}

/// Una tecla de número: su progreso, la palomita al completarse y la celebración.
///
/// Vive aparte de `NumberPadView` porque la vista previa de los ajustes muestra la misma tecla,
/// y así lo que se ve allí es exactamente lo que se verá al jugar.
struct NumberPadKey: View {
    let number: Int
    /// De 0 a 1: la parte de sus nueve apariciones que ya está colocada.
    let progress: Double
    let showsCheckmark: Bool
    let pulse: CellPulse?
    let celebrationStyle: CelebrationStyle
    let allowsMotion: Bool
    let action: () -> Void

    /// Algo más alta que un botón normal, para que el relleno de progreso se aprecie.
    static let height: CGFloat = 36

    var body: some View {
        Button(action: action) {
            ZStack {
                if showsCheckmark {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                        .fontWeight(.bold)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(number)")
                }
            }
            .font(.title3)
            .frame(maxWidth: .infinity, minHeight: Self.height)
        }
        .buttonStyle(NumberPadButtonStyle(progress: progress, allowsMotion: allowsMotion))
        // Los efectos de la celebración van **fuera** del botón, sobre el botón entero, igual
        // que en las celdas del tablero. Dentro de la etiqueta o del `ButtonStyle` forman parte
        // del control, que SwiftUI gestiona por su cuenta, y la animación no llegaba a verse.
        // Así además celebra la tecla completa, como una tecla física.
        .background {
            // Detrás del botón: sus fondos son translúcidos, así que el tinte se ve a través.
            CelebrationBackdrop(pulse: pulse, style: celebrationStyle, allowsMotion: allowsMotion)
                .clipShape(.rect(cornerRadius: NumberPadButtonStyle.cornerRadius))
        }
        .modifier(CelebrationMotion(
            pulse: pulse,
            style: celebrationStyle,
            allowsMotion: allowsMotion,
            size: Self.height
        ))
        .animation(.easeOut(duration: 0.25), value: showsCheckmark)
    }
}

/// El aspecto de los botones del teclado numérico: un fondo gris que se rellena desde abajo con
/// el color del tema.
///
/// Es un `ButtonStyle` propio porque el relleno tiene que dibujarse dentro de la forma del
/// botón, y con `.bordered` no hay acceso a ese fondo. La celebración no va aquí, sino fuera del
/// botón (ver `NumberPadView.numberButton`).
struct NumberPadButtonStyle: ButtonStyle {
    /// De 0 a 1, o `nil` para un botón sin progreso (el de borrar).
    var progress: Double?
    var allowsMotion = true

    static let cornerRadius: CGFloat = 8

    @Environment(\.themeColor) private var themeColor
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius)

        configuration.label
            .foregroundStyle(isEnabled ? .primary : .tertiary)
            .background {
                ZStack(alignment: .bottom) {
                    shape.fill(.quaternary)

                    if let progress {
                        progressFill(progress)
                    }
                }
                .clipShape(shape)
                // En macOS, `Color.accentColor` se vuelve gris dentro de un control desactivado,
                // y los números completos se desactivan. El fondo es decoración, no el control:
                // se dibuja como activo para que un número completo se vea lleno de color.
                .environment(\.isEnabled, true)
            }
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }

    private func progressFill(_ progress: Double) -> some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(themeColor.opacity(0.35))
                .frame(height: proxy.size.height * min(max(progress, 0), 1))
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        // Sube con suavidad al acertar. Sin movimiento cambia de golpe, como el resto de la app.
        .animation(allowsMotion ? .easeOut(duration: 0.3) : nil, value: progress)
    }
}

/// Una partida con el tablero resuelto salvo las celdas indicadas, para ver el numpad en sus
/// distintos estados sin pagar el coste del generador completo.
@MainActor
private func padPreviewGame(emptyIndices: [Int] = []) -> SudokuGame {
    var generator = SystemRandomNumberGenerator()
    let solution = SudokuGenerator.makeFilledGrid(using: &generator)

    var board = solution
    for index in emptyIndices {
        board[index] = 0
    }

    return SudokuGame(puzzle: Puzzle(board: board, solution: solution, difficulty: .easy))
}

@MainActor
private let previewSettings = GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard)

#Preview("Todos completos") {
    NumberPadView(game: padPreviewGame(), settings: previewSettings, onAction: {})
        .padding()
        .frame(width: 460)
}

#Preview("Progreso a medias") {
    // Vacía una cantidad distinta de celdas de cada número para ver varios niveles de relleno.
    NumberPadView(
        game: padPreviewGame(emptyIndices: Array(stride(from: 0, to: 81, by: 2))),
        settings: previewSettings,
        onAction: {}
    )
    .padding()
    .frame(width: 460)
}
