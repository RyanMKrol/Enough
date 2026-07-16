import SwiftUI

struct ReviewsBanner: View {
  let dueCount: Int
  let onReview: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Circle()
        .fill(EnoughColor.easyTint)
        .frame(width: 34, height: 34)
        .overlay(
          Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(EnoughColor.linkBlue)
        )

      VStack(alignment: .leading, spacing: 2) {
        Text("\(dueCount) cards ready to review")
          .font(.system(size: 15, weight: .semibold))
          .foregroundColor(EnoughColor.label)

        Text("Spaced repetition · keeps them stuck")
          .font(.system(size: 13, weight: .regular))
          .foregroundColor(EnoughColor.secondaryText)
      }

      Spacer()

      Button(action: onReview) {
        Text("Review")
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(EnoughColor.linkBlue)
          .padding(.vertical, 8)
          .padding(.horizontal, 14)
          .background(Capsule().fill(EnoughColor.easyTint))
      }
    }
    .padding(16)
    .background(EnoughColor.surface)
    .cornerRadius(20)
    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
  }
}

#Preview {
  VStack(spacing: 16) {
    ReviewsBanner(dueCount: 12, onReview: {})
      .padding()
  }
  .frame(maxHeight: .infinity, alignment: .top)
  .background(EnoughColor.canvas)
}
