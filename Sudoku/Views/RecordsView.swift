//
//  RecordsView.swift
//  Sudoku
//

import SwiftData
import SwiftUI

/// La ventana de récords: una tabla por dificultad con los mejores tiempos.
struct RecordsView: View {
    /// El identificador con el que se abre la ventana desde `openWindow`.
    static let windowID = "records"

    /// La clave de la dificultad que se está mirando. La comparte con `ContentView`, que la fija
    /// antes de abrir la ventana para que se abra en la dificultad de la partida.
    static let difficultyKey = "records.difficulty"

    @AppStorage(RecordsView.difficultyKey) private var difficultyRaw = Difficulty.medium.rawValue

    private var difficulty: Difficulty {
        Difficulty(rawValue: difficultyRaw) ?? .medium
    }

    var body: some View {
        RecordsTable(difficulty: difficulty)
            // Una tabla nueva por dificultad: su `@Query` se crea con el filtro en el `init`, así
            // que cambiar de dificultad tiene que crear la vista otra vez.
            .id(difficulty)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Difficulty", selection: $difficultyRaw) {
                        ForEach(Difficulty.allCases) { difficulty in
                            Text(difficulty.displayName).tag(difficulty.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .frame(minWidth: 520, minHeight: 360)
    }
}

/// La tabla de una dificultad.
///
/// Lee los récords con `@Query`, que vigila la base de datos: cuando se guarda o se borra un
/// récord, esta vista se actualiza sola, aunque el cambio se haga desde otra ventana.
private struct RecordsTable: View {
    @Query private var records: [GameRecord]
    @Environment(\.modelContext) private var context

    init(difficulty: Difficulty) {
        // Mismo filtro y mismo orden que `RecordStore.records(for:)`, para que la ventana y la
        // tarjeta de victoria nunca discrepen sobre el puesto.
        let raw = difficulty.rawValue
        var descriptor = FetchDescriptor<GameRecord>(
            predicate: #Predicate { $0.difficultyRaw == raw },
            sortBy: [SortDescriptor(\.time), SortDescriptor(\.date)]
        )
        descriptor.fetchLimit = RecordStore.tableSize
        _records = Query(descriptor)
    }

    var body: some View {
        if records.isEmpty {
            ContentUnavailableView {
                Label("No Records Yet", systemImage: "trophy")
            } description: {
                Text("Win a game on this difficulty to set the first record.")
            }
        } else {
            table
        }
    }

    private var table: some View {
        Table(records) {
            TableColumn("#") { record in
                Text("\(rank(of: record))")
                    .monospacedDigit()
                    .fontWeight(rank(of: record) == 1 ? .bold : .regular)
            }
            .width(28)

            TableColumn("Name") { record in
                Text(record.playerName)
            }

            TableColumn("Time") { record in
                Text(TimerLabel.format(record.time))
                    .monospacedDigit()
            }
            .width(70)

            TableColumn("Lives") { record in
                livesLabel(record.lives)
            }
            .width(60)

            TableColumn("Mistakes") { record in
                Text("\(record.mistakes)")
                    .monospacedDigit()
            }
            .width(70)

            TableColumn("Date") { record in
                // `Text` con formato usa el idioma del entorno, así que sigue al elegido en los
                // ajustes; `date.formatted()` usaría siempre el del sistema.
                Text(record.date, format: .dateTime.day().month(.abbreviated).year())
            }
        }
        .contextMenu(forSelectionType: GameRecord.ID.self) { ids in
            Button("Delete Record", role: .destructive) {
                delete(ids)
            }
            .disabled(ids.isEmpty)
        }
    }

    /// El puesto de un récord en la tabla, desde 1.
    private func rank(of record: GameRecord) -> Int {
        (records.firstIndex(of: record) ?? 0) + 1
    }

    @ViewBuilder
    private func livesLabel(_ lives: Int) -> some View {
        if lives == 0 {
            // `verbatim`: es un símbolo, no un texto que traducir.
            Text(verbatim: "∞")
                .accessibilityLabel("Unlimited")
        } else {
            Label("\(lives)", systemImage: "heart.fill")
                .labelStyle(.titleAndIcon)
                .monospacedDigit()
                .foregroundStyle(.pink)
        }
    }

    private func delete(_ ids: Set<GameRecord.ID>) {
        let store = RecordStore(context: context)
        for record in records where ids.contains(record.id) {
            try? store.delete(record)
        }
    }
}

#Preview("Con récords") {
    let container = previewRecordsContainer(filled: true)
    return RecordsView()
        .modelContainer(container)
}

#Preview("Vacía") {
    RecordsView()
        .modelContainer(previewRecordsContainer(filled: false))
}

/// Una base de datos en memoria para las previews, con algunos récords inventados.
@MainActor
private func previewRecordsContainer(filled: Bool) -> ModelContainer {
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: GameRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("No se pudo crear la base de datos de la preview: \(error)")
    }

    if filled {
        let store = RecordStore(context: container.mainContext)
        let samples: [(String, TimeInterval, Int?, Int)] = [
            ("Víctor", 312, 3, 0), ("Ana", 358, 1, 0), ("Luis", 401, nil, 4),
            ("Víctor", 455, 5, 2), ("???", 610, 3, 1),
        ]
        for (index, sample) in samples.enumerated() {
            _ = try? store.save(
                playerName: sample.0,
                time: sample.1,
                difficulty: .medium,
                lives: sample.2,
                mistakes: sample.3,
                date: .now.addingTimeInterval(Double(-index) * 86_400)
            )
        }
    }
    return container
}
