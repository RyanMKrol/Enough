import SwiftData
import SwiftUI

struct DeckDetailView: View {
  @Environment(\.services) private var services
  @Environment(\.accentTheme) private var accentTheme
  @Environment(\.dismiss) private var dismiss
  @State private var deckInfo: DeckInfo?
  @State private var countryInfo: CountryInfo?
  @State private var cards: [CardContent] = []
  @State private var progress: DeckProgressService.DeckProgress?
  @State private var isResetting = false
  @State private var showResetConfirmation = false
  @State private var sessionEngine: SessionEngine?
  @State private var isPresentingSession = false
  @State private var sessionStartError: String?
  @State private var loadFailed = false
  @State private var resetErrorMessage: String?

  let deckId: String

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        DeckDetailHeroSection(
          deckInfo: deckInfo,
          countryInfo: countryInfo,
          accentTheme: accentTheme,
          onBack: { dismiss() },
          onResetTapped: { showResetConfirmation = true },
          minutesEstimate: minutesEstimate
        )

        // Main content
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            // Progress row
            if let progress {
              VStack(spacing: 12) {
                HStack {
                  Text("\(progress.learned) of \(progress.total) learned")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(EnoughColor.secondaryText)

                  Spacer()

                  let percentage = Int(
                    (Double(progress.learned) / Double(progress.total) * 100).rounded()
                  )
                  Text("\(percentage)%")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(EnoughColor.label)
                }

                AnimatedProgressBar(
                  progress: Double(progress.learned) / Double(progress.total),
                  tint: accentTheme.accent,
                  trackColor: Color.black.opacity(0.08)
                )
              }
              .padding(.horizontal, 22)
              .padding(.top, 22)
            }

            if loadFailed {
              loadFailedBanner
            }

            // Samples section
            VStack(alignment: .leading, spacing: 16) {
              EyebrowLabel("In this deck")

              VStack(spacing: 0) {
                if cards.isEmpty && !loadFailed {
                  emptyCardsRow
                }

                ForEach(Array(cards.prefix(5).enumerated()), id: \.element.id) { index, card in
                  VStack(alignment: .leading, spacing: 3) {
                    Text(card.target)
                      .font(.system(size: 17, weight: .semibold))
                      .foregroundStyle(EnoughColor.label)

                    Text("\(card.pronunciation) · \(card.english)")
                      .font(.system(size: 15, weight: .regular))
                      .foregroundStyle(EnoughColor.secondaryText)
                      .lineLimit(1)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.vertical, 12)
                  .padding(.horizontal, 16)
                  .accessibilityElement(children: .combine)

                  if index < min(4, cards.count - 1) {
                    Divider()
                      .padding(.leading, 16)
                  }
                }
              }
              .background(Color.white)
              .cornerRadius(20)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
          }
        }

        Spacer()
      }
      .background(EnoughColor.canvas)

      DeckDetailActionBar(
        accentTheme: accentTheme,
        cardCount: deckInfo?.cardCount ?? 0,
        onLearn: startLearnSession,
        onPractice: startPracticeSession
      )
    }
    .toolbar(.hidden, for: .navigationBar)
    .accessibilityIdentifier(AXID.screenDeckDetail)
    .onAppear {
      loadContent()
    }
    .confirmationDialog(
      "Reset deck progress?",
      isPresented: $showResetConfirmation,
      actions: {
        Button("Reset", role: .destructive) {
          resetProgress()
        }
      }
    )
    .fullScreenCover(isPresented: $isPresentingSession) {
      if let sessionEngine {
        MCSessionView(engine: sessionEngine)
      }
    }
    .errorAlert("Couldn't start session", message: $sessionStartError)
    .errorAlert("Couldn't reset progress", message: $resetErrorMessage)
  }

  private var loadFailedBanner: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("We couldn't load this deck")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(EnoughColor.label)

      Button("Try again") {
        loadFailed = false
        loadContent()
      }
      .buttonStyle(TextLinkButtonStyle())
    }
    .padding(.horizontal, 22)
  }

  private var emptyCardsRow: some View {
    Text("No cards in this deck yet")
      .font(.system(size: 15, weight: .regular))
      .foregroundStyle(EnoughColor.secondaryText)
      .padding(.vertical, 12)
      .padding(.horizontal, 16)
  }

  private func startLearnSession() {
    do {
      sessionEngine = try services.study.makeLearnSession(deckId: deckId)
      isPresentingSession = true
    } catch {
      sessionStartError = "Couldn't start this session — try again"
    }
  }

  private func startPracticeSession() {
    do {
      sessionEngine = try services.study.makePracticeSession(deckId: deckId)
      isPresentingSession = true
    } catch {
      sessionStartError = "Couldn't start practice — try again"
    }
  }

  private func loadContent() {
    do {
      deckInfo = try services.contentStore.deck(deckId)

      let allCards = try services.contentStore.cards(forDeck: deckId)
      cards = Array(allCards.prefix(5))

      if let deckInfo {
        let countryId = try services.contentStore.countryId(forDeck: deckInfo.id)
        countryInfo = try services.contentStore.country(countryId)
      }

      progress = try services.deckProgress.progress(forDeck: deckId)
      loadFailed = false
    } catch {
      loadFailed = true
    }
  }

  private func resetProgress() {
    isResetting = true
    do {
      try services.cardSRSStore.deleteAll(forDeck: deckId)
      progress = try services.deckProgress.progress(forDeck: deckId)
    } catch {
      resetErrorMessage = "Try again in a moment."
    }
    isResetting = false
  }

  private func minutesEstimate(_ cardCount: Int) -> Int {
    let seconds = cardCount * 25
    return (seconds + 59) / 60
  }
}

