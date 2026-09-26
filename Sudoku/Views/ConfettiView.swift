//
//  ConfettiView.swift
//  Sudoku
//

import SwiftUI

/// Una lluvia de confeti que se lanza una sola vez al aparecer.
///
/// `TimelineView` da el ritmo (un fotograma por refresco de pantalla) y `Canvas` dibuja todos los
/// trozos en una sola capa. Crear una vista por trozo serían 140 vistas que SwiftUI tendría que
/// comparar en cada fotograma; con `Canvas` solo se dibujan formas.
///
/// Quien la usa decide si mostrarla: con Reduce Motion no debería aparecer.
struct ConfettiView: View {
    /// Los trozos se sortean una vez, al crear la vista, y ya no cambian.
    @State private var pieces: [ConfettiPiece] = {
        var generator = SystemRandomNumberGenerator()
        return ConfettiPiece.burst(using: &generator)
    }()

    /// Cuándo se lanzó. Todo el movimiento se calcula como tiempo transcurrido desde aquí.
    @State private var launchDate = Date.now

    /// Cuando el último trozo ha desaparecido, el `TimelineView` se pausa y deja de pedir
    /// fotogramas. Sin esto seguiría redibujando una capa vacía a 60 o 120 fps.
    @State private var isFinished = false

    /// Los colores, en el orden de `ConfettiPiece.colorIndex`.
    private let palette: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    /// Si no es `nil`, el confeti se queda quieto en ese instante en lugar de animarse.
    private let frozenTime: Double?

    /// - Parameter frozenTime: solo para previews. Una preview toma su imagen al empezar, cuando
    ///   todo el confeti sigue por encima del borde; congelarlo permite ver cómo se dibuja.
    init(frozenAt frozenTime: Double? = nil) {
        self.frozenTime = frozenTime
    }

    var body: some View {
        Group {
            if let frozenTime {
                canvas(at: frozenTime)
            } else {
                TimelineView(.animation(paused: isFinished)) { timeline in
                    canvas(at: timeline.date.timeIntervalSince(launchDate))
                }
            }
        }
        // Es decoración: ni tapa los botones de la tarjeta de victoria ni lo lee VoiceOver.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(for: .seconds(ConfettiPiece.totalDuration))
            isFinished = true
        }
    }

    /// Todos los trozos tal como están `time` segundos después del lanzamiento.
    private func canvas(at time: Double) -> some View {
        Canvas { context, size in
            for piece in pieces {
                guard let snapshot = piece.snapshot(at: time) else { continue }
                draw(piece, snapshot, in: &context, size: size)
            }
        }
    }

    private func draw(
        _ piece: ConfettiPiece,
        _ snapshot: ConfettiPiece.Snapshot,
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        // Cada trozo trabaja sobre una copia del contexto: así sus transformaciones no se
        // acumulan sobre las del siguiente.
        var context = context
        context.opacity = snapshot.opacity
        context.translateBy(x: snapshot.x * size.width, y: snapshot.y * size.height)
        context.rotate(by: .degrees(snapshot.rotation))
        // Aplastar en vertical según el aleteo simula que gira en 3D; al llegar a 0 queda de canto.
        context.scaleBy(x: 1, y: snapshot.flutter)

        let color = palette[piece.colorIndex % palette.count]
        context.fill(path(for: piece.shape), with: .color(color))
    }

    /// La forma de cada tipo de trozo, centrada en el origen.
    private func path(for shape: ConfettiPiece.Shape) -> Path {
        switch shape {
        case .strip:
            Path(CGRect(x: -2.5, y: -6, width: 5, height: 12))
        case .square:
            Path(CGRect(x: -4, y: -4, width: 8, height: 8))
        case .circle:
            Path(ellipseIn: CGRect(x: -3.5, y: -3.5, width: 7, height: 7))
        }
    }
}

#Preview("Animado") {
    ConfettiView()
        .frame(width: 460, height: 600)
        .background(.background)
}

#Preview("Congelado a 1.4 s") {
    ConfettiView(frozenAt: 1.4)
        .frame(width: 460, height: 600)
        .background(.background)
}

#Preview("Sobre la victoria") {
    ZStack {
        VictoryOverlay(
            elapsed: 245,
            mistakeCount: 0,
            record: VictoryRecordInfo(),
            playerName: .constant(""),
            onSaveRecord: {},
            onShowRecords: {},
            onNewGame: {}
        )
        ConfettiView(frozenAt: 1.4)
    }
    .frame(width: 460, height: 600)
}
