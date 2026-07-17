import SwiftUI

struct LiquidGlassTabBar: View {
  @Binding var selection: EnoughTab
  @Environment(\.accentTheme) var accentTheme

  private enum GlassVariant {
    case regular
    case interactive
    case accentTint
    case animatedSelection
  }

  private let tabBarGlassVariant: GlassVariant = .interactive

  var body: some View {
    switch tabBarGlassVariant {
    case .regular:
      regularVariant
    case .interactive:
      interactiveVariant
    case .accentTint:
      accentTintVariant
    case .animatedSelection:
      animatedSelectionVariant
    }
  }

  private var regularVariant: some View {
    HStack(spacing: 0) {
      ForEach(EnoughTab.allCases) { tab in
        tabButton(tab)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 58)
    .padding(.vertical, 10)
    .glassEffect(.regular, in: Capsule())
    .shadow(color: .black.opacity(0.1), radius: 22, y: 6)
  }

  private var interactiveVariant: some View {
    HStack(spacing: 0) {
      ForEach(EnoughTab.allCases) { tab in
        tabButton(tab)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 58)
    .padding(.vertical, 10)
    .glassEffect(.regular.interactive(), in: Capsule())
    .shadow(color: .black.opacity(0.1), radius: 22, y: 6)
  }

  private var accentTintVariant: some View {
    HStack(spacing: 0) {
      ForEach(EnoughTab.allCases) { tab in
        VStack(spacing: 4) {
          Image(systemName: tab.symbol)
            .font(.system(size: 18, weight: .semibold))
          Text(tab.title)
            .font(.system(size: 10, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .foregroundStyle(
          selection == tab ? accentTheme.accent : EnoughColor.inactiveTab
        )
        .background(
          selection == tab
            ? AnyShapeStyle(accentTheme.accent.opacity(0.15))
            : AnyShapeStyle(Color.clear)
        )
        .onTapGesture {
          selection = tab
        }
      }
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 58)
    .padding(.vertical, 10)
    .glassEffect(.regular, in: Capsule())
    .shadow(color: .black.opacity(0.1), radius: 22, y: 6)
  }

  private var animatedSelectionVariant: some View {
    HStack(spacing: 0) {
      ForEach(EnoughTab.allCases) { tab in
        VStack(spacing: 4) {
          Image(systemName: tab.symbol)
            .font(.system(size: 18, weight: .semibold))
          Text(tab.title)
            .font(.system(size: 10, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .foregroundStyle(
          selection == tab ? accentTheme.accent : EnoughColor.inactiveTab
        )
        .background(
          selection == tab
            ? AnyShapeStyle(accentTheme.accent.opacity(0.15))
            : AnyShapeStyle(Color.clear)
        )
        .onTapGesture {
          withAnimation(.easeInOut(duration: 0.25)) {
            selection = tab
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 58)
    .padding(.vertical, 10)
    .glassEffect(.regular, in: Capsule())
    .shadow(color: .black.opacity(0.1), radius: 22, y: 6)
  }

  private func tabButton(_ tab: EnoughTab) -> some View {
    Button(
      action: {
        selection = tab
      },
      label: {
        VStack(spacing: 4) {
          Image(systemName: tab.symbol)
            .font(.system(size: 18, weight: .semibold))
          Text(tab.title)
            .font(.system(size: 10, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
        .foregroundStyle(
          selection == tab ? accentTheme.accent : EnoughColor.inactiveTab
        )
      }
    )
    .buttonStyle(PlainButtonStyle())
    .accessibilityIdentifier(tab.axID)
    .accessibilityLabel(tab.title)
    .accessibilityAddTraits(selection == tab ? .isSelected : [])
  }
}

#Preview {
  @Previewable @State var selection: EnoughTab = .learn
  VStack {
    Spacer()
    LiquidGlassTabBar(selection: $selection)
      .padding(.horizontal, 44)
      .padding(.bottom, 18)
  }
  .background(EnoughColor.canvas)
  .environment(\.accentTheme, .japan)
}

#Preview {
  @Previewable @State var selection: EnoughTab = .learn
  VStack {
    Spacer()
    LiquidGlassTabBar(selection: $selection)
      .padding(.horizontal, 44)
      .padding(.bottom, 18)
  }
  .background(EnoughColor.canvas)
  .environment(\.accentTheme, .japan)
}
