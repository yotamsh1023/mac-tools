import AppKit

final class ClipboardMonitor {
    var onNewClip: ((ClipItem) -> Void)?

    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?

    func start() {
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // Call this after writing to the pasteboard yourself to avoid re-capturing it
    func syncChangeCount() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        if let string = pb.string(forType: .string), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let item = ClipItem(contentType: .text, textContent: string)
            onNewClip?(item)
            return
        }

        // Try PNG first, then TIFF (convert to PNG for storage efficiency)
        if let data = pb.data(forType: .png) {
            let item = ClipItem(contentType: .image, imageData: data)
            onNewClip?(item)
            return
        }
        if let tiffData = pb.data(forType: .tiff),
           let img = NSImage(data: tiffData),
           let pngData = img.pngData() {
            let item = ClipItem(contentType: .image, imageData: pngData)
            onNewClip?(item)
            return
        }

        if let urls = pb.readObjects(forClasses: [NSURL.self],
                                      options: [.urlReadingFileURLsOnly: true]) as? [URL],
           let first = urls.first {
            let item = ClipItem(contentType: .fileURL, fileURL: first.path)
            onNewClip?(item)
        }
    }
}

private extension NSImage {
    func pngData() -> Data? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        return rep.representation(using: .png, properties: [:])
    }
}
