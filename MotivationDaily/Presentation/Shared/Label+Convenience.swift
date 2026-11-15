import SwiftUI
import DesignTokensKit
import LocalizationKit

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
