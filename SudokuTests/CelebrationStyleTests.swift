//
//  CelebrationStyleTests.swift
//  SudokuTests
//

import Testing
@testable import Sudoku

@Suite("Estilos de celebración")
struct CelebrationStyleTests {

    /// Muestras del progreso de 0 a 1, para recorrer una animación entera.
    private let samples = stride(from: 0.0, through: 1.0, by: 0.01).map { $0 }

    // MARK: - Principio y final

    @Test("Al empezar y al terminar la celda queda como estaba", arguments: CelebrationStyle.allCases)
    func startsAndEndsAtRest(style: CelebrationStyle) {
        #expect(CelebrationFrame(style: style, progress: 0, allowsMotion: true) == .rest)
        #expect(CelebrationFrame(style: style, progress: 1, allowsMotion: true) == .rest)
    }

    @Test("Un progreso fuera de rango no produce efectos", arguments: [-0.5, 1.5])
    func outOfRangeProgressIsAtRest(progress: Double) {
        #expect(CelebrationFrame(style: .wave, progress: progress, allowsMotion: true) == .rest)
    }

    @Test("\"Ninguna\" nunca hace nada")
    func offDoesNothing() {
        for progress in samples {
            #expect(CelebrationFrame(style: .off, progress: progress, allowsMotion: true) == .rest)
        }
    }

    // MARK: - Reducir movimiento

    @Test(
        "Sin movimiento solo queda el tinte",
        arguments: CelebrationStyle.allCases.filter { $0 != .off }
    )
    func reducedMotionKeepsOnlyTint(style: CelebrationStyle) {
        let frame = CelebrationFrame(style: style, progress: 0.5, allowsMotion: false)

        #expect(frame.tint > 0, "El color sigue avisando de la celebración")
        #expect(frame.scale == 1)
        #expect(frame.rotation == 0)
        #expect(frame.elevation == 0)
        #expect(frame.shineOffset == nil)
    }

    // MARK: - Cada estilo

    @Test("La onda agranda el número a mitad de camino")
    func waveGrows() {
        let frame = CelebrationFrame(style: .wave, progress: 0.5, allowsMotion: true)

        #expect(frame.scale > 1.2)
        #expect(frame.tint > 0.9)
    }

    @Test("El volteo nunca enseña el número reflejado")
    func flipNeverShowsBackSide() {
        // Entre 90° y 270° se vería el reverso de la "carta", con la cifra al revés. El volteo se
        // queda siempre en −90°…90°, de cara o de canto.
        for progress in samples {
            let rotation = CelebrationFrame(style: .flip, progress: progress, allowsMotion: true).rotation
            #expect((-90...90).contains(rotation), "Progreso \(progress): \(rotation)°")
        }
    }

    @Test("El volteo pasa de canto a mitad de camino")
    func flipIsEdgeOnHalfway() {
        let rotation = CelebrationFrame(style: .flip, progress: 0.5, allowsMotion: true).rotation

        #expect(abs(rotation) == 90)
    }

    @Test("El salto agranda el número hacia quien mira y vuelve a su tamaño")
    func jumpGrowsTowardViewer() {
        let frames = samples.map { CelebrationFrame(style: .jump, progress: $0, allowsMotion: true) }
        let scales = frames.map(\.scale)

        #expect((scales.max() ?? 0) > 1.4, "Se nota el salto")
        // A 0.52 del lado de la celda, el número sigue cabiendo en su recuadro con esta escala.
        #expect((scales.max() ?? 0) <= 1.5, "No se sale de su recuadro")
        #expect((frames.map(\.elevation).max() ?? 0) > 0.9, "La sombra acompaña la altura")
    }

    @Test("Al aterrizar el salto se aplasta un poco, sin exagerar")
    func jumpSquashesOnLanding() {
        let landing = samples
            .filter { $0 > 0.7 }
            .map { CelebrationFrame(style: .jump, progress: $0, allowsMotion: true) }

        let smallest = landing.map(\.scale).min() ?? 1
        #expect(smallest < 0.95)
        #expect(smallest > 0.85)
        #expect(landing.allSatisfy { $0.elevation == 0 }, "Ya está en el suelo: sin sombra")
    }

    @Test("El salto no tiene saltos bruscos de tamaño")
    func jumpIsContinuous() {
        // Entre muestra y muestra (1 % del tiempo) la escala nunca cambia de golpe, ni siquiera
        // al pasar del aire al aterrizaje.
        let scales = samples.map { CelebrationFrame(style: .jump, progress: $0, allowsMotion: true).scale }

        for (previous, next) in zip(scales, scales.dropFirst()) {
            #expect(abs(next - previous) < 0.05)
        }
    }

    @Test("La franja de luz cruza la celda de izquierda a derecha")
    func shineCrossesLeftToRight() {
        let offsets = samples.dropFirst().dropLast().compactMap {
            CelebrationFrame(style: .shine, progress: $0, allowsMotion: true).shineOffset
        }

        #expect(offsets.count == samples.count - 2, "Hay franja durante toda la animación")
        #expect(offsets == offsets.sorted(), "Siempre avanza en el mismo sentido")
        #expect((offsets.first ?? 0) < -0.9)
        #expect((offsets.last ?? 0) > 0.9)
    }

    // MARK: - Duración

    @Test("La celebración dura lo que tarda en llegar a la última celda más su animación")
    func totalDurationCoversLastCell() {
        let style = CelebrationStyle.flip
        let lastCellStarts = 8 * CelebrationStyle.stepDelay

        #expect(style.totalDuration(cellCount: 9) >= lastCellStarts + style.cellDuration)
    }

    @Test("Cada estilo con animación tarda algo en cada celda", arguments: CelebrationStyle.allCases)
    func cellDurations(style: CelebrationStyle) {
        if style == .off {
            #expect(style.cellDuration == 0)
        } else {
            #expect(style.cellDuration > 0)
        }
    }
}
