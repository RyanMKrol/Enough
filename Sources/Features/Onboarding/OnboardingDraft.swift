import Foundation
import SwiftUI

enum TripDuration: String {
  case weekend
  case week
}

@Observable
final class OnboardingDraft {
  var selectedCountryId: String?
  var selectedCountry: CountryInfo?
  var duration: TripDuration = .weekend
  var scenarioIds: Set<String> = []
  var selectedBundleId: String?
  var extraDeckIds: Set<String> = []

  var accent: AccentTheme {
    if let accentRaw = selectedCountry?.accent {
      return AccentTheme(rawValue: accentRaw) ?? .japan
    }
    return .japan
  }

  func selectCountry(_ country: CountryInfo) {
    selectedCountryId = country.id
    selectedCountry = country
  }
}
