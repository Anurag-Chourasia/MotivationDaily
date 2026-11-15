import SwiftUI
import LocalizationKit

extension HomeView {
    var categoryTabs: [CategoryTabItem] {
        var tabs: [CategoryTabItem] = [CategoryTabItem(key: nil, title: randomTabTitle)]
        tabs.append(contentsOf: categories.map { category in
            CategoryTabItem(key: category.key, title: categoryTitle(for: category))
        })
        return tabs
    }

    func selectCategory(_ key: CategoryKey?) {
        selectedCategory = key
        let lane = laneKey(category: key, ratio: selectedRatio)
        activeDepth = clampedDepth(cacheCoordinator.depthByLane[lane] ?? 0, for: key)
        targetDepth = activeDepth
        currentDepth = activeDepth
        cacheCoordinator.depthByLane[lane] = activeDepth
        scrollOffset = 0
        let hasCachedTarget = cachedContent(category: key, depth: activeDepth, ratio: selectedRatio) != nil
        loadCurrentCoordinate(forceFetch: !hasCachedTarget)
    }

    func loadCategoriesIfNeeded() async {
        guard categories.isEmpty else { return }
        let fallback: [Category]
        do {
            fallback = try await quoteVM.fetchCategories()
        } catch {
            fallback = []
        }

        categories = await pageVM.categories(fallback: fallback)
        randomQuoteCount = await pageVM.randomQuoteCount()
        let clamped = clampedDepth(currentDepth, for: selectedCategory)
        if clamped != currentDepth {
            currentDepth = clamped
            cacheCoordinator.depthByLane[laneKey(category: selectedCategory, ratio: selectedRatio)] = clamped
        }
    }

    func categoryTitle(for category: Category) -> String {
        guard let quoteCount = category.quoteCount else {
            return category.localizedDisplayName
        }
        return "\(category.localizedDisplayName) (\(quoteCount))"
    }

    var randomTabTitle: String {
        if let randomQuoteCount {
            return "\(String(\MotivationStrings.randomCategory)) (\(randomQuoteCount))"
        }
        return String(\MotivationStrings.randomCategory)
    }

    func allCategoryKeys() -> [CategoryKey?] {
        [nil] + categories.map { $0.key }
    }

    func selectAdjacentCategory(direction: Int) {
        let keys = allCategoryKeys()
        guard !keys.isEmpty else { return }

        let currentIndex = keys.firstIndex { $0 == selectedCategory } ?? 0
        var next = currentIndex + direction
        while next < 0 { next += keys.count }
        while next >= keys.count { next -= keys.count }
        selectCategory(keys[next])
    }

    func goToNextCategory() { selectAdjacentCategory(direction: 1) }

    func goToPreviousCategory() { selectAdjacentCategory(direction: -1) }
}
