import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import DesignTokensKit
import LocalizationKit

struct SideActionIconView: View {
    enum LabelType {
        case motivation(KeyPath<MotivationStrings, String>)
        case common(KeyPath<CommonStrings, String>)
        case text(String)
    }

    let symbol: KeyPath<SymbolTheme, AppSymbol>
    let labelType: LabelType
    let tintKeyPath: KeyPath<ColorTheme, Color>

    @Environment(\.designTokens) private var theme

    init(
        _ symbol: KeyPath<SymbolTheme, AppSymbol>,
        _ label: KeyPath<MotivationStrings, String>,
        tint: KeyPath<ColorTheme, Color> = \.white
    ) {
        self.symbol = symbol
        self.labelType = .motivation(label)
        self.tintKeyPath = tint
    }

    init(
        _ symbol: KeyPath<SymbolTheme, AppSymbol>,
        _ label: KeyPath<CommonStrings, String>,
        tint: KeyPath<ColorTheme, Color> = \.white
    ) {
        self.symbol = symbol
        self.labelType = .common(label)
        self.tintKeyPath = tint
    }

    init(
        _ symbol: KeyPath<SymbolTheme, AppSymbol>,
        label: String,
        tint: KeyPath<ColorTheme, Color> = \.white
    ) {
        self.symbol = symbol
        self.labelType = .text(label)
        self.tintKeyPath = tint
    }

    var body: some View {
        VStack(spacing: \.six) {
            Image(symbol)
                .symbolVariant(.none)
                .font(size: \.p20, weight: .bold)
                .foregroundColor(tintKeyPath)
                .frame(width: \.p50, height: \.p50)
                .background(\.black, opacity: \.p0_4)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(\.white, opacity: \.p0_3, lineWidth: \.one)
                )
                .shadow(color: \.black, opacity: \.p0_3, radius: \.eight, y: \.four)

            labelView
                .font(\.caption2)
                .foregroundColor(\.white)
                .padding(.horizontal, \.eight)
                .padding(.vertical, \.four)
                .background(\.black, opacity: \.p0_4)
                .clipShape(Capsule())
                .shadow(color: \.black, opacity: \.p0_25, radius: \.four, y: \.two)
        }
        .frame(width: \.p100)
    }

    @ViewBuilder
    private var labelView: some View {
        switch labelType {
        case .motivation(let keyPath):
            Text(keyPath)
        case .common(let keyPath):
            Text(keyPath)
        case .text(let string):
            Text(string)
        }
    }
}

// MARK: - KeyPath Label Convenience Extensions

extension Label where Title == Text, Icon == Image {
    init(_ titleKeyPath: KeyPath<MotivationStrings, String>, _ symbolKeyPath: KeyPath<SymbolTheme, AppSymbol>) {
        self.init {
            Text(titleKeyPath)
        } icon: {
            Image(symbolKeyPath)
        }
    }

    init(_ titleKeyPath: KeyPath<CommonStrings, String>, _ symbolKeyPath: KeyPath<SymbolTheme, AppSymbol>) {
        self.init {
            Text(titleKeyPath)
        } icon: {
            Image(symbolKeyPath)
        }
    }
}
