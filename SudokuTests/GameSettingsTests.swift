//
//  GameSettingsTests.swift
//  SudokuTests
//

import Foundation
import Testing
@testable import Sudoku

@Suite("Ajustes")
@MainActor
struct GameSettingsTests {

    /// Un `UserDefaults` propio de cada prueba.
    ///
    /// Es la razón por la que `GameSettings.init` recibe el `UserDefaults`: sin eso las pruebas
    /// escribirían en los ajustes reales de quien juega y se afectarían entre sí.
    private func makeIsolatedDefaults() -> (UserDefaults, cleanup: () -> Void) {
        let suiteName = "SudokuTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        return (defaults, { UserDefaults().removePersistentDomain(forName: suiteName) })
    }

    // MARK: - Valores por defecto

    @Test("Los valores por defecto son los esperados")
    func defaults() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let settings = GameSettings(defaults: defaults)

        #expect(settings.language == .automatic)
        #expect(settings.lives == 3)
        #expect(settings.maxLives == 3)
        #expect(settings.showTimer)
        #expect(settings.highlightGroups)
        #expect(settings.highlightMatches)
        #expect(!settings.reduceEffects)
        #expect(settings.celebrationStyle == .wave)
        #expect(settings.theme == .system)
    }

    // MARK: - Vidas

    @Test("Cero vidas significa sin límite")
    func zeroLivesMeansUnlimited() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let settings = GameSettings(defaults: defaults)
        settings.lives = 0

        #expect(settings.maxLives == nil)
    }

    @Test("Cada valor del selector se traduce a un límite", arguments: 1...5)
    func livesMapToLimit(count: Int) {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let settings = GameSettings(defaults: defaults)
        settings.lives = count

        #expect(settings.maxLives == count)
    }

    @Test("El rango del selector es de 1 a 5")
    func livesRange() {
        #expect(GameSettings.livesRange.lowerBound == 1)
        #expect(GameSettings.livesRange.upperBound == 5)
    }

    // MARK: - Persistencia

    @Test("Los cambios sobreviven a una instancia nueva")
    func changesPersist() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let first = GameSettings(defaults: defaults)
        first.language = .english
        first.lives = 5
        first.showTimer = false
        first.highlightGroups = false
        first.highlightMatches = false
        first.reduceEffects = true
        first.celebrationStyle = .flip
        first.theme = .green

        let second = GameSettings(defaults: defaults)

        #expect(second.language == .english)
        #expect(second.lives == 5)
        #expect(!second.showTimer)
        #expect(!second.highlightGroups)
        #expect(!second.highlightMatches)
        #expect(second.reduceEffects)
        #expect(second.celebrationStyle == .flip)
        #expect(second.theme == .green)
    }

    @Test("Un ajuste booleano guardado como false se distingue de no guardado")
    func falseIsNotTreatedAsMissing() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let first = GameSettings(defaults: defaults)
        first.showTimer = false

        let second = GameSettings(defaults: defaults)

        // Con `defaults.bool(forKey:)` esto fallaría: devuelve false tanto si se guardó false
        // como si no hay nada, y el valor volvería a su default de true.
        #expect(!second.showTimer)
    }

    @Test("Vidas guardadas como cero se distinguen de no guardadas")
    func zeroLivesIsNotTreatedAsMissing() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        let first = GameSettings(defaults: defaults)
        first.lives = 0

        let second = GameSettings(defaults: defaults)

        #expect(second.lives == 0)
        #expect(second.maxLives == nil)
    }

    @Test("Un idioma guardado que ya no existe cae en automático")
    func unknownLanguageFallsBack() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        defaults.set("klingon", forKey: "settings.language")

        let settings = GameSettings(defaults: defaults)

        #expect(settings.language == .automatic)
    }

    @Test("Un estilo de celebración guardado que ya no existe vuelve a la onda")
    func unknownCelebrationStyleFallsBack() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        defaults.set("fireworks", forKey: "settings.celebrationStyle")

        let settings = GameSettings(defaults: defaults)

        #expect(settings.celebrationStyle == .wave)
    }

    @Test("Un tema guardado que ya no existe vuelve al del sistema")
    func unknownThemeFallsBack() {
        let (defaults, cleanup) = makeIsolatedDefaults()
        defer { cleanup() }

        defaults.set("neon", forKey: "settings.theme")

        let settings = GameSettings(defaults: defaults)

        #expect(settings.theme == .system)
    }

    // MARK: - Idioma

    @Test("Automático no impone ningún locale")
    func automaticHasNoLocale() {
        #expect(AppLanguage.automatic.locale == nil)
    }

    @Test("Los idiomas explícitos dan su locale")
    func explicitLanguagesHaveLocales() {
        #expect(AppLanguage.spanish.locale?.identifier == "es")
        #expect(AppLanguage.english.locale?.identifier == "en")
    }

    @Test("El locale efectivo nunca es nulo", arguments: AppLanguage.allCases)
    func effectiveLocaleIsAlwaysResolved(language: AppLanguage) {
        #expect(!language.effectiveLocale.identifier.isEmpty)
    }
}
