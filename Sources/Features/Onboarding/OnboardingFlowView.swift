import SwiftUI

enum OnboardingStep: Hashable {
  case country
  case tripShape
  case plan
}

struct OnboardingFlowView: View {
  @Environment(\.services) private var services
  let appState: AppState

  @State private var draft = OnboardingDraft()
  @State private var path: [OnboardingStep] = []

  var body: some View {
    NavigationStack(path: $path) {
      welcomeView
        .navigationDestination(for: OnboardingStep.self) { step in
          switch step {
          case .country:
            Text("Country")
              .navigationBarBackButtonHidden(true)
          case .tripShape:
            Text("Trip shape")
              .navigationBarBackButtonHidden(true)
          case .plan:
            Text("Plan")
              .navigationBarBackButtonHidden(true)
          }
        }
    }
    .environment(draft)
    .environment(\.accentTheme, draft.accent)
  }

  private var welcomeView: some View {
    VStack(spacing: 24) {
      Text("Welcome")
        .font(.largeTitle)

      Spacer()

      Button("Get started") {
        path.append(.country)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 54)
    }
    .padding()
  }

  func finish() {
    do {
      try OnboardingCompleter.complete(draft: draft, services: services, appState: appState)
    } catch {
      // Handle error appropriately in real implementation
    }
  }
}
