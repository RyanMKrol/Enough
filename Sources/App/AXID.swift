enum AXID {
  // Tab bar
  static let tabLearn = "tab-learn"
  static let tabReviews = "tab-reviews"
  static let tabProgress = "tab-progress"
  static let tabBrowse = "tab-browse"

  // Screen roots
  static let screenWelcome = "screen-welcome"
  static let screenCountry = "screen-country"
  static let screenTripShape = "screen-trip-shape"
  static let screenPlan = "screen-plan"
  static let screenHome = "screen-home"
  static let screenDeckDetail = "screen-deck-detail"
  static let screenSessionMC = "screen-session-mc"
  static let screenSessionReview = "screen-session-review"
  static let screenSessionComplete = "screen-session-complete"
  static let screenReviews = "screen-reviews"
  static let screenProgress = "screen-progress"
  static let progressNewTrip = "progress-new-trip"
  static let screenBrowse = "screen-browse"
  static let screenDebug = "screen-debug"

  // Onboarding
  static let onboardingContinue = "onboarding-continue"
  static let restorePurchases = "restore-purchases"
  static func countryCard(_ id: String) -> String { "country-card-\(id)" }

  // Home
  static let homeContinueCard = "home-continue-card"
  static let homeReviewsBanner = "home-reviews-banner"
  static let streakPill = "streak-pill"
  static func deckRow(_ deckId: String) -> String { "deck-row-\(deckId)" }

  // Deck detail
  static let deckContinue = "deck-continue"
  static let deckPractice = "deck-practice"

  // Sessions
  static let audioButton = "audio-button"
  static let flashcard = "flashcard"
  static let gradeAgain = "grade-again"
  static let gradeHard = "grade-hard"
  static let gradeGood = "grade-good"
  static let gradeEasy = "grade-easy"
  static let sessionClose = "session-close"
  static let sessionNext = "session-next"
  static func answerRow(_ n: Int) -> String { "answer-row-\(n)" }

  // Session complete
  static let completeDone = "complete-done"
  static let completeLearnMore = "complete-learn-more"

  // Reviews
  static let startReview = "start-review"

  // Browse
  static let browseRestore = "browse-restore"
  static func buy(_ productId: String) -> String { "buy-\(productId)" }
}
