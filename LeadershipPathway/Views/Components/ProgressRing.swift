import SwiftUI

struct ProgressRing: View {
    let fraction: Double
    var lineWidth: CGFloat = 12
    var tint: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(fraction, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: fraction)
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    ProgressRing(fraction: 0.42)
        .frame(width: 120, height: 120)
        .padding()
}
