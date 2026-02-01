import SwiftUI

/// A tooltip view that points to a specific tab in the tab bar
struct TabTooltip: View {
    let text: String
    let tabIndex: Int
    let totalTabs: Int
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            // Calculate offset from center: tab 1 of 5 is at 30%, center is 50%, so -20%
            let tabFraction = (CGFloat(tabIndex) + 0.5) / CGFloat(totalTabs)
            let offsetFromCenter = (tabFraction - 0.5) * geometry.size.width

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    Text(text)
                        .font(Theme.bodyFont)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.background)
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.vertical, Theme.spacingSM)
                        .background(Theme.accent)
                        .cornerRadius(Theme.cornerRadiusSM)

                    Triangle()
                        .fill(Theme.accent)
                        .frame(width: 14, height: 8)
                }
                .offset(x: offsetFromCenter)
                .padding(.bottom, 58)
            }
            .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
    }
}

/// Triangle shape for tooltip arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TabTooltip(text: "Add more anytime here", tabIndex: 1, totalTabs: 5, onDismiss: {})
    }
}
