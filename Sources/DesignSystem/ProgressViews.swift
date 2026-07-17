import SwiftUI

struct AnimatedProgressBar: View {
  let progress: Double
  let tint: Color
  let trackColor: Color

  @State private var displayedProgress: Double = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(trackColor)

        Capsule()
          .fill(tint)
          .frame(width: displayedProgress * geometry.size.width)
      }
      .frame(height: 5)
      .onAppear {
        withAnimation(
          Animation.easeOut(duration: Motion.barGrow)
        ) {
          displayedProgress = clampProgress(progress)
        }
      }
      .onChange(of: progress) { _, newProgress in
        withAnimation(
          Animation.easeOut(duration: Motion.barGrow)
        ) {
          displayedProgress = clampProgress(newProgress)
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityValue("\(percentValue) percent")
  }

  private var percentValue: Int {
    Int((clampProgress(progress) * 100).rounded())
  }

  private func clampProgress(_ value: Double) -> Double {
    max(0, min(1, value))
  }
}

struct ProgressRing: View {
  let progress: Double
  let size: CGFloat
  let lineWidth: CGFloat
  let tint: Color
  let showsPercent: Bool

  @State private var displayedProgress: Double = 0

  var body: some View {
    ZStack {
      Circle()
        .stroke(tint.opacity(0.15), lineWidth: lineWidth)

      Circle()
        .trim(from: 0, to: displayedProgress)
        .stroke(
          tint,
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))

      if showsPercent {
        Text("\(Int((clampProgress(progress) * 100).rounded()))%")
          .font(.system(size: size * 0.28, weight: .bold))
          .foregroundStyle(tint)
      }
    }
    .frame(width: size, height: size)
    .onAppear {
      withAnimation(
        Animation.easeOut(duration: Motion.ringFill)
      ) {
        displayedProgress = clampProgress(progress)
      }
    }
    .onChange(of: progress) { _, newProgress in
      withAnimation(
        Animation.easeOut(duration: Motion.ringFill)
      ) {
        displayedProgress = clampProgress(newProgress)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityValue("\(percentValue) percent")
  }

  private var percentValue: Int {
    Int((clampProgress(progress) * 100).rounded())
  }

  private func clampProgress(_ value: Double) -> Double {
    max(0, min(1, value))
  }
}

#Preview {
  VStack(spacing: 32) {
    VStack(alignment: .leading, spacing: 8) {
      Text("Progress Bar")
        .font(.headline)
      AnimatedProgressBar(
        progress: 0.27,
        tint: AccentTheme.japan.accent,
        trackColor: Color.black.opacity(0.08)
      )
      .padding()
      .background(Color.white)
      .cornerRadius(12)
    }

    VStack(alignment: .leading, spacing: 8) {
      Text("Progress Ring (40%)")
        .font(.headline)
      HStack {
        ProgressRing(
          progress: 0.4,
          size: 64,
          lineWidth: 6,
          tint: AccentTheme.japan.accent,
          showsPercent: true
        )
        Spacer()
      }
      .padding()
      .background(Color.white)
      .cornerRadius(12)
    }

    VStack(alignment: .leading, spacing: 8) {
      Text("Progress Ring (100%, no percent)")
        .font(.headline)
      HStack {
        ProgressRing(
          progress: 1.0,
          size: 120,
          lineWidth: 6,
          tint: AccentTheme.japan.accent,
          showsPercent: false
        )
        Spacer()
      }
      .padding()
      .background(Color.white)
      .cornerRadius(12)
    }

    Spacer()
  }
  .padding()
  .background(Color(hex: 0xf2f2f7))
}
