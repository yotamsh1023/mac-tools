import SwiftUI

struct ClipListView: View {
    let pinnedItems: [ClipItem]
    let recentItems: [ClipItem]
    let selectedID: UUID?
    let onSelect: (UUID) -> Void
    let onCopy: (ClipItem) -> Void
    let onEdit: (ClipItem) -> Void
    let onPin: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if !pinnedItems.isEmpty {
                        Section {
                            ForEach(pinnedItems) { item in
                                ClipRowView(
                                    item: item,
                                    isSelected: item.id == selectedID,
                                    onCopy: { onCopy(item) },
                                    onEdit: { onEdit(item) },
                                    onPin: { onPin(item.id) },
                                    onDelete: { onDelete(item.id) }
                                )
                                .onTapGesture(count: 2) { onEdit(item) }
                                .onTapGesture(count: 1) { onSelect(item.id) }
                                .id(item.id)
                                Divider().padding(.leading, 12)
                            }
                        } header: {
                            sectionHeader("Pinned")
                        }
                    }

                    if !recentItems.isEmpty {
                        Section {
                            ForEach(recentItems) { item in
                                ClipRowView(
                                    item: item,
                                    isSelected: item.id == selectedID,
                                    onCopy: { onCopy(item) },
                                    onEdit: { onEdit(item) },
                                    onPin: { onPin(item.id) },
                                    onDelete: { onDelete(item.id) }
                                )
                                .onTapGesture(count: 2) { onEdit(item) }
                                .onTapGesture(count: 1) { onSelect(item.id) }
                                .id(item.id)
                                Divider().padding(.leading, 12)
                            }
                        } header: {
                            sectionHeader("Recent")
                        }
                    }
                }
            }
            .onChange(of: selectedID) { id in
                if let id {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(.regularMaterial)
    }
}
