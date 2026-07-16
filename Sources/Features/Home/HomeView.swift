import SwiftUI

struct HomeView: View {
  @Environment(\.services) private var services
  @State private var viewModel: HomeViewModel?
  @State private var learnSessionEngine: SessionEngine?
  @State private var isPresentingLearnSession = false
  @State private var reviewSessionEngine: SessionEngine?
  @State private var isPresentingReviewSession = false

  var body: some View {
    NavigationStack {
      content
        .navigationDestination(for: HomeDestination.self) { destination in
          switch destination {
          case .deckDetail(let deckId):
            DeckDetailView(deckId: deckId)
          }
        }
    }
    .accessibilityIdentifier(AXID.screenHome)
    .fullScreenCover(isPresented: $isPresentingLearnSession) {
      if let learnSessionEngine {
        MCSessionView(engine: learnSessionEngine)
      }
    }
    .fullScreenCover(isPresented: $isPresentingReviewSession) {
      if let reviewSessionEngine {
        ReviewSessionView(engine: reviewSessionEngine)
      }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let viewModel {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          header(viewModel: viewModel)

          if let continueDeck = viewModel.continueDeck {
            ContinueCard(
              deckName: continueDeck.deck.title,
              detailLine: viewModel.continueDetailLine,
              progress: continueDeck.progress.total > 0
                ? Double(continueDeck.progress.learned) / Double(continueDeck.progress.total) : 0,
              onPlay: {
                startLearnSession(deckId: continueDeck.deck.id)
              }
            )
            .accessibilityIdentifier(AXID.homeContinueCard)
          }

          if viewModel.dueCount > 0 {
            ReviewsBanner(
              dueCount: viewModel.dueCount,
              onReview: {
                startReviewSession()
              }
            )
            .accessibilityIdentifier(AXID.homeReviewsBanner)
          }

          VStack(alignment: .leading, spacing: 8) {
            EyebrowLabel("Your decks")

            VStack(spacing: 0) {
              ForEach(Array(viewModel.deckRows.enumerated()), id: \.element.id) { index, row in
                NavigationLink(value: HomeDestination.deckDetail(deckId: row.deck.id)) {
                  DeckListRow(
                    iconSystemName: row.deck.icon,
                    title: row.deck.title,
                    progress: row.progress,
                    status: row.status
                  )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AXID.deckRow(row.deck.id))

                if index < viewModel.deckRows.count - 1 {
                  Divider()
                    .padding(.leading, 46)
                    .foregroundColor(EnoughColor.hairline)
                }
              }
            }
            .padding(.horizontal, 16)
            .background(EnoughColor.surface)
            .cornerRadius(20)
          }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 90)
      }
      .background(EnoughColor.canvas)
      .onAppear {
        viewModel.reload()
      }
    } else {
      EnoughColor.canvas.ignoresSafeArea()
        .onAppear {
          let model = HomeViewModel(services: services)
          model.reload()
          viewModel = model
        }
    }
  }

  private func startLearnSession(deckId: String) {
    guard let engine = try? services.study.makeLearnSession(deckId: deckId) else { return }
    learnSessionEngine = engine
    isPresentingLearnSession = true
  }

  private func startReviewSession() {
    guard let engine = try? services.study.makeReviewSession() else { return }
    reviewSessionEngine = engine
    isPresentingReviewSession = true
  }

  private func header(viewModel: HomeViewModel) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Learn")
          .font(.system(size: 34, weight: .bold))
          .tracking(-0.02)
          .foregroundColor(EnoughColor.label)

        Text(viewModel.subtitle)
          .font(.system(size: 15, weight: .regular))
          .foregroundColor(EnoughColor.secondaryText)
      }

      Spacer()

      StreakPill(count: viewModel.streak)
        .accessibilityIdentifier(AXID.streakPill)
    }
  }
}

#Preview {
  HomeView()
    .environment(\.accentTheme, .japan)
}
