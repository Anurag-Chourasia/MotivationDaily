import SwiftUI
import UIKit
import DesignTokensKit

struct SideActionIconView: View {
    let systemName: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: CornerRadius.six) {
            Image(systemName: resolvedSystemName)
                .symbolVariant(.none)
                .font(.system(size: DesignMetric.p20, weight: .bold))
                .foregroundColor(tint)
                .frame(width: DesignMetric.p50, height: DesignMetric.p50)
                .background(DesignColor.black.opacity(0.42))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DesignColor.white.opacity(0.28), lineWidth: StrokeWidth.one)
                )
                .shadow(color: DesignColor.black.opacity(0.28), radius: Spacing.eight, x: 0, y: Spacing.four)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DesignColor.white)
                .padding(.horizontal, Spacing.eight)
                .padding(.vertical, Spacing.four)
                .background(DesignColor.black.opacity(0.45))
                .clipShape(Capsule())
                .shadow(color: DesignColor.black.opacity(0.24), radius: Spacing.four, x: 0, y: StrokeWidth.two)
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
