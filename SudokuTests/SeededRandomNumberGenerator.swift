//
//  SeededRandomNumberGenerator.swift
//  SudokuTests
//

/// Un generador aleatorio reproducible (SplitMix64).
///
/// Es la pieza que hace posible probar el generador de tableros: con la misma semilla produce
/// siempre la misma secuencia, así que `SudokuGenerator` devuelve el mismo tablero en cada
/// ejecución y los fallos se pueden reproducir.
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
