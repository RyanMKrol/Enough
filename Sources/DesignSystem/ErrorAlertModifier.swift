import SwiftUI

extension View {
  func errorAlert(_ title: String, message: Binding<String?>) -> some View {
    alert(
      title,
      isPresented: Binding(
        get: { message.wrappedValue != nil },
        set: { if !$0 { message.wrappedValue = nil } }
      )
    ) {
      Button("OK") { message.wrappedValue = nil }
    } message: {
      Text(message.wrappedValue ?? "")
    }
  }
}
