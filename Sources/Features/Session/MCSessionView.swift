import SwiftUI

struct MCSessionView: View {
  @Environment(\.services) private var services
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: MCSessionViewModel?
  @State private var path: [SessionRoute] = []

  let engine: SessionEngine

  init(engine: SessionEngine) {
    self.engine = engine
  }

  var body: some View {
    NavigationStack(path: $path) {
      content
        .navigationDestination(for: SessionRoute.self) { route in
          switch route {
          case .complete:
            // swiftlint:disable:next todo
            Text("Complete")  // TODO(T050): SessionCompleteView
              .accessibilityIdentifier(AXID.screenSessionComplete)
          }
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let viewModel {
      ZStack {
        Color.white.ignoresSafeArea()

        VStack(spacing: 0) {
          SessionChrome(
            progress: viewModel.progressValue,
            counterText: viewModel.progressText,
            onClose: {
              viewModel.closeAndCommit()
              dismiss()
            }
          )
          .padding(.horizontal, 20)
          .padding(.top, 12)

          Spacer()

          VStack(spacing: 28) {
            MCQuestionHeader(
              target: viewModel.target,
              pronunciation: viewModel.pronunciation,
              onPlayAudio: { viewModel.replayAudio() }
            )

            VStack(spacing: 10) {
              ForEach(Array(viewModel.options.enumerated()), id: \.offset) { index, option in
                AnswerRow(
                  text: option,
                  state: viewModel.rowStates.indices.contains(index)
                    ? viewModel.rowStates[index] : .idle,
                  action: { viewModel.select(option: option) }
                )
                .accessibilityIdentifier(AXID.answerRow(index))
              }
            }
          }
          .padding(.horizontal, 20)
          .id(viewModel.currentCardId)
          .transition(
            .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .leading))
          )
          .animation(Motion.swapSpring, value: viewModel.currentCardId)

          Spacer()
        }

        if let resultSheet = viewModel.resultSheet {
          resultSheetView(resultSheet, viewModel: viewModel)
        }
      }
      .accessibilityIdentifier(AXID.screenSessionMC)
      .sensoryFeedback(.impact(weight: .light), trigger: viewModel.selectionCount)
      .sensoryFeedback(trigger: viewModel.lastResult) { _, new in
        switch new {
        case .correct:
          return .success
        case .wrongShake:
          return .error
        default:
          return nil
        }
      }
      .onChange(of: viewModel.route) { _, newRoute in
        if let newRoute {
          path.append(newRoute)
        }
      }
    } else {
      Color.white.ignoresSafeArea()
        .onAppear {
          viewModel = MCSessionViewModel(engine: engine, services: services)
        }
    }
  }

  @ViewBuilder
  private func resultSheetView(_ sheet: MCResultSheet, viewModel: MCSessionViewModel) -> some View {
    switch sheet {
    case .correct(let intervalLabel):
      BottomResultSheet(
        tint: EnoughColor.successTint,
        onContinue: { viewModel.advance() },
        content: {
          VStack(alignment: .leading, spacing: 4) {
            Text("Nice.")
              .font(.system(size: 20, weight: .bold))
              .foregroundStyle(EnoughColor.successDeep)

            Text("You'll see this again in \(intervalLabel)")
              .font(.system(size: 15, weight: .regular))
              .foregroundStyle(EnoughColor.secondaryText)
          }
        }
      )
      .contentShape(Rectangle())
      .onTapGesture { viewModel.advance() }
      .gesture(
        DragGesture().onEnded { value in
          if value.translation.height > 30 {
            viewModel.advance()
          }
        }
      )

    case .incorrect(let target, let english):
      BottomResultSheet(
        tint: Color(hex: 0xffe9e6),
        onContinue: { viewModel.advance() },
        content: {
          VStack(alignment: .leading, spacing: 4) {
            Text("Not quite")
              .font(.system(size: 20, weight: .bold))
              .foregroundStyle(Color(hex: 0xb71824))

            Text(incorrectExplanation(target: target, english: english))
              .font(.system(size: 15, weight: .regular))
              .foregroundStyle(EnoughColor.secondaryText)
          }
        }
      )
      .contentShape(Rectangle())
      .onTapGesture { viewModel.advance() }
      .gesture(
        DragGesture().onEnded { value in
          if value.translation.height > 30 {
            viewModel.advance()
          }
        }
      )
    }
  }

  private func incorrectExplanation(target: String, english: String) -> AttributedString {
    var result = AttributedString("\(target) is the ")
    var bold = AttributedString(english)
    bold.font = .system(size: 15, weight: .bold)
    result += bold
    result += AttributedString(". We'll bring this back soon.")
    return result
  }
}

#Preview {
  MCSessionView(engine: SessionEngine(mode: .learn, cards: [], now: { Date() }))
    .environment(\.accentTheme, .japan)
    .environment(\.services, .preview())
}
