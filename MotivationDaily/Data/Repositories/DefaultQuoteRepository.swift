import Foundation

final class DefaultQuoteRepository: QuoteRepository {
    private let zenClient: ZenQuotesClient
    private let quotableClient: QuotableClient
    private let adviceSlipClient: AdviceSlipClient
    private let mappingStore: CategoryMappingStore
    private let fallbackQuotes: [CategoryKey?: [(text: String, author: String)]]

    init(
        zenClient: ZenQuotesClient,
        quotableClient: QuotableClient,
        adviceSlipClient: AdviceSlipClient,
        mappingStore: CategoryMappingStore
    ) {
        self.zenClient = zenClient
        self.quotableClient = quotableClient
        self.adviceSlipClient = adviceSlipClient
        self.mappingStore = mappingStore
        self.fallbackQuotes = [
            nil: [
                ("Small progress each day adds up to big results.", "Unknown"),
                ("Discipline creates freedom.", "Jocko Willink"),
                ("You do not have to be extreme, just consistent.", "Unknown"),
                ("Start where you are. Use what you have. Do what you can.", "Arthur Ashe"),
                ("Action is the foundational key to all success.", "Pablo Picasso")
            ],
            CategoryKey(rawValue: "inspiration"): [
                ("Dream big. Start small. Act now.", "Robin Sharma"),
                ("Inspiration exists, but it has to find you working.", "Pablo Picasso")
            ],
            CategoryKey(rawValue: "wisdom"): [
                ("Knowing yourself is the beginning of all wisdom.", "Aristotle"),
                ("Turn your wounds into wisdom.", "Oprah Winfrey")
            ],
            CategoryKey(rawValue: "success"): [
                ("Success is the sum of small efforts repeated daily.", "Robert Collier"),
                ("Success is not final, failure is not fatal.", "Winston Churchill")
            ],
            CategoryKey(rawValue: "happiness"): [
                ("Happiness depends upon ourselves.", "Aristotle"),
                ("For every minute you are angry you lose sixty seconds of happiness.", "Ralph Waldo Emerson")
            ],
            CategoryKey(rawValue: "life"): [
                ("Life is really simple, but we insist on making it complicated.", "Confucius"),
                ("Life is what happens when you are busy making other plans.", "John Lennon")
            ]
        ]
    }

    func fetchRandom() async throws -> Quote {
        do {
            let zen = try await zenClient.fetchRandomQuote()
            return Quote(
                id: UUID().uuidString,
                text: zen.q,
                author: zen.a.replacingOccurrences(of: ", type.works", with: ""),
                source: .zenQuotes,
                categoryKey: nil
            )
        } catch {
            do {
                return try await fetchAdviceSlipQuote(categoryKey: nil)
            } catch {
                return fallbackQuote(for: nil)
            }
        }
    }

    func fetchByCategory(_ key: CategoryKey) async throws -> Quote {
        guard let mapping = mappingStore.mapping(for: key) else {
            do {
                return try await fetchAdviceSlipQuote(categoryKey: key)
            } catch {
                return fallbackQuote(for: nil)
            }
        }

        if let tags = mapping.quotableTags {
            do {
                let quotable = try await quotableClient.fetchRandomQuote(tags: tags)
                return Quote(
                    id: quotable._id,
                    text: quotable.content,
                    author: quotable.author,
                    source: .quotable,
                    categoryKey: key
                )
            } catch {
                // Fall through
            }
        }

        do {
            return try await fetchAdviceSlipQuote(categoryKey: key)
        } catch {
            return fallbackQuote(for: key)
        }
    }

    func fetchCategories() async throws -> [Category] {
        mappingStore.categories()
    }

    private func fallbackQuote(for key: CategoryKey?) -> Quote {
        let quotes = fallbackQuotes[key] ?? fallbackQuotes[nil] ?? []
        let selected = quotes.randomElement() ?? (text: "Keep going.", author: "Unknown")
        return Quote(
            id: UUID().uuidString,
            text: selected.text,
            author: selected.author,
            source: .zenQuotes,
            categoryKey: key
        )
    }

    private func fetchAdviceSlipQuote(categoryKey: CategoryKey?) async throws -> Quote {
        let advice = try await adviceSlipClient.fetchRandomAdvice()
        return Quote(
            id: String(advice.id),
            text: advice.advice,
            author: "Advice Slip",
            source: .adviceSlip,
            categoryKey: categoryKey
        )
    }
}
