import SwiftUI

struct CountryPickerView: View {
  @Environment(\.services) private var services
  @Environment(OnboardingDraft.self) private var draft

  var showsBackButton: Bool = true
  let onContinue: () -> Void

  @State private var catalog: ContentCatalog?
  @State private var loadError = false

  private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        if loadError {
          errorState
        } else {
          LazyVGrid(columns: columns, spacing: 12) {
            ForEach(catalog?.countries ?? []) { country in
              CountryCardView(
                country: country,
                isSelected: draft.selectedCountryId == country.id,
                action: { draft.selectCountry(country) }
              )
            }

            moreSoonTile
          }
        }
      }
      .padding(.horizontal, 22)
      .padding(.top, 12)
      .padding(.bottom, 120)
    }
    .background(EnoughColor.surface)
    .safeAreaInset(edge: .bottom) {
      continueButton
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
        .background(EnoughColor.surface)
    }
    .toolbar {
      if showsBackButton {
        ToolbarItem(placement: .navigationBarLeading) {
          OnboardingBackButton()
        }
      }
    }
    .navigationBarBackButtonHidden(true)
    .onAppear(perform: loadCatalog)
    .accessibilityIdentifier(AXID.screenCountry)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      EyebrowLabel("STEP 1 OF 3")

      Text("Where are you headed?")
        .font(.system(size: 30, weight: .bold))
        .tracking(-0.02 * 30)
        .foregroundColor(EnoughColor.label)

      Text("Pick a country to unlock its decks.")
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(EnoughColor.secondaryText)
    }
  }

  private var errorState: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("We couldn't load the destinations")
        .font(.system(size: 17, weight: .semibold))
        .foregroundColor(EnoughColor.label)

      Text("Check your connection and try again.")
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(EnoughColor.secondaryText)

      Button("Try again") {
        loadError = false
        catalog = nil
        loadCatalog()
      }
      .buttonStyle(TextLinkButtonStyle())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 24)
  }

  private var moreSoonTile: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("More soon")
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(EnoughColor.tertiaryText)

      Text((catalog?.comingSoon ?? []).joined(separator: " · "))
        .font(.system(size: 13, weight: .regular))
        .foregroundColor(EnoughColor.faintText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 20)
        .strokeBorder(
          Color.black.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6])
        )
    )
  }

  private var continueButton: some View {
    Button("Continue", action: onContinue)
      .buttonStyle(
        PrimaryButtonStyle(
          background: draft.selectedCountryId == nil
            ? EnoughColor.graphite : draft.accent.accent
        )
      )
      .animation(.easeInOut(duration: Motion.toastFade), value: draft.selectedCountryId)
      .disabled(draft.selectedCountryId == nil)
      .opacity(draft.selectedCountryId == nil ? 0.5 : 1.0)
      .accessibilityIdentifier(AXID.onboardingContinue)
  }

  private func loadCatalog() {
    guard catalog == nil else { return }
    do {
      catalog = try services.contentStore.catalog()
    } catch {
      loadError = true
    }
  }
}

#Preview("No selection") {
  NavigationStack {
    CountryPickerView(onContinue: {})
      .environment(\.services, AppServices.preview())
      .environment(OnboardingDraft())
  }
}

#Preview("Japan selected") {
  let draft = OnboardingDraft()
  let services = AppServices.preview()
  let catalog = try? services.contentStore.catalog()
  if let japan = catalog?.countries.first(where: { $0.id == "japan" }) {
    draft.selectCountry(japan)
  }

  return NavigationStack {
    CountryPickerView(onContinue: {})
      .environment(\.services, services)
      .environment(draft)
  }
}
