import SwiftUI

struct PlanView: View {
  @Environment(\.services) private var services
  @Environment(OnboardingDraft.self) private var draft

  let onFinish: () -> Bool

  @State private var catalog: ContentCatalog?
  @State private var vm: PlanViewModel?
  @State private var isPurchasing = false
  @State private var pendingNote: String?
  @State private var errorNote: String?
  @State private var showBrowseSheet = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        if let vm, let country = selectedCountry {
          bundleRows(vm: vm, country: country)
          orDivider
          packCard(vm: vm)
          browseLink(country: country)
        }
      }
      .padding(.horizontal, 22)
      .padding(.top, 12)
      .padding(.bottom, 160)
    }
    .background(EnoughColor.surface)
    .safeAreaInset(edge: .bottom) {
      if let vm {
        footer(vm: vm)
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        OnboardingBackButton()
      }
    }
    .navigationBarBackButtonHidden(true)
    .accessibilityIdentifier(AXID.screenPlan)
    .onAppear(perform: loadCatalog)
  }

  private var selectedCountry: CountryInfo? {
    catalog?.countries.first(where: { $0.id == draft.selectedCountryId })
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      EyebrowLabel("STEP 3 OF 3")

      Text("Your plan")
        .font(.system(size: 30, weight: .bold))
        .tracking(-0.02 * 30)
        .foregroundColor(EnoughColor.label)

      Text("Built from your answers — pick a bundle or add packs à la carte.")
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(EnoughColor.secondaryText)
    }
  }

  private func bundleRows(vm: PlanViewModel, country: CountryInfo) -> some View {
    VStack(spacing: 10) {
      ForEach(country.bundles) { bundle in
        BundleRowView(
          title: bundle.title,
          subtitle: vm.bundleSubtitle(for: bundle),
          price: services.purchase.displayPrice(productId: bundle.id)
            ?? PricingCalculator.price(bundle.priceGBP),
          isPopular: bundle.popular,
          isSelected: draft.selectedBundleId == bundle.id,
          action: { vm.selectBundle(bundle.id) }
        )
      }
    }
  }

  private var orDivider: some View {
    HStack(spacing: 12) {
      Rectangle()
        .fill(Color.black.opacity(0.08))
        .frame(height: 0.5)

      Text("or choose packs")
        .font(.system(size: 13, weight: .regular))
        .foregroundColor(EnoughColor.tertiaryText)
        .fixedSize()

      Rectangle()
        .fill(Color.black.opacity(0.08))
        .frame(height: 0.5)
    }
  }

  private func packCard(vm: PlanViewModel) -> some View {
    VStack(spacing: 0) {
      ForEach(Array(vm.packRows.enumerated()), id: \.element.deck.id) { index, row in
        if index > 0 {
          Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 0.5)
            .padding(.leading, 49)
        }

        PackChecklistRow(
          name: row.deck.title,
          cardCount: row.deck.cardCount,
          state: row.state,
          onToggle: isInBundle(row.state) ? nil : { vm.togglePack(row.deck.id) }
        )
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 4)
    .background(EnoughColor.surface)
    .cornerRadius(18)
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.black.opacity(0.08), lineWidth: 1)
    )
  }

  private func isInBundle(_ state: PackRowState) -> Bool {
    if case .inBundle = state { return true }
    return false
  }

  private func browseLink(country: CountryInfo) -> some View {
    Button {
      showBrowseSheet = true
    } label: {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(EnoughColor.linkBlue)

        Text("Browse all \(country.name) decks")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(EnoughColor.linkBlue)
      }
    }
    .accessibilityIdentifier("plan-browse-link")
    .sheet(isPresented: $showBrowseSheet) {
      BrowseView(countryId: country.id)
    }
  }

  private func footer(vm: PlanViewModel) -> some View {
    VStack(spacing: 8) {
      footerSummaryRow(vm: vm)
      footerNotes
      Text("One-time purchase · yours forever")
        .font(.system(size: 12, weight: .regular))
        .foregroundColor(EnoughColor.tertiaryText)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .padding(.horizontal, 22)
    .padding(.top, 16)
    .padding(.bottom, 16)
    .background(
      LinearGradient(
        colors: [EnoughColor.surface.opacity(0), EnoughColor.surface, EnoughColor.surface],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }

  private func footerSummaryRow(vm: PlanViewModel) -> some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 2) {
        Text(vm.summary)
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(EnoughColor.label)

        Text(vm.totalLabel)
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(EnoughColor.label)
      }

      Spacer()

      Button(
        action: { purchase(vm: vm) },
        label: {
          if isPurchasing {
            ProgressView()
              .progressViewStyle(.circular)
              .tint(.white)
          } else {
            Text(vm.ctaTitle)
              .lineLimit(1)
              .minimumScaleFactor(0.7)
          }
        }
      )
      .buttonStyle(PrimaryButtonStyle(background: draft.accent.accent))
      .disabled(isPurchasing)
      .frame(minWidth: 180)
      .accessibilityIdentifier(AXID.onboardingContinue)
    }
  }

  @ViewBuilder
  private var footerNotes: some View {
    if let pendingNote {
      Text(pendingNote)
        .font(.system(size: 13, weight: .regular))
        .foregroundColor(EnoughColor.secondaryText)
    }

    if let errorNote {
      Text(errorNote)
        .font(.system(size: 13, weight: .regular))
        .foregroundColor(draft.accent.accent)
    }
  }

  private func loadCatalog() {
    guard catalog == nil else { return }
    let loaded = try? services.contentStore.catalog()
    catalog = loaded
    if let country = loaded?.countries.first(where: { $0.id == draft.selectedCountryId }) {
      vm = PlanViewModel(country: country, draft: draft)
    }
  }

  private func purchase(vm: PlanViewModel) {
    errorNote = nil
    pendingNote = nil
    isPurchasing = true

    Task {
      do {
        let outcome = try await vm.purchaseSelection(purchase: services.purchase)
        isPurchasing = false

        switch outcome {
        case .success:
          if !onFinish() {
            errorNote = "We couldn't finish setup. Your purchase is safe — tap Continue to retry."
          }
        case .cancelled:
          break
        case .pending:
          pendingNote = "Pending approval — you can finish once it's confirmed"
        }
      } catch {
        isPurchasing = false
        errorNote = "Purchase failed — try again"
      }
    }
  }
}
