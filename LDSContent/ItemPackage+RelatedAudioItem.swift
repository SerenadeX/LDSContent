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
    
    class RelatedAudioItemTable {
        
        static let table = Table("related_audio_item")
        static let id = Expression<Int64>("_id")
        static let subitemID = Expression<Int64>("subitem_id")
        static let mediaURL = Expression<String>("media_url")
        static let fileSize = Expression<Int>("file_size")
        static let duration = Expression<Int>("duration")
        
        static func fromRow(row: Row) -> RelatedAudioItem {
            return RelatedAudioItem(id: row[id], subitemID: row[subitemID], mediaURL: NSURL(string: row[mediaURL])!, fileSize: row[fileSize], duration: row[duration])
        }
        
        static func fromNamespacedRow(row: Row) -> RelatedAudioItem {
            return RelatedAudioItem(id: row[RelatedAudioItemTable.table[id]], subitemID: row[RelatedAudioItemTable.table[subitemID]], mediaURL: NSURL(string: row[RelatedAudioItemTable.table[mediaURL]])!, fileSize: row[RelatedAudioItemTable.table[fileSize]], duration: row[RelatedAudioItemTable.table[duration]])
        }
        
    }
    
    public func firstRelatedAudioItemForSubitemWithURI(subitemURI: String) -> RelatedAudioItem? {
        return db.pluck(RelatedAudioItemTable.table.join(SubitemTable.table.filter(SubitemTable.uri == subitemURI), on: SubitemTable.id == RelatedAudioItemTable.subitemID).order(RelatedAudioItemTable.subitemID)).map { RelatedAudioItemTable.fromRow($0) }
    }
    
    public func relatedAudioItemsForSubitemWithID(subitemID: Int64) -> [RelatedAudioItem] {
        do {
            return try db.prepare(RelatedAudioItemTable.table.filter(RelatedAudioItemTable.subitemID == subitemID)).map { RelatedAudioItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func relatedAudioItemsForSubitemsWithIDs(subitemIDs: [Int64]) -> [RelatedAudioItem] {
        do {
            return try db.prepare(RelatedAudioItemTable.table.filter(subitemIDs.contains(RelatedAudioItemTable.subitemID))).map { RelatedAudioItemTable.fromRow($0) }
        } catch {
            return []
        }
    }
    
    public func hasRelatedAudioItemsForSubitemsWithIDs(subitemIDs: [Int64]) -> Bool {
        return db.scalar(RelatedAudioItemTable.table.filter(subitemIDs.contains(RelatedAudioItemTable.subitemID)).count) > 0
    }
    
    private func subitemIDsForDescendantsOfNavNode(navNode: NavNode) -> [Int64] {
        var subitemIDs = Set<Int64>()
        
        switch navNode {
        case let navItem as NavItem:
            subitemIDs.insert(navItem.subitemID)
        case let navCollection as NavCollection:
            for section in navSectionsForNavCollectionWithID(navCollection.id) ?? [] {
                for navNode in navNodesForNavSectionWithID(section.id) ?? [] {
                    subitemIDs.unionInPlace(subitemIDsForDescendantsOfNavNode(navNode))
                }
            }
        default:
            break
        }
        
        return Array(subitemIDs)
    }
    
    func relatedAudioItemsInNavCollection(collection: NavCollection) -> [RelatedAudioItem] {
        let subitemIDs = subitemIDsForDescendantsOfNavNode(collection)
        return relatedAudioItemsForSubitemsWithIDs(subitemIDs)
    }
    
    func relatedAudioAvailableInNavCollection(collection: NavCollection) -> Bool {
        let subitemIDs = subitemIDsForDescendantsOfNavNode(collection)
        return hasRelatedAudioItemsForSubitemsWithIDs(subitemIDs)
    }


    
    
}