import SwiftUI

/// A tappable checklist row for one passage of a reading day.
struct PassageRow: View {
    @EnvironmentObject private var store: ProgressStore
    let day: ReadingDay
    let index: Int

    private var passage: Passage { day.passages[index] }
    private var isComplete: Bool { store.isComplete(day, passage: index) }

    var body: some View {
        Button {
            withAnimation(.snappy) { store.togglePassage(day, index: index) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isComplete ? passage.category.color : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(passage.displayName)
                        .font(.body.weight(.medium))
                        .strikethrough(isComplete, color: .secondary)
                        .foregroundStyle(isComplete ? Color.secondary : Color.primary)
                    Label(passage.category.title, systemImage: passage.category.symbol)
                        .font(.caption)
                        .foregroundStyle(passage.category.color)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isComplete) { _, new in new }
        .accessibilityAddTraits(isComplete ? .isSelected : [])
        .accessibilityHint(isComplete ? "Marks this passage as unread" : "Marks this passage as read")
    }
}
