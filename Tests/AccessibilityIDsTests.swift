import XCTest

@testable import Enough

@MainActor
final class AccessibilityIDsTests: XCTestCase {
  func testTabBarIdentifiers() {
    XCTAssertEqual(AXID.tabLearn, "tab-learn")
    XCTAssertEqual(AXID.tabReviews, "tab-reviews")
    XCTAssertEqual(AXID.tabProgress, "tab-progress")
    XCTAssertEqual(AXID.tabBrowse, "tab-browse")
  }

  func testScreenRootIdentifiers() {
    XCTAssertEqual(AXID.screenWelcome, "screen-welcome")
    XCTAssertEqual(AXID.screenCountry, "screen-country")
    XCTAssertEqual(AXID.screenTripShape, "screen-trip-shape")
    XCTAssertEqual(AXID.screenPlan, "screen-plan")
    XCTAssertEqual(AXID.screenHome, "screen-home")
    XCTAssertEqual(AXID.screenDeckDetail, "screen-deck-detail")
    XCTAssertEqual(AXID.screenSessionMC, "screen-session-mc")
    XCTAssertEqual(AXID.screenSessionReview, "screen-session-review")
    XCTAssertEqual(AXID.screenSessionComplete, "screen-session-complete")
    XCTAssertEqual(AXID.screenReviews, "screen-reviews")
    XCTAssertEqual(AXID.screenProgress, "screen-progress")
    XCTAssertEqual(AXID.screenBrowse, "screen-browse")
    XCTAssertEqual(AXID.screenDebug, "screen-debug")
  }

  func testOnboardingIdentifiers() {
    XCTAssertEqual(AXID.onboardingContinue, "onboarding-continue")
    XCTAssertEqual(AXID.restorePurchases, "restore-purchases")
    XCTAssertEqual(AXID.countryCard("japan"), "country-card-japan")
  }

  func testHomeIdentifiers() {
    XCTAssertEqual(AXID.homeContinueCard, "home-continue-card")
    XCTAssertEqual(AXID.homeReviewsBanner, "home-reviews-banner")
    XCTAssertEqual(AXID.streakPill, "streak-pill")
    XCTAssertEqual(AXID.deckRow("jp-greetings"), "deck-row-jp-greetings")
  }

  func testDeckDetailIdentifiers() {
    XCTAssertEqual(AXID.deckContinue, "deck-continue")
    XCTAssertEqual(AXID.deckPractice, "deck-practice")
  }

  func testSessionIdentifiers() {
    XCTAssertEqual(AXID.audioButton, "audio-button")
    XCTAssertEqual(AXID.flashcard, "flashcard")
    XCTAssertEqual(AXID.gradeAgain, "grade-again")
    XCTAssertEqual(AXID.gradeHard, "grade-hard")
    XCTAssertEqual(AXID.gradeGood, "grade-good")
    XCTAssertEqual(AXID.gradeEasy, "grade-easy")
    XCTAssertEqual(AXID.sessionClose, "session-close")
    XCTAssertEqual(AXID.sessionNext, "session-next")
    XCTAssertEqual(AXID.answerRow(2), "answer-row-2")
  }

  func testSessionCompleteIdentifiers() {
    XCTAssertEqual(AXID.completeDone, "complete-done")
    XCTAssertEqual(AXID.completeLearnMore, "complete-learn-more")
  }

  func testReviewsIdentifiers() {
    XCTAssertEqual(AXID.startReview, "start-review")
  }

  func testBrowseIdentifiers() {
    XCTAssertEqual(AXID.browseRestore, "browse-restore")
    XCTAssertEqual(AXID.buy("jp-greetings"), "buy-jp-greetings")
  }
}
