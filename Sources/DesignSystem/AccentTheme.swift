import SwiftUI

enum AccentTheme: String, CaseIterable {
  case japan
  case france
  case germany

  var accent: Color {
    switch self {
    case .japan:
      Color(hex: 0xe24947)
    case .france:
      Color(hex: 0x3d7ede)
    case .germany:
      Color(hex: 0xd07b00)
    }
  }

  var tint: Color {
    switch self {
    case .japan:
      Color(hex: 0xffe9e6)
    case .france:
      Color(hex: 0xe6f3ff)
    case .germany:
      Color(hex: 0xffeed9)
    }
  }

  var deep: Color {
    switch self {
    case .japan:
      Color(hex: 0xb71824)
    case .france:
      Color(hex: 0x1659b5)
    case .germany:
      Color(hex: 0xa95600)
    }
  }
}

extension EnvironmentValues {
  @Entry var accentTheme: AccentTheme = .japan
}
