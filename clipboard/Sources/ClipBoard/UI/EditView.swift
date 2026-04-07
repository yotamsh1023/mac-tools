import SwiftUI

struct EditView: View {
    let item: ClipItem
    let onCopy: (String) -> Void       // copy without saving
    let onSaveAndCopy: (String) -> Void // save to store + copy
    let onDismiss: () -> Void

    @State private var text: String

    init(item: ClipItem,
         onCopy: @escaping (String) -> Void,
         onSaveAndCopy: @escaping (String) -> Void,
         onDismiss: @escaping () -> Void) {
        self.item = item
        self.onCopy = onCopy
        self.onSaveAndCopy = onSaveAndCopy
        self.onDismiss = onDismiss
        _text = State(initialValue: item.textContent ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Clip")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Text editor
            TextEditor(text: $text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(8)
                .scrollContentBackground(.hidden)

            Divider()

            // Actions
            HStack(spacing: 8) {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Copy") {
                    onCopy(text)
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Save & Copy") {
                    onSaveAndCopy(text)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
