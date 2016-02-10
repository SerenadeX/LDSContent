//
// Copyright (c) 2016 Hilton Campbell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import SQLite
import Swiftification

public class Catalog {
    
    private let db: Connection!
    private let noDiacritic: ((Expression<String>) -> Expression<String>)!
    
    public init?(path: String? = nil) {
        db = try? Connection(path ?? "")
        if db == nil {
            noDiacritic = nil
            return nil
        }
        
        do {
            try db.execute("PRAGMA synchronous = OFF")
            try db.execute("PRAGMA journal_mode = OFF")
            try db.execute("PRAGMA temp_store = MEMORY")
            
            noDiacritic = try db.createFunction("noDiacritic", deterministic: true) { (string: String) -> String in
                return string.withoutDiacritics()
            }
        } catch {
            noDiacritic = nil
            return nil
        }
    }
    
    public func inTransaction(closure: () throws -> Void) throws {
        let inTransactionKey = "txn:\(unsafeAddressOf(self))"
        if NSThread.currentThread().threadDictionary[inTransactionKey] != nil {
            try closure()
        } else {
            NSThread.currentThread().threadDictionary[inTransactionKey] = true
            defer { NSThread.currentThread().threadDictionary.removeObjectForKey(inTransactionKey) }
            try db.transaction {
                try closure()
            }
        }
    }
    
}

private class MetadataTable {
    
    static let table = Table("metadata")
    static let key = Expression<String>("key")
    static let integerValue = Expression<Int>("value")
    static let stringValue = Expression<String>("value")
    
}

extension Catalog {
    
    func intForMetadataKey(key: String) -> Int? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).flatMap { row in
            let string = row[MetadataTable.stringValue]
            return Int(string)
        }
    }
    
    func stringForMetadataKey(key: String) -> String? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).map { row in
            return row[MetadataTable.stringValue]
        }
    }
    
    public func schemaVersion() -> Int? {
        return self.intForMetadataKey("schemaVersion")
    }
    
    public func catalogVersion() -> Int? {
        return self.intForMetadataKey("catalogVersion")
    }
    
}

private class SourceTable {
    
    static let table = Table("source")
    static let id = Expression<Int>("_id")
    static let name = Expression<String>("name")
    static let typeID = Expression<Int>("type_id")
    
    static func fromRow(row: Row) -> Source {
        return Source(id: row[id], name: row[name], type: SourceType(rawValue: row[typeID]) ?? .Default)
    }
    
}

extension Catalog {
    
    public func sources() -> [Source] {
        do {
            return try db.prepare(SourceTable.table).map { row in
                return SourceTable.fromRow(row)
            }
        } catch {
            return []
        }
    }
    
    public func sourceWithID(id: Int) -> Source? {
        return db.pluck(SourceTable.table.filter(SourceTable.id == id)).map { SourceTable.fromRow($0) }
    }
    
    public func sourceWithName(name: String) -> Source? {
        return db.pluck(SourceTable.table.filter(SourceTable.name == name)).map { SourceTable.fromRow($0) }
    }
    
}

private class ItemCategoryTable {
    
    static let table = Table("item_category")
    static let id = Expression<Int>("_id")
    static let name = Expression<String>("name")
    
    static func fromRow(row: Row) -> ItemCategory {
        return ItemCategory(id: row[id], name: row[name])
    }
    
}

extension Catalog {
    
    public func itemCategoryWithID(id: Int) -> ItemCategory? {
        return db.pluck(ItemCategoryTable.table.filter(ItemCategoryTable.id == id)).map { ItemCategoryTable.fromRow($0) }
    }
    
}

private class ItemTable {
    
    static let table = Table("item")
    static let id = Expression<Int>("_id")
    static let externalID = Expression<String>("external_id")
    static let languageID = Expression<Int>("language_id")
    static let sourceID = Expression<Int>("source_id")
    static let platformID = Expression<Int>("platform_id")
    static let uri = Expression<String>("uri")
    static let title = Expression<String>("title")
    static let itemCoverRenditions = Expression<String?>("item_cover_renditions")
    static let itemCategoryID = Expression<Int>("item_category_id")
    static let latestVersion = Expression<Int>("latest_version")
    static let obsolete = Expression<Bool>("is_obsolete")
    
    static func fromRow(row: Row) -> Item {
        return Item(id: row[id], externalID: row[externalID], languageID: row[languageID], sourceID: row[sourceID], platformID: row[platformID], uri: row[uri], title: row[title], itemCoverRenditions: (row[itemCoverRenditions] ?? "").toImageRenditions() ?? [], itemCategoryID: row[itemCategoryID], latestVersion: row[latestVersion], obsolete: row[obsolete])
    }
    
