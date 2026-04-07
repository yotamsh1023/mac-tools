import SwiftUI
import AppKit

struct ClipRowView: View {
    let item: ClipItem
    let isSelected: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            contentPreview
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : .orange)
                }
                Text(item.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            isSelected
                ? RoundedRectangle(cornerRadius: 6).fill(Color.accentColor)
                : RoundedRectangle(cornerRadius: 6).fill(Color.clear)
        )
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            if item.contentType == .text {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }

            Button {
                onPin()
            } label: {
                Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var contentPreview: some View {
        switch item.contentType {
        case .text:
            Text(item.textContent ?? "")
                .font(.subheadline)
                .lineLimit(2)
                .foregroundStyle(isSelected ? .white : .primary)

        case .image:
            if let data = item.imageData,
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 60)
                    .cornerRadius(4)
            } else {
                Label("Image", systemImage: "photo")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .secondary)
            }

        case .fileURL:
            HStack(spacing: 6) {
                Image(systemName: "doc")
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : .blue)
                Text(item.preview)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
        }
    }
}
