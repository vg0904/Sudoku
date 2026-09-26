//
//  ConfettiPiece.swift
//  Sudoku
//

import Foundation

/// Un trozo de confeti y cómo se mueve.
///
/// Es solo física: dónde está, cuánto ha girado y cuánto se ve en cada instante. No sabe nada de
/// SwiftUI, así que se puede probar sin dibujar nada. Las posiciones van en **unidades
/// relativas** (0 = borde izquierdo o superior, 1 = borde derecho o inferior) para que el mismo
/// confeti sirva para cualquier tamaño de ventana.
nonisolated struct ConfettiPiece: Equatable, Sendable {
    enum Shape: CaseIterable, Sendable {
        /// Una tira alargada, el confeti clásico.
        case strip
        case square
        case circle
    }

    /// Dónde empieza en horizontal.
    let startX: Double
    /// Dónde empieza en vertical. Siempre por encima del borde superior, así que entra cayendo.
    let startY: Double
    /// Cuánto espera antes de empezar a caer. Repartir las esperas hace que llueva en lugar de
    /// caer todo en bloque.
    let delay: Double
    /// Velocidad inicial hacia abajo, en alturas por segundo.
    let fallSpeed: Double
    /// Deriva lateral constante, en anchos por segundo. Negativa va hacia la izquierda.
    let drift: Double
    /// Amplitud del vaivén lateral, como un papel que cae balanceándose.
    let swayAmplitude: Double
    /// Rapidez del vaivén y del aleteo, en radianes por segundo.
    let swayFrequency: Double
    /// Desfase del vaivén, para que no se balanceen todas a la vez.
    let phase: Double
    /// Giro en el plano, en grados por segundo.
    let spin: Double
    let colorIndex: Int
    let shape: Shape

    // MARK: - Constantes de la física

    /// Aceleración hacia abajo, en alturas por segundo al cuadrado. Es baja a propósito: el
    /// confeti de papel cae despacio por el rozamiento con el aire.
    static let gravity = 0.25
    /// Lo que vive cada trozo desde que empieza a caer.
    static let lifetime = 2.6
    /// Los últimos segundos de vida, en los que se desvanece.
    static let fadeDuration = 0.6
    /// La espera más larga que puede tocarle a un trozo.
    static let maxDelay = 0.8
    /// Cuánto dura el confeti entero: el último trozo en arrancar más su vida.
    static let totalDuration = maxDelay + lifetime
    /// Cuántos colores distintos hay; la vista decide cuáles son.
    static let colorCount = 7

    /// Dónde está un trozo en un instante.
    struct Snapshot: Equatable, Sendable {
        var x: Double
        var y: Double
        /// Giro en el plano, en grados.
        var rotation: Double
        /// De −1 a 1: cuánto se ve de frente. Al pasar por 0 está de canto; así parece que
        /// aletea en 3D sin tener que dibujar en 3D.
        var flutter: Double
        var opacity: Double
    }

    /// El estado del trozo `time` segundos después de lanzar el confeti, o `nil` si todavía no ha
    /// arrancado o ya terminó.
    func snapshot(at time: Double) -> Snapshot? {
        let t = time - delay
        guard t >= 0, t <= Self.lifetime else { return nil }

        // Caída con aceleración constante: y = y₀ + v·t + ½·g·t².
        let y = startY + fallSpeed * t + 0.5 * Self.gravity * t * t
        let x = startX + drift * t + swayAmplitude * sin(swayFrequency * t + phase)

        let fadeStart = Self.lifetime - Self.fadeDuration
        let opacity = t < fadeStart ? 1 : max(0, 1 - (t - fadeStart) / Self.fadeDuration)

        return Snapshot(
            x: x,
            y: y,
            rotation: spin * t,
            // El aleteo va al doble del vaivén: el papel gira más rápido de lo que se balancea.
            flutter: cos(swayFrequency * 2 * t + phase),
            opacity: opacity
        )
    }

    /// Un lanzamiento completo de confeti con valores al azar.
    ///
    /// Recibe el generador para que las pruebas usen uno con semilla y obtengan siempre el mismo
    /// confeti; la app usa el del sistema.
    static func burst(count: Int = 140, using generator: inout some RandomNumberGenerator) -> [ConfettiPiece] {
        (0..<count).map { _ in
            ConfettiPiece(
                startX: .random(in: 0...1, using: &generator),
                startY: .random(in: -0.25 ... -0.03, using: &generator),
                delay: .random(in: 0...maxDelay, using: &generator),
                fallSpeed: .random(in: 0.05...0.2, using: &generator),
                drift: .random(in: -0.06...0.06, using: &generator),
                swayAmplitude: .random(in: 0.005...0.025, using: &generator),
                swayFrequency: .random(in: 3...7, using: &generator),
                phase: .random(in: 0...(2 * .pi), using: &generator),
                spin: .random(in: -360...360, using: &generator),
                colorIndex: .random(in: 0..<colorCount, using: &generator),
                shape: Shape.allCases.randomElement(using: &generator) ?? .strip
            )
        }
    }
}
