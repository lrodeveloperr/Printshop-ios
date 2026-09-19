import Foundation

enum PrintShopCSVParser {
    static let maximumBytes = 50 * 1_024 * 1_024
    static let maximumRows = 250_000
    static let maximumColumns = 512
    static let maximumFieldBytes = 1_024 * 1_024

    private static let aliases: [String: Set<String>] = [
        "reference": ["order_reference", "order_ref", "order_number", "order_#", "job", "job_number", "job_#", "reference"],
        "customer": ["customer", "customer_name", "client", "client_name"],
        "item": ["item", "product", "product_name", "garment", "description"],
        "quantity": ["quantity", "qty", "ordered_quantity", "total_quantity"],
        "due_date": ["due_date", "due", "delivery_date", "in_hands_date"],
    ]

    static func preview(data: Data, fileName: String, locale: Locale) -> ImportPreview {
        guard data.count <= maximumBytes else {
            return failure(fileName, "error.csv.file_limit")
        }
        guard let text = decode(data) else { return failure(fileName, "error.csv.invalid_input") }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return failure(fileName, "error.csv.empty")
        }
        let delimiter = detectDelimiter(text)
        guard let delimiter else { return failure(fileName, "error.csv.unsupported_delimiter") }
        let parsed: [[String]]
        do { parsed = try rows(text, delimiter: delimiter) }
        catch { return failure(fileName, "error.csv.malformed_quotes") }
        guard parsed.count > 1 else { return failure(fileName, "error.csv.no_data_rows") }
        guard parsed.count - 1 <= maximumRows else { return failure(fileName, "error.csv.row_limit") }
        guard let header = parsed.first, header.count <= maximumColumns else {
            return failure(fileName, "error.csv.column_limit")
        }
        let normalizedHeader = header.map(normalizeHeader)
        guard Set(normalizedHeader).count == normalizedHeader.count else {
            return failure(fileName, "error.csv.duplicate_header")
        }
        var index: [String: Int] = [:]
        for (canonical, candidates) in aliases {
            if let match = normalizedHeader.firstIndex(where: candidates.contains) { index[canonical] = match }
        }
        let required = ["reference", "customer", "item", "quantity"]
        guard required.allSatisfy({ index[$0] != nil }) else {
            return failure(fileName, "error.csv.missing_header")
        }

        var drafts: [ImportedJobDraft] = []
        var issues: [LocalizedImportIssue] = []
        var seenReferences = Set<String>()
        for (offset, row) in parsed.dropFirst().enumerated() {
            let rowNumber = offset + 2
            if row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { continue }
            guard row.count == header.count else {
                issues.append(issue("error.csv.column_count", rowNumber, nil)); continue
            }
            if row.contains(where: { $0.utf8.count > maximumFieldBytes }) {
                issues.append(issue("error.csv.field_limit", rowNumber, nil)); continue
            }
            let reference = value("reference", row, index).trimmingCharacters(in: .whitespacesAndNewlines)
            let customer = value("customer", row, index).trimmingCharacters(in: .whitespacesAndNewlines)
            let item = value("item", row, index).trimmingCharacters(in: .whitespacesAndNewlines)
            let quantityText = value("quantity", row, index).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !reference.isEmpty, !customer.isEmpty, !item.isEmpty else {
                let column = reference.isEmpty ? "order_reference" : (customer.isEmpty ? "customer" : "item")
                issues.append(issue("error.csv.required_value", rowNumber, column)); continue
            }
            guard reference.range(of: #"^[A-Za-z0-9][A-Za-z0-9._/-]{0,127}$"#, options: .regularExpression) != nil else {
                issues.append(issue("error.csv.invalid_identifier", rowNumber, "order_reference")); continue
            }
            guard let quantity = Int(quantityText), quantity > 0 else {
                issues.append(issue("error.csv.invalid_quantity", rowNumber, "quantity")); continue
            }
            let foldedReference = reference.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
            guard seenReferences.insert(foldedReference).inserted else {
                issues.append(issue("error.csv.duplicate_record_id", rowNumber, "order_reference")); continue
            }
            let dueText = value("due_date", row, index).trimmingCharacters(in: .whitespacesAndNewlines)
            let dueDate: Date
            if dueText.isEmpty {
                dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            } else if let parsedDate = parseDate(dueText) {
                dueDate = parsedDate
            } else {
                issues.append(issue("error.csv.invalid_date", rowNumber, "due_date")); continue
            }
            drafts.append(
                ImportedJobDraft(id: UUID(), reference: reference, customer: customer,
                                 item: item, quantity: quantity, dueDate: dueDate)
            )
        }
        return ImportPreview(fileName: fileName, drafts: drafts, issues: issues)
    }

    static var sampleData: Data {
        Data("order_reference,customer,item,quantity,due_date\nPS-2001,Harbour Athletics,T-shirts - screen print,48,2026-10-15\n".utf8)
    }

    private static func failure(_ name: String, _ key: String) -> ImportPreview {
        ImportPreview(fileName: name, drafts: [], issues: [issue(key, nil, nil)])
    }

    private static func issue(_ key: String, _ row: Int?, _ column: String?) -> LocalizedImportIssue {
        LocalizedImportIssue(id: UUID(), key: key, row: row, column: column, isBlocking: true)
    }

    private static func value(_ field: String, _ row: [String], _ index: [String: Int]) -> String {
        guard let position = index[field], row.indices.contains(position) else { return "" }
        return row[position]
    }

    private static func decode(_ data: Data) -> String? {
        if data.starts(with: [0xEF, 0xBB, 0xBF]) { return String(data: data.dropFirst(3), encoding: .utf8) }
        if data.starts(with: [0xFF, 0xFE]) { return String(data: data.dropFirst(2), encoding: .utf16LittleEndian) }
        if data.starts(with: [0xFE, 0xFF]) { return String(data: data.dropFirst(2), encoding: .utf16BigEndian) }
        return String(data: data, encoding: .utf8)
    }

    private static func detectDelimiter(_ text: String) -> Character? {
        let firstRecord = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        let candidates: [Character] = [",", ";", "\t", "|"]
        return candidates.max { delimiterCount(firstRecord, $0) < delimiterCount(firstRecord, $1) }
            .flatMap { delimiterCount(firstRecord, $0) > 0 ? $0 : nil }
    }

    private static func delimiterCount(_ line: String, _ delimiter: Character) -> Int {
        var quoted = false
        var count = 0
        var iterator = line.makeIterator()
        while let character = iterator.next() {
            if character == "\"" { quoted.toggle() }
            else if character == delimiter && !quoted { count += 1 }
        }
        return count
    }

    private static func rows(_ text: String, delimiter: Character) throws -> [[String]] {
        enum CSVError: Error { case unterminatedQuote }
        var result: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var index = text.startIndex
        while index < text.endIndex {
            let character = text[index]
            if quoted {
                if character == "\"" {
                    let next = text.index(after: index)
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else { quoted = false }
                } else { field.append(character) }
            } else {
                switch character {
                case "\"": quoted = true
                case delimiter: row.append(field); field = ""
                case "\n": row.append(field); result.append(row); row = []; field = ""
                case "\r": break
                default: field.append(character)
                }
            }
            index = text.index(after: index)
        }
        if quoted { throw CSVError.unterminatedQuote }
        if !field.isEmpty || !row.isEmpty { row.append(field); result.append(row) }
        return result
    }

    private static func normalizeHeader(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
    }

    private static func parseDate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: value) { return date }
        for format in ["yyyy-MM-dd", "MM/dd/yyyy", "dd.MM.yyyy"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            formatter.isLenient = false
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}
