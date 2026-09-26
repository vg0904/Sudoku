//
//  ConfettiTests.swift
//  SudokuTests
//

import Testing
@testable import Sudoku

@Suite("Confeti")
struct ConfettiTests {

    private func makeBurst(seed: UInt64 = 7) -> [ConfettiPiece] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return ConfettiPiece.burst(using: &generator)
    }

    /// Una pieza sin azar, para comprobar la física con números conocidos.
    private let steadyPiece = ConfettiPiece(
        startX: 0.5,
        startY: -0.1,
        delay: 0.5,
        fallSpeed: 0.1,
        drift: 0,
        swayAmplitude: 0,
        swayFrequency: 4,
        phase: 0,
        spin: 90,
        colorIndex: 0,
        shape: .strip
    )

    // MARK: - Lanzamiento

    @Test("La misma semilla da el mismo confeti")
    func burstIsDeterministic() {
        #expect(makeBurst(seed: 1) == makeBurst(seed: 1))
        #expect(makeBurst(seed: 1) != makeBurst(seed: 2))
    }

    @Test("Cada lanzamiento tiene las piezas pedidas y todas las formas")
    func burstHasRequestedPieces() {
        let burst = makeBurst()

        #expect(burst.count == 140)
        #expect(Set(burst.map(\.shape)).count == ConfettiPiece.Shape.allCases.count)
    }

    @Test("Todas las piezas empiezan fuera de la vista, por arriba")
    func piecesStartAboveTheTop() {
        // Si alguna empezara ya dentro, aparecería de golpe en mitad de la ventana.
        for piece in makeBurst() {
            let first = piece.snapshot(at: piece.delay)
            #expect((first?.y ?? 0) < 0)
        }
    }

    @Test("Los colores siempre existen en la paleta")
    func colorIndicesAreInRange() {
        for piece in makeBurst() {
            #expect((0..<ConfettiPiece.colorCount).contains(piece.colorIndex))
        }
    }

    // MARK: - Movimiento

    @Test("Antes de su turno la pieza no se dibuja")
    func pieceWaitsForItsDelay() {
        #expect(steadyPiece.snapshot(at: 0.2) == nil)
        #expect(steadyPiece.snapshot(at: 0.5) != nil)
    }

    @Test("La gravedad hace que caiga cada vez más rápido")
    func gravityAccelerates() throws {
        let y0 = try #require(steadyPiece.snapshot(at: 0.5)).y
        let y1 = try #require(steadyPiece.snapshot(at: 1.0)).y
        let y2 = try #require(steadyPiece.snapshot(at: 1.5)).y

        #expect(y1 > y0, "Baja")
        #expect(y2 - y1 > y1 - y0, "Cada medio segundo recorre más que el anterior")
    }

    @Test("Gira según su velocidad de giro")
    func spinsOverTime() throws {
        let snapshot = try #require(steadyPiece.snapshot(at: 1.5))

        // Un segundo después de arrancar, a 90 °/s.
        #expect(abs(snapshot.rotation - 90) < 0.001)
    }

    @Test("El aleteo siempre está entre de frente y de canto")
    func flutterStaysInRange() {
        for piece in makeBurst() {
            for time in stride(from: 0.0, through: ConfettiPiece.totalDuration, by: 0.1) {
                if let snapshot = piece.snapshot(at: time) {
                    #expect((-1...1).contains(snapshot.flutter))
                }
            }
        }
    }

    // MARK: - Final

    @Test("Se ve entera hasta que empieza a desvanecerse")
    func fullyVisibleBeforeFade() throws {
        let snapshot = try #require(steadyPiece.snapshot(at: steadyPiece.delay + 1))

        #expect(snapshot.opacity == 1)
    }

    @Test("Al final de su vida ya no se ve")
    func fadesOutAtTheEnd() throws {
        let end = steadyPiece.delay + ConfettiPiece.lifetime
        let snapshot = try #require(steadyPiece.snapshot(at: end))

        #expect(snapshot.opacity == 0)
        #expect(steadyPiece.snapshot(at: end + 0.1) == nil)
    }

    @Test("Cuando termina el confeti no queda ninguna pieza")
    func nothingRemainsAfterTotalDuration() {
        // Es lo que permite pausar el `TimelineView` sin cortar ninguna pieza a medias.
        for piece in makeBurst() {
            #expect(piece.snapshot(at: ConfettiPiece.totalDuration + 0.01) == nil)
        }
    }
}
