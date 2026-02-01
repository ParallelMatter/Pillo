import SwiftUI

/// A tooltip view that points to a specific tab in the tab bar
struct TabTooltip: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Tooltip bubble
                Text(text)
                    .font(Theme.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, Theme.spacingMD)
                    .padding(.vertical, Theme.spacingSM)
                    .background(Theme.accent)
                    .cornerRadius(Theme.cornerRadiusSM)
                    .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 4)

                // Arrow pointing down
                Triangle()
                    .fill(Theme.accent)
                    .frame(width: 14, height: 8)
            }
            .position(
                x: geometry.size.width * 0.3, // Routine tab is ~30% from left (2nd of 5 tabs)
                y: geometry.size.height - 70  // Above tab bar
            )
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
        TabTooltip(text: "Add more anytime here", onDismiss: {})
    }
}
