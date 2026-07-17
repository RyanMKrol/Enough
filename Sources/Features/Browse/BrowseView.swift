import SwiftUI

private struct TrailingControlSpec {
  let productId: String
  let kind: EntitlementKind
  let owned: Bool
  let fallbackGBP: Double
  let accent: AccentTheme
}

struct BrowseView: View {
  @Environment(\.services) private var services
  @State private var viewModel: BrowseViewModel?

  var body: some View {
    ZStack {
      EnoughColor.canvas.ignoresSafeArea()

      if let viewModel {
        content(viewModel: viewModel)
      }
    }
    .accessibilityIdentifier(AXID.screenBrowse)
    .onAppear {
      if let viewModel {
        viewModel.refresh()
      } else {
        let model = BrowseViewModel(services: services)
        model.refresh()
        viewModel = model
      }
    }
    .alert(
      "Something went wrong",
      isPresented: Binding(
        get: { viewModel?.errorMessage != nil },
        set: { if !$0 { viewModel?.errorMessage = nil } }
      )
    ) {
      Button("OK") { viewModel?.errorMessage = nil }
    } message: {
      Text(viewModel?.errorMessage ?? "")
    }
  }

  @ViewBuilder
  private func content(viewModel: BrowseViewModel) -> some View {
    ZStack(alignment: .top) {
      ScrollView {
        VStack(alignment: .leading, spacing: Layout.sectionGap) {
          Text("Browse")
            .font(EnoughFont.largeTitle())
            .foregroundStyle(EnoughColor.label)
            .padding(.horizontal, Layout.screenHPad)
            .padding(.top, 12)

          ForEach(viewModel.countries) { country in
            countrySection(country: country, viewModel: viewModel)
          }

          Button("Restore purchases") {
            Task { await viewModel.restore() }
          }
          .buttonStyle(TextLinkButtonStyle())
          .frame(maxWidth: .infinity)
          .padding(.top, 4)
          .accessibilityIdentifier(AXID.browseRestore)

          if !viewModel.comingSoon.isEmpty {
            Text("More soon: \(viewModel.comingSoon.joined(separator: " · "))")
              .font(.system(size: 13, weight: .regular))
              .foregroundStyle(EnoughColor.tertiaryText)
              .frame(maxWidth: .infinity, alignment: .center)
          }
        }
        .padding(.horizontal, Layout.screenHPad)
        .padding(.bottom, 100)
      }

      if viewModel.showRestoredToast {
        restoredToast(viewModel: viewModel)
      }
    }
  }

  @ViewBuilder
  private func restoredToast(viewModel: BrowseViewModel) -> some View {
    Text("Purchases restored")
      .font(.system(size: 15, weight: .semibold))
      .foregroundStyle(.white)
      .padding(.horizontal, 18)
      .padding(.vertical, 10)
      .background(Capsule().fill(EnoughColor.graphite))
      .padding(.top, 8)
      .transition(.move(edge: .top).combined(with: .opacity))
      .onAppear {
        Task {
          try? await Task.sleep(for: .seconds(2))
          withAnimation {
            viewModel.showRestoredToast = false
          }
        }
      }
      .animation(.easeInOut(duration: Motion.selectionFade), value: viewModel.showRestoredToast)
  }

  @ViewBuilder
  private func countrySection(country: CountryInfo, viewModel: BrowseViewModel) -> some View {
    let accent = AccentTheme(rawValue: country.accent) ?? .japan

    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text("\(country.flagEmoji) \(country.name)")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(EnoughColor.label)

        EyebrowLabel(country.nativeLanguageName)
      }

      ForEach(country.bundles) { bundle in
        bundleCard(bundle: bundle, country: country, accent: accent, viewModel: viewModel)
      }

