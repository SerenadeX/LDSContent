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
    
    class NavCollectionIndexEntryTable {
        
        static let table = Table("nav_collection_index_entry")
        static let id = Expression<Int64>("_id")
        static let navCollectionID = Expression<Int64>("nav_collection_id")
        static let position = Expression<Int>("position")
        static let title = Expression<String>("title")
        static let refNavCollectionID = Expression<Int64?>("ref_nav_collection_id")
        static let refNavItemID = Expression<Int64?>("ref_nav_item_id")
        
        static func fromRow(row: Row) -> NavCollectionIndexEntry {
            return NavCollectionIndexEntry(id: row[id], navCollectionID: row[navCollectionID], position: row[position], title: row[title], refNavCollectionID: row[refNavCollectionID], refNavItemID: row[refNavItemID])
        }
        
    }
    
    public func navCollectionIndexEntryWithID(id: Int64) -> NavCollectionIndexEntry? {
        return db.pluck(NavCollectionIndexEntryTable.table.filter(NavCollectionIndexEntryTable.id == id)).map { NavCollectionIndexEntryTable.fromRow($0) }
    }
    
    public func navCollectionIndexEntriesForNavCollectionWithID(navCollectionID: Int64) -> [NavCollectionIndexEntry] {
        do {
            return try db.prepare(NavCollectionIndexEntryTable.table.filter(NavCollectionIndexEntryTable.navCollectionID == navCollectionID).order(NavCollectionIndexEntryTable.position)).map { NavCollectionIndexEntryTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    
}