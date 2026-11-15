import SwiftUI
import DesignTokensKit
import LocalizationKit
import UIComponentsKit

struct ShareHeaderBarView: View {
    let onDone: () -> Void

    var body: some View {
        HStack {
            Text(\.share).font(\.headline)
            Spacer()
            Button(\.done, action: onDone).accessibilityIdentifier(.shareDoneButton)
        }
        .padding(\.sixteen)
    }
}
