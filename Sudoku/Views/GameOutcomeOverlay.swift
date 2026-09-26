//
//  GameOutcomeOverlay.swift
//  Sudoku
//

import SwiftUI

/// El panel que aparece sobre el tablero cuando la partida termina, se gane o se pierda.
///
/// Nunca se cierra solo: la HIG pide evitar elementos que se descartan por temporizador, porque
/// penalizan a quien necesita más tiempo para leer. Siempre hace falta pulsar un botón.
struct GameOutcomeOverlay<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                content
            }
            .padding(36)
            .background(.background.secondary, in: .rect(cornerRadius: 18))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

/// Lo que la tarjeta de victoria necesita saber sobre los récords.
struct VictoryRecordInfo {
    /// El puesto que ocupa este tiempo en la tabla, o `nil` si no entra (o si la partida no
    /// cuenta para récords).
    var rank: Int?
    /// El mejor tiempo que había antes de esta partida, o `nil` si no había ninguno.
    var previousBest: TimeInterval?
    /// Los nombres usados otras veces, para elegirlos sin escribirlos.
    var knownNames: [String] = []
    /// `true` cuando el récord ya está guardado.
    var isSaved = false
}

/// Se muestra al resolver el tablero.
struct VictoryOverlay: View {
    let elapsed: TimeInterval
    let mistakeCount: Int
    let record: VictoryRecordInfo
    /// El nombre que se está escribiendo para el récord.
    @Binding var playerName: String
    let onSaveRecord: () -> Void
    let onShowRecords: () -> Void
    let onNewGame: () -> Void

    @FocusState private var isNameFocused: Bool

    var body: some View {
        GameOutcomeOverlay {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text("Solved!")
                .font(.largeTitle.bold())

            Text(TimerLabel.format(elapsed))
                .font(.system(.title, design: .rounded).monospacedDigit())

            mistakeSummary
                .foregroundStyle(.secondary)

            recordSection
                .padding(.top, 6)

            HStack(spacing: 10) {
                Button("Records", action: onShowRecords)

                Button("New Game", action: onNewGame)
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.top, 4)
        }
        .onAppear {
            // Con récord pendiente, el cursor ya está en el nombre: basta con pulsar Intro.
            if record.rank != nil, !record.isSaved {
                isNameFocused = true
            }
        }
    }

    // MARK: - Récord

    @ViewBuilder
    private var recordSection: some View {
        if let rank = record.rank {
            VStack(spacing: 10) {
                Label("New record! #\(rank)", systemImage: "trophy.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)

                if record.isSaved {
                    Label("Saved as \(playerName)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                } else {
                    nameEntry
                }
            }
        } else if let previousBest = record.previousBest {
            Text("Your best: \(TimerLabel.format(previousBest))")
                .foregroundStyle(.secondary)
        }
    }

    /// El campo del nombre, como en las recreativas: ya viene escrito el último que se usó.
    private var nameEntry: some View {
        HStack(spacing: 6) {
            TextField("Your name", text: $playerName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 170)
                .focused($isNameFocused)
                .onSubmit(onSaveRecord)

            // Los "perfiles": los nombres de récords anteriores, a un clic.
            if !record.knownNames.isEmpty {
                Menu {
                    ForEach(record.knownNames, id: \.self) { name in
                        Button(name) { playerName = name }
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Choose a previous name")
            }

            Button("Save", action: onSaveRecord)
        }
    }

    /// El resumen de errores.
    ///
    /// Tiene que devolver `Text` y no `String`: `Text(someString)` no localiza, así que con un
    /// `String` estas frases nunca se traducirían. El plural se resuelve con una variación
    /// explícita en el catálogo.
    @ViewBuilder
    private var mistakeSummary: some View {
        if mistakeCount == 0 {
            Text("Not a single mistake.")
        } else {
            Text("With \(mistakeCount) mistakes.")
        }
    }
}

/// Se muestra al agotar los corazones.
struct DefeatOverlay: View {
    let elapsed: TimeInterval
    let onRetry: () -> Void
    let onNewGame: () -> Void

    var body: some View {
        GameOutcomeOverlay {
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 52))
                .foregroundStyle(.red)

            Text("You ran out of hearts")
                .font(.title.bold())

            Text(TimerLabel.format(elapsed))
                .font(.system(.title2, design: .rounded).monospacedDigit())
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Try This Board Again", action: onRetry)
                    .buttonStyle(.borderedProminent)

                Button("New Game", action: onNewGame)
            }
            .controlSize(.large)
            .padding(.top, 4)
        }
    }
}

#Preview("Nuevo récord") {
    @Previewable @State var name = "Víctor"
    VictoryOverlay(
        elapsed: 245,
        mistakeCount: 0,
        record: VictoryRecordInfo(rank: 2, previousBest: 212, knownNames: ["Víctor", "Ana"]),
        playerName: $name,
        onSaveRecord: {},
        onShowRecords: {},
        onNewGame: {}
    )
    .frame(width: 460, height: 600)
}

#Preview("Récord guardado") {
    @Previewable @State var name = "Víctor"
    VictoryOverlay(
        elapsed: 245,
        mistakeCount: 0,
        record: VictoryRecordInfo(rank: 2, previousBest: 212, isSaved: true),
        playerName: $name,
        onSaveRecord: {},
        onShowRecords: {},
        onNewGame: {}
    )
    .frame(width: 460, height: 600)
}

#Preview("Sin récord, con errores") {
    @Previewable @State var name = ""
    VictoryOverlay(
        elapsed: 1325,
        mistakeCount: 4,
        record: VictoryRecordInfo(rank: nil, previousBest: 212),
        playerName: $name,
        onSaveRecord: {},
        onShowRecords: {},
        onNewGame: {}
    )
    .frame(width: 460, height: 600)
}

#Preview("Derrota") {
    DefeatOverlay(elapsed: 88, onRetry: {}, onNewGame: {})
        .frame(width: 460, height: 560)
}
