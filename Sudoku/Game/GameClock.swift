//
//  GameClock.swift
//  Sudoku
//

import Foundation

/// Un cronómetro acumulador para medir cuánto se tarda en una partida.
///
/// No contiene ningún temporizador: solo guarda cuándo arrancó el tramo actual y cuánto tiempo
/// suman los tramos anteriores. Quien lo dibuja decide cada cuánto preguntar la hora.
///
/// `elapsed(at:)` **recibe el instante como parámetro** en lugar de leer `Date.now` por dentro. Esa
/// es la decisión que lo hace comprobable: las pruebas le pasan fechas fijas y no tienen que
/// esperar tiempo real.
nonisolated struct GameClock: Equatable, Sendable {
    /// Cuándo empezó el tramo en curso, o `nil` si está detenido.
    private(set) var startedAt: Date?

    /// Tiempo sumado por los tramos ya cerrados.
    private(set) var accumulated: TimeInterval = 0

    var isRunning: Bool { startedAt != nil }

    init() {}

    /// Arranca el cronómetro. No hace nada si ya estaba corriendo.
    mutating func start(at now: Date) {
        guard startedAt == nil else { return }
        startedAt = now
    }

    /// Detiene el cronómetro y guarda el tramo. No hace nada si ya estaba detenido.
    mutating func stop(at now: Date) {
        guard let startedAt else { return }

        accumulated += max(0, now.timeIntervalSince(startedAt))
        self.startedAt = nil
    }

    /// Vuelve a cero y queda detenido.
    mutating func reset() {
        startedAt = nil
        accumulated = 0
    }

    /// Vuelve a cero y arranca de inmediato.
    mutating func restart(at now: Date) {
        reset()
        start(at: now)
    }

    /// El tiempo total transcurrido visto desde `now`.
    ///
    /// El `max(0, …)` protege de un salto del reloj del sistema hacia atrás (un cambio de hora, por
    /// ejemplo), que si no daría un tiempo negativo.
    func elapsed(at now: Date) -> TimeInterval {
        guard let startedAt else { return accumulated }
        return accumulated + max(0, now.timeIntervalSince(startedAt))
    }
}
