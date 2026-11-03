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
                .background(DesignColor.black.opacity(OpacityToken.p0_35 + OpacityToken.p0_15 / 2))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DesignColor.white.opacity(OpacityToken.p0_2 + OpacityToken.p0_15 / 2), lineWidth: StrokeWidth.one)
                )
                .shadow(color: DesignColor.black.opacity(OpacityToken.p0_2 + OpacityToken.p0_15 / 2), radius: Spacing.eight, x: 0, y: Spacing.four)

            Text(label)
                .font(Typography.caption2)
                .foregroundColor(DesignColor.white)
                .padding(.horizontal, Spacing.eight)
                .padding(.vertical, Spacing.four)
                .background(DesignColor.black.opacity(OpacityToken.p0_35 + OpacityToken.p0_15 / 1.5))
                .clipShape(Capsule())
                .shadow(color: DesignColor.black.opacity(OpacityToken.p0_2 + OpacityToken.p0_15 / 3), radius: Spacing.four, x: 0, y: StrokeWidth.two)
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
