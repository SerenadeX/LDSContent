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
import FTS3HTMLTokenizer

public class ItemPackage {
    
    let db: Connection
    public let path: NSURL
    
    public init(path: NSURL) throws {
        do {
            db = try Connection(path.path ?? "")
            self.path = path
        } catch {
            throw error
        }
        
        try db.execute("PRAGMA synchronous = OFF")
        try db.execute("PRAGMA journal_mode = OFF")
        try db.execute("PRAGMA temp_store = MEMORY")
        
        registerTokenizer(db.handle, UnsafeMutablePointer<Int8>(("HTMLTokenizer" as NSString).UTF8String))
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
    
    public var schemaVersion: Int {
        return Int(self.intForMetadataKey("schemaVersion") ?? 0)
    }
    
    public var itemPackageVersion: Int {
        return Int(self.intForMetadataKey("itemPackageVersion") ?? 0)
    }
    
    public var iso639_3Code: String? {
        return self.stringForMetadataKey("iso639_3")
    }
    
    public var uri: String? {
        return self.stringForMetadataKey("uri")
    }
    
    public var itemID: Int64? {
        return self.intForMetadataKey("item_id")
    }
    
    public var itemExternalID: String? {
        return self.stringForMetadataKey("item_external_id")
    }
    
    public func itemHeadHTML() -> String {
        guard let packageDirectory = path.path else { return "" }

        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(path, includingPropertiesForKeys: nil, options: .SkipsPackageDescendants).flatMap { fileURL -> String? in
                guard fileURL.pathExtension == "css", let filePath = fileURL.path else { return nil }
                return "<link rel=\"stylesheet\" href=\"\(filePath)\"/>"
            }.joinWithSeparator("\n")
        } catch {
            return ""
        }
    }
    
    public func scriptureGotoURL() -> NSURL {
        return path.URLByAppendingPathComponent("scriptureGoto.plist")
    }
    
}

extension ItemPackage {
    
    class MetadataTable {
        
        static let table = Table("metadata")
        static let key = Expression<String>("key")
        static let integerValue = Expression<Int64>("value")
        static let stringValue = Expression<String>("value")
        
    }
    
    func intForMetadataKey(key: String) -> Int64? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).flatMap { row in
            let string = row[MetadataTable.stringValue]
            return Int64(string)
        }
    }
    
    func stringForMetadataKey(key: String) -> String? {
        return db.pluck(MetadataTable.table.filter(MetadataTable.key == key).select(MetadataTable.stringValue)).map { row in
            return row[MetadataTable.stringValue]
        }
    }
    
}

extension ItemPackage {
    
    class SubitemContentView {
        
        static let table = View("subitem_content")
        static let id = Expression<Int64>("_id")
        static let subitemID = Expression<Int64>("subitem_id")
        static let contentHTML = Expression<NSData>("content_html")
        
        static func fromRow(row: Row) -> SubitemContent {
            return SubitemContent(id: row[id], subitemID: row[subitemID], contentHTML: row[contentHTML])
        }
        
    }
    
    public func subitemContentWithSubitemID(subitemID: Int64) -> SubitemContent? {
        return db.pluck(SubitemContentView.table.filter(SubitemContentView.subitemID == subitemID)).map { SubitemContentView.fromRow($0) }
    }
    
}

extension ItemPackage {
    
    class SubitemContentVirtualTable {
        
        static let table = VirtualTable("subitem_content_fts")
        static let id = Expression<Int64>("_id")
        static let subitemID = Expression<Int64>("subitem_id")
        static let contentHTML = Expression<NSData>("content_html")
        
        static func fromRow(row: [Binding?], iso639_3Code: String, keywordSearch: Bool) -> SearchResult {
            return SearchResult(subitemID: Int64(row[2] as! Int64), uri: row[4] as! String, title: row[3] as! String, matchRanges: matchRangesFromOffsets(row[0] as! String, keywordSearch: keywordSearch), iso639_3Code: iso639_3Code, snippet: row[1] as! String)
        }
        
