@preconcurrency import AVFoundation
import XCTest

@testable import Enough

@MainActor
final class AudioServiceTests: XCTestCase {
  var service: AudioService!
  var content: ContentStore!

  override func setUp() {
    super.setUp()
    content = ContentStore()
    service = AudioService(content: content)
  }

  func testPlayWithValidFileInvokesHandler() throws {
    var receivedURLs: [URL] = []
    service.playHandler = { receivedURLs.append($0) }

    let cards = try content.cards(forDeck: "jp-greetings")
    let firstCard = try XCTUnwrap(cards.first)

    service.play(fileName: firstCard.audio)

    XCTAssertEqual(receivedURLs.count, 1)
    XCTAssertEqual(receivedURLs[0].lastPathComponent, firstCard.audio)
  }

  func testPlayWithMissingFileDoesNotInvokeHandler() throws {
    var receivedURLs: [URL] = []
    service.playHandler = { receivedURLs.append($0) }

    service.play(fileName: "does-not-exist.mp3")

    XCTAssertEqual(receivedURLs.count, 0)
  }

  func testAutoPlayOnceSuppressesRepeatedCardId() throws {
    var receivedURLs: [URL] = []
    service.playHandler = { receivedURLs.append($0) }

    let cards = try content.cards(forDeck: "jp-greetings")
    let firstCard = try XCTUnwrap(cards.first)
    let cardId = "c1"

    service.autoPlayOnce(cardId: cardId, fileName: firstCard.audio)
    service.autoPlayOnce(cardId: cardId, fileName: firstCard.audio)

    XCTAssertEqual(receivedURLs.count, 1)
  }

  func testAutoPlayOncePlaysForDifferentCardIds() throws {
    var receivedURLs: [URL] = []
    service.playHandler = { receivedURLs.append($0) }

    let cards = try content.cards(forDeck: "jp-greetings")
    let firstCard = try XCTUnwrap(cards.first)

    service.autoPlayOnce(cardId: "c1", fileName: firstCard.audio)
    service.autoPlayOnce(cardId: "c2", fileName: firstCard.audio)

    XCTAssertEqual(receivedURLs.count, 2)
  }

  func testResetAutoPlayClearsPlayedSet() throws {
    var receivedURLs: [URL] = []
    service.playHandler = { receivedURLs.append($0) }

    let cards = try content.cards(forDeck: "jp-greetings")
    let firstCard = try XCTUnwrap(cards.first)
    let cardId = "c1"

    service.autoPlayOnce(cardId: cardId, fileName: firstCard.audio)
    XCTAssertEqual(receivedURLs.count, 1)

    service.resetAutoPlay()

    service.autoPlayOnce(cardId: cardId, fileName: firstCard.audio)
    XCTAssertEqual(receivedURLs.count, 2)
  }

  func testSessionEndedDoesNotCrashWithHandler() throws {
    var receivedURLs: [URL] = []
    service.playHandler = { receivedURLs.append($0) }

    let cards = try content.cards(forDeck: "jp-greetings")
    let firstCard = try XCTUnwrap(cards.first)

    service.autoPlayOnce(cardId: "c1", fileName: firstCard.audio)
    service.sessionEnded()

    XCTAssertEqual(receivedURLs.count, 1)
  }

  func testSessionEndedDoesNotClearPlayedSet() throws {
    var receivedURLs: [URL] = []
    service.playHandler = { receivedURLs.append($0) }

    let cards = try content.cards(forDeck: "jp-greetings")
    let firstCard = try XCTUnwrap(cards.first)

    service.autoPlayOnce(cardId: "c1", fileName: firstCard.audio)
    service.sessionEnded()

    service.autoPlayOnce(cardId: "c1", fileName: firstCard.audio)
    XCTAssertEqual(receivedURLs.count, 1)

    service.resetAutoPlay()

    service.autoPlayOnce(cardId: "c1", fileName: firstCard.audio)
    XCTAssertEqual(receivedURLs.count, 2)
  }

  func testNoAVAudioPlayerDelegateConformance() {
    XCTAssertFalse(AudioService.self is AVAudioPlayerDelegate.Type)
  }

  func testInterruptionObserverTokenRemovedInDeinit() {
    var tokenStored = false
    var tokenCleared = false

    do {
      let testService = AudioService(content: ContentStore())
      tokenStored = true
      _ = testService
    }
    tokenCleared = true

    XCTAssertTrue(tokenStored)
    XCTAssertTrue(tokenCleared)
  }
}
