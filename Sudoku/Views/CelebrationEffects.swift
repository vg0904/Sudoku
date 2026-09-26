//
//  CelebrationEffects.swift
//  Sudoku
//

import SwiftUI

// Las dos piezas visuales de una celebración, compartidas por las celdas del tablero y los
// botones del teclado numérico. Las dos animan el mismo progreso de 0 a 1 y dejan que
// `CelebrationFrame` decida qué significa ese progreso según el estilo.

/// La línea de tiempo común: espera su turno en la onda y luego avanza de 0 a 1.
///
/// Sustituye a esperar con `Task.sleep`: el retardo es simplemente el primer tramo, y SwiftUI
/// reemplaza la línea de tiempo sola si llega otra celebración a mitad.
private func celebrationTimeline(pulse: CellPulse?, style: CelebrationStyle) -> some Keyframes<Double> {
    KeyframeTrack {
        MoveKeyframe(0.0)
        LinearKeyframe(0.0, duration: pulse?.delay ?? 0)
        LinearKeyframe(1.0, duration: style.cellDuration)
    }
}

extension CelebrationFrame {
    /// Los efectos para un progreso dado, o `.rest` si no hay celebración.
    ///
    /// Cuando la celebración termina, `pulse` pasa a `nil` y el animador se dispara otra vez;
    /// devolver `.rest` en ese caso evita que se repita.
    ///
    /// `nonisolated` explícito: aunque `CelebrationFrame` lo sea, un método añadido en una
    /// extensión toma el aislamiento por defecto del proyecto (`MainActor`), y lo llaman cierres
    /// `@Sendable` que no corren en el actor principal.
    nonisolated static func current(
        pulse: CellPulse?,
        style: CelebrationStyle,
        progress: Double,
        allowsMotion: Bool
    ) -> CelebrationFrame {
        guard pulse != nil else { return .rest }
        return CelebrationFrame(style: style, progress: progress, allowsMotion: allowsMotion)
    }
}

/// El movimiento de la celebración sobre un contenido: escala, giro y sombra de altura.
struct CelebrationMotion: ViewModifier {
    let pulse: CellPulse?
    let style: CelebrationStyle
    let allowsMotion: Bool
    /// El tamaño de referencia para la sombra, normalmente el lado de la celda o del botón.
    let size: CGFloat

    func body(content: Content) -> some View {
        // Copias locales: el cierre `content` de `keyframeAnimator` es `@Sendable` y no corre en
        // el actor principal, así que no debe leer propiedades de la vista.
        let pulse = pulse
        let style = style
        let allowsMotion = allowsMotion
        let size = size

        return content
            .keyframeAnimator(initialValue: 0.0, trigger: pulse) { view, progress in
                let frame = CelebrationFrame.current(
                    pulse: pulse,
                    style: style,
                    progress: progress,
                    allowsMotion: allowsMotion
                )
                view
                    // La sombra crece y se aleja con la altura: el contenido parece flotar
                    // aunque no se mueva de su sitio.
                    .shadow(
                        color: .black.opacity(0.35 * frame.elevation),
                        radius: size * 0.08 * frame.elevation,
                        y: size * 0.06 * frame.elevation
                    )
                    .scaleEffect(frame.scale)
                    .rotation3DEffect(.degrees(frame.rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            } keyframes: { _ in
                celebrationTimeline(pulse: pulse, style: style)
            }
    }
}

/// El tinte y la franja de luz de la celebración, para poner **detrás** del contenido.
///
/// Tiene su propio animador con la misma línea de tiempo que `CelebrationMotion`: los dos calculan
/// el mismo progreso, así que avanzan sincronizados.
struct CelebrationBackdrop: View {
    let pulse: CellPulse?
    let style: CelebrationStyle
    let allowsMotion: Bool

    @Environment(\.themeColor) private var themeColor

    var body: some View {
        let tint = themeColor
        let pulse = pulse
        let style = style
        let allowsMotion = allowsMotion

        GeometryReader { proxy in
            // La franja se mide con el ancho real: sirve igual para una celda cuadrada que para
            // un botón rectangular.
            let width = proxy.size.width

            Color.clear
                .keyframeAnimator(initialValue: 0.0, trigger: pulse) { content, progress in
                    let frame = CelebrationFrame.current(
                        pulse: pulse,
                        style: style,
                        progress: progress,
                        allowsMotion: allowsMotion
                    )
                    content
                        .background(tint.opacity(0.5 * frame.tint))
                        .overlay {
                            if let offset = frame.shineOffset {
                                LinearGradient(
                                    colors: [.clear, tint.opacity(0.75), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: width * 0.5)
                                .rotationEffect(.degrees(20))
                                .offset(x: offset * width)
                            }
                        }
                } keyframes: { _ in
                    celebrationTimeline(pulse: pulse, style: style)
                }
        }
        // La franja no debe salirse de su celda o su botón.
        .clipped()
    }
}
