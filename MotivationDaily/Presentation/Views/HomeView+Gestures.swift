import SwiftUI
import DesignTokensKit
import LocalizationKit

extension HomeView {
    var feedSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                guard !isActionRailInteraction(at: value.startLocation), !isHorizontallyDragging else { return }
                if !isDragging {
                    isDragging = true
                    gestureStartOffset = scrollOffset
                    reduceVisualEffectsForInteraction()
                }
                scrollOffset = gestureStartOffset + value.translation.height
            }
            .onEnded { value in
                if isHorizontallyDragging {
                    isHorizontallyDragging = false
                    return
                }
                isDragging = false
                guard !isActionRailInteraction(at: value.startLocation) else { return }
                handleVerticalSwipeEnd(value)
            }
    }

    var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isActionRailInteraction(at: value.startLocation) else { return }
                if !isHorizontallyDragging && abs(value.translation.width) > abs(value.translation.height) {
                    isHorizontallyDragging = true
                }
            }
            .onEnded { value in
                guard !isActionRailInteraction(at: value.startLocation) else { return }
                if isHorizontallyDragging {
                    let projected = value.translation.width + project(value.velocity.width)
                    if projected <= -40 { goToNextCategory() }
                    else if projected >= 40 { goToPreviousCategory() }
                    isHorizontallyDragging = false
                }
            }
    }

    private func handleVerticalSwipeEnd(_ value: DragGesture.Value) {
        let projected = scrollOffset + project(value.velocity.height)
        let pageHeight = max(containerSize.height, DesignMetric.p1)
        let rawShift = Int(round(-projected / pageHeight))
        let indexShift = max(-1, min(1, rawShift))
        let proposedDepth = activeDepth + indexShift
        let clamped = clampedDepth(proposedDepth, for: selectedCategory)
        let maxDepth = maxDepth(for: selectedCategory)

        if proposedDepth != clamped {
            let title = proposedDepth < 0 ? \MotivationStrings.feedTopTitle : \MotivationStrings.feedEndTitle
            let msg = proposedDepth < 0 ? \MotivationStrings.feedTopMessage : \MotivationStrings.feedEndMessage
            presentAlert(title: String(title), message: String(msg))
        } else if indexShift == 0 {
            if activeDepth == 0, value.translation.height > 24 {
                presentAlert(
                    title: String(\MotivationStrings.feedTopTitle),
                    message: String(\MotivationStrings.feedTopMessage)
                )
            } else if let maxDepth, activeDepth == maxDepth, value.translation.height < -24 {
                presentAlert(
                    title: String(\MotivationStrings.feedEndTitle),
                    message: String(\MotivationStrings.feedEndMessage)
                )
            }
        }
        targetDepth = clamped
        snapToDepth(targetDepth)
    }

    func project(_ velocity: CGFloat) -> CGFloat { velocity * 0.32 }
}