    static func fromNamespacedRow(row: Row) -> Item {
        return Item(id: row[ItemTable.table[id]], externalID: row[ItemTable.table[externalID]], languageID: row[ItemTable.table[languageID]], sourceID: row[ItemTable.table[sourceID]], platformID: row[ItemTable.table[platformID]], uri: row[ItemTable.table[uri]], title: row[ItemTable.table[title]], itemCoverRenditions: (row[ItemTable.table[itemCoverRenditions]] ?? "").toImageRenditions() ?? [], itemCategoryID: row[ItemTable.table[itemCategoryID]], latestVersion: row[ItemTable.table[latestVersion]], obsolete: row[ItemTable.table[obsolete]])
    }
    
}

extension Catalog {
    
    public func items() -> [Item] {
        do {
            return try db.prepare(ItemTable.table).map { ItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func itemsForLibraryCollectionWithID(id: Int) -> [Item] {
        do {
            return try db.prepare(ItemTable.table.join(LibraryItemTable.table, on: ItemTable.table[ItemTable.id] == LibraryItemTable.itemID).join(LibrarySectionTable.table, on: LibraryItemTable.librarySectionID == LibrarySectionTable.table[LibrarySectionTable.id]).filter(LibrarySectionTable.libraryCollectionID == id && [1, 2].contains(ItemTable.platformID)).order(LibraryItemTable.position)).map { ItemTable.fromNamespacedRow($0) }
        } catch {
            return []
        }
    }
    
    public func itemsWithURIsIn(uris: [String], languageID: Int) -> [Item] {
        do {
            return try db.prepare(ItemTable.table.filter(uris.contains(ItemTable.uri) && ItemTable.languageID == languageID && [1, 2].contains(ItemTable.platformID))).map { ItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func itemsWithSourceID(sourceID: Int) -> [Item] {
        do {
            return try db.prepare(ItemTable.table.filter(ItemTable.sourceID == sourceID && [1, 2].contains(ItemTable.platformID))).map { ItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func itemsWithIDsIn(ids: [Int]) -> [Item] {
        do {
            return try db.prepare(ItemTable.table.filter(ids.contains(ItemTable.id) && [1, 2].contains(ItemTable.platformID))).map { ItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func itemsWithExternalIDsIn(externalIDs: [String]) -> [Item] {
        do {
            return try db.prepare(ItemTable.table.filter(externalIDs.contains(ItemTable.externalID) && [1, 2].contains(ItemTable.platformID))).map { ItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func itemWithID(id: Int) -> Item? {
        return db.pluck(ItemTable.table.filter(ItemTable.id == id && [1, 2].contains(ItemTable.platformID))).map { ItemTable.fromRow($0) }
    }
    
    public func itemWithExternalID(externalID: String) -> Item? {
        return db.pluck(ItemTable.table.filter(ItemTable.externalID == externalID && [1, 2].contains(ItemTable.platformID))).map { ItemTable.fromRow($0) }
    }
    
    public func itemWithURI(uri: String, languageID: Int) -> Item? {
        return db.pluck(ItemTable.table.filter(ItemTable.uri == uri && ItemTable.languageID == languageID && [1, 2].contains(ItemTable.platformID))).map { ItemTable.fromRow($0) }
    }
    
    public func itemsWithTitlesThatContainString(string: String, languageID: Int, limit: Int) -> [Item] {
        do {
            return try db.prepare(ItemTable.table.filter(noDiacritic(ItemTable.title).like("%\(string.withoutDiacritics().escaped())%", escape: "!") && ItemTable.languageID == languageID && ItemTable.obsolete == false && [1, 2].contains(ItemTable.platformID)).limit(limit)).map { ItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func itemThatContainsURI(uri: String, languageID: Int) -> Item? {
        var prefix = uri
        while !prefix.isEmpty && prefix != "/" {
            if let item = db.pluck(ItemTable.table.filter(ItemTable.uri == prefix && ItemTable.languageID == languageID && [1, 2].contains(ItemTable.platformID))).map({ ItemTable.fromRow($0) }) {
                return item
            }
            prefix = (prefix as NSString).stringByDeletingLastPathComponent
        }
        return nil
    }

}

private class LanguageTable {
    
    static let table = Table("language")
    static let id = Expression<Int>("_id")
    static let ldsLanguageCode = Expression<String>("lds_language_code")
    static let iso639_3Code = Expression<String>("iso639_3")
    static let bcp47Code = Expression<String?>("bcp47")
    static let rootLibraryCollectionID = Expression<Int>("root_library_collection_id")
    static let rootLibraryCollectionExternalID = Expression<String>("root_library_collection_external_id")
    
    static func fromRow(row: Row) -> Language {
        return Language(id: row[id], ldsLanguageCode: row[ldsLanguageCode], iso639_3Code: row[iso639_3Code], bcp47Code: row[bcp47Code], rootLibraryCollectionID: row[rootLibraryCollectionID], rootLibraryCollectionExternalID: row[rootLibraryCollectionExternalID])
    }
    
}

extension Catalog {
    
    func languages() -> [Language] {
        do {
            return try db.prepare(LanguageTable.table).map { LanguageTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    func languageWithID(id: Int) -> Language? {
        return db.pluck(LanguageTable.table.filter(LanguageTable.id == id)).map { LanguageTable.fromRow($0) }
    }
    
    func languageWithISO639_3Code(iso639_3Code: String) -> Language? {
        return db.pluck(LanguageTable.table.filter(LanguageTable.iso639_3Code == iso639_3Code)).map { LanguageTable.fromRow($0) }
    }
    
    func languageWithBCP47Code(bcp47Code: String) -> Language? {
        return db.pluck(LanguageTable.table.filter(LanguageTable.bcp47Code == bcp47Code)).map { LanguageTable.fromRow($0) }
    }
    
    func languageWithLDSLanguageCode(ldsLanguageCode: String) -> Language? {
        return db.pluck(LanguageTable.table.filter(LanguageTable.ldsLanguageCode == ldsLanguageCode)).map { LanguageTable.fromRow($0) }
    }
    
    func languageWithRootLibraryCollectionID(rootLibraryCollectionID: Int) -> Language? {
        return db.pluck(LanguageTable.table.filter(LanguageTable.rootLibraryCollectionID == rootLibraryCollectionID)).map { LanguageTable.fromRow($0) }
    }
    
    func languageWithRootLibraryCollectionExternalID(rootLibraryCollectionExternalID: String) -> Language? {
        return db.pluck(LanguageTable.table.filter(LanguageTable.rootLibraryCollectionExternalID == rootLibraryCollectionExternalID)).map { LanguageTable.fromRow($0) }
    }
    
}

private class LanguageNameTable {
    
    static let table = Table("language_name")
    static let id = Expression<Int>("_id")
    static let languageID = Expression<Int>("language_id")
    static let localizationLanguageID = Expression<Int>("localization_language_id")
    static let name = Expression<String>("name")
    
}

extension Catalog {

    func nameForLanguageWithID(languageID: Int, inLanguageWithID localizationLanguageID: Int) -> String {
        return db.scalar(LanguageNameTable.table.select(LanguageNameTable.name).filter(LanguageNameTable.languageID == languageID && LanguageNameTable.localizationLanguageID == localizationLanguageID))
    }
    
}

private class LibraryItemTable {
    
    static let table = Table("library_item")
    static let id = Expression<Int>("_id")
    static let externalID = Expression<String>("external_id")
    static let librarySectionID = Expression<Int>("library_section_id")
    static let librarySectionExternalID = Expression<String>("library_section_external_id")
    static let position = Expression<Int>("position")
    static let title = Expression<String>("title")
    static let obsolete = Expression<Bool>("is_obsolete")
    static let itemID = Expression<Int>("item_id")
    static let itemExternalID = Expression<String>("item_external_id")
    
    static func fromRow(row: Row) -> LibraryItem {
        return LibraryItem(id: row[id], externalID: row[externalID], librarySectionID: row[librarySectionID], librarySectionExternalID: row[librarySectionExternalID], position: row[position], title: row[title], obsolete: row[obsolete], itemID: row[itemID], itemExternalID: row[itemExternalID])
    }
    
}

private class LibrarySectionTable {
    
    static let table = Table("library_section")
    static let id = Expression<Int>("_id")
    static let externalID = Expression<String>("external_id")
    static let libraryCollectionID = Expression<Int>("library_collection_id")
    static let libraryCollectionExternalID = Expression<String>("library_collection_external_id")
    static let position = Expression<Int>("position")
    static let title = Expression<String>("title")
    static let indexTitle = Expression<String>("index_title")
    
    static func fromRow(row: Row) -> LibrarySection {
        return LibrarySection(id: row[id], externalID: row[externalID], libraryCollectionID: row[libraryCollectionID], libraryCollectionExternalID: row[libraryCollectionExternalID], position: row[position], title: row[title], indexTitle: row[indexTitle])
    }
    
}

private class LibraryCollectionTable {
    
    static let table = Table("library_collection")
    static let id = Expression<Int>("_id")
    static let externalID = Expression<String>("external_id")
    static let librarySectionID = Expression<Int?>("library_section_id")
    static let librarySectionExternalID = Expression<String?>("library_section_external_id")
    static let position = Expression<Int>("position")
    static let title = Expression<String>("title")
    static let coverRenditions = Expression<String?>("cover_renditions")
    static let typeID = Expression<Int>("type_id")
    
    static func fromRow(row: Row) -> LibraryCollection {
        return LibraryCollection(id: row[id], externalID: row[externalID], librarySectionID: row[librarySectionID], librarySectionExternalID: row[librarySectionExternalID], position: row[position], title: row[title], coverRenditions: (row[coverRenditions] ?? "").toImageRenditions() ?? [], type: LibraryCollectionType(rawValue: row[typeID]) ?? .Default)
    }
    
}

extension Catalog {
    
    public func libraryCollections() -> [LibraryCollection] {
        do {
            return try db.prepare(LibraryCollectionTable.table).map { LibraryCollectionTable.fromRow($0) }
        } catch {
            return []
        }
    }

}
