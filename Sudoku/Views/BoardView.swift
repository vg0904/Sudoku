//
//  BoardView.swift
//  Sudoku
//

import SwiftUI

/// El tablero de 9×9.
///
/// Las celdas no dibujan sus propios bordes: las líneas van en un único `overlay` con un `Path`.
/// Así se evitan los bordes dobles entre celdas vecinas y las líneas gruesas de cada caja 3×3
/// salen sin anidar vistas.
struct BoardView: View {
    let game: SudokuGame
    let settings: GameSettings

    private let cornerRadius: CGFloat = 10

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.themeColor) private var themeColor

    /// Cualquiera de los dos ajustes basta para quitar el movimiento.
    private var allowsMotion: Bool {
        !settings.reduceEffects && !systemReduceMotion
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cellSide = side / CGFloat(SudokuGrid.size)
            // Se calculan una sola vez por dibujado: consultarlos dentro del bucle los
            // reconstruiría 81 veces.
            // Las ayudas se pueden apagar en los ajustes; con un conjunto vacío no se resalta nada.
            let matching = settings.highlightMatches ? game.matchingValueIndices : []
            let highlighted = settings.highlightGroups ? game.highlightedIndices : []
            // Con los efectos reducidos la celebración sigue, pero solo con el tinte: lo decide
            // `CelebrationFrame` a partir de `allowsMotion`. Para quitarla está el estilo "Ninguna".
            let pulses = settings.celebrationStyle == .off ? [:] : celebrationPulses

            VStack(spacing: 0) {
                ForEach(0..<SudokuGrid.size, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<SudokuGrid.size, id: \.self) { column in
                            let index = SudokuGrid.index(row: row, column: column)

                            CellView(
                                value: game.value(at: index),
                                state: game.state(at: index),
                                isMatching: matching.contains(index),
                                isHighlighted: highlighted.contains(index),
                                pulse: pulses[index],
                                // Solo la celda del error recibe el evento; las demás, `nil`.
                                mistake: game.lastMistake?.index == index ? game.lastMistake : nil,
                                allowsMotion: allowsMotion,
                                celebrationStyle: settings.celebrationStyle,
                                sideLength: cellSide
                            )
                            .onTapGesture { game.select(index) }
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            // Las capas de fondo quedan debajo de las celdas. Como el fondo de cada celda es
            // translúcido, se siguen viendo a través.
            .background {
                alternateBoxes(side: side)
                    .fill(.primary.opacity(0.05))

                selectionMarker(cellSide: cellSide, side: side) { shape in
                    shape.fill(themeColor.opacity(0.28))
                }
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay {
                innerLines(side: side)
                    .stroke(.separator, lineWidth: 1)
            }
            .overlay {
                boxLines(side: side)
                    .stroke(.primary.opacity(0.6), lineWidth: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(.primary.opacity(0.6), lineWidth: 2)
            }
            // El borde de la selección va encima de las líneas, para que se lea como un marco
            // y no quede cortado por ellas.
            .overlay {
                selectionMarker(cellSide: cellSide, side: side) { shape in
                    shape.strokeBorder(themeColor, lineWidth: 2)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// El retardo de cada celda que participa en la celebración, indexado por celda.
    ///
    /// El modelo ya entrega los índices ordenados desde la jugada, así que aquí basta con repartir
    /// un retardo creciente: eso es lo que produce la onda.
    private var celebrationPulses: [Int: CellPulse] {
        guard let celebration = game.celebration else { return [:] }

        let step = CelebrationStyle.stepDelay
        return Dictionary(
            uniqueKeysWithValues: celebration.indices.enumerated().map { position, index in
                (index, CellPulse(celebrationID: celebration.id, delay: Double(position) * step))
            }
        )
    }

    /// El resaltado de la celda seleccionada, colocado encima de ella.
    ///
    /// Es **una sola vista** que cambia de posición, en lugar de un fondo que cada celda enciende
    /// y apaga. Por eso, al animar la posición, se ve deslizarse de una celda a otra. Se usa dos
    /// veces (relleno debajo, borde encima) con la misma posición, así que se mueven juntas.
    @ViewBuilder
    private func selectionMarker<Marker: View>(
        cellSide: CGFloat,
        side: CGFloat,
        @ViewBuilder marker: (RoundedRectangle) -> Marker
    ) -> some View {
        if let selected = game.selectedIndex {
            marker(RoundedRectangle(cornerRadius: 4))
                .frame(width: cellSide, height: cellSide)
                .offset(
                    x: CGFloat(SudokuGrid.column(of: selected)) * cellSide,
                    y: CGFloat(SudokuGrid.row(of: selected)) * cellSide
                )
                .frame(width: side, height: side, alignment: .topLeading)
                // Sin movimiento, la selección salta directamente, como antes.
                .animation(
                    allowsMotion ? .spring(duration: 0.22, bounce: 0.15) : nil,
                    value: selected
                )
        }
    }

    /// Las cajas 3×3 que llevan un tono de fondo, alternadas como en un tablero de ajedrez.
    ///
    /// Se sombrean las cuatro cajas de los lados. Las esquinas y el centro quedan limpias, así que
    /// ninguna caja sombreada toca a otra y cada una se distingue de un vistazo.
    private func alternateBoxes(side: CGFloat) -> Path {
        let boxSide = side / CGFloat(SudokuGrid.boxSize)
        var path = Path()

        for boxRow in 0..<SudokuGrid.boxSize {
            for boxColumn in 0..<SudokuGrid.boxSize where !(boxRow + boxColumn).isMultiple(of: 2) {
                path.addRect(CGRect(
                    x: CGFloat(boxColumn) * boxSide,
                    y: CGFloat(boxRow) * boxSide,
                    width: boxSide,
                    height: boxSide
                ))
            }
        }

        return path
    }

    /// Las líneas finas entre celdas que no son borde de caja.
    private func innerLines(side: CGFloat) -> Path {
        lines(side: side) { $0 % SudokuGrid.boxSize != 0 }
    }

    /// Las líneas gruesas que separan las cajas 3×3, sin incluir el borde exterior
    /// (ese lo dibuja el `strokeBorder` redondeado).
    private func boxLines(side: CGFloat) -> Path {
        lines(side: side) { $0 % SudokuGrid.boxSize == 0 }
    }

    private func lines(side: CGFloat, includeIndex: (Int) -> Bool) -> Path {
        let cellSide = side / CGFloat(SudokuGrid.size)
        var path = Path()

        // 1..<9: los extremos 0 y 9 son el borde exterior y se dibujan aparte.
        for step in 1..<SudokuGrid.size where includeIndex(step) {
            let offset = cellSide * CGFloat(step)

            path.move(to: CGPoint(x: offset, y: 0))
            path.addLine(to: CGPoint(x: offset, y: side))

            path.move(to: CGPoint(x: 0, y: offset))
            path.addLine(to: CGPoint(x: side, y: offset))
        }

        return path
    }
}

/// Una partida con una pista ya seleccionada, para ver el resaltado de coincidencias.
@MainActor
private func previewGame() -> SudokuGame {
    let game = SudokuGame(puzzle: SudokuGenerator.makePuzzle(difficulty: .easy))
    game.select((0..<SudokuGrid.cellCount).first { game.isGiven($0) } ?? 0)
    return game
}

#Preview {
    BoardView(
        game: previewGame(),
        settings: GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    )
    .padding()
    .frame(width: 400, height: 400)
}

#Preview("Tema naranja") {
    BoardView(
        game: previewGame(),
        settings: GameSettings(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    )
    .environment(\.themeColor, AppTheme.orange.color)
    .padding()
    .frame(width: 400, height: 400)
}
