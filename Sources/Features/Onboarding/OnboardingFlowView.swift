import SwiftUI

enum OnboardingStep: Hashable {
  case country
  case tripShape
  case plan
}

struct OnboardingFlowView: View {
  @Environment(\.services) private var services
  let appState: AppState
  let startAtCountryPicker: Bool

  @State private var draft = OnboardingDraft()
  @State private var path: [OnboardingStep] = []

  init(appState: AppState, startAtCountryPicker: Bool = false) {
    self.appState = appState
    self.startAtCountryPicker = startAtCountryPicker
  }

  var body: some View {
    NavigationStack(path: $path) {
      rootView
        .navigationDestination(for: OnboardingStep.self) { step in
          switch step {
          case .country:
            CountryPickerView(showsBackButton: !startAtCountryPicker) {
              path.append(.tripShape)
            }
          case .tripShape:
            TripShapeView {
              path.append(.plan)
            }
            .navigationBarBackButtonHidden(true)
          case .plan:
            PlanView(onFinish: finish)
              .navigationBarBackButtonHidden(true)
          }
        }
    }
    .environment(draft)
    .environment(\.accentTheme, draft.accent)
  }

  @ViewBuilder
  private var rootView: some View {
    if startAtCountryPicker {
      CountryPickerView(showsBackButton: false) {
        path.append(.tripShape)
      }
    } else {
      welcomeView
    }
  }

  private var welcomeView: some View {
    WelcomeView {
      path.append(.country)
    }
  }

  func finish() {
    do {
      try OnboardingCompleter.complete(draft: draft, services: services, appState: appState)
    } catch {
      // Handle error appropriately in real implementation
    }
  }
}
