import SwiftUI
import DesignTokensKit
import UIComponentsKit

struct CategoryTabItem: Identifiable, Equatable {
    let key: CategoryKey?
    let title: String
    var id: String { key?.rawValue ?? "random" }
}

struct HomeCategoryBarView: View {
    let tabs: [CategoryTabItem]
    let selectedCategory: CategoryKey?
    let selectedAccentTheme: AccentTheme
    let onSelectCategory: (CategoryKey?) -> Void
    var namespace: Namespace.ID

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: \.eight) {
                    ForEach(tabs) { tab in
                        categoryTabButton(tab: tab)
                    }
                }
                .padding(.horizontal, \.four)
            }
            .accessibilityIdentifier(.contentCategoryTabs)
            .onAppear { proxy.scrollTo(selectedCategory?.rawValue ?? "random", anchor: .center) }
            .onChange(of: selectedCategory) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(selectedCategory?.rawValue ?? "random", anchor: .center)
                }
            }
        }
    }

    private func categoryTabButton(tab: CategoryTabItem) -> some View {
        let isSelected = tab.key == selectedCategory
        return Button(action: { onSelectCategory(tab.key) }) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: \.sixteen)
                        .fill(selectedAccentTheme.color.opacity(OpacityTheme.default.p0_25))
                        .matchedGeometryEffect(id: "category-tab", in: namespace)
                }
                Text(tab.title)
                    .font(\.footnote)
                    .foregroundColor(
                        isSelected ? selectedAccentTheme.color : ColorTheme.default.white.opacity(OpacityTheme.default.p0_7)
                    )
                    .padding(.horizontal, \.twelve)
                    .padding(.vertical, \.five)
            }
        }
        .buttonStyle(.plain)
        .id(tab.id)
    }
}
