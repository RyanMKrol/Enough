import SwiftUI

struct FlowLayout<Content: View>: View {
  @State private var height: CGFloat = 0
  var spacing: CGFloat = 10
  let content: Content

  init(spacing: CGFloat = 10, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: spacing) {
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
