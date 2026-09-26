//
//  TimerLabel.swift
//  Sudoku
//

import SwiftUI

/// Muestra el tiempo de la partida en mm:ss.
///
/// Usa `TimelineView` en vez de guardar los segundos en el modelo a propósito: así **solo esta
/// etiqueta se redibuja cada segundo** y no las 81 celdas del tablero. También evita montar un
/// temporizador con Combine, que este proyecto no usa.
struct TimerLabel: View {
    let clock: GameClock
    /// En pausa, el icono cambia para que se vea de un vistazo por qué el tiempo no avanza.
    var isPaused = false

    var body: some View {
        Group {
            if clock.isRunning {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    label(elapsed: clock.elapsed(at: context.date))
                }
            } else {
                // Detenido no hay nada que refrescar, así que no se paga el coste del timeline.
                label(elapsed: clock.elapsed(at: .now))
            }
        }
        .accessibilityLabel("Elapsed time")
        .accessibilityValue(Self.accessibleText(clock.elapsed(at: .now)))
    }

    private func label(elapsed: TimeInterval) -> some View {
        Label(Self.format(elapsed), systemImage: isPaused ? "pause.circle" : "clock")
            .font(.title3.monospacedDigit())
            .foregroundStyle(.secondary)
            // Sin esto el ancho baila al cambiar de dígito y arrastra el resto de la cabecera.
            .contentTransition(.numericText())
    }

    /// Formatea como mm:ss, y añade las horas si la partida se alarga de verdad.
    static func format(_ elapsed: TimeInterval) -> String {
        let duration = Duration.seconds(max(0, elapsed))

        return duration.formatted(
            .time(pattern: elapsed >= 3600 ? .hourMinuteSecond : .minuteSecond)
        )
    }

    /// Una lectura en palabras, porque "05:09" en VoiceOver suena a fecha u hora del día.
    static func accessibleText(_ elapsed: TimeInterval) -> String {
        Duration.seconds(max(0, elapsed)).formatted(.units(allowed: [.hours, .minutes, .seconds]))
    }
}

/// Un reloj que lleva `seconds` corriendo, para las previews.
private func runningClock(seconds: TimeInterval) -> GameClock {
    var clock = GameClock()
    clock.start(at: .now.addingTimeInterval(-seconds))
    return clock
}

private func stoppedClock(seconds: TimeInterval) -> GameClock {
    var clock = runningClock(seconds: seconds)
    clock.stop(at: .now)
    return clock
}

#Preview("Corriendo") {
    TimerLabel(clock: runningClock(seconds: 155)).padding()
}

#Preview("Detenido, más de una hora") {
    TimerLabel(clock: stoppedClock(seconds: 3725)).padding()
}
