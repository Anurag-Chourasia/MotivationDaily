import Foundation

final class CategoryMappingStore {
    struct Mapping {
        let displayName: String
        let quotableTags: String?
    }

    private let mappings: [CategoryKey: Mapping] = [
        CategoryKey(rawValue: "inspiration"): Mapping(
            displayName: "Inspiration",
            quotableTags: "inspirational"
        ),
        CategoryKey(rawValue: "wisdom"): Mapping(
            displayName: "Wisdom",
            quotableTags: "wisdom"
        ),
        CategoryKey(rawValue: "success"): Mapping(
            displayName: "Success",
            quotableTags: "success"
        ),
        CategoryKey(rawValue: "happiness"): Mapping(
            displayName: "Happiness",
            quotableTags: "happiness"
        ),
        CategoryKey(rawValue: "life"): Mapping(
            displayName: "Life",
            quotableTags: "life"
        )
    ]

    func categories() -> [Category] {
        mappings.keys
            .sorted { $0.rawValue < $1.rawValue }
            .map { key in
                let name = mappings[key]?.displayName ?? key.rawValue.capitalized
                return Category(key: key, displayName: name)
            }
    }

    func mapping(for key: CategoryKey) -> Mapping? {
        mappings[key]
    }
}
