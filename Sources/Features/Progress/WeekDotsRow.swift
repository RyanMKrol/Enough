import SwiftUI

struct WeekDotsRow: View {
  let dots: [DayDot]

  private let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<min(dots.count, 7), id: \.self) { index in
        VStack(spacing: 4) {
          ZStack {
            switch dots[index] {
            case .done:
              Circle()
                .fill(EnoughColor.streakAmber)

              Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)

            case .today:
              Circle()
                .stroke(Color.accentColor, lineWidth: 2)
                .background(Circle().fill(Color.white))

            case .upcoming, .missed:
              Circle()
                .fill(Color(hex: 0xe5e5ea))
            }
          }
          .frame(width: 24, height: 24)

          Text(dayLetters[index])
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(EnoughColor.tertiaryText)
        }
      }

      Spacer()
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("This week: \(doneCount) of 7 days practiced")
  }

  private var doneCount: Int {
    dots.prefix(7).filter { $0 == .done }.count
  }
}

#Preview {
  VStack(spacing: 16) {
    WeekDotsRow(
      dots: [DayDot.done, .done, .done, .done, .done, .today, .upcoming]
    )
    .padding()
    .background(EnoughColor.surface)

    WeekDotsRow(
      dots: [DayDot.done, .done, .done, .today, .upcoming, .upcoming, .upcoming]
    )
    .padding()
    .background(EnoughColor.surface)

    WeekDotsRow(
      dots: [DayDot.done, .missed, .missed, .today, .upcoming, .upcoming, .upcoming]
    )
    .padding()
    .background(EnoughColor.surface)

    WeekDotsRow(
      dots: [DayDot.upcoming, .upcoming, .upcoming, .today, .upcoming, .upcoming, .upcoming]
    )
    .padding()
    .background(EnoughColor.surface)
  }
  .padding()
  .background(EnoughColor.canvas)
}
