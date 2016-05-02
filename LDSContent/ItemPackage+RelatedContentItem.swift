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

extension ItemPackage {
    
    class RelatedContentItemTable {
        
        static let table = Table("related_content_item")
        static let id = Expression<Int64>("_id")
        static let subitemID = Expression<Int64>("subitem_id")
        static let refID = Expression<String>("ref_id")
        static let labelHTML = Expression<String>("label_html")
        static let originID = Expression<String>("origin_id")
        static let contentHTML = Expression<String>("content_html")
        static let wordOffset = Expression<Int>("word_offset")
        static let byteLocation = Expression<Int>("byte_location")
        
        static func fromRow(row: Row) -> RelatedContentItem {
            return RelatedContentItem(id: row[id], subitemID: row[subitemID], refID: row[refID], labelHTML: row[labelHTML], originID: row[originID], contentHTML: row[contentHTML], wordOffset: row[wordOffset], byteLocation: row[byteLocation])
        }
        
    }
    
    // TODO: Do we even still need this?
    public func relatedContentItemsForSubitemWithID(subitemID: Int64) -> [RelatedContentItem] {
        do {
            return try db.prepare(RelatedContentItemTable.table.filter(RelatedContentItemTable.subitemID == subitemID).order(RelatedContentItemTable.byteLocation)).map { RelatedContentItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func relatedContentItemsForSubitemWithURI(subitemURI: String) -> [RelatedContentItem] {
        do {
            return try db.prepare(RelatedContentItemTable.table.join(SubitemTable.table.filter(SubitemTable.uri == subitemURI), on: RelatedContentItemTable.subitemID == SubitemTable.id).order(RelatedContentItemTable.byteLocation)).map { RelatedContentItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
}