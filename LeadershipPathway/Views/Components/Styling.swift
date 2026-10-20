import SwiftUI

extension PassageCategory {
    var color: Color {
        switch self {
        case .newTestament: .indigo
        case .psalms: .teal
        case .proverbs: .orange
        }
    }
}

extension ProgressStore {
    /// An in-memory store for SwiftUI previews, with the first two weeks read.
    static var preview: ProgressStore {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview-\(UUID().uuidString).json")
        let store = ProgressStore(plan: .bundled, storageURL: url)
        for day in store.plan.allDays.prefix(10) {
            store.setDay(day, complete: true)
        }
        return store
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
