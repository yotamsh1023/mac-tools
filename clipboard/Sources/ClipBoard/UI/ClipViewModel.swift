import Foundation
import Combine
import AppKit

final class ClipViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published private(set) var filteredItems: [ClipItem] = []

    private let store: ClipStore
    private var cancellables = Set<AnyCancellable>()

    init(store: ClipStore) {
        self.store = store

        Publishers.CombineLatest($searchQuery, store.$items)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] query, _ in
                self?.updateFilter(query: query)
            }
            .store(in: &cancellables)
    }

    private func updateFilter(query: String) {
        filteredItems = query.isEmpty ? store.items : store.search(query: query)
    }

    var pinnedItems: [ClipItem] { filteredItems.filter { $0.isPinned } }
    var recentItems: [ClipItem] { filteredItems.filter { !$0.isPinned } }

    func copyToClipboard(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.contentType {
        case .text:
            pb.setString(item.textContent ?? "", forType: .string)
        case .image:
            if let data = item.imageData {
                pb.setData(data, forType: .png)
            }
        case .fileURL:
            if let path = item.fileURL {
                pb.writeObjects([NSURL(fileURLWithPath: path)])
            }
        }
        NotificationCenter.default.post(name: .clipboardDidWrite, object: nil)
    }

    func togglePin(_ id: UUID) {
        store.togglePin(id)
    }

    func delete(_ id: UUID) {
        store.delete(id)
    }

    func clearHistory() {
        store.clearHistory()
    }

    /// Copy an edited string to clipboard without saving
    func copyText(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        NotificationCenter.default.post(name: .clipboardDidWrite, object: nil)
    }

    /// Update a stored text clip and copy it
    func saveAndCopy(id: UUID, newText: String) {
        store.updateText(id: id, newText: newText)
        copyText(newText)
    }
}

extension Notification.Name {
    static let clipboardDidWrite = Notification.Name("clipboardDidWrite")
}
