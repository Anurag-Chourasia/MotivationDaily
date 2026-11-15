import Foundation
import CommonNetworkingKit

extension AppContainer {
    static func makeFeedCatalogueStore(
        apiService: APIService,
        quotableClient: QuotableClient,
        zenClient: ZenQuotesClient,
        adviceSlipClient: AdviceSlipClient,
        arguments: [String]
    ) -> FeedCatalogueStore {
        #if DEBUG
        let scenario = AppRuntime.stubScenario
        let isStubMode = arguments.contains("-UITestMode") || scenario != nil
        if isStubMode {
            if scenario == "empty" {
                return FeedCatalogueStore.makeEmptyUITestStore(
                    apiService: apiService, quotableClient: quotableClient,
                    zenClient: zenClient, adviceSlipClient: adviceSlipClient
                )
            } else if scenario == "offline" {
                return FeedCatalogueStore.makeOfflineUITestStore(
                    apiService: apiService, quotableClient: quotableClient,
                    zenClient: zenClient, adviceSlipClient: adviceSlipClient
                )
            } else {
                return FeedCatalogueStore.makeUITestStore(
                    apiService: apiService, quotableClient: quotableClient,
                    zenClient: zenClient, adviceSlipClient: adviceSlipClient
                )
            }
        }
        #endif
        return FeedCatalogueStore(
            apiService: apiService, quotableClient: quotableClient,
            zenClient: zenClient, adviceSlipClient: adviceSlipClient
        )
    }

    static func makeQuoteRepository(
        zenClient: ZenQuotesClient,
        quotableClient: QuotableClient,
        adviceSlipClient: AdviceSlipClient,
        mappingStore: CategoryMappingStore,
        arguments: [String]
    ) -> any QuoteRepository {
        #if DEBUG
        let scenario = AppRuntime.stubScenario
        if arguments.contains("-UITestMode") || scenario != nil {
            return PreviewQuoteRepository(isEmpty: scenario == "empty")
        }
        #endif
        return DefaultQuoteRepository(
            zenClient: zenClient, quotableClient: quotableClient,
            adviceSlipClient: adviceSlipClient, mappingStore: mappingStore
        )
    }

    static func makeWallpaperRepository(
        quoteRepository: any QuoteRepository,
        imageRepository: any ImageRepository,
        arguments: [String]
    ) -> any WallpaperRepository {
        #if DEBUG
        let scenario = AppRuntime.stubScenario
        if arguments.contains("-UITestMode") || scenario != nil {
            if scenario == "empty" || scenario == "offline" {
                return DefaultWallpaperRepository(quoteRepository: quoteRepository, imageRepository: imageRepository)
            }
            return UITestWallpaperRepository()
        }
        #endif
        return DefaultWallpaperRepository(quoteRepository: quoteRepository, imageRepository: imageRepository)
    }
}
