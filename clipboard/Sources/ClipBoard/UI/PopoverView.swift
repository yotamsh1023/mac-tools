import SwiftUI

struct PopoverView: View {
    @StateObject private var vm: ClipViewModel
    @State private var selectedID: UUID?
    @State private var editingItem: ClipItem?

    init(store: ClipStore) {
        _vm = StateObject(wrappedValue: ClipViewModel(store: store))
    }

    var body: some View {
        ZStack {
            mainContent

            if let item = editingItem {
                EditView(
                    item: item,
                    onCopy: { text in
                        vm.copyText(text)
                        editingItem = nil
                    },
                    onSaveAndCopy: { text in
                        vm.saveAndCopy(id: item.id, newText: text)
                        editingItem = nil
                    },
                    onDismiss: { editingItem = nil }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .frame(width: 360, height: 520)
        .background(.regularMaterial)
        .animation(.easeInOut(duration: 0.2), value: editingItem?.id)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            SearchBarView(text: $vm.searchQuery)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            Divider()

            if vm.filteredItems.isEmpty {
                emptyState
            } else {
                ClipListView(
                    pinnedItems: vm.pinnedItems,
                    recentItems: vm.recentItems,
                    selectedID: selectedID,
                    onSelect: { selectedID = $0 },
                    onCopy: { item in
                        vm.copyToClipboard(item)
                        selectedID = item.id
                    },
                    onEdit: { item in
                        guard item.contentType == .text else { return }
                        editingItem = item
                    },
                    onPin: { vm.togglePin($0) },
                    onDelete: { vm.delete($0) }
                )
            }

            Divider()

            FooterView(
                count: vm.recentItems.count,
                onClear: vm.clearHistory
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(
            KeyboardHandler(
                onUp: { moveSelection(-1) },
                onDown: { moveSelection(1) },
                onActivate: copySelected,
                onEdit: openEditForSelected
            )
            .frame(width: 0, height: 0)
        )
        .onAppear {
            if selectedID == nil {
                selectedID = vm.filteredItems.first?.id
            }
        }
        .onChange(of: vm.filteredItems) { items in
            if selectedID == nil || !items.contains(where: { $0.id == selectedID }) {
                selectedID = items.first?.id
            }
        }
    }

    private func moveSelection(_ delta: Int) {
        let items = vm.filteredItems
        guard !items.isEmpty else { return }
        if let current = selectedID,
           let idx = items.firstIndex(where: { $0.id == current }) {
            let newIdx = max(0, min(items.count - 1, idx + delta))
            selectedID = items[newIdx].id
        } else {
            selectedID = items.first?.id
        }
    }

    private func copySelected() {
        guard let id = selectedID,
              let item = vm.filteredItems.first(where: { $0.id == id }) else { return }
        vm.copyToClipboard(item)
    }

    private func openEditForSelected() {
        guard let id = selectedID,
              let item = vm.filteredItems.first(where: { $0.id == id }),
              item.contentType == .text else { return }
        editingItem = item
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(vm.searchQuery.isEmpty ? "No clipboard history yet" : "No results")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FooterView: View {
    let count: Int
    let onClear: () -> Void

    var body: some View {
        HStack {
            Text("\(count) item\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Clear History", action: onClear)
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.8))
        }
    }
}
