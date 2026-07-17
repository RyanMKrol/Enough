import SwiftUI

struct WelcomeView: View {
  @Environment(\.services) private var services
  let onGetStarted: () -> Void

  @State private var isRestoringPurchases = false
  @State private var restoreMessage: String?
  @State private var restoreMessageTimer: Task<Void, Never>?

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
        .frame(height: 96)

      VStack(spacing: 0) {
        CardStackHero()
          .frame(height: 292)

        wordmark
          .offset(y: -26)
          .padding(.top, -26)

        VStack(spacing: 0) {
          tagline
            .padding(.top, 14)
        }
      }

      Spacer()

      VStack(spacing: 12) {
        Button("Get started") {
          onGetStarted()
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityIdentifier(AXID.onboardingContinue)

        restorePurchasesButton
      }
      .padding(.horizontal, 28)
      .padding(.bottom, 40)
    }
    .background(EnoughColor.surface)
    .accessibilityIdentifier(AXID.screenWelcome)
  }

  private var wordmark: some View {
    HStack(spacing: 0) {
      Text("Enough")
        .font(.system(size: 44, weight: .bold))
        .tracking(-0.03 * 44 / 16)
        .foregroundColor(EnoughColor.label)

      Text(".")
        .font(.system(size: 44, weight: .bold))
        .tracking(-0.03 * 44 / 16)
        .foregroundColor(Color(hex: 0xe24947))
    }
  }

  private var tagline: some View {
    Text(
      "Learn just enough of a language to get through the trip. A weekend. A week. "
        + "No more than you need."
    )
    .font(.system(size: 18, weight: .regular))
    .foregroundColor(EnoughColor.secondaryText)
    .lineLimit(nil)
    .multilineTextAlignment(.center)
    .frame(maxWidth: 280)
  }

  private var restorePurchasesButton: some View {
    VStack(spacing: 8) {
      Button(action: handleRestorePurchases) {
        if isRestoringPurchases {
          ProgressView()
            .scaleEffect(0.8)
        } else {
          Text("Restore purchases")
        }
      }
      .buttonStyle(TextLinkButtonStyle())
      .disabled(isRestoringPurchases)
      .accessibilityIdentifier(AXID.restorePurchases)

      if let message = restoreMessage {
        Text(message)
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(EnoughColor.tertiaryText)
          .transition(.opacity)
      }
    }
  }

  private func handleRestorePurchases() {
    isRestoringPurchases = true
    restoreMessageTimer?.cancel()

    Task {
      do {
        try await services.purchase.restorePurchases()
        await MainActor.run {
          isRestoringPurchases = false
          restoreMessage = "Purchases restored"
          scheduleMessageDismissal()
        }
      } catch {
        await MainActor.run {
          isRestoringPurchases = false
          restoreMessage = "Couldn't restore purchases"
          scheduleMessageDismissal()
        }
      }
    }
  }

  private func scheduleMessageDismissal() {
    restoreMessageTimer?.cancel()
    restoreMessageTimer = Task {
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      await MainActor.run {
        withAnimation(.easeOut(duration: Motion.welcomeTransition)) {
          restoreMessage = nil
        }
      }
    }
  }
}

#Preview {
  WelcomeView(onGetStarted: {})
    .environment(\.services, AppServices.preview())
}
