import SwiftUI

struct BundleRowView: View {
  let title: String
  let subtitle: String
  let price: String
  let isPopular: Bool
  let isSelected: Bool
  let action: () -> Void

  @Environment(\.accentTheme) var accentTheme

  var body: some View {
    Button(action: handleTap) {
      HStack(spacing: 12) {
        radioIndicator
          .frame(width: 22, height: 22)

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(title)
              .font(.system(size: 17, weight: .semibold))
              .foregroundColor(EnoughColor.label)
              .fixedSize()

            if isPopular {
              Text("POPULAR")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(accentTheme.accent)
                .cornerRadius(99)
                .fixedSize()
            }
          }

          Text(subtitle)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(EnoughColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 8)

        Text(price)
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(EnoughColor.label)
          .fixedSize()
      }
      .padding(16)
      .background(EnoughColor.surface)
      .cornerRadius(18)
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(
            isSelected ? accentTheme.accent : Color.black.opacity(0.08),
            lineWidth: isSelected ? 2 : 1
          )
      )
      .shadow(
        color: isSelected ? accentTheme.accent.opacity(0.18) : .clear,
        radius: isSelected ? 12 : 0,
        y: isSelected ? 5 : 0
      )
      .animation(.spring(duration: Motion.selectionSpringResponse), value: isSelected)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var radioIndicator: some View {
    if isSelected {
      ZStack {
        Circle()
          .fill(accentTheme.accent)

        Circle()
          .fill(.white)
          .frame(width: 8, height: 8)
      }
    } else {
      Circle()
        .stroke(Color(hex: 0xc7c7cc), lineWidth: 1.5)
    }
  }

  private func handleTap() {
    action()
  }
}

#Preview {
  VStack(spacing: 16) {
    BundleRowView(
      title: "Weekend",
      subtitle: "3 essential packs · save £0.51",
      price: "£2.49",
      isPopular: true,
      isSelected: true,
      action: {}
    )

    BundleRowView(
      title: "The whole week",
      subtitle: "Every Japan pack · save £3.20",
      price: "£3.49",
      isPopular: false,
      isSelected: false,
      action: {}
    )
  }
  .padding(22)
  .background(EnoughColor.canvas)
  .environment(\.accentTheme, .japan)
}
