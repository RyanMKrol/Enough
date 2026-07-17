import SwiftUI

enum GradeChoice: CaseIterable {
  case again
  case hard
  case good
  case easy

  var title: String {
    switch self {
    case .again:
      "Again"
    case .hard:
      "Hard"
    case .good:
      "Good"
    case .easy:
      "Easy"
    }
  }

  var fill: Color {
    switch self {
    case .again:
      Color(hex: 0xffe9e6)
    case .hard:
      Color(hex: 0xf2f2f7)
    case .good:
      EnoughColor.successTint
    case .easy:
      EnoughColor.easyTint
    }
  }

  var textColor: Color {
    switch self {
    case .again:
      Color(hex: 0xb71824)
    case .hard:
      EnoughColor.secondaryText
    case .good:
      EnoughColor.successDeep
    case .easy:
      EnoughColor.easyBlue
    }
  }

  var axID: String {
    switch self {
    case .again:
      AXID.gradeAgain
    case .hard:
      AXID.gradeHard
    case .good:
      AXID.gradeGood
    case .easy:
      AXID.gradeEasy
    }
  }
}

struct GradeButtonRow: View {
  let previews: [GradeChoice: String]
  let onGrade: (GradeChoice) -> Void

  var body: some View {
    HStack(spacing: 8) {
      ForEach(GradeChoice.allCases, id: \.self) { choice in
        Button {
          onGrade(choice)
        } label: {
          VStack(spacing: 2) {
            Text(choice.title)
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(choice.textColor)

            Text(previews[choice] ?? "")
              .font(.system(size: 11, weight: .regular))
              .foregroundColor(choice.textColor.opacity(0.7))
          }
          .frame(maxWidth: .infinity)
          .frame(minHeight: 56)
          .background(
            RoundedRectangle(cornerRadius: Layout.chipRadius)
              .fill(choice.fill)
          )
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(choice.title)
          .accessibilityValue(previews[choice] ?? "")
        }
        .buttonStyle(GradeButtonStyle())
        .accessibilityIdentifier(choice.axID)
      }
    }
  }
}

struct GradeButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .animation(.easeInOut(duration: Motion.pressFeedbackFast), value: configuration.isPressed)
  }
}

#Preview {
  GradeButtonRow(
    previews: [
      .again: "<1 min",
      .hard: "1 day",
      .good: "3 days",
      .easy: "6 days",  // swiftlint:disable:this trailing_comma
    ],
    onGrade: { _ in }
  )
  .padding()
  .background(Color(hex: 0xf2f2f7))
}
