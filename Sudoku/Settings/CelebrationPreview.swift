//
//  CelebrationPreview.swift
//  Sudoku
//

import SwiftUI

/// Una fila de nueve celdas y una tecla del teclado numérico que reproducen un estilo de
/// celebración, para verlo antes de jugar.
///
/// Usa `CellView` y `NumberPadKey` tal cual, así que muestra exactamente lo que se verá en el
/// tablero al completar una fila y en el teclado al completar un número.
struct CelebrationPreview: View {
    let style: CelebrationStyle
    let allowsMotion: Bool

    /// Sube para pedir otra reproducción: al elegir estilo, al pulsar ▶ o al abrir los ajustes.
    @State private var runID = 0

    /// Sube cuando empieza de verdad la celebración. `CellPulse` lo usa como id, y un id nuevo es
    /// lo que dispara los animadores de las celdas y de la tecla.
    @State private var celebrationID = 0

    /// En qué punto está la tecla de la vista previa.
    private enum KeyPhase {
        /// Le falta una aparición, como justo antes de la jugada que la completa.
        case waiting
        case celebrating
        /// Ya completa: muestra la palomita.
        case done
    }

    @State private var keyPhase = KeyPhase.waiting

    private let cellSide: CGFloat = 28
    /// El número de la tecla. El último de la fila, para que se lea como "el que faltaba".
    private let keyNumber = 9

    var body: some View {
        // Alineadas por abajo para que las dos etiquetas queden a la misma altura, aunque la tecla
        // sea más alta que las celdas.
        HStack(alignment: .bottom) {
            labeled("Row") {
                row
            }

            labeled("Number") {
                key
            }

            Spacer()

            Button("Play Again", systemImage: "play.fill") {
                runID += 1
            }
            .labelStyle(.iconOnly)
            .help("Play Again")
        }
        // `.task(id:)` se ejecuta al aparecer (al abrir los ajustes) y otra vez cada vez que
        // cambia `runID`: al elegir otro estilo o al pulsar ▶.
        .onChange(of: style) { runID += 1 }
        .task(id: runID) { await play() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Celebration preview")
    }

    // MARK: - Partes

    private var row: some View {
        HStack(spacing: 0) {
            ForEach(0..<SudokuGrid.size, id: \.self) { column in
                CellView(
                    value: column + 1,
                    state: .filled,
                    isMatching: false,
                    isHighlighted: false,
                    pulse: CellPulse(
                        celebrationID: celebrationID,
                        delay: Double(column) * CelebrationStyle.stepDelay
                    ),
                    mistake: nil,
                    allowsMotion: allowsMotion,
                    celebrationStyle: style,
                    sideLength: cellSide
                )
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(.separator)
        }
    }

    private var key: some View {
        NumberPadKey(
            number: keyNumber,
            progress: keyPhase == .waiting ? Double(SudokuGrid.size - 1) / Double(SudokuGrid.size) : 1,
            showsCheckmark: keyPhase == .done,
            pulse: keyPhase == .celebrating ? CellPulse(celebrationID: celebrationID, delay: 0) : nil,
            celebrationStyle: style,
            allowsMotion: allowsMotion,
            action: {}
        )
        .frame(width: 40)
        // Es una demostración, no un botón que haga algo.
        .allowsHitTesting(false)
    }

    /// Una parte de la vista previa con su nombre debajo.
    private func labeled<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 4) {
            content()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Secuencia

    /// Reproduce la secuencia completa: la tecla vuelve a estar a una del final, se llena,
    /// celebra a la vez que la fila y termina con la palomita.
    ///
    /// Vive en `.task(id:)`: si se pide otra reproducción a mitad, SwiftUI cancela esta sola y los
    /// `Task.sleep` salen antes de tiempo, así que dos secuencias nunca se pisan.
    private func play() async {
        keyPhase = .waiting

        // Una pausa corta para que se vea la tecla a 8 de 9 antes de llenarse.
        try? await Task.sleep(for: .seconds(0.35))
        guard !Task.isCancelled else { return }

        celebrationID += 1
        keyPhase = .celebrating

        try? await Task.sleep(for: .seconds(style.cellDuration + 0.1))
        guard !Task.isCancelled else { return }

        keyPhase = .done
    }
}

#Preview {
    CelebrationPreview(style: .jump, allowsMotion: true)
        .padding()
        .frame(width: 420)
}
