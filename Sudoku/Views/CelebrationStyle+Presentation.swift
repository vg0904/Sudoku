//
//  CelebrationStyle+Presentation.swift
//  Sudoku
//

import SwiftUI

extension CelebrationStyle {
    /// El nombre que se muestra en el selector de los ajustes.
    ///
    /// `LocalizedStringKey` por la misma razón que en `Difficulty.displayName`: así respeta el
    /// idioma elegido en los ajustes al cambiarlo en vivo.
    var displayName: LocalizedStringKey {
        switch self {
        case .wave: "Wave"
        case .flip: "Flip"
        case .jump: "Jump"
        case .shine: "Shine"
        case .off: "None"
        }
    }

    /// Lo que dura la animación en **una** celda, sin contar su retardo en la onda.
    var cellDuration: Double {
        switch self {
        case .wave: 0.3
        case .flip: 0.45
        case .jump: 0.5
        case .shine: 0.4
        case .off: 0
        }
    }

    /// El retardo entre una celda y la siguiente. Es lo que convierte animaciones sueltas en una
    /// onda que sale de la jugada.
    static let stepDelay = 0.035

    /// Lo que dura una celebración entera sobre `cellCount` celdas: el retardo de la última más
    /// su propia animación, con un pequeño margen para que ninguna se corte al final.
    func totalDuration(cellCount: Int) -> Double {
        Double(max(cellCount - 1, 0)) * Self.stepDelay + cellDuration + 0.05
    }
}

/// Los efectos de una celda en un instante concreto de la celebración.
///
/// Es una **función pura** del estilo y del progreso de la celda (0 al empezar, 1 al terminar).
/// La vista solo anima ese progreso y aplica lo que salga de aquí; por eso cada estilo se puede
/// comprobar con pruebas sin reproducir ninguna animación.
///
/// Al principio y al final todo vale su valor neutro: la celda queda exactamente como estaba.
nonisolated struct CelebrationFrame: Equatable, Sendable {
    /// Escala del número.
    var scale: Double = 1
    /// Giro del número sobre su eje vertical, en grados.
    var rotation: Double = 0
    /// Cuánto se "levanta" el número hacia quien mira, de 0 a 1. No lo mueve: se dibuja como una
    /// sombra que crece, la señal de que está por encima del tablero.
    var elevation: Double = 0
    /// Intensidad del tinte de fondo, de 0 a 1.
    var tint: Double = 0
    /// Posición de la franja de luz, de −1 (fuera por la izquierda) a 1 (fuera por la derecha),
    /// o `nil` si no hay franja.
    var shineOffset: Double?

    /// Una celda sin celebración.
    static let rest = CelebrationFrame()

    private init() {}

    /// - Parameter allowsMotion: con `false` (Reduce Motion o efectos reducidos) solo queda el
    ///   tinte. Nada se mueve, gira ni cambia de tamaño, como pide la HIG.
    init(style: CelebrationStyle, progress: Double, allowsMotion: Bool) {
        let p = min(max(progress, 0), 1)
        guard style != .off, p > 0, p < 1 else { return }

        // Sube de 0 a 1 y vuelve a 0: la forma de "ir y volver" que comparten casi todos.
        let hump = sin(.pi * p)

        // El tinte es la señal común a todos los estilos y la única que sobrevive sin movimiento.
        // En la onda es más intenso porque es su efecto principal.
        tint = style == .wave ? hump : hump * 0.6

        guard allowsMotion else { return }

        switch style {
        case .wave:
            scale = 1 + 0.25 * hump

        case .flip:
            // Una vuelta de carta sin mostrar nunca el reverso: de 0° a 90°, salto a −90° justo
            // cuando la carta está de canto (y no se ve), y de −90° a 0°. Con un giro de 180°
            // completo, a mitad de camino el número se vería reflejado.
            let eased = p * p * (3 - 2 * p)
            rotation = eased < 0.5 ? eased * 180 : (eased - 1) * 180

        case .jump:
            // Salta hacia quien mira, sin salir de su recuadro: crece al "subir" y encoge al
            // "bajar". El 70 % del tiempo está en el aire y el 30 % restante es el aterrizaje.
            let airTime = 0.7
            if p < airTime {
                // Una parábola, como algo lanzado hacia arriba: rápido al despegar, se frena
                // arriba y acelera al caer.
                let t = p / airTime
                let height = 4 * t * (1 - t)
                scale = 1 + 0.45 * height
                elevation = height
            } else {
                // Al aterrizar se aplasta un poco por debajo de su tamaño y se recupera.
                let t = (p - airTime) / (1 - airTime)
                scale = 1 - 0.1 * sin(.pi * t)
            }

        case .shine:
            shineOffset = p * 2 - 1

        case .off:
            break
        }
    }
}
