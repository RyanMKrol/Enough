import AppIntents

struct StartReviewIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Start my review"
  nonisolated(unsafe) static var description: IntentDescription = "Start a review session in Enough"
  nonisolated(unsafe) static var openAppWhenRun = true

  @MainActor
  func perform() async throws -> some IntentResult {
    guard let appState = AppStatePublisher.shared.appState else {
      throw IntentError.appStateNotAvailable
    }
    appState.requestStartReview()
    return .result()
  }

  enum IntentError: LocalizedError {
    case appStateNotAvailable

    var errorDescription: String? {
      switch self {
      case .appStateNotAvailable:
        return "App state is not available"
      }
    }
  }
}
