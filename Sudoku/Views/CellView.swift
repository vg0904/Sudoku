//
//  CellView.swift
//  Sudoku
//

import SwiftUI

/// La participación de una celda en una celebración.
///
/// Lleva el id de la celebración además del retardo porque dos celebraciones seguidas pueden
/// asignar el mismo retardo a la misma celda. Sin el id, `.task(id:)` no vería ningún cambio y el
/// segundo pulso no se dispararía.
struct CellPulse: Equatable {
    let celebrationID: Int
    let delay: Double
}

/// Una celda del tablero. Solo dibuja: recibe ya resuelto todo lo que necesita saber.
///
/// La selección no se dibuja aquí: es una sola vista del tablero que se desliza de celda en celda.
struct CellView: View {
    let value: Int
    let state: CellState
    /// La celda muestra el mismo número que la seleccionada.
    let isMatching: Bool
    /// La celda comparte fila, columna o caja con la seleccionada.
    let isHighlighted: Bool
    /// Cuándo se une esta celda a la celebración, o `nil` si no participa.
    let pulse: CellPulse?
    /// El error que hay que sacudir si se cometió en esta celda; `nil` en las demás.
    let mistake: Mistake?
    /// `false` con Reduce Motion o con los efectos reducidos en los ajustes: entonces nada se
    /// mueve ni cambia de tamaño, y solo quedan los cambios de color.
    let allowsMotion: Bool
    /// Cómo se anima la celebración cuando llega `pulse`.
    let celebrationStyle: CelebrationStyle
    let sideLength: CGFloat

    @Environment(\.themeColor) private var themeColor

    var body: some View {
        // Capas de abajo arriba: el fondo de estado, los efectos de fondo de la celebración y el
        // número. Así el tinte y la franja de luz quedan detrás de la cifra y no la tapan.
        ZStack {
            background
            CelebrationBackdrop(pulse: pulse, style: celebrationStyle, allowsMotion: allowsMotion)
            number
        }
        .frame(width: sideLength, height: sideLength)
        // Sin esto, las celdas vacías no responderían al clic.
        .contentShape(.rect)
        .animation(.easeOut(duration: 0.12), value: isMatching)
        .animation(.easeOut(duration: 0.12), value: state)
    }

    // MARK: - Capas

    private var number: some View {
        Text(value == 0 ? " " : "\(value)")
            .font(.system(size: sideLength * 0.52, weight: weight, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(foreground)
            // El brillo alrededor del número es lo que hace que las coincidencias salten a la
            // vista sin recargar el fondo de la celda.
            .shadow(color: glow, radius: sideLength * 0.18)
            // Los dos efectos van sobre el número y no sobre la celda, para que el fondo y las
            // líneas del tablero se queden quietos.
            .keyframeAnimator(initialValue: 1.0, trigger: value) { content, scale in
                // `value` también cambia al borrar o al empezar partida; solo rebota un acierto.
                content.scaleEffect(state == .filled && allowsMotion ? scale : 1)
            } keyframes: { _ in
                // El número "cae" sobre la celda: empieza grande, como si estuviera más cerca, y
                // baja acelerando (`easeIn`) hasta su tamaño. Al chocar se aplasta un poco y
                // rebota hasta asentarse.
                //
                // - El salto inicial es `MoveKeyframe` (instantáneo), para no generar velocidad.
                // - La velocidad del impacto se da explícita en `startVelocity`. Es la que produce
                //   el aplastamiento; con −6 baja hasta ~0.82 y rebota hasta ~1.03. Medido con
                //   `KeyframeTimeline`: nunca se acerca a cero, así que el número no se refleja.
                // - El fotograma dura más (0.6 s) que el resorte (0.35 s) para que termine de
                //   asentarse en 1.0; si se corta antes, al final hay un saltito.
                MoveKeyframe(1.7)
                LinearKeyframe(1.0, duration: 0.16, timingCurve: .easeIn)
                SpringKeyframe(
                    1.0,
                    duration: 0.6,
                    spring: Spring(duration: 0.35, bounce: 0.5),
                    startVelocity: -6
                )
            }
            .keyframeAnimator(initialValue: 0.0, trigger: mistake) { content, offset in
                // Cuando el error pasa a otra celda, `mistake` vuelve a `nil` aquí y la animación
                // también se dispara; esta condición la deja sin efecto visible.
                content.offset(x: mistake != nil && allowsMotion ? offset : 0)
            } keyframes: { _ in
                let amplitude = sideLength * 0.1
                LinearKeyframe(-amplitude, duration: 0.05)
                LinearKeyframe(amplitude, duration: 0.08)
                LinearKeyframe(-amplitude * 0.6, duration: 0.07)
                LinearKeyframe(0, duration: 0.06)
            }
            // El movimiento de la celebración: escala, giro o salto, según el estilo.
            .modifier(CelebrationMotion(
                pulse: pulse,
                style: celebrationStyle,
                allowsMotion: allowsMotion,
                size: sideLength
            ))
    }

    // MARK: - Estilos

    private var weight: Font.Weight {
        if isMatching { return .bold }
        return state == .given ? .semibold : .regular
    }

    private var foreground: Color {
        switch state {
        case .given: .primary
        case .filled: themeColor
        case .wrong: .red
        case .empty: .clear
        }
    }

    private var glow: Color {
        guard isMatching, value != 0 else { return .clear }
        return state == .wrong ? .red.opacity(0.7) : themeColor.opacity(0.8)
    }

    /// El fondo se decide por prioridad: el error primero (para no perder nunca la señal de
    /// rojo), luego la coincidencia de número y al final el grupo. El tinte de la celebración va
    /// en su propia capa, encima de este.
    ///
    /// Todos son translúcidos, así que la selección, que se dibuja debajo, sigue viéndose.
    private var background: Color {
        if state == .wrong { return .red.opacity(0.12) }
        if isMatching { return themeColor.opacity(0.16) }
        if isHighlighted { return .secondary.opacity(0.12) }
        return .clear
    }
}

/// Una celda para las previews, con los parámetros que no interesan ya rellenos.
private func previewCell(
    _ value: Int,
    _ state: CellState,
    isMatching: Bool = false,
    isHighlighted: Bool = false
) -> CellView {
    CellView(
        value: value,
        state: state,
        isMatching: isMatching,
        isHighlighted: isHighlighted,
        pulse: nil,
        mistake: nil,
        allowsMotion: true,
        celebrationStyle: .wave,
        sideLength: 60
    )
}

#Preview("Estados") {
    HStack(spacing: 0) {
        previewCell(5, .given)
        previewCell(3, .filled)
        previewCell(7, .wrong)
        previewCell(0, .empty)
        previewCell(0, .empty, isHighlighted: true)
    }
    .padding()
}

#Preview("Coincidencias") {
    HStack(spacing: 0) {
        previewCell(4, .given, isMatching: true)
        previewCell(4, .given, isMatching: true)
        previewCell(4, .filled, isMatching: true)
        previewCell(9, .given)
    }
    .padding()
}
