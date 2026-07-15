import Foundation
import SwiftData

@Model
final class TripProfileRecord {
  var countryId: String
  var duration: String
  var scenarioIds: [String]
  var startDate: Date
  var accentRawValue: String
  var isActive: Bool

  init(
    countryId: String,
    duration: String,
    scenarioIds: [String],
    startDate: Date,
    accentRawValue: String,
    isActive: Bool = true
  ) {
    self.countryId = countryId
    self.duration = duration
    self.scenarioIds = scenarioIds
    self.startDate = startDate
    self.accentRawValue = accentRawValue
    self.isActive = isActive
  }
}

@Model
final class EntitlementRecord {
  var productId: String
  var kind: String
  var grantedAt: Date

  init(productId: String, kind: String, grantedAt: Date) {
    self.productId = productId
    self.kind = kind
    self.grantedAt = grantedAt
  }
}

@Model
final class CardSRSRecord {
  var deckId: String
  var cardId: String
  var statusRaw: String
  var easeFactor: Double
  var intervalDays: Double
  var repetitions: Int
  var lapses: Int
  var dueAt: Date?
  var lastReviewedAt: Date?

  init(
    deckId: String,
    cardId: String,
    statusRaw: String,
    easeFactor: Double = 2.5,
    intervalDays: Double = 0,
    repetitions: Int = 0,
    lapses: Int = 0,
    dueAt: Date? = nil,
    lastReviewedAt: Date? = nil
  ) {
    self.deckId = deckId
    self.cardId = cardId
    self.statusRaw = statusRaw
    self.easeFactor = easeFactor
    self.intervalDays = intervalDays
    self.repetitions = repetitions
    self.lapses = lapses
    self.dueAt = dueAt
    self.lastReviewedAt = lastReviewedAt
  }
}

@Model
final class DailyActivityRecord {
  var day: Date
  var cardsReviewed: Int
  var cardsLearned: Int
  var secondsStudied: Int

  init(day: Date, cardsReviewed: Int, cardsLearned: Int, secondsStudied: Int) {
    self.day = day
    self.cardsReviewed = cardsReviewed
    self.cardsLearned = cardsLearned
    self.secondsStudied = secondsStudied
  }
}