      deckList(country: country, accent: accent, viewModel: viewModel)
    }
  }

  @ViewBuilder
  private func bundleCard(
    bundle: BundleInfo, country: CountryInfo, accent: AccentTheme, viewModel: BrowseViewModel
  ) -> some View {
    let owned =
      viewModel.ownedProductIds.contains(bundle.id)
      || bundle.deckIds.allSatisfy { viewModel.ownedDeckIds.contains($0) }
    let savings = PricingCalculator.bundleSavings(bundle, in: country)

    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text(bundle.title)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(EnoughColor.label)

        Text("\(bundle.subtitle) · save \(PricingCalculator.price(savings))")
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(EnoughColor.secondaryText)
      }

      Spacer()

      trailingControl(
        control: TrailingControlSpec(
          productId: bundle.id, kind: .bundle, owned: owned, fallbackGBP: bundle.priceGBP,
          accent: accent
        ),
        viewModel: viewModel
      )
    }
    .padding(Layout.cardPad)
    .background(EnoughColor.surface)
    .cornerRadius(Layout.cardRadius)
  }

  @ViewBuilder
  private func deckList(
    country: CountryInfo, accent: AccentTheme, viewModel: BrowseViewModel
  ) -> some View {
    VStack(spacing: 0) {
      ForEach(Array(country.decks.enumerated()), id: \.element.id) { index, deck in
        deckRow(deck: deck, accent: accent, viewModel: viewModel)

        if index < country.decks.count - 1 {
          Divider()
            .padding(.leading, 66)
        }
      }
    }
    .background(EnoughColor.surface)
    .cornerRadius(Layout.cardRadius)
  }

  @ViewBuilder
  private func deckRow(
    deck: DeckInfo, accent: AccentTheme, viewModel: BrowseViewModel
  ) -> some View {
    let owned = viewModel.ownedDeckIds.contains(deck.id)

    HStack(spacing: 14) {
      Image(systemName: deck.icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(accent.deep)
        .frame(width: 34, height: 34)
        .background(accent.tint)
        .cornerRadius(10)

      VStack(alignment: .leading, spacing: 2) {
        Text(deck.title)
          .font(.system(size: 17, weight: .regular))
          .foregroundStyle(EnoughColor.label)

        Text("\(deck.cardCount) cards")
          .font(.system(size: 13, weight: .regular))
          .foregroundStyle(EnoughColor.tertiaryText)
      }

      Spacer()

      trailingControl(
        control: TrailingControlSpec(
          productId: deck.id, kind: .deck, owned: owned, fallbackGBP: deck.priceGBP, accent: accent
        ),
        viewModel: viewModel
      )
    }
    .padding(.horizontal, Layout.cardPad)
    .padding(.vertical, Layout.rowVPad)
  }

  @ViewBuilder
  private func trailingControl(
    control: TrailingControlSpec, viewModel: BrowseViewModel
  ) -> some View {
    let productId = control.productId
    let kind = control.kind
    let owned = control.owned
    let fallbackGBP = control.fallbackGBP
    let accent = control.accent

    if owned {
      HStack(spacing: 4) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(EnoughColor.successGreen)
        Text("Owned")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(EnoughColor.successGreen)
      }
    } else if viewModel.inFlightProductId == productId {
      ProgressView()
        .disabled(true)
    } else if viewModel.pendingProductId == productId {
      Text("Pending approval")
        .font(.system(size: 13, weight: .regular))
        .foregroundStyle(EnoughColor.secondaryText)
    } else {
      Button {
        Task { await viewModel.buy(productId: productId, kind: kind) }
      } label: {
        Text(viewModel.price(for: productId, fallbackGBP: fallbackGBP))
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(accent.deep)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Capsule().fill(accent.tint))
      }
      .disabled(viewModel.inFlightProductId != nil)
      .accessibilityIdentifier(AXID.buy(productId))
    }
  }
}

#Preview {
  BrowseView()
    .environment(\.accentTheme, .japan)
    .environment(\.services, AppServices.preview())
}