private struct DeckDetailHeroSection: View {
  let deckInfo: DeckInfo?
  let countryInfo: CountryInfo?
  let accentTheme: AccentTheme
  let onBack: () -> Void
  let onResetTapped: () -> Void
  let minutesEstimate: (Int) -> Int

  var body: some View {
    VStack(spacing: 16) {
      // Top buttons row
      GlassEffectContainer {
        HStack {
          Button(action: onBack) {
            Image(systemName: "chevron.backward")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(accentTheme.accent)
              .frame(width: 36, height: 36)
              .glassEffect(.regular, in: Circle())
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
          .accessibilityLabel("Back")

          Spacer()

          Menu {
            Button(role: .destructive, action: onResetTapped) {
              Label("Reset deck progress", systemImage: "arrow.counterclockwise")
            }
          } label: {
            Image(systemName: "ellipsis")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(accentTheme.accent)
              .frame(width: 36, height: 36)
              .glassEffect(.regular, in: Circle())
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
          .accessibilityLabel("More options")
        }
      }
      .padding(.horizontal, 22)
      .padding(.top, 16)

      // Icon tile and info
      if let deckInfo {
        VStack(spacing: 12) {
          ZStack {
            RoundedRectangle(cornerRadius: 14)
              .fill(Color.white)
              .frame(height: 56)

            HStack(spacing: 12) {
              Image(systemName: deckInfo.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(accentTheme.accent)

              VStack(alignment: .leading, spacing: 2) {
                Text(deckInfo.title)
                  .font(.system(size: 30, weight: .bold))
                  .foregroundStyle(EnoughColor.label)

                if let countryInfo {
                  Text("\(countryInfo.languageName) · \(deckInfo.subtitle)")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(accentTheme.deep)
                }
              }

              Spacer()
            }
            .padding(.horizontal, 16)
          }

          // Meta chips
          HStack(spacing: 8) {
            MetaChip(text: "\(deckInfo.cardCount) cards")
            MetaChip(text: "~\(minutesEstimate(deckInfo.cardCount)) min")
            MetaChip(text: "Audio")
          }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
      }
    }
    .background(accentTheme.accent)
  }
}

private struct DeckDetailActionBar: View {
  let accentTheme: AccentTheme
  let cardCount: Int
  let onLearn: () -> Void
  let onPractice: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      LinearGradient(
        gradient: Gradient(colors: [Color.white.opacity(0), Color.white]),
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 110)

      VStack(spacing: 10) {
        Button("Continue learning", action: onLearn)
          .buttonStyle(PrimaryButtonStyle(background: accentTheme.accent, subtleShadow: true))
          .accessibilityIdentifier(AXID.deckContinue)

        Button("Practice all \(cardCount)", action: onPractice)
          .buttonStyle(TintedButtonStyle())
          .accessibilityIdentifier(AXID.deckPractice)
      }
      .padding(.horizontal, 22)
      .padding(.vertical, 16)
      .background(Color.white)
    }
    .frame(maxHeight: .infinity, alignment: .bottom)
  }
}

#Preview {
  NavigationStack {
    DeckDetailView(deckId: "jp-greetings")
      .environment(\.accentTheme, .japan)
      .environment(\.services, .preview())
  }
}
