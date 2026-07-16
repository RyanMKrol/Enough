import SwiftUI

struct DebugMenuView: View {
  @Environment(\.services) private var services
  @Environment(\.dismiss) private var dismiss
  @State private var toast: String?

  var body: some View {
    NavigationStack {
      List {
        ForEach(DebugProviders.all) { section in
          Section(section.title) {
            ForEach(section.rows) { row in
              rowView(row)
            }
          }
        }

        Section {
        } footer: {
          Text("Debug menu — not user-facing.")
        }
      }
      .accessibilityIdentifier(AXID.screenDebug)
      .navigationTitle("Debug")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
      .overlay(alignment: .bottom) {
        if let toast {
          Text(toast)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .padding(.bottom, 24)
        }
      }
    }
  }

  @ViewBuilder
  private func rowView(_ row: DebugRow) -> some View {
    switch row.kind {
    case .action(let action):
      Button(row.title) {
        Task {
          do {
            let message = try await action(services)
            showToast(message)
          } catch {
            showToast("\(error)")
          }
        }
      }

    case .stepper(let get, let set, let label):
      Stepper(
        "\(row.title): \(label(get(services)))",
        onIncrement: { set(services, get(services) + 1) },
        onDecrement: { set(services, get(services) - 1) }
      )

    case .info(let value):
      LabeledContent(row.title, value: value(services))
    }
  }

  private func showToast(_ message: String) {
    toast = message
    Task {
      try? await Task.sleep(for: .seconds(2))
      toast = nil
    }
  }
}

#Preview {
  DebugMenuView()
}
