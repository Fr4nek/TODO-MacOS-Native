import SwiftUI

struct CircleButton: View {
    // MARK: - Configuration
    var systemImage: String
    var size: CGFloat = 56
    var foregroundColor: Color = .white
    var shadow: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: size, height: size)
                .background {
                    Circle().fill(.clear)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .clipShape(Circle())
        .shadow(color: shadow ? .black.opacity(0.15) : .clear, radius: shadow ? 4 : 0, x: 0, y: shadow ? 2 : 0)
        .accessibilityLabel(Text(systemImage.replacingOccurrences(of: ".", with: " "))) // simple label from symbol name
    }
}















#Preview("CircleButton Examples") {
    VStack(spacing: 24) {
        CircleButton(systemImage: "heart.fill") {
            print("Heart tapped")
        }
        CircleButton(systemImage: "plus", size: 44) {
            print("Plus tapped")
        }
        CircleButton(systemImage: "trash", size: 56, foregroundColor: .white, shadow: false) {
            print("Trash tapped")
        }
    }
    .padding()
}
