import XCTest

@testable import Enough

final class ReadinessCalculatorTests: XCTestCase {
  private func deck(_ id: String, scenario: String, cardCount: Int) -> DeckInfo {
    DeckInfo(
      id: id,
      title: id,
      subtitle: "",
      scenario: scenario,
      icon: "",
      cardsFile: "",
      cardCount: cardCount,
      priceGBP: 0
    )
  }

  private func scenario(_ id: String, title: String? = nil) -> ScenarioInfo {
    ScenarioInfo(id: id, title: title ?? id)
  }

  private typealias Progress = DeckProgressService.DeckProgress

  private func progressLookup(_ map: [String: Int]) -> (String) -> Progress? {
    { deckId in
      guard let learned = map[deckId] else { return nil }
      return DeckProgressService.DeckProgress(
        deckId: deckId, total: 0, learned: learned, newCount: 0, learning: 0, mastered: 0,
        dueNow: 0,
        strength: 0
      )
    }
  }

  func testNothingLearned() {
    let scenarios = [scenario("eating-out"), scenario("greetings")]
    let d1 = deck("d1", scenario: "eating-out", cardCount: 30)
    let d2 = deck("d2", scenario: "greetings", cardCount: 24)
    let decks = [d1, d2]
    let result = ReadinessCalculator.readiness(
      tripScenarios: scenarios, decks: decks, progress: progressLookup([:]))
    XCTAssertEqual(result.percent, 0)
    XCTAssertEqual(result.line, "Start with food.")
  }

  func testPartialMock() {
    let s1 = scenario("eating-out")
    let s2 = scenario("greetings")
    let s3 = scenario("getting-around")
    let s4 = scenario("nightlife")
    let scenarios = [s1, s2, s3, s4]
    let d1 = deck("d1", scenario: "eating-out", cardCount: 30)
    let d2 = deck("d2", scenario: "greetings", cardCount: 24)
    let d3 = deck("d3", scenario: "getting-around", cardCount: 34)
    let d4 = deck("d4", scenario: "nightlife", cardCount: 32)
    let decks = [d1, d2, d3, d4]
    let progress = progressLookup(["d1": 21, "d2": 18, "d3": 24, "d4": 0])
    let result = ReadinessCalculator.readiness(
      tripScenarios: scenarios, decks: decks, progress: progress)
    XCTAssertEqual(result.percent, 53)
    XCTAssertEqual(result.line, "You can handle food, greetings & directions. Nightlife's next.")
  }

  func testAllHandled() {
    let scenarios = [scenario("eating-out"), scenario("greetings")]
    let d1 = deck("d1", scenario: "eating-out", cardCount: 30)
    let d2 = deck("d2", scenario: "greetings", cardCount: 24)
    let decks = [d1, d2]
    let progress = progressLookup(["d1": 30, "d2": 24])
    let result = ReadinessCalculator.readiness(
      tripScenarios: scenarios, decks: decks, progress: progress)
    XCTAssertEqual(result.percent, 100)
    XCTAssertEqual(result.line, "You're covered. Keep it fresh.")
  }

  func testIgnoredScenarioDoesNotAffectResult() {
    let scenarios = [scenario("eating-out"), scenario("greetings"), scenario("shopping")]
    let d1 = deck("d1", scenario: "eating-out", cardCount: 30)
    let d2 = deck("d2", scenario: "greetings", cardCount: 24)
    let decks = [d1, d2]
    let progress = progressLookup(["d1": 30, "d2": 24])
    let withIgnored = ReadinessCalculator.readiness(
      tripScenarios: scenarios, decks: decks, progress: progress)
    let withoutIgnored = ReadinessCalculator.readiness(
      tripScenarios: [scenario("eating-out"), scenario("greetings")], decks: decks,
      progress: progress
    )
    XCTAssertEqual(withIgnored.percent, withoutIgnored.percent)
    XCTAssertEqual(withIgnored.line, withoutIgnored.line)
  }

  func testTwoHandledFormatsWithAmpersandNoComma() {
    let scenarios = [scenario("eating-out"), scenario("greetings"), scenario("shopping")]
    let d1 = deck("d1", scenario: "eating-out", cardCount: 10)
    let d2 = deck("d2", scenario: "greetings", cardCount: 10)
    let d3 = deck("d3", scenario: "shopping", cardCount: 10)
    let decks = [d1, d2, d3]
    let progress = progressLookup(["d1": 10, "d2": 10, "d3": 2])
    let result = ReadinessCalculator.readiness(
      tripScenarios: scenarios, decks: decks, progress: progress)
    XCTAssertEqual(result.line, "You can handle food & greetings. Shopping's next.")
  }
}
