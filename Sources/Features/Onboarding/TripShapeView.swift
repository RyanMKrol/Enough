import SwiftUI

struct TripShapeView: View {
  @Environment(\.services) private var services
  @Environment(OnboardingDraft.self) private var draft

  let onContinue: () -> Void

  @State private var catalog: ContentCatalog?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        VStack(alignment: .leading, spacing: 12) {
          Text("How long are you there?")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(EnoughColor.secondaryText)

          Picker(
            "Duration",
            selection: .init(
              get: { draft.duration },
              set: { draft.duration = $0 }
            )
          ) {
            Text("A weekend").tag(TripDuration.weekend)
            Text("A week").tag(TripDuration.week)
          }
          .pickerStyle(.segmented)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("What will you be doing?")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(EnoughColor.secondaryText)

          FlowLayout(spacing: 10) {
            ForEach(catalog?.scenarios ?? []) { scenario in
              ScenarioChip(
                title: scenario.title,
                isSelected: draft.scenarioIds.contains(scenario.id),
                action: {
                  toggleScenario(scenario.id)
                }
              )
            }
          }
        }
      }
      .padding(.horizontal, 22)
      .padding(.top, 12)
      .padding(.bottom, 120)
    }
    .background(EnoughColor.surface)
    .safeAreaInset(edge: .bottom) {
      buildButton
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
        .background(EnoughColor.surface)
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        OnboardingBackButton()
      }
    }
    .navigationBarBackButtonHidden(true)
    .onAppear(perform: loadCatalog)
    .accessibilityIdentifier(AXID.screenTripShape)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      EyebrowLabel("STEP 2 OF 3")

      Text("Shape your trip")
        .font(.system(size: 30, weight: .bold))
        .tracking(-0.02 * 30)
        .foregroundColor(EnoughColor.label)
    }
  }

  private var buildButton: some View {
    Button("Build my plan", action: onContinue)
      .buttonStyle(
        PrimaryButtonStyle(background: draft.accent.accent)
      )
      .accessibilityIdentifier(AXID.onboardingContinue)
  }

  private func toggleScenario(_ id: String) {
    withAnimation(Motion.selectionSpring) {
      if draft.scenarioIds.contains(id) {
        draft.scenarioIds.remove(id)
      } else {
        draft.scenarioIds.insert(id)
      }
    }
  }

  private func loadCatalog() {
    guard catalog == nil else { return }
    catalog = try? services.contentStore.catalog()
  }
}
