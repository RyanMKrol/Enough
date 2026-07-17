import SwiftUI

struct ProgressTabView: View {
  @Environment(\.services) var services
  @Environment(\.accentTheme) var accentTheme
  @Environment(AppState.self) private var appState: AppState?

  @State private var vm: ProgressViewModel?
  @State private var showsNewTripConfirmation = false

  var body: some View {
    ZStack {
      EnoughColor.canvas.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
          titleRow

          StreakCard(streak: vm?.streak ?? 0, dots: vm?.dots ?? [])

          statTiles()
          readinessCard()
        }
        .padding(.horizontal, Layout.screenHPad)
        .padding(.top, 12)
        .padding(.bottom, 32)
      }
    }
    .accessibilityIdentifier(AXID.screenProgress)
    .onAppear {
      let viewModel = vm ?? ProgressViewModel(services: services)
      vm = viewModel
      viewModel.refresh()
    }
    .confirmationDialog(
      "Start a new trip?",
      isPresented: $showsNewTripConfirmation,
      titleVisibility: .visible
    ) {
      Button("Start new trip", role: .destructive) {
        appState?.startNewTrip()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Your packs stay yours. Progress and streaks reset.")
    }
  }

  @ViewBuilder
  private var titleRow: some View {
    HStack(alignment: .firstTextBaseline) {
      Text("Progress")
        .font(EnoughFont.largeTitle())
        .foregroundStyle(EnoughColor.label)

      Spacer()

      Button("New trip") {
        showsNewTripConfirmation = true
      }
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(EnoughColor.linkBlue)
      .accessibilityIdentifier(AXID.progressNewTrip)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func statTiles() -> some View {
    HStack(spacing: 12) {
      statTile(count: vm?.wordsLearned ?? 0, caption: "words learned")
      statTile(count: vm?.minutes ?? 0, caption: "minutes")
      statTile(count: vm?.decksGoing ?? 0, caption: "decks going")
    }
  }

  @ViewBuilder
  private func statTile(count: Int, caption: String) -> some View {
    VStack(spacing: 8) {
      Text(String(count))
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(EnoughColor.label)

      Text(caption)
        .font(.system(size: 12, weight: .semibold))
        .tracking(0.05)
        .textCase(.uppercase)
        .foregroundStyle(EnoughColor.tertiaryText)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(EnoughColor.surface)
    .cornerRadius(18)
  }

  @ViewBuilder
  private func readinessCard() -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("\(vm?.destination ?? "") survival readiness")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(EnoughColor.label)

      HStack(spacing: 16) {
        ProgressRing(
          progress: Double(vm?.readinessPercent ?? 0) / 100,
          size: 72,
          lineWidth: 6,
          tint: accentTheme.accent,
          showsPercent: true
        )

        Text(vm?.readinessLine ?? "")
          .font(.system(size: 15, weight: .regular))
          .foregroundStyle(Color(hex: 0x6b6b70))
          .lineLimit(nil)
          .fixedSize(horizontal: false, vertical: true)

        Spacer()
      }
    }
    .padding(18)
    .background(EnoughColor.surface)
    .cornerRadius(20)
  }
}

#Preview {
  ProgressTabView()
    .environment(\.accentTheme, .japan)
    .environment(\.services, AppServices.preview())
}
