import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  let background: Color
  let subtleShadow: Bool

  init(background: Color = EnoughColor.graphite, subtleShadow: Bool = false) {
    self.background = background
    self.subtleShadow = subtleShadow
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity)
      .frame(height: Layout.buttonHeight)
      .background(background, in: RoundedRectangle(cornerRadius: Layout.buttonRadius))
      .shadow(
        color: background.opacity(subtleShadow ? 0.22 : 0.35),
        radius: subtleShadow ? 5 : 9,
        y: subtleShadow ? 3 : 6
      )
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .opacity(configuration.isPressed ? 0.9 : 1.0)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }
}

struct TintedButtonStyle: ButtonStyle {
  @Environment(\.accentTheme) var accentTheme

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 17, weight: .semibold))
      .foregroundStyle(accentTheme.deep)
      .frame(maxWidth: .infinity)
      .frame(height: Layout.buttonHeight)
      .background(accentTheme.tint, in: RoundedRectangle(cornerRadius: Layout.buttonRadius))
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }
}

struct TextLinkButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 15, weight: .regular))
      .foregroundStyle(EnoughColor.linkBlue)
      .opacity(configuration.isPressed ? 0.6 : 1.0)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }
}

#Preview {
  VStack(spacing: 12) {
    Button("Get started") {}
      .buttonStyle(PrimaryButtonStyle())

    Button("Continue") {}
      .buttonStyle(PrimaryButtonStyle(background: AccentTheme.japan.accent))

    Button("Practice all 30") {}
      .buttonStyle(TintedButtonStyle())

    Button("Restore purchases") {}
      .buttonStyle(TextLinkButtonStyle())
  }
  .padding(22)
}
