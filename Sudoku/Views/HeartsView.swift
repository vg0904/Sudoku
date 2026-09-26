//
//  HeartsView.swift
//  Sudoku
//

import SwiftUI

/// Los corazones que quedan en la partida.
///
/// Al perder uno, la fila se sacude y destella en rojo. La sacudida se apaga si la persona tiene
/// **Reduce Motion** activo en el sistema o si ha desactivado los efectos en los ajustes: en ese
/// caso solo queda el cambio de color, que la HIG admite como sustituto del movimiento.
///
/// El movimiento nunca es la única señal: el número de corazones llenos ya dice cuántas vidas
/// quedan.
struct HeartsView: View {
    let livesRemaining: Int
    let maxLives: Int
    /// Dispara la animación al cambiar. Se usa el contador de errores porque sube exactamente una
    /// vez por vida perdida.
    let mistakeCount: Int
    /// El ajuste propio de la app para reducir efectos.
    let reduceEffects: Bool

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    /// Las fases por las que pasa la fila cuando se pierde una vida.
    private enum Phase: CaseIterable {
        case rest, hitLeft, hitRight, settle

        var offset: CGFloat {
            switch self {
            case .hitLeft: -4
            case .hitRight: 4
            case .rest, .settle: 0
            }
        }

        var scale: CGFloat {
            switch self {
            case .hitLeft, .hitRight: 1.14
            case .rest, .settle: 1
            }
        }

        /// `true` mientras el destello rojo está activo.
        var isFlashing: Bool {
            self == .hitLeft || self == .hitRight
        }
    }

    private var allowsMotion: Bool {
        !reduceEffects && !systemReduceMotion
    }

    var body: some View {
        PhaseAnimator(Phase.allCases, trigger: mistakeCount) { phase in
            hearts(phase: phase)
        } animation: { _ in
            .easeInOut(duration: 0.1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lives")
        .accessibilityValue("\(livesRemaining) of \(maxLives)")
    }

    private func hearts(phase: Phase) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<maxLives, id: \.self) { slot in
                Image(systemName: slot < livesRemaining ? "heart.fill" : "heart")
                    .foregroundStyle(slot < livesRemaining ? heartColor(phase: phase) : .secondary)
            }
        }
        .font(.title3)
        .symbolRenderingMode(.hierarchical)
        // Con Reduce Motion el desplazamiento y la escala se quedan en su valor neutro, así que
        // solo se percibe el destello de color.
        .offset(x: allowsMotion ? phase.offset : 0)
        .scaleEffect(allowsMotion ? phase.scale : 1)
        .help("Lives remaining")
    }

    private func heartColor(phase: Phase) -> Color {
        phase.isFlashing ? .red : .pink
    }
}

#Preview("Tres vidas") {
    HeartsView(livesRemaining: 3, maxLives: 3, mistakeCount: 0, reduceEffects: false)
        .padding()
}

#Preview("Una vida") {
    HeartsView(livesRemaining: 1, maxLives: 3, mistakeCount: 2, reduceEffects: false)
        .padding()
}

#Preview("Sin vidas") {
    HeartsView(livesRemaining: 0, maxLives: 3, mistakeCount: 3, reduceEffects: false)
        .padding()
}

#Preview("Cinco vidas, dos perdidas") {
    HeartsView(livesRemaining: 3, maxLives: 5, mistakeCount: 2, reduceEffects: false)
        .padding()
}