        static func matchRangesFromOffsets(offsets: String, keywordSearch: Bool) -> [NSRange] {
            var matchRanges = [NSRange]()
            
            let scanner = NSScanner(string: offsets)
            while !scanner.atEnd {
                var columnNumber = 0
                if !scanner.scanInteger(&columnNumber) {
                    return []
                }
                
                var termNumber = 0
                if !scanner.scanInteger(&termNumber) {
                    return []
                }
                
                var byteOffset = 0
                if !scanner.scanInteger(&byteOffset) {
                    return []
                }
                
                var byteSize = 0
                if !scanner.scanInteger(&byteSize) {
                    return []
                }
                
                let range = NSMakeRange(byteOffset, byteSize)
                if !keywordSearch && termNumber != 0, let lastRange = matchRanges.popLast() {
                    // Combine into single range for exact phrase matches
                    let combinedRange = NSMakeRange(lastRange.location, (range.location - lastRange.location) + range.length)
                    matchRanges.append(combinedRange)
                } else {
                    // Don't try to combine search tokens on keyword search
                    matchRanges.append(range)
                }
            }
            return matchRanges
        }
        
    }

    public func searchResultsForString(searchString: String) -> [SearchResult] {
        let iso639_3Code = self.iso639_3Code!
        let keywordSearch = (searchString.rangeOfString("^\\\".*\\\"$", options: .RegularExpressionSearch) != nil)
        
        do {
            return try db.prepare("SELECT offsets(subitem_content_fts) AS offsets, snippet(subitem_content_fts, '<em class=\"searchMatch\">', '</em>', '…', -1, 35) AS snippet, subitem_content_fts.subitem_id, subitem.title, subitem.uri FROM subitem_content_fts LEFT JOIN subitem ON subitem._id = subitem_content_fts.subitem_id WHERE subitem_content_fts.content_html MATCH ? ORDER BY subitem_content_fts.subitem_id", searchString).map { row in
                return SubitemContentVirtualTable.fromRow(row, iso639_3Code: iso639_3Code, keywordSearch: keywordSearch)
            }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    class NavSectionTable {
        
        static let table = Table("nav_section")
        static let id = Expression<Int64>("_id")
        static let navCollectionID = Expression<Int64>("nav_collection_id")
        static let position = Expression<Int>("position")
        static let indentLevel = Expression<Int>("indent_level")
        static let title = Expression<String?>("title")
        
        static func fromRow(row: Row) -> NavSection {
            return NavSection(id: row[id], navCollectionID: row[navCollectionID], position: row[position], indentLevel: row[indentLevel], title: row[title])
        }
        
    }
    
    public func navSectionWithID(id: Int64) -> NavSection? {
        return db.pluck(NavSectionTable.table.filter(NavSectionTable.id == id)).map { NavSectionTable.fromRow($0) }
    }
    
    public func navSectionsForNavCollectionWithID(navCollectionID: Int64) -> [NavSection] {
        do {
            return try db.prepare(NavSectionTable.table.filter(NavSectionTable.navCollectionID == navCollectionID).order(NavSectionTable.position)).map { NavSectionTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func numberOfNavSectionsForNavCollectionWithID(navCollectionID: Int64) -> Int {
        return db.scalar(NavSectionTable.table.filter(NavSectionTable.navCollectionID == navCollectionID).order(NavSectionTable.position).count)
    }
    
}

extension ItemPackage {
    
    class NavItemTable {
        
        static let table = Table("nav_item")
        static let id = Expression<Int64>("_id")
        static let navSectionID = Expression<Int64>("nav_section_id")
        static let position = Expression<Int>("position")
        static let imageRenditions = Expression<String?>("image_renditions")
        static let titleHTML = Expression<String>("title_html")
        static let subtitle = Expression<String?>("subtitle")
        static let preview = Expression<String?>("preview")
        static let uri = Expression<String>("uri")
        static let subitemID = Expression<Int64>("subitem_id")
        
        static func fromRow(row: Row) -> NavItem {
            return NavItem(id: row[id], navSectionID: row[navSectionID], position: row[position], imageRenditions: (row[imageRenditions] ?? "").toImageRenditions() ?? [], titleHTML: row[titleHTML], subtitle: row[subtitle], preview: row[preview], uri: row[uri], subitemID: row[subitemID])
        }
        
    }
    
    public func navItemWithURI(uri: String) -> NavItem? {
        return db.pluck(NavItemTable.table.filter(NavItemTable.uri == uri)).map { NavItemTable.fromRow($0) }
    }
    
    public func navItemsForNavSectionWithID(navSectionID: Int64) -> [NavItem] {
        do {
            return try db.prepare(NavItemTable.table.filter(NavItemTable.navSectionID == navSectionID).order(NavItemTable.position)).map { NavItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}

extension ItemPackage {
    
    public func navNodesForNavSectionWithID(navSectionID: Int64) -> [NavNode] {
        var navNodes = [NavNode]()
        navNodes += navCollectionsForNavSectionWithID(navSectionID).map { $0 as NavNode }
        navNodes += navItemsForNavSectionWithID(navSectionID).map { $0 as NavNode }
        return navNodes.sort { $0.position < $1.position }
    }
    
}

extension ItemPackage {
    
    class AuthorTable {
        static let table = Table("author")
        static let id = Expression<Int64>("_id")
        static let givenName = Expression<String>("given_name")
        static let familyName = Expression<String>("family_name")
        
        static func fromRow(row: Row) -> Author {
            return Author(id: row[id], givenName: row[givenName], familyName: row[familyName])
        }
    }
    
    public func authorsOfSubitemWithID(subitemID: Int64) -> [Author] {
        do {
            return try db.prepare(AuthorTable.table.filter(SubitemAuthorTable.subitemID == subitemID && AuthorTable.id == SubitemAuthorTable.authorID).order(AuthorTable.familyName).order(AuthorTable.givenName)).map { AuthorTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func authorWithGivenName(givenName: String, familyName: String) -> Author? {
        return db.pluck(AuthorTable.table.filter(AuthorTable.givenName == givenName && AuthorTable.familyName == familyName)).map { AuthorTable.fromRow($0) }
    }
    
}

extension ItemPackage {
    
    class RoleTable {
        static let table = Table("role")
        static let id = Expression<Int64>("_id")
        static let name = Expression<String>("name")
        static let position = Expression<Int>("position")
        
        static func fromRow(row: Row) -> Role {
            return Role(id: row[id], name: row[name], position: row[position])
        }
    }
    
    public func roleWithName(name: String) -> Role? {
        return db.pluck(RoleTable.table.filter(RoleTable.name == name)).map { RoleTable.fromRow($0) }
    }
    
}

extension ItemPackage {
    
    class AuthorRoleTable {
        static let table = Table("author_role")
        static let id = Expression<Int64>("_id")
        static let authorID = Expression<Int64>("author_id")
        static let roleID = Expression<Int64>("role_id")
        static let position = Expression<Int>("position")
        
        static func fromRow(row: Row) -> AuthorRole {
            return AuthorRole(id: row[id], authorID: row[authorID], roleID: row[roleID], position: row[position])
        }
    }
    
}

extension ItemPackage {
    
    class SubitemAuthorTable {
        static let table = Table("subitem_author")
        static let id = Expression<Int64>("_id")
        static let subitemID = Expression<Int64>("subitem_id")
        static let authorID = Expression<Int64>("author_id")
    }
    
}

extension ItemPackage {
    
    class TopicTable {
        static let table = Table("topic")
        static let id = Expression<Int64>("_id")
        static let name = Expression<String>("name")
        
        static func fromRow(row: Row) -> Topic {
            return Topic(id: row[id], name: row[name])
        }
    }
    
    public func topicWithName(name: String) -> Topic? {
        return db.pluck(TopicTable.table.filter(TopicTable.name == name)).map { TopicTable.fromRow($0) }
    }
    
}

extension ItemPackage {
    
    class SubitemTopicTable {
        static let table = Table("subitem_topic")
        static let id = Expression<Int64>("_id")
        static let subitemID = Expression<Int64>("subitem_id")
        static let topicID = Expression<Int64>("topic_id")
    }
    
}
