import SwiftUI
import UIKit

struct SideActionIconView: View {
    let systemName: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: resolvedSystemName)
                .symbolVariant(.none)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 50, height: 50)
                .background(Color.black.opacity(0.42))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 4)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.45))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.24), radius: 4, x: 0, y: 2)
        }
    }

    private var resolvedSystemName: String {
        if UIImage(systemName: systemName) != nil {
            return systemName
        }
        // Prefer the crop glyph family if available, otherwise fall back to a safe slider icon.
        if UIImage(systemName: "crop") != nil {
            return "crop"
        }
        if UIImage(systemName: "crop.square") != nil {
            return "crop.square"
        }
        return "slider.horizontal.3"
    }
}
