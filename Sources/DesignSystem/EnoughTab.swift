import Foundation

enum EnoughTab: String, CaseIterable, Identifiable {
  case learn
  case reviews
  case progress
  case browse

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .learn:
      "Learn"
    case .reviews:
      "Reviews"
    case .progress:
      "Progress"
    case .browse:
      "Browse"
    }
  }

  var symbol: String {
    switch self {
    case .learn:
      "rectangle.stack.fill"
    case .reviews:
      "arrow.trianglehead.2.clockwise.rotate.90"
    case .progress:
      "chart.bar.fill"
    case .browse:
      "bag.fill"
    }
  }
}
