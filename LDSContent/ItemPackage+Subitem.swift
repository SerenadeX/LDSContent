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

public extension ItemPackage {
    
    class SubitemTable {
        
        static let table = Table("subitem")
        static let id = Expression<Int64>("_id")
        static let uri = Expression<String>("uri")
        static let docID = Expression<String>("doc_id")
        static let docVersion = Expression<Int>("doc_version")
        static let position = Expression<Int>("position")
        static let titleHTML = Expression<String>("title_html")
        static let title = Expression<String>("title")
        static let webURL = Expression<String>("web_url")
        static let contentType = Expression<ContentType>("content_type")
        
        static func fromRow(row: Row) -> Subitem {
            return Subitem(id: row[id], uri: row[uri], docID: row[docID], docVersion: row[docVersion], position: row[position], titleHTML: row[titleHTML], title: row[title], webURL: NSURL(string: row[webURL]), contentType: row.get(contentType))
        }
        
    }
    
    public func subitemWithURI(uri: String) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.uri == uri)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitemWithDocID(docID: String) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.docID == docID)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitemWithID(id: Int64) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.id == id)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitemAtPosition(position: Int) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.position == position)).map { SubitemTable.fromRow($0) }
    }
    
    public func subitems() -> [Subitem] {
        do {
            return try db.prepare(SubitemTable.table.order(SubitemTable.position)).map { SubitemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func subitemExistsWithURI(subitemURI: String) -> Bool {
        return db.scalar(SubitemTable.table.filter(SubitemTable.uri == subitemURI).count) > 0
    }
    
    public func subitemsWithURIs(uris: [String]) -> [Subitem] {
        do {
            return try db.prepare(SubitemTable.table.filter(uris.contains(SubitemTable.uri)).order(SubitemTable.position)).map { SubitemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func subitemAtIndex(index: Int) -> Subitem? {
        return db.pluck(SubitemTable.table.filter(SubitemTable.position == index)).map { SubitemTable.fromRow($0) }
    }
    
    public func firstSubitemURIPrefixedByURI(uri: String) -> String? {
        return db.pluck(SubitemTable.table.select(SubitemTable.uri).filter(SubitemTable.uri.like("\(uri.escaped())%", escape: "!")).order(SubitemTable.position)).map { $0[SubitemTable.uri] }
    }
    
    public func subitemsWithAuthor(author: Author) -> [Subitem] {
        do {
            return try db.prepare(SubitemTable.table.filter(SubitemTable.id == SubitemAuthorTable.subitemID && SubitemAuthorTable.authorID == author.id).order(SubitemTable.position)).map { SubitemTable.fromRow($0) }
        } catch {
            return []
        }
    }

    public func numberOfSubitems() -> Int {
        return db.scalar(SubitemTable.table.count)
    }
    
    public func subitemIDOfSubitemWithURI(subitemURI: String) -> Int64? {
        return db.pluck(SubitemTable.table.select(SubitemTable.id).filter(SubitemTable.uri == subitemURI)).map { $0[SubitemTable.id] }
    }
    
    public func docIDOfSubitemWithURI(subitemURI: String) -> String? {
        return db.pluck(SubitemTable.table.select(SubitemTable.docID).filter(SubitemTable.uri == subitemURI)).map { $0[SubitemTable.docID] }
    }
    
    public func docVersionOfSubitemWithURI(subitemURI: String) -> Int? {
        return db.pluck(SubitemTable.table.select(SubitemTable.docVersion).filter(SubitemTable.uri == subitemURI)).map { $0[SubitemTable.docVersion] }
    }
    
    public func URIOfSubitemWithID(subitemID: Int64) -> String? {
        return db.pluck(SubitemTable.table.select(SubitemTable.uri).filter(SubitemTable.id == subitemID)).map { $0[SubitemTable.uri] }
    }
    
    public func allDocIDsAndVersions() -> [(docID: String, docVersion: Int)] {
        do {
            return try db.prepare(SubitemTable.table.select(SubitemTable.docID, SubitemTable.docVersion)).map { (docID: $0[SubitemTable.docID], docVersion: $0[SubitemTable.docVersion]) }
        } catch {
            return []
        }
    }
    
    public func citationForSubitemWithDocID(docID: String, paragraphAIDs: [String]?) -> String? {
        guard let subitem = subitemWithDocID(docID) else { return nil }
        guard let verse = verseNumberTitleForSubitemWithDocID(docID, paragraphAIDs: paragraphAIDs) else { return subitem.title }
        
        var title = subitem.title
        if title.rangeOfString("[0-9]$", options: .RegularExpressionSearch) == nil {
            // If not, add 1. This is a one chapter book.
            title += " 1"
        }
        return String(format: NSLocalizedString("%1$@:%2$@", comment: "Formatter string for creating short titles with a verse ({chapter title}:{verse number}, e.g. 1 Nephi 10:7)"), title, verse)
    }
    
    public func verseNumberTitleForSubitemWithDocID(docID: String, paragraphAIDs: [String]?) -> String? {
        var verse: String?
        
        if let paragraphAIDs = paragraphAIDs where !paragraphAIDs.isEmpty {
            let verseNumbers = verseNumbersForSubitemWithDocID(docID, paragraphAIDs: paragraphAIDs)
            if verseNumbers.count > 1, let firstVerse = verseNumbers.first, lastVerse = verseNumbers.last {
                verse = String(format: "%@-%@", firstVerse, lastVerse)
            } else if verseNumbers.count == 1 {
                verse = verseNumbers.first
            }
        }
        
        return verse
    }
    
    func verseNumbersForSubitemWithDocID(docID: String, paragraphAIDs: [String]) -> [String] {
        do {
            return try db.prepare(ParagraphMetadataTable.table.select(ParagraphMetadataTable.verseNumber).join(SubitemTable.table.filter(SubitemTable.docID == docID), on: SubitemTable.id == ParagraphMetadataTable.subitemID)).flatMap { $0[ParagraphMetadataTable.verseNumber] }
        } catch {
            return []
        }
    }
    
    func firstSubitemURIThatContainsURI(uri: String) -> String? {
        if subitemExistsWithURI(uri) {
            return uri
        }

        // Iteratively look for the last subitem whose URI is a prefix of this URI
        var subitemURI = uri.componentsSeparatedByString("?").first ?? ""
        while subitemURI.characters.count > 0 && subitemURI != "/" {
            guard !subitemExistsWithURI(subitemURI) else {
                // Found a valid SubitemURI
                return subitemURI
            }
            
            if let range = subitemURI.rangeOfString("/", options: .BackwardsSearch) {
                subitemURI = subitemURI.substringToIndex(range.startIndex)
            } else {
                subitemURI = ""
            }
        }

        return firstSubitemURIPrefixedByURI(uri)
    }
    
}

