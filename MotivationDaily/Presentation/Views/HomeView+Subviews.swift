import SwiftUI
import AuthKit
import AuthKitUI
import DesignTokensKit
import LocalizationKit

extension HomeView {
    var feedContainer: some View {
        HomeFeedContainerView(
            activeDepth: activeDepth, scrollOffset: scrollOffset,
            selectedCategory: selectedCategory, selectedRatio: selectedRatio,
            visualEffectsReduced: visualEffectsReduced,
            isConnected: networkMonitor.isConnected,
            hasError: pageVM.refreshError != nil,
            isEmpty: categories.isEmpty && initialBootHasRun,
            cachedContent: { depth in
                let clamped = clampedDepth(depth, for: selectedCategory)
                return cachedContent(category: selectedCategory, depth: clamped, ratio: selectedRatio)
            },
            isFavorited: { quoteVM.isFavorited(quote: $0) },
            onSelectRatio: { selectRatio($0) },
            onToggleFavorite: { toggleFavorite(for: $0) },
            onShare: { shareContent($0) },
            onRetry: { loadCurrentCoordinate(forceFetch: true) },
            onPrewarmCell: {
                let clamped = clampedDepth($0, for: selectedCategory)
                prewarmCell(category: selectedCategory, depth: clamped, ratio: selectedRatio)
            }
        )
    }

    var topChromeView: some View {
        HomeTopChromeView(
            selectedAccentTheme: selectedAccentTheme,
            user: user, sessionManager: sessionManager,
            tabs: categoryTabs, selectedCategory: selectedCategory,
            banner: (showConnectivityBanner, connectivityMessage, connectivityBannerIsWarning),
            namespace: categoryTabNamespace,
            actions: HomeTopChromeActions(
                onSelectTheme: { selectAccentTheme($0) }, onSelectCategory: { selectCategory($0) },
                onShowFavorites: { openFavorites() }, onShowAbout: { openAbout() },
                onShowUserSettings: { showUserSettings = true }, onRequestDeleteAccount: { requestDeleteAccount() }
            )
        )
    }

    @ViewBuilder
    var userSettingsSheetContent: some View {
        UserSettingsSheet(
            user: resolvedUser,
            isLoading: sessionManager?.isLoading ?? false,
            aboutConfiguration: UserSettingsAboutConfiguration(
                appName: String(\MotivationStrings.motivationAppName), version: AppRuntime.version,
                build: AppRuntime.build, disclaimerTitle: String(\MotivationStrings.profileDisclaimer),
                disclaimerText: String(\MotivationStrings.aboutDisclaimer)
            ),
            currentAppScheme: "motivationdaily",
            onSaveProfile: { email, first, last, phone in
                Task { await sessionManager?.updateProfile(email: email, firstName: first, lastName: last, phone: phone) }
            },
            onSendOTP: { try await sessionManager?.sendPasswordResetOTP() },
            onChangePassword: { current, new, otp in
                try await sessionManager?.changePassword(
                    currentPassword: current, newPassword: new, otpCode: otp
                )
            },
            onUpdatePassword: { await sessionManager?.updatePassword($0) },
            onSignOut: { Task { await sessionManager?.signOut(); showUserSettings = false } },
            onDeleteAccount: {
                Task { quoteVM.clearAllFavorites(); await sessionManager?.deleteAccount(); showUserSettings = false }
            },
            onDismiss: { showUserSettings = false }
        )
    }

    private var resolvedUser: AuthUser? {
        if case .authenticated(let u) = sessionManager?.state { return u } else { return user }
    }

    @ViewBuilder
    var shareSheetContent: some View {
        let active = sharingContent ?? pageVM.current
        ShareImageQuoteView(
            favorite: nil, favoriteImage: nil, quote: active?.quote,
            wallpaper: active?.image, layoutSize: shareLayoutSize(), imageLoader: imageLoader
        )
    }

    @ViewBuilder
    var deleteAccountButtons: some View {
        Button(\CommonStrings.accountDeleteConfirmationAction, role: .destructive) {
            Task { quoteVM.clearAllFavorites(); await sessionManager?.deleteAccount() }
        }
        Button(\CommonStrings.cancel, role: .cancel) {}
    }

    func cleanupTasks() {
        bannerHideTask?.cancel()
        visualEffectsRestoreTask?.cancel()
        cacheCoordinator.cancelAllFetchTasks()
    }
}
