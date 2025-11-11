import SwiftUI

// MARK: - Empty State
struct EmptyFavoritesView: View {
    var body: some View {
        VStack {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Favorites Yet")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
