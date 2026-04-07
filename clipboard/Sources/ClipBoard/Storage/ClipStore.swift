import Foundation
import SQLite3
import Combine

// SQLITE_TRANSIENT is a C macro not bridged to Swift; define it manually
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class ClipStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []

    private var db: OpaquePointer?
    private let maxItems = 500

    init() {
        openDatabase()
        createSchema()
        items = loadAll()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Public API

    func save(_ item: ClipItem) {
        // Deduplicate: skip if same content as the most recent non-pinned item
        if let latest = items.first(where: { !$0.isPinned }),
           latest.contentHash == item.contentHash {
            return
        }

        insertItem(item)
        trimIfNeeded()
        DispatchQueue.main.async { self.items = self.loadAll() }
    }

    func search(query: String) -> [ClipItem] {
        guard !query.isEmpty else { return loadAll() }
        return searchFTS(query: query)
    }

    func togglePin(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let newPinned = !items[idx].isPinned
        let sql = "UPDATE clips SET is_pinned = ? WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, newPinned ? 1 : 0)
            sqlite3_bind_text(stmt, 2, id.uuidString, -1, SQLITE_TRANSIENT)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        DispatchQueue.main.async { self.items = self.loadAll() }
    }

    func delete(_ id: UUID) {
        let sql = "DELETE FROM clips WHERE id = ?"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        DispatchQueue.main.async { self.items = self.loadAll() }
    }

    func updateText(id: UUID, newText: String) {
        let sql = "UPDATE clips SET text_content = ?, search_text = ? WHERE id = ? AND content_type = 'text'"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, newText, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, newText, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, id.uuidString, -1, SQLITE_TRANSIENT)
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        DispatchQueue.main.async { self.items = self.loadAll() }
    }

    func clearHistory() {
        let sql = "DELETE FROM clips WHERE is_pinned = 0"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
        DispatchQueue.main.async { self.items = self.loadAll() }
    }

    // MARK: - Private

    private func openDatabase() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/clipboard")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("clips.db").path
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("ClipStore: failed to open database at \(path)")
        }
        // Restrict file to owner-only (rw-------)
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: path
        )
    }

    private func createSchema() {
        let createTable = """
        CREATE TABLE IF NOT EXISTS clips (
            id           TEXT PRIMARY KEY,
            timestamp    REAL NOT NULL,
            content_type TEXT NOT NULL,
            text_content TEXT,
            image_data   BLOB,
            file_url     TEXT,
            is_pinned    INTEGER NOT NULL DEFAULT 0,
            search_text  TEXT NOT NULL DEFAULT ''
        );
        """
        let createFTS = """
        CREATE VIRTUAL TABLE IF NOT EXISTS clips_fts
        USING fts5(search_text, content='clips', content_rowid='rowid');
        """
        execute(createTable)
        execute(createFTS)
    }

    private func insertItem(_ item: ClipItem) {
        let sql = """
        INSERT OR REPLACE INTO clips
            (id, timestamp, content_type, text_content, image_data, file_url, is_pinned, search_text)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, item.id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 2, item.timestamp.timeIntervalSince1970)
        sqlite3_bind_text(stmt, 3, item.contentType.rawValue, -1, SQLITE_TRANSIENT)
        bindTextOrNull(stmt, index: 4, value: item.textContent)
        if let data = item.imageData {
            _ = data.withUnsafeBytes { ptr in
                sqlite3_bind_blob(stmt, 5, ptr.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
            }
        } else {
            sqlite3_bind_null(stmt, 5)
        }
        bindTextOrNull(stmt, index: 6, value: item.fileURL)
        sqlite3_bind_int(stmt, 7, item.isPinned ? 1 : 0)
        sqlite3_bind_text(stmt, 8, item.searchableText, -1, SQLITE_TRANSIENT)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)

        // Update FTS index
        let ftsInsert = "INSERT INTO clips_fts(rowid, search_text) SELECT rowid, search_text FROM clips WHERE id = ?"
        var ftsStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, ftsInsert, -1, &ftsStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(ftsStmt, 1, item.id.uuidString, -1, SQLITE_TRANSIENT)
            sqlite3_step(ftsStmt)
        }
        sqlite3_finalize(ftsStmt)
    }

    private func loadAll() -> [ClipItem] {
        let sql = "SELECT id, timestamp, content_type, text_content, image_data, file_url, is_pinned FROM clips ORDER BY is_pinned DESC, timestamp DESC"
        var stmt: OpaquePointer?
        var result: [ClipItem] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return result }
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let item = rowToClipItem(stmt) { result.append(item) }
        }
        sqlite3_finalize(stmt)
        return result
    }

    private func searchFTS(query: String) -> [ClipItem] {
        let safe = query.replacingOccurrences(of: "\"", with: "")
        let sql = """
        SELECT c.id, c.timestamp, c.content_type, c.text_content, c.image_data, c.file_url, c.is_pinned
        FROM clips c
        JOIN clips_fts f ON c.rowid = f.rowid
        WHERE clips_fts MATCH ?
        ORDER BY c.is_pinned DESC, c.timestamp DESC
        """
        var stmt: OpaquePointer?
        var result: [ClipItem] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return result }
        sqlite3_bind_text(stmt, 1, "\"\(safe)\"*", -1, SQLITE_TRANSIENT)
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let item = rowToClipItem(stmt) { result.append(item) }
        }
        sqlite3_finalize(stmt)
        return result
    }

    private func rowToClipItem(_ stmt: OpaquePointer?) -> ClipItem? {
        guard let idStr = sqlite3_column_text(stmt, 0).map({ String(cString: $0) }),
              let id = UUID(uuidString: idStr),
              let typeStr = sqlite3_column_text(stmt, 2).map({ String(cString: $0) }),
              let contentType = ClipItem.ContentType(rawValue: typeStr) else { return nil }

        let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 1))
        let textContent = sqlite3_column_text(stmt, 3).map { String(cString: $0) }
        let imageData: Data? = {
            let bytes = sqlite3_column_blob(stmt, 4)
            let count = sqlite3_column_bytes(stmt, 4)
            guard let bytes, count > 0 else { return nil }
            return Data(bytes: bytes, count: Int(count))
        }()
        let fileURL = sqlite3_column_text(stmt, 5).map { String(cString: $0) }
        let isPinned = sqlite3_column_int(stmt, 6) != 0

        return ClipItem(
            id: id,
            timestamp: timestamp,
            isPinned: isPinned,
            contentType: contentType,
            textContent: textContent,
            imageData: imageData,
            fileURL: fileURL
        )
    }

    private func trimIfNeeded() {
        let sql = """
        DELETE FROM clips WHERE id IN (
            SELECT id FROM clips WHERE is_pinned = 0
            ORDER BY timestamp DESC LIMIT -1 OFFSET ?
        )
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(maxItems))
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }

    private func execute(_ sql: String) {
        var err: UnsafeMutablePointer<CChar>?
        sqlite3_exec(db, sql, nil, nil, &err)
    }

    private func bindTextOrNull(_ stmt: OpaquePointer?, index: Int32, value: String?) {
        if let value {
            sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, index)
        }
    }
}
